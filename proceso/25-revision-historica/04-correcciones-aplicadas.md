# 25 · 04 · Correcciones aplicadas de la revisión histórica

Fecha: 2026-11-16. Parte de los tres informes de esta etapa: [01 · América Latina](01-america-latina.md), [02 · África](02-africa.md) y [03 · Asia](03-asia.md).

## Pedido

Aplicar **solo** las correcciones que no cambian mecánicas ni balance: ningún número de juego, ningún efecto, ninguna regla de la simulación, y el hash de `tests/test_determinism.gd` igual. Lo que sí cambia mecánicas, efectos, nombres de edad o hitos jugables va a una lista aparte, para que se pase a `CONSULTAS.md`.

## Criterio

- **Textos:** se corrigieron fechas, hechos, anacronismos y frases que quitan agencia en campañas, fichas de pueblo, notas de arte y fuentes. Si un texto describe una mecánica (por ejemplo, "la roza agotada deja un yerbal"), **no se tocó**: corregirlo sin cambiar la mecánica haría que el panel mienta. Va a la lista.
- **Nombres de edad:** no se cambió ninguno. Ninguna de las propuestas de los historiadores coincide con una opción ya abierta en consulta (C-39, C-41 y C-42 tienen otras opciones). Van todas a la lista.
- **Nombres de unidades y hitos:** solo se tocó el de la leva inca (*awqa runa*, que dice "gente enemiga"), con `[verificar]`, porque así lo pidió el orquestador. Los demás nombres (hitos mapuches, *Baqueano*, *Ruka de guerra*, *Tukul*, *bayingyi* y *kathe*) van a la lista.
- **Fuentes:** las de divulgación que se ven en el juego (Memoria Chilena, *Americas Quarterly*, *Brasil de Fato*, Pesquisa FAPESP, la *Country Study* de la Library of Congress) se reemplazaron por obras académicas de la bibliografía de los informes. Las de Wikipedia en `_fuentes` (internas, no se ven) quedaron marcadas como "divulgación: orientación, no fuente"; donde el informe nombra la obra que corresponde, se sumó. Las citas que el historiador no pudo confirmar quedaron con "[verificar que exista]".
- **Sonido:** se sacaron pistas de `CIV_MUSIC` (`src/game/audio.gd`), que es solo presentación. Los archivos `.ogg` siguen en el repositorio, por si el autor quiere volverlas.
- **Arte:** solo `data/arte_edades.json` (que la simulación no lee), notas de `arte_hitos.json` y `arte_animales.json`. No se tocaron mallas.

## Resultado de las pruebas

| Prueba | Resultado |
|---|---|
| `tests/test_determinism.gd` | `ticks=3000 hash=2203695307`, DETERMINISMO: OK. **El mismo hash** que en la base (`b22e0e4`), corrida en paralelo sobre una copia limpia |
| `tests/campaign_smoke.gd` | Corren las 25 misiones (24 de campaña y el tutorial), sin errores de guion |
| `tests/civ_smoke.gd` | Las tres partidas terminan, sin errores |
| `tests/sonido_civ.gd` | RESULTADO: OK (carga todas las pistas de `CIV_MUSIC` y los sonidos por pueblo) |
| `godot --path . -- --autotest --civ=guaranies --terreno=llano` | AUTOTEST: OK. Después, al salir, el volcado de siempre (`corrupted size vs. prev_size`, código 134), ya anotado en `proceso/22-testers` |
| JSON | Los 21 archivos tocados de `data/` se cargan con `json.load` sin error |

Capturas (`--demo=base --edad=N --shot-at=3`):
- [`capturas/inca-edad-4-sin-oro.png`](capturas/inca-edad-4-sin-oro.png): la base inca en la edad IV, sin bandas de oro en kanchas, torres ni tropa.
- [`capturas/birmanos-edad-3-teca.png`](capturas/birmanos-edad-3-teca.png): Birmania en la edad III, con muros de teca oscura en lugar del ladrillo claro de Ayutthaya.

## Cambios, archivo por archivo

"Lo pide" cita el informe y su número de fila (01: E, A, R y S; 02 y 03: n.º).

#### `data/campanas/ayutthaya.json`

| Clave | Antes | Después | Lo pide |
|---|---|---|---|
| `ayutthaya-1.intro[1]` | durante quince años el tributo bajó por el río hacia allá | durante quince años el tributo salió hacia el oeste, a Pegu | 03 (Asia) n.º 18 |
| `ayutthaya-2.intro[2]` | En 1663 tres barcos holandeses cerraron la boca del río | En 1664 los barcos holandeses cerraron la boca del río | 03 (Asia) n.º 7 |
| `ayutthaya-2.intro[3]` | es como tres barcos holandeses, con una diferencia | es como los barcos holandeses, con una diferencia | 03 (Asia) n.º 7 (la cifra de tres barcos queda a verificar) |
| `ayutthaya-2.epilogo[0]` | Narai murió en Lopburi en julio de 1688. Phra Phetracha, que mandaba los elefantes del rey, tomó el palacio. Ejecutaron a Phaulkon, y también murieron los que podían heredar. | Narai se moría en Lopburi. En mayo de 1688 Phra Phetracha, que mandaba los elefantes del rey, tomó el palacio. En junio ejecutaron a Phaulkon, cercaron a los franceses en Bangkok y también murieron los que podían heredar. En julio murió Narai. | 03 (Asia) n.º 9 |
| `ayutthaya-2.objetivos.o5` | Narai se muere en Lopburi. Cercá la fortaleza | Narai agoniza en Lopburi. Cercá la fortaleza | 03 (Asia) n.º 9 |
| `ayutthaya-3.intro[0]` | En 1760 el rey de Ava, Alaungpaya, sitió la isla y se fue cuando llegaron las lluvias, como Pegu en tiempos de Naresuan. La isla había aprendido a esperar el agua. | En 1760 el rey de Ava, Alaungpaya, sitió la isla, cayó enfermo y se retiró; murió en el camino. Las lluvias estaban cerca, como cuando Pegu en tiempos de Naresuan, y la isla había aprendido a esperar el agua. | 03 (Asia) n.º 8 |
| `ayutthaya-4.epilogo[1]` | A mi hermano, que es phrai, le tatuaron en la muñeca la marca de su registro, para que nadie se pierda de las cuentas. | Dicen que a los phrai como mi hermano les van a tatuar en la muñeca la marca de su registro, para que nadie se pierda de las cuentas. | 03 (Asia) n.º 16 (la orden general es posterior a 1767) |
| `ayutthaya-4.epilogo[2]` | en Phitsanulok, en Phimai, en Fang. | en Phitsanulok, en Phimai, en Fang, en Nakhon Si Thammarat. | 03 (Asia) n.º 17 |

