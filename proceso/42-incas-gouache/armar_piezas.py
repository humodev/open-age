#!/usr/bin/env python3
"""Arma piezas.json: todas las piezas incas de la prueba en gouache, con la receta afinada en el
proceso 41. Primera frase = estilo (lo único que cambia si se cambia de estilo). Uso: python3 armar_piezas.py"""
import json, os
D = os.path.dirname(os.path.abspath(__file__))

# «mid-century storybook» hacía niños (medido: edad_t1 contra los v1); sin esa frase salen adultos.
ESTILO = ("Gouache painting for a historical strategy game, flat opaque color shapes, "
          "simple graphic forms, matte paper texture, limited palette.")
# Caras fijadas en las rondas de cara (sección 0): misma descripción en todas las unidades.
CARA_M = ("a grown adult Native American Quechua man from the Peruvian Andes in his early thirties, with a mature face: "
          "a very broad face, strong square jaw, defined high cheekbones, a large hooked aquiline nose, dark eyes, faint expression "
          "lines around the eyes, weathered copper-brown skin, dark brown lips the same tone as his skin, thick straight black hair "
          "cut short at the ears, a thick adult neck, broad shoulders and adult body proportions")
CARA_F = ("a grown adult Native American Quechua woman from the Peruvian Andes in her early thirties, with a mature face: "
          "a very broad round face, defined high cheekbones, a large convex aquiline nose, dark eyes, faint expression lines, "
          "weathered copper-brown skin, dark brownish lips, thick straight black hair parted in the middle in two long braids, "
          "adult shoulders and adult body proportions")
TUNICA = "a plain solid bright red sleeveless wool tunic, one flat uniform red color"  # zona del equipo
NATURAL = "Natural undyed tones for everything except the red tunic."
ENCUADRE_U = "Waist-up portrait: the head, shoulders and hands fill the frame, the tool or weapon visible next to the body, three-quarter view, plain flat dark grey-green backdrop."
LLAMA = "a llama (a woolly camelid with no hump, a long neck and tall upright banana-shaped ears)"
EDIF = ("Single building, three-quarter view from above like a strategy game icon, the whole building visible and centered, "
        "plain flat pale background. Inca architecture of the Andes: walls of grey fieldstone set in mud mortar or of finely "
        "fitted stone blocks, trapezoidal doorways and niches, steep gable roofs thatched with golden ichu grass.")
OBJ = "Single object centered, clear silhouette, plain flat pale background, three-quarter view."
PROP = "Single object for a 3D model reference, side view, centered, whole object visible, plain flat light grey background, even light."
HOJA = ("Character turnaround reference sheet for 3D modeling: the same person shown side by side in front view and in side "
        "profile view, the same headwear and clothing in every view, standing in A-pose with arms held straight and out at "
        "45 degrees from the body, open empty hands. The tunic hangs straight and loose from the shoulders.")
FONDO_H = "Even flat studio light, plain light grey background."

piezas = []
def add(seccion, id, nombre, prompt, semilla=7, w=768, h=768, recolor=False, nota=""):
    piezas.append(dict(seccion=seccion, id=id, nombre=nombre, prompt=f"{ESTILO} {prompt}", semilla=semilla,
                       w=w, h=h, recolor=recolor, nota=nota))

# 0 · Caras (ya generadas; se dejan para la página)
viejo = json.load(open(os.path.join(D, "piezas.json"), encoding="utf-8")) if os.path.exists(os.path.join(D, "piezas.json")) else []
piezas += [p for p in viejo if p["seccion"].startswith("0")]

# 1 · Unidades: un arte por unidad (ícono y retrato), túnica roja recoloreable.
U = "1 · Unidades (un arte por unidad: ícono y retrato)"
O = "/mnt/games/01_Projects/comfyui/output/incas_gouache"
V1 = {"aldeano_m", "aldeano_f", "comerciante_m", "comerciante_f", "explorador", "awqa", "hondero", "boleador", "lancero",
      "guerrero", "guardia", "guardia_distancia", "galgueros", "jinete", "jinete_manco"}  # ya generadas (no se pisan)
MENORES = {"aldeano_m", "aldeano_f", "comerciante_m", "comerciante_f", "explorador", "awqa", "hondero", "boleador",
           "lancero", "guerrero", "guardia", "guardia_distancia", "jinete_manco"}  # se leían menores de edad: van en v2
