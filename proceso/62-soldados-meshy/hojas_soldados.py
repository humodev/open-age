"""Hoja de referencia de un soldado (entrada de Meshy), como hoja_aldeano_e1_31.png.

    $PY proceso/62-soldados-meshy/hojas_soldados.py <civ> <unidad> [semilla] [--ver]   (ComfyUI ya arriba)

1152×768: frente a la izquierda, espalda a la derecha, la misma ropa en las dos; pose A con las
manos vacías (el arma, el escudo y el carcaj van después como piezas en handslot.r/.l); la ropa
del equipo en rojo plano; un hombre adulto de 30 a 40 años con la cara del aldeano de su pueblo.
Ropa de guerra de la época según los historiadores (proceso/49 y proceso/42): nada sagrado, sin
estereotipos. Menos de ~180 palabras (FLUX schnell corta el prompt).
Salida: comfyui/output/<dir>_gouache/hoja_<unidad>_soldado_31.png; si ya existe, pasa a _v<n>.
"""
import json
import os
import subprocess
import sys
import time

R = "/mnt/games/01_Projects/open-age"
O = "/mnt/games/01_Projects/comfyui/output"
PY = "/mnt/games/01_Projects/comfyui/venv/bin/python"
sys.path.insert(0, R + "/tools")
from arte_gouache import ESTILO  # noqa: E402

DIR = {"tawantinsuyu": "incas"}

HOJA = ("Turnaround reference sheet for 3D modeling of one soldier, a grown man about thirty-five years old, "
        "not a boy: front view on the left, back view on the right, the same clothing and the same headwear in both views, A-pose "
        "with arms straight out at 45 degrees, open empty hands; no weapon, no shield, nothing held, nothing "
        "carried on the back.")

# La cara del aldeano de cada pueblo (hoja_aldeano_e1_meta.json), compacta.
CARA = {
    "tawantinsuyu": "a Quechua man from the Peruvian Andes with a very broad face, strong square jaw, high cheekbones, "
                    "a large hooked aquiline nose, weathered copper-brown skin, thick straight black hair cut short at the ears",
    "mapuches": "a Mapuche man from Araucanía in southern Chile with a broad face, a strong wide jaw, high cheekbones, "
                "light copper-brown skin, thick straight black hair to the shoulders",
    "guaranies": "a Guaraní man from the forests of Paraguay with a broad face, high rounded cheekbones, a broad nose, "
                 "dark almond-shaped eyes, warm golden-brown skin, straight black hair cut straight across the forehead",
    "etiopia": "an Ethiopian Amhara man from the northern highlands with an oval face, high cheekbones, a slightly "
               "aquiline nose, warm medium-brown skin, short tightly curled black hair and a short trimmed black beard",
    "palmares": "an Afro-Brazilian man of Kongo and Mbundu descent from the quilombo of Palmares with a broad face, a "
                "strong jaw, a wide nose, deep dark brown skin, short tightly curled black hair and a short beard",
    "ayutthaya": "a Siamese Thai man from Ayutthaya with a broad face, high cheekbones, a short wide nose, dark "
                 "almond-shaped eyes, warm light-brown skin, short cropped black hair",
}

