#!/usr/bin/env python3
"""Arma el arte pintado de la interfaz de un pueblo (proceso/48-arte-en-la-interfaz).

Lee data/arte_pueblos.json → pueblos.<clave>: la carpeta de los PNG originales (fuente, fuera del
repo; <pieza>_<semilla>.png y, si se recolorea, <pieza>_<semilla>_mascara.png de
tools/recolorear.py) y el mapeo id del juego → pieza. Escribe en carpeta (dentro del repo):

  <pieza>.webp              retrato: unidades con su fondo; edificios y mejoras recortados (alfa)
  <pieza>_icono.webp        casilla: unidades en cabeza y torso; el resto, el recorte ajustado
  <pieza>_equipo.webp       la zona del color del jugador: gris (el valor de la tela) con alfa de
  <pieza>_icono_equipo.webp la máscara. El juego la dibuja encima teñida con el color del equipo.
  hoja.jpg                  comprobación: cada pieza a 128 y a 48 px, y teñida de azul

Uso (Pillow y numpy, sin GPU):
  python3 tools/arte_pueblo.py --pueblo=tawantinsuyu [--hoja=ruta.jpg]
"""
import argparse
import glob
import json
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter  # noqa: F401

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATOS = os.path.join(REPO, "data", "arte_pueblos.json")
CALIDAD = 88


def res_a_disco(ruta):
    return os.path.join(REPO, ruta[len("res://"):]) if ruta.startswith("res://") else ruta


def original(fuente, pieza):
    c = [f for f in glob.glob(os.path.join(fuente, pieza + "_*.png")) if not f.endswith("_mascara.png")]
    c = [f for f in c if os.path.basename(f)[len(pieza) + 1:-4].isdigit()]  # «hondero_7», no «hondero_caliente_7»
    if not c:
        raise SystemExit(f"falta el original de {pieza} en {fuente}")
    png = sorted(c)[0]
    m = png[:-4] + "_mascara.png"
    return png, (m if os.path.exists(m) else None)


def fondo_de(im):
    a = np.asarray(im.convert("RGB")).astype(np.int16)
    borde = np.concatenate([a[0], a[-1], a[:, 0], a[:, -1]])
    return np.median(borde, axis=0)


def es_fondo(im, tol):
    """Píxeles parecidos al color del borde y conectados con el borde (relleno desde afuera)."""
    a = np.asarray(im.convert("RGB")).astype(np.int16)
    d = np.abs(a - fondo_de(im)).max(axis=2)
    parecido = d < tol
    # Reconstrucción geodésica: desde el borde, crecer solo por lo parecido (relleno sin recursión).
    fondo = np.zeros_like(parecido)
    fondo[0], fondo[-1], fondo[:, 0], fondo[:, -1] = parecido[0], parecido[-1], parecido[:, 0], parecido[:, -1]
    while True:
        g = fondo.copy()
        g[1:] |= fondo[:-1]
        g[:-1] |= fondo[1:]
        g[:, 1:] |= fondo[:, :-1]
        g[:, :-1] |= fondo[:, 1:]
        g &= parecido
        if (g == fondo).all():
            return fondo
        fondo = g


