#!/usr/bin/env python3
"""Arma piezas.json: el juego de arte de Ayutthaya en gouache (proceso/49), con la receta de proceso/42
y tools/arte_gouache.py. Uso: python3 armar_piezas.py [--caras]"""
import os, sys
D = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(D, "..", "..", "tools"))
from arte_gouache import Juego

# 0 · Caras: una ronda de 6. Siameses (tailandeses) del reino de Ayutthaya; etnónimo primero.
# La Loubère (1691): hombres y mujeres con el pelo muy corto.
def M(extra): return ("a Siamese Thai man from the kingdom of Ayutthaya in central Thailand, a grown adult in his early thirties, "
                      f"with a mature face: a broad face, high cheekbones, {extra}, dark almond-shaped eyes, faint expression lines "
                      "around the eyes, warm light-brown skin, dark brown lips, short cropped black hair, a thick adult neck, broad "
                      "shoulders and adult body proportions")
def F(extra): return ("a Siamese Thai woman from the kingdom of Ayutthaya in central Thailand, a grown adult in her early thirties, "
                      f"with a mature face: a broad oval face, high cheekbones, {extra}, dark almond-shaped eyes, faint expression "
                      "lines, warm light-brown skin, dark brownish lips, short black hair cropped close to the head and brushed up "
                      "on top, adult shoulders and adult body proportions")
NARIZ_M = ["a short wide nose with a low bridge", "a broad nose with rounded nostrils", "a straight wide nose"]
NARIZ_F = ["a short wide nose with a low bridge", "a small broad nose", "a straight wide nose"]
ROPA_M = "Bare shoulders, a plain undyed cotton cloth over one shoulder."
ROPA_F = "She wears a plain undyed cotton breast cloth wrapped across the chest and over one shoulder."

CARA_M = M(NARIZ_M[0])
CARA_F = F(NARIZ_F[1])
EDAD_M = ", a mature man of about thirty-five with a strong adult face and smile lines"
EDAD_F = ", a mature woman of about thirty-five with a strong adult face, a defined jaw and smile lines"
ZONA = ("a plain solid bright red cotton chong kraben, the wrapped lower garment pulled up between the legs like loose knee "
        "breeches, one flat uniform red color")  # zona del equipo
NATURAL = "Natural undyed cotton, wood and bronze tones for everything except the red garment."
ARQ = ("Secular architecture of the 17th-century Siamese kingdom of Ayutthaya: houses of teak wood raised on stilts with "
       "steep gable roofs with curved ends, and brick buildings with whitewashed walls and tiered roofs of orange and "
       "green glazed tiles, by a river and canals, coconut palms and banana plants.")
j = Juego(D, "ayutthaya", CARA_M + EDAD_M, CARA_F + EDAD_F, ZONA, NATURAL, ARQ)
for i, n in enumerate(NARIZ_M):
    j.cara(f"cara_m_{i+1}", f"Hombre {i+1} · {n}", M(n), 23 + i, ROPA_M)
for i, n in enumerate(NARIZ_F):
    j.cara(f"cara_f_{i+1}", f"Mujer {i+1} · {n}", F(n), 11 + i, ROPA_F)

if "--caras" not in sys.argv:
    exec(open(os.path.join(D, "piezas_ayutthaya.py"), encoding="utf-8").read())
j.escribir()
