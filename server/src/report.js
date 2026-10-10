// Parent report: Gemini writes a warm, plain-language "official" progress report from the numbers the app sends,
// the server checks it (numbers must match, no diagnostic words), renders an HTML + text email, and sends it.
// Mail providers: SMTP (e.g. Gmail with an app password: SMTP_HOST/SMTP_PORT/SMTP_USER/SMTP_PASS) or Resend (RESEND_API_KEY) — with neither set, the email is written to server/outbox/ (dry run).
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

export const SYSTEM_PROMPT = `You are the report writer for Wordoo, a reading and writing game for children aged 5–10. You write an official progress report for a child's PARENT.

RULES
- You are NOT a clinician. Never diagnose or name any condition (dyslexia, ADHD, etc.). Do not say "disorder", "disability" or "at risk of". Use "skill that needs more practice" instead.
- Use only the data given. Never invent scores, dates or events. If data is missing, say so.
- Tone: warm, respectful, plain English, no jargon. Lead with strengths. Keep each point short and concrete.
- Skill names: Phonological Awareness, Grapheme–Phoneme Correspondence, Decoding, Word Recognition, Spelling/Writing, Comprehension.
- Bands: Needs Support, Developing, Strong. Scores are percentages.
- Say that this is a learning-skills snapshot, not a medical or diagnostic result.
- Every home activity must take 5–10 minutes, need no special materials, and be tied to one specific skill.
- If the data includes speech timing (response speed, pauses, hesitation), explain it simply, as in "took longer to answer", not as a medical sign.
- Write in the language given in report_language. If it is "hi", write in Devanagari script, in simple everyday spoken Hindi (common English words like “game”, “level”, “star” are fine), not formal or Sanskritised Hindi.
- Copy baseline_pct, latest_pct, band_before and band_now exactly from the data.`;

const S = (t, extra = {}) => ({ type: t, ...extra });
const STR = { type: 'STRING' };
export const REPORT_SCHEMA = {
  type: 'OBJECT',
  properties: {
    subject: STR,
    greeting: STR,
    summary: STR,
    highlights: S('ARRAY', { items: STR }),
    skills: S('ARRAY', {
      items: {
        type: 'OBJECT',
        properties: { skill: STR, baseline_pct: { type: 'NUMBER' }, latest_pct: { type: 'NUMBER' }, band_before: STR, band_now: STR, trend: STR, what_it_means: STR, evidence: STR },
        required: ['skill', 'baseline_pct', 'latest_pct', 'band_before', 'band_now', 'trend', 'what_it_means', 'evidence'],
      },
    }),
    focus_areas: S('ARRAY', { items: { type: 'OBJECT', properties: { skill: STR, why: STR, home_activity: STR, minutes: { type: 'NUMBER' } }, required: ['skill', 'why', 'home_activity', 'minutes'] } }),
    weekly_plan: S('ARRAY', { items: STR }),
    how_to_help_tips: S('ARRAY', { items: STR }),
    when_to_talk_to_teacher: STR,
    closing: STR,
    disclaimer: STR,
  },
  required: ['subject', 'greeting', 'summary', 'highlights', 'skills', 'focus_areas', 'weekly_plan', 'how_to_help_tips', 'when_to_talk_to_teacher', 'closing', 'disclaimer'],
};

export const DISCLAIMER = 'This report shows learning-skill performance in the Wordoo game. It is not a medical or diagnostic assessment.';
const BANNED = /dyslex|dysgraph|dyscalcul|adhd|autis|disorder|diagnos(?!tic assessment)|disabilit|syndrome|at risk of/i;
const BAND = { needs: 'Needs Support', dev: 'Developing', strong: 'Strong' };
export const bandOf = (pct) => (pct >= 70 ? BAND.strong : pct >= 40 ? BAND.dev : BAND.needs);

