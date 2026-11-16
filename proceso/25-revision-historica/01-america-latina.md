# 01 · Revisión histórica: América Latina

Revisor: historiador de América Latina, 1400–1800 (Andes, mundo mapuche, guaraníes y tupíes, y el lado brasileño de Palmares). Fecha: 2026-11-16.

**Qué leí:**
- `docs/00-indice.md`, `04-decisiones.md` y `07-arte-y-ui.md`;
- `proceso/CONSULTAS.md` (C-39 a C-44 y C-53 a C-60) y los tres informes del jugador de historia;
- `data/civs/` de tawantinsuyu, mapuches, guaranies, tupies, chankas, canaris, caranquis, palmares e invasores;
- `data/campanas/` de tawantinsuyu, mapuches, guaranies y palmares;
- `data/arte_edades.json`, `arte_hitos.json`, `arte_animales.json` y `audio.json`;
- `assets/audio/musica/README.md`, `src/game/audio.gd` (`CIV_MUSIC`), `4g-sonido.md` y `4h-sonido-con-respeto.md`;
- las capturas 4c, 4d, 4i y 4p.

No corrí el juego ni cambié nada fuera de este archivo.

**Convención:** "a verificar" quiere decir que no puedo confirmar el dato de memoria con la precisión necesaria. Digo por qué sospecho y nunca invento la cita.

---

## 1. Resumen

