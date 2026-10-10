# Session handoff — Wordoo (wordoo) · 10 Oct 2026

## 1. Project state
Flutter literacy adventure for Indian children 5–10 (repo `~/code/wordoo`, GitHub `aryanjain281005/wordoo`, branch `main`,
app version `1.2.0+3000`). DALI-style screening → per-skill learner model → 11 games on 7 islands. **Story v3 ("Rescue of
the Story Keepers") is implemented** on top of the v2.1 level system. All 147 tests pass; latest build installed on the
team's Vivo V2130 (USB, adb). Everything is committed and pushed (HEAD `1c0755b`).

## 2. Completed and verified
| Feature | Verified |
|---|---|
| 11 games × 4 levels (same concept, rising difficulty, `lib/engine/levels.dart`); 2nd game unlocks after 2 main-game levels | tests + device |
| Fix "games not accepting answers": intro demo trapped taps/scroll and hid the start button → demo is `IgnorePointer`, tap-to-start, "Let's go!" pinned | device (Sound Orchestra L1+L2, Sound Ninja, Word Detective) |
| Sound Orchestra rhymes by sound (`rhymeFamily` in `en_pack.dart`), one-tap answers, listen-only L3–4 | tests + device |
| Sound Ninja: one-beat words answerable with no cut | tests + device |
| Word Detective: plain signs L1–2, fog L3–4 | tests + device |
| Story Quest first sentence not cut off | device (logcat) |
| Recorded speech bank: 5,217 phrases (`assets/story/say_en.json`, `assets/vo/en/say/`), `AudioManager.say()` with TTS fallback | APK contents |
| **v3 keys**: 1–3 per normal level, 1/3/5 boss, best per level kept; Keeper freed only at max (28 / 14 Castle) | tests (`test/v3_keys_test.dart`) |
| v3 UI: cage + key meter on island sheet, key slots on level tiles, map key pills, reward-screen keys, Keeper roster in Journal | device |
| v3 Storm Trial (`lib/screens/storm_trial.dart`): 30 Qs, pass 21, retry shows weakest skills | tests only |
| v3 scenes: prologue, island_start_<6>, rescue_<6>, trial_warning, trial_retry, finale (softer redemption) | device (prologue, forest start/rescue, trial_warning, finale) |
| Smoothness 55–60 fps on device; layout/a11y/crash-fuzz tests | device + tests |

## 3. Important files changed (this session)
- `lib/engine/campaign.dart`: `IslandState.keys/rescued`, `chapterDone` = all keys (7th island = `trialPassed`), `recordKeys`, `keyLevel`, `recordTrial`, trial fields in JSON, old saves migrate (cleared level → 1 key).
- `lib/engine/levels.dart`: `keysFor`, `maxKeysFor`, `keysPerGame=14`, `trialQuestions/PassMark`.
- `lib/state/app_state.dart`: `completeQuest` returns keys/rescued/trialUnlocked; `completeTrial`.
- `lib/story/cutscene.dart`: engine v2: `video` per shot (`assets/video/<id>.mp4`, muted; code fallback), `card`, `cage`, `burst`, `y`, fx `rain|sparkle|keys|lightning|colour`, bg `art:<id>[~storm]`.
- `lib/story/puppets.dart`: jailers `jailer_<island>` (recoloured Gumsum), `CloudCage`, v3 moods (`milo:injured`, `gumsum:villain|small_sad|redeemed`), mood→happy picture fallback.
- `lib/screens/world_map.dart` (key UI, `_KeeperCage`, island-start scene on first visit, trial entry), `game_screen.dart` (intro fix, rescue scene), `journal.dart` (roster), `reward_modal.dart` (keys).
- `assets/cutscenes/*.json` (v3 scenes), `assets/story/lines_en.json` (+59 `v3_*` lines, voiced), `tool/voice_cast.json` (jailer voices, `gumsum_small`), `tool/gen_voices.py` (shards, skip unspeakable, `cast` override), `tool/export_speech.dart`, `tool/merge_voices.py`.
- Docs: `GAME_DESIGN_V3.md` (approved design), `ANIMATION_PROMPTS.md` (48 AI clips), `ART_PROMPTS.md` §O, `ELEVENLABS_PLAN.md`, `YOUR_TASKS.md`.

## 4. Unfinished / errors / blockers
- **SECURITY:** ElevenLabs key was committed in `7749aed` (`.env`) and pushed. On 10 Oct a NEW key was placed in the gitignored `.env` (never committed/printed), but the **old leaked key still returned HTTP 200 → NOT revoked**. User must delete it in the ElevenLabs dashboard (Developers → API Keys); re-check with a status-only curl. History rewrite not done (moot once revoked). The new key was also pasted in chat — consider rotating it too.
- **ElevenLabs generation not started:** the auto-mode classifier blocks reading `.env` ("Credential Materialization"). Needs a user permission rule. Free plan is non-commercial and too small (10k credits vs ~65k chars).
- Storm Trial **played on device 10 Oct (Vivo V2130, dev panel auto-play 21 → finale, 20 → trial_retry + weakest skills, 12 → result card)**; real tap-through verified for the first 2 questions only. Real-mode save-after-restart (`completeTrial`) is covered by unit tests, **not yet seen on device**.
- Island-start scene did not auto-play on first device open of Sound Forest (probably already marked seen on the phone); unconfirmed.
- Art missing (placeholders work): `char.gumsum.villain/small_sad/redeemed`, `char.milo.injured`, `char.jailer.*`, `prop.cage.*`, `island.citadel`, `bg.citadel`, keys/badges; all 48 videos; talk frames for pip/bolt/coral/jugnu/kalam (uploaded ones were wrong characters, set aside in `art_src/unused/`).

## 5. Decisions and things that failed
- v3 decisions (team): max keys (100%), Trial 30/pass 21, AI video for cinematics, softer Gumsum redemption.
- Voices are **generated offline and bundled**, never called at runtime (no key in app; `--dart-define` is unsafe).
- Size is not a constraint: full-quality art (WebP q94–96), music 128 kbps, voices 64 kbps.
- Failed/avoid: per-line `AudioPlayer` (stutter → one shared player); `stopVoice` in a demo's dispose cut the real narration; global `stopVoice` order race; spelling-based rhymes; ✓-confirm on picture answers; ColorFiltered/blur every frame; old 10-quest chapters that alternated games.
- Phone install needs a higher versionCode than what's installed. arm64 `--split-per-abi` builds get `2000 + build number` (`1.2.0+3000` → 5000; someone had installed 4003). Bump the `+N` in `pubspec.yaml` if adb reports `VERSION_DOWNGRADE`.
- `adb` tap coordinates: screenshots are scaled; use `uiautomator dump` bounds. Helper scripts lived in `$TMPDIR` (not in repo).

## 6. Update 10 Oct (late session)
* **Animation is now fully ours (decision changed):** cutscene engine v3 (`lib/story/cutscene.dart`): fx combos (`"rain+mist"`), 11 new particle fx (fireflies, leaves, notes, mist, rays, letters, lanterns, dust, embers, petals, confetti), sideways pan, shake, letterbox bars, place titles, per-character `delay/act/toX/toY/flip`, timed multi-sound cues, per-scene music. Scenes are generated by `tool/build_scenes.py` (edit there, not the JSON). Sound Forest and Word Village have 7-shot showpiece start + rescue scenes; the other four islands share a 5/5-shot template; prologue (11 shots), trial_warning, trial_retry, finale (7 shots) rebuilt. No AI video needed (the `video` hook still works if clips ever arrive).
* **ElevenLabs implemented** (see `ELEVENLABS_PLAN.md`): all 224 dialogue lines re-voiced. Old keys revoked (verified HTTP 401); new key only in `.env`.
* **SFX:** `tool/gen_sfx.py` synthesises 42 new sounds (drums, marimba, birds, owl, leaves, fireflies, bamboo; stamp, magnifier, pencil, paper, sign creak, market bell, clue chime; thunder, rain, cage, key, colour wave). Wired into Sound Orchestra, Sound Ninja, Word Detective, Word Flash, island ambience (random birds/leaves in Forest, bells/paper in Village) and all cutscenes.
* **Smoothness (Sound Forest + Word Village games).** Biggest finding: `AudioManager.sfx` used audioplayers' `AudioPool` in low-latency mode, which never gets its players back, so **every sound effect created and loaded a new native player (a 50–90 ms stall on the platform thread, plus a leak)**. Now one persistent, pre-loaded `AudioPlayer` per effect (`_sfxPlayer`; replay needs `stop()` first, SoundPool quirk). Also: art decoded at display size (`WordooAssets.provider`; characters were 1300 px for 150 px), `GpuWarmUp` at launch, `ArtWarmUp` per game/cutscene, RepaintBoundaries (Puppet, band, fruit, trail, swarm, lens), blur-free glows, Ninja trail without per-move rebuilds, straight cut intro→play. Dev panel records frame stats (`FRAMESTATS` + event marks in logcat, snackbar). Measured on the Vivo V2130 (idle runs, so adb-injected taps don't distort): Sound Orchestra 0.8 % slow frames (was 4.6 %), Word Detective 3.7 % but worst hitch 57 ms, Sound Ninja 1.1 %, Word Flash 1.8 % (before the audio fix). Baseline raster ≈ 6–9 ms/frame on this GPU (continuous breathing animations keep it at 60 fps); a few 50–85 ms hitches remain. **Not literally zero.** Caution: `adb shell input tap` itself steals CPU and creates fake hitches: measure idle.
* Still to verify on device: Word Village / Ninja / Flash frame stats after the last changes, prologue/finale/village scenes visually.

