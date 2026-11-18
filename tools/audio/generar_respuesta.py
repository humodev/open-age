#!/usr/bin/env python3
"""Sonidos de respuesta inmediata (etapa 30, frente 3): elegir por categoría, la orden por función y el cimiento.

Uso:  python3 tools/audio/generar_respuesta.py [civ ...]      (sin argumentos, todos y los genéricos)
Sale: assets/audio/civ/<civ>/<civ>_elegir_{aldeano,tropa,edificio}.ogg
      assets/audio/civ/<civ>/<civ>_orden_{civil,montado,asedio}.ogg   (la orden «a pie» es <civ>_orden.ogg, de 4g)
      assets/audio/ui/ui_elegir_{aldeano,tropa,edificio}.ogg y ui_cimiento.ogg (genéricos, para los pueblos sin entrada)
      tools/audio/medidas_respuesta.json

Todo sintetizado con tools/audio/instrumentos.py (obra propia, CC0). Sin instrumentos sagrados
(proceso/24-tras-la-segunda-ronda/4h-sonido-con-respeto.md): ni kultrun, ni mbaraka ni takuapu, ni begena,
ni berimbau; el kebero y el ching, que también son de la liturgia o del repertorio ceremonial, quedan fuera de
los clics, como en la orden de 4g. Son golpes y notas sueltas: no imitan ningún toque.
"""
from __future__ import annotations

import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import instrumentos as ins  # noqa: E402
from dsp import (bandpass, expdecay, export, fade, lowpass, modal, noise, place, reverb, silence,  # noqa: E402
                 trim_tail)
from generar_sonidos import BATI, D3, KULL, MIM, PAL, TRU_F0, A4, B4, D5, E5, G4, _pg  # noqa: E402

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CIV = os.path.join(RAIZ, "assets", "audio", "civ")
UI = os.path.join(RAIZ, "assets", "audio", "ui")

# Más bajos que la orden de 4g (-20): se oyen en cada clic.
NIVEL = {"elegir": -22.0, "orden": -20.0, "cimiento": -18.0}


def _corto(x: np.ndarray, fout: float = 0.05) -> np.ndarray:
    return trim_tail(fade(x, 0.0, fout))


def _dos(a: np.ndarray, b: np.ndarray, sep: float, dur: float = 0.6) -> np.ndarray:
    buf = silence(dur)
    buf = place(buf, a, 0.0)
    return place(buf, b, sep)


# ---------------------------------------------------------------- genéricos (madera y cuero)

def _toc(f: float, dur: float, seed: int, vel: float = 1.0) -> np.ndarray:
    """Golpe de madera: tres modos secos y un clic de ataque."""
    x = modal(dur, [(f, 1.0, 0.05), (f * 2.7, 0.4, 0.025), (f * 5.1, 0.15, 0.012)], seed)
    n = len(x)
    clic = bandpass(noise(dur, seed + 1), 1500, 6000, 2) * expdecay(n, 0.004) * 0.3
    return (x + clic) * vel


def ui_elegir_aldeano() -> np.ndarray:
    return _corto(_toc(520, 0.18, 10, 0.8))


def ui_elegir_tropa() -> np.ndarray:
    return _corto(_dos(_toc(680, 0.12, 11, 0.7), _toc(900, 0.16, 12, 0.8), 0.055, 0.3))


def ui_elegir_edificio() -> np.ndarray:
    return _corto(_toc(190, 0.3, 13, 1.0), 0.08)


def ui_cimiento() -> np.ndarray:
    """Tablones apoyados en la tierra: un golpe grave, otro de rebote y el soplo del polvo."""
    b = silence(0.7)
    b = place(b, _toc(140, 0.35, 20, 1.0), 0.0)
    b = place(b, _toc(210, 0.25, 21, 0.45), 0.07)
    polvo = lowpass(noise(0.5, 22), 1400, 2) * expdecay(int(0.5 * 44100), 0.12, 0.03) * 0.35
    b = place(b, polvo, 0.01)
    return trim_tail(reverb(b, 0.1, 0.2, seed=23))