1. El nivel general es alto. Hay narradores de adentro, nadie es héroe ni villano de cartón, hay fuentes por misión y las fechas y nombres principales de las cuatro campañas son correctos: Sangarará, Curalaba, Quilín, Mbororé, Caiboaté, Cucaú y la Barriga.
2. El error de hecho más serio está en la economía guaraní. La yerba (*ka'a*) no nace de una roza agotada. Era un árbol silvestre del monte, y en la colonia su cosecha fue trabajo forzado de encomienda; solo las reducciones del siglo XVIII la plantaron.
3. La edad IV inca junta tres anacronismos en la misma pantalla:
   - el nombre *Inkarri*, un mito documentado en el siglo XX;
   - el Qorikancha, obra de Pachakutiq;
   - las **bandas de oro en todos los edificios**, justo en la época en que el oro del Cusco ya se había fundido para el rescate de Atawallpa (1533).
4. Los nombres de las edades guaraníes tienen dos problemas. *Amundá* no tiene fuente, y la secuencia termina en *Tava*: la meta parece "reducirse". Propongo *Tekoha → Guára → Mbororé → Ñande retã*, a verificar con un hablante y con Meliá.
5. Errores de lengua o de etnónimo:
   - *awqa runa* dice "gente enemiga", no "soldado";
   - la "lengua cara" de los caranquis viene del *Reino de Quito* de Velasco (1789), que hoy se considera en buena parte legendario.
6. Mapuches:
   - las edades (*Lof → Rewe → Ayllarewe → Butalmapu*) están muy bien;
   - los hitos inventan cargos: "toqui de caballería" y "toqui del monte";
   - Quilín (1641) adelanta los "cuatro butalmapu", un sistema que se formaliza más tarde.
7. En Palmares la historia está muy cuidada: sigue a Lara, usa *Gana Zumba* y *Aca Inene* y no cae en el mito de *Aqualtune*. Pero `arte_edades` y `4h` citan a Décio Freitas, cuyas fuentes sobre Zumbi están cuestionadas, y la frase del pueblo ("se esconde", C-20) le quita agencia a la gente.
8. Sonido:
   - el paso 4h fue correcto: sin kultrun, mbaraka ni takuapu;
   - quedan dos anacronismos menores en la música inca (charango y arpa, ambos coloniales);
   - la pifilka, la que más se teme, es justamente la que las crónicas ponen en la guerra (pasaje a verificar).
9. Varias fuentes citadas son de divulgación (Wikipedia, Memoria Chilena, *Americas Quarterly*, *Brasil de Fato*, FAPESP) y conviene reemplazarlas por obras académicas. Una es probablemente errónea: "Memoria Chilena, el éxodo del Guairá".
10. Antes de publicar hacen falta consultas con organizaciones mapuches, mbyá guaraní, quechuas (Cusco y Apurímac) y quilombolas, y con hablantes para los nombres. Ver la sección 4.

---

## 2. Problemas, ordenados por gravedad

**Cómo se ordena.** Dentro de cada bloque, del más grave al más leve:
1. **Error de hecho** (E);
2. **Anacronismo** (A);
3. **Estereotipo o falta de respeto** (R);
4. **Simplificación aceptable** (S): mejora sugerida, no urgente.

### 2.1 Errores de hecho

| # | Qué dice el juego (archivo → clave) | Qué es lo correcto o lo discutido | G | Propuesta | Fuente |
|---|---|---|---|---|---|
| E1 | `civs/guaranies.json` → `riqueza_desc`, `granja.deja: "yerbal"`: "La roza agotada deja un yerbal" | La yerba mate (*Ilex paraguariensis*, *ka'a*) es un árbol del monte. Se cosechaba en yerbales silvestres (*ka'aguy*), sobre todo en el Mbaracayú y el Tarumá. Una roza abandonada se vuelve *capuera* (monte secundario), no yerbal. En la colonia, el beneficio de la yerba fue la forma más dura del servicio de encomienda. Las reducciones lograron cultivarla en plantíos recién a fines del siglo XVII y en el XVIII. La misión 4 lo dice bien ("los yerbales que habíamos plantado") y contradice la mecánica. | E | Mantener el motor, pero que el yerbal sea un **recurso silvestre del monte** (nodo de *ka'a* en el bosque, que se cosecha y se agota). Desde la vía misión (edad III), sumar el **yerbal plantado** cerca del pueblo. La roza agotada deja *capuera* (ya existe la clave `capuera`). En la descripción, una línea sobre la yerba como tributo y trabajo forzado. | Garavaglia, *Mercado interno y economía colonial* (1983); Meliá, *El guaraní conquistado y reducido* (1986); Ganson (2003) |
| E2 | `civs/tawantinsuyu.json` → `unidades_nuevas.awqa.nombre`: "Leva (awqa runa)" | En el quechua colonial, *awqa* (*auca*) es "enemigo, contrario, tirano", la misma palabra que los españoles aplicaron después a los mapuches. "Guerrero" es *awqaq*, y "soldado", *awqa kamayuq* (*auca camayoc* en Guaman Poma). *Awqa runa* se lee "gente enemiga". | E | *Awqa kamayuq* ("leva" en castellano), o *Mit'a awqa* si se quiere marcar el turno. A verificar con un quechuahablante del Cusco. | González Holguín, *Vocabulario de la lengua general…* (1608), entradas *Auca* y *Aucac* (a verificar la grafía exacta); Guaman Poma (c. 1615) |
| E3 | `civs/caranquis.json` → `descripcion`: "lengua propia, la cara, que no era quechua" | "Cara" y "caras" vienen de Juan de Velasco, *Historia del Reino de Quito* (1789), con su reino de los *shyris*, que la historiografía considera mayormente legendario. La lengua de Caranqui y Cayambe está poco documentada; suele agruparse, con dudas, en la familia barbacoana. Que no fuera quechua sí es correcto. | E | "Lengua propia, poco documentada (probablemente barbacoana), que no era quechua". No usar "cara". | Salomon, *Native Lords of Quito* (1986); Adelaar y Muysken, *The Languages of the Andes* (2004) |
| E4 | `campanas/tawantinsuyu.json` → misión 3 (`intro[3]`, `rivales[1]`): Mateo Pumakawa en la columna derrotada en Sangarará | La columna de Sangarará (18-XI-1780) la mandaba Tiburcio Landa, con milicias del Cusco y auxiliares indígenas. Pumakawa, cacique de Chinchero, se destaca después, en la defensa del Cusco (enero de 1781) y en la persecución. A verificar si estuvo en Sangarará; sospecho que no. La idea de fondo ("kurakas leales al rey") es correcta y conviene conservarla. | E (probable) | Poner a los auxiliares de los kurakas leales en la columna sin nombrar a Pumakawa, y llevarlo a la defensa del Cusco (objetivo 6). O dejarlo y verificarlo en Walker. | Walker, *The Tupac Amaru Rebellion* (2014), caps. 3–4 |
| E5 | `campanas/tawantinsuyu.json` → misión 1 (`intro[0]`): "Tres generaciones después de Pachakutiq… Wayna Qhapaq, su nieto" | Si es su nieto, son dos generaciones (Pachakutiq → Thupa Inka → Wayna Qhapaq). | E (leve) | "Dos generaciones después". | Rostworowski (1988); D'Altroy (2002) |
| E6 | `campanas/tawantinsuyu.json` → misión 1 (`epilogo[1]`): "Wayna Qhapaq murió en Tumipampa" | Las crónicas difieren: la mayoría dice Quito, otras Tumipampa. | E (leve, discutido) | "Murió en el norte, en Quito o en Tumipampa según quién lo cuente". Le queda bien al narrador de cuerdas. | Cieza (c. 1553); Cabello Balboa (1586); D'Altroy (2002) |
| E7 | `campanas/tawantinsuyu.json` → misión 3 (`epilogo[0]`): "cuando llegamos, en enero, el Cusco ya tenía refuerzos" | El cerco del Cusco empezó a fines de diciembre de 1780 (alrededor del 28) y se levantó a comienzos de enero de 1781. | E (leve) | "Cuando llegamos, a fin de diciembre". | Walker (2014) |
| E8 | `campanas/guaranies.json` → misión 1 (`intro[0]`): Ñezú "en 1628 echaron a los padres por la fuerza", en una misión del Guairá | Ñezú actuó en la región del Uruguay (Caaró e Ijuí), no en el Guairá, y en 1628 mató a Roque González, Alonso Rodríguez y Juan del Castillo. "Echaron" suaviza el hecho. No es un error grave, porque el narrador puede referirse a otro lugar, pero el contexto lo ubica en el Guairá. | E (leve) | "Lejos, en el Uruguay, Ñezú, que era cacique y karai, mató a los padres en 1628". Dicho sin juicio, como el resto de la campaña. | Montoya, *Conquista espiritual* (1639); Meliá (1986) |
| E9 | `campanas/guaranies.json` → misión 1 (`fuentes[2]`): "Memoria Chilena, el éxodo del Guairá" | Memoria Chilena es el portal de la Biblioteca Nacional de Chile, y no creo que tenga una página sobre el Guairá. Probable cita equivocada (a verificar). | E (cita) | Reemplazar por Montoya (1639) y Meliá (1986), o por Cortesão (ed.), *Jesuítas e bandeirantes no Guairá* (1951). | — |
| E10 | `civs/guaranies.json` → `animales._doc`: "Pueblo cazador" | Los guaraníes eran sobre todo agricultores de roza: maíz, mandioca, porotos, zapallo. La caza y la pesca completaban la dieta. El texto no se ve en el juego, pero orienta a quien diseñe. Además, las reducciones tuvieron grandes estancias de ganado (Yapeyú). | E (interno) | "Pueblo de roza: sin rebaño propio en la edad I; caza en el monte". Evaluar ganado vacuno en la vía misión. | Noelli (1993, tesis, a verificar el título); Susnik (1979–82) |
| E11 | `campanas/guaranies.json` → misión 3 (`intro[2]`): Sepé Tiaraju "mandaba la artillería" | Sepé era alférez real o corregidor de San Miguel (las fuentes varían) y capitán de las milicias. Que mandara la artillería no lo encuentro (a verificar). Muy bien resuelto, en cambio, el "dicen que les dijo: esta tierra tiene dueño". | E (a verificar) | "Capitaneaba las milicias de San Miguel". | Golin, *A Guerra Guaranítica* (1998); Henis (1754) |
| E12 | `campanas/guaranies.json` → misión 2 (`epilogo[1]`): "En 1649 nos quitaron los arcabuces… veintisiete años" | No pude confirmar ni la fecha ni el plazo. Hubo idas y vueltas sobre el permiso de armas en el siglo XVII. | A verificar | Verificar en Avellaneda y Quarleri (2007); si no está, decirlo sin cifra exacta. | — |
| E13 | `campanas/palmares.json` → misión 2 (`epilogo[0]`) y misión 3 (`epilogo[0]`): "Al año siguiente mataron a Gana Zumba" y "232 casas y cuarenta tiendas de herreros" | El pacto es de 1678 y la muerte de Gana Zumba suele fecharse hacia 1680. Las cifras de 1694 tampoco las pude confirmar. | A verificar | Contrastar con Lara (2021) y con Oliveira (2005). | — |
| E14 | `civs/canaris.json` → `centro.nombre`: "Guapondélig" | Es el nombre que la tradición cuencana da a la ciudad cañari anterior a Tumipampa. Su fuente documental temprana es dudosa (ya está marcado). | E (a verificar) | Hasta tener fuente, "Tumipampa (Guapondélig, según la tradición)". | Idrovo, *Tomebamba* (2000) (a verificar) |

### 2.2 Anacronismos

| # | Qué dice el juego | Qué es lo correcto | G | Propuesta | Fuente |
|---|---|---|---|---|---|
| A1 | `arte_edades.json` → `civs.tawantinsuyu.edades[3]`: `"dorado": true`, `"remate": "dorado"`, `tropa.oro` en la edad IV, en **todos** los edificios y la tropa | El oro era exclusivo de lo sagrado y de lo real: Qorikancha, palacios y vajilla del Inka. Nunca estuvo en kanchas comunes ni en qollqas. Además, la edad IV es Vilcabamba (1537–1572), cuando las planchas del Qorikancha ya se habían fundido para el rescate de Cajamarca (1533). Es la imagen exactamente inversa a la de la época. | A | Sacar el dorado de la edad IV. Si se quiere oro, ponerlo **solo en la edad III** y solo en el centro y los hitos. Para la IV, Vilcabamba como arqueología: pirca más tosca, techos empinados de selva alta y **teja española** en algunos techos, como en Espíritu Pampa (el hito ya lo hace bien). La tropa de la IV, con algo tomado: un casco de hierro, una lanza larga. | Bauer, Fonseca Santa Cruz y Aráoz Silva, *Vilcabamba and the Archaeology of Inca Resistance* (2015); Hemming (1970) |
| A2 | `civs/tawantinsuyu.json` → `edades[3]`: "Inkarri" (C-39) | El ciclo de Inkarrí se documenta en el siglo XX (Arguedas y otros, Puquio, 1956). Vincularlo con el Taki Onqoy (1560s) es una interpretación moderna. Como nombre de época es anacrónico, aunque como guiño tiene fuerza. | A | Opción que propongo y que no está en C-39: edad IV **"Willkapampa"** (Vilcabamba, en grafía quechua), y el hito militar pasa a llamarse **"Espíritu Pampa"** (el sitio de Vilcabamba la Vieja), así no chocan. Si el autor prefiere conservarlo, la a) de C-39, explicado. | Arguedas, "Puquio, una cultura en proceso de cambio" (1956); Flores Galindo, *Buscando un inca* (1986) |
| A3 | `civs/tawantinsuyu.json` → `hitos[2][0]`: "qorikancha" en la edad IV (C-40) | Lo reconstruyó Pachakutiq hacia 1438 (Betanzos). | A | La b) de C-40: Qorikancha a la edad II o III. Si no se quiere rebalancear, la a), pero con un nombre de la época de resistencia y lo económico: **"Wak'akuna de Vilcabamba"**, o el **Punchao** (la imagen del sol que Manco llevó a Vilcabamba y que se entregó en 1572). | Betanzos (1551); Bauer, *Ancient Cuzco* (2004); Hemming (1970) sobre el Punchao |
| A4 | `civs/tawantinsuyu.json` → `edificios_nuevos.tambo.desc`: "Antiguo ingenio que el Inca ganó con un regalo de cumbi" | "Ingenio" (trapiche o molienda de metal) es una palabra colonial. El sitio neutral del mapa se llama así para todos (`reglas.json → ingenios`), pero en boca del Inka es raro. La reciprocidad con cumbi como regalo a un curaca, en cambio, es muy correcta. | A (leve) | "Un señorío vecino que el Inka ganó con regalos de cumbi: ahora es un tambo del camino real". | Murra, "Cloth and its Functions in the Inca State" (1962) |
| A5 | `audio.gd` → `CIV_MUSIC.tawantinsuyu.paz`: "musica_andes_charango_1" y "flauta de pan, **arpa** y bajo" | El charango y el arpa andina son instrumentos coloniales (derivados de la vihuela y del arpa española, de los siglos XVII y XVIII). Para 1438–1572 son anacrónicos; para la misión de 1780, no. | A (leve) | Dejar el charango solo para la edad IV o la misión de Túpac Amaru, y buscar o sintetizar quena, siku, pinkillu y wankar para las edades I a III. Pututu en la alarma, como ya sugiere `4h`. | Stevenson, *Music in Aztec and Inca Territory* (1968) (a verificar) |
| A6 | `campanas/mapuches.json` → misión 3 (`intro[1]`): "Los lonko de los cuatro butalmapu… costa, llanos, precordillera y cordillera" en 1641 | La organización en cuatro *butalmapu* como interlocutores de los parlamentos se consolida en la segunda mitad del siglo XVII y, sobre todo, en el XVIII. En Quilín (1641) los españoles trataron con caciques de varias parcialidades (Lincopichón, entre otros). | A (leve) | "Los lonko de los ayllarewe de la costa y de los llanos…", y dejar *Butalmapu* para la edad IV. Encaja: la narradora habla desde 1641, y la edad IV puede apuntar al siglo XVIII. | Boccara, *Los vencedores* (2007); Zavala, *Los mapuches del siglo XVIII* (2008) |
| A7 | `civs/guaranies.json` → `edades[0]`: "Tekoha" | *Tekoha* como "el lugar donde somos lo que somos" es una categoría etnográfica y política del siglo XX. Montoya registra *tekoha* con un sentido más amplio: modo de ser, costumbre, lugar. No está mal, pero es un concepto que hoy tiene peso en las luchas por la tierra. | S | Conservarlo (lo usan las propias comunidades) y explicarlo en el panel. | Meliá, Grünberg y Grünberg, *Los Paĩ-Tavyterã* (1976); Montoya, *Tesoro* (1639) |
| A8 | `arte_hitos.json` → `guaranies.tava._nota` | La nota ya está corregida: las iglesias de piedra son del siglo XVIII. Bien. | — | Nada. | — |

