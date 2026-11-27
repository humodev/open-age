#!/usr/bin/env python3
"""Genera los sonidos propios de cada pueblo (fanfarria de edad, alarma, entrenado, orden) y el loop de música
de Etiopía. Todo sintetizado (tools/audio/instrumentos.py): no usa ninguna grabación.

Uso:  python3 tools/audio/generar_sonidos.py [civ ...]      (sin argumentos, todos)
Sale: assets/audio/civ/<civ>/<civ>_<sonido>.ogg y los loops de paz sintetizados (MUSICA: Etiopía, Palmares y
      Ayutthaya, en assets/audio/musica/<carpeta>/)
      tools/audio/medidas.json (sonoridad y pico de cada archivo)

Requiere numpy y ffmpeg con libvorbis. Es determinista: misma semilla, mismo archivo.
"""
from __future__ import annotations

import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import instrumentos as ins  # noqa: E402
from dsp import SR, export, fade, pan, place, reverb, rng, save_meta, silence, trim_tail  # noqa: E402

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SALIDA = os.path.join(RAIZ, "assets", "audio", "civ")

# Sonoridad de cada clase de sonido (LUFS integrados). Los de la interfaz actual andan entre -17 y -13
# y el juego los baja otra vez con el volumen de cada llamada (src/game/audio.gd).
NIVEL = {"fanfarria": -16.0, "alarma": -16.0, "entrenado": -18.0, "orden": -20.0, "musica": -16.0}


def _h(at: float, seed: int, spread: float = 0.008) -> float:
    """Humaniza el momento de un golpe (±8 ms)."""
    return max(0.0, at + rng(seed).uniform(-spread, spread))


# =================== Tawantinsuyu: quena, siku y wankara ===================
# Pentatónica sin semitonos (mi menor: mi sol la si re) [verificar: d'Harcourt 1925; ver 4g-sonido.md].
E4, G4, A4, B4, D5, E5, G5, A5, B5, D6 = 329.6, 392.0, 440.0, 493.9, 587.3, 659.3, 784.0, 880.0, 987.8, 1174.7


def tawantinsuyu_fanfarria() -> np.ndarray:
    b = silence(4.0)
    # Tropa de sikus: ira y arka se reparten las notas (hoquetus), en octavas paralelas.
    notas = [E4, G4, A4, B4, A4, B4]
    for i, f in enumerate(notas):
        at = 0.25 + i * 0.22
        b = place(b, ins.siku(f, 0.34, seed=10 + i, vel=0.8), _h(at, i))
        b = place(b, ins.siku(f * 2, 0.32, seed=20 + i, vel=0.35), _h(at, 50 + i))
    # La quena canta sobre la tropa y cierra en la tónica, con una apoyatura.
    b = place(b, ins.quena(D5, 0.16, seed=31, vel=0.8), 1.62)
    b = place(b, ins.quena(E5, 1.5, seed=32, vel=0.95), 1.76)
    b = place(b, ins.siku(E4, 1.4, seed=33, vel=0.7), 1.78)
    b = place(b, ins.siku(B4, 1.4, seed=34, vel=0.45), 1.80)
    for i, at in enumerate([0.25, 0.69, 1.13, 1.76, 2.0]):
        b = place(b, ins.wankara(seed=40 + i, vel=0.9 if i in (0, 3) else 0.55), _h(at, 60 + i))
    return trim_tail(reverb(b, 0.22, 0.45, seed=1))


def tawantinsuyu_alarma() -> np.ndarray:
    b = silence(3.0)
    figura = [B5, A5, G5, E5]
    for rep in range(2):
        for i, f in enumerate(figura):
            at = 0.05 + rep * 0.95 + i * 0.13
            b = place(b, ins.quena(f, 0.2 if i < 3 else 0.45, seed=100 + rep * 10 + i, vel=0.85), at)
    for i, at in enumerate([0.05, 0.2, 1.0, 1.15, 1.9, 2.05]):
        b = place(b, ins.wankara(0.7, seed=120 + i, vel=0.85 if i % 2 == 0 else 0.6), _h(at, 70 + i))
    b = place(b, ins.siku(E4, 1.0, seed=130, vel=0.6), 1.9)
    return trim_tail(reverb(b, 0.18, 0.35, seed=2))


