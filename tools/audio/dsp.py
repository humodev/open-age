"""Herramientas de síntesis para los sonidos de los pueblos (solo numpy).

Todo lo que sale de acá es obra propia del proyecto: no se usa ninguna muestra
grabada, solo osciladores, ruido y filtros. Ver tools/audio/README en
assets/CREDITOS.md y proceso/24-tras-la-segunda-ronda/4g-sonido.md.
"""
from __future__ import annotations

import json
import os
import subprocess
import tempfile
import wave

import numpy as np

SR = 44100


def rng(seed: int) -> np.random.Generator:
    return np.random.default_rng(seed)


def t_axis(dur: float) -> np.ndarray:
    return np.arange(int(dur * SR)) / SR


def silence(dur: float) -> np.ndarray:
    return np.zeros(int(dur * SR))


# --- envolventes ---------------------------------------------------------

def adsr(n: int, a: float, d: float, s: float, r: float, hold: float | None = None) -> np.ndarray:
    """Envolvente ataque-decaimiento-sostén-relajación en muestras; `hold` en segundos (por defecto, hasta el final menos r)."""
    t = np.arange(n) / SR
    total = n / SR
    if hold is None:
        hold = max(0.0, total - r)
    env = np.empty(n)
    env[:] = s
    env = np.where(t < a, t / max(a, 1e-6), env)
    dmask = (t >= a) & (t < a + d)
    env = np.where(dmask, 1.0 - (1.0 - s) * (t - a) / max(d, 1e-6), env)
    rmask = t >= hold
    env = np.where(rmask, s * np.clip(1.0 - (t - hold) / max(r, 1e-6), 0.0, 1.0), env)
    return env


def expdecay(n: int, tau: float, attack: float = 0.002) -> np.ndarray:
    t = np.arange(n) / SR
    return np.exp(-t / tau) * np.clip(t / attack, 0.0, 1.0)


# --- filtros por espectro ---------------------------------------------------

def _spec_filter(x: np.ndarray, gain_fn) -> np.ndarray:
    n = len(x)
    m = 1 << int(np.ceil(np.log2(max(n, 2))))
    X = np.fft.rfft(x, m)
    f = np.fft.rfftfreq(m, 1.0 / SR)
    return np.fft.irfft(X * gain_fn(f), m)[:n]


def lowpass(x: np.ndarray, fc: float, order: float = 2.0) -> np.ndarray:
    return _spec_filter(x, lambda f: 1.0 / np.sqrt(1.0 + (f / fc) ** (2 * order)))


def highpass(x: np.ndarray, fc: float, order: float = 2.0) -> np.ndarray:
    return _spec_filter(x, lambda f: 1.0 / np.sqrt(1.0 + (fc / np.maximum(f, 1e-3)) ** (2 * order)))


def bandpass(x: np.ndarray, lo: float, hi: float, order: float = 2.0) -> np.ndarray:
    return highpass(lowpass(x, hi, order), lo, order)


def resonances(x: np.ndarray, peaks: list[tuple[float, float, float]]) -> np.ndarray:
    """Suma resonancias (frecuencia, ancho en Hz, ganancia lineal extra) a la respuesta plana."""
    def g(f):
        out = np.ones_like(f)
        for fc, bw, gain in peaks:
            out = out + gain / (1.0 + ((f - fc) / (bw / 2.0)) ** 2)
        return out
    return _spec_filter(x, g)


def convolve(x: np.ndarray, h: np.ndarray) -> np.ndarray:
    n = len(x) + len(h) - 1
    m = 1 << int(np.ceil(np.log2(n)))
    return np.fft.irfft(np.fft.rfft(x, m) * np.fft.rfft(h, m), m)[:n]


# --- generadores ------------------------------------------------------------

def additive(freq: np.ndarray | float, amps, dur: float, phase_seed: int = 0, inharm: float = 0.0) -> np.ndarray:
    """Suma de armónicos. `freq` puede variar en el tiempo (vibrato, glissando).
    `amps` es una lista de amplitudes o una función k -> array(n) (brillo que cambia en el tiempo)."""
    n = int(dur * SR)
    f = np.broadcast_to(np.asarray(freq, dtype=float), (n,)) if np.ndim(freq) == 0 else np.asarray(freq)[:n]
    phase = 2 * np.pi * np.cumsum(f) / SR
    r = rng(phase_seed)
    out = np.zeros(n)
    kmax = len(amps) if not callable(amps) else 48
    fmax = float(np.max(f))
    for k in range(1, kmax + 1):
        ratio = k * np.sqrt(1.0 + inharm * k * k)
        if ratio * fmax >= SR * 0.45:
            break
        a = amps(k) if callable(amps) else amps[k - 1]
        if np.isscalar(a) and a == 0:
            continue
        out += a * np.sin(ratio * phase + r.uniform(0, 2 * np.pi))
    return out


