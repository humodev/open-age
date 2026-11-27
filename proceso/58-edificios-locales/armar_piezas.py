#!/usr/bin/env python3
"""Piezas del pipeline 3D local para todos los edificios de los seis pueblos (proceso/58).

    python3 proceso/58-edificios-locales/armar_piezas.py        escribe en data/gen3d_piezas.json

Cada edificio lleva una referencia nueva de FLUX (receta gouache de proceso/42) pensada para el
3D: un solo cuerpo, vista de tres cuartos, sin suelo ni paisaje, y unos pocos elementos en ROJO
PLANO (telas, toldos, cortinas, banderolas, fajas pintadas) que después toman el color del equipo
con la máscara (tools/mascara_equipo_3d.py --metodo=rojo --edificio) y equipo_3d.gdshader.
Lo sagrado no lleva rojo («rojo»: False): el color va solo en el estandarte del juego.

Clave de la pieza: <pueblo>_<tipo> (los que ya tenían modelo del proceso 54, <pueblo>_<tipo>_rojo).
Destino: assets/generados/modelos/local/<pueblo>_<tipo>.glb; en el juego, una línea de
data/civs/<pueblo>.json → estilo.modelos: "<tipo>": "local/<pueblo>_<tipo>".
"""
import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
F = REPO / "data/gen3d_piezas.json"

MARCO = ("One single building as a 3D model reference: three-quarter view from slightly above, the whole building visible "
         "and centered, isolated on a plain flat light grey background. No ground, no terrain, no grass, no hill, no "
         "water, no trees, no people, no animals, no cast shadow. Only this one building: no other houses, huts or sheds "
         "around it.")
ROJO = ("Team-color details, large and clearly visible from above: {rojo}, painted in one flat uniform pure bright red, the only red in the picture; roofs, "
        "walls, wood and stone keep their natural tones.")
SIN_ROJO = "Natural tones only, no red anywhere."

ARQ = {
    "tawantinsuyu": "Inca architecture of the Andes: walls of grey fieldstone set in mud mortar or of finely fitted stone "
                    "blocks, trapezoidal doorways and niches, steep roofs thatched with golden ichu grass.",
    "mapuches": "Mapuche architecture of southern Chile: oval houses with thick rounded roofs of golden grass thatch "
                "reaching almost to the ground, walls of wooden poles and woven branches, rough wooden pole fences.",
    "guaranies": "Guarani architecture of the Parana forest: long houses with wooden posts, walls of tacuara bamboo canes "
                 "and mud, steep roofs thatched with grass and palm leaves reaching almost to the ground.",
    "etiopia": "Ethiopian highland architecture of the 16th and 17th centuries: round houses with walls of brown fieldstone "
               "or wattle and daub and steep conical thatched roofs, buildings of brown and grey stone.",
    "palmares": "Architecture of the 17th-century quilombo of Palmares in northeastern Brazil: rectangular houses of wattle "
                "and daub with steep roofs thatched with palm leaves, palisades of sharpened logs.",
    "ayutthaya": "Secular architecture of 17th-century Ayutthaya in Siam: teak houses raised on stilts with steep gable "
                 "roofs with curved ends, whitewashed brick buildings with tiered roofs; all roofs are covered with dark "
                 "grey-brown weathered wooden shingles, never red or orange.",
}

# Rojo por defecto de cada pueblo (telas y pinturas de uso cotidiano o militar, nada sagrado).
ROJO_CIV = {
    "tawantinsuyu": "a wide woven cloth band wrapping around all the walls just under the eaves and woven cloth curtains in the doorways",
    "mapuches": "large woolen blankets draped over a pole rail in front of the door and long cloth pennants on two tall cane lances",
    "guaranies": "wide cotton cloth awnings over the doorways and wide cloth bands tied around the main posts",
    "etiopia": "wide cloth awnings over the doorways and a wide cloth band around the walls below the roof",
    "palmares": "a wide cloth band around the walls under the eaves and cloth curtains in the doorways",
    "ayutthaya": "plain rectangular cloth flags on two tall poles and wide cloth awnings over the doors",
}