def tawantinsuyu_entrenado() -> np.ndarray:
    b = silence(0.9)
    b = place(b, ins.siku(A4, 0.2, seed=140, vel=0.8), 0.0)
    b = place(b, ins.siku(E5, 0.45, seed=141, vel=0.85), 0.16)
    return trim_tail(reverb(b, 0.15, 0.3, seed=3))


def tawantinsuyu_orden() -> np.ndarray:
    return trim_tail(fade(ins.quena(B5, 0.22, seed=150, vel=0.9), 0.0, 0.06))


# =================== Mapuches: kultrun y trutruka ===================
# C-53 a: vuelve el kultrun (partituras de 4g, commit 456a59b). Consultarlo con una organización mapuche antes de publicar.
TRU_F0 = 58.0  # fundamental de una trutruka de ~3 m [verificar]: se tocan los armónicos 3 a 6.


def mapuches_fanfarria() -> np.ndarray:
    b = silence(4.5)
    for i in range(10):
        at = 0.0 + i * 0.4
        b = place(b, ins.kultrun(seed=200 + i, vel=0.9 if i % 2 == 0 else 0.7), _h(at, 80 + i))
    llamado = [(0.3, 4, 0.9), (1.3, 5, 0.35), (1.7, 6, 1.1), (2.9, 5, 0.4), (3.3, 4, 1.0)]
    for i, (at, h, d) in enumerate(llamado):
        b = place(b, ins.trutruka(TRU_F0, h, d, seed=210 + i, vel=0.85), at)
    return trim_tail(reverb(b, 0.2, 0.5, seed=4))


def mapuches_alarma() -> np.ndarray:
    b = silence(3.0)
    n = 18
    for i in range(n):
        at = i * 0.12
        b = place(b, ins.kultrun(0.4, seed=230 + i, vel=0.45 + 0.5 * i / n, centro=i % 2 == 0), _h(at, 90 + i, 0.005))
    for i, (at, h, d) in enumerate([(0.0, 6, 0.32), (0.4, 6, 0.32), (0.8, 5, 0.6), (1.5, 6, 0.32), (1.9, 6, 0.7)]):
        b = place(b, ins.trutruka(TRU_F0, h, d, seed=250 + i, vel=0.9), at)
    return trim_tail(reverb(b, 0.16, 0.35, seed=5))


def mapuches_entrenado() -> np.ndarray:
    b = silence(1.0)
    b = place(b, ins.kultrun(0.5, seed=260, vel=0.7, centro=False), 0.0)
    b = place(b, ins.kultrun(0.6, seed=261, vel=0.95), 0.15)
    b = place(b, ins.trutruka(TRU_F0, 4, 0.42, seed=262, vel=0.7), 0.15)
    return trim_tail(reverb(b, 0.15, 0.3, seed=6))


def mapuches_orden() -> np.ndarray:
    return trim_tail(ins.kultrun(0.35, seed=270, vel=1.0))


# =================== Guaraníes: mimby y angu'apu ===================
# Sin mbaraka ni takuapu, instrumentos del opy: ver 4h-sonido-con-respeto.md.
# Escala de cuatro notas sobre la, sin semitonos [verificar: no hay una escala guaraní documentada para el siglo XVII].
MIM = {"A5": 880.0, "C6": 1046.5, "D6": 1174.7, "E6": 1318.5, "G5": 784.0, "E5": 659.3}


def guaranies_fanfarria() -> np.ndarray:
    b = silence(4.0)
    at, paso, i = 0.1, 0.42, 0
    while at < 2.8:
        b = place(b, ins.angu_apu(i % 2 == 0, seed=300 + i, vel=0.6 + 0.4 * at / 2.8), _h(at, 100 + i))
        at += paso
        paso = max(0.24, paso * 0.93)
        i += 1
    # El mimby: un llamado que sube por la escala, con adornos cortos, y cierra arriba.
    frase = [(0.5, "E5", 0.3), (0.85, "A5", 0.3), (1.2, "C6", 0.2), (1.4, "A5", 0.25), (1.8, "C6", 0.2),
             (2.0, "D6", 0.2), (2.2, "E6", 0.5), (at - 0.1, "D6", 0.08), (at + 0.0, "E6", 1.0)]
    for j, (t0, nota, d) in enumerate(frase):
        b = place(b, ins.mimby(MIM[nota], d, seed=310 + j, vel=0.75), _h(t0, 120 + j, 0.006))
    b = place(b, ins.angu_apu(True, 0.8, seed=330, vel=1.0), at + 0.05)
    return trim_tail(reverb(b, 0.2, 0.4, seed=7))


