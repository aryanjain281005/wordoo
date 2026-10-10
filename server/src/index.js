// Readle cloud server. Start:  cd server && npm install && npm start      (settings in the repo's git-ignored .env)
//   GET  /health                      status, database kind, bank size
//   GET  /questions?lang=en           the whole active question bank (seed + agent-written) for the app to cache
//   POST /telemetry                   one answer → stored in `responses`, then the Question Agent writes 10 new questions
//   POST /screenings                  one finished screening → `screenings` (the longitudinal history)
//   GET  /screenings?student_id=…     a child's history, newest first
//   GET  /bank/stats?lang=en          counts per station and difficulty pool, and by source
//   GET  /agent/runs                  the latest Question Agent runs
import http from 'node:http';
import { config } from './env.js';
import { openStore } from './store.js';
import { geminiClient } from './gemini.js';
import { QuestionAgent } from './agent.js';
import { seedBank } from './seed.js';

export function createApp({ store, agent, cfg }) {
  const json = (res, code, body) => {
    res.writeHead(code, { 'Content-Type': 'application/json; charset=utf-8', 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'content-type,x-readle-key', 'Access-Control-Allow-Methods': 'GET,POST,OPTIONS' });
    res.end(JSON.stringify(body));
  };
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
        return json(res, 200, { ok: true, database: store.kind, agent: cfg.agentEnabled && !!cfg.geminiKey ? cfg.geminiModels : 'off', bank: await store.count('questions', { lang, status: 'active' }) });
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
  const app = createApp({ store, agent, cfg });
  app.listen(cfg.port, cfg.host, () => console.log(`Readle server on :${cfg.port} · database: ${store.kind} · agent: ${cfg.geminiKey ? cfg.geminiModels.join(' → ') : 'OFF (no GEMINI_API_KEY)'} · bank seeded +${n}`));
}
