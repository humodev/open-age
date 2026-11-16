#!/usr/bin/env python3
"""Modelo numérico de las peleas de tools/micro_matriz.gd (proceso/24, 5a).

Lee data/reglas.json, data/unidades.json y data/edades.json (más un parche opcional, el mismo
formato que usa micro_matriz.gd) y calcula, por par de unidades:

  * daño por golpe y daño por segundo efectivo (ataque con bono de edad + bono por función
    − la armadura que toca, mínimo `danio_minimo`), golpes para matar y tiempo para matar;
  * fuerza de Lanchester (dps × vida): el que tiene más gana; con la ley cuadrada, la fracción
    que sobrevive es sqrt(1 − (Fb/Fa)²);
  * kiteo: tiros gratis al acercarse y si el escalonado deja distancia o la pierde por ciclo.

Y simula en una dimensión las peleas de grupo de la matriz (sin micro y con la línea que
mantiene y la distancia que escalona detrás), con dos parámetros que se calibran contra lo
medido: qué fracción de los cuerpo a cuerpo llega a pegar a la vez (`--contacto`) y cuánto
reparten el daño en vez de concentrarlo (`--reparto`).

Uso:
  python3 tools/modelo_micro.py                      # datos del repo
  python3 tools/modelo_micro.py --parche=x.json      # con una propuesta
  python3 tools/modelo_micro.py --edad=2 --contacto=60 --reparto=40
"""
import argparse
import copy
import json
import math
import os

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


def cargar(parche=None):
    def j(p):
        with open(os.path.join(RAIZ, p), encoding="utf-8") as f:
            return json.load(f)

    reglas, unidades, edades = j("data/reglas.json"), j("data/unidades.json"), j("data/edades.json")
    if parche:
        with open(parche, encoding="utf-8") as f:
            p = json.load(f)
        fusionar(reglas, p.get("reglas", {}))
        fusionar(unidades, p.get("unidades", {}))
    return reglas, unidades, edades["edades"]


def fusionar(dst, src):
    for k, v in src.items():
        if isinstance(v, dict) and isinstance(dst.get(k), dict):
            fusionar(dst[k], v)
        else:
            dst[k] = copy.deepcopy(v)


class Unidad:
    def __init__(self, clave, d, reglas, edad, edades):
        self.clave = clave
        self.fn = d["funcion"]
        self.pv = d["pv"]
        bono_edad = edades[edad - 1].get("bono_ataque", 0)
        self.ataque = d["ataque"] * (100 + bono_edad) // 100  # como effective_attack, en enteros
        self.arm = d.get("armadura", 0)
        self.arm_d = d.get("armadura_distancia", self.arm)
        self.alcance = d["alcance"] / 1000
        self.cad = d["cadencia_ms"] / 1000
        self.vel = d["velocidad"] * reglas.get("velocidad_pct", 100) / 100 / 1000
        self.radio = d["radio"] / 1000
        self.distancia = d["alcance"] > reglas.get("alcance_distancia", 1500)
        self.bono_propio = d.get("bono", {})
        self.montado = d.get("montado", False)
        self.costo = sum(d.get("costo", {}).values())
        self.pob = d.get("pob", 1)


def golpe(a, t, reglas):
    b = reglas.get("bonos", {}).get(a.fn, {}).get(t.fn, 0) + a.bono_propio.get(t.fn, 0)
    if t.montado:
        b += a.bono_propio.get("montado", 0)
    arm = t.arm_d if a.distancia else t.arm
    return max(reglas["danio_minimo"], a.ataque + b - arm)


def dps(a, t, reglas):
    return golpe(a, t, reglas) / a.cad