#### `data/civs/ayutthaya.json`

| Clave | Antes | Después | Lo pide |
|---|---|---|---|
| `riqueza_desc` | El monte paga al rey: parte de lo que se entrega | El monte paga al rey (suai): los phrai del monte pagan en sapán, cueros y estaño en lugar de servir, y el Phra Khlang, el almacén real, lo vende. Parte de lo que se entrega | 03 (Asia) n.º 13 |
| `descripcion` | Arrozales que rinden junto al agua, barrios extranjeros | Arroz de crecida que rinde junto al agua, el suai del monte que vende el Phra Khlang, barrios extranjeros | 03 (Asia) n.º 13 y 15 |
| `unidades_nuevas.elefante_rey.desc` | Almacén que camina: recibe madera, alimento y piedra. El monte paga al rey: | Almacén que camina: recibe madera, alimento y piedra. El monte paga al rey (suai): | 03 (Asia) n.º 13 |
| `edificios.granja.desc` | Arroz de inundación: +35 % de alimento a 2 casillas del agua o menos. La base empieza junto a un khlong, un canal. | Arroz de crecida: +35 % de alimento a 2 casillas del agua o menos, en la tierra que inunda el río. La base empieza junto a un khlong, un canal que era camino de agua más que riego. | 03 (Asia) n.º 15 |
| `edificios_nuevos.puerto_real.desc` | El almacén vende a los barcos de cada monzón. | El Phra Khlang, el almacén real, vende a los barcos de cada monzón. | 03 (Asia) n.º 13 |

#### `data/civs/birmanos.json`

| Clave | Antes | Después | Lo pide |
|---|---|---|---|
| `frase` | Los que vinieron en la crecida. | El reino del Irrawaddy, que contaba la gente y no la tierra. | 03 (Asia) n.º 21 |
| `_fuentes[2]` | consultadas 2026-11-15" | consultadas 2026-11-15 [divulgación: orientación, no fuente; ver Lieberman 2003 y Charney 2004]" | 03 (Asia) (bibliografía) |

#### `data/campanas/etiopia.json`

| Clave | Antes | Después | Lo pide |
|---|---|---|---|
| `etiopia-1.intro[0]` | donde por primera vez en trescientos años el rey duerme cada noche en el mismo lugar. | donde por primera vez en mucho tiempo el rey vuelve cada estación de lluvias al mismo lugar. | 02 (África) n.º 11 |
| `etiopia-1.epilogo[0]` | Badlay murió en Gomit. Once años después, Zara Yaqob vio una luz en el cielo, fundó una iglesia en ese lugar | Badlay murió en Gomit. Once años después apareció una luz en el cielo, dicen, el día en que el rey hizo apedrear a unos monjes que no se postraban ante la cruz ni ante la Virgen, los estefanitas. Las crónicas lo cuentan como milagro. Zara Yaqob fundó una iglesia en ese lugar | 02 (África) n.º 16 |
| `etiopia-2.epilogo[1]` | Su hijo Galawdewos heredó un reino que era casi solo montañas. Desde una de ellas mandó a buscar a los portugueses. | Su hijo Galawdewos heredó un reino que era casi solo montañas, y la respuesta a la carta que su padre había mandado a Portugal. | 02 (África) n.º 5 |
| `etiopia-2.fuentes[2]` | (Ethiopian Journal of Social Sciences 9:1, 2023) | (Ethiopian Journal of Social Sciences 9:1, 2023) [verificar que exista] | 02 (África) (bibliografía) |
| `etiopia-2.fuentes[3]` | Library of Congress, Ethiopia: A Country Study (1991) | Harold G. Marcus, A History of Ethiopia (University of California Press, 1994) | 02 (África) (Lo que está bien: cambiar la Country Study) |
| `etiopia-3.intro[0]` | Galawdewos tenía dieciocho años. | Galawdewos tenía unos veintiún años; había subido al trono con dieciocho. | 02 (África) n.º 4 |
| `etiopia-4.intro[1]` | y dejó el trono a su hijo Fasiladas. Fasiladas echó a los jesuitas. | y dejó el trono a su hijo Fasiladas. Fasiladas echó a los jesuitas. Susenyos se había criado entre los oromo, que desde hacía casi un siglo se asentaban en el sur y el centro del reino: no eran una horda, se gobernaban por el gada, clases de edad que se pasaban el mando cada ocho años, y fueron para nuestros reyes aliados, soldados y rivales. | 02 (África) n.º 15 |
| `etiopia-4.intro[2]` | Después hizo lo que ningún rey había hecho en trescientos años: eligió un lugar y se quedó. | Después hizo lo que ningún rey había hecho en mucho tiempo: eligió un lugar para volver cada estación de lluvias. | 02 (África) n.º 11 |
| `etiopia-4.intro[2]` | albañiles beta israel y artesanos | albañiles beta israel, a los que Susenyos había quitado la tierra con la guerra y que vivían de su oficio, y artesanos | 02 (África) n.º 17 |
| `etiopia-4.fuentes[2]` | Library of Congress, Ethiopia: A Country Study (1991) | Steven Kaplan, The Beta Israel (Falasha) in Ethiopia (NYU Press, 1992) | 02 (África) n.º 17 y Lo que está bien |
| `etiopia-4.fuentes[4] (nueva)` | Southern Ethiopia and the Christian Kingdom 1508-1708 (tesis, Londres, 1971)"  | Southern Ethiopia and the Christian Kingdom 1508-1708 (tesis, Londres, 1971)",         "Mohammed Hassen, The Oromo and the Christian Kingdom of Ethiopia, 1300-1700 (James Currey, 2015)"  | 02 (África) n.º 15 |
| `etiopia-4.intro[3]` | Pero en Lasta había señores que no querían un rey quieto. | Pero los señores de Lasta, la vieja tierra de los zagwe, se habían alzado contra Susenyos por la fe y seguían queriendo mandarse solos. | 02 (África) n.º 23 |