### 2.3 Estereotipo, falta de respeto o mirada desde afuera

| # | Qué dice el juego | Por qué | G | Propuesta | Fuente |
|---|---|---|---|---|---|
| R1 | `civs/guaranies.json` → `edades`: "Tekoha → Amundá → Mbororé → Tava" (C-41) | *Amundá* no tiene fuente en ningún documento (lo confirmé: solo aparece en el JSON). *Tava* como meta final sugiere que el destino es la reducción. | R + E | **Tekoha → Guára → Mbororé → Ñande retã**. *Guára* es la región o el conjunto de tekoha aliados de la escala de Susnik y Meliá (*teýy*, linaje en una casa grande → *tekoha* → *guára*), y deja una secuencia paralela a la mapuche (*Lof → Rewe → Ayllarewe*). Ojo con *tovaja*, la a) de C-41: es "cuñado", el instrumento del pacto con los españoles, y como nombre de edad puede leerse como celebración de la alianza colonial. A verificar *guára* con un hablante y en Meliá (1986, cap. sobre organización). | Susnik, *Los aborígenes del Paraguay* II (1979–80); Meliá (1986) |
| R2 | `civs/palmares.json` → `frase`: "La libertad que llega sola y se esconde en la sierra" (C-20) y `descripcion`: "la gente llega por la fama" | Las dos frases le quitan agencia a la gente. La fuga era una acción arriesgada y organizada, y Palmares fue una formación política con rey, potentados, consejo, comercio y guerra, no un escondite. La mecánica puede seguir igual. | R | Frase: "La libertad que se toma, se defiende y se pacta en la sierra". Descripción: "No entrena aldeanos: la gente huye de los ingenios y llega por la fama…". Sí a C-20 a). | Lara, *Palmares & Cucaú* (2021); Reis y Gomes (orgs.), *Liberdade por um fio* (1996) |
| R3 | `arte_edades.json` → `palmares._nota` y `4h` → fuentes: Décio Freitas, *Palmares: a guerra dos escravos* | Freitas es un clásico, pero su relato de la infancia de Zumbi (criado por el padre Antônio Melo en Porto Calvo) se apoya en cartas que nadie volvió a encontrar, y la historiografía reciente lo trata con cautela. No conviene que el juego cite como fuente lo más dudoso de la historia de Palmares. | R (fuente) | Reemplazar por Gomes, *Palmares: escravidão e liberdade no Atlântico Sul* (2005), y Lara (2021). | Gomes (2005); Lara (2021) |
| R4 | `civs/mapuches.json` → `hitos`: "Rewe del toqui de malón", "Rewe del toqui de caballería", "Rewe del toqui del monte" | El *toqui* era el jefe de guerra que se elegía para una guerra (el que alzaba la *toki kura*); no había toquis por rama. "Rewe del toqui del monte" no tiene base. Repetir *rewe* en cuatro nombres, aunque sea en su sentido político, insiste en una palabra cargada (el altar de la machi). El arte ya se corrigió; faltan los nombres. | R + E | <ul><li>`rewe_malon` → **"Malón del toqui"**</li><li>`rewe_lonko` → **"Nguillatuwe del rewe"** (el único donde el rewe va)</li><li>`rewe_caballeria` → **"Corral de la remonta"** o "Kawellu" (caballo, a verificar la grafía)</li><li>`rewe_monte` → **"Pewenal"**</li></ul> | Bengoa, *Historia del pueblo mapuche* (1985); Boccara (2007); Dillehay (2007) |
| R5 | `civs/mapuches.json` → `edificios.cuartel`: "Ruka de guerra" | No hay registro de casas de guerra mapuches. Los guerreros se convocaban (*koyagtun*, *weichan*) y se juntaban en campos o lugares de reunión. | S | Nombre en castellano ("Junta de guerra") hasta tener fuente, o un término validado por hablantes. | Boccara (2007) |
| R6 | `civs/guaranies.json` → `explorador`: "Baqueano" | *Baqueano* es una palabra criolla, de origen caribe y del castellano americano, no guaraní. Para un pueblo con todos los nombres en su lengua, desentona. | S | Un término guaraní a verificar con hablantes, o "Explorador". | — |
| R7 | `campanas/palmares.json` → misión 1 (`epilogo[1]`): "Así se conoce a la gente que sabe esconderse: por lo que deja", y "la mata" (C-43) | Repite el tema del escondite (R2). Lo de "la mata" ya está en C-43. | S | "Así se conoce a la gente que no se deja encontrar". C-43 a). | — |
| R8 | `civs/invasores.json` → edades "Hueste… Virreinato" para holandeses, paulistas y la tropa de Velho | En Brasil no hubo virreinato efectivo en el siglo XVII. La bandeira y la tropa de Velho eran sobre todo indígenas y mamelucos. | R (fidelidad) | La b) de C-44, con edades por potencia. Para la tropa de Velho, mejor una facción "paulista" con base en los tupíes de las aldeias. | Monteiro, *Negros da terra* (1994) |
| R9 | `civs/chankas.json` → `descripcion` y misión 0 inca | Todo lo que sabemos de la guerra chanka viene de fuentes incas del Cusco (Betanzos se casó con Cuxirimay Ocllo, de la panaqa de Atawallpa). Bauer y Kellett muestran que la arqueología no confirma una "confederación" chanka capaz de amenazar el Cusco hacia 1438. El narrador ya relativiza a los *pururawka*; falta decir que los chankas son vistos por sus enemigos. | S | Agregar a la descripción: "Lo que se sabe de esta guerra lo contaron los incas vencedores". | Bauer, Kellett y Aráoz Silva (2010); Bauer y Smit, "Separating the Wheat from the Chaff" (2015, a verificar título y año) |
| R10 | `civs/tawantinsuyu.json` → `taller_tejido` y `riqueza_desc`: "la mit'a que sobra se teje y se vuelve riqueza" | Simplificación aceptable. El cumbi no era mercancía ni "riqueza" en sentido de mercado: era don político y ritual, se quemaba en sacrificios y se regalaba a curacas y soldados. | S | En la ficha del pueblo: "La tela no se vendía: se regalaba, se quemaba en ofrenda y ataba lealtades". Se puede conservar la mecánica. | Murra (1962; 1956/1980) |

