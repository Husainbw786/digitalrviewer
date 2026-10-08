#!/usr/bin/env python3
"""Generate every DigitalRViewer icon/logo file from one source.

Source: branding/logo-1024.png if it exists (drop the real logo there, square, 1024x1024,
transparent background allowed); otherwise a placeholder monogram is drawn from the
constants below.

Requires Pillow (`pip install pillow`) and macOS `iconutil` (for AppIcon.icns).
Run from the repo root:  python3 branding/gen-icons.py
"""
import os
import shutil
import subprocess
import tempfile

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "branding", "logo-1024.png")

# Placeholder brand — replace with the real logo (logo-1024.png) and colour later.
BRAND_COLOR = "#2F5BEA"
MONOGRAM = "DR"
FONT = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"


def p(*parts):
    return os.path.join(ROOT, *parts)


def placeholder(size=1024, color=BRAND_COLOR, fg="white", radius_ratio=0.0):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    r = int(size * radius_ratio)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=r, fill=color)
    font = ImageFont.truetype(FONT, int(size * 0.46))
    box = d.textbbox((0, 0), MONOGRAM, font=font)
    w, h = box[2] - box[0], box[3] - box[1]
    d.text(((size - w) / 2 - box[0], (size - h) / 2 - box[1]), MONOGRAM, font=font, fill=fg)
    return img


def master():
    if os.path.exists(SRC):
        return Image.open(SRC).convert("RGBA").resize((1024, 1024), Image.LANCZOS)
    return placeholder()


def mac_app_icon(src):
    # macOS icons sit on a ~824px rounded tile inside the 1024 canvas.
    canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    tile = 824
    mask = Image.new("L", (tile, tile), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, tile - 1, tile - 1], radius=int(tile * 0.225), fill=255)
    art = src.resize((tile, tile), Image.LANCZOS)
    canvas.paste(art, (100, 100), mask)
    return canvas


def tray_template(size):
    # Template image: macOS only uses the alpha channel, so draw the monogram/logo as black.
    if os.path.exists(SRC):
        alpha = master().resize((size, size), Image.LANCZOS).split()[3]
        img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        img.putalpha(alpha)
        return img
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pad = max(1, size // 12)
    d.rectangle([pad, pad, size - 1 - pad, size - 1 - pad], outline="black", width=max(2, size // 12))
    font = ImageFont.truetype(FONT, int(size * 0.42))
    box = d.textbbox((0, 0), MONOGRAM, font=font)
    w, h = box[2] - box[0], box[3] - box[1]
    d.text(((size - w) / 2 - box[0], (size - h) / 2 - box[1]), MONOGRAM, font=font, fill="black")
    return img


def svg_placeholder():
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 26 26">'
        f'<rect width="26" height="26" fill="{BRAND_COLOR}"/>'
        '<text x="13" y="17.6" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" '
        f'font-weight="700" font-size="12" fill="#fff">{MONOGRAM}</text></svg>\n'
    )


def main():
    src = master()

    def save(img, *path, size=None):
        out = p(*path)
        (img.resize((size, size), Image.LANCZOS) if size else img).save(out)
        print("wrote", os.path.relpath(out, ROOT))

    # Generic PNGs (Linux packages, Cargo bundle, Flutter in-app logo).
    save(src, "res", "icon.png", size=1024)
    for s, name in [(32, "32x32.png"), (64, "64x64.png"), (128, "128x128.png"), (256, "128x128@2x.png")]:
        save(src, "res", name, size=s)
    save(src, "flutter", "assets", "icon.png", size=256)
    save(src, "flutter", "assets", "logo.png", size=256)

    # macOS app icon + tray template icons.
    mac = mac_app_icon(src)
    save(mac, "res", "mac-icon.png")
    save(tray_template(60), "res", "mac-tray-dark-x2.png")
    save(tray_template(48), "res", "mac-tray-light-x2.png")
    with tempfile.TemporaryDirectory() as tmp:
        iconset = os.path.join(tmp, "AppIcon.iconset")
        os.makedirs(iconset)
        for s in (16, 32, 128, 256, 512):
            mac.resize((s, s), Image.LANCZOS).save(os.path.join(iconset, f"icon_{s}x{s}.png"))
            mac.resize((s * 2, s * 2), Image.LANCZOS).save(os.path.join(iconset, f"icon_{s}x{s}@2x.png"))
        icns = p("flutter", "macos", "Runner", "AppIcon.icns")
        subprocess.run(["iconutil", "-c", "icns", "-o", icns, iconset], check=True)
        print("wrote", os.path.relpath(icns, ROOT))

    # Windows icons: exe/MSI/portable packer, Flutter runner window, and tray.
    ico_sizes = [(s, s) for s in (16, 24, 32, 48, 64, 128, 256)]
    for path in [("res", "icon.ico"), ("flutter", "windows", "runner", "resources", "app_icon.ico")]:
        src.resize((256, 256), Image.LANCZOS).save(p(*path), sizes=ico_sizes)
        print("wrote", os.path.join(*path))
    src.resize((64, 64), Image.LANCZOS).save(p("res", "tray-icon.ico"), sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64)])
    print("wrote", os.path.join("res", "tray-icon.ico"))

    # SVGs used by the Flutter UI and docs (placeholder only; with a real logo, supply SVGs by hand).
    if not os.path.exists(SRC):
        for path in [("flutter", "assets", "icon.svg"), ("res", "logo.svg"), ("res", "scalable.svg")]:
            with open(p(*path), "w") as f:
                f.write(svg_placeholder())
            print("wrote", os.path.join(*path))

    shutil.copyfile(p("res", "icon.png"), p("branding", "preview.png"))


if __name__ == "__main__":
    main()
