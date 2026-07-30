"""Generate PWA icons: ink-green rounded square, brass serif 'M'. Run once."""
import os
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "web", "munshi-ui", "icons")
os.makedirs(OUT, exist_ok=True)

INK = (15, 46, 39)
GOLD = (203, 178, 127)

FONT_CANDIDATES = [
    "/System/Library/Fonts/Supplemental/Georgia Bold.ttf",
    "/System/Library/Fonts/Supplemental/Times New Roman Bold.ttf",
    "/System/Library/Fonts/Supplemental/Georgia.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf",
]


def font(size):
    for path in FONT_CANDIDATES:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def make(size, maskable=False, name=None):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    radius = 0 if maskable else size // 5
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=INK)
    ring = size // 22
    d.ellipse([size * 0.14, size * 0.14, size * 0.86, size * 0.86], outline=GOLD, width=max(2, ring // 2))
    f = font(int(size * 0.42))
    bbox = d.textbbox((0, 0), "M", font=f)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text(((size - w) / 2 - bbox[0], (size - h) / 2 - bbox[1]), "M", font=f, fill=GOLD)
    img.save(os.path.join(OUT, name or f"icon-{size}.png"))


make(192)
make(512)
make(512, maskable=True, name="icon-maskable-512.png")
make(180, name="apple-touch-icon.png")
print("icons written to", OUT)
