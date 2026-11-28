#!/usr/bin/env python3
"""Texturas de la interfaz pintada (proceso/68-interfaz-pintada).

    python3 tools/interfaz_pintada.py              todas las texturas (con las fuentes de FLUX si están)
    python3 tools/interfaz_pintada.py --flux       antes, pide a FLUX las fuentes que falten (ComfyUI)
    python3 tools/interfaz_pintada.py --hoja X.jpg además, una hoja con todo para el README

Lee data/interfaz.json → hud_estilo.pintado. Escribe en assets/ui/hud/:
- superficie.webp: el papel con gouache, sin costuras, oscuro (nunca más claro que el FONDO de
  tests/test_paleta.gd). Sale de una foto de FLUX (proceso/68-interfaz-pintada/fuentes/); sin ella,
  de ruido.
- <pueblo>/marco.png: faja tejida en 9 cortes (esquinas y lados que se repiten; centro vacío).
- <pueblo>/esquina.png: la pieza de las esquinas de arriba.
- <pueblo>/marca.webp: marca de agua (arte en gouache del pueblo, en tinta oscura con un filo de luz).
- divisor.png, medallon.png, boton_<estado>.png: compartidos.
Todo al doble de resolución: el juego lo dibuja a escala 0,5 (nítido a 4K).

Las fajas son geométricas: se tejen en código, hilo por hilo, desde los datos (motivo, filas,
período y colores). FLUX inventa signos (cruces, budas, tocapus) y no repite exacto: por eso no.
"""
import argparse
import json
import math
import subprocess
import sys
import time
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "assets/ui/hud"
FUENTES = REPO / "proceso/68-interfaz-pintada/fuentes"
CELDA = 3            # px por hilo a 2x
SS = 4               # superposición al tejer (se reduce con Lanczos)
FONDO_LUM = None     # luminancia del FONDO de test_paleta (26282b)

# Pedidos a FLUX: superficies (lo que FLUX hace bien: grano, fibra, pigmento) y una candidata de
# lai Thai para comparar con la hecha en código.
FLUX = {
    "papel_7": ("flat top-down scan of a sheet of handmade paper painted with a dark umber and burnt sienna gouache wash, "
                "visible paper fibres and deckle texture, uneven pigment pooling, soft brush marks, even lighting, "
                "no objects, no text, no border, seamless texture", 7),
    "papel_8": ("flat top-down scan of thick handmade cotton rag paper with a dark brown earth pigment gouache wash, "
                "subtle fibres, granulating pigment, dry brush streaks, even diffuse light, no objects, no text, texture", 8),
    "algodon_7": ("flat top-down macro scan of handwoven undyed cotton cloth dyed dark walnut brown, coarse plain weave, "
                  "irregular handspun threads, even lighting, no objects, no text, seamless fabric texture", 7),
    "laithai_7": ("flat horizontal decorative border strip, traditional Thai lai prajam yam four-petal flower pattern, "
                  "gold paint on black lacquer, repeating geometric floral, textile border, no figures, no buddha, "
                  "no temple, flat front view", 7),
}


def fuente(k):
    """La fuente de FLUX `k` (PNG recién hecha o JPG guardada en el repo), o None."""
    for ext in (".png", ".jpg"):
        p = FUENTES / f"{k}{ext}"
        if p.exists():
            return p
    return None


def lum(rgb):
    """Luminancia relativa (WCAG) de un arreglo [...,3] en 0..1."""
    c = np.asarray(rgb, dtype=np.float64)
    lin = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return lin[..., 0] * 0.2126 + lin[..., 1] * 0.7152 + lin[..., 2] * 0.0722


def hexa(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float64) / 255.0


