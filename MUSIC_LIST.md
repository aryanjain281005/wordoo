# Readle — Music to Download (Pixabay)

The app is ready for these tracks: it plays them automatically as soon as the files exist, and stays silent until then.
Every track is free on **[Pixabay Music](https://pixabay.com/music/)** under the Pixabay Content License (commercial use OK, no
attribution required, but the raw files must not be resold on their own).

## How to add a track

1. Open the search link, listen, and pick one track you like (the "Pick if" column tells you what to listen for).
2. Click **Download** (MP3 is fine).
3. Rename the file to the exact **file name** below and put it in `assets/music/`.
4. Tell Claude. Claude will trim it so it loops smoothly, lower the volume to the app's level, convert it to a small
   OGG file and rebuild the app. Please also send Claude the **Pixabay page link** for each track you chose, so it can be recorded in `assets/music/CREDITS.txt`.

**General rules for all tracks:** instrumental only (no singing; children must hear the voices clearly), gentle and
steady, no sudden loud drops, 1–3 minutes long, and nothing scary or too fast.

## Status (9 Oct)

✅ All 10 tracks are in the app. Claude converted them to small looping OGG files (about 1–2 MB each instead of 2–8 MB).
**Still needed from you:** the **Pixabay page link** for each of the 13 tracks you picked, so they can be listed in `assets/music/CREDITS.txt` (good practice, and proof of licence if a store ever asks).

## Which track plays where (all games built so far)

| Game / screen                   | Track                                                           |
| ------------------------------- | --------------------------------------------------------------- |
| Map, menus                      | `music.aksharpur` ✅                                            |
| Sound Orchestra (Sound Forest)  | `music.forest` ✅, which gets louder as the band wakes up       |
| Letter Archer (Symbol Valley)   | `music.valley` ✅                                               |
| Word Detective (Word Village)   | `music.village` ✅                                              |
| Spelling Hive (Treasure Island) | `music.treasure` ✅                                             |
| Story Quest (Story Castle)      | `music.castle` ✅ (→ `music.library` while reading, once added) |
| Star Observatory                | `music.observatory` ✅                                          |
| Check-in / dashboard            | `music.bridge` ✅ / `music.calm` ✅                             |

**All 13 tracks are in the app.** Phase 3 (rewards, room) needs no new music: the room uses the map theme. No new music is needed for the six main games.
(`music.castle` is kept for the Story Castle island screens planned in Phase 3.)

## Second batch (✅ done 9 Oct: story, library, boss)

| #   | File name                                                                                                      | Where it plays                                                | Mood                      | Search on Pixabay                                                                                                                                                         | Pick if…                                                                                              |
| --- | -------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- | ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| 11  | `music.story.mp3`https://pixabay.com/music/main-title-dreamy-land-mysterious-medieval-background-music-249446/ | Under the story cutscenes (prologue, Star Bridge, new season) | Gentle "once upon a time" | [storytelling magical soft](https://pixabay.com/music/search/storytelling%20magical%20soft/) · [fairy tale intro](https://pixabay.com/music/search/fairy%20tale%20intro/) | Soft and slow, harp, celesta or strings, mysterious but warm. Dadi narrates over it, so keep it quiet |
| 12  | `music.library.mp3` https://pixabay.com/music/pop-calm-calm-music-595679/                                      | Story Quest comic books (while the story is read aloud)       | Very calm reading         | [calm reading kids](https://pixabay.com/music/search/calm%20reading%20kids/) · [soft music box](https://pixabay.com/music/search/soft%20music%20box/)                     | Almost ambient, very sparse, no melody that competes with the narration                               |
| 13  | `music.boss.mp3`https://pixabay.com/music/rock-upbeat-rock-137016/                                             | Boss quests (the 10th quest of every chapter)                 | Exciting but friendly     | [kids adventure upbeat](https://pixabay.com/music/search/kids%20adventure%20upbeat/) · [heroic cartoon](https://pixabay.com/music/search/heroic%20cartoon/)               | A bit more energy and drums than the island tracks, still happy, never scary                          |

