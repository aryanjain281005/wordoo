// The Question Agent.
//
// Every answer a child gives is sent here (POST /telemetry). The agent looks at HOW the child answered (right/wrong, quick or
// hesitant, which mistake) and which difficulty pool the app will draw the next question from, then asks Gemini to write
// `agentBatch` (10) NEW questions for that station and pool. Each question is checked by the rules in subtests.js; the ones that
// pass are written to the `questions` collection, so the bank grows with every child and every answer.
import { createHash } from 'node:crypto';
import { SUBTESTS, TIERS, TIER_NAMES, generableSubtest } from './subtests.js';

const id8 = (s) => createHash('sha1').update(s).digest('hex').slice(0, 8);

export class QuestionAgent {
  constructor({ store, gemini, cfg, log = console.log }) {
    this.store = store;
    this.gemini = gemini;
    this.cfg = cfg;
    this.log = log;
    this._chain = Promise.resolve(); // runs are queued one after another (Gemini is rate-limited)
    this._lastRun = new Map(); // student → time of their last run
  }

  /** Called for every telemetry event. Never throws: the result says what happened. */
  onResponse(t) {
    const run = this._chain.then(() => this._run(t)).catch((e) => ({ ran: false, reason: 'error', error: String(e.message ?? e) }));
    this._chain = run.then(() => {}, () => {});
    return run;
  }

  async bankSize(lang) {
    return this.store.count('questions', { lang, status: 'active' });
  }

  async _run(t) {
    const lang = t.lang || 'en';
    const started = Date.now();
    if (!this.cfg.agentEnabled) return { ran: false, reason: 'agent-disabled' };
    const subtest = generableSubtest(t.subtest);
    if (!subtest) return { ran: false, reason: `no question writer for ${t.subtest}` };
    const spec = SUBTESTS[subtest];
    const tierNum = TIERS[t.nextTier] ?? TIERS.medium;
    const last = this._lastRun.get(t.studentId) ?? 0;
    if (this.cfg.agentMinIntervalMs && started - last < this.cfg.agentMinIntervalMs) return { ran: false, reason: 'rate-limited' };
    this._lastRun.set(t.studentId, started);

    const bankBefore = await this.bankSize(lang);
    const existing = await this.store.find('questions', { lang, subtest, status: 'active' });
    const taken = new Set(existing.map((q) => q.key).filter(Boolean));
    // the same word / passage is never added twice to a station, whichever pool it is in (seed questions have no key, so compare the text)
    const texts = new Set(existing.flatMap((q) => [q.target, q.passage?.toLowerCase()]).filter(Boolean));
    const want = this.cfg.agentBatch;
    const accepted = [];
    const rejected = [];
    const seen = new Set();

    for (let attempt = 0; attempt < 2 && accepted.length < want; attempt++) {
      const need = want - accepted.length;
      const ask = need + 4; // a few spare, because some will fail the checks
      const prompt = this._prompt({ spec, subtest, tier: tierNum, t, existing, ask, avoid: [...seen] });
      const out = await this.gemini.generateJson(prompt, { type: 'OBJECT', properties: { items: { type: 'ARRAY', items: spec.schema } }, required: ['items'] });
      for (const g of out.items ?? []) {
        if (accepted.length >= want) break;
        let r;
        try {
          r = spec.build(g, tierNum, t);
        } catch (e) {
          r = { reject: `exception: ${e.message}` };
        }
        if (r.reject) {
          rejected.push(r.reject);
          continue;
        }
        const key = `${subtest}|${tierNum}|${r.key}`;
        const text = r.item.target ?? r.item.passage?.toLowerCase();
        if (taken.has(key) || seen.has(key) || (text && texts.has(text))) {
          rejected.push('duplicate of an existing question');
          continue;
        }
        seen.add(key);
        if (text) texts.add(text);
        accepted.push({ item: r.item, key });
      }
    }

    const ts = new Date().toISOString();
    const docs = accepted.map(({ item, key }, i) => ({
      id: `g_${subtest}_${TIER_NAMES[tierNum][0]}_${id8(key)}`,
      lang,
      subtest,
      pool: i % 2 === 0 ? 'A' : 'B', // spread over both forms so baseline and weekly check-ins both get fresh questions
      difficulty: tierNum,
      correct: 0,
      accept: [],
      answer: [],
      distractors: [],
      questions: [],
      options: [],
      ...item,
      key,
      source: 'gemini',
      status: 'active',
      model: this.gemini.model,
      createdAt: ts,
      createdFor: { student_id: t.studentId, trigger_item: t.itemId, score: t.score, tier: t.tier, quality: t.quality ?? {}, error: t.tag ?? null },
    }));
    for (const d of docs) await this.store.upsertQuestion(d);
    const bankAfter = await this.bankSize(lang);
    const result = {
      ran: true,
      model: this.gemini.model,
      subtest,
      requestedFor: t.subtest,
      tier: TIER_NAMES[tierNum],
      added: docs.length,
      rejected: rejected.length,
      rejectedWhy: [...new Set(rejected)].slice(0, 6),
      bankBefore,
      bankAfter,
      ms: Date.now() - started,
      questions: docs.map(({ key, createdFor, _id, ...q }) => q),
    };
    await this.store.insertOne('agent_runs', { ts, student_id: t.studentId, trigger: { subtest: t.subtest, item: t.itemId, score: t.score, tier: t.tier, next: t.nextTier, quality: t.quality ?? {}, tag: t.tag ?? null }, ...result, questions: docs.map((d) => d.id) });
    this.log(`[agent] ${t.studentId} ${t.subtest}→${subtest}/${TIER_NAMES[tierNum]}: +${docs.length} (rejected ${rejected.length}) bank ${bankBefore}→${bankAfter} in ${result.ms} ms`);
    return result;
  }

