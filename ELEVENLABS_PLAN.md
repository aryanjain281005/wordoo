# ElevenLabs voices for Wordoo: design blueprint

Status: **implemented 10 Oct (steps 1-3 and batch 1).** Where it lives:
* `tool/gen_voices.py` — `ENGINE=eleven` (dialogue only: `assets/story/lines_en.json`; the 5,000-word `say` bank and story-book narration stay on Kokoro). `DRY=1` prints the credit estimate. Stops cleanly on `quota`/402/401, retries 429/5xx, resumes by content hash.
* `tool/voice_cast.json` — per-character `"eleven": {voice_id, stability, style, speed, fx}`. **Premade voices only** (the free plan cannot use Voice Library voices over the API; swap `voice_id` after upgrading, e.g. the Indian-English "Mitali / Anika / Sonal" voices).
* `.env` (git-ignored, `ELEVENLABS_API_KEY=`) — never committed; `test/cutscene_content_test.dart` fails if a key-like string appears in `lib/`, `assets/story`, `assets/cutscenes` or `tool/`.
* Output: `assets/vo/en/<line id>.ogg` (same names as the Kokoro files, so the app needed no change) + lip-sync envelopes.
* Model: `eleven_flash_v2_5` (half the credits). 224 lines / ≈ 13,300 characters voiced on 10 Oct. Free plan = non-commercial: upgrade to Starter before publishing.

(The text below is the original design.)

Original status line: **plan only.** Written after reviewing the current audio pipeline
(`tool/gen_voices.py`, `tool/voice_cast.json`, `lib/core/audio.dart`, `lib/story/cutscene.dart`, `lib/story/story_book.dart`).

## 0. The key finding: we don't need ElevenLabs at runtime

Every sentence a character says in Wordoo is **known before the app ships**:

| Source | Lines | Characters (text) |
|---|---|---|
| `assets/story/lines_en.json`: character dialogue (Milo, Dadi, Gumsum, guardians, friends) | 139 | 7,397 |
| `assets/story/books_en.json`: story narration (Dadi) + Kitabu's questions | 96 | 4,118 |
| `assets/story/say_en.json`: every word, sound, instruction, story sentence the games say | 5,217 | 53,890 |
| **Total** | **5,452** | **≈ 65,400** |

So the right design is the one we already use with Kokoro: **generate every line once on the developer's Mac,
bundle the audio files in the app, play them offline.** ElevenLabs just becomes a better *generator*.

This removes the runtime problems entirely:
* no API key inside the app (an APK can always be unpacked, so a key shipped in it is a key leaked),
* no credits used while children play, no 429/quota errors in front of a child, no internet needed,
* zero latency (files play instantly, lip-sync data computed in advance).

## 1. Quota and credit failure handling

### At generation time (where ElevenLabs is actually called)
`tool/gen_voices.py` gets an `elevenlabs` engine next to `kokoro`. Its behaviour on errors:

| Response | Meaning | What the tool does |
|---|---|---|
| `401` / `quota_exceeded` | Monthly credits used up | **Stop cleanly**, save progress (`.hashes.json`), print "N lines left, resume after the reset". Lines already done stay; the rest keep their Kokoro audio |
| `429` / `too_many_concurrent_requests` | Plan concurrency (free = 2, Starter = 3) | Wait and retry with exponential backoff (1 s, 2 s, 4 s… max 5 tries); run at most *plan-limit* requests at once |
| `5xx`, `system_busy`, timeout | Temporary | Same backoff; then skip the line and report it |
| Network down | — | Stop with a clear message; resume later |

"Mid-sentence" cannot happen: each line is one request, and a line is written to disk only after the full audio
arrived and passed a check (duration > 0.2 s, not silent). Re-running the tool only generates lines whose
text, voice or settings changed (content hash), so nothing is paid for twice.

### At play time (the fallback chain, so the game never freezes)
Already implemented in `AudioManager.voice()`; only one tier is added:

```
1. Bundled ElevenLabs clip   assets/vo/en/<id>.ogg            (new voice files, same names)
2. Bundled Kokoro clip       (what ships today, kept for any line not yet re-voiced)
3. Device text-to-speech     flutter_tts (Speaker)            (any text with no clip)
4. Text only                 subtitles/speech bubble stay on screen; a timer keeps the scene moving
```

Every tier is offline. Each step has a timeout (clip length + 2 s), so a failed tier never blocks the game.