#### `data/civs/etiopia.json`

| Clave | Antes | Después | Lo pide |
|---|---|---|---|
| `descripcion` | el gult asigna tierras que rinden sin trabajo; | el gult da a un señor el derecho a cobrar el tributo de los campesinos (gäbbar) de una tierra: la corte cobra sin poner aldeanos; | 02 (África) n.º 18 |
| `edificios_nuevos.gult.desc` | Tierra repartida a un señor: el tributo campesino llega | Derecho de tributo dado a un señor: lo paga el gäbbar que trabaja esa tierra, y llega | 02 (África) n.º 18 |
| `edificios_nuevos.iglesia.desc` | Comunidad y tabot: recolección y vida. | Comunidad de la iglesia: recolección y vida. | 02 (África) n.º 19 (solo se saca la palabra tabot del bono; el efecto va a consulta) |

#### `data/civs/adal.json`

| Clave | Antes | Después | Lo pide |
|---|---|---|---|
| `descripcion` | con capital en Dakar y desde 1520 | con capital en Dakkar y desde 1520 | 02 (África) n.º 3 |
| `_fuentes[1]` | consultada 2026-11-15" | consultada 2026-11-15 [divulgación: orientación, no fuente]",   "Richard Pankhurst, The Ethiopian Borderlands (Red Sea Press, 1997)" | 02 (África) n.º 3 y bibliografía |

#### `data/civs/palmares.json`

| Clave | Antes | Después | Lo pide |
|---|---|---|---|
| `frase` | La libertad que llega sola y se esconde en la sierra. | La libertad que se toma y se defiende en la sierra. | 02 (África) n.º 21; 01 (América Latina) R2 (C-20) |
| `region` | Serra da Barriga y alrededores, 1605–1714 | Palmares de Pernambuco (hoy Alagoas), fines del siglo XVI a 1714 | 02 (África) n.º 6 |
| `descripcion` | No entrena aldeanos: la gente llega por la fama. | No entrena aldeanos: la gente huye de los ingenios y llega por la fama. | 01 (América Latina) R2 |
| `unidades.arcabucero.desc` | Espingarda: arma de fuego de chispa. | Espingarda: arma de fuego larga, de mecha o de pedernal. | 02 (África) n.º 33 |

#### `data/campanas/palmares.json`

| Clave | Antes | Después | Lo pide |
|---|---|---|---|
| `palmares-1.epilogo[1]` | Así se conoce a la gente que sabe esconderse: por lo que deja. | Así se conoce a la gente que no se deja encontrar: por lo que deja. | 01 (América Latina) R7 |
| `palmares-2.fuentes[3]` | Revista Pesquisa FAPESP, Documentos originais revelam novos aspectos da história de Palmares (2022) | Flávio dos Santos Gomes, Palmares: escravidão e liberdade no Atlântico Sul (Contexto, 2005) | 01 (América Latina) R3 y S13 |
| `palmares-3.epilogo[0]` | Al año siguiente mataron a Gana Zumba en Cucaú. | Poco después mataron a Gana Zumba en Cucaú. | 02 (África) n.º 8; 01 (América Latina) E13 |
| `palmares-3.fuentes[3]` | Revista Pesquisa FAPESP, Documentos originais revelam novos aspectos da história de Palmares (2022) | Robert Nelson Anderson, The Quilombo of Palmares: A New Overview of a Maroon State in Seventeenth-Century Brazil (Journal of Latin American Studies 28:3, 1996) | 02 (África) n.º 1 y bibliografía; 01 (América Latina) S13 |
| `palmares-4.fuentes[4]` | Brasil de Fato, entrevista a Silvia Hunold Lara (22 de noviembre de 2023) | Silvia Hunold Lara, Palmares & Cucaú: o aprendizado da dominação (Edusp, 2021) | 01 (América Latina) R3 y S13 |

#### `data/campanas/tawantinsuyu.json`

