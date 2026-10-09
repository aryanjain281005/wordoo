"""Joins the partial files of a parallel tool/gen_voices.py run (SHARDS>1) into envelopes.json / .hashes.json."""
import glob, json, os
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets/vo/en")
for name in ["envelopes.json", ".hashes.json"]:
    main = os.path.join(OUT, name)
    d = json.load(open(main)) if os.path.exists(main) else {}
    for p in sorted(glob.glob(main + ".*")):
        d.update(json.load(open(p)))
        os.remove(p)
    json.dump(d, open(main, "w"), indent=0 if name.startswith(".") else None)
    print(name, len(d))
