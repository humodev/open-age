# 27 · Juego tardío, progreso por edad y saberes de los pueblos

Fecha: 2026-11-16. Etapa 26, paso 3, revisado con las tres revisiones históricas ([`proceso/26-juego-tardio`](../../proceso/26-juego-tardio/README.md)). Es diseño: no se implementó nada ni se corrió ningún torneo. Lo único ejecutable es el modelo numérico [`tools/modelo_progreso.py`](../../tools/modelo_progreso.py).

> Pedido del autor: un final de partida y unas recompensas y progreso al subir de edad al nivel de AoE4, con las cantidades del veterano ([01-veterano-cantidades.md](../../proceso/26-juego-tardio/01-veterano-cantidades.md)). Ser creativos y abrir la mente a los **saberes** de estos pueblos que la historia de los conquistadores borró (la trepanación andina, por ejemplo), pero con evidencia. Si rompe el balance, queda diseñado como contenido para retomar.

**Base:** los datos de hoy (`data/unidades.json`, `tecnologias.json`, `edades.json`, `reglas.json`, `civs/*.json`); los 51 errores históricos y 27 pedidos de juego ([26-pendientes](26-pendientes-historia-y-juego.md)); la revisión histórica de la etapa 25; las consultas C-31 a C-74; y **las tres revisiones de los historiadores de esta etapa** ([América Latina](../../proceso/26-juego-tardio/02-revision-america-latina.md), [África](../../proceso/26-juego-tardio/03-revision-africa.md), [Asia](../../proceso/26-juego-tardio/04-revision-asia.md)), ya aplicadas en esta versión.

---

# 0. Cambios por la revisión histórica

Quién lo pidió: **AL** = historiador de América Latina (informe 02); **AF** = historiador africanista (informe 03); **AS** = historiador del Sudeste Asiático (informe 04). El número entre paréntesis es la fila de su informe. "Fuente" es la que el revisor propone para sostener el cambio; lo que él marcó **a verificar** queda marcado igual acá.

**Balance:** se mantienen 8 mejoras y 3 unidades por pueblo. El único cambio de efecto que entra en el modelo es el hierro de Palmares (armadura → ataque); se volvió a correr el modelo (§5): la tabla 1 no cambia, Palmares baja en la tabla 2 (343 → 332 en la IV) y su gente de guerra baja en la tabla 3 (×1,93 → ×1,84). Lo demás son nombres, fichas, fuentes, niveles o mecánicas que el modelo no cuenta (curación, velocidad, economía).

### Tawantinsuyu

| Cambio | Pidió | Fuente |
|---|---|---|
| **Trepanación, cifra:** el 46–56 % de la Guerra Civil de Estados Unidos es **mortalidad**, no supervivencia. Ahora: "en la época inca sobrevivía entre el 75 y el 83 %; en la Guerra Civil, moría entre el 46 y el 56 %" | AL (2.3) | Kushner, Verano y Titelbaum, *World Neurosurgery* 114 (2018) [verificar las cifras en el texto] |
| **Trepanación, fecha:** es un saber andino de más de dos mil años (desde Paracas) que **el Inka heredó** y llevó a su punto más alto | AL (2.3) | Verano, *Holes in the Head* (2016) |
| **Trepanación, mecánica:** "los caídos vuelven" se leía como resurrección (regla 5). Ahora el 20 % de los que caen **por golpe** cerca del hampikamayuq **no muere**: queda herido y vuelve a la kallanka. Sin dibujo del hueso cicatrizado hasta la consulta (solo instrumentos) | AL (2.3, R-1) | Verano (2016) |
| **Ollantaytambo:** no "la fortaleza de Manco", sino la **llaqta y finca real de Pachakutiq que Manco usó como fortaleza** en 1536–1537. La inundación, con Pedro Pizarro como fuente | AL (2.3) | Protzen (1993); Pedro Pizarro (1571); Hemming (1970) |
| **Galgas repetidas** (unidad de la III y pieza pesada de la IV): la pieza pesada pasa a las **armas capturadas** de Vilcabamba | AL (2.1, R-5) | Titu Cusi Yupanqui (1570); Hemming (1970) |
| **Galgueros:** las galgas documentadas son las del **camino a Vilcabamba** (1539 y 1572), no las de Ollantaytambo | AL (2.3) | Hemming (1970); Bauer, Fonseca y Aráoz (2015) |
| ***Champi*:** en las fuentes coloniales parece nombrar **la porra de metal**, no el bronce: "*Champi*, la porra de bronce" [verificar] | AL (2.3) | Lechtman (1984); González Holguín (1608) [verificar] |
| **Huayrachina** entra como economía de la IV (el horno de viento que fundió toda la plata de Potosí hasta 1572). **Mitmaqkuna** pasa a "para retomar" (§3.7) | AL (§3, R-6) | Bakewell (1984); Van Buren y Mills, *Latin American Antiquity* 16 (2005) |
| **Chaski:** la cita larga está en *El señorío de los Incas* de Cieza (c. 1550), no en la *Primera parte* (1553) | AL (2.3) | Cieza, *Señorío*; Guaman Poma (c. 1615) |
| **Boleador:** nombre propio *liwi* [verificar] y fuente | AL (2.1) | González Holguín (1608) [verificar]; Guaman Poma |
| *Q'eswa chaka*: se suman los *chaka kamayuq*; *Mitmaqkuna* y *Yachaywasi*, fichas precisadas; la caravana de llamas es **de intercambio**, no de mercado | AL (2.2, 2.3) | Garcilaso (1609); Murra (1975) |

### Mapuches

| Cambio | Pidió | Fuente |
|---|---|---|
| **Sanador:** *lawentuchefe* (término de la salud intercultural de fines del siglo XX) → ***ampive*** [verificar] | AL (2.1, R-4) | Valdivia (1606); Febrés (1765) [verificar las entradas] |
| ***Rütrafe*** (florece a fines del XVIII y en el XIX) → **el poncho (*makuñ*)**, la gran mercancía de la frontera | AL (2.4, §3, R-4) | León Solís (1990/1991); Bengoa (2003) |
| **Maravilla:** en Quilín (1641) no había cuatro *butalmapu*: "la gente de los ayllarewe"; fuente mejor, Zavala (ed., 2015) | AL (2.4) | Zavala (2008; ed. 2015); Boccara (2007) |
| **Flecheros de fuego → "Incendiarios"** (la quema está documentada, las flechas incendiarias no) y se unifica la edad: III, en la ranura del asedio de área. La **infantería montada** baja a la II | AL (2.1, 2.4) | Rosales (c. 1674); González de Nájera (1614) [verificar los pasajes] |
| **Arreo en tropilla** pasa a la III (las rastrilladas son de fines del XVII y del XVIII); **Trigo y manzana** baja a la II | AL (2.4) | León Solís (1990/1991) |
| **Hoyos y estacas:** Mataquito y Peteroa (1556–1557), no Marihueñu | AL (2.4) | Góngora Marmolejo (1575); Vivar (1558) [verificar] |
| ***Lawen*:** nivel "documentado tardío" (Mösbach recoge el siglo XX) | AL (2.4) | Mösbach (1992); Ovalle (1646) y Rosales [verificar] |
| ***Werken* y *pron*:** se suma la cuerda de nudos para contar los días hasta la junta | AL (§3) | Rosales; Febrés [verificar el pasaje y la grafía] |
| Fuentes: Ercilla detrás de Góngora y González de Nájera; Bengoa (1985) → Bengoa (2003); Villalobos junto a Boccara; *weupife* con Febrés | AL (2.2, 2.4) | — |

### Guaraníes

| Cambio | Pidió | Fuente |
|---|---|---|
| **Élite de la IV:** Sepé Tiaraju y la Guerra Guaranítica pasan a la **vía misión** (la pelearon los siete pueblos). La vía monte tiene a los ***ka'aguygua*** [verificar la grafía] | AL (2.5, R-2) | Susnik; Meliá (1986); Ganson (2003) |
| **Frase de Sepé:** nivel "tradición, sin documento de época" | AL (2.5) | Golin (1998) |
| **Maravilla de la vía monte:** *tekoha guasu* (categoría del siglo XX, hoy en litigio) → **"Aldea grande del monte"** | AL (2.5, R-3) | Meliá, Grünberg y Grünberg (1976) |
| **Imprenta duplicada** (escuela y mejora de la IV): queda en la mejora; la escuela de la vía misión pasa a **la escritura de los cabildos y los talleres** | AL (2.2) | Neumann (2015); Wilde (2009) |
| **Imprenta:** "tipos fundidos por guaraníes" → documentado por Furlong, el detalle a verificar; se nombran las obras (1700, 1705) | AL (2.2) | Furlong (1953); Neumann (2015) |
| **Pieza pesada:** "cañón de bronce" (sin confirmar) → **tacuara reforzada con el hierro de la misión** (San Juan Bautista) | AL (2.1, §3) | Sepp (c. 1710) [verificar]; Furlong (1962) |
| **Sanador:** vía misión, **enfermero del hospital de la misión**; vía monte, *pohãnohára* con consulta (en el siglo XVII curaba el *paje* o el *karai*) | AL (2.1) | Montenegro (1710; ed. 1945); Wilde (2009) |
| *Ygára* → ***Ygá*** [verificar en Montoya]; *óga* de *takuára*: postes de madera y techo de paja o pindó | AL (2.5) | Montoya (1639) |

### Etiopía

| Cambio | Pidió | Fuente |
|---|---|---|
| ***Bahrä Hasab* sale:** es el cómputo de la Pascua y de los ayunos, y no ordenaba las mudanzas de la corte. Lo reemplaza el **orden del *kätäma*** (el campamento real con plano fijo). Se descarta "Cartógrafos de la corte" | AF (E9, S-E1) | Álvares (1540); Horvath, *JAH* 10 (1969); Pankhurst (1982) |
| **Élite:** "Caballería del *gada*" → **"Jinetes oromo aliados"**, con costo de **tratado** que se puede romper. El *gadaa* es un sistema de grados de edad, no un cuerpo montado | AF (E11) | Mohammed Hassen (2015); Bahrey (1593), trad. Beckingham y Huntingford (1954); Bruce (1790) |
| ***Shotelay*** (no atestiguado) → **Guerrero de *gaša*** (escudo y jabalinas); sale el bono "por encima del escudo"; el *šotäl* queda en la ficha como **debatido** | AF (E10) | *Futūḥ* (Stenhouse, 2003); Álvares (1540) |
| **Armeros de Gondar → "Pólvora de Massawa"**: el +10 % a la pólvora vale solo con una ruta comercial abierta | AF (E8) | Pankhurst, artículos sobre armas de fuego [verificar] |
| **Sanador:** *hakim* (médico de la corte, muchas veces extranjero) → ***wägešša*** (el que acomoda huesos) en el campo | AF (E4, S-E5) | Pankhurst (1990) |
| ***Fäws*:** nivel "documentado (s. XVIII–XIX); antes, debatido"; la ficha habla solo de farmacopea; se suma el ***kosso*** | AF (E3, S-E3) | Strelcyn (1968, 1973); Pankhurst (1990) |
| ***Ṭef* y el granero *gotära*** entran en la mejora del arado (II) | AF (S-E4) | D'Andrea, *Economic Botany* 62 (2008) [verificar el título] |
| **Comerciante y amole:** mercaderes ***jabarti***; sal cortada por afar; fuente Pankhurst (1961), no (1968) | AF (E7, S-E6) | Pankhurst (1961); Álvares (1540) |
| **Amba:** sale Debre Damo (monasterio vivo) de la mecánica; entra Wähni | AF (E6) | Taddesse Tamrat (1972); Bruce (1790) |
| **Maresha:** sin "terrazas" (son de Konso y Tigray); McCann cubre 1800–1990: se suma Álvares | AF (E1) | Álvares (1540); McCann (1995) |
| **Talleres de Gondar:** tejedores musulmanes del Islam Bet; la acusación de *buda* contra los herreros beta israel | AF (E13) | Quirin (1992); Kaplan (1992) |
| "Registros" de la escuela: los cronistas ***ṣäḥafe tə'əzaz***; jinete III: ***färäsäñña***; actas de tierra con Huntingford; Fasil Gəbbi sin iglesias en el modelo | AF (C1, E5, E2, E12) | Huntingford (1965) |