| Clave | Antes | Después | Lo pide |
|---|---|---|---|
| `tawantinsuyu-2.intro[0]` | Tres generaciones después de Pachakutiq | Dos generaciones después de Pachakutiq | 01 (América Latina) E5 |
| `tawantinsuyu-2.epilogo[1]` | Wayna Qhapaq murió en Tumipampa de una peste | Wayna Qhapaq murió en el norte, en Quito o en Tumipampa según quién lo cuente, de una peste | 01 (América Latina) E6 |
| `tawantinsuyu-4.intro[1]` | y descendía de los incas de Vilcabamba. | y decía descender de los incas de Vilcabamba, y lo pleiteó en Lima. | 01 (América Latina) S12 |
| `tawantinsuyu-4.intro[3]` | también kurakas leales al rey, como Mateo Pumakawa. Aquí nadie estaba de un solo lado. | también auxiliares de los kurakas leales al rey. Y en el Cusco esperaba Mateo Pumakawa, kuraka de Chinchero, con su gente. Aquí nadie estaba de un solo lado. | 01 (América Latina) E4 |
| `tawantinsuyu-4.epilogo[0]` | y cuando llegamos, en enero, el Cusco ya tenía refuerzos. | y cuando llegamos, a fin de diciembre, el Cusco ya tenía refuerzos. | 01 (América Latina) E7 |

#### `data/civs/tawantinsuyu.json`

| Clave | Antes | Después | Lo pide |
|---|---|---|---|
| `unidades_nuevas.awqa.nombre` | Leva (awqa runa) | Leva (awqa kamayuq [verificar]) | 01 (América Latina) E2 |
| `edificios_nuevos.tambo.desc` | Antiguo ingenio que el Inca ganó con un regalo de cumbi: | Un señorío vecino que el Inka ganó con regalos de cumbi: | 01 (América Latina) A4 |

#### `data/civs/caranquis.json`

| Clave | Antes | Después | Lo pide |
|---|---|---|---|
| `descripcion` | lengua propia, la cara, que no era quechua. | lengua propia, poco documentada (probablemente barbacoana), que no era quechua. | 01 (América Latina) E3 |
| `_fuentes[2]` | consultada 2026-11-15" | consultada 2026-11-15 [divulgación: orientación, no fuente; la lengua cara viene de Velasco, 1789]",   "Willem Adelaar y Pieter Muysken, The Languages of the Andes (Cambridge UP, 2004)" | 01 (América Latina) E3 y S13 |

#### `data/civs/canaris.json`

| Clave | Antes | Después | Lo pide |
|---|---|---|---|
| `descripcion` | con capital en Guapondélig, la Tumipampa de los incas. | con capital donde los incas levantaron Tumipampa (Guapondélig, según la tradición cuencana). | 01 (América Latina) E14 |
| `_fuentes[1]` | consultada 2026-11-15" | consultada 2026-11-15 [divulgación: orientación, no fuente]" | 01 (América Latina) S13 |

#### `data/civs/chankas.json`

| Clave | Antes | Después | Lo pide |
|---|---|---|---|
| `descripcion` | Sin caballos ni pólvora. Solo IA y campaña. | Sin caballos ni pólvora. Lo que se sabe de esta guerra lo contaron los incas vencedores. Solo IA y campaña. | 01 (América Latina) R9 |
| `_fuentes[2]` | consultada 2026-11-15" | consultada 2026-11-15 [divulgación: orientación, no fuente]" | 01 (América Latina) S13 |

#### `data/civs/tupies.json`

| Clave | Antes | Después | Lo pide |
|---|---|---|---|
| `_fuentes[2]` | consultada 2026-11-15" | consultada 2026-11-15 [divulgación: orientación, no fuente]" | 01 (América Latina) S13 |

#### `data/campanas/guaranies.json`

| Clave | Antes | Después | Lo pide |
|---|---|---|---|
| `guaranies-2.intro[0]` | Otros, como Ñezú, que era cacique y karai, dijeron que no, y en 1628 echaron a los padres por la fuerza. | Otros dijeron que no: lejos, en el Uruguay, Ñezú, que era cacique y karai, mató a los padres en 1628. | 01 (América Latina) E8 |
| `guaranies-2.fuentes[2]` | Memoria Chilena, el éxodo del Guairá | Bartomeu Meliá, El guaraní conquistado y reducido (CEADUC, 1986) | 01 (América Latina) E9 |
| `guaranies-4.intro[2]` | era alférez del cabildo de San Miguel y mandaba la artillería. | era alférez del cabildo de San Miguel y capitaneaba sus milicias. | 01 (América Latina) E11 |

#### `data/civs/guaranies.json`

| Clave | Antes | Después | Lo pide |
|---|---|---|---|
| `animales._doc` | Pueblo cazador: sin rebaño propio, | Pueblo de roza (maíz, mandioca, porotos, zapallo) que completaba la dieta con caza y pesca: sin rebaño propio, | 01 (América Latina) E10 |

#### `data/campanas/mapuches.json`

