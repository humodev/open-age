#!/usr/bin/env python3
"""Resumen de tools/bancos.gd (proceso/26, 09): banco sin gastar por minuto, gasto por destino y
por edad, y de dónde sale la riqueza.

Uso: python3 tools/bancos_resumen.py salida1.txt [salida2.txt ...] [--dificultad=experta] [--solo-de=otra.txt]
"""
import json
import sys
from collections import defaultdict

RES = ["alimento", "madera", "riqueza", "piedra"]
CATS = ["aldeanos", "tropa", "edificios", "hitos", "economia", "herreria", "niveles", "otras_tec", "mercado", "otros"]
EDADES = ["I", "II", "III", "IV"]


def cargar(paths, diff):
    out = []
    for p in paths:
        for line in open(p, encoding="utf-8"):
            if line.startswith("JSON "):
                j = json.loads(line[5:])
                if diff is None or j["dificultad"] == diff:
                    out.append(j)
    return out


def gastado(m):
    """Gasto acumulado por destino y recurso, con «otros» por diferencia con el libro."""
    g = {c: {r: m["gastado"].get(c, {}).get(r, 0) for r in RES} for c in CATS if c != "otros"}
    total = {}
    for r in RES:
        juntado = sum(v for k, v in m["origen"].items() if k.endswith(":" + r))
        total[r] = m["inicial"].get(r, 0) + juntado - m["banco"][r]
    g["otros"] = {r: total[r] - sum(g[c][r] for c in g) for r in RES}
    return g


def tabla(filas, cab):
    print("| " + " | ".join(cab) + " |")
    print("|" + "---|" * len(cab))
    for f in filas:
        print("| " + " | ".join(str(x) for x in f) + " |")
    print()