def guaranies_alarma() -> np.ndarray:
    b = silence(2.8)
    for i in range(12):
        at = i * 0.19
        b = place(b, ins.angu_apu(i % 4 in (0, 2), 0.4, seed=350 + i, vel=0.95 if i % 4 == 0 else 0.7), _h(at, 110 + i, 0.005))
    # Llamado agudo e insistente, dos veces: mi mi do la.
    for rep in range(2):
        for j, (pos, nota, d) in enumerate([(0.0, "E6", 0.12), (0.16, "E6", 0.12), (0.32, "C6", 0.12), (0.48, "A5", 0.35)]):
            b = place(b, ins.mimby(MIM[nota], d, seed=370 + rep * 10 + j, vel=0.85), 0.05 + rep * 1.15 + pos)
    return trim_tail(reverb(b, 0.15, 0.3, seed=8))


def guaranies_entrenado() -> np.ndarray:
    b = silence(0.8)
    b = place(b, ins.angu_apu(True, 0.5, seed=380, vel=0.9), 0.02)
    b = place(b, ins.mimby(MIM["A5"], 0.12, seed=381, vel=0.6), 0.02)
    b = place(b, ins.mimby(MIM["E6"], 0.3, seed=382, vel=0.6), 0.16)
    return trim_tail(reverb(b, 0.12, 0.25, seed=9))


def guaranies_orden() -> np.ndarray:
    return trim_tail(ins.angu_apu(False, 0.3, seed=390, vel=1.0))


# =================== Etiopía: kebero, masenqo y krar ===================
# Sin begena (C-54 b, opción prudente): ver 4h-sonido-con-respeto.md.
# Modos (qenet) en re [verificar]: bati mayor (re fa# sol la do#) y ambassel (re mib sol la sib).
D3, D4 = 146.83, 293.66
BATI = {"D": D4, "F#": 369.99, "G": 392.0, "A": 440.0, "C#": 554.37, "D5": 587.33, "A3": 220.0}
AMB = {"A2": 110.0, "Bb2": 116.54, "D3": 146.83, "Eb3": 155.56, "G3": 196.0, "A3": 220.0, "Bb3": 233.08,
       "D4": 293.66, "Eb4": 311.13, "G4": 392.0, "A4": 440.0, "Bb4": 466.16, "D2": 73.42, "Eb2": 77.78, "G2": 98.0}


def _kebero_bar(b: np.ndarray, t0: float, eighth: float, seed: int, vel: float = 1.0) -> np.ndarray:
    """Un compás de 6/8: DUM . ta DUM ta . (grande en 1 y 4, chico en 3 y 5) [verificar]."""
    for j, (pos, grande, v) in enumerate([(0, True, 1.0), (2, False, 0.6), (3, True, 0.8), (4, False, 0.55)]):
        b = place(b, ins.kebero(grande, seed=seed + j, vel=v * vel), _h(t0 + pos * eighth, seed + 7 * j))
    return b


def etiopia_fanfarria() -> np.ndarray:
    # C-73 a: el nagarit (timbal real de guerra) en lugar del kebero, que es también tambor de la liturgia.
    # Golpes lentos y pesados, como el anuncio del rey: uno por compás y dos al final.
    b = silence(5.0)
    e = 0.21
    for k in range(3):
        b = place(b, ins.nagarit(1.4, seed=400 + 10 * k, vel=0.85), _h(k * 6 * e, 400 + k))
        b = place(b, ins.nagarit(1.0, seed=405 + 10 * k, vel=0.5), _h(k * 6 * e + 3 * e, 410 + k))
    b = place(b, ins.nagarit(1.8, seed=440, vel=1.0), 18 * e)
    b = place(b, ins.nagarit(1.8, seed=441, vel=0.8), 18 * e + 2 * e)
    frase = [(0.0, BATI["D"]), (0.42, BATI["F#"]), (0.84, BATI["A"]), (1.26, BATI["D5"]), (1.9, BATI["C#"]),
             (2.15, BATI["A"]), (2.6, BATI["G"]), (2.85, BATI["F#"]), (3.15, BATI["D"])]
    b = place(b, ins.masenqo(frase, 4.1, seed=450, vel=0.9), 0.05)
    # Krar: un punteo en el primer tiempo de cada compás (re, la, re) y el acorde final (la re re).
    for k, nota in enumerate(["D", "A3", "D"]):
        b = place(b, ins.krar(BATI[nota], 1.4, seed=455 + k, vel=0.55), _h(k * 6 * e, 300 + k))
    for j, nota in enumerate(["A3", "D", "D5"]):
        b = place(b, ins.krar(BATI[nota], 1.8, seed=460 + j, vel=0.6), 18 * e + 0.03 * j)
    return trim_tail(reverb(b, 0.22, 0.5, seed=10))


