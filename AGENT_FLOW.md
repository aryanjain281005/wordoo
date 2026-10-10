# Adaptive screening + Question Agent (MongoDB · Gemini)

## Where the agent lives

| What | File |
|---|---|
| **The Question Agent** (calls Gemini, checks, stores) | [`server/src/agent.js`](server/src/agent.js) |
| What it may write per station + the checks every question must pass | [`server/src/subtests.js`](server/src/subtests.js) |
| Gemini client (key stays on the server) | [`server/src/gemini.js`](server/src/gemini.js) |
| HTTP API / entry point | [`server/src/index.js`](server/src/index.js) |
| Database layer (MongoDB, or JSON files when no `MONGODB_URI`) | [`server/src/store.js`](server/src/store.js) |
| Seeds the shipped questions into the database | [`server/src/seed.js`](server/src/seed.js) ← `tool/export_bank.dart` |
| App side: three-pool rule | [`lib/screening/adaptive.dart`](lib/screening/adaptive.dart) |
| App side: screening flow | [`lib/screening/ui/screening_screen.dart`](lib/screening/ui/screening_screen.dart) |
| App side: link to the server | [`lib/core/cloud.dart`](lib/core/cloud.dart) |
| App side: local copy of the bank | [`lib/screening/question_store.dart`](lib/screening/question_store.dart) |
| History document | [`lib/screening/history_doc.dart`](lib/screening/history_doc.dart) |
| The banner shown after each answer | [`lib/screening/ui/agent_banner.dart`](lib/screening/ui/agent_banner.dart) |

## The flow, one answer at a time

```
child answers a question                         (app: ScreeningScreen._onDone)
  │
  ├─ 1. HOW did they answer?                     (Adaptive.assess)
  │      right / wrong · response time · long pause before speaking / pauses while speaking
  │      · unclear speech · asked for replays
  │
  ├─ 2. WHICH POOL is the next question from?    (Adaptive.next)   questions are in 3 pools: easy / medium / hard
  │        wrong                                  → EASY
  │        right, but slow / paused / unclear     → MEDIUM
  │        right, quick and clean                 → HARD
  │      (the first question of every station is MEDIUM)
  │
  ├─ 3. pick the question                        (Adaptive.pick)   least-seen first; agent-written questions before shipped ones
  │
  └─ 4. send the answer to the cloud             (Cloud.sendResponse → POST /telemetry)
         │
         ▼  server/src/index.js
         responses collection ← the answer (telemetry)
         │
         ▼  server/src/agent.js  (QuestionAgent.onResponse)
         a) which station + which pool?  (the pool the child goes to next; oral reading / fluency / naming map to the closest writable station)
         b) prompt Gemini (gemini-flash-latest; if it is slow (>20 s) or fails, gemini-flash-lite-latest answers; structured JSON) with: the station's rules, the pool's difficulty, how the child answered
            (right/wrong, slow, pause, mistake type), and the questions that already exist (so it does not repeat them)
         c) every question Gemini returns is CHECKED (subtests.js): e.g. a rhyme must share its ending with the target and the
            wrong options must not; a "take away the c sound" answer must equal the word minus its first letter; spelling decoys
            must not be in the word; word length must fit the pool. Failures and duplicates are thrown away.
         d) up to 10 valid questions → `questions` collection (source "gemini", pool = difficulty 1/2/3, status "active")
         e) the run is logged in `agent_runs`
         │
         ▼  response: { added: 10, bankBefore: 124, bankAfter: 134, questions: [...] }
  app: the 10 new questions are added to the local bank at once (the same screening can already use them)
       and the BANNER shows:  "🧠 Question Agent added +10 new questions · bank 124 → 134 · Rhyme Time · hard pool"

screening finished → POST /screenings → `screenings` collection (the longitudinal history, one nested document per screening)
```

If the server is not reachable the screening still runs from the questions bundled in the app, answers are simply not sent, and a
finished screening is kept on the phone and sent next time.

## Collections (MongoDB)

* **questions** – the bank: `{id, lang, subtest, pool: A|B, difficulty: 1|2|3, …question fields…, source: seed|gemini, status, createdAt, model, createdFor}`
* **screenings** – `{student_id, child_name, grade_band, test_date, indicator, construct_scores: {phonological: {percentile, band}, …}, observations: [], kind: baseline|weekly_check, subtests: [], adaptive_trace: []}`
* **responses** – one document per answer (time, pool, next pool, quality flags, speech metrics)
* **agent_runs** – what the agent was asked, what it added, what it rejected

## Running it

```
cd server && npm install
# .env at the repo root (git-ignored):   MONGODB_URI=mongodb+srv://…   GEMINI_API_KEY=…      (MONGODB_URI empty → JSON files in server/data)
npm start                      # seeds the 124 shipped questions on first start
npm test                       # 7 tests (mock Gemini)
adb reverse tcp:8787 tcp:8787  # lets a phone on USB reach it as http://127.0.0.1:8787  (the app's default READLE_API)
```
Deployed server: build the app with `--dart-define=READLE_API=https://your-server` (plain http is allowed only for localhost).
Change the shipped questions → `dart run tool/export_bank.dart && (cd server && npm run seed)`.
Turn the cloud link off in the app: `--dart-define=READLE_API=off`. Hide the banner: `--dart-define=READLE_AGENT_BANNER=false`.

## Notes
* Thresholds (slow = 9 s per choice question, 30 s tiles; long pause = 3.5 s before speaking / 2 pauses / 1.2 s silence; unclear = recogniser confidence < 0.5) and the pool weights in scoring (easy 0.7 · medium 1 · hard 1.3) are **provisional**, to be tuned on pilot data.
* The agent writes **English** questions only for now; the same code takes other languages through `lang`.
* Keys live only in `.env` / server environment. The app contains no key. Anyone who can reach the server can send answers — put it behind
  `API_TOKEN` / an HTTPS gateway before real use.
