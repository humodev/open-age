# 27 · Juego tardío, progreso por edad y saberes de los pueblos

Fecha: 2026-11-16. Etapa 26, paso 3 ([`proceso/26-juego-tardio`](../../proceso/26-juego-tardio/README.md)). Es diseño: no se implementó nada ni se corrió ningún torneo. Lo único ejecutable es el modelo numérico [`tools/modelo_progreso.py`](../../tools/modelo_progreso.py).

> Pedido del autor: un final de partida y unas recompensas y progreso al subir de edad al nivel de AoE4, con las cantidades del veterano ([01-veterano-cantidades.md](../../proceso/26-juego-tardio/01-veterano-cantidades.md)). Ser creativos y abrir la mente a los **saberes** de estos pueblos que la historia de los conquistadores borró (la trepanación andina, por ejemplo), pero con evidencia. Si rompe el balance, queda diseñado como contenido para retomar.

**Base:** los datos de hoy (`data/unidades.json`, `tecnologias.json`, `edades.json`, `reglas.json`, `civs/*.json`); los 51 errores históricos y 27 pedidos de juego ([26-pendientes](26-pendientes-historia-y-juego.md)); la revisión histórica de la etapa 25; las consultas C-31 a C-74.

## Cómo leer este documento

- **Números tentativos.** Todo número de balance es una propuesta para el torneo, no un dato. Cuando entre al juego va a `data/` (regla 4 del proyecto); mientras tanto vive en `PROPUESTA` y `PROPIAS` del modelo.
- **Nivel de evidencia** de cada saber:
  - **documentado:** lo cuentan fuentes escritas de la época (propias o ajenas) y la historiografía lo acepta;
  - **arqueológico:** lo muestran restos materiales estudiados;
  - **debatido:** hay evidencia, pero la interpretación o la fecha se discute; el juego lo dice así en la ficha.
- **[verificar]:** nombre o dato que no pude confirmar con la precisión necesaria. Va en castellano en el juego hasta que lo confirme un hablante o la fuente (regla C-30 b).
- **Reglas que este diseño respeta** (de la etapa 25 y del documento 26):
  1. lo sagrado vivo no da bonos de combate, no se construye como pieza del jugador y no suena en las órdenes;
  2. toda renta dice quién la paga;
  3. una ventaja histórica con costo tiene costo en el juego;
  4. la mecánica no contradice la historia;
  5. ningún saber se presenta como "mágico": cada uno es técnica, institución u oficio.

---

# 1. Progreso por edad (I a IV)

## 1.1 Qué abre cada edad

La idea de fondo, la del veterano: **el poder no llega gratis al subir; llega con lo que se puede comprar después de subir.** Cada edad abre opciones, no porcentajes.

| | **I** | **II** | **III** | **IV** |
|---|---|---|---|---|
| **Unidades compartidas** | guerrero, hondero, **lancero** (baja de la II), explorador | jinete, **hostigador montado**, ariete | arcabucero, **asedio de área**, **sanador** | **cañón o pieza pesada**; la **tropa de élite** es la propia de la IV de cada pueblo (§3) |
| **Niveles** | común | común | **veterano** por línea (5 líneas) | **élite** por línea (5 líneas) |
| **Herrería** (en el cuartel; no hace falta un edificio nuevo) | — | tanda I: ataque cuerpo a cuerpo, ataque a distancia, armadura cuerpo a cuerpo y armadura a distancia | tanda II (las mismas 4) y adiestramiento | tanda III (las mismas 4) |
| **Economía** | tala I, cestas | alimento II (riego), riqueza I, piedra, **velocidad del aldeano** | tala II, alimento III (terrazas), riqueza II, **vida del aldeano** (textiles) | **tala III, alimento IV (la granja como sostén), carga II**: la economía del final |
| **Defensa** | empalizada y puerta | torre, mampostería I, vigías | **fortaleza o torre pesada** (§4.2), aspilleras, mampostería II | fortaleza reforzada, reparación rápida |
| **Escuela** (el equivalente propio de la universidad, §1.3) | — | — | — | 6 mejoras |
| **Propias** (§3) | — | 2 mejoras + 1 unidad | 3 mejoras + 1 unidad | 3 mejoras + 1 unidad (la de élite) + **maravilla** |
| **Otros** | — | mercado, segundo centro | — | comerciante que camina (§4.3) |

**Las cinco líneas** que suben de nivel: **choque** a pie, **distancia**, **línea**, **montados** (jinetes y elefantes) y **pólvora**. El nivel se compra en el edificio que entrena la línea. Si un pueblo entrena una línea en dos edificios (Etiopía, los montados en el establo; Ayutthaya, los elefantes en el kraal), el nivel está en los dos.

| Nivel | Edad | Efecto (tentativo) | Costo (tentativo) | Tiempo |
|---|---|---|---|---|
| Veterano | III | +5 % de ataque y +5 % de vida a la línea | 150 de alimento + 150 de riqueza | 45 s |
| Élite | IV, después del veterano | +10 % de ataque y +5 % de vida a la línea (acumulado: +15 % y +10 %) | 300 de alimento + 300 de riqueza | 60 s |

Diez mejoras de nivel en total, como pidió el veterano.

## 1.2 Cómo se reemplaza el bono automático sin cambiar el poder total (paso 1)

Hoy, `edades.json → bono_ataque` suma +10, +20 y +35 % al ataque de toda la tropa y de los edificios que disparan (`sim.gd`, `effective_attack`). El paso 1 lo saca **para las unidades** y devuelve ese poder en cosas que se compran:

| Edad | Hoy (gratis) | Paso 1 (se compra) |
|---|---|---|
| II | +10 % | La **herrería I de ataque** (`armas_1`, el mismo costo de hoy: 100 de alimento + 50 de riqueza) suma, además de su +1, **+10 % de ataque** a todas las líneas |
| III | +20 % | La herrería I (+10 %) y el **veterano** de cada línea (+5 % de ataque, +5 % de vida) |
| IV | +35 % | Lo anterior y el **élite** de cada línea (+10 % de ataque, +5 % de vida más) |

- **Los edificios conservan su bono por edad:** el campo pasa a llamarse `bono_ataque_edificio`, con los mismos valores (0, 10, 20, 35). La defensa que aguanta (§4.2) no se toca en el paso 1.
- **El efecto nuevo `ataque_pct` por línea** es la misma cuenta que el bono de hoy (`atk × (100 + pct) / 100`), pero por jugador y por línea. Hace falta que la simulación sepa la línea de cada unidad: sale de `funcion` más las marcas `montado`, `elefante` y `polvora`, que ya existen.
- **La IA tiene que comprar los niveles.** Es el riesgo más grande que marcó el veterano. Orden de compra: herrería I al llegar a la II; al llegar a la III, el veterano de las dos líneas con más población en su ejército; al llegar a la IV, el élite de esas dos y después el resto.
- **El resultado del modelo (§5, tabla 1):** con el gasto típico, el poder del ejército de 30 queda igual que hoy en las cuatro edades y en los seis pueblos (diferencias de 0 a −2 %). Lo que cambia es el **cómo**: quien no compra los niveles pelea con un 8–9 % menos de poder en la III y un 20 % menos en la IV, y elegir qué línea subir es una decisión de composición.

## 1.3 La "universidad" de cada pueblo: la escuela de la edad IV

La universidad de AoE4 es una institución europea. Acá cada pueblo tiene **el lugar donde se guardaba y se enseñaba su saber técnico**. Las seis mejoras son las mismas para todos (la capa común); cambian el nombre, el edificio y la ficha.

