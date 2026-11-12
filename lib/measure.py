#!/usr/bin/env python3
"""Prints the darkest and brightest 1% of a picture as JSON: {"p01":[r,g,b],"p99":[r,g,b]}.
Tries Pillow, then ImageMagick, then a plain PNG reader. Reads the file, nothing else."""
import json, struct, subprocess, sys, zlib

def lum(p):
    c = [v / 12.92 if v <= .03928 else ((v + .055) / 1.055) ** 2.4 for v in (x / 255 for x in p)]
    return .2126 * c[0] + .7152 * c[1] + .0722 * c[2]

def pillow(path):
    from PIL import Image
    im = Image.open(path).convert("RGB").resize((96, 54))
    return list(im.getdata())

def magick(path):
    for tool in (["magick"], ["convert"]):
        try:
            raw = subprocess.run(tool + [path + "[0]", "-resize", "96x54!", "-depth", "8", "rgb:-"],
                                 capture_output=True, timeout=40, check=True).stdout
            return [tuple(raw[i:i + 3]) for i in range(0, len(raw) - 2, 3)]
        except Exception:
            continue
    raise RuntimeError("no ImageMagick")

def png(path):
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n": raise RuntimeError("not a PNG")
    pos, idat, pal = 8, b"", None
    while pos < len(data):
        n, kind = struct.unpack(">I4s", data[pos:pos + 8]); body = data[pos + 8:pos + 8 + n]; pos += 12 + n
        if kind == b"IHDR": w, h, depth, ctype, _, _, lace = struct.unpack(">IIBBBBB", body)
        elif kind == b"PLTE": pal = body
        elif kind == b"IDAT": idat += body
    if depth != 8 or lace: raise RuntimeError("unsupported PNG")
    ch = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[ctype]; row = w * ch; raw = zlib.decompress(idat)
    prev, out, step = bytearray(row), [], max(1, h // 54)
    for y in range(h):
        f = raw[y * (row + 1)]; cur = bytearray(raw[y * (row + 1) + 1:(y + 1) * (row + 1)])
        for i in range(row):
            a = cur[i - ch] if i >= ch else 0; b = prev[i]; c = prev[i - ch] if i >= ch else 0
            if f == 1: cur[i] = (cur[i] + a) & 255
            elif f == 2: cur[i] = (cur[i] + b) & 255
            elif f == 3: cur[i] = (cur[i] + (a + b) // 2) & 255
            elif f == 4:
                p = a + b - c; pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                cur[i] = (cur[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        if y % step == 0:
            for x in range(0, w, max(1, w // 96)):
                v = cur[x * ch:x * ch + ch]
                out.append((v[0],) * 3 if ctype in (0, 4) else tuple(pal[v[0] * 3:v[0] * 3 + 3]) if ctype == 3 else tuple(v[:3]))
        prev = cur
    return out

path, err = sys.argv[1], []
for reader in (pillow, magick, png):
    try:
        px = sorted(reader(path), key=lum)
        print(json.dumps({"p01": list(px[int(len(px) * .01)]), "p99": list(px[int(len(px) * .99)]), "via": reader.__name__}))
        sys.exit(0)
    except Exception as e:
        err.append(f"{reader.__name__}: {e}")
print(json.dumps({"error": "; ".join(err)})); sys.exit(1)