def unidad(id, nombre, que, mujer=False, semilla=7, nota=""):
    cara = CARA_F if mujer else CARA_M
    nuevo = f"{que} The figure is {cara}. {NATURAL} {ENCUADRE_U}"
    if id in V1:
        viejo = json.load(open(f"{O}/{id}_meta.json", encoding="utf-8"))["prompt"]
        piezas.append(dict(seccion=U, id=id, nombre=nombre + " · v1", prompt=viejo, semilla=semilla, w=768, h=768,
                           recolor=True, nota=("Se leía menor de edad: ver v2. " if id in MENORES else "") + nota))
        if id in MENORES:
            add(U, id + "_v2", nombre + " · v2 (adulto)", nuevo, semilla=semilla, recolor=True,
                nota="Rehecha: adulto de unos 30 años, sin «storybook» en el estilo.")
    else:
        add(U, id, nombre, nuevo, semilla=semilla, recolor=True, nota=nota)

unidad("aldeano_m", "Runa (aldeano, hombre)", f"A farmer working the soil with a chakitaqlla, the Andean foot plough: a long wooden pole with a footrest and a narrow blade. He wears {TUNICA} and a plain woven headband.")
unidad("aldeano_f", "Runa (aldeana, mujer)", f"A woman spinning wool while standing: a drop spindle, a thin wooden stick with a round whorl, hangs and twirls from a thread of wool that she pulls from a bundle of raw wool held up in her other hand. She wears {TUNICA} reaching her ankles and an undyed cream shawl pinned at the chest.", mujer=True)
unidad("comerciante_m", "Caravana de llamas (hombre)", f"A caravan driver leading {LLAMA} by a rope; the llama carries woven bundles and a clay jar on its back. He wears {TUNICA}, a plain woven headband and a woven bag across the chest.")
unidad("comerciante_f", "Caravana de llamas (mujer)", f"A woman leading {LLAMA} by a rope; the llama carries woven bundles on its back. She wears {TUNICA} reaching her ankles and an undyed cream shawl.", mujer=True)
unidad("explorador", "Chaski", f"A young relay runner in mid-stride, a conch-shell trumpet hanging at his side and a bundle of knotted colored cords in his hand, a small white feather crest on his headband. He wears {TUNICA}.")
unidad("awqa", "Leva (awqa kamayuq)", f"A farmer called up to fight, holding a plain wooden club and a sling, bare head, barefoot. He wears {TUNICA}.")
unidad("hondero", "Hondero", f"A slinger whirls his sling above his head like a lasso: his right arm raised, a loop of thin braided cord circling over his head, and a woven pouch holding a round grey stone at the far end of the loop. He wears {TUNICA}, a cream woven headband and a woven bag of stones at his hip.")
unidad("boleador", "Boleador", f"A warrior swinging bolas above his head like a gaucho: three round stones wrapped in leather, joined by long cords. He wears {TUNICA} and a cream woven headband.")
unidad("lancero", "Lancero con escudo", f"A spearman holding a long wooden spear with a bronze point upright, and a square shield of cane covered in undyed cloth with a fringe at the bottom. He wears {TUNICA} and a round helmet woven from tan cane strips like a basket.")
unidad("guerrero", "Guerrero de porra", f"A warrior holding up a club whose bronze head is shaped like a six-pointed star, and a square shield of cane covered in undyed cloth with a fringe. He wears {TUNICA}, a round helmet woven from tan cane strips like a basket, and wool fringes tied below the knees.")
unidad("guardia", "Guardia (élite, edad IV)", f"An elite guard holding a club with a six-pointed star-shaped bronze head and a square shield painted with black and white checks. He wears thick quilted cream cotton armor over {TUNICA}, a cane helmet with a tall crest of upright brown and white feathers like a fan, and one flat pewter-grey silver disc on the chest.")
unidad("guardia_distancia", "Guardia de distancia (élite, edad IV)", f"An elite slinger holding a braided sling and a round stone, a square shield on his back. He wears thick quilted cream cotton armor over {TUNICA}, a cane helmet with a tall crest of upright brown and white feathers like a fan, and one flat pewter-grey silver disc on the chest.")
unidad("galgueros", "Galgueros", f"A man pushing a big round boulder with a long wooden pole at the edge of a steep mountain slope, ready to roll it downhill. He wears {TUNICA} and a cream woven headband.")
unidad("jinete", "Jinete", f"An Andean rider on a brown horse taken from the Spanish, holding a long wooden spear, no saddle armor. He wears {TUNICA} and a cream woven headband.", nota="Caballo capturado: solo desde 1536.")
unidad("jinete_manco", "Jinete de Manco", f"A rider of Manco Inca's resistance on a captured brown horse, holding a long lance, wearing a captured steel Spanish helmet over a woven headband. He wears {TUNICA}.", nota="Vilcabamba, 1537–1572.")
unidad("arcabucero", "Arcabucero", f"A warrior holding a captured Spanish arquebus, a long matchlock gun with a wooden stock, a smoking slow-match cord in his hand. He wears {TUNICA} and a cream woven headband.")
unidad("hondero_caliente", "Hondero de piedra caliente (asedio)", f"A slinger whirls his sling above his head like a lasso; in the pouch at the end of the loop a stone wrapped in cotton burns with a bright flame and a trail of smoke. He wears {TUNICA} and a cream woven headband.", nota="Ocupa la ranura del ariete y de la catapulta: un solo arte.")
add(U, "rebano", "Llama (rebaño)", f"A single {LLAMA} standing, cream and brown wool, red wool tassels tied to its ears, three-quarter view, plain flat dark grey-green backdrop.")

