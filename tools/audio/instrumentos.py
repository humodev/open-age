"""Instrumentos sintetizados, uno por función. Cada función devuelve una nota o un golpe (mono, numpy).

Las fuentes y lo que queda por verificar de cada instrumento están en
proceso/24-tras-la-segunda-ronda/4g-sonido.md. Son aproximaciones de timbre
hechas con modelos simples; no imitan ninguna grabación.
"""
from __future__ import annotations

import numpy as np

from dsp import (SR, additive, adsr, bandpass, convolve, expdecay, highpass, karplus, lowpass, modal, noise,
                 resonances, rng, soft_clip)


def _vib(n: int, f: float, depth: float, rate: float, delay: float, seed: int) -> np.ndarray:
    t = np.arange(n) / SR
    ramp = np.clip((t - delay) / 0.25, 0, 1)
    jitter = lowpass(rng(seed).standard_normal(n), 6.0, 1.0)
    jitter /= np.max(np.abs(jitter)) + 1e-9
    return f * (1 + depth * ramp * np.sin(2 * np.pi * rate * t) + 0.002 * jitter)


# ============ Andes: quena, siku, wankara ============

def quena(f: float, dur: float, seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Flauta de muesca: casi senoidal, con soplo y un 'chiff' al ataque. Vibrato tardío y leve."""
    n = int(dur * SR)
    fr = _vib(n, f, 0.006, 5.2, 0.18, seed)
    tone = additive(fr, [1.0, 0.32, 0.14, 0.07, 0.035, 0.015], dur, seed)
    env = adsr(n, 0.045, 0.08, 0.82, min(0.12, dur * 0.3))
    breath = bandpass(noise(dur, seed + 1), f * 0.9, f * 3.2, 1.5) * 0.10
    chiff = bandpass(noise(dur, seed + 2), f * 2, f * 5, 2) * expdecay(n, 0.018) * 0.35
    return (tone * env + breath * env + chiff) * vel


def siku(f: float, dur: float, seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Tubo cerrado de la zampoña: armónicos impares y mucho soplo, golpe de aire al ataque."""
    n = int(dur * SR)
    fr = _vib(n, f, 0.003, 4.5, 0.25, seed) * (1 - 0.012 * np.exp(-np.arange(n) / SR / 0.03))
    tone = additive(fr, [1.0, 0.0, 0.30, 0.0, 0.12, 0.0, 0.05], dur, seed)
    env = adsr(n, 0.03, 0.12, 0.65, min(0.15, dur * 0.35))
    breath = bandpass(noise(dur, seed + 3), f * 0.8, f * 6, 1.2) * 0.22
    puff = bandpass(noise(dur, seed + 4), 600, 4000, 1) * expdecay(n, 0.03) * 0.5
    return (tone * env + breath * env + puff) * vel


def wankara(dur: float = 0.9, seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Bombo andino de doble parche, golpeado con maza acolchada [verificar el nombre por región]."""
    modes = [(62, 1.0, 0.30), (98, 0.5, 0.22), (133, 0.3, 0.15), (171, 0.18, 0.1), (205, 0.1, 0.08)]
    body = modal(dur, modes, seed, pitch_drop=0.18, drop_tau=0.04)
    n = len(body)
    thump = lowpass(noise(dur, seed + 5), 900, 2) * expdecay(n, 0.012) * 0.35
    return (body + thump) * vel


# ============ Mapuches: kultrun, trutruka ============

def kultrun(dur: float = 0.7, seed: int = 0, vel: float = 1.0, centro: bool = True) -> np.ndarray:
    """Timbal de cuenco de madera con un solo parche, golpeado con una baqueta (trepuwe).
    Modos de membrana circular (1, 1,59, 2,14, 2,30, 2,65) sobre ~118 Hz y el cuenco que resuena."""
    f0 = 118 if centro else 128
    ratios = [(1.0, 1.0, 0.24), (1.59, 0.55 if not centro else 0.25, 0.14), (2.14, 0.4, 0.1), (2.30, 0.28, 0.09),
              (2.65, 0.22, 0.07), (2.92, 0.15, 0.06), (3.16, 0.1, 0.05)]
    body = modal(dur, [(f0 * r, a, tau) for r, a, tau in ratios], seed, pitch_drop=0.06, drop_tau=0.03)
    n = len(body)
    stick = bandpass(noise(dur, seed + 6), 1500, 6000, 2) * expdecay(n, 0.006) * 0.5
    bowl = modal(dur, [(310, 0.12, 0.08), (560, 0.06, 0.05)], seed + 7)
    return (body + stick + bowl) * vel


def trutruka(f0: float, harm: int, dur: float, seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Trompa larga de colihue con cuerno en la boca: solo da armónicos naturales de una fundamental grave.
    Labio que vibra: muchos armónicos que se abren con la fuerza, y la nota que sube un poco al ataque."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = f0 * harm * (1 - 0.04 * np.exp(-t / 0.06)) * (1 + 0.004 * np.sin(2 * np.pi * 5.5 * t) * np.clip((t - 0.3) / 0.3, 0, 1))
    env = adsr(n, 0.07, 0.15, 0.78, min(0.18, dur * 0.3))
    bright = 2.0 + 5.0 * env * vel

    def amps(k: int) -> np.ndarray:
        return env * np.exp(-(k - 1) / bright)
    tone = additive(f, amps, dur, seed)
    # Cuerno: realza la zona de 700 a 1300 Hz, sin agudos ásperos.
    tone = resonances(tone, [(900, 600, 1.2)])
    tone = lowpass(tone, 2600, 2)
    buzz = bandpass(noise(dur, seed + 8), 300, 2000, 1) * env * 0.04
    return soft_clip((tone + buzz) * 0.8, 1.4) * vel


# ============ Guaraníes: mbaraka, takuapu ============

def mbaraka(dur: float, golpes: list[tuple[float, float]], seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Sonaja de porongo con semillas. `golpes`: (momento, fuerza). Cada sacudida lanza una nube de semillas que
    llegan juntas a la pared (ataque) y se dispersan; cada semilla es un chasquido de ruido de ~1 ms, y el porongo
    hueco colorea el conjunto (resonancia ancha cerca de 1 kHz)."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    rate = np.zeros(n)
    for at, g in golpes:
        dt = t - at
        rate += np.where(dt >= 0, g * 1800 * np.exp(-dt / 0.04) * np.clip(dt / 0.005, 0, 1), 0.0)
    r = rng(seed)
    hits = (r.random(n) < np.clip(rate / SR, 0, 1)) * r.uniform(0.2, 1.0, n)
    k = np.exp(-np.arange(int(0.004 * SR)) / SR / 0.0009)
    env = convolve(hits, k)[:n]
    x = r.standard_normal(n) * env
    x = bandpass(x, 1800, 9000, 1.5)
    x = resonances(x, [(1000, 500, 1.2), (3600, 2500, 0.6)])
    return x * vel


def takuapu(alto: bool, dur: float = 0.5, seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Bastón de takuara grueso que se golpea contra el suelo: golpe sordo y el tubo (cerrado abajo) que resuena
    en armónicos impares. Dos largos: uno más agudo."""
    f = 172 if alto else 128
    tube = modal(dur, [(f, 1.0, 0.09), (3 * f * 1.02, 0.35, 0.05), (5 * f * 1.03, 0.15, 0.03)], seed)
    n = len(tube)
    ground = lowpass(noise(dur, seed + 9), 300, 2) * expdecay(n, 0.02) * 1.1
    wood = modal(dur, [(f * 4.6, 0.25, 0.012), (f * 7.3, 0.12, 0.008)], seed + 10)
    return (tube + ground + wood) * vel


# ============ Etiopía: kebero, begena, masenqo ============

def kebero(grande: bool, dur: float = 0.9, seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Tambor de dos parches tocado con las manos: el grande da el golpe grave (cae la altura),
    el chico un golpe seco y más agudo."""
    if grande:
        modes = [(72, 1.0, 0.32), (115, 0.45, 0.2), (156, 0.25, 0.13), (199, 0.12, 0.09)]
        body = modal(dur, modes, seed, pitch_drop=0.14, drop_tau=0.05)
        skin = lowpass(noise(dur, seed + 11), 700, 2) * expdecay(len(body), 0.01) * 0.3
    else:
        modes = [(196, 0.8, 0.09), (312, 0.5, 0.06), (420, 0.3, 0.045), (517, 0.2, 0.035)]
        body = modal(dur, modes, seed, pitch_drop=0.05, drop_tau=0.02)
        skin = bandpass(noise(dur, seed + 11), 800, 4500, 2) * expdecay(len(body), 0.008) * 0.45
    return (body + skin) * vel


def begena(f: float, dur: float, seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Lira grande de diez cuerdas gruesas: grave, y cada cuerda zumba contra una tira de cuero (el
    'zumbido' característico). Cuerda pulsada + un zumbido que roza cuando la cuerda va hacia un lado."""
    s = karplus(f, dur, seed, decay=0.9985, bright=0.35, pluck_pos=0.18)
    s /= np.max(np.abs(s)) + 1e-9
    n = len(s)
    # El roce: solo la mitad positiva pasa por un recorte duro y se filtra a la zona media.
    touch = np.clip(s - 0.15, 0, None)
    buzz = bandpass(np.sign(touch) * touch ** 0.4, 600, 5000, 1.5)
    buzz *= np.exp(-np.arange(n) / SR / 1.2)
    body = resonances(s, [(110, 60, 1.5), (240, 120, 0.8)])
    return lowpass(body + 0.28 * buzz, 4500, 1.5) * vel


def masenqo(freqs: list[tuple[float, float]], dur: float, seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Violín de una cuerda con caja en rombo y parche de cuero, tocado con arco. Lista de (inicio, frecuencia):
    pasa de nota en nota con un pequeño glissando, como hace la mano sobre la única cuerda."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    target = np.zeros(n)
    for i, (at, fr) in enumerate(freqs):
        target[t >= at] = fr
    target[target == 0] = freqs[0][1]
    # Glissando: suaviza los saltos de altura (~35 ms) en escala logarítmica.
    lf = np.log(target)
    k = int(0.035 * SR)
    lf = np.convolve(np.pad(lf, (k, k), mode="edge"), np.ones(k) / k, mode="same")[k:-k]
    fr = np.exp(lf) * (1 + 0.009 * np.sin(2 * np.pi * 5.8 * t) * np.clip((t - 0.15) / 0.3, 0, 1))
    saw = additive(fr, [1.0 / k for k in range(1, 30)], dur, seed)
    bow = bandpass(noise(dur, seed + 12), 1500, 6000, 1) * 0.05
    env = adsr(n, 0.09, 0.1, 0.85, min(0.2, dur * 0.25))
    # Re-arco en cada nota: leve acento.
    acc = np.ones(n)
    for at, _ in freqs[1:]:
        acc += 0.18 * np.exp(-np.clip(t - at, 0, None) / 0.08) * (t >= at)
    x = (saw + bow) * env * acc
    # Parche de cuero: timbre nasal (resonancias medias), sin el brillo del violín europeo.
    x = resonances(x, [(520, 220, 2.0), (1350, 500, 1.4), (2600, 900, 0.5)])
    return lowpass(highpass(x, 180, 2), 3800, 2) * vel


# ============ Palmares: atabaque, berimbau, caxixi ============

def atabaque(golpe: str, dur: float = 0.6, seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Tambor alto de un parche tocado con las manos: 'grave' (mano al centro), 'aberto' (borde, nota) y 'tapa' (seco)."""
    if golpe == "grave":
        body = modal(dur, [(92, 1.0, 0.22), (147, 0.4, 0.12), (196, 0.2, 0.08)], seed, 0.08, 0.03)
        sk = lowpass(noise(dur, seed + 13), 600, 2) * expdecay(len(body), 0.01) * 0.3
    elif golpe == "aberto":
        body = modal(dur, [(188, 1.0, 0.18), (300, 0.45, 0.1), (402, 0.3, 0.07), (432, 0.2, 0.06), (500, 0.12, 0.05)], seed, 0.03, 0.02)
        sk = bandpass(noise(dur, seed + 13), 900, 5000, 2) * expdecay(len(body), 0.006) * 0.35
    else:
        body = modal(dur, [(188, 0.4, 0.05), (360, 0.4, 0.035), (610, 0.35, 0.025)], seed)
        sk = bandpass(noise(dur, seed + 13), 1500, 7000, 2) * expdecay(len(body), 0.012) * 0.9
    return (body + sk) * vel


def caxixi(dur: float = 0.15, seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Cestita con semillas que se toca con la misma mano de la baqueta del berimbau."""
    n = int(dur * SR)
    x = bandpass(noise(dur, seed + 14), 3000, 9000, 2) * expdecay(n, 0.03, 0.006)
    return x * 0.6 * vel


def berimbau(f: float, dur: float, seed: int = 0, vel: float = 1.0, chiado: bool = False, wah_rate: float = 1.6) -> np.ndarray:
    """Arco de alambre con la calabaza contra el vientre: golpe de baqueta sobre el alambre (cuerda metálica, poco
    amortiguada) y la boca de la calabaza que se abre y se cierra ('uá'). `chiado`: la piedra apenas apoyada, zumbido."""
    s = karplus(f, dur, seed, decay=0.9993 if not chiado else 0.985, bright=0.95, pluck_pos=0.07)
    s /= np.max(np.abs(s)) + 1e-9
    n = len(s)
    t = np.arange(n) / SR
    if chiado:
        s = soft_clip(s * 3, 2) * expdecay(n, 0.08)
        s = bandpass(s, 400, 5000, 1)
    # Calabaza: resonancia que se mueve (abierta ~ 2,5 f, cerrada ~ 1,2 f): mezcla de dos filtrados.
    open_ = resonances(s, [(f * 2.6, f * 0.8, 3.0)])
    closed = resonances(s, [(f * 1.25, f * 0.5, 2.5)])
    m = 0.5 + 0.5 * np.sin(2 * np.pi * wah_rate * t - np.pi / 2)
    x = closed * (1 - m) + open_ * m
    stick = bandpass(noise(dur, seed + 15), 2000, 8000, 2) * expdecay(n, 0.004) * 0.4
    return lowpass(x + stick, 6000, 1.5) * vel


# ============ Ayutthaya: khong wong, ranat, ching ============

def khong(f: float, dur: float = 1.8, seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Gong de bulto (uno del círculo khong wong yai): parciales inarmónicos con pares levemente desafinados que
    laten, ataque brillante de la maza dura y cola larga."""
    parts = [(1.0, 1.0, 1.4), (1.004, 0.5, 1.3), (2.02, 0.45, 0.7), (2.95, 0.3, 0.45), (2.97, 0.15, 0.45),
             (4.2, 0.18, 0.25), (5.4, 0.1, 0.16), (6.9, 0.06, 0.1)]
    x = modal(dur, [(f * r, a, tau) for r, a, tau in parts], seed)
    mallet = bandpass(noise(dur, seed + 16), 2000, 6000, 2) * expdecay(len(x), 0.004) * 0.25
    return (x + mallet) * vel


def ranat(f: float, dur: float = 0.55, seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Teclado de láminas de madera dura con mazas duras (ranat ek): fundamental reforzada por el cajón con forma de
    barco, parciales de barra libre (2,76 y 5,40) y decaimiento corto."""
    x = modal(dur, [(f, 1.0, 0.28), (f * 2.76, 0.35, 0.06), (f * 5.40, 0.12, 0.025), (f * 2.0, 0.08, 0.12)], seed)
    knock = bandpass(noise(dur, seed + 17), 1500, 5000, 2) * expdecay(len(x), 0.003) * 0.3
    return (x + knock) * vel


def ching(abierto: bool = True, dur: float = 0.9, seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Platillos chicos de bronce en par: 'ching' abierto (suena) y 'chap' cerrado (seco)."""
    tau = 0.55 if abierto else 0.05
    parts = [(1820, 0.5, tau), (2290, 0.6, tau * 0.9), (3170, 0.5, tau * 0.7), (4410, 0.35, tau * 0.6), (5930, 0.25, tau * 0.5), (7210, 0.15, tau * 0.4)]
    x = modal(dur, parts, seed)
    hiss = bandpass(noise(dur, seed + 18), 4000, 11000, 2) * expdecay(len(x), tau * 0.4) * 0.15
    return (x + hiss) * vel
