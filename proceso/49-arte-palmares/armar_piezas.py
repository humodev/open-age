#!/usr/bin/env python3
"""Arma piezas.json: el juego de arte de Palmares en gouache (proceso/49), con la receta de proceso/42
y tools/arte_gouache.py. Uso: python3 armar_piezas.py [--caras]"""
import os, sys
D = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(D, "..", "..", "tools"))
from arte_gouache import Juego

# 0 · Caras: una ronda de 6. Afrobrasileños de ascendencia centroafricana (Kongo, Ndongo); etnónimo primero.
def M(extra, pelo): return ("an Afro-Brazilian man of Central African Kongo and Mbundu descent, from the quilombo of Palmares in "
                      "northeastern Brazil, a grown adult in his early thirties, with a mature face: a broad face, a strong jaw, "
                      f"{extra}, dark eyes, faint expression lines around the eyes, deep dark brown skin, full lips, {pelo}, a thick "
                      "adult neck, broad shoulders and adult body proportions")
def F(extra, pelo): return ("an Afro-Brazilian woman of Central African Kongo and Mbundu descent, from the quilombo of Palmares in "
                      "northeastern Brazil, a grown adult in her early thirties, with a mature face: a broad oval face, high "
                      f"cheekbones, {extra}, dark eyes, faint expression lines, deep dark brown skin, full lips, {pelo}, adult "
                      "shoulders and adult body proportions")
CM = [("a broad nose with a wide base", "short tightly curled black hair"),
      ("a wide flat nose", "short tightly curled black hair and a short beard"),
      ("a broad nose with a rounded tip", "closely shaved black hair")]
CF = [("a broad nose with a wide base", "black hair in thick braids along the scalp"),
      ("a wide nose with a rounded tip", "black hair under a plain cloth head wrap"),
      ("a broad flat nose", "short tightly curled black hair")]
ROPA_M = "He wears a plain undyed cotton shirt."
ROPA_F = "She wears a plain undyed cotton blouse."

CARA_M = M(*CM[1])
CARA_F = F(*CF[1])
EDAD_M = ", a mature man of about thirty-five with a strong adult face and smile lines"
EDAD_F = ", a mature woman of about thirty-five with a strong adult face, a defined jaw and smile lines"
ZONA = "a plain solid bright red cotton tunic, one flat uniform red color"  # zona del equipo
NATURAL = "Natural undyed cotton, palm fiber, wood and iron tones for everything except the red tunic."
ARQ = ("Architecture of the 17th-century quilombo of Palmares in the forested hills of the Serra da Barriga, northeastern "
       "Brazil: rectangular houses of wattle and daub (pau a pique) with steep roofs thatched with palm leaves, palisades of "
       "sharpened logs, tall native palm trees and dense green Atlantic forest around.")
j = Juego(D, "palmares", CARA_M + EDAD_M, CARA_F + EDAD_F, ZONA, NATURAL, ARQ)
for i, (n, p) in enumerate(CM):
    j.cara(f"cara_m_{i+1}", f"Hombre {i+1} · {n} · {p}", M(n, p), 23 + i, ROPA_M)
for i, (n, p) in enumerate(CF):
    j.cara(f"cara_f_{i+1}", f"Mujer {i+1} · {n} · {p}", F(n, p), 11 + i, ROPA_F)

if "--caras" not in sys.argv:
    exec(open(os.path.join(D, "piezas_palmares.py"), encoding="utf-8").read())
j.escribir()