# 2 · Edificios: un ícono por edificio, sin variante por edad.
B = "2 · Edificios, hitos y maravilla (un ícono por edificio)"
def edif(id, nombre, que, nota=""):
    add(B, id, nombre, f"{que} {EDIF}", nota=nota)
edif("centro", "Llaqta (centro)", "A small Inca town center: several fieldstone houses with thatched roofs around an open plaza, a larger hall on one side.")
edif("casa", "Kancha (casa)", "A small one-room fieldstone house with a steep thatched gable roof and one trapezoidal doorway, a low stone wall around a small yard.")
edif("granja", "Chacra (granja)", "A field of tall maize and potato plants on terraced ground, a small fieldstone hut with a thatched roof, a wooden foot plough leaning on the wall.")
edif("anden", "Andén (terrazas)", "Agricultural terraces on a mountainside: four curved steps held by fieldstone retaining walls, green crops on each step.")
edif("almacen_madera", "Llant'a wasi (depósito de leña)", "An open-sided fieldstone shed with a thatched roof, stacks of firewood and bundles of branches piled inside and in front.")
edif("almacen_mina", "Kamayuq wasi (depósito de piedra y metal)", "A fieldstone workshop with a thatched roof, piles of cut stone blocks and green copper ore in front, stone hammers and baskets.")
edif("qollqa", "Qollqa (almacén)", "A row of three round fieldstone storehouses with conical thatched roofs on a hillside, small square openings.")
edif("cuartel", "Kallanka (cuartel)", "A long rectangular hall of fieldstone with many trapezoidal doorways along its long side and a steep thatched gable roof; long wooden spears lean against the wall and square cloth-covered shields hang beside the doors.")
edif("campo_tiro", "Warak'a kancha (campo de honderos)", "A rectangular fieldstone enclosure with a thatched hut in one corner, a big pile of round sling stones, braided slings hanging from a wooden pole.")
edif("taller_tejido", "Taller de tejido", "A fieldstone workshop with a thatched roof and an open front, upright wooden looms with half-woven patterned cloth and colored skeins of wool hanging outside.")
edif("mercado", "Mercado", "An open stone-walled plaza where goods are laid out on woven cloths: potatoes, maize, clay pots and folded textiles, a llama standing by.")
edif("mercado_neutral", "Feria (neutral)", "A busy open-air fair: goods on cloths and under simple cane awnings, clay jars, baskets of produce and llamas.")
edif("tambo", "Tambo", "A roadside waystation: two fieldstone buildings with thatched roofs beside a stone-paved road, a corral with llamas.")
edif("camino", "Qhapaq Ñan (camino)", "A stretch of Inca road paved with flat stones, with a few stone steps and low side walls, climbing a mountainside.")
edif("muralla", "Pirca (muralla)", "A straight segment of a thick fieldstone wall with a flat top.")
edif("torre_muralla", "Torreón de pirca", "A fieldstone wall with a round stone bastion tower with a flat top.")
edif("torre", "Pukara (torre)", "A tall round fieldstone lookout tower with a conical thatched roof on a rocky hill.")
edif("puerta_piedra", "Punku (puerta)", "A gateway with a tall double-jamb trapezoidal doorway set in a wall of finely fitted stone blocks.")
edif("fortaleza", "Hatun pukara (fortaleza)", "A hilltop fortress with three levels of massive zigzag terrace walls of huge fitted stones, with a few thatched buildings on top.")
edif("sitio_sagrado", "Sitio sagrado", "A large natural rock outcrop with steps and channels carved into it, surrounded by a low stone wall, open sky.", nota="Sin ídolos ni símbolos: la roca tallada sola.")
edif("escuela", "Yachaywasi (escuela)", "A hall of finely fitted stone blocks with a thatched roof and trapezoidal doorways, bundles of knotted colored cords hanging by the door.")
edif("ingenio", "Ingenio (neutral)", "A colonial sugar-cane press: a wooden mill with three vertical rollers turned by a long beam, under a tiled roof, cane stacked beside it.")
edif("kallanka_real", "Kallanka real (hito)", "A very long great hall of finely fitted stone blocks with a row of tall trapezoidal doorways and a huge thatched gable roof, facing a wide plaza.")
edif("aqllawasi", "Aqllawasi (hito)", "A walled compound of finely fitted stone blocks with a single trapezoidal gate, thatched roofs inside, looms and folded fine textiles visible in the courtyard.")
edif("ushnu", "Ushnu y plaza (hito)", "A stepped stone platform of three levels with a staircase, standing in a wide open plaza.")
edif("pukara_mayor", "Pukara de frontera (hito)", "A frontier fortress on a mountain ridge: several rings of fieldstone walls following the ridge, thatched barracks inside.")
edif("qorikancha", "Qorikancha (hito)", "A temple enclosure with a curved wall of perfectly fitted dark stone blocks, a thin band of gold plates along the top of the wall, thatched roofs behind.", nota="El único con oro, porque así era.")
edif("vilcabamba", "Vilcabamba (hito)", "A town at the edge of the cloud forest: fieldstone buildings, some with thatched roofs and some with Spanish clay tile roofs, mist and green jungle behind.", nota="Espíritu Pampa tenía techos de teja.")
edif("maravilla", "Ollantaytambo (maravilla)", "The mountainside complex of Ollantaytambo: long stone terraces climbing a steep hill, a wall of six enormous pink granite blocks at the top, stone storehouses on the opposite slope.")

