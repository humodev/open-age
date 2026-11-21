PAKHAOMA = ("a checked cotton pha khao ma cloth in muted indigo and white, wrapped around the head and tied at the "
            "side like a low head wrap, the hair cropped short underneath; no hat")  # proceso/50: las unidades, con el paño
NGOB = ("a wide-brimmed woven palm-leaf sun hat whose crown is a low flat-topped drum, a short cylinder with a "
        "perfectly flat round top, set in the middle of a broad brim that is almost flat and dips slightly at the edge, "
        "like a flat-crowned planter's hat made of pale palm leaf and bamboo; the top of the hat is flat, never pointed")  # proceso/50: el ngob siamés, no el nón lá
# Piezas de Ayutthaya (lo ejecuta armar_piezas.py con j, ZONA ya definidos). Lista real de
# data/civs/ayutthaya.json. Historiadores (proceso/25, 03-asia; C-79): sin imágenes del Buda (ni de
# decoración, ni en el piso, ni cortadas) y sin monjes combatientes; el wat solo por su arquitectura
# (prang y viharn), pendiente de la consulta; la maravilla es la ciudad isla y Pom Phet, sin el wat del
# palacio; los edificios son seculares; mujeres phrai visibles en el campo y el mercado; el elefante sin
# la parte ritual (augurios, elefantes blancos). Las compañías extranjeras llevan su propia cara.
Z = ZONA
# Reintento de los edificios que salían con un barrio alrededor: sin el río ni las palmeras.
ARQ_SOLO = ("Secular architecture of the 17th-century Siamese kingdom of Ayutthaya: whitewashed brick and teak wood, "
            "tiered roofs of orange glazed tiles. Only this one structure, alone, with a little bare ground around it.")
from arte_gouache import U  # las compañías extranjeras: prompt propio, sin la cara siamesa
ZF = "a plain solid bright red cotton wrapped skirt (pha nung), one flat uniform red color"
CABALLO = "a small sturdy brown horse"
ELEFANTE = "a large Asian elephant"
DAP = "a straight single-edged sword (dap) with a long handle"