# tipo: (qué es, rojo propio o None para el del pueblo o False para ninguno, categoría)
# Categoría: la de WorldView._want_h_of (casa, produccion, mercado, torre, capital, hito, maravilla; "" sin estirar).
E = {
 "tawantinsuyu": {
  "casa": ("A small one-room fieldstone house with a steep thatched gable roof and one trapezoidal doorway, a low stone wall around a small yard.", None, "casa"),
  "centro": ("An Inca administrative center: a large fieldstone hall with a huge steep thatched gable roof and a row of trapezoidal doorways, two smaller thatched houses joined at its ends forming a U around a small paved court.", None, "capital"),
  "cuartel": ("A long rectangular hall of fieldstone with many trapezoidal doorways along its long side and a steep thatched gable roof; long wooden spears lean against the wall.", "woven cloth curtains in every doorway and square cloth-covered shields hanging beside the doors", "produccion"),
  "taller_tejido": ("A small square fieldstone workshop with an open front under a thatched roof, a large upright wooden frame loom standing in front with a half-woven cloth, skeins of wool hanging from a pole.", "the half-woven cloth on the loom and the skeins of wool", ""),
  "almacen_madera": ("A long rectangular woodpile of split firewood logs as tall as a man, the round cut log ends facing the viewer, under a lean-to of thatch on wooden posts.", "a woven cloth tied over one end of the woodpile", ""),
  "almacen_mina": ("A stepped pile of large cut grey stone blocks stacked like a small pyramid beside a small fieldstone hut with a thatched roof, lumps of green copper ore at its foot.", None, ""),
  "qollqa": ("A row of three round fieldstone storehouses with conical thatched roofs standing side by side on one low stone platform, small square openings.", "woven cloth curtains over the small openings", ""),
  "campo_tiro": ("A rectangular enclosure of low fieldstone walls with a thatched hut in one corner, a pile of round sling stones and a wooden pole rack.", "braided slings and cloth hanging from the wooden pole rack", "produccion"),
  "torre": ("A tall round fieldstone lookout tower with a conical thatched roof and a small doorway at the base, standing on a square stone base.", "a cloth band around the top of the tower wall", "torre"),
  "fortaleza": ("A fortress block of three stepped levels of massive zigzag stone walls of huge fitted blocks, with a thatched barracks on the top level.", "cloth curtains in the barracks doorways and two cloth pennants on poles at the top", "torre"),
  "mercado": ("An open stone-walled market square with a thatched gateway, goods laid out on woven cloths: potatoes, maize, clay pots and folded textiles.", "the woven cloths under the goods", "mercado"),
  "ushnu": ("A stepped stone platform of three levels with a central staircase, a small square stone seat on top.", "a cloth band along the edge of each step level", "hito"),
  "pukara_mayor": ("A round frontier fort: two concentric rings of fieldstone walls with a gate, a thatched barracks inside the inner ring.", None, "hito"),
  "qorikancha": ("A temple enclosure with a curved wall of perfectly fitted dark stone blocks, a thin band of gold plates along the top of the wall, thatched roofs behind.", False, "hito"),
  "kallanka_real": ("A very long great hall of finely fitted stone blocks with a row of tall trapezoidal doorways and a huge thatched gable roof.", None, "hito"),
  "aqllawasi": ("A rectangular walled compound of finely fitted stone blocks with a single trapezoidal gate and long thatched roofs inside along the walls.", "folded fine textiles stacked on the walls and a cloth curtain in the gate", "hito"),
  "vilcabamba": ("A cluster of four fieldstone buildings around a small court, two with thatched roofs and two with Spanish clay tile roofs, joined by a low wall.", None, "hito"),
  "maravilla": ("Ollantaytambo as one compact monument: a block of long stone terraces climbing in steps to a top platform with a wall of six enormous pink granite blocks, stone storehouses with thatched roofs on one side.", "cloth bands along the terrace edges", "maravilla"),
 },
 "mapuches": {
  "casa": ("A single large oval Mapuche house with a thick rounded thatched roof of golden grass reaching almost to the ground, a small low doorway.", None, "casa"),
  "lof": ("A Mapuche family settlement: three large oval thatched houses close together around a small yard, joined by a low wooden pole fence.", None, "capital"),
  "cuartel": ("A long open-sided shelter of wooden posts with a thatched gable roof, a rack of long cane lances leaning against it.", "cloth pennants on the tips of the lances and a woolen blanket over the rack", "produccion"),
  "fortaleza": ("A frontier fort of wood and earth: a round ring of sharpened log palisade on an earth bank, a lookout platform on posts and a thatched house inside.", "cloth pennants on two lances on the lookout platform", "torre"),
  "mercado": ("A long open thatched shelter on posts, folded woven ponchos with stepped patterns, cattle hides and clay jars laid out on a low bench.", "the folded woven ponchos", "mercado"),
  "rewe_malon": ("A large oval thatched house with a tall bundle of colihue cane lances leaning against it and a wooden pole corral beside it.", "cloth pennants on the tips of the lances", "hito"),
  "rewe_lonko": ("The large oval thatched house of a lineage head, the biggest house of the valley, with a wide wooden pole corral beside it.", False, "hito"),
  "rewe_caballeria": ("A large round corral of rough wooden poles with a thatched shelter on one side and a hitching rail with sheepskin saddle pads.", "woolen saddle blankets hanging on the hitching rail", "hito"),
  "rewe_monte": ("Three tall araucaria trees with straight bare grey trunks and flat dark green umbrella-shaped crowns only at the very top, an oval thatched house between the trunks, baskets of pine nuts.", "woolen blankets draped over the baskets", "hito"),
  "parlamento": ("A long wide open shelter with a thatched roof on twelve wooden posts, two long rows of wooden benches facing each other underneath.", "woolen blankets laid over the benches", "hito"),
  "weichan": ("A war council ground: a ring of long colihue cane lances stuck upright around a fire pit, a small thatched shelter at one side.", "cloth pennants on the tips of the lances", "hito"),
  "maravilla": ("A great treaty ground: two very long open thatched shelters on wooden posts facing each other across an open space with rows of benches, a few oval thatched houses at the ends.", "woolen blankets laid over the benches", "maravilla"),
 },
 "guaranies": {
  "casa": ("A small house with walls of tacuara bamboo canes and mud and a steep thatched roof of palm leaves, one low doorway.", "a cotton hammock tied under the eave and a cloth awning over the doorway", "casa"),
  "centro": ("A very long communal house: a huge steep thatched roof of grass reaching to the ground over wooden posts, several low doorways along its side.", None, "capital"),
  "almacen_madera": ("An open-sided shelter of wooden posts with a thatched palm roof, stacks of firewood and hanging bundles of maize inside.", None, ""),
  "almacen_mina": ("An open-sided thatched shelter with large clay pots drying in rows and a heap of clay and stones.", None, ""),
  "cuartel": ("A long open-sided thatched shelter on wooden posts, long bows, spears and flat hardwood clubs leaning in racks.", None, "produccion"),
  "campo_tiro": ("A small thatched shelter on four posts, long hardwood bows and bundles of cane arrows hanging under the roof, a straw target on a post beside it.", None, "produccion"),
  "taller": ("An open thatched workshop with piles of thick giant bamboo poles, rawhide strips on a rack and a bamboo tube cannon on a wooden frame.", None, "produccion"),
  "fortaleza": ("A double palisade of giant bamboo canes and logs in a square, raised wooden archer platforms behind it, a thatched house inside.", "cloth bands tied around the palisade gate posts and two cloth pennants on the platforms", "torre"),
  "mercado": ("An open thatched shelter on posts with goods laid out on mats: clay pots, cotton cloth, baskets of manioc and bundles of yerba mate leaves.", "the folded cotton cloths", "mercado"),
  "karai_palabra": ("A very large communal house with a thatched roof reaching the ground and a ring of low wooden stools in front of its door.", False, "hito"),
  "aty_guasu": ("A wide round meeting ground enclosed by four long thatched communal houses at its sides, a ring of wooden benches in the middle.", None, "hito"),
  "mision": ("A mission town row: a long building with a dark brown weathered clay tile roof (not red) and a wide veranda on wooden columns, a workshop with a loom under the veranda.", "cloth awnings between the veranda columns", "hito"),
  "monte": ("A hidden forest camp: three low thatched shelters on posts close together under two huge trees, a cotton hammock between the trunks.", "the cotton hammock and a cloth hanging on a shelter", "hito"),
  "tava": ("A fortified mission block: two rows of yellow-brown sandstone houses with dark brown weathered tile roofs (not red) and verandas, enclosed by a square log palisade with one gate.", "cloth bands tied around the gate posts and cloth awnings on the verandas", "hito"),
  "yvy_marane": ("A defensive earthwork: a curved earth bank topped by a log palisade, two bamboo tube cannons wrapped in rawhide aimed over it.", "cloth bands tied around the palisade posts", "hito"),
  "maravilla": ("A two-story town hall of yellow-brown sandstone with a long upper gallery on wooden columns and a dark brown weathered clay tile roof (not red), two lower workshop wings with verandas at its sides.", "cloth awnings along the upper gallery", "maravilla"),
  "maravilla_monte": ("A large forest village: eight long communal houses with thatched roofs reaching the ground arranged in a ring around a round plaza.", None, "maravilla"),
 },
 "etiopia": {
  "casa": ("A single round house with a low wall of brown fieldstone and mud and a steep conical thatched roof, one wooden doorway.", None, "casa"),
  "centro": ("A compact royal camp: one large round cloth pavilion tent in the center with four smaller white tents pressed tightly against its sides, all touching in one tight cluster.", "the large central tent", "capital"),
  "corte_nueva": ("A new camp being laid out, in one tight cluster: a half-raised round tent on poles with rolled tents, tent poles and bundles of supplies piled against it.", "the half-raised tent cloth", ""),
  "almacen_alimento": ("A tall woven basket granary plastered with mud standing on a round stone base, with a small conical thatched roof, sacks of grain beside it.", None, ""),
  "almacen_madera": ("An open-sided shed with a thatched roof on wooden posts, stacks of juniper logs and bundles of branches.", None, ""),
  "almacen_mina": ("A round stone workshop with a conical thatched roof, piles of cut stone blocks and baskets of rocks in front.", None, ""),
  "cuartel": ("A compact soldiers' camp: a round thatched house with three white cloth tents pressed tightly against it in one tight cluster, a rack of spears and round hide shields against the house.", "cloth pennants on the spear tips and the door flaps of the tents", "produccion"),
  "establo": ("A long low stable of fieldstone with a thatched roof and open stalls, a wooden rail in front with saddles on it.", "saddle cloths on the rail", "produccion"),
  "taller": ("An open workshop of fieldstone and wooden beams with a thatched roof, logs, wheels and a half-built battering ram inside.", None, "produccion"),
  "torre": ("A tall round tower of brown fieldstone with a flat top and a small parapet, a wooden door at the base.", "a cloth pennant on a pole on top", "torre"),
  "fortaleza": ("A small flat-topped rock with sheer sides like a table, a brown stone wall along its rim, two round thatched houses on top and a narrow path with a gate.", "cloth pennants on poles at the gate", "torre"),
  "mercado": ("A compact market: one round open-sided thatched market hall on posts with low tables under it holding salt bars, sacks of grain, clay pots and cotton cloth.", "cloth shades over two stalls", "mercado"),
  "iglesia": ("A round compound: a low stone wall with a gatehouse and inside it a large round building with a gallery of wooden posts and a steep conical thatched roof.", False, "hito"),
  "monasterio": ("A monastic community: small round stone cells with thatched roofs inside a stone wall, a library hut, terraced garden beds.", False, "hito"),
  "amba": ("A flat-topped rock mesa with sheer cliffs as a fortress, a stone wall along the rim, round houses and a storehouse on top, a zigzag path to a gate.", "cloth pennants on poles along the wall", "hito"),
  "remonta": ("A large stone-walled corral beside a long thatched stable, grooms' round house and piles of hay.", "saddle cloths hanging on the corral wall", "hito"),
  "gondar": ("A two-story castle of brown and grey stone with round corner towers topped by small domes and a taller square tower.", "cloth awnings over the windows of the upper floor", "hito"),
  "alianza": ("A compact court camp: one large round royal tent with open wooden trade crates of muskets, two small bronze cannons and powder barrels piled right against its side.", "the large royal tent", "hito"),
  "maravilla": ("The royal enclosure of Gondar: a large two-story castle of brown and grey stone with round domed corner towers and a tall square tower, a second smaller castle beside it, inside a stone wall with a gate.", "cloth awnings over the upper windows and pennants on the towers", "maravilla"),
 },
 "palmares": {
  "casa": ("A small rectangular house with walls of wattle and daub and a steep roof thatched with palm leaves, one doorway.", None, "casa"),
  "centro": ("A town enclosed by a tall palisade of sharpened logs with one wooden gate, palm-thatched roofs of houses visible inside and a larger house with a veranda in the middle.", None, "capital"),
  "almacen_alimento": ("A granary of wattle and palm thatch raised on wooden stilts with a ladder, ears of maize and sacks of manioc flour beside it.", None, ""),
  "almacen_mina": ("An open palm-thatched shed with a dome-shaped clay kiln, rows of clay pots and a pile of clay.", None, ""),
  "cuartel": ("A long palm-thatched house with open sides on posts, spears and bows leaning in racks, round woven shields on the posts.", None, "produccion"),
  "mocambo": ("Four small palm-thatched houses of wattle and daub close together around a tiny yard with a potter's kiln.", None, ""),
  "fortaleza": ("A bastion of thick upright logs jutting out from a short section of palisade, a raised wooden platform behind it, sharpened stakes in front.", "cloth bands tied around the tallest logs and a cloth pennant on the platform", "torre"),
  "mercado": ("An open palm-thatched shelter with goods laid out on mats: clay pots, palm baskets, manioc flour, maize and iron tools.", "cloth laid under the goods", "mercado"),
  "quilombo_central": ("A large house with walls of wattle and daub, a long veranda on wooden posts and a high palm-thatched roof, two smaller houses at its sides.", None, "hito"),
  "mocambo_guerra": ("A cluster of palm-thatched huts behind rows of sharpened stakes slanting outwards, a tall wooden lookout platform on poles.", "cloth pennant on the lookout platform and cloth curtains in the hut doorways", "hito"),
  "cerca_real": ("Three concentric rings of log palisade one inside another with offset gates, palm-thatched houses in the center.", "cloth bands tied around the gate posts", "hito"),
  "ferraria": ("A large open forge shed with a palm-thatched roof on posts, a charcoal forge with bowl bellows, an iron anvil and a rack of hoes and spear points.", "cloth tied on the roof posts", "hito"),
  "pacto_cucau": ("Two straight rows of palm-thatched houses side by side and a granary on stilts at the end.", None, "hito"),
  "guerra_zumbi": ("A round palisade of sharpened logs with a wooden gate and a large wooden drum beside it, palm-thatched houses inside.", "cloth bands tied around the gate posts", "hito"),
  "maravilla": ("A fortified hilltop town as one compact model: three rings of log palisade stepping up around a central cluster of palm-thatched houses.", "cloth bands tied around the gate posts of each ring", "maravilla"),
 },
 "ayutthaya": {
  "casa": ("A single house of teak wood planks raised on tall wooden stilts, with a steep gable roof with curved ends, a ladder to the veranda.", "a cloth awning over the veranda", "casa"),
  "centro": ("A royal palace hall: an audience hall of whitewashed brick with a tiered roof of brown and dark green glazed tiles with curved finials, a short white wall with leaf-shaped merlons in front.", None, "capital"),
  "cuartel": ("A long barracks of whitewashed brick with a tiered brown tiled roof, swords and spears in racks under the veranda.", None, "produccion"),
  "campo_tiro": ("A teak shelter on stilts with bows and quivers hanging, two straw targets on wooden stands beside it.", None, "produccion"),
  "taller": ("An open teak workshop with a tiled roof on posts, logs, solid wooden wheels and a half-built gun carriage inside.", None, "produccion"),
  "torre": ("A small square fort of whitewashed brick with leaf-shaped merlons along the top and one small cannon.", None, "torre"),
  "fortaleza": ("A polygonal brick fort with whitewashed walls topped by leaf-shaped merlons and cannons in the openings, a small tiered-roof gate.", None, "torre"),
  "almacen_mina": ("An open-sided shed with a tiled roof on wooden posts, rows of drying bricks and a round brick kiln beside it.", None, ""),
  "kraal": ("A square corral of thick upright teak logs with a narrow gate and a raised wooden watching platform on stilts with a small roof.", None, "produccion"),
  "barrio_japones": ("A Japanese-style wooden house with a dark tiled roof and paper screens, a small wooden gate and a fence.", "noren cloth curtains hanging in the doorway", "produccion"),
  "barrio_portugues": ("A whitewashed Portuguese-style two-story house with a clay tile roof and wooden balconies, a small warehouse beside it.", None, "produccion"),
  "barrio_chinos": ("A Chinese-style shophouse of brick with a curved grey tiled roof and wooden shutters, a small warehouse beside it.", "cloth lanterns and cloth banners at the door", "produccion"),
  "mercado": ("A row of wooden market stalls under palm-thatched shades on posts, with fruit, rice and pottery on low tables.", "cloth awnings over two stalls", "mercado"),
  "wat": ("A Khmer-style corncob-shaped central tower (prang) of brick and white stucco on a tall stepped base, four smaller prangs at the corners, a low white wall around. No statues, no images of the Buddha.", False, "hito"),
  "kraal_real": ("A royal elephant stockade of thick teak logs in a square, a royal pavilion on tall stilts with a tiered roof at one side.", None, "hito"),
  "puerto_real": ("A royal port warehouse of teak raised on stilts on a long wooden wharf, rows of large brown glazed storage jars and bales.", None, "hito"),
  "fortaleza_rio": ("A whitewashed brick fortress: high walls with leaf-shaped merlons, a polygonal bastion with cannons and a gate with a tiered roof.", None, "hito"),
  "junco_tributo": ("A large Chinese-style junk ship with sails of stiff battened matting and a high stern, resting beside a short wooden wharf with stacked crates.", "pennants at the mast tops", "hito"),
  "guardia_extranjera": ("A barracks block: a Siamese barracks hall with a tiered roof joined to a whitewashed European-style house and a Japanese-style house around a small court, two cannons in front.", None, "hito"),
  "maravilla": ("The walled city of Ayutthaya as one compact model: a long whitewashed brick wall with leaf-shaped merlons, an octagonal brick fort at one corner and palace halls with tiered brown roofs inside.", "flags on tall poles on the fort and the gate", "maravilla"),
 },
}