def main():
    paths = [a for a in sys.argv[1:] if not a.startswith("--")]
    diff = None
    solo = None
    for a in sys.argv[1:]:
        if a.startswith("--dificultad="):
            diff = a.split("=")[1]
        elif a.startswith("--solo-de="):
            solo = a.split("=", 1)[1]
    js = cargar(paths, diff)
    if solo:
        # Solo las partidas que también están en otra medición (antes y después, mismos cruces).
        clave = lambda j: (j["civ"], j["rival"], j["semilla"], j["dificultad"])
        otras = {clave(j) for j in cargar([solo], diff)}
        js = [j for j in js if clave(j) in otras]
    n = len(js)
    print(f"Jugadores: {n} ({diff or 'todas las dificultades'})\n")

    # 0. Edades y riqueza ociosa en la II (lo que el hito III pide de riqueza ya está y espera).
    def mediana(v):
        v = sorted(v)
        return f"{v[len(v) // 2]:.1f}" if v else "–"
    a2 = [int(j["edades"]["2"]) / 600 for j in js if "2" in j["edades"]]
    a3 = [int(j["edades"]["3"]) / 600 for j in js if "3" in j["edades"]]
    a4 = [int(j["edades"]["4"]) / 600 for j in js if "4" in j["edades"]]
    listo = [next(m["t"] for m in j["min"] if m["edad"] == 2 and m["banco"]["riqueza"] >= 600)
             for j in js if any(m["edad"] == 2 and m["banco"]["riqueza"] >= 600 for m in j["min"])]
    m2 = [m for j in js for m in j["min"] if m["edad"] == 2]
    ocioso = sum(1 for m in m2 if m["banco"]["riqueza"] >= 400)
    print("### Edades y riqueza ociosa en la II\n")
    tabla([[f"{mediana(a2)} ({len(a2)})", f"{mediana(a3)} ({len(a3)})", len(a4), f"{mediana(listo)} ({len(listo)})",
            f"{ocioso}/{len(m2)} ({100 * ocioso / max(1, len(m2)):.0f} %)"]],
          ["II: minuto (jugadores)", "III", "IV (jugadores)", "600 de riqueza en la II: minuto", "minutos de la II con 400 o más de riqueza"])

    # 1. Banco sin gastar por minuto (promedio de los jugadores que siguen en la partida).
    print("### Banco sin gastar (promedio por jugador)\n")
    filas = []
    for t in [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 25]:
        ms = [m for j in js for m in j["min"] if m["t"] == t]
        if not ms:
            continue
        edad = sum(m["edad"] for m in ms) / len(ms)
        filas.append([t, len(ms), f"{edad:.1f}"] + [round(sum(m["banco"][r] for m in ms) / len(ms)) for r in RES])
    tabla(filas, ["min", "jugadores", "edad media"] + RES)

    # 2. Banco medio por edad (promedio de los minutos que cada jugador pasó en esa edad).
    print("### Banco medio mientras se está en cada edad\n")
    filas = []
    for e in range(1, 5):
        ms = [m for j in js for m in j["min"] if m["edad"] == e]
        if not ms:
            continue
        filas.append([EDADES[e - 1], len(ms)] + [round(sum(m["banco"][r] for m in ms) / len(ms)) for r in RES])
    tabla(filas, ["edad", "minutos-jugador"] + RES)

    # 3. Gasto por destino y por edad (incrementos de cada minuto, según la edad de ese minuto).
    por_edad = defaultdict(lambda: defaultdict(lambda: defaultdict(int)))
    minutos = defaultdict(int)
    juntado_edad = defaultdict(lambda: defaultdict(int))
    for j in js:
        prev_g = {c: {r: 0 for r in RES} for c in CATS}
        prev_o = {}
        for m in j["min"]:
            g = gastado(m)
            e = m["edad"]
            minutos[e] += 1
            for c in CATS:
                for r in RES:
                    por_edad[e][c][r] += g[c][r] - prev_g[c][r]
            for k, v in m["origen"].items():
                juntado_edad[e][k] += v - prev_o.get(k, 0)
            prev_g, prev_o = g, dict(m["origen"])
    print("### Gasto por destino en cada edad (por jugador y por minuto en esa edad)\n")
    for e in range(1, 5):
        if not minutos[e]:
            continue
        print(f"Edad {EDADES[e - 1]} ({minutos[e]} minutos-jugador)\n")
        filas = []
        tot = {r: sum(por_edad[e][c][r] for c in CATS) for r in RES}
        for c in CATS:
            row = [c]
            for r in RES:
                v = por_edad[e][c][r] / minutos[e]
                pct = 100 * por_edad[e][c][r] / tot[r] if tot[r] else 0
                row.append(f"{v:.0f} ({pct:.0f} %)" if abs(v) >= 0.5 else "–")
            filas.append(row)
        filas.append(["**total gastado**"] + [f"{tot[r] / minutos[e]:.0f}" for r in RES])
        jun = {r: sum(v for k, v in juntado_edad[e].items() if k.endswith(":" + r)) for r in RES}
        filas.append(["**juntado**"] + [f"{jun[r] / minutos[e]:.0f}" for r in RES])
        tabla(filas, ["destino"] + RES)

    # 4. Riqueza: de dónde sale, por edad.
    print("### Riqueza juntada por origen (por jugador y por minuto en esa edad)\n")
    origenes = sorted({k for e in juntado_edad for k in juntado_edad[e] if k.endswith(":riqueza")})
    filas = []
    for e in range(1, 5):
        if not minutos[e]:
            continue
        filas.append([EDADES[e - 1]] + [f"{juntado_edad[e][k] / minutos[e]:.0f}" for k in origenes])
    tabla(filas, ["edad"] + [k.split(":")[0] for k in origenes])

    # 5. Por pueblo: riqueza juntada, gastada y en el banco al final; gasto de riqueza por destino.
    print("### Por pueblo, al minuto 25 (o al final), promedio por jugador\n")
    porciv = defaultdict(list)
    for j in js:
        porciv[j["civ"]].append(j)
    filas = []
    for civ in sorted(porciv):
        ls = [j["min"][-1] for j in porciv[civ]]
        k = len(ls)
        jun = sum(sum(v for kk, v in m["origen"].items() if kk.endswith(":riqueza")) for m in ls) / k
        gs = [gastado(m) for m in ls]
        dest = {c: sum(g[c]["riqueza"] for g in gs) / k for c in CATS}
        banco = {r: sum(m["banco"][r] for m in ls) / k for r in RES}
        top = sorted(dest.items(), key=lambda x: -x[1])[:4]
        ed = [j["edades"] for j in porciv[civ]]
        def med(key):
            v = sorted(int(x[key]) / 600 for x in ed if key in x)
            return f"{v[len(v) // 2]:.1f} ({len(v)}/{k})" if v else "–"
        filas.append([civ, k, med("2"), med("3"), med("4"), round(jun), round(banco["riqueza"]), round(banco["alimento"]), round(banco["madera"]), round(banco["piedra"]),
                      ", ".join(f"{c} {v:.0f}" for c, v in top if v > 0)])
    tabla(filas, ["pueblo", "jug.", "II (min)", "III", "IV", "riqueza juntada", "banco riqueza", "banco alimento", "banco madera", "banco piedra", "riqueza gastada en"])


if __name__ == "__main__":
    main()
