#!/usr/bin/env python
"""Vlastní tečkované sloupce pro Waybar. FontTools je potřeba jen při generování."""

from pathlib import Path
from math import ceil
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

TARGET = Path.home() / ".local/share/fonts/desktop-waves/DesktopWaves.ttf"
NAMES = [".notdef", "space"] + [f"wave{level}" for level in range(8)]
font = FontBuilder(1000, isTTF=True)
font.setupGlyphOrder(NAMES)
font.setupCharacterMap({32: "space", **{0xE000 + n: f"wave{n}" for n in range(8)}})
glyphs = {}
for name in NAMES:
    pen = TTGlyphPen(None)
    if name.startswith("wave"):
        level = int(name[4:])
        # Dvojice kulatých bodů rostou symetricky kolem středového bodu.
        height = level * 5 / 7
        for row in range(-ceil(height), ceil(height) + 1):
            # Okrajové body se zvětšují postupně; mezi kruhy zůstává viditelná mezera.
            strength = min(1, height - abs(row) + 1)
            x, y = 100, 350 + row * 83
            rx = ry = round(33 * strength)
            pen.moveTo((x + rx, y))
            pen.qCurveTo((x + rx, y + ry), (x, y + ry))
            pen.qCurveTo((x - rx, y + ry), (x - rx, y))
            pen.qCurveTo((x - rx, y - ry), (x, y - ry))
            pen.qCurveTo((x + rx, y - ry), (x + rx, y))
            pen.closePath()
    glyphs[name] = pen.glyph()
font.setupGlyf(glyphs)
font.setupHorizontalMetrics({name: (200, 0) for name in NAMES})
font.setupHorizontalHeader(ascent=850, descent=-150)
font.setupOS2(sTypoAscender=850, sTypoDescender=-150, usWinAscent=850, usWinDescent=150)
font.setupNameTable(
    {
        "familyName": "Desktop Waves",
        "styleName": "Regular",
        "uniqueFontIdentifier": "DesktopWaves-Regular-2",
        "fullName": "Desktop Waves Regular",
        "psName": "DesktopWaves-Regular",
    }
)
font.setupPost()
font.setupMaxp()
TARGET.parent.mkdir(parents=True, exist_ok=True)
font.save(TARGET)
print(TARGET)
