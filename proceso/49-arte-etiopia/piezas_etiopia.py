# Piezas etíopes (lo ejecuta armar_piezas.py con j, ZONA ya definidos). Lista real de
# data/civs/etiopia.json. Historiadores (proceso/25, 02-africa; arte_hitos H-49; C-69): nada sagrado
# como bono ni como arma; sin cruces; la iglesia y el monasterio (Lalibela) quedan pendientes de C-69:
# se pintan el recinto y el bosque de la iglesia sin cruz, y el monasterio como comunidad de celdas
# y libros, sin Lalibela ni Debre Damo; Fasil Gəbbi sin las iglesias del recinto; el šotäl solo en la
# ficha; la caballería de la corte con su nombre de reserva (sin oromo hasta la consulta).
Z = ZONA
SH = "a white cotton shawl (shamma) with a thin colored woven border draped over one shoulder"
ESCUDO = "a round convex shield of thick hide"
CABALLO = "a small sturdy highland horse"

j.unidad("aldeano_m", "Gäbbar (aldeano, hombre)", f"A farmer carrying a wooden ox plough (maresha) on his shoulder: a long wooden beam with a short iron-tipped share and a handle. He wears {Z} reaching the knees and {SH}.")
j.unidad("aldeano_f", "Gäbbar (aldeana, mujer)", f"A woman carrying a large round clay water jar on her back, held by a cord across her chest. She wears {Z} reaching her ankles and a white cotton shawl over her head and shoulders. She is clearly in her mid thirties, with a long mature face, slight hollows under the cheekbones and a calm experienced look.", mujer=True, semilla=19, intento=2)
j.unidad("comerciante_m", "Mercader jabarti (hombre)", f"A Muslim caravan merchant leading a mule loaded with stacks of rectangular white salt bars (amole) wrapped in reed matting. He wears {Z}, a white cotton turban and {SH}.", nota="Jabarti: mercaderes musulmanes (Pankhurst, 1961).")
j.unidad("comerciante_f", "Mercadera (mujer)", f"A woman trader holding a woven basket filled with rectangular white salt bars (amole). She wears {Z} reaching her ankles and a white cotton shawl over her head. She is clearly in her mid thirties, with a long mature face, slight hollows under the cheekbones and a calm experienced look.", mujer=True, semilla=19, intento=2)
j.unidad("explorador", "Mensajero", f"A messenger walking fast with a long wooden staff, a small leather bag on a strap. He wears {Z} reaching the knees and {SH}.")
j.unidad("guerrero", "Jinete noble", f"A noble rider on {CABALLO} with a colorful saddle cloth, holding a long spear and {ESCUDO}. He wears {Z} and a short cape of black and white colobus monkey fur over the shoulders.", montado=True, nota="El jinete noble desde la edad I.")
j.unidad("hondero", "Jabalinero", f"A javelin thrower raising a javelin over his shoulder, ready to throw, two more javelins and {ESCUDO} in his other hand. He wears {Z} reaching the knees.")
j.unidad("lancero", "Chewa", f"A soldier holding upright a long spear with a narrow iron point and {ESCUDO} decorated with a few brass studs. He wears {Z} reaching the knees and {SH}.")
j.objeto_unidad("ariete", "Ariete", "A battering ram: a heavy log with an iron-capped point under a sloping roof of wooden planks and hides, on four solid wooden wheels.")
j.objeto_unidad("catapulta", "Pieza ligera (asedio)", "A small 16th-century bronze cannon on a two-wheeled wooden carriage, a few round iron balls beside it.", nota="Los cañones livianos que llegaron con Cristóvão da Gama (1541).")
j.unidad("jinete", "Jinete", f"A rider on {CABALLO}, holding a long spear and {ESCUDO}. He wears {Z} and {SH}.", montado=True)
j.unidad("arcabucero", "Mosquetero", f"A musketeer holding a long matchlock musket with a wooden stock, a powder horn and a leather pouch at his belt. He wears {Z} reaching the knees and {SH}.")
j.unidad("guardia", "Guardia (élite, edad IV)", f"An elite guard holding a long spear and {ESCUDO} covered with silver-colored metal plates, a lion-mane headdress around his face. He wears {Z} and a short cape of lion skin over the shoulders.")
j.unidad("guardia_distancia", "Guardia de distancia (élite, edad IV)", f"An elite musketeer holding a long matchlock musket, wearing a cape of black and white colobus monkey fur, {Z} and a white cotton sash.")
j.animal("rebano", "Cabra", "A single brown and white highland goat with short curved horns.")
j.unidad("guerrero_gasa", "Guerrero de gaša", f"An infantry warrior holding one {ESCUDO} (gasha) on his left arm and a spear with two short javelins in his right hand. He wears {Z} reaching the knees.", semilla=19, intento=2, nota="El šotäl (espada curva) queda solo en la ficha.")
j.unidad("farasanna", "Färäsäñña con cota (edad III)", f"A heavy horseman on {CABALLO} with a padded saddle cloth, wearing a long shirt of iron chain mail over {Z}, an iron helmet, holding a long spear.", montado=True)
j.unidad("caballeria_corte", "Caballería de la corte (edad IV)", f"A fast court horseman on {CABALLO} at a gallop, holding a light spear and {ESCUDO}. He wears {Z} and a white cotton shawl blowing behind him.", montado=True, nota="Nombre de reserva hasta consultar a académicos y comunidades oromo.")
j.unidad("carpa_real", "Corte en marcha", f"A court official riding a mule, holding a long staff of office, a large red cloth parasol raised above him. He wears {Z} and {SH}.", montado=True, nota="La corte se mudaba con su campamento (kätäma).")