# 3 · Mejoras propias: un objeto concreto cada una.
M = "3 · Mejoras propias"
def mejora(id, nombre, que, nota=""):
    add(M, id, nombre, f"{que} {OBJ}", nota=nota)
mejora("khipukamayuq", "Khipukamayuq", "A khipu: a thick main cord with many hanging cords of different colors, red, cream, brown, black and ochre, each with clusters of knots.")
mejora("champi", "Champi, la porra de metal", "A club head of bronze shaped like a six-pointed star, mounted on a short wooden handle.")
mejora("chunu_charki", "Ch'uñu y ch'arki", "Freeze-dried potatoes, small dark wrinkled and white, and strips of dried llama meat on a woven cloth.")
mejora("qeswa_chaka", "Q'eswa chaka", "A suspension bridge woven from thick grass ropes hanging over a deep rocky gorge, stone anchors on each side.")
mejora("trepanacion", "Cirugía de cráneo", "An ancient skull seen from above with a neat healed round hole, next to a small bronze knife with a half-moon blade, on a cloth.", nota="Los cráneos con hueso cicatrizado prueban que los pacientes sobrevivían.")
mejora("waraka_trenzada", "Warak'a trenzada", "A coiled braided sling made of wool in red, cream and black with a diamond-patterned pouch.")
mejora("wayrachina", "Wayrachina", "A small clay smelting furnace with many holes in its sides on a windy hillside, flames inside, a pile of ore beside it.")
mejora("chaski", "Chaski en relevo", "A conch-shell trumpet and a bundle of knotted colored cords lying on a stone-paved mountain road.")

# 4 · Accesorios: herramientas y armas para el 3D.
A = "4 · Accesorios (herramientas y armas para el 3D)"
def prop(id, nombre, que):
    add(A, id, nombre, f"{que} {PROP}")
