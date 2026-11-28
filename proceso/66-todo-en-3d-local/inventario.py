#!/usr/bin/env python3
"""Inventario de todos los edificios que el juego dibuja (proceso/66-todo-en-3d-local).

    python3 proceso/66-todo-en-3d-local/inventario.py [--md] [--json salida.json]

Por pueblo, los edificios que de verdad puede levantar o tener en el mapa:
  - los seis jugables: `construye` + los hitos de `hitos`;
  - los 12 solo de IA: el `construye` del aldeano de data/unidades.json, más fortaleza, maravilla y los
    dos hitos comunes (la IA los levanta: src/sim/sim_ai.gd), menos `sin_edificios`; con `hereda`, lo del
    pueblo base;
  - los neutrales del mapa (dueño -1): feria (tres estilos por terreno), ingenio, sitios sagrados.
Estado: `local/…` (pipeline local), `recinto/…` (armado por partes), Meshy (otro nombre),
«pieza» (muros, puertas, caminos, campos y andenes: src/game/piezas.gd) o «maqueta».
"""
import json
import sys
from pathlib import Path

R = Path(__file__).resolve().parents[2]
E = json.loads((R / "data/edificios.json").read_text())
U = json.loads((R / "data/unidades.json").read_text())
AB = json.loads((R / "data/arte_base.json").read_text())
JUGABLES = ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]
SOLO_IA = ["chankas", "caranquis", "canaris", "tupies", "invasores", "castilla", "portugal", "holanda",
           "francia", "paulistas", "adal", "birmanos"]
IA_EXTRA = ["fortaleza", "hito_economia", "hito_guerra", "maravilla"]


def civ_file(k):
    c = json.loads((R / f"data/civs/{k}.json").read_text())
    base = c.get("hereda", "")
    if not base or base == k:
        return c
    out = civ_file(base)
    for kk, v in c.items():
        if kk in ("unidades", "edificios") and isinstance(out.get(kk), dict):
            for a, b in v.items():
                out[kk][a] = {**out[kk].get(a, {}), **b} if isinstance(out[kk].get(a), dict) else b
        else:
            out[kk] = v
    out.pop("hereda", None)
    return out


def defn(c, t):
    b = dict(E.get(t, {}))
    b.update(c.get("edificios", {}).get(t, {}))
    b.update(c.get("edificios_nuevos", {}).get(t, {}))
    return b


def es_pieza(b):
    return bool(b.get("camino") or b.get("linea") or b.get("puerta") or b.get("solo_sobre") or "fuente" in b)


def estado(m, b):
    if es_pieza(b):
        return "pieza"
    if not m:
        return "maqueta"
    if m.startswith("recinto/"):
        return "recinto"
    if m.startswith("local/"):
        return "local"
    return "meshy"


def tipos_de(k, c):
    if k in JUGABLES:
        return list(dict.fromkeys(list(c["construye"]) + [t for f in c["hitos"] for t in f]))
    sin = set(c.get("sin_edificios", []))
    ts = list(U["aldeano"]["construye"]) + IA_EXTRA
    return [t for t in dict.fromkeys(ts) if t not in sin and (t in E or t in c.get("edificios_nuevos", {}))]


def neutrales():
    mods = AB.get("modelos_neutrales", {})
    out = []
    for t, est in [("mercado_neutral", "feria"), ("mercado_neutral", "puerto"), ("mercado_neutral", "altura"),
                   ("ingenio", ""), ("sitio_sagrado", ""), ("sitio_lalibela", "")]:
        clave = f"{t}_{est}" if est else t
        m = mods.get(clave, "")
        b = E[t]
        out.append({"tipo": clave, "nombre": b["nombre"] + (f" ({est})" if est else ""),
                    "huella": "×".join(map(str, b["tam"])), "modelo": m, "estado": estado(m, b)})
    return out


def tabla():
    res = {}
    for k in JUGABLES + SOLO_IA:
        c = civ_file(k)
        mods = c.get("estilo", {}).get("modelos", {})
        filas = []
        for t in tipos_de(k, c):
            b = defn(c, t)
            m = mods.get(t, "")
            filas.append({"tipo": t, "nombre": b.get("nombre", t), "huella": "×".join(map(str, b.get("tam", ["?"]))),
                          "modelo": m, "estado": estado(m, b)})
        res[k] = {"nombre": c.get("nombre", k), "solo_ia": k in SOLO_IA, "filas": filas}
    res["neutral"] = {"nombre": "Neutrales del mapa", "solo_ia": False, "filas": neutrales()}
    return res


def md(res):
    out = []
    tot = {}
    for k, v in res.items():
        out.append(f"\n#### {v['nombre']} (`{k}`){' · solo IA' if v['solo_ia'] else ''}\n")
        out.append("| Tipo | Nombre | Huella | Estado | Modelo |")
        out.append("|---|---|---|---|---|")
        for f in v["filas"]:
            tot[f["estado"]] = tot.get(f["estado"], 0) + 1
            out.append(f"| `{f['tipo']}` | {f['nombre']} | {f['huella']} | {f['estado']} | {('`' + f['modelo'] + '`') if f['modelo'] else '—'} |")
    out.insert(0, "Totales: " + ", ".join(f"{a} {b}" for a, b in sorted(tot.items())))
    return "\n".join(out)


if __name__ == "__main__":
    r = tabla()
    if "--json" in sys.argv:
        Path(sys.argv[sys.argv.index("--json") + 1]).write_text(json.dumps(r, ensure_ascii=False, indent=1))
    print(md(r))
