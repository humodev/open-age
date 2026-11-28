#!/usr/bin/env python3
"""Piezas nuevas del pipeline local para el proceso 66 (todo lo que faltaba en 3D).

    python3 proceso/66-todo-en-3d-local/piezas.py      escribe proceso/66-todo-en-3d-local/piezas_66.json

Cada pieza es UN edificio suelto (Hunyuan cierra los patios en cajas: los conjuntos se arman
después con src/game/recintos.gd). Semilla 41 (intento a); las de INTENTO_B, 42 (intento b).
    python3 tools/gen3d_flux_lote.py --archivo proceso/66-todo-en-3d-local/piezas_66.json <clave>
    python3 tools/gen3d_pipeline.py --piezas proceso/66-todo-en-3d-local/piezas_66.json <clave>
Reglas históricas al frente del prompt (FLUX schnell corta los largos), como en proceso/58;
lo que toma el color del equipo, en rojo plano; lo sagrado va sin rojo ("rojo": false).
"""
import copy
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SALIDA = Path(__file__).with_name("piezas_66.json")
IMG = "/mnt/games/01_Projects/comfyui/output/edificios_66/{clave}_{sem}.png"
VISTA = ("One single building, three-quarter view from a low angle just above eye level, the whole building "
         "visible and centered, isolated on a plain flat light grey background, no ground, no grass, no terrain, "
         "no people, no cast shadow.")
# Paredes encaladas o blancas: en fondo gris claro, el alfa por el color del fondo (tools/gen3d_entradas.py)
# se come las paredes y Hunyuan arma solo el techo (colonial_casa salió un prisma de tejas). Van en fondo
# oscuro (intento b, semilla 42).
VISTA_OSCURA = VISTA.replace("plain flat light grey background", "plain flat dark charcoal grey background")
OSCURAS = {"colonial_casa", "colonial_almacen", "colonial_iglesia", "colonial_cuartel", "colonial_garita",
           "birmanos_zedi", "neutral_huanca"}
# Intento c (semilla 43): con el fondo oscuro, la casa salió de frente y Hunyuan dio una lámina (fondo
# 0,13). Vista de tres cuartos desde 40° (la del proceso 65), para que se vean techo, frente y costado.
VISTA_40 = ("One single building as a 3D model reference: three-quarter view from above at about 40 degrees, so the "
            "top, the front and one side are all visible and the depth reads clearly; the whole building visible and "
            "centered, isolated on a plain flat dark charcoal grey background, no ground, no grass, no terrain, no "
            "people, no cast shadow.")
INTENTO_C = {"colonial_casa", "colonial_iglesia", "colonial_cuartel"}
ROJO = ("Team-color details, large and clearly visible from above: {rojo}, painted in one flat uniform pure bright "
        "red, the only red in the picture; roofs, walls, wood and stone keep their natural tones.")
SIN_ROJO = "Natural tones only, no red anywhere."

REGLAS = {
    "colonial": ("Iberian and Dutch colonial architecture of 16th and 17th century South America: thick whitewashed "
                 "adobe or rubble walls, small barred windows, heavy wooden doors, roofs of weathered dark brown clay "
                 "tiles (never orange or red), plain wooden beams. No gothic spires, no ornate baroque facade."),
    "adal": ("Architecture of Harar and the Adal Sultanate in the Horn of Africa, 16th century: rectangular houses of "
             "rough stone set in mud, plastered in ochre and white, flat roofs with a low parapet, small wooden doors "
             "and tiny windows; tents of woven goat hair for the army. No domes on houses, no gothic arches, no tiles."),
    "birmanos": ("Burmese architecture of the Toungoo and Konbaung kingdoms on the Irrawaddy: dark brown teak wood, "
                 "houses raised on stilts, steep gable roofs of dark wooden shingles or thatch, tiered roofs "
                 "(pyatthat) with carved wooden finials, white and gold bell-shaped stupas. Not Thai: no prang towers. "
                 "Roofs never red or orange."),
    "andes": ("Pre-Inca architecture of the northern and central Andes: round houses on a circular plan, walls of "
              "fieldstone or wattle and daub, steep conical roofs of thick golden ichu straw thatch with a ragged "
              "edge, one low trapezoidal doorway. No tiles, no shingles, no windows with frames, no crenellations."),
    "tupi": ("Tupi architecture of the Brazilian Atlantic coast forest: wooden posts, walls of palm thatch, roofs of "
             "palm leaves reaching almost to the ground. No stone, no tiles, no crenellations."),
    "neutral": "",
    "etiopia": ("Medieval Ethiopian rock-cut church architecture of Lalibela: a monolith carved out of reddish volcanic "
                "tuff, flat roof, plain rectangular windows."),
}

