#!/usr/bin/env python3
"""Synthesise Wordoo's own sound effects (no samples, no licences): numpy -> wav -> ffmpeg -> assets/sfx/<id>.ogg.

    ~/readle-tools/venv/bin/python tool/gen_sfx.py [id ...]

Sound Forest (drums, marimba, flute, birds, owl, leaves, fireflies, bamboo), Word Village (stamp, magnifier, pencil,
paper, sign creak, market bell, clue chime, quill) and the cutscene set (thunder, rain, cage, key, colour wave).
"""
import os, subprocess, sys, tempfile
import numpy as np
import soundfile as sf

SR = 32000
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets/sfx")
rng = np.random.default_rng(7)


def t(d): return np.arange(int(SR * d)) / SR
def env(n, a=.005, d=.2, s=0.0, r=.05, dur=None):
    """attack / exponential decay to sustain s / release"""
    x = np.arange(n) / SR
    dur = dur or n / SR
    e = np.where(x < a, x / max(a, 1e-4), s + (1 - s) * np.exp(-(x - a) / max(d, 1e-4)))
    rel = np.clip((dur - x) / max(r, 1e-4), 0, 1)
    return e * rel
def sine(f, d, ph=0): return np.sin(2 * np.pi * f * t(d) + ph)
def noise(d): return rng.standard_normal(int(SR * d))
def lowpass(x, fc):
    a = np.exp(-2 * np.pi * fc / SR); y = np.zeros_like(x); p = 0.0
    for i, v in enumerate(x): p = (1 - a) * v + a * p; y[i] = p
    return y
def bandpass(x, f, q=4):
    # state-variable filter
    f1 = min(2 * np.sin(np.pi * f / SR), 1.0); q1 = max(1 / q, .7); lo = bp = 0.0; y = np.zeros_like(x)
    for i, v in enumerate(x):
        lo += f1 * bp; hi = v - lo - q1 * bp; bp += f1 * hi; y[i] = bp
    return y
def sweep(f0, f1, d): 
    f = np.linspace(f0, f1, int(SR * d)); return np.sin(2 * np.pi * np.cumsum(f) / SR)
def mix(*parts):
    n = max(len(p[0]) + int(p[1] * SR) for p in parts); y = np.zeros(n)
    for x, at in parts: y[int(at * SR):int(at * SR) + len(x)] += x
    return y
def tone(f, d, harm=(1,), a=.004, dd=.25, s=0, bright=1.0):
    y = sum(sine(f * (k + 1), d) * (h * bright ** k) for k, h in enumerate(harm))
    return y * env(len(y), a, dd, s, .03, d)
def bell(f, d=1.2): return (sine(f, d) + .5 * sine(f * 2.76, d) * np.exp(-t(d) * 6) + .3 * sine(f * 5.4, d) * np.exp(-t(d) * 9)) * env(int(SR * d), .002, d / 4, 0, .05, d)
def marimba(f, d=.6): return (sine(f, d) + .35 * sine(f * 4, d) * np.exp(-t(d) * 25) + .15 * sine(f * 10, d) * np.exp(-t(d) * 40)) * env(int(SR * d), .002, .16, 0, .05, d)
def drum(f, d=.5, snap=.3):
    fe = f * (1 + 1.2 * np.exp(-t(d) * 28)); body = np.sin(2 * np.pi * np.cumsum(fe) / SR) * np.exp(-t(d) * 9)
    return body + snap * bandpass(noise(d), 1800, 1.5) * np.exp(-t(d) * 60)
def chirp(f0, f1, d=.12): return sweep(f0, f1, d) * env(int(SR * d), .01, d / 2, 0, .03, d)

S = {}
# --- Sound Forest ---
S["drum_low"] = lambda: drum(95, .6)
S["drum_mid"] = lambda: drum(140, .45)
S["drum_hi"] = lambda: drum(210, .35, .4)
for i, n in enumerate([523.25, 587.33, 659.25, 783.99, 880.0]):
    S[f"marimba_{i + 1}"] = (lambda n=n: marimba(n))