### 2.4 Simplificaciones aceptables y detalles

| # | Qué dice el juego | Comentario | Propuesta |
|---|---|---|---|
| S1 | `campanas/mapuches.json` → misión 1: Marigüeñu, "donde a los caballos les falta el aire" | Marihueñu es una cuesta costera de pocos cientos de metros. La falta de aire es hipérbole. | "Donde a los caballos les pesa la cuesta". |
| S2 | `campanas/mapuches.json` → misión 3 (`epilogo[1]`): "casi cincuenta [parlamentos] en ciento sesenta años" | Depende de qué se cuente como parlamento (generales, particulares, juntas). A verificar en Zavala (2015). | "Decenas de parlamentos". |
| S3 | `campanas/mapuches.json` → misión 0: "Los wingka escribieron que fue obra del demonio" | A verificar en Vivar o en Góngora Marmolejo. | Verificar o atribuir en general ("algunos cronistas…"). |
| S4 | `campanas/guaranies.json` → misión 3 (`eventos[4]`): minuanes y charrúas aliados | Hubo minuanes del lado guaraní en 1754–1756 (a verificar). Para los charrúas, más dudoso. | Dejar solo a los minuanes si no hay fuente para los charrúas. |
| S5 | `civs/guaranies.json` → `yvy_marane` (clave interna) | *Yvy marane'ỹ* es "tierra sin mal"; sin la ỹ final, *yvy marane* es "tierra con mal". No se ve en el juego. | Renombrar la clave a `nande_reta` cuando se toquen los datos. |
| S6 | `civs/tawantinsuyu.json` → `almacen_mina`: "Kamayuq wasi" | *Kamayuq* es "especialista" o "encargado", y no dice qué guarda. | *Qhuya wasi* (*qhuya*: mina), a verificar con un hablante. |
| S7 | `arte_animales.json` → `guaranies: pecari` como rebaño | El pecarí se amansaba como animal criado en la casa (*mymba*), no en rebaño. Ya está marcado. | Aceptable. Mejor: sin rebaño en la edad I y ganado vacuno en la vía misión. |
| S8 | `arte_animales.json` → `chilihueque` | Su existencia está bien documentada por cronistas ("carneros de la tierra", *hueque*): sirvió para lana, carga y sacrificio, y Quilín lo confirma en el juego. Se discute si era una llama o un guanaco domesticado localmente. | Conservar el `[verificar]` solo sobre su aspecto, no sobre su existencia. Fuente para la existencia: Vivar (1558); para su aspecto, a verificar. |
| S9 | `civs/palmares.json` → `rebano`: Cerdo `[verificar]` | Plausible, pero no lo tengo confirmado en Blaer. Las gallinas sí aparecen en los relatos de entradas (a verificar). | Si no aparece el cerdo, gallinas, que además no piden una silueta grande. |
| S10 | `civs/palmares.json` → `granja`: "Roça de mandioca" | Inconsistente con C-43, que cambió "roças" por "rozas" en los textos. Además, en Palmares el cultivo más mencionado es el maíz, junto con mandioca, porotos, banana y caña. | "Roça" como nombre propio está bien (es un edificio). Que la descripción diga "maíz y mandioca". |
| S11 | `campanas/tawantinsuyu.json` → misión 0: batalla en "Yawarpampa" | El topónimo *Yahuarpampa* viene sobre todo de Garcilaso, que además atribuye la victoria a Wiraqocha. Betanzos pone el combate decisivo en el mismo Cusco y la persecución hacia Xaquixaguana. | Que el narrador lo diga: "Los de Garcilaso lo llaman Yawarpampa". O dejarlo, como simplificación. |
| S12 | `campanas/tawantinsuyu.json` → misión 3: "descendía de los incas de Vilcabamba" | Lo reclamaba, por línea de una hija de Túpac Amaru I, y le fue disputado en juicio. | "Decía descender, y lo pleiteó en Lima". |
| S13 | Fuentes de divulgación: Wikipedia (chankas, cañaris, caranquis, tupíes); Memoria Chilena; Sauer, *Americas Quarterly* (2022); FAPESP; *Brasil de Fato* | Sirven para orientarse, no como fuente en el juego. | Reemplazar por las obras de la bibliografía. La cita "Mendoza Pinto y Castro González, *Cuadernos CANELA* 31 (2021)" no la puedo confirmar: verificar que exista. |

