import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, readdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { FileStore } from '../src/store.js';
import { createApp } from '../src/index.js';
import { cleanData, checkReport, fallbackReport, generateReport, renderEmail, createMailer, validEmail } from '../src/report.js';

const raw = { report_language: 'en', child: { name: 'Aarav', age: 6, class: '1' }, season: 'Season 2', check_ins_done: 2, baseline_date: '2026-09-12', latest_date: '2026-10-10', skills: [{ skill: 'Decoding', baseline_pct: 30, latest_pct: 98 }, { skill: 'Phonological Awareness', baseline_pct: 9, latest_pct: 42 }], game_stats: { levels_cleared: 14 }, observations: ['Reads short words well'] };

const good = (data) => ({
  subject: 'Aarav’s Wordoo report', greeting: 'Dear parent,', summary: 'Aarav is doing well.', highlights: ['Decoding 30% → 98%'],
  skills: data.skills.map((s) => ({ ...s, trend: 'improved', what_it_means: 'ok', evidence: 'ok' })),
  focus_areas: [{ skill: 'Phonological Awareness', why: 'x', home_activity: 'rhyme game', minutes: 8 }], weekly_plan: ['a'], how_to_help_tips: ['b'],
  when_to_talk_to_teacher: 'c', closing: 'd', disclaimer: 'x',
});

test('cleanData fixes bands and strips markup', () => {
  const d = cleanData({ ...raw, child: { name: '<b>Aarav</b>' } });
  assert.equal(d.skills[0].band_now, 'Strong');
  assert.equal(d.skills[1].band_before, 'Needs Support');
  assert.ok(!d.child.name.includes('<'));
});

test('checks reject wrong numbers and diagnostic words', () => {
  const d = cleanData(raw);
  assert.deepEqual(checkReport(good(d), d), []);
  const wrong = good(d); wrong.skills[0].latest_pct = 50;
  assert.ok(checkReport(wrong, d).some((p) => /numbers differ/.test(p)));
  const dx = good(d); dx.summary = 'Aarav may have dyslexia.';
  assert.ok(checkReport(dx, d).some((p) => /diagnostic word/.test(p)));
});

test('gemini answer is used when valid; fallback when it keeps failing', async () => {
  const d = cleanData(raw);
  const ok = await generateReport({ async generateJson() { return good(d); } }, d);
  assert.equal(ok.source, 'gemini');
  const calls = [];
  const bad = await generateReport({ async generateJson() { calls.push(1); const r = good(d); r.summary = 'a disorder'; return r; } }, d);
  assert.equal(bad.source, 'template');
  assert.equal(calls.length, 2); // one retry
  assert.deepEqual(checkReport(fallbackReport(d), d), []);
  const down = await generateReport({ async generateJson() { throw new Error('boom'); } }, d);
  assert.equal(down.source, 'template');
});

test('email html escapes text', () => {
  const d = cleanData(raw);
  const r = good(d); r.summary = '<script>x</script>';
  assert.ok(!renderEmail(r, d).html.includes('<script>'));
});

test('email address validation', () => {
  assert.ok(validEmail('mum@example.com'));
  for (const e of ['', 'a@b', 'a b@c.com', '<x>@y.com', null]) assert.ok(!validEmail(e));
});

test('POST /report/email: needs consent, writes to the outbox without a mail provider, rate limits', async () => {
  const store = new FileStore(mkdtempSync(join(tmpdir(), 'wordoo-')));
  const outboxDir = mkdtempSync(join(tmpdir(), 'outbox-'));
  const gemini = { lastModel: 'mock', async generateJson() { return good(cleanData(raw)); } };
  const app = createApp({ store, agent: {}, cfg: { apiToken: '', outboxDir }, whisper: null, gemini, mailer: createMailer({ outboxDir }) });
  await new Promise((r) => app.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${app.address().port}`;
  const post = (body) => fetch(`${base}/report/email`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(body) });
  try {
    assert.equal((await post({ parent_email: 'mum@example.com', report_data: raw })).status, 400); // no consent
    assert.equal((await post({ parent_email: 'nope', consent: true, report_data: raw })).status, 400);
    const r = await post({ parent_email: 'mum@example.com', consent: true, student_id: 's1', report_data: raw });
    const j = await r.json();
    assert.equal(r.status, 200);
    assert.equal(j.sent, false);
    assert.equal(j.mode, 'outbox');
    assert.equal(j.written_by, 'gemini');
    assert.equal(readdirSync(outboxDir).length, 1);
    const stored = await store.find('reports', {});
    assert.equal(stored.length, 1);
    assert.equal(JSON.stringify(stored[0]).includes('mum@example.com'), false); // the address is never stored
    assert.equal((await post({ parent_email: 'mum@example.com', consent: true, report_data: raw })).status, 429);
  } finally {
    app.close();
  }
});

test('SMTP mailer sends through the transport (Gmail-style settings)', async () => {
  const sent = [];
  const m = createMailer({ outboxDir: '/nonexistent', smtp: { host: 'smtp.gmail.com', port: 465, user: 'me@gmail.com', pass: 'abcd efgh' }, transportFactory: async (o) => ({ opts: o, sendMail: async (x) => sent.push(x) }) });
  assert.equal(m.mode, 'smtp');
  const r = await m.send({ to: 'mum@example.com', subject: 's', html: '<p>h</p>', text: 't' });
  assert.equal(r.sent, true);
  assert.equal(sent[0].to, 'mum@example.com');
  assert.match(sent[0].from, /me@gmail.com/);
});
