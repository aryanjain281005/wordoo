#!/usr/bin/env python3
"""Builds the Story v3 cutscene JSON (assets/cutscenes/*.json) and the new narration lines (assets/story/lines_en.json).

    python3 tool/build_scenes.py        then   ENGINE=eleven python3 tool/gen_voices.py   (voices only the new lines)

Sound Forest and Word Village are the two showpiece islands (longer, layered sequences); the other four islands share
one shorter template. Everything is code-animated by the cutscene engine (lib/story/cutscene.dart): camera moves,
particles, character motion, timed sound cues, colour wave. Edit here, not the JSON.
"""
import json, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CUT = os.path.join(ROOT, "assets/cutscenes")
LINES = os.path.join(ROOT, "assets/story/lines_en.json")
lines = json.load(open(LINES))


def line(lid, who, text):
    lines[lid] = {"who": who, "text": text}
    return lid


def c(id, x=.5, size=.4, mood=None, **k):
    d = {"id": id, "x": x, "size": size}
    if mood: d["mood"] = mood
    d.update(k)
    return d


def shot(bg, ms, cast=(), ln=None, fx="none", cues=(), zoom=(1, 1.08), panx=(0, 0), pany=(0, 0), **k):
    d = {"bg": bg, "fx": fx, "ms": ms, "camera": {"zoom": list(zoom), "pan": list(pany), "panx": list(panx)}, "cast": list(cast)}
    if ln: d["line"] = ln
    if cues: d["sfx"] = [{"id": i, "at": a, "vol": v} if not isinstance(i, dict) else i for i, a, v in cues]
    d.update(k)
    return d


def save(name, title, shots, music=None):
    d = {"title": title, "shots": shots}
    if music: d["music"] = music
    json.dump(d, open(os.path.join(CUT, f"{name}.json"), "w"), indent=1, ensure_ascii=False)


STORM = lambda i: f"art:bg.island.{i}~storm"
CLEAR = lambda i: f"art:bg.island.{i}"
MILO_HURT = "injured"

# ---------------------------------------------------------------- new narration lines
line("v3_pro_2b", "dadi", "Seven friends carried my stories: Milo the fox, Maestro Bhalu, Arya, Captain Kachhua, Inspector Ullu, Queen Madhu and Princess Pari.")
line("v3_fin_7", "dadi", "And so the storm became rain, the rain became flowers, and Aksharpur sang until morning. The end... or perhaps, a new beginning.")
line("v3_gen_r2", "dadi", "Click, click, click! The last key turns, and the cloud cage bursts into soft, fluffy puffs!")
line("v3_gen_r5", "dadi", "A new light glows in my branches. I can feel the stories coming home.")

# ---------------------------------------------------------------- SOUND FOREST (showpiece)
line("v3_sf_s1", "dadi", "High in the clouds floats Sound Forest, where every tree hums and every leaf has a song.")
line("v3_sf_s2", "milo", "But listen... it is so quiet. Where is the music?")
line("v3_sf_s5", "dadi", "The little band has gone silent. Tinku, Koyal and Gajju are waiting for their Maestro.")
line("v3_sf_s7", "dadi", "Win the keys, wake the band, and the whole forest will sing again.")
line("v3_sf_r2", "dadi", "The cage bursts open, and out hops Maestro Bhalu, ready to conduct!")
line("v3_sf_r5", "bhalu", "One, two, three, and a-ONE! Tinku, Koyal, Gajju, wake up, my friends!")
line("v3_sf_r7", "dadi", "Hear that? The whole forest is singing, and the first light of the Story Tree is glowing.")

