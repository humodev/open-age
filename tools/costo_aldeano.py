#!/usr/bin/env python3
"""Costo de cada investigación en tiempo de aldeano (proceso/26, 09).

Un cambio de costos que mueve recursos de uno a otro (madera por riqueza, por ejemplo) no tiene
que encarecer ni abaratar: lo que se compara es cuántos segundos de un aldeano hacen falta para
juntar el costo, con las tasas base de `data/unidades.json` (aldeano.tasa; el alimento con la tasa
de `alimento`, sin caminar). tools/modelo_progreso.py no lee costos: este es el control del poder
por recurso gastado.

Uso: python3 tools/costo_aldeano.py viejo/tecnologias.json [nuevo/tecnologias.json]
     (sin el segundo, el de data/)
"""
import json
import os
import sys

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
RES = ["alimento", "madera", "riqueza", "piedra"]


def main():
    viejo = json.load(open(sys.argv[1], encoding="utf-8"))
    nuevo = json.load(open(sys.argv[2] if len(sys.argv) > 2 else os.path.join(RAIZ, "data", "tecnologias.json"), encoding="utf-8"))
    tasa = json.load(open(os.path.join(RAIZ, "data", "unidades.json"), encoding="utf-8"))["aldeano"]["tasa"]

    def seg(c):
        return sum(1000 * n / tasa[r] for r, n in c.items() if r in tasa)

    def txt(c):
        return " ".join(f"{n}{r[0]}" for r, n in c.items())

    print("| Investigación | Edad | Antes | Después | s de aldeano antes | después | Δ |")
    print("|---|---|---|---|---|---|---|")
    tot = {}
    for k, t in nuevo.items():
        if k.startswith("_") or k not in viejo:
            continue
        a, d = viejo[k]["costo"], t["costo"]
        e = t.get("edad_min", 1)
        row = tot.setdefault(e, [{r: 0 for r in RES}, {r: 0 for r in RES}, 0.0, 0.0])
        for r in RES:
            row[0][r] += a.get(r, 0)
            row[1][r] += d.get(r, 0)
        row[2] += seg(a)
        row[3] += seg(d)
        if a != d:
            print(f"| {k} | {'I II III IV'.split()[e - 1]} | {txt(a)} | {txt(d)} | {seg(a):.0f} | {seg(d):.0f} | {100 * (seg(d) - seg(a)) / seg(a):+.0f} % |")
    print()
    print("Todas las investigaciones comunes, por edad (a = alimento, m = madera, r = riqueza, p = piedra):\n")
    print("| Edad | Antes | Después | s de aldeano antes | después | Δ |")
    print("|---|---|---|---|---|---|")
    ta, td = {r: 0 for r in RES}, {r: 0 for r in RES}
    for e in sorted(tot):
        a, d, sa, sd = tot[e]
        for r in RES:
            ta[r] += a[r]
            td[r] += d[r]
        print(f"| {'I II III IV'.split()[e - 1]} | {txt({r: a[r] for r in RES if a[r]})} | {txt({r: d[r] for r in RES if d[r]})} | {sa:.0f} | {sd:.0f} | {100 * (sd - sa) / sa:+.1f} % |")
    print(f"| **todas** | {txt({r: ta[r] for r in RES if ta[r]})} | {txt({r: td[r] for r in RES if td[r]})} | {seg(ta):.0f} | {seg(td):.0f} | {100 * (seg(td) - seg(ta)) / seg(ta):+.1f} % |")


if __name__ == "__main__":
    main()