| Pueblo | Escuela | Qué era | Evidencia | Edificio |
|---|---|---|---|---|
| Tawantinsuyu | ***Yachaywasi*** ("casa del saber") | Donde los *amawta* enseñaban a los hijos de la nobleza: lengua, khipu, historia y ritos | documentado (Garcilaso, 1609); su forma de escuela formal está **debatida**, porque Garcilaso idealiza el Cusco | la kallanka |
| Mapuches | ***Trawün*** de los *weupife* [verificar] | Reunión civil donde los *weupife* (los que cuentan la historia) transmitían el saber de los linajes. No se usa el *ngillatun*, que es ceremonia | documentado (crónicas del parlamento; Bengoa, 1985); el rol del weupife en el siglo XVII, a verificar | el parlamento o el lof principal |
| Guaraníes | vía misión: **imprenta y talleres de la misión**; vía monte: ***óga guasu*** (la casa grande comunal) | En las misiones, la primera imprenta del Río de la Plata (hacia 1700), con tipos fundidos por artesanos guaraníes. En el monte, el saber se transmitía en la casa comunal | imprenta: documentado (Furlong, 1953); óga guasu: documentado (Montoya, 1639; Susnik) | la tava o el aty guasu |
| Etiopía | **Talleres de Gondar** | Artesanos de la corte de Fasilädäs y sus sucesores: albañiles, carpinteros y herreros, muchos beta israel, con la línea honesta sobre su despojo (H-30) | documentado (Quirin, 1992; Pankhurst) | el recinto de Gondar o el centro |
| Palmares | **Conselho dos mocambos** [verificar el nombre] | El consejo de jefes de mocambo alrededor del rey en el Macaco | documentado (Relação de 1678; Lara, 2021) | el Macaco |
| Ayutthaya | ***Krom Horasat*** [verificar], el departamento de los astrónomos de la corte | Los astrónomos y calendaristas del rey, cuyas reglas analizó Cassini en París | documentado (La Loubère, 1691) | el palacio (centro) |

**Las seis mejoras de la escuela** (tentativas): dos de combate, que entran en el modelo, y cuatro que no suman poder de combate directo (de asedio, defensa y economía), para no inflar la IV:

1. **+10 % de vida a la infantería de choque.**
2. **+10 % de ataque a la pólvora.**
3. **+15 % de daño del asedio contra edificios.**
4. **El asedio se repara en el campo** (los aldeanos lo reparan como un edificio).
5. **+1 casilla de alcance a torres y fortalezas.**
6. **Registros** (khipu, actas, cuentas): −10 % de costo en las mejoras de la IV.

Las de combate no tocan nada sagrado. En Etiopía, por eso la escuela son los talleres de la corte y no las escuelas de la iglesia (*qəne bet*), que se consultan aparte (§7).

---

# 2. Unidades compartidas nuevas

| Ranura | Edad | Función en el juego | Números tentativos |
|---|---|---|---|
| **Lancero** | I (baja de la II) | Respuesta temprana a la caballería y muro de la mezcla C2 | Como hoy; ya está en la I para incas y mapuches |
| **Hostigador montado** | II | Jabalinas o flechas, rápido y frágil; el que kitea al choque (J-04, C-64 c) | 110 de vida, 7 de ataque, alcance 4000, velocidad 2000, +4 contra la distancia; 70 de alimento + 50 de madera, 2 de población |
| **Asedio de área** | III | Rompe bloques de tropa; poco daño a edificios | 150 de vida, 20 de ataque en un radio de 1,2 casillas (50 % al borde), alcance 7000, cadencia 5 s; 150 de madera + 100 de riqueza, 3 de población |
| **Sanador** | III | Cura 4 de vida por segundo a una unidad a 4 casillas; no pelea | 60 de vida; 50 de alimento + 75 de riqueza |
| **Cañón o pieza pesada** | IV | Rompe fortalezas y hitos; lento, necesita escolta | 300 de vida, 120 de ataque contra edificios (×4), alcance 8000, cadencia 6 s; 300 de madera + 250 de riqueza, 4 de población |
| **Tropa de élite** | IV | La propia de la IV de cada pueblo (§3) | Ver cada pueblo |

**Cuando un pueblo no tuvo esa cosa, tiene otra en su lugar.** No se le inventa un caballo ni un cañón: se usa lo que hizo con lo que tenía.

| Ranura | Tawantinsuyu | Mapuches | Guaraníes | Etiopía | Palmares | Ayutthaya |
|---|---|---|---|---|---|---|
| **Lancero (I)** | Lancero con escudo (ya está) | Lanza larga, la *waiki* de colihue (ya está) | Lancero | *Chewa* (baja a la I) | Lanceiro | Lancero |
| **Hostigador montado (II)** | **No hay caballo antes de 1532.** En su lugar, el **boleador** (frena) y la velocidad del Qhapaq Ñan | **Malonero**: kona liviano de lanza corta. Ya tenían caballos propios a fines del siglo XVI | **No hay caballo antes de las misiones.** En su lugar, el **hostigador del monte** a pie, con sigilo en el bosque | **Jinete jabalinero**, la caballería ligera de la nobleza | **No hay caballo.** En su lugar, la **gente da correria** a pie, rápida en el mato | **Jinete ligero** (*thahan ma* [verificar]) |
| **Asedio de área (III)** | **Hondero de piedra caliente**: hoy es su ariete y pasa a esta ranura. Piedras al rojo que encendían los techos de paja (Cusco, 1536) | **Flecheros de fuego**: flechas incendiarias (las ciudades del sur, 1599–1604) | **Cañón de tacuara** (hoy es su ariete): tacuara reforzada con cuero, usada en Mbororé (1641) | **Pieza ligera**: cañones llegados con los portugueses en 1541 | **No tiene.** En su lugar, la defensa: la cerca con estrepes y los fojos (§3.5) | **Cañón de muralla** (*puen* [verificar]) |
| **Sanador (III)** | ***Hampikamayuq*** ("el que se ocupa de los remedios") | **Lawentuchefe** [verificar]: el que sabe de remedios (*lawen*). **No es la machi**, que es autoridad espiritual | **Pohãnohára** [verificar]: el que cura con remedios (*pohã*). No es el *karai* | ***Hakim*** (médico) | **Curador o curadora** [verificar el término] | ***Mo*** (médico); en la corte, *mo luang* |
| **Pieza pesada (IV)** | **No hay cañón.** En su lugar, las **galgas** (piedras que ruedan desde la ladera) y la **inundación de Ollantaytambo** (§3.1) | **No hay cañón.** En su lugar, el **cerco largo y el fuego**: la mejora *Weichan* rompe fortalezas con el tiempo (hito de hoy) | **Cañón de bronce de las misiones** [verificar si los fundieron] o el cañón de tacuara reforzado | **Cañón de la corte** (portugués u otomano), escaso | **No hay cañón.** En su lugar, la **antorcha de la correría**: bono contra edificios de madera y cañaverales | ***Puen yai*** (cañón grande) de bronce |

---

# 3. Los saberes de cada pueblo

Cada pueblo tiene **8 mejoras propias** (2 en la II, 3 en la III y 3 en la IV), con al menos una de economía, una militar y una de su mecánica, y **3 unidades propias** (II, III y IV). En cada fila:
- **qué hace:** los números son tentativos;
- **saber:** la técnica o la institución histórica que la sostiene;
- **evidencia:** el nivel y la fuente.

Las mejoras se compran en el edificio de su eje: las de economía en el centro o el almacén; las militares en el cuartel; las de la mecánica en el edificio propio (qollqa, corral, misión, gult, mocambo, kraal).

## 3.1 Tawantinsuyu

**Mecánicas:** mit'a, Qhapaq Ñan, qollqa, andenes y cumbi. **Los saberes:** medicina quirúrgica, administración con cuerdas, conservación de alimentos, ingeniería de caminos y puentes, metalurgia del bronce. Es el pueblo con más evidencia material de todo el juego.

### Mejoras

