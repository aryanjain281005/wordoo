"""Prepare generated art for the app.

    ~/readle-tools/venv/bin/python tool/prepare_art.py

Reads the original images in art_src/art/<id>.png (as made by the image tool) and writes small app-ready
files to assets/art/<id>.webp:
  * characters (char.*) and props (prop.*): background removed; if the image is a model sheet with several
    views, only the FRONT view (top-left figure) is kept; trimmed and resized.
  * backgrounds (bg.*) and story covers (story.*): resized for phones. A grid of variations ("sheet") is
    rejected and listed so it can be generated again.
Only changed originals are processed again (art_src/art/.hashes.json).
"""
import hashlib
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "art_src" / "art"
OUT = ROOT / "assets" / "art"
HASHES = SRC / ".hashes.json"


def is_grid(img: Image.Image) -> bool:
    """True when the picture is a grid of small variations separated by white gutters."""
    a = np.asarray(img.convert("L").resize((300, int(300 * img.height / img.width))), dtype=np.float32)
    rows = (a > 238).mean(axis=1) > 0.97
    cols = (a > 238).mean(axis=0) > 0.97
    inner_rows = rows[5:-5].sum()
    inner_cols = cols[5:-5].sum()
    return inner_rows >= 2 or inner_cols >= 2


def cover(img: Image.Image, w: int, h: int) -> Image.Image:
    s = max(w / img.width, h / img.height)
    r = img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS)
    x, y = (r.width - w) // 2, (r.height - h) // 2
    return r.crop((x, y, x + w, y + h))


def _segments(cover: np.ndarray, gap: int):
    """Runs of non-empty lines separated by at least `gap` empty lines."""
    segs, start, empty = [], None, 0
    for i, v in enumerate(cover):
        if v:
            if start is None:
                start = i
            empty = 0
        elif start is not None:
            empty += 1
            if empty >= gap:
                segs.append((start, i - empty + 1))
                start, empty = None, 0
    if start is not None:
        segs.append((start, len(cover) - empty))
    return segs


# per-image tuning when neighbouring views overlap a lot
TOL = {'char.bhalu.happy': 0.15}


def front_view(mask: np.ndarray, gap: int, tol: float = 0.04) -> np.ndarray:
    """XY-cut: split a model sheet along empty rows/columns and keep the top-left big piece each time.
    Drops other views, close-up boxes and the little "Front View" labels (they are much smaller)."""
    y0, y1, x0, x1 = 0, mask.shape[0], 0, mask.shape[1]
    for _ in range(8):
        sub = mask[y0:y1, x0:x1]
        changed = False
        for axis in (1, 0):  # rows first, then columns
            # a line counts as a gutter when almost empty (a neighbour's tail or arm may poke across)
            cover = sub.sum(axis=axis) > tol * sub.shape[axis]
            segs = [sg for sg in _segments(cover, gap) if sg[1] - sg[0] > 2]
            if len(segs) > 1:
                sizes = [(sub[a:b, :] if axis == 1 else sub[:, a:b]).sum() for a, b in segs]
                a, b = next(sg for sg, sz in zip(segs, sizes) if sz >= 0.30 * max(sizes))
                if axis == 1:
                    y0, y1 = y0 + a, y0 + b
                else:
                    x0, x1 = x0 + a, x0 + b
                changed = True
                break
        if not changed:
            break
    keep = np.zeros_like(mask)
    keep[y0:y1, x0:x1] = mask[y0:y1, x0:x1]
    return keep


_session = None


def cutout(img: Image.Image, id_: str = '') -> Image.Image:
    global _session
    from rembg import new_session, remove

    if _session is None:
        _session = new_session("isnet-general-use")
    rgba = remove(img.convert("RGB"), session=_session)
    a = np.asarray(rgba)[:, :, 3]
    mask = a > 100
    # drop specks so they don't bridge the white gutters between views
    lab, n = ndimage.label(mask)
    if n:
        areas = ndimage.sum(mask, lab, range(1, n + 1))
        mask = np.isin(lab, [i + 1 for i, s in enumerate(areas) if s >= mask.size * 0.0008])
    keep = front_view(mask, max(3, img.width // 400), TOL.get(id_, 0.04))
    ys, xs = np.where(keep)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    arr = np.asarray(rgba).copy()
    arr[:, :, 3] = np.where(ndimage.binary_dilation(keep, iterations=2), arr[:, :, 3], 0)
    out = Image.fromarray(arr).crop((x0, y0, x1, y1))
    pad = round(max(out.size) * 0.04)
    canvas = Image.new("RGBA", (out.width + 2 * pad, out.height + 2 * pad), (0, 0, 0, 0))
    canvas.paste(out, (pad, pad))
    canvas.thumbnail((1600, 1600), Image.LANCZOS)
    return canvas


def main(only=None):
    hashes = json.loads(HASHES.read_text()) if HASHES.exists() else {}
    rejected, done = [], []
    for f in sorted(SRC.glob("*.png")) + sorted(SRC.glob("*.jpg")):
        id_ = f.stem
        if only and id_ not in only:
            continue
        h = hashlib.sha1(f.read_bytes()).hexdigest()
        out = OUT / f"{id_}.webp"
        if hashes.get(id_) == h and (out.exists() or id_ in hashes.get("_rejected", [])):
            continue
        img = Image.open(f)
        if id_.startswith(("bg.", "story.")):
            if is_grid(img):
                rejected.append(id_)
                out.unlink(missing_ok=True)
                hashes[id_] = h
                continue
            # best quality (size is not a constraint): keep the source resolution, never upscale
            landscape = id_.startswith(("bg.book.", "story.")) or img.width > img.height
            tw, th = (1536, 1024) if landscape else (1440, 2560)
            scale = min(1.0, max(img.width / tw, img.height / th))
            res = cover(img.convert("RGB"), round(tw * scale), round(th * scale))
            res.save(out, "WEBP", quality=94, method=6)
        else:
            cutout(img, id_).save(out, "WEBP", quality=96, method=6)
        hashes[id_] = h
        done.append(id_)
        print("ok ", id_, f"{out.stat().st_size // 1024} KB")
    prev = set(hashes.get("_rejected", [])) - set(done)
    hashes["_rejected"] = sorted(prev | set(rejected))
    HASHES.write_text(json.dumps(hashes, indent=1))
    for r in hashes["_rejected"]:
        print("SHEET (please generate again as one single picture):", r)


if __name__ == "__main__":
    main(set(sys.argv[1:]) or None)
