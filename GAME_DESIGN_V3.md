# Readle — Game Design v3: *The Rescue of the Story Keepers*

> Status: **approved 10 Oct (decisions in §9); implementation in progress.** `GAME_DESIGN.md` (v2.1) still describes the app as it is built today.
> This document re-tells the story and changes the progression rules with the **fewest possible changes**:
> every game, level, character and picture we already have is reused. Only one small new character set is
> proposed (the storm-cloud jailers), and even that is made from existing Gumsum art.

---

## 1. The story in one page

**Aksharpur** is a fantasy realm floating above the clouds. At its heart stands the **Great Story Tree**, the source
of every story. Animals, *living* plants and flowers, and even friendly clouds live there happily, because every
evening they gather to **listen to stories**.

Nobody but the **seven Story Keepers** can hear the Tree. They carry its stories to everyone else:

| Story Keeper | Home island (before) | Keeper of… |
|---|---|---|
| **Milo the Fox** (leader) | the Story Tree | the Tree itself |
| **Maestro Bhalu** | Sound Forest | the stories of **sounds** |
| **Arya the Archer** | Symbol Valley | the stories of **letters** |
| **Captain Kachhua** | Word Ocean | the stories of **blending** |
| **Inspector Ullu** | Word Village | the stories of **words** |
| **Queen Madhu** | Treasure Island | the stories of **spelling** |
| **Princess Pari** | Story Castle | the stories of **meaning** |

**The villain.** **Gumsum**, a huge storm cloud, *hates* stories. Every evening the whole realm laughs and listens,
and he just gets darker. One night he attacks: lightning, thunder and a howling wind. He **kidnaps six Story
Keepers** and locks each one in a **cloud cage** on one of his six **storm islands**. Each island is guarded by one of
his **Hush Clouds** (little storm clouds that obey him). **Milo** escapes, but he is **injured**: his tail is singed,
and he can still walk but cannot fly to the islands alone.

Without the Keepers, the Tree goes silent, the animals stop smiling, the flowers droop and the sky turns grey.

**The hero.** The Tree uses its last light to call for help, and **the child playing the game** falls through a golden
page into Aksharpur. Together with Milo, the Explorer travels to each storm island and wins **keys** by playing the
island's two games. Collect **every key on an island** → the cage opens → **a Story Keeper is free**, and that
island bursts back into colour.

**The finale.** When all six Keepers are free, the **seventh island**, Gumsum's **Storm Citadel** (the old Star
Observatory, now wrapped in storm), appears. Gumsum challenges the Explorer to **the Storm Trial**, a test mixing
everything they have learned. Score high enough and the light of every story, shining through the seven Keepers,
**breaks the storm**. **Softer redemption:** Gumsum shrinks to a small, lonely grey cloud. Nobody ever told *him* a story,
and that is why he hated them. The Keepers and the Explorer tell him one. He brightens to white-gold and becomes
the Story Tree's gentle rain cloud, a friend. The next season brings a new threat from beyond the clouds.

> **Tone guardrails** (unchanged from v2): no scary imagery. Cages are made of fluffy grey cloud, not bars. Keepers
> are *bored and grumpy* in their cages, not hurt or crying. Milo's injury is a bandaged tail, played for warmth
> rather than pain. Gumsum is loud and theatrical, never frightening; lightning is cartoon zig-zags with no flashes.

---

## 2. What changes and what stays