# Los que ya tenían modelo del pipeline (proceso/54): pieza nueva con sufijo, el viejo queda _v1.
VIEJOS = {("tawantinsuyu", "casa"), ("tawantinsuyu", "cuartel"), ("mapuches", "casa"), ("mapuches", "lof"),
          ("guaranies", "casa"), ("guaranies", "centro"), ("etiopia", "casa"), ("etiopia", "centro"),
          ("palmares", "casa"), ("palmares", "centro"), ("ayutthaya", "casa"), ("ayutthaya", "centro")}

# Reintentos: semilla nueva por pieza (la imagen y el modelo anteriores quedan como _v1).
SEMILLA = {"tawantinsuyu_casa_rojo": 8, "tawantinsuyu_cuartel_rojo": 8, "tawantinsuyu_kallanka_real": 9,
           "guaranies_mision": 8, "guaranies_tava": 8, "guaranies_maravilla": 8,
           "etiopia_centro_rojo": 8, "etiopia_corte_nueva": 8, "etiopia_cuartel": 8, "etiopia_mercado": 8, "etiopia_alianza": 8}
SEMILLA.update({f"ayutthaya_{t}": 8 for t in ("casa_rojo", "centro_rojo", "cuartel", "campo_tiro", "taller", "torre", "fortaleza",
               "almacen_mina", "kraal", "barrio_japones", "barrio_portugues", "barrio_chinos", "mercado", "wat", "kraal_real",
               "puerto_real", "fortaleza_rio", "junco_tributo", "guardia_extranjera", "maravilla")})
