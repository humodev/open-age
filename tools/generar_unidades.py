#!/usr/bin/env python3
"""Modelos de unidades con Meshy: aldeanos y unidades características (proceso/19-arte-y-sonido).

Mismo flujo que generar_naturaleza.py (texto → concepto aislado → multi-image-to-3d), con
una etapa para revisar los conceptos antes de pagar el 3D:

    python3 tools/generar_unidades.py imagenes [nombres]   # conceptos (6 créditos c/u)
    python3 tools/generar_unidades.py modelos [nombres]    # 3D con remesh incluido (30 c/u) y optimizado
    python3 tools/generar_unidades.py remesh [nombres]     # remesh aparte (5 c/u), si el 3D no lo trajo
    python3 tools/generar_unidades.py optimizar [nombres]  # vuelve a optimizar desde los crudos de .cache/

Se ven decenas a la vez: de 1500 a 3000 triángulos y texturas de 512 px.
"""
import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONCEPTOS = os.path.join(ROOT, "assets", "generados", "conceptos")
CRUDOS = os.path.join(ROOT, ".cache", "meshy", "modelos")
SALIDA = os.path.join(ROOT, "assets", "generados", "modelos")

# El mismo estilo del jinete mapuche y el elefante (proceso/08), sin "diorama", que trae bases.
STYLE = ("Stylized 3D game character for a historical real-time strategy game, matte hand-painted textures, "
         "soft natural colors, chunky readable proportions with slightly large hands and head, clean silhouette, "
         "exactly one single character, full body from head to feet, standing upright in a relaxed neutral pose "
         "facing three-quarter front, legs slightly apart, arms a little away from the body, tool held close to "
         "the body, isolated and centered on a plain white background, three-quarter view from slightly above, "
         "standing on nothing: no base, no pedestal, no platform, no ground, no shadow, no other people, no text")

STYLE_MONTADO = ("Stylized 3D game asset for a historical real-time strategy game, matte hand-painted textures, "
                 "soft natural colors, clean readable silhouette, exactly one rider on one horse, horse in walking "
                 "pose, isolated and centered on a plain white background, three-quarter view from slightly above, "
                 "standing on nothing: no base, no pedestal, no ground, no shadow, no other people, no text")

# nombre: (descripción, triángulos finales, montado)
ASSETS = {
    # Aldeanos
    "tawantinsuyu_aldeano": ("an Andean Inca commoner farmer of the 15th century: knee-length woven wool tunic with a "
                             "band of small geometric squares at the waist, a brown wool mantle knotted on one shoulder, "
                             "a simple red woven headband, leather sandals, a small striped coca bag at the hip, "
                             "carrying a wooden foot plough with a footrest over one shoulder", 2400, False),
    "mapuches_aldeano": ("a Mapuche commoner of the 16th century in southern Chile: a dark grey woven wool poncho "
                         "with a stepped geometric pattern in red and white, a woven wool waist wrap, a woven "
                         "headband, barefoot, holding a wooden digging hoe in one hand and a small woven basket in "
                         "the other", 2400, False),
    "guaranies_aldeano": ("a Guarani commoner of the 16th century: bare chest with red urucum body paint lines, a short "
                          "white cotton wrap at the waist, a headband of red and yellow feathers, a string of seeds "
                          "around the neck, barefoot, holding a long wooden digging stick and carrying a woven palm "
                          "basket on the back", 2400, False),
    "etiopia_aldeano": ("an Ethiopian highland farmer of the 16th century: a white cotton shamma wrap draped over "
                        "the shoulders with a thin colored woven border, white knee-length trousers, barefoot, short "
                        "hair, holding a curved iron sickle in one hand and a long wooden staff in the other",
                        2400, False),
    "palmares_aldeano": ("a free Afro-Brazilian farmer of the 17th-century quilombo of Palmares: a loose undyed cotton "
                         "shirt and knee-length trousers, a patterned ochre cloth head wrap, a cloth sash at the "
                         "waist, barefoot, carrying an iron hoe with a wooden handle over one shoulder and a woven "
                         "basket of cassava roots at the hip", 2400, False),
    "ayutthaya_aldeano": ("a Siamese commoner farmer of 17th-century Ayutthaya: a dark indigo wrapped lower garment "
                          "tucked between the legs like knee breeches, a loose short-sleeved light cotton shirt, a "
                          "checkered cloth sash over one shoulder, a wide conical woven palm hat, barefoot, carrying "
                          "a wooden hoe over one shoulder", 2400, False),
    # Unidades características sin modelo
    "tawantinsuyu_hondero": ("an Inca slinger warrior of the 15th century: a checkerboard black and white woven "
                             "tunic, a padded cotton vest, a red headband with a small feather, leather sandals, a "
                             "braided wool sling held in the right hand and a pouch of round stones at the hip",
                             2600, False),
    "guaranies_arquero": ("a Guarani archer of the 16th century: bare chest with black and red body paint, a short "
                          "white cotton wrap at the waist, a crown of red and yellow parrot feathers, a tall wooden "
                          "longbow held vertically in the left hand and a bundle of long cane arrows in the right "
                          "hand, barefoot", 2600, False),
    "etiopia_jinete": ("a 16th-century Ethiopian noble horseman: rider wearing a lion-mane cape over a white cotton "
                       "shamma and a red silk tunic, holding a long spear upright and a round embossed hide shield, "
                       "riding a grey horse with a red and gold embroidered saddle cloth and tasseled bridle",
                       3000, True),
    "palmares_flecheiro": ("a flecheiro archer of the 17th-century quilombo of Palmares: bare chest, knee-length "
                           "cotton trousers, a red cloth head wrap, a quiver of arrows on the back, holding a wooden "
                           "bow vertically in the left hand, barefoot", 2600, False),
}


