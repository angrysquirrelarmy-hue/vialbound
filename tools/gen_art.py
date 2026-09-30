#!/usr/bin/env python3
"""Generates every sprite, tile and height/normal map in art/.

The prototype drew its art with code, so the art IS this file: shapes in, PNGs out.
Each draw call writes two layers at once — colour and height — and the height layer
becomes a normal map the 2D lights read. Re-run after editing; the output is
deterministic, so a regenerated sheet diffs cleanly.

    python3 tools/gen_art.py
"""
import os, math
import numpy as np
from PIL import Image, ImageDraw

ART = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "art")
T = 16                      # tile size
CELL_W, CELL_H = 16, 24     # character cell

PAL = ["#06080e","#0b0f1c","#131a2e","#1e2742","#2b375c","#3d4c79","#5a6c98","#8497b8",
       "#b6c6dc","#dce6f2","#0c2015","#14301f","#1d4a2c","#2c6b3c","#46914b","#7cb85c",
       "#a8d178","#221409","#3d2412","#5a351a","#7d4d1f","#a8692a","#d9a340","#f2c765",
       "#ffe9a8","#fff8dc","#0f3a42","#1d6b74","#2e9aa6","#63d9de","#b8f6f2","#e0cfea"]

def hsh(x, y):
    n = (x * 374761393 + y * 668265263) & 0x7fffffff
    n = (n ^ (n >> 13)) * 1274126177
    return ((n ^ (n >> 16)) & 0xffff) / 65535.0

class Canvas:
    """Colour and height in one pass. height is 0..1, 0 = ground level."""
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.col = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.hgt = Image.new("L", (w, h), 0)
        self.shd = Image.new("RGBA", (w, h), (0, 0, 0, 0))   # contact shadows, composited under
        self.dc = ImageDraw.Draw(self.col)
        self.dh = ImageDraw.Draw(self.hgt)
        self.ds = ImageDraw.Draw(self.shd)
    def shadow(self, x, y, rx, ry, a=64):
        self.ds.ellipse([x - rx, y - ry, x + rx, y + ry], fill=(6, 8, 14, a))
    def rect(self, x, y, w, h, c, z=None):
        self.dc.rectangle([x, y, x + w - 1, y + h - 1], fill=c)
        if z is not None:
            self.dh.rectangle([x, y, x + w - 1, y + h - 1], fill=int(z * 255))
    def ell(self, x, y, rx, ry, c, z=None):
        box = [x - rx, y - ry, x + rx, y + ry]
        self.dc.ellipse(box, fill=c)
        if z is not None:
            self.dh.ellipse(box, fill=int(z * 255))
    def poly(self, pts, c, z=None):
        self.dc.polygon(pts, fill=c)
        if z is not None:
            self.dh.polygon(pts, fill=int(z * 255))

def normal_map(height_img, strength=2.6):
    """Sobel the height into a tangent-space normal map (OpenGL convention, +Y up)."""
    h = np.asarray(height_img, dtype=np.float32) / 255.0
    gx = np.zeros_like(h); gy = np.zeros_like(h)
    gx[:, 1:-1] = (h[:, :-2] - h[:, 2:]) * strength
    gy[1:-1, :] = (h[2:, :] - h[:-2, :]) * strength
    nz = np.ones_like(h)
    ln = np.sqrt(gx * gx + gy * gy + nz * nz)
    out = np.zeros(h.shape + (4,), dtype=np.uint8)
    out[..., 0] = np.clip((gx / ln * 0.5 + 0.5) * 255, 0, 255)
    out[..., 1] = np.clip((gy / ln * 0.5 + 0.5) * 255, 0, 255)
    out[..., 2] = np.clip((nz / ln * 0.5 + 0.5) * 255, 0, 255)
    out[..., 3] = 255
    return Image.fromarray(out, "RGBA")

def save(canvas, name):
    os.makedirs(os.path.dirname(os.path.join(ART, name)), exist_ok=True)
    flat = Image.alpha_composite(canvas.shd, canvas.col)
    flat.save(os.path.join(ART, name + ".png"))
    canvas.col = flat
    normal_map(canvas.hgt).save(os.path.join(ART, name + "_n.png"))
    canvas.hgt.save(os.path.join(ART, name + "_h.png"))
    print("  ", name, canvas.col.size)