def modal(dur: float, modes: list[tuple[float, float, float]], seed: int = 0, pitch_drop: float = 0.0, drop_tau: float = 0.05) -> np.ndarray:
    """Modos amortiguados (frecuencia, amplitud, tau en s). `pitch_drop`: fracción que cae la altura al golpe (parches)."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    r = rng(seed)
    bend = 1.0 + pitch_drop * np.exp(-t / drop_tau)
    out = np.zeros(n)
    for f, a, tau in modes:
        if f * (1 + pitch_drop) >= SR * 0.45:
            continue
        ph = 2 * np.pi * np.cumsum(f * bend) / SR
        out += a * np.sin(ph + r.uniform(0, 2 * np.pi)) * np.exp(-t / tau)
    return out * np.clip(t / 0.0008, 0, 1)


def noise(dur: float, seed: int) -> np.ndarray:
    return rng(seed).standard_normal(int(dur * SR))


def karplus(freq: float, dur: float, seed: int = 0, decay: float = 0.996, bright: float = 0.6, pluck_pos: float = 0.0) -> np.ndarray:
    """Cuerda pulsada (Karplus-Strong) en bloques; afinación exacta por remuestreo."""
    n_out = int(dur * SR)
    N = max(8, int(SR / freq))
    ratio = (SR / freq) / N  # >1: hay que estirar
    total = int(n_out / ratio) + N + 2
    r = rng(seed)
    exc = r.uniform(-1, 1, N)
    # Brillo: mezcla del ruido con su versión suavizada.
    smooth = np.convolve(exc, np.ones(5) / 5, mode="same")
    exc = bright * exc + (1 - bright) * smooth
    if pluck_pos > 0:
        d = max(1, int(N * pluck_pos))
        exc = exc - np.roll(exc, d)
    exc -= exc.mean()
    y = np.zeros(total + N)
    y[:N] = exc
    start = N
    while start < total:
        end = min(start + N, total)
        L = end - start
        a = y[start - N:start - N + L]
        b = y[start - N - 1:start - N - 1 + L] if start - N - 1 >= 0 else np.concatenate(([0.0], y[0:L - 1]))
        y[start:end] = decay * 0.5 * (a + b)
        start = end
    y = y[:total]
    src = np.arange(n_out) / ratio
    return np.interp(src, np.arange(total), y)


def grains(dur: float, rate_env: np.ndarray, seed: int, kernel: np.ndarray) -> np.ndarray:
    """Granos al azar (semillas de una sonaja): densidad por muestra en `rate_env` (granos por segundo)."""
    n = int(dur * SR)
    r = rng(seed)
    p = np.clip(rate_env[:n] / SR, 0, 1)
    hits = (r.random(n) < p).astype(float) * r.uniform(0.3, 1.0, n) * np.sign(r.uniform(-1, 1, n))
    return convolve(hits, kernel)[:n]


# --- espacio y mezcla ---------------------------------------------------------

def reverb_ir(dur: float, tau: float, seed: int, damp_hz: float = 5000.0, pre: float = 0.012) -> np.ndarray:
    n = int(dur * SR)
    t = np.arange(n) / SR
    ir = rng(seed).standard_normal(n) * np.exp(-t / tau)
    ir = lowpass(ir, damp_hz, 1.0)
    ir[: int(pre * SR)] = 0.0
    return ir / np.sqrt(np.sum(ir ** 2))


def reverb(x: np.ndarray, wet: float = 0.18, tau: float = 0.35, seed: int = 7, damp_hz: float = 5000.0) -> np.ndarray:
    ir = reverb_ir(min(2.5, tau * 6), tau, seed, damp_hz)
    y = convolve(x, ir)
    out = np.zeros(len(y))
    out[: len(x)] += x
    return out * (1 - wet) + y * wet


def place(buf: np.ndarray, x: np.ndarray, at: float, gain: float = 1.0) -> np.ndarray:
    """Suma `x` en `buf` desde `at` segundos. Cierra la nota con 15 ms de fundido para que no haga clic
    si todavía suena."""
    x = fade(x, 0.0, 0.015)
    i = int(at * SR)
    need = i + len(x)
    if need > len(buf):
        buf = np.concatenate((buf, np.zeros(need - len(buf))))
    buf[i:need] += gain * x
    return buf


def fade(x: np.ndarray, fin: float = 0.003, fout: float = 0.05) -> np.ndarray:
    x = x.copy()
    a, b = int(fin * SR), int(fout * SR)
    if a:
        x[:a] *= np.linspace(0, 1, a)
    if b:
        x[-b:] *= np.linspace(1, 0, b)
    return x


def trim_tail(x: np.ndarray, thresh_db: float = -48.0, fout: float = 0.08) -> np.ndarray:
    peak = np.max(np.abs(x)) + 1e-12
    above = np.nonzero(np.abs(x) > peak * 10 ** (thresh_db / 20))[0]
    end = int(above[-1]) + 1 if len(above) else len(x)
    return fade(x[:end], 0.0, fout)


def pan(x: np.ndarray, p: float) -> np.ndarray:
    """p en [-1, 1]; potencia constante. Devuelve (n, 2)."""
    a = (p + 1) * np.pi / 4
    return np.stack((x * np.cos(a), x * np.sin(a)), axis=1)


def soft_clip(x: np.ndarray, drive: float = 1.0) -> np.ndarray:
    return np.tanh(x * drive) / np.tanh(drive)


# --- escalas ---------------------------------------------------------------------

def et(base: float, steps: float, div: int = 12) -> float:
    return base * 2.0 ** (steps / div)


# --- salida -------------------------------------------------------------------------

def _write_wav(path: str, x: np.ndarray) -> None:
    x = np.asarray(x, dtype=float)
    if x.ndim == 1:
        x = x[:, None]
    peak = np.max(np.abs(x)) + 1e-12
    x = x / peak * 0.5  # margen: el volumen final lo pone ffmpeg
    data = (x * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(x.shape[1])
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def _loudness(path: str) -> tuple[float, float]:
    out = subprocess.run(["ffmpeg", "-nostats", "-hide_banner", "-i", path, "-af", "ebur128=peak=true", "-f", "null", "-"],
                         capture_output=True, text=True).stderr
    i_val, peak = -70.0, 0.0
    for line in out.splitlines()[::-1]:
        s = line.strip()
        if s.startswith("I:") and i_val == -70.0:
            i_val = float(s.split()[1])
        if s.startswith("Peak:") and peak == 0.0:
            peak = float(s.split()[1])
    return i_val, peak


def export(x: np.ndarray, dest: str, lufs: float, peak_max: float = -1.5, quality: int = 4) -> dict:
    """Escribe `dest` en Ogg Vorbis con sonoridad integrada `lufs` (sin pasar `peak_max` dBFS de pico real).
    Los sonidos muy cortos, que ebur128 no llega a medir, se ajustan por pico."""
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with tempfile.TemporaryDirectory() as td:
        wav = os.path.join(td, "x.wav")
        _write_wav(wav, x)
        i_val, peak = _loudness(wav)
        if i_val <= -69.0:
            gain = peak_max - 3.0 - peak
        else:
            # Hasta 6 dB de limitador para los golpes de percusión; más que eso, se queda más bajo.
            gain = min(lufs - i_val, peak_max - peak + 6.0)
        lim = 10 ** ((peak_max - 0.5) / 20)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-af",
                        f"volume={gain:.2f}dB,alimiter=limit={lim:.3f}:level=disabled:attack=2:release=60",
                        "-c:a", "libvorbis", "-q:a", str(quality), "-fflags", "+bitexact", "-flags:a", "+bitexact", "-serial_offset", "1", dest], check=True)
    i2, p2 = _loudness(dest)
    return {"archivo": dest, "lufs": i2, "pico_dbfs": p2, "duracion_s": round(len(x) / SR, 2)}


def save_meta(path: str, rows: list[dict]) -> None:
    with open(path, "w", encoding="utf-8") as f:
        json.dump(rows, f, ensure_ascii=False, indent=1)
