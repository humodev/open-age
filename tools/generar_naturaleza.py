#!/usr/bin/env python3
"""Modelos del paisaje con Meshy: árboles, arbustos, rocas, arcilla y peñascos (proceso/16-paisaje).

Mismo flujo que generar_modelos.py (texto → concepto aislado → multi-image-to-3d), con
una etapa intermedia para revisar los conceptos antes de gastar en el 3D:

    python3 tools/generar_naturaleza.py imagenes      # solo los conceptos (6 créditos c/u)
    python3 tools/generar_naturaleza.py modelos       # 3D de los conceptos aprobados (30 c/u) y optimizado
    python3 tools/generar_naturaleza.py remesh        # rehace en Meshy las mallas finas (5 c/u), ver REMESH
    python3 tools/generar_naturaleza.py optimizar     # vuelve a optimizar desde los crudos de .cache/

Son miles de instancias en MultiMesh: el presupuesto es bajo (árboles y arbustos de 600 a
1500 triángulos, rocas y arcilla hasta 3000, texturas de 256 a 512 px).
"""
import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONCEPTOS = os.path.join(ROOT, "assets", "generados", "conceptos", "naturaleza")
CRUDOS = os.path.join(ROOT, ".cache", "meshy", "naturaleza")
SALIDA = os.path.join(ROOT, "assets", "generados", "naturaleza")

STYLE = ("Stylized low-poly 3D game asset for a historical real-time strategy game, matte hand-painted textures, "
         "soft natural colors, chunky faceted shapes, clean readable silhouette, one single object at full scale, "
         "isolated and centered on a plain white background, three-quarter view from slightly above, floating on "
         "nothing: no base, no platform, no ground, no soil disc, no grass, no shadow, no people, no text")

# nombre: (descripción, polígonos pedidos a Meshy, triángulos finales, textura px)
ASSETS = {
    "pino": ("an Andean cypress tree: a straight brown trunk and a tall narrow conical crown of dense dark green "
             "foliage built from a few chunky stacked clumps", 3000, 1200, 512),
    "latifoliada": ("a broadleaf South American forest tree: a sturdy brown trunk that forks into two branches and a "
                    "full rounded crown made of several chunky leafy clumps in fresh green", 3000, 1400, 512),
    "araucaria": ("an araucaria monkey-puzzle tree: a tall straight grey-brown trunk, bare below, and at the top "
                  "horizontal whorls of upward-curving branches forming a flat umbrella-shaped dark green crown",
                  3000, 1400, 512),
    "palmera": ("a pindo palm tree: a slender slightly curved grey trunk with ring marks and a crown of long arching "
                "feathery green fronds, a small hanging cluster of orange fruits under the crown", 3000, 1300, 512),
    "copa_plana": ("a gnarled highland queñua tree: a short twisted reddish-brown trunk leaning slightly, spreading "
                   "crooked branches and a wide flat layered canopy of small olive green leaves", 3000, 1300, 512),
    "arbusto": ("a low round cluster of wild shrubs about knee height: dense green leaves dotted with many bright "
                "red and purple berries clearly visible all over", 2000, 800, 256),
    "roca": ("a stone outcrop for quarrying: a cluster of several large angular grey granite boulders of different "
             "sizes with a few split rectangular blocks, compact rounded-square footprint", 4000, 2400, 512),
    "arcilla": ("a pottery clay pit: a low mound of wet reddish-orange clay with a shallow dug hollow and a wooden "
                "digging stick, and beside it a stack of finished terracotta pots and round jars of different sizes, "
                "two jars lying on their side; the clay mound is the object itself, with no grass around it",
                5000, 3000, 512),
    "penasco": ("a large weathered rock crag: one massive blocky boulder of grey-brown stone with flat fractured "
                "faces and deep cracks, irregular, a little wider than tall", 3000, 1800, 512),
    "yerbal": ("a small grove of yerba mate: three bushy small trees with glossy dark green leaves and thin pale "
               "grey trunks growing close together, a woven basket full of harvested leaves at their foot",
               4000, 2400, 512),
}

