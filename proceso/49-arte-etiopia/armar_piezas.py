#!/usr/bin/env python3
"""Arma piezas.json: el juego de arte etíope en gouache (proceso/49), con la receta de proceso/42
y tools/arte_gouache.py. Uso: python3 armar_piezas.py [--caras]"""
import os, sys
D = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(D, "..", "..", "tools"))
from arte_gouache import Juego

# 0 · Caras: una ronda de 6. Amhara y Tigray de las tierras altas; etnónimo primero.
def M(pueblo, extra): return (f"an Ethiopian {pueblo} man from the northern Ethiopian highlands, a grown adult in his early thirties, "
                      f"with a mature face: an oval face, high cheekbones, {extra}, large dark eyes, faint expression lines around the "
                      "eyes, warm medium-brown skin, full dark brown lips, short tightly curled black hair and a short trimmed black beard, "
                      "a thick adult neck, broad shoulders and adult body proportions")
def F(pueblo, extra): return (f"an Ethiopian {pueblo} woman from the northern Ethiopian highlands, a grown adult in her early thirties, "
                      f"with a mature face: an oval face, high cheekbones, {extra}, large dark eyes, faint expression lines, warm "
                      "medium-brown skin, full dark brownish lips, black hair braided in many thin tight braids along the scalp "
                      "(shuruba) gathered at the back, adult shoulders and adult body proportions")
CM = [("Amhara", "a long straight narrow nose"), ("Tigray", "a straight nose with a rounded tip"), ("Amhara", "a slightly aquiline nose")]
CF = [("Amhara", "a long straight narrow nose"), ("Tigray", "a straight nose with a rounded tip"), ("Amhara", "a slightly aquiline nose")]
ROPA_M = "He wears a white cotton shawl with a thin colored woven border over his shoulders."
ROPA_F = "She wears a white cotton dress and a white cotton shawl with a thin colored woven border."

# Elegidos: hombre 3 y mujer 1. Lección de los guaraníes: en cuerpo entero rejuvenecen, así que
# la edad va dicha de nuevo.
CARA_M = M(*CM[2]) + ", a mature man of about thirty-five with a strong adult face and smile lines"
CARA_F = F(*CF[0]) + ", a mature woman of about thirty-five with a strong adult face, a defined jaw and smile lines"
ZONA = "a long plain solid bright red cotton tunic, one flat uniform red color"  # zona del equipo
NATURAL = "Natural white cotton, hide and leather tones for everything except the red tunic."
ARQ = ("Ethiopian highland architecture of the 16th and 17th centuries: round houses (tukul) with walls of stone or wattle "
       "and daub and steep conical thatched roofs, walls of brown and grey fieldstone set in mud, green highland plateau with "
       "flat-topped cliffs (amba), juniper and acacia trees.")
j = Juego(D, "etiopia", CARA_M, CARA_F, ZONA, NATURAL, ARQ)
for i, (p, n) in enumerate(CM):
    j.cara(f"cara_m_{i+1}", f"Hombre {i+1} · {p} · {n}", M(p, n), 23 + i, ROPA_M)
for i, (p, n) in enumerate(CF):
    j.cara(f"cara_f_{i+1}", f"Mujer {i+1} · {p} · {n}", F(p, n), 11 + i, ROPA_F)

if "--caras" not in sys.argv:
    exec(open(os.path.join(D, "piezas_etiopia.py"), encoding="utf-8").read())
j.escribir()