### Palmares

| Cambio | Pidió | Fuente |
|---|---|---|
| **Fuelle de Angola → "Forja de los mocambos"**: fuelle de cuenco con membrana (no de bolsa); forja, no fundición; la herencia, debatida | AF (P3), AL (2.6) | Childs y Killick (1993) |
| **Curadores:** la fuente era errónea (Domingos Álvares era gbe, del siglo XVIII y de práctica *vodun*). El sanador pasa a ***erveira / erveiro***, con Sweet (2003) y nivel **debatido** | AF (P4), AL (2.6) | Sweet, *Recreating Africa* (2003) |
| **La mejora de los curadores**, sin fuente para Palmares, se reemplaza por el ***sanguar*** (esquivar proyectiles), con la aclaración de que **no es capoeira** (H-28) | AF (S-P1) | Thornton (1988, 1999); Cavazzi (1687); Cadornega (1680) |
| **Escuela:** *Conselho dos mocambos* (nombre moderno, no es lugar de saber técnico) → ***Oficinas do Macaco***: herreros, alfareros (la **cerámica de los mocambos**) y **tejedores de palma** | AF (P12, S-P2, S-P3), AL (2.2, R-7) | Blaer (1645); Funari (1996); Orser y Funari (2001) |
| **Hierro de Angola Janga:** +1 de **ataque** (hojas y puntas), no de armadura | AF (P7) | Lara (2021); Gomes (2005) |
| **Roças e palmeiras:** palmeras **nativas**, no el dendê; "fibra, techo, fruto y vino de palma"; grafía en portugués | AL (2.6), AF (P1) | Blaer (1645); *Relação* (1678) [verificar el pasaje] |
| **Maravilla:** "Cerca do Outeiro da Barriga"; 1692 el asalto que falla, febrero de 1694 la caída; consulta sobre si puede destruirse | AF (P13), AL (2.6) | Lara (2021); Ennes (1938) |
| *Zagaieiro* glosado ("así llamaban los portugueses a la lanza arrojadiza"); *kilombo* con Thornton (2008); *fojos* con Ennes (1938); Ganga Muíça a verificar; antorcha solo contra cañaverales e ingenios | AF (P5, P8, P9, P11, P14), AL (2.6) | Thornton (2008); Ennes (1938) |

### Ayutthaya

| Cambio | Pidió | Fuente |
|---|---|---|
| **Astrología de corte fuera de las mecánicas:** "Reglas de la astronomía siamesa" → **Astilleros de juncos**; la escuela *Krom Horasat* → **el Phra Khlang con sus escribanos e intérpretes (*lam*)** | AS (1, 2) | Sarasin Viraphol (1977); Cushman (1993); La Loubère (1691) |
| **Transliteración (RTGS):** *Phom Phet* → **Pom Phet**; *phom* → ***pom***; *kotchasat* → ***khotchasat***; *Krung* → ***Krung Si Ayutthaya*** | AS (3, 17, 19) | RTGS |
| **Recetario de Narai:** con fuente; sale "el elefante del rey cura a los phrai"; el *mo luang* se entrena en el centro; médicos de cuatro tradiciones. Se suma el ***nuat*** | AS (5, S3) | Ed. *Krom Sinlapakon* [verificar]; Salguero (2007); La Loubère (1691) |
| **La crecida como muralla:** con el matiz de 1767 (los birmanos se quedaron durante las lluvias) y una respuesta: la torre enemiga anula el frenado. Pasa a ser el efecto de la maravilla | AS (9, S2) | Baker y Pasuk (2017); Lieberman (2003) |
| **Si Satchanalai** (cerámica, arqueológico fuerte) entra como economía de la II; **arroz de crecida** pasa a la III; **Krom Tha** se funde con el barrio chino | AS (S1, 7) | Brown (2009) |
| ***Khlong lat*** (canales que cortan meandros) entra como mecánica de la IV | AS (S2) | Baker y Pasuk (2017); Molle y Keawkulaya (1998) |
| ***Thahan ma*** (palabra moderna) → **"Jinete de la guardia"**, escaso; *puen* → **"Cañón de muralla"** (metralla); *ngao* = **guja**, no alabarda; comerciante: **la barca del río (*ruea*)**, no el junco | AS (11, 12, 14, 20) | La Loubère; Charney (2004); Cushman (2000) |
| **Élite:** "Defensores de Suan Phlu"; el arcabuz, a verificar | AS (15) | Cushman (2000) |
| **C-79 se cierra en a):** Krung Si Ayutthaya con Pom Phet; sale la opción del Wat Phra Si Sanphet | AS (17, 18) | Baker y Pasuk (2017) |
| El kraal es el *phaniat* (corral de captura); los elefantes viven en los establos reales; "Registros" con el ***Chindamani*** | AS (21, S5) | La Loubère (1691) |

---

## Cómo leer este documento

- **Números tentativos.** Todo número de balance es una propuesta para el torneo, no un dato. Cuando entre al juego va a `data/` (regla 4 del proyecto); mientras tanto vive en `PROPUESTA` y `PROPIAS` del modelo.
- **Nivel de evidencia** de cada saber:
  - **documentado:** lo cuentan fuentes escritas de la época (propias o ajenas) y la historiografía lo acepta;
  - **documentado tardío:** lo cuentan fuentes posteriores a la época del juego, y se supone continuidad;
  - **arqueológico:** lo muestran restos materiales estudiados;
  - **debatido:** hay evidencia, pero la interpretación o la fecha se discute; el juego lo dice así en la ficha;
  - **tradición:** lo transmite la memoria oral o la literatura posterior, sin documento de época.
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