/** The data block the app sends is cleaned to a known shape before it goes anywhere near the model. */
export function cleanData(d = {}) {
  const num = (x) => (Number.isFinite(Number(x)) ? Math.round(Number(x)) : 0);
  const txt = (x, n = 80) => String(x ?? '').replace(/[\u0000-\u001f<>]/g, ' ').trim().slice(0, n);
  return {
    report_language: d.report_language === 'hi' ? 'hi' : 'en',
    child: { name: txt(d.child?.name, 40) || 'Your child', age: num(d.child?.age), class: txt(d.child?.class, 20) },
    season: txt(d.season, 80),
    check_ins_done: num(d.check_ins_done),
    baseline_date: txt(d.baseline_date, 20),
    latest_date: txt(d.latest_date, 20),
    skills: (Array.isArray(d.skills) ? d.skills : []).slice(0, 8).map((s) => {
      const b = Math.max(0, Math.min(100, num(s.baseline_pct))), l = Math.max(0, Math.min(100, num(s.latest_pct)));
      return { skill: txt(s.skill, 60), baseline_pct: b, latest_pct: l, band_before: bandOf(b), band_now: bandOf(l) };
    }),
    game_stats: d.game_stats && typeof d.game_stats === 'object' ? Object.fromEntries(Object.entries(d.game_stats).slice(0, 12).map(([k, v]) => [txt(k, 30), Array.isArray(v) ? v.slice(0, 8).map((x) => txt(x, 30)) : num(v)])) : {},
    speech_metrics: d.speech_metrics && typeof d.speech_metrics === 'object' ? Object.fromEntries(Object.entries(d.speech_metrics).slice(0, 6).map(([k, v]) => [txt(k, 30), num(v)])) : undefined,
    difficult_items: (Array.isArray(d.difficult_items) ? d.difficult_items : []).slice(0, 8).map((x) => txt(x, 60)),
    observations: (Array.isArray(d.observations) ? d.observations : []).slice(0, 8).map((x) => txt(x, 160)),
  };
}

export function userMessage(data) {
  return `Write the report for this child.\n\n${JSON.stringify(data, null, 2)}`;
}