save("island_start_forest", "Sound Forest: the storm island", [
    shot(STORM("forest"), 5200, fx="rain+mist", title="Sound Forest", bars=True, zoom=(1.0, 1.22), pany=(0.0, -0.03), ln=line("v3_sf_s1", "dadi", lines["v3_sf_s1"]["text"]),
         cues=[("wind_soft", 0, .5), ("thunder_soft", 900, .5), ("leaves_rustle", 2800, .35)], shake=.3),
    shot(STORM("forest"), 4000, fx="mist+dust", zoom=(1.12, 1.0), panx=(.04, -.04), bars=True, ln="v3_sf_s2",
         cast=[c("milo", .5, .42, MILO_HURT, enter="left", act="sway")], cues=[("owl_hoot", 800, .35)]),
    shot(STORM("forest"), 4200, fx="rain+lightning", shake=1, zoom=(1.2, 1.0), ln="v3_start_forest_1",
         cast=[c("jailer_forest", .5, .5, y=.25, enter="pop", act="float")], cues=[("thunder_soft", 0, .7), ("cloud_whoosh", 100, .6), ("drum_low", 1600, .5)]),
    shot(STORM("forest"), 4600, fx="rain+mist", panx=(.05, -.05), zoom=(1.1, 1.14), ln="v3_start_forest_2",
         cast=[c("bhalu", .36, .52, "sad", cage="closed", act="sway"), c("jailer_forest", .8, .26, y=.3, enter="right", act="float", delay=500)], cues=[("cage_creak", 600, .5)]),
    shot(STORM("forest"), 4800, fx="mist+dust", panx=(-.03, .03), zoom=(1.05, 1.12), ln="v3_sf_s5",
         cast=[c("tinku", .22, .3, "sad", act="sway", y=.12), c("koyal", .5, .3, "sad", act="sway", delay=500, y=.18), c("gajju", .78, .34, "sad", act="sway", delay=1000, y=.12)]),
    shot(STORM("forest"), 4200, fx="sparkle", ln="v3_start_forest_3", zoom=(1, 1.1),
         cast=[c("milo", .5, .44, MILO_HURT, enter="left", act="bounce")], cues=[("key_turn", 1200, .6), ("sparkle", 1500, .5)]),
    shot(CLEAR("forest"), 4800, fx="fireflies+notes+rays", ln="v3_sf_s7", zoom=(1.0, 1.14), panx=(-.04, .04), bars=True,
         cast=[c("milo", .26, .36, "happy", act="hop"), c("bhalu", .74, .4, "happy", cage="closed", act="sway")],
         cues=[("forest_wake", 0, .6), ("marimba_1", 1500, .5), ("marimba_3", 1800, .5), ("marimba_5", 2100, .5), ("firefly_chime", 2600, .4)]),
], music="music.forest")

save("rescue_forest", "Sound Forest: freed", [
    shot(STORM("forest"), 4200, fx="keys+rain", ln="v3_rescue_forest_1", zoom=(1.05, 1.18), shake=.5,
         cast=[c("bhalu", .4, .5, "sad", cage="open"), c("jailer_forest", .8, .3, "surprised", y=.3, act="shake")],
         cues=[("key_turn", 0, .7), ("key_turn", 700, .6), ("key_turn", 1400, .6), ("cage_burst", 2400, .8), ("fruit_pop", 3200, .6)]),
    shot(STORM("forest"), 4200, fx="sparkle+rays", ln="v3_sf_r2", zoom=(1.2, 1.0), bars=True,
         cast=[c("bhalu", .5, .5, "happy", cage="open", burst=True, act="hop")], cues=[("cage_burst", 0, .7), ("band_join", 1400, .5)]),
    shot(CLEAR("forest"), 4600, fx="colour+sparkle+leaves", ln="v3_rescue_forest_2", zoom=(1, 1.1),
         cast=[c("bhalu", .5, .5, "happy", act="wave")], cues=[("colour_wave", 0, .7), ("forest_wake", 400, .6), ("bird_1", 2400, .5), ("bird_2", 3200, .4)]),
    shot(CLEAR("forest"), 5200, fx="notes+fireflies+leaves", ln="v3_sf_r5", zoom=(1.0, 1.12), panx=(-.03, .03),
         cast=[c("bhalu", .5, .46, "happy", act="wave"), c("tinku", .2, .27, act="hop", delay=900), c("koyal", .8, .27, act="bounce", delay=1500), c("gajju", .65, .3, act="hop", delay=2100)],
         cues=[("marimba_2", 900, .6), ("bird_1", 1500, .6), ("drum_mid", 2100, .7), ("shaker", 2800, .4), ("flute_trill", 3400, .5)]),
    shot(CLEAR("forest"), 4600, fx="notes+rays+fireflies+petals", ln="v3_rescue_forest_3", zoom=(1.1, 1.0), bars=True,
         cast=[c("milo", .26, .38, "cheer", act="hop"), c("bhalu", .52, .44, act="wave"), c("tinku", .8, .22, act="bounce"), c("koyal", .12, .2, act="hop", y=.35)],
         cues=[("band_join", 0, .7), ("firefly_chime", 900, .5), ("island_restore", 1800, .7)]),
    shot("tree", 5000, fx="sparkle+rays", ln="v3_sf_r7", zoom=(1.0, 1.15),
         cues=[("story_swell", 0, .5), ("magic", 800, .5), ("bell", 1400, .5)]),
], music="music.forest")