| Thing | v2.1 (built) | v3 | Change needed |
|---|---|---|---|
| Islands | 6 skill islands + Star Observatory | Same 6 islands ("storm islands" until rescued) + Storm Citadel = Observatory | Story text, island state "stormy / rescued" |
| Games | 2 per island (Castle: 1), 4 levels each | **Same** | None |
| Level 4 | Boss level | **Boss level** (more keys) | None |
| Progress currency | Levels cleared ⭐ | **Keys 🔑** (1–3 per normal level, 1/3/5 per boss) | New key rules (§3) |
| Island goal | Clear all levels | **Collect every key** → free the Keeper | New unlock rule |
| Second game | Opens after 2 levels of the main game | **Same** | None |
| 7th island | Star Observatory, 4 mixed levels | **Storm Trial**: one mixed test with a pass mark | New test flow (§5) |
| Guardians (Bhalu, Arya…) | Island hosts | **The captured Story Keepers** (in a cage until rescued, then hosts again) | New dialogue lines, cage visual |
| Second-game hosts (Pip, Bolt, Coral, Jugnu, Kalam, Kitabu) | Game hosts | **Island friends** who help the Explorer (same roles) | Dialogue tweaks only |
| Gumsum | Lonely cloud who swallowed words | **The villain** storm cloud | Dialogue; existing art moods (happy = gloating, sad, surprised) are enough |
| Dadi Kahani | Narrator, spirit of the Tree | **The voice of the Story Tree** (narrator) | None |
| Milo | Companion | Companion **and** the 7th Keeper (injured) | Bandage overlay in code; new lines |
| Screening, learner model, adaptive difficulty, reports | — | **Unchanged** | None |
| Collections, room, Journal, streak, gifts | — | Unchanged (keys added to the Journal) | Small UI |

### The only "new" characters: the six Hush Clouds (jailers)

One jailer per storm island. **They are made from the existing Gumsum pictures**: each is the Gumsum art,
recoloured in code (a tint and saturation filter), drawn at 60 % size, with a small prop drawn in code. So **zero new
images are needed**. Optional painted versions can come later.

| Island | Hush Cloud | Colour | Code-drawn prop | Guarding |
|---|---|---|---|---|
| Sound Forest | **Drizzle** | moss green | drum with a cloth over it (no music!) | Bhalu |
| Symbol Valley | **Gust** | violet | knotted kite string | Arya |
| Word Ocean | **Murk** | teal | anchor | Kachhua |
| Word Village | **Smudge** | orange-brown | blotted signboard | Ullu |
| Treasure Island | **Sulk** | mustard | locked honey jar | Madhu |
| Story Castle | **Hush** | pink-grey | closed book with a clasp | Pari |

Each jailer appears in the island-start animation and taunts once per level. Every key the child wins knocks a
small puff off the jailer, so it **shrinks as the key meter fills**. At 28/28 it pops into a harmless sprinkle.

---

## 3. Keys

### 3.1 Keys per level

Keys are counted from **first-try answers** in the level (the same score that clears a level today).

| Level | Questions | 1 key | 2 keys | 3 keys | 5 keys |
|---|---|---|---|---|---|
| Normal (levels 1–3) | 6 | 3–4 right (≥ 50 %) | 5 right (≥ 80 %) | **6 right (100 %)** | — |
| Boss (level 4) | 8 | 4–5 right (≥ 50 %) | — | 6–7 right (≥ 75 %) → **3 keys** | **8 right (100 %) → 5 keys** |

Fewer than half right: **0 keys**, "Almost! Play again"; the next level stays locked (same as today).

* **Per game:** 3 + 3 + 3 + 5 = **14 keys**. **Per island:** two games = **28 keys**; Story Castle (one game) = **14 keys**.
* **Best result counts.** Replaying a level can only *raise* its keys (new questions every time). Keys are never lost.
* The level **unlocks the next level as soon as it earns ≥ 1 key**, so the child is never stuck; perfect play is only needed for the rescue.
* The island sheet shows each level's key slots (🔑🔑◻ / 🔑🔑🔑◻◻) and the island total (**🔑 17 / 28**).

### 3.2 Rescue rule

**A Keeper is freed only when the island's key total reaches its maximum (28, or 14 on Story Castle).**

**Decided (10 Oct): maximum keys.** Every level must be cleared with 100 % first-try answers. A child who
is not there yet keeps replaying (new questions each time) and keeps every key already won. Safety nets that do not
lower the bar: Milo's hints and the extra-help mode stay on inside levels, and the island sheet always shows which
levels still have keys to win ("2 keys left on Level 3").