# ---------------------------------------------------------------- terrain ---
def tile_grass(c, ox, oy, seed):
    c.rect(ox, oy, T, T, "#2c6b3c", .03)
    for i in range(10):
        x = ox + int(hsh(seed * 7 + i, 3) * T); y = oy + int(hsh(3, seed * 5 + i) * T)
        c.rect(x, y, 1, 1, "#1d4a2c", .03)
    for i in range(5):
        x = ox + int(hsh(seed + i, 11) * (T - 1)); y = oy + int(hsh(11, seed + i) * (T - 2))
        c.rect(x, y, 1, 2, "#46914b", .05)

def tile_path(c, ox, oy):
    c.rect(ox, oy, T, T, "#8f5a24" if True else "#7d4d1f", .015)
    for i in range(14):
        x = ox + int(hsh(i, 21) * T); y = oy + int(hsh(21, i) * T)
        c.rect(x, y, 2, 1, "#7d4d1f" if i % 2 else "#a8692a", .015)

def tile_tilled(c, ox, oy):
    c.rect(ox, oy, T, T, "#5a351a", .02)
    for r in range(0, T, 4):
        c.rect(ox, oy + r, T, 2, "#3d2412", .01)
        c.rect(ox, oy + r + 2, T, 1, "#7d4d1f", .03)

def tile_plank(c, ox, oy):
    c.rect(ox, oy, T, T, "#7d4d1f", .04)
    for r in range(0, T, 5):
        c.rect(ox, oy + r, T, 4, "#a8692a" if r % 10 else "#8f5a24", .04)
        c.rect(ox, oy + r + 4, T, 1, "#5a351a", .03)

def tile_water(c, ox, oy):
    c.rect(ox, oy, T, T, "#1d6b74", 0.0)
    for i in range(3):
        y = oy + 3 + i * 5
        c.rect(ox + (i * 5) % 8, y, 6, 1, "#2e9aa6", 0.0)
        c.rect(ox + 8 + (i * 3) % 6, y + 2, 4, 1, "#63d9de", 0.0)