# ---------------------------------------------------------------- WORD VILLAGE (showpiece)
line("v3_wv_s1", "dadi", "Word Village is where every word has a home: on signs, on shop fronts, on little wooden doors.")
line("v3_wv_s2", "milo", "But look! Every sign is a blotchy smudge. Nobody can read a thing.")
line("v3_wv_s5", "dadi", "Even the letters are lost, wandering around like puzzled little ducklings.")
line("v3_wv_s7", "ullu", "Find the clues, solve the cases, and every word will shine again! Hoo-hoo!")
line("v3_wv_r2", "dadi", "Click! The last key turns, and Inspector Ullu's cage melts away like morning mist.")
line("v3_wv_r4", "dadi", "One by one the signs shine clear: BAKERY, LIBRARY, SCHOOL. Every word is home again.")
line("v3_wv_r5", "ullu", "Case closed! Splendid work, young detective. Hoo-hoo!")

save("island_start_village", "Word Village: the storm island", [
    shot(STORM("village"), 5000, fx="rain+mist", title="Word Village", bars=True, zoom=(1.0, 1.2), pany=(0, -.03), ln="v3_wv_s1",
         cues=[("wind_soft", 0, .4), ("thunder_soft", 900, .5), ("sign_creak", 2500, .5), ("door_creak", 3300, .3)], shake=.3),
    shot(STORM("village"), 4000, fx="dust+mist", zoom=(1.1, 1.0), panx=(.05, -.05), ln="v3_wv_s2", bars=True,
         cast=[c("milo", .5, .42, MILO_HURT, enter="left", act="sway")], cues=[("sign_creak", 400, .5), ("paper_rustle", 2000, .4)]),
    shot(STORM("village"), 4200, fx="rain+lightning", shake=1, zoom=(1.2, 1.0), ln="v3_start_village_1",
         cast=[c("jailer_village", .5, .5, y=.25, enter="pop", act="float")], cues=[("thunder_soft", 0, .7), ("cloud_whoosh", 100, .6), ("ink_blot", 1500, .8), ("ink_blot", 2300, .6)]),
    shot(STORM("village"), 4600, fx="rain+mist", panx=(.05, -.05), zoom=(1.1, 1.14), ln="v3_start_village_2",
         cast=[c("ullu", .36, .52, "sad", cage="closed", act="sway"), c("jailer_village", .8, .26, y=.3, enter="right", act="float", delay=500)], cues=[("cage_creak", 600, .5)]),
    shot(STORM("village"), 4800, fx="letters+mist", zoom=(1.0, 1.12), panx=(-.03, .03), ln="v3_wv_s5", cues=[("paper_rustle", 300, .4), ("quill_write", 2200, .4)]),
    shot(STORM("village"), 4200, fx="sparkle", ln="v3_start_village_3", zoom=(1, 1.1),
         cast=[c("milo", .5, .44, MILO_HURT, enter="left", act="bounce")], cues=[("key_turn", 1200, .6), ("sparkle", 1500, .5)]),
    shot(CLEAR("village"), 4800, fx="lanterns+dust+rays", ln="v3_wv_s7", zoom=(1.0, 1.14), panx=(-.04, .04), bars=True,
         cast=[c("ullu", .72, .42, "happy", cage="closed", act="sway"), c("milo", .26, .34, "happy", act="hop")],
         cues=[("lantern_glow", 0, .6), ("market_bell", 1400, .5), ("magnifier_ting", 2600, .5), ("clue_found", 3200, .5)]),
], music="music.village")

