"""Perk-iconen voor de HUD-tegels (36x36 in-game): Juggernog, Speed Cola, Stamin-Up.
Zelfde stijl als de andere iconen: dikke donkere outline + creme, leesbaar op
de gekleurde perk-tegel.
"""
from PIL import Image, ImageDraw
import math

S = 1024
OUT = 256
OUTLINE = (62, 34, 20, 255)
CREAM = (247, 236, 208, 255)
CREAM_DIM = (228, 212, 178, 255)
RED = (194, 59, 46, 255)
GOLD = (217, 164, 65, 255)

def canvas():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))

def save(img, name):
    img.resize((OUT, OUT), Image.LANCZOS).save(name)
    print("ok", name)

# ---- Juggernog: stevig kruis met hartje (health) ----
def juggernog():
    img = canvas()
    d = ImageDraw.Draw(img)
    w = 250   # armdikte van het kruis
    L = 780   # totale lengte
    cx = cy = 512
    for extra, col in [(56, OUTLINE), (0, CREAM)]:
        ww, ll = w + extra, L + extra
        d.rounded_rectangle([cx-ll//2, cy-ww//2, cx+ll//2, cy+ww//2], 60, fill=col)
        d.rounded_rectangle([cx-ww//2, cy-ll//2, cx+ww//2, cy+ll//2], 60, fill=col)
    # hartje in het midden
    hs = 150
    d.ellipse([cx-hs, cy-hs*0.75, cx, cy+hs*0.25], fill=RED)
    d.ellipse([cx, cy-hs*0.75, cx+hs, cy+hs*0.25], fill=RED)
    d.polygon([(cx-hs+8, cy+hs*0.02), (cx+hs-8, cy+hs*0.02), (cx, cy+hs*1.05)], fill=RED)
    save(img, "icon_juggernog.png")

# ---- Speed Cola: flesje met bliksem-etiket ----
def speed_cola():
    img = canvas()
    d = ImageDraw.Draw(img)
    cx = 512
    for extra, col in [(30, OUTLINE), (0, CREAM)]:
        e = extra
        # dop
        d.rounded_rectangle([cx-110-e, 120-e, cx+110+e, 220+e], 24, fill=col)
        # hals (taps)
        d.polygon([(cx-95-e, 210), (cx+95+e, 210), (cx+150+e, 430), (cx-150-e, 430)], fill=col)
        # body
        d.rounded_rectangle([cx-190-e, 400-e, cx+190+e, 900+e], 80, fill=col)
    # dop-details
    d.rounded_rectangle([cx-110, 120, cx+110, 220], 24, fill=GOLD)
    for lx in range(int(cx)-90, int(cx)+95, 42):
        d.rectangle([lx, 128, lx+18, 212], fill=(176, 126, 40, 255))
    # etiket-band
    d.rectangle([cx-190, 520, cx+190, 790], fill=RED)
    d.rectangle([cx-190, 520, cx+190, 548], fill=(150, 40, 32, 255))
    d.rectangle([cx-190, 762, cx+190, 790], fill=(150, 40, 32, 255))
    # bliksem op het etiket
    bolt = [(cx+55, 555), (cx-75, 665), (cx-5, 672), (cx-60, 765), (cx+85, 648), (cx+8, 641)]
    d.polygon(bolt, fill=CREAM)
    d.polygon(bolt, outline=OUTLINE, width=8)
    # glansje links op de fles
    d.rounded_rectangle([cx-150, 440, cx-105, 880], 22, fill=(255, 255, 255, 70))
    save(img, "icon_speedcola.png")

# ---- Stamin-Up: rennende schoen met vleugeltje ----
def stamin_up():
    img = canvas()
    d = ImageDraw.Draw(img)
    # vaartstrepen achter de schoen
    for sy, ln in [(430, 210), (540, 280), (650, 180)]:
        d.rounded_rectangle([90, sy, 90+ln, sy+26], 13, fill=CREAM_DIM)
        d.rounded_rectangle([90, sy, 90+ln, sy+26], 13, outline=OUTLINE, width=6)
    # schoen: zool + neus + schacht (outline eerst, dan vulling)
    for e, colS, colB in [(26, OUTLINE, OUTLINE), (0, GOLD, CREAM)]:
        # zool (dik, licht gebogen)
        d.rounded_rectangle([330-e, 700-e, 900+e, 800+e], 46, fill=colS)
        # neus + wreef
        d.polygon([(880+e, 720), (770, 520-e), (600, 470-e), (460-e, 520), (430-e, 720)], fill=colB)
        # schacht/enkel
        d.rounded_rectangle([430-e, 380-e, 640+e, 730], 46, fill=colB)
    # veters
    for i in range(3):
        y = 500 + i * 74
        d.line([(470, y), (610, y+40)], fill=OUTLINE, width=18)
    # vleugeltje aan de hiel
    wing = [(430, 430), (210, 330), (300, 430), (180, 420), (310, 500), (430, 520)]
    d.polygon(wing, fill=CREAM)
    d.polygon(wing, outline=OUTLINE, width=10)
    d.line([(300, 430), (430, 470)], fill=OUTLINE, width=8)
    save(img, "icon_staminup.png")

juggernog()
speed_cola()
stamin_up()