| Clave | Antes | Después | Lo pide |
|---|---|---|---|
| `mapuches-1.fuentes[0]` | Memoria Chilena, El toqui Lautaro (ca. 1534-1557) | José Bengoa, Historia de los antiguos mapuches del sur (Catalonia, 2003) | 01 (América Latina) S13 |
| `mapuches-2.intro` | donde a los caballos les falta el aire. | donde a los caballos les pesa la cuesta. | 01 (América Latina) S1 |
| `mapuches-2.fuentes[0]` | Memoria Chilena, Batalla de Marigüeñu | Guillaume Boccara, Los vencedores: historia del pueblo mapuche en la época colonial (2007) | 01 (América Latina) S13 |
| `mapuches-2.fuentes[3]` | (Cuadernos CANELA 31, 2021) | (Cuadernos CANELA 31, 2021) [verificar que exista] | 01 (América Latina) S13 |
| `mapuches-3.fuentes[0]` | Memoria Chilena, La Guerra de Arauco (1550-1656) | Diego de Rosales, Historia general del Reino de Chile (c. 1674) | 01 (América Latina) S13 |
| `mapuches-3.fuentes[3]` | Memoria Chilena, Estrategias y Esclavitud indígena | Guillaume Boccara, Guerre et ethnogenèse mapuche dans le Chili colonial (1998) | 01 (América Latina) S13 |
| `mapuches-4.intro[1]` | Los lonko de los cuatro butalmapu, costa, llanos, precordillera y cordillera, decidieron | Los lonko de los ayllarewe de la costa, de los llanos y de la precordillera decidieron | 01 (América Latina) A6 |
| `mapuches-4.epilogo[1]` | otros parlamentos, casi cincuenta en ciento sesenta años. | otros parlamentos, decenas en ciento sesenta años. | 01 (América Latina) S2 |
| `mapuches-4.objetivos.o4` | Convocá a los cuatro butalmapu al parlamento (avanzá a la edad IV). | Convocá a los lonko de los ayllarewe al parlamento (avanzá a la edad IV). | 01 (América Latina) A6 |
| `mapuches-4.fuentes[1]` | Jonathan Sauer, When Chile's Indigenous Made the Spanish Back Down (Americas Quarterly, 2022) | Guillaume Boccara, Los vencedores: historia del pueblo mapuche en la época colonial (2007) | 01 (América Latina) S13 |
| `mapuches-4.fuentes[3]` | Memoria Chilena, Esclavitud indígena | Alonso de Ovalle, Histórica relación del Reino de Chile (1646) | 01 (América Latina) S13 |

#### `data/arte_edades.json`

| Clave | Antes | Después | Lo pide |
|---|---|---|---|
| `civs.tawantinsuyu._nota` | (no blanca: …, 4i) y, en la última edad, las bandas de oro del Qorikancha. | (no blanca: …, 4i). Sin oro en las kanchas ni en las qollqas: el oro era del Qorikancha, de los palacios y de la vajilla del Inka, y en la edad IV (Vilcabamba, 1537–1572) el del Cusco ya se había fundido para el rescate de Cajamarca (1533). El oro queda solo en el hito del Qorikancha. Bauer, Fonseca Santa Cruz y Aráoz Silva, Vilcabamba and the Archaeology of Inca Resistance (2015). | 01 (América Latina) A1 |
| `civs.tawantinsuyu.edades[3]` | {"alto_pct": 125, "dorado": true, "remate": "dorado", "torre_alto_pct": 125, "tropa": {"oro": true}} | {"alto_pct": 125, "torre_alto_pct": 125} | 01 (América Latina) A1 |
| `civs.palmares._nota` | Fuentes: Freitas, Palmares: a guerra dos escravos (1978); Gomes, Palmares (2005) [verificar]. | Fuentes: Gomes, Palmares: escravidão e liberdade no Atlântico Sul (2005); Lara, O território dos Palmares (2021) [verificar]. No se cita a Freitas: parte de sus documentos nunca se localizó. | 01 (América Latina) R3 |

#### `data/arte_hitos.json`

| Clave | Antes | Después | Lo pide |
|---|---|---|---|
| `civs.tawantinsuyu.qorikancha._nota` | que describe Garcilaso [verificar]. | que describe Garcilaso [verificar]. Lo reconstruyó Pachakutiq hacia 1438 (Betanzos): como hito de la edad IV es un anacronismo, en consulta (C-40). Es el único lugar inca con oro en el juego. | 01 (América Latina) A3 y A1 |
| `civs.etiopia.monasterio._nota` | como Bete Giyorgis de Lalibela (siglo XIII); celdas de monjes en la pared del foso [verificar]. | como Bete Giyorgis de Lalibela (siglo XIII); celdas de monjes en la pared del foso [verificar]. Pendiente: Lalibela es zagwe, anterior al juego, y un lugar de peregrinación vivo; la investigación pedía que las iglesias excavadas fueran sitios del mapa y no algo que se construye. Propuesta: que el monasterio se vea como Debre Damo (amba con cuerda de cuero) y Lalibela pase a sitio sagrado neutral (revisión 25, informe 02). | 02 (África) n.º 9 |
| `civs.palmares.cerca_real._nota` | como la cerca real del Macaco [verificar]. | [verificar]. Las tres cercas son las que Jorge Velho describe en la Barriga (carta del 27-XI-1692); para el Macaco de 1677 las fuentes hablan de una cerca de pau a pique con estrepes (Lara, O território dos Palmares, 2021). | 02 (África) n.º 38 |
| `civs.palmares.guerra_zumbi._nota` | el tambor y el estandarte de Zumbi (1694) [verificar]. | el tambor y el estandarte del jugador. No hay fuente de época de un estandarte de Zumbi: el estandarte es solo el color del equipo, no un dato. | 02 (África) n.º 22 |

#### `data/arte_animales.json`

| Clave | Antes | Después | Lo pide |
|---|---|---|---|
| `especies.chilihueque._nota` | Camélido de los mapuches, más bajo y lanudo que la llama [verificar]. | Camélido de los mapuches (hueque, 'carnero de la tierra'): lana, carga y sacrificio, documentado por Vivar (1558). Se discute si era una llama o un guanaco domesticado: más bajo y lanudo que la llama [verificar el aspecto, no la existencia]. | 01 (América Latina) S8 |
| `rebano_por_civ._nota` | Guaraníes y tupíes no crían rebaño; lo que reclaman se ve como pecarí, que se amansaba en las aldeas [verificar]. | Guaraníes y tupíes no crían rebaño en la edad I; lo que reclaman se ve como pecarí, que se amansaba en la casa como animal criado (mymba), no en rebaño [verificar]. Las reducciones sí tuvieron grandes estancias de ganado vacuno (Yapeyú). | 01 (América Latina) S7 y E10 |

#### `data/arte_edades.json` → `civs.birmanos`