j.unidad("aldeano_m", "Phrai (aldeano, hombre)", f"A rice farmer holding a curved iron sickle and a sheaf of ripe golden rice. He wears {Z}, {PAKHAOMA}, and a cotton cloth over one shoulder. He is a mature man of about thirty-five with a strong adult face, a defined jaw and smile lines.", semilla=19, intento=5)
j.unidad("aldeano_f", "Phrai (aldeana, mujer)", f"A woman holding a bundle of green rice seedlings ready to transplant, her other hand on a woven basket at her hip. She wears {ZF} and a plain undyed cotton breast cloth over one shoulder.", mujer=True)
j.unidad("comerciante_m", "Cargadores del río (hombre)", f"A porter carrying a bamboo pole across his shoulder with a woven basket of goods hanging from each end, glazed jars and bolts of cloth inside. He wears {Z} and {PAKHAOMA}. He is a mature man of about thirty-five with a strong adult face, a defined jaw and smile lines.", semilla=19, intento=5)
j.unidad("comerciante_f", "Cargadores del río (mujer)", f"A market woman carrying a bamboo pole across her shoulder with a flat basket of fruit and fish hanging from each end. She wears {ZF}, a plain undyed cotton breast cloth and {PAKHAOMA}.", mujer=True, semilla=19, intento=5, nota="El arroz y el mercado, en buena parte en manos de mujeres (Reid, 1988).")
j.unidad("explorador", "Jinete explorador", f"A scout on {CABALLO}, riding with a simple saddle cloth, holding a short spear and looking ahead. He wears {Z} and a short undyed cotton jacket.", montado=True)
j.unidad("guerrero", "Infantería de dap", f"A soldier holding two straight single-edged swords (dap), one in each hand, in a fighting stance. He wears {Z}, bare chest, and a cloth band tied around the head. He is a mature man of about thirty-five with a strong adult face, a defined jaw and smile lines.", semilla=19, intento=2)
j.unidad("hondero", "Arquero", f"An archer drawing a short curved bow with an arrow, a quiver at his hip. He wears {Z}, bare chest, and a cloth band around the head. He is a mature man of about thirty-five with a strong adult face, a defined jaw and smile lines.", semilla=19, intento=2)
j.unidad("lancero", "Lancero", f"A spearman holding upright a long bamboo spear with an iron point and a small round shield of rattan. He wears {Z}, bare chest. He is a mature man of about thirty-five with a strong adult face, a defined jaw and smile lines.", semilla=19, intento=2)
j.objeto_unidad("ariete", "Ariete", "A heavy tree trunk battering ram with a sharpened point and rope handles along its sides, lying on two log rollers.")
j.objeto_unidad("catapulta", "Cañón de muralla (asedio)", "A light bronze wall cannon on a low wooden carriage with two solid wheels, a basket of iron grapeshot beside it.")
j.unidad("jinete", "Jinete", f"A rider on {CABALLO} holding a long lance, a red cotton jacket and {Z}, a round metal helmet with a pointed top.", montado=True)
j.add(U, "arcabucero", "Compañía portuguesa", "A Luso-Asian musketeer of the Portuguese company in Siamese service, holding a long matchlock musket, wearing a steel morion helmet, a white cotton shirt, a plain solid bright red cotton doublet, baggy knee breeches and a powder flask on a bandolier. He is a grown adult man in his thirties of mixed Portuguese and Southeast Asian ancestry, with a mature face and a short dark beard. Natural tones for everything except the red doublet. " + "Waist-up portrait of one single person, three-quarter view, isolated on a plain flat light grey background.", recolor=True, nota="Mestizos de la comunidad portuguesa de Ayutthaya: su propia cara.")
j.unidad("guardia", "Guardia (élite, edad IV)", f"An elite palace guard holding two straight swords (dap), wearing a red cotton jacket with gold trim over {Z}, a tall pointed lacquered helmet and a patterned silk sash.")
j.unidad("guardia_distancia", "Guardia de distancia (élite, edad IV)", f"An elite musketeer holding a long matchlock musket, wearing a red cotton jacket over {Z}, a tall pointed lacquered helmet and a powder horn at the side.")
j.animal("rebano", "Búfalo de agua", "A single dark grey water buffalo with long swept-back curved horns, standing.")
j.unidad("ngao", "Ngao (edad III)", f"A soldier holding a ngao, a long wooden pole topped by a curved single-edged blade, upright beside him. He wears a red cotton jacket and {Z}, a round metal helmet.", nota="La guja: hoja curva sobre un asta, no una alabarda.")
j.add(U, "defensores_suan_phlu", "Defensores de Suan Phlu (edad IV)", "A Chinese defender of Ayutthaya in 1767, holding a long polearm with a broad curved blade, a matchlock musket slung on his back, wearing a plain solid bright red cotton jacket, dark trousers and a cloth head wrap. He is a grown adult Chinese man in his thirties with a mature face and a long queue of black hair. Natural tones for everything except the red jacket. Waist-up portrait of one single person, three-quarter view, isolated on a plain flat light grey background.", recolor=True, nota="La comunidad china que defendió Khlong Suan Phlu: su propia cara.")
j.animal("elefante_rey", "Elefante del rey (chang luang)", f"{ELEFANTE} carrying large woven baskets and bundles of timber strapped on its back, a mahout in {Z} sitting on its neck with an iron hook.", nota="Almacén que camina; sin la parte ritual.")
j.animal("chang_suek", "Elefante de guerra (chang suek)", f"A war elephant: {ELEFANTE} with a red saddle cloth, a mahout on its neck holding a long ngao polearm, and a second soldier with a spear sitting on a small saddle behind him.")
j.add(U, "compania_japonesa", "Compañía japonesa", "A Japanese soldier of the company in Siamese service in the 17th century, holding a long spear, a katana at his belt, wearing a plain solid bright red cotton kimono-style jacket tied with a dark sash, dark hakama trousers and his hair tied in a topknot. He is a grown adult Japanese man in his thirties with a mature face. Natural tones for everything except the red jacket. Waist-up portrait of one single person, three-quarter view, isolated on a plain flat light grey background.", recolor=True, nota="Del barrio japonés: su propia cara.")

