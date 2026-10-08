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

## Tracks

| # | File name | Where it plays | Mood | Search on Pixabay | Pick if… |
|---|---|---|---|---|---|
| 1 | `music.aksharpur.mp3` | World map, menus, story scenes | Wonder, gentle adventure | [indian flute adventure](https://pixabay.com/music/search/indian%20flute%20adventure/) · [bansuri happy](https://pixabay.com/music/search/bansuri%20happy/) | Light bansuri or strings, warm and hopeful, medium-slow, would suit a storybook opening |
| 2 | `music.forest.mp3` | Sound Forest games | Groovy, playful jungle | [tabla playful](https://pixabay.com/music/search/tabla%20playful/) · [jungle kids](https://pixabay.com/music/search/jungle%20kids/) | Clear steady beat (tabla or hand drums), fun but not hectic. A good beat helps rhythm games |
| 3 | `music.valley.mp3` | Symbol Valley games | Festive, bright | [indian festival happy](https://pixabay.com/music/search/indian%20festival%20happy/) · [celebration children](https://pixabay.com/music/search/celebration%20children/) | Festive (dhol, shehnai-like, bells) but soft enough to talk over |
| 4 | `music.ocean.mp3` | Word Ocean games | Curious underwater adventure | [underwater kids](https://pixabay.com/music/search/underwater%20kids/) · [marimba adventure](https://pixabay.com/music/search/marimba%20adventure/) | Bubbly marimba or soft synth pads, a sense of exploring |
| 5 | `music.village.mp3` | Word Village games | Playful mystery | [pizzicato detective](https://pixabay.com/music/search/pizzicato%20detective/) · [sneaky cartoon](https://pixabay.com/music/search/sneaky%20cartoon/) | Tip-toe pizzicato strings, "funny detective", never spooky |
| 6 | `music.treasure.mp3` | Treasure Island games (Spelling Hive) | Jolly, warm | [ukulele happy kids](https://pixabay.com/music/search/ukulele%20happy%20kids/) · [pirate kids](https://pixabay.com/music/search/pirate%20kids/) | Ukulele or accordion, sunny and bouncy, slow enough for concentrating |
| 7 | `music.castle.mp3` | Story Castle games | Storybook, magical | [fairy tale harp](https://pixabay.com/music/search/fairy%20tale%20harp/) · [music box waltz](https://pixabay.com/music/search/music%20box%20waltz/) | Harp, celesta or music box, calm. This plays while children read, so keep it quiet and simple |
| 8 | `music.observatory.mp3` | Star Observatory quests | Dreamy, starry | [space lullaby](https://pixabay.com/music/search/space%20lullaby/) · [dreamy kids ambient](https://pixabay.com/music/search/dreamy%20kids%20ambient/) | Soft twinkly piano or pads, slow, sense of wonder |
| 9 | `music.bridge.mp3` | Star Bridge check-in (the reading check) | Calm, hopeful, focused | [calm piano hopeful](https://pixabay.com/music/search/calm%20piano%20hopeful/) | **Very calm**, sparse piano or pads, no beat. Children speak and listen here, so this must stay in the background |
| 10 | `music.calm.mp3` | Grown-up dashboard and reports | Neutral, calm | [soft background piano](https://pixabay.com/music/search/soft%20background%20piano/) | Simple and unobtrusive |

## Optional later (Phase 2c, Sound Orchestra)
The Orchestra game will add instruments one by one as the child succeeds. For that it needs **one track split into
four parts** (stems), which Pixabay rarely offers. Options:
- Claude cuts four layers from one track with free tools (bass, drums, melody, extras). Quality is OK.
- Or skip stems: the game raises the volume and adds sound effects as the band "wakes up".

Claude will ask about this when Phase 2c starts.