def etiopia_alarma() -> np.ndarray:
    # C-73 a: el nagarit que llama a la guerra, cada vez más rápido, en lugar del kebero.
    b = silence(3.2)
    for i in range(9):
        at = i * 0.27 - 0.006 * i * i
        b = place(b, ins.nagarit(0.9, seed=460 + i, vel=0.7 + 0.3 * (i % 3 == 0)), _h(at, 130 + i, 0.004))
    frase = [(0.0, AMB["A4"]), (0.2, AMB["Bb4"]), (0.4, AMB["A4"]), (0.6, AMB["G4"]), (0.8, AMB["A4"]),
             (1.15, AMB["A4"]), (1.35, AMB["Bb4"]), (1.55, AMB["A4"]), (1.75, AMB["Eb4"]), (1.95, AMB["D4"])]
    b = place(b, ins.masenqo(frase, 2.6, seed=480, vel=0.9), 0.0)
    return trim_tail(reverb(b, 0.16, 0.35, seed=11))


def etiopia_entrenado() -> np.ndarray:
    b = silence(0.9)
    b = place(b, ins.kebero(False, 0.4, seed=490, vel=0.7), 0.0)
    b = place(b, ins.kebero(False, 0.4, seed=491, vel=0.6), 0.11)
    b = place(b, ins.kebero(True, 0.7, seed=492, vel=1.0), 0.22)
    return trim_tail(reverb(b, 0.14, 0.3, seed=12))


def etiopia_orden() -> np.ndarray:
    # Un punteo de krar: el kebero también es tambor de la liturgia y no se repite en cada clic.
    return trim_tail(fade(ins.krar(BATI["A"], 0.4, seed=495, vel=1.0), 0.0, 0.08))


def etiopia_musica() -> np.ndarray:
    """Loop de paz, 16 compases de 6/8 (~35 s), en ambassel sobre re [verificar].
    Compases 1-4: krar solo; 3-14: kebero suave; 5-12: masenqo; 13-16: vuelve el krar solo para cerrar el loop."""
    e = 0.36
    bar = 6 * e
    bars = 16
    L = bars * bar
    n = int(L * SR)
    beg = np.zeros(n + 4 * SR)
    keb = np.zeros(n + 4 * SR)
    mas = np.zeros(n + 4 * SR)
    # Krar: el mismo ostinato de dos compases que tenía la begena, una octava arriba (el registro del krar).
    osti = [[(0, "D4"), (2, "A3"), (3, "Bb3"), (5, "A3")], [(0, "D4"), (2, "A3"), (3, "G3"), (5, "Eb3")]]
    for k in range(bars):
        for j, (pos, nota) in enumerate(osti[k % 2]):
            v = 0.95 if pos == 0 else 0.7
            beg = place(beg, ins.krar(AMB[nota], 2.0, seed=500 + k * 8 + j, vel=v), _h(k * bar + pos * e, 1000 + k * 8 + j, 0.012))
    # Kebero: entra suave en el compás 3, se calla en el 15.
    for k in range(2, 14):
        v = 0.45 if k in (2, 13) else 0.65
        keb = _kebero_bar(keb, k * bar, e, 600 + 10 * k, v)
    # Masenqo: una frase de ocho compases, notas largas que se deslizan.
    mel = [
        (4, 0, "A4", 1.0), (4, 3, "G4", 1.0),
        (5, 0, "A4", 0.5), (5, 2, "Bb4", 0.5), (5, 3, "A4", 0.5), (5, 4, "G4", 1.0),
        (6, 0, "Eb4", 2.0), (6, 4, "D4", 0.5),
        (7, 0, "D4", 4.0),
        (8, 0, "G4", 0.5), (8, 2, "A4", 0.5), (8, 3, "Bb4", 1.0),
        (9, 0, "A4", 0.5), (9, 2, "G4", 0.5), (9, 3, "Eb4", 1.0),
        (10, 0, "D4", 0.5), (10, 2, "Eb4", 0.5), (10, 3, "G4", 1.0),
        (11, 0, "D4", 4.0),
    ]
    # Dos arcadas (compases 5-8 y 9-12), cada una con su glissando interno.
    for start, end, seed in ((4, 8, 700), (8, 12, 710)):
        frase = [((k - start) * bar + p * e, AMB[nota]) for k, p, nota, _ in mel if start <= k < end]
        dur = (end - start) * bar + 0.2
        mas = place(mas, ins.masenqo(frase, dur, seed=seed, vel=0.75), start * bar)
    st = 0.62 * pan(reverb(beg, 0.25, 0.6, seed=20), -0.3) + 0.5 * pan(reverb(keb, 0.2, 0.5, seed=21), 0.05) \
        + 0.45 * pan(reverb(mas, 0.3, 0.7, seed=22), 0.28)
    # Envuelve la cola sobre el principio: el loop empalma sin corte.
    out = st[:n].copy()
    tail = st[n:]
    out[: len(tail)] += tail
    return out