  _prompt({ spec, subtest, tier, t, existing, ask, avoid }) {
    const sameTier = existing.filter((q) => q.difficulty === tier).slice(0, 30);
    const examples = sameTier.slice(0, 4).map((q) => JSON.stringify({ target: q.target, say: q.say, options: (q.options ?? []).map((o) => o.label), passage: q.passage }));
    const taken = existing.map((q) => q.target ?? q.passage ?? q.say).filter(Boolean).slice(0, 80);
    const how = [];
    if (t.score < 0.5) how.push('answered the last question WRONG');
    else if (t.score < 0.99) how.push('answered the last question only partly right');
    else how.push('answered the last question right');
    const q = t.quality ?? {};
    if (q.slow) how.push('took a long time');
    if (q.longPause) how.push('paused for a long time');
    if (q.lowConfidence) how.push('spoke unclearly');
    if (q.replayed) how.push('needed the instruction repeated');
    if (t.tag) how.push(`made this kind of mistake: "${t.tag}"`);
    return `You write questions for "Readle", a reading-screening game for children aged 5-10 in India who learn English at school.
Station: ${subtest}. ${spec.describe}
Write exactly ${ask} NEW questions of ${TIER_NAMES[tier].toUpperCase()} difficulty (difficulty pool ${tier} of 3).
Rules: ${spec.rules}
All words must be simple, child-safe, and spelled in lowercase English letters (emoji for pictures). Do not repeat each other.
Context: a ${t.gradeBand ?? 'junior'}-band child (${t.gradeBand === 'middle' ? 'Classes 3-5' : 'Classes 1-2'}) just ${how.join(', ')}. The next questions in this pool should help find out whether this child can do this skill: vary the words and patterns, and when a mistake type is given, include some questions that probe that exact mistake.
Do NOT reuse any of these already-existing items: ${JSON.stringify(taken)}${avoid.length ? ` and also not: ${JSON.stringify(avoid.slice(0, 40))}` : ''}.
${examples.length ? `Examples of the style (existing items): ${examples.join(' ')}` : ''}
Return JSON only, in the given schema.`;
  }
}
