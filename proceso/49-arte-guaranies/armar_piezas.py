#!/usr/bin/env python3
"""Arma piezas.json: el juego de arte guaraní en gouache (proceso/49), con la receta de proceso/42
y tools/arte_gouache.py. Uso: python3 armar_piezas.py [--caras]"""
import os, sys
D = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(D, "..", "..", "tools"))
from arte_gouache import Juego

# 0 · Caras: una ronda de 6. Etnónimo primero, inglés concreto, sin negaciones.
def M(extra): return ("a Guaraní man from the subtropical forests of the Paraná river in Paraguay, a grown adult in his early thirties, "
                      f"with a mature face: a broad face, a wide jaw, high rounded cheekbones, {extra}, dark almond-shaped eyes, faint "
                      "expression lines around the eyes, warm golden-brown skin, dark brown lips the same tone as his skin, thick straight "
                      "black hair cut straight across the forehead and long at the back, a thick adult neck, broad shoulders and adult "
                      "body proportions")
def F(extra): return ("a Guaraní woman from the subtropical forests of the Paraná river in Paraguay, a grown adult in her early thirties, "
                      f"with a mature face: a broad round face, high rounded cheekbones, {extra}, dark almond-shaped eyes, faint expression "
                      "lines, warm golden-brown skin, dark brownish lips, very long thick straight black hair falling loose down her back, "
                      "adult shoulders and adult body proportions")
NARIZ_M = ["a wide nose with a low bridge", "a broad straight nose", "a short wide nose with flared nostrils"]
NARIZ_F = ["a wide nose with a low bridge", "a short broad nose", "a small wide nose with a rounded tip"]
ROPA_M = "Bare shoulders, a thin line of red body paint across the cheekbones."
ROPA_F = "She wears a plain undyed white cotton sleeveless tunic."

CARA_M = M(NARIZ_M[1])
CARA_F = F(NARIZ_F[1])
ZONA = "a plain solid bright red cotton sleeveless tunic (tipoy), one flat uniform red color"  # zona del equipo
NATURAL = "Natural undyed cotton, wood and plant fiber tones for everything except the red tunic."
ARQ = ("Guaraní architecture of the subtropical Paraná forest: long houses with wooden posts and walls of tacuara bamboo canes "
       "and mud, steep thatched roofs of grass and palm leaves reaching almost to the ground, red earth, dense green forest with "
       "palm trees around.")
j = Juego(D, "guaranies", CARA_M, CARA_F, ZONA, NATURAL, ARQ)
for i, n in enumerate(NARIZ_M):
    j.cara(f"cara_m_{i+1}", f"Hombre {i+1} · {n}", M(n), 23 + i, ROPA_M)
for i, n in enumerate(NARIZ_F):
    j.cara(f"cara_f_{i+1}", f"Mujer {i+1} · {n}", F(n), 11 + i, ROPA_F)

if "--caras" not in sys.argv:
    exec(open(os.path.join(D, "piezas_guaranies.py"), encoding="utf-8").read())
j.escribir()