/** Returns a list of problems; empty means the report is safe to send. */
export function checkReport(r, data) {
  const bad = [];
  if (!r || typeof r !== 'object') return ['not an object'];
  // negations such as "not a medical or diagnostic assessment" are fine; the fixed disclaimer is replaced later anyway
  const { disclaimer, ...rest } = r;
  const all = JSON.stringify(rest).replace(/\b(not|no|isn't|is not|non)[ -](a |an )?(medical |clinical )?(or )?(a )?diagnos\w*( assessment| tool| result| test| label| score)?/gi, '');
  const hit = all.match(BANNED);
  if (hit) bad.push(`contains a diagnostic word (“${hit[0]}”)`);
  for (const s of data.skills) {
    const m = (r.skills ?? []).find((x) => x.skill === s.skill);
    if (!m) bad.push(`missing skill ${s.skill}`);
    else if (Math.round(m.baseline_pct) !== s.baseline_pct || Math.round(m.latest_pct) !== s.latest_pct) bad.push(`numbers differ for ${s.skill}`);
  }
  if (!r.summary || !r.subject) bad.push('no summary');
  return bad;
}

/** A plain report from the numbers alone: used when Gemini is unreachable or its answer fails the checks. */
export function fallbackReport(data) {
  const hi = data.report_language === 'hi';
  const name = data.child.name;
  const up = data.skills.filter((s) => s.latest_pct - s.baseline_pct >= 5);
  const low = [...data.skills].sort((a, b) => a.latest_pct - b.latest_pct).filter((s) => s.band_now !== 'Strong').slice(0, 2);
  const trend = (s) => (s.latest_pct - s.baseline_pct >= 5 ? 'improved' : s.latest_pct - s.baseline_pct <= -5 ? 'dipped' : 'steady');
  const tip = { 'Phonological Awareness': 'Say two words and ask “do they rhyme?” (cat–hat, dog–sun).', 'Decoding': 'Point to a short word on a cereal box and sound it out together.', 'Spelling/Writing': 'Say a 3-letter word slowly and let your child write it.', 'Comprehension': 'After a bedtime story ask “what happened first? what happened next?”', 'Word Recognition': 'Play “find the word”: hide three words around the room and race to read them.', 'Grapheme–Phoneme Correspondence': 'Say a sound and let your child find a matching letter in a book.' };
  return {
    subject: hi ? `${name} की Wordoo प्रगति रिपोर्ट` : `${name}'s Wordoo progress report`,
    greeting: hi ? `प्रिय अभिभावक,` : `Dear parent,`,
    summary: hi ? `${name} ने Wordoo में अच्छा अभ्यास किया है। नीचे हर कौशल की झलक है।` : `${name} has been practising reading skills in Wordoo. Here is a snapshot of every skill, with simple ideas for home.`,
    highlights: up.length ? up.slice(0, 3).map((s) => `${s.skill}: ${s.baseline_pct}% → ${s.latest_pct}%`) : [`${name} keeps practising regularly.`],
    skills: data.skills.map((s) => ({ ...s, trend: trend(s), what_it_means: s.band_now === 'Strong' ? 'A strong skill right now.' : s.band_now === 'Developing' ? 'Coming along well; steady practice will help.' : 'This skill needs more practice; short, fun sessions work best.', evidence: `Score ${s.latest_pct}% in the latest check-in.` })),
    focus_areas: low.map((s) => ({ skill: s.skill, why: 'This is where a little extra practice will help most.', home_activity: tip[s.skill] ?? 'Read together for 10 minutes.', minutes: 8 })),
    weekly_plan: ['Mon: rhyme game', 'Tue: sound a word out', 'Wed: read a short story together', 'Thu: spelling with magnets or paper', 'Fri: play a Wordoo island', 'Sat: find words on signs', 'Sun: rest and celebrate'],
    how_to_help_tips: ['Keep sessions short and cheerful.', 'Praise effort, not just right answers.', 'Let your child read to you, and wait before helping.'],
    when_to_talk_to_teacher: 'If a skill stays at “Needs Support” over two or more check-ins, it is worth sharing this report with your child’s teacher.',
    closing: `Thank you for supporting ${name}'s reading journey!`,
    disclaimer: DISCLAIMER,
  };
}

export async function generateReport(gemini, data) {
  let r, source = 'gemini', problems = [];
  try {
    r = await gemini.generateJson(userMessage(data), REPORT_SCHEMA, { system: SYSTEM_PROMPT, temperature: 0.4 });
    problems = checkReport(r, data);
    if (problems.length) {
      r = await gemini.generateJson(userMessage(data) + `\n\nYour previous answer had problems: ${problems.join('; ')}. Fix them.`, REPORT_SCHEMA, { system: SYSTEM_PROMPT, temperature: 0.2 });
      problems = checkReport(r, data);
    }
  } catch (e) {
    problems = [String(e.message ?? e)];
  }
  if (problems.length || !r) {
    return { report: fallbackReport(data), source: 'template', problems };
  }
  r.disclaimer = DISCLAIMER; // always the exact approved wording
  return { report: r, source, problems: [] };
}

const esc = (s) => String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);
const COL = { 'Strong': '#2E9B5B', 'Developing': '#E0A41A', 'Needs Support': '#E5483F' };

export function renderEmail(r, data) {
  const li = (a) => a.map((x) => `<li style="margin:4px 0">${esc(x)}</li>`).join('');
  const rows = r.skills.map((s) => {
    const arrow = s.trend === 'improved' ? '▲' : s.trend === 'dipped' ? '▼' : '■';
    return `<tr><td style="padding:12px 0;border-bottom:1px solid #eee"><div style="font-weight:700;color:#262A66">${esc(s.skill)} <span style="float:right">${s.baseline_pct}% → <b>${s.latest_pct}%</b> ${arrow}</span></div>
<div style="background:#eee;border-radius:8px;height:10px;margin:6px 0"><div style="background:${COL[s.band_now] ?? '#888'};width:${Math.max(3, s.latest_pct)}%;height:10px;border-radius:8px"></div></div>
<div style="font-size:12px;color:#555">${esc(s.band_before)} → <b style="color:${COL[s.band_now] ?? '#555'}">${esc(s.band_now)}</b></div>
<div style="font-size:14px;margin-top:4px">${esc(s.what_it_means)} <i style="color:#666">${esc(s.evidence)}</i></div></td></tr>`;
  }).join('');
  const focus = r.focus_areas.map((f) => `<div style="background:#FFF9E8;border-radius:12px;padding:12px;margin:8px 0"><b>${esc(f.skill)}</b> · ${esc(f.minutes)} min<br>${esc(f.why)}<br><b>Try:</b> ${esc(f.home_activity)}</div>`).join('');
  const html = `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head><body style="margin:0;background:#EEF3FF;font-family:Arial,Helvetica,sans-serif;color:#1E2753">
<div style="max-width:640px;margin:0 auto;padding:16px">
<div style="background:linear-gradient(#3B3F8F,#262A66);color:#fff;border-radius:18px 18px 0 0;padding:22px;text-align:center"><div style="font-size:28px;font-weight:800">Wordoo</div><div style="color:#FFE17A">Progress report · ${esc(data.child.name)}${data.latest_date ? ' · ' + esc(data.latest_date) : ''}</div></div>
<div style="background:#fff;padding:22px;border-radius:0 0 18px 18px;line-height:1.5">
<p>${esc(r.greeting)}</p><p>${esc(r.summary)}</p>
<h3 style="color:#2E9B5B">Highlights</h3><ul>${li(r.highlights)}</ul>
<h3>Skill by skill</h3><table width="100%" cellspacing="0" cellpadding="0">${rows}</table>
<h3>Focus areas for home</h3>${focus}
<h3>This week's plan</h3><ol>${li(r.weekly_plan)}</ol>
<h3>How to help</h3><ul>${li(r.how_to_help_tips)}</ul>
<p style="background:#E8F1FF;border-radius:12px;padding:12px">${esc(r.when_to_talk_to_teacher)}</p>
<p>${esc(r.closing)}</p>
<hr style="border:none;border-top:1px solid #eee"><p style="font-size:12px;color:#777">${esc(r.disclaimer)}</p>
</div></div></body></html>`;
  const text = [r.greeting, '', r.summary, '', 'HIGHLIGHTS', ...r.highlights.map((x) => `- ${x}`), '', 'SKILLS', ...r.skills.map((s) => `${s.skill}: ${s.baseline_pct}% -> ${s.latest_pct}% (${s.band_before} -> ${s.band_now}). ${s.what_it_means}`), '', 'FOCUS AREAS', ...r.focus_areas.map((f) => `${f.skill} (${f.minutes} min): ${f.home_activity}`), '', 'THIS WEEK', ...r.weekly_plan.map((x, i) => `${i + 1}. ${x}`), '', r.when_to_talk_to_teacher, '', r.closing, '', r.disclaimer].join('\n');
  return { html, text };
}

/** Sends through Resend when configured; otherwise writes the email to server/outbox/ so nothing is lost (dry run). */
export function createMailer({ resendKey, from, outboxDir, fetchImpl = fetch, smtp, transportFactory }) {
  const useSmtp = !!(smtp && smtp.host && smtp.user && smtp.pass);
  let transport;
  return {
    mode: useSmtp ? 'smtp' : resendKey ? 'resend' : 'outbox',
    async send({ to, subject, html, text }) {
      if (useSmtp) {
        transport ??= await (transportFactory ?? (async (o) => (await import('nodemailer')).default.createTransport(o)))({ host: smtp.host, port: smtp.port || 465, secure: (smtp.port || 465) === 465, auth: { user: smtp.user, pass: smtp.pass } });
        await transport.sendMail({ from: from || `Wordoo <${smtp.user}>`, to, subject, html, text });
        return { sent: true, mode: 'smtp' };
      }
      if (!resendKey) {
        mkdirSync(outboxDir, { recursive: true });
        const f = join(outboxDir, `${Date.now()}-${to.replace(/[^a-z0-9@._-]/gi, '_')}.html`);
        writeFileSync(f, `<!-- To: ${to}\n     Subject: ${subject} -->\n${html}`);
        return { sent: false, mode: 'outbox', file: f };
      }
      const res = await fetchImpl('https://api.resend.com/emails', { method: 'POST', headers: { Authorization: `Bearer ${resendKey}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ from: from || 'Wordoo <onboarding@resend.dev>', to: [to], subject, html, text }) });
      const body = await res.text();
      if (!res.ok) throw new Error(`mail ${res.status}: ${body.slice(0, 200)}`);
      return { sent: true, mode: 'resend' };
    },
  };
}

export const validEmail = (e) => typeof e === 'string' && e.length <= 120 && /^[^\s@<>"]+@[^\s@<>"]+\.[^\s@<>"]{2,}$/.test(e);
