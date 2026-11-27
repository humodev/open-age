#!/usr/bin/env python3
"""Conecta los edificios del pipeline local de un pueblo (proceso/58-edificios-locales).

    python3 tools/conectar_edificios_locales.py <pueblo> [--sin tipo1,tipo2] [--solo tipo1,...]

Por cada pieza del proceso 58 de ese pueblo cuyo GLB exista, pone en data/civs/<pueblo>.json →
estilo.modelos la línea "<tipo>": "local/<pueblo>_<tipo>" (un renglón por edificio; se vuelve atrás
borrándolo). --sin deja esos tipos como estaban (modelos que salieron mal: candidatos a Meshy).
Edita el JSON como texto, solo dentro de "modelos", para no tocar el resto del archivo.
"""
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
civ = sys.argv[1]
sin = set(sys.argv[sys.argv.index("--sin") + 1].split(",")) if "--sin" in sys.argv else set()
solo = set(sys.argv[sys.argv.index("--solo") + 1].split(",")) if "--solo" in sys.argv else None
piezas = json.loads((REPO / "data/gen3d_piezas.json").read_text())["piezas"]
f = REPO / f"data/civs/{civ}.json"
txt = f.read_text()
m = re.search(r'("modelos"\s*:\s*\{)(.*?)(\n?\s*\})', txt, re.S)
modelos = json.loads("{" + m.group(2) + "}")
for k, p in piezas.items():
    if p.get("proceso") != "58" or p["civ"] != civ:
        continue
    tipo = k[len(civ) + 1:].removesuffix("_rojo")
    if tipo in sin or (solo is not None and tipo not in solo):
        continue
    if (REPO / p["destino"]).exists():
        modelos[tipo] = "local/" + Path(p["destino"]).stem
ind = re.search(r'\n(\s*)"modelos"', txt).group(1)
cuerpo = ",".join(f'\n{ind} {json.dumps(a, ensure_ascii=False)}: {json.dumps(b, ensure_ascii=False)}' for a, b in modelos.items())
txt = txt[:m.start()] + f'"modelos": {{{cuerpo}\n{ind}}}' + txt[m.end():]
json.loads(txt)
f.write_text(txt)
print(civ, len(modelos), "modelos")