save("rescue_village", "Word Village: freed", [
    shot(STORM("village"), 4200, fx="keys+rain", ln="v3_rescue_village_1", zoom=(1.05, 1.18), shake=.5,
         cast=[c("ullu", .4, .5, "sad", cage="open"), c("jailer_village", .8, .3, "surprised", y=.3, act="shake")],
         cues=[("key_turn", 0, .7), ("key_turn", 700, .6), ("key_turn", 1400, .6), ("cage_burst", 2400, .8), ("fruit_pop", 3200, .6)]),
    shot(STORM("village"), 4200, fx="sparkle+rays", ln="v3_wv_r2", zoom=(1.2, 1.0), bars=True,
         cast=[c("ullu", .5, .5, "happy", cage="open", burst=True, act="hop")], cues=[("cage_burst", 0, .7), ("market_bell", 1400, .5)]),
    shot(CLEAR("village"), 4600, fx="colour+sparkle+letters", ln="v3_rescue_village_2", zoom=(1, 1.1),
         cast=[c("ullu", .5, .5, "happy", act="wave")], cues=[("colour_wave", 0, .7), ("magnifier_ting", 1800, .5), ("pencil_scratch", 2600, .4)]),
    shot("art:bg.flash.bazaar", 5200, fx="letters+lanterns+dust", ln="v3_wv_r4", zoom=(1.0, 1.14), panx=(-.04, .04),
         cues=[("market_bell", 300, .5), ("pencil_scratch", 1200, .4), ("clue_found", 2400, .6), ("lantern_glow", 3400, .5)]),
    shot(CLEAR("village"), 4200, fx="confetti+sparkle", ln="v3_wv_r5", zoom=(1.05, 1.0), card="CASE CLOSED ✔",
         cast=[c("ullu", .5, .4, "happy", act="hop", y=-.05)], cues=[("stamp_thud", 700, .9), ("reward_fanfare", 900, .5)]),
    shot(CLEAR("village"), 4600, fx="lanterns+rays+petals", ln="v3_rescue_village_3", zoom=(1.1, 1.0), bars=True,
         cast=[c("milo", .26, .38, "cheer", act="hop"), c("ullu", .6, .44, act="wave")], cues=[("island_restore", 0, .7), ("firefly_chime", 1200, .4)]),
    shot("tree", 5000, fx="sparkle+rays", ln="v3_gen_r5", zoom=(1.0, 1.15), cues=[("story_swell", 0, .5), ("magic", 800, .5), ("bell", 1400, .5)]),
], music="music.village")

