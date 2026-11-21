# Piezas guaraníes (lo ejecuta armar_piezas.py con j, ZONA ya definidos). Lista real de
# data/civs/guaranies.json. Historiadores (proceso/25; arte_hitos H-23 y H-37): sin bastones rituales
# (yvyra'i) ni mbaraka del karai; el cabildo y no la fachada de la iglesia; sin cruces; la yerba también
# fue tributo y trabajo forzado (lo dice la ficha, no se embellece).
Z = ZONA
CABALLO = "a sturdy brown Criollo horse"
PLUMAS = "a headband of short upright red and yellow parrot feathers"

j.unidad("aldeano_m", "Ava (aldeano, hombre)", f"A farmer holding a long wooden digging stick and a bundle of manioc stem cuttings for planting. He wears {Z} reaching the knees.")
j.unidad("aldeano_f", "Ava (aldeana, mujer)", f"A woman carrying a large woven basket full of manioc roots on her back, held by a strap across her forehead. She wears {Z} reaching her ankles. She is a mature woman of about thirty-five with a strong adult face, a defined jaw and smile lines.", mujer=True, semilla=19, intento=2)
j.unidad("comerciante_m", "Tropa de yerba (hombre)", f"A carrier with a large bale of dried yerba mate leaves wrapped in rawhide on his back, held by a strap, a walking stick in his hand. He wears {Z} reaching the knees. He is a mature man of about thirty-five with a strong adult face, a defined jaw and smile lines.", semilla=19, intento=2, nota="La yerba bajaba en tropas y balsas; también fue trabajo forzado.")
j.unidad("comerciante_f", "Tropa de yerba (mujer)", f"A woman carrying a large woven basket of dried yerba mate leaves on her back, held by a strap across her forehead. She wears {Z} reaching her ankles. She is a mature woman of about thirty-five with a strong adult face, a defined jaw and smile lines.", mujer=True, semilla=19, intento=2)
j.unidad("explorador", "Baqueano", f"A forest tracker walking carefully, holding a bow and two arrows, looking ahead. He wears {Z} reaching the knees and a cotton bag across the chest.", nota="Nombre en castellano, a revisar (proceso/25).")
j.unidad("guerrero", "Guerrero de macana", f"A warrior holding a macana, a long flat club of dark hardwood with sharp edges, ready to strike. He wears {Z} cut short at the thighs and {PLUMAS}.")
j.unidad("hondero", "Arquero", f"An archer drawing a very long bow of dark hardwood, as tall as he is, with a long cane arrow. He wears {Z} cut short at the thighs and {PLUMAS}.")
j.unidad("lancero", "Lancero", f"A spearman holding upright a long hardwood spear with a fire-hardened point. He wears {Z} cut short at the thighs and {PLUMAS}.")
j.objeto_unidad("ariete", "Cañón de tacuara (asedio)", "A small cannon made of a thick tube of giant tacuara bamboo, tightly wrapped with strips of rawhide, resting on a low wooden frame.", nota="Ocupa la ranura del ariete y de la catapulta: un solo arte (Mbororé, 1641).")
j.unidad("jinete", "Jinete", f"A rider on {CABALLO} with a sheepskin saddle pad, holding a long wooden lance. He wears {Z} and a cotton band around the head.", montado=True)
j.unidad("arcabucero", "Milicia arcabucera", f"A militia soldier holding an arquebus, a long matchlock gun with a wooden stock, a powder horn at his side. He wears {Z} over white cotton trousers.")
j.unidad("guardia", "Guardia (élite, edad IV)", f"A veteran warrior holding a large macana, a flat club of dark hardwood, wearing a tall crown of upright red, yellow and blue feathers, a feather cape over the shoulders and {Z}.")
j.unidad("guardia_distancia", "Guardia de distancia (élite, edad IV)", f"A veteran archer holding a very long hardwood bow and arrows, wearing a tall crown of upright red and yellow feathers and {Z}.")
j.animal("rebano", "Animal del rebaño (vaca)", "A single brown cow with long horns, the cattle of the mission estancias, standing.")
j.objeto_unidad("yga", "Ygá (canoa)", "A long dugout canoe carved from a single tree trunk, with two wooden paddles inside, floating on calm brown river water.")
j.unidad("caballeria_mision", "Caballería de las misiones (edad IV)", f"A mission militia lancer on {CABALLO}, holding a long lance with an iron point, wearing a broad-brimmed straw hat, {Z} and white cotton trousers, a leather belt.", montado=True, nota="Guerra Guaranítica, 1754–1756.")
j.unidad("kaaguygua", "Ka'aguygua (edad IV)", f"A forest warrior crouching low, ready to ambush, holding a macana and a long bow, red body paint lines on the arms, {PLUMAS}. He wears {Z} cut short at the thighs.", semilla=19, intento=2, nota="«Los del monte», que resistieron la reducción.")

