#!/usr/bin/env python3
"""Modelos 3D con Meshy: texto → imagen de concepto aislada → multi-image-to-3d (C-03).

    python3 tools/generar_modelos.py            # genera lo que falte
"""
import subprocess, sys, os
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Sin "diorama": esa palabra traía bases y losas de terreno bajo el edificio (docs/10, paso 5).
STYLE = ("Stylized 3D game asset for a historical real-time strategy game, matte hand-painted "
         "textures, soft natural colors, clean readable silhouette, one single building at full scale, isolated and centered "
         "on a plain white background, three-quarter view from slightly above, standing directly on nothing: no base, "
         "no platform, no terrain slab, no ground, no grass, no people, no text")
ASSETS = {
    "tawantinsuyu_centro": "an Inca administrative compound of the 15th century: fitted stone walls with trapezoidal doorways and niches, a large rectangular hall with a steep hip roof of golden thatch, a small stone platform in front, square footprint",
    "mapuches_lof": "a large Mapuche ruka house of the 16th century: a big oval house with a thick thatched roof reaching the ground, a small door and a carved wooden rewe post standing beside it, square footprint",
    "guaranies_centro": "a Guarani communal long house of the 16th century: a very long house with a thatched gable roof that reaches the ground, wooden posts, two small doors, square footprint",
    "etiopia_centro": "the royal tent of a 16th-century Ethiopian emperor: one large richly decorated tent of red and white fabric with two tall poles and pennants and embroidered borders, square footprint",
    "palmares_centro": "the council house of a 17th-century quilombo in Brazil: one large rectangular wattle-and-daub building with a tall steep palm-thatched roof, wide eaves on wooden posts and a short section of sharpened palisade stakes on one side, square footprint",
    "ayutthaya_centro": "a Siamese royal palace hall of the 17th century: whitewashed walls on a raised platform, steep multi-tiered red roofs with golden finials and curved gable ornaments, square footprint",
    "ayutthaya_elefante": "a war elephant of 17th-century Siam with an ornate wooden howdah, red and gold cloth, ivory tusks, walking pose, side three-quarter view",
    "tawantinsuyu_casa": "a small Andean stone house of the 15th century: fitted grey stone walls, one trapezoidal doorway, steep hip roof of golden thatch, compact square footprint",
    "mapuches_casa": "a small Mapuche ruka house of the 16th century: an oval house with a thick thatched roof reaching the ground and one small door, compact footprint",
    "guaranies_casa": "a small Guarani house of the 16th century: an A-frame thatched roof reaching the ground, wooden posts, one door, compact footprint",
    "etiopia_casa": "a small Ethiopian highland tukul of the 16th century: round wattle-and-daub wall with a tall conical thatched roof and a small wooden finial, compact footprint",
    "palmares_casa": "a small quilombo house of the 17th century in Brazil: wattle-and-daub walls with a low palm-thatched gable roof and wide eaves, compact footprint",
    "ayutthaya_casa": "a small Siamese wooden house of the 17th century on short stilts: teak walls and a steep red tiled gable roof with curved finials, compact footprint",
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
        tris = "30000" if name.endswith("centro") or name.endswith("lof") else ("12000" if name.endswith("casa") else "15000")
        subprocess.run(["blender", "--background", "--python", os.path.join(ROOT, "tools", "optimizar_glb.py"), "--", raw, glb, tris, "1024"], capture_output=True)
        out.append("optimizado")
    return name + ": " + " | ".join(out)


if __name__ == "__main__":
    with ThreadPoolExecutor(8) as ex:
        for line in ex.map(lambda kv: make(*kv), ASSETS.items()):
            print(line, flush=True)