def sh(args):
    r = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "meshy_api.py")] + args, capture_output=True, text=True)
    return (r.stdout.strip().splitlines() or ["?"])[-1] + r.stderr.strip()[-300:]


def imagen(name):
    desc, _, montado = ASSETS[name]
    img = os.path.join(CONCEPTOS, name + ".png")
    if os.path.exists(img):
        return name + ": concepto ya existe"
    style = STYLE_MONTADO if montado else STYLE
    return name + ": " + sh(["imagen", img, "nano-banana-2", style + ". Subject: " + desc + ".", "--aspect=1:1", "--fondo"])


def tarea_3d(name):
    tid = None
    for line in open(os.path.join(ROOT, "assets", "generados", "registro.jsonl")):
        d = json.loads(line)
        if d.get("tarea") == "multi-image-to-3d" and d.get("salida", "").endswith("/modelos/%s.glb" % name):
            tid = d["id"]
    return tid


def remesh(name):
    out = os.path.join(CRUDOS, name + "_remesh.glb")
    if os.path.exists(out):
        return name + ": remesh ya existe"
    tid = tarea_3d(name)
    if tid is None:
        return name + ": no encuentro la tarea 3D"
    return name + ": " + sh(["remesh", out, tid, "--poli=%d" % ASSETS[name][1]])


def optimizar(name):
    tris = ASSETS[name][1]
    raw = os.path.join(CRUDOS, name + ".glb")
    if os.path.exists(os.path.join(CRUDOS, name + "_remesh.glb")):
        raw = os.path.join(CRUDOS, name + "_remesh.glb")
    glb = os.path.join(SALIDA, name + ".glb")
    r = subprocess.run(["blender", "--background", "--python", os.path.join(ROOT, "tools", "optimizar_glb.py"),
                        "--", raw, glb, str(tris), "512", "solo_color"], capture_output=True, text=True)
    cuenta = [l for l in r.stdout.splitlines() if l.startswith("triangulos")]
    return "optimizado " + "; ".join(cuenta)


def modelo(name):
    img = os.path.join(CONCEPTOS, name + ".png")
    raw = os.path.join(CRUDOS, name + ".glb")
    glb = os.path.join(SALIDA, name + ".glb")
    if not os.path.exists(img):
        return name + ": falta el concepto"
    out = []
    if not os.path.exists(raw) and not os.path.exists(glb):
        # Remesh dentro de la misma tarea: Meshy respeta target_polycount y no cobra el remesh aparte.
        out.append(sh(["modelo", raw, img, "--poli=%d" % ASSETS[name][1], "--remesh"]))
    if os.path.exists(raw) and not os.path.exists(glb):
        out.append(optimizar(name))
    return name + ": " + (" | ".join(out) or "ya existe")


if __name__ == "__main__":
    etapa = sys.argv[1] if len(sys.argv) > 1 else "imagenes"
    nombres = sys.argv[2:] or list(ASSETS)
    f = {"imagenes": imagen, "modelos": modelo, "remesh": remesh, "optimizar": lambda n: n + ": " + optimizar(n)}[etapa]
    with ThreadPoolExecutor(6) as ex:
        for line in ex.map(f, nombres):
            print(line, flush=True)
