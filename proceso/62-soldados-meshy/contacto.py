"""Hoja de contacto de las hojas de soldados: contacto.py salida.jpg [ancho_celda] [civ:unidad ...]"""
import sys
from PIL import Image, ImageDraw
O = "/mnt/games/01_Projects/comfyui/output"
DIR = {"tawantinsuyu": "incas"}
out = sys.argv[1]
w = int(sys.argv[2]) if len(sys.argv) > 2 else 384
items = [a.split(":") for a in sys.argv[3:]]
h = w * 2 // 3
cols = 4
rows = (len(items) + cols - 1) // cols
img = Image.new("RGB", (cols * w, rows * (h + 18)), "white")
d = ImageDraw.Draw(img)
for i, (c, u) in enumerate(items):
    try:
        im = Image.open(f"{O}/{DIR.get(c, c)}_gouache/hoja_{u}_soldado_31.png").convert("RGB").resize((w, h))
    except FileNotFoundError:
        continue
    x, y = (i % cols) * w, (i // cols) * (h + 18)
    img.paste(im, (x, y + 18))
    d.text((x + 4, y + 3), f"{c} · {u}", fill="black")
img.save(out, quality=82)