# ---------------------------------------------------------------- the other four islands (shared, shorter template)
GEN = {
    "valley": ("Symbol Valley", "arya", "fx_s", "Symbol Valley is the home of every letter, from sleepy A to zippy Z.", "Together we will make every letter shine again!", "letters+petals", ["wind_soft", "page_whoosh"], "music.valley"),
    "ocean": ("Word Ocean", "kachhua", "", "Word Ocean is where little sounds swim together and blend into words.", "Ahoy, Explorer! Full sail to the next key!", "mist+sparkle", ["bubble", "wind_soft"], "music.ocean"),
    "treasure": ("Treasure Island", "madhu", "", "On Treasure Island every word is a treasure, and every treasure is spelled just so.", "Bzzz! Sweet success is only a few keys away!", "embers+dust", ["coins", "wind_soft"], "music.treasure"),
    "castle": ("Story Castle", "pari", "", "Story Castle is where stories live, with a tower for every tale.", "Every story is waiting. Let us open them all!", "dust+rays", ["book_open", "wind_soft"], "music.castle"),
}
for isl, (title, keeper, _, est, hope, fxs, ambient, mus) in GEN.items():
    s1 = line(f"v3_gen_s1_{isl}", "dadi", est)
    s5 = line(f"v3_gen_s5_{isl}", keeper, hope)
    bg_storm = STORM(isl)
    save(f"island_start_{isl}", f"{title}: the storm island", [
        shot(bg_storm, 4800, fx="rain+mist", title=title, bars=True, zoom=(1.0, 1.2), ln=s1, shake=.3, cues=[(ambient[1], 0, .45), ("thunder_soft", 800, .5), (ambient[0], 2800, .4)]),
        shot(bg_storm, 4000, fx="rain+lightning", shake=1, zoom=(1.2, 1.0), ln=f"v3_start_{isl}_1", cast=[c(f"jailer_{isl}", .5, .5, y=.25, enter="pop", act="float")], cues=[("thunder_soft", 0, .7), ("cloud_whoosh", 100, .6)]),
        shot(bg_storm, 4600, fx="rain+mist", panx=(.05, -.05), zoom=(1.1, 1.14), ln=f"v3_start_{isl}_2",
             cast=[c(keeper, .36, .52, "sad", cage="closed", act="sway"), c(f"jailer_{isl}", .8, .26, y=.3, enter="right", act="float", delay=500)], cues=[("cage_creak", 600, .5)]),
        shot(bg_storm, 4200, fx="sparkle", zoom=(1, 1.1), ln=f"v3_start_{isl}_3", cast=[c("milo", .5, .44, MILO_HURT, enter="left", act="bounce")], cues=[("key_turn", 1200, .6), ("sparkle", 1500, .5)]),
        shot(CLEAR(isl), 4400, fx=fxs + "+rays", zoom=(1.0, 1.14), panx=(-.04, .04), ln=s5, bars=True,
             cast=[c(keeper, .72, .42, "happy", cage="closed", act="sway"), c("milo", .26, .34, "happy", act="hop")], cues=[("firefly_chime", 400, .4)]),
    ], music=mus)
    save(f"rescue_{isl}", f"{title}: freed", [
        shot(bg_storm, 4200, fx="keys+rain", ln=f"v3_rescue_{isl}_1", zoom=(1.05, 1.18), shake=.5,
             cast=[c(keeper, .4, .5, "sad", cage="open"), c(f"jailer_{isl}", .8, .3, "surprised", y=.3, act="shake")],
             cues=[("key_turn", 0, .7), ("key_turn", 700, .6), ("key_turn", 1400, .6), ("cage_burst", 2400, .8), ("fruit_pop", 3200, .6)]),
        shot(bg_storm, 4000, fx="sparkle+rays", ln="v3_gen_r2", zoom=(1.2, 1.0), bars=True, cast=[c(keeper, .5, .5, "happy", cage="open", burst=True, act="hop")], cues=[("cage_burst", 0, .7)]),
        shot(CLEAR(isl), 4600, fx="colour+sparkle+" + fxs.split("+")[0], ln=f"v3_rescue_{isl}_2", zoom=(1, 1.1), cast=[c(keeper, .5, .5, "happy", act="wave")], cues=[("colour_wave", 0, .7), ("firefly_chime", 2000, .4)]),
        shot(CLEAR(isl), 4600, fx=fxs + "+rays", ln=f"v3_rescue_{isl}_3", zoom=(1.1, 1.0), bars=True, cast=[c("milo", .26, .38, "cheer", act="hop"), c(keeper, .6, .44, act="wave")], cues=[("island_restore", 0, .7)]),
        shot("tree", 4800, fx="sparkle+rays", ln="v3_gen_r5", zoom=(1.0, 1.15), cues=[("story_swell", 0, .5), ("magic", 800, .5), ("bell", 1400, .5)]),
    ], music=mus)

