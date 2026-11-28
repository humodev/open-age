#!/usr/bin/env python3
"""Riggea las siluetas de los animales exportadas por tools/exportar_animales.gd
(proceso/63-montados-y-animales): una pasada de tools/gen3d_rig_cuadrupedo.py por especie, con
el tipo de su forma (data/arte_cuadrupedos.json → forma_tipo), y la tira de galope, ataque y
morir de cada forma (tools/gen3d_tiras.py).

    tools/rig_animales.py <carpeta de los .glb exportados> <carpeta de renders> [especie,...]

Blender va dentro de systemd-run con 4 GB de tope y solo con 7 GB disponibles, de a uno.
"""
import json
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
ent, rend = Path(sys.argv[1]), Path(sys.argv[2])
solo = sys.argv[3].split(",") if len(sys.argv) > 3 else []
rend.mkdir(parents=True, exist_ok=True)
esp = json.loads((REPO / "data/arte_animales.json").read_text())["especies"]
ft = json.loads((REPO / "data/arte_cuadrupedos.json").read_text())["forma_tipo"]
dest = REPO / "assets/generados/modelos/animales"
dest.mkdir(parents=True, exist_ok=True)


def disponible_gb():
    for l in open("/proc/meminfo"):
        if l.startswith("MemAvailable"):
            return int(l.split()[1]) / 1024 / 1024
    return 0


hechas = set()
for sp, e in esp.items():
    if solo and sp not in solo:
        continue
    forma = e.get("forma", "camelido")
    tipo = ft.get(forma, "buey")
    while disponible_gb() < 7:
        time.sleep(10)
    tiras = forma not in hechas
    r = subprocess.run(["systemd-run", "--user", "--scope", "-q", "-p", "MemoryMax=4G", "blender", "--background",
                        "--python", str(REPO / "tools/gen3d_rig_cuadrupedo.py"), "--", str(ent / f"{sp}.glb"),
                        str(dest / f"{sp}.glb"), str(rend / sp), f"--tipo={tipo}", "--cabeza=-y"]
                       + (["--tiras"] if tiras else []), capture_output=True, text=True)
    linea = [l for l in r.stdout.splitlines() if l.startswith("RIG tipo")]
    print(sp, tipo, linea[-1] if linea else r.stdout[-600:] + r.stderr[-600:])
    if tiras and linea:
        hechas.add(forma)
        subprocess.run([sys.executable, str(REPO / "tools/gen3d_tiras.py"), str(rend / sp),
                        str(rend / f"tira_{forma}.jpg"), f"{sp} ({tipo})"])
