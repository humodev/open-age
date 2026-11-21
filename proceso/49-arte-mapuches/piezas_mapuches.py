# Piezas mapuches (lo ejecuta armar_piezas.py con j, ZONA ya definidos). Lista real de
# data/civs/mapuches.json: unidades comunes con su nombre, unidades_nuevas, edificios, hitos y saberes.
# Historiadores (proceso/25, 01-america-latina R4 y R5; arte_hitos): el rewe solo en el nguillatuwe, y acá
# ni eso; sin machi, kultrun, canelo ni toki kura; nada sagrado como arma; la «ruka de guerra» no tiene
# registro: se muestra el lugar de junta, no una casa de guerra.
Z = ZONA
CABALLO = "a sturdy compact brown Criollo horse"
CHILIHUEQUE = ("a chilihueque, the native camelid of the Mapuche: a llama-like animal with a long neck, a small head, "
               "tall upright banana-shaped ears and thick shaggy white and brown wool, shorter and woollier than a llama")
CIRC = "woven wool headband (trarilonko)"

j.unidad("aldeano_m", "Che (aldeano, hombre)", f"A farmer working the soil with a long wooden digging stick with a pointed end. He wears {Z} over a wrapped wool loincloth, and a plain {CIRC}.")
j.unidad("aldeano_f", "Che (aldeana, mujer)", f"A woman spinning wool while standing: a long thin wooden spindle in one hand, a bundle of raw cream wool held up in the other. She wears a long black wool dress and {Z} as a shawl over her shoulders, pinned at the chest.", mujer=True)
j.unidad("comerciante_m", "Conchavador (hombre)", f"A frontier trader leading {CABALLO} by a rawhide rope; the horse carries a load of folded woven ponchos tied with rope. He wears {Z} and a plain {CIRC}.", nota="Conchavo de ganado y ponchos, siglo XVIII.")
j.unidad("comerciante_f", "Conchavadora (mujer)", f"A woman trader holding a stack of folded woven ponchos with stepped geometric patterns in black and white. She wears a long black wool dress and {Z} as a shawl pinned at the chest.", mujer=True, nota="Las mujeres tejían los ponchos del conchavo.")
j.unidad("explorador", "Werken (mensajero)", f"A messenger walking fast, holding a knotted wool cord in one hand and a short walking staff in the other. He wears {Z} and a plain {CIRC}.", semilla=19, intento=2, nota="El pron, la cuerda de nudos para contar los días hasta la junta.")
j.unidad("guerrero", "Weichafe", f"A warrior holding a heavy wooden club with a thick curved head, ready to strike. He wears {Z} cut short at the waist, a {CIRC}, and leather sandals.")
j.unidad("hondero", "Arquero", f"An archer drawing a short wooden bow, a quiver of cane arrows at his back. He wears {Z} cut short at the waist and a {CIRC}.")
j.unidad("lancero", "Lanza larga", f"A pikeman holding upright a very long lance of colihue cane, twice his height, with a sharp fire-hardened point. He wears {Z} cut short at the waist and a {CIRC}.", semilla=19, intento=2, nota="La lanza de colihue (waiki).")
j.objeto_unidad("ariete", "Ariete", "A heavy tree trunk battering ram with a sharpened point and rawhide rope handles along its sides, lying on two log rollers.", semilla=29, intento=3)
j.unidad("jinete", "Kona montado", f"A rider on {CABALLO}, riding with a sheepskin saddle pad, holding a long colihue cane lance. He wears {Z} and a {CIRC}.", montado=True)
j.unidad("arcabucero", "Arcabucero", f"A warrior holding a captured Spanish arquebus, a long matchlock gun with a wooden stock, a smoking slow-match cord in his hand. He wears {Z} and a {CIRC}.")
j.unidad("guardia", "Guardia (élite, edad IV)", f"A veteran warrior holding a heavy wooden club, wearing a hardened rawhide cuirass laced at the sides over {Z}, and a captured steel Spanish morion helmet.")
j.unidad("guardia_distancia", "Guardia de distancia (élite, edad IV)", f"A veteran archer holding a short bow and an arrow, wearing a hardened rawhide cuirass over {Z} and a rawhide helmet.")
j.animal("rebano", "Chilihueque (rebaño)", f"A single {CHILIHUEQUE}, with red wool tassels tied to its ears.")
j.unidad("incendiarios", "Incendiarios", f"A warrior running with a burning torch made of a bundle of dry reeds tied together, flames and smoke trailing behind. He wears {Z} cut short at the waist and a {CIRC}.", nota="La quema de fuertes y ciudades en el alzamiento de 1598–1604.")
j.unidad("infanteria_montada", "Weichafe montado", f"A warrior on {CABALLO}, riding bareback, holding a heavy wooden club, about to jump down to fight on foot. He wears {Z} and a {CIRC}.", montado=True, nota="Infantería montada: va a caballo y pelea a pie.")
j.unidad("kona_waiki", "Kona de waiki (edad IV)", f"A heavy lancer on {CABALLO} charging with a very long colihue cane lance with an iron point, wearing a hardened rawhide cuirass over {Z}, and a rawhide helmet.", montado=True)
j.animal("cabeza", "Cabeza de ganado", "A single brown and white cow with short horns, the cattle of the Spanish frontier, walking.", nota="Ganado arreado en un malón.")