# Piezas con verde propio (no se recorta el verde de la vista: copas de araucaria).
CON_VERDE = {"mapuches_rewe_monte"}


# --- Segunda pasada (pedido del autor tras ver el Tawantinsuyu: «parece medieval europeo») ---
# Reglas históricas por pueblo, al frente del prompt (FLUX schnell corta lo largo), un solo
# edificio por referencia y vista de tres cuartos baja, no desde arriba.
MARCO2 = ("One single building, three-quarter view from a low angle just above eye level, the whole building visible and "
          "centered, isolated on a plain flat light grey background, no ground, no grass, no terrain, no people.")
REGLAS = {
    "tawantinsuyu": ("Inca architecture: walls of grey fieldstone or finely fitted polygonal stone blocks, trapezoidal doorways "
                     "and trapezoidal niches, steep roofs of thick bundled golden ichu straw thatch with visible thickness and "
                     "ragged edges. No crenellations, no battlements, no round towers, no conical tower caps, no timber "
                     "framing, no wooden shingles, no roof tiles, no chimneys, no windows with frames."),
}
# Tipos que la segunda pasada no rehace: recintos amurallados grandes que Hunyuan aplasta en
# «barriles». Quedan con su maqueta y en la lista de candidatos a Meshy.
MESHY = {"tawantinsuyu": {"qorikancha", "pukara_mayor", "aqllawasi", "vilcabamba", "kallanka_real"}}
E2 = {
 "tawantinsuyu": {
  "casa": "A small rectangular one-room house of grey fieldstone with one trapezoidal doorway and two trapezoidal wall niches, a very steep gable roof of thick ichu straw thatch.",
  "centro": "A large Inca great hall (kallanka) of finely fitted stone blocks, long and tall, with a row of four tall trapezoidal doorways on its long side and a huge steep hipped roof of thick ichu straw thatch.",
  "cuartel": "A long rectangular barracks hall of grey fieldstone with five trapezoidal doorways along its long side and a steep gable roof of thick ichu straw thatch; long wooden spears lean against the wall.",
  "taller_tejido": "A small square fieldstone house with a steep ichu thatch roof and an open trapezoidal doorway, a large upright wooden backstrap loom frame standing against its front wall.",
  "almacen_madera": "A long low lean-to shed of grey fieldstone walls and a single-slope ichu thatch roof, filled with a big neat stack of split firewood logs with the round cut ends facing out.",
  "almacen_mina": "A small fieldstone workshop with a steep ichu thatch roof beside a big stepped pile of large cut grey stone blocks, lumps of green copper ore at its foot.",
  "qollqa": "A row of three small round fieldstone storehouses with conical ichu straw thatch roofs, standing side by side on a low stone terrace, each with one small square opening.",
  "campo_tiro": "A small rectangular fieldstone shelter with a steep ichu thatch roof and an open front, slings hanging from a wooden pole beside it and a heap of round sling stones.",
  "torre": "A small Inca lookout post: a square terraced platform of three stepped fieldstone levels with a stair, a small square fieldstone hut with a steep ichu thatch roof on the top level.",
  "fortaleza": "An Inca hill fort (pukara) as a compact model: three massive stepped terrace walls of huge fitted stone blocks in a zigzag plan, a fieldstone barracks with a steep ichu thatch roof on the top terrace.",
  "mercado": "An open market shelter: a long fieldstone building with an open front of trapezoidal pillars and a steep ichu thatch roof, woven cloths with potatoes, maize and clay jars laid out in front.",
  "ushnu": "An ushnu: a stepped square platform of three levels of finely fitted stone blocks with a central staircase and a low stone seat on top.",
  "maravilla": "Ollantaytambo as one compact monument: long stepped agricultural stone terraces climbing to a top platform with a wall of six enormous pink granite monoliths, a fieldstone storehouse with steep ichu thatch on one side.",
 },
}
ROJO2 = {
    "tawantinsuyu": "a wide woven cloth band wrapped around the walls just under the thatch and woven cloth curtains in the doorways",
}
ROJO_PIEZA2 = {"tawantinsuyu_torre": "a wide cloth band around the walls of the hut and a cloth pennant on a pole beside it"}
# Elegidas entre las candidatas 21 y 22 (img/candidatas_tawantinsuyu.jpg): siluetas distintas entre sí.
SEMILLA2 = {"tawantinsuyu_casa_rojo": 22, "tawantinsuyu_centro": 22, "tawantinsuyu_cuartel_rojo": 22,
            "tawantinsuyu_taller_tejido": 21, "tawantinsuyu_almacen_madera": 21, "tawantinsuyu_almacen_mina": 21,
            "tawantinsuyu_qollqa": 22, "tawantinsuyu_campo_tiro": 22, "tawantinsuyu_torre": 21,
            "tawantinsuyu_fortaleza": 21, "tawantinsuyu_mercado": 22, "tawantinsuyu_ushnu": 21, "tawantinsuyu_maravilla": 21}