| Clave | Antes | Después | Lo pide |
|---|---|---|---|
| `_nota` (nueva) | — | Teca oscura, no el ladrillo encalado de Ayutthaya; pendiente el *pyatthat* y la *zedi* | 03 (Asia) n.º 6 |
| `edades[0]` | `{"techo": "#6a5236", "pisos_techo": 1}` | `{"muro": "#7a5636", "techo": "#6a5236", "pisos_techo": 1}` | 03 (Asia) n.º 6 |
| `edades[1]` | `{"techo": "#4e3322", "pisos_techo": 2}` | `{"muro": "#6a4a2e", "techo": "#4e3322", "pisos_techo": 2}` | 03 (Asia) n.º 6 |

Birmania sigue con `estilo.forma: "ayutthaya"`. Una forma `birmano` propia no se puede hacer solo con datos: `civ_meshes.gd` arma casas, depósitos, cuarteles, monumentos y tropa con un `match forma`, y el *pyatthat* (techo de muchos pisos con aguja) y la *zedi* (estupa en campana) son mallas nuevas. Lo que sí se pudo es la paleta: con la teca y los techos que ya tenía, se lee como un monasterio de madera (*kyaung*) y no como un palacio siamés encalado. Queda pendiente (ver la lista).

#### `src/game/audio.gd` → `CIV_MUSIC`

| Pueblo | Antes | Después | Lo pide |
|---|---|---|---|
| Palmares, paz | `musica_quilombo_berimbau_iuna_1`, `musica_quilombo_berimbau_angola_1`, `musica_quilombo_ijexa_1` | (nada: suena la música general) | 02 (África) n.º 10; 01 (América Latina) §4; C-57 b) |
| Palmares, combate | `musica_quilombo_tambores_combate_1` ("Tropical loop", genérica), `musica_marcha_batalla` | (nada: suena la general, que ya es `musica_marcha_batalla`) | 02 (África) n.º 10 |
| Ayutthaya, paz | `musica_ayutthaya_xilofono_1` ("Kingdom of a million elephants under a white parasol", el nombre de Lan Xang), `musica_ayutthaya_maha_nimit_1` | `musica_ayutthaya_maha_nimit_1` | 03 (Asia) n.º 2 |
| Ayutthaya, combate | `musica_ayutthaya_combate_xilofono_1` ("Bamboo Blitz", "tambores tribales") | (nada: suena la general) | 03 (Asia) n.º 2 |

**No se tocaron**, porque están en consulta:
- *Phleng Maha Nimit (Tra Nimit)* (C-59). Ahora es la única pista propia de Ayutthaya, así que suena más seguido. El historiador de Asia recomienda contestar b), sacarla.
- El kebero en la fanfarria, la alarma y el entrenado de Etiopía (C-58). El historiador de África recomienda el *nagarit* para la fanfarria y la alarma.

Ojo: sacar la música de paz de Palmares es, de hecho, la opción b) de C-57, que sigue abierta. Si el autor contesta a), alcanza con revertir estas líneas de `audio.gd`.

También se actualizó `assets/audio/musica/README.md`: las cinco pistas figuran "fuera de uso" y se explica por qué.

#### Documentos

- `docs/03-matriz-de-roles.md` y `docs/civs/palmares.md`: la frase de Palmares, igual que en `data/civs/palmares.json`.

## Lo que no se aplicó y no necesita consulta (pendiente técnico)

| Qué | Por qué no | Lo pide |
|---|---|---|
| Inca: oro **solo** en el centro y los hitos de la edad III | `arte_edades` no tiene una clave para poner oro solo en el centro. Se sacó el oro de la edad IV entero; el Qorikancha conserva su banda y su jardín de oro porque los dibuja `hitos_meshes.gd` aparte | 01 A1 |
| Inca edad IV como Vilcabamba: pirca más tosca, teja española en algunos techos, casco de hierro y lanza larga en la tropa | Hace falta una clave nueva de techo de teja y piezas de tropa nuevas | 01 A1 |
| Birmania: *pyatthat* y *zedi* | Mallas nuevas en `civ_meshes.gd` (forma `birmano`) | 03 n.º 6 |
| Khlong recto | En la simulación ya es un rectángulo de 9 × 2 casillas (`modulos.khlong`); lo ovalado es el dibujo del agua baja, que es común a todos los mapas. Alargarlo cambiando `largo` y `ancho` cambia la simulación (las casillas de agua y el bono del arrozal): no se hizo | 03 n.º 15 |
| Estandarte de la Serra da Barriga | El estandarte es el del equipo (`_banner`), no uno de Zumbi; se corrigió la nota. Sacarlo es tocar `hitos_meshes.gd` | 02 n.º 22 |
| Monasterio etíope como Debre Damo | Malla nueva (`lalibela` → `amba` con cuerda) | 02 n.º 9 |
| Etiopía edad III sin casco (escudo con borde de metal) y Fasil Ghebbi pardo grisáceo en vez de blanco | Son solo vista y fáciles (`arte_edades.etiopia`), pero el pedido limitaba el arte a lo inca, lo birmano y las notas | 02 n.º 30 y 31 |
| Rebaño: buey cebú para Birmania y bueyes para Etiopía | Solo vista (`arte_animales.rebano_por_civ`), pero cambia también el nombre de la unidad (`unidades.rebano.nombre` en la civ) | 02 n.º 32; 03 n.º 26 |
| Música inca sin charango ni arpa en las edades I a III | No hay música por edad; habría que sumar ese mecanismo a `audio.gd` o sintetizar quena y siku | 01 A5 |
| Línea del cumbi en la ficha ("la tela no se vendía: se regalaba, se quemaba en ofrenda y ataba lealtades"), glosario de *Gana*/"Ganga", nota de "Angola Janga", "Fama" como noticia, *sakdina* y Ayutthaya conquistadora en el panel del pueblo | Son textos del panel del pueblo, que no tiene campo para esto en los datos actuales | 01 R10; 02 n.º 34, 36 y "Lo que está bien"; 03 n.º 14 y 22 |
| Cifras a verificar: el permiso de armas de 1649 y los 27 años, las 232 casas y 40 herrerías de 1694, los asaltos a Amba Geshen de 1531 y 1533, los arcabuceros del imán antes de 1541, los 200 portugueses tras Wofla, los funerales del elefante de Naresuan, los "veintisiete fuertes", minuanes y charrúas, el "demonio" de Tucapel | No se pudieron verificar en esta pasada; quedan como están | 01 E12, E13, S3, S4; 02 n.º 24 a 26; 03 n.º 19 y 20 |