# clave: (edificio, categoría, reglas, prompt, rojo, máscara, caras)
NUEVAS = {
    # --- neutrales y conjunto colonial
    "colonial_ingenio": ("taller", "", "colonial",
        "A colonial sugar mill house (casa da moenda): an open-sided timber shed under a big hipped roof on thick "
        "wooden posts, with a vertical three-roller wooden cane press inside turned by a long wooden beam, and a short "
        "square brick chimney of the boiling house at the back; bundles of sugar cane piled beside it.",
        "cloth awnings tied over the front posts", {"tono": 15}, 6000),  # con faja, el 46 %: aleros por todos lados
    "colonial_casa": ("casa", "casa", "colonial",
        "A small one-storey colonial house with thick whitewashed walls, a heavy wooden door, two small barred windows "
        "and a hipped roof of dark brown weathered clay tiles.",
        "a cloth awning over the door and a cloth curtain in the window", {"tono": 15, "faja": 0.15}, 4500),
    "colonial_casa_ladrillo": ("casa", "casa", "colonial",
        "A narrow two-storey Dutch colonial town house of dark brown-grey brick (never red brick) with a stepped gable "
        "facing the front, white window frames, a heavy wooden door and a steep roof of dark grey tiles.",
        "a cloth awning over the door", {"tono": 12, "faja": 0.12}, 4500),
    "colonial_casa_taipa": ("casa", "casa", "colonial",
        "A rural Paulista house (casa bandeirista): low thick walls of ochre rammed earth (taipa de pilao), a deep "
        "front veranda between two small rooms under one wide hipped roof of dark brown clay tiles, wooden shutters.",
        "a cloth hanging over the veranda rail", {"tono": 15, "faja": 0.15}, 4500),
    "colonial_iglesia": ("hito_economia", "hito", "colonial",
        "A small plain colonial chapel with whitewashed walls, a simple wooden door under a round arch, a small "
        "bell-gable (espadana) with one bell on the front and a gabled roof of dark brown tiles; only a small plain "
        "cross on the gable, no statues, no paintings.",
        None, {}, 5000),
    "colonial_cuartel": ("cuartel", "", "colonial",
        "A long one-storey colonial guardhouse (corpo da guarda) with whitewashed walls, an arcade of three round "
        "arches on the front, a gabled roof of dark brown tiles, and a wooden rack of pikes and muskets by the door.",
        "a flag on a pole by the door and cloth hanging under the arches", {"tono": 15, "faja": 0.12}, 5000),
    "colonial_almacen": ("deposito", "", "colonial",
        "A two-storey colonial warehouse (armazem) of whitewashed rubble stone with big double wooden doors and a "
        "hoist beam over the upper door, a hipped roof of dark brown tiles, wooden barrels and crates stacked in front.",
        "a cloth awning over the big doors", {"tono": 15, "faja": 0.12}, 4500),
    "colonial_garita": ("torre", "torre", "colonial",
        "A small square colonial bastion of grey stone masonry, as tall as two men, with a sloping base, a stone "
        "parapet with two cannon embrasures and a round stone sentry box (garita) with a little domed top on one corner.",
        "a flag on a pole on the bastion", {"tono": 15, "faja": 0.1}, 4500),
    "neutral_huanca": ("sitio_sagrado", "", "neutral",
        "A sacred standing stone: one tall rough weathered grey stone pillar, three times as tall as it is wide, "
        "standing upright on a low round platform of fieldstones, with small offerings of flowers and pottery at its "
        "foot. Natural grey and brown stone.",
        None, {}, 3000),
    "neutral_lalibela": ("sitio_lalibela", "", "etiopia",
        "A cross-shaped monolithic church (like Bete Giyorgis): one solid block carved in the shape of a Greek cross "
        "with equal arms, on a stepped plinth, a flat roof with a stepped cross carved in relief, plain rectangular "
        "windows in two rows, reddish brown stone; the walls and the cross-shaped silhouette both visible.",
        None, {}, 4000),
    # --- Adal
    "adal_casa": ("casa", "casa", "adal",
        "A two-storey Harari stone house (gey gar): a plain rectangular block of rough stone plastered in ochre and "
        "white, a flat roof with a low parapet, a small carved wooden door and two tiny windows.",
        "a cloth curtain in the doorway and a cloth band under the roof parapet", {"tono": 15, "faja": 0.15}, 4500),
    "adal_tienda": ("centro", "", "adal",
        "A large army tent of the imam: a long rectangular tent of dark brown and black woven goat hair cloth on "
        "wooden poles, ropes pegged to the ground, the front side rolled up showing carpets and wooden chests inside.",
        "pennants on the two tent poles and a wide cloth band along the front edge", {"tono": 15}, 4500),
    "adal_torre": ("torre", "torre", "adal",
        "A gate tower of the Jugol wall of Harar: a square tower of rough stone plastered in ochre, flat roof with a "
        "low parapet, a big arched gateway through the bottom with a wooden door, small slit windows.",
        "a cloth band under the parapet and a flag on the roof", {"tono": 15, "faja": 0.12}, 4500),
    "adal_mezquita": ("hito_economia", "hito", "adal",
        "A small Harar mosque: a low whitewashed rectangular hall with a flat roof and low parapet, and beside it a "
        "short plain square tower (minaret) with a flat top and a small parapet, a simple wooden door. No dome, no cross, "
        "no symbol or finial on top, no gold, no writing.",
        None, {}, 4500),
    "adal_cuartel": ("cuartel", "", "adal",
        "A walled army camp shelter: a long low building of rough ochre-plastered stone with a flat roof on wooden "
        "beams, an open front with wooden posts, spears and round hide shields leaning on the wall.",
        "cloth hanging between the front posts and a flag on the roof", {"tono": 15, "faja": 0.12}, 4500),
    # --- Birmania (lo sagrado sin rojo)
    "birmanos_casa": ("casa", "casa", "birmanos",
        "A Burmese house (ein) of dark brown teak raised on wooden stilts, walls of woven bamboo mats, a steep gable "
        "roof of dark thatch, a wooden ladder up to the door, a small veranda.",
        "a cloth curtain in the doorway and a cloth hanging over the veranda rail", {"tono": 15, "faja": 0.15}, 4500),
    "birmanos_kyaung": ("hito_economia", "hito", "birmanos",
        "A Burmese teak monastery (kyaung) on a tall platform of wooden posts with a wide wooden staircase, a long "
        "hall with several tiered roofs rising one above the other in dark weathered teak shingles, carved wooden "
        "gable finials. No statues, no Buddha images.",
        None, {}, 6000),
    "birmanos_zedi": ("hito_guerra", "hito", "birmanos",
        "A Burmese bell-shaped stupa (zedi): whitewashed brick on three square receding terraces, a smooth bell dome, "
        "a tall tapering ringed spire with a small golden umbrella (hti) on top. No statues, no Buddha images.",
        None, {}, 4500),
    "birmanos_pyatthat": ("centro", "", "birmanos",
        "A Burmese royal audience hall of dark teak on a low brick platform, with a central pyatthat: a tall spire of "
        "five square tiered roofs stacked one above the other, each with carved wooden finials, over a hall with "
        "wide eaves.",
        "cloth banners hanging from the eaves of the hall", {"tono": 15, "faja": 0.1}, 6000),
    "birmanos_cuartel": ("cuartel", "", "birmanos",
        "A long Burmese barracks hall of dark teak on short stilts, open sides with wooden railings, a steep gable "
        "roof of dark thatch, spears and round shields leaning on the posts.",
        "cloth hanging along the railings and a pennant on a pole", {"tono": 15, "faja": 0.12}, 4500),
    # --- Andes (chankas, caranquis, cañaris)
    "andes_casa_piedra": ("casa", "casa", "andes",
        "A round house of grey fieldstone set in mud, about as tall as a person, one low trapezoidal doorway, under "
        "a steep conical roof of thick golden ichu straw thatch with a ragged edge.",
        "a woven cloth curtain in the doorway and a woven band around the wall just under the thatch",
        {"tono": 22, "faja": 0.15, "cumbrera": 0.08}, 4000),
    "andes_casa_bahareque": ("casa", "casa", "andes",
        "A round house of wattle and daub plastered in light brown mud, about as tall as a person, one low doorway, "
        "under a tall steep conical roof of thick golden straw thatch with a short wooden finial.",
        "a woven cloth curtain in the doorway and a woven band around the wall just under the thatch",
        {"tono": 22, "faja": 0.15, "cumbrera": 0.08}, 4000),
    # --- Tupíes
    "tupies_mirador": ("torre", "torre", "tupi",
        "A tall wooden lookout platform on four rough tree-trunk posts lashed with vines, a ladder of poles, a small "
        "platform with a low railing on top under a little roof of palm thatch.",
        "a cloth band tied around the railing and a pennant on top", {"tono": 15, "faja": 0.12}, 4000),
}


