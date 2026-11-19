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


# ---------------------------------------------------------------- Cursores
# Celda de 64 px (src/game/ui/cursores.gd la achica a data/interfaz.json → cursores.px por la
# escala de la interfaz). Flecha propia + una insignia abajo a la derecha con la silueta de la
# acción (las mismas de los íconos). Punto activo: cursores.punta en data/interfaz.json.
CURSORES = os.path.join(RAIZ, "assets", "ui", "cursores")
VERDE, ROJO, DORADO, ACERO = _hex("85f2c4"), _hex("ff5a26"), _hex("e3b23c"), _hex("d9dee6")
FLECHA = [(4, 4), (4, 46), (14, 37), (21, 53), (30, 49), (23, 33.5), (36, 33.5)]
INSIGNIA = {  # tipo: (color del aro, ícono del catálogo, color del ícono o None = su material)
    "mover": (VERDE, None, VERDE),
    "atacar": (ROJO, "atacar", ACERO),
    "construir": (DORADO, "martillo", None),
    "reparar": (VERDE, "martillo", VERDE),
    "recolectar_alimento": (_hex(RES["alimento"]), "alimento", None),
    "recolectar_madera": (_hex(RES["madera"]), "madera", None),
    "recolectar_piedra": (_hex(RES["piedra"]), "piedra", None),
    "recolectar_riqueza": (_hex(RES["riqueza"]), "riqueza", None),
    "refugio": (DORADO, "escudo", None),
    "depositar": (DORADO, "carga", None),
}


def _capa(lado):
    return Image.new("RGBA", (lado, lado), (0, 0, 0, 0))


def _con_sombra(img, k):
    """Sombra blanda abajo a la derecha: se lee sobre pasto claro y sobre la niebla."""
    a = img.getchannel("A").filter(ImageFilter.GaussianBlur(2 * k))
    sombra = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sombra.paste(Image.new("RGBA", img.size, (0, 0, 0, 110)), (2 * k, 3 * k), a)
    return Image.alpha_composite(sombra, img)


def _poligono(lado, k, pts, relleno, borde):
    m = Image.new("L", (lado, lado), 0)
    ImageDraw.Draw(m).polygon([(x * k, y * k) for x, y in pts], fill=255)
    out = _capa(lado)
    out.paste(Image.new("RGBA", (lado, lado), OSCURO + (255,)), (0, 0), m.filter(ImageFilter.MaxFilter(2 * borde * k + 1)))
    out.paste(relleno, (0, 0), m)
    return out


def cursor(tipo, cat):
    k = ESCALA
    lado = BASE * k
    img = _capa(lado)
    dr = ImageDraw.Draw(img)
    if tipo == "no":
        c, r = 32 * k, 20 * k
        dr.ellipse((c - r - 6 * k, c - r - 6 * k, c + r + 6 * k, c + r + 6 * k), outline=OSCURO + (255,), width=16 * k)
        dr.ellipse((c - r - 3 * k, c - r - 3 * k, c + r + 3 * k, c + r + 3 * k), outline=ROJO + (255,), width=7 * k)
        dr.line((17 * k, 17 * k, 47 * k, 47 * k), fill=OSCURO + (255,), width=13 * k)
        dr.line((18 * k, 18 * k, 46 * k, 46 * k), fill=ROJO + (255,), width=7 * k)
        return _con_sombra(img, k)
    if tipo == "reunion":
        dr.line((10 * k, 4 * k, 10 * k, 58 * k), fill=OSCURO + (255,), width=8 * k)
        dr.line((10 * k, 5 * k, 10 * k, 57 * k), fill=(0x9A, 0x73, 0x50, 255), width=4 * k)
        tela = _poligono(lado, k, [(12, 5), (52, 15), (12, 28)], degradado(lado, _mezcla(DORADO, (255, 255, 255), 0.3), DORADO), 2)
        img = Image.alpha_composite(img, tela)
        ImageDraw.Draw(img).ellipse((6 * k, 54 * k, 14 * k, 62 * k), fill=(0xEC, 0xE8, 0xE1, 255), outline=OSCURO + (255,), width=2 * k)
        return _con_sombra(img, k)
    # Atacar: la flecha entera en rojo, para distinguirla de un vistazo en medio de la pelea.
    piel = (_mezcla(ROJO, (255, 255, 255), 0.35), _mezcla(ROJO, (0, 0, 0), 0.2)) if tipo == "atacar" else NEUTRO
    img = _poligono(lado, k, FLECHA, degradado(lado, *piel), 3)
    aro, icono, color = INSIGNIA[tipo]
    cx, cy, r = 46 * k, 46 * k, 17 * k
    dr = ImageDraw.Draw(img)
    dr.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(22, 24, 28, 255), outline=OSCURO + (255,), width=k)
    dr.ellipse((cx - r + 2 * k, cy - r + 2 * k, cx + r - 2 * k, cy + r - 2 * k), outline=aro + (255,), width=int(2.5 * k))
    if icono is None:  # mover: cuatro puntas
        for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            sx, sy = -dy, dx
            pts = [(46 + dx * 12, 46 + dy * 12), (46 + dx * 4 + sx * 6, 46 + dy * 4 + sy * 6), (46 + dx * 4 - sx * 6, 46 + dy * 4 - sy * 6)]
            dr.polygon([(x * k, y * k) for x, y in pts], fill=color + (255,))
    else:
        a = silueta(ruta_svg(cat[icono]["fuente"]), 22 * k)
        luz, sombra = (_mezcla(color, (255, 255, 255), 0.3), color) if color else material(icono)
        pinta = degradado(22 * k, luz, sombra)
        img.paste(pinta, (cx - 11 * k, cy - 11 * k), a)
    return _con_sombra(img, k)


