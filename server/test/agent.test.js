import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { FileStore } from '../src/store.js';
import { QuestionAgent } from '../src/agent.js';
import { SUBTESTS } from '../src/subtests.js';
import { createApp } from '../src/index.js';
import { seedBank } from '../src/seed.js';

const cfg = { agentEnabled: true, agentBatch: 10, agentMinIntervalMs: 0, apiToken: '' };
const o = (label, emoji = '🙂') => ({ label, emoji });

// ten valid rhyme items for the mock to return, plus some broken ones
const RHYMES = [['cat', 'hat', 'dog', 'sun'], ['bee', 'tree', 'cup', 'fish'], ['ring', 'king', 'rain', 'moon'], ['cake', 'snake', 'cap', 'book'], ['bell', 'shell', 'ball', 'cup'], ['goat', 'boat', 'gate', 'cow'], ['bat', 'rat', 'bus', 'pig'], ['moon', 'spoon', 'fox', 'hat'], ['fish', 'dish', 'pan', 'bed'], ['star', 'car', 'stop', 'sun'], ['tent', 'bent', 'door', 'ship'], ['mug', 'bug', 'hen', 'pot']];
const rhymeItems = RHYMES.map(([w, c, a, b]) => ({ word: w, emoji: '🐱', correct: o(c), wrong: [o(a), o(b)] }));
const mockGemini = (items) => ({ model: 'mock', async generateJson() { return { items }; } });

function freshStore() {
  return new FileStore(mkdtempSync(join(tmpdir(), 'readle-')));
}
const telemetry = (over = {}) => ({ studentId: 'child_t1', subtest: 'rhyme', itemId: 'r1', tier: 'medium', nextTier: 'hard', score: 1, ms: 3000, lang: 'en', gradeBand: 'junior', quality: {}, ...over });

test('rhyme builder accepts a real rhyme and rejects a wrong one', () => {
  const ok = SUBTESTS.rhyme.build({ word: 'cat', emoji: '🐱', correct: o('hat'), wrong: [o('dog'), o('sun')] }, 1);
  assert.ok(ok.item);
  assert.equal(ok.item.say, 'Which one rhymes with cat?');
  assert.equal(SUBTESTS.rhyme.build({ word: 'cat', emoji: '🐱', correct: o('dog'), wrong: [o('hat'), o('sun')] }, 1).reject !== undefined, true);
  assert.equal(SUBTESTS.rhyme.build({ word: 'cat', emoji: '🐱', correct: o('hat'), wrong: [o('bat'), o('sun')] }, 1).reject !== undefined, true); // a wrong option rhymes too
});

test('other builders check their rules', () => {
  assert.ok(SUBTESTS.wordReading.build({ word: 'cat' }, 1).item);
  assert.ok(SUBTESTS.wordReading.build({ word: 'cats' }, 1).reject);
  assert.ok(SUBTESTS.nonwordReading.build({ word: 'blet' }, 2).item);
  assert.ok(SUBTESTS.nonwordReading.build({ word: 'xyz' }, 1).reject);
  assert.ok(SUBTESTS.spelling.build({ emoji: '🐱', word: 'cat', extraLetters: 'oe' }, 1).item);
  assert.ok(SUBTESTS.spelling.build({ emoji: '🐱', word: 'cat', extraLetters: 'ca' }, 1).reject);
  const m = SUBTESTS.phonemeManip.build({ word: 'cat', op: 'delete_first', removed: 'k', answer: 'at', wrong: ['ca', 'cot'] }, 1);
  assert.equal(m.item.say, 'Say cat, but take away the k sound.');
  assert.ok(SUBTESTS.phonemeManip.build({ word: 'cat', op: 'delete_first', removed: 'k', answer: 'ct', wrong: ['ca', 'cot'] }, 1).reject);
  const r = SUBTESTS.phonemeManip.build({ word: 'bat', op: 'replace_first', replaceWith: 'h', answer: 'hat', wrong: ['bit', 'bad'] }, 1);
  assert.equal(r.item.say, 'Say bat. Now change b to h.');
  assert.ok(SUBTESTS.firstSound.build({ letter: 'm', sound: 'mmm', correct: o('moon'), wrong: [o('sun'), o('car')] }).item);
  assert.ok(SUBTESTS.firstSound.build({ letter: 'm', sound: 'mmm', correct: o('moon'), wrong: [o('mat'), o('car')] }).reject);
});

