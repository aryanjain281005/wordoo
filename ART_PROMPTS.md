# Readle — Image Generation Prompts

Every image the app can use, with a ready-to-paste prompt. Until a file exists, the app shows its own
code-drawn placeholder, so you can add images **one at a time, in any order**. Nothing breaks if some are missing.

## How to add an image (3 steps)

1. Generate the image with the prompt below (copy the **Style block** + the image's own prompt).
2. Save it with the exact **file name** shown (e.g. `char.milo.happy.png`).
3. Put it in `assets/art/` and send it to Claude (or just tell Claude it is there). Claude will check it,
   remove the background if needed, resize and compress it, and rebuild the app.

The app finds images by file name automatically (`assets/art/<id>.png`, `.webp` or `.jpg`), so there are no settings to edit.

### Free tools that work well
| Tool | Good for | Notes |
|---|---|---|
| **Microsoft Designer / Bing Image Creator** (free, Microsoft account) | Characters, backgrounds | Good at following long prompts |
| **Google Gemini / ImageFX** (free, Google account) | Backgrounds, consistent edits ("same character, now sad") | Good at editing an image you upload |
| **Leonardo.ai** (free daily credits) | Character sheets, transparent PNGs | Has a "transparent background" option |
| **Ideogram** (free tier) | Anything with letters on it (signs, tiles) | Best at spelling text correctly |

Check each tool's terms allow commercial use before the app is published. Keep a note of which tool made which image.

### Getting the same character every time
- Generate the **`.happy`** image first. When you like it, **upload it as a reference** and ask for the other moods:
  *"Same character, same style, same outfit and colours — now with a sad expression. Keep everything else identical."*
- Never change the **Character block** text between prompts. Small wording changes give a different character.
- The **`.talk`** image must be the **`.happy`** image edited so that only the mouth is open (same pose and framing). The app swaps
  between the two while the character speaks, which makes the mouth move.

---

## Style block (paste at the start of EVERY prompt)

> Children's storybook illustration for a mobile game for Indian kids aged 5–10. Soft 2.5D painted style with rounded
> chunky shapes, thick friendly dark-indigo outlines (#1E2753), warm soft gradients, gentle rim light, and subtle paper
> texture. Cute, kind, expressive, never scary. Indian cultural details where natural (rangoli patterns, kurtas, diyas,
> marigolds, mango trees, tabla, kites). Bright cheerful saturated colours, soft shadows, clean readable silhouette,
> high detail but uncluttered. No text, no letters, no watermark, no signature, no frame.

**Avoid (negative prompt, if the tool has a box for it):** realistic photo, 3D render plastic look, horror, sharp teeth,
weapons pointed at viewer, dark gloomy palette, text, watermark, logo, extra limbs, extra fingers, cropped head, busy background behind characters.

### Technical specs
| Kind | Size | Background | Format |
|---|---|---|---|
| Characters (`char.*`) | 1024 × 1024, character centred, full body, feet near the bottom edge, ~8% empty margin | **plain flat white** (Claude removes it) or transparent | PNG |
| Backgrounds (`bg.*`) | **1440 × 2560 (portrait 9:16)**. Keep the key content in the middle 60 %, because phones crop the edges. Leave the **lower third calm** (game cards sit there) | full scene | PNG or JPG (Claude converts to WebP) |
| Props (`prop.*`) | 512 × 512, single object centred | plain flat white or transparent | PNG |

---

## A. Main characters

### A1. Milo the Fox — the child's companion and Keeper of the Story Tree

**Character block (copy exactly):**
> Milo, a young cheerful fox cub, chibi proportions (big head, small body), bright orange fur, cream-white cheek tufts and
> chest, white tail tip, big round shiny dark-brown eyes with two white highlights, small black nose, pointy ears with
> pink insides, wearing a soft leaf-green knitted scarf with a small mango-leaf pin and a tiny brown leather satchel
> stuffed with glowing golden leaves. Friendly, slightly clumsy, warm.

| File name | Prompt (after Style block + Character block) |
|---|---|
| `char.milo.happy.png` | Full body, standing facing the viewer three-quarter view, big open smile with mouth closed, tail swishing up, one paw waving hello. Plain flat white background. |
| `char.milo.talk.png` | **Edit of `char.milo.happy`:** identical pose, colours and framing, only the mouth is open in a friendly "ah" speaking shape showing a little pink tongue. |
| `char.milo.sad.png` | Same character, ears drooping down, eyes looking down with a soft worried brow, small frown, tail low, paws together. Gentle, not crying. Plain flat white background. |
| `char.milo.surprised.png` | Same character, ears straight up, eyes wide, mouth in a small round "oh!", both paws raised, tail puffed. Plain flat white background. |
| `char.milo.thinking.png` | Same character, head tilted, one paw on chin, eyes looking up to the side, small curious smile, one ear bent. Plain flat white background. |
| `char.milo.cheer.png` | Same character jumping with both arms up, eyes closed happily, huge open smile, golden leaves flying out of the satchel, sparkles around. Plain flat white background. |

### A2. Gumsum the Hush Cloud — the lonely cloud who swallowed the words

**Character block:**
> Gumsum, a small round fluffy cloud character with a soft puffy outline, big round expressive eyes with long lashes,
> tiny rosy cheeks, a small mouth, two tiny cloud-puff arms. Inside his semi-transparent body float faint glowing
> letters (a, b, k, m, s) like trapped fireflies. Mischievous but secretly lonely. Never scary.

| File name | Prompt |
|---|---|
| `char.gumsum.happy.png` | Stormy grey colour (#8E96A8) with darker grey underside, giggling mischievously with eyes squeezed, letters swirling inside, floating. Plain flat white background. |
| `char.gumsum.talk.png` | **Edit of `char.gumsum.happy`:** same image, mouth open in a small "hee-hee" speaking shape. |
| `char.gumsum.sad.png` | Same grey cloud, eyes big and watery looking down, small frown, a tiny raindrop falling from the bottom, letters dim. Plain flat white background. |
| `char.gumsum.surprised.png` | Same grey cloud, puffed up big with surprise, eyes wide, a few letters popping out of the top like popcorn. Plain flat white background. |
| `char.gumsum.light.png` | Same character but almost white and glowing softly with pale gold, smiling shyly, letters inside shining brightly (the cloud after children have read many stories). Plain flat white background. |

### A3. Dadi Kahani — the narrator, spirit of the Great Story Tree

**Character block:**
> Dadi Kahani, a warm smiling Indian grandmother made of soft glowing golden light, as if she grows out of tree bark.
> Silver hair in a neat bun with a small flower, round gold-rimmed glasses, small red bindi, kind wrinkles around the
> eyes, wearing a flowing shawl made of green and gold leaves over a cream saree. Gentle golden glow around her.

| File name | Prompt |
|---|---|
| `char.dadi.happy.png` | Upper body (waist up), hands gently open as if beginning a story, warm closed-mouth smile, leaves of her shawl gently lifting. Plain flat white background. |
| `char.dadi.talk.png` | **Edit of `char.dadi.happy`:** same image, mouth softly open while speaking. |
| `char.dadi.thinking.png` | Same, one finger raised as if remembering something, eyes twinkling. Plain flat white background. |

### A4. The Explorer (the child) — optional, used in cutscenes only
The app draws the child's customised avatar in code, so this is **optional** and only for cutscene key art.

| File name | Prompt |
|---|---|
| `char.explorer.png` | A brave curious Indian child of about 7, gender-neutral look, short tidy hair, orange kurta-style tunic over blue trousers, small backpack, holding up a glowing paper lantern (the Reading Lantern) that shines warm gold. Full body, three-quarter view, smiling. Plain flat white background. |

---

## B. Island guardians

One **happy** + one **talk** image each is enough for now (they appear in the story beat before every quest).
Add `.sad`, `.surprised`, `.thinking`, `.cheer` later with the same edit method as Milo.

| File name | Prompt (after Style block) |
|---|---|
| `char.bhalu.happy.png` | Maestro Bhalu, a big round friendly brown bear conductor, wearing a red silk kurta with gold buttons and a tiny gold bow-tie, holding a thin conductor's baton raised dramatically, eyes closed in musical joy, small round spectacles on his nose. Full body. Plain flat white background. |
| `char.arya.happy.png` | Arya the Archer, a confident kind Indian girl of about 12, long black braid, purple tunic with gold trim, soft brown boots, a golden bow held at her side (not aimed), a quiver of feather arrows with glowing letter tips, a friendly bald eagle (Garud) with a little orange scarf perched on her shoulder. Full body, smiling. Plain flat white background. |
| `char.kachhua.happy.png` | Captain Kachhua, an old friendly green sea turtle with a white bushy moustache, a navy captain's hat with a gold anchor badge, a small brass telescope under his arm, standing upright, laughing heartily. Full body. Plain flat white background. |
| `char.ullu.happy.png` | Inspector Ullu, a serious but lovable round brown owl wearing a tweed deerstalker detective hat and holding a big brass magnifying glass, one eyebrow raised; next to him a tiny grey mouse (Chuchu) holding a notebook and a biscuit, looking nervous. Full body, both characters. Plain flat white background. |
| `char.madhu.happy.png` | Queen Madhu, a regal but kind round honeybee queen with soft yellow-and-brown stripes, shimmering translucent wings, a small crown made of a glowing honey drop, a tiny royal cape with a honeycomb pattern, holding a little wooden honey dipper like a sceptre, warm smile. Full body, hovering. Plain flat white background. |
| `char.pari.happy.png` | Princess Pari, an adventurous Indian princess of about 10, a pink and gold lehenga with comfortable sneakers, a small crown shaped like a glowing lantern, holding an open storybook; next to her Kitabu, a chubby old blue book with big googly eyes, page-arms and a forgetful grin. Full body, both characters. Plain flat white background. |
| `char.kitabu.happy.png` | Kitabu alone: a chubby old talking storybook with a blue cloth cover and gold corners, big googly eyes on the cover, pages forming two little arms, a bookmark ribbon like a tongue, funny forgetful smile. Plain flat white background. |
| `char.bolt.happy.png` | Bolt the Portal Robot, a small round tin robot on one slightly wobbly wheel, teal and silver panels with rivets, a glowing yellow antenna bulb, a round screen face showing happy pixel eyes. Plain flat white background. |
| `char.pip.happy.png` | Pip, a cool little red panda ninja, black ninja headband with long ribbons, a leaf-shaped wooden practice sword on the back, ninja pose, confident grin. Full body. Plain flat white background. |
| `char.coral.happy.png` | Coral, a busy pink octopus builder with a yellow hard hat and a tool belt, holding a different little tool in each of her eight tentacles (hammer, ruler, brush, spanner), cheerful. Plain flat white background. |
| `char.jugnu.happy.png` | Jugnu, a tiny giggly firefly with big eyes and a glowing lantern-shaped tail shining warm yellow-green, zooming happily with motion sparkles. Plain flat white background. |
| `char.kalam.happy.png` | Captain Kalam, a loud happy pirate parrot with bright green and red feathers, a black eye-patch, a little pirate hat, holding a giant golden feather quill like a sword (raised, not pointed at the viewer). Plain flat white background. |

For each, make a **`char.<id>.talk.png`** by editing the happy image so only the mouth is open (or, for Bolt, the screen face shows an open pixel mouth).

---

## C. Cutscene backgrounds (portrait 1440 × 2560)

| File name | Prompt (after Style block) |
|---|---|
| `bg.cut.tree.png` | The Great Story Tree (Kahani Vriksh) at the centre of a floating island at golden sunset: a giant ancient banyan-like tree with a wide trunk and spreading roots, its leaves glowing like warm golden pages, tiny glowing letters drifting up like fireflies, a small wooden swing on a branch, marigold flowers around the roots, soft clouds below the island. Calm lower third (grass), tree in the upper two thirds. Vertical 9:16. |
| `bg.cut.tree_grey.png` | **Edit of `bg.cut.tree`:** exactly the same scene but drained of colour: grey-blue tones, leaves dull and silent, no glowing letters, overcast sky, a few grey wisps of cloud. Still gentle, not scary. |
| `bg.cut.aksharpur.png` | Wide establishing view of Aksharpur, seven small floating islands in a ring above a sea of soft pink-gold clouds, connected by rope bridges: a jungle island, a purple valley island with kites, an ocean island with a lighthouse, a village island with colourful rooftops, a treasure island with a golden hive, a castle island with pink towers, and a small observatory island with a telescope dome. The Story Tree glows in the middle. Morning light. Vertical 9:16. |
| `bg.cut.night.png` | Stormy but cosy night over Aksharpur: deep indigo sky, swirling grey clouds, a crescent moon, little lightning sparkles far away, islands silhouetted with tiny warm window lights. Not frightening. Vertical 9:16. |
| `bg.cut.forest.png` | A magical Indian jungle path at dusk: tall trees with hanging vines, giant ferns, glowing mushrooms, a tabla and a flute resting on a tree stump, fireflies. Vertical 9:16. |
| `bg.cut.castle.png` | Story Castle: a fairytale pink-and-gold palace inspired by Rajasthani architecture (domes, jharokha windows, arches) floating on a cloud, flags shaped like bookmarks, a big library window glowing. Vertical 9:16. |
| `bg.cut.sea.png` | A sparkling turquoise ocean seen from a cliff edge, gentle waves, a tiny lighthouse, sea-birds, soft afternoon sun. Vertical 9:16. |
| `bg.cut.day.png` | A bright sunny sky above the clouds with a glowing rainbow bridge made of stars arching from bottom left to top right (the Star Bridge), soft gold sparkles. Vertical 9:16. |

---

## D. Island game backgrounds (portrait 1440 × 2560)

These sit behind the games, so keep them **softer and less detailed in the middle and lower third** where cards and tiles appear.

| File name | Island | Prompt (after Style block) |
|---|---|---|
| `bg.island.forest.png` | Sound Forest | Lush green Indian jungle clearing set up as an outdoor music stage: a stage made of a fallen log, drums and a tabla, lanterns strung between trees, big leaves, soft green-gold light rays. Middle area open and softly blurred. Vertical 9:16. |
| `bg.island.valley.png` | Symbol Valley | A purple and lilac mountain valley during a kite festival: colourful kites in the sky, paper lanterns, rolling hills, a small temple-style archery range with straw targets at the far end. Middle area open. Vertical 9:16. |
| `bg.island.ocean.png` | Word Ocean | Underwater turquoise world: sunbeams from the surface, coral reefs in pink and orange, bubbles, a cute submarine-rocket parked on a rock, small fish. Middle area open water. Vertical 9:16. |
| `bg.island.village.png` | Word Village | A colourful Indian village street in the evening: painted houses in orange, blue and pink, a chai stall, shop signboards with **blank** boards (no text), bunting flags, marigold garlands, warm lamp light. Middle area is an open courtyard. Vertical 9:16. |
| `bg.island.treasure.png` | Treasure Island | A sunny tropical island meadow with a giant flowering tree holding a huge golden beehive, honey dripping gently, sunflowers and marigolds, a treasure chest half-buried in the sand, a pirate flag far away. Middle area open grass. Vertical 9:16. |
| `bg.island.castle.png` | Story Castle | Inside a cosy palace library: tall bookshelves, pink-and-gold arches, floating open books, a big round window with sunset light, soft rugs with rangoli patterns. Middle area open floor. Vertical 9:16. |
| `bg.island.observatory.png` | Star Observatory | Night-time observatory dome on a small island: a big brass telescope, star maps on the walls, constellations made of letters in the sky, purple-blue gradient. Middle area open. Vertical 9:16. |

**Grey versions (optional, later):** for each `bg.island.<name>.png`, an edit named `bg.island.<name>.grey.png`: identical scene, drained to grey-blue, flowers closed, no glow.

---

## E. App screens (portrait 1440 × 2560)

| File name | Used on | Prompt (after Style block) |
|---|---|---|
| `bg.day.png` | Welcome and setup screens | A bright happy sky above soft clouds, a few small floating islands far away, a warm sun, gentle gradient from sky blue to peach at the bottom. Very calm, plenty of empty space for buttons. Vertical 9:16. |
| `bg.night.png` | Journal and night screens | A calm starry night sky, deep indigo to purple gradient, tiny stars and a crescent moon, distant floating island silhouettes with warm windows. Very calm, empty space in the middle. Vertical 9:16. |
| `bg.castle.png` | Treasures room | A cosy pink-gold palace room with shelves for collectibles, soft cushions, a window with clouds outside. Calm empty space in the middle. Vertical 9:16. |
| `bg.forest.png` / `bg.ocean.png` / `bg.treasure.png` | General scene variants | Same as the matching island backgrounds above, but even calmer and simpler. |

---

## F. Spelling Hive props (Phase 2a, 512 × 512)

| File name | Prompt (after Style block) |
|---|---|
| `prop.hive.cell_empty.png` | A single hexagonal honeycomb cell seen from the front, empty, pale wax-yellow with a soft inner shadow, thick rounded edge. Plain flat white background. |
| `prop.hive.cell_full.png` | The same hexagonal cell filled with glowing golden honey, a shiny highlight, a tiny drip on the lower edge. Plain flat white background. |
| `prop.hive.tile.png` | A blank rounded-square wooden letter tile carried by a tiny cute worker bee (bee holding the tile from above with its legs), no letter on the tile. Plain flat white background. |
| `prop.hive.baby_bee.png` | A newborn baby bee, super round and fuzzy, tiny wings, huge sparkly eyes, a little bit of honeycomb shell on its head, waving. Plain flat white background. |
| `prop.hive.honey_jar.png` | A small clay honey pot with a cloth cover tied with red string, a wooden dipper, honey dripping down the side. Plain flat white background. |
| `bg.hive.png` (1440 × 2560) | Inside a giant golden beehive: warm amber light, walls of honeycomb, little bees flying in the distance, honey drips, a soft glowing centre where a big honeycomb board will be placed. Calm centre. Vertical 9:16. |

---

## G. Later phases (not needed yet)

Prompts for these will be added to this file when each phase starts:
- the other games' props (Orchestra instruments, lanterns and arrows, rocket parts, detective clue cards…)
- the 11 collection sets (badges, hats, room items, companion friends)
- Story Gems (one per island)
- island tier-up versions (Grow / Flourish / Shine / Legend)
- the world-map island art

---

## Priority order (if you only make a few)
1. `char.milo.happy` + `char.milo.talk` + `char.milo.sad` + `char.milo.surprised` + `char.milo.thinking`
2. `char.gumsum.happy` + `.talk` + `.sad`; `char.dadi.happy` + `.talk`
3. `bg.cut.tree`, `bg.cut.tree_grey`, `bg.cut.aksharpur`, `bg.cut.night`, `bg.cut.day`
4. `char.madhu.happy` + `.talk`, `bg.island.treasure`, the Spelling Hive props (Phase 2a)
5. The other guardians and island backgrounds