**Las cinco líneas** que suben de nivel: **choque** a pie, **distancia**, **línea**, **montados** (jinetes y elefantes) y **pólvora**. El nivel se compra en el edificio que entrena la línea. Si un pueblo entrena una línea en dos edificios (Etiopía, los montados en el establo; Ayutthaya, los elefantes en el kraal), el nivel está en los dos. En Ayutthaya, "kraal" es el nombre de juego: la ficha dice que el elefante se capturaba en el *phaniat* (เพนียด, el corral de captura) y se criaba en los establos del rey (*rong chang* [verificar]) (AS 21).

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
| Tawantinsuyu | ***Yachaywasi*** ("casa del saber") | Donde los *amawta* enseñaban a los hijos de la nobleza: lengua, khipu, historia y ritos. La ficha dice que la fundación por Inka Roca es **la versión de Garcilaso**, y que lo mejor documentado es la formación de los khipukamayuq | documentado (Garcilaso, 1609, libro IV [verificar el capítulo]); su forma de escuela formal está **debatida**, porque Garcilaso idealiza el Cusco. Urton (2003) para los khipukamayuq | la kallanka |
| Mapuches | ***Trawün*** de los *weupife* | Reunión civil donde los *weupife* (los oradores del parlamento; *weupin*, hablar en parlamento) transmitían el saber de los linajes. No se usa el *ngillatun*, que es ceremonia | documentado (Febrés, 1765 [verificar las entradas]; Bengoa, *Historia de los antiguos mapuches del sur*, 2003) | el parlamento o el lof principal |
| Guaraníes | vía misión: **escritura del cabildo y talleres**; vía monte: ***óga guasu*** (la casa grande comunal) | En las misiones, los cabildos guaraníes escribían cartas, actas y memorias en su lengua (por ejemplo, las cartas de 1753 contra el Tratado de Madrid), y los talleres hacían grabados, instrumentos y herrería. En el monte, el saber se transmitía en la casa comunal. **La imprenta queda solo como mejora de la IV (§3.3)** | escritura: **documentado (fuerte)** (Neumann, *Letra de índios*, 2015; Wilde, 2009); óga guasu: documentado (Montoya, 1639; Susnik) | la tava o el aty guasu |
| Etiopía | **Talleres de Gondar** | Artesanos de la corte de Fasilädäs y sus sucesores: albañiles y herreros beta israel, con la línea honesta sobre su despojo (H-30) y sobre la acusación de *buda* que cargaban; tejedores musulmanes del Islam Bet. Ninguno de los dos grupos podía tener tierra en *rəst* | documentado (Quirin, 1992; Kaplan, 1992; Pankhurst, 1982) | el recinto de Gondar o el centro |
| Palmares | ***Oficinas do Macaco*** | Los oficios del Macaco: **herreros** (las ferrarias), **alfareros** (la cerámica de los mocambos, con formas indígenas, africanas y europeas) y **cesteros y tejedores de palma**. El consejo de jefes alrededor del rey va como texto, con el modelo de los *makota* del Ndongo y la marca **debatido** | documentado y arqueológico (Blaer, 1645; Funari, en Reis y Gomes, 1996; Orser y Funari, *World Archaeology* 33, 2001); los tejedores de palma en Palmares, [verificar el pasaje] | el Macaco |
| Ayutthaya | **El Phra Khlang**: escribanos, contadores e **intérpretes** (*lam*, ล่าม) | El tesoro y los puertos guardaban el saber técnico que más servía al reino: lenguas (chino, persa, malayo, japonés, portugués, holandés, francés), cuentas, cartas náuticas y tratados. La embajada de Kosa Pan (1686) dejó un diario | documentado (La Loubère, 1691; *Van Vliet's Siam*, 2005; *The Diary of Kosa Pan*, 2002 [verificar la edición]) | el palacio (centro) |

**Las seis mejoras de la escuela** (tentativas): dos de combate, que entran en el modelo, y cuatro que no suman poder de combate directo (de asedio, defensa y economía), para no inflar la IV:

1. **+10 % de vida a la infantería de choque.**
2. **+10 % de ataque a la pólvora.**
3. **+15 % de daño del asedio contra edificios.**
4. **El asedio se repara en el campo** (los aldeanos lo reparan como un edificio).
5. **+1 casilla de alcance a torres y fortalezas.**
6. **Registros:** −10 % de costo en las mejoras de la IV. Nombre propio por pueblo:
   - Tawantinsuyu: **khipu**;
   - mapuches: **el *pron*** [verificar la grafía], la cuerda de cómputo, sin archivo escrito;
   - guaraníes: **actas del cabildo** (vía misión) o **la memoria del *óga guasu*** (vía monte);
   - Etiopía: los cronistas reales, ***ṣäḥafe tə'əzaz*** (ጸሐፌ ትእዛዝ, "el que escribe las órdenes"), con crónicas desde ʿAmdä Ṣəyon (AF C1);
   - Palmares: **la memoria de los mocambos**. No hay registros escritos propios y no se inventan archivos (AF C1);
   - Ayutthaya: el ***Chindamani***, el manual de lengua y versificación de la corte de Narai (autoría y fecha, **debatidas**) (AS S5).

Las de combate no tocan nada sagrado. En Etiopía, por eso la escuela son los talleres de la corte y no las escuelas de la iglesia (*qəne bet*), que se consultan aparte (§7). En Ayutthaya, por lo mismo, la escuela no es el cuerpo de los *hon* (los astrólogos de la corte, cuyo oficio central era fijar el momento propicio, *roek*): las reglas del calendario que estudió Cassini pueden aparecer en la ficha del Phra Khlang como saber, nunca como un bono "de buen augurio" (AS 1).

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

**Sobre los sanadores** (AL, resumen 8): separar al "herbolario" del especialista religioso es una distinción nuestra. En los siglos XVI y XVII, el que curaba era muchas veces el mismo que oficiaba. Por eso se usan términos de época u oficios documentados, la ficha habla solo de remedios y técnicas, y cada nombre va a consulta (§7).

| Ranura | Tawantinsuyu | Mapuches | Guaraníes | Etiopía | Palmares | Ayutthaya |
|---|---|---|---|---|---|---|
| **Lancero (I)** | Lancero con escudo (ya está) | Lanza larga, la *waiki* de colihue (ya está) | Lancero | *Chewa* (*č̣äwa*, ጨዋ; baja a la I) | Lanceiro | Lancero |
| **Hostigador montado (II)** | **No hay caballo antes de 1532.** En su lugar, el **boleador** (*liwi* [verificar]; frena) y la velocidad del Qhapaq Ñan | **Malonero**: kona liviano de lanza corta. Ya tenían caballos propios a fines del siglo XVI | **No hay caballo antes de las misiones.** En su lugar, el **hostigador del monte** a pie, con sigilo en el bosque | **Jinete jabalinero**, la caballería ligera de la nobleza | **No hay caballo.** En su lugar, la **gente da correria** a pie, rápida en el mato (*correria* es palabra de los papeles de los dos lados) | **Jinete de la guardia**: Siam tenía pocos caballos y la guardia montada del rey reclutaba jinetes extranjeros [verificar el pasaje]. Más caro y con tope |
| **Asedio de área (III)** | **Hondero de piedra caliente**: hoy es su ariete y pasa a esta ranura. Piedras al rojo envueltas en algodón que encendían los techos de paja (Cusco, 1536; Titu Cusi, 1570; Pedro Pizarro, 1571) | **Incendiarios**: antorchas y fuego en los techos de paja (las ciudades del sur, 1599–1604). Si se confirman las flechas incendiarias, "flecheros de fuego" | **Cañón de tacuara** (hoy es su ariete): tacuara reforzada con cuero, usada en Mbororé (1641) | **Pieza ligera**: cañones llegados con los portugueses en 1541 | **No tiene.** En su lugar, la defensa: la cerca con estrepes y los fojos (§3.5) | **Cañón de muralla**: metralla de un cañón liviano sobre la muralla (*puen lek* [verificar]; *puen* solo es cualquier arma de fuego) |
| **Sanador (III)** | ***Hampikamayuq*** ("el que se ocupa de los remedios"; *hampicamayoc* en González Holguín [verificar]) | ***Ampive*** [verificar] ("médico herbolario"; *ampi*, del quechua *hampi*). Reemplaza a *lawentuchefe*, que es un término de fines del siglo XX | Vía misión: **enfermero del hospital de la misión** (documentado). Vía monte: ***pohãnohára*** [verificar], con consulta | ***Wägešša*** (ወጌሻ, el que acomoda huesos y cura heridas; antigüedad del término, [verificar]); en la corte, el *ḥakim* | ***Erveira / erveiro*** (la persona que sabe de hierbas); **debatido** para Palmares | ***Mo*** (médico); en la corte, *mo luang* |
| **Pieza pesada (IV)** | **No hay cañón.** En su lugar, las **armas capturadas** de Vilcabamba: arcabuces y caballos tomados, y almagristas refugiados con Manco desde 1542. La inundación queda en la maravilla | **No hay cañón.** En su lugar, el **cerco largo y el fuego**: la mejora *Weichan* rompe fortalezas con el tiempo (hito de hoy) | **Tacuara reforzada con el hierro de la misión** (el de San Juan Bautista). El cañón de bronce, solo si aparece la fuente | **Cañón de la corte** (portugués u otomano), escaso | **No hay cañón.** En su lugar, la **antorcha de la correría**: bono **solo contra cañaverales e ingenios**, para no reabrir el problema de la liberación (AF P14) [verificar el pasaje de la quema, AL 2.1] | ***Puen yai*** (ปืนใหญ่, cañón) de bronce |

---

# 3. Los saberes de cada pueblo

Cada pueblo tiene **8 mejoras propias** (2 en la II, 3 en la III y 3 en la IV), con al menos una de economía, una militar y una de su mecánica, y **3 unidades propias** (II, III y IV). En cada fila:
- **qué hace:** los números son tentativos;
- **saber:** la técnica o la institución histórica que la sostiene;
- **evidencia:** el nivel y la fuente.

Las mejoras se compran en el edificio de su eje: las de economía en el centro o el almacén; las militares en el cuartel; las de la mecánica en el edificio propio (qollqa, corral, misión, gult, mocambo, kraal).

## 3.1 Tawantinsuyu

**Mecánicas:** mit'a, Qhapaq Ñan, qollqa, andenes y cumbi. **Los saberes:** medicina quirúrgica, administración con cuerdas, conservación de alimentos, ingeniería de caminos y puentes, metalurgia del bronce y de la plata. Es el pueblo con más evidencia material de todo el juego.

### Mejoras

| Edad | Nombre | Eje | Qué hace | Saber | Evidencia y fuente |
|---|---|---|---|---|---|
| II | ***Ch'uñu* y *ch'arki*** | economía | Cada qollqa guarda +50 de mit'a de tope y los andenes rinden +10 % | Papa liofilizada por helada y sol, y carne secada. Se guardaban años en qollqas con ventilación y drenaje, en hileras de cientos sobre las laderas | **Documentado y arqueológico.** Murra, *Formaciones económicas y políticas del mundo andino* (1975); Morris y Thompson, *Huánuco Pampa* (1985); LeVine (ed.), *Inka Storage Systems* (1992); Cobo, *Historia del Nuevo Mundo* (1653) |
| II | ***Khipukamayuq*** | mecánica | La mit'a por runa de las edades III y IV vuelve de 3 a 4. El taller de tejido consume 10 % menos | Registro en cuerdas anudadas con sistema decimal posicional: censos, tributo y depósitos. **La mit'a era tributo en trabajo:** lo dice la ficha | **Arqueológico y documentado** para lo numérico (Locke, *The Ancient Quipu*, 1923; Ascher y Ascher, *Code of the Quipu*, 1981). **Debatido** si registraban relatos (Urton, *Signs of the Inka Khipu*, 2003; Salomon, *The Cord Keepers*, 2004) |
| III | **Cirugía de cráneo** (trepanación) | militar | El 20 % de los guerreros y lanceros que caen **por golpe** (porra, honda, piedra) a 6 casillas de un hampikamayuq o de la kallanka **no muere**: queda herido y vuelve a la kallanka, donde se repone en 60 s con la mitad de la vida. Además, el hampikamayuq cura +25 % | La cirugía craneal andina, **un saber de más de dos mil años** (desde Paracas, hacia el 400 a. C.) **que el Inka heredó** y que llegó a su punto más alto en su época, sobre todo en la región del Cusco. Más de 800 cráneos trepanados estudiados en el Perú, muchos con fracturas por golpe operadas. En la época inca **sobrevivía entre el 75 y el 83 %** (el hueso cicatrizado lo muestra); en la Guerra Civil de Estados Unidos, ya con anestesia, **moría entre el 46 y el 56 %** [verificar las cifras en el artículo]. Instrumentos: cuchillos de obsidiana y de bronce (el *tumi*); raspado y corte | **Arqueológico (fuerte).** Verano, *Holes in the Head: The Art and Archaeology of Trepanation in Ancient Peru* (Dumbarton Oaks, 2016); Kushner, Verano y Titelbaum, *World Neurosurgery* 114 (2018). **En el juego no se muestran cráneos ni restos humanos, tampoco el hueso cicatrizado en dibujo:** la ficha ilustra solo los instrumentos, hasta la consulta con bioarqueólogos (§7) |
| III | ***Q'eswa chaka*** (puente de soga) | mecánica | El Qhapaq Ñan se puede tender sobre ríos de hasta 2 casillas (6 de mit'a por tramo). Los caminos dan +5 % más de velocidad | Puentes colgantes de fibra de *q'oya ichu* trenzada que las comunidades renovaban por turnos de mit'a, a cargo de los *chaka kamayuq* (*chaca camayoc* en Guaman Poma [verificar]). Garcilaso describe el del Apurímac. **El de Q'eswachaka se sigue renovando cada año**: el juego usa el nombre genérico, no el del puente vivo | **Documentado.** Garcilaso, *Comentarios reales* (1609), libro III [verificar el capítulo]; Hyslop, *The Inka Road System* (1984); Guaman Poma (c. 1615). Patrimonio inmaterial de la UNESCO (2013). **Tradición viva:** consultar a las comunidades de Quehue antes de usar el nombre (§7) |
| III | ***Champi***, la porra de bronce [verificar] | militar | +1 de ataque al choque (porras de estrella de bronce) | Aleación de cobre y estaño estandarizada en todo el imperio, para herramientas y armas. En las fuentes coloniales, *champi* parece nombrar **la porra o el hacha de metal**, no el metal (el cobre es *anta*) | **Arqueológico** (la aleación). Lechtman, "Andean Value Systems and the Development of Prehistoric Metallurgy", *Technology and Culture* 25 (1984). El nombre, en González Holguín (1608) y Garcilaso [verificar] |
| IV | ***Wayrachina*** (*huayrachina*, horno de viento) | economía | Las minas y los sitios de riqueza de la IV rinden +20 % | Horno de barro con aberturas que funde la plata con el viento de la puna. Hasta la amalgama con mercurio (1572), **toda** la plata de Potosí la fundían indígenas con esta técnica, y los españoles dependían de ellos. **La mita minera de Potosí fue trabajo forzado:** lo dice la ficha | **Documentado y arqueológico (fuerte).** Bakewell, *Miners of the Red Mountain* (1984); Van Buren y Mills, "Huayrachinas and Tocochimbos", *Latin American Antiquity* 16 (2005) |
| IV | ***Warak'a* trenzada** | militar | +0,5 casillas de alcance a honderos y boleadores | Hondas de fibra de camélido con trenzas complejas, el arma con la que se sitió el Cusco en 1536 | **Documentado** (Titu Cusi Yupanqui, *Instrucción*, 1570; Hemming, *The Conquest of the Incas*, 1970) y **arqueológico** (hondas en contextos andinos) |
| IV | ***Chaski* en relevo** | mecánica | Todo tramo de camino conectado a la llaqta da visión de 4 casillas; el chaski anda +20 % en los caminos | Corredores en postas (*chaskiwasi*) cada pocos kilómetros que llevaban mensajes y khipus | **Documentado.** Cieza de León, *El señorío de los Incas* (escrito hacia 1550, publicado en 1880) [verificar el capítulo]; Guaman Poma (c. 1615), con el dibujo del chaski; Hyslop (1984) |

### Unidades propias

| Edad | Unidad | Qué hace | Saber | Evidencia |
|---|---|---|---|---|
| II | **Boleador** (*liwi* [verificar]; ya existe) | Frena 3 s; poco daño | Boleadoras de piedra y cuero; las crónicas cuentan que se usaron contra los caballos en el cerco del Cusco [verificar el pasaje] | Documentado. González Holguín (1608), entrada *liui* [verificar]; Guaman Poma (c. 1615) |
| III | **Galgueros** (cuadrilla de galgas) | Asedio de defensa: desde una loma, sueltan piedras que ruedan ladera abajo, 60 de daño a todo lo que esté en la línea. Solo pegan cuesta abajo (usa la altura del mapa, D-027) | Galgas preparadas en las laderas del **camino a Vilcabamba** contra las entradas españolas: la de Gonzalo Pizarro en 1539 (Chuquillusca [verificar el sitio]) y la de 1572 | **Documentado.** Hemming (1970); Bauer, Fonseca y Aráoz (2015) |
| IV | **Jinete de Manco** (élite) | Montado con lanza y, a veces, arcabuz capturado. Solo se entrena en Vilcabamba y con caballos capturados (ya existe la captura en el hito). Tope de 8 | Las tropas de Manco Inka aprendieron a montar y a usar armas capturadas en la resistencia (1537–1572); Hemming cuenta a Manco a caballo y con lanza en Ollantaytambo | **Documentado.** Titu Cusi Yupanqui (1570); Hemming (1970); Bauer, Fonseca y Aráoz, *Vilcabamba and the Archaeology of Inca Resistance* (2015) |