def tabla_pares(us, reglas):
    print("## Daño por golpe, dps y tiempo para matar (uno contra uno)")
    print("atacante → blanco | golpe | dps | golpes para matar | segundos para matar")
    for a in us.values():
        for t in us.values():
            g = golpe(a, t, reglas)
            n = math.ceil(t.pv / g)
            print(f"{a.clave} → {t.clave} | {g} | {g / a.cad:.1f} | {n} | {n * a.cad:.1f}")
    print()
    print("## Fuerza de Lanchester por población (dps × vida ÷ pob²) y ley cuadrada, misma población")
    print("A contra B | fuerza A | fuerza B | gana | quedan (de 10 pob)")
    claves = list(us)
    for i, ka in enumerate(claves):
        for kb in claves[i + 1:]:
            a, b = us[ka], us[kb]
            fa = dps(a, b, reglas) * a.pv / a.pob ** 2
            fb = dps(b, a, reglas) * b.pv / b.pob ** 2
            w, fw, fl = (ka, fa, fb) if fa >= fb else (kb, fb, fa)
            q = 10 * math.sqrt(max(0.0, 1 - (fl / fw) ** 2)) / us[w].pob
            print(f"{ka} contra {kb} | {fa:.0f} | {fb:.0f} | {w} | {q:.1f}")
    print()


def tabla_kiteo(us, reglas, latencia):
    print("## Kiteo: ¿el de distancia mantiene la distancia al escalonar?")
    print(f"(latencia de la orden: {latencia} s; el disparo es instantáneo en la simulación)")
    print("tirador contra perseguidor | vel. tirador | vel. perseguidor | se acerca por ciclo (casillas) | tiros gratis al acercarse | tiros escalonando antes del contacto")
    for a in us.values():
        if not a.distancia:
            continue
        for t in us.values():
            if t.distancia:
                continue
            hueco = a.alcance - t.alcance - a.radio - t.radio
            # Al acercarse con el tirador quieto: un tiro por ciclo mientras cierra el hueco.
            libres = hueco / t.vel / a.cad + 1
            # Escalonando: en cada ciclo el tirador se para `latencia` y corre el resto.
            cierre = t.vel * a.cad - a.vel * max(0.0, a.cad - latencia)
            if cierre <= 0:
                esc = "sin límite (lo mantiene a raya)"
            else:
                esc = f"{hueco / cierre + 1:.1f}"
            print(f"{a.clave} contra {t.clave} | {a.vel:.2f} | {t.vel:.2f} | {cierre:+.2f} | {libres:.1f} | {esc}")
    print()


# ----------------------------------------------------------------- pelea de grupos en 1D

class Grupo:
    def __init__(self, u, n, x, lado):
        self.u, self.n0, self.x, self.lado = u, n, x, lado
        self.pool = n * u.pv
        self.parado = False

    @property
    def n(self):
        return self.pool / self.u.pv

    @property
    def vivos(self):
        return math.ceil(self.pool / self.u.pv - 1e-9) if self.pool > 0 else 0


def pelea(sa, sb, us, reglas, contacto, reparto, modo="nada", dt=0.1, tmax=150):
    """sa, sb: listas de (clave, n). A arranca a la izquierda, con el primer grupo adelante."""
    A = [Grupo(us[k], n, -5 - 2 * i, 1) for i, (k, n) in enumerate(sa)]
    B = [Grupo(us[k], n, 5, -1) for k, n in sb]
    t = 0.0
    while t < tmax and any(g.pool > 0 for g in A) and any(g.pool > 0 for g in B):
        dano = []
        for mios, otros in ((A, B), (B, A)):
            for g in mios:
                if g.pool <= 0:
                    continue
                vivos_o = [o for o in otros if o.pool > 0]
                blanco = min(vivos_o, key=lambda o: abs(o.x - g.x))
                d = abs(blanco.x - g.x)
                alc = g.u.alcance + g.u.radio + blanco.u.radio
                quieto = modo == "mantener" and mios is A
                if d <= alc + 0.3:
                    frac = 1.0 if g.u.distancia else contacto
                    dano.append((blanco, g.n * frac * dps(g.u, blanco.u, reglas)))
                elif not quieto:
                    paso = g.u.vel * dt
                    g.x += paso if blanco.x > g.x else -paso
        # Ningún grupo de B atraviesa a la línea de A: si el frente de A está vivo, B se para ahí.
        frente_a = next((g for g in A if g.pool > 0 and not g.u.distancia), None)
        if frente_a:
            for g in B:
                if not g.u.distancia and g.x < frente_a.x:
                    g.x = frente_a.x
        for blanco, dmg in dano:
            # `reparto` % del daño se diluye: no mata a nadie hasta el final (modela el daño
            # repartido entre varios blancos sin concentrar).
            blanco.pool -= dmg * dt * (100 - reparto * 0.5) / 100
        t += dt
    return t, A, B