ROJO = "plain solid bright red, one flat uniform red color"
# Ropa de guerra por pueblo y unidad (sin armas, sin escudo, sin carcaj ni bolsas).
ROPA = {
    "tawantinsuyu": {
        "guerrero": f"a knee-length sleeveless wool tunic, {ROJO}; a round helmet woven from tan cane strips like a basket; undyed wool fringes tied below the knees; simple leather sandals.",
        "lancero": f"a knee-length sleeveless wool tunic, {ROJO}; a round helmet woven from tan cane strips like a basket; simple leather sandals.",
        "hondero": f"a knee-length sleeveless wool tunic, {ROJO}; a cream braided wool cord wound around his head as a headband; barefoot.",
        "boleador": f"a knee-length sleeveless wool tunic, {ROJO}; a cream woven headband across the forehead; a wide cream woven sash around the waist; simple leather sandals.",
        "awqa": f"a knee-length sleeveless wool tunic, {ROJO}; bare head; barefoot.",
    },
    "mapuches": {
        "guerrero": f"a short sleeveless wool shirt (makuñ) reaching mid-thigh, {ROJO}, the same in both views; a dark brown woven wool sash at the waist; a cream woven headband (trarilonko) across the forehead; leather sandals.",
        "lancero": f"a short sleeveless wool shirt (makuñ) reaching mid-thigh, {ROJO}, the same in both views; a dark brown woven wool sash at the waist; a round brown rawhide cap; leather sandals.",
        "hondero": f"a short sleeveless wool shirt (makuñ) reaching mid-thigh, {ROJO}, the same in both views; a dark brown woven wool sash at the waist; a cream woven headband (trarilonko) across the forehead; barefoot.",
        "incendiarios": f"a short sleeveless wool shirt (makuñ) reaching mid-thigh, {ROJO}, the same in both views; a dark brown woven wool sash at the waist; a dark brown woven headband across the forehead; leather sandals.",
    },
    "guaranies": {
        "guerrero": f"a sleeveless cotton tunic (tipoy) cut short at the thighs, {ROJO}; a headband of short upright red and yellow parrot feathers; thin black body paint lines on both forearms; barefoot.",
        "lancero": f"a sleeveless cotton tunic (tipoy) cut short at the thighs, {ROJO}; a headband of short upright red and yellow parrot feathers; woven cotton bands tied below the knees; barefoot.",
        "hondero": f"a sleeveless cotton tunic (tipoy) cut short at the thighs, {ROJO}; a headband of short upright red and yellow parrot feathers; barefoot.",
        "arcabucero": f"a sleeveless cotton tunic (tipoy) to mid-thigh, {ROJO}, over loose white cotton trousers; a narrow leather belt; bare head; barefoot.",
    },
    "etiopia": {
        "lancero": f"a long-sleeved cotton tunic reaching the knees, {ROJO}; tight white cotton trousers to the calves; a white cotton sash wrapped around the waist; bare head; barefoot.",
        "hondero": f"a short-sleeved cotton tunic reaching the knees, {ROJO}; a narrow leather belt; bare legs; bare head; barefoot.",
        "arcabucero": f"a long-sleeved cotton tunic reaching the knees, {ROJO}; tight white cotton trousers to the calves; a leather bandolier across the chest; bare head; barefoot.",
        "guerrero_gasa": f"a short-sleeved cotton tunic reaching the knees, {ROJO}; tight white cotton trousers to the calves; a short cape of black and white colobus fur on the shoulders only; barefoot.",
    },
    "palmares": {
        "guerrero": f"a short-sleeved cotton tunic reaching the knees, {ROJO}; a cream cloth band tied around the head; a short necklace of brown seed beads; barefoot.",
        "lancero": f"a short-sleeved cotton tunic reaching the knees, {ROJO}; a narrow leather belt; bare head; barefoot.",
        "hondero": f"a short-sleeved cotton tunic reaching the knees, {ROJO}; a cream cloth band tied around the head; a palm-fiber cord belt; barefoot.",
        "arcabucero": f"a short-sleeved cotton tunic reaching the knees, {ROJO}; a dark cloth cap; a leather bandolier across the chest; barefoot.",
        "zagaieiro": f"a sleeveless cotton tunic reaching mid-thigh, {ROJO}; a palm-fiber cord belt; bare head; barefoot.",
    },
    "ayutthaya": {
        "guerrero": f"a cotton chong kraben, the wrapped lower garment pulled up between the legs like loose knee breeches, {ROJO}; bare chest; a red cloth band tied around the head; barefoot.",
        "lancero": f"a short sleeveless cotton jacket and a cotton chong kraben, the wrapped lower garment pulled up between the legs like loose knee breeches, both {ROJO}; bare head; barefoot.",
        "hondero": f"a cotton chong kraben, the wrapped lower garment pulled up between the legs like loose knee breeches, {ROJO}; a red cloth sash tied diagonally across the bare chest; a red cloth band around the head; barefoot.",
        "arcabucero": f"a short-sleeved cotton jacket and a cotton chong kraben, the wrapped lower garment pulled up between the legs like loose knee breeches, both {ROJO}; a round dark metal helmet; barefoot.",
        "ngao": f"a long-sleeved cotton jacket and a cotton chong kraben, the wrapped lower garment pulled up between the legs like loose knee breeches, both {ROJO}; a round dark metal helmet with a short point on top; barefoot.",
    },
}


def prompt(civ: str, uni: str) -> str:
    return (f"{ESTILO} {HOJA} He is {CARA[civ]}, a mature adult face with smile lines, no jewelry. "
            f"Clothing: {ROPA[civ][uni]} Natural tones for everything except the red clothing. "
            "Plain light grey background, even light.")


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    civ, uni = args[0], args[1]
    sem = int(args[2]) if len(args) > 2 else 31
    p = prompt(civ, uni)
    if "--ver" in sys.argv:
        print(len(p.split()), p)
        return
    d = f"{O}/{DIR.get(civ, civ)}_gouache"
    base = f"{d}/hoja_{uni}_soldado"
    if os.path.exists(base + "_31.png"):
        n = 1
        while os.path.exists(f"{base}_v{n}_31.png"):
            n += 1
        for suf in (".png", ".jpg", "_mascara.png"):
            if os.path.exists(base + "_31" + suf):
                os.replace(base + "_31" + suf, f"{base}_v{n}_31{suf}")
        if os.path.exists(base + "_meta.json"):
            os.replace(base + "_meta.json", f"{base}_v{n}_meta.json")
    t = time.time()
    subprocess.run([PY, R + "/tools/generar_local.py", p, "--modelo", "flux", "--semilla", str(sem),
                    "--ancho", "1152", "--alto", "768", "--salida", base, "--jpg", "512"], check=True)
    if sem != 31:
        for suf in (".png", ".jpg"):
            os.replace(f"{base}_{sem}{suf}", f"{base}_31{suf}")
        m = json.load(open(base + "_meta.json"))
        m["nota"] = f"semilla real {sem}"
        json.dump(m, open(base + "_meta.json", "w"), indent=1, ensure_ascii=False)
    subprocess.run([PY, R + "/tools/recolorear.py", base + "_31.png"], check=False)
    print(civ, uni, sem, f"{time.time() - t:.0f}s")


if __name__ == "__main__":
    main()