---

## 3. Lo que está bien y conviene conservar

### Narradores y tono
- El khipukamayuq de Tinta, la tejedora de Purén que anuda el *pron*, el escribano guaraní del cabildo de San Miguel y la mujer nacida en Palmares. Que ningún narrador sea un cronista europeo es lo mejor del juego.
- **Ambigüedad honesta:**
  - los cañaris y chachapoyas "tenían cuentas pendientes";
  - los yanakuna en Tucapel "no habían elegido esa guerra";
  - los tupíes de la bandeira, "muchos cautivos";
  - Cucaú, "ninguno de los dos estaba del todo equivocado";
  - "Dicen que les dijo: esta tierra tiene dueño. Lo seguro es que no los dejó pasar". Esto es historia bien hecha.

### Fechas y personas correctas
- **Tawantinsuyu:**
  - los obrajes de Pomacanchi y Parapuquio, Arriaga, Sangarará (18-XI-1780) y la ejecución del 18-V-1781, con Micaela e Hipólito;
  - la mit'a de Potosí "de uno de cada siete", el anegamiento de Ollantaytambo y las piedras calientes de 1536;
  - Yawarqocha y la *chunka*.
- **Mapuches:** Tucapel (1553), Marigüeñu (1554), Mataquito (1557), Quiapo (1558), Curalaba (23-XII-1598, con Pelantaru y Anganamón), la Real Cédula de esclavitud de 1608, Las Cangrejeras y Núñez de Pineda, y Quilín (enero de 1641, ratificado en 1643).
- **Guaraníes:**
  - Lambaré, la encomienda de 1556 y el éxodo del Guairá de 1631;
  - Mbororé (11-III-1641), con Ñeenguirú y Abiarú;
  - las tres campañas contra Colonia, el Tratado de Madrid, Sepé (7-II-1756), Caiboaté (10-II-1756) y la anulación de 1761.
