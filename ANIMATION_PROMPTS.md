# Readle — AI Video Prompts (GAME_DESIGN_V3 animations)

Every cinematic in [`GAME_DESIGN_V3.md`](GAME_DESIGN_V3.md) §6, broken into short clips that today's AI video tools can
make well (5–10 seconds each). The app plays the clips in order and adds the **recorded character voices, music and
sound effects on top**, so **every clip must be silent** (or the audio is simply dropped) and must **not contain any text**.

## How to make them (read first)

1. **Make the reference stills first** (section 1). They are normal images, made with the image tool you already use
   (prompts are also in `ART_PROMPTS.md` §O). AI video keeps characters on-model far better when it starts from our own picture.
2. Use an **image-to-video** tool and upload the listed **Start frame** (and **End frame** when the tool supports
   first-and-last frame: Kling, Veo, Runway, Luma and Hailuo do). Paste the **Prompt** and the **Negative prompt**.
3. Settings: **9:16 portrait**, the length listed, highest quality, **no audio** (or mute it), camera motion as listed.
   If the tool has a "creativity / motion strength" slider, keep it **low to medium**: big values make characters change design.
4. Make **3–4 versions** of each clip and keep the one where the characters look most like our pictures.
5. Save each clip as the exact **file name** shown (e.g. `video.prologue.01.mp4`) and put it in `assets/video/`
   (or push it to GitHub). Claude trims, colour-matches, compresses and wires each clip into the app.

**Good tools** (check the licence allows commercial use on the plan you pick): **Kling AI** (best for keeping cartoon
characters on-model; has first+last frame), **Google Veo 3** (via Gemini / Flow; beautiful motion), **Runway Gen-4**
(good control), **Hailuo / MiniMax** (cheap, good 2D motion), **Luma Dream Machine**.

**Rules for every clip:** no scary moments (Gumsum is theatrical, never frightening); no flashing (lightning is soft
cartoon zig-zags); characters must not change colour, clothes or species; no text, letters or subtitles; keep the
centre of the frame clear in the last second (the app may show a title or button there).

---

## 1. Reference stills to make first

| File name | Used as start frame for | Prompt |
|---|---|---|
| `still.tree.keepers` | prologue 02 | see `ART_PROMPTS.md` §O1: the Story Tree at golden evening with the seven Story Keepers standing in a half-circle under it and animals, talking flowers and small happy clouds listening |
| `char.gumsum.villain` | prologue 03–04, trial warning | `ART_PROMPTS.md` §O2: Gumsum as a HUGE theatrical storm cloud |
| `char.milo.injured` | prologue 05, 08 | `ART_PROMPTS.md` §O3: Milo with a bandaged tail |
| `char.jailer.<island>` ×6 | island start, rescue | `ART_PROMPTS.md` §O4: the six Hush Clouds |
| `prop.cage.<island>` ×6 | island start, rescue | `ART_PROMPTS.md` §O5: each Keeper inside a fluffy grey cloud cage |
| `prop.key.gold` | key reveal | `ART_PROMPTS.md` §O6 |
| `still.map.storm` | prologue 09 | `ART_PROMPTS.md` §O1: the six islands under storm clouds |
| `island.citadel` | trial warning | `ART_PROMPTS.md` §O7: the Storm Citadel |
| `char.gumsum.small_sad`, `char.gumsum.redeemed` | finale | `ART_PROMPTS.md` §O2 |

Existing pictures used as frames: `bg.cut.tree`, `bg.cut.tree_grey`, `bg.cut.night`, `bg.cut.aksharpur`, `bg.island.*`,
`island.*`, `char.milo.*`, `char.gumsum.*`, every Keeper's `char.<id>.happy`.

---

## 2. A1 · Prologue: "The Night the Stories Stopped" (9 clips, ≈ 70 s)


#### `video.prologue.01` · The happy realm

| | |
|---|---|
| Length | 8 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `bg.cut.tree` |
| End frame | — |
| Camera | slow gentle push-in toward the tree, very slight parallax |
| Voice-over (added by the app, not in the video) | Dadi Kahani (the Tree): "Long, long ago, high above the clouds, there was a realm called Aksharpur…" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Golden evening in Aksharpur, a floating fantasy realm above the clouds. The Great Story Tree, a giant ancient banyan-like tree whose leaves glow like warm golden pages, stands in the middle of a grassy floating island. Tiny glowing letters drift up from its leaves like fireflies. Around it, cute animals (a rabbit, a peacock, a baby elephant, monkeys), smiling living flowers that sway and bob their petal-heads, and small fluffy white clouds with happy faces gather and sway happily as if listening to music. Everything gently moves: leaves rustle, flowers dance side to side, a rabbit hops once, clouds bounce softly.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.prologue.02` · The seven Story Keepers

| | |
|---|---|
| Length | 8 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `still.tree.keepers` |
| End frame | — |
| Camera | slow pan from left to right across the Keepers, then settle on Milo |
| Voice-over (added by the app, not in the video) | Dadi: "Only seven Story Keepers could hear the Tree. They carried its stories to every animal, flower and cloud." |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Under the glowing Story Tree, the seven Story Keepers stand in a half-circle: Milo the young orange fox with a green scarf in the middle, a brown bear conductor in a red kurta, a girl archer in purple with a golden bow, an old green sea turtle in a captain hat, a round brown owl in a detective hat with a tiny mouse, a regal honeybee queen with a honey-drop crown, and a princess in pink and gold with a blue talking book. One by one each Keeper raises a hand and a ribbon of golden light (a story) flows from the tree through them to the animals and flowers, who smile and sway. Calm, warm, magical.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.prologue.03` · The storm arrives

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `bg.cut.tree` |
| End frame | `bg.cut.night` |
| Camera | slow tilt up from the tree to the sky |
| Voice-over (added by the app, not in the video) | Gumsum (booming, theatrical): "Stories, stories, STORIES! I am sick of stories!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. The golden evening sky slowly darkens to deep indigo. From the horizon a HUGE grumpy grey storm cloud with big angry eyebrows and a theatrical frown rolls in (Gumsum, see reference picture), puffing and growing bigger. Soft cartoon zig-zag lightning bolts appear inside him (no bright flashes). The animals look up surprised and hide behind the tree; the dancing flowers close their petals; the little white clouds scatter away. Wind blows the grass. Dramatic but not scary, like a pantomime villain entering.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


