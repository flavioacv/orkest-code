"""Package approved ribbon artwork into platform icon resources.

The artwork masters are produced by imagegen and kept unchanged. This script
only adapts sizes, masks, safe areas and formats required by each platform.
Requires Pillow: python3 tool/generate_orkest_icons.py
"""
from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
BRAND = ROOT / 'assets/branding'
MASTER = BRAND / 'orkest-app-icon-ribbon-v1.png'
SYMBOL = BRAND / 'orkest-symbol-ribbon-v1.png'
BG = '#101827'


def icon(size, foreground=False, monochrome=False, opaque=False, maskable=False):
    if foreground or monochrome:
        source = Image.open(SYMBOL).convert('RGBA')
        alpha = source.getchannel('A')
        bounds = alpha.point(lambda value: 255 if value > 32 else 0).getbbox()
        source = source.crop(bounds)
        source.thumbnail((580, 580), Image.Resampling.LANCZOS)
        if monochrome:
            white = Image.new('RGBA', source.size, 'white')
            white.putalpha(source.getchannel('A'))
            source = white
        image = Image.new('RGBA', (1024, 1024))
        image.alpha_composite(source, ((1024 - source.width) // 2, (1024 - source.height) // 2))
    else:
        image = Image.open(MASTER).convert('RGBA').resize((1024, 1024), Image.Resampling.LANCZOS)
        if maskable:
            safe = image.resize((880, 880), Image.Resampling.LANCZOS)
            image = Image.new('RGBA', (1024, 1024), BG)
            image.alpha_composite(safe, (72, 72))
        if not opaque:
            mask = Image.new('L', (1024, 1024))
            ImageDraw.Draw(mask).rounded_rectangle((0, 0, 1023, 1023), 220, fill=255)
            image.putalpha(mask)
    return image.resize((size, size), Image.Resampling.LANCZOS)


# Shared UI symbol; horizontal wordmarks are separate assets.
icon(1024).save(BRAND / 'orkest_logo.png')
for platform in ['macos', 'ios']:
    target = ROOT / platform / 'Runner/Assets.xcassets/AppIcon.appiconset'
    for entry in json.loads((target / 'Contents.json').read_text())['images']:
        if 'filename' not in entry:
            continue
        size = round(float(entry['size'].split('x')[0]) * float(entry['scale'].replace('x', '')))
        image = icon(size, opaque=platform == 'ios')
        if platform == 'ios':
            image = image.convert('RGB')
        image.save(target / entry['filename'])
for size in [64, 128, 256, 512, 1024]:
    icon(size).save(ROOT / f'linux/runner/resources/app_icon_{size}.png')
icon(256).save(ROOT / 'windows/runner/resources/app_icon.ico',
               sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
for density, scale in [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)]:
    target = ROOT / f'android/app/src/main/res/mipmap-{density}'
    icon(round(48 * scale)).save(target / 'ic_launcher.png')
    icon(round(108 * scale), foreground=True).save(target / 'ic_launcher_foreground.png')
    icon(round(108 * scale), monochrome=True).save(target / 'ic_launcher_monochrome.png')
for name, size in [('Icon-192.png', 192), ('Icon-512.png', 512),
                   ('Icon-maskable-192.png', 192), ('Icon-maskable-512.png', 512)]:
    icon(size, opaque=True, maskable='maskable' in name).save(ROOT / 'web/icons' / name)
icon(32).save(ROOT / 'web/favicon.png')
print('Packaged approved Orkest ribbon artwork for macOS, Windows, Linux, iOS, Android and web.')