# 2 · Edificios: un ícono por edificio.
j.edif("lof", "Lof (centro)", "A Mapuche family settlement: three large oval thatched houses around an open yard, a small wooden pole corral with a few animals, firewood stacked, a garden of potatoes and maize.", nota="No hay capital: cada lof es un centro chico.")
j.edif("casa", "Ruka (casa)", "A single large oval Mapuche house with a thick rounded thatched roof of golden grass reaching almost to the ground, a small low doorway, smoke rising from a hole at the top of the roof.")
j.edif("granja", "Chacra (granja)", "A field of potatoes, maize and quinoa plants in rows at the edge of the forest, a small thatched shelter and a wooden digging stick leaning on it.")
j.edif("cuartel", "Ruka de guerra (junta)", "A long open-sided shelter of wooden posts with a thatched gable roof in a small forest clearing, a rack of long cane lances leaning against it, wooden clubs on the ground.", semilla=19, intento=2, nota="Historiadores (01 R5): no hay registro de casas de guerra; se muestra el lugar de junta.")
j.edif("corral", "Corral", "A large round corral of rough wooden poles and branches on a green meadow, a few brown and white cows and a chilihueque inside, a small thatched shelter beside it.")
j.edif("fortaleza", "Pukara (fortaleza)", "A frontier hill fort of wood and earth on top of a hill: a ring of sharpened log palisade, a deep ditch and an earth bank around it, a few thatched houses inside, no stone.", nota="Pukara de madera y tierra, sin cantería (Dillehay, 2007).")
j.edif("empalizada", "Empalizada con foso", "A straight segment of a palisade of sharpened upright logs tied together, with a ditch dug in front of it.")
j.edif("puerta", "Puerta", "A wooden gate of heavy logs in a sharpened log palisade, with a ditch in front and a log bridge.")
j.edif("mercado", "Mercado", "A frontier trading place: a long open thatched shelter on posts, folded woven ponchos with stepped patterns, salt, cattle hides and clay jars laid out on cloths, two cows tied to a post.")
j.edif("hoyo", "Hoyo con estacas", "A hidden pit trap on a forest path: a square pit with sharpened wooden stakes pointing up at the bottom, half covered with branches and leaves.", nota="Peteroa y Mataquito, 1556–1557.")
j.edif("sitio_sagrado", "Sitio sagrado", "A huge old boulder covered in moss at the edge of a calm lake, with tall forest and a snowy volcano far behind, open sky.", nota="Solo el paisaje: ni rewe ni ceremonia.")
j.edif("rewe_malon", "Malón del toqui (hito)", "A large oval thatched house of a war leader, with a tall bundle of colihue cane lances leaning against it and a herd of captured cattle and horses inside a wooden pole corral beside it.", nota="Historiadores (01 R4): «Malón del toqui». Sin rewe ni toki kura.")
j.edif("rewe_lonko", "Lof del lonko (hito)", f"The large oval thatched house of a lineage head, the biggest house of the valley, with a wide wooden pole corral full of woolly white and brown llama-like camelids and cows, gardens around it.", nota="El juego le da cría de ganado. El nguillatuwe (con el rewe) queda fuera: es vida religiosa actual (C-74).")
j.edif("rewe_caballeria", "Corral de la remonta (hito)", "A very large corral of rough poles full of brown and black horses, a thatched house beside it and a hitching rail with sheepskin saddle pads and rawhide bridles hanging.", nota="Historiadores (01 R4): «Corral de la remonta».")
j.edif("rewe_monte", "Pewenal (hito)", "Three tall araucaria trees (monkey puzzle trees) with straight bare grey trunks and flat dark green umbrella-shaped crowns of spiky branches only at the very top, an oval thatched house between the trunks, piles of pine nuts in baskets on the ground.", semilla=19, intento=2, nota="Historiadores (01 R4): «Pewenal». El pewen como alimento; sin ceremonia.")
j.edif("parlamento", "Parlamento (hito)", "A frontier treaty ground: a long wide open shelter with a thatched roof on twelve wooden posts, two long rows of wooden benches facing each other underneath, jars of drink and baskets of food laid out, horses tied nearby.")
j.edif("weichan", "Gran weichan (hito)", "A war council ground in a meadow: a ring of long colihue cane lances stuck upright in the ground around a campfire, four saddled horses waiting beside it, forest behind.", nota="Sin toki kura (consulta a comunidades, proceso/25).")
j.edif("maravilla", "El gran koyagtun (maravilla)", "A great treaty field in a wide meadow: two very long open thatched shelters facing each other across an open ground, rows of benches, many horses tied to posts, a few oval thatched houses at the edge, forest and volcano behind.", nota="Sin el rito: la consulta es imprescindible.")

