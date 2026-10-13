"""Draws the app icon (speech bubble card with a fork and an alert dot).

Run from the repo root: python3 tools/make_app_icon.py  (needs Pillow)
"""
from PIL import Image, ImageDraw
S = 4096
k = S / 1024
def r(v): return int(v * k)

# Background: deep teal gradient (top lighter)
img = Image.new("RGB", (S, S))
top, bottom = (0, 128, 140), (0, 70, 88)
px = img.load()
d = ImageDraw.Draw(img)
for y in range(S):
    t = y / (S - 1)
    c = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
    d.line([(0, y), (S, y)], fill=c)

white = (255, 255, 255)
teal = (0, 98, 112)
coral = (255, 122, 89)

# Speech bubble: a card the waiter reads, with a tail at bottom left
d.rounded_rectangle([r(170), r(200), r(854), r(760)], radius=r(130), fill=white)
d.polygon([(r(300), r(720)), (r(250), r(880)), (r(450), r(740))], fill=white)

# Fork in the bubble (centre x = 512)
cx = 512
# tines
for dx in (-62, 0, 62):
    d.rounded_rectangle([r(cx + dx - 17), r(300), r(cx + dx + 17), r(470)], radius=r(17), fill=teal)
# head joining tines
d.rounded_rectangle([r(cx - 79), r(430), r(cx + 79), r(520)], radius=r(45), fill=teal)
# neck taper
d.polygon([(r(cx - 60), r(500)), (r(cx + 60), r(500)), (r(cx + 26), r(570)), (r(cx - 26), r(570))], fill=teal)
# handle
d.rounded_rectangle([r(cx - 26), r(550), r(cx + 26), r(680)], radius=r(26), fill=teal)

# Small coral alert dot, top right of the bubble
d.ellipse([r(700), r(150), r(880), r(330)], fill=coral, outline=white, width=r(22))
d.rounded_rectangle([r(781), r(190), r(799), r(255)], radius=r(9), fill=white)
d.ellipse([r(780), r(268), r(800), r(288)], fill=white)

img.resize((1024, 1024), Image.LANCZOS).save("AllergyApp/AllergyApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png", optimize=True)
