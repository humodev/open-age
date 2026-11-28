"""Fila de la tabla del README por modelo: tabla.py <civ>_<unidad> ..."""
import os
import re
import sys
R = "/mnt/games/01_Projects/open-age"
P = R + "/.cache/meshy_soldados/proc"
for x in sys.argv[1:]:
    t = re.search(r"triangulos \S+ (\d+)", open(f"{P}/{x}_opt.log").read()).group(1)
    sp = re.search(r"vertices_sin_peso=(\d+)", open(f"{P}/{x}_rig.log").read()).group(1)
    m = re.search(r"([0-9.]+)% de la superficie, luz_ref=([0-9.]+)", open(f"{P}/{x}_mascara.log").read())
    mb = os.path.getsize(f"{R}/assets/generados/modelos/meshy_soldados/{x}.glb") / 1e6
    tt = f"{int(t):,}".replace(",", ".")
    print(f"| `{x}` | {tt} | {sp} | {float(m.group(1)):.0f} % | {m.group(2).replace('.', ',')} | {str(round(mb, 1)).replace('.', ',')} MB |")