### 3.3 Island key meter (UI)

* Map: each storm island shows a **cage icon + "🔑 17/28"** pill (replaces "0/8 ⭐").
* Island sheet: the two game cards (unchanged layout) with **key slots per level tile** and a big **cage with a keyhole
  meter** at the top. The cage glows when the rescue threshold is reached, and tapping it plays the rescue animation.
* Reward screen after a level: keys fly from the level into the island meter (+ sound), with "2 more keys to beat your best!" if not maxed.

---

## 4. Island flow (one island, start to finish)

```
Arrive (first visit) ──► ISLAND-START ANIMATION (jailer taunts, Keeper in cage, Milo's plan)
        │
        ▼
Main game  L1 ─► L2 ─► L3 ─► L4 BOSS          (each level: 0–3 keys, boss 0/1/3/5)
                  │
                  └─ after 2 main levels ─► Second game  L1 ─► L2 ─► L3 ─► L4 BOSS
        │
        ▼  key meter reaches the rescue threshold
RESCUE ANIMATION (cage opens, jailer pops, island turns to colour, Keeper joins the team)
        │
        ▼  Keeper now hosts the island's games again; replays keep earning keys toward "Perfect Rescue"
```

* Islands can be done **in any order** (the Quest Board still suggests the weakest skill first).
* The Explorer's Journal shows the **Keeper roster**: 7 portraits, rescued ones in colour, caged ones grey with their island name.

---

## 5. The Storm Trial (7th island)

* **Unlocks** when all six Keepers are free.
* **Before it starts:** the TRIAL-WARNING animation (§6.4) shows the pass mark clearly.
* **Format:** **30 questions, 5 per skill**, mixed and shuffled, one question per screen, using the quick single-screen
  versions of the six main games. Difficulty is the child's **current level** in each skill (from the learner model),
  so the test is fair to every child. No timer, and hints are off.
* **Pass mark: 21 / 30 (70 %)**, shown as a **lightning meter** that drains Gumsum's storm with every right answer.
  * Rationale: 70 % is a common "mastery" threshold that is challenging but reachable at the child's own level. A
    child who cleared all six islands normally scores 75–90 %.
* **Win:** FINALE animation (§6.5) → season complete → the existing **Star Bridge check-in** (fresh screening) →
  next season (Gumsum returns with new jailers, and every island grows a tier).
* **Not yet (< 21):** Gumsum gloats, but kindly ("Ha! My storm holds… for now!"). The result shows the **two weakest
  skills**, and their Keepers each offer a short practice round. The child can retry anytime with new questions. Nothing is lost.

---

## 6. Animations

### 6.1 What the Nessy reference does (analysed frame by frame, 38 s)

| Shot | Time | Technique | Our equivalent |
|---|---|---|---|
| Happy valley: crocodile plays banjo, hippos dance, bunny hops, rainbow | 0–6 s | Flat 2D cut-out characters on looping "idle" moves; static painted background | Puppet rigs (built) on painted backgrounds |
| Camera glides to the volcano, which erupts (purple smoke, orange lava), sky darkens | 6–10 s | Slow camera push + particle burst + colour grade to dusk | Cutscene camera zoom/pan (built) + new particle FX + "darken" filter |
| **4-panel comic split**: knight, toucan with egg, lion, turtle react at once | 10–16 s | Screen splits into panels; each character reacts; items fly in | New *split-panel* shot type |
| Each panel gets a **colour burst** behind a white "sticker" outline | 16–18 s | Radial colour flash + outlined cut-out pop | New *spotlight burst* effect |
| A **green gem** spins and grows, with glints | 20–24 s | Item reveal on a dark vignette | New *item reveal* shot (we'd use **the key** and **the Keeper's medallion**) |
| Island map overview, then the lesson map | 24–30 s | Map reveal, path drawing | Our map + path-reveal animation |
| Egg sits with a **"?" silhouette** of what will hatch | 30–38 s | Mystery silhouette as a curiosity hook | *Silhouette tease* shot (next Keeper, Gumsum) |