## 7. Exact next step
1. Re-run frame stats for Sound Ninja, Word Flash, Word Detective, Sound Orchestra on the phone (dev panel → play a quest → close; read the snackbar / `adb logcat -s flutter | grep FRAMESTATS`) and look at the `hitches` lines for what is left.
2. Watch every scene in the dev panel (chips) on the phone; tune shot lengths/positions in `tool/build_scenes.py`.
3. Upgrade ElevenLabs to Starter (commercial use) before release; optionally re-cast with Indian-English voices.

## 8. Hindi demo (11 Oct) — see HINDI_DEMO.md
Bilingual build: when the child picks हिन्दी at set-up, the **prologue, the map page, the Sound Forest island (island sheet, both games, start + rescue animations, reward screen) and the screening** are Hindi; everything else stays English. **English is unchanged** (all English tests pass; English map/game checked on the phone).
* Gate: `AppState.langCode` → `Loc.code`, `AudioManager.lang`, `StoryLines.lang`. `AppState.hindiIsland(i)`/`contentFor(i)`/`packFor(i)` keep other islands English. Interface text via `Tr` + `lib/data/hi_text.dart`.
* Content: `lib/content/hi/hi_pack.dart` (picture words, rhyme families, beats), `assets/story/lines_hi.json` (37 story lines), `assets/story/say_hi.json` (589 words/sounds/instructions).
* Voices: story lines = ElevenLabs (`VOLANG=hi ENGINE=eleven`), words/instructions = Kokoro Hindi (`VOLANG=hi`), files in `assets/vo/hi/`. Phone TTS (hi-IN) speaks the screening and the bridge screen.
* Verified: phone (prologue, map, island sheet, Orchestra + Ninja in Hindi, Hindi clips confirmed loading via frame-stat marks), browser build (fresh set-up → Hindi prologue → bridge → first screening station). Not heard by ear: the Hindi voices.
* Dev panel: English / हिन्दी switch.