def recortado(im, tol=26):
    """RGBA sin el fondo claro y liso de los edificios y las mejoras, ajustado y en cuadrado."""
    fondo = es_fondo(im, tol)
    alfa = Image.fromarray(((~fondo) * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.8))
    rgba = im.convert("RGB").copy()
    rgba.putalpha(alfa)
    caja = alfa.point(lambda v: 255 if v > 24 else 0).getbbox() or (0, 0) + im.size
    rgba = rgba.crop(caja)
    lado = int(max(rgba.size) * 1.04)
    out = Image.new("RGBA", (lado, lado), (0, 0, 0, 0))
    out.paste(rgba, ((lado - rgba.size[0]) // 2, (lado - rgba.size[1]) // 2), rgba)
    return out


def caja_icono(im, cfg, pieza=""):
    """Cuadrado de cabeza y torso: desde la coronilla, centrado en la figura de esa franja."""
    w, h = im.size
    cajas = cfg.get("cajas", {})
    clave = next((k for k in (f"{cfg.get('_pueblo', '')}:{pieza}", pieza) if k in cajas), None)
    if clave:
        x, y, lado = cajas[clave]
        return (int(x * w), int(y * h), int(x * w) + int(lado * w), int(y * h) + int(lado * w))
    fondo = es_fondo(im, 30)
    filas = np.flatnonzero((~fondo).sum(axis=1) > w * 0.01)
    arriba = int(filas[0]) if filas.size else 0
    lado = int(h * cfg["lado_pct"] / 100)
    y0 = max(0, min(h - lado, arriba - int(h * cfg["arriba_pct"] / 100)))
    franja = ~fondo[y0:y0 + lado]
    cols = np.flatnonzero(franja.sum(axis=0) > lado * 0.02)
    cx = int((cols[0] + cols[-1]) / 2) if cols.size else w // 2
    peso = franja[: lado // 3].sum(axis=0)  # la cabeza manda: que no quede cortada por la lanza
    if peso.sum() > 0:
        cx = int(0.5 * cx + 0.5 * float((np.arange(w) * peso).sum() / peso.sum()))
    x0 = max(0, min(w - lado, cx - lado // 2))
    return (x0, y0, x0 + lado, y0 + lado)


def capa_equipo(im, m):
    """Gris con el valor (V de HSV) de la zona del equipo, normalizado, y alfa = máscara."""
    v = np.asarray(im.convert("HSV")).astype(np.float32)[..., 2]
    ma = np.asarray(m.convert("L")).astype(np.float32) / 255.0
    dentro = v[ma > 0.5]
    tope = np.percentile(dentro, 92) if dentro.size else 255.0
    g = np.clip(v / max(tope, 1.0), 0, 1) * 255
    capa = Image.fromarray(g.astype(np.uint8)).convert("RGBA")
    capa.putalpha(m.convert("L"))
    return capa


def guardar(im, ruta, lado):
    im = im.resize((lado, lado), Image.LANCZOS)
    im.save(ruta, "WEBP", quality=CALIDAD, method=6)
    return im


def teñir(base, capa, color):
    c = np.asarray(capa).astype(np.float32) / 255.0
    t = c[..., :3] * np.array(color, np.float32) / 255.0
    b = np.asarray(base.convert("RGB")).astype(np.float32) / 255.0
    a = c[..., 3:4]
    return Image.fromarray(((b * (1 - a) + t * a) * 255).astype(np.uint8))


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--pueblo", required=True)
    p.add_argument("--hoja", default=None, help="comprobación en JPG (por defecto, carpeta/../hoja_gouache.jpg no se escribe)")
    a = p.parse_args()
    datos = json.load(open(DATOS, encoding="utf-8"))
    pb = datos["pueblos"][a.pueblo]
    tam = datos["tam"]
    dest = res_a_disco(pb["carpeta"])
    os.makedirs(dest, exist_ok=True)
    piezas = {}
    for grupo in ("unidades", "edificios", "tecnologias"):
        for _id, v in pb.get(grupo, {}).items():
            for pz in (v.values() if isinstance(v, dict) else [v]):
                piezas[pz] = grupo
    muestras = []
    for pz, grupo in sorted(piezas.items()):
        png, masc = original(pb["fuente"], pz)
        im = Image.open(png).convert("RGB")
        if grupo == "unidades":
            ret = guardar(im, os.path.join(dest, pz + ".webp"), tam["retrato"])
            caja = caja_icono(im, {**datos["icono_unidad"], "_pueblo": a.pueblo}, pz)
            ico = guardar(im.crop(caja), os.path.join(dest, pz + "_icono.webp"), tam["icono"])
            if masc:
                capa = capa_equipo(im, Image.open(masc))
                guardar(capa, os.path.join(dest, pz + "_equipo.webp"), tam["retrato"])
                ci = guardar(capa.crop(caja), os.path.join(dest, pz + "_icono_equipo.webp"), tam["icono"])
                muestras.append((pz, ico, teñir(ico, ci, (60, 110, 230))))
            else:
                muestras.append((pz, ico, None))
        else:
            rec = recortado(im)
            guardar(rec, os.path.join(dest, pz + ".webp"), tam["retrato"])
            ico = guardar(rec, os.path.join(dest, pz + "_icono.webp"), tam["icono"])
            muestras.append((pz, ico, None))
        print(f"{pz:24s} {grupo}{' + equipo' if masc and grupo == 'unidades' else ''}")
    if a.hoja:
        T, cols = 128, 8
        celda = (T + 48 + T + 12, T + 14)
        filas = (len(muestras) + cols - 1) // cols
        hoja = Image.new("RGB", (celda[0] * cols, celda[1] * filas), (34, 36, 40))
        d = ImageDraw.Draw(hoja)
        for i, (pz, ico, azul) in enumerate(muestras):
            x, y = (i % cols) * celda[0], (i // cols) * celda[1]
            fondo = Image.new("RGB", (T, T), (52, 56, 62))
            fondo.paste(ico, (0, 0), ico if ico.mode == "RGBA" else None)
            hoja.paste(fondo, (x, y))
            hoja.paste(fondo.resize((48, 48), Image.LANCZOS), (x + T + 2, y))
            if azul is not None:
                hoja.paste(azul, (x + T + 52, y))
            d.text((x, y + T), pz, fill=(220, 220, 220))
        hoja.save(a.hoja, quality=82)
        print("hoja:", a.hoja)


if __name__ == "__main__":
    main()
