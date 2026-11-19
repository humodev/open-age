#!/usr/bin/env python3
"""Íconos genéricos de la interfaz a partir de siluetas de game-icons.net (CC BY 3.0).

Lee assets/ui/iconos/catalogo.json ({nombre del ícono: {fuente, autor, material}}) y, por cada uno:

  1. (con --bajar) baja la silueta SVG de game-icons.net a assets/ui/iconos/fuentes/;
  2. la rasteriza con rsvg-convert a 4× el tamaño final;
  3. la encuadra en el marco fijo: lienzo cuadrado, la silueta centrada en una caja de 52/64
     (margen de 6/64), así todas pesan lo mismo en la casilla;
  4. la pinta con el material: «neutro» (pergamino claro, para órdenes, mejoras y estados) o el
     color natural del recurso (Palette.RES de src/game/palette.gd), con luz desde arriba a la
     izquierda (degradé) y un contorno oscuro de 2 px a 64 px;
  5. exporta PNG en los tamaños de la grilla (32 y 64) y una lámina de revisión.

Los íconos genéricos no llevan color de equipo, así que no hay máscara aparte; si un material
pide equipo («equipo": true en el catálogo), sale además <nombre>_equipo.png con la zona en blanco.

  python3 tools/iconos_render.py [--bajar] [--lamina=ruta.png]
"""
import json
import os
import re
import subprocess
import sys
import urllib.request

from PIL import Image, ImageChops, ImageDraw, ImageFilter

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR = os.path.join(RAIZ, "assets", "ui", "iconos")
FUENTES = os.path.join(DIR, "fuentes")
CATALOGO = os.path.join(DIR, "catalogo.json")
URL = "https://game-icons.net/icons/ffffff/000000/1x1/%s.svg"

TAMANOS = (32, 64)
BASE = 64            # medidas del marco, en px de un ícono de 64
CAJA = 52            # la silueta entra en una caja de 52×52, centrada
CONTORNO = 2.0       # contorno oscuro
ESCALA = 4           # se dibuja a 4× y se achica con Lanczos

OSCURO = (16, 17, 20)
# Materiales: (color de la luz, arriba a la izquierda; color de la sombra, abajo a la derecha).
NEUTRO = ((0xF6, 0xF1, 0xE7), (0xB4, 0xAC, 0x9C))
RES = {  # Palette.RES (src/game/palette.gd)
    "alimento": "bf4a6c",
    "madera": "46bf5a",
    "piedra": "bacad1",
    "riqueza": "e8d317",
}


def _hex(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def _mezcla(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def material(nombre):
    if nombre in RES:
        c = _hex(RES[nombre])
        return (_mezcla(c, (255, 255, 255), 0.45), _mezcla(c, (0, 0, 0), 0.08))
    return NEUTRO


def ruta_svg(fuente):
    return os.path.join(FUENTES, fuente.replace("/", "_") + ".svg")


def bajar(cat):
    os.makedirs(FUENTES, exist_ok=True)
    for nombre, d in cat.items():
        if nombre.startswith("_"):
            continue
        dst = ruta_svg(d["fuente"])
        if os.path.exists(dst):
            continue
        svg = urllib.request.urlopen(URL % d["fuente"]).read().decode("utf-8")
        # Sin el cuadrado negro de fondo: queda la silueta blanca sobre transparente.
        svg = re.sub(r'<path d="M0 0h512v512H0z"\s*/>', "", svg, count=1)
        with open(dst, "w", encoding="utf-8") as f:
            f.write(svg)
        print("bajado", d["fuente"])


def silueta(svg, lado):
    """Alfa de la silueta, recortada a su contenido y encajada en la caja del marco."""
    png = subprocess.run(["rsvg-convert", "-w", "1024", "-h", "1024", svg], check=True, capture_output=True).stdout
    from io import BytesIO
    im = Image.open(BytesIO(png)).convert("RGBA")
    a = im.getchannel("A")
    bb = a.getbbox()
    a = a.crop(bb)
    caja = lado * CAJA // BASE
    k = caja / max(a.size)
    a = a.resize((max(1, round(a.size[0] * k)), max(1, round(a.size[1] * k))), Image.LANCZOS)
    out = Image.new("L", (lado, lado), 0)
    out.paste(a, ((lado - a.size[0]) // 2, (lado - a.size[1]) // 2))
    return out


def degradado(lado, luz, sombra):
    g = Image.new("RGB", (lado, lado))
    px = g.load()
    for y in range(lado):
        for x in range(lado):
            t = (x + y) / (2 * (lado - 1))
            px[x, y] = _mezcla(luz, sombra, t)
    return g


def render(nombre, d):
    lado = BASE * ESCALA
    a = silueta(ruta_svg(d["fuente"]), lado)
    r = int(round(CONTORNO * ESCALA))
    borde = a.filter(ImageFilter.MaxFilter(2 * r + 1))
    luz, sombra = material(nombre)
    relleno = degradado(lado, luz, sombra)
    # Filo interior más oscuro abajo a la derecha: la luz viene de arriba a la izquierda.
    corrida = ImageChops.offset(a, -ESCALA, -ESCALA)
    filo = ImageChops.subtract(a, corrida)
    relleno = Image.composite(Image.new("RGB", (lado, lado), _mezcla(sombra, (0, 0, 0), 0.35)), relleno, filo)
    img = Image.new("RGBA", (lado, lado), OSCURO + (0,))
    img.paste(Image.new("RGBA", (lado, lado), OSCURO + (255,)), (0, 0), borde)
    img.paste(relleno, (0, 0), a)
    for t in TAMANOS:
        img.resize((t, t), Image.LANCZOS).save(os.path.join(DIR, "%s_%d.png" % (nombre, t)))
    if d.get("equipo"):
        Image.merge("RGBA", (a, a, a, a)).resize((64, 64), Image.LANCZOS).save(os.path.join(DIR, nombre + "_equipo.png"))
    return img


def main():
    cat = json.load(open(CATALOGO, encoding="utf-8"))
    if "--bajar" in sys.argv:
        bajar(cat)
    hechos = []
    for nombre, d in cat.items():
        if nombre.startswith("_"):
            continue
        hechos.append((nombre, render(nombre, d)))
    lamina = next((x.split("=", 1)[1] for x in sys.argv if x.startswith("--lamina=")), "")
    if lamina:
        # Cada ícono a 64 y a 32 sobre el fondo de la casilla, para revisar que se lea chico.
        col, celda = 6, 112
        filas = (len(hechos) + col - 1) // col
        hoja = Image.new("RGB", (col * celda, filas * celda), (24, 26, 30))
        dr = ImageDraw.Draw(hoja)
        for i, (n, img) in enumerate(hechos):
            x, y = (i % col) * celda, (i // col) * celda
            dr.rounded_rectangle((x + 4, y + 4, x + celda - 4, y + celda - 4), 6, fill=(36, 39, 44))
            hoja.paste(img.resize((64, 64), Image.LANCZOS), (x + 8, y + 10), img.resize((64, 64), Image.LANCZOS))
            p = img.resize((32, 32), Image.LANCZOS)
            hoja.paste(p, (x + 74, y + 26), p)
            dr.text((x + 8, y + 90), n, fill=(236, 232, 225))
        hoja.save(lamina)
    print(len(hechos), "íconos en", os.path.relpath(DIR, RAIZ))


if __name__ == "__main__":
    main()