- **Palmares:**
  - Blaer (1645), Carrilho, el *Papel* de junio de 1678 y Cucaú;
  - *quilombo* como palabra que aparece en los documentos de los años 1680, según Lara;
  - la tropa indígena y mameluca de Velho, la caída de la Barriga (febrero de 1694), Zumbi (20-XI-1695) y Camuanga.

### Decisiones finas
- **Palmares:** usar *Gana Zumba*, *Gana Zona* y *Aca Inene* (de los manuscritos que editaron Lara y Fachin), sin el mito moderno de *Aqualtune*; y sacar la bandera blanca de Cucaú.
- **Rivales andinos:**
  - los chankas en castellano, porque no se sabe su lengua;
  - cañaris y caranquis por separado, con la tola caranqui y el fuerte de cresta de Pambamarca.
- **Arte:**
  - el ushnu de Vilcashuamán corregido y la cantería gris (captura 4i);
  - Vilcabamba con teja, como en Espíritu Pampa;
  - el rewe solo en el nguillatuwe y el pewen en paraguas;
  - las torres sin almenas europeas (ver 4i y 4d).

### Mecánicas con raíz
- **Tawantinsuyu:** mit'a, qollqa, Qhapaq Ñan, andenes y el regalo de cumbi.
- **Mapuches:**
  - lof sin capital;
  - relevo de escuadrones: está en las crónicas de Tucapel y Marigüeñu;
  - kulliñ como riqueza (en mapudungun es también "pago" o "bien");
  - malón que arrea;
  - el caballo adoptado.