**Style takeaways:** short shots (1.5–3 s), *always* something moving, the camera never fully still, bold flat
colours, thick outlines, one clear idea per shot, sound effects on every beat, narration over everything.

### 6.2 The animations we need

| # | When | Length | Storyboard |
|---|---|---|---|
| A1 | **Prologue** (first launch, after creating the explorer) | 60–75 s | 1) Story Tree glowing, animals/flowers/clouds dancing (idle loops). 2) Seven Keepers around the Tree, quick 7-panel split, each waves. 3) Sky darkens; Gumsum looms, lightning. 4) **6-panel split**: each Keeper is swept away in a cloud swirl (spotlight bursts). 5) Milo tumbles, bandaged tail; the Tree flickers. 6) Golden page; the Explorer falls in; Milo: "You came! Will you help me rescue them?" 7) Map of six storm islands with **silhouette cages** ("?") |
| A2 ×6 | **Island start** (first visit to each island) | 20–25 s | Fly-in over the stormy island → the jailer cloud pops up and taunts → push-in on the cage: the Keeper waves sadly ("Explorer! In here!") → Milo explains the two games → **key reveal**: a key spins and shows "28 keys open the cage" |
| A3 ×6 | **Rescue** (key meter reaches the threshold) | 15–20 s | Keys fly into the lock one by one (fast) → cage bursts into fluffy puffs → jailer shrinks and pops into a sprinkle → **colour wave** sweeps the island (grey → full colour) → the Keeper does a happy dance and joins Milo (sticker-burst) → Tree glows a bit brighter (1 of 6 lights on) |
| A4 | **Trial warning** (before the 7th island) | 20 s | All six Keepers in a 6-panel split, then together → the Storm Citadel rises, lightning → Gumsum: "A test! Answer **21 of 30** right and my storm breaks. Fail, and it stays forever!" → big on-screen card: **"Storm Trial · 30 questions · score 21 to win ⚡"** → Milo: "We can do this together!" |
| A5 | **Finale** (Trial passed) | 40–50 s | Lightning meter fills → beam of light from the Tree through all seven Keepers → storm cracks and bursts → Gumsum shrinks to a small, sad grey cloud, alone → **softer redemption:** Milo and the Explorer sit beside him; the Keepers tell him a story; he listens, starts to glow and turns soft white-gold ("Nobody ever told me a story before…") → he floats up and becomes the Tree's gentle rain cloud, a friend → whole realm in colour, animals dance → season badge |
| A6 | Trial not passed | 8 s | Storm rumbles, Gumsum smirks; Keepers cheer the child on; "Try again whenever you're ready" |

**Extras (cheap, high value):** key-earned fly-in (every level, 1 s) · boss-level intro (3 s: jailer appears,
"BOSS LEVEL" card) · second-game unlock (3 s: friend character pops in with a sticker burst) · season opener (exists).

### 6.3 How to make them: options and recommendation

| Option | What it is | Pros | Cons | Cost |
|---|---|---|---|---|
| **1. Code cutscenes (recommended for all of A1–A6)** | Extend our existing cutscene engine (JSON shots, camera moves, puppet characters with lip-sync, voice) with the Nessy techniques: split panels, spotlight bursts, particles, item reveal, colour wave, silhouette, jailer tint | Uses our real art and voices; perfectly consistent characters; voice-synced; tiny files; tappable and skippable; Claude builds it fully | Characters move as cut-outs (bob, squash, sway, mouth), not frame-by-frame animation | Free (≈ 3–4 days of work) |
| 2. AI image-to-video (for 2–4 "hero" shots) | Feed our painted backgrounds/characters as the first frame to a video model (e.g. Kling AI, Runway Gen-4, Google Veo 3, Hailuo) with a prompt; drop the MP4 into a cutscene shot | Real motion (eruption, flying, storm) that looks cinematic | Characters drift off-model; little control; 5–10 s clips; needs an account and credits; check commercial licence | Free tiers limited; ≈ $10–30/month |
| 3. Rive / Lottie by an animator | Professional rigged characters and VFX | Nessy-level quality, small files, interactive | Needs a hired animator (weeks) | Paid |