S["shaker"] = lambda: bandpass(noise(.25), 7000, 2) * env(int(SR * .25), .02, .06, 0, .05, .25) * 4
S["flute_trill"] = lambda: mix(*[(tone(f, .16, (1, .25, .1), .02, .1, .3), i * .09) for i, f in enumerate([880, 988, 880, 988, 1175])])
S["bird_1"] = lambda: mix(*[(chirp(3000 + 400 * k, 4200 + 300 * k, .09), k * .12) for k in range(3)])
S["bird_2"] = lambda: mix((chirp(2600, 3600, .15), 0), (chirp(3800, 2800, .12), .2), (chirp(3000, 4400, .1), .38))
S["owl_hoot"] = lambda: mix((tone(330, .45, (1, .3), .08, .3, .4), 0), (tone(294, .7, (1, .3), .06, .5, .3), .55))
S["leaves_rustle"] = lambda: bandpass(noise(.9), 4200, 1.2) * (env(int(SR * .9), .15, .45, 0, .25, .9)) * 3
S["firefly_chime"] = lambda: mix(*[(bell(f, .9) * .5, i * .08) for i, f in enumerate([1318, 1568, 1976, 2349])])
S["wind_soft"] = lambda: lowpass(noise(2.2), 700) * np.sin(np.pi * t(2.2) / 2.2) ** 2 * 7
S["bamboo_clack"] = lambda: mix((bandpass(noise(.12), 1400, 6) * np.exp(-t(.12) * 45) * 6, 0), (marimba(392, .2) * .5, 0))
S["slice_swish"] = lambda: bandpass(noise(.28), 3200, 1.5) * np.sin(np.pi * t(.28) / .28) ** 1.5 * 5
S["fruit_pop"] = lambda: mix((chirp(500, 150, .08), 0), (bandpass(noise(.12), 2500, 2) * np.exp(-t(.12) * 40) * 2, 0))
S["forest_wake"] = lambda: mix((sweep(300, 900, .7) * env(int(SR * .7), .2, .5, 0, .2, .7) * .5, 0), *[(bell(f, .8) * .4, .3 + i * .1) for i, f in enumerate([784, 988, 1175, 1568])])
S["band_join"] = lambda: mix(*[(marimba(f, .5), i * .07) for i, f in enumerate([523, 659, 784])])
# --- Word Village ---
S["stamp_thud"] = lambda: drum(70, .35, .6) * 1.2
S["magnifier_ting"] = lambda: mix((bell(2093, .5) * .5, 0), (bell(3136, .4) * .3, .06))
S["pencil_scratch"] = lambda: bandpass(noise(.5), 5200, 3) * (np.abs(np.sin(2 * np.pi * 14 * t(.5))) ** .5) * env(int(SR * .5), .02, .6, .5, .08, .5) * 3
S["paper_rustle"] = lambda: bandpass(noise(.45), 3000, .9) * (.5 + .5 * np.sin(2 * np.pi * 22 * t(.45)) ** 2) * env(int(SR * .45), .02, .3, 0, .1, .45) * 3
S["sign_creak"] = lambda: bandpass(noise(.7), 620, 14) * np.sin(np.pi * t(.7) / .7) * (.6 + .4 * np.sin(2 * np.pi * 9 * t(.7))) * 5
S["market_bell"] = lambda: mix((bell(1046, 1.6) * .6, 0), (bell(1568, 1.2) * .3, .02))
S["clue_found"] = lambda: mix(*[(marimba(f, .5) * .9 + bell(f * 2, .5) * .2, i * .1) for i, f in enumerate([659, 784, 1046])])
S["flash_swoosh"] = lambda: mix((bandpass(noise(.2), 5000, 1.2) * np.sin(np.pi * t(.2) / .2) * 5, 0), (chirp(900, 2400, .18) * .2, 0))
S["quill_write"] = lambda: bandpass(noise(.6), 6000, 3) * (np.abs(np.sin(2 * np.pi * 9 * t(.6) + np.sin(2 * np.pi * 3 * t(.6)))) ** .7) * env(int(SR * .6), .04, .7, .5, .1, .6) * 2.5
S["lantern_glow"] = lambda: mix((sweep(500, 1200, .5) * env(int(SR * .5), .15, .4, 0, .15, .5) * .3, 0), (bell(1568, 1.0) * .4, .25))
S["door_creak"] = lambda: bandpass(noise(.9), 420, 16) * np.sin(np.pi * t(.9) / .9) ** .8 * (.7 + .3 * np.sin(2 * np.pi * 6 * t(.9))) * 5
S["ink_blot"] = lambda: mix((chirp(300, 90, .12) * .8, 0), (bandpass(noise(.15), 700, 2) * np.exp(-t(.15) * 25), 0))
# --- cutscenes ---
S["thunder_soft"] = lambda: lowpass(noise(2.0), 220) * np.exp(-t(2.0) * 1.6) * (1 + .6 * np.sin(2 * np.pi * 7 * t(2.0))) * 14
S["rain_loop"] = lambda: bandpass(noise(3.0), 6500, .7) * .9
S["cage_creak"] = lambda: bandpass(noise(.8), 300, 12) * np.sin(np.pi * t(.8) / .8) * 4
S["cage_burst"] = lambda: mix((bandpass(noise(.5), 1200, .8) * np.exp(-t(.5) * 7) * 3, 0), *[(bell(f, .7) * .35, .05 + i * .06) for i, f in enumerate([1568, 2093, 2637, 3136])])
S["key_turn"] = lambda: mix((bandpass(noise(.05), 2500, 6) * np.exp(-t(.05) * 60) * 4, 0), (bandpass(noise(.05), 2000, 6) * np.exp(-t(.05) * 60) * 4, .18), (bell(1760, .9) * .5, .3))
S["colour_wave"] = lambda: mix((sweep(250, 1500, 1.4) * env(int(SR * 1.4), .5, 1.0, 0, .3, 1.4) * .35, 0), *[(bell(f, 1.0) * .3, .4 + i * .15) for i, f in enumerate([784, 988, 1175, 1568, 1976])])
S["story_swell"] = lambda: mix(*[(tone(f, 1.6, (1, .4, .2), .5, .9, .2) * .4, 0) for f in [261.6, 329.6, 392]])
S["gong"] = lambda: bell(196, 3.0) * 1.2
S["page_whoosh"] = lambda: bandpass(noise(.35), 2400, 1) * np.sin(np.pi * t(.35) / .35) * 4


def render(name, y):
    y = np.nan_to_num(np.asarray(y, dtype=np.float64))
    y = y / max(np.abs(y).max(), 1e-6) * .85
    y = np.concatenate([y, np.zeros(int(SR * .05))])
    with tempfile.TemporaryDirectory() as td:
        w = os.path.join(td, "a.wav"); sf.write(w, y, SR)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", w, "-af", "loudnorm=I=-18:TP=-2:LRA=7", "-ar", "48000", "-ac", "1", "-c:a", "libopus", "-b:a", "80k", os.path.join(OUT, f"{name}.ogg")], check=True)
    print(f"  {name:18s} {len(y) / SR:4.1f}s")


want = sys.argv[1:] or list(S)
for n in want:
    render(n, S[n]())