- **Guaraníes:** potirõ (trabajo colectivo) y la bifurcación misión o monte, que muestra la reducción como negociación y no como destino.
- **Palmares:**
  - fama y acogida;
  - las fraguas (Blaer);
  - estrepes y fojos;
  - el pacto de Cucaú como bifurcación moral.

### Sonido y edades
- **Paso 4h:** fuera el kultrun, la mbaraka y el takuapu; trutruka, kull-kull, mimby y tambor de tronco; Palmares con ngoma y marimba, sin berimbau. Correcto, y con buen criterio: "se saca el objeto sagrado en sí".
- **Edades mapuches** (*Lof → Rewe → Ayllarewe → Butalmapu*): una escala política real, con un orden histórico coherente.

---

## 4. Consultas a comunidades y especialistas

Ninguna de estas consultas es un trámite. Conviene ofrecer crédito y, si se puede, pago por la revisión, y mostrar el juego antes de publicarlo.

| Con quién | Qué preguntar | Por qué |
|---|---|---|
| **Organizaciones mapuches** (por ejemplo, una asociación de comunidades de Arauco o Malleco, o una organización urbana con área de cultura; también kimche o lingüistas mapuches universitarios) | <ul><li>Uso de la pifilka en el combate (C-08). A favor: las crónicas la ubican en la guerra (Ovalle, 1646; Rosales, c. 1674; pasajes a verificar).</li><li>Kakelkultrun: ¿es profano?</li><li>Que la *toki kura* y el canelo aparezcan en hitos de guerra; el nguillatuwe como hito jugable.</li><li>Nombres: *Weichafe*, *Kona*, *Werken*, el cuartel y los hitos de R4.</li><li>Grafía: Azümchefe, Ragileo o Unificado.</li></ul> | El ngillatun y la machi son vida religiosa actual, no pasado. |
| **Mbyá guaraní** (Misiones, Paraguay o Rio Grande do Sul; organizaciones o *aty guasu* de comunidades) y **paĩ-tavyterã o kaiowá** para *tekoha* | <ul><li>La mbaraka del karai en el hito (C-60: recomiendo la b mientras no haya respuesta).</li><li>El uso de *opy*, *karai* y *yvyra'i* en un juego de guerra.</li><li>*Tekoha* como nombre de edad: hoy es una palabra de lucha por la tierra.</li><li>*Guára* o *Amundá*; *Ñande retã*; un nombre para el explorador.</li><li>Mimby y angu'apu (C-56).</li></ul> | Los objetos rituales siguen en uso, y *tekoha* tiene un peso político presente (Mato Grosso do Sul). |
| **Quechuahablantes del Cusco y de Apurímac** (Academia Mayor de la Lengua Quechua, docentes de EIB) | <ul><li>*Awqa kamayuq*, *Qhuya wasi*, *Inkarri* o *Willkapampa*.</li><li>Cómo se vive hoy la figura de Inkarrí: para muchos es una esperanza viva, no un "guiño".</li><li>Chankas: cómo se ve en Andahuaylas que el juego los ponga como invasores; hay una identidad chanka contemporánea.</li></ul> | El mito y la identidad chanka están vivos en la región. |
| **Comunidades quilombolas** (por ejemplo, la CONAQ; comunidades de Alagoas cercanas a la Serra da Barriga) y el **Parque Memorial Quilombo dos Palmares** | <ul><li>La representación de Zumbi y de Gana Zumba (Cucaú como "traición" o como pacto).</li><li>Música: ijexá y capoeira en la paz (C-57). Recomiendo la c) de esa consulta propuesta.</li><li>La palabra "esconder".</li><li>El 20 de noviembre (Día de la Conciencia Negra): cuidar fechas de lanzamiento y textos.</li></ul> | Zumbi es figura nacional y de culto cívico; Gana Zumba es discutido dentro del movimiento negro. |
| **Pueblo cañari (Cañar, Azuay) y kichwa karanki (Imbabura)** | <ul><li>Cómo se presenta su alianza con los españoles.</li><li>*Guapondélig*.</li><li>*Tola* y casas redondas.</li></ul> | Son pueblos con organizaciones vigentes y su historia se discute en Ecuador. |
| **Especialistas** | <ul><li>Para Palmares: Silvia Lara o su equipo (Unicamp).</li><li>Para las misiones: Guillermo Wilde o Eduardo Neumann (escritura guaraní de los cabildos).</li><li>Para Vilcabamba: Brian Bauer.</li><li>Para mapuches: José Manuel Zavala o Guillaume Boccara.</li></ul> | Una lectura de una hora de cada uno ahorraría muchos `[verificar]`. |

---

## 5. Bibliografía

Marco "a verificar" lo que cito de memoria sin certeza del detalle (título exacto, año o pasaje).

