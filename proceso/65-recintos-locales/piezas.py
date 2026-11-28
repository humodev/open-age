#!/usr/bin/env python3
"""Reintentos del proceso 65 para el pipeline local (como mucho dos por pieza).

    python3 proceso/65-recintos-locales/piezas.py      escribe proceso/65-recintos-locales/piezas_65.json

Toma la pieza del proceso 58 (data/gen3d_piezas.json, sin tocarlo) y cambia la referencia:
semillas 31 (intento a) y 32 (intento b), prompt nuevo y la máscara donde hace falta.
    python3 tools/gen3d_flux_lote.py --archivo proceso/65-recintos-locales/piezas_65.json <clave>
    python3 tools/gen3d_pipeline.py --piezas proceso/65-recintos-locales/piezas_65.json <clave>
"""
import copy
import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SALIDA = Path(__file__).with_name("piezas_65.json")
IMG = "/mnt/games/01_Projects/comfyui/output/edificios_65/{clave}_{sem}.png"
VISTA = ("One single building as a 3D model reference: three-quarter view from above at about 40 degrees, so the top, "
         "the front and one side are all visible and the depth reads clearly; the whole building visible and centered, "
         "isolated on a plain flat light grey background, no ground, no grass, no terrain, no people, no cast shadow.")
ROJO = ("Team-color details, large and clearly visible from above: {rojo}, painted in one flat uniform pure bright red, "
        "the only red in the picture; everything else keeps its natural tones.")

NUEVAS = {
    "tawantinsuyu_almacen_madera": {
        "prompt": "{estilo} Inca firewood store of the Andes: a big square stack of split firewood logs, as deep as it is "
                  "wide, with the round cut ends showing on the front and the side, resting on a low base of grey "
                  "fieldstone, under a small low hip roof of thick bundled golden ichu straw thatch held by four rough "
                  "wooden posts at the corners; the logs fill most of the picture and the roof only covers the top. "
                  "No walls, no house, no crenellations, no tiles, no shingles, no chimney. " + ROJO.format(
                      rojo="a woven cloth band tied around the four posts just under the thatch") + " " + VISTA,
        "mascara": {"tono": 22, "faja": 0.12, "cumbrera": 0.08},
    },
    "mapuches_rewe_caballeria": {
        "prompt": "{estilo} Mapuche horse shelter of southern Chile: a long low open-sided shelter of rough unworked "
                  "wooden poles with a thick rounded roof of golden grass thatch, the roof ridge smooth and plain; in "
                  "front, a hitching rail of rough poles with sheepskin saddle pads and rawhide ropes. No cross, no "
                  "religious symbol, no finial, no pole or ornament on top of the roof, no stone, no tiles, no planks, "
                  "no windows. " + ROJO.format(rojo="woolen saddle blankets hanging over the hitching rail") + " " + VISTA,
        "mascara": {"tono": 15, "faja": 0.15, "cumbrera": 0.08},
    },
    "ayutthaya_torre": {
        "prompt": "{estilo} A small square river fort of 17th-century Ayutthaya in Siam: four thick solid whitewashed "
                  "brick walls enclosing a small court, leaf-shaped merlons (bai sema) all along the top of the walls, "
                  "a square corner bastion at each corner, a small gatehouse in the front wall, and inside a small hall "
                  "with a two-tiered roof of dark grey-brown wooden shingles; one small bronze cannon on the wall; on a "
                  "low brick platform. Roofs never red or orange. No statues, no Buddha images, no neighbouring houses, "
                  "no water. " + ROJO.format(rojo="plain rectangular cloth flags on two tall poles and a wide cloth "
                                            "band running around the outside of the walls just under the merlons")
                  + " " + VISTA,
        "mascara": {"tono": 15, "faja": 0.12, "cumbrera": 0.06},
    },
    "etiopia_alianza": {
        "prompt": "{estilo} Ethiopian royal camp of the 17th century: one large round royal tent of plain off-white "
                  "undyed cotton cloth with a conical top and a short wooden finial, the whole tent white and cream; "
                  "beside it open wooden crates of muskets and two small bronze cannons on wooden carriages. No cross "
                  "on the tent, no star, no gothic arches. " + ROJO.format(
                      rojo="one wide cloth band wrapped around the white tent just above the door and two cloth "
                           "pennants on the tent pole") + " The tent itself is white, never red. " + VISTA,
        "mascara": {"tono": 15},
    },
}


def main():
    base = json.loads((REPO / "data/gen3d_piezas.json").read_text())
    out = {"_doc": __doc__, "comun": base["comun"], "piezas": {}}
    for clave, n in NUEVAS.items():
        p = copy.deepcopy(base["piezas"][clave])
        p["proceso"] = "65"
        for letra, sem in (("a", 31), ("b", 32)):
            q = copy.deepcopy(p)
            q["referencia"]["receta"]["prompt"] = n["prompt"]
            q["referencia"]["receta"]["semilla"] = sem
            q["referencia"]["imagen"] = IMG.format(clave=clave, sem=sem)
            q["mascara"] = n["mascara"]
            q["destino"] = f"assets/generados/modelos/local/{clave}_65{letra}.glb"
            out["piezas"][f"{clave}_65{letra}"] = q
    SALIDA.write_text(json.dumps(out, ensure_ascii=False, indent=1) + "\n")
    print(SALIDA, len(out["piezas"]))


if __name__ == "__main__":
    main()