GENERICOS = {"ui_elegir_aldeano": ui_elegir_aldeano, "ui_elegir_tropa": ui_elegir_tropa,
             "ui_elegir_edificio": ui_elegir_edificio, "ui_cimiento": ui_cimiento}


# ---------------------------------------------------------------- por pueblo
# aldeano: una nota tranquila; tropa: algo más brillante y seco; edificio: grave.
# civil: dos notas que suben; montado: dos golpes rápidos (el paso del caballo); asedio: grave y pesado.

SONIDOS = {
    "tawantinsuyu": {
        "elegir_aldeano": lambda: _corto(ins.siku(A4, 0.18, seed=3000, vel=0.7)),
        "elegir_tropa": lambda: _corto(ins.quena(E5, 0.14, seed=3001, vel=0.8)),
        "elegir_edificio": lambda: _corto(ins.wankara(0.35, seed=3002, vel=0.7), 0.1),
        "orden_civil": lambda: _corto(_dos(ins.siku(G4, 0.12, seed=3010, vel=0.7), ins.siku(B4, 0.2, seed=3011, vel=0.75), 0.1)),
        "orden_montado": lambda: _corto(_dos(ins.quena(D5, 0.09, seed=3020, vel=0.8), ins.quena(D5 * 2, 0.16, seed=3021, vel=0.85), 0.08)),
        "orden_asedio": lambda: _corto(_dos(ins.wankara(0.4, seed=3030, vel=0.9), ins.siku(E5 / 2, 0.3, seed=3031, vel=0.6), 0.0)),
    },
    "mapuches": {
        "elegir_aldeano": lambda: _corto(ins.kakelkultrun(0.22, seed=3100, vel=0.6, centro=False)),
        "elegir_tropa": lambda: _corto(ins.kull_kull(KULL, 0.1, seed=3101, vel=0.7)),
        "elegir_edificio": lambda: _corto(ins.kakelkultrun(0.35, seed=3102, vel=0.8, centro=True), 0.1),
        "orden_civil": lambda: _corto(ins.trutruka(TRU_F0, 4, 0.25, seed=3110, vel=0.7)),
        "orden_montado": lambda: _corto(_dos(ins.kull_kull(KULL, 0.08, seed=3120, vel=0.8), ins.kull_kull(KULL * 2, 0.14, seed=3121, vel=0.8), 0.09)),
        "orden_asedio": lambda: _corto(_dos(ins.kakelkultrun(0.4, seed=3130, vel=0.9), ins.trutruka(TRU_F0, 3, 0.3, seed=3131, vel=0.75), 0.02)),
    },
    "guaranies": {
        "elegir_aldeano": lambda: _corto(ins.mimby(MIM["E5"], 0.15, seed=3200, vel=0.6)),
        "elegir_tropa": lambda: _corto(ins.angu_apu(False, 0.18, seed=3201, vel=0.8)),
        "elegir_edificio": lambda: _corto(ins.angu_apu(True, 0.35, seed=3202, vel=0.8), 0.1),
        "orden_civil": lambda: _corto(_dos(ins.mimby(MIM["A5"], 0.08, seed=3210, vel=0.65), ins.mimby(MIM["C6"], 0.16, seed=3211, vel=0.7), 0.08)),
        "orden_montado": lambda: _corto(_dos(ins.angu_apu(False, 0.12, seed=3220, vel=0.8), ins.angu_apu(False, 0.18, seed=3221, vel=0.9), 0.09)),
        "orden_asedio": lambda: _corto(_dos(ins.angu_apu(True, 0.45, seed=3230, vel=1.0), ins.mimby(MIM["E5"], 0.2, seed=3231, vel=0.5), 0.03)),
    },
    "etiopia": {
        "elegir_aldeano": lambda: _corto(ins.krar(BATI["D"], 0.25, seed=3300, vel=0.7)),
        "elegir_tropa": lambda: _corto(ins.krar(BATI["D5"], 0.18, seed=3301, vel=0.8)),
        "elegir_edificio": lambda: _corto(ins.masenqo([(0.0, D3)], 0.3, seed=3302, vel=0.7), 0.1),
        "orden_civil": lambda: _corto(_dos(ins.krar(BATI["F#"], 0.15, seed=3310, vel=0.7), ins.krar(BATI["A"], 0.25, seed=3311, vel=0.75), 0.09)),
        "orden_montado": lambda: _corto(_dos(ins.krar(BATI["C#"], 0.1, seed=3320, vel=0.8), ins.krar(BATI["D5"], 0.2, seed=3321, vel=0.85), 0.07)),
        "orden_asedio": lambda: _corto(ins.masenqo([(0.0, BATI["A3"]), (0.12, D3)], 0.35, seed=3330, vel=0.85), 0.1),
    },
    "palmares": {
        "elegir_aldeano": lambda: _corto(ins.kisanji(PAL["D4"], 0.25, seed=3400, vel=0.7)),
        "elegir_tropa": lambda: _corto(ins.ngongi(True, 0.18, seed=3401, vel=0.6)),
        "elegir_edificio": lambda: _corto(ins.ngoma("grave", True, 0.35, seed=3402, vel=0.8), 0.1),
        "orden_civil": lambda: _corto(_dos(ins.marimba(PAL["E4"], 0.2, seed=3410, vel=0.7), ins.marimba(PAL["G4"], 0.3, seed=3411, vel=0.75), 0.09)),
        "orden_montado": lambda: _corto(_dos(ins.ngongi(True, 0.12, seed=3420, vel=0.7), ins.ngongi(False, 0.18, seed=3421, vel=0.7), 0.09)),
        "orden_asedio": lambda: _corto(_dos(ins.ngoma("grave", True, 0.45, seed=3430, vel=1.0), ins.marimba(PAL["G3"], 0.4, seed=3431, vel=0.6), 0.02)),
    },
    "ayutthaya": {
        "elegir_aldeano": lambda: _corto(ins.ranat(_pg(5), 0.22, seed=3500, vel=0.7)),
        "elegir_tropa": lambda: _corto(ins.ranat(_pg(9), 0.16, seed=3501, vel=0.8)),
        "elegir_edificio": lambda: _corto(ins.khong(_pg(0), 0.4, seed=3502, vel=0.6), 0.12),
        "orden_civil": lambda: _corto(_dos(ins.ranat(_pg(6), 0.12, seed=3510, vel=0.7), ins.ranat(_pg(7), 0.22, seed=3511, vel=0.75), 0.09)),
        "orden_montado": lambda: _corto(_dos(ins.ranat(_pg(9), 0.1, seed=3520, vel=0.8), ins.ranat(_pg(9), 0.16, seed=3521, vel=0.85), 0.08)),
        "orden_asedio": lambda: _corto(ins.khong(_pg(0) / 2, 0.45, seed=3530, vel=0.9), 0.12),
    },
}