| Edad | Nombre | Eje | Qué hace | Saber | Evidencia y fuente |
|---|---|---|---|---|---|
| II | ***Ch'uñu* y *ch'arki*** | economía | Cada qollqa guarda +50 de mit'a de tope y los andenes rinden +10 % | Papa liofilizada por helada y sol, y carne secada. Se guardaban años en qollqas con ventilación y drenaje, en hileras de cientos sobre las laderas | **Documentado y arqueológico.** Murra, *Formaciones económicas y políticas del mundo andino* (1975); Morris y Thompson, *Huánuco Pampa* (1985); Cobo, *Historia del Nuevo Mundo* (1653) |
| II | ***Khipukamayuq*** | mecánica | La mit'a por runa de las edades III y IV vuelve de 3 a 4. El taller de tejido consume 10 % menos | Registro en cuerdas anudadas con sistema decimal posicional: censos, tributo y depósitos. **La mit'a era tributo en trabajo:** lo dice la ficha | **Arqueológico y documentado** para lo numérico (Locke, *The Ancient Quipu*, 1923; Ascher y Ascher, *Code of the Quipu*, 1981). **Debatido** si registraban relatos (Urton, *Signs of the Inka Khipu*, 2003; Salomon, *The Cord Keepers*, 2004) |
| III | **Cirugía de cráneo** (trepanación) | militar | El 20 % de los guerreros y lanceros que mueren a 6 casillas de un hampikamayuq o de la kallanka vuelve a la kallanka a los 60 s, con la mitad de la vida. Además, el hampikamayuq cura +25 % | La cirugía craneal andina: **más de 800 cráneos trepanados** estudiados en el Perú, muchos con fracturas de porra o de honda. En la época inca, entre el **75 y el 83 % sobrevivía** a largo plazo (el hueso cicatrizado lo muestra), más que en la Guerra Civil de Estados Unidos (46–56 %) [verificar las cifras exactas] | **Arqueológico (fuerte).** Verano, *Holes in the Head: The Art and Archaeology of Trepanation in Ancient Peru* (2016); Kushner, Verano y Titelbaum, *World Neurosurgery* 114 (2018). **En el juego no se muestran cráneos ni restos humanos:** la ficha usa ilustración de instrumentos (*tumi*) y del hueso cicatrizado en dibujo |
| III | ***Q'eswa chaka*** (puente de ichu) | mecánica | El Qhapaq Ñan se puede tender sobre ríos de hasta 2 casillas (6 de mit'a por tramo). Los caminos dan +5 % más de velocidad | Puentes colgantes de fibra de ichu trenzada que las comunidades renovaban por turnos. **El de Q'eswachaka se sigue renovando cada año** | **Documentado.** Garcilaso, *Comentarios reales* (1609); Hyslop, *The Inka Road System* (1984). Patrimonio inmaterial de la UNESCO (2013). **Tradición viva:** consultar a las comunidades de Quehue antes de usar el nombre (§7) |
| III | ***Champi*** (bronce) [verificar] | militar | +1 de ataque al choque (porras de estrella de bronce) | Aleación de cobre y estaño estandarizada en todo el imperio, para herramientas y armas | **Arqueológico.** Lechtman, "Andean Value Systems and the Development of Prehistoric Metallurgy", *Technology and Culture* 25 (1984). El nombre, en González Holguín (1608) [verificar] |
| IV | ***Mitmaqkuna*** | economía | Cada centro nuevo llega con 3 runa y 60 de mit'a | Colonias de familias trasladadas para poblar, producir o vigilar. **Muchas veces fue traslado forzoso:** lo dice la ficha | **Documentado.** Rowe (1946); D'Altroy, *The Incas* (2014) |
| IV | ***Warak'a* trenzada** | militar | +0,5 casillas de alcance a honderos y boleadores | Hondas de fibra de camélido con trenzas complejas, el arma con la que se sitió el Cusco en 1536 | **Documentado** (Titu Cusi Yupanqui, *Instrucción*, 1570; Hemming, *The Conquest of the Incas*, 1970) y **arqueológico** (hondas en contextos andinos) |
| IV | ***Chaski* en relevo** | mecánica | Todo tramo de camino conectado a la llaqta da visión de 4 casillas; el chaski anda +20 % en los caminos | Corredores en postas (*chaskiwasi*) cada pocos kilómetros que llevaban mensajes y khipus | **Documentado.** Cieza de León (1553); Hyslop (1984) |

### Unidades propias

| Edad | Unidad | Qué hace | Saber | Evidencia |
|---|---|---|---|---|
| II | **Boleador** (ya existe) | Frena 3 s; poco daño | Boleadoras de piedra y cuero | Documentado |
| III | **Galgueros** (cuadrilla de galgas) | Asedio de defensa: desde una loma, sueltan piedras que ruedan ladera abajo, 60 de daño a todo lo que esté en la línea. Solo pegan cuesta abajo (usa la altura del mapa, D-027) | Galgas preparadas en las laderas contra los españoles en Ollantaytambo (1537) y en el camino a Vilcabamba | **Documentado.** Titu Cusi Yupanqui (1570); Hemming (1970) [verificar los pasajes] |
| IV | **Jinete de Manco** (élite) | Montado con lanza y, a veces, arcabuz capturado. Solo se entrena en Vilcabamba y con caballos capturados (ya existe la captura en el hito). Tope de 8 | Las tropas de Manco Inka aprendieron a montar y a usar armas capturadas en la resistencia (1537–1572) | **Documentado.** Titu Cusi Yupanqui (1570); Bauer, Fonseca y Aráoz, *Vilcabamba and the Archaeology of Inca Resistance* (2015) |

**Maravilla: Ollantaytambo** (la fortaleza de Manco, 1537). Mientras está en pie, la llanura junto al río a 12 casillas se puede **inundar** una vez cada 5 minutos: el enemigo anda a la mitad durante 45 s. Es lo que hizo Manco contra Hernando Pizarro, desviando el agua por los canales. **Documentado** (Hemming, 1970; Protzen, *Inca Architecture and Construction at Ollantaytambo*, 1993). Encaja con la edad IV de Vilcabamba y con la H-14 (que la IV se parezca a la resistencia, no a un imperio de oro).

## 3.2 Mapuches

**Mecánicas:** lof disperso, malón y arreo, sigilo, relevo y caballo. **Los saberes:** la adopción rápida y propia de lo que llegó de afuera (caballo, trigo, manzana, ganado, plata), la táctica que frenó al imperio español durante tres siglos, la herbolaria y la diplomacia de los parlamentos. **Cuidado:** la machi, el rewe, el kultrun y el *foye* (canelo) son sagrados y no se usan (H-22, H-27).

### Mejoras

| Edad | Nombre | Eje | Qué hace | Saber | Evidencia y fuente |
|---|---|---|---|---|---|
| II | **Coseletes de cuero** | militar | +1 de armadura cuerpo a cuerpo al weichafe y al choque | Corazas y cascos de cuero crudo (de lobo marino y, después, vacuno) | **Documentado.** Ercilla, *La Araucana* (1569); Góngora Marmolejo, *Historia de Chile* (1575) |
| II | **Arreo en tropilla** | mecánica | El arreo pasa de 3 a 4 cabezas por minuto y el corral guarda 25 % más | Manejo ganadero y rutas de arreo a través de la cordillera (las rastrilladas) | **Documentado.** León Solís, *Maloqueros y conchavadores* (1991); Bengoa, *Historia del pueblo mapuche* (1985) |
| III | **Hoyos y estacas** | mecánica | El weichafe cava hoyos ocultos (20 de madera): 40 de daño y frenado de 4 s a quien cae, el doble a los montados. Se ven a 2 casillas | Hoyos encubiertos con estacas contra la caballería (Marihueñu, 1554; Lautaro) | **Documentado.** Vivar, *Crónica* (1558); Góngora Marmolejo (1575) [verificar los pasajes] |
| III | ***Lawen*** (remedios) | militar (sanador) | El lawentuchefe cura +25 % y las tropas en el monte sanan 1 de vida por segundo fuera de combate | Herbolaria mapuche: matico (*palngiñ*) para heridas y otras plantas cicatrizantes | **Documentado** (etnobotánica). Mösbach, *Botánica indígena de Chile* (1992). **Consultar** antes de usarlo: el límite entre remedio y ceremonia lo marca la comunidad (§7) |
| III | **Trigo y manzana** | economía | Las granjas del lof rinden +15 % | Adopción propia y muy rápida del trigo, la manzana y el ganado: no fue aculturación, fue elección | **Documentado.** Bengoa (1985); Pinto Rodríguez, *La formación del Estado y la nación, y el pueblo mapuche* (2000) [verificar el título] |
| IV | ***Rütrafe*** (plateros) | economía | Cada cabeza de ganado vendida en el mercado da +20 % de riqueza; los agasajos del parlamento rinden +25 % | Platería mapuche, con la plata de las monedas del comercio de frontera (el conchavo) | **Documentado,** sobre todo en el siglo XVIII (el final de la época del juego). Morris von Bennewitz, sobre los plateros de la frontera (1997) [verificar el título] |
| IV | ***Kawellu*** (remonta propia) | militar | +10 % de vida a los montados y −10 % de costo al kona montado | Cría propia de caballos desde fines del siglo XVI: el caballo dejó de ser botín para ser economía | **Documentado.** Villalobos, *Vida fronteriza en la Araucanía* (1995); Boccara, *Los vencedores* (2007) |
| IV | ***Werken*** de los lof | mecánica | Cada lof suma +5 % al relevo y comparte visión de 8 casillas con los demás | Mensajeros entre lof y alianzas por linaje: mando sin centro | **Documentado.** Boccara (2007) |