## Lista para consulta (cambian mecánicas, efectos, nombres de edad, hitos jugables o nombres)

Para que el orquestador lo pase a `CONSULTAS.md`. Entre paréntesis, la consulta abierta con la que se cruza.

### Mecánicas y efectos

1. **Yerba guaraní como recurso silvestre** (01 E1). La yerba (*ka'a*) es un árbol del monte, no lo que deja una roza agotada; en la colonia su cosecha fue trabajo forzado de encomienda. *Recomienda:* un nodo de *ka'a* en el bosque que se cosecha y se agota; el yerbal plantado recién desde la vía misión (edad III); la roza agotada deja *capuera* (la clave ya existe). En la descripción, una línea sobre la yerba como tributo y trabajo forzado. Afecta `riqueza_desc`, `descripcion` y `edificios.granja.desc` de los guaraníes, que hoy describen la mecánica actual.
2. **Ganado vacuno en la vía misión guaraní** (01 S7 y E10). Las reducciones tuvieron grandes estancias (Yapeyú). *Recomienda:* sin rebaño en la edad I y ganado vacuno desde la misión.
3. **Costo del Pacto de Cucaú** (02 n.º 1). Hoy es `tasa +25 %` sin costo, y el texto dice "a cambio de cerrar la puerta a quienes llegan". *Recomienda:* al elegir el pacto se apagan la acogida (`acogida_pausa` fija) y la liberación, o al menos se reducen a la mitad, y el panel lo dice.
4. **Liberación solo contra ingenios e invasores** (02 n.º 2). Hoy cualquier casa enemiga destruida da liberados (`sim_mods.gd`, ~l. 782), también las guaraníes, mapuches, etíopes o siamesas. *Recomienda:* que valga solo contra el ingenio neutral y contra `invasores` (como `_neutral_loot` con `liberados_por_edad`); contra los demás pueblos, nada, o nombrarlo con honestidad ("cautivos incorporados").
5. **Lalibela como hito construible** (02 n.º 9). El monasterio de la edad II se ve como Bete Giyorgis (siglo XIII, sitio vivo de peregrinación) y da +25 % de vida a los edificios. *Recomienda:* que el monasterio se vea como Debre Damo (o un monasterio del lago Tana o Debre Libanos) y que Lalibela sea un sitio sagrado neutral del mapa, no construible. Consultar a la Iglesia Tewahedo.
6. **Iglesia etíope con bono de combate** (02 n.º 19). `iglesia` da `vida_pct` +5 % a las tropas; el tabot es lo más sagrado de la iglesia. *Recomienda:* mantener `tasa +10 %` y cambiar `vida_pct` por algo de abastecimiento o de población (tierras de la iglesia, mercado, monjes y escritura); nunca destruible ni capturable como trofeo. Ya se sacó la palabra "tabot" del texto del bono.
7. **Qorikancha en otra edad** (C-40; 01 A3). *Recomienda:* b), pasarlo a la edad II o III. Si no se quiere rebalancear, a), pero con un nombre de la resistencia: "Wak'akuna de Vilcabamba" o "Punchao" (la imagen del sol que Manco llevó a Vilcabamba).
8. **Torre del Jugol** (02 n.º 12). Es de 1550–1567 y aparece en misiones de 1445, 1531 y 1543. *Recomienda:* una torre de piedra genérica de Harar o Zeila en esas misiones y el Jugol recién en la edad IV (necesita un alias por edad o por misión).
9. **Tercer anillo de la cerca real de Palmares** (02 n.º 38). Las tres cercas son las de la Barriga (1692), no las del Macaco. *Recomienda:* que el tercer anillo llegue recién en la edad IV, o dejar la nota (ya corregida).
10. **Caza del sambar como suai** (03 n.º 25, opcional). Los cueros de ciervo eran un gran negocio con Japón. *Recomienda:* que la caza sume al tributo del elefante del rey, como la madera.
11. ***Phrai luang* y *phrai som*** (03 n.º 14, a futuro). La mecánica M8 de la investigación.

### Nombres de edad (no se cambió ninguno)