def mostrar(nombre, sa, sb, us, reglas, contacto, reparto, modo="nada"):
    t, A, B = pelea(sa, sb, us, reglas, contacto, reparto, modo)
    va = sum(g.vivos for g in A)
    vb = sum(g.vivos for g in B)
    na = sum(g.n0 for g in A)
    nb = sum(g.n0 for g in B)
    print(f"{nombre} | {t:.1f} s | {va}/{na} | {vb}/{nb}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--parche")
    ap.add_argument("--edad", type=int, default=2)
    ap.add_argument("--contacto", type=float, default=0.6, help="fracción de cuerpo a cuerpo que pega a la vez")
    ap.add_argument("--reparto", type=float, default=40, help="%% del daño que se reparte sin matar")
    ap.add_argument("--latencia", type=float, default=0.3)
    args = ap.parse_args()
    reglas, unidades, edades = cargar(args.parche)
    us = {k: Unidad(k, unidades[k], reglas, args.edad, edades) for k in ("guerrero", "hondero", "lancero", "jinete")}
    for k in unidades:
        if k not in us and isinstance(unidades[k], dict) and unidades[k].get("funcion") in ("choque", "distancia", "linea") and k != "arcabucero":
            us[k] = Unidad(k, unidades[k], reglas, args.edad, edades)
    print(f"# modelo_micro · edad {args.edad} · parche {args.parche or 'ninguno'} · contacto {args.contacto} · reparto {args.reparto} %")
    print(f"# bonos {json.dumps(reglas.get('bonos', {}), ensure_ascii=False)}")
    print()
    tabla_pares(us, reglas)
    tabla_kiteo(us, reglas, args.latencia)
    print("## Peleas de grupo (1D, sin micro salvo donde se dice)")
    print("pelea | tiempo | A vivos | B vivos")
    c, r = args.contacto, args.reparto
    for nombre, sa, sb, modo in [
        ("guerrero:10 contra guerrero:10", [("guerrero", 10)], [("guerrero", 10)], "nada"),
        ("hondero:10 contra guerrero:10", [("hondero", 10)], [("guerrero", 10)], "nada"),
        ("hondero:10 contra lancero:10", [("hondero", 10)], [("lancero", 10)], "nada"),
        ("guerrero:10 contra lancero:10", [("guerrero", 10)], [("lancero", 10)], "nada"),
        ("jinete:5 contra hondero:10", [("jinete", 5)], [("hondero", 10)], "nada"),
        ("lancero:10 contra jinete:5", [("lancero", 10)], [("jinete", 5)], "nada"),
        ("lancero:5+hondero:5 contra guerrero:10", [("lancero", 5), ("hondero", 5)], [("guerrero", 10)], "nada"),
        ("lancero:5+hondero:5 contra guerrero:10, mantener", [("lancero", 5), ("hondero", 5)], [("guerrero", 10)], "mantener"),
        ("lancero:5+hondero:5 contra jinete:5", [("lancero", 5), ("hondero", 5)], [("jinete", 5)], "nada"),
        ("lancero:5+hondero:5 contra lancero:10", [("lancero", 5), ("hondero", 5)], [("lancero", 10)], "nada"),
    ]:
        mostrar(nombre, sa, sb, us, reglas, c, r, modo)
    for k in us:
        if k not in ("guerrero", "hondero", "lancero", "jinete") and us[k].distancia:
            n = 10 // us[k].pob
            mostrar(f"{k}:{n} contra guerrero:10", [(k, n)], [("guerrero", 10)], us, reglas, c, r)


if __name__ == "__main__":
    main()