# Intentos que no entran (quedan en piezas_66.json para el catálogo, sin GLB).
DESCARTADAS = {
    "adal_mezquita": "FLUX pintó una cruz las dos veces (41 y 42, con «no cross» en el prompt): no se genera el 3D",
    "neutral_lalibela": "41: losa vista desde arriba; 42: torre en T. Va procedural (utilería iglesia_cruz)",
}


def pieza(clave, n, sem, base):
    edificio, cat, reg, sujeto, rojo, masc, caras = n
    color = ROJO.format(rojo=rojo) if rojo else SIN_ROJO
    prompt = " ".join(x for x in ["{estilo}", sujeto, REGLAS[reg], color, VISTA_40 if clave in INTENTO_C else VISTA_OSCURA if clave in OSCURAS else VISTA] if x)
    if reg == "colonial" and masc:
        masc = {**masc, "tono": 8}  # las tejas pardas caen en 15–25°: con 15 la máscara tomaba el techo (46 %)
    civ = clave.split("_")[0]
    return {
        "tipo": "edificio", "edificio": edificio, "categoria": cat, "civ": civ, "proceso": "66",
        "rojo": bool(rojo),
        "referencia": {"imagen": IMG.format(clave=clave, sem=sem),
                       "receta": {"semilla": sem, "ancho": 768, "alto": 768, "prompt": prompt},
                       "vistas": {"front": {"margen": 0.06, "quitar": ["verde"]}}},
        "forma": {"modelo": "hy-mini-turbo", "semilla": 12345, "octree": 256},
        "textura": "auto", "caras": caras, "suelo_pct": 6,
        "destino": f"assets/generados/modelos/local/{clave}.glb",
        "pasada": 2, "textura_px": 2048, "mezcla": True, "apagar": 0.3,
        **({"mascara": masc} if rojo else {}),
        **({"descartada": DESCARTADAS[clave]} if clave in DESCARTADAS else {}),
    }


# Las que van por el intento b (semilla 42): referencia rehecha.
INTENTO_B = OSCURAS | set(DESCARTADAS)


def main():
    base = json.loads((REPO / "data/gen3d_piezas.json").read_text())
    out = {"_doc": __doc__, "comun": base["comun"], "piezas": {}}
    for clave, n in NUEVAS.items():
        out["piezas"][clave] = pieza(clave, n, 43 if clave in INTENTO_C else 42 if clave in INTENTO_B else 41, base)
    SALIDA.write_text(json.dumps(out, ensure_ascii=False, indent=1) + "\n")
    print(SALIDA, len(out["piezas"]))


if __name__ == "__main__":
    main()