def ruido(h, w, escalas, rng):
    """Ruido de valor suave y sin costuras (suma de octavas interpoladas)."""
    out = np.zeros((h, w))
    for s, peso in escalas:
        gh, gw = max(1, h // s), max(1, w // s)
        g = rng.random((gh, gw))
        im = Image.fromarray((g * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
        out += (np.asarray(im, dtype=np.float64) / 255.0 - 0.5) * peso
    return out


def sin_costuras(a):
    """Mezcla con la copia corrida media vuelta: los bordes quedan con el centro (que sí continúa)."""
    h, w = a.shape[:2]
    r = np.roll(np.roll(a, h // 2, 0), w // 2, 1)
    y = np.minimum(np.arange(h), h - 1 - np.arange(h)) / (h / 2)
    x = np.minimum(np.arange(w), w - 1 - np.arange(w)) / (w / 2)
    m = np.clip(np.minimum.outer(y, x) * 2.2, 0, 1)
    m = m * m * (3 - 2 * m)
    if a.ndim == 3:
        m = m[..., None]
    return a * m + r * (1 - m)


# ------------------------------------------------------------------ superficie

def superficie(cfg, rng, lado=1024):
    """Papel con gouache, oscuro y con grano. Base: una foto de FLUX (si está) o ruido."""
    base = hexa(cfg.get("superficie_color", "1d1915"))
    # papel_8: la hoja (se recorta el centro: FLUX dejó el borde barbado). papel_7 salió como una
    # mancha sobre papel blanco: no sirve. algodon_7: la trama, mezclada suave encima del papel.
    src = fuente("papel_8")
    trama = fuente("algodon_7")
    if src is not None:
        im = Image.open(src).convert("RGB")
        w, h = im.size
        im = im.crop((int(w * 0.14), int(h * 0.14), int(w * 0.86), int(h * 0.86))).resize((lado, lado), Image.LANCZOS)
        a = np.asarray(im, dtype=np.float64) / 255.0
        a = sin_costuras(a)
        y = a.mean(axis=2)
        z = (y - y.mean()) / (y.std() + 1e-6)
        # el papel de FLUX es parejo: se le suma una aguada de baja frecuencia (pigmento que se junta)
        z = z * 0.6 + sin_costuras(ruido(lado, lado, [(256, 1.0), (96, 0.6)], rng)) / 0.25 * 0.5
        if trama is not None:
            t = np.asarray(Image.open(trama).convert("L").resize((lado, lado), Image.LANCZOS), dtype=np.float64)
            t = sin_costuras(t)
            z = z + (t - t.mean()) / (t.std() + 1e-6) * float(cfg.get("superficie_trama", 0.35))
        z = (z - z.mean()) / z.std()
        # Un poco del tono de la foto (pigmento que vira) y casi todo del valor.
        tono = a / (y[..., None] + 1e-3)
        tono = tono / tono.reshape(-1, 3).mean(axis=0)
        tono = 1 + (tono - 1) * 0.35
        print("superficie desde", src.name)
    else:
        z = ruido(lado, lado, [(256, 1.0), (64, 0.7), (16, 0.45), (4, 0.3), (2, 0.2)], rng)
        z = sin_costuras(z)
        z = (z - z.mean()) / z.std()
        tono = np.ones((lado, lado, 3))
        print("superficie de ruido (no hay fuente de FLUX)")
    k = float(cfg.get("superficie_contraste", 0.11))
    out = base[None, None, :] * tono * (1 + k * np.clip(z, -3, 3))[..., None]
    # Tope: ningún píxel (salvo el 0,2 % más claro, que se recorta) más claro que el FONDO.
    out = np.clip(out, 0, 1)
    L = lum(out)
    tope = FONDO_LUM * 0.97
    p = np.percentile(L, 99.8)
    if p > tope:
        out = out * (tope / p) ** (1 / 2.2)
    L = lum(out)
    over = L > tope
    out[over] *= ((tope / L[over]) ** (1 / 2.2))[:, None]
    return np.clip(out, 0, 1)


# ------------------------------------------------------------------ fajas tejidas

def matriz(motivo, filas, periodo, n_col):
    """Índices de color (filas × periodo). Fila 0 = el lado de afuera del panel."""
    F, P = filas, periodo
    m = np.zeros((F, P), dtype=int)
    mid = F // 2
    if motivo == "pallay_rombos":
        # 0 oscuro, 1 rojo | motivo en 2..F-3: rombos encadenados, contorno blanco, amarillo y
        # centro oscuro, con un punto verde donde se tocan | rojo, oscuro
        m[:] = 1
        m[0] = 0; m[F - 1] = 0
        r = (F - 5) // 2  # radio del rombo
        for j in range(P):
            for i in range(2, F - 2):
                d = abs(i - mid) + abs((j % P) - P // 2)
                if d == r:
                    m[i, j] = 3
                elif d == r - 1:
                    m[i, j] = 2
                elif d < r - 1:
                    m[i, j] = 0
        m[mid, 0] = 4
    elif motivo == "escalonado":
        m[:] = 0  # negro
        m[1] = 1; m[F - 2] = 1  # rojo
        m[0] = 0; m[F - 1] = 0
        for j in range(P):
            for i in range(2, F - 2):
                d = abs(i - mid)
                x = abs((j % P) - P // 2)
                # rombo escalonado: escalón de 2 columnas por fila
                if (x // 2 + d) == (F - 5) // 2:
                    m[i, j] = 2
                elif (x // 2 + d) < (F - 5) // 2 - 1:
                    m[i, j] = 1 if (x // 2 + d) == 0 else 0
        m[mid, 0] = 2
    elif motivo == "sarga":
        # 0 natural horizontal, 1 teñida vertical (cestería). Espiga: la diagonal cambia a la mitad.
        m[:] = 0
        for i in range(F):
            for j in range(P):
                jj = j if j < P // 2 else P - 1 - j
                m[i, j] = 0 if ((i + jj) % 4) < 2 else 1
        m[0] = 3; m[F - 1] = 3  # atadura
        m[1] = 2; m[F - 2] = 2
    elif motivo == "tibeb":
        m[:] = 0  # algodón
        m[0] = 5; m[F - 1] = 5
        m[2] = 1; m[F - 3] = 1  # hilos rojos
        m[3:F - 3] = 5          # la guarda: fondo oscuro entre dos rayas rojas, sobre el algodón
        for j in range(P):
            x = abs((j % P) - P // 2)
            for i in range(3, F - 3):
                d = abs(i - mid) + x
                if d <= 1:
                    m[i, j] = 3      # centro amarillo
                elif d == 2:
                    m[i, j] = 2      # verde
                elif d == 3:
                    m[i, j] = 1      # rojo
                elif d == 4:
                    m[i, j] = 4      # azul
            # triángulos entre rombos (sin cruz: nunca una línea vertical y una horizontal juntas)
    elif motivo == "rafia":
        m[:] = 0
        m[0] = 2; m[F - 1] = 2
        m[1] = 1; m[F - 2] = 1
        for i in range(2, F - 2):
            for j in range(P):
                x = (j % P)
                # zigzag doble y rombo entrelazado
                if (abs(i - mid) + abs(x - P // 2)) % 4 == 0:
                    m[i, j] = 2
                elif (abs(i - mid) + abs(x - P // 2)) % 4 == 2:
                    m[i, j] = 3
    elif motivo == "cordon":
        m[:] = 1
        m[0] = 0; m[F - 1] = 0
        for i in range(1, F - 1):
            for j in range(P):
                k = (j - i) % P
                m[i, j] = 2 if k < P // 2 - 1 else (3 if k == P // 2 - 1 else 1)
    elif motivo == "prajam_yam":
        m[:] = 0
        m[1] = 1; m[F - 2] = 1  # filetes de oro
    else:
        raise SystemExit(f"motivo desconocido: {motivo}")
    return np.clip(m, 0, n_col - 1)


def esquina_matriz(m, motivo):
    """Bloque de la esquina: las rayas de afuera dan la vuelta; adentro, un rombo chico."""
    F = m.shape[0]
    col = m[:, 0]
    # filas de raya (todas las columnas iguales) desde afuera
    rayas = [i for i in range(F) if (m[i] == m[i, 0]).all()]
    m0 = 0
    while m0 in rayas:
        m0 += 1
    m1 = F - 1
    while m1 in rayas and m1 > m0:
        m1 -= 1
    c = np.zeros((F, F), dtype=int)
    fondo = np.bincount(m[m0:m1 + 1].ravel()).argmax()
    acento = [v for v in np.unique(m[m0:m1 + 1]) if v != fondo]
    acento = acento[0] if acento else fondo
    mid = (m0 + m1) / 2
    for i in range(F):
        for j in range(F):
            r = min(i, j)
            if r < m0:
                c[i, j] = col[r]
            elif i > m1 and j > m1:
                c[i, j] = col[min(i, j)]
            elif i > m1 or j > m1:
                c[i, j] = col[max(i, j)] if max(i, j) <= F - 1 else fondo
            else:
                d = abs(i - mid) + abs(j - mid)
                c[i, j] = acento if d <= (m1 - m0) / 2 - 0.5 and d >= (m1 - m0) / 2 - 1.5 else fondo
                if d < 0.6:
                    c[i, j] = acento
    return c


def tejer(m, colores, rng, modo="urdimbre", celda=CELDA):
    """Cada celda, un hilo pintado: color con la variación de los tintes naturales, sombra de
    cilindro y un hueco oscuro entre hilos. modo cesteria: la orientación de la tira sigue al color."""
    F, P = m.shape
    S = celda * SS
    pal = np.array([hexa(c) for c in colores])
    col = pal[m]                                                 # F,P,3
    jit = 1 + rng.normal(0, 0.06, (F, P, 1)) + rng.normal(0, 0.04, (1, P, 1))
    col = np.clip(col * jit, 0, 1)
    big = np.repeat(np.repeat(col, S, 0), S, 1)                  # F*S, P*S, 3
    t = (np.arange(S) + 0.5) / S
    perfil = 0.62 + 0.42 * np.sin(np.pi * t)                     # cilindro
    extremo = 0.82 + 0.18 * np.sin(np.pi * t)
    vert = np.outer(extremo, perfil)                              # hilo vertical (urdimbre)
    hori = vert.T
    if modo == "cesteria":
        orient = (m % 2 == 1)                                     # teñidas verticales, naturales horizontales
        prof = np.where(np.repeat(np.repeat(orient, S, 0), S, 1), np.tile(vert, (F, P)), np.tile(hori, (F, P)))
    else:
        prof = np.tile(vert, (F, P))
    fibra = 1 + ruido(F * S, P * S, [(S // 2, 0.10), (2, 0.08)], rng)
    out = big * (prof * fibra)[..., None]
    im = Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8))
    return im.resize((P * celda, F * celda), Image.LANCZOS)


def prajam(m, colores, rng, celda=CELDA):
    """Lai Thai pintado (no tejido): laca negra, filetes de oro y la flor de cuatro pétalos."""
    F, P = m.shape
    S = celda * SS
    W, H = P * S, F * S
    pal = [tuple(int(v * 255) for v in hexa(c)) for c in colores]
    im = Image.new("RGB", (W, H), pal[0])
    d = ImageDraw.Draw(im)
    for i in range(F):  # filetes
        if m[i, 0] != 0:
            d.rectangle([0, i * S, W, (i + 1) * S - 1], fill=pal[m[i, 0]])
    cy = H / 2
    cx = W / 2
    r = (F - 4) * S / 2
    # rombo de oro (marco de la flor) y la flor: cuatro pétalos en gota hacia los vértices
    for ox in (cx - W, cx, cx + W):
        d.polygon([(ox, cy - r), (ox + r, cy), (ox, cy + r), (ox - r, cy)], outline=pal[1], width=max(2, S // 2))
        for ang in range(4):
            a = ang * math.pi / 2
            px, py = ox + math.cos(a) * r * 0.42, cy + math.sin(a) * r * 0.42
            pr = r * 0.30
            d.ellipse([px - pr, py - pr, px + pr, py + pr], fill=pal[2])
        d.ellipse([ox - r * 0.16, cy - r * 0.16, ox + r * 0.16, cy + r * 0.16], fill=pal[3])
        # punto de oro entre rombos
        d.ellipse([ox + W / 2 - S * 0.7, cy - S * 0.7, ox + W / 2 + S * 0.7, cy + S * 0.7], fill=pal[1])
    a = np.asarray(im, dtype=np.float64) / 255.0
    a = a * (1 + ruido(H, W, [(S, 0.12), (3, 0.08)], rng))[..., None]  # pincel y pan de oro
    return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).resize((P * celda, F * celda), Image.LANCZOS)


def pintar(img, papel, rng, fuerza=0.35):
    """Multiplica por el grano del papel y una aguada leve: que no quede plano ni digital."""
    a = np.asarray(img.convert("RGB"), dtype=np.float64) / 255.0
    h, w = a.shape[:2]
    g = papel[:h, :w].mean(axis=2)
    g = g / g.mean()
    agua = 1 + ruido(h, w, [(max(2, w // 3), 0.10), (8, 0.05)], rng)
    a = a * (1 + (g - 1) * fuerza)[..., None] * agua[..., None]
    return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8))


def faja(fcfg, rng, papel):
    m = matriz(fcfg["motivo"], int(fcfg["filas"]), int(fcfg["periodo"]), len(fcfg["colores"]))
    if fcfg["motivo"] == "prajam_yam":
        tira = prajam(m, fcfg["colores"], rng)
        esq = prajam(np.tile(m[:, :1], (1, m.shape[0])), fcfg["colores"], rng)
    else:
        modo = "cesteria" if fcfg["motivo"] in ("sarga", "rafia") else "urdimbre"
        tira = tejer(m, fcfg["colores"], rng, modo)
        esq = tejer(esquina_matriz(m, fcfg["motivo"]), fcfg["colores"], rng, modo)
    return pintar(tira, papel, rng), pintar(esq, papel, rng), m


def marco(tira, esq, reps=3):
    """9 cortes: esquina (c×c), lados = la tira repetida `reps` veces, centro vacío. Fila 0 de la
    tira = afuera. Las cuatro esquinas, la misma pieza girada."""
    c = tira.height
    L = tira.width * reps
    lado = Image.new("RGBA", (L, c))
    for k in range(reps):
        lado.paste(tira, (k * tira.width, 0))
    T = 2 * c + L
    im = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    im.paste(lado, (c, 0))                                              # arriba
    im.paste(lado.transpose(Image.FLIP_TOP_BOTTOM), (c, T - c))        # abajo
    izq = lado.transpose(Image.TRANSPOSE)                               # afuera a la izquierda
    im.paste(izq, (0, c))
    im.paste(izq.transpose(Image.FLIP_LEFT_RIGHT), (T - c, c))
    e = esq.convert("RGBA")
    im.paste(e, (0, 0))
    im.paste(e.transpose(Image.FLIP_LEFT_RIGHT), (T - c, 0))
    im.paste(e.transpose(Image.FLIP_TOP_BOTTOM), (0, T - c))
    im.paste(e.transpose(Image.ROTATE_180), (T - c, T - c))
    # Filo de sombra hacia adentro (la faja está cosida encima del papel).
    a = np.asarray(im, dtype=np.float64)
    sombra = np.zeros((T, T))
    for k, v in enumerate((0.55, 0.3, 0.12)):
        sombra[c + k, c:T - c] = v; sombra[T - c - 1 - k, c:T - c] = v
        sombra[c:T - c, c + k] = np.maximum(sombra[c:T - c, c + k], v)
        sombra[c:T - c, T - c - 1 - k] = np.maximum(sombra[c:T - c, T - c - 1 - k], v)
    hueco = a[..., 3] == 0
    a[hueco, 3] = sombra[hueco] * 255
    return Image.fromarray(a.astype(np.uint8)), c


def pieza_esquina(fcfg, rng, papel, lado=15):
    """La pieza de las esquinas de arriba: un cuadrado tejido con un rombo concéntrico."""
    cols = fcfg["colores"]
    n = len(cols)
    m = np.zeros((lado, lado), dtype=int)
    mid = lado // 2
    orden = [0, 1, 2, 3, 2, 1, 4 % n, 3 % n]
    for i in range(lado):
        for j in range(lado):
            d = abs(i - mid) + abs(j - mid)
            m[i, j] = orden[min(d // 1, len(orden) - 1) % len(orden)] % n if d <= mid else 0
    m[0, :] = m[-1, :] = m[:, 0] = m[:, -1] = 0
    if fcfg["motivo"] == "prajam_yam":
        im = prajam(np.full((lado, lado), 0), cols, rng)
        d = ImageDraw.Draw(im)
        s = im.width
        d.polygon([(s / 2, 2), (s - 2, s / 2), (s / 2, s - 2), (2, s / 2)], outline=tuple(int(v * 255) for v in hexa(cols[1])), width=2)
        d.ellipse([s / 2 - 5, s / 2 - 5, s / 2 + 5, s / 2 + 5], fill=tuple(int(v * 255) for v in hexa(cols[2])))
    else:
        im = tejer(m, cols, rng, "cesteria" if fcfg["motivo"] in ("sarga", "rafia") else "urdimbre")
    im = pintar(im, papel, rng).convert("RGBA")
    # recorte en rombo con borde suave (la pieza se cose en diagonal sobre la esquina)
    s = im.width
    mask = Image.new("L", (s * 4, s * 4), 0)
    ImageDraw.Draw(mask).polygon([(s * 2, 0), (s * 4, s * 2), (s * 2, s * 4), (0, s * 2)], fill=255)
    mask = mask.resize((s, s), Image.LANCZOS)
    im.putalpha(mask)
    # contorno oscuro
    out = Image.new("RGBA", (s + 4, s + 4), (0, 0, 0, 0))
    sh = Image.new("RGBA", (s, s), (10, 8, 6, 200))
    sh.putalpha(mask.point(lambda v: int(v * 0.75)))
    out.alpha_composite(sh, (3, 3))
    out.alpha_composite(im, (2, 2))
    return out


# ------------------------------------------------------------------ piezas compartidas

def divisor(rng, papel):
    m = matriz("cordon", 4, 8, 4)
    im = tejer(m, ["1e1812", "6a5232", "c9a25a", "ead08a"], rng)
    tira = Image.new("RGBA", (im.width * 4, im.height))
    for k in range(4):
        tira.paste(im, (k * im.width, 0))
    return pintar(tira, papel, rng, 0.2)


def medallon(rng, papel, lado=256, grosor=22):
    """Marco cuadrado del retrato: latón pintado al gouache con un cordón y botones en las esquinas."""
    S = 4
    W = lado * S
    g = grosor * S
    im = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rad = 18 * S
    d.rounded_rectangle([0, 0, W - 1, W - 1], radius=rad, fill=(28, 20, 12, 255))
    d.rounded_rectangle([S * 2, S * 2, W - 1 - S * 2, W - 1 - S * 2], radius=rad - S * 2, fill=(150, 112, 52, 255))
    d.rounded_rectangle([g - S * 5, g - S * 5, W - g + S * 5, W - g + S * 5], radius=rad - S * 4, outline=(226, 190, 110, 255), width=S * 2)
    d.rounded_rectangle([g - S * 2, g - S * 2, W - g + S * 2, W - g + S * 2], radius=rad - S * 6, fill=(20, 14, 9, 255))
    d.rounded_rectangle([g, g, W - g, W - g], radius=rad - S * 8, fill=(0, 0, 0, 0))
    # cordón en la mitad del marco
    paso = 6 * S
    y0 = S * 6
    for k in range(0, W, paso):
        for (x, y) in ((k, y0), (k, W - y0)):
            if rad < x < W - rad:
                d.ellipse([x - S * 2.2, y - S * 2.2, x + S * 2.2, y + S * 2.2], fill=(214, 172, 88, 255))
        for (x, y) in ((y0, k), (W - y0, k)):
            if rad < y < W - rad:
                d.ellipse([x - S * 2.2, y - S * 2.2, x + S * 2.2, y + S * 2.2], fill=(214, 172, 88, 255))
    for (x, y) in ((y0 + S * 4, y0 + S * 4), (W - y0 - S * 4, y0 + S * 4), (y0 + S * 4, W - y0 - S * 4), (W - y0 - S * 4, W - y0 - S * 4)):
        d.regular_polygon((x, y, S * 7), 4, rotation=45, fill=(20, 14, 9, 255))
        d.regular_polygon((x, y, S * 5), 4, rotation=45, fill=(232, 196, 112, 255))
    im = im.resize((lado, lado), Image.LANCZOS)
    a = np.asarray(im, dtype=np.float64) / 255.0
    g2 = papel[:lado, :lado].mean(axis=2)
    g2 = g2 / g2.mean()
    a[..., :3] *= (1 + (g2 - 1) * 0.6)[..., None] * (1 + ruido(lado, lado, [(64, 0.18), (12, 0.08)], rng))[..., None]
    return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8))


def boton(estado, papel, rng, w=96, h=64, m=12):
    """Botón: papel algo más claro que el panel (sin pasar el FONDO) y filete pintado."""
    base = {"normal": 1.18, "hover": 1.42, "pressed": 0.82, "disabled": 0.9}[estado]
    tinte = {"normal": (1, 1, 1), "hover": (1.04, 1.0, 0.94), "pressed": (1.10, 1.0, 0.80), "disabled": (0.9, 0.92, 0.95)}[estado]
    filete = {"normal": (150, 118, 64), "hover": (232, 190, 96), "pressed": (227, 178, 60), "disabled": (92, 88, 82)}[estado]
    p = papel[:h, :w] * base * np.array(tinte)
    if estado == "disabled":
        p = p * 0.75 + p.mean(axis=2, keepdims=True) * 0.25
    p = np.clip(p, 0, 1)
    L = lum(p)
    tope = FONDO_LUM * 0.97
    over = L > tope
    p[over] *= ((tope / L[over]) ** (1 / 2.2))[:, None]
    S = 4
    big = Image.fromarray((p * 255).astype(np.uint8)).resize((w * S, h * S), Image.BICUBIC).convert("RGBA")
    mask = Image.new("L", (w * S, h * S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w * S - 1, h * S - 1], radius=7 * S, fill=255)
    big.putalpha(mask)
    d = ImageDraw.Draw(big)
    # filete irregular (pincel): dos pasadas corridas
    for k, al in ((0, 255), (1, 120)):
        d.rounded_rectangle([S * (2 + k), S * (2 + k), w * S - 1 - S * (2 + k), h * S - 1 - S * (2 + k)], radius=6 * S,
                            outline=filete + (al,), width=S + S // 2)
    if estado == "pressed":  # sombra de adentro arriba
        d.rectangle([S * 5, S * 5, w * S - S * 5, S * 9], fill=(0, 0, 0, 90))
    if estado == "hover":
        d.line([S * 10, S * 6, w * S - S * 10, S * 6], fill=(255, 236, 190, 70), width=S)
    return big.resize((w, h), Image.LANCZOS)


def marca(civ, pieza, alto=300):
    """Marca de agua: el arte en gouache del pueblo en tinta más oscura que el papel, con un filo
    de luz arriba a la izquierda (relieve hundido). Nunca más clara que el FONDO."""
    p = REPO / f"assets/ui/arte/{civ}/gouache/{pieza}.webp"
    if not p.exists():
        return None
    im = Image.open(p).convert("RGBA")
    im = im.resize((alto, alto), Image.LANCZOS)
    a = np.asarray(im, dtype=np.float64) / 255.0
    al = a[..., 3]
    y = a[..., :3].mean(axis=2)
    # bordes del dibujo (lo que se lee en la marca): gradiente del valor
    gy, gx = np.gradient(y)
    borde = np.clip(np.hypot(gx, gy) * 6, 0, 1)
    tinta = np.clip(al * (0.2 + 0.25 * (1 - y) + 0.9 * borde), 0, 1)
    out = np.zeros((alto, alto, 4))
    out[..., :3] = hexa("0b0907")
    out[..., 3] = tinta * 0.7
    # filo de luz: donde el alfa sube hacia abajo a la derecha
    sh = np.roll(np.roll(al, 2, 0), 2, 1)
    luz = np.clip(al - sh, 0, 1)
    luzc = hexa("2c261f")
    k = luz * 0.9
    out[..., :3] = out[..., :3] * (1 - k[..., None]) + luzc * k[..., None]
    out[..., 3] = np.maximum(out[..., 3], k * 0.8)
    img = Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8))
    return img.filter(ImageFilter.GaussianBlur(0.6))


# ------------------------------------------------------------------ FLUX

def pedir_flux(rehacer=False):
    sys.path.insert(0, str(REPO / "tools"))
    import arte_gouache as ag
    falta = [(k, v) for k, v in FLUX.items() if rehacer or fuente(k) is None]
    print(len(falta), "imágenes de FLUX por hacer", flush=True)
    if not falta:
        return
    FUENTES.mkdir(parents=True, exist_ok=True)
    ag.comfy_arrancar()
    for u in ag._scopes():
        subprocess.run(["systemctl", "--user", "set-property", "--runtime", u, "MemoryHigh=infinity"], capture_output=True)
    try:
        for k, (prompt, sem) in falta:
            ancho, alto = (1280, 384) if k.startswith("laithai") else (768, 768)
            t0 = time.time()
            pref = FUENTES / k.rsplit("_", 1)[0]
            r = subprocess.run([ag.PY, str(REPO / "tools/generar_local.py"), prompt, "--modelo", "flux", "--semilla", str(sem),
                                "--ancho", str(ancho), "--alto", str(alto), "--salida", str(pref)], capture_output=True, text=True)
            hecho = FUENTES / f"{k}.png"
            if r.returncode != 0 or not hecho.exists():
                print("FALLÓ", k, r.stdout[-300:], r.stderr[-600:], flush=True)
                continue
            print(f"{k}: {time.time() - t0:.0f} s", flush=True)
    finally:
        if not ag.comfy_apagar():
            sys.exit("ComfyUI sigue vivo")


# ------------------------------------------------------------------ main

def guardar(im, ruta, calidad=None):
    ruta.parent.mkdir(parents=True, exist_ok=True)
    if ruta.suffix == ".webp":
        im.save(ruta, "WEBP", quality=calidad or 88, method=6)
    else:
        im.save(ruta, optimize=True)


def main():
    global FONDO_LUM
    ap = argparse.ArgumentParser()
    ap.add_argument("--flux", action="store_true")
    ap.add_argument("--rehacer-flux", action="store_true")
    ap.add_argument("--hoja")
    a = ap.parse_args()
    FONDO_LUM = float(lum(hexa("26282b")))
    if a.flux or a.rehacer_flux:
        pedir_flux(a.rehacer_flux)
    d = json.loads((REPO / "data/interfaz.json").read_text())
    cfg = d["hud_estilo"]["pintado"]
    rng = np.random.default_rng(68)
    sup = superficie(cfg, rng)
    guardar(Image.fromarray((sup * 255).astype(np.uint8)), OUT / "superficie.webp", 90)
    print(f"superficie: lum media {lum(sup).mean():.4f}, p99,8 {np.percentile(lum(sup), 99.8):.4f}, tope {FONDO_LUM:.4f}")
    papel = sup / sup.mean(axis=(0, 1))  # grano normalizado (media 1) para multiplicar
    hoja = []
    for civ, pc in cfg["pueblos"].items():
        tira, esq, _ = faja(pc["faja"], rng, papel)
        mk, c = marco(tira, esq)
        guardar(mk, OUT / civ / "marco.png")
        guardar(pieza_esquina(pc["faja"], rng, papel), OUT / civ / "esquina.png")
        guardar(tira, OUT / civ / "faja.png")
        print(f"{civ}: marco {mk.size}, margen {c}")
        if pc.get("marca"):
            mm = marca(civ, pc["marca"])
            if mm is not None:
                guardar(mm, OUT / civ / "marca.webp", 85)
        hoja.append((civ, mk))
    guardar(divisor(rng, papel), OUT / "divisor.png")
    guardar(medallon(rng, papel), OUT / "medallon.png")
    for e in ("normal", "hover", "pressed", "disabled"):
        guardar(boton(e, sup, rng), OUT / f"boton_{e}.png")
    if a.hoja:
        hoja_muestras(a.hoja, cfg, sup)


def hoja_muestras(ruta, cfg, sup):
    """Hoja para el README: cada faja sobre el papel, a 2x."""
    filas = list(cfg["pueblos"].keys())
    W, H = 1400, 140 * len(filas) + 300
    bg = Image.fromarray((sup * 255).astype(np.uint8)).resize((1024, 1024))
    out = Image.new("RGB", (W, H))
    for y in range(0, H, 1024):
        for x in range(0, W, 1024):
            out.paste(bg, (x, y))
    d = ImageDraw.Draw(out)
    for k, civ in enumerate(filas):
        y = 20 + k * 140
        mk = Image.open(OUT / civ / "marco.png").convert("RGBA")
        out.paste(mk, (20, y), mk)
        tira = Image.open(OUT / civ / "faja.png").convert("RGBA")
        t2 = tira.resize((tira.width * 3, tira.height * 3), Image.NEAREST)
        for x in range(200, 1000, t2.width):
            out.paste(t2, (x, y + 10), t2)
        e = Image.open(OUT / civ / "esquina.png").convert("RGBA")
        e = e.resize((e.width * 3, e.height * 3), Image.LANCZOS)
        out.paste(e, (1020, y), e)
        mp = OUT / civ / "marca.webp"
        if mp.exists():
            m = Image.open(mp).convert("RGBA").resize((120, 120))
            out.paste(m, (1180, y), m)
        d.text((200, y + 110), civ, fill=(236, 232, 225))
    y = 20 + len(filas) * 140
    for k, e in enumerate(("normal", "hover", "pressed", "disabled")):
        b = Image.open(OUT / f"boton_{e}.png").convert("RGBA").resize((192, 128))
        out.paste(b, (20 + k * 210, y), b)
        d.text((60 + k * 210, y + 56), e, fill=(236, 232, 225))
    me = Image.open(OUT / "medallon.png").convert("RGBA")
    out.paste(me, (880, y), me)
    dv = Image.open(OUT / "divisor.png").convert("RGBA")
    dv = dv.resize((dv.width * 3, dv.height * 3), Image.NEAREST)
    out.paste(dv, (1150, y + 120), dv)
    out.save(ruta, quality=78)
    print("hoja:", ruta)


if __name__ == "__main__":
    main()