SONIDOS = {
    "tawantinsuyu": {"fanfarria": tawantinsuyu_fanfarria, "alarma": tawantinsuyu_alarma, "entrenado": tawantinsuyu_entrenado, "orden": tawantinsuyu_orden},
    "mapuches": {"fanfarria": mapuches_fanfarria, "alarma": mapuches_alarma, "entrenado": mapuches_entrenado, "orden": mapuches_orden},
    "guaranies": {"fanfarria": guaranies_fanfarria, "alarma": guaranies_alarma, "entrenado": guaranies_entrenado, "orden": guaranies_orden},
    "etiopia": {"fanfarria": etiopia_fanfarria, "alarma": etiopia_alarma, "entrenado": etiopia_entrenado, "orden": etiopia_orden},
    "palmares": {},  # se completan abajo
    "ayutthaya": {},
}


# =================== Palmares: ngoma, ngongi, marimba y kisanji ===================
# Raíz angoleña, sin berimbau ni toques de capoeira (C-55 b, opción prudente): ver 4h-sonido-con-respeto.md.
# Marimba y kisanji en una escala de cinco notas sobre sol [verificar: las afinaciones angoleñas no son temperadas].
PAL = {"G3": 196.0, "A3": 220.0, "C4": 261.6, "D4": 293.7, "E4": 329.6, "G4": 392.0, "A4": 440.0, "C5": 523.3}
# Línea de tiempo de la campana en 12/8 (x . x . x x . x . x . x) [verificar: común a África central y occidental].
CAMPANA = [0, 2, 4, 5, 7, 9, 11]


def _campana(b: np.ndarray, t0: float, e: float, seed: int, vel: float = 1.0) -> np.ndarray:
    for j, pos in enumerate(CAMPANA):
        b = place(b, ins.ngongi(pos in (0, 7), 0.4, seed=seed + j, vel=vel * (0.8 if pos == 0 else 0.55)), _h(t0 + pos * e, seed + j, 0.005))
    return b


def palmares_fanfarria() -> np.ndarray:
    b = silence(4.6)
    e = 0.13  # corchea de 12/8: un ciclo de 1,56 s
    for k in range(2):
        b = _campana(b, k * 12 * e, e, 800 + 20 * k, 0.6)
        for j, (pos, g, grande) in enumerate([(0, "grave", True), (3, "abierto", False), (6, "abierto", True),
                                              (8, "seco", False), (9, "abierto", False)]):
            b = place(b, ins.ngoma(g, grande, seed=840 + 10 * k + j, vel=0.8), _h((k * 12 + pos) * e, 140 + 10 * k + j))
    # Marimba: una frase que sube en el segundo ciclo y cierra en la tónica.
    mel = [(12, "G3"), (14, "A3"), (16, "C4"), (17, "D4"), (19, "E4"), (21, "D4"), (23, "G4")]
    for j, (pos, nota) in enumerate(mel):
        b = place(b, ins.marimba(PAL[nota], 0.8, seed=870 + j, vel=0.7), _h(pos * e, 180 + j, 0.005))
    fin = 24 * e
    b = place(b, ins.ngoma("grave", True, 0.9, seed=890, vel=1.0), fin)
    b = place(b, ins.ngoma("abierto", False, 0.8, seed=891, vel=0.8), fin + 0.01)
    b = place(b, ins.marimba(PAL["G3"], 1.2, seed=892, vel=0.8), fin)
    b = place(b, ins.marimba(PAL["G4"], 1.2, seed=893, vel=0.6), fin + 0.015)
    b = place(b, ins.ngongi(False, 0.6, seed=894, vel=0.7), fin)
    return trim_tail(reverb(b, 0.2, 0.45, seed=13))