## First batch (done)

| #   | File name               | Where it plays                           | Mood                         | Search on Pixabay                                                                                                                                                       | Pick if…                                                                                                          |
| --- | ----------------------- | ---------------------------------------- | ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| 1   | `music.aksharpur.mp3`   | World map, menus, story scenes           | Wonder, gentle adventure     | [indian flute adventure](https://pixabay.com/music/search/indian%20flute%20adventure/) · [bansuri happy](https://pixabay.com/music/search/bansuri%20happy/)             | Light bansuri or strings, warm and hopeful, medium-slow, would suit a storybook opening                           |
| 2   | `music.forest.mp3`      | Sound Forest games                       | Groovy, playful jungle       | [tabla playful](https://pixabay.com/music/search/tabla%20playful/) · [jungle kids](https://pixabay.com/music/search/jungle%20kids/)                                     | Clear steady beat (tabla or hand drums), fun but not hectic. A good beat helps rhythm games                       |
| 3   | `music.valley.mp3`      | Symbol Valley games                      | Festive, bright              | [indian festival happy](https://pixabay.com/music/search/indian%20festival%20happy/) · [celebration children](https://pixabay.com/music/search/celebration%20children/) | Festive (dhol, shehnai-like, bells) but soft enough to talk over                                                  |
| 4   | `music.ocean.mp3`       | Word Ocean games                         | Curious underwater adventure | [underwater kids](https://pixabay.com/music/search/underwater%20kids/) · [marimba adventure](https://pixabay.com/music/search/marimba%20adventure/)                     | Bubbly marimba or soft synth pads, a sense of exploring                                                           |
| 5   | `music.village.mp3`     | Word Village games                       | Playful mystery              | [pizzicato detective](https://pixabay.com/music/search/pizzicato%20detective/) · [sneaky cartoon](https://pixabay.com/music/search/sneaky%20cartoon/)                   | Tip-toe pizzicato strings, "funny detective", never spooky                                                        |
| 6   | `music.treasure.mp3`    | Treasure Island games (Spelling Hive)    | Jolly, warm                  | [ukulele happy kids](https://pixabay.com/music/search/ukulele%20happy%20kids/) · [pirate kids](https://pixabay.com/music/search/pirate%20kids/)                         | Ukulele or accordion, sunny and bouncy, slow enough for concentrating                                             |
| 7   | `music.castle.mp3`      | Story Castle games                       | Storybook, magical           | [fairy tale harp](https://pixabay.com/music/search/fairy%20tale%20harp/) · [music box waltz](https://pixabay.com/music/search/music%20box%20waltz/)                     | Harp, celesta or music box, calm. This plays while children read, so keep it quiet and simple                     |
| 8   | `music.observatory.mp3` | Star Observatory quests                  | Dreamy, starry               | [space lullaby](https://pixabay.com/music/search/space%20lullaby/) · [dreamy kids ambient](https://pixabay.com/music/search/dreamy%20kids%20ambient/)                   | Soft twinkly piano or pads, slow, sense of wonder                                                                 |
| 9   | `music.bridge.mp3`      | Star Bridge check-in (the reading check) | Calm, hopeful, focused       | [calm piano hopeful](https://pixabay.com/music/search/calm%20piano%20hopeful/)                                                                                          | **Very calm**, sparse piano or pads, no beat. Children speak and listen here, so this must stay in the background |
| 10  | `music.calm.mp3`        | Grown-up dashboard and reports           | Neutral, calm                | [soft background piano](https://pixabay.com/music/search/soft%20background%20piano/)                                                                                    | Simple and unobtrusive                                                                                            |

## Optional later (Phase 2c, Sound Orchestra)

The Orchestra game will add instruments one by one as the child succeeds. For that it needs **one track split into
four parts** (stems), which Pixabay rarely offers. Options:

- Claude cuts four layers from one track with free tools (bass, drums, melody, extras). Quality is OK.
- Or skip stems: the game raises the volume and adds sound effects as the band "wakes up".

Claude will ask about this when Phase 2c starts.