### Unidades propias

| Edad | Unidad | Qué hace | Saber | Evidencia |
|---|---|---|---|---|
| II | **Flecheros de fuego** | Su asedio (hoy los mapuches no tienen ninguno): flechas incendiarias, +200 % contra edificios de madera y paja, poco contra la piedra | Incendio de ciudades y fuertes en el gran alzamiento (1598–1604) | **Documentado.** Rosales, *Historia general del Reino de Chile* (c. 1674) |
| III | **Infantería montada** | Weichafe a caballo que se desmonta para pelear: anda como jinete y pelea como lanza; 2 s para desmontar | Infantería que se movía a caballo y peleaba a pie, una adaptación propia del siglo XVII | **Documentado.** Villalobos (1995); Boccara (2007) |
| IV | **Kona de *waiki*** (élite) | Lancero montado pesado: +8 contra los montados, carga que derriba | Lanza larga de colihue a caballo; la caballería mapuche de los siglos XVII y XVIII | **Documentado** [verificar el largo de la lanza en las crónicas] |

**Maravilla: el gran *koyagtun*** (parlamento) [verificar la grafía]: un campo de parlamento con ramadas y la gente de los cuatro *butalmapu*. Mientras está en pie y sin enemigos dentro, los rivales no pueden capturar sitios a 15 casillas. La cuenta para ganar corre igual que en las otras maravillas. Es lo que lograron Quilín (1641) y los parlamentos siguientes: frontera reconocida por tratado. **Documentado** (Zavala, *Los mapuches del siglo XVIII*, 2008). **Consultar** si un parlamento puede ser "maravilla" (§7).

## 3.3 Guaraníes

**Mecánicas:** roza y yerba (con C-67), *potirõ* (obra colectiva), sigilo en el monte y bifurcación entre misión y monte. **Los saberes:** el manejo del monte (no es selva virgen sino monte manejado), el policultivo, la navegación de ríos, la farmacopea, la arquitectura de tacuara y, en las misiones, la imprenta y los talleres. **Cuidado:** opy, karai, mbaraka y takuapu son sagrados (H-23).

### Mejoras

