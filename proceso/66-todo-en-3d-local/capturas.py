#!/usr/bin/env python3
"""Capturas del proceso 66: cada pueblo con sus edificios del proceso, en azul y en violeta.

    python3 proceso/66-todo-en-3d-local/capturas.py <grupo> [--antes]

Una partida real (`--demo=base_completa --tipos=…`, edad IV), con Godot en ventana, `timeout` y tope de
4 GB (y 7 GB libres). --antes: lo mismo sin los modelos (el renglón sacado), para el antes y después:
se corre antes de conectar. Las capturas quedan en proceso/66-todo-en-3d-local/img/<pueblo>_<color>.jpg.
"""
import subprocess
import sys
import time
from pathlib import Path

from PIL import Image

R = Path(__file__).resolve().parents[2]
IMG = Path(__file__).with_name("img")
SCR = Path("/tmp/claude-1000/-mnt-games-01-Projects-open-age/481c6f08-db17-4268-bf0b-14788944cecc/scratchpad/e66")
IA = "deposito,cuartel,torre,mercado,fortaleza,hito_economia,hito_guerra,maravilla,casa"
GRUPOS = {
    "sobras": [("mapuches", "corral,hoyo", ""), ("etiopia", "gult", ""), ("palmares", "hoyo", "")],
    "neutral": [("tawantinsuyu", "casa", "mercado_neutral,ingenio,sitio_sagrado,sitio_lalibela")],
    "andes": [(c, IA, "") for c in ["chankas", "caranquis", "canaris"]],
    "tupies": [("tupies", IA, "")],
    "colonial": [(c, IA, "") for c in ["invasores", "castilla", "portugal", "holanda", "francia", "paulistas"]],
    "adal": [("adal", IA, "")],
    "birmanos": [("birmanos", IA, "")],
}
COLORES = {"azul": "0,1", "violeta": "2,1"}


def libre_gb():
    for l in open("/proc/meminfo"):
        if l.startswith("MemAvailable"):
            return int(l.split()[1]) / 1048576
    return 0


def captura(civ, tipos, neutrales, color, salida, terreno="llano"):
    while libre_gb() < 7:
        time.sleep(10)
    png = SCR / f"{salida.stem}.png"
    cmd = ["timeout", "150", "systemd-run", "--user", "--scope", "-q", "-p", "MemoryMax=4G",
           "godot", "--path", str(R), "--", "--demo=base_completa", f"--civ={civ}", f"--tipos={tipos}",
           f"--colores={COLORES[color]}", "--seed=66", f"--terreno={terreno}", "--nofog", "--mute",
           f"--shot={png}", "--shot-at=5"]
    if neutrales:
        cmd.append(f"--neutrales={neutrales}")
    r = subprocess.run(cmd, capture_output=True, text=True)
    if not png.exists():
        print("FALLÓ", civ, color, r.stdout[-400:], r.stderr[-400:])
        return
    Image.open(png).convert("RGB").save(salida, quality=82)
    png.unlink()
    print(salida)


def main():
    g = sys.argv[1]
    antes = "--antes" in sys.argv
    for civ, tipos, neu in GRUPOS[g]:
        for color in (["azul"] if antes else COLORES):
            terrenos = ["llano", "rio", "montana"] if neu else ["llano"]
            for t in terrenos:
                suf = f"_{t}" if neu else ""
                captura(civ, tipos, neu, color, IMG / f"{'antes_' if antes else ''}{civ}{suf}_{color}.jpg", t)
                if neu and (antes or color == "violeta"):
                    break


if __name__ == "__main__":
    main()