def cursores(cat):
    os.makedirs(CURSORES, exist_ok=True)
    tipos = list(INSIGNIA) + ["reunion", "no"]
    for t in tipos:
        cursor(t, cat).resize((BASE, BASE), Image.LANCZOS).save(os.path.join(CURSORES, t + ".png"))
    print(len(tipos), "cursores en", os.path.relpath(CURSORES, RAIZ))


# ---------------------------------------------------------------- Marco del HUD
# Textura de 9 cortes (data/interfaz.json → marco; Hud.dibujar_marco) que se dibuja encima del
# fondo de los paneles: canto oscuro, filete de bronce (el dorado de la interfaz apagado), un
# brillo arriba y un rombo en cada esquina. El centro es transparente: el fondo sigue siendo el
# de Hud.panel_box, así que el color y la transparencia del panel no cambian.
MARCOS = os.path.join(RAIZ, "assets", "ui", "marcos")
LADO_MARCO, RADIO_MARCO = 32, 8


def marco():
    k = 8
    L, R = LADO_MARCO * k, RADIO_MARCO * k
    img = _capa(L)
    dr = ImageDraw.Draw(img)
    bronce = _mezcla(DORADO, (40, 30, 20), 0.45)
    dr.rounded_rectangle((0, 0, L - 1, L - 1), R, outline=(8, 9, 11, 235), width=k)
    dr.rounded_rectangle((k, k, L - 1 - k, L - 1 - k), R - k, outline=bronce + (230,), width=k)
    brillo = _capa(L)
    ImageDraw.Draw(brillo).rounded_rectangle((2 * k, 2 * k, L - 1 - 2 * k, L - 1 - 2 * k), R - 2 * k, outline=(255, 255, 255, 34), width=k)
    corte = Image.new("L", (L, L), 0)
    ImageDraw.Draw(corte).rectangle((0, 0, L, L // 2), fill=255)  # el brillo, solo en la mitad de arriba
    img = Image.alpha_composite(img, Image.composite(brillo, _capa(L), corte))
    dr = ImageDraw.Draw(img)
    for cx, cy in ((5, 5), (LADO_MARCO - 5, 5), (5, LADO_MARCO - 5), (LADO_MARCO - 5, LADO_MARCO - 5)):
        d = 1.6
        dr.polygon([((cx) * k, (cy - d) * k), ((cx + d) * k, cy * k), (cx * k, (cy + d) * k), ((cx - d) * k, cy * k)], fill=DORADO + (190,))
    os.makedirs(MARCOS, exist_ok=True)
    img.resize((LADO_MARCO, LADO_MARCO), Image.LANCZOS).save(os.path.join(MARCOS, "marco.png"))
    print("marco en", os.path.relpath(MARCOS, RAIZ))


def main():
    cat = json.load(open(CATALOGO, encoding="utf-8"))
    if "--marcos" in sys.argv:
        marco()
    if "--bajar" in sys.argv:
        bajar(cat)
    if "--cursores" in sys.argv:
        cursores(cat)
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
