#!/usr/bin/env python3
"""Tabla de inventario de edificios por pueblo para el README (proceso/58).

    python3 proceso/58-edificios-locales/inventario.py > /tmp/x.md

Por pueblo: cada edificio que construye el aldeano más los hitos; qué modelo usa hoy
(estilo.modelos: local/… del pipeline, Meshy, o la maqueta procedural) y qué se hizo acá.
"""
import json
from pathlib import Path

R = Path(__file__).resolve().parents[2]
E = json.loads((R / "data/edificios.json").read_text())
P = json.loads((R / "data/gen3d_piezas.json").read_text())["piezas"]
EQ = json.loads((R / "data/modelos_equipo.json").read_text())["mascaras"]
CIVS = ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]
LINEA = {"linea", "puerta", "transitable"}
# Antes de este proceso (proceso/54, C-106): casas y capitales del pipeline, el resto maqueta.
ANTES = {("tawantinsuyu", "centro"): "Meshy", ("tawantinsuyu", "cuartel"): "pipeline (kallanka, 54)",
         ("mapuches", "lof"): "Meshy"}
for c in ["tawantinsuyu", "mapuches", "guaranies", "etiopia", "palmares", "ayutthaya"]:
    ANTES.setdefault((c, "casa"), "pipeline (54)")
    if c not in ("tawantinsuyu", "mapuches"):
        ANTES[(c, "centro")] = "pipeline (54)"

for civ in CIVS:
    d = json.loads((R / f"data/civs/{civ}.json").read_text())
    mods = d["estilo"].get("modelos", {})
    tipos = list(dict.fromkeys(list(d["construye"]) + [t for fila in d["hitos"] for t in fila]))
    print(f"\n#### {d.get('nombre', civ)}\n")
    print("| Tipo | Nombre | Huella | Antes | Modelo en el juego ahora | Color | Nota |")
    print("|---|---|---|---|---|---|---|")
    for t in tipos:
        b = dict(E.get(t, {}))
        b.update(d.get("edificios", {}).get(t, {}))
        b.update(d.get("edificios_nuevos", {}).get(t, {}))
        tam = "×".join(map(str, b.get("tam", E["maravilla"]["tam"] if "maravilla" in t else ["?"])))
        m = mods.get(t, "")
        pieza = P.get(f"{civ}_{t}") or P.get(f"{civ}_{t}_rojo") or {}
        if any(b.get(k) for k in LINEA) or t == "torre_muralla":
            modelo, nota = "maqueta (tramo de muro, campo o camino)", "sin modelo: se arma por casillas"
        elif m.startswith("local/") and not m.endswith("_v1"):
            modelo, nota = f"`{m}` (pipeline, proceso 58)", ""
        elif m.endswith("_v1"):
            modelo, nota = f"`{m}` (pipeline, proceso 54)", ""
        elif m:
            modelo, nota = f"`{m}` (Meshy)", ""
        else:
            modelo, nota = "maqueta procedural", ""
        if pieza.get("meshy"):
            nota = "candidato a Meshy"
        elif pieza and not m.startswith("local/") and not nota:
            nota = "generado, sin conectar"
        color = f"{EQ[m]['cobertura']:.0%}" if m in EQ else ("estandarte" if pieza.get("rojo") is False else "—")
        antes = ANTES.get((civ, t), "maqueta")
        print(f"| `{t}` | {b.get('nombre', t)} | {tam} | {antes} | {modelo} | {color} | {nota} |")