| Edad | Nombre | Eje | Qué hace | Saber | Evidencia y fuente |
|---|---|---|---|---|---|
| II | ***Kokue*** (chacra de roza en policultivo) | economía | Las rozas rinden +15 % y tardan 25 % más en agotarse | Mandioca (*mandi'o*), maíz (*avati*), porotos (*kumanda*) y decenas de variedades juntas en la misma roza | **Documentado y arqueológico.** Montoya, *Tesoro de la lengua guaraní* (1639); Noelli, *Sem tekohá não há tekó* (1993) |
| II | ***Ygára*** (canoas) | mecánica | Las tropas cruzan vados y ríos de 1 casilla sin frenar; el aldeano que junta junto al río carga +2 | Navegación del Paraná y el Uruguay; flota de canoas en Mbororé (1641) | **Documentado.** Cartas anuas de la Compañía de Jesús; Furlong, *Misiones y sus pueblos de guaraníes* (1962) |
| III | ***Pohã ñana*** (remedios del monte) | militar (sanador) | El pohãnohára cura +25 % y las tropas en el monte sanan 1 de vida por segundo | Farmacopea guaraní que recogieron las misiones: plantas, usos y nombres | **Documentado.** Montenegro, *Materia médica misionera* (1710); Montoya (1639). Cuánto es guaraní y cuánto jesuita: **debatido**, y lo dice la ficha |
| III | ***Óga* de *takuára*** | economía | Casas y almacenes: −30 % de tiempo de obra y −20 % de madera; el potirõ suma +2 % más por constructor | Arquitectura de tacuara y la gran casa comunal (*óga guasu*), que levantaba todo el grupo | **Documentado.** Montoya (1639); Susnik, *Los aborígenes del Paraguay* (1979–80) |
| III | **Defensa de Mbororé** | militar | El cañón de tacuara pega +25 % y alcanza 1 casilla más; los arqueros junto a un río tienen +1 de armadura | La batalla de Mbororé (1641): canoas, arcabuces y cañones de tacuara contra los bandeirantes | **Documentado.** Cartas anuas; Furlong (1962) |
| IV | **Vía misión, *ka'a* plantada; vía monte, *ka'a ka'aguy*** | economía | Misión: el yerbal plantado (C-67 a). Monte: los yerbales silvestres rinden +25 % | En las reducciones, a comienzos del siglo XVIII, se logró que germinara la semilla de la yerba y se plantaron yerbales. En el monte, la cosecha silvestre. **La yerba fue también tributo y trabajo forzado:** lo dice la ficha | **Documentado** (Garavaglia, *Mercado interno y economía colonial*, 1983). Quién encontró la técnica de germinación: **debatido** |
| IV | ***U'y hatã*** (flecha dura) [verificar] | militar | +1 de ataque a la distancia | Arcos de madera dura (*guyrapa*) y puntas endurecidas o de hueso; arqueros temidos desde las primeras crónicas | **Documentado.** Schmidl (1567); Montoya (1639) [verificar los pasajes] |
| IV | **Vía misión, imprenta; vía monte, *aty*** | mecánica | Misión: las mejoras cuestan −15 %. Monte: el sigilo y la emboscada, +25 % | La imprenta de las misiones: el primer libro impreso en el Río de la Plata (1705), con tipos hechos por guaraníes. En el monte, la asamblea como gobierno | **Documentado.** Furlong, *Historia y bibliografía de las primeras imprentas rioplatenses* (1953) |

### Unidades propias

| Edad | Unidad | Qué hace | Saber | Evidencia |
|---|---|---|---|---|
| II | ***Ygára*** (canoa) | Transporte por el río: 6 plazas, rápida, sin ataque (D-020: sin combate naval) | La canoa monóxila del Paraná | **Documentado** |
| III | **Cañón de tacuara** (ya existe; pasa a la ranura del asedio de área) | Daño en área contra la tropa; poco contra la piedra | Mbororé (1641) | **Documentado** |
| IV | Misión: **caballería de las misiones**; monte: **guerrero del Ñande retã** (élite) | Misión: jinete de lanza (las misiones tenían estancias y compañías de caballería). Monte: choque con +2 de armadura en el monte | La Guerra Guaranítica (1754–1756) y Sepé Tiaraju. La frase "esta tierra tiene dueño" (*co yvy oguereco yara*) se le atribuye: **debatido** | **Documentado.** Ganson, *The Guaraní under Spanish Rule* (2003); Avellaneda y Quarleri (2007) |

**Maravilla:**
- **Vía misión: la plaza y el cabildo de la tava.** No la fachada de la iglesia: el cabildo guaraní, los talleres y la plaza (H-37). Mientras está en pie, la obra colectiva no tiene tope.
- **Vía monte: el *tekoha guasu*,** una gran aldea de óga guasu en el monte cerrado. Mientras está en pie, todo el bosque propio da sigilo.

Las dos, con consulta a mbyá y paĩ-tavyterã sobre *tekoha* (§7).

## 3.4 Etiopía

**Mecánicas:** la corte que se muda, el gult (renta pagada por los *gäbbar*), caballería desde la I y defensa en altura. **Los saberes:** la escritura en ge'ez, la medicina de los manuscritos, el arado de bueyes, las ambas, el calendario y las caravanas de sal. **Cuidado:** Lalibela, el tabot, la iglesia y el kebero (H-20, H-21, H-24). Nada de lo eclesiástico da combate.

### Mejoras

| Edad | Nombre | Eje | Qué hace | Saber | Evidencia y fuente |
|---|---|---|---|---|---|
| II | ***Maresha*** (arado de bueyes) | economía | Granjas +15 %; en altura no pierden rendimiento | El arado de bueyes de las tierras altas, con raíces aksumitas; terrazas en las laderas | **Documentado y arqueológico.** McCann, *People of the Plow* (1995); Crummey, *Land and Society in the Christian Kingdom of Ethiopia* (2000) |
| II | **Actas de tierra en ge'ez** | mecánica | El gult rinde +15 % y no deja de cobrar mientras la corte se muda | Las concesiones de tierra y de gult se escribían en ge'ez, a menudo en los márgenes de los manuscritos | **Documentado.** Crummey (2000). La renta la pagan los gäbbar (H-05) |
| III | ***Fäws*** (remedio) | militar (sanador) | El hakim cura +25 % y las tropas junto a la corte sanan 1 de vida por segundo | Manuscritos médicos con recetas de plantas, minerales y cirugía menor | **Documentado.** Strelcyn, *Médecine et plantes d'Éthiopie* (1968); Pankhurst, *An Introduction to the Medical History of Ethiopia* (1990). La mayoría de los manuscritos conservados es del siglo XVIII en adelante [verificar] |
| III | **Cota de malla** | militar | +1 de armadura cuerpo a cuerpo al choque (jinete noble) | Jinetes con cota de malla, descritos por el cronista de Adal y por Álvares | **Documentado.** *Futūḥ al-Ḥabaša* (trad. Stenhouse, 2003); Álvares (1540) |
| III | **Amba** | mecánica | La defensa en altura sube de +25 % a +35 %; la amba guarda 400 de riqueza que no se puede saquear | Mesetas de paredes a pique como fortaleza y como tesoro: Amba Gəšän (prisión de los príncipes) y Debre Damo (se sube con una cuerda) | **Documentado.** Taddesse Tamrat, *Church and State in Ethiopia* (1972); Phillipson (2009) |
| IV | **Caravanas de *amole*** | economía | El comerciante etíope (§4.3) rinde +20 % y la corte que se muda junto a una ruta paga −20 % | Barras de sal de las llanuras del Afar como moneda, en caravanas de mulas y camellos | **Documentado.** Pankhurst, *Economic History of Ethiopia* (1968) |
| IV | **Armeros de Gondar** | militar | +10 % de ataque a la pólvora | Reparación y fabricación local de armas de fuego en la corte de Gondar | **Debatido:** la mayoría se importaba; cuánto se fabricaba localmente es discutido [verificar] |
| IV | ***Bahrä Hasab*** (cómputo del calendario) | mecánica | La corte se despliega en la mitad del tiempo y rinde +10 % el primer minuto | El cómputo etíope del calendario, con sus propios ciclos y estaciones, que ordenaba las mudanzas de la corte y las cosechas | **Documentado,** pero es saber eclesiástico. **Consultar a la Iglesia Tewahedo** (§7). Si no, se reemplaza por "Cartógrafos de la corte en marcha" |

### Unidades propias

| Edad | Unidad | Qué hace | Saber | Evidencia |
|---|---|---|---|---|
| II | ***Shotelay*** (espada curva y escudo) [verificar] | Choque a pie con +4 contra la línea con escudo (la espada curva pasa por encima del escudo) | El *shotel*, la espada curva etíope | **Debatido** para la época: las imágenes son sobre todo de los siglos XVIII y XIX |
| III | **Jinete con cota de malla** | Montado pesado: 220 de vida, armadura 3 | Ver arriba | **Documentado** |
| IV | **Caballería aliada del *gada*** (élite) | Montados rápidos que llegan en grupo de 5 por una alianza (cuesta riqueza y no se entrenan) | Los oromo, aliados y rivales del reino; Susenyos se crió entre ellos (H-29) | **Documentado.** Mohammed Hassen, *The Oromo and the Christian Kingdom of Ethiopia* (2015). **Consultar a académicos y comunidades oromo** (§7); si no, "Caballería de la corte" |

**Maravilla: Fasil Ghebbi,** el recinto de Gondar, en piedra parda y gris, no blanca (H-49). Mientras está en pie, la corte deja de mudarse y los gult de todo el mapa rinden +25 %. Es el paso de la corte en marcha a la capital fija. **Documentado** (Pankhurst, *History of Ethiopian Towns*, 1982).

## 3.5 Palmares

**Mecánicas:** fama, acogida y liberación (con C-68), oficios, sigilo y cercas con estrepes. **Los saberes:** el policultivo en la sierra, el uso de la palmera, la metalurgia de tradición centroafricana, la defensa del territorio y la organización política propia. **Cuidado:** ningún texto dice "esconderse" como esencia (H-35); nada de capoeira, que es del siglo XIX (H-28); lo religioso (calundu) no se usa.

### Mejoras

| Edad | Nombre | Eje | Qué hace | Saber | Evidencia y fuente |
|---|---|---|---|---|---|
| II | ***Roças* y palmeiras** | economía | Granjas +15 %; los árboles de palma junto a un mocambo dan 6 de riqueza por minuto (aceite, vino de palma, fibra) | Grandes roças de maíz, porotos, mandioca, batata y caña al pie de la sierra, y el uso de la palmera, que le dio el nombre | **Documentado.** Blaer, diario (1645); *Relação das guerras feitas aos Palmares* (1678); Carneiro, *O Quilombo dos Palmares* (1947) |
| II | **Aviso de los mocambos** | mecánica | Los mocambos comparten visión y avisan cuando entra tropa enemiga a 10 casillas | Red de mocambos con vigías y sendas propias en el mato | **Documentado.** Blaer (1645); Gomes, *Palmares* (2005) |
| III | **Fuelle de Angola** | mecánica | Los oficios de la ferraria rinden +25 % y los estrepes de hierro pegan +50 % | Metalurgia del hierro de tradición bantú (fuelles de bolsa, forja) en las ferrarias de Palmares | Metalurgia bantú: **arqueológico** (Childs y Killick, *Annual Review of Anthropology*, 1993). Forjas en Palmares: **documentado** (*Relação*, 1678) [verificar el pasaje]. La herencia directa: **debatido** |
| III | **Curadores** | militar (sanador) | El curador cura +25 % y la gente junto a un mocambo sana 1 de vida por segundo | Saber de plantas que juntaba tradiciones centroafricanas e indígenas | **Documentado** en general (Sweet, *Domingos Álvares*, 2011); para Palmares en particular, **debatido**. **Consultar** a comunidades quilombolas (§7) |
| III | ***Kilombo*** | mecánica | De cada 4 personas que llegan por la fama, una entra como gente de guerra si hay un mocambo de guerra | El *kilombo* angoleño: campamento y sociedad de guerra que integraba gente de cualquier origen | **Debatido.** Miller, *Kings and Kinsmen* (1976); Munanga, "Origem e histórico do quilombo na África" (1996). Cuánto de esa institución pasó a Palmares se discute, y la ficha lo dice |
| IV | **Trato con los moradores** | economía | El mercado no cobra comisión y el comerciante (§4.3) rinde +15 % | Comercio a escondidas con los vecinos: productos de la sierra por herramientas, pólvora y sal | **Documentado.** Gomes (2005); Lara (2021) |
| IV | **Hierro de Angola Janga** | militar | +1 de armadura cuerpo a cuerpo al choque | Armas y defensas de hierro de las ferrarias propias | **Documentado** (las forjas) / **debatido** (el volumen) |
| IV | ***Fojos* y estrepes** | mecánica | Las cercas pegan +50 % de espinas; la gente de guerra cava fojos ocultos (pozos con estacas) | Fosos camuflados y estrepes en los accesos de la cerca real, descritos en las campañas de 1692–1694 | **Documentado.** Lara, "O território dos Palmares" (2021); relatos de Velho [verificar los pasajes] |

### Unidades propias

| Edad | Unidad | Qué hace | Saber | Evidencia |
|---|---|---|---|---|
| II | ***Zagaieiro*** | Arroja la azagaya (alcance 3000) y después pelea con lanza | La azagaya (*zagaia*), la lanza arrojadiza de tradición africana, mencionada en las campañas | **Documentado** |
| III | **Guarnição da cerca** | Línea que gana +2 de armadura junto a cercas y puertas propias | La defensa de la cerca real | **Documentado** |
| IV | **Capitães de mocambo** (élite) | Choque y mando: las unidades a 5 casillas pegan +1 | Jefes de mocambo y de guerra nombrados en las fuentes (como Ganga Muíça, maestre de campo) | **Documentado.** *Relação* (1678). Sin glorificar a una persona: **consultar** a la CONAQ (§7) |

**Maravilla: la cerca de la Barriga,** con sus tres anillos (los de 1692, H-17). Mientras está en pie, la fama no baja y la acogida cuesta la mitad. La cuenta para ganar es igual que las otras, pero **si el jugador eligió el Pacto de Cucaú la maravilla no se puede construir**: el precio del pacto (C-68). **Documentado** (Lara, 2021).

## 3.6 Ayutthaya

**Mecánicas:** arroz junto al agua, el *suai* (C-72), el elefante del rey y los barrios extranjeros. **Los saberes:** la hidráulica y el arroz de crecida, el saber de los elefantes, la medicina de la corte, la astronomía y el comercio y la diplomacia del Phra Khlang. **Cuidado:** el wat, la imagen del Buda, el *Tra Nimit* y el *piphat* ceremonial (H-25, H-26).

### Mejoras

| Edad | Nombre | Eje | Qué hace | Saber | Evidencia y fuente |
|---|---|---|---|---|---|
| II | ***Kotchasat*** (el saber de los elefantes) | militar | +10 % de vida a los elefantes; el kraal entrena 15 % más rápido | Tratados de elefantes (*gajasastra*): crianza, doma, medicina y la captura en el kraal real | **Documentado.** La Loubère, *Du Royaume de Siam* (1691); Baker y Pasuk, *A History of Ayutthaya* (2017) |
| II | **Arroz de crecida** | economía | Los arrozales junto al agua rinden +10 %; en la IV no se agotan | Variedades de arroz que crecen con la inundación natural de la llanura (H-09) | **Documentado.** La Loubère (1691); Baker y Pasuk (2017) |
| III | ***Tamra Phra Osot Phra Narai*** | militar (sanador) | El mo cura +25 % y el elefante del rey cura 1 de vida por segundo a los phrai cercanos | El recetario médico de la corte del rey Narai (década de 1660): plantas, minerales y prescripciones | **Documentado** (el texto se conserva) |
| III | ***Krom Tha*** (departamento de puertos) | economía | El suai rinde +15 % y los barrios extranjeros pagan +20 % | La administración real del comercio con el exterior: puerto de la izquierda (chinos) y de la derecha (musulmanes y otros) | **Documentado.** Baker y Pasuk (2017); Breazeale (1999) |
| III | **Barrio chino** | mecánica | Tercer barrio extranjero (C-71): el comercio de juncos y, en la IV, su compañía | La comunidad extranjera más grande, que defendió la muralla en 1767 | **Documentado.** Sarasin Viraphol, *Tribute and Profit* (1977) |
| IV | **La crecida como muralla** | mecánica | Las casillas bajas junto al agua a 15 casillas de la capital frenan 30 % a la tropa enemiga | La isla rodeada de ríos y la crecida anual: los sitiadores tenían que irse antes de las lluvias | **Documentado.** Baker y Pasuk (2017) |
| IV | **Fundición real** | militar | +10 % de ataque a la pólvora | Cañones fundidos en Ayutthaya, con fundidores locales, portugueses y chinos | **Documentado** [verificar la escala] |
| IV | **Reglas de la astronomía siamesa** | economía | El junco de tributo y el puerto rinden +20 % ("se zarpa con el monzón justo") | Las reglas astronómicas y del calendario siamés que La Loubère llevó a Francia y analizó Cassini | **Documentado.** La Loubère (1691) |

### Unidades propias

| Edad | Unidad | Qué hace | Saber | Evidencia |
|---|---|---|---|---|
| II | **Elefante de guerra** (*chang suek*, ya existe) | Choque de área | — | Documentado |
| III | ***Ngao*** | Línea con alabarda de hoja larga: +6 contra los montados y los elefantes | El *ngao*, el arma de asta de la infantería y de los que montaban elefante | **Documentado** |
| IV | **Compañía china de la muralla** (élite) | Arcabucería con +2 de armadura sobre la muralla y las fortalezas | La defensa china de la muralla en 1767 y el apoyo a Taksin | **Documentado.** Sarasin Viraphol (1977) |

La compañía japonesa queda como la unidad del barrio japonés.

**Maravilla: *Krung*, la ciudad isla, con el baluarte de Phom Phet.** Mientras está en pie, la crecida como muralla dobla su radio. Es una opción no sagrada. El historiador propuso Wat Phra Si Sanphet (H-50), pero es un templo y pide consulta (H-26); queda como opción si la comunidad theravada lo acepta (§7).

---

# 4. El final de partida

## 4.1 Las maravillas

| | Propuesta |
|---|---|
| Costo | 1500 de madera, 1500 de piedra y 1500 de riqueza [tentativo] |
| Obra | 600 s con 10 constructores; como los hitos, la obra es vulnerable |
| Victoria | Una cuenta de 15 minutos desde que se termina [verificar el tiempo de AoE4]. Si cae, la cuenta se pierde. Es una opción del lobby (C-50) |
| Una por pueblo | Ollantaytambo; el gran koyagtun; la plaza de la tava o el tekoha guasu; Fasil Ghebbi; la cerca de la Barriga; Krung con Phom Phet (§3) |
| Efecto mientras está en pie | El de cada pueblo, sobre todo **defensivo y económico**: obliga al rival a ir a romperla |

## 4.2 El asedio que rompe contra la defensa que aguanta

- **Defensa que aguanta (III):**
  - **fortaleza o torre pesada**, una por pueblo: pukara (incas), pukara de frontera mapuche (sin piedra: madera y tierra), trinchera de tacuara (guaraníes), amba fortificada (Etiopía), cerca real (Palmares) y *phom* (Ayutthaya);
  - **hitos militares con aura:** en el diseño completo, el bono de combate de los hitos militares de la III y la IV vale **dentro de su aura** (9 casillas, como la curación de `aura_hito.militar`), no en todo el mapa. Defender cerca del hito paga; atacar lejos no se infla. Es lo que más baja la inflación de la IV (§5).
- **Asedio que rompe:** el asedio de área (III) contra las bolas de tropa, y el cañón o pieza pesada (IV) contra fortalezas, hitos y maravillas. Los pueblos sin cañón rompen con tiempo (cerco largo y fuego, galgas, antorchas) o con su élite. El asedio sin escolta muere: la respuesta es el hostigador montado y el choque.
- **Atacar el suelo** (J-05) para el asedio de área y el cañón.

## 4.3 La economía del final

1. **Las vetas se agotan:** la arcilla de casa ya se agota (C-16). En la IV, la arcilla del centro del mapa y los sitios rinden más (`sitios.renta_por_cantidad` por edad: +50 % en la IV).
2. **El comerciante que camina** (IV, desde el mercado): lleva riqueza entre el mercado propio y uno aliado o el ingenio neutral. Rinde más cuanto más lejos va, como en AoE4, y se puede cortar. Por pueblo:
   - la caravana de llamas (Tawantinsuyu);
   - el conchavo de ganado (mapuches);
   - la canoa de yerba (guaraníes);
   - la caravana de *amole* (Etiopía);
   - el trato con los moradores (Palmares);
   - el junco del río (Ayutthaya, sin combate naval).
3. **La granja como sostén** (alimento IV): las granjas no se agotan; las rozas guaraníes y los arrozales siguen sus reglas propias.

## 4.4 Cómo terminan las partidas

1. **Por conquista:** destruir los hitos y la capital (como hoy).
2. **Por sitios:** 10 minutos (como hoy).
3. **Por maravilla:** 15 minutos (nueva, opción del lobby).
4. **Por rendición:** la IA normal, difícil y experta se rinde como la fácil (`rendicion`), con umbrales más duros: perdió 10 edificios terminados, tiene menos de un tercio del ejército del rival y su capital está atacada. Cuando se rinde, dice una frase de su pueblo.
5. **Por tiempo límite:** gana el puntaje (como hoy). La maravilla en pie suma puntos.

**Meta medible del conjunto:** en partidas de 45 minutos entre IAs normales, la **edad IV en el 40–60 %** de las partidas (hoy, ≈ 15 %) y una duración media de 25–35 minutos.

---

# 5. Modelo numérico

`tools/modelo_progreso.py` (nuevo, solo lee `data/`). Uso: `python3 tools/modelo_progreso.py` (y `--vara-fija` para la tabla 1 contra un rival fijo).

## Qué mide

- **El poder del ejército de 30** (Lanchester) es la suma de los dps contra el rival por la suma de los tiempos que tarda cada unidad en morir bajo el dps medio del rival.
  - Cada pueblo tiene **su composición por edad** según lo que produce: los incas sin caballo, los mapuches con kona, Ayutthaya con elefantes y compañías.
  - **El gasto típico** es el de hoy: herrería I en la II; herrería II y adiestramiento en la III; herrería III en la IV; y el hito militar de cada edad.
  - En la tabla 1, el rival es un ejército genérico de la misma edad con las reglas de hoy, igual para las dos columnas.
- **El valor de una línea** es cuántas unidades comunes (sin mejoras ni bono) vale una unidad de esa línea en la IV, peleando las dos contra la misma mezcla de comunes. Se calcula con la ley cuadrada: √(razón de dps × razón de vida efectiva).
  - **Interpretación de la regla del veterano** ("ninguna línea pasa de ×2 su base en la IV"): **una unidad de la IV no vale más de dos comunes.** Se consulta al autor (C-75).
- **No modela:**
  - el área (elefante y asedio), la curación, el sigilo, la altura, el alcance ni la velocidad;
  - las unidades nuevas.

  Son órdenes de magnitud: lo que decide es el torneo.

### Tabla 1 · Paso 1: el poder no cambia (contra el rival de la misma edad con las reglas de hoy; edad I de hoy = 100)

| Pueblo | I | II hoy | II paso 1 | III hoy | III paso 1 | IV hoy | IV paso 1 | Δ II | Δ III | Δ IV |
|---|---|---|---|---|---|---|---|---|---|---|
| Tawantinsuyu | 100 | 93 | 93 | 173 | 173 | 198 | 195 | 0 % | 0 % | −2 % |
| Mapuches | 100 | 111 | 111 | 167 | 166 | 202 | 201 | 0 % | −1 % | −1 % |
| Guaraníes | 100 | 108 | 108 | 124 | 123 | 153 | 152 | 0 % | −1 % | −1 % |
| Etiopía | 100 | 144 | 144 | 194 | 193 | 199 | 197 | 0 % | −1 % | −1 % |
| Palmares | 100 | 104 | 104 | 143 | 142 | 184 | 182 | 0 % | 0 % | −1 % |
| Ayutthaya | 100 | 191 | 191 | 206 | 205 | 230 | 229 | 0 % | −1 % | −1 % |

Contra un rival fijo (`--vara-fija`), las diferencias son de 0 % en todas las celdas. **El paso 1 cambia el "cómo" sin cambiar el "cuánto"**, siempre que se compren los niveles. Sin comprarlos (con la herrería sí), el ejército de la III pierde 8–9 % y el de la IV, 19–20 %.

### Tabla 2 · Diseño completo: el poder crece por compras (contra un rival fijo, el genérico de la II sin mejoras; edad I = 100)

| Pueblo | I | II | III | IV sin comprar nada | IV con el gasto típico | IV / III | IV hoy |
|---|---|---|---|---|---|---|---|
| Tawantinsuyu | 100 | 135 | 300 | 300 | 444 | ×1,48 | 621 |
| Mapuches | 100 | 180 | 329 | 329 | 510 | ×1,55 | 578 |
| Guaraníes | 100 | 163 | 218 | 218 | 323 | ×1,49 | 418 |
| Etiopía | 100 | 214 | 376 | 340 | 503 | ×1,34 | 575 |
| Palmares | 100 | 160 | 225 | 225 | 343 | ×1,53 | 574 |
| Ayutthaya | 100 | 311 | 443 | 443 | 664 | ×1,50 | 732 |

- **Llegar a la IV no da nada solo:** la columna "sin comprar nada" es igual a la III. En Etiopía es menor porque su composición de la IV cambia infantería por mosqueteros.
- **Lo que compra la IV da ×1,34 a ×1,55** de poder: élite, herrería III, escuela y el saber militar propio. Es el motivo para llegar.
- **El diseño completo termina por debajo de la IV de hoy** (444 contra 621 en los incas). **Es a propósito:** hoy la IV está inflada por el bono de +35 %, la herrería y tres hitos militares globales que se suman. Esa diferencia no se pierde:
  - pasa al **aura de los hitos** (la defensa que aguanta);
  - y a lo que el modelo no cuenta: asedio, cañón, élite propia y sanador.

### Tabla 3 · Valor de cada línea en la IV, en unidades comunes (regla: ≤ ×2)

| Pueblo | Unidad | Línea | IV hoy | IV diseño completo |
|---|---|---|---|---|
| Tawantinsuyu | Leva (awqa) | línea | ×2,45 | ×2,01 ⚠ |
| Tawantinsuyu | Boleador | distancia | ×2,41 | ×1,91 |
| Tawantinsuyu | Guerrero de porra | choque | ×2,12 | ×1,93 |
| Tawantinsuyu | Hondero | distancia | ×2,18 | ×1,79 |
| Tawantinsuyu | Lancero con escudo | línea | ×2,49 | ×2,06 ⚠ |
| Mapuches | Weichafe | choque | ×1,99 | ×1,86 |
| Mapuches | Arquero | distancia | ×1,95 | ×1,68 |
| Mapuches | Kona montado | montados | ×1,96 | ×1,94 |
| Mapuches | Lanza larga | línea | ×2,12 | ×1,83 |
| Guaraníes | Milicia arcabucera | pólvora | ×1,86 | ×1,75 |
| Guaraníes | Guerrero de macana | choque | ×1,95 | ×1,73 |
| Guaraníes | Arquero | distancia | ×2,17 | ×1,90 |
| Guaraníes | Lancero | línea | ×2,21 | ×1,83 |
| Etiopía | Mosquetero | pólvora | ×1,68 | ×1,69 |
| Etiopía | Jinete noble | montados | ×1,92 | ×1,84 |
| Etiopía | Jabalinero | distancia | ×1,81 | ×1,64 |
| Etiopía | Jinete | montados | ×1,95 | ×1,87 |
| Etiopía | Chewa | línea | ×2,05 | ×1,83 |
| Palmares | Espingardeiro | pólvora | ×2,06 | ×1,67 |
| Palmares | Gente de guerra | choque | ×2,31 | ×1,93 |
| Palmares | Flecheiro | distancia | ×2,35 | ×1,73 |
| Palmares | Lanceiro | línea | ×2,76 | ×1,91 |
| Ayutthaya | Compañía portuguesa | pólvora | ×1,68 | ×1,69 |
| Ayutthaya | Elefante de guerra | montados | ×1,89 | ×1,91 |
| Ayutthaya | Compañía japonesa | choque | ×1,95 | ×1,85 |
| Ayutthaya | Infantería de dap | choque | ×1,91 | ×1,75 |
| Ayutthaya | Arquero | distancia | ×1,89 | ×1,68 |
| Ayutthaya | Lancero | línea | ×2,05 | ×1,83 |

**Lectura:**
- **Hoy ya hay 14 líneas por encima de ×2.** La peor es el lanceiro de Palmares (×2,76), que suma la ferraria (+2/+1), el mocambo de guerra y la guerra de Zumbi. La regla del veterano ya se rompe sin contenido nuevo.
- **El diseño completo baja todas a ×2 o menos**, salvo dos líneas incas (×2,01 y ×2,06), dentro del error del modelo. Las sostiene el +1 de armadura global de la Pukara de frontera (hito de la II). Si el torneo las ve altas, ese +1 pasa a valer solo para la tropa a distancia.

**Qué se cambió para cumplir la regla** (en `PROPUESTA` y `PROPIAS` del modelo):
- la herrería III de ataque da +1 (hoy, +2), porque el élite ya sube el ataque;
- los hitos militares de la III y la IV dan su bono en aura;
- la escuela da vida al choque (no a la línea, que ya es la más dura);
- tres saberes militares de la IV se movieron a cosas que no inflan la línea:
  - la warak'a da alcance;
  - Ayutthaya y Etiopía refuerzan la pólvora, que es la línea más baja.

---

# 6. Plan de entrada

**Medida de cada paso:**
- torneo de **10 semillas** (±7 puntos; un cambio por torneo, como en la etapa 24);
- **ninguna civ por encima del 66 %**;
- desde el paso 3, partidas de 45 minutos con la **edad IV en el 40–60 %** de las partidas;
- antes de entregar: `tests/test_determinism.gd`, `tests/bench.gd` y `tests/civ_smoke.gd`, y, si toca la interfaz, el autotest con captura.

**Regla:** si un paso rompe la medida, **se pausa**. Lo diseñado queda como contenido en `data/` apagado (o en este documento) y se retoma con más contenido: modelos, animaciones y los pasos que falten.

| Paso | Qué | Necesita código | Necesita arte | Medida propia del paso |
|---|---|---|---|---|
| **1** | **Niveles veterano y élite** (10 mejoras) y **sacar el bono por edad** de las unidades, en el mismo cambio; `armas_1` con +10 %; los edificios conservan su bono (`bono_ataque_edificio`); la IA compra los niveles | Efecto `ataque_pct` y `vida_pct` por línea; línea de la unidad; orden de compra de la IA; panel de la unidad con los niveles | **No:** solo 10 íconos (2 por línea) | Tabla 1 del modelo (≈ 0 %). Tasas por civ a ±7 puntos del torneo anterior. `micro_matriz.gd` igual que hoy. Tiempos de edad iguales |
| **2** | **Herrería separada** (12 en lugar de 6): ataque y armadura, cuerpo a cuerpo y distancia | Armadura separada en los mods (hoy `armadura` suma a las dos) | No (íconos) | Torneo; micro C2 |
| **3** | **Economía del final** (las terceras de cada recurso, velocidad y vida del aldeano) y **escuela** de la IV (6) | Poco (tipos de efecto existentes, más el costo −10 %) | No | Partidas de 45 min: la IV en el 40–60 % |
| **4** | **III y IV completas:** asedio de área, sanador, cañón o pieza pesada, fortaleza; hitos militares de la III y la IV en aura; herrería III de ataque a +1 | Área con ataque al suelo (J-05), curación, aura de los hitos, galgas (altura) | **Sí:** asedio de área (4 modelos: incas y guaraníes ya tienen), cañón (3), sanador (6), fortaleza (6) | Micro con asedio; tabla 3 (≤ ×2); partidas de 45 min |
| **5** | **Lancero en la I para todos** y **hostigador montado en la II** (o su reemplazo) | IA que kitea | **Sí:** hostigador (3 montados y 3 a pie) | Torneo y la primera victoria del jugador nuevo (`primera_victoria.gd`) |
| **6** | **Saberes propios:** 8 mejoras y 3 unidades por pueblo, de a dos pueblos por torneo. Primero guaraníes y mapuches, después Palmares y Etiopía, y por último incas y Ayutthaya | Por pueblo: hoyos, canoa, regreso de caídos (trepanación), puentes, inundación, aliados que llegan | **Sí:** unas 14 unidades nuevas (boleador, cañón de tacuara, chang suek y compañía japonesa ya existen) y 48 íconos | Torneo por par; `civ_smoke.gd` |
| **7** | **Maravillas, comerciante que camina y rendición de la IA** | Victoria por maravilla, comercio, rendición en todas las dificultades | **Sí:** 6 maravillas y 6 comerciantes | Partidas de 45–60 min; opciones del lobby |

**Sin arte se puede hacer:** los pasos 1, 2 y 3 enteros, y en los demás todas las mejoras propias (son íconos). **Con arte:** las unidades nuevas y las maravillas. Mientras no haya modelo, una unidad nueva no entra al juego: el veterano lo pidió, porque la batalla ya es una mancha (J-06).

**Primer paso a implementar:** el **paso 1**.
- Es el pedido más repetido del veterano (J-09, seis rondas de seis) y el que más riesgo tiene (J-11).
- No necesita arte y el modelo dice que deja el poder igual.

Archivos que toca:
- `data/edades.json`: `bono_ataque` pasa a `bono_ataque_edificio`;
- `data/tecnologias.json`: 10 niveles y `armas_1`;
- `src/sim/sim.gd`: `effective_attack` y la línea de la unidad;
- `src/sim/sim_mods.gd`: el efecto nuevo;
- la IA de compra;
- `docs/05-mecanicas-nucleo.md`, en el mismo commit.

---

# 7. Consultas

## Para el autor (a pasar a `proceso/CONSULTAS.md`, desde C-75)

| # | Pregunta | Opciones (la por defecto, primero) |
|---|---|---|
| C-75 | **Regla del ×2:** ¿"una unidad de la IV no vale más de dos comunes" (ley cuadrada, como mide el modelo) o "ni el ataque ni la vida pasan de ×2" (más permisiva)? | a) Valor en comunes · b) Por estadística |
| C-76 | **Hitos militares con aura** en la III y la IV (en lugar de bono global). Es lo que más desinfla la IV | a) Sí, en el paso 4 · b) Solo el de la IV · c) No |
| C-77 | **Paso 1:** el +10 % de la II en la herrería I y los niveles veterano y élite comprados. ¿Arrancamos por ahí? | a) Sí · b) Primero la herrería separada |
| C-78 | **Maravilla:** costo de 1500 madera, piedra y riqueza; 600 s de obra; cuenta de 15 min; opción del lobby | a) Así · b) Otros números |
| C-79 | **Ayutthaya:** maravilla Krung con Phom Phet (no sagrada) o Wat Phra Si Sanphet (con consulta) | a) Krung · b) El wat, si la consulta lo acepta |
| C-80 | **Unidades nuevas sin modelo:** ¿esperan al arte o entran con una maqueta distinta? | a) Esperan · b) Maqueta con silueta propia |
| C-81 | **Trepanación:** que los caídos vuelvan (20 %) en lugar de un sanador más fuerte. ¿Te gusta como saber destacado? | a) Sí · b) Solo un sanador más fuerte |
| C-82 | **Etiopía, *Bahrä Hasab*:** saber eclesiástico usado en una mecánica económica | a) Consultar a la Tewahedo y, si no, "Cartógrafos de la corte" · b) Sacarlo ya |
| C-83 | **Saberes con nivel "debatido"** (kilombo, shotel, armeros de Gondar, yachaywasi): ¿entran con la marca en la ficha o se reemplazan? | a) Entran con la marca · b) Solo documentados y arqueológicos |