# 2 · Edificios.
j.edif("centro", "Oga guasu (centro)", "A very long communal house: a huge steep thatched roof of grass reaching to the ground, wooden posts, several low doorways along its side, a cleared yard of red earth in front.")
j.edif("casa", "Oga (casa)", "A small house with walls of tacuara bamboo canes and mud and a steep thatched roof of palm leaves, one low doorway, a cotton hammock tied under the eave.")
j.edif("granja", "Kokue (roza)", "A field opened in the forest: manioc plants, maize and bean vines growing together among old tree stumps, a small thatched shelter, forest around.")
j.edif("almacen_madera", "Tapyi (rancho del monte)", "An open-sided shelter of wooden posts with a thatched palm roof at the forest edge, stacks of firewood, hanging bundles of maize and baskets of fruit inside.")
j.edif("almacen_mina", "Ñai'ũ renda (lugar de la arcilla)", "An open-sided thatched shelter beside a pit of red clay, large clay pots drying in rows, piles of stones and clay in front.")
j.edif("campo_tiro", "Guyrapa róga (casa del arco)", "A small thatched shelter between tall trees, long hardwood bows and bundles of cane arrows hanging under the roof, a straw target on a post.")
j.edif("taller", "Taller de tacuara", "An open thatched workshop with piles of thick giant tacuara bamboo poles, strips of rawhide drying on a rack, a finished bamboo tube cannon on a frame.")
j.edif("cuartel", "Aty de guerra", "A gathering ground in a forest clearing: a long open-sided thatched shelter on wooden posts, long bows, spears and flat hardwood clubs leaning in racks.")
j.edif("fortaleza", "Trinchera de tacuara", "A double palisade of giant bamboo canes and logs with a trench in front, raised wooden platforms for archers behind it, a thatched house inside.")
j.edif("empalizada", "Empalizada", "A straight segment of a palisade of sharpened bamboo canes and logs tied with vines.")
j.edif("puerta", "Puerta", "A wooden gate of logs and thick bamboo canes in a palisade, with a small thatched roof above.")
j.edif("mercado", "Mercado", "An open thatched shelter on posts where goods are laid out on mats: clay pots, cotton cloth, baskets of manioc and maize, bundles of yerba mate leaves.")
j.edif("sitio_sagrado", "Sitio sagrado", "A small waterfall falling into a clear pool among large mossy rocks in the subtropical forest, ferns and palm trees, open sky.", nota="Solo el paisaje.")
j.edif("karai_palabra", "Casa del karai (hito)", "A very large communal house with a thatched roof reaching the ground, a wide swept plaza of red earth in front with a ring of low wooden stools and a small fire.", nota="Sin yvyra'i ni mbaraka (H-23): la casa y la plaza.")
j.edif("aty_guasu", "Aty guasu (hito)", "A wide plaza surrounded by four long thatched communal houses, a fire in the middle and a large ring of wooden benches and stools around it.")
j.edif("mision", "Pueblo de misión (hito)", "A mission town square: long rows of houses with clay tile roofs and wide verandas on wooden columns around a grassy square, a workshop with a loom and a carpenter's bench under a veranda.", nota="Sin la iglesia ni la cruz (H-37): las casas, las galerías y los talleres.")
j.edif("monte", "Monte libre (hito)", "A hidden clearing in the dense forest: low thatched shelters under huge trees, a cotton hammock between two trunks, a small fire, almost covered by leaves.")
j.edif("tava", "Tava fortificada (hito)", "A fortified mission town: rows of red sandstone houses with tile roofs and verandas, surrounded by a palisade of logs with a gate and a trench.", nota="Sin la fachada de la iglesia ni la cruz.")
j.edif("yvy_marane", "Ñande retã (hito)", "A defensive earthwork: a trench and an earth bank topped by a log palisade, two bamboo tube cannons wrapped in rawhide aimed over it, forest behind.", nota="«Esta tierra tiene dueño» (Sepé Tiaraju), Guerra Guaranítica.")
j.edif("maravilla", "La plaza y el cabildo de la tava (maravilla)", "A two-story town hall of red sandstone with a long upper gallery on wooden columns and a tile roof, facing a wide grassy square, workshops with verandas on both sides.", nota="El cabildo y no la iglesia (H-37). Vía misión.")
j.edif("maravilla_monte", "Aldea grande del monte (maravilla)", "A large village in the tall forest: eight long communal houses with thatched roofs reaching the ground, arranged in a ring around a wide plaza of red earth, huge trees around.", nota="Vía monte. Sin bastones rituales (H-23).")

