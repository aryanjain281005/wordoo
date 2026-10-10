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
  const server = createApp({ store, agent, cfg: { ...cfg, geminiKey: 'x', geminiModels: ['mock'] } });
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

test('Gemini client falls back to the next model when the first is slow or fails', async () => {
  const { geminiClient } = await import('../src/gemini.js');
  const calls = [];
  const fetchImpl = async (url, opts) => {
    calls.push(url.split('/models/')[1].split(':')[0]);
    if (calls.length === 1) {
      await new Promise((_, rej) => opts.signal.addEventListener('abort', () => rej(Object.assign(new Error('x'), { name: 'AbortError' }))));
    }
    return { ok: true, text: async () => JSON.stringify({ candidates: [{ content: { parts: [{ text: '{"items":[1]}' }] } }] }) };
  };
  const g = geminiClient({ apiKey: 'k', models: ['slow-model', 'fast-lite'], fetchImpl, firstTimeoutMs: 30 });
  assert.deepEqual(await g.generateJson('p', {}), { items: [1] });
  assert.deepEqual(calls, ['slow-model', 'fast-lite']);
  assert.equal(g.lastModel, 'fast-lite');
});

test('Whisper: result is normalised, phantom phrases in silence are dropped, HTTP endpoint works', async () => {
  const { createWhisper, normalise } = await import('../src/whisper.js');
  const good = normalise({ text: ' Cat', duration: 2.1, words: [{ word: ' Cat', start: 0.8, end: 1.2 }], segments: [{ start: 0, end: 2.1, avg_logprob: -0.2, no_speech_prob: 0.02 }] });
  assert.equal(good.text, 'Cat');
  assert.equal(good.words[0].start, 0.8);
  assert.ok(good.confidence > 0.7 && good.confidence <= 1);
  const phantom = normalise({ text: 'Thank you.', words: [{ word: 'Thank', start: 0, end: 0.4 }], segments: [{ start: 0, end: 2, avg_logprob: -0.9, no_speech_prob: 0.7 }] });
  assert.equal(phantom.text, '');
  assert.deepEqual(phantom.words, []);
  assert.equal(phantom.confidence, 0);

  let seen;
  const fetchImpl = async (url, opts) => {
    seen = { url, auth: opts.headers.Authorization, fields: [...opts.body.keys()] };
    return { ok: true, text: async () => JSON.stringify({ text: 'ship', duration: 1.5, words: [{ word: 'ship', start: 0.5, end: 1.0 }], segments: [{ start: 0, end: 1.5, avg_logprob: -0.1, no_speech_prob: 0 }] }) };
  };
  const whisper = createWhisper({ apiKey: 'sk-test', fetchImpl });
  const store = freshStore();
  const server = createApp({ store, agent: new QuestionAgent({ store, gemini: mockGemini([]), cfg, log() {} }), cfg: { ...cfg, geminiKey: 'x', geminiModels: ['m'] }, whisper });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${server.address().port}`;
  try {
    assert.equal((await (await fetch(base + '/health')).json()).whisper, true);
    const r = await (await fetch(base + '/transcribe?lang=en&prompt=a%20child', { method: 'POST', headers: { 'content-type': 'audio/wav' }, body: Buffer.from('RIFFxxxxWAVE') })).json();
    assert.equal(r.text, 'ship');
    assert.equal(r.words[0].end, 1.0);
    assert.equal(seen.url, 'https://api.openai.com/v1/audio/transcriptions');
    assert.equal(seen.auth, 'Bearer sk-test');
    assert.ok(seen.fields.includes('timestamp_granularities[]') && seen.fields.includes('file') && seen.fields.includes('language'));
  } finally {
    server.close();
  }
  const off = createApp({ store, agent: new QuestionAgent({ store, gemini: mockGemini([]), cfg, log() {} }), cfg, whisper: createWhisper({ apiKey: '' }) });
  await new Promise((r) => off.listen(0, '127.0.0.1', r));
  try {
    const x = await fetch(`http://127.0.0.1:${off.address().port}/transcribe`, { method: 'POST', body: Buffer.from('a') });
    assert.equal(x.status, 503);
  } finally {
    off.close();
  }
});

test('Whisper probe: unhealthy (no credits) → health says whisper:false and /transcribe is refused; healthy again after a good probe', async () => {
  const { createWhisper } = await import('../src/whisper.js');
  let ok = false;
  const fetchImpl = async () => (ok ? { ok: true, text: async () => JSON.stringify({ text: '', segments: [] }) } : { ok: false, status: 429, text: async () => '{"error":{"message":"You have no credits remaining"}}' });
  const whisper = createWhisper({ apiKey: 'sk-x', fetchImpl });
  const store = freshStore();
  const server = createApp({ store, agent: new QuestionAgent({ store, gemini: mockGemini([]), cfg, log() {} }), cfg, whisper });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${server.address().port}`;
  try {
    assert.equal(await whisper.probe(), false);
    const h = await (await fetch(base + '/health')).json();
    assert.equal(h.whisper, false);
    assert.match(h.whisperError, /no credits/);
    assert.equal((await fetch(base + '/transcribe', { method: 'POST', body: Buffer.from('x') })).status, 503);
    ok = true;
    assert.equal(await whisper.probe(), true);
    assert.equal((await (await fetch(base + '/health')).json()).whisper, true);
  } finally {
    server.close();
  }
});
