#!/usr/bin/env python3
"""Láminas de civilización y de campaña con Meshy (C-03: imágenes generadas por IA, marcadas).

    python3 tools/generar_laminas.py civs
    python3 tools/generar_laminas.py campanas
"""
import subprocess, sys, json, os
from concurrent.futures import ThreadPoolExecutor

STYLE = ("Painterly key art illustration for a historical real-time strategy game, rich but soft colors, "
         "warm late-afternoon light, wide landscape seen from a slightly elevated view, respectful and historically "
         "grounded, people shown as active protagonists of their own history, no text, no logos, no letters, full-bleed image edge to edge with no border and no frame")
CIVS = {
    "tawantinsuyu": "a 15th-century Andean settlement of Tawantinsuyu on mountain terraces: fitted stone walls with trapezoidal doorways, steep thatched roofs, rows of round qollqa storehouses on the hillside, a paved stone road winding through the green valley, llamas carrying loads, people in woven tunics working the terraces, snow-capped peaks",
    "mapuches": "a 16th-century Mapuche lof in southern Chile: oval thatched ruka houses in a forest clearing, araucaria and canelo trees, a carved stepped rewe ceremonial post with branches, people in woven ponchos with silver headbands, horses and cattle grazing, a snowy volcano in the misty distance",
    "guaranies": "a 16th-century Guarani village in the subtropical forest by the Parana river: long communal houses with thatched roofs reaching the ground, cleared fields of manioc and maize at the forest edge, dugout canoes on the river, archers and families, dense green forest, warm humid light",
    "etiopia": "a 16th-century Ethiopian royal camp on a green highland plateau: many tents arranged around a large royal tent, round thatched tukul houses, a round stone church with a cross, horsemen and spearmen with round shields, flat-topped amba mountains in the background",
    "palmares": "the Quilombo dos Palmares in the 17th century in the forested hills of northeastern Brazil: a hidden village of palm-thatched wattle-and-daub houses inside rings of sharpened wooden palisades, manioc fields, a blacksmith forge with smoke, Afro-Brazilian people farming, forging and keeping watch, tall palm trees",
    "ayutthaya": "the island city of Ayutthaya in the 17th century: white bell-shaped stupas and prang towers with golden spires, wooden houses with steep multi-tiered red roofs, canals with boats, flooded rice fields, war elephants with howdahs, foreign merchant ships at the river port",
}
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def run(name, scene):
    out = os.path.join(ROOT, "assets", "generados", "laminas", name + ".png")
    if os.path.exists(out):
        return name + ": ya existe"
    r = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "meshy_api.py"), "imagen", out, "nano-banana-2",
                        STYLE + ". Scene: " + scene + ".", "--aspect=16:9"], capture_output=True, text=True)
    return name + ": " + (r.stdout.strip().splitlines() or ["?"])[-1] + r.stderr.strip()[-200:]


def jobs(kind):
    if kind == "civs":
        return CIVS.items()
    out = []
    for f in sorted(os.listdir(os.path.join(ROOT, "data", "campanas"))):
        c = json.load(open(os.path.join(ROOT, "data", "campanas", f)))
        m = c["misiones"][0]
        scene = "%s. %s, %s. %s" % (c["titulo"], m.get("lugar", ""), m.get("anio", ""), CIVS.get(c["civ"], ""))
        out.append(("campana_" + c["civ"], scene))
    return out


if __name__ == "__main__":
    with ThreadPoolExecutor(6) as ex:
        for line in ex.map(lambda j: run(*j), jobs(sys.argv[1])):
            print(line)
