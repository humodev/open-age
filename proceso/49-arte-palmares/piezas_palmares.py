# Piezas de Palmares (lo ejecuta armar_piezas.py con j, ZONA ya definidos). Lista real de
# data/civs/palmares.json. Historiadores (proceso/25, 01 y 02; arte_hitos H-17, H-28): sin capoeira,
# berimbau ni candomblé; sin Aqualtune; sin la bandera blanca en Cucaú (imagen europea sin fuente);
# sin estandarte de Zumbi; el capitão sin glorificar a una persona (consulta a la CONAQ); la forja sin
# el rito ni la realeza del herrero; no es dendê. Gente que eligió la libertad, no escondida.
Z = ZONA
CABALLO = "a sturdy brown horse"
ESCUDO = "a round shield of woven palm fiber"

j.unidad("aldeano_m", "Palmarista (aldeano, hombre)", f"A farmer holding an iron hoe on his shoulder and a bundle of manioc stems. He wears {Z} reaching the knees and a palm-fiber cord belt.")
j.unidad("aldeano_f", "Palmarista (aldeana, mujer)", f"A woman pounding manioc in a tall wooden mortar with a long wooden pestle. She wears {Z} reaching her ankles and a plain cloth head wrap.", mujer=True)
j.unidad("comerciante_m", "Mascate (hombre)", f"A peddler walking with a large basket of palm fiber on his back, full of clay pots, palm baskets and bundles, a walking stick in his hand. He wears {Z} reaching the knees and a straw hat.", nota="Nombre a revisar por los historiadores.")
j.unidad("comerciante_f", "Mascate (mujer)", f"A woman trader carrying a wide flat basket on her head with clay pots and woven palm mats, one hand steadying it. She wears {Z} reaching her ankles.", mujer=True)
j.unidad("explorador", "Batedor", f"A forest scout walking carefully, holding a short spear and a long iron knife, looking ahead. He wears {Z} reaching the knees and a palm-fiber cord belt.")
j.unidad("guerrero", "Gente de guerra", f"A warrior holding a long iron knife (facão) and {ESCUDO}, ready to fight. He wears {Z} reaching the knees, a necklace of beads and a cloth band around the head.")
j.unidad("hondero", "Flecheiro", f"An archer drawing a long wooden bow with an arrow, a quiver of arrows at his back. He wears {Z} reaching the knees and a cloth band around the head.")
j.unidad("lancero", "Lanceiro", f"A spearman holding upright a long spear with a broad iron point and {ESCUDO}. He wears {Z} reaching the knees.")
j.objeto_unidad("ariete", "Ariete", "A heavy tree trunk battering ram with a sharpened point and rope handles along its sides, lying on two log rollers.")
j.unidad("jinete", "Jinete", f"A rider on {CABALLO}, riding with a simple leather saddle, holding a long spear. He wears {Z} and a cloth band around the head.", montado=True)
j.unidad("arcabucero", "Espingardeiro", f"A gunman holding a long matchlock gun (espingarda) with a wooden stock, a powder horn and a leather bag at his side. He wears {Z} reaching the knees.", nota="Armas de las correrías y del trato a escondidas.")
j.unidad("guardia", "Guardia (élite, edad IV)", f"A veteran defender holding a long spear with a broad iron point and a large {ESCUDO.split('a ', 1)[1]}, a leather belt with a long iron knife, a cloth cap. He wears {Z}.")
j.unidad("guardia_distancia", "Guardia de distancia (élite, edad IV)", f"A veteran gunman holding a matchlock gun, a leather bandolier with powder flasks across the chest, a cloth cap. He wears {Z}.")
j.animal("rebano", "Cerdo", "A single black and pink pig with a long snout, standing.", nota="Cerdos criados en los mocambos.")
j.unidad("zagaieiro", "Zagaieiro", f"A warrior raising a short throwing spear over his shoulder, ready to throw, two more spears in his other hand. He wears {Z} reaching the knees.")
j.unidad("guarnicao_cerca", "Guarnição da cerca (edad III)", f"A defender standing guard with a long spear and {ESCUDO}, a short row of sharpened log palisade stakes behind him. He wears {Z} reaching the knees and a leather belt.")
j.unidad("capitao_mocambo", "Capitão de mocambo (edad IV)", f"A mature war leader holding a spear with a broad iron point, a long iron knife at a leather belt, a dark cloth cap and a wrapped indigo cloth over one shoulder. He wears {Z}.", nota="Sin glorificar a una persona (consulta a la CONAQ).")