*Notes:* Use `char.gumsum.villain` as an extra reference image if the tool allows character references.


#### `video.prologue.04` · The Keepers are swept away

| | |
|---|---|
| Length | 8 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `still.tree.keepers` (darkened) |
| End frame | — |
| Camera | static wide shot, then slight push in on Milo |
| Voice-over (added by the app, not in the video) | Dadi: "One stormy night, Gumsum swept six Keepers away to his six storm islands…" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Gumsum the giant storm cloud blows a big swirling gust. Six curling grey cloud tendrils like soft ribbons reach down and gently wrap around six of the Story Keepers (the bear, the archer girl, the turtle, the owl with the mouse, the bee queen, the princess with the book), lifting them up into fluffy grey cloud bubbles that float away in six different directions across the night sky. The Keepers look surprised and grumpy rather than frightened. Milo the fox jumps to catch them but misses.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


*Notes:* Keep it gentle: like a cartoon whirlwind, nobody gets hurt.


#### `video.prologue.05` · Milo is left behind

| | |
|---|---|
| Length | 6 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `char.milo.injured` on `bg.cut.night` |
| End frame | — |
| Camera | gentle push-in to a medium close-up of Milo |
| Voice-over (added by the app, not in the video) | Milo: "They're gone… and my tail is too hurt to fly. I can't save them alone." |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Milo the young orange fox with a green scarf tumbles softly onto the grass and sits up, a little dizzy, with a white bandage wrapped around the tip of his fluffy tail. He rubs his head, looks up at the empty sky where the cloud bubbles disappeared, and his ears droop sadly. A couple of cartoon stars circle his head briefly. Night garden, glowing tree behind him dimmer than before.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.prologue.06` · The Tree goes grey

| | |
|---|---|
| Length | 6 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `bg.cut.tree` |
| End frame | `bg.cut.tree_grey` |
| Camera | very slow pull-back to a wide shot |
| Voice-over (added by the app, not in the video) | Dadi: "Without its Keepers, the Tree went silent, and Aksharpur turned grey." |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. The great Story Tree's golden glowing leaves slowly lose their light and fade to grey-blue, one branch at a time, the drifting letters falling silent and disappearing. The flowers around the roots droop; the animals sit down quietly. The colour drains from the whole scene into soft grey, like a picture being washed out by rain.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.prologue.07` · The golden page

| | |
|---|---|
| Length | 6 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `bg.cut.tree_grey` |
| End frame | — |
| Camera | slow push-in into the glowing pages, then hold |
| Voice-over (added by the app, not in the video) | Dadi: "With the very last of its light, the Tree called for help… and you came." |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. In the grey tree trunk a small warm light appears. It grows into a big glowing golden book that floats out and opens by itself; its pages flutter and a bright golden doorway of light opens from the pages, spilling sparkles. A friendly child silhouette (the player, seen from behind, backpack on) tumbles gently out of the light and lands softly on the grass, holding a small glowing paper lantern.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