*(Only if a future feature needs **truly dynamic** speech, e.g. saying the child's typed name, would we add a runtime
call. That must go through **our own small server** that holds the key (e.g. a Firebase/Cloud Run function), with an
on-device cache in the app's documents folder. **Never** from the app directly. Not needed for anything planned.)*

## 2. Voice IDs: who picks them

**Claude can do it,** with the team approving by ear:

1. With an API key, the tool lists the available voices (`GET /v1/voices` and the shared Voice Library), filtered
   by description (child-friendly, warm, Indian-English accent where available, age and gender).
2. For each of our 17 roles (Milo, Dadi Kahani, Gumsum, 6 Keepers, 6 friends, Chuchu, the narrator "say" voice, plus
   the v3 jailers), it generates **3 candidates** saying one of that character's real lines (≈ 4,000 credits total).
3. Claude publishes an **audition page** (play buttons, side by side). The team picks one per character, and Claude
   writes the chosen `voice_id` and settings (stability, style, speed) into `tool/voice_cast.json`.

If you already have favourite voices, just send their IDs; that works too.

Note: on the **free plan**, which Voice Library voices can be used over the API is limited (premade voices
always work). We'll see this in step 1.

## 3. API key security

| Rule | How |
|---|---|
| The key is **only on the developer's Mac**, never in the app | The generator is a Mac tool; the Flutter app never sees the key |
| Never committed | `.env` file at the repo root, listed in `.gitignore` (added in step 1). The tool reads `ELEVENLABS_API_KEY` from the environment or `.env` |
| **Not** `--dart-define` | `--dart-define` values are compiled *into* the APK and can be extracted; only use it for non-secret flags |
| Leak guard | A test that fails if any file under `lib/` or `assets/` contains an `sk_`-style key; plus GitHub secret scanning |

**Multiple backup keys:** technically trivial (try key 1, on `quota_exceeded` move to key 2). But **opening several
free accounts to stretch the free credits is against ElevenLabs' terms**, so we won't build that. Multiple keys from
**one paid workspace** (e.g. per team member) are fine and the tool will accept a list.

**Licence:** the free plan is **non-commercial and requires attribution**. For an app we publish, we need at least
the **Starter plan (≈ $5/month, 30,000 credits, commercial rights)**.

## 4. Where it lives (fits the current architecture)

```
tool/
  gen_voices.py          # existing: add --engine elevenlabs|kokoro (per character in voice_cast.json)
  eleven/                # new: small client (requests + retries + quota handling), audition page builder
  voice_cast.json        # existing: add "engine", "voice_id", "settings" per character
.env                     # new, git-ignored: ELEVENLABS_API_KEY=...
assets/vo/en/            # unchanged: <id>.ogg + envelopes.json (lip-sync) + .hashes.json
lib/core/audio.dart      # unchanged API: voice(id, text, character:) / say(text)
```

* **No new Dart service is needed.** The cutscene player, dialogue widgets, Story Quest narration and games already
  call `AudioManager.voice/say`, which plays whatever file is bundled. ElevenLabs files simply replace Kokoro files
  with the **same names**, and the lip-sync envelopes are recomputed by the same tool.
* `SpeechEngine` (the screening's speech *recognition*) is unrelated and unchanged.

## 5. Cost and what to voice with ElevenLabs

| Batch | Characters | Credits (Multilingual v2: 1/char) | Credits (Flash v2.5: ~0.5/char) | Plan |
|---|---|---|---|---|
| Character dialogue + story narration (most noticeable) | ~11,500 | ~11,500 | ~5,800 | Starter, 1 month |
| v3 new lines (≈ 120) | ~6,000 | ~6,000 | ~3,000 | same month |
| All game words/sounds (`say`, 5,217 lines) | ~54,000 | ~54,000 | ~27,000 | Creator for 1 month, or Starter over 2 months |

**Recommendation:** voice **character dialogue and story narration** with ElevenLabs first (biggest quality gain, one
Starter month). **Test the phonics sounds before the `say` bank** ("kuh", "sss", "ar"…): general voices often
pronounce isolated sounds badly. If they do, keep those 200-odd sound clips from Kokoro or record them with a
teacher, and voice only the whole words.

## 6. Step-by-step implementation plan

1. `.gitignore` + `.env` support + leak-guard test.
2. `tool/eleven/client.py`: TTS request (model, voice settings, output 48 kHz), retry/backoff, quota stop.
3. `gen_voices.py`: per-character `engine`, same effects chain (pitch, reverb, loudness) and envelopes; dry-run mode that prints the credit estimate.
4. Voice auditions → audition page → team picks → `voice_cast.json`.
5. Generate batch 1 (dialogue + narration), listen-check, rebuild, device test.
6. Optional: phonics test, then the `say` bank.

**Effort:** about 1 day of work plus your listening time. **Needed from you:** an ElevenLabs account (Starter for
commercial use) and its API key, placed in `.env` on the Mac (not pasted into chat or the repo).