# 2 · Edificios.
j.edif("mocambo", "Mocambo", "A village in the forest: four small houses with palm-thatched roofs around a yard, a potter's kiln, palm baskets and a loom under a shade.", nota="Los oficios: herrero, alfarero, cestero, tejedor de palma.")
j.edif("centro", "Cerca real (centro)", "A town enclosed by a tall palisade of sharpened logs: many palm-thatched houses inside, a larger house with a veranda in the middle, one wooden gate.")
j.edif("casa", "Casa de palha (casa)", "A small rectangular house with walls of wattle and daub and a steep roof thatched with palm leaves, one doorway, a palm tree beside it.")
j.edif("granja", "Roça de mandioca (granja)", "A field of manioc plants in rows with maize and banana plants at the edge of the forest, a small thatched shelter.")
j.edif("almacen_alimento", "Paiol (granero)", "A granary of wattle and palm thatch raised on wooden stilts, ears of maize and sacks of manioc flour beside it.")
j.edif("almacen_mina", "Olaria (alfarería)", "An open palm-thatched shed with a dome-shaped clay kiln, rows of clay pots drying in the sun and a pile of clay.")
j.edif("cuartel", "Casa de guerra", "A long palm-thatched house with open sides, spears and bows leaning in racks, round woven shields hanging on the posts.")
j.edif("fortaleza", "Baluarte da cerca", "A bastion of thick upright logs jutting out from a palisade, a raised wooden platform behind it, sharpened stakes stuck in the ground in front.")
j.edif("empalizada", "Cerca com estrepes", "A straight segment of a palisade of sharpened logs with many short sharpened stakes stuck slanting in the ground in front of it.")
j.edif("puerta", "Puerta", "A heavy wooden gate of logs in a palisade of sharpened logs.")
j.edif("mercado", "Mercado", "An open palm-thatched shelter where goods are laid out on mats: clay pots, palm baskets, manioc flour, maize, iron tools.")
j.edif("hoyo", "Fojo com estrepes", "A hidden pit on a forest path with sharpened wooden stakes pointing up at the bottom, half covered with palm leaves and branches.", nota="Los accesos de la cerca en 1692–1694.")
j.edif("sitio_sagrado", "Sitio sagrado", "A clear forest spring falling between large mossy rocks under tall palm trees, open sky.", nota="Solo el paisaje.")
j.edif("quilombo_central", "Macaco (hito)", "A large house with walls of wattle and daub, a long veranda on wooden posts and a high palm-thatched roof, facing a wide plaza with palm trees and smaller houses around.", nota="El mocambo del rey (relatos de 1677). Sin la capilla.")
j.edif("mocambo_guerra", "Mocambo de guerra (hito)", "Huts with palm-thatched roofs on a steep forested hill, rows of sharpened stakes slanting out in front, a tall wooden lookout platform on poles.")
j.edif("cerca_real", "Cerca real en anillos (hito)", "Three rings of log palisade one inside another on a hilltop, with the gates of each ring offset, covered pits between the rings and houses in the center.", nota="Las tres cercas de la Barriga (Jorge Velho, 1692).")
j.edif("ferraria", "Ferraria grande (hito)", "A large open forge shed with a palm-thatched roof, a glowing charcoal fire, bowl bellows covered with leather, an iron anvil and finished hoes and spear points on a rack.", nota="Forja, sin el rito.")
j.edif("pacto_cucau", "Pacto de Cucaú (hito)", "A village of palm-thatched houses in straight rows, fields of maize around it, a granary on stilts and palm trees.", nota="Sin la bandera blanca (imagen europea, sin fuente).")
j.edif("guerra_zumbi", "Guerra de Zumbi (hito)", "A steep forested hill with a palisade of sharpened logs around its top, houses inside, a large wooden drum beside the gate.", nota="Sin estandarte de Zumbi: no hay fuente de época.")
j.edif("maravilla", "Cerca do Outeiro da Barriga (maravilla)", "A great forested hill, the Serra da Barriga, with three rings of log palisade around its top, many palm-thatched houses and fields inside, a lake at its foot.", nota="Los tres anillos (H-17).")

