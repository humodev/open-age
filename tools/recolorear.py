#!/usr/bin/env python3
"""Recolorea la «zona del equipo» (ropa en rojo saturado plano) de una imagen de unidad.

La máscara se arma por tono (HSV): rojo con saturación alta, que no toque la piel
(la piel es naranja, tono ~15-35°, y menos saturada). Se guarda como <imagen>_mascara.png
(blanco = color del jugador, con bordes suaves) para que el juego recoloree.

Uso (con el python de ComfyUI, que trae Pillow y numpy):
    python3 tools/recolorear.py imagen.png [--colores azul verde amarillo] [--hoja salida.jpg]

--hoja arma la comprobación: original | gris | un recoloreo por cada color.
"""
import argparse
import numpy as np
from PIL import Image, ImageFilter

# Tono objetivo en grados (HSV) de cada color de jugador.
COLORES = {"azul": 220, "verde": 120, "amarillo": 50, "violeta": 280, "rojo": 0, "cian": 185}


def mascara(im, tono_max=12, sat_min=0.45, val_min=0.12, area_min=0.004):
    hsv = np.asarray(im.convert("HSV")).astype(np.float32) / 255.0
    h, s, v = hsv[..., 0] * 360, hsv[..., 1], hsv[..., 2]
    rojo = ((h <= tono_max) | (h >= 360 - tono_max * 1.5)) & (s >= sat_min) & (v >= val_min)
    # Solo las manchas grandes: labios, orejas y yemas de los dedos quedan afuera.
    from scipy import ndimage
    etiquetas, n = ndimage.label(rojo)
    if n:
        tam = ndimage.sum(rojo, etiquetas, range(1, n + 1))
        grandes = np.isin(etiquetas, 1 + np.flatnonzero(tam >= area_min * rojo.size))
        rojo = ndimage.binary_closing(grandes, iterations=2)
    m = Image.fromarray((rojo * 255).astype(np.uint8))
    return m.filter(ImageFilter.GaussianBlur(1.2))


def recolorear(im, m, tono):
    hsv = np.asarray(im.convert("HSV")).astype(np.float32)
    nuevo = hsv.copy()
    nuevo[..., 0] = tono / 360 * 255
    if tono in (50,):  # el amarillo necesita más valor para no verse oliva
        nuevo[..., 2] = np.clip(nuevo[..., 2] * 1.25 + 20, 0, 255)
    rec = Image.fromarray(nuevo.astype(np.uint8), "HSV").convert("RGB")
    return Image.composite(rec, im.convert("RGB"), m)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("imagen")
    p.add_argument("--colores", nargs="*", default=["azul", "verde"])
    p.add_argument("--hoja", default=None)
    p.add_argument("--sin-mascara", action="store_true", help="no guardar _mascara.png")
    a = p.parse_args()
    im = Image.open(a.imagen).convert("RGB")
    m = mascara(im)
    if not a.sin_mascara:
        m.save(a.imagen.rsplit(".", 1)[0] + "_mascara.png")
    cobertura = np.asarray(m).mean() / 255
    print(f"{a.imagen}: zona del equipo {cobertura:.1%} de la imagen")
    if a.hoja:
        piezas = [im, im.convert("L").convert("RGB")] + [recolorear(im, m, COLORES[c]) for c in a.colores]
        w, h = im.size
        hoja = Image.new("RGB", (w * len(piezas), h))
        for i, x in enumerate(piezas):
            hoja.paste(x, (i * w, 0))
        hoja.thumbnail((256 * len(piezas), 512))
        hoja.save(a.hoja, quality=85)


if __name__ == "__main__":
    main()
