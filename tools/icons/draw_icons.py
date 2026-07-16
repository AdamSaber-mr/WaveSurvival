"""Spaceland HUD-iconen: ticket + 3 Fate-kaart-iconen.
Retro-kermis-palet dat past bij de Fate Card (bruin/goud/creme/rood).
Getekend op 1024x1024 en verkleind naar 256 (supersampling = scherpe randen).
"""
from PIL import Image, ImageDraw, ImageFilter
import math

S = 1024
OUT = 256

# palet
OUTLINE = (62, 34, 20, 255)
CREAM = (247, 236, 208, 255)
CREAM_DIM = (233, 218, 184, 255)
AMBER = (235, 166, 64, 255)
AMBER_HI = (248, 196, 106, 255)
AMBER_LO = (206, 134, 40, 255)
RED = (194, 59, 46, 255)
RED_DARK = (150, 40, 32, 255)
BRASS = (216, 171, 74, 255)
BRASS_LO = (176, 132, 48, 255)
COPPER = (196, 110, 58, 255)
COPPER_HI = (230, 150, 95, 255)
STEEL = (124, 138, 153, 255)
STEEL_HI = (158, 172, 186, 255)
STEEL_LO = (92, 104, 118, 255)
GOLD = (217, 164, 65, 255)
GOLD_LO = (176, 126, 40, 255)
MAROON = (90, 30, 20, 255)

def canvas():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))

def star_points(cx, cy, r_outer, r_inner, n=5, rot=-90):
    pts = []
    for i in range(n * 2):
        r = r_outer if i % 2 == 0 else r_inner
        a = math.radians(rot + i * 180.0 / n)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts

def save(img, name):
    img = img.resize((OUT, OUT), Image.LANCZOS)
    img.save(name)
    print("ok", name)