def palmares_alarma() -> np.ndarray:
    b = silence(3.0)
    # La campana en dos notas que se alternan, rápida e insistente, sobre la ngoma.
    for i in range(16):
        b = place(b, ins.ngongi(i % 2 == 0, 0.3, seed=900 + i, vel=0.85 if i % 4 == 0 else 0.6), _h(i * 0.15, 150 + i, 0.004))
    for i in range(16):
        g = "abierto" if i % 2 == 0 else "seco"
        b = place(b, ins.ngoma(g, i % 4 != 2, 0.4, seed=930 + i, vel=0.8 if i % 4 == 0 else 0.6), _h(i * 0.15, 170 + i, 0.004))
    b = place(b, ins.ngoma("grave", True, 0.9, seed=960, vel=1.0), 2.4)
    b = place(b, ins.ngoma("grave", True, 0.9, seed=961, vel=0.9), 2.55)
    return trim_tail(reverb(b, 0.15, 0.3, seed=14))


def palmares_entrenado() -> np.ndarray:
    b = silence(1.0)
    b = place(b, ins.kisanji(PAL["D4"], 0.6, seed=995, vel=0.8), 0.0)
    b = place(b, ins.kisanji(PAL["G4"], 0.9, seed=996, vel=0.9), 0.14)
    b = place(b, ins.ngoma("abierto", False, 0.5, seed=997, vel=0.7), 0.14)
    return trim_tail(reverb(b, 0.12, 0.3, seed=15))


def palmares_orden() -> np.ndarray:
    return trim_tail(fade(ins.kisanji(PAL["A4"], 0.35, seed=999, vel=1.0), 0.0, 0.08))


# =================== Ayutthaya: khong wong, ranat ek y ching ===================
# Afinación tailandesa de siete pasos iguales por octava (~171 cents) [verificar: Morton 1976].
THAI_BASE = 261.0


def thai(grado: int) -> float:
    return THAI_BASE * 2.0 ** (grado / 7.0)


PENTA = [0, 1, 2, 4, 5]  # subconjunto pentatónico de los siete grados [verificar]


def _pg(i: int) -> float:
    """Grado i de la pentatónica, con octavas."""
    o, k = divmod(i, 5)
    return thai(PENTA[k] + 7 * o)


def ayutthaya_fanfarria() -> np.ndarray:
    b = silence(4.6)
    # Khong wong: corrida ascendente por el círculo de gongs.
    for i, g in enumerate([0, 1, 2, 3, 4, 5]):
        b = place(b, ins.khong(_pg(g), 1.8, seed=1100 + i, vel=0.7), _h(0.1 + i * 0.16, 200 + i))
    # Ranat ek: la melodía una octava arriba, en notas repetidas (como se toca).
    mel = [5, 6, 7, 6, 7, 8, 9, 8, 7]
    for i, g in enumerate(mel):
        at = 1.1 + i * 0.14
        b = place(b, ins.ranat(_pg(g), 0.45, seed=1120 + i, vel=0.6), _h(at, 220 + i, 0.005))
    fin = 1.1 + len(mel) * 0.14 + 0.05
    b = place(b, ins.khong(_pg(0), 2.4, seed=1150, vel=0.9), fin)
    b = place(b, ins.khong(_pg(5), 2.4, seed=1151, vel=0.6), fin + 0.012)
    b = place(b, ins.ranat(_pg(10), 0.6, seed=1152, vel=0.6), fin)
    for i, at in enumerate([1.1, 1.66, 2.22, fin]):
        b = place(b, ins.ching(i % 2 == 0 or at == fin, seed=1160 + i, vel=0.35), at)
    return trim_tail(reverb(b, 0.2, 0.55, seed=16))