# 2 · Edificios.
j.edif("centro", "Kätäma (corte)", "A royal camp: a large red cloth tent in the center surrounded by many smaller white tents and round thatched houses in a fixed plan, inside a thorn fence, banners on tall poles.")
j.edif("casa", "Tukul (casa)", "A single round house with a low wall of brown fieldstone and mud and a steep conical thatched roof, one wooden doorway.")
j.edif("granja", "Granja", "A field of golden teff being ploughed by a pair of oxen pulling a wooden plough, a small round thatched house at the edge.")
j.edif("almacen_alimento", "Gotära (granero)", "A large tall woven basket granary plastered with mud, standing on a stone base, with a small conical thatched roof, sacks of grain beside it.")
j.edif("almacen_madera", "Inchet bet (depósito de leña)", "An open-sided shed with a thatched roof on wooden posts, stacks of juniper logs and bundles of branches.")
j.edif("almacen_mina", "Dängay bet (casa de la piedra)", "A round stone workshop with a thatched roof, piles of cut stone blocks and baskets of earth and rocks in front.")
j.edif("establo", "Färäs bet (casa del caballo)", "A long low stable of fieldstone with a thatched roof, horses tied to a wooden rail in front, saddles on a fence.")
j.edif("cuartel", "Campamento de chewa", "A soldiers' camp: a ring of white cloth tents and two round thatched houses, spears planted upright in the ground and round hide shields leaning on them.")
j.edif("taller", "Taller de asedio", "An open workshop of fieldstone and wooden beams with a thatched roof, logs, wheels and a half-built battering ram inside.")
j.edif("torre", "Torre de la amba", "A tall round tower of brown fieldstone with a flat top and a small parapet, standing at the edge of a steep cliff.")
j.edif("fortaleza", "Fortaleza de amba", "A flat-topped mountain with sheer cliff sides (an amba), a brown stone wall along the edge at the top, a few round thatched houses on top and one narrow path climbing up.")
j.edif("empalizada", "Empalizada", "A straight segment of a fence of thick wooden stakes and thorny branches woven together.")
j.edif("puerta", "Puerta", "A wooden gate of thick planks in a fence of stakes and thorn branches.")
j.edif("muralla", "Muro de la amba", "A straight segment of a thick wall of brown fieldstone set in mud, with a flat top.")
j.edif("puerta_piedra", "Puerta de la amba", "A gateway with a round stone arch and a heavy wooden door set in a thick wall of brown fieldstone.")
j.edif("torre_muralla", "Torre del muro", "A round tower of brown fieldstone with a flat top, standing on a thick stone wall.")
j.edif("mercado", "Mercado", "An open market ground with stalls under simple thatched shades, salt bars, sacks of grain, clay pots, cotton cloth and mules.")
j.edif("sitio_sagrado", "Sitio sagrado", "A huge old wild fig tree with a wide spreading crown standing alone on a green highland meadow, flat-topped cliffs far behind, open sky.", nota="Solo el paisaje.")
j.edif("corte_nueva", "Corte nueva (cimiento)", "A new camp being laid out: wooden stakes and ropes marking the ground in a circle, rolled tents, tent poles and bundles waiting on the grass, one tent half raised.")
j.edif("gult", "Gult", "A farmstead of three round thatched houses with fields around them and a pile of rectangular white salt bars and sacks of grain stacked as tribute in front.", nota="El derecho de tributo, no un palacio.")
j.edif("iglesia", "Iglesia (hito)", "A round compound in a grove of tall old juniper and olive trees: a stone wall with a gatehouse and inside it a large round building with a gallery of wooden posts and a steep conical thatched roof.", nota="Pendiente C-69: sin cruz y sin uso como arma; el bosque y el recinto.")
j.edif("monasterio", "Monasterio (hito)", "A monastic community on a hillside: small round stone cells with thatched roofs inside a stone wall, a library hut with leather book satchels hanging, terraced gardens.", nota="Ni Lalibela ni Debre Damo (lugares vivos de peregrinación, C-69).")
j.edif("amba", "Amba fortificada (hito)", "A great flat-topped mountain with sheer cliffs, a stone wall along the rim, round houses and a storehouse on the top, and a single zigzag path to a gate.", nota="Amba Gəšän.")
j.edif("remonta", "Remonta (hito)", "A large stone-walled corral full of horses beside a long thatched stable, grooms' round houses and piles of hay.")
j.edif("gondar", "Recinto de Gondar (hito)", "A two-story castle of brown and grey stone with round corner towers topped by small domes and a taller square tower, a stone wall around it.", nota="Fasil Gəbbi, siglo XVII.")
j.edif("alianza", "Alianza con armas de fuego (hito)", "A court camp with a large red royal tent, wooden trade crates opened to show muskets, two small bronze cannons on carriages and barrels of powder.")
j.edif("maravilla", "Fasil Gəbbi (maravilla)", "The royal enclosure of Gondar: a large two-story castle of brown and grey stone with round domed corner towers and a tall square tower, a second smaller castle beside it, all inside a long stone wall with a gate.", nota="Sin las iglesias del recinto (H-49).")

