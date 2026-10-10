#!/usr/bin/env python3
"""Makes every voice clip loud and clear (speech polish), in place:  python3 tool/polish_audio.py [dir ...]

Chain: remove rumble (high-pass 90 Hz) → gentle compression (evens out quiet words so whole sentences are heard) → presence
boost (+3 dB around 3 kHz, where consonants live) → loudness -13 LUFS with a -1 dB peak limit → Opus 80 kbps.
A clip is polished once: assets/vo/<lang>/.polished.json remembers the md5 of each polished file, so running this again only
touches clips that were (re)generated since. Needs ffmpeg."""
import hashlib, json, os, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHAIN = ("highpass=f=90,"
         "acompressor=threshold=-24dB:ratio=3:attack=8:release=120:makeup=4,"
         "equalizer=f=3000:t=q:w=1.1:g=3,"
         "loudnorm=I=-13:TP=-1.0:LRA=6,"
         "alimiter=limit=0.89:level=disabled")


def md5(f):
    return hashlib.md5(open(f, "rb").read()).hexdigest()


def polish(f):
    fd, tmp = tempfile.mkstemp(suffix=".ogg", dir=os.path.dirname(f))
    os.close(fd)
    r = subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", f, "-af", CHAIN, "-ac", "1", "-ar", "24000", "-c:a", "libopus", "-b:a", "80k", "-application", "voip", tmp])
    if r.returncode != 0 or os.path.getsize(tmp) < 200:
        os.remove(tmp)
        return None
    os.replace(tmp, f)
    return md5(f)


def run(d):
    mark = os.path.join(d, ".polished.json")
    done = json.load(open(mark)) if os.path.exists(mark) else {}
    todo = []
    for base, _, files in os.walk(d):
        for n in files:
            if n.endswith(".ogg"):
                f = os.path.join(base, n)
                if done.get(os.path.relpath(f, d)) != md5(f):
                    todo.append(f)
    print(f"{d}: {len(todo)} clips to polish")
    with ThreadPoolExecutor(max_workers=os.cpu_count() or 4) as ex:
        for f, h in zip(todo, ex.map(polish, todo)):
            if h:
                done[os.path.relpath(f, d)] = h
    json.dump(done, open(mark, "w"))


for d in (sys.argv[1:] or [os.path.join(ROOT, "assets/vo/en")]):
    run(d)
