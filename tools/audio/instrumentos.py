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


# ============ Mapuches: trutruka, kull-kull, kakelkultrun ============
# El kultrun (tambor de la machi) no se usa: ver proceso/24-tras-la-segunda-ronda/4h-sonido-con-respeto.md.

def kakelkultrun(dur: float = 0.7, seed: int = 0, vel: float = 1.0, centro: bool = True) -> np.ndarray:
    """Tambor de dos parches, de uso no ceremonial [verificar: Grebe], golpeado con un palo. Cuerpo cilíndrico
    abierto, sin el cuenco del kultrun: dos parches casi iguales cuyos modos laten entre sí (98 y 101 Hz), un
    golpe de aire grave y el chasquido del palo. `centro=False`: golpe cerca del borde, más seco y agudo."""
    f0 = 98 if centro else 112
    a2 = 0.3 if centro else 0.6
    modes = []
    for detune, amp in ((1.0, 1.0), (1.03, 0.7)):
        modes += [(f0 * detune * r, amp * a, tau) for r, a, tau in
                  [(1.0, 1.0, 0.2), (1.59, a2, 0.11), (2.14, 0.3, 0.07), (2.65, 0.15, 0.05)]]
    body = modal(dur, modes, seed, pitch_drop=0.08, drop_tau=0.035)
    n = len(body)
    air = lowpass(noise(dur, seed + 19), 220, 2) * expdecay(n, 0.03) * 0.5
    stick = bandpass(noise(dur, seed + 6), 1200, 5000, 2) * expdecay(n, 0.005) * (0.35 if centro else 0.6)
    return (body * 0.6 + air + stick) * vel