# 3 · Mejoras propias.
j.mejora("maresha_tef", "Maresha y ṭef", "A wooden ox plough with an iron-tipped share lying beside a bound sheaf of golden teff grass with tiny grains.")
j.mejora("actas_geez", "Actas de tierra en ge'ez", "A single loose parchment sheet with neat lines of dark script and a round seal, lying flat beside a reed pen.", nota="Una hoja suelta con sello, no un evangeliario abierto.")
j.mejora("faws_kosso", "Fäws y kosso (remedios)", "A branch of the kosso tree with hanging clusters of pink-red flowers, beside a small clay pot and a bundle of dried herbs.", nota="Solo la farmacopea, sin oraciones ni rollos protectores.")
j.mejora("cota_malla", "Cota de malla", "A long shirt of iron chain mail with short sleeves, laid over a wooden stand.")
j.mejora("amba_fortaleza", "Amba", "A flat-topped mountain with sheer vertical cliff sides rising from a green plateau, a thin stone wall along its rim.")
j.mejora("caravanas_amole", "Caravanas de amole", "A neat stack of rectangular white salt bars (amole) bound with reed cord, on a mule's pack saddle.")
j.mejora("polvora_massawa", "Pólvora de Massawa", "A small wooden barrel of gunpowder, a curved powder horn and a leather pouch of round lead balls.")
j.mejora("orden_katama", "Orden del kätäma", "A rolled red cloth royal tent tied with ropes, a bundle of wooden tent poles and iron stakes beside it.")

# 4 · Accesorios.
j.prop("arma_lanza", "Lanza", "A long spear with a straight wooden shaft and a narrow leaf-shaped iron point.")
j.prop("arma_jabalinas", "Jabalinas", "Three short javelins with thin wooden shafts and small iron points, tied together.")
j.prop("escudo_gasa", "Gaša (escudo)", "A round convex shield of thick buffalo hide with a raised rim and a few brass studs.")
j.prop("arma_mosquete", "Mosquete", "A 17th-century matchlock musket with a long iron barrel and a wooden stock.")
j.prop("herr_maresha", "Maresha (arado)", "An Ethiopian wooden ox plough: a long beam, a single handle and a short pointed iron share.")
j.prop("herr_hoz", "Hoz", "A harvesting sickle: a thin crescent-shaped iron blade curving forward from a short straight wooden handle, side view.", semilla=19, intento=2)
j.prop("herr_hacha", "Hacha", "An axe with a narrow iron blade fixed in a wooden handle.")
j.prop("herr_ensera", "Ensera (cántaro)", "A large round black clay water jar with a narrow neck and a small handle.")
j.prop("herr_canasta", "Canasta", "A round woven grass basket with a lid, in natural straw colors with a simple dark pattern.")
j.prop("herr_huso", "Huso", "A thin wooden spindle with a round wooden whorl and some spun white cotton thread.")

# 5 · Hojas por edad: aldeano y chewa (la unidad propia para el 3D).
ED = ["Kätäma", "Gult", "Ras", "Gondar"]
j.hojas("aldeano", "Gäbbar (aldeano)", ED, [
    f"Clothing: {Z}, reaching the knees; bare head; barefoot.",
    f"Clothing: {Z}, reaching the knees; {SH}; barefoot.",
    f"Clothing: {Z}, reaching the knees, over white cotton trousers; a white shawl with a wide colorful woven border; leather sandals.",
    f"Clothing: {Z}, reaching the knees, over white cotton trousers; a white shawl with a wide colorful border; a white cotton head cloth; leather sandals; a leather bag.",
])
j.hojas("chewa", "Chewa", ED, [
    f"Clothing: {Z}, reaching the knees; bare head; barefoot; a plain hide shield on the back.",
    f"Clothing: {Z}, reaching the knees; {SH}; leather sandals; a round hide shield on the back.",
    f"Clothing: {Z}, reaching the knees, over white cotton trousers; a short cape of lion skin over the shoulders, in every view; leather sandals; a round hide shield with brass studs on the back.",
    f"Clothing: a long shirt of iron chain mail over {Z}; a lion-mane headdress around the face, in every view; leather sandals; a round hide shield with silver plates on the back.",
])
