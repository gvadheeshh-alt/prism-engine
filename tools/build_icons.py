"""Draws the PRISM logo (five spectrum stripes, same proportions as the wordmark in the app)
and writes the web favicon, PWA icons and Android launcher icons.   python tools/build_icons.py"""
import os
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(__file__), '..')
SPECTRUM = [(0x7B, 0x61, 0xF0), (0x14, 0xB3, 0xA3), (0xE5, 0xA5, 0x0F), (0x3D, 0x7B, 0xF5), (0xE0, 0x50, 0x7A)]
NAVY = (0x0B, 0x10, 0x20)

def logo(size, maskable=False):
    """Navy rounded tile with the five stripes. Maskable icons keep the stripes inside the central safe zone."""
    s = size * 4  # draw large, then shrink for smooth edges
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if maskable:
        d.rectangle([0, 0, s, s], fill=NAVY)            # platform applies its own mask shape
        area = 0.56                                     # stay inside the 80% safe zone with margin
    else:
        d.rounded_rectangle([0, 0, s - 1, s - 1], radius=int(s * 0.22), fill=NAVY)
        area = 0.70
    # Wordmark proportions: stripe width 0.16, height 0.8, gap ~0.05 of the wordmark size.
    unit = s * area / (5 * 0.16 + 4 * 0.05)
    w, gap, h = unit * 0.16, unit * 0.05, unit * 0.8
    total = 5 * w + 4 * gap
    x0, y0 = (s - total) / 2, (s - h) / 2
    r = max(1, int(w * 0.18))
    for i, c in enumerate(SPECTRUM):
        x = x0 + i * (w + gap)
        d.rounded_rectangle([x, y0, x + w, y0 + h], radius=r, fill=c)
    return img.resize((size, size), Image.LANCZOS)

def save(img, *path):
    p = os.path.join(ROOT, *path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    img.save(p)
    return p

out = [
    save(logo(64), 'web', 'favicon.png'),
    save(logo(192), 'web', 'icons', 'Icon-192.png'),
    save(logo(512), 'web', 'icons', 'Icon-512.png'),
    save(logo(192, maskable=True), 'web', 'icons', 'Icon-maskable-192.png'),
    save(logo(512, maskable=True), 'web', 'icons', 'Icon-maskable-512.png'),
]
for folder, px in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
    out.append(save(logo(px), 'android', 'app', 'src', 'main', 'res', f'mipmap-{folder}', 'ic_launcher.png'))
logo(512).save('/tmp/prism_logo_preview.png')
print('\n'.join(os.path.relpath(p, ROOT) for p in out))