def tile_wall(c, ox, oy):
    c.rect(ox, oy, T, T, "#5a6c98", .80)
    for r in range(0, T, 5):
        for k in range(0, T, 8):
            x = ox + k + (4 if (r // 5) % 2 else 0)
            c.rect(x, oy + r, 7, 4, "#3d4c79" if hsh(x, r) < .45 else "#8497b8", .80)
    c.rect(ox, oy, T, 1, "#b6c6dc", .84)

def tile_rock(c, ox, oy):
    c.rect(ox, oy, T, T, "#2c6b3c", .03)
    c.ell(ox + 8, oy + 10, 6, 4, "#3d4c79", .42)
    c.ell(ox + 7, oy + 8, 4, 3, "#5a6c98", .50)
    c.ell(ox + 6, oy + 7, 2, 1.5, "#8497b8", .54)

def build_terrain():
    c = Canvas(T * 4, T * 2)
    tile_grass(c, 0, 0, 1); tile_grass(c, T, 0, 9); tile_path(c, T * 2, 0); tile_tilled(c, T * 3, 0)
    tile_plank(c, 0, T); tile_water(c, T, T); tile_wall(c, T * 2, T); tile_rock(c, T * 3, T)
    save(c, "tiles/terrain")

# ------------------------------------------------------------- characters ---
def human(c, ox, oy, d, f, cw=CELL_W):
    """d: 0 down 1 up 2 left 3 right. f: 0 idle, 1-2 walk. Feet at oy+22."""
    x, y = ox + cw // 2, oy + 22
    sw = [0, 1, -1][f] if f else 0                      # leg swing
    c.shadow(x, y - 1, 5, 2)
    c.rect(x - 3 + sw, y - 6, 2, 6, "#2b375c", .30)
    c.rect(x + 1 - sw, y - 6, 2, 6, "#2b375c", .30)
    c.rect(x - 4, y - 12, 8, 7, "#3d4c79", .44)
    c.rect(x - 4, y - 12, 8, 2, "#8497b8", .47)
    c.rect(x - 5, y - 11, 1, 5, "#3d4c79", .40); c.rect(x + 4, y - 11, 1, 5, "#3d4c79", .40)
    c.rect(x - 3, y - 17, 6, 5, "#f2c765", .52)
    if d == 0:
        c.rect(x - 2, y - 15, 1, 1, "#06080e"); c.rect(x + 1, y - 15, 1, 1, "#06080e")
    elif d == 2:
        c.rect(x - 3, y - 15, 1, 1, "#06080e")
    elif d == 3:
        c.rect(x + 2, y - 15, 1, 1, "#06080e")
    if d != 1:
        c.rect(x - 3, y - 16, 6, 1, "#5a351a", .54)
    c.rect(x - 5, y - 18, 10, 1, "#7d4d1f", .56)
    c.rect(x - 3, y - 21, 6, 3, "#7d4d1f", .59)
    c.rect(x - 3, y - 19, 6, 1, "#d9a340", .60)
    for bx in (x + 4, x - 6):                            # the vials on the bracers
        c.rect(bx, y - 9, 2, 3, "#b8f6f2", .42)

def glim(c, ox, oy, d, f, cw=24):
    """The moth. Hovers, so the frames bob instead of stepping."""
    x, y = ox + cw // 2, oy + 20 - [0, 1, 2][f]
    wing = [4.2, 3.4, 4.6][f]
    c.shadow(x, y + 3, 4, 1.6, 48)
    if d == 1:
        body, wingc = "#e0cfea", "#6b4a82"
    else:
        body, wingc = "#ffe9a8", "#a98cc4"
    c.ell(x - 4, y - 8, wing, 3.6, wingc, .30)
    c.ell(x + 4, y - 8, wing, 3.6, wingc, .30)
    c.ell(x - 4, y - 5, wing - 1, 2.6, "#6b4a82", .28)
    c.ell(x + 4, y - 5, wing - 1, 2.6, "#6b4a82", .28)
    c.ell(x - 4, y - 8, 1.6, 1.2, "#3c2650", .31); c.ell(x + 4, y - 8, 1.6, 1.2, "#3c2650", .31)
    c.ell(x, y - 6, 2, 4.5, body, .36)
    c.rect(x - 2, y - 13, 1, 4, "#e0cfea", .36); c.rect(x + 1, y - 13, 1, 4, "#e0cfea", .36)
    c.rect(x - 3, y - 14, 2, 1, "#e0cfea", .36); c.rect(x + 2, y - 14, 2, 1, "#e0cfea", .36)
    if d == 0:
        c.rect(x - 1, y - 9, 1, 1, "#06080e"); c.rect(x, y - 9, 1, 1, "#06080e")

def build_sheet(fn, name, cw=CELL_W, ch=CELL_H):
    """Three frames across, four facings down. Wide cryptids get a wider cell."""
    c = Canvas(cw * 3, ch * 4)
    for d in range(4):
        for f in range(3):
            fn(c, f * cw, d * ch, d, f, cw)
    save(c, name)

def build_palette():
    img = Image.new("RGBA", (len(PAL), 1))
    for i, hx in enumerate(PAL):
        img.putpixel((i, 0), tuple(int(hx[k:k + 2], 16) for k in (1, 3, 5)) + (255,))
    img.save(os.path.join(ART, "palette.png"))
    print("   palette", img.size)

def build_icon():
    c = Canvas(64, 64)
    c.rect(0, 0, 64, 64, "#131a2e", 0)
    c.rect(26, 8, 12, 6, "#a8692a", .5)          # cork
    c.poly([(24, 14), (40, 14), (44, 52), (20, 52)], "#8497b8", .6)
    c.poly([(26, 30), (38, 30), (41, 50), (23, 50)], "#63d9de", .7)
    c.ell(32, 40, 5, 5, "#b8f6f2", .8)
    c.col.save(os.path.join(ART, "icon.png"))
    print("   icon", c.col.size)


def build_light():
    """Falloff texture for PointLight2D. The shader bands it, so the gradient only
    needs to be smooth and round — the steps come later."""
    n = 128
    img = Image.new("RGBA", (n, n))
    px = img.load()
    for y in range(n):
        for x in range(n):
            d = math.hypot(x - n / 2 + .5, y - n / 2 + .5) / (n / 2)
            v = max(0.0, 1.0 - d)
            v = v * v * (3 - 2 * v)
            px[x, y] = (255, 255, 255, int(v * 255))
    img.save(os.path.join(ART, "light_soft.png"))
    print("   light_soft", img.size)

if __name__ == "__main__":
    print("generating art into", ART)
    build_terrain()
    build_sheet(human, "chars/player")
    build_sheet(glim, "chars/glim", cw=24)
    build_palette()
    build_icon()
    build_light()
    print("done")