# Hojas finas, frondas y bayas: el diezmado de Blender se come los troncos y deja astillas
# (proceso/16-paisaje). A estos se les pide a Meshy una malla nueva con pocos polígonos.
REMESH = {"palmera": 1500, "araucaria": 1500, "copa_plana": 1400, "arbusto": 1000, "yerbal": 2500}


def sh(args):
    r = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "meshy_api.py")] + args, capture_output=True, text=True)
    return (r.stdout.strip().splitlines() or ["?"])[-1] + r.stderr.strip()[-300:]


def imagen(name):
    desc = ASSETS[name][0]
    img = os.path.join(CONCEPTOS, name + ".png")
    if os.path.exists(img):
        return name + ": concepto ya existe"
    os.makedirs(CONCEPTOS, exist_ok=True)
    return name + ": " + sh(["imagen", img, "nano-banana-2", STYLE + ". Subject: " + desc + ".", "--aspect=1:1", "--fondo"])


def tarea_3d(name):
    """Id de la tarea multi-image-to-3d que hizo el modelo (assets/generados/registro.jsonl)."""
    tid = None
    for line in open(os.path.join(ROOT, "assets", "generados", "registro.jsonl")):
        d = json.loads(line)
        if d.get("tarea") == "multi-image-to-3d" and d.get("salida", "").endswith("/naturaleza/%s.glb" % name):
            tid = d["id"]
    return tid


def remesh(name):
    out = os.path.join(CRUDOS, name + "_remesh.glb")
    if name not in REMESH:
        return name + ": no lleva remesh"
    if os.path.exists(out):
        return name + ": remesh ya existe"
    tid = tarea_3d(name)
    if tid is None:
        return name + ": no encuentro la tarea 3D"
    return name + ": " + sh(["remesh", out, tid, "--poli=%d" % REMESH[name]])


def optimizar(name):
    _, _, tris, tex = ASSETS[name]
    raw = os.path.join(CRUDOS, name + ".glb")
    if os.path.exists(os.path.join(CRUDOS, name + "_remesh.glb")):
        raw = os.path.join(CRUDOS, name + "_remesh.glb")
    glb = os.path.join(SALIDA, name + ".glb")
    os.makedirs(SALIDA, exist_ok=True)
    r = subprocess.run(["blender", "--background", "--python", os.path.join(ROOT, "tools", "optimizar_glb.py"),
                        "--", raw, glb, str(tris), str(tex), "solo_color"], capture_output=True, text=True)
    cuenta = [l for l in r.stdout.splitlines() if l.startswith("triangulos")]
    return "optimizado " + "; ".join(cuenta)


def modelo(name):
    _, poli, _, _ = ASSETS[name]
    img = os.path.join(CONCEPTOS, name + ".png")
    raw = os.path.join(CRUDOS, name + ".glb")
    glb = os.path.join(SALIDA, name + ".glb")
    if not os.path.exists(img):
        return name + ": falta el concepto"
    out = []
    if not os.path.exists(raw) and not os.path.exists(glb):
        out.append(sh(["modelo", raw, img, "--poli=%d" % poli]))
    if os.path.exists(raw) and not os.path.exists(glb):
        out.append(optimizar(name))
    return name + ": " + (" | ".join(out) or "ya existe")


if __name__ == "__main__":
    etapa = sys.argv[1] if len(sys.argv) > 1 else "imagenes"
    nombres = sys.argv[2:] or (list(REMESH) if etapa == "remesh" else list(ASSETS))
    f = {"imagenes": imagen, "modelos": modelo, "remesh": remesh, "optimizar": lambda n: n + ": " + optimizar(n)}[etapa]
    with ThreadPoolExecutor(6) as ex:
        for line in ex.map(f, nombres):
            print(line, flush=True)