## 9. Adaptive screening + Question Agent (see AGENT_FLOW.md)
Three difficulty pools (easy/medium/hard = `SItem.difficulty` 1–3). After each answer the next question comes from: wrong → easy; right but slow / long pause / unclear / replays → medium; right and clean → hard (`lib/screening/adaptive.dart`). Scoring weights answers by pool (0.7/1/1.3). Every answer → `server` (`POST /telemetry`) → Question Agent (Gemini) writes 10 new questions → MongoDB `questions`; app shows the **Question Agent banner** and uses the new questions at once. Finished screenings → `screenings` collection (schema from the brief). Server: `server/` (Node, `npm start`). The MongoDB MCP connector is blocked by the Atlas org (MCP access disabled), so the DB was verified on a local mongod; for Atlas set `MONGODB_URI` in `.env`.

## 10. Audio, map/landing, Whisper (10 Oct, late)
* **Audio:** measured on the phone that the player's "finished" event never fires, so every line waited 2 s of silence; now capped at the clip length + 0.45 s. The phone-voice fallback used to be cut off after a guessed time; it now waits for the sentence to finish (`Speaker.speak` awaits completion). Music ducks to 16 % under speech. All 5,709 clips re-processed by `tool/polish_audio.py` (compression, presence boost, -13 LUFS); Dadi/Gumsum/jailer reverb+echo removed; Dadi story narration (books) re-voiced with ElevenLabs (`INCLUDE_BOOKS=1 ENGINE=eleven`, new key). 172 story words/names that had no clip (taps used the phone voice) were generated (`tool/export_speech.dart` now covers every story word).
* **Map:** `lib/widgets/ambient.dart` – bright animated sea (rainbow, lagoon, petals, clouds, boats, dolphin, fish, gulls, balloon); taps ripple and critters answer with sounds (raw pointer layer, never blocks the islands). **Landing:** sky critters + rainbow + fireworks on tap.
* **Whisper:** see `WHISPER.md`. Needs OpenAI credits (account currently has none; the app uses the phone recogniser until then).
* Keys in `.env` (git-ignored): ELEVENLABS (new account), GEMINI, MONGODB_URI, OPENAI.
