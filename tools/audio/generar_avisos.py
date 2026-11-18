#!/usr/bin/env python3
"""Sonidos de los avisos (etapa 30, frente 4): ataque por tipo, recurso que se agota y granja vacía.

Uso:  python3 tools/audio/generar_avisos.py
Sale: assets/audio/ui/ui_alerta_{aldeanos,tropa,edificio,aliado}.ogg, ui_aviso_recurso.ogg,
      ui_aviso_granja.ogg y tools/audio/medidas_avisos.json

Sintetizados con dsp.py: golpes de madera, metal genérico y notas puras. Sin instrumentos sagrados ni
de ningún repertorio (proceso/24-tras-la-segunda-ronda/4h-sonido-con-respeto.md). Cada tipo se
distingue por el ritmo y la altura, no por el volumen: aldeanos, dos notas que bajan; tropa, tres
golpes secos rápidos; edificio, un golpe grave con eco; aliado, dos notas iguales más lejanas.
"""
from __future__ import annotations

import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from dsp import additive, bandpass, expdecay, export, fade, modal, noise, place, reverb, silence, trim_tail  # noqa: E402

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
UI = os.path.join(RAIZ, "assets", "audio", "ui")
SR = 44100
NIVEL = {"alerta": -16.0, "aviso": -20.0}


def _nota(f: float, dur: float, seed: int, vel: float = 1.0) -> np.ndarray:
    """Nota de campanita genérica: pocos armónicos con caída exponencial."""
    x = additive(f, [1.0, 0.35, 0.12, 0.05], dur, seed)
    return x * expdecay(len(x), dur * 0.35) * vel


def _toc(f: float, dur: float, seed: int, vel: float = 1.0) -> np.ndarray:
    x = modal(dur, [(f, 1.0, 0.05), (f * 2.7, 0.4, 0.025), (f * 5.1, 0.15, 0.012)], seed)
    clic = bandpass(noise(dur, seed + 1), 1500, 6000, 2) * expdecay(len(x), 0.004) * 0.3
    return (x + clic) * vel


def _fin(x: np.ndarray, wet: float = 0.12, seed: int = 7) -> np.ndarray:
    return trim_tail(fade(reverb(x, wet, 0.25, seed=seed), 0.002, 0.08))


def ui_alerta_aldeanos() -> np.ndarray:
    b = silence(0.8)
    b = place(b, _nota(880, 0.35, 40), 0.0)
    b = place(b, _nota(660, 0.45, 41), 0.16)
    return _fin(b, seed=42)


def ui_alerta_tropa() -> np.ndarray:
    b = silence(0.7)
    for i in range(3):
        b = place(b, _toc(420 + 30 * i, 0.14, 50 + i, 0.9), 0.09 * i)
    return _fin(b, 0.08, 53)


def ui_alerta_edificio() -> np.ndarray:
    b = silence(1.2)
    b = place(b, _toc(110, 0.6, 60, 1.0), 0.0)
    b = place(b, _toc(110, 0.5, 61, 0.45), 0.32)
    return _fin(b, 0.25, 62)


def ui_alerta_aliado() -> np.ndarray:
    b = silence(0.9)
    b = place(b, _nota(587, 0.3, 70, 0.7), 0.0)
    b = place(b, _nota(587, 0.4, 71, 0.6), 0.22)
    return _fin(b, 0.35, 72)


def ui_aviso_recurso() -> np.ndarray:
    b = silence(0.6)
    b = place(b, _toc(300, 0.2, 80, 0.8), 0.0)
    b = place(b, _toc(240, 0.25, 81, 0.6), 0.12)
    return _fin(b, 0.1, 82)


def ui_aviso_granja() -> np.ndarray:
    b = silence(0.6)
    b = place(b, _nota(523, 0.25, 90, 0.6), 0.0)
    b = place(b, _nota(659, 0.3, 91, 0.6), 0.12)
    return _fin(b, 0.1, 92)


SONIDOS = {"ui_alerta_aldeanos": ui_alerta_aldeanos, "ui_alerta_tropa": ui_alerta_tropa,
           "ui_alerta_edificio": ui_alerta_edificio, "ui_alerta_aliado": ui_alerta_aliado,
           "ui_aviso_recurso": ui_aviso_recurso, "ui_aviso_granja": ui_aviso_granja}


def main() -> None:
    filas = []
    for nombre, fn in SONIDOS.items():
        nivel = NIVEL["alerta"] if "alerta" in nombre else NIVEL["aviso"]
        filas.append(export(fn(), os.path.join(UI, f"{nombre}.ogg"), nivel))
    for f in filas:
        f["archivo"] = os.path.relpath(f["archivo"], RAIZ)
        f["bytes"] = os.path.getsize(os.path.join(RAIZ, f["archivo"]))
        print(f)
    with open(os.path.join(os.path.dirname(__file__), "medidas_avisos.json"), "w", encoding="utf-8") as fh:
        json.dump(sorted(filas, key=lambda f: f["archivo"]), fh, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
