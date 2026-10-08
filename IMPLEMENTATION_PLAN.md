# Readle — Implementation Plan (remaining work)

Primary reference: [`GAME_DESIGN.md`](GAME_DESIGN.md) v2. Newer requirements take priority: no daily limit, no
endpoint, retest only after full seven-island progress, per-skill difficulty from the screening, English-only v1.

## Decisions (approved)

| # | Decision | Status |
|---|---|---|
| 1 | Flutter + **Flame** (no Unity), asset manifest with placeholders, puppet-rig characters, data-driven cutscenes, one game contract | ✅ approved |
| 2 | Hidden **developer debug panel** (jump to any game and step; never changes the child's progress or the retest gate) | ✅ approved |
| 3a | **Kenney** CC0 sound effects, downloaded by Claude | ✅ approved |
| 3b | Free open-source **AI voices** (Kokoro / Piper), generated on the Mac and bundled | ✅ approved |
| 3c | **Pixabay** music: Claude provides a list ([`MUSIC_LIST.md`](MUSIC_LIST.md)); the team downloads it | ✅ approved |
| 3d | Images: Claude writes detailed prompts for every image ([`ART_PROMPTS.md`](ART_PROMPTS.md)); the team generates them; the code uses placeholders until the files arrive | ✅ approved |
| 3e | Rive: no animator available → code-driven **puppet rigs** from layered parts (see below); Rive stays an optional upgrade | ✅ decided |
| 3f | **ffmpeg** installed for audio conversion | ✅ approved |
| 4 | Start with Phase 0 → Phase 1 → Phase 2a | ✅ approved |

### Why not Unity (and no Unity MCP)
Readle's screening, reports, state and personalisation are all Flutter. Unity would mean either a rewrite in C#, or
embedding Unity inside Flutter through an unofficial bridge. Either way that brings two engines, two languages,
+40–80 MB app size and harder debugging. The games are 2D, light-motion and text- and audio-heavy, so **Flame**, a game
engine that runs inside Flutter, covers them while keeping one codebase in Dart.

### Animation without Rive
- Each character is drawn as **separate parts** (body, head, eyes, mouth, ears, tail, arms).
- Code moves the parts: breathing, blinking, tail wag, head tilt, bounce, a happy jump, a sad droop, and mouth
  open/close while a voice line plays (lip-sync from the voice loudness).
- The parts can be code-drawn now, and later replaced by layered PNGs or SVGs generated from `ART_PROMPTS.md`, with no code changes.
- Optional later: a designer can make a Rive file for any character; the character widget will prefer it when present.

## Core architecture

```
GameHost (shared shell: mission card, progress, Milo, story beat, rewards)
  ├─ asks the engine for the next item: ItemGen(skill, step from SkillModel, error focus, least-seen)
  ├─ hands it to the specific game (Hive, Archer, Rocket…) — the only part that differs per game
  └─ receives the result → AppState.recordItem → AppState.completeQuest
Asset manifest (assets/manifest.json): logical id → file; missing file → automatic placeholder
Audio Manager: sound effects, music (with ducking under voices), voice lines; falls back to device TTS
Cutscenes: JSON scripts played by one CutscenePlayer
```

## Roadmap

| Phase | Goal | Main contents | Effort |
|---|---|---|---|
| **0 Groundwork** | Plug-in points for games, assets, audio | Asset manifest + placeholders, Audio Manager, GameHost contract, Flame added, folders, developer debug panel, Kenney SFX | ≈ 2 days |
| **1 Story spine** | Children feel the story | CutscenePlayer, dialogue + voice + lip-sync, puppet characters (Milo, Gumsum, Dadi), prologue, a story beat per quest, Star Bridge, season opener, Explorer's Journal, generated voice lines | ≈ 4 days |
| **2 Six hero games** | Real mechanics from GAME_DESIGN.md | 2a Spelling Hive · 2b Story Quest · 2c Sound Orchestra · 2d Word Detective · 2e Letter Archer (Flame) · 2f Word Rocket (Flame) | ≈ 12–15 days |
| **3 Meta-progression** | Reasons to play for months | Island tier visuals, Story Gems, 11 collections, Explorer's Room, effort gifts, cosy streak | ≈ 4 days |
| **4 Five more games** | All 11 games | 4a Word Flash · 4b Sound Portal · 4c Word Builder · 4d Sound Ninja · 4e Magic Writer ($P handwriting check) | ≈ 10–12 days |
| **5 Art pass** | Final visuals | Swap placeholders via the manifest; style guide | ≈ 3–5 days (+ art production) |
| **6 Audio pass** | Final sound | All voice lines, music (Pixabay), effects, mixing | ≈ 4 days |
| **7 Quality** | Smooth on low-cost Android | 60 fps, app < 100 MB, accessibility, offline, crash-free full cycle | ≈ 3 days |
| **8 Playtest & tuning** | Fun + learning verified | 10–20 children, teacher review, threshold tuning | ≈ 2 days + sessions |
| **9 Hindi (later)** | Phase 2 language | Hindi content pack, stories, voices; enable in `enabledLanguages` | later |

Order: P0 → P1 → P2 → P3 → P4 → (P5, P6 run in parallel whenever assets arrive) → P7 → P8 → P9.

### Done criteria per game
It plays at every step 1–10; it reports every answer to the learner model; it has a demo, hints and a reward;
its tests pass; and it runs smoothly on the Vivo V2130.

## Progress log
- [x] Plan saved, decisions recorded
- [x] Phase 0 — Groundwork (asset manifest + placeholders, Audio Manager, Kenney SFX, GameHost contract, Flame, dev panel)
- [x] Phase 1 — Story spine (cutscene player + 3 scenes, puppet characters with lip-sync, 95 Kokoro voice lines, guardian story beat before every quest, Star Bridge, season opener, Explorer's Journal, dev-panel scene launchers)
- [x] Phase 2a — Spelling Hive (drag or tap bee tiles into a honeycomb that wraps for long words, honey fill + baby-bee hatch, persistent hive growth, sound-aware hints that keep correct cells, scaffold, self-playing demo, tests)
- [x] Art & music batch 1 integrated (tool/prepare_art.py: background removal + front-view extraction; music → looping OGG)
- [x] Phase 2b — Story Quest (comic-book panels per sentence, Dadi narration for all 14 authored stories with word highlighting, tap-a-word, Kitabu asks, look-back help that reopens the answer panel, emotion faces, Story Library to re-read, castle restoration)
- [x] Phase 2c — Sound Orchestra (band on tree stumps, tap-to-hear + ✓ to choose, blend chorus, new Clap-the-Beat syllable rounds, band wakes up layer by layer with music volume + fireflies, sound-specific hints; syllable counter fixed)
- [x] Device validation on the Vivo: fixed audio never playing on devices (assets/assets path), voice waiting/fallback, oversized hatch bee, Story Quest scroll + page fade, cutscene pan edge, Android back on grown-up screens, Journal art, Library tiles
- [ ] Phase 2d — Word Detective