# ---------------------------------------------------------------- prologue, trial, finale
ks = ["bhalu", "arya", "kachhua", "ullu", "madhu", "pari"]
save("prologue", "Prologue: the Rescue of the Story Keepers", [
    shot("tree", 5200, fx="sparkle+rays+fireflies", ln="v3_pro_1", bars=True, zoom=(1.0, 1.15), pany=(0, -.02), cues=[("story_swell", 0, .5), ("bell", 1500, .4), ("birds", 0, 0) if False else ("bird_1", 2500, .3)]),
    shot("tree", 5000, fx="sparkle+petals+notes", ln="v3_pro_2", zoom=(1.1, 1.0), cast=[c("dadi", .5, .42, act="sway")], cues=[("firefly_chime", 600, .4), ("bird_2", 2400, .3)]),
    shot("tree", 6600, fx="sparkle+rays", ln=line("v3_pro_2b", "dadi", lines["v3_pro_2b"]["text"]), zoom=(1.0, 1.1), panx=(-.03, .03),
         cast=[c("milo", .12, .24, act="hop"), c("bhalu", .3, .28, act="wave", delay=500), c("arya", .5, .26, act="bounce", delay=1100), c("kachhua", .7, .26, act="sway", delay=1700, y=-.05), c("ullu", .88, .26, act="wave", delay=2300), c("madhu", .4, .22, act="float", delay=2900, y=.4), c("pari", .65, .22, act="float", delay=3500, y=.4)],
         cues=[("pop", 500, .5), ("pop", 1100, .5), ("pop", 1700, .5), ("pop", 2300, .5), ("pop", 2900, .5), ("pop", 3500, .5)]),
    shot("tree", 5400, fx="sparkle", ln="v3_pro_3", zoom=(1.0, 1.12), cast=[c("milo", .5, .4, act="bounce")], cues=[("magic", 400, .4)]),
    shot("night", 4600, fx="storm+lightning+mist", ln="v3_pro_4", shake=1.2, zoom=(1.3, 1.0), cast=[c("gumsum", .5, .6, "villain", act="float", y=.15)], cues=[("thunder_soft", 0, .9), ("cloud_whoosh", 200, .7), ("wind_soft", 800, .5)]),
    shot("night", 5400, fx="storm+rain+lightning", ln="v3_pro_5", shake=.8, zoom=(1.0, 1.15),
         cast=[c(k, .12 + i * .15, .2, "surprised", act="float", y=.3 + (i % 2) * .15, toX=.95, toY=.95, enter="none") for i, k in enumerate(ks)], cues=[("thunder_soft", 0, .8), ("cloud_whoosh", 400, .8), ("cloud_whoosh", 1300, .6), ("wind_soft", 800, .6)]),
    shot("night", 4200, fx="rain+mist", ln="v3_pro_6", zoom=(1.2, 1.0), cast=[c("milo", .5, .42, MILO_HURT, enter="left", act="sway")], cues=[("thud_soft", 0, .6), ("owl_hoot", 2200, .25)]),
    shot("tree_grey", 4400, fx="greying+mist", ln="v3_pro_7", zoom=(1.0, 1.12), bars=True, cues=[("wind_soft", 0, .5), ("level_down", 400, .4)]),
    shot("tree_grey", 4600, fx="light+sparkle", ln="v3_pro_8", zoom=(1.0, 1.2), cues=[("magic", 400, .6), ("story_swell", 0, .5), ("sparkle", 2000, .5)]),
    shot("tree_grey", 4400, fx="sparkle", ln="v3_pro_9", zoom=(1.0, 1.1), cast=[c("milo", .5, .42, MILO_HURT, act="bounce")], cues=[("power_up", 600, .5)]),
    shot("art:still.map.storm", 5600, fx="rain+lightning", ln="v3_pro_10", zoom=(1.0, 1.18), panx=(-.04, .04), bars=True, cues=[("thunder_soft", 0, .5), ("key_turn", 3600, .5)]),
], music="music.story")