### Andes
- Adelaar, Willem y Pieter Muysken. *The Languages of the Andes*. Cambridge University Press, 2004.
- Arguedas, José María. "Puquio, una cultura en proceso de cambio". *Revista del Museo Nacional* 25, 1956.
- Bauer, Brian S. *Ancient Cuzco: Heartland of the Inca*. University of Texas Press, 2004.
- Bauer, Brian S., Lucas C. Kellett y Miriam Aráoz Silva. *The Chanka: Archaeological Research in Andahuaylas*. Cotsen Institute, 2010.
- Bauer, Brian S., Javier Fonseca Santa Cruz y Miriam Aráoz Silva. *Vilcabamba and the Archaeology of Inca Resistance*. Cotsen Institute, 2015.
- Betanzos, Juan de. *Suma y narración de los Incas*, 1551.
- D'Altroy, Terence N. *The Incas*. Blackwell, 2002.
- Flores Galindo, Alberto. *Buscando un inca: identidad y utopía en los Andes*. 1986 (1.ª ed.; luego ampliada).
- González Holguín, Diego. *Vocabulario de la lengua general de todo el Perú llamada lengua qquichua o del Inca*. 1608.
- Guaman Poma de Ayala, Felipe. *Nueva corónica y buen gobierno*, c. 1615.
- Hemming, John. *The Conquest of the Incas*. 1970.
- Murra, John V. "Cloth and its Functions in the Inca State". *American Anthropologist* 64, 1962.
- Murra, John V. *The Economic Organization of the Inka State*. 1956 (tesis) / 1980.
- Rostworowski, María. *Historia del Tahuantinsuyu*. IEP, 1988.
- Salomon, Frank. *Native Lords of Quito in the Age of the Incas*. Cambridge University Press, 1986.
- Salomon, Frank. *The Cord Keepers: Khipus and Cultural Life in a Peruvian Village*. Duke University Press, 2004. Sostiene al narrador khipukamayuq de época colonial.
- Serulnikov, Sergio. *Revolution in the Andes: The Age of Túpac Amaru*. Duke University Press, 2013.
- Walker, Charles F. *The Tupac Amaru Rebellion*. Harvard University Press, 2014.
- Idrovo, Jaime. *Tomebamba: arqueología e historia de una ciudad imperial*. 2000 (a verificar).

### Mapuches
- Bengoa, José. *Historia del pueblo mapuche (siglos XIX y XX)*. 1985.
- Bengoa, José. *Historia de los antiguos mapuches del sur*. 2003. Más pertinente para los siglos XVI y XVII.
- Boccara, Guillaume. *Guerre et ethnogenèse mapuche dans le Chili colonial*. 1998.
- Boccara, Guillaume. *Los vencedores: historia del pueblo mapuche en la época colonial*. 2007.
- Dillehay, Tom D. *Monuments, Empires, and Resistance*. Cambridge University Press, 2007.
- Góngora Marmolejo, Alonso de. *Historia de todas las cosas que han acaecido en el Reino de Chile*, 1575.
- González de Nájera, Alonso. *Desengaño y reparo de la guerra del Reino de Chile*, 1614.
- Grebe, María Ester. Trabajos sobre organología mapuche en la *Revista Musical Chilena* (a verificar títulos).
- Núñez de Pineda y Bascuñán, Francisco. *Cautiverio feliz*, 1673.
- Ovalle, Alonso de. *Histórica relación del Reino de Chile*, 1646.
- Rosales, Diego de. *Historia general del Reino de Chile*, c. 1674.
- Vivar, Jerónimo de. *Crónica y relación copiosa y verdadera de los reinos de Chile*, 1558.
- Zavala Cepeda, José Manuel. *Los mapuches del siglo XVIII*. 2008.
- Zavala Cepeda, José Manuel (ed.). *Los parlamentos hispano-mapuches 1593–1803*. 2015.

### Guaraníes y tupíes
- Avellaneda, Mercedes y Lía Quarleri. "Las milicias guaraníes en el Paraguay y Río de la Plata". *Estudos Ibero-Americanos* 33:1, 2007.
- Cadogan, León. *Ayvu Rapyta*. 1959.
- Ganson, Barbara. *The Guaraní under Spanish Rule in the Río de la Plata*. Stanford University Press, 2003.
- Garavaglia, Juan Carlos. *Mercado interno y economía colonial*. Grijalbo, 1983. Sobre la yerba mate.
- Golin, Tau. *A Guerra Guaranítica*. 1998.
- Meliá, Bartomeu. *El guaraní conquistado y reducido*. CEADUC, 1986.
- Meliá, Bartomeu, Georg Grünberg y Friedl Grünberg. *Los Paĩ-Tavyterã*. 1976.
- Monteiro, John M. *Negros da terra*. Companhia das Letras, 1994.
- Neumann, Eduardo. *Letra de índios: cultura escrita, comunicação e memória indígena nas reduções do Paraguai*. 2015 (a verificar el año). Para el escribano narrador.
- Ruiz de Montoya, Antonio. *Conquista espiritual*, 1639.
- Ruiz de Montoya, Antonio. *Tesoro de la lengua guaraní*, 1639.
- Susnik, Branislava. *Los aborígenes del Paraguay*. 1979–1982.
- Wilde, Guillermo. *Religión y poder en las misiones de guaraníes*. SB, 2009.

### Palmares, lado brasileño
- Gomes, Flávio dos Santos. *Palmares: escravidão e liberdade no Atlântico Sul*. Contexto, 2005.
- Gomes, Flávio dos Santos (org.). *Mocambos de Palmares*. 2010.
- Lara, Silvia Hunold. *Palmares & Cucaú: o aprendizado da dominação*. Edusp, 2021.
- Lara, Silvia Hunold y Phablo Fachin (orgs.). *Guerra contra Palmares: o manuscrito de 1678*. Chão, 2021.
- Reis, João José y Flávio dos Santos Gomes (orgs.). *Liberdade por um fio: história dos quilombos no Brasil*. Companhia das Letras, 1996.
- Schwartz, Stuart B. *Slaves, Peasants, and Rebels*. University of Illinois Press, 1992. Incluye el capítulo sobre mocambos y Palmares.
- Thornton, John K. "Palmares revisitado". *Afro-Ásia* 65, 2022.
- Para el lado africano (Kongo, Ndongo, *kilombo*), ver el informe 02.