# ============ 1. TICKET ============
def ticket():
    img = canvas()
    d = ImageDraw.Draw(img)
    x0, y0, x1, y1 = 170, 372, 854, 652
    # schaduwlaagje
    sh = canvas()
    ImageDraw.Draw(sh).rounded_rectangle([x0+14, y0+20, x1+14, y1+20], 36, fill=(40, 20, 10, 90))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(10)))
    # donkere rand (outline) + body
    d.rounded_rectangle([x0-12, y0-12, x1+12, y1+12], 44, fill=OUTLINE)
    d.rounded_rectangle([x0, y0, x1, y1], 34, fill=AMBER)
    # licht bovenop / schaduw onder (namaak-gradient)
    grad = canvas()
    gd = ImageDraw.Draw(grad)
    gd.rounded_rectangle([x0, y0, x1, y0+90], 34, fill=(255, 255, 255, 48))
    gd.rounded_rectangle([x0, y1-70, x1, y1], 34, fill=(0, 0, 0, 40))
    img.alpha_composite(grad)
    # binnenrand creme (dun kadertje)
    d.rounded_rectangle([x0+28, y0+28, x1-28, y1-28], 20, outline=CREAM, width=8)
    # perforatie-lijn (stub rechts op 2/3)
    px = x0 + int((x1 - x0) * 0.66)
    yy = y0 + 40
    while yy < y1 - 30:
        d.rounded_rectangle([px-6, yy, px+6, yy+26], 6, fill=CREAM)
        yy += 46
    # halve-cirkel inkepingen op de perforatie-uiteinden en zijkanten
    for cx, cy in [(px, y0-12), (px, y1+12)]:
        d.ellipse([cx-30, cy-30, cx+30, cy+30], fill=(0, 0, 0, 0))
    # gaatje wegpoetsen: echt transparant maken
    hole = Image.new("L", (S, S), 0)
    hd = ImageDraw.Draw(hole)
    for cx, cy in [(px, y0-12), (px, y1+12), (x0-12, (y0+y1)//2), (x1+12, (y0+y1)//2)]:
        hd.ellipse([cx-30, cy-30, cx+30, cy+30], fill=255)
    img.putalpha(Image.composite(Image.new("L", (S, S), 0), img.getchannel("A"), hole))
    # ster-embleem links van de perforatie
    scx = x0 + int((x1 - x0) * 0.33)
    scy = (y0 + y1) // 2
    d = ImageDraw.Draw(img)
    d.ellipse([scx-104, scy-104, scx+104, scy+104], fill=AMBER_LO)
    d.ellipse([scx-92, scy-92, scx+92, scy+92], fill=CREAM)
    d.polygon(star_points(scx, scy+6, 78, 32), fill=RED)
    # 'tekst'-streepjes boven en onder de ster
    for ty in (y0+52, y1-64):
        d.rounded_rectangle([x0+70, ty, scx+150, ty+14], 7, fill=CREAM_DIM)
    # stub: drie sterretjes-knopjes
    stx = (px + x1) // 2
    for i, sy in enumerate((scy-70, scy, scy+70)):
        d.ellipse([stx-20, sy-20, stx+20, sy+20], fill=CREAM if i == 1 else CREAM_DIM)
        d.polygon(star_points(stx, sy+2, 14, 6), fill=AMBER_LO)
    # glans-baan
    gl = canvas()
    ImageDraw.Draw(gl).polygon([(x0+120, y0), (x0+230, y0), (x0+90, y1), (x0-20, y1)], fill=(255, 255, 255, 34))
    img.alpha_composite(gl)
    img = img.rotate(-12, resample=Image.BICUBIC, expand=False, center=(S/2, S/2))
    save(img, "icon_ticket.png")

# ============ 2. MAD DASH (renner) ============
def mad_dash():
    img = canvas()
    d = ImageDraw.Draw(img)
    def limb(pts, w, fill):
        d.line(pts, fill=fill, width=w, joint="curve")
        for p in (pts[0], pts[-1]):
            d.ellipse([p[0]-w/2, p[1]-w/2, p[0]+w/2, p[1]+w/2], fill=fill)
    # snelheids-strepen (creme, links)
    for i, (sy, ln) in enumerate([(330, 300), (460, 380), (590, 260)]):
        d.rounded_rectangle([120, sy, 120+ln, sy+30], 15, fill=CREAM)
        d.rounded_rectangle([120, sy, 120+ln, sy+30], 15, outline=OUTLINE, width=6)
    # figuur: outline-laag eerst (dikker), dan vulling
    for w_extra, col in [(26, OUTLINE), (0, MAROON)]:
        w_body = 96 + w_extra
        w_limb = 72 + w_extra
        # romp (leunt naar voren)
        limb([(596, 372), (518, 592)], w_body, col)
        # hoofd
        r = 88 + w_extra/2
        d.ellipse([648-r, 250-r, 648+r, 250+r], fill=col)
        # voorste arm (gebogen, pompend omhoog)
        limb([(600, 400), (716, 458), (790, 372)], w_limb, col)
        # achterste arm (naar achter-onder)
        limb([(576, 408), (452, 494), (386, 594)], w_limb, col)
        # voorste been (grote pas naar voren)
        limb([(518, 592), (668, 690), (776, 806)], w_limb, col)
        # achterste been (hiel omhoog naar achteren)
        limb([(518, 592), (398, 716), (302, 662)], w_limb, col)
    # pet-klepje (creme accent op het hoofd)
    d.polygon([(700, 196), (812, 216), (800, 262), (700, 248)], fill=CREAM)
    d.polygon([(700, 196), (812, 216), (800, 262), (700, 248)], outline=OUTLINE, width=6)
    # stof-wolkje bij achterste voet
    for cx, cy, r in [(258, 700, 34), (300, 730, 26), (232, 742, 22)]:
        d.ellipse([cx-r, cy-r, cx+r, cy+r], fill=CREAM_DIM)
        d.ellipse([cx-r, cy-r, cx+r, cy+r], outline=OUTLINE, width=5)
    save(img, "icon_maddash.png")

# ============ 3. POWER SHOT (kogel + knal) ============
def power_shot():
    img = canvas()
    d = ImageDraw.Draw(img)
    # knal-ster achter de punt
    burst_c = (512, 330)
    d.polygon(star_points(*burst_c, 320, 130, n=8, rot=-90), fill=CREAM)
    d.polygon(star_points(*burst_c, 320, 130, n=8, rot=-90), outline=OUTLINE, width=10)
    d.polygon(star_points(*burst_c, 190, 82, n=8, rot=-67), fill=GOLD)
    # kogel (rechtop; straks alles draaien)
    cx = 512
    # outline-laag
    d.rounded_rectangle([cx-96, 428, cx+96, 852], 40, fill=OUTLINE)
    d.pieslice([cx-96, 268, cx+96, 512], 180, 360, fill=OUTLINE)
    # koperen punt
    d.pieslice([cx-78, 290, cx+78, 500], 180, 360, fill=COPPER)
    d.polygon([(cx-78, 395), (cx+78, 395), (cx+78, 452), (cx-78, 452)], fill=COPPER)
    # glansje op de punt
    d.pieslice([cx-52, 312, cx+10, 470], 180, 290, fill=COPPER_HI)
    # huls
    d.rectangle([cx-78, 448, cx+78, 834], fill=BRASS)
    # huls-schaduw rechts + glans links
    d.rectangle([cx+34, 448, cx+78, 834], fill=BRASS_LO)
    d.rectangle([cx-66, 448, cx-38, 834], fill=(238, 204, 124, 255))
    # rand-ringen
    d.rectangle([cx-78, 448, cx+78, 478], fill=BRASS_LO)
    d.rectangle([cx-88, 788, cx+88, 812], fill=BRASS_LO)
    d.rounded_rectangle([cx-88, 806, cx+88, 842], 14, fill=BRASS)
    d.rectangle([cx-88, 788, cx+88, 800], fill=OUTLINE)
    # alles samen draaien
    img = img.rotate(-32, resample=Image.BICUBIC, center=(512, 540))
    # losse vonkjes (na het draaien, blijven recht)
    d = ImageDraw.Draw(img)
    for cx2, cy2, r in [(240, 260, 26), (760, 220, 20), (300, 640, 18)]:
        d.polygon(star_points(cx2, cy2, r, r*0.4, n=4, rot=-90), fill=CREAM)
        d.polygon(star_points(cx2, cy2, r, r*0.4, n=4, rot=-90), outline=OUTLINE, width=5)
    save(img, "icon_powershot.png")

# ============ 4. IRON HIDE (schild) ============
def iron_hide():
    img = canvas()
    d = ImageDraw.Draw(img)
    def shield_path(inset):
        top = 190 + inset
        left = 220 + inset
        right = 804 - inset
        mid_y = 560 - inset * 0.4
        bottom = (512, 880 - inset)
        pts = [(left, top), (right, top)]
        steps = 26
        for i in range(steps + 1):
            t = i / steps
            x = right - (right - 512) * (t ** 1.6)
            y = top + (mid_y - top) * min(1, t * 1.9) + (bottom[1] - mid_y) * max(0, (t * 1.9 - 0.9) / 1.0) ** 1.35
            pts.append((x, min(y, bottom[1])))
        for i in range(steps + 1):
            t = 1 - i / steps
            x = left + (512 - left) * (t ** 1.6)
            y = top + (mid_y - top) * min(1, t * 1.9) + (bottom[1] - mid_y) * max(0, (t * 1.9 - 0.9) / 1.0) ** 1.35
            pts.append((x, min(y, bottom[1])))
        return pts
    # schaduw
    sh = canvas()
    ImageDraw.Draw(sh).polygon([(x+12, y+18) for x, y in shield_path(0)], fill=(40, 20, 10, 90))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(10)))
    # outline → gouden rand → staal
    d.polygon(shield_path(-14), fill=OUTLINE)
    d.polygon(shield_path(0), fill=GOLD)
    d.polygon(shield_path(16), fill=GOLD_LO)
    d.polygon(shield_path(44), fill=STEEL)
    # verticale glans-baan
    hl = canvas()
    hd = ImageDraw.Draw(hl)
    hd.polygon([(400, 240), (520, 240), (470, 820), (410, 780)], fill=(255, 255, 255, 46))
    # masker: alleen binnen het stalen vlak
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).polygon(shield_path(44), fill=255)
    img.paste(Image.alpha_composite(img.crop((0, 0, S, S)), hl), (0, 0), mask)
    d = ImageDraw.Draw(img)
    # klinknagels langs de bovenrand
    for rx in (300, 405, 512, 619, 724):
        d.ellipse([rx-17, 258-17, rx+17, 258+17], fill=GOLD)
        d.ellipse([rx-17, 258-17, rx+17, 258+17], outline=OUTLINE, width=5)
        d.ellipse([rx-7, 251-7, rx+7, 251+7], fill=(240, 205, 130, 255))
    # centrale ster (creme met reliëf)
    d.polygon(star_points(512, 560, 150, 62, rot=-90), fill=STEEL_LO)
    d.polygon(star_points(512, 548, 150, 62, rot=-90), fill=CREAM)
    d.polygon(star_points(512, 548, 150, 62, rot=-90), outline=OUTLINE, width=8)
    save(img, "icon_ironhide.png")

ticket()
mad_dash()
power_shot()
iron_hide()