prop("arma_honda", "Honda (warak'a)", "A braided wool sling laid out straight: two long thin cords with a small woven pouch in the middle.")
prop("arma_boleadoras", "Boleadoras", "Bolas: three round stones wrapped in leather, joined by three long leather cords tied together.")
prop("arma_maza", "Porra de estrella", "A club with a six-pointed star-shaped bronze head on a long wooden handle.")
prop("arma_lanza", "Lanza", "A long wooden spear with a leaf-shaped bronze point.")
prop("arma_vara", "Vara del chaski", "A short walking staff of dark wood with a wrapped cord grip.")
prop("arma_galga", "Galga", "A big round boulder roughly shaped by hand, with a wooden lever pole beside it.")
prop("arma_arcabuz", "Arcabuz", "A 16th-century matchlock arquebus with a wooden stock and a long iron barrel.")
prop("escudo_cuadrado", "Escudo cuadrado", "A square shield of woven cane covered in undyed cloth with a fringe along the bottom edge.")
prop("carga_cantaro", "Cántaro (aríbalo)", "An Inca clay jar with a tall narrow neck, a pointed base, two side handles and simple painted geometric bands.")
prop("herr_azada", "Azada", "An Andean hoe: a wooden handle with a broad blade of bronze tied on with cord.")
prop("herr_pico", "Pico", "A digging tool with a wooden handle and a pointed bronze head.")
prop("herr_hacha", "Hacha", "An axe with a flat bronze blade tied to a wooden handle.")
prop("herr_martillo", "Martillo", "A rounded hammerstone of dark river rock.")
prop("herr_cuchillo", "Cuchillo (tumi)", "A small bronze knife with a half-moon blade and a short handle.")
prop("herr_huso", "Huso (pushka)", "A drop spindle: a thin wooden stick with a round clay whorl near the bottom and some spun wool.")
prop("herr_canasta", "Canasta", "A round woven reed basket with low sides.")
prop("herr_fardo", "Fardo", "A bundle wrapped in woven cloth and tied with rope.")

# 5 · Hojas 3D por edad: aldeano, hondero y guerrero. La edad se nota por el equipo.
H = "5 · Hojas para el 3D por edad (lo único por edad)"
EDADES = ["I · Ayllu", "II · Suyu", "III · Tawantinsuyu", "IV · Inkarri"]
EQUIPO = {
    "aldeano": [
        f"Clothing: {TUNICA}, knee-length; bare head; barefoot.",
        f"Clothing: {TUNICA}, knee-length; a cream woven headband; rope sandals; a small cream woven bag on a strap across the chest.",
        f"Clothing: {TUNICA}, knee-length; a cream woven headband; rope sandals; a short undyed brown wool cloak knotted over one shoulder; a woven bag across the chest.",
        f"Clothing: {TUNICA}, knee-length; a braided headband with hanging wool tassels; rope sandals with wool ties; a long undyed cream mantle knotted at the chest; a woven bag with tassels.",
    ],
    "hondero": [
        f"Clothing: {TUNICA}, knee-length; bare head; barefoot.",
        f"Clothing: {TUNICA}, knee-length; a cream woven headband; rope sandals; a cream woven bag of stones on a strap across the chest.",
        f"Clothing: thick quilted cream cotton armor stitched in diamonds over {TUNICA}; a round helmet woven from tan cane strips like a basket, worn in every view; rope sandals; a small round shield on the back.",
        f"Clothing: {TUNICA}; a cream headband with a tall crest of upright brown and white feathers like a fan, in every view; one flat pewter-grey silver disc on the chest; a short undyed brown wool cape tied at the chest; rope sandals.",
    ],
    "guerrero": [
        f"Clothing: {TUNICA}, knee-length; bare head; barefoot.",
        f"Clothing: {TUNICA}, knee-length; a cream woven headband; rope sandals; cream wool fringes tied below the knees.",
        f"Clothing: thick quilted cream cotton armor stitched in diamonds over {TUNICA}; a round helmet woven from tan cane strips like a basket, worn in every view; rope sandals; cream wool fringes below the knees; a square cloth-covered shield on the back.",
        f"Clothing: thick quilted cream cotton armor over {TUNICA}; a cane helmet with a tall crest of upright brown and white feathers like a fan, in every view; one flat pewter-grey silver disc on the chest; a short undyed brown cape; wool fringes below the knees; rope sandals.",
    ],
}
NOMBRES = {"aldeano": "Runa (aldeano)", "hondero": "Hondero", "guerrero": "Guerrero de porra"}
for k, lista in EQUIPO.items():
    for i, eq in enumerate(lista):
        add(H, f"hoja_{k}_e{i+1}", f"{NOMBRES[k]} · edad {EDADES[i]}",
            f"{HOJA} {eq} The person is {CARA_M}. {NATURAL} {FONDO_H}", semilla=31, w=1152, h=768, recolor=True)

json.dump(piezas, open(os.path.join(D, "piezas.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
from collections import Counter
print(len(piezas), Counter(p["seccion"][:1] for p in piezas))
