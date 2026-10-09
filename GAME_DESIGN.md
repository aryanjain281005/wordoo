# Readle — Game Design Document
## *The Quest for the Lost Words* · खोए शब्दों की खोज

Version 2.0 · Covers: main story, 11 games, characters, cinematics, art & animation assets, voice casting,
sound effects & music, **long-term progression**, **personalisation**, **reassessment**, and the technical plan.

Every game trains **one** literacy skill (from the screening), takes its **difficulty step (1–10) from that skill's
learner model**, and reports **every answer** back. The story is the wrapper; the learning engine underneath is what makes it work.

> **Version 1 is English-only.** All gameplay, stories, dialogue, word lists and audio are English. Hindi lines in this
> document are kept as reference for **phase 2** and are not built now. The architecture keeps language content
> separate, so Hindi can be added without rewriting the engine (§13).

**What changed in v2.0**
| Before (v1.0) | Now (v2.0) |
|---|---|
| 3 missions/day, ~10 min, "Goodnight, Explorer" cap | **No session limit.** An always-full Quest Board; play as long as the child wants |
| Restoring 7 islands = finale = end | Islands **grow in tiers every season**; seasons continue indefinitely (§1.6) |
| Weekly retest (time-based) | Retest opens **only after all seven islands are played through** + enough evidence per skill (§3B) |
| Screening → 3 coarse starting levels (1–3 of 4) | Screening percentile → **starting step 1–7 of 10 per skill**, plus error targets (§3A) |
| Level changes only on streaks | **Per-skill learner model** updated after every answer (§3A) |
| ~50 hand-levelled English words | **Feature-tagged English word database** (770+ words) with automatic difficulty (§3C) |

---

## 0. Design pillars

1. **Story first.** Every game is a chapter of one big adventure. The child is never "doing an exercise" — they are saving a friend, opening a treasure, launching a rocket.
2. **One skill, one fantasy.** Each game's core action *is* the skill (slicing a word into sounds, aiming at the letter you hear, blending fuel cells to launch).
3. **Juicy, never punishing.** Big satisfying feedback for success; mistakes cause a gentle wobble and a hint, never lost lives or "Game Over".
4. **Visible growth.** The world literally regains colour as skills improve. The child *sees* themselves getting better.
5. **Play as long as you like, always meaningful.** No daily cap and no forced stop. There is always a next quest, and every quest is chosen by the learning engine. Ethical design is kept: no ads, no loot boxes, no punishing streaks.
6. **The screening really matters.** Every child starts each skill at a different difficulty, taken straight from their screening profile. There is no global level.
7. **Never-ending, never pointless.** The adventure continues season after season, but every quest still practises a real skill at the right difficulty.
8. **English first, Hindi later.** v1 is fully English; language content lives in packs so Hindi plugs in later.

---

## 1. The main story

### 1.1 World: **Aksharpur (अक्षरपुर)** — the Floating Islands of Words

High above the clouds floats Aksharpur, a ring of seven islands kept alive by sounds, letters and stories.
At the centre stands the **Kahani Vriksh — the Great Story Tree**, whose glowing leaves are words. Every time
someone reads, a new leaf grows, and its light keeps the islands colourful and singing.

### 1.2 The problem

One stormy night, a lonely little cloud called **Gumsum (गुमसुम)** drifts over Aksharpur. Nobody ever read Gumsum a
story, so he thinks words are only for others. Sad and a little jealous, he takes a big breath and **swallows
the sounds, letters and words** of the islands. The music stops, the colours drain to grey, signboards scramble,
and the bridge to the Magic Forest breaks.

### 1.3 The hero

**Milo the fox (मीलो)**, the young Keeper of the Story Tree, opens the Tree's last golden book and calls for help.
Out of the pages tumbles **the Explorer** — the child. In their hand glows the **Reading Lantern (ज्ञान दीपक)**: whenever the
Explorer uses a reading skill, the lantern shines and brings colour back.

### 1.4 The arc (how the whole product is the story)

| Product moment | Story moment |
|---|---|
| Screening (first time) | **Chapter 0 — The Broken Bridge.** Help Milo fix the bridge (already built). The bridge planks are the screening stations. |
| Skill map | Milo's **Map of Aksharpur** appears: the grey islands the Explorer must restore. |
| Playing (any time, any length) | **Levels.** Every game has **4 levels** with the same task and rising difficulty (level 4 of the main game is the boss). An island's **second game unlocks after 2 levels of its main game**. The island sheet shows each game's 4 level tiles (cleared ✓ / play ▶ / locked 🔒); the Quest Board always offers 3 next levels. |
| Getting better at a skill | That island's **restoration %** rises (70 % levels cleared + 30 % real skill growth). Clearing every level on the island earns the island's **Story Gem**. |
| All six skill islands cleared | The 7th island, the **Star Observatory**, opens: 4 mixed "star map" levels that combine every skill. |
| All seven islands played through, with enough evidence per skill | **The Star Bridge appears** (the check-in, fresh screening items). Gumsum floats back, a little lighter each season. |
| After the check-in | **New season.** Every island grows to its next tier (Restore → Grow → Flourish → Shine → Legend), with new quest chapters at the child's new levels. |
| Season 1 ending | **Gumsum learns to read** and becomes **Gunjan (गुंजन), the Humming Cloud**. The story continues: Gunjan's cousins from the Other Side of the Clouds arrive in season 2. |

There is **no scary villain**. Gumsum is mischievous, sneezes letters, giggles, and is secretly lonely — a redemption story about sharing reading.

### 1.5 The seven islands

| Island | Skill | Guardian(s) | Games |
|---|---|---|---|
| 🌲 **Sound Forest** (ध्वनि वन) | Phonological awareness | Maestro Bhalu & the Jungle Band · Pip the Ninja | 1 Sound Orchestra · 2 Sound Ninja |
| 🏹 **Symbol Valley** (अक्षर घाटी) | Letter–sound | Arya the Archer & Garud the eagle · Bolt the robot | 3 Letter Archer · 4 Sound Portal |
| 🌊 **Word Ocean** (शब्द सागर) | Decoding | Captain Kachhua (turtle) · Coral the octopus | 5 Word Rocket · 6 Word Builder |
| 🏘️ **Word Village** (शब्द नगरी) | Word recognition | Inspector Ullu & Chuchu · Jugnu the firefly | 7 Word Detective · 8 Word Flash |
| 🏝️ **Treasure Island** (खज़ाना द्वीप) | Spelling / writing | Queen Madhu the bee · Captain Kalam the parrot | 9 Spelling Hive · 10 Magic Writer |
| 🏰 **Story Castle** (कहानी महल) | Comprehension | Princess Pari & Kitabu the talking book | 11 Story Quest |
| 🔭 **Star Observatory** (7th island) | All six skills, mixed | Milo & Gumsum | Star Observatory (mixed review); gateway to the **Star Bridge** check-in |

### 1.6 Levels (v2.1, replaces the 10-quest chapters)