TEXTURA_PX2 = 2048
# Paint corre el rojo al carmesí (330–345°): tono más ancho donde los techos no son rojizos.
MASCARA2 = {"tawantinsuyu": {"tono": 22}}  # Paint a 2048 para que la paja no se vuelva una lámina lisa


def prompt2(civ, tipo, que, rojo):
    color = SIN_ROJO if rojo is False else ROJO.format(rojo=rojo or ROJO2.get(civ, ROJO_CIV[civ]))
    return f"{{estilo}} {que} {REGLAS[civ]} {color} {MARCO2}"


def prompt(civ, tipo, que, rojo):
    if rojo is False:
        color = SIN_ROJO
    else:
        color = ROJO.format(rojo=rojo or ROJO_CIV[civ])
    return f"{{estilo}} {que} {color} {MARCO} {ARQ[civ]}"


# Prueba de Hunyuan 2mv: hoja con frente y costado del mismo edificio (misma semilla de FLUX).
MV = {
 "tawantinsuyu_casa": ("casa", "casa", "A small rectangular one-room house of grey fieldstone with one trapezoidal doorway and two trapezoidal wall niches, a very steep gable roof of thick ichu straw thatch."),
 "tawantinsuyu_cuartel": ("cuartel", "produccion", "A long rectangular barracks hall of grey fieldstone with five trapezoidal doorways along its long side and a steep gable roof of thick ichu straw thatch."),
}
HOJA_MV = ("Architectural reference sheet for 3D modeling of one building shown twice side by side at eye level, flat "
           "orthographic views: on the left the front elevation seen straight from the front, on the right the side "
           "elevation seen straight from its left side; the same building, same size, same materials in both views.")


