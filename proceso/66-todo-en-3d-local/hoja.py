#!/usr/bin/env python3
"""Hoja de contacto en JPEG (proceso/66): imágenes en grilla con su rótulo.

    python3 proceso/66-todo-en-3d-local/hoja.py salida.jpg --cols 6 --lado 256 img1[=rótulo] img2 ...
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


def main():
    a = sys.argv[1:]
    out = a.pop(0)
    cols, lado = 6, 256
    if "--cols" in a:
        i = a.index("--cols"); cols = int(a[i + 1]); del a[i:i + 2]
    if "--lado" in a:
        i = a.index("--lado"); lado = int(a[i + 1]); del a[i:i + 2]
    items = [(x.split("=", 1) + [Path(x).stem])[:2] for x in a]
    filas = (len(items) + cols - 1) // cols
    th = 22
    hoja = Image.new("RGB", (cols * lado, filas * (lado + th)), (236, 232, 224))
    d = ImageDraw.Draw(hoja)
    try:
        f = ImageFont.truetype("/usr/share/fonts/TTF/DejaVuSans.ttf", 13)
    except OSError:
        f = ImageFont.load_default()
    for n, (img, rot) in enumerate(items):
        x, y = (n % cols) * lado, (n // cols) * (lado + th)
        if Path(img).exists():
            im = Image.open(img).convert("RGB")
            im.thumbnail((lado, lado))
            hoja.paste(im, (x + (lado - im.width) // 2, y + (lado - im.height) // 2))
        d.text((x + 4, y + lado + 3), rot[:40], fill=(40, 36, 30), font=f)
    hoja.save(out, quality=84)
    print(out, hoja.size)


if __name__ == "__main__":
    main()