def ayutthaya_alarma() -> np.ndarray:
    # C-73 a: el conjunto de la procesión y de la guerra (klong chana, pi chawa y sang) en lugar del piphat de corte.
    # La caracola abre, el tambor de barril marca rápido y el oboe repite una llamada de dos notas [verificar: Morton 1976].
    b = silence(3.4)
    b = place(b, ins.sang(thai(-7), 1.1, seed=1200, vel=0.8), 0.0)
    for i in range(16):
        at = 0.5 + i * 0.15
        b = place(b, ins.klong_chana(i % 4 == 0, 0.5, seed=1210 + i, vel=0.85 if i % 4 == 0 else 0.6), _h(at, 240 + i, 0.004))
    llamada = [(0.0, _pg(7)), (0.22, _pg(8)), (0.44, _pg(7)), (0.66, _pg(8)), (0.88, _pg(9)), (1.3, _pg(8)), (1.52, _pg(7))]
    b = place(b, ins.pi_chawa(llamada, 2.0, seed=1230, vel=0.7), 0.55)
    for i, at in enumerate([0.5, 1.1, 1.7, 2.3]):
        b = place(b, ins.ching(False, seed=1240 + i, vel=0.35), at)
    return trim_tail(reverb(b, 0.15, 0.35, seed=17))


def ayutthaya_entrenado() -> np.ndarray:
    b = silence(1.2)
    b = place(b, ins.ranat(_pg(7), 0.4, seed=1250, vel=0.8), 0.0)
    b = place(b, ins.ranat(_pg(9), 0.5, seed=1251, vel=0.8), 0.12)
    b = place(b, ins.khong(_pg(4), 1.0, seed=1252, vel=0.5), 0.12)
    return trim_tail(reverb(b, 0.14, 0.3, seed=18))


def ayutthaya_orden() -> np.ndarray:
    return trim_tail(ins.ranat(_pg(8), 0.3, seed=1260, vel=1.0))


def _suma(capas: list[np.ndarray]) -> np.ndarray:
    """Suma capas estéreo de largo distinto (las colas de reverberación no miden lo mismo)."""
    n = max(len(c) for c in capas)
    out = np.zeros((n, 2))
    for c in capas:
        out[: len(c)] += c
    return out


def palmares_musica() -> np.ndarray:
    """C-73 a: loop de paz de Palmares, 12 ciclos de 12/8 (~28 s): campana (ngongi), ngoma y marimba, sin berimbau
    ni toques de capoeira. Ciclos 1-2: campana y ngoma; 3-10: la marimba; 11-12: vuelve la base para empalmar."""
    e = 0.19
    cyc = 12 * e
    cycles = 12
    L = cycles * cyc
    n = int(L * SR)
    cam = np.zeros(n + 4 * SR)
    ngo = np.zeros(n + 4 * SR)
    mar = np.zeros(n + 4 * SR)
    for k in range(cycles):
        cam = _campana(cam, k * cyc, e, 2000 + 10 * k, 0.45)
        for j, (pos, g, grande) in enumerate([(0, "grave", True), (3, "abierto", False), (6, "abierto", True),
                                              (8, "seco", False), (9, "abierto", False)]):
            ngo = place(ngo, ins.ngoma(g, grande, seed=2200 + 10 * k + j, vel=0.6), _h(k * cyc + pos * e, 2300 + 10 * k + j, 0.006))
    frases = [["G3", "A3", "C4", "D4", "C4", "A3"], ["D4", "E4", "G4", "E4", "D4", "C4"],
              ["C4", "D4", "E4", "D4", "C4", "A3"], ["A3", "C4", "D4", "C4", "A3", "G3"]]
    for k in range(2, 10):
        fr = frases[(k - 2) % 4]
        for j, nota in enumerate(fr):
            mar = place(mar, ins.marimba(PAL[nota], 0.9, seed=2500 + 8 * k + j, vel=0.6 if j % 2 else 0.75), _h(k * cyc + 2 * j * e, 2600 + 8 * k + j, 0.008))
        mar = place(mar, ins.marimba(PAL[fr[0]], 1.2, seed=2590 + k, vel=0.4), _h(k * cyc + 11 * e, 2690 + k, 0.008))
    st = _suma([0.5 * pan(reverb(cam, 0.15, 0.4, seed=30), 0.25), 0.7 * pan(reverb(ngo, 0.18, 0.45, seed=31), -0.1),
                0.55 * pan(reverb(mar, 0.25, 0.6, seed=32), -0.25)])
    out = st[:n].copy()
    tail = st[n:]
    out[: len(tail)] += tail
    return out


