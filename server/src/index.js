// Wordoo cloud server. Start:  cd server && npm install && npm start      (settings in the repo's git-ignored .env)
//   GET  /health                      status, database kind, bank size
//   GET  /questions?lang=en           the whole active question bank (seed + agent-written) for the app to cache
//   POST /telemetry                   one answer → stored in `responses`, then the Question Agent writes 10 new questions
//   POST /screenings                  one finished screening → `screenings` (the longitudinal history)
//   GET  /screenings?student_id=…     a child's history, newest first
//   POST /report/email                parent report: Gemini writes it, the server checks it, then emails it (or writes it to server/outbox/)
//   GET  /bank/stats?lang=en          counts per station and difficulty pool, and by source
//   GET  /agent/runs                  the latest Question Agent runs
import http from 'node:http';
import { config } from './env.js';
import { openStore } from './store.js';
import { geminiClient } from './gemini.js';
import { QuestionAgent } from './agent.js';
import { seedBank } from './seed.js';
import { createWhisper } from './whisper.js';
import { cleanData, generateReport, renderEmail, createMailer, validEmail } from './report.js';

export function createApp({ store, agent, cfg, whisper, gemini, mailer }) {
  const lastMail = new Map(); // parent email → time of the last report (one per minute)
  const json = (res, code, body) => {
    res.writeHead(code, { 'Content-Type': 'application/json; charset=utf-8', 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'content-type,x-readle-key', 'Access-Control-Allow-Methods': 'GET,POST,OPTIONS' });
    res.end(JSON.stringify(body));
  };
  const readRaw = (req, limit = 12e6) =>
    new Promise((resolve, reject) => {
      const chunks = [];
      let n = 0;
      req.on('data', (c) => {
        n += c.length;
        if (n > limit) reject(new Error('audio too large'));
        else chunks.push(c);
      });
      req.on('end', () => resolve(Buffer.concat(chunks)));
      req.on('error', reject);
    });
  const readBody = (req) =>
    new Promise((resolve, reject) => {
      let b = '';
      req.on('data', (c) => {
        b += c;
        if (b.length > 2e6) reject(new Error('body too large'));
      });
      req.on('end', () => {
        try {
          resolve(b ? JSON.parse(b) : {});
        } catch (e) {
          reject(new Error('invalid JSON'));
        }
      });
    });

  return http.createServer(async (req, res) => {
    const url = new URL(req.url, 'http://x');
    if (req.method !== 'OPTIONS' && url.pathname !== '/health') console.log(`${new Date().toISOString()} ${req.method} ${url.pathname}${url.search}`);
    try {
      if (req.method === 'OPTIONS') return json(res, 204, {});
      if (cfg.apiToken && req.headers['x-readle-key'] !== cfg.apiToken && url.pathname !== '/health') return json(res, 401, { error: 'unauthorized' });
      const lang = url.searchParams.get('lang') || 'en';

      if (req.method === 'GET' && url.pathname === '/health') {
        return json(res, 200, { ok: true, database: store.kind, agent: cfg.agentEnabled && !!cfg.geminiKey ? cfg.geminiModels : 'off', whisper: !!whisper?.enabled && whisper.healthy !== false, ...(whisper?.enabled && whisper.healthy === false ? { whisperError: whisper.error } : {}), bank: await store.count('questions', { lang, status: 'active' }) });
      }
      if (req.method === 'GET' && url.pathname === '/questions') {
        const qs = (await store.find('questions', { lang, status: 'active' })).map(({ _id, key, createdFor, ...q }) => q);
        return json(res, 200, { lang, count: qs.length, questions: qs });
      }
      if (req.method === 'GET' && url.pathname === '/bank/stats') {
        const qs = await store.find('questions', { lang, status: 'active' });
        const by = {};
        for (const q of qs) {
          const k = (by[q.subtest] ??= { easy: 0, medium: 0, hard: 0, seed: 0, gemini: 0 });
          k[['easy', 'medium', 'hard'][q.difficulty - 1]]++;
          k[q.source === 'gemini' ? 'gemini' : 'seed']++;
        }
        return json(res, 200, { lang, total: qs.length, generated: qs.filter((q) => q.source === 'gemini').length, bySubtest: by });
      }
      if (req.method === 'GET' && url.pathname === '/agent/runs') {
        return json(res, 200, { runs: await store.find('agent_runs', {}, { sort: { ts: -1 }, limit: 20 }) });
      }
      if (req.method === 'GET' && url.pathname === '/screenings') {
        const sid = url.searchParams.get('student_id');
        return json(res, 200, { screenings: await store.find('screenings', sid ? { student_id: sid } : {}, { sort: { test_date: -1 }, limit: 50 }) });
      }
      if (req.method === 'POST' && url.pathname === '/transcribe') {
        if (!whisper?.enabled) return json(res, 503, { error: 'whisper is not configured (OPENAI_API_KEY)' });
        if (whisper.healthy === false) return json(res, 503, { error: `whisper is unavailable: ${whisper.error}` });
        const audio = await readRaw(req);
        const r = await whisper.transcribe({ audio, mime: req.headers['content-type'] || 'audio/wav', lang: url.searchParams.get('lang') || 'en', prompt: url.searchParams.get('prompt') || '' });
        return json(res, 200, { ok: true, model: whisper.model, ...r });
      }
      if (req.method === 'POST' && url.pathname === '/telemetry') {
        const t = await readBody(req);
        for (const k of ['studentId', 'subtest', 'itemId']) if (!t[k]) return json(res, 400, { error: `missing ${k}` });
        t.lang = t.lang || lang;
        await store.insertOne('responses', { ts: new Date().toISOString(), student_id: t.studentId, ...t });
        const agentResult = await agent.onResponse(t);
        return json(res, 200, { ok: true, stored: true, agent: agentResult });
      }
      if (req.method === 'POST' && url.pathname === '/screenings') {
        const d = await readBody(req);
        for (const k of ['student_id', 'child_name', 'grade_band', 'test_date', 'indicator', 'construct_scores', 'observations']) if (d[k] === undefined) return json(res, 400, { error: `missing ${k}` });
        await store.insertOne('screenings', d);
        return json(res, 200, { ok: true, stored: true });
      }
      if (req.method === 'POST' && url.pathname === '/report/email') {
        const b = await readBody(req);
        if (!validEmail(b.parent_email)) return json(res, 400, { error: 'invalid parent_email' });
        if (b.consent !== true) return json(res, 400, { error: 'parent consent is required' });
        if (!gemini) return json(res, 503, { error: 'report writer is not configured' });
        const to = b.parent_email.trim().toLowerCase();
        if (Date.now() - (lastMail.get(to) ?? 0) < 60000) return json(res, 429, { error: 'a report was just sent; try again in a minute' });
        lastMail.set(to, Date.now());
        const data = cleanData(b.report_data);
        if (!data.skills.length) return json(res, 400, { error: 'report_data.skills is empty' });
        const { report, source, problems } = await generateReport(gemini, data);
        const { html, text } = renderEmail(report, data);
        let sent;
        try {
          sent = await (mailer ?? createMailer({ outboxDir: cfg.outboxDir })).send({ to, subject: report.subject, html, text });
        } catch (e) {
          lastMail.delete(to);
          await store.insertOne('reports', { ts: new Date().toISOString(), student_id: String(b.student_id ?? ''), to_domain: to.split('@')[1], source, status: 'failed', error: String(e.message).slice(0, 200) });
          return json(res, 502, { error: 'could not send the email', detail: String(e.message).slice(0, 200) });
        }
        // the address itself is not stored: only its domain, the text of the report and how it was sent
        await store.insertOne('reports', { ts: new Date().toISOString(), student_id: String(b.student_id ?? ''), to_domain: to.split('@')[1], source, status: sent.sent ? 'sent' : 'outbox', mode: sent.mode, data, report });
        return json(res, 200, { ok: true, sent: sent.sent, mode: sent.mode, written_by: source, model: source === 'gemini' ? gemini.lastModel : null, ...(problems.length ? { notes: problems } : {}) });
      }
      return json(res, 404, { error: 'not found' });
    } catch (e) {
      return json(res, 500, { error: String(e.message ?? e) });
    }
  });
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const cfg = config();
  const store = await openStore(cfg);
  const gemini = geminiClient({ apiKey: cfg.geminiKey, models: cfg.geminiModels });
  const agent = new QuestionAgent({ store, gemini, cfg });
  const n = await seedBank(store);
  const whisper = createWhisper({ apiKey: cfg.openaiKey });
  whisper.probe().then((ok) => console.log(ok ? 'Whisper probe: OK' : `Whisper probe FAILED: ${whisper.error}`));
  setInterval(() => whisper.probe(), 10 * 60 * 1000).unref(); // credits added later → the app starts using Whisper by itself
  const mailer = createMailer({ resendKey: cfg.resendKey, smtp: cfg.smtp, from: cfg.mailFrom, outboxDir: cfg.outboxDir });
  const app = createApp({ store, agent, cfg, whisper, gemini, mailer });
  app.listen(cfg.port, cfg.host, () => console.log(`Wordoo server on :${cfg.port} · database: ${store.kind} · whisper: ${cfg.openaiKey ? 'on' : 'off'} · agent: ${cfg.geminiKey ? cfg.geminiModels.join(' → ') : 'OFF (no GEMINI_API_KEY)'} · mail: ${mailer.mode} · bank seeded +${n}`));
}