**Decided (10 Oct): AI video is used** for the cinematic animations; prompts are in [`ANIMATION_PROMPTS.md`](ANIMATION_PROMPTS.md). The code cutscene engine plays the clips (with our recorded voices on top) and does the small in-game moments (key fly-in, boss card, unlocks). The earlier plan remains the fallback while clips are missing: build **all six animations with option 1** (Claude does it, no new art needed). Optionally add
**AI video for 2–3 spectacle shots** (storm attack in A1, cage burst in A3, storm breaking in A5). Claude writes
those prompts, using our existing art as the starting frame, but someone has to create the account and download
the clips (they need an account, and possibly payment).

### 6.4 New engine pieces (for implementation later)

| Piece | Purpose |
|---|---|
| `split` shot | 2–7 panels with independent backgrounds, characters and camera |
| `burst` effect | radial colour flash + white sticker outline behind a character |
| `particles` effect | lightning zig-zags, cloud puffs, sparkles, rain, keys flying |
| `reveal` shot | item spins/grows on a vignette (key, medallion, trophy) |
| `colourWave` effect | grey → colour wipe across the background |
| `silhouette` | black-filled version of any character art with a "?" |
| Jailer tint | Gumsum art + colour matrix + scale (no new images) |
| Bandage overlay | code-drawn bandage on Milo's tail |
| Cutscene JSON | `prologue_v3`, `island_start_<island>`, `rescue_<island>`, `trial_warning`, `finale`, `trial_retry` |

---

## 7. New voice lines (≈ 120)

* Prologue (Dadi, Milo, Gumsum): ~15
* Island start: jailer taunt ×6, Keeper-in-cage ×6, Milo's plan ×6
* Level taunts: jailer ×6 islands × 4 short variations
* Rescue: Keeper thank-you ×6, jailer "pop" ×6
* Trial: warning (Gumsum, Milo), per-question encouragement ×10, win ×3, not-yet ×3
* Key earned: Milo ×6 short variations

New voices: the six jailers can be one cloud voice pitched up or down per island (we already have Gumsum's voice; tool/voice_cast.json supports pitch).

---

## 8. Implementation outline (later; not started)

| Step | Work | Effort |
|---|---|---|
| 1 | Keys: per-level best keys in `IslandState`, key rules, rescue threshold, migration of existing saves (each already-cleared level starts with 1 key; replays earn more) | 1 day |
| 2 | UI: key slots on level tiles, island key meter + cage, map pills, Keeper roster in Journal, reward-screen key fly-in | 1.5 days |
| 3 | Storm Trial: 30-question mixed test, lightning meter, pass/not-yet, weakest-skill practice | 1.5 days |
| 4 | Cutscene engine v2 pieces (§6.4) | 2 days |
| 5 | Write and voice the 6 animations + extras (§6.2), new lines (§7) | 2 days |
| 6 | Tests (keys, rescue, trial, cutscenes), device check | 1 day |

**Total ≈ 9 days.** Nothing in the screening, learner model, games or levels changes.

## 9. Decisions (team, 10 Oct)

1. Rescue threshold: **maximum keys** (100 % first try on every level).
2. Storm Trial: **30 questions, pass 21**: approved.
3. Animations: **AI video** for the cinematic moments (prompts in `ANIMATION_PROMPTS.md`).
4. Gumsum's ending: **softer redemption** (he hears his first story and becomes the Tree's rain cloud).