**Maravilla: Ollantaytambo,** la **llaqta y finca real de Pachakutiq** (con el templo inconcluso de los grandes monolitos) **que Manco convirtió en fortaleza** en 1536–1537, antes de dejarla por Vitcos. Mientras está en pie, la llanura junto al río a 12 casillas se puede **inundar** una vez cada 5 minutos: el enemigo anda a la mitad durante 45 s. Es lo que hizo Manco en 1537 contra Hernando Pizarro: desvió el río por los canales y anegó el llano bajo los caballos. **Documentado** (Pedro Pizarro, *Relación*, 1571; Hemming, 1970; Protzen, *Inca Architecture and Construction at Ollantaytambo*, 1993). Encaja con la edad IV de Vilcabamba y con la H-14 (que la IV se parezca a la resistencia, no a un imperio de oro). **Es un pueblo vivo:** consultar a la municipalidad y a las comunidades de Ollantaytambo (§7).

## 3.2 Mapuches

**Mecánicas:** lof disperso, malón y arreo, sigilo, relevo y caballo. **Los saberes:** la adopción rápida y propia de lo que llegó de afuera (caballo, trigo, manzana, ganado, lana), la táctica que frenó al imperio español durante tres siglos, el tejido, la herbolaria y la diplomacia de los parlamentos. **Cuidado:** la machi, el rewe, el kultrun y el *foye* (canelo) son sagrados y no se usan (H-22, H-27).

### Mejoras

| Edad | Nombre | Eje | Qué hace | Saber | Evidencia y fuente |
|---|---|---|---|---|---|
| II | **Coseletes de cuero** | militar | +1 de armadura cuerpo a cuerpo al weichafe y al choque | Corazas y cascos de cuero crudo (de lobo marino y, después, vacuno) | **Documentado.** Góngora Marmolejo, *Historia de Chile* (1575); González de Nájera, *Desengaño y reparo de la guerra del Reino de Chile* (1614) [verificar el pasaje]. Ercilla, *La Araucana* (1569), detrás, porque es poesía épica |
| II | **Trigo y manzana** | economía | Las granjas del lof rinden +15 % | Adopción propia y muy rápida del trigo, la manzana y el ganado. "No fue aculturación, fue elección" **es la lectura de Bengoa, Boccara y Pinto**: la ficha la atribuye. Los manzanares del sur aparecen en Rosales | **Documentado.** Bengoa, *Historia de los antiguos mapuches del sur* (2003); Pinto Rodríguez, *La formación del Estado y la nación, y el pueblo mapuche* (2000 o 2003) [verificar]; Rosales (c. 1674) |
| III | **Hoyos y estacas** | mecánica | El weichafe cava hoyos ocultos (20 de madera): 40 de daño y frenado de 4 s a quien cae, el doble a los montados. Se ven a 2 casillas | Hoyos encubiertos con estacas contra la caballería, en el fuerte de Lautaro en Peteroa y en Mataquito (1556–1557) | **Documentado.** Góngora Marmolejo (1575); Vivar, *Crónica* (1558) [verificar los pasajes] |
| III | ***Lawen*** (remedios) | militar (sanador) | El ampive cura +25 % y las tropas en el monte sanan 1 de vida por segundo fuera de combate | Herbolaria mapuche: el matico (*Buddleja globosa*; *pañil* o *palngiñ* [verificar la grafía]) para heridas y otras plantas cicatrizantes | **Documentado tardío:** Mösbach, *Botánica indígena de Chile* (1992), recoge saber del siglo XX. Para la época, Ovalle (1646) y Rosales (c. 1674) sobre las curas de heridas [verificar]. **Consultar** antes de usarlo: el límite entre remedio y ceremonia lo pone la comunidad (§7) |
| III | **Arreo en tropilla** | mecánica | El arreo pasa de 3 a 4 cabezas por minuto y el corral guarda 25 % más | Manejo ganadero y la ruta de arreo a través de la cordillera (las rastrilladas), **la ruta que se haría grande** a fines del siglo XVII y en el XVIII | **Documentado.** León Solís, *Maloqueros y conchavadores en Araucanía y las Pampas, 1700–1800* (1990/1991) [verificar el año] |
| IV | ***Makuñ*** (el poncho) | economía | Cada telar del lof da 4 de riqueza por minuto; los ponchos vendidos en el mercado y los agasajos del parlamento rinden +20 % | El poncho de lana fue **la gran mercancía mapuche de la frontera**: miles por año hacia Chile y las pampas en el siglo XVIII. Tiene raíz en el chilihueque y en la tejedora narradora. **Lo tejían las mujeres**: lo dice la ficha | **Documentado.** León Solís (1990/1991); Villalobos (1995); Bengoa (2003) |
| IV | ***Kawellu*** (remonta propia) | militar | +10 % de vida a los montados y −10 % de costo al kona montado | Cría propia de caballos desde fines del siglo XVI: el caballo dejó de ser botín para ser economía | **Documentado.** Boccara, *Los vencedores* (2007); Villalobos, *Vida fronteriza en la Araucanía* (1995), cuya tesis de la "vida fronteriza" minimiza la guerra y está discutida |
| IV | ***Werken*** y ***pron*** | mecánica | Cada lof suma +5 % al relevo y comparte visión de 8 casillas con los demás. Los lof que reciben el *pron* llegan a la junta del malón con +15 % de velocidad | Mensajeros entre lof y alianzas por linaje: mando sin centro. El *pron* era la cuerda de nudos para contar los días hasta una junta o un malón: es lo que anuda la narradora de Purén | **Documentado.** Boccara (2007); el *pron*: Rosales (c. 1674) y Febrés (1765) [verificar el pasaje y la grafía: *pron* o *prom*] |

### Unidades propias

| Edad | Unidad | Qué hace | Saber | Evidencia |
|---|---|---|---|---|
| II | **Infantería montada** | Weichafe a caballo que se desmonta para pelear: anda como jinete y pelea como lanza; 2 s para desmontar | Infantería que se movía a caballo y peleaba a pie, una adaptación propia de fines del siglo XVI y del XVII | **Documentado.** González de Nájera (1614); Boccara (2007) |
| III | **Incendiarios** (ocupa la ranura del asedio de área) | Su asedio (hoy los mapuches no tienen ninguno): antorchas y fuego, +200 % contra edificios de madera y paja, poco contra la piedra | La quema de las ciudades y fuertes del sur en el gran alzamiento (1598–1604) | **Documentado** (la quema). Rosales (c. 1674); González de Nájera (1614). **A verificar** que se hiciera con flechas incendiarias: si aparece el pasaje, pasan a llamarse "flecheros de fuego" |
| IV | **Kona de *waiki*** (élite) | Lancero montado pesado: +8 contra los montados, carga que derriba | Lanza larga de colihue (*waiki*, *huaiqui* en las crónicas) a caballo; la caballería mapuche de los siglos XVII y XVIII. *Kona* es el mocetón, el guerrero joven | **Documentado.** Ovalle (1646); Rosales (c. 1674) [verificar el largo de la lanza] |

**Maravilla: el gran *koyagtun*** (parlamento; Febrés registra *coyagh* [verificar]): un campo de parlamento con ramadas y **la gente de los ayllarewe**. Mientras está en pie y sin enemigos dentro, los rivales no pueden capturar sitios a 15 casillas. La cuenta para ganar corre igual que en las otras maravillas. Es lo que lograron Quilín (1641) y los parlamentos siguientes: frontera reconocida por tratado. Los cuatro *butalmapu* son de los parlamentos del siglo XVIII, y por eso la edad IV se llama *Butalmapu*. **Documentado** (Zavala, *Los mapuches del siglo XVIII*, 2008; Zavala, ed., *Los parlamentos hispano-mapuches*, 2015 [verificar el título]). El parlamento era bilateral y tenía rito (sacrificio de chilihueque, ramas de canelo): el juego no muestra el rito y **la consulta es imprescindible** (§7).

## 3.3 Guaraníes

**Mecánicas:** roza y yerba (con C-67), *potirõ* (obra colectiva), sigilo en el monte y bifurcación entre misión y monte. **Los saberes:** el manejo del monte (no es selva virgen sino monte manejado), el policultivo, la navegación de ríos, la farmacopea, la arquitectura de tacuara y, en las misiones, la escritura de los cabildos, la imprenta, el hierro y los talleres. **Cuidado:** opy, karai, mbaraka y takuapu son sagrados (H-23).

### Mejoras

