#!/usr/bin/env python3
"""Generate character voice lines for Readle (English v1).

Reads  assets/story/lines_en.json + books_en.json  (id -> who, text)  and  tool/voice_cast.json (who -> voice settings),
speaks every line with the free open-source Kokoro model (Apache 2.0) and writes
  assets/vo/en/<id>.ogg        small Ogg Opus files bundled in the app (works offline)
  assets/vo/en/envelopes.json  loudness every 50 ms, used for lip-sync
Only new or changed lines are regenerated.

Usage:  ~/readle-tools/venv/bin/python tool/gen_voices.py
Needs:  ~/readle-tools/{kokoro-v1.0.int8.onnx, voices-v1.0.bin}, ffmpeg on PATH.
"""
import hashlib, json, os, subprocess, sys, tempfile
import numpy as np
import soundfile as sf
from kokoro_onnx import Kokoro

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.expanduser("~/readle-tools")
OUT = os.path.join(ROOT, "assets/vo/en")
lines = json.load(open(os.path.join(ROOT, "assets/story/lines_en.json")))
books = os.path.join(ROOT, "assets/story/books_en.json")  # story narration (tool/export_books.dart)
if os.path.exists(books):
    lines.update(json.load(open(books)))
say = os.path.join(ROOT, "assets/story/say_en.json")  # every word / instruction (tool/export_speech.dart)
if os.path.exists(say):
    lines.update(json.load(open(say)))
os.makedirs(os.path.join(OUT, "say"), exist_ok=True)
cast = json.load(open(os.path.join(ROOT, "tool/voice_cast.json")))
hash_path = os.path.join(OUT, ".hashes.json")
hashes = json.load(open(hash_path)) if os.path.exists(hash_path) else {}
env_path = os.path.join(OUT, "envelopes.json")
envelopes = json.load(open(env_path)) if os.path.exists(env_path) else {}

kokoro = Kokoro(os.path.join(TOOLS, "kokoro-v1.0.int8.onnx"), os.path.join(TOOLS, "voices-v1.0.bin"))


def effects(c):
    f = []
    p = c.get("pitch", 1.0)
    if abs(p - 1.0) > 1e-3:  # change pitch, keep speed
        f.append(f"asetrate=24000*{p},aresample=24000,atempo={1 / p:.4f}")
    if c.get("reverb"):
        f.append("aecho=0.8:0.5:60:0.22")
    if c.get("echo"):
        f.append("aecho=0.8:0.6:140|260:0.28|0.16")
    if c.get("robot"):
        f.append("aecho=0.8:0.9:7:0.5,flanger=delay=2:depth=3")
    f.append("loudnorm=I=-16:TP=-2:LRA=9")
    return ",".join(f)


# parallel runs: SHARDS=4 SHARD=0..3 each take every 4th line and save partial files (tool/merge_voices.py joins them)
SHARDS, SHARD = int(os.environ.get("SHARDS", "1")), int(os.environ.get("SHARD", "0"))
part = f".{SHARD}" if SHARDS > 1 else ""
done = 0
mine_env, mine_hash = {}, {}
for idx, (lid, ln) in enumerate(lines.items()):
    if idx % SHARDS != SHARD:
        continue
    c = cast.get(ln.get("cast", ln["who"]), cast["milo"])  # "cast" picks a different voice for the same speaker
    key = hashlib.md5(json.dumps([ln, c], sort_keys=True).encode()).hexdigest()
    dst = os.path.join(OUT, f"{lid}.ogg")
    if hashes.get(lid) == key and os.path.exists(dst):
        continue
    try:
        samples, sr = kokoro.create(ln["text"], voice=c["voice"], speed=c.get("speed", 1.0), lang="en-us")
    except ValueError as e:  # nothing speakable: skip the line, keep going
        print(f"  skip {lid}: {e}")
        continue
    with tempfile.TemporaryDirectory() as td:
        raw = os.path.join(td, "raw.wav")
        proc = os.path.join(td, "proc.wav")
        sf.write(raw, samples, sr)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", raw, "-af", effects(c), "-ac", "1", "-ar", "24000", proc], check=True)
        audio, asr = sf.read(proc)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", proc, "-c:a", "libopus", "-b:a", "64k", "-application", "audio", dst], check=True)
    hop = int(asr * 0.05)
    rms = np.array([np.sqrt(np.mean(audio[i:i + hop] ** 2)) for i in range(0, len(audio), hop)])
    peak = max(rms.max(), 1e-6)
    envelopes[lid] = mine_env[lid] = [int(min(9, round(9 * (v / peak) ** 0.7))) for v in rms]
    hashes[lid] = mine_hash[lid] = key
    done += 1
    if done % 100 == 0:  # save progress so a long run can be resumed
        json.dump(mine_env if part else envelopes, open(env_path + part, "w"))
        json.dump(mine_hash if part else hashes, open(hash_path + part, "w"), indent=0)
    print(f"  {lid:28s} {ln['who']:8s} {len(audio) / asr:4.1f}s")

json.dump(mine_env if part else envelopes, open(env_path + part, "w"))
json.dump(mine_hash if part else hashes, open(hash_path + part, "w"), indent=0)
print(f"generated {done} lines, total {len(lines)}")
