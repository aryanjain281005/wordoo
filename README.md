# Readle (wordoo) — A Reading Adventure Just for You

Offline-first Flutter prototype of an adaptive literacy-skill adventure for children (≈6–10).
It measures **six literacy skills**, personalises difficulty and games **per skill**, and re-checks
progress every **week** with fresh items. It is a skill-support tool, **not** a diagnostic tool.

## Run

```bash
flutter pub get
flutter run -d chrome        # or: -d macos / an Android device
flutter test                 # engine + flow tests
```

## Demo script (≈3 min)

1. Landing → *Start Your Adventure* → grown-up setup (or use the **Aarav / Meera** shortcuts for Profile A / B).
2. Explorer avatar → *Your First Adventure* (hidden six-skill assessment) → Skill Map → personalised World Map.
3. Play a mission (e.g. Spelling Hive). Make a few mistakes: hints, retries and level changes appear.
4. Grown-up area (gate: simple sum) → **Demo controls**: *Jump to end of week*, *Play week-1 check-in*
   (fresh items) or *Simulate week-1 results* → report → next-adventure plan → learning loop.
5. Compare Profile A vs Profile B: different map emphasis, day-by-day plan, starting levels.

## Architecture

| Layer | Where |
|---|---|
| Tunable thresholds (90 % / 60 %, window, levels) | `lib/core/config.dart` |
| Skills, 11-game registry, regions, rewards | `lib/data/skills.dart` |
| Language packs (English, Hindi; Kannada placeholder) | `lib/data/lang.dart`, `content_en.dart`, `content_hi.dart` |
| UI strings | `lib/data/strings.dart` |
| Item generation (all six skills, forms A/B/P) | `lib/engine/item_factory.dart` |
| Personalisation / adaptation / daily plan | `lib/engine/personalizer.dart` |
| Reports & observations | `lib/engine/report.dart` |
| App state + localStorage persistence | `lib/state/app_state.dart` |
| Screens / widgets | `lib/screens`, `lib/widgets` |

Playable games: Sound Orchestra, Letter Archer, Word Rocket, Word Detective, Spelling Hive, Story Quest.
The other five (Sound Ninja, Sound Portal, Word Builder, Word Flash, Magic Writer) are registered as locked
future adventures. Adding a language = a new `LangPack`; adding a game = a skin + registry entry.

**Fresh-item rule:** baseline uses pool *A*, week-1 uses pool *B*, daily practice only uses pool *P*.

Fonts: Noto Sans Devanagari (SIL OFL) is bundled so Hindi renders offline.