| Edad | Nombre | Eje | Qué hace | Saber | Evidencia y fuente |
|---|---|---|---|---|---|
| II | ***Kokue*** (chacra de roza en policultivo) | economía | Las rozas rinden +15 % y tardan 25 % más en agotarse | Mandioca (*mandi'o*), maíz (*avati*), porotos (*kumanda*) y decenas de variedades juntas en la misma roza | **Documentado y arqueológico.** Montoya, *Tesoro de la lengua guaraní* (1639); Noelli, *Sem tekohá não há tekó* (disertación, PUCRS, 1993) [verificar el título completo] |
| II | ***Ygá*** (canoas) [verificar] | mecánica | Las tropas cruzan vados y ríos de 1 casilla sin frenar; el aldeano que junta junto al río carga +2 | Navegación del Paraná y el Uruguay; flota de canoas en Mbororé (1641). *Ygara* es la forma del tupí antiguo; en el guaraní de Montoya, *ygá* [verificar] | **Documentado.** Cartas anuas de la Compañía de Jesús; Furlong, *Misiones y sus pueblos de guaraníes* (1962) |
| III | ***Pohã ñana*** (remedios del monte) | militar (sanador) | El sanador (enfermero o pohãnohára) cura +25 % y las tropas en el monte sanan 1 de vida por segundo | Farmacopea guaraní que recogieron las misiones: plantas, usos y nombres. *Pohã ñana* es la expresión paraguaya actual para los yuyos medicinales | **Documentado.** Montenegro, *Materia médica misionera* (1710; manuscrito, publicado en 1945); Montoya (1639). Cuánto es guaraní y cuánto jesuita: **debatido**, y lo dice la ficha |
| III | ***Óga* de *takuára*** | economía | Casas y almacenes: −30 % de tiempo de obra y −20 % de madera; el potirõ suma +2 % más por constructor | La gran casa comunal (*óga guasu*), que levantaba todo el grupo: postes de madera, techo de paja o de pindó y tacuara en las paredes y los entramados | **Documentado.** Montoya (1639); Susnik, *Los aborígenes del Paraguay* (1979–80); Noelli (1993) |
| III | **Defensa de Mbororé** | militar | El cañón de tacuara pega +25 % y alcanza 1 casilla más; los arqueros junto a un río tienen +1 de armadura | La batalla de Mbororé (1641): canoas, arcabuces (llegados con un permiso real de esos años [verificar la fecha]) y cañones de tacuara contra los bandeirantes | **Documentado.** Cartas anuas; Furlong (1962); Avellaneda y Quarleri (2007) |
| IV | **Vía misión, *ka'a* plantada; vía monte, *ka'a ka'aguy*** | economía | Misión: el yerbal plantado (C-67 a). Monte: los yerbales silvestres rinden +25 % | En las reducciones, a comienzos del siglo XVIII, se logró que germinara la semilla de la yerba y se plantaron yerbales. En el monte, la cosecha silvestre. **La yerba fue también tributo y trabajo forzado:** lo dice la ficha | **Documentado** (Garavaglia, *Mercado interno y economía colonial*, 1983). Quién encontró la técnica de germinación: **debatido** |
| IV | ***U'y hatã*** (flecha dura) [verificar con hablantes] | militar | +1 de ataque a la distancia | Arcos de madera dura (*guyrapa*, el arco) y puntas endurecidas o de hueso; arqueros temidos desde las primeras crónicas | **Documentado.** Schmidl (1567); Montoya (1639) [verificar los pasajes] |
| IV | **Vía misión, imprenta; vía monte, *aty*** | mecánica | Misión: las mejoras cuestan −15 %. Monte: el sigilo y la emboscada, +25 % | La imprenta de las misiones, la primera del Río de la Plata: un *Martirologio romano* (1700) y *De la diferencia entre lo temporal y lo eterno* de Nieremberg en la versión guaraní de José Serrano (1705), con grabados de artesanos guaraníes como Juan Yaparí. En el monte, la asamblea como gobierno | **Documentado** (Furlong, *Historia y bibliografía de las primeras imprentas rioplatenses*, 1953; Neumann, 2015). Que los tipos los fundieran guaraníes lo sostiene Furlong: **a verificar el detalle** |

### Unidades propias

| Edad | Unidad | Qué hace | Saber | Evidencia |
|---|---|---|---|---|
| II | ***Ygá*** (canoa) | Transporte por el río: 6 plazas, rápida, sin ataque (D-020: sin combate naval) | La canoa monóxila del Paraná | **Documentado** |
| III | **Cañón de tacuara** (ya existe; pasa a la ranura del asedio de área) | Daño en área contra la tropa; poco contra la piedra | Mbororé (1641) | **Documentado** |
| IV | Misión: **caballería y milicias de las misiones**; monte: ***ka'aguygua*** (élite) [verificar la grafía] | Misión: jinete de lanza o milicia de a pie a elección (las misiones tenían estancias, compañías de caballería y milicias). Monte: choque con +2 de armadura en el monte | **Misión:** la Guerra Guaranítica (1754–1756), que pelearon los siete pueblos de misión, y Sepé Tiaraju, corregidor o alférez de San Miguel. La frase "esta tierra tiene dueño" (*co yvy oguereco yara*) se le atribuye: es **tradición**, de la literatura riograndense de los siglos XIX y XX; la forma en guaraní es una retraducción. **Monte:** los *ka'aguygua* ("los del monte", los *monteses* o *caaiguás* de las fuentes), que resistieron la reducción hasta el siglo XVIII | **Documentado.** Misión: Ganson, *The Guaraní under Spanish Rule* (2003); Avellaneda y Quarleri (2007); la frase, Golin (1998) [verificar si aparece en algún diario de 1756]. Monte: Susnik (1979–82); Meliá (1986) |

**Maravilla:**
- **Vía misión: la plaza y el cabildo de la tava.** No la fachada de la iglesia: el cabildo guaraní, con su escritura, los talleres y la plaza (H-37). Mientras está en pie, la obra colectiva no tiene tope. (Neumann, 2015; Wilde, 2009.)
- **Vía monte: la "Aldea grande del monte",** una gran aldea de óga guasu en el monte cerrado. Mientras está en pie, todo el bosque propio da sigilo. No se usa *tekoha guasu*: es una categoría de los avá guaraní y los kaiowá en los litigios por tierras de los siglos XX y XXI, y una palabra de lucha presente. Si se confirma *guára* (C-70), puede llevar ese nombre.

Las dos, con consulta a mbyá, paĩ-tavyterã, avá guaraní y kaiowá (§7).

## 3.4 Etiopía

**Mecánicas:** la corte que se muda, el gult (renta pagada por los *gäbbar*), caballería desde la I y defensa en altura. **Los saberes:** la escritura en ge'ez (actas y crónicas), el orden del campamento real, el arado de bueyes y el *ṭef*, la farmacopea, las ambas y las caravanas de sal. **Cuidado:** Lalibela, el tabot, la iglesia y el kebero (H-20, H-21, H-24). Nada de lo eclesiástico da combate ni entra en una mecánica.

### Mejoras

| Edad | Nombre | Eje | Qué hace | Saber | Evidencia y fuente |
|---|---|---|---|---|---|
| II | ***Maresha* y *ṭef*** | economía | Granjas +15 %; en altura no pierden rendimiento. El alimento guardado en el *gotära* no se pierde cuando la corte se muda | El arado de bueyes de tracción doble (*maräša*, ማረሻ, es la reja; vale por el arado): **el par de bueyes era la unidad de la riqueza campesina**. El ***ṭef*** (ጤፍ), un cereal domesticado en Etiopía, de grano diminuto que no se agusana y se guarda años en el granero de mimbre y barro (***gotära***, ጎተራ) | **Documentado y arqueológico.** Álvares, *Verdadeira informação das terras do Preste João* (1540) [verificar el pasaje del arado]; Crummey, *Land and Society in the Christian Kingdom of Ethiopia* (2000); McCann, *People of the Plow* (1995, que cubre 1800–1990). El *ṭef*: D'Andrea, *Economic Botany* 62 (2008) [verificar el título]; la fecha de los primeros restos, **debatida**. Las raíces aksumitas del arado, [verificar] |
| II | **Actas de tierra en ge'ez** | mecánica | El gult rinde +15 % y no deja de cobrar mientras la corte se muda | Las cesiones de tierra y de gult se copiaban en ge'ez en los folios en blanco de los evangeliarios; muchas eran cesiones a iglesias y monasterios. El ícono es una hoja suelta con sello, **no un evangeliario abierto** | **Documentado.** Crummey (2000); Huntingford, *The Land Charters of Northern Ethiopia* (1965). La renta la pagan los gäbbar (H-05) |
| III | ***Fäws*** (ፈውስ, remedio) y ***kosso*** | militar (sanador) | El wägešša cura +25 % y las tropas junto a la corte sanan 1 de vida por segundo | **Solo la farmacopea:** plantas como el *kosso* (ኮሶ, *Hagenia abyssinica*, la flor contra la tenia), minerales, cauterio y curación de heridas y fracturas. Los tratados los copiaban *däbtära* que mezclaban recetas con oraciones y rollos protectores (*asmat*): **el juego no usa esa parte** | **Documentado** para los siglos XVIII y XIX; **debatido** para 1500–1700. Strelcyn, *Médecine et plantes d'Éthiopie* (1968; vol. II, 1973); Pankhurst, *An Introduction to the Medical History of Ethiopia* (1990). Desde cuándo describen los europeos el *kosso*, [verificar] (¿Ludolf, 1681?) |
| III | **Cota de malla** | militar | +1 de armadura cuerpo a cuerpo al choque (jinete noble) | Jinetes con cota de malla, **importada (de Egipto y del mundo otomano) y de pocos**, descritos por el cronista de Adal y por Álvares | **Documentado.** *Futūḥ al-Ḥabaša* (trad. Stenhouse, notas de Pankhurst, 2003); Álvares (1540) [verificar los pasajes] |
| III | **Amba** | mecánica | La defensa en altura sube de +25 % a +35 %; la amba guarda 400 de riqueza que no se puede saquear | Mesetas de paredes a pique como fortaleza, prisión y tesoro: **Amba Gəšän** (prisión de los príncipes y tesoro real hasta que la tomó el imán Aḥmad, c. 1540) y **Wähni** (ወህኒ), la amba-prisión de la época de Gondar [verificar desde qué reinado]. Debre Damo, monasterio vivo, no se usa en la mecánica | **Documentado.** Taddesse Tamrat, *Church and State in Ethiopia, 1270–1527* (1972); Álvares (1540); *Futūḥ* (la toma); Bruce, *Travels* (1790) |
| IV | **Caravanas de *amole*** | economía | El comerciante etíope (§4.3) rinde +20 % y la corte que se muda junto a una ruta paga −20 % | Barras de sal como moneda (ya en la década de 1520), **cortadas por trabajadores afar en la llanura de sal y llevadas por mercaderes musulmanes, los *jabarti***, en caravanas de mulas y camellos | **Documentado.** Pankhurst, *An Introduction to the Economic History of Ethiopia from Early Times to 1800* (1961); Álvares (1540) |
| IV | **Pólvora de Massawa** | militar | +10 % de ataque a la pólvora, **solo mientras haya una ruta comercial abierta** (con el comerciante vivo y el mercado en pie) | Casi todas las armas de fuego se importaban por Massawa (otomana desde 1557), y los mosqueteros de la corte eran en parte descendientes de los portugueses de 1541. En la corte se reparaban; no hay evidencia de una fabricación local de importancia | **Documentado** (la importación). Pankhurst, artículos sobre las armas de fuego en Etiopía antes del siglo XIX (*Ethiopia Observer*, *Journal of Ethiopian Studies*, décadas de 1960 y 1970) [verificar títulos y números] |
| IV | **Orden del *kätäma*** (ከተማ) | mecánica | La corte se despliega en la mitad del tiempo | El campamento real se armaba siempre con el mismo plano: la tienda del rey al centro y cada dignatario y cada regimiento en un lugar fijo. Por eso se levantaba y se armaba rápido. Las mudanzas dependían de la estación (el campamento de lluvias, *kərämt*), de que se agotaran la leña y la comida del lugar, y de las campañas | **Documentado.** Álvares (1540, lo vio en los años 1520); las crónicas reales; Horvath, "The Wandering Capitals of Ethiopia", *Journal of African History* 10 (1969); Pankhurst, *History of Ethiopian Towns* (1982) |

### Unidades propias

| Edad | Unidad | Qué hace | Saber | Evidencia |
|---|---|---|---|---|
| II | **Guerrero de *gaša*** (escudo y jabalinas) | Choque a pie que arroja una jabalina antes de cerrar; +1 de armadura a distancia por el escudo | La infantería que describen el *Futūḥ* y Álvares: lanza, jabalina, escudo (*gaša*, ጋሻ) y espada. La espada curva, el ***šotäl*** (ሾተል), queda en la ficha como **debatido**: sus imágenes son de los siglos XVIII y XIX, y lo de que "pasa por encima del escudo" es una explicación de catálogos modernos, sin fuente de época | **Documentado** (la infantería). *Futūḥ* (Stenhouse, 2003); Álvares (1540). La iconografía del *šotäl*, [verificar] (Institute of Ethiopian Studies) |
| III | ***Färäsäñña*** (ፈረሰኛ, jinete) **con cota de malla** | Montado pesado: 220 de vida, armadura 3 | Ver la cota de malla, arriba | **Documentado** |
| IV | **Jinetes oromo aliados** (élite) | Montados rápidos que llegan en grupo de 5 por un **tratado de alianza**: cuesta riqueza al firmarlo y se rompe si el jugador ataca un sitio aliado o deja de pagar el agasajo; no se entrenan | La historia es de alianzas, de **adopción** (*moggaasa*) en las dos direcciones y, en Gondar, de matrimonios: Susenyos se crió entre los oromo (H-29) y la madre de Iyoas era oromo, de Wällo; en Gondar, la guardia de Iyoas (1755–1769). El ***gadaa***, el sistema de grados de edad que rotaba el mando cada ocho años, se nombra como la institución que les dio su fuerza, **no como mecánica de combate** | **Documentado.** Mohammed Hassen, *The Oromo and the Christian Kingdom of Ethiopia, 1300–1700* (2015); Bahrey, *Zenahu lä Galla* (1593), trad. en Beckingham y Huntingford, *Some Records of Ethiopia, 1593–1646* (1954), citado por su título y sin repetir en el juego el etnónimo despectivo; Bruce (1790). **Consultar a académicos y comunidades oromo** (§7); si no, "Caballería de la corte" |

**Maravilla: Fasil Gəbbi** (ፋሲል ግቢ; "Fasil Ghebbi" en la UNESCO), el recinto de Gondar, en piedra parda y gris, no blanca (H-49). El modelo muestra los castillos de Fasilädäs y de Iyasu I y la muralla, **sin las iglesias del recinto**. Mientras está en pie, la corte deja de mudarse y los gult de todo el mapa rinden +25 %. Es el paso de la corte en marcha a la capital fija, que salió de los campamentos de lluvias. **Documentado** (Pankhurst, *History of Ethiopian Towns*, 1982; Horvath, 1969; UNESCO, 1979).

## 3.5 Palmares

**Mecánicas:** fama, acogida y liberación (con C-68), oficios, sigilo y cercas con estrepes. **Los saberes:** el policultivo en la sierra, el uso de la palmera, la forja, la cerámica y el tejido, el arte de la guerra de tradición centroafricana, la defensa del territorio y la organización política propia. **Cuidado:** ningún texto dice "esconderse" como esencia (H-35); nada de capoeira, que es del siglo XIX (H-28); lo religioso (calundu, *nganga*, *kimbanda*) no se usa, ni el rito de la fundición centroafricana.

### Mejoras

| Edad | Nombre | Eje | Qué hace | Saber | Evidencia y fuente |
|---|---|---|---|---|---|
| II | ***Roças e palmeiras*** | economía | Granjas +15 %; los árboles de palma junto a un mocambo dan 6 de riqueza por minuto (fibra, techo, fruto y vino de palma) | Grandes roças de maíz, porotos, mandioca, batata y caña al pie de la sierra, y el uso de las **palmeras nativas** (pindoba, catolé: *Attalea*, *Syagrus*), que le dieron el nombre. **No es el dendê**, la palma de aceite africana. Quienes venían del Kongo y del Ndongo ya conocían el trabajo de la palmera, y el maíz y la mandioca ya se cultivaban en Angola hacia 1600: el saber se juntó con el de los indígenas | **Documentado.** Blaer, diario (1645; publicado en 1902); *Relação das guerras feitas aos Palmares* (1678) [verificar el pasaje sobre la palmera y el vino]; Carneiro, *O Quilombo dos Palmares* (1947). La continuidad con el saber centroafricano de la palmera: **debatida** |
| II | **Aviso de los mocambos** | mecánica | Los mocambos comparten visión y avisan cuando entra tropa enemiga a 10 casillas | Red de mocambos con vigías, sendas, aguadas y refugios escalonados en la sierra | **Documentado.** Blaer (1645); Gomes, *Palmares* (2005); Lara (2021) |
| III | **Forja de los mocambos** | mecánica | Los oficios de la ferraria rinden +25 % y los estrepes de hierro pegan +50 % | Herreros que trabajaban el hierro conseguido por trueque o en las correrías, con **fuelles de cuenco con membrana de cuero**, a la manera centroafricana. **Forja, no fundición de mineral**. El rito y la realeza del herrero en el Ndongo y el Kongo no se usan | La técnica centroafricana: **arqueológico** (Childs y Killick, "Indigenous African Metallurgy", *Annual Review of Anthropology* 22, 1993). Las forjas en Palmares: **documentado** (*Relação*, 1678 [verificar el pasaje]); sin evidencia arqueológica de forja en la Barriga, por ahora. La herencia directa: **debatido** |
| III | ***Sanguar*** | militar | La gente de guerra y los zagaieiros reciben −15 % de daño de la distancia mientras se mueven | La infantería centroafricana peleaba en orden abierto y se entrenaba para **esquivar** flechas y tiros (*sanguar*). Con el arco, era la base de la guerra de Angola. **No es capoeira ni su antecedente** (H-28): lo dice la ficha | **Documentado** en Angola: Cavazzi, *Istorica descrizione de' tre regni Congo, Matamba et Angola* (1687); Cadornega, *História geral das guerras angolanas* (1680); Thornton, "The Art of War in Angola, 1575–1680" (1988) y *Warfare in Atlantic Africa* (1999). En Palmares: **debatido**. Consultar (§7) |
| III | ***Kilombo*** | mecánica | De cada 4 personas que llegan por la fama, una entra como gente de guerra si hay un mocambo de guerra | El *kilombo* angoleño: institución de guerra que integraba gente de cualquier origen por la iniciación (el juego no detalla el rito). La palabra *quilombo* para Palmares aparece en los papeles coloniales recién desde los años 1680: es palabra de los otros | **Debatido.** Miller, *Kings and Kinsmen* (1976); Munanga, "Origem e histórico do quilombo na África", *Revista USP* 28 (1995–1996); Thornton, "Les États de l'Angola et la formation de Palmares", *Annales HSS* 63 (2008). Cuánto pasó a Palmares se discute, y la ficha lo dice |
| IV | **Trato con los moradores** | economía | El mercado no cobra comisión y el comerciante (§4.3) rinde +15 % | Comercio a escondidas con los vecinos: productos de la sierra por herramientas, pólvora y sal. Palmares no estaba aislado | **Documentado.** Gomes (2005); Lara, *Palmares & Cucaú* (2021); Carneiro (1947) |
| IV | **Hierro de Angola Janga** | militar | +1 de ataque al choque | Hojas y puntas de hierro de las forjas propias: lanzas, facones, flechas. No hay indicio de defensas de hierro en el cuerpo. "Angola Janga" está en las fuentes; su glosa ("Angola pequeña") [verificar con lingüistas de kimbundu] | **Documentado** (las forjas) / **debatido** (el volumen). Lara (2021); Gomes (2005) |
| IV | ***Fojos* e estrepes** | mecánica | Las cercas pegan +50 % de espinas; la gente de guerra cava fojos ocultos (pozos con estacas) | Fosos camuflados y estrepes en los accesos de la cerca real, descritos en las campañas de 1692–1694 | **Documentado.** Ennes, *As guerras nos Palmares* (1938), con las cartas de Domingos Jorge Velho; Lara (2021). El título "O território dos Palmares" que se citaba [verificar si es de Lara o un capítulo de Gomes, org., *Mocambos de Palmares*, 2010] |

### Unidades propias

| Edad | Unidad | Qué hace | Saber | Evidencia |
|---|---|---|---|---|
| II | ***Zagaieiro*** | Arroja la lanza (alcance 3000) y después pelea con ella | *Zagaia* es como llamaban los portugueses a **toda** lanza arrojadiza africana (la palabra viene del beréber y el árabe): la ficha lo dice. Las lanzas y las flechas de Palmares están en las fuentes | **Documentado** (las lanzas); **a verificar** la azagaya y la palabra "zagaieiro" en un documento. Thornton (1999) |
| III | **Guarnição da cerca** | Línea que gana +2 de armadura junto a cercas y puertas propias | La defensa de la cerca real | **Documentado.** Lara (2021); Ennes (1938) |
| IV | **Capitães de mocambo** (élite) | Choque y mando: las unidades a 5 casillas pegan +1 | Jefes de mocambo y de guerra que las fuentes nombran con títulos portugueses (*mestre de campo*, *capitão*), como Ganga Muíça en 1677–1678 [verificar el título que le da la *Relação*; si no aparece así, "jefes de mocambo" sin nombre propio]. Los títulos *ngana*, en el texto | **Documentado.** *Relação* (1678); Lara y Fachin (2021). Sin glorificar a una persona: **consultar** a la CONAQ (§7) |

**Maravilla: la *Cerca do Outeiro da Barriga*,** con sus tres anillos (H-17): el asalto que falla es el de 1692 y la caída, febrero de 1694. Mientras está en pie, la fama no baja y la acogida cuesta la mitad. La cuenta para ganar es igual que las otras, pero **si el jugador eligió el Pacto de Cucaú la maravilla no se puede construir**: el precio del pacto (C-68). **Documentado** (Lara, 2021; Ennes, 1938). La Serra da Barriga es hoy el Parque Memorial, sitio de memoria del 20 de noviembre: una maravilla cuya caída cierra la partida reproduce 1694. **Hasta la consulta a la CONAQ y al Parque Memorial, la maravilla no se destruye: queda "sitiada"** (la cuenta se corta mientras haya tropa enemiga dentro) (C-97).

## 3.6 Ayutthaya

**Mecánicas:** arroz junto al agua, el *suai* (C-72), el elefante del rey y los barrios extranjeros. **Los saberes:** la hidráulica (el arroz de crecida y los canales que cortan meandros), la cerámica de Si Satchanalai, el saber de los elefantes, la medicina de la corte, la construcción de juncos y el comercio y la diplomacia del Phra Khlang. **Cuidado:** el wat, la imagen del Buda, el *Tra Nimit*, el *piphat* ceremonial (H-25, H-26), la astrología de corte (*hon*, *roek*), los amuletos y los tatuajes protectores (*sak yant*), y la parte ritual de los tratados de elefantes y de medicina.

### Mejoras

| Edad | Nombre | Eje | Qué hace | Saber | Evidencia y fuente |
|---|---|---|---|---|---|
| II | ***Khotchasat*** (คชศาสตร์, el saber de los elefantes) | militar | +10 % de vida a los elefantes; el kraal entrena 15 % más rápido | El saber práctico de los cornacas y del departamento real de elefantes (que Phetracha dirigía bajo Narai): crianza, doma, curación y la captura en el *phaniat*. Entre los cazadores, los **kui** del este [verificar su presencia en la época]. **El juego no usa la parte ritual** de los tratados (*tamra chang*): marcas de augurio, elefantes blancos, ensalmos, el espíritu del lazo | **Documentado** (el manejo y la captura). La Loubère, *Du Royaume de Siam* (1691); Baker y Pasuk, *A History of Ayutthaya* (2017); Dhiravat (1984). Cuáles tratados vienen de Ayutthaya y no de Bangkok, y el nombre del departamento (*Krom Phra Khotchaban*), [verificar] |
| II | **Cerámica de Si Satchanalai** | economía | El horno (en el almacén) da riqueza al cocer arcilla, y el suai rinde +15 % de riqueza. **Se apaga en la IV** (la exportación cayó después del siglo XVI) | Hornos de gres y celadón cerca de Sukhothai (Sawankhalok) que exportaron por todo el Sudeste Asiático marítimo entre los siglos XIV y XVI. Sukhothai quedó bajo Ayutthaya en el siglo XV | **Arqueológico (fuerte):** cientos de hornos excavados y la cerámica en naufragios. Brown, *The Ming Gap and Shipwreck Ceramics in Southeast Asia* (2009); los trabajos de Don Hein sobre los hornos [verificar el título] |
| III | ***Tamra Phra Osot Phra Narai*** y ***nuat*** | militar (sanador) | El mo cura +25 % y sana más rápido a las unidades fuera de combate; el ***mo luang*** se entrena en el centro, con +50 % de alcance de curación | El recetario de los médicos de la corte de Narai (ตำราพระโอสถพระนารายณ์): **médicos siameses, chinos, indios y uno europeo**, una mezcla de tradiciones que desarma el mito de una medicina "pura". Era la medicina del rey y de la corte, no la de los campesinos. El ***nuat*** (masaje médico): La Loubère cuenta que, al enfermar, lo primero era hacerse amasar el cuerpo por quien conocía el arte. El marco budista y astrológico (el *wai khru* a Jivaka) no se usa | **Documentado** (el texto y el masaje). Edición del Departamento de Bellas Artes (*Krom Sinlapakon*) [verificar el año]; Salguero, *Traditional Thai Medicine* (2007); La Loubère (1691). El número de recetas (unas 81), las fechas (década de 1660) y los autores, [verificar]. El departamento de masaje en las listas del *Kotmai Tra Sam Duang*: **debatido**. Las inscripciones del Wat Pho son de la década de 1830: no se usan como época |
| III | **Arroz de crecida** | economía | Los arrozales junto al agua rinden +10 %; en la IV no se agotan | Variedades de arroz que crecen con la inundación natural de la llanura (H-09), *khao khuen nam* (ข้าวขึ้นน้ำ, "arroz que sube con el agua") [verificar el uso de época] | **Documentado.** La Loubère (1691); Baker y Pasuk (2017); Molle y Keawkulaya (1998) |
| III | **Barrio chino y puertos** | mecánica | Tercer barrio extranjero (C-71): el comercio de juncos y, en la IV, su compañía. Los barrios extranjeros pagan +20 % | La comunidad extranjera más grande, que defendió Khlong Suan Phlu en 1767. La administración real de los puertos (*Krom Tha*): el puerto de la derecha (*Krom Tha Khwa*: persas, indios y otros musulmanes) y el de la izquierda (*Krom Tha Sai*, chinos) [verificar antes de 1767]. **Quién paga:** los derechos de aduana y el monopolio de compra del almacén real (*Phra Khlang Sinkha*) | **Documentado.** Sarasin Viraphol, *Tribute and Profit* (1977); Baker y Pasuk (2017); Breazeale (ed., 1999); Cushman (trad.), *The Royal Chronicles of Ayutthaya* (2000) |
| IV | ***Khlong lat*** (canales que cortan meandros) | mecánica | El aldeano cava un tramo de khlong recto entre dos curvas del río: las tropas y el comerciante propios van +25 % más rápido por él; el enemigo, no | El reino acortaba el Chao Phraya cavando atajos entre las curvas. Uno, en el siglo XVI, dejó el viejo cauce en Bangkok; otro, en el XVIII, dejó la isla de Ko Kret (H-09) | **Documentado.** Baker y Pasuk (2017); Molle y Keawkulaya (1998). Las fechas (1522 y 1722), [verificar] |
| IV | **Fundición real** | militar | +10 % de ataque a la pólvora | Cañones fundidos en Ayutthaya, con fundidores locales, portugueses y chinos. Si se confirma, los cañones que Kosa Pan llevó de regalo a Luis XIV (1686) | **Documentado** (la artillería). Charney, *Southeast Asian Warfare* (2004). La escala y la fabricación local, [verificar] |
| IV | **Astilleros de juncos** | economía | El junco de tributo y el comerciante de la IV cuestan −20 % y rinden +10 % | Siam construía juncos de teca más baratos que en China, con carpinteros chinos y madera siamesa: "teca siamesa y oficio chino". El calendario del viaje lo marcaban el monzón y los pilotos (*nakhoda*) chinos | **Documentado** (sobre todo en el siglo XVIII). Sarasin Viraphol (1977); Cushman, *Fields from the Sea* (1993); Ishii (ed.), *The Junk Trade from Southeast Asia* (1998) |

### Unidades propias

| Edad | Unidad | Qué hace | Saber | Evidencia |
|---|---|---|---|---|
| II | **Elefante de guerra** (*chang suek*, ช้างศึก, ya existe) | Choque de área | — | Documentado |
| III | ***Ngao*** | Línea con **guja** (hoja curva de un filo sobre un asta; no es alabarda): +6 contra los montados y los elefantes | El arma de quien iba en el cuello del elefante y también de la infantería | **Documentado** (crónicas: el combate de Nong Sarai). Cushman (2000); Terwiel, *JSS* 101 (2013). Las piezas de época, [verificar]: las de museo son mayormente de Bangkok |
| IV | **Defensores de Suan Phlu** (élite) | Tropa china con +2 de armadura sobre la muralla y las fortalezas; armas de fuego y de asta | La defensa china de la muralla en 1767 y el apoyo a Taksin | **Documentado** (la defensa). Cushman (2000); Sarasin Viraphol (1977). El armamento, [verificar] |

La compañía japonesa queda como la unidad del barrio japonés.

**Maravilla: *Krung Si Ayutthaya*, la ciudad isla, con el fuerte de *Pom Phet*** (ป้อมเพชร, en la esquina sureste, en la confluencia con el Pa Sak; sus restos se conservan). Ficha: "Una isla hecha a mano: ríos, canal (el Khu Khue Na [verificar fecha y rey]) y foso, murallas de ladrillo (de mediados del siglo XVI) y fuertes en las esquinas". Mientras está en pie, rige **la crecida como muralla**: las casillas bajas junto al agua a 15 casillas de la capital frenan 30 % a la tropa enemiga; **una torre o fuerte enemigo dentro del radio anula el frenado a 4 casillas**. Ficha: "La crecida echaba a los sitiadores (1548, 1586–1587, 1760)... hasta que en 1766 los birmanos se quedaron durante las lluvias, con campamentos en alto, barcos y cultivos propios". **Documentado y arqueológico** (Baker y Pasuk, 2017; Wyatt, 2003; Lieberman, *Strange Parallels* I, 2003; parque histórico, Patrimonio de la Humanidad, 1991). **No es sagrada; el Wat Phra Si Sanphet queda descartado como maravilla** (C-79 a): era el templo del palacio, guardaba la imagen de oro que fundieron los birmanos en 1767 y sus *chedi* guardan cenizas de reyes. Si un día se quiere, será un escenario de campaña con consulta, no una pieza del jugador.

## 3.7 Para retomar

Saberes con evidencia que no entraron para mantener 8 mejoras y 3 unidades por pueblo. Quedan como contenido para cuando haya lugar (o para reemplazar si la consulta saca alguno):

- **Tawantinsuyu:** *mitmaqkuna* (colonias trasladadas, muchas veces por la fuerza; los de Wayna Qhapaq en Cochabamba: Wachtel, 1982; Rowe, 1946; D'Altroy, 2014), la cantería que resiste sismos (Protzen, 1993), la hidráulica de Tipón y Machu Picchu (Wright y Valencia Zegarra, 2000), la observación del horizonte (con consulta) y la quina (**debatida**).
- **Mapuches:** el *rütrafe* (platería, **documentado desde fines del siglo XVIII**), el piñón del pewen, las armas tomadas en Curalaba (variante de la élite).
- **Guaraníes:** los talleres de música; el manejo del monte (**debatido**).
- **Etiopía:** el campamento de *kərämt* (la corte quieta en la estación de lluvias rinde +10 %), la variolación (**debatida** antes de 1800), los títulos y la corte en las crónicas.
- **Palmares:** la sociedad mezclada de la Serra da Barriga como mecánica de acogida (Orser y Funari, 2001); los títulos *ngana* (texto de campaña).
- **Ayutthaya:** el ***Krom Suratsawadi***, el registro de la mano de obra (con su ficha de trabajo forzado, H-08; Akin Rabibhadana, 1969); las formaciones del *Tamra Phichai Songkhram* (**debatido**, sin presagios ni amuletos).

---

# 4. El final de partida

## 4.1 Las maravillas

| | Propuesta |
|---|---|
| Costo | 1500 de madera, 1500 de piedra y 1500 de riqueza [tentativo] |
| Obra | 600 s con 10 constructores; como los hitos, la obra es vulnerable |
| Victoria | Una cuenta de 15 minutos desde que se termina [verificar el tiempo de AoE4]. Si cae, la cuenta se pierde. Es una opción del lobby (C-50) |
| Una por pueblo | Ollantaytambo; el gran koyagtun; la plaza y el cabildo de la tava o la aldea grande del monte; Fasil Gəbbi; la Cerca do Outeiro da Barriga (sitiada, no destruida, hasta la consulta); Krung Si Ayutthaya con Pom Phet (§3) |
| Efecto mientras está en pie | El de cada pueblo, sobre todo **defensivo y económico**: obliga al rival a ir a romperla |

## 4.2 El asedio que rompe contra la defensa que aguanta

- **Defensa que aguanta (III):**
  - **fortaleza o torre pesada**, una por pueblo: pukara (incas), pukara de frontera mapuche (sin piedra: madera y tierra; las crónicas llaman *pucaraes* a los fuertes mapuches y la arqueología los confirma, Dillehay, 2007), trinchera de tacuara (guaraníes), amba fortificada (Etiopía), cerca real (Palmares) y ***pom*** (ป้อม, fuerte; Ayutthaya);
  - **hitos militares con aura:** en el diseño completo, el bono de combate de los hitos militares de la III y la IV vale **dentro de su aura** (9 casillas, como la curación de `aura_hito.militar`), no en todo el mapa. Defender cerca del hito paga; atacar lejos no se infla. Es lo que más baja la inflación de la IV (§5).
- **Asedio que rompe:** el asedio de área (III) contra las bolas de tropa, y el cañón o pieza pesada (IV) contra fortalezas, hitos y maravillas. Los pueblos sin cañón rompen con tiempo (cerco largo y fuego, armas capturadas, antorchas) o con su élite. El asedio sin escolta muere: la respuesta es el hostigador montado y el choque.
- **Atacar el suelo** (J-05) para el asedio de área y el cañón.

## 4.3 La economía del final

1. **Las vetas se agotan:** la arcilla de casa ya se agota (C-16). En la IV, la arcilla del centro del mapa y los sitios rinden más (`sitios.renta_por_cantidad` por edad: +50 % en la IV).
2. **El comerciante que camina** (IV, desde el mercado): lleva riqueza entre el mercado propio y uno aliado o el ingenio neutral. Rinde más cuanto más lejos va, como en AoE4, y se puede cortar. Por pueblo:
   - la **caravana de intercambio** de llamas entre pisos ecológicos (Tawantinsuyu). La ficha dice que el Estado inca no tenía mercado: redistribuía (Murra, 1975);
   - el conchavo de ganado y de ponchos (mapuches; siglo XVIII, adecuado para la IV);
   - la canoa de yerba (guaraníes; la yerba bajaba en balsas y barcas hasta Santa Fe);
   - el **mercader *jabarti*** con la caravana de *amole* (Etiopía);
   - el trato con los moradores (Palmares);
   - **la barca del río** (*ruea*, เรือ; Ayutthaya, sin combate naval). El junco era un barco de mar: queda para el puerto y el tributo.
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

`tools/modelo_progreso.py` (nuevo, solo lee `data/`). Uso: `python3 tools/modelo_progreso.py` (y `--vara-fija` para la tabla 1 contra un rival fijo). Se volvió a correr después de la revisión histórica: el único efecto propio que cambió en el modelo es el hierro de Palmares (+1 de armadura al choque → +1 de ataque al choque). Los saberes que cambiaron de nombre (champi, pólvora de Massawa, khotchasat) conservan el efecto.

## Qué mide

- **El poder del ejército de 30** (Lanchester) es la suma de los dps contra el rival por la suma de los tiempos que tarda cada unidad en morir bajo el dps medio del rival.
  - Cada pueblo tiene **su composición por edad** según lo que produce: los incas sin caballo, los mapuches con kona, Ayutthaya con elefantes y compañías.
  - **El gasto típico** es el de hoy: herrería I en la II; herrería II y adiestramiento en la III; herrería III en la IV; y el hito militar de cada edad.
  - En la tabla 1, el rival es un ejército genérico de la misma edad con las reglas de hoy, igual para las dos columnas.
- **El valor de una línea** es cuántas unidades comunes (sin mejoras ni bono) vale una unidad de esa línea en la IV, peleando las dos contra la misma mezcla de comunes. Se calcula con la ley cuadrada: √(razón de dps × razón de vida efectiva).
  - **Interpretación de la regla del veterano** ("ninguna línea pasa de ×2 su base en la IV"): **una unidad de la IV no vale más de dos comunes.** Se consulta al autor (C-75).
- **No modela:**
  - el área (elefante y asedio), la curación, la esquiva (*sanguar*), el sigilo, la altura, el alcance ni la velocidad;
  - las condiciones (la pólvora de Massawa se cuenta con la ruta abierta);
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

Contra un rival fijo (`--vara-fija`), las diferencias son de 0 % en todas las celdas. **El paso 1 cambia el "cómo" sin cambiar el "cuánto"**, siempre que se compren los niveles. Sin comprarlos (con la herrería sí), el ejército de la III pierde 8–9 % y el de la IV, 19–20 %. (La tabla 1 no usa los saberes propios: la revisión no la cambia.)

### Tabla 2 · Diseño completo: el poder crece por compras (contra un rival fijo, el genérico de la II sin mejoras; edad I = 100)

| Pueblo | I | II | III | IV sin comprar nada | IV con el gasto típico | IV / III | IV hoy |
|---|---|---|---|---|---|---|---|
| Tawantinsuyu | 100 | 135 | 300 | 300 | 444 | ×1,48 | 621 |
| Mapuches | 100 | 180 | 329 | 329 | 510 | ×1,55 | 578 |
| Guaraníes | 100 | 163 | 218 | 218 | 323 | ×1,49 | 418 |
| Etiopía | 100 | 214 | 376 | 340 | 503 | ×1,34 | 575 |
| Palmares | 100 | 160 | 225 | 225 | **332** (antes 343) | **×1,48** (antes ×1,53) | 574 |
| Ayutthaya | 100 | 311 | 443 | 443 | 664 | ×1,50 | 732 |

- **Llegar a la IV no da nada solo:** la columna "sin comprar nada" es igual a la III. En Etiopía es menor porque su composición de la IV cambia infantería por mosqueteros.
- **Lo que compra la IV da ×1,34 a ×1,55** de poder: élite, herrería III, escuela y el saber militar propio. Es el motivo para llegar.
- **El diseño completo termina por debajo de la IV de hoy** (444 contra 621 en los incas). **Es a propósito:** hoy la IV está inflada por el bono de +35 %, la herrería y tres hitos militares globales que se suman. Esa diferencia no se pierde:
  - pasa al **aura de los hitos** (la defensa que aguanta);
  - y a lo que el modelo no cuenta: asedio, cañón, élite propia, sanador y, en Palmares, el *sanguar*.

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
| Palmares | Gente de guerra | choque | ×2,31 | **×1,84** (antes ×1,93) |
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
- **El cambio del hierro de Palmares** (ataque en lugar de armadura) baja a la gente de guerra de ×1,93 a ×1,84: la armadura rendía más que el ataque contra la mezcla de comunes. Palmares queda con el menor salto de la IV junto a los incas; el *sanguar* (que el modelo no cuenta) compensa contra la distancia.

**Qué se cambió para cumplir la regla** (en `PROPUESTA` y `PROPIAS` del modelo):
- la herrería III de ataque da +1 (hoy, +2), porque el élite ya sube el ataque;
- los hitos militares de la III y la IV dan su bono en aura;
- la escuela da vida al choque (no a la línea, que ya es la más dura);
- tres saberes militares de la IV se movieron a cosas que no inflan la línea:
  - la warak'a da alcance;
  - Ayutthaya (fundición real) y Etiopía (pólvora de Massawa) refuerzan la pólvora, que es la línea más baja.

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
| **6** | **Saberes propios:** 8 mejoras y 3 unidades por pueblo, de a dos pueblos por torneo. Primero guaraníes y mapuches, después Palmares y Etiopía, y por último incas y Ayutthaya | Por pueblo: hoyos, canoa, heridos que no mueren (trepanación), puentes, canales (*khlong lat*), inundación, esquiva contra la distancia (*sanguar*), condición de ruta abierta (pólvora de Massawa), aliados por tratado que se rompe | **Sí:** unas 14 unidades nuevas (boleador, cañón de tacuara, chang suek y compañía japonesa ya existen) y 48 íconos | Torneo por par; `civ_smoke.gd` |
| **7** | **Maravillas, comerciante que camina y rendición de la IA** | Victoria por maravilla, maravilla "sitiada" (Palmares), comercio, rendición en todas las dificultades | **Sí:** 6 maravillas y 6 comerciantes | Partidas de 45–60 min; opciones del lobby |

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

## Para el autor (en `proceso/CONSULTAS.md`, C-75 a C-83; nuevas desde C-84)

### C-75 a C-83, después de la revisión

| # | Pregunta | Opciones (la por defecto, primero) | Estado tras la revisión |
|---|---|---|---|
| C-75 | **Regla del ×2:** ¿"una unidad de la IV no vale más de dos comunes" (ley cuadrada, como mide el modelo) o "ni el ataque ni la vida pasan de ×2" (más permisiva)? | a) Valor en comunes · b) Por estadística | Sin cambio |
| C-76 | **Hitos militares con aura** en la III y la IV (en lugar de bono global). Es lo que más desinfla la IV | a) Sí, en el paso 4 · b) Solo el de la IV · c) No | Sin cambio |
| C-77 | **Paso 1:** el +10 % de la II en la herrería I y los niveles veterano y élite comprados. ¿Arrancamos por ahí? | a) Sí · b) Primero la herrería separada | Sin cambio |
| C-78 | **Maravilla:** costo de 1500 madera, piedra y riqueza; 600 s de obra; cuenta de 15 min; opción del lobby | a) Así · b) Otros números | Sin cambio (la de Palmares, ver C-97) |
| C-79 | **Ayutthaya:** maravilla Krung Si Ayutthaya con Pom Phet | — | **Cambia: se cierra en a).** El historiador pide sacar la opción del Wat Phra Si Sanphet (templo del palacio, cenizas de reyes, la imagen fundida en 1767). Se corrige la grafía (Pom, no Phom; Krung Si Ayutthaya, no Krung) |
| C-80 | **Unidades nuevas sin modelo:** ¿esperan al arte o entran con una maqueta distinta? | a) Esperan · b) Maqueta con silueta propia | Sin cambio |
| C-81 | **Trepanación:** que el 20 % de los que caen **por golpe** cerca del hampikamayuq **no muera** y vuelva herido a la kallanka, en lugar de un sanador más fuerte | a) Así · b) Solo un sanador más fuerte | **Cambia** (AL, R-1): ya no "los caídos vuelven", que se leía como resurrección. Se corrige la cifra de la Guerra Civil (mortalidad, no supervivencia) y se dice que es un saber de dos mil años que el Inka heredó |
| C-82 | **Etiopía: orden del *kätäma*** en lugar del *Bahrä Hasab*. La corte se despliega en la mitad del tiempo porque el campamento real tenía un plano fijo (Álvares, 1540; Horvath, 1969) | a) *Kätäma* · b) Consultar igual a la Tewahedo antes de sacar el *Bahrä Hasab* | **Cambia** (AF, E9): el *Bahrä Hasab* sale porque la mecánica afirmaba algo falso; "Cartógrafos de la corte" se descarta |
| C-83 | **Saberes con nivel "debatido":** *kilombo*, *yachaywasi*, *fäws* antes del siglo XVIII, la herencia de la forja centroafricana, el *sanguar* en Palmares, la erveira en Palmares, el *šotäl* (solo en la ficha), el *Chindamani* y el *nuat* en la corte. ¿Entran con la marca en la ficha o se reemplazan? | a) Entran con la marca · b) Solo documentados y arqueológicos | **Cambia la lista:** salen el shotel como bono y los armeros de Gondar (reemplazados por la pólvora de Massawa, documentada); entran los nuevos debatidos |