## Para comunidades y especialistas (suma a la tabla de C-74)

Como en la etapa 25: ofrecer crédito y, si se puede, pago por la revisión.

| Con quién | Qué |
|---|---|
| Comunidades de Quehue y Huinchiri (Q'eswachaka) | Usar el puente de ichu como mejora y su nombre |
| Quechuahablantes; arqueólogos de bioarqueología andina | La trepanación en el juego (sin restos humanos visibles), *hampikamayuq*, *champi*, *yachaywasi*, *Ollantaytambo* como maravilla |
| Organizaciones mapuches; lingüistas de mapudungun | *Lawentuchefe* y el límite con la machi; *koyagtun* como maravilla; *rütrafe*, *weupife*, *trawün*, *waiki* |
| Mbyá y paĩ-tavyterã; hablantes de guaraní | *Pohãnohára*, *pohã ñana*, *tekoha guasu*, *u'y hatã*, *ygára*; la frase de Sepé Tiaraju |
| Iglesia ortodoxa Tewahedo | *Bahrä Hasab*, los manuscritos de *fäws*, las escuelas de la iglesia (si se quieren como escuela de la IV) |
| Académicos y comunidades oromo | La caballería aliada del *gada* |
| Hablantes de amhárico y ge'ez | *Shotelay*, *hakim*, *maresha*, *amole* |
| CONAQ y quilombolas de Alagoas; lingüistas de kimbundu | *Kilombo* como saber "debatido", curadores, *Conselho dos mocambos*, capitães de mocambo, la maravilla de la Barriga y el pacto |
| *Khru* y médicos de medicina tradicional tailandesa; hablantes de tailandés | *Tamra Phra Osot Phra Narai*, *kotchasat*, *Krom Horasat*, *thahan ma*, *puen yai* |
| Comunidad theravada | El wat como maravilla (C-79) |

---

## Resumen de los saberes destacados

| Pueblo | Saber destacado | Evidencia |
|---|---|---|
| Tawantinsuyu | Cirugía de cráneo (75–83 % de supervivencia en época inca); khipu | arqueológico (fuerte); arqueológico y documentado (lo narrativo, debatido) |
| Mapuches | Hoyos y estacas contra la caballería; la adopción propia del caballo (*kawellu*) | documentado |
| Guaraníes | La imprenta de las misiones con tipos guaraníes; el *kokue* de policultivo | documentado; documentado y arqueológico |
| Etiopía | *Fäws*, la medicina de los manuscritos; actas de tierra en ge'ez | documentado |
| Palmares | Fuelle de Angola (metalurgia bantú); roças y palmeiras | arqueológico y documentado (la herencia, debatida); documentado |
| Ayutthaya | El recetario de Narai; la crecida como muralla | documentado |