def _nivel(nombre: str) -> float:
    return NIVEL["elegir"] if nombre.startswith("elegir") else NIVEL["cimiento"] if "cimiento" in nombre else NIVEL["orden"]


def main(civs: list[str]) -> None:
    filas = []
    if not civs:
        for nombre, fn in GENERICOS.items():
            dest = os.path.join(UI, f"{nombre}.ogg")
            filas.append(export(fn(), dest, _nivel(nombre)))
    for civ in civs or list(SONIDOS):
        for nombre, fn in SONIDOS[civ].items():
            dest = os.path.join(CIV, civ, f"{civ}_{nombre}.ogg")
            filas.append(export(fn(), dest, _nivel(nombre)))
    for f in filas:
        f["archivo"] = os.path.relpath(f["archivo"], RAIZ)
        f["bytes"] = os.path.getsize(os.path.join(RAIZ, f["archivo"]))
        print(f)
    with open(os.path.join(os.path.dirname(__file__), "medidas_respuesta.json"), "w", encoding="utf-8") as fh:
        json.dump(sorted(filas, key=lambda f: f["archivo"]), fh, ensure_ascii=False, indent=1)
    print("total:", sum(f["bytes"] for f in filas), "bytes en", len(filas), "archivos")


if __name__ == "__main__":
    main(sys.argv[1:])
