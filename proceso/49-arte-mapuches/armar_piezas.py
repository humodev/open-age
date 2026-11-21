#!/usr/bin/env python3
"""Arma piezas.json: el juego de arte mapuche en gouache (proceso/49), con la receta de proceso/42
y tools/arte_gouache.py. Uso: python3 armar_piezas.py"""
import os, sys
D = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(D, "..", "..", "tools"))
from arte_gouache import Juego

# 0 · Caras: una ronda de 6. Etnónimo primero, inglés concreto, sin negaciones.
def M(extra): return ("a Mapuche man from Araucanía in southern Chile, a grown adult in his early thirties, with a mature face: "
                      f"a broad face, a strong wide jaw, high cheekbones, {extra}, dark eyes, faint expression lines around the eyes, "
                      "light copper-brown skin, dark brown lips the same tone as his skin, thick straight black hair to the shoulders "
                      "held by a woven wool headband, a thick adult neck, broad shoulders and adult body proportions")
def F(extra): return ("a Mapuche woman from Araucanía in southern Chile, a grown adult in her early thirties, with a mature face: "
                      f"a broad round face, high cheekbones, {extra}, dark eyes, faint expression lines, light copper-brown skin, "
                      "dark brownish lips, thick straight black hair parted in the middle in two long braids wrapped with dark blue "
                      "wool ribbons, adult shoulders and adult body proportions")
NARIZ_M = ["a straight wide nose", "a large slightly hooked nose with a wide base", "a wide flat nose bridge and a rounded nose tip"]
NARIZ_F = ["a straight wide nose", "a short wide nose with a rounded tip", "a slightly convex nose with a wide base"]
ROPA_M = "He wears a plain undyed grey wool poncho."
ROPA_F = "She wears a black wool dress pinned on one shoulder and a dark wool shawl."

# Elegidas en la ronda de caras (ver README).
CARA_M = M(NARIZ_M[0])
CARA_F = F(NARIZ_F[1])
ZONA = "a plain solid bright red wool poncho, one flat uniform red color"  # zona del equipo
NATURAL = "Natural undyed wool and leather tones for everything except the red poncho."
ARQ = ("Mapuche architecture of the temperate forests of southern Chile: rounded or oval houses with a thick thatched roof "
       "of grass and reeds that reaches almost to the ground, walls of wooden poles and woven branches, a low doorway facing "
       "east, wooden pole fences, green meadows and tall forest around.")
j = Juego(D, "mapuches", CARA_M, CARA_F, ZONA, NATURAL, ARQ)
for i, n in enumerate(NARIZ_M):
    j.cara(f"cara_m_{i+1}", f"Hombre {i+1} · {n}", M(n), 23 + i, ROPA_M)
for i, n in enumerate(NARIZ_F):
    j.cara(f"cara_f_{i+1}", f"Mujer {i+1} · {n}", F(n), 11 + i, ROPA_F)

if "--caras" not in sys.argv:
    exec(open(os.path.join(D, "piezas_mapuches.py"), encoding="utf-8").read())
j.escribir()