# 2 · Edificios (seculares).
j.edif("centro", "Wang (palacio)", "A royal palace compound: audience halls of whitewashed brick with tiered roofs of orange and green glazed tiles with curved finials, a white wall with leaf-shaped merlons around it, a courtyard.", nota="Palacio, sin el wat del palacio.")
j.arq = ARQ_SOLO; j.edif("casa", "Ruean (casa)", "A single house of teak wood planks raised on tall wooden stilts, with a steep gable roof with curved ends, a ladder to the veranda, a water jar beside the stairs.", semilla=19, intento=2); j.arq = ARQ
j.edif("granja", "Arrozal", "Flooded rice paddies in neat squares with green rice plants, a small canal beside them, a raised wooden hut on stilts and a water buffalo.")
j.arq = ARQ_SOLO; j.edif("almacen_mina", "Khlang din (almacén de tierra)", "An open-sided shed with a tiled roof on wooden posts, piles of clay and bricks drying in rows, a brick kiln beside it.", semilla=19, intento=2); j.arq = ARQ
j.arq = ARQ_SOLO; j.edif("campo_tiro", "Sanam ying thanu (campo de tiro)", "An archery ground with straw targets on wooden stands, a teak shelter on stilts with bows and quivers hanging, a low bamboo fence.", semilla=19, intento=2); j.arq = ARQ
j.edif("taller", "Taller de asedio", "An open teak workshop with a tiled roof, logs, solid wooden wheels and a half-built gun carriage inside.")
j.edif("cuartel", "Cuartel de la guardia", "A long barracks of whitewashed brick with a tiered orange-tiled roof, swords and spears in racks under the veranda.")
j.arq = ARQ_SOLO; j.edif("torre", "Fortín de río", "A small square fort of whitewashed brick on a riverbank, with leaf-shaped merlons along the top and one small cannon.", semilla=19, intento=2); j.arq = ARQ
j.edif("fortaleza", "Pom (fuerte de ladrillo)", "A large polygonal brick fort with whitewashed walls topped by leaf-shaped merlons (bai sema), cannons in the openings, standing at a river corner.")
j.arq = ARQ_SOLO; j.edif("empalizada", "Empalizada", "A straight segment of a palisade of teak logs tied together.", semilla=19, intento=2); j.arq = ARQ
j.arq = ARQ_SOLO; j.edif("puerta", "Puerta", "A wooden gate of teak logs in a log palisade.", semilla=19, intento=2); j.arq = ARQ
j.arq = ARQ_SOLO; j.edif("muralla", "Kamphaeng (muralla)", "A straight segment of a thick whitewashed brick wall topped by a row of leaf-shaped merlons (bai sema).", semilla=19, intento=2); j.arq = ARQ
j.edif("puerta_piedra", "Pratu (puerta de la muralla)", "A gateway in a thick whitewashed brick wall with leaf-shaped merlons, a heavy wooden double door and a small tiered roof above it.")
j.arq = ARQ_SOLO; j.edif("torre_muralla", "Atalaya de la muralla", "A small square brick watchtower on a whitewashed wall with leaf-shaped merlons.", semilla=19, intento=2); j.arq = ARQ
j.edif("mercado", "Mercado", "A riverside market: wooden stalls under palm-thatched shades on the bank and small boats loaded with fruit, rice and pottery at the edge of the water.")
j.edif("sitio_sagrado", "Sitio sagrado", "A huge old rain tree with a wide spreading crown standing alone at a bend of a wide brown river, rice fields around, open sky.", nota="Solo el paisaje.")
j.edif("kraal", "Kraal de elefantes", "A large corral of thick upright teak logs with a narrow gate, two elephants inside, a raised wooden platform for watching beside it.")
j.edif("barrio_japones", "Barrio japonés", "A riverside quarter of Japanese-style wooden houses with dark tiled roofs and paper screens, a small wooden wharf with a boat.")
j.edif("barrio_portugues", "Barrio portugués", "A riverside quarter of whitewashed Portuguese-style houses with red clay tile roofs and wooden balconies, a warehouse and a small wharf.", nota="Sin la iglesia ni la cruz.")
j.edif("wat", "Wat Mahathat (hito)", "A Khmer-style corncob-shaped central tower (prang) of brick and white stucco on a tall stepped base, four smaller prangs at the corners, and a hall with tiered red and orange tiled roofs in front, inside a low white wall.", nota="Solo la arquitectura, sin imágenes del Buda; pendiente de la consulta (proceso/25, 03 §4).")
j.edif("kraal_real", "Kraal real (hito)", "A royal elephant stockade of thick teak logs in a large square, a royal pavilion on tall stilts with a tiered roof overlooking it, elephants inside.")
j.edif("puerto_real", "Puerto real (hito)", "A royal river port: a long wooden wharf, warehouses of teak raised on stilts, rows of large brown glazed storage jars, bales and a sampan boat moored.")
j.edif("fortaleza_rio", "Fortaleza de la isla (hito)", "A whitewashed brick river fortress: high walls with leaf-shaped merlons, a polygonal bastion with cannons pointing at the river, and a gate with a tiered roof.")
j.edif("junco_tributo", "Junco de tributo (hito)", "A large Chinese-style junk ship with sails of stiff battened matting, a high stern and a painted eye on the bow, moored at a wharf with stacked crates.", nota="Misión a China: comercio y prestigio.")
j.edif("guardia_extranjera", "Guardia extranjera (hito)", "A quarter of the foreign companies: a Siamese barracks with a tiered roof, a whitewashed European-style house and a Japanese-style house around a parade ground, banners of several colors on tall poles and two cannons.")
j.edif("maravilla", "Krung Si Ayutthaya y Pom Phet (maravilla)", "The island city of Ayutthaya surrounded by rivers: long whitewashed brick walls with leaf-shaped merlons, an octagonal brick fort at the corner where two rivers meet, palace halls with tiered orange roofs inside, boats on the water.", nota="La ciudad isla y Pom Phet, sin el wat del palacio (C-79 a).")

