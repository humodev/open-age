#!/usr/bin/env python3
"""Referencias de FLUX en lote para piezas del pipeline 3D (proceso/58-edificios-locales).

    python3 tools/gen3d_flux_lote.py --civ tawantinsuyu        las que falten de ese pueblo (proceso 58)
    python3 tools/gen3d_flux_lote.py clave1 clave2 [--rehacer]  esas piezas

Arranca ComfyUI una sola vez (arrancar_aislado.sh, scope a 12 GB, con 14 GB disponibles),
pinta con la receta de cada pieza (data/gen3d_piezas.json → referencia.receta) en la ruta de
referencia.imagen y al final libera (POST /free), apaga el scope y verifica con pgrep anclado.
Después, tools/gen3d_pipeline.py encuentra la imagen hecha y no llama a FLUX.
Para reintentar, cambiar la semilla de la receta (y la de referencia.imagen): la imagen vieja queda.
"""
import argparse
import json
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
import arte_gouache as ag  # noqa: E402 (ComfyUI: arrancar, apagar, pgrep anclado)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("piezas", nargs="*")
    ap.add_argument("--civ")
    ap.add_argument("--rehacer", action="store_true")
    ap.add_argument("--semillas", help="candidatas: genera la pieza con cada una de estas semillas (21,22)")
    ap.add_argument("--extra", action="append", default=[],
                    help="comando más (con el python de ComfyUI) a correr con ComfyUI arriba, antes de apagarlo")
    a = ap.parse_args()
    d = json.loads((REPO / "data/gen3d_piezas.json").read_text())
    comun = d["comun"]
    claves = a.piezas or [k for k, v in d["piezas"].items() if v.get("proceso") == "58" and v.get("civ") == a.civ]
    falta = []  # (clave, semilla, imagen)
    for k in claves:
        ref = d["piezas"][k]["referencia"]
        sem0 = int(ref["receta"].get("semilla", 7))
        for sem in ([int(x) for x in a.semillas.split(",")] if a.semillas else [sem0]):
            img = Path(str(ref["imagen"]).replace(f"_{sem0}.png", f"_{sem}.png"))
            if a.rehacer or not img.exists():
                falta.append((k, sem, img))
    print(len(falta), "imágenes por hacer:", " ".join(f"{k}:{s}" for k, s, _ in falta), flush=True)
    if not falta and not a.extra:
        return
    ag.comfy_arrancar()
    # MemoryHigh=10G (de arte_gouache) frena a FLUX con --cache-none en swap: 60–85 s por imagen.
    # Sin ese freno, con el tope de 12 GB igual, baja a ~30 s (proceso/58).
    for u in ag._scopes():
        subprocess.run(["systemctl", "--user", "set-property", "--runtime", u, "MemoryHigh=infinity"],
                       capture_output=True)
    try:
        for k, sem, img in falta:
            rec = d["piezas"][k]["referencia"]["receta"]
            img.parent.mkdir(parents=True, exist_ok=True)
            prefijo = str(img)[: -len(f"_{sem}.png")]
            prompt = rec["prompt"].replace("{estilo}", comun["estilo"])
            t0 = time.time()
            r = subprocess.run([ag.PY, str(REPO / "tools/generar_local.py"), prompt, "--modelo", "flux",
                                "--semilla", str(sem), "--ancho", str(rec.get("ancho", 768)),
                                "--alto", str(rec.get("alto", 768)), "--salida", prefijo],
                               capture_output=True, text=True)
            if r.returncode != 0 or not img.exists():
                print("FALLÓ", k, r.stderr[-600:], flush=True)
                continue
            print(f"{k}: {time.time() - t0:.0f} s", flush=True)
        for cmd in a.extra:
            subprocess.run([ag.PY, *cmd.split()])
    finally:
        ok = ag.comfy_apagar()
        if not ok:
            sys.exit("ComfyUI sigue vivo")


if __name__ == "__main__":
    main()
