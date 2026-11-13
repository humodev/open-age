#!/usr/bin/env python3
"""Modelos 3D con Meshy: texto → imagen de concepto aislada → multi-image-to-3d (C-03).

    python3 tools/generar_modelos.py            # genera lo que falte
"""
import subprocess, sys, os
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STYLE = ("Stylized 3D game asset for a historical real-time strategy game, miniature diorama look, matte hand-painted "
         "textures, soft natural colors, clean readable silhouette, single isolated object centered on a plain white "
         "background, three-quarter view from slightly above, no ground plane, no people, no text")
ASSETS = {
    "tawantinsuyu_centro": "an Inca administrative compound of the 15th century: fitted stone walls with trapezoidal doorways and niches, a large rectangular hall with a steep hip roof of golden thatch, a small stone platform in front, square footprint",
    "mapuches_lof": "a Mapuche family homestead of the 16th century: a large oval ruka house with a thick thatched roof reaching the ground, a small door, a woven wooden fence around it and a carved wooden post, square footprint",
    "guaranies_centro": "a Guarani communal long house of the 16th century: a very long house with a thatched gable roof that reaches the ground, wooden posts, two small doors, square footprint",
    "etiopia_centro": "an Ethiopian royal camp centerpiece of the 16th century: a large richly decorated royal tent with red and white fabric, surrounded by smaller white tents and a round thatched tukul, square footprint",
    "palmares_centro": "a fortified quilombo village of the 17th century in Brazil: palm-thatched wattle-and-daub houses inside a ring of sharpened wooden palisade stakes with a gate, square footprint",
    "ayutthaya_centro": "a Siamese royal palace hall of the 17th century: whitewashed walls on a raised platform, steep multi-tiered red roofs with golden finials and curved gable ornaments, square footprint",
    "ayutthaya_elefante": "a war elephant of 17th-century Siam with an ornate wooden howdah, red and gold cloth, ivory tusks, walking pose, side three-quarter view",
    "mapuches_jinete": "a Mapuche lancer on a brown horse in the late 16th century, rider in a woven poncho with a silver headband holding a long cane lance, horse in walking pose",
}


def sh(args):
    r = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "meshy_api.py")] + args, capture_output=True, text=True)
    return (r.stdout.strip().splitlines() or ["?"])[-1] + r.stderr.strip()[-300:]


def make(name, desc):
    img = os.path.join(ROOT, "assets", "generados", "conceptos", name + ".png")
    raw = os.path.join(ROOT, ".cache", "meshy", "modelos", name + ".glb")
    glb = os.path.join(ROOT, "assets", "generados", "modelos", name + ".glb")
    out = []
    if not os.path.exists(img):
        out.append(sh(["imagen", img, "nano-banana-2", STYLE + ". Subject: " + desc + ".", "--aspect=1:1", "--fondo"]))
    if not os.path.exists(raw) and not os.path.exists(glb):
        out.append(sh(["modelo", raw, img, "--poli=9000"]))
    if os.path.exists(raw) and not os.path.exists(glb):
        tris = "30000" if name.endswith("centro") or name.endswith("lof") else "15000"
        subprocess.run(["blender", "--background", "--python", os.path.join(ROOT, "tools", "optimizar_glb.py"), "--", raw, glb, tris, "1024"], capture_output=True)
        out.append("optimizado")
    return name + ": " + " | ".join(out)


if __name__ == "__main__":
    with ThreadPoolExecutor(8) as ex:
        for line in ex.map(lambda kv: make(*kv), ASSETS.items()):
            print(line, flush=True)