# 3 · Mejoras propias: un objeto cada una.
j.mejora("coseletes_cuero", "Coseletes de cuero", "A hardened rawhide cuirass laced at the sides with leather thongs, and a rounded rawhide helmet beside it, on the ground.")
j.mejora("trigo_manzana", "Trigo y manzana", "A sheaf of golden wheat tied with cord and a woven basket full of red and green apples.")
j.mejora("hoyos_estacas", "Hoyos y estacas", "A bundle of sharpened wooden stakes tied together and a wooden digging spade lying on fresh dark soil.")
j.mejora("lawen", "Lawen (remedios)", "A bunch of fresh matico leaves, long wrinkled green leaves with orange round flower balls, and a small clay bowl with a green paste of crushed leaves.", nota="Solo el remedio, sin el sanador ni la ceremonia.")
j.mejora("arreo_tropilla", "Arreo en tropilla", "A coiled braided rawhide lasso and a short leather whip lying on a mountain path marked with many cattle hoofprints.")
j.mejora("makun", "Makuñ (el poncho)", "A finely woven wool poncho folded on a wooden bench, with bold stepped geometric patterns in red, black and white.")
j.mejora("kawellu", "Kawellu (remonta propia)", "A sheepskin saddle pad, a rawhide bridle and a braided leather rein laid over a wooden pole fence.")
j.mejora("werken_pron", "Werken y pron", "A long knotted wool cord, dark blue and cream, with a row of knots along its length, coiled on a flat stone.")

# 4 · Accesorios para el 3D.
j.prop("arma_lanza", "Lanza de colihue (waiki)", "A very long thin lance of colihue cane with a sharp fire-hardened point.")
j.prop("arma_macana", "Macana", "A heavy wooden club carved from one piece of dark hardwood: a straight handle and a thick heavy curved head.", semilla=19, intento=2)
j.prop("arma_arco", "Arco y flechas", "A short curved wooden bow strung with sinew, lying beside three cane arrows with stone points.", semilla=19, intento=2)
j.prop("arma_antorcha", "Antorcha de totora", "A torch made of a bundle of dry reeds tied with cord, burning at one end.")
j.prop("herr_palo", "Palo de cavar", "A long wooden digging stick with a pointed end.")
j.prop("herr_hacha", "Hacha", "A neolithic stone axe: a wedge-shaped head of polished dark grey stone lashed with rawhide strips to the end of a wooden handle.", semilla=29, intento=3)
j.prop("herr_canasta", "Canasta", "A round woven basket of plant fibers with a carrying strap.")
j.prop("herr_huso", "Huso", "A long thin wooden spindle with a wooden whorl and some spun cream wool.")
j.prop("herr_metawe", "Metawe (jarro)", "A Mapuche clay jug with a round body, one handle and a short spout, polished red and cream.")
j.prop("herr_lazo", "Lazo", "A coiled braided rawhide lasso.")

# 5 · Hojas por edad: aldeano y weichafe (las dos piezas 3D de persona). La edad por el equipo.
ED = ["Lof", "Rewe", "Ayllarewe", "Butalmapu"]
j.hojas("aldeano", "Che (aldeano)", ED, [
    f"Clothing: {Z}, reaching the knees, over a wrapped wool loincloth; bare head; barefoot.",
    f"Clothing: {Z}, reaching the knees, over a wrapped wool loincloth; a plain {CIRC}; leather sandals.",
    f"Clothing: {Z}, reaching the knees, over a wrapped wool loincloth; a {CIRC}; leather sandals; a woven sash with a stepped pattern and a woven bag on a strap.",
    f"Clothing: {Z}, reaching the knees, over wool trousers; a {CIRC} with hanging tassels; leather sandals; a woven sash; a second cream poncho folded over one shoulder.",
])
j.hojas("guerrero", "Weichafe", ED, [
    f"Clothing: {Z}, short, reaching the hips, over a wrapped wool loincloth; bare head; barefoot.",
    f"Clothing: {Z}, short, reaching the hips, over a wrapped wool loincloth; a {CIRC}; leather sandals; wool bands wrapped around the shins.",
    f"Clothing: a hardened rawhide cuirass laced at the sides over {Z}; a rounded rawhide helmet, worn in every view; leather sandals; wool bands around the shins.",
    f"Clothing: a hardened rawhide cuirass laced at the sides over {Z}; a captured steel Spanish morion helmet, worn in every view; leather sandals; a leather belt.",
])