### Nuevas

| # | Pregunta | Opciones (la por defecto, primero) | Pidió |
|---|---|---|---|
| C-84 | **Élite guaraní de la vía monte:** Sepé y la Guerra Guaranítica pasan a la vía misión (la pelearon los pueblos de misión) y la vía monte tiene a los *ka'aguygua* | a) Sí · b) Otra | AL (R-2) |
| C-85 | **Maravilla guaraní de la vía monte:** "Aldea grande del monte" en lugar de *tekoha guasu* hasta consultar | a) Sí · b) Consultar primero y dejar *tekoha guasu* | AL (R-3) |
| C-86 | **Mapuches:** *ampive* en lugar de *lawentuchefe*, y el poncho (*makuñ*) en lugar del *rütrafe* | a) Las dos · b) Solo el nombre del sanador (y *rütrafe* marcado "desde fines del siglo XVIII") · c) Ninguna | AL (R-4) |
| C-87 | **Incas, pieza pesada de la IV:** armas capturadas de Vilcabamba en lugar de repetir las galgas | a) Armas capturadas · b) Solo la inundación de la maravilla | AL (R-5) |
| C-88 | **Huayrachina** como economía de la IV inca, con *mitmaqkuna* a "para retomar" | a) Sí · b) No: queda *mitmaqkuna* | AL (R-6) |
| C-89 | **Escuela de Palmares:** *Oficinas do Macaco* (herreros, alfareros, tejedores de palma) en lugar del *Conselho dos mocambos* | a) *Oficinas do Macaco* · b) *Ferrarias do Macaco* (solo la forja) · c) Consejo con *makota* y "debatido" | AL (R-7), AF (P12) |
| C-90 | **Etiopía, unidad de la II:** guerrero de *gaša* (escudo y jabalinas), sin el bono "por encima del escudo" | a) Sí, choque con jabalinas y *gaša* · b) Queda el *šotäl* con "debatido" y sin bono especial | AF (E10) |
| C-91 | **Élite etíope:** "Jinetes oromo aliados" con costo de tratado (que se puede romper), en lugar de una compra con riqueza | a) Sí · b) "Caballería de la corte" (sin oromo) | AF (E11) |
| C-92 | **Hierro de Angola Janga:** +1 de ataque en lugar de +1 de armadura (ya aplicado en el modelo) | a) +1 de ataque · b) Herramientas y estrepes −15 % de costo | AF (P7) |
| C-93 | **Palmares, sanador y mejora de la III:** sanador *erveira/erveiro*; la mejora de los curadores (sin fuente para Palmares) se reemplaza por el *sanguar* | a) Las dos · b) Solo el nombre; la mejora de curación queda con "debatido" · c) Esperar la consulta quilombola | AF (P4, S-P1) |
| C-94 | **Saberes nuevos de Etiopía y Palmares:** entran ya *kätäma*, *jabarti*, *wägešša*, *ṭef* y *gotära*, *kosso*, *ṣäḥafe tə'əzaz*, *sanguar* y las oficinas; *kərämt*, variolación y *ngana*, para retomar | a) Como queda en el diseño · b) Solo los reemplazos (*kätäma*, *jabarti*, *wägešša*); el resto, para retomar | AF |
| C-95 | **Astrología de corte en Ayutthaya:** "Reglas de la astronomía siamesa" → Astilleros de juncos; escuela *Krom Horasat* → el Phra Khlang con sus intérpretes | a) Así · b) Escuela = "Los calculistas del calendario", con una ficha sobre la astrología y sin bono de augurio · c) Dejarlo | AS (1, 2) |
| C-96 | **Saberes nuevos de Ayutthaya:** Si Satchanalai (II), *khlong lat* (IV), el *nuat* con el recetario; la crecida como muralla pasa a la maravilla; *Krom Suratsawadi*, para retomar | a) Así · b) Solo Si Satchanalai y *khlong lat* · c) Además *Krom Suratsawadi* en la II, en lugar de Si Satchanalai | AS (S1–S6) |
| C-97 | **Maravilla de Palmares:** ¿la Cerca do Outeiro da Barriga se puede destruir como las otras, o queda "sitiada" (la cuenta se corta mientras haya enemigos dentro) hasta la consulta a la CONAQ y al Parque Memorial? | a) Sitiada hasta la consulta · b) Como las otras | AF (P13) |