save("trial_warning", "The Storm Trial", [
    shot("tree", 4600, fx="sparkle+rays", ln="v3_trial_1", zoom=(1.0, 1.1), bars=True,
         cast=[c(k, .1 + i * .16, .22, act="bounce", delay=i * 350, y=0) for i, k in enumerate(ks)], cues=[("pop", 300 + i * 350, .4) for i in range(6)]),
    shot("art:island.citadel", 4600, fx="lightning+rain+mist", shake=1.2, zoom=(1.25, 1.0), ln="v3_trial_2", cast=[c("gumsum", .5, .6, "villain", act="float", y=.15)], cues=[("thunder_soft", 0, .9), ("gong", 200, .5)]),
    shot("art:island.citadel", 5000, fx="lightning+rain", zoom=(1.0, 1.1), ln="v3_trial_3", cast=[c("gumsum", .5, .5, "villain", act="float", y=.2)],
         card="⚡ Storm Trial\n30 questions\nScore 21 to break the storm", cues=[("zap", 300, .5), ("stamp_thud", 700, .6)]),
    shot("night", 4000, fx="sparkle", zoom=(1.0, 1.1), ln="v3_trial_4", card="⚡ Score 21 of 30", cast=[c("milo", .5, .36, act="hop", y=-.05)], cues=[("power_up", 300, .5)]),
], music="music.boss")

save("trial_retry", "Not yet", [
    shot("art:island.citadel", 3600, fx="lightning+rain", shake=.8, zoom=(1.1, 1.0), ln="v3_retry_1", cast=[c("gumsum", .5, .55, "villain", act="float", y=.2)], cues=[("thunder_soft", 0, .6)]),
    shot("night", 3600, fx="sparkle", zoom=(1.0, 1.08), ln="v3_retry_2", cast=[c("milo", .5, .42, act="bounce")], cues=[("hint", 400, .5)]),
], music="music.story")

save("finale", "The storm breaks", [
    shot("art:island.citadel", 5200, fx="light+rays+sparkle", zoom=(1.0, 1.25), ln="v3_fin_1", bars=True, cues=[("story_swell", 0, .6), ("magic", 800, .6), ("cage_burst", 3200, .7), ("colour_wave", 3600, .5)]),
    shot("night", 5000, fx="rain+mist", zoom=(1.2, 1.0), ln="v3_fin_2", cast=[c("gumsum", .5, .34, "small_sad", act="sway", y=.05)], cues=[("wind_soft", 0, .4)]),
    shot("night", 4600, fx="sparkle+dust", zoom=(1.0, 1.15), ln="v3_fin_3", cast=[c("milo", .26, .38, act="sway"), c("gumsum", .66, .3, "small_sad", act="sway", y=.05), c("dadi", .5, .22, act="float", y=.5, enter="float", delay=900)], cues=[("page_turn", 300, .5), ("book_open", 900, .5)]),
    shot("tree", 5000, fx="sparkle+rays+petals", zoom=(1.0, 1.15), ln="v3_fin_4", bars=True, cast=[c("gumsum", .5, .4, "redeemed", act="float", y=.2)], cues=[("firefly_chime", 400, .5), ("magic", 1400, .5)]),
    shot("tree", 4200, fx="sparkle+rays", zoom=(1.0, 1.1), ln="v3_fin_5", cast=[c("dadi", .5, .42, act="sway")], cues=[("story_swell", 0, .5), ("bell", 1500, .4)]),
    shot("aksharpur", 5200, fx="confetti+sparkle+petals+notes", zoom=(1.0, 1.14), ln="v3_fin_6", cast=[c("milo", .3, .4, "cheer", act="hop"), c("gumsum", .72, .36, "redeemed", act="float", y=.2)], cues=[("reward_fanfare", 0, .7), ("colour_wave", 300, .5), ("band_join", 1800, .5), ("firefly_chime", 2600, .4)]),
    shot("aksharpur", 5600, fx="sparkle+rays+fireflies", zoom=(1.0, 1.2), ln="v3_fin_7", bars=True, cues=[("story_swell", 0, .6), ("chapter_complete", 1200, .5)]),
], music="music.aksharpur")

json.dump(lines, open(LINES, "w"), indent=1, ensure_ascii=False)
print("scenes written;", len(lines), "lines")