# 3 · Mejoras propias.
j.mejora("kokue", "Kokue (roza en policultivo)", "A pile of long brown manioc roots, yellow ears of maize, green bean pods and a round squash together on a woven mat.", semilla=19, intento=2)
j.mejora("canoas_rio", "Ygá (canoas)", "Two carved wooden canoe paddles crossed over each other on a sandy riverbank.")
j.mejora("poha_nana", "Pohã ñana (remedios del monte)", "Bundles of fresh medicinal herbs and leaves tied with cord, beside an open gourd bowl.")
j.mejora("oga_takuara", "Óga de takuára", "A stack of long giant tacuara bamboo poles tied together and a big bundle of dry thatching grass.")
j.mejora("defensa_mborore", "Defensa de Mbororé", "A thick bamboo tube cannon tightly wrapped in strips of rawhide, resting on a riverbank beside a dugout canoe.")
j.mejora("kaa_plantada", "Ka'a plantada", "Rows of young yerba mate seedlings with glossy green leaves growing in a planted nursery bed, a wooden hoe beside them.")
j.mejora("kaa_kaaguy", "Ka'a ka'aguy (yerba del monte)", "A woven basket full of freshly cut branches of wild yerba mate with glossy green leaves, on the forest floor.")
j.mejora("uy_hata", "U'y hatã (flecha dura)", "A bundle of long cane arrows with fire-hardened wooden points and carved bone points, tied with cord.")
j.mejora("imprenta", "Imprenta de las misiones", "A wooden hand printing press with a large screw, a carved wooden printing block and a stack of blank paper beside it.")
j.mejora("aty", "Aty (la asamblea)", "A ring of low carved wooden stools around a small campfire on swept red earth.")

# 4 · Accesorios.
j.prop("arma_macana", "Macana", "A long flat club of dark hardwood with sharp edges and a narrow handle.")
j.prop("arma_arco", "Arco largo", "A very long curved bow of dark hardwood with its string, lying beside one long cane arrow.", semilla=19, intento=2)
j.prop("arma_lanza", "Lanza", "A long hardwood spear with a fire-hardened point.")
j.prop("arma_arcabuz", "Arcabuz", "A 17th-century matchlock arquebus with a wooden stock, a long iron barrel and a slow-match cord.")
j.prop("herr_palo", "Palo de cavar", "A long wooden digging stick with a flattened pointed end.")
j.prop("herr_hacha", "Hacha", "A neolithic stone axe: a wedge-shaped head of polished dark grey stone lashed with plant fiber to the end of a wooden handle.", semilla=19, intento=2)
j.prop("herr_ajaka", "Ajaka (canasta)", "A deep woven basket of palm fiber with a long carrying strap for the forehead.")
j.prop("herr_huso", "Huso", "A thin wooden spindle with a round clay whorl and some spun white cotton thread.")
j.prop("herr_japepo", "Japepo (olla)", "A large Guaraní clay cooking pot with a round body and a surface covered in rows of thumbnail-pressed corrugations.")
j.prop("herr_remo", "Remo", "A carved wooden canoe paddle with a long handle and a leaf-shaped blade.")

# 5 · Hojas por edad: aldeano y guerrero de macana. La edad por el equipo.
ED = ["Tekoha", "Amundá", "Mbororé", "Tava"]
j.hojas("aldeano", "Ava (aldeano)", ED, [
    f"Clothing: {Z}, reaching the knees; bare head; barefoot.",
    f"Clothing: {Z}, reaching the knees; a plain woven cotton headband; barefoot; a cotton bag on a strap across the chest.",
    f"Clothing: {Z}, reaching the knees, over loose white cotton trousers; a woven cotton sash; leather sandals.",
    f"Clothing: {Z}, reaching the knees, over loose white cotton trousers; a broad-brimmed straw hat, worn in every view; a woven sash; leather sandals.",
])
j.hojas("guerrero", "Guerrero de macana", ED, [
    f"Clothing: {Z}, short, reaching the thighs; a headband of short red feathers; barefoot.",
    f"Clothing: {Z}, short, reaching the thighs; {PLUMAS}; armbands of feathers; a necklace of seeds; barefoot.",
    f"Clothing: {Z}, reaching the knees, over white cotton trousers; {PLUMAS}; a leather belt with a pouch; barefoot.",
    f"Clothing: {Z}, reaching the knees, over white cotton trousers; a broad-brimmed straw hat, worn in every view; a leather belt with a powder horn; leather sandals.",
])
