# Hindi demo (bilingual build)

**Rule: nothing in the English version changes.** Every Hindi switch is gated on the language the child picks at set-up
(`AppState.langCode == 'hi'`). Pick English and the app behaves exactly as before (all English tests still pass).

## What is Hindi when the child chooses हिन्दी

| Part | How it is Hindi |
|---|---|
| Screening test (the "bridge" check) | already had a full Hindi bank: `lib/screening/bank_hi.dart`, titles/instructions in `lib/screening/battery.dart`; spoken by the phone's Hindi voice (`hi-IN`). The bridge intro screen (`lib/screens/adventure.dart`) is Hindi too |
| Prologue story | `assets/story/lines_hi.json` (text) + `assets/vo/hi/<id>.ogg` (ElevenLabs voices); same scene file as English (`assets/cutscenes/prologue.json`) |
| Map page (all islands) | `lib/screens/world_map.dart` via `Tr` / `HiText` (island names, tags, quest board, buttons) |
| Sound Forest island | island sheet, both games (Sound Orchestra "जंगल का बैंड", Sound Ninja "आवाज़ निंजा"), reward screen, start + rescue animations; Hindi words/rhymes in `lib/content/hi/hi_pack.dart`; Hindi voices for every word and instruction in `assets/vo/hi/say/` (Kokoro) |
| Everything else (other 5 islands, Storm Trial, journal, dashboards…) | stays English, on purpose |

## Where things live

* `lib/core/loc.dart` — `Loc.code` (current language) and `Tr` (`tr('Level {n}')` → Hindi only when asked for Hindi).
* `lib/data/hi_text.dart` — all Hindi interface text, character/island/game names. Everyday words, no formal Hindi.
* `assets/story/lines_hi.json` — Hindi story lines (same ids as `lines_en.json`; a line missing here stays English).
* `assets/story/say_hi.json` — every Hindi word / sound / instruction the games speak (made by `tool/export_speech_hi.dart`).
* `assets/vo/hi/` — Hindi recordings; `lib/core/audio.dart` plays a Hindi clip only when Hindi is chosen and the clip exists.
* `lib/content/hi/hi_pack.dart` — Hindi picture words (with rhyme families and beats) for the two Sound Forest games.

## Regenerating voices

```
dart run tool/export_speech_hi.dart                                  # words/instructions -> assets/story/say_hi.json
VOLANG=hi ENGINE=eleven python3 tool/gen_voices.py                   # story lines (ElevenLabs, key in .env)
VOLANG=hi ~/readle-tools/venv/bin/python tool/gen_voices.py          # words/instructions (Kokoro, offline)
```

## Trying it

Real flow: set-up → "Preferred language: हिन्दी". Shortcut: Grown-up Dashboard → long-press the title → the developer panel
has an English / हिन्दी switch, plus every cutscene and game.