| Rule | Detail |
|---|---|
| 4 levels per game | Same concept on every level; only the difficulty rises (see `lib/engine/levels.dart` for each game's 4 level names and steps) |
| Order | Levels open one after another; a level is **cleared** with at least half the answers right first time, otherwise "Almost! Play it again" |
| Second game | Unlocks after **2 cleared levels** of the island's main game (e.g. Sound Ninja after 2 levels of Sound Orchestra) |
| Screening | A child who clearly knows the first levels already has up to 2 levels per game marked "You know it ⏩" (never more, so every game is played) |
| Adaptation | The learner model still adapts the scaffolding, hints and error focus inside a level; the level fixes the task and its difficulty band |
| Seasons | Every level restarts a little harder each season |

### 1.7 Long-term structure (never a final screen)

```
Season (story arc, e.g. 1 "The Lost Words", 2 "The Whispering Winds", 3 "The Starlight Library" …)
  └─ 7 islands, each at a tier: Restore → Grow → Flourish → Shine → Legend → Legend 2 …
       └─ Games: 1–2 per island × 4 levels each (same task, rising difficulty; main game level 4 = boss) · 4 star maps
            └─ Quest = one game round (5–8 items) + one story beat
```

- **Islands evolve instead of ending.** Each season the island grows (a village becomes a town, the reef becomes a city, the hive gets more floors), so restoring an island isn't the end.
- **After a chapter is done** the island still offers **Bonus quests** (where the learning evidence is thin) and **Echo quests** (spaced review of earlier skills), so play never stops.
- **Seasons repeat the cycle at higher difficulty:** play → check-in → new season. The story keeps going (new arcs, new characters), and the learning keeps going (new levels, new error targets).

---

## 2. The cast

### 2.1 Main characters

| Character | Who they are | Personality | Look | Catchphrases (EN / HI) |
|---|---|---|---|---|
| **The Explorer** | The child's own avatar | Brave, curious | Customisable (hair, outfit, hats); carries the Reading Lantern and a backpack | — |
| **Milo the Fox** (मीलो) | Keeper of the Story Tree, the child's companion | Cheerful, a bit clumsy, loves puns, never gives up | Orange fox, white cheek tufts, green scarf, tiny satchel of leaves | "Ready, Explorer?" / "तैयार हो, खोजी?" · "Let's solve this together!" / "चलो मिलकर करते हैं!" |
| **Gumsum the Hush Cloud** (गुमसुम) | The lonely cloud who swallowed the words | Mischievous, giggly, secretly sad | Small grey cloud with big eyes; letters float inside him; gets lighter each week | "Hee-hee! Words are only for others…" / "हीही! शब्द तो दूसरों के लिए होते हैं…" |
| **Dadi Kahani** (दादी कहानी) | Narrator of every cinematic; the Story Tree's spirit | Warm, wise, funny grandmother | Glowing outline in the bark of the Story Tree; shawl made of leaves | "A long, long time ago, in Aksharpur…" / "बहुत समय पहले, अक्षरपुर में…" |

### 2.2 Island guardians

| Game | Character | Personality | Look |
|---|---|---|---|
| Sound Orchestra | **Maestro Bhalu** (bear conductor) + **Tinku** (tabla monkey), **Koyal** (flute bird), **Gajju** (drum elephant) | Dramatic, loves music; band members are silly | Bear in a red kurta with baton; band in tiny vests |
| Sound Ninja | **Pip the Red Panda** | Fast, cool, secretly scared of the dark | Red panda in a black ninja band, leaf-sword |
| Letter Archer | **Arya the Archer** + **Garud** (eagle) | Confident, kind; Garud is cheeky | Girl in a purple tunic, golden bow; eagle with a scarf |
| Sound Portal | **Bolt the Portal Robot** | Talks in beeps, mixes words when nervous | Round tin robot, antenna light, one wobbly wheel |
| Word Rocket | **Captain Kachhua** (turtle) | Old sea captain, says "Bubbles and barnacles!" | Turtle with captain's hat, rocket-submarine "Bubble Rocket" |
| Word Builder | **Coral the Octopus** | Busy builder, eight tools at once | Pink octopus with a hard hat and tool belt |
| Word Detective | **Inspector Ullu** (owl) + **Chuchu** (mouse) | Ullu is serious and dramatic; Chuchu is a nervous snack-lover | Owl with deerstalker hat and magnifier; mouse with notebook |
| Word Flash | **Jugnu the Firefly** | Speedy, giggly, glows brighter when happy | Tiny firefly with a lantern tail |
| Spelling Hive | **Queen Madhu** (bee) | Regal but kind, hums when thinking | Bee with a honey-drop crown |
| Magic Writer | **Captain Kalam** (pirate parrot) | Loud, poetic pirate with a magic quill | Parrot with eye-patch, feather quill as a sword |
| Story Quest | **Princess Pari** + **Kitabu** (talking book) | Pari is adventurous; Kitabu is a forgetful, funny book | Princess with a lantern crown; book with eyes and page-arms |

---

## 3. The 11 games

Common rules for every game:
- **Length:** set by the quest type, not the clock: Explore/probe 6 · Gentle 5 · Adventure 6 · Challenge 8 · Boss 8 items. There is **no daily limit**.
- **Structure:** 15–30 s cinematic intro (first time) → 10 s "Watch me!" demo → play → celebration → island restoration % goes up.
- **Difficulty:** each skill has a **10-step ladder**. The step comes from that skill's learner model and is re-estimated **after every answer** (§3A). The "Lv 1–4" lists below are the four bands of that ladder (steps 1–3, 4–6, 7–9, 10).
- **Mistakes:** gentle wobble, "Almost! Let's listen again", one option fades. Never a fail screen.
- **Reports:** every answer sends `ItemResult` (correct, ms, error tag) to the engine.

---

### Game 1 · 🎻 Sound Orchestra — *"The Jungle Band Lost Its Rhythm"*
**Skill:** Phonological awareness (syllables, rhyme, first sound, blending) · **Island:** Sound Forest

**Cinematic intro (25 s)**
1. *Wide shot:* the forest at dusk, grey and silent. Instruments lie on tree stumps, drained of colour.
2. *Close-up:* Maestro Bhalu's baton droops. "My band… they've forgotten every beat!"
3. Gumsum peeks from behind a tree, burps a little "♪" and giggles away.
4. Milo: "The band needs to *hear* the sounds again. Explorer, can you lead them?"
5. The Explorer lifts the Reading Lantern; one firefly lights up. Title card: **SOUND ORCHESTRA**.

**Gameplay**
A stage of tree stumps. Each band member sings or plays a word. The child conducts:
- **Lv 1 — Clap the Beat:** Koyal sings "ba-na-na"; tap Gajju's drum once per syllable.
- **Lv 2 — Rhyme Duet:** two animals sing words; tap the one that rhymes with the Maestro's word so they harmonise.
- **Lv 3 — Lead Note:** "Who starts with /m/?" Tap the animal whose word starts with that sound.
- **Lv 4 — Blend Chorus:** each animal sings one sound (/k/ /a/ /t/); tap the picture the chorus makes.

**The hook — adaptive soundtrack:** every correct answer adds a music layer (tabla → flute → drum → full band).
By challenge 5 the whole forest is playing a song, and fireflies swirl in time.

**Scaffolding:** the animal glows and repeats slowly; the extra choice fades out.
**Reward:** a concert finale; collect **Band Stickers**; the forest regains colour.

**Assets**
- *Background:* forest stage at dusk, 3 parallax layers, grey and colour versions.
- *Characters:* Bhalu, Tinku, Koyal, Gajju. Animation states: idle, sing, play, happy-bounce, confused, cheer.
- *Props:* tree-stump stage, instruments (tabla, bansuri flute, dhol drum), fireflies, music-note particles.
- *UI:* beat ring for syllable taps, picture cards.

**Audio**
- *Music:* "Forest Groove" in 4 stems (tabla, bansuri, dhol, strings) that layer in.
- *SFX:* drum hit (×3 pitches), flute trill, note sparkle, firefly chime, crowd cheer (animals), gentle "boop" for a miss.

---

### Game 2 · 🥷 Sound Ninja — *"Pip and the Sound Fruits"*
**Skill:** Phonological awareness (segmenting, deleting and swapping sounds) · **Island:** Sound Forest

**Cinematic intro (20 s)**
1. *Night dojo in the bamboo grove.* Fruit trees hang heavy with glowing sound-fruits.
2. Gumsum has tied the sounds together, so the fruits are stuck on the branches and the forest animals are hungry.
3. Pip flips in: "A true ninja hears every piece of a word!"
4. Pip throws the Explorer a leaf-sword. Title: **SOUND NINJA**.

**Gameplay**
Picture-fruits fly up (fruit-ninja style, slow and calm). The voice says the word. The child **swipes to slice the word into its sounds**.
- **Lv 1 — Syllable slice:** "ba-na-na" → slice 2 times → 3 pieces, each saying its syllable.
- **Lv 2 — Onset / rime:** "s | un" → one slice in the right place.
- **Lv 3 — Phoneme slice:** "f | i | sh" → slice into every sound.
- **Lv 4 — Swap master:** slice off /s/ from "sun", catch the /b/ piece from the basket → it becomes "bun"! (deletion and substitution)

**Juice:** slow-motion slice, petal burst, combo counter that never resets on a mistake (it just pauses).
**Scaffolding:** dotted slice guides appear, and Pip says the word in slow motion.
**Reward:** the fruits fall into the animals' baskets; earn **Ninja Belts** (white → black).

**Assets**
- *Background:* bamboo dojo at night with moon and lanterns.
- *Character:* Pip — idle, ready, slice, flip, celebrate, scared-of-dark gag.
- *Props:* picture-fruits (one per word) with split pieces, sword trail, fruit baskets.
- *VFX:* slice trail, petal burst, juice splash.

**Audio**
- *SFX:* whoosh (light and heavy), slice "shing", fruit pop, piece-landing plop, gong for a combo.
- *Music:* soft taiko + flute loop.

---

### Game 3 · 🏹 Letter Archer — *"The Festival of Flying Lanterns"*
**Skill:** Letter / akshara–sound matching · **Island:** Symbol Valley

**Cinematic intro (25 s)**
1. *Valley at night.* The Lantern Festival should be today, but every sky-lantern is dark.
2. Gumsum sneezes and letters scatter onto the lanterns in a jumble.
3. Arya: "Each lantern lights only if we hit it with the right sound-arrow."
4. Garud swoops down, drops a golden arrow at the Explorer's feet. Title: **LETTER ARCHER**.

**Gameplay**
A sound plays ("/b/", or "का"). Lanterns float with letters on them. **Drag back on the bow (slingshot), aim, release.** A hit makes the lantern burst into its colour and float up to light the valley.
- **Lv 1:** 3 still lanterns, very different letters.
- **Lv 2:** slowly drifting lanterns with look-alikes (b / d / p · ब / व).
- **Lv 3:** digraphs and matras (sh / ch / th · का / कि / की).
- **Lv 4:** vowel teams / conjuncts (igh, ph · क्ष, त्र) with a light breeze.

**Hook:** a **Golden Lantern** appears after 3 hits in a row — hitting it releases fireworks shaped like the Explorer's name.
**Scaffolding:** the wind stops, an aiming arc appears, the wrong lanterns dim.
**Reward:** the valley sky fills with your lanterns; collect **Lantern Colours** to decorate your room.

**Assets**
- *Background:* night valley with mountains, a river reflecting lantern light.
- *Characters:* Arya — aim, release, cheer; Garud — fly, perch, laugh.
- *Props:* bow with a stretch animation, arrows, paper lanterns with letter slots.
- *VFX:* arrow trail, lantern burst, fireworks.

**Audio**
- *SFX:* bow creak (drag), twang (release), arrow whoosh, lantern "pop-glow", firework crackle, soft "thunk" for a miss.
- *Music:* festive dhol + shehnai-lite loop.

---

### Game 4 · 🌀 Sound Portal — *"Bolt's Broken Portals"*
**Skill:** Letter–sound patterns (multiple spellings, matra forms) · **Island:** Symbol Valley

**Cinematic intro (20 s)**
1. *Bolt's workshop* of humming portal rings.
2. ZAP! Gumsum floats through the portals and tangles all the wires.
3. Bolt's antenna sparks: "Beep! Sounds… and symbols… CROSSED! Help-beep!"
4. Title: **SOUND PORTAL**.

**Gameplay**
A puzzle board. On the left, **sound orbs** (tap to hear). On the right, **symbol portals**. **Drag an energy beam** from each sound to its matching symbol. When every pair is connected, a little critter rides through the portal chain.
- **Lv 1:** 3 pairs, single letters.
- **Lv 2:** 4 pairs including look-alikes.
- **Lv 3:** one sound with two spellings (/f/ → f and ph · the same vowel on different consonants: का, मा, ना).
- **Lv 4:** tricky patterns (silent letters, conjuncts) with a bonus "chain" puzzle.

**Scaffolding:** the correct portal hums when the right orb is held near it.
**Reward:** Bolt dances; each solved board repairs one gear of his machine. Collect **Portal Critters**.

**Assets**
- *Background:* steampunk-cute workshop.
- *Character:* Bolt — idle wobble, beep-talk, spark-panic, dance.
- *Props:* sound orbs, portal rings in 6 colours, energy beams, critters.
- *VFX:* electric arcs, portal swirl.

**Audio**
- *SFX:* orb hum (pitched per orb), beam connect "zzt-click", portal whoosh, gear clunk, robot beeps (as Bolt's voice layer).
- *Music:* bouncy electronic loop with a santoor melody.

---

### Game 5 · 🚀 Word Rocket — *"Captain Kachhua's Bubble Rocket"*
**Skill:** Decoding (blending written sound units) · **Island:** Word Ocean

**Cinematic intro (30 s)**
1. *Underwater harbour.* The Bubble Rocket, a rocket-submarine, sits empty.
2. Captain Kachhua: "Bubbles and barnacles! Gumsum dropped the **Pearl of Sounds** into the deepest trench!"
3. "The Rocket runs on **word fuel**: blend the sound-cells and she flies!"
4. The engine sputters, then roars as the first cell clicks in. Title: **WORD ROCKET**.

**Gameplay**
Fuel cells slide in with sound units (`c | a | t`). Tap each cell to hear it, then **swipe up to blend**: the cells slide together like a zip, and the sounds merge as you swipe. Pick the matching picture (or, in voice mode, **say the word**, using the screening's speech engine) → *BOOST!* The rocket dives to the next ocean zone.
- **Lv 1 — Sunlight Zone:** CVC words (cat, sun).
- **Lv 2 — Twilight Zone:** blends and digraphs (ship, frog · मोर, केला).
- **Lv 3 — Deep Zone:** two syllables (rocket · बंदर).
- **Lv 4 — Alien Trench:** made-up words, framed as **names of alien sea creatures** ("Meet the *blick*!"). This gives a story reason to read nonwords.

**Hook:** each zone reveals new glowing creatures; the Pearl gets closer on a depth meter.
**Scaffolding:** cells light up one by one while the sounds play slowly; the swipe slows down.
**Reward:** the Pearl of Sounds; creature cards in the **Sea Log**.

**Assets**
- *Backgrounds:* 4 ocean zones (light → dark, bioluminescent).
- *Characters:* Captain Kachhua — steer, laugh, worry, salute.
- *Props:* Bubble Rocket with boost and idle animations, fuel cells, creatures (anglerfish, jellyfish, alien "blick").
- *VFX:* bubbles, boost flame, depth-meter UI.

**Audio**
- *SFX:* cell click, sound-merge "whoomp", engine rumble, BOOST whoosh, bubbles, sonar ping (zone change).
- *Music:* adventure loop that gets deeper and mysterious per zone.

---

### Game 6 · 🧱 Word Builder — *"Coral's Reef City"*
**Skill:** Decoding (building unfamiliar words from parts) · **Island:** Word Ocean

**Cinematic intro (20 s)**
1. *The Reef City in ruins*; the coral is grey.
2. Coral the octopus, holding 8 tools: "Every reef creature is born from a **name**. Build a name, and the creature hatches!"
3. Title: **WORD BUILDER**.

**Gameplay**
Sound blocks float in the water. The voice says a new (often made-up) word, or the picture of a strange creature appears. **Drag the blocks into the reef slot in order**; each block sounds as it locks. A creature **hatches from the coral**, named after the word ("a *zug*-fish!"), and swims off into the city.
- **Lv 1:** 2 blocks.
- **Lv 2:** 3 blocks with blends.
- **Lv 3:** syllable blocks.
- **Lv 4:** longer made-up words with extra distractor blocks.

**Hook:** the **Reef-o-pedia**, a collection of silly creatures the child named. The reef city grows with every creature.
**Scaffolding:** a ghost outline shows the number of blocks; the first block is placed.
**Reward:** a new creature, more reef colour, and Coral's victory dance.

**Assets**
- *Background:* reef city (grey → colourful states).
- *Character:* Coral — build, hammer, cheer, juggle.
- *Props:* sound blocks, coral slots, 40+ procedurally coloured creatures (body + eyes + fins combinations).
- *VFX:* hatch burst, bubble trail.

**Audio**
- *SFX:* block snap (pitch rises per block), coral crack, hatch "plip!", creature squeaks (random set), cheer.
- *Music:* playful marimba loop.

---

### Game 7 · 🕵️ Word Detective — *"The Case of the Switched Signs"*
**Skill:** Word recognition (fast, accurate familiar words) · **Island:** Word Village

**Cinematic intro (25 s, noir-but-cute)**
1. *Rainy village street.* Signboards read "BAKREY", "SCOOL"; the villagers are lost.
2. Inspector Ullu turns dramatically: "A mystery! Someone switched the words."
3. Chuchu (eating a laddoo): "C-c-could it be a ghost?!"
4. A wisp of grey cloud vanishes around a corner. Title: **WORD DETECTIVE**.

**Gameplay — every round is a mini mystery** ("Who took the mangoes?")
- The village scene is shown. **Drag the magnifier** over signs, posters and letters.
- The voice says a word; find the **correctly written** one among look-alikes to collect a **clue card**.
- 3 clues → **accuse the culprit** from 3 suspects → cute reveal (*"It was the goat… he just wanted a snack!"*).
- **Lv 1:** clearly different words. **Lv 2:** same first letter. **Lv 3:** visual confusions (b/d, swapped letters, wrong matra). **Lv 4:** more signs on screen, gentler "case clock".

**Scaffolding:** the magnifier glows near the right area; the word is spoken slowly.
**Reward:** a **Case File** collection, Detective Badges (Rookie → Chief Inspector), and the village signs fixed.

**Assets**
- *Background:* village street in 3 variants (market, school, temple square), rain and sunny versions.
- *Characters:* Ullu — think, point, dramatic turn; Chuchu — scared, eat, cheer; 6 suspect animals.
- *Props:* signboards, posters, letters, magnifier, clue cards, case-file folder.
- *VFX:* magnifier lens distortion, clue sparkle.

**Audio**
- *SFX:* magnifier swish, clue "ding-ding", case-solved jingle, rain ambience, footsteps, Chuchu squeak.
- *Music:* cute detective theme (pizzicato strings + soft sitar).

---

### Game 8 · ⚡ Word Flash — *"Jugnu's Night Bazaar"*
**Skill:** Word recognition (instant recognition, orthographic memory) · **Island:** Word Village

**Cinematic intro (15 s)**
1. *The Night Bazaar*, dark and empty.
2. Jugnu zips in: "My firefly friends carry words, but only for a blink! Catch them and the bazaar lights up!"
3. Title: **WORD FLASH**.

**Gameplay**
A firefly swarm forms a word in light for a moment, then scatters. The child taps **the stall jar with the same word** among similar ones.
- **Lv 1:** 2 s flash, different words.
- **Lv 2:** 1.5 s, same first letter.
- **Lv 3:** 1 s, close look-alikes.
- **Lv 4:** 0.6 s, a longer word.

**Hook:** every catch lights a stall (chai stall, bangle shop, kite shop…); a full bazaar at night is beautiful.
**Scaffolding:** "Flash again" button (free), slower flash.
**Reward:** bazaar decorations; Jugnu glows brighter.

**Assets**
- *Background:* night market with 10 stalls (dark and lit states).
- *Character:* Jugnu — zip, giggle, glow-pulse.
- *Props:* firefly swarm (particle system forming letters), glass jars with labels, lanterns.
- *VFX:* swarm-to-word morph, jar glow.

**Audio**
- *SFX:* swarm buzz-chime, flash "fwip", jar catch "tink", stall light-up "whomp + crowd murmur".
- *Music:* night-market loop (light tabla, crickets).

---

### Game 9 · 🐝 Spelling Hive — *"Queen Madhu's Honey Kingdom"*
**Skill:** Spelling (letter / akshara + matra building) · **Island:** Treasure Island

**Cinematic intro (25 s)**
1. *A giant golden hive in a flowering tree*, with empty cells.
2. Queen Madhu: "The baby bees can only hatch in **honey-word cells**… but Gumsum blew our letters away!"
3. Worker bees zoom in, each carrying a letter tile. Title: **SPELLING HIVE**.

**Gameplay**
The voice says a word (picture shown). Bees carry letter or akshara/matra tiles. **Drag tiles into the honeycomb slots.** Correct → honey pours into the cells, glows, and **a baby bee hatches**.
- **Lv 1:** 3-letter words (2 extra tiles).
- **Lv 2:** digraphs / matras (ship, पानी).
- **Lv 3:** longer words.
- **Lv 4:** tricky spellings (silent e · conjuncts, chandrabindu) with close distractors (the wrong matra).

**Error-aware help:** if the matra is wrong, only that cell turns pale and Queen Madhu hums *"Listen to the end sound…"*. Correct cells stay locked in (green).
**Hook:** the **hive grows** with every hatched bee; bees fly around the island and visit your room.
**Reward:** baby bees and honey jars (a currency for room decoration).

**Assets**
- *Background:* hive interior and exterior, flowering tree.
- *Characters:* Queen Madhu — hum, think, cheer; worker bees (carry); baby bee (hatch, wiggle).
- *Props:* honeycomb slots, tiles, honey pour.
- *VFX:* honey fill (shader or animated mask), hatch sparkle.

**Audio**
- *SFX:* bee buzz (carry), tile snap, honey pour "gloop", hatch "pop-squeak", Queen hum.
- *Music:* warm acoustic loop with a buzzing-bass motif.

---

### Game 10 · ✨ Magic Writer — *"Captain Kalam's Treasure Runes"*
**Skill:** Writing (letter formation, writing dictated words) · **Island:** Treasure Island

**Cinematic intro (25 s)**
1. *Pirate cove at sunset.* Treasure chests are locked with glowing runes.
2. Captain Kalam lands with a flourish: "Arr! Only a true writer can open these chests! My magic quill obeys the hand that writes true!"
3. He tosses the quill to the Explorer. Title: **MAGIC WRITER**.

**Gameplay**
A rune (a letter, akshara or word) glows on the chest lid. The child **traces with a finger**; the quill leaves sparkling ink.
- **Lv 1:** trace a letter with dotted guides and stroke-order arrows.
- **Lv 2:** trace without guides (only start dots).
- **Lv 3:** write a dictated short word (with letter-tile hints).
- **Lv 4:** write a dictated 2–3-word line.

Stroke checking uses an on-device shape recogniser (template matching, like the $1/$P recognisers) with gentle tolerance.
**Hook:** chests open with different treasures (avatar gear, pirate hats, room items); a **Treasure Map** fills in as runes are written.
**Scaffolding:** a ghost stroke animates; the start dot pulses.
**Reward:** treasure plus a written word added to the child's **Rune Book**.

**Assets**
- *Background:* cove at sunset, ship, sand.
- *Character:* Kalam — flourish, squawk, write-air, laugh.
- *Props:* chests (5 designs), runes for every EN letter and HI akshara/matra, a stroke-order data file, quill.
- *VFX:* ink sparkle trail, chest burst.

**Audio**
- *SFX:* quill scratch (loop while drawing), stroke-complete chime, lock click, chest creak-open, coin shower, parrot squawk.
- *Music:* jolly pirate loop (accordion + dhol).

---

### Game 11 · 📖 Story Quest — *"The Living Books of Story Castle"*
**Skill:** Reading comprehension (detail, sequence, cause/effect, inference, prediction) · **Island:** Story Castle

**Cinematic intro (30 s)**
1. *The castle library*, its books floating but silent.
2. Princess Pari: "Gumsum ate the **endings** of all our stories! The characters are stuck forever!"
3. Kitabu the book flaps open: "Oh, I remember my beginning… but not my middle… or my end!"
4. A page glows; the Explorer and Milo are sucked inside. Title: **STORY QUEST**.

**Gameplay — interactive comic books**
- Each book is a 4–6 panel story. Text is shown with **karaoke highlighting** as it is read aloud (optional). **Tap any word to hear it.**
- Between panels the child makes choices that need understanding:
  - **What happened?** Tap the right picture (detail).
  - **Put the panels in order** by dragging (sequence).
  - **Why did it happen?** (cause / effect)
  - **How does she feel?** Pick the emotion face (inference).
  - **What happens next?** Choose the ending (prediction). The book plays the chosen ending; a sensible choice restores the "true" ending, while a silly one gives a funny scene and a gentle second chance.
- **Lv 1:** 3 panels, picture answers. **Lv 2:** 4 panels with a sequence question. **Lv 3:** 5 panels with cause/effect. **Lv 4:** 6 panels with inference and prediction, less read-aloud support.

**Hook:** each finished book restores a castle tower; books become a re-readable **Library** with the child's stickers.
**Reward:** a castle tower, a Library book, and Kitabu remembering his own story (a running gag).

**Assets**
- *Background:* library hall, then book-world backgrounds (jungle, market, sea, school, sky).
- *Characters:* Pari — talk, point, cheer; Kitabu — flap, think, laugh; story characters reused from other islands.
- *Props:* comic panels, page-turn frames, emotion faces, castle towers.
- *VFX:* page-turn, word-highlight glow, "story restored" swirl.

**Audio**
- *SFX:* page flip, book "whoosh-in", word-tap tick, choice "chime", ending fanfare, tower rebuild "clink-clink".
- *Music:* storybook waltz; each book has a short themed motif.
- *VO:* full narration of each story (Dadi Kahani), plus character voices for dialogue.

---

## 3A. Personalisation (the most important system)

### From screening to the first quest
| Screening percentile (per skill) | Starting step (of 10) |
|---|---|
| < 5 | 1 |
| 5 – 15 | 2 |
| 16 – 30 | 3 |
| 30 – 50 | 4 |
| 50 – 70 | 5 |
| 70 – 85 | 6 |
| > 85 | 7 (headroom left above) |

- Each of the six skills gets **its own** starting step. A child can start Word Village at step 6 and Treasure Island at step 1.
- **Screening error tags seed practice targets.** For example, *Wrong vowel* → Spelling Hive adds vowel contrasts; *Similar-letter confusion* → Letter Archer serves b/d/p/q.
- **Skills not measured** (no voice permission) start conservatively and get extra calibration quests. They are never guessed as strong.
- **The first 2 quests on each island are "Explore" (calibration) quests** with bigger difficulty jumps, so a wrong starting point corrects itself within minutes.

### During play: the per-skill learner model
For each skill the engine keeps:

| Field | Use |
|---|---|
| θ (ability) | Updated after **every** answer: `θ ← θ + K·(result − expected)`, with `expected = 1/(1+e^−(θ − item difficulty))` (a lightweight Elo / IRT rating) |
| Step served | Chosen so the child is expected to succeed about **78 %** of the time: hard enough to grow, easy enough to enjoy |
| Smoothed accuracy and response time | Detects "right but slow" (needs fluency practice before moving up) |
| Error tags that fade over time | A tag that repeats becomes a **practice target**; it fades once the child gets it right consistently |
| Trend over recent quests | Status shown to grown-ups: *Finding the right level · Needs extra support · Practising steadily · Improving · Ready for a challenge* |
| Items seen | Least-seen items are chosen first; no repetition of the same questions |

**Behaviour:**
- **Ready for a challenge** → Challenge quests (more items, bonus stars).
- **Struggling** → Gentle quests: hints on, shorter rounds, one choice removed, first tile placed.
- **Repeated error** → targeted content until the error fades.
- **Every answer** can move the step, so difficulty changes inside a round ("Power up!" or a friendly warm-up).

### Strong and weak skills together
- There is **no global level** anywhere, including the UI. Power pips and steps are per skill.
- The Quest Board shows **the highest-need skill first, a middle skill, and a stretch quest for a strong skill**, interleaved so the child never gets only weak-skill rounds.
- The map shows weak skills as bigger, glowing islands; strong skills get the ✨ "advanced" look.

## 3B. Reassessment (Star Bridge check-in): unlocked by progress, never by time

The check-in becomes available **only when all are true**:
1. All **six skill islands** have every level cleared for this season (4 levels per game; 8 on islands with two games).
2. The **Star Observatory** (7th island) has finished its 6 mixed star maps.
3. **At least 60 scored answers per skill** in this cycle.
4. **Each skill's level has settled** (its ability estimate changed little over the last 3 quests).

- There are **no dates, timers or day counters**, and **no manual override**.
- The grown-up dashboard shows a checklist of what is still needed.
- The check-in uses **fresh screening items**: the least-used items across all question forms are chosen first.
- After the check-in, the fresh screening result is blended with what gameplay knows (60 % screening, 40 % gameplay) to set the new starting steps. Then the next season begins.
- In simulation, a full cycle is about **66 quests (~430 answers)**, roughly 2.5–3.5 hours of play.

## 3C. English content database (automatic difficulty)

- **770+ English words**, 240+ with a unique picture. Each word is tagged automatically:
  - grapheme units (sh, ee, igh, tch …)
  - syllables
  - digraphs
  - consonant blends
  - vowel teams
  - silent-e
  - whether it is a common word
  - whether it is irregular (not fully decodable)
- **Difficulty (1–10)** is calculated from those features, with no hand-assigned levels. For example: cat 1 · ship 2–3 · train 4 · elephant 8 · strawberry 10.
- **Made-up words** are generated per step for decoding (CVC → blends → vowel teams → two syllables), never matching a real word.
- **Word-recognition distractors** get closer as the step rises: different words → same first letter → one-letter neighbours → look-alike confusions (b/d, transposed letters).
- **Stories:**
  - generated mini-stories for steps 1–3 (endless variety)
  - 14 authored stories for steps 3–10, with detail, sequence, cause, inference and prediction questions
- **Letter–sound ladder** of 50+ graphemes: s a t p i n → look-alikes → digraphs → vowel teams → r-controlled → igh/ph/wh → tch/dge/kn/wr/tion.

---

## 4. Cinematics

### 4.1 Prologue — *"The Night the Words Went Quiet"* (75 s, shown once, skippable)

| Shot | Visual | Audio / VO (Dadi Kahani) |
|---|---|---|
| 1 | Clouds part; the floating islands glow; the Story Tree sparkles | Soft music. "High above the clouds lies Aksharpur, where words keep the world alive." |
| 2 | Children of the islands reading; leaves sprout on the Tree | "Every time someone reads, the Story Tree grows a new leaf." |
| 3 | A tiny grey cloud watches from far away, alone | "But one little cloud had never heard a story…" |
| 4 | Gumsum inhales; letters, notes and colour are sucked in; islands turn grey | Whoosh, music cuts. Gumsum: "Hee-hee! Now they're all mine!" |
| 5 | The bridge cracks; Milo runs up the Tree to the golden book | Milo: "Oh no, oh no! The Story Tree is fading!" |
| 6 | The book opens; light; the Explorer tumbles out with the Lantern | Magic chime. Milo: "You came! An Explorer! Will you help me bring the words back?" |
| 7 | The Explorer nods; the Lantern glows; title **READLE — The Quest for the Lost Words** | Title sting. |

### 4.2 "Star Bridge" cutscene (20 s), shown when all seven islands are played through
Gumsum floats in, a little lighter each season. He tries a riddle; the Explorer answers (this is the check-in).
At the end Gumsum smiles: *"You're… really getting good at this. Maybe… reading isn't only for others?"*

### 4.3 Season finale (60 s) and next-season opener
All six gems placed in the Story Tree → the Explorer reads Gumsum a story → Gumsum glows and becomes **Gunjan** → word-rain across the colourful islands.
**It is not the end:** the opener for season 2 shows Gunjan's cousins drifting in from the Other Side of the Clouds, and every island growing to its next tier.

### 4.4 How cinematics are built
- A **JSON cutscene script**: shots with background, characters plus animation state, camera pan/zoom, dialogue line IDs (VO file + subtitles in EN/HI), SFX cues and timings.
- Played by an in-app **CutscenePlayer** (Flutter), with 2.5D parallax and Rive character animations. **Lip-sync** opens the mouth from the VO amplitude.
- Skippable after the first view; replayable from the Explorer's Journal.

---

## 5. Meta-progression (why children come back)

| System | What the child sees | Ethics guardrail |
|---|---|---|
| **Island restoration & tiers** | Each island goes from grey to full colour (70 % chapter progress + 30 % real skill growth) and then **grows a tier every season** | Tied to real learning, never purchasable |
| **Story Gems** | One gem per finished island chapter, every season | — |
| **Quest Board** | Always 3 quests ready: Explore, Gentle, Adventure, Challenge, Boss, Star map, Bonus, Echo | Chosen by need, never random filler |
| **Collections** | Band Stickers, Ninja Belts, Lantern Colours, Portal Critters, Sea Log, Reef-o-pedia, Case Files, Bazaar Lights, Hive bees, Rune Book, Library | Earned by playing; no random paid rewards |
| **Explorer's Room** | Decorate with items, bees visit, creatures in an aquarium | — |
| **Story beats** | Every quest is a story beat with a cliffhanger ("Next, Inspector Ullu has a NEW case…") | No daily limit and no forced stop |
| **Cozy streak** | Story Tree flowers bloom for days played | Missing a day never removes anything; a "rain day" auto-protects the streak |
| **Surprise gifts** | Occasionally Milo finds a gift after a hard effort | Rewards effort, not luck; no loot boxes |

---

## 6. Art direction & asset pipeline

- **Style:** soft 2.5D storybook (like the reference board): rounded shapes, warm gradients, thick friendly outlines, Indian motifs (rangoli patterns, kurtas, chai stalls, tabla, kites, mango trees).
- **Palette:** per island (forest greens, valley purples, ocean blues, village oranges, island golds, castle pinks); grey "drained" versions for restoration.
- **Characters:** a turnaround sheet each (front, ¾, side), an expression sheet, and **Rive rigs** with a state machine (idle, talk, happy, sad, surprised, cheer, plus game-specific actions).
- **Production options:**
  1. *Best:* commission an illustrator for 13 characters + 12 backgrounds; rig in Rive.
  2. *Fast prototype:* generate concept art with an image-generation tool, then trace or clean into vectors for a consistent style. Check each tool's licence for commercial use.
  3. *Free fillers:* [Kenney](https://kenney.nl) CC0 2D packs for UI icons, particles and props.
- **Formats:** Rive (`.riv`) for characters, Lottie (`.json`) for VFX, WebP backgrounds (2×), SVG/vector for UI.
- **Size budget:** under 60 MB per language, so the app works on low-cost Android phones.

### 6.1 Master asset list (count)
| Type | Count |
|---|---|
| Character rigs | 17 (Explorer, Milo, Gumsum, Dadi Kahani + 13 guardians and band members) + suspect and creature sets |
| Backgrounds | ~24 (each island hub + each game scene, grey and colour versions) |
| Props / sprites | ~250 (picture-word cards reused from the content packs, fruits, lanterns, cells, tiles, chests…) |
| VFX (Lottie) | ~25 (sparkle, burst, honey fill, fireworks, page turn…) |
| Cutscenes | 1 prologue, 11 game intros, 1 Star Bridge, season finales and openers, island tier-up scenes |

---

## 7. Voice casting

### 7.1 Approach
- **Recommended for launch:** record the **4 main voices with real voice actors** (Milo, Dadi Kahani, Gumsum, Explorer narration), **in English for v1** (Hindi recordings in phase 2); children respond far better to real, warm voices.
- **Prototype / supporting characters:** pre-generate lines with neural text-to-speech and **bundle the audio files** in the app (works offline; no API at runtime).
- **Word and sound audio** for exercises: record cleanly by a native speaker per language (phonemes need to be exact), or use high-quality TTS checked by a teacher.

### 7.2 Voice options (researched)
| Option | Languages | Why | Notes |
|---|---|---|---|
| **Microsoft Azure Neural TTS** | en-IN: Neerja, Prabhat, Aarav, Ananya, Kavya, Kunal, Rehaan, Aashi… · hi-IN: Swara, Madhur + newer voices | Natural Indian voices; Neerja and Swara support *cheerful* / *empathetic* styles; SSML pitch and rate control for character variety | Paid per character; generate once and bundle |
| **AI4Bharat Indic Parler-TTS** (open source, Apache 2.0) | 20+ Indian languages incl. Hindi, Kannada, plus English | Describe the voice in words ("a playful young voice, fast and expressive"); great for many characters and for future Kannada | Large model; run offline on a PC to pre-generate; access is gated on Hugging Face |
| **Google Cloud TTS** (Neural2 / WaveNet) | en-IN, hi-IN | Good quality, SSML | Paid |
| **ElevenLabs** | English, Hindi | Most expressive character voices | Paid; check the licence for children's apps |
| **Device TTS** (`flutter_tts`, already in the app) | en-IN, hi-IN | Free, offline | Robotic; fallback only |

### 7.3 Casting sheet
| Character | Voice brief | Suggested TTS voice (EN / HI) | Treatment |
|---|---|---|---|
| **Milo** | Bright, young, excited, a little squeaky | en-IN-Aarav or Rehaan / hi-IN-Madhur | pitch +15 %, rate 1.05 |
| **Dadi Kahani** (narrator) | Warm grandmother, slow, smiling | en-IN-Neerja (empathetic) / hi-IN-Swara (empathetic) | pitch −5 %, rate 0.9, soft reverb |
| **Gumsum** | Soft, wobbly, giggly, airy | Indic Parler-TTS: "soft breathy playful voice" | chorus + light echo |
| **Maestro Bhalu** | Deep, dramatic, booming | en-IN-Prabhat / hi-IN-Madhur | pitch −20 % |
| **Pip the Ninja** | Fast, cool, confident | en-IN-Kunal / Parler | rate 1.15 |
| **Arya** | Confident, kind teenage girl | en-IN-Ananya / hi-IN-Swara (cheerful) | — |
| **Bolt** | Robotic, beep-filled | any voice + vocoder / ring-mod | add beep SFX between words |
| **Captain Kachhua** | Old, gravelly sea captain | en-IN-Prabhat / Parler "old man, raspy" | pitch −15 %, rate 0.9 |
| **Coral** | Busy, chatty | en-IN-Kavya / Parler | rate 1.1 |
| **Inspector Ullu** | Serious, dramatic detective | en-IN-Prabhat / hi-IN-Madhur | slight reverb on "A mystery!" |
| **Chuchu** | Nervous, squeaky | any voice | pitch +35 %, rate 1.2 |
| **Jugnu** | Giggly, tiny, fast | en-IN-Aashi / Parler | pitch +30 % |
| **Queen Madhu** | Regal, kind, hums | en-IN-Neerja (cheerful) / hi-IN-Swara | layer a soft hum |
| **Captain Kalam** | Loud, poetic pirate parrot | en-IN-Kunal / Parler "loud excited" | pitch +20 %, squawk SFX |
| **Princess Pari** | Adventurous girl | en-IN-Ananya / hi-IN-Swara | — |
| **Kitabu** | Forgetful, funny, papery | Parler "funny old voice" | light paper-rustle layer |

**Audio specs:** 48 kHz mono, normalised to −16 LUFS, exported as OGG/Opus (about 24 kbps for VO). Files named `vo/{lang}/{character}/{line_id}.ogg`, with subtitles in the same JSON.

### 7.4 Example voice lines (English for v1; the Hindi column is for phase 2)
| ID | Character | English | Hindi |
|---|---|---|---|
| `milo_ready` | Milo | "Ready, Explorer?" | "तैयार हो, खोजी?" |
| `milo_almost` | Milo | "Almost! Let's listen again." | "लगभग! चलो फिर से सुनते हैं।" |
| `milo_power` | Milo | "Whoa — you're getting stronger!" | "वाह — तुम और मज़बूत हो रहे हो!" |
| `bhalu_intro` | Maestro Bhalu | "My band has forgotten every beat!" | "मेरा बैंड सारी ताल भूल गया!" |
| `pip_intro` | Pip | "A true ninja hears every piece of a word!" | "सच्चा निंजा शब्द का हर टुकड़ा सुनता है!" |
| `arya_hit` | Arya | "Bullseye! The lantern is shining!" | "निशाना सही! लालटेन जगमगा उठी!" |
| `bolt_crossed` | Bolt | "Beep! Sounds and symbols… crossed!" | "बीप! आवाज़ें और अक्षर… उलझ गए!" |
| `kachhua_boost` | Kachhua | "Bubbles and barnacles — BOOST!" | "बुलबुले और सीपियाँ — उड़ान!" |
| `ullu_mystery` | Inspector Ullu | "A mystery! Someone switched the words." | "एक रहस्य! किसी ने शब्द बदल दिए हैं।" |
| `madhu_hint` | Queen Madhu | "Hmm… listen to the end sound, little one." | "हम्म… आख़िरी आवाज़ सुनो, नन्हे।" |
| `kalam_open` | Captain Kalam | "Arr! The quill obeys the hand that writes true!" | "अरे वाह! जादुई कलम सच्चे लिखने वाले की सुनती है!" |
| `kitabu_forgot` | Kitabu | "I remember my beginning… but not my end!" | "मुझे अपनी शुरुआत याद है… पर अंत नहीं!" |
| `gumsum_week` | Gumsum | "Maybe… reading isn't only for others?" | "शायद… पढ़ना सिर्फ़ दूसरों के लिए नहीं है?" |

---

## 8. Sound effects & music

### 8.1 Sources (free for commercial use)
| Source | Licence | Use for |
|---|---|---|
| [Kenney audio packs](https://kenney.nl/assets/category:Audio): Interface Sounds, UI Audio, Impact Sounds, Digital Audio, RPG Audio, Music Jingles | **CC0** (no attribution) | UI clicks, pops, impacts, jingles, robot blips |
| [Pixabay Sound Effects & Music](https://pixabay.com/sound-effects/) | Pixabay Content License (commercial OK, no attribution; don't resell the raw files) | Ambiences (rain, forest, ocean), whooshes, magic chimes, background music |
| [Freesound.org](https://freesound.org) (filter: **CC0**) | CC0 per file | Specific sounds (bee buzz, quill scratch, page flip) |
| [Mixkit](https://mixkit.co/free-sound-effects/) | Mixkit free licence | Game SFX, short music |
| Custom recording / composition | — | Signature themes with Indian instruments (tabla, bansuri, santoor, dhol) |

### 8.2 Global SFX set (used everywhere)
`ui_tap`, `ui_back`, `card_flip`, `correct_chime` (3 variations), `gentle_miss_boop`, `hint_sparkle`, `power_up`, `star_earned` (×3 rising), `reward_fanfare`, `chest_open`, `coin_shower`, `island_restore_swell`, `level_up_whoosh`, `milo_giggle`, `page_turn`, `cloud_whoosh` (Gumsum).

### 8.3 Music plan
| Track | Mood | Instruments | Notes |
|---|---|---|---|
| Main theme "Aksharpur" | Wonder, adventure | Strings, bansuri, light tabla | Menus and the map; grows fuller as more islands are restored |
| Sound Forest | Groovy | Tabla, bansuri, dhol | 4 adaptive stems (Orchestra) |
| Symbol Valley | Festive | Shehnai-lite, dhol | Festival feel |
| Word Ocean | Mysterious adventure | Synth pads, marimba | Darker per zone |
| Word Village | Playful mystery | Pizzicato, sitar | Detective motif |
| Treasure Island | Jolly | Accordion, dhol, ukulele | Pirate fun |
| Story Castle | Storybook | Harp, strings, celesta | Waltz |
| Star Bridge | Hopeful | Choir pad, piano | Season check-in (after all seven islands) |

**Mixing rules:** music at about −20 dB under VO (auto-ducking while anyone speaks), SFX at about −12 dB. One-tap "music off" in settings. No sudden loud sounds; nothing above −6 dBFS.

---

## 9. How every game plugs into the engine

```
Screening report ──► SkillModel per skill (θ, step, errors)  ──►  Campaign (islands, tiers, chapters)
                                    ▲                                     │
                                    │                                     ▼
       AppState.recordItem (every answer)  ◄──  Game  ◄── Quest (island, kind, items) from the Quest Board
                                    │                ▲
                                    │                └── ItemGen(step, error focus, least-seen) ◄── GameContentPack (English v1)
                                    ▼
       AppState.completeQuest → chapter node, restoration %, rewards, session log → retest gate check
```

**Implemented in code:**

| File | Responsibility |
|---|---|
| `lib/engine/skill_model.dart` | θ rating, step, decaying error memory, trend/status, settling check |
| `lib/engine/campaign.dart` | islands, tiers, seasons, chapters, Quest Board, retest gate |
| `lib/engine/item_gen.dart` | items for every skill × step 1–10, error-focused, least-seen first |
| `lib/content/content_pack.dart` | language interface + `enabledLanguages = ['en']` |
| `lib/content/en/*` | English word data, automatic feature tagging and difficulty, made-up words, stories |
| `lib/core/config.dart` | every threshold (target success 78 %, 10 quests/chapter, 60 answers/skill, start-step table…) |

New item types still needed for the five games not yet built:
| Game | New item data |
|---|---|
| Sound Orchestra | syllable counts per word, rhyme groups, first sounds |
| Sound Ninja | segment boundaries per word (syllable / onset-rime / phoneme) |
| Sound Portal | multi-spelling pattern sets |
| Word Builder | nonword block sets + creature parts |
| Word Detective | mystery scripts (scene, suspects, 3 target words) |
| Word Flash | exposure time per level |
| Magic Writer | stroke-order templates per letter/akshara |
| Story Quest | panel stories with question types (EN + HI) |

---

## 10. Technical build plan

| Area | Choice |
|---|---|
| Action games (Archer, Ninja, Rocket, Flash, Writer) | **Flame** game engine on Flutter (sprites, physics-lite, particles, gestures) |
| Puzzle / story games (Orchestra, Portal, Builder, Detective, Hive, Story) | Flutter widgets + Rive + Lottie (lighter, accessible) |
| Characters | `rive` package with state machines; lip-sync from VO amplitude |
| VFX | `lottie` package + Flame particles |
| Audio | `flame_audio` / `audioplayers` for SFX (low latency); `just_audio` for music stems and VO; auto-ducking |
| Cutscenes | JSON script + `CutscenePlayer` widget (parallax, camera, subtitles, VO, SFX) |
| Handwriting | on-device `$P` point-cloud recogniser + stroke-order check |
| Speech (voice mode) | existing `SpeechEngine` + `VoxLexi` from the screening |
| Content | per-language JSON packs (words, segments, stories, mysteries, VO line IDs) |
| Offline | all VO/SFX/music bundled; optional downloadable language packs later |

### 10.1 Milestones
| # | Milestone | Contents |
|---|---|---|
| M0 ✅ | **Learning engine** (done) | Per-skill learner model, screening → starting steps, Quest Board (no daily cap), islands/tiers/seasons, 7th island, evidence-based retest gate, English word database with automatic difficulty, cycle reports, 34 tests |
| M1 | Foundations | Audio manager (SFX, music stems, VO, ducking), CutscenePlayer, Rive character component, Explorer's Journal |
| M2 | Story spine | Prologue, Milo/Gumsum/Dadi rigs, quest story beats, Star Bridge scene, season openers |
| M3 | Hero games (demo set, playable today in basic form) | Sound Orchestra, Letter Archer, Word Rocket, Word Detective, Spelling Hive, Story Quest, plus Star Observatory (mixed) |
| M4 | Second wave | Sound Ninja, Sound Portal, Word Builder, Word Flash, Magic Writer |
| M5 | Voices & polish | Record or generate all **English** VO, music, SFX mix, accessibility pass, low-end Android performance |
| M6 | Playtest | 10–20 children; measure fun (return rate, "again!") and learning (step growth per skill); tune thresholds |
| M7 | Hindi (phase 2) | Hindi `GameContentPack` (aksharas, matras, conjuncts, Hindi stories), Hindi VO; switch on in `enabledLanguages` |

### 10.2 What is needed from the team
- An illustrator (or the AI-assisted plus vector-clean pipeline) for characters and backgrounds.
- Voice actors for Milo and Dadi Kahani in **English** (Hindi in phase 2), or approval to use TTS for the prototype.
- A teacher to review the English word lists, stories and phoneme audio.
- Keys or accounts if cloud TTS is chosen (only for pre-generating; never shipped in the app).

---

## 11. Safety & child-first checks
- No ads, no in-app purchases, no chat, no external links in child mode.
- No scary content: Gumsum is never threatening; there are no deaths, no "game over".
- No forced session cap (by design decision). Engagement comes from story and progress, never from pressure mechanics.
- Feedback language is always encouraging; the reports stay in the grown-up area.
- Audio is processed on the device; nothing is uploaded.

---

## 12. Retired concepts (from v1.0)
- Daily mission limit, "3 missions/day", "Goodnight, Explorer", "Tomorrow" button
- Weekly / day-count retest, demo "skip day" and "jump to end of week" controls, manual retest override
- Global level 1–4 starting at the same level for everyone
- Finite finale after the seventh island

## 13. English now, Hindi later: how the code stays ready
- `GameContent.enabledLanguages = ['en']`; Hindi is shown as "soon" in setup, and saved Hindi choices fall back to English.
- The engine (skill model, item generator, campaign, retest gate) contains **no words or letters**. It only reads `WordEntry` features (units, syllables, blends, digraphs, vowel teams, irregularity, difficulty).
- Adding Hindi = a new `GameContentPack` that tags Hindi words (akshara count, matra, conjunct, anusvara/chandrabindu), Hindi stories and Hindi VO under `vo/hi/…`, then adding `'hi'` to `enabledLanguages`.
- The existing Hindi screening bank and the old Hindi game content are kept in the repo for phase 2, but are not used in v1.