def ayutthaya_musica() -> np.ndarray:
    """C-73 a: loop de paz de Ayutthaya (~30 s), en reemplazo de Tra Nimit (C-59): khong wong con la melodía lenta,
    ranat ek que la adorna en notas repetidas y ching que marca el ciclo (abierto, cerrado). Sin pi ni sang: eso queda
    para la alarma."""
    beat = 0.5
    bars = 16
    L = bars * 4 * beat
    n = int(L * SR)
    kh = np.zeros(n + 4 * SR)
    ra = np.zeros(n + 4 * SR)
    ch = np.zeros(n + 4 * SR)
    # Melodía nuclear (luk tok) de 8 compases, una nota por tiempo fuerte, que se repite dos veces.
    nucleo = [0, 2, 1, 4, 3, 2, 4, 5, 5, 4, 2, 3, 1, 2, 0, 0]
    for k in range(bars):
        g = nucleo[k % len(nucleo)]
        kh = place(kh, ins.khong(_pg(g), 2.0, seed=3000 + k, vel=0.7), _h(k * 4 * beat, 3100 + k, 0.01))
        kh = place(kh, ins.khong(_pg(g + 2), 1.6, seed=3050 + k, vel=0.45), _h(k * 4 * beat + 2 * beat, 3150 + k, 0.01))
        if 2 <= k < 14:
            for j in range(8):
                gg = g + 5 + (0, 1, 2, 1, 0, 1, 2, 3)[j]
                ra = place(ra, ins.ranat(_pg(gg), 0.4, seed=3200 + 8 * k + j, vel=0.45 if j % 2 else 0.55), _h(k * 4 * beat + j * beat / 2, 3300 + 8 * k + j, 0.006))
        for j in range(4):
            ch = place(ch, ins.ching(j % 2 == 1, seed=3500 + 4 * k + j, vel=0.22), k * 4 * beat + j * beat)
    st = _suma([0.65 * pan(reverb(kh, 0.25, 0.7, seed=33), -0.2), 0.5 * pan(reverb(ra, 0.2, 0.5, seed=34), 0.25),
                0.4 * pan(reverb(ch, 0.15, 0.4, seed=35), 0.05)])
    out = st[:n].copy()
    tail = st[n:]
    out[: len(tail)] += tail
    return out


SONIDOS["palmares"] = {"fanfarria": palmares_fanfarria, "alarma": palmares_alarma, "entrenado": palmares_entrenado, "orden": palmares_orden}
SONIDOS["ayutthaya"] = {"fanfarria": ayutthaya_fanfarria, "alarma": ayutthaya_alarma, "entrenado": ayutthaya_entrenado, "orden": ayutthaya_orden}


# Loops de paz sintetizados: carpeta, archivo y función.
MUSICA = {
    "etiopia": ("etiopia", "musica_etiopia_krar_kebero_1.ogg", etiopia_musica),
    "palmares": ("palmares", "musica_palmares_ngoma_marimba_1.ogg", palmares_musica),
    "ayutthaya": ("ayutthaya", "musica_ayutthaya_khong_ranat_1.ogg", ayutthaya_musica),
}


def main(civs: list[str]) -> None:
    filas = []
    for civ in civs:
        for nombre, fn in SONIDOS[civ].items():
            x = fn()
            dest = os.path.join(SALIDA, civ, f"{civ}_{nombre}.ogg")
            fila = export(x, dest, NIVEL[nombre])
            fila["archivo"] = os.path.relpath(dest, RAIZ)
            filas.append(fila)
            print(fila)
        if civ in MUSICA:
            carpeta, archivo, fn = MUSICA[civ]
            dest = os.path.join(RAIZ, "assets", "audio", "musica", carpeta, archivo)
            fila = export(fn(), dest, NIVEL["musica"])
            fila["archivo"] = os.path.relpath(dest, RAIZ)
            filas.append(fila)
            print(fila)
    medidas = os.path.join(os.path.dirname(__file__), "medidas.json")
    previas = []
    if os.path.exists(medidas) and len(civs) < len(SONIDOS):
        import json
        previas = [f for f in json.load(open(medidas, encoding="utf-8")) if not any(f["archivo"].find(f"/{c}/") >= 0 or f["archivo"].find(f"/{c}_") >= 0 for c in civs)]
    save_meta(medidas, sorted(previas + filas, key=lambda f: f["archivo"]))


if __name__ == "__main__":
    main(sys.argv[1:] or list(SONIDOS))