test('agent adds exactly 10 valid, de-duplicated questions and logs the run', async () => {
  const store = freshStore();
  const agent = new QuestionAgent({ store, gemini: mockGemini([{ word: 'cat', emoji: '🐱', correct: o('dog'), wrong: [o('hat'), o('sun')] }, ...rhymeItems, rhymeItems[0]]), cfg, log() {} });
  const res = await agent.onResponse(telemetry());
  assert.equal(res.ran, true);
  assert.equal(res.added, 10);
  assert.equal(res.tier, 'hard');
  assert.equal(res.bankAfter - res.bankBefore, 10);
  assert.ok(res.rejected >= 1);
  const bank = await store.find('questions', { source: 'gemini' });
  assert.equal(bank.length, 10);
  assert.ok(bank.every((q) => q.difficulty === 3 && q.correct === 0 && q.options.length === 3 && q.status === 'active' && q.createdFor.student_id === 'child_t1'));
  assert.equal(new Set(bank.map((q) => q.id)).size, 10);
  assert.equal((await store.find('agent_runs')).length, 1);
  // a second response for the same station cannot re-add the same words
  const again = await agent.onResponse(telemetry({ itemId: 'r2' }));
  assert.equal(again.added, 1); // of the 12 words only one valid, unused word is left ("bell/ball" is rejected: the wrong option shares the ending)
});

test('agent reports (and does not crash) when Gemini fails or the station has no writer', async () => {
  const store = freshStore();
  const bad = new QuestionAgent({ store, gemini: { model: 'mock', async generateJson() { throw new Error('Gemini 429: quota'); } }, cfg, log() {} });
  const r = await bad.onResponse(telemetry());
  assert.equal(r.ran, false);
  assert.match(r.error, /429/);
  const ok = new QuestionAgent({ store, gemini: mockGemini([]), cfg, log() {} });
  assert.equal((await ok.onResponse(telemetry({ subtest: 'unknownStation' }))).ran, false);
  const off = new QuestionAgent({ store, gemini: mockGemini([]), cfg: { ...cfg, agentEnabled: false }, log() {} });
  assert.equal((await off.onResponse(telemetry())).reason, 'agent-disabled');
});

test('stations without a writer map to the closest one (oral reading → word reading)', async () => {
  const store = freshStore();
  const words = ['rabbit', 'garden', 'pencil', 'basket', 'window', 'monkey', 'yellow', 'orange', 'dinner', 'finger', 'summer', 'pocket'].map((word) => ({ word }));
  const agent = new QuestionAgent({ store, gemini: mockGemini(words), cfg, log() {} });
  const r = await agent.onResponse(telemetry({ subtest: 'oralReading', nextTier: 'hard' }));
  assert.equal(r.added, 10);
  assert.equal(r.subtest, 'wordReading');
  assert.equal(r.requestedFor, 'oralReading');
});

test('HTTP API: health, telemetry → agent, bank, screenings history', async () => {
  const store = freshStore();
  const agent = new QuestionAgent({ store, gemini: mockGemini(rhymeItems), cfg, log() {} });
  const server = createApp({ store, agent, cfg: { ...cfg, geminiKey: 'x', geminiModel: 'mock' } });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${server.address().port}`;
  const get = async (p) => (await fetch(base + p)).json();
  const post = async (p, b) => (await fetch(base + p, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(b) })).json();
  try {
    assert.equal((await get('/health')).ok, true);
    const t = await post('/telemetry', telemetry());
    assert.equal(t.agent.added, 10);
    const q = await get('/questions?lang=en');
    assert.equal(q.count, 10);
    assert.equal((await get('/bank/stats?lang=en')).generated, 10);
    assert.equal((await post('/telemetry', { subtest: 'rhyme' })).error, 'missing studentId');
    const doc = { student_id: 'child_t1', child_name: 'Aryan', grade_band: 'junior', test_date: '2026-10-10T03:54:00Z', indicator: 'some_indicators', construct_scores: { phonological: { percentile: 42.5, band: 'needsSupport' } }, observations: ['x'] };
    assert.equal((await post('/screenings', doc)).stored, true);
    assert.equal((await post('/screenings', { student_id: 'a' })).error, 'missing child_name');
    assert.equal((await get('/screenings?student_id=child_t1')).screenings.length, 1);
    assert.equal((await get('/agent/runs')).runs.length, 1);
  } finally {
    server.close();
  }
});

test('seed: the shipped questions go into the database once', async () => {
  const store = freshStore();
  const first = await seedBank(store);
  assert.ok(first >= 100);
  assert.equal(await seedBank(store), 0);
  const one = (await store.find('questions', { id: 'r1' }))[0];
  assert.equal(one.source, 'seed');
  assert.equal(one.subtest, 'rhyme');
});
