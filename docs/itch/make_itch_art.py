"""Gera a capa (630x500) e o banner (960x300) da página do itch.io a partir
das capturas de tela e do emblema. Fonte: Noto Serif Bold (licença OFL).
Uso: python3 docs/itch/make_itch_art.py (na raiz do repositório)."""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SHOTS = os.path.join(ROOT, "docs/screenshots")
ICON = os.path.join(ROOT, "docs/itch/emblem_512.png")
FONT = "/usr/share/fonts/truetype/noto/NotoSerif-Bold.ttf"
OUT = os.path.join(ROOT, "docs/itch")


def cover_crop(img, w, h, focus_y=0.5):
    sw, sh = img.size
    scale = max(w / sw, h / sh)
    img = img.resize((int(sw * scale) + 1, int(sh * scale) + 1), Image.LANCZOS)
    x = (img.width - w) // 2
    y = int((img.height - h) * focus_y)
    return img.crop((x, y, x + w, y + h))


def shade(img, top=0.55, bottom=0.85):
    w, h = img.size
    grad = Image.new("L", (1, h))
    for y in range(h):
        k = y / (h - 1)
        a = top * (1 - k) ** 2 + bottom * k ** 3
        grad.putpixel((0, y), int(255 * min(1.0, a)))
    grad = grad.resize((w, h))
    black = Image.new("RGB", (w, h), (8, 6, 10))
    return Image.composite(black, img, grad)


def brass_text(canvas, text, cx, y, size, spacing):
    font = ImageFont.truetype(FONT, size)
    widths = [font.getbbox(c)[2] - font.getbbox(c)[0] for c in text]
    total = sum(widths) + spacing * (len(text) - 1)
    x0 = cx - total // 2
    mask = Image.new("L", canvas.size, 0)
    md = ImageDraw.Draw(mask)
    x = x0
    for c, wdt in zip(text, widths):
        md.text((x - font.getbbox(c)[0], y), c, font=font, fill=255)
        x += wdt + spacing
    # Sombra/contorno escuro
    shadow = mask.filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.GaussianBlur(2))
    canvas.paste((10, 6, 4), (0, 3), shadow)
    # Gradiente de latão
    bbox = mask.getbbox()
    grad = Image.new("RGB", canvas.size)
    gd = ImageDraw.Draw(grad)
    top, bot = bbox[1], bbox[3]
    for yy in range(top, bot + 1):
        k = (yy - top) / max(1, bot - top)
        if k < 0.5:
            c1, c2, t = (255, 238, 160), (222, 146, 62), k * 2
        else:
            c1, c2, t = (222, 146, 62), (110, 58, 22), (k - 0.5) * 2
        col = tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))
        if 0.47 < k < 0.53:
            col = tuple(min(255, v + 50) for v in col)
        gd.line([(0, yy), (canvas.width, yy)], fill=col)
    canvas.paste(grad, (0, 0), mask)


def make_cover():
    bg = Image.open(os.path.join(OUT, "bg_act1.png")).convert("RGB")
    img = shade(cover_crop(bg, 630, 500, 0.55), 0.15, 0.9)
    icon = Image.open(ICON).convert("RGBA").resize((200, 200), Image.LANCZOS)
    glow = Image.new("RGBA", (630, 500), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((315 - 130, 150 - 130, 315 + 130, 150 + 130), fill=(255, 170, 70, 70))
    glow = glow.filter(ImageFilter.GaussianBlur(40))
    img.paste(glow, (0, 0), glow)
    img.paste(icon, (315 - 100, 34), icon)
    brass_text(img, "IRONVEIL", 315, 268, 78, 10)
    d = ImageDraw.Draw(img)
    d.line([(150, 372), (480, 372)], fill=(160, 110, 50), width=2)
    small = ImageFont.truetype(FONT, 17)
    t = "Caldeiras · Mercado · Torre · Fundições · Véu"
    w = d.textlength(t, font=small)
    d.text((315 - w / 2, 386), t, font=small, fill=(232, 214, 190))
    img.save(os.path.join(OUT, "cover_630x500.png"))


def make_banner():
    bg = Image.open(os.path.join(OUT, "bg_regulator.png")).convert("RGB")
    img = shade(cover_crop(bg, 960, 300, 0.45), 0.45, 0.6)
    dark = Image.new("RGBA", (960, 300), (6, 4, 8, 0))
    dd = ImageDraw.Draw(dark)
    for x in range(960):
        a = int(170 * max(0.0, 1 - abs(x - 480) / 520))
        dd.line([(x, 0), (x, 300)], fill=(6, 4, 8, a))
    img.paste(dark, (0, 0), dark)
    icon = Image.open(ICON).convert("RGBA").resize((150, 150), Image.LANCZOS)
    img.paste(icon, (120, 75), icon)
    brass_text(img, "IRONVEIL", 560, 92, 84, 10)
    img.save(os.path.join(OUT, "banner_960x300.png"))


make_cover()
make_banner()
print("ok")