# 3 · Mejoras propias.
j.mejora("khotchasat", "Khotchasat", "An elephant goad (an iron hook on a short wooden handle), a thick rope halter and a bowl of crushed medicinal herbs on a mat.", nota="Solo el saber práctico de los cornacas.")
j.mejora("ceramica_satchanalai", "Cerámica de Si Satchanalai", "A group of glazed stoneware: a green celadon jar, celadon bowls and a brown glazed bottle.")
j.mejora("recetario_narai", "Recetario de Narai y nuat", "A folding book of thick paper opened to show drawings of plants, beside a stone mortar with herbs and bundles of dried roots.")
j.mejora("arroz_crecida", "Arroz de crecida", "Tall rice plants with heavy golden heads standing in deep brown flood water.")
j.mejora("barrio_chino", "Barrio chino y puertos", "Crates of porcelain, bolts of silk and tea boxes stacked on a wooden wharf beside a coiled rope.")
j.mejora("khlong_lat", "Khlong lat", "A straight new canal cut across the neck of a wide river bend, seen from above, green fields on both sides.")
j.mejora("fundicion_real", "Fundición real", "A newly cast bronze cannon resting on wooden blocks beside a glowing clay furnace and a casting mold.")
j.mejora("astilleros_juncos", "Astilleros de juncos", "The wooden frame of a junk hull of teak on a riverside slipway, planks and tools around it.")

# 4 · Accesorios.
j.prop("arma_dap", "Dap", "A Siamese dap sword: a long straight single-edged blade with a slightly upturned tip, a small round disc guard and a long round wooden handle wrapped in cord.", semilla=19, intento=2)
j.prop("arma_ngao", "Ngao", "A long wooden pole topped by a curved single-edged blade.")
j.prop("arma_arco", "Arco", "A short curved wooden bow with its string, lying beside two arrows.")
j.prop("arma_lanza", "Lanza", "A long bamboo spear with a narrow iron point.")
j.prop("arma_mosquete", "Mosquete", "A 17th-century matchlock musket with a long iron barrel and a wooden stock.")
j.prop("herr_hoz", "Hoz", "A small hand sickle for cutting rice, shaped like a question mark: a short wooden handle and a thin curved iron blade forming a half circle.", semilla=29, intento=3)
j.prop("herr_vara", "Vara de carga", "A long bamboo carrying pole with a woven basket hanging from each end by cords.")
j.prop("herr_azada", "Azada", "A digging hoe lying on the ground: a long straight wooden handle with a broad square iron blade fixed flat at its end, the blade wider than the handle is thick, like a garden hoe.", semilla=29, intento=3)
j.prop("herr_hacha", "Hacha", "An axe with an iron blade fixed in a wooden handle.")
j.prop("herr_tinaja", "Tinaja martaban", "A large brown glazed stoneware storage jar with a wide body and four small loop handles.")

# 5 · Hojas por edad: phrai e infantería de dap.
ED = ["Mueang", "Krung Si", "Ekkarat", "Mueang Tha"]
j.hojas("aldeano", "Phrai (aldeano)", ED, [
    f"Clothing: {Z}; bare chest; bare head; barefoot.",
    f"Clothing: {Z}; bare chest; a dark cotton sash at the waist; {NGOB}, worn in every view; barefoot.",
    f"Clothing: {Z}; a short undyed cotton jacket; a patterned silk sash at the waist; barefoot.",
    f"Clothing: {Z}; a short undyed cotton jacket; a fine patterned silk cloth over one shoulder; a patterned sash; leather sandals.",
], intentos={2: 3})
j.hojas("guerrero", "Infantería de dap", ED, [
    f"Clothing: {Z}; bare chest; bare head; barefoot.",
    f"Clothing: {Z}; bare chest; a dark cotton sash; a cloth band tied around the head; barefoot.",
    f"Clothing: {Z}; a short-sleeved red cotton jacket; a round metal helmet with a pointed top, worn in every view; barefoot.",
    f"Clothing: {Z}; a red cotton jacket with gold trim; a tall pointed lacquered helmet, worn in every view; a patterned silk sash; leather sandals.",
])