# 3 · Mejoras propias.
j.mejora("rocas_palmeiras", "Roças e palmeiras", "Yellow ears of maize, long thick brown-skinned manioc roots with white cut ends, purple sweet potatoes and short stalks of sugar cane piled on a large fan-shaped palm leaf.", semilla=19, intento=2, nota="Pindoba y catolé, no dendê.")
j.mejora("aviso_mocambos", "Aviso de los mocambos", "A tall wooden lookout platform built on four poles among palm trees, a ladder leaning on it.")
j.mejora("forja_mocambos", "Forja de los mocambos", "A pair of bowl bellows covered with leather membranes, iron tongs and a bed of glowing charcoal with a red-hot iron bar.", nota="Forja, no fundición; sin el rito del herrero.")
j.mejora("sanguar", "Sanguar", "Two short spears crossed over a round woven palm-fiber shield, lying on the ground.", nota="Esquivar flechas y tiros en orden abierto. No es capoeira (H-28).")
j.mejora("kilombo", "Kilombo", "A circle of low carved wooden stools in the shade of a large tree, spears leaning against the trunk.", nota="La institución de guerra que integraba a gente de cualquier origen; sin el rito.")
j.mejora("trato_moradores", "Trato con los moradores", "A plain undecorated cloth sack of white salt, a small plain wooden keg, two iron hoe blades and a basket of manioc flour set together on a woven palm mat.", semilla=19, intento=2)
j.mejora("hierro_angola_janga", "Hierro de Angola Janga", "Hand-forged dark iron spear points shaped like leaves and small iron arrowheads laid in a row on a flat block of wood beside a blacksmith's hammer.", semilla=19, intento=2)
j.mejora("fojos_estrepes", "Fojos e estrepes", "A bundle of sharpened wooden stakes tied together beside a small pit half covered with palm leaves.")

# 4 · Accesorios.
j.prop("arma_lanca", "Lança", "A long spear with a straight wooden shaft and a broad leaf-shaped iron point.")
j.prop("arma_zagaia", "Zagaia", "Three short throwing spears with thin wooden shafts and small iron points, tied together.")
j.prop("arma_arco", "Arco e flechas", "A long curved wooden bow with its string, lying beside two long arrows with iron points.")
j.prop("arma_facao", "Facão", "A long straight iron knife with a wide blade and a wooden handle.")
j.prop("escudo_palha", "Escudo de palha", "A round shield of tightly woven palm fiber with a wooden handle at the back.")
j.prop("arma_espingarda", "Espingarda", "A 17th-century matchlock long gun with a wooden stock and a long iron barrel.")
j.prop("herr_enxada", "Enxada", "A simple garden hoe lying flat: a wide flat rectangular iron blade, as wide as a hand, attached to the end of a long straight wooden handle.", semilla=29, intento=3)
j.prop("herr_machado", "Machado", "An axe with an iron blade fixed in a wooden handle.")
j.prop("herr_pilao", "Pilão", "A tall wooden mortar carved from a tree trunk with a long wooden pestle leaning in it.")
j.prop("herr_cesto", "Cesto", "A tall woven basket of palm fiber with a carrying strap.")

# 5 · Hojas por edad: palmarista y gente de guerra.
ED = ["Mocambo", "Palmares", "Angola Janga", "Cucaú o Quilombo"]
j.hojas("aldeano", "Palmarista (aldeano)", ED, [
    f"Clothing: {Z}, reaching the knees; a palm-fiber cord belt; bare head; barefoot.",
    f"Clothing: {Z}, reaching the knees; a necklace of beads; a plain cloth head wrap; barefoot.",
    f"Clothing: {Z}, reaching the knees; an indigo cloth wrapped over one shoulder; a necklace of beads; a woven palm bag; barefoot.",
    f"Clothing: {Z}, reaching the knees; a straw hat, worn in every view; a leather belt with a knife; an indigo cloth over one shoulder; leather sandals.",
])
j.hojas("guerrero", "Gente de guerra", ED, [
    f"Clothing: {Z}, reaching the knees; bare head; barefoot.",
    f"Clothing: {Z}, reaching the knees; a necklace of beads; an indigo cloth band around the head; a round woven shield on the back; barefoot.",
    f"Clothing: {Z}, reaching the knees; an ochre cloth sash; a leather belt with a long knife in a sheath; an indigo cloth band around the head; a round woven shield on the back; barefoot.",
    f"Clothing: {Z}, reaching the knees; a leather bandolier with a powder horn across the chest; a leather belt; a dark cloth cap, worn in every view; leather sandals.",
])
