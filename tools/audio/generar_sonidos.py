#!/usr/bin/env python3
"""Genera los sonidos propios de cada pueblo (fanfarria de edad, alarma, entrenado, orden) y el loop de música
de Etiopía. Todo sintetizado (tools/audio/instrumentos.py): no usa ninguna grabación.

Uso:  python3 tools/audio/generar_sonidos.py [civ ...]      (sin argumentos, todos)
Sale: assets/audio/civ/<civ>/<civ>_<sonido>.ogg y assets/audio/musica/etiopia/musica_etiopia_begena_kebero_1.ogg
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


# =================== Guaraníes: mbaraka y takuapu ===================

def guaranies_fanfarria() -> np.ndarray:
    dur = 4.0
    b = silence(dur)
    golpes = []
    at, paso, i = 0.1, 0.42, 0
    while at < 2.8:
        alto = i % 2 == 1
        b = place(b, ins.takuapu(alto, seed=300 + i, vel=0.6 + 0.4 * at / 2.8), _h(at, 100 + i))
        golpes += [(at, 0.6 + 0.4 * at / 2.8), (at + paso / 2, 0.45)]
        at += paso
        paso = max(0.24, paso * 0.93)
        i += 1
    # Cierre: los dos takuapu juntos y una sacudida larga.
    b = place(b, ins.takuapu(False, 0.7, seed=330, vel=1.0), at + 0.05)
    b = place(b, ins.takuapu(True, 0.7, seed=331, vel=0.8), at + 0.06)
    golpes += [(at + 0.05, 1.0), (at + 0.16, 0.6), (at + 0.27, 0.4)]
    b = place(b, ins.mbaraka(dur, golpes, seed=340), 0.0, 0.55)
    return trim_tail(reverb(b, 0.2, 0.4, seed=7))


def guaranies_alarma() -> np.ndarray:
    dur = 2.8
    b = silence(dur)
    golpes = []
    for i in range(12):
        at = i * 0.19
        b = place(b, ins.takuapu(i % 4 in (1, 3), 0.4, seed=350 + i, vel=0.95 if i % 4 == 0 else 0.7), _h(at, 110 + i, 0.005))
    for i in range(30):
        golpes.append((i * 0.075, 0.5 + 0.4 * (i % 2)))
    b = place(b, ins.mbaraka(dur, golpes, seed=370), 0.0, 0.5)
    return trim_tail(reverb(b, 0.15, 0.3, seed=8))


def guaranies_entrenado() -> np.ndarray:
    b = silence(0.8)
    b = place(b, ins.takuapu(False, 0.5, seed=380, vel=0.9), 0.02)
    b = place(b, ins.mbaraka(0.8, [(0.0, 0.8), (0.14, 0.6)], seed=381), 0.0, 0.6)
    return trim_tail(reverb(b, 0.12, 0.25, seed=9))


def guaranies_orden() -> np.ndarray:
    return trim_tail(ins.mbaraka(0.3, [(0.0, 0.9)], seed=390))


# =================== Etiopía: kebero, masenqo y begena ===================
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
    b = silence(4.6)
    e = 0.21
    for k in range(3):
        b = _kebero_bar(b, 0.0 + k * 6 * e, e, 400 + 10 * k, 0.9)
    b = place(b, ins.kebero(True, 1.0, seed=440, vel=1.0), 18 * e)
    frase = [(0.0, BATI["D"]), (0.42, BATI["F#"]), (0.84, BATI["A"]), (1.26, BATI["D5"]), (1.9, BATI["C#"]),
             (2.15, BATI["A"]), (2.6, BATI["G"]), (2.85, BATI["F#"]), (3.15, BATI["D"])]
    b = place(b, ins.masenqo(frase, 4.1, seed=450, vel=0.9), 0.05)
    return trim_tail(reverb(b, 0.22, 0.5, seed=10))


def etiopia_alarma() -> np.ndarray:
    b = silence(3.0)
    for i in range(14):
        at = i * 0.16 - 0.0015 * i * i
        b = place(b, ins.kebero(i % 3 == 0, 0.5, seed=460 + i, vel=0.6 + 0.4 * (i % 3 == 0)), _h(at, 130 + i, 0.004))
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
    return trim_tail(ins.kebero(False, 0.3, seed=495, vel=1.0))


def etiopia_musica() -> np.ndarray:
    """Loop de paz, 16 compases de 6/8 (~35 s), en ambassel sobre re [verificar].
    Compases 1-4: begena sola; 3-14: kebero suave; 5-12: masenqo; 13-16: vuelve a la begena sola para cerrar el loop."""
    e = 0.36
    bar = 6 * e
    bars = 16
    L = bars * bar
    n = int(L * SR)
    beg = np.zeros(n + 4 * SR)
    keb = np.zeros(n + 4 * SR)
    mas = np.zeros(n + 4 * SR)
    # Begena: ostinato de dos compases, punteado lento, en el registro grave.
    osti = [[(0, "D3"), (2, "A2"), (3, "Bb2"), (5, "A2")], [(0, "D3"), (2, "A2"), (3, "G2"), (5, "Eb2")]]
    for k in range(bars):
        for j, (pos, nota) in enumerate(osti[k % 2]):
            v = 0.95 if pos == 0 else 0.7
            beg = place(beg, ins.begena(AMB[nota], 2.6, seed=500 + k * 8 + j, vel=v), _h(k * bar + pos * e, 1000 + k * 8 + j, 0.012))
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


# =================== Palmares: berimbau, caxixi y atabaque ===================
GUNGA, GUNGA_PEDRA = 118.0, 132.4  # nota abierta y con la piedra (~ un tono) [verificar]


def _toque(b: np.ndarray, t0: float, pulso: float, seed: int, vel: float = 1.0) -> np.ndarray:
    """Célula del toque de angola: chi-chi DON din (chiado, chiado, abierta, con piedra)."""
    for j, (pos, kind) in enumerate([(0, "ch"), (0.5, "ch"), (1, "don"), (2, "din")]):
        at = _h(t0 + pos * pulso, seed + j, 0.006)
        if kind == "ch":
            b = place(b, ins.berimbau(GUNGA, 0.25, seed=seed + j, vel=0.45 * vel, chiado=True), at)
        else:
            f = GUNGA if kind == "don" else GUNGA_PEDRA
            b = place(b, ins.berimbau(f, 1.0, seed=seed + j, vel=vel), at)
        b = place(b, ins.caxixi(seed=seed + 10 + j, vel=0.5 * vel), at)
    return b


def palmares_fanfarria() -> np.ndarray:
    b = silence(4.5)
    p = 0.3
    for k in range(3):
        b = _toque(b, k * 4 * p, p, 800 + 20 * k)
    patt = [(0, "grave"), (1, "aberto"), (1.5, "aberto"), (2, "tapa"), (3, "aberto")]
    for k in range(3):
        for j, (pos, g) in enumerate(patt):
            b = place(b, ins.atabaque(g, seed=860 + 10 * k + j, vel=0.75), _h((k * 4 + pos) * p, 140 + 10 * k + j))
    fin = 12 * p
    b = place(b, ins.berimbau(GUNGA, 1.4, seed=890, vel=1.0), fin)
    b = place(b, ins.atabaque("grave", 0.8, seed=891, vel=1.0), fin)
    b = place(b, ins.atabaque("aberto", 0.8, seed=892, vel=0.8), fin + 0.01)
    return trim_tail(reverb(b, 0.2, 0.45, seed=13))


def palmares_alarma() -> np.ndarray:
    b = silence(3.0)
    p = 0.2
    for k in range(3):
        b = _toque(b, k * 4 * p, p, 900 + 20 * k, 1.0)
    for i in range(16):
        g = "aberto" if i % 2 == 0 else "tapa"
        b = place(b, ins.atabaque(g, 0.4, seed=960 + i, vel=0.8 if i % 4 == 0 else 0.6), _h(i * p * 0.75, 160 + i, 0.004))
    b = place(b, ins.berimbau(GUNGA_PEDRA, 0.9, seed=990, vel=1.0, wah_rate=4.0), 12 * p)
    return trim_tail(reverb(b, 0.15, 0.3, seed=14))


def palmares_entrenado() -> np.ndarray:
    b = silence(1.0)
    b = place(b, ins.berimbau(GUNGA_PEDRA, 0.5, seed=995, vel=0.8), 0.0)
    b = place(b, ins.caxixi(seed=996, vel=0.5), 0.0)
    b = place(b, ins.berimbau(GUNGA, 0.8, seed=997, vel=1.0, wah_rate=2.4), 0.16)
    b = place(b, ins.caxixi(seed=998, vel=0.5), 0.16)
    return trim_tail(reverb(b, 0.12, 0.3, seed=15))


def palmares_orden() -> np.ndarray:
    b = silence(0.35)
    b = place(b, ins.berimbau(GUNGA, 0.3, seed=999, vel=0.7, chiado=True), 0.0)
    b = place(b, ins.caxixi(0.15, seed=1001, vel=0.9), 0.0)
    return trim_tail(b)


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
    b = silence(3.0)
    # Ranat en trémolo sobre dos notas altas que se alternan, gong grave insistente y 'chap' seco.
    for i in range(18):
        g = 9 if (i // 3) % 2 == 0 else 8
        b = place(b, ins.ranat(_pg(g), 0.3, seed=1200 + i, vel=0.55 + 0.1 * (i % 3 == 0)), _h(i * 0.1, 240 + i, 0.004))
    for i, at in enumerate([0.0, 0.6, 1.2, 1.8]):
        b = place(b, ins.khong(_pg(0), 1.2, seed=1230 + i, vel=0.85), at)
        b = place(b, ins.ching(False, seed=1240 + i, vel=0.4), at + 0.3)
    return trim_tail(reverb(b, 0.15, 0.35, seed=17))


def ayutthaya_entrenado() -> np.ndarray:
    b = silence(1.2)
    b = place(b, ins.ranat(_pg(7), 0.4, seed=1250, vel=0.8), 0.0)
    b = place(b, ins.ranat(_pg(9), 0.5, seed=1251, vel=0.8), 0.12)
    b = place(b, ins.khong(_pg(4), 1.0, seed=1252, vel=0.5), 0.12)
    return trim_tail(reverb(b, 0.14, 0.3, seed=18))


def ayutthaya_orden() -> np.ndarray:
    return trim_tail(ins.ranat(_pg(8), 0.3, seed=1260, vel=1.0))


SONIDOS["palmares"] = {"fanfarria": palmares_fanfarria, "alarma": palmares_alarma, "entrenado": palmares_entrenado, "orden": palmares_orden}
SONIDOS["ayutthaya"] = {"fanfarria": ayutthaya_fanfarria, "alarma": ayutthaya_alarma, "entrenado": ayutthaya_entrenado, "orden": ayutthaya_orden}


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
        if civ == "etiopia":
            dest = os.path.join(RAIZ, "assets", "audio", "musica", "etiopia", "musica_etiopia_begena_kebero_1.ogg")
            fila = export(etiopia_musica(), dest, NIVEL["musica"])
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