def kull_kull(f: float, dur: float, seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Cuerno de vaca soplado de costado o por la punta [verificar]: tubo corto y cónico, una nota ronca y nasal
    que sube al atacar, a veces con un salto a la octava. Más agudo y más corto que la trutruka."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    fr = f * (1 - 0.07 * np.exp(-t / 0.05))
    env = adsr(n, 0.04, 0.08, 0.8, min(0.12, dur * 0.3))
    bright = 1.5 + 4.0 * env * vel

    def amps(k: int) -> np.ndarray:
        return env * np.exp(-(k - 1) / bright)
    tone = additive(fr, amps, dur, seed)
    # Ronquera: leve modulación irregular de amplitud, y la boca del cuerno que realza 1-2 kHz.
    rough = 1 + 0.12 * lowpass(rng(seed + 20).standard_normal(n), 40, 2) / 0.05
    tone = resonances(tone * np.clip(rough, 0.6, 1.4), [(1400, 700, 1.4)])
    tone = lowpass(tone, 3200, 2)
    breath = bandpass(noise(dur, seed + 21), 600, 3000, 1) * env * 0.03
    return soft_clip((tone + breath) * 0.8, 1.6) * vel


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


# ============ Guaraníes: mimby, angu'apu ============
# La mbaraka y el takuapu (instrumentos del opy) no se usan: ver 4h-sonido-con-respeto.md.

def mimby(f: float, dur: float, seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Flauta de caña o de hueso [verificar]: más aguda y más soplada que la quena, sin vibrato, con un leve
    ascenso de altura al atacar y un tono de filo (ruido estrecho por encima de la nota)."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    fr = f * (1 - 0.015 * np.exp(-t / 0.02))
    tone = additive(fr, [1.0, 0.12, 0.22, 0.04, 0.06], dur, seed)
    env = adsr(n, 0.02, 0.05, 0.75, min(0.08, dur * 0.3))
    breath = bandpass(noise(dur, seed + 22), f * 0.7, f * 4.0, 1.2) * 0.16
    edge = bandpass(noise(dur, seed + 23), f * 2.8, f * 3.4, 3) * 0.12
    chiff = bandpass(noise(dur, seed + 24), 2000, 8000, 2) * expdecay(n, 0.012) * 0.3
    return ((tone + breath + edge) * env + chiff) * vel


def angu_apu(grave: bool = True, dur: float = 0.6, seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Tambor de tronco ahuecado con parche [verificar], golpeado con la mano o un palo: membrana grave y el
    tronco de madera gruesa que resuena (modos de madera cortos). `grave=False`: golpe al borde, seco."""
    if grave:
        body = modal(dur, [(84, 1.0, 0.24), (134, 0.4, 0.13), (180, 0.22, 0.08)], seed, 0.1, 0.03)
        wood = modal(dur, [(410, 0.2, 0.03), (690, 0.1, 0.02)], seed + 25)
        sk = lowpass(noise(dur, seed + 26), 700, 2) * expdecay(len(body), 0.012) * 0.35
    else:
        body = modal(dur, [(150, 0.4, 0.06), (260, 0.35, 0.04), (410, 0.4, 0.03), (690, 0.25, 0.02)], seed)
        wood = modal(dur, [(1150, 0.15, 0.012)], seed + 25)
        sk = bandpass(noise(dur, seed + 26), 1200, 6000, 2) * expdecay(len(body), 0.008) * 0.6
    return (body + wood + sk) * vel


# ============ Etiopía: kebero, krar, masenqo ============
# La begena (lira de la oración de Cuaresma) no se usa: ver 4h-sonido-con-respeto.md.

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


def krar(f: float, dur: float, seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Lira de cinco o seis cuerdas de los azmari, profana, punteada con plectro: más aguda y brillante que la
    begena y sin su zumbido de cuero. Caja de cuenco cubierta de cuero (resonancias medias)."""
    s = karplus(f, dur, seed, decay=0.9975, bright=0.7, pluck_pos=0.12)
    s /= np.max(np.abs(s)) + 1e-9
    n = len(s)
    pick = bandpass(noise(dur, seed + 27), 2500, 7000, 2) * expdecay(n, 0.003) * 0.15
    body = resonances(s, [(260, 120, 1.2), (620, 300, 0.9), (1500, 700, 0.4)])
    return lowpass(body + pick, 6000, 1.5) * vel


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


# ============ Palmares: ngoma, marimba, kisanji, ngongi ============
# Raíz centroafricana (Angola Janga). Sin berimbau ni toques de capoeira: ver 4h-sonido-con-respeto.md.

def ngoma(golpe: str, grande: bool = True, dur: float = 0.7, seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Tambor alto de un parche, de tradición congo-angoleña, tocado con las manos [verificar]. 'abierto' (la
    nota), 'grave' (mano al centro, cae la altura) y 'seco' (palmada en el borde). El grande suena una quinta
    abajo del chico, aproximadamente."""
    f = 78 if grande else 118
    if golpe == "grave":
        body = modal(dur, [(f, 1.0, 0.26), (f * 1.59, 0.35, 0.13), (f * 2.14, 0.18, 0.08)], seed, 0.12, 0.035)
        sk = lowpass(noise(dur, seed + 13), 500, 2) * expdecay(len(body), 0.012) * 0.3
    elif golpe == "abierto":
        body = modal(dur, [(f * 1.6, 1.0, 0.2), (f * 2.5, 0.45, 0.1), (f * 3.4, 0.25, 0.07), (f * 4.1, 0.15, 0.05)], seed, 0.03, 0.02)
        sk = bandpass(noise(dur, seed + 13), 800, 4500, 2) * expdecay(len(body), 0.006) * 0.3
    else:
        body = modal(dur, [(f * 1.6, 0.35, 0.05), (f * 3.2, 0.35, 0.03), (f * 5.3, 0.3, 0.02)], seed)
        sk = bandpass(noise(dur, seed + 13), 1500, 7000, 2) * expdecay(len(body), 0.012) * 0.85
    return (body + sk) * vel


def marimba(f: float, dur: float = 0.8, seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Marimba angoleña: tablas de madera sobre calabazas, cada calabaza con una membrana que zumba (mirlitón)
    [verificar]. Parciales de barra afinada a mano (1; 3,9 aprox.), decaimiento corto, y el zumbido."""
    x = modal(dur, [(f, 1.0, 0.35), (f * 3.9, 0.22, 0.05), (f * 2.0, 0.05, 0.15)], seed)
    n = len(x)
    knock = bandpass(noise(dur, seed + 28), 800, 3500, 2) * expdecay(n, 0.004) * 0.25
    # Mirlitón: la membrana vibra con la calabaza y solo roza de un lado: recorte asimétrico filtrado.
    m = np.clip(x / (np.max(np.abs(x)) + 1e-9) - 0.2, 0, None) ** 0.5
    buzz = bandpass(m, 400, 4000, 1.5) * np.exp(-np.arange(n) / SR / 0.25) * 0.22
    return (resonances(x, [(f, f * 0.3, 1.2)]) + knock + buzz) * vel


def kisanji(f: float, dur: float = 1.0, seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Lamelófono de lengüetas de hierro sobre una tabla o caja (kisanji, nsambi) [verificar]: parcial alto muy
    inarmónico (~5,9) que se apaga enseguida, fundamental larga y un leve cascabeleo de anillos."""
    x = modal(dur, [(f, 1.0, 0.6), (f * 5.9, 0.35, 0.03), (f * 13.0, 0.1, 0.01)], seed)
    n = len(x)
    click = bandpass(noise(dur, seed + 29), 2000, 7000, 2) * expdecay(n, 0.002) * 0.2
    rattle = bandpass(noise(dur, seed + 30), 3000, 9000, 2) * expdecay(n, 0.06, 0.004) * 0.05
    return (resonances(x, [(f * 1.0, f * 0.4, 0.8)]) + click + rattle) * vel


def ngongi(alta: bool, dur: float = 0.6, seed: int = 0, vel: float = 1.0) -> np.ndarray:
    """Campana doble de hierro forjado, golpeada con un palo (ngongi, de donde viene el gonguê/agogô) [verificar].
    Hierro, no bronce: parciales inarmónicos que se apagan rápido."""
    f = 920 if alta else 690
    x = modal(dur, [(f, 1.0, 0.22), (f * 2.32, 0.5, 0.1), (f * 3.9, 0.3, 0.06), (f * 5.6, 0.15, 0.04)], seed)
    hit = bandpass(noise(dur, seed + 31), 2500, 9000, 2) * expdecay(len(x), 0.003) * 0.3
    return (x + hit) * vel


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