*Notes:* Keep the child a soft silhouette (the player's own avatar appears in the app afterwards).


#### `video.prologue.08` · Milo meets the Explorer

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `char.milo.injured` on `bg.cut.tree_grey` |
| End frame | — |
| Camera | medium shot, slight sway |
| Voice-over (added by the app, not in the video) | Milo: "You came! Will you help me rescue the Story Keepers? Together we can do it!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Milo the young orange fox with the bandaged tail limps over, then his face lights up with hope. He bounces on the spot, waves both paws, and points excitedly toward the horizon. Behind him the grey Story Tree flickers with one tiny spark of gold. Warm, hopeful mood despite the grey world.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.prologue.09` · Six storm islands

| | |
|---|---|
| Length | 8 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `still.map.storm` |
| End frame | — |
| Camera | slow rising crane-up over the map |
| Voice-over (added by the app, not in the video) | Milo: "Each Keeper is locked on a storm island. Win the keys, and we open the cages!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. A bird's-eye fly-over of the realm: six small floating islands in a ring, each under its own small swirling storm cloud, each with a fluffy grey cloud cage on top with a tiny question-mark silhouette inside. In the middle the grey Story Tree island. A dotted golden path draws itself from the Tree to the first island. Soft lightning zig-zags inside the storm clouds, no flashes.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


---

## 3. A2 · Island start (×6, 2 clips each, ≈ 15 s)


### 3.1 Sound Forest · Keeper: Maestro Bhalu · Jailer: Drizzle


#### `video.start.forest.01` · Arriving at stormy Sound Forest

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `island.forest` (darkened / greyed) — or `bg.island.forest` |
| End frame | — |
| Camera | fast-but-smooth fly-in from far to near, then settle |
| Voice-over (added by the app, not in the video) | Drizzle: "No stories on MY island! Go away!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Fly-in toward a lush jungle island with tall trees, giant ferns, a tree-stump music stage, tabla and drums lying silent, now under a low swirling grey storm cloud: the trees droop, instruments lie silent and grey, fireflies are gone. Soft rain, cartoon zig-zag lightning inside the cloud (no flashes). As we arrive, a small round moss-green storm cloud with a cheeky grumpy face and tiny arms (Drizzle, one of Gumsum's Hush Clouds, holding a cloth draped over a little drum so no music can play) pops up from behind a rock, puffs itself up and wags a finger at the camera.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.start.forest.02` · Maestro Bhalu in the cloud cage

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `prop.cage.forest` |
| End frame | — |
| Camera | slow push-in on the keyhole at the end |
| Voice-over (added by the app, not in the video) | Maestro Bhalu: "Explorer! Over here! Win every key and this lock will open!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Close view of a fluffy grey cloud cage (a round puffy cloud bubble with soft cloud bars and a big golden keyhole lock on the front) floating near the ground. Inside sits a big round friendly brown bear conductor in a red silk kurta with gold buttons, tiny gold bow-tie, small round spectacles, holding a thin baton, looking bored and grumpy rather than scared. The Keeper sees the camera, brightens, waves both hands and presses against the cloud bars. Next to the cage the moss-green Hush Cloud Drizzle floats, arms crossed, and turns away with a huff. The keyhole on the lock glows softly.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


### 3.2 Symbol Valley · Keeper: Arya the Archer · Jailer: Gust


#### `video.start.valley.01` · Arriving at stormy Symbol Valley

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `island.valley` (darkened / greyed) — or `bg.island.valley` |
| End frame | — |
| Camera | fast-but-smooth fly-in from far to near, then settle |
| Voice-over (added by the app, not in the video) | Gust: "No stories on MY island! Go away!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Fly-in toward a purple-and-lilac mountain valley with kites, paper lanterns and a small archery range, now under a low swirling grey storm cloud: the kites are tangled on the ground and every paper lantern is dark. Soft rain, cartoon zig-zag lightning inside the cloud (no flashes). As we arrive, a small round violet storm cloud with a cheeky grumpy face and tiny arms (Gust, one of Gumsum's Hush Clouds, holding a tangle of knotted kite strings) pops up from behind a rock, puffs itself up and wags a finger at the camera.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.start.valley.02` · Arya the Archer in the cloud cage

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `prop.cage.valley` |
| End frame | — |
| Camera | slow push-in on the keyhole at the end |
| Voice-over (added by the app, not in the video) | Arya the Archer: "Explorer! Over here! Win every key and this lock will open!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Close view of a fluffy grey cloud cage (a round puffy cloud bubble with soft cloud bars and a big golden keyhole lock on the front) floating near the ground. Inside sits a confident kind Indian girl of about 12 with a long black braid, purple tunic with gold trim, brown boots and a golden bow, with her friendly eagle Garud (orange scarf), looking bored and grumpy rather than scared. The Keeper sees the camera, brightens, waves both hands and presses against the cloud bars. Next to the cage the violet Hush Cloud Gust floats, arms crossed, and turns away with a huff. The keyhole on the lock glows softly.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


### 3.3 Word Ocean · Keeper: Captain Kachhua · Jailer: Murk


#### `video.start.ocean.01` · Arriving at stormy Word Ocean

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `island.ocean` (darkened / greyed) — or `bg.island.ocean` |
| End frame | — |
| Camera | fast-but-smooth fly-in from far to near, then settle |
| Voice-over (added by the app, not in the video) | Murk: "No stories on MY island! Go away!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Fly-in toward a tropical island that is mostly a turquoise lagoon with a little lighthouse and a yellow rocket-submarine, now under a low swirling grey storm cloud: the lagoon is grey and choppy, the lighthouse lamp is out, the submarine is stuck on the sand. Soft rain, cartoon zig-zag lightning inside the cloud (no flashes). As we arrive, a small round dark teal storm cloud with a cheeky grumpy face and tiny arms (Murk, one of Gumsum's Hush Clouds, holding a heavy rusty anchor on a chain) pops up from behind a rock, puffs itself up and wags a finger at the camera.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.start.ocean.02` · Captain Kachhua in the cloud cage

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `prop.cage.ocean` |
| End frame | — |
| Camera | slow push-in on the keyhole at the end |
| Voice-over (added by the app, not in the video) | Captain Kachhua: "Explorer! Over here! Win every key and this lock will open!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Close view of a fluffy grey cloud cage (a round puffy cloud bubble with soft cloud bars and a big golden keyhole lock on the front) floating near the ground. Inside sits an old friendly green sea turtle with a white bushy moustache, navy captain hat with a gold anchor badge and a brass telescope, looking bored and grumpy rather than scared. The Keeper sees the camera, brightens, waves both hands and presses against the cloud bars. Next to the cage the dark teal Hush Cloud Murk floats, arms crossed, and turns away with a huff. The keyhole on the lock glows softly.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


### 3.4 Word Village · Keeper: Inspector Ullu · Jailer: Smudge


#### `video.start.village.01` · Arriving at stormy Word Village

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `island.village` (darkened / greyed) — or `bg.island.village` |
| End frame | — |
| Camera | fast-but-smooth fly-in from far to near, then settle |
| Voice-over (added by the app, not in the video) | Smudge: "No stories on MY island! Go away!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Fly-in toward a colourful Indian village with painted houses, a chai stall, bunting flags and marigold garlands, now under a low swirling grey storm cloud: every shop signboard is smudged blank, the lamps are out, bunting hangs limp. Soft rain, cartoon zig-zag lightning inside the cloud (no flashes). As we arrive, a small round orange-brown storm cloud with a cheeky grumpy face and tiny arms (Smudge, one of Gumsum's Hush Clouds, holding an ink-blotted signboard with smeared letters) pops up from behind a rock, puffs itself up and wags a finger at the camera.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.start.village.02` · Inspector Ullu in the cloud cage

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `prop.cage.village` |
| End frame | — |
| Camera | slow push-in on the keyhole at the end |
| Voice-over (added by the app, not in the video) | Inspector Ullu: "Explorer! Over here! Win every key and this lock will open!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Close view of a fluffy grey cloud cage (a round puffy cloud bubble with soft cloud bars and a big golden keyhole lock on the front) floating near the ground. Inside sits a serious but lovable round brown owl in a tweed deerstalker hat holding a brass magnifying glass, with his tiny grey mouse friend Chuchu holding a notebook, looking bored and grumpy rather than scared. The Keeper sees the camera, brightens, waves both hands and presses against the cloud bars. Next to the cage the orange-brown Hush Cloud Smudge floats, arms crossed, and turns away with a huff. The keyhole on the lock glows softly.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


### 3.5 Treasure Island · Keeper: Queen Madhu · Jailer: Sulk


#### `video.start.treasure.01` · Arriving at stormy Treasure Island

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `island.treasure` (darkened / greyed) — or `bg.island.treasure` |
| End frame | — |
| Camera | fast-but-smooth fly-in from far to near, then settle |
| Voice-over (added by the app, not in the video) | Sulk: "No stories on MY island! Go away!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Fly-in toward a sunny tropical island with a giant flowering tree holding a golden beehive and a half-buried treasure chest, now under a low swirling grey storm cloud: the hive is silent and grey, honey has stopped flowing, flowers are closed. Soft rain, cartoon zig-zag lightning inside the cloud (no flashes). As we arrive, a small round mustard-yellow storm cloud with a cheeky grumpy face and tiny arms (Sulk, one of Gumsum's Hush Clouds, holding a big honey jar with a padlock) pops up from behind a rock, puffs itself up and wags a finger at the camera.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.start.treasure.02` · Queen Madhu in the cloud cage

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `prop.cage.treasure` |
| End frame | — |
| Camera | slow push-in on the keyhole at the end |
| Voice-over (added by the app, not in the video) | Queen Madhu: "Explorer! Over here! Win every key and this lock will open!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Close view of a fluffy grey cloud cage (a round puffy cloud bubble with soft cloud bars and a big golden keyhole lock on the front) floating near the ground. Inside sits a regal but kind round honeybee queen with soft yellow-brown stripes, shimmering wings, a crown made of a glowing honey drop and a tiny honeycomb cape, looking bored and grumpy rather than scared. The Keeper sees the camera, brightens, waves both hands and presses against the cloud bars. Next to the cage the mustard-yellow Hush Cloud Sulk floats, arms crossed, and turns away with a huff. The keyhole on the lock glows softly.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


### 3.6 Story Castle · Keeper: Princess Pari · Jailer: Hush


#### `video.start.castle.01` · Arriving at stormy Story Castle

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `island.castle` (darkened / greyed) — or `bg.island.castle` |
| End frame | — |
| Camera | fast-but-smooth fly-in from far to near, then settle |
| Voice-over (added by the app, not in the video) | Hush: "No stories on MY island! Go away!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Fly-in toward a pink-and-gold storybook castle with Rajasthani domes and arches on a floating island, flags shaped like bookmarks, now under a low swirling grey storm cloud: the castle is grey, the windows dark, open books lie closed and silent. Soft rain, cartoon zig-zag lightning inside the cloud (no flashes). As we arrive, a small round pinkish-grey storm cloud with a cheeky grumpy face and tiny arms (Hush, one of Gumsum's Hush Clouds, holding a closed storybook locked with a clasp) pops up from behind a rock, puffs itself up and wags a finger at the camera.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.start.castle.02` · Princess Pari in the cloud cage

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `prop.cage.castle` |
| End frame | — |
| Camera | slow push-in on the keyhole at the end |
| Voice-over (added by the app, not in the video) | Princess Pari: "Explorer! Over here! Win every key and this lock will open!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Close view of a fluffy grey cloud cage (a round puffy cloud bubble with soft cloud bars and a big golden keyhole lock on the front) floating near the ground. Inside sits an adventurous Indian princess of about 10 with a long black side braid, pink and gold lehenga, white sneakers and a small golden lantern-shaped crown, with Kitabu the chubby blue talking book with googly eyes, looking bored and grumpy rather than scared. The Keeper sees the camera, brightens, waves both hands and presses against the cloud bars. Next to the cage the pinkish-grey Hush Cloud Hush floats, arms crossed, and turns away with a huff. The keyhole on the lock glows softly.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


---

## 4. A3 · Rescue (×6, 2 clips each, ≈ 14 s)


### 4.1 Rescue of Maestro Bhalu


#### `video.rescue.forest.01` · The cage opens

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `prop.cage.forest` |
| End frame | — |
| Camera | static medium shot, slight zoom-out as the cage bursts |
| Voice-over (added by the app, not in the video) | Maestro Bhalu: "I'm free! Thank you, Explorer!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Golden glowing keys fly in a sparkling stream into the big keyhole of the fluffy grey cloud cage. The lock spins, clicks and bursts in a shower of sparkles; the cloud cage puffs apart into soft cotton-like puffs that float away. Next to it the small moss-green Hush Cloud Drizzle looks shocked, shrinks smaller and smaller and finally pops into a harmless sprinkle of rain drops and a tiny rainbow. Inside, a big round friendly brown bear conductor in a red silk kurta with gold buttons, tiny gold bow-tie, small round spectacles, holding a thin baton stretches, smiles hugely and jumps out free.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.rescue.forest.02` · Sound Forest comes back to life

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `island.forest` greyed |
| End frame | `island.forest` in full colour |
| Camera | slow orbit around the island |
| Voice-over (added by the app, not in the video) | Milo: "Sound Forest is singing again! One more light for the Story Tree!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. A wave of colour sweeps across a lush jungle island with tall trees, giant ferns, a tree-stump music stage, tabla and drums lying silent, washing away the grey: the band instruments start playing by themselves, fireflies swirl, flowers open in rhythm. The storm cloud overhead breaks up into fluffy white clouds and sunshine. Maestro Bhalu does a happy celebration dance in the middle, joined by Milo the orange fox (bandaged tail) and Pip the red-panda ninja (black headband, leaf sword). A golden light beam shoots up from the island into the sky toward the distant Story Tree.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


### 4.2 Rescue of Arya the Archer


#### `video.rescue.valley.01` · The cage opens

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `prop.cage.valley` |
| End frame | — |
| Camera | static medium shot, slight zoom-out as the cage bursts |
| Voice-over (added by the app, not in the video) | Arya the Archer: "I'm free! Thank you, Explorer!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Golden glowing keys fly in a sparkling stream into the big keyhole of the fluffy grey cloud cage. The lock spins, clicks and bursts in a shower of sparkles; the cloud cage puffs apart into soft cotton-like puffs that float away. Next to it the small violet Hush Cloud Gust looks shocked, shrinks smaller and smaller and finally pops into a harmless sprinkle of rain drops and a tiny rainbow. Inside, a confident kind Indian girl of about 12 with a long black braid, purple tunic with gold trim, brown boots and a golden bow, with her friendly eagle Garud (orange scarf) stretches, smiles hugely and jumps out free.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.rescue.valley.02` · Symbol Valley comes back to life

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `island.valley` greyed |
| End frame | `island.valley` in full colour |
| Camera | slow orbit around the island |
| Voice-over (added by the app, not in the video) | Milo: "Symbol Valley is singing again! One more light for the Story Tree!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. A wave of colour sweeps across a purple-and-lilac mountain valley with kites, paper lanterns and a small archery range, washing away the grey: hundreds of paper lanterns light up and float into the sky, kites fly again. The storm cloud overhead breaks up into fluffy white clouds and sunshine. Arya the Archer does a happy celebration dance in the middle, joined by Milo the orange fox (bandaged tail) and Bolt the round teal tin robot on one wheel. A golden light beam shoots up from the island into the sky toward the distant Story Tree.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


### 4.3 Rescue of Captain Kachhua


#### `video.rescue.ocean.01` · The cage opens

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `prop.cage.ocean` |
| End frame | — |
| Camera | static medium shot, slight zoom-out as the cage bursts |
| Voice-over (added by the app, not in the video) | Captain Kachhua: "I'm free! Thank you, Explorer!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Golden glowing keys fly in a sparkling stream into the big keyhole of the fluffy grey cloud cage. The lock spins, clicks and bursts in a shower of sparkles; the cloud cage puffs apart into soft cotton-like puffs that float away. Next to it the small dark teal Hush Cloud Murk looks shocked, shrinks smaller and smaller and finally pops into a harmless sprinkle of rain drops and a tiny rainbow. Inside, an old friendly green sea turtle with a white bushy moustache, navy captain hat with a gold anchor badge and a brass telescope stretches, smiles hugely and jumps out free.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.rescue.ocean.02` · Word Ocean comes back to life

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `island.ocean` greyed |
| End frame | `island.ocean` in full colour |
| Camera | slow orbit around the island |
| Voice-over (added by the app, not in the video) | Milo: "Word Ocean is singing again! One more light for the Story Tree!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. A wave of colour sweeps across a tropical island that is mostly a turquoise lagoon with a little lighthouse and a yellow rocket-submarine, washing away the grey: the lighthouse flashes on, the lagoon turns sparkling turquoise, dolphins and fish leap. The storm cloud overhead breaks up into fluffy white clouds and sunshine. Captain Kachhua does a happy celebration dance in the middle, joined by Milo the orange fox (bandaged tail) and Coral the pink octopus builder in a yellow hard hat. A golden light beam shoots up from the island into the sky toward the distant Story Tree.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


### 4.4 Rescue of Inspector Ullu


#### `video.rescue.village.01` · The cage opens

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `prop.cage.village` |
| End frame | — |
| Camera | static medium shot, slight zoom-out as the cage bursts |
| Voice-over (added by the app, not in the video) | Inspector Ullu: "I'm free! Thank you, Explorer!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Golden glowing keys fly in a sparkling stream into the big keyhole of the fluffy grey cloud cage. The lock spins, clicks and bursts in a shower of sparkles; the cloud cage puffs apart into soft cotton-like puffs that float away. Next to it the small orange-brown Hush Cloud Smudge looks shocked, shrinks smaller and smaller and finally pops into a harmless sprinkle of rain drops and a tiny rainbow. Inside, a serious but lovable round brown owl in a tweed deerstalker hat holding a brass magnifying glass, with his tiny grey mouse friend Chuchu holding a notebook stretches, smiles hugely and jumps out free.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.rescue.village.02` · Word Village comes back to life

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `island.village` greyed |
| End frame | `island.village` in full colour |
| Camera | slow orbit around the island |
| Voice-over (added by the app, not in the video) | Milo: "Word Village is singing again! One more light for the Story Tree!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. A wave of colour sweeps across a colourful Indian village with painted houses, a chai stall, bunting flags and marigold garlands, washing away the grey: the signboards light up with their words, lamps glow, bunting flutters, villagers wave. The storm cloud overhead breaks up into fluffy white clouds and sunshine. Inspector Ullu does a happy celebration dance in the middle, joined by Milo the orange fox (bandaged tail) and Jugnu the tiny glowing firefly. A golden light beam shoots up from the island into the sky toward the distant Story Tree.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


### 4.5 Rescue of Queen Madhu


#### `video.rescue.treasure.01` · The cage opens

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `prop.cage.treasure` |
| End frame | — |
| Camera | static medium shot, slight zoom-out as the cage bursts |
| Voice-over (added by the app, not in the video) | Queen Madhu: "I'm free! Thank you, Explorer!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Golden glowing keys fly in a sparkling stream into the big keyhole of the fluffy grey cloud cage. The lock spins, clicks and bursts in a shower of sparkles; the cloud cage puffs apart into soft cotton-like puffs that float away. Next to it the small mustard-yellow Hush Cloud Sulk looks shocked, shrinks smaller and smaller and finally pops into a harmless sprinkle of rain drops and a tiny rainbow. Inside, a regal but kind round honeybee queen with soft yellow-brown stripes, shimmering wings, a crown made of a glowing honey drop and a tiny honeycomb cape stretches, smiles hugely and jumps out free.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.rescue.treasure.02` · Treasure Island comes back to life

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `island.treasure` greyed |
| End frame | `island.treasure` in full colour |
| Camera | slow orbit around the island |
| Voice-over (added by the app, not in the video) | Milo: "Treasure Island is singing again! One more light for the Story Tree!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. A wave of colour sweeps across a sunny tropical island with a giant flowering tree holding a golden beehive and a half-buried treasure chest, washing away the grey: honey glows and drips, baby bees zoom out of the hive, sunflowers turn to the sun. The storm cloud overhead breaks up into fluffy white clouds and sunshine. Queen Madhu does a happy celebration dance in the middle, joined by Milo the orange fox (bandaged tail) and Captain Kalam the green-and-red pirate parrot with an eye-patch and a golden quill. A golden light beam shoots up from the island into the sky toward the distant Story Tree.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


### 4.6 Rescue of Princess Pari


#### `video.rescue.castle.01` · The cage opens

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `prop.cage.castle` |
| End frame | — |
| Camera | static medium shot, slight zoom-out as the cage bursts |
| Voice-over (added by the app, not in the video) | Princess Pari: "I'm free! Thank you, Explorer!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Golden glowing keys fly in a sparkling stream into the big keyhole of the fluffy grey cloud cage. The lock spins, clicks and bursts in a shower of sparkles; the cloud cage puffs apart into soft cotton-like puffs that float away. Next to it the small pinkish-grey Hush Cloud Hush looks shocked, shrinks smaller and smaller and finally pops into a harmless sprinkle of rain drops and a tiny rainbow. Inside, an adventurous Indian princess of about 10 with a long black side braid, pink and gold lehenga, white sneakers and a small golden lantern-shaped crown, with Kitabu the chubby blue talking book with googly eyes stretches, smiles hugely and jumps out free.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.rescue.castle.02` · Story Castle comes back to life

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `island.castle` greyed |
| End frame | `island.castle` in full colour |
| Camera | slow orbit around the island |
| Voice-over (added by the app, not in the video) | Milo: "Story Castle is singing again! One more light for the Story Tree!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. A wave of colour sweeps across a pink-and-gold storybook castle with Rajasthani domes and arches on a floating island, flags shaped like bookmarks, washing away the grey: books fly open and pages flutter out like birds, the castle windows glow, flags wave. The storm cloud overhead breaks up into fluffy white clouds and sunshine. Princess Pari does a happy celebration dance in the middle, joined by Milo the orange fox (bandaged tail) and Kitabu the chubby blue talking book. A golden light beam shoots up from the island into the sky toward the distant Story Tree.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


---

## 5. A4 · Storm Trial warning (3 clips, ≈ 22 s)


#### `video.trial.01` · All six Keepers together

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `still.tree.keepers` (Tree half-lit) |
| End frame | — |
| Camera | slow push-in then tilt toward the horizon |
| Voice-over (added by the app, not in the video) | Dadi: "Six Keepers are free! But Gumsum still holds the last island…" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Under the Story Tree, now half golden and half grey, the six rescued Story Keepers stand with Milo the fox (bandaged tail) and the player's silhouette. They cheer, high-five and hug; the tree glows brighter with six lights. Then everyone turns to look at the horizon, where dark clouds gather.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.trial.02` · The Storm Citadel rises

| | |
|---|---|
| Length | 8 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `island.citadel` |
| End frame | — |
| Camera | slow rise with the island, then hold on Gumsum |
| Voice-over (added by the app, not in the video) | Gumsum: "So you freed my prisoners? Then face my STORM TRIAL!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. A seventh floating island rises out of a sea of dark clouds: an old observatory with a brass telescope dome, now wrapped in a huge spiralling storm. Soft cartoon lightning zig-zags circle it like a crown (no flashes). On top, Gumsum the huge theatrical grey storm cloud with angry eyebrows grows bigger and bigger and points down at the camera.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.trial.03` · The challenge

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `char.gumsum.villain` on `island.citadel` |
| End frame | — |
| Camera | push-in on Gumsum, cut-like whip pan to Milo |
| Voice-over (added by the app, not in the video) | Gumsum: "Thirty questions. Answer TWENTY-ONE right and my storm breaks. Fail, and it stays forever!" / Milo: "We can do this together!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Close-up of Gumsum the giant storm cloud with a smug grin, holding up a glowing scroll made of cloud (blank, no text). He waves it dramatically; a ring of 30 small glowing star-shaped lights appears around him in a circle (the questions), 21 of them pulse brighter in a row. Then Milo the orange fox steps in front of the camera, determined, fists up, ears high.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


*Notes:* The app shows the big card "Storm Trial · 30 questions · score 21 to win" over the last second, so keep the centre clear.


---

## 6. A5 · Finale and Gumsum's redemption (5 clips, ≈ 40 s)


#### `video.finale.01` · The storm breaks

| | |
|---|---|
| Length | 8 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `island.citadel` |
| End frame | — |
| Camera | wide shot, slow push-in |
| Voice-over (added by the app, not in the video) | Dadi: "Every story you read became light…" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. A brilliant (but soft, not flashing) beam of golden story-light rises from the Story Tree far away, passes through the seven Story Keepers standing in a line (each one glows as it passes), and hits the giant storm around the Citadel. The storm cracks like a breaking egg shell made of cloud, light pours through the cracks, and it bursts into thousands of soft sparkles.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.finale.02` · Gumsum, small and alone

| | |
|---|---|
| Length | 8 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `char.gumsum.small_sad` on `island.citadel` (clear sky) |
| End frame | — |
| Camera | slow push-in on Gumsum's face |
| Voice-over (added by the app, not in the video) | Gumsum (small voice): "Nobody… ever told me a story. Everyone else had stories. I only had thunder." |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Where the giant storm was, a small grey cloud (Gumsum, now tiny, with big sad watery eyes, no eyebrows of anger anymore) floats alone, sniffling, a single raindrop falling. He hugs himself. Milo the orange fox with the bandaged tail and the six Keepers walk up gently and sit down around him in a circle; nobody is angry.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.finale.03` · His first story

| | |
|---|---|
| Length | 8 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `char.gumsum.small_sad` |
| End frame | `char.gumsum.redeemed` |
| Camera | orbit slowly around the circle |
| Voice-over (added by the app, not in the video) | Milo: "Then here is your first story, Gumsum…" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Princess Pari opens her blue talking book Kitabu, and golden letters float out of the pages like butterflies toward the small grey cloud. The Keepers lean in, telling a story with big friendly gestures. Gumsum listens; his eyes go wide with wonder; little by little his grey colour warms to soft white and then glowing gold, starting from his cheeks. The letters swirl inside him like happy fireflies.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.finale.04` · The rain cloud of the Tree

| | |
|---|---|
| Length | 8 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `char.gumsum.redeemed` |
| End frame | `bg.cut.tree` |
| Camera | rising crane from the ground up to the tree crown |
| Voice-over (added by the app, not in the video) | Gumsum: "May I stay… and water the Story Tree, and listen every evening?" / Dadi: "Of course. Everyone deserves a story." |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Gumsum, now a soft glowing white-gold cloud with a shy smile, floats up above the Story Tree and gently rains sparkling drops on it. The tree bursts into full golden glow, new leaves sprouting, flowers blooming around the roots. Animals, living flowers and little clouds cheer and dance. Gumsum giggles and makes a tiny rainbow.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


#### `video.finale.05` · Celebration

| | |
|---|---|
| Length | 8 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `bg.cut.aksharpur` |
| End frame | — |
| Camera | slow pull-back to the widest shot |
| Voice-over (added by the app, not in the video) | Milo: "You did it, Explorer! Aksharpur is full of stories again!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Aksharpur fully restored: seven floating islands in full colour connected by rope bridges, lanterns, kites and fireworks of soft light, the Story Tree glowing in the middle with a friendly white-gold cloud above it. Milo (bandage off his tail now!) and the seven Keepers wave goodbye to the camera from the bridge. Hold on a beautiful wide shot for the last two seconds.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


*Notes:* The app shows the season badge over the last seconds.


---

## 7. A6 · Storm Trial: not yet (1 clip, ≈ 7 s)


#### `video.trial.retry` · The storm holds… for now

| | |
|---|---|
| Length | 7 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `char.gumsum.villain` on `island.citadel` |
| End frame | — |
| Camera | static medium shot |
| Voice-over (added by the app, not in the video) | Gumsum: "Ha! My storm holds… for now!" / Milo: "So close! Let's practise and try again!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. Gumsum the giant storm cloud chuckles and puffs up, but a little crack of golden light already shows in his storm. In front, Milo the orange fox and the six Keepers cheer the player on with thumbs up and fist pumps, not disappointed at all. Friendly, encouraging mood.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


---

## 8. Small extras (optional, 1 clip each)


#### `video.key.reveal` · The magic key

| | |
|---|---|
| Length | 5 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | `prop.key.gold` |
| End frame | — |
| Camera | static, the key rotates |
| Voice-over (added by the app, not in the video) | — |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. A single ornate golden key with a tiny Story-Tree leaf on its handle floats and slowly spins on a deep green glowing background with soft light rays, small sparkles twinkling around it, gently growing bigger. Loopable.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


*Notes:* Played before the first level of the first island, and as a loop behind the key counter.


#### `video.unlock.second` · A friend joins

| | |
|---|---|
| Length | 5 s |
| Aspect | 9:16 portrait, 1080×1920, 24–30 fps |
| Start frame | the second-game host picture (e.g. `char.pip.happy`) on its island background |
| End frame | — |
| Camera | static |
| Voice-over (added by the app, not in the video) | Friend: "A new game is open! Come and play!" |


**Prompt**

> 2D storybook cartoon animation for children aged 5–10, soft 2.5D painted style, rounded chunky shapes, thick friendly dark-indigo outlines, warm gradients, gentle rim light, bright cheerful colours, smooth limited animation like a children's TV show (Nessy / Peppa-style simplicity), characters stay exactly on-model, consistent proportions, no text on screen. The island friend character pops into view with a bright colourful burst behind them (like a sticker with a white outline popping out of a colour flash), waves happily and points to the right where the new game is. Loopable ending.


**Negative prompt:** realistic, photographic, 3D plastic render, horror, scary faces, sharp teeth, blood, weapons pointed at camera, flashing strobe lights, fast flicker, extra limbs, extra fingers, melting faces, morphing characters, characters changing design, text, letters, subtitles, watermark, logo, camera shake, motion blur smears


*Notes:* One clip per friend: Pip, Bolt, Coral, Jugnu, Kalam (file `video.unlock.<friend>.mp4`).


---

## Checklist (48 clip files)

| Group | Clips | Files |
|---|---|---|
| Prologue | 9 | `video.prologue.01` … `09` |
| Island start | 12 | `video.start.<island>.01/02` |
| Rescue | 12 | `video.rescue.<island>.01/02` |
| Trial warning | 3 | `video.trial.01` … `03` |
| Finale | 5 | `video.finale.01` … `05` |
| Trial retry | 1 | `video.trial.retry` |
| Extras | 1 + 5 | `video.key.reveal`, `video.unlock.<friend>` |

Island ids: `forest`, `valley`, `ocean`, `village`, `treasure`, `castle`. Until a clip exists the app plays the
same moment as a code cutscene built from our pictures, so clips can arrive in any order.
