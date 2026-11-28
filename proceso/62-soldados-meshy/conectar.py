"""Conecta soldados procesados: conectar.py <civ>_<unidad> ... (lee luz_ref del log de la máscara).
Agrega la entrada en modelos.lista y la línea modelos.soldados[civ][unidad] de data/arte_animaciones.json."""
import re
import sys
R = "/mnt/games/01_Projects/open-age"
P = R + "/data/arte_animaciones.json"
s = open(P).read()
for x in sys.argv[1:]:
    civ, uni = x.split("_", 1)
    luz = re.search(r"luz_ref=([0-9.]+)", open(f"{R}/.cache/meshy_soldados/proc/{x}_mascara.log").read()).group(1)
    d = "res://assets/generados/modelos/meshy_soldados/"
    ent = f'      "sol_{x}": {{ "glb": "{d}{x}.glb", "mascara": "{d}{x}_mascara.png", "luz_ref": {luz} }},\n'
    if f'"sol_{x}"' not in s:
        i = s.index('    "lista": {\n') + len('    "lista": {\n')
        s = s[:i] + ent + s[i:]
    a = s.index('    "soldados": {\n') + len('    "soldados": {\n')
    b = s.index("\n    }", a - 1)
    lines = [l.rstrip().rstrip(",") for l in s[a:b].split("\n") if l.strip()]
    found = False
    for k, l in enumerate(lines):
        if l.strip().startswith(f'"{civ}":'):
            found = True
            if f'"{uni}"' not in l:
                l = l[:l.rindex("}")].rstrip() + f', "{uni}": "sol_{x}" }}'
            lines[k] = l
    if not found:
        lines.append(f'      "{civ}": {{ "{uni}": "sol_{x}" }}')
    s = s[:a] + ",\n".join(lines) + s[b:]
    print(x, luz)
open(P, "w").write(s)
import json
json.load(open(P))