def main():
    d = json.loads(F.read_text())
    piezas = d["piezas"]
    n = 0
    for civ, eds in E.items():
        for tipo, (que, rojo, cat) in eds.items():
            clave = f"{civ}_{tipo}" + ("_rojo" if (civ, tipo) in VIEJOS else "")
            semilla = SEMILLA.get(clave, piezas.get(clave, {}).get("referencia", {}).get("receta", {}).get("semilla", 7))
            pasada2 = civ in E2 and tipo in E2[civ]
            if pasada2:
                semilla = SEMILLA2.get(clave, 21)
            pieza = {
                "tipo": "edificio",
                "edificio": "maravilla" if tipo.startswith("maravilla") else tipo,
                "categoria": cat,
                "civ": civ,
                "proceso": "58",
                "rojo": rojo is not False,
                "referencia": {
                    "imagen": f"/mnt/games/01_Projects/comfyui/output/edificios_58{'_v2' if pasada2 else ''}/{clave}_{semilla}.png",
                    "receta": {"semilla": semilla, "ancho": 768, "alto": 768,
                               "prompt": prompt2(civ, tipo, E2[civ][tipo], ROJO_PIEZA2.get(clave, rojo)) if pasada2 else prompt(civ, tipo, que, rojo)},
                    # Sin el pasto o la tierra que FLUX pone igual bajo el edificio (proceso/50).
                    "vistas": {"front": {"margen": 0.06} if clave in CON_VERDE else {"margen": 0.06, "quitar": ["verde"]}},
                },
                "forma": {"modelo": "hy-mini-turbo", "semilla": 12345, "octree": 256},
                "textura": "auto",
                "caras": 6000 if cat in ("hito", "maravilla", "capital") else 4500,
                "suelo_pct": 3,
                "destino": f"assets/generados/modelos/local/{civ}_{tipo}.glb",
            }
            # Conservar ajustes hechos a mano en una pieza ya escrita (reintentos, vistas, suelo).
            viejo = piezas.get(clave, {})
            for k in ("intento", "suelo_pct", "caras", "forma"):
                if k in viejo:
                    pieza[k] = viejo[k]
            if civ in MESHY and tipo in MESHY[civ]:
                pieza["meshy"] = True  # candidato a Meshy: no se conecta
            if pasada2:
                pieza["pasada"] = 2
                pieza["textura_px"] = TEXTURA_PX2
                pieza["mezcla"] = True  # techos de la referencia (gen3d_mezcla.py): la paja no se alisa
                pieza["suelo_pct"] = 6  # la sombra de FLUX dejaba una lámina al pie
                pieza["mascara"] = MASCARA2.get(civ, {})
            piezas[clave] = pieza
            n += 1
    for clave, (tipo, cat, que) in MV.items():
        civ = clave.split("_")[0]
        piezas[clave + "_mv"] = {
            "tipo": "edificio", "edificio": tipo, "categoria": cat, "civ": civ, "proceso": "58", "rojo": True,
            "prueba": "mv",
            "referencia": {
                "imagen": f"/mnt/games/01_Projects/comfyui/output/edificios_58_v2/{clave}_mv_21.png",
                "receta": {"semilla": 21, "ancho": 1152, "alto": 768,
                           "prompt": f"{{estilo}} {HOJA_MV} {que} {REGLAS[civ]} {ROJO.format(rojo=ROJO2[civ])} "
                                     "Plain flat light grey background, no ground, no grass."},
                "vistas": {"front": {"recorte": [0, 0, 0.5, 1], "margen": 0.06, "quitar": ["verde"]},
                           "left": {"recorte": [0.5, 0, 1, 1], "margen": 0.06, "quitar": ["verde"]}},
            },
            "forma": {"modelo": "hy-mv-turbo", "semilla": 12345, "octree": 256},
            "textura": "auto", "caras": 4500, "suelo_pct": 6, "textura_px": TEXTURA_PX2, "mezcla": True,
            "mascara": MASCARA2.get(civ, {}),
            "destino": f"assets/generados/modelos/local/pruebas/{clave}_mv.glb",
        }
    F.write_text(json.dumps(d, ensure_ascii=False, indent=1) + "\n")
    print(n, "piezas")


if __name__ == "__main__":
    main()