12. **Tawantinsuyu, edad IV "Inkarri"** (C-39; 01 A2). *Recomienda* una opción que no está en C-39: **"Willkapampa"**, y el hito militar pasa a llamarse **"Espíritu Pampa"**. Si se conserva, la a), explicada.
13. **Guaraníes "Tekoha → Amundá → Mbororé → Tava"** (C-41; 01 R1). *Recomienda* una opción nueva: **Tekoha → Guára → Mbororé → Ñande retã** (*guára*: el conjunto de tekoha aliados, en la escala de Susnik y Meliá), a verificar con un hablante. Advierte contra *tovaja* (la a) de C-41): es "cuñado", el instrumento del pacto con los españoles, y puede leerse como celebración de la alianza colonial.
14. **Palmares, edad IV "Cucaú o Quilombo"** (C-42; 02 n.º 7). *Recomienda* **no aplicar la a)** ("Macaco"): pone el Macaco en la Barriga, contra Lara y la propia campaña, y repite el nombre del hito. Prefiere la b) "1678" o la d) dejarlo y explicar la bifurcación.
15. **Etiopía, edad III "Ras"** (02 n.º 13). Aceptable. Si se cambia: "Amba" o "Zämächa" [verificar la grafía].
16. **Birmania, edad III "Hanthawaddy"** (03 n.º 5). Es el reino mon de Pegu: usarlo como edad birmana borra a los mon. *Recomienda* **"Toungoo"** para la III, en paralelo con "Konbaung" para la IV.
17. **Ayutthaya, edad III "Ekkarat"** (03 n.º 10). Es la palabra del nacionalismo del siglo XX. *Recomienda:* aceptarlo si el panel lo explica; si no, "Naresuan" o un término de soberanía real [verificar].
18. **Ayutthaya, edad IV "Mueang Tha"** (03 n.º 11). No está documentado como nombre de época. *Recomienda:* *Krung Thonburi* (refundación) o "Phra Khlang" (el comercio de Narai); hasta tener fuente, "Puerto real".

### Nombres de unidades, edificios e hitos jugables

19. **Bayingyi y kathe en 1593** (03 n.º 3 y 4). *Recomienda:* "Tiradores portugueses a sueldo" y "Jinete" o "Jinete shan" hasta la edad III, y *bayingyi* y *kathe* solo en la IV (necesita nombres por edad o alias de misión). El informe propone el texto: **C-xx · Edades birmanas y anacronismos de 1593.** a) III "Toungoo", IV "Konbaung"; *bayingyi* y *kathe* solo en la IV *(por defecto)* · b) Dejarlo y explicarlo en el panel.
20. **Barrio chino en Ayutthaya** (03 n.º 12). La comunidad extranjera más grande falta. Texto propuesto: **C-xx · Barrio chino en Ayutthaya.** a) Sumarlo como tercer barrio *(por defecto)* · b) Que reemplace al portugués · c) Dejarlo.
21. **Hitos mapuches con toquis inventados** (01 R4). `rewe_malon` → "Malón del toqui"; `rewe_lonko` → "Nguillatuwe del rewe"; `rewe_caballeria` → "Corral de la remonta" o "Kawellu" [verificar]; `rewe_monte` → "Pewenal".
22. **"Ruka de guerra"** (cuartel mapuche; 01 R5). "Junta de guerra" hasta tener fuente.
23. **"Baqueano"** (explorador guaraní; 01 R6). Un término guaraní a verificar, o "Explorador".
24. **"Kamayuq wasi"** (almacén de mina inca; 01 S6). *Qhuya wasi* [verificar].
25. **Clave `yvy_marane`** (01 S5). Sin la ỹ dice "tierra con mal"; renombrarla a `nande_reta` (toca datos y código).
26. **"Tukul"** (02 n.º 29). Puede ser un préstamo del árabe del Sudán; "Gojjo bet" [verificar].
27. **"Sanam ying thanu" y "Khlang din"** (C-30; 03 n.º 27). Parecen armados; que los revise un hablante o, si no, "Campo de tiro" y "Almacén de arcilla".
28. **"Tributo del rey"** (`riqueza_nombre` de Ayutthaya; 03 n.º 13). *Recomienda* "Suai (pago al rey)". No se cambió porque es el nombre del recurso en la barra; las descripciones ya dicen *suai* y *Phra Khlang*.
29. **Rebaño de Palmares "Cerdo"** (01 S9; 02 n.º 35). Blaer menciona gallinas; sumarlas o dejar el cerdo con fuente.
30. **Facciones europeas** (C-44; 01 R8). *Recomienda* la b): edades por potencia, sin "Virreinato" para Brasil, y la tropa de Velho como facción "paulista" con base en los tupíes de las aldeias.
31. **Oromo como facción propia de IA, con la lógica del gada** (02 n.º 15, a futuro), y una misión o al menos un hito propio de Adal (la mezquita de Harar, el mercado de Zeila; 02 n.º 20). Rivales Lan Na, Lan Xang o Camboya para Ayutthaya en escaramuza (03 n.º 22).

### Sonido y arte en consulta

32. **C-57 (música de paz de Palmares)**: ya se aplicó la b) (ver arriba). El historiador de África la recomienda; el latinoamericano recomienda consultar con comunidades quilombolas y mestres de capoeira angola.
33. **C-58 (kebero)**: *recomienda* el **nagarit** (tambor real de guerra, profano) para la fanfarria y la alarma, y el kebero solo en la paz o en ningún lado hasta la consulta.
34. **C-59 (*Tra Nimit*)**: *recomienda* **b), sacarla**: es probablemente repertorio *naphat* y es un arreglo de banda naval de 1934.
35. **Alarma de Ayutthaya** (03 n.º 24): *klong chana*, *pi chawa* y *sang* en lugar del *piphat*, que queda para la fanfarria.
36. **C-60 (mbaraka del karai)**: el latinoamericano recomienda la b), sacarla del modelo, mientras no haya respuesta de una organización mbyá.
37. **C-20 (frases)**: se aplicó a Palmares la frase de los historiadores ("La libertad que se toma y se defiende en la sierra"), que corrige también el "llega sola" de la propuesta del diseño. Para Ayutthaya el historiador recomienda la a) ("La ciudad isla del rey, sus elefantes y sus huéspedes"); no se cambió.
38. **C-43 ("la mata")**: el latinoamericano recomienda la a).
39. **Imágenes del Buda y destrucción del wat** (03 §4): que el modelo del wat no muestre una imagen del Buda reconocible hasta consultar.