## Para comunidades y especialistas (suma a la tabla de C-74)

Están en la lista completa: [29-consultas-a-comunidades](29-consultas-a-comunidades.md).

---

## Resumen de los saberes destacados

| Pueblo | Saber destacado | Evidencia |
|---|---|---|
| Tawantinsuyu | Cirugía de cráneo, un saber de dos mil años que el Inka heredó (en su época sobrevivía el 75–83 %; en la Guerra Civil de Estados Unidos moría el 46–56 %); la *huayrachina* de Potosí; el khipu | arqueológico (fuerte); documentado y arqueológico (fuerte); arqueológico y documentado (lo narrativo, debatido) |
| Mapuches | Hoyos y estacas contra la caballería; la adopción propia del caballo (*kawellu*); el poncho de la frontera | documentado |
| Guaraníes | La escritura de los cabildos y la imprenta de las misiones; el *kokue* de policultivo | documentado (fuerte); documentado y arqueológico |
| Etiopía | Actas de tierra en ge'ez; el orden del *kätäma* | documentado (desde el siglo XV y los años 1520) |
| Palmares | Roças con las palmeras nativas; la red de mocambos; la forja (con su "debatido") | documentado; documentado; documentado y debatido |
| Ayutthaya | Los canales que cortan meandros (*khlong lat*); la cerámica de Si Satchanalai; el recetario de Narai (médicos de cuatro tradiciones) | documentado; arqueológico (fuerte); documentado |
