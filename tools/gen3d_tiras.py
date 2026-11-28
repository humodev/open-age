#!/usr/bin/env python3
"""Junta los cuadros que deja tools/gen3d_rig_cuadrupedo.py --tiras en una tira por animal
(proceso/63-montados-y-animales): una fila por clip (galope, ataque, morir), seis cuadros cada
una, con el nombre al costado. JPEG de a lo sumo 300 KB.

    tools/gen3d_tiras.py <prefijo> <salida.jpg> [titulo]
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

prefijo, salida = sys.argv[1], Path(sys.argv[2])
titulo = sys.argv[3] if len(sys.argv) > 3 else Path(prefijo).name
filas = ["galope", "ataque", "morir"]
cuadros = [[Image.open(f"{prefijo}_{f}_{i:02d}.jpg") for i in range(6)] for f in filas]
w, h = cuadros[0][0].size
izq = 90
out = Image.new("RGB", (izq + 6 * w, 24 + 3 * h), (236, 232, 224))
d = ImageDraw.Draw(out)
d.text((8, 6), titulo, fill=(40, 30, 20))
for r, (nombre, fila) in enumerate(zip(filas, cuadros)):
    d.text((8, 24 + r * h + h // 2 - 6), nombre, fill=(40, 30, 20))
    for c, im in enumerate(fila):
        out.paste(im, (izq + c * w, 24 + r * h))
q = 85
while True:
    out.save(salida, quality=q)
    if salida.stat().st_size <= 300 * 1024 or q <= 40:
        break
    q -= 10
print(salida, salida.stat().st_size // 1024, "KB")
