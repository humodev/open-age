# Campañas — índice y decisiones de guion

> Estado: borrador v1 (2026-11-13). Los datos jugables viven en `data/campanas/<clave>.json` (D-008); este documento explica el arco, qué enseña cada misión, las decisiones de tono y lo que falta verificar.
> Fuentes de diseño: `01-vision-y-pilares.md` (pilar 3), `03-matriz-de-roles.md`, `05-mecanicas-nucleo.md` y los informes de `investigacion/`. Las mecánicas citadas (M1, M2…) remiten a la numeración de cada informe.

## Índice

| Clave | Título | Narrador | Arco | Archivo |
|---|---|---|---|---|
| `tawantinsuyu` | Los nudos del camino | Un khipukamayuq de Tinta, en 1781 | 1438–1780: construir la red, estirarla, defenderla, levantarla | `data/campanas/tawantinsuyu.json` |
| `mapuches` | El hacha y el canelo | Una tejedora de Purén que anuda el *pron*, en 1641 | 1553–1641: del hacha de guerra al parlamento | `data/campanas/mapuches.json` |
| `guaranies` | Esta tierra tiene dueño | Un escribano del cabildo de San Miguel, después de Caiboaté (1756) | 1537–1754: pactar, huir, resistir, negarse | `data/campanas/guaranies.json` |
| `etiopia` | La corte que camina | Un escriba de la corte en la Gondar recién fundada (c. 1636) | 1445–1636: la corte móvil sobrevive a Adal y elige quedarse | `data/campanas/etiopia.json` |
| `palmares` | Lo más oculto | Una anciana nacida en Palmares, en un mocambo de Camuanga (c. 1700) | 1645–1694: esconderse, fortificar, pactar, negarse; sobrevivir a la caída | `data/campanas/palmares.json` |
| `ayutthaya` | El tiempo del agua | Un escribano del almacén real (Phra Khlang) en la Thonburi recién fundada (c. 1770) | 1593–1767: pelear en la seca, abrir el puerto, perder la isla, refundar desde el mar | `data/campanas/ayutthaya.json` |

> Palmares y Ayutthaya todavía no tienen ficha en `civs/` ni decisión en `04` (sus informes lo piden). Las campañas usan las claves `palmares` y `ayutthaya` como provisionales.

## Arcos y mecánica que enseña cada misión

Los tipos de objetivo del motor son genéricos; la mecánica propia va en el texto del objetivo y se usa el tipo más cercano (columna "Cómo se representa").

### Tawantinsuyu — Los nudos del camino

Arco: un mismo khipukamayuq, en 1781, lee cuerdas viejas y termina contando lo que vio. La red se construye con trabajo pagado con fiesta (1438), se estira hasta el límite con una guerra de conquista que el propio narrador no embellece (c. 1500), se defiende contra los invasores y sus aliados andinos (1537) y se vuelve a levantar desde abajo (1780).

| # | Misión | Protagonistas | Mecánica que enseña (informe) | Cómo se representa |
|---|---|---|---|---|
| 1 | Los que se quedaron (1438) | Kusi Yupanki (Pachakutiq) | Mit'a (M1) y reciprocidad con fiesta (M2); obra estatal (avance) | `entrenar aldeano`, `recolectar alimento` (la fiesta), `edad 2`; los "pururawka" llegan como `refuerzos` al terminar la obra |
| 2 | La frontera de piedra (c. 1500) | Wayna Qhapaq | Qollqa en hilera (M3), pukara (M11), leva por turnos en chunka de 10 (M5), herencia dividida (M6) | `construir deposito 4`, `construir torre 3`, `entrenar hondero 10`, `edad 3` con texto de distancia a la obra anterior; `proteger deposito` |
| 3 | El agua de Ollantaytambo (1537) | Manco Inka, Titu Kusi (como fuente), Hernando Pizarro | Leva desde qollqa (M5), piedra caliente (M10), pozos e inundación (M11), adopción por captura (M13) | `entrenar hondero`, `construir empalizada 20`, `sobrevivir`, objetivo oculto `matar` al abrir los canales, `destruir jinete` secundario |
| 4 | Tinta (1780) | Túpac Amaru II, Micaela Bastidas, Mateo Pumakawa | Levantamiento de los kurakas (M13, opción B), logística de qollqa | `entrenar guerrero 15`, `destruir hito_economia` (obrajes), `recolectar alimento`, `matar`; objetivo oculto secundario "marchar ya sobre el Cusco" |

### Mapuches — El hacha y el canelo

Arco: la tejedora habla antes de Quilín y cuenta la guerra desde el tiempo de su abuela. El hacha negra (guerra) y el canelo (paz) son los dos polos: la campaña empieza alzando el hacha y termina con el gobernador entrando a Quilín con ramas de canelo.

| # | Misión | Protagonistas | Mecánica que enseña (informe) | Cómo se representa |
|---|---|---|---|---|
| 1 | El hacha negra (1553) | Lautaro | Lof dispersos (M3), koyagtun (M4), relevo de escuadrones (M7) | `construir deposito 3` (lof separados), `recolectar alimento`, `edad 2`, `destruir_hitos`, `matar` oculto con texto de oleadas; `proteger deposito` |
| 2 | Lo que no llega a casa no cuenta (1554) | Lautaro, Francisco de Villagra | Malón con arreo (M1), relevo (M7), captura de armas sin pólvora (M11) | `matar`, `destruir granja 6`, `recolectar riqueza` (el botín cuenta al llegar), `destruir arcabucero` secundario |
| 3 | Curalaba (1598) | Pelantaru, Anganamón, Óñez de Loyola | Asamblea que elige toqui de caballería (M4, opción edad III), jinete lancero, trasnochada (M6) | `edad 3` que dispara `refuerzos jinete`, `entrenar lancero`, `destruir_hitos` x2 (el segundo oculto: alzamiento general), `proteger granja` |
| 4 | Quilín (1641) | Lientur, Maulicán, Lincopichón | Kulliñ (M2), malón (M1), parlamento y frontera (M9) | `destruir granja`, `recolectar riqueza`, `destruir cuartel` (ningún fuerte de este lado), `edad 4` (los cuatro butalmapu), `sobrevivir` oculto mientras se parlamenta |

### Guaraníes — Esta tierra tiene dueño

Arco: cuatro respuestas guaraníes a la conquista, todas activas. Pactar como parientes (Lambaré), irse en masa (Guairá), esperar armados (Mbororé) y negarse (1754). La misión 2 nombra a Ñezú para que quede claro que también hubo quien rechazó las reducciones.

| # | Misión | Protagonistas | Mecánica que enseña (informe) | Cómo se representa |
|---|---|---|---|---|
| 1 | Lambaré (1537) | Mburuvicha de Lambaré (colectivo), Juan de Ayolas | Roça en el monte, nunca en *ñu* (M1); empalizada doble y fosos (M5); arqueros (núcleo); cuñadazgo como reciprocidad (M11) | `construir granja 3`, `construir empalizada 30`, `entrenar hondero` (arqueros), `sobrevivir`, `recolectar alimento` oculto (el convite del pacto) |
| 2 | Río abajo (1631) | Ñezú (en la narración), una anciana de Loreto | Éxodo (M12), fundación guiada por el karai (M4), canoas (M6), emboscada desde la orilla (M5) | `recolectar madera` (canoas), `sobrevivir`, `edad 3` (fundar río abajo), `proteger aldeano` |
| 3 | Mbororé (1641) | Nicolás Ñeenguirú, Ignacio Abiarú | Cañón de tacuara (M7), control del paso del río (M6), pólvora prestada (M9) | `entrenar ariete 3` (tacuara), `construir empalizada`, `matar 40`, `destruir_hitos`, `proteger arcabucero` |
| 4 | Esta tierra tiene dueño (1754) | Sepé Tiaraju | Ejército de pueblo, fuerte en casa (M8); vados con estacadas y tacuara (M6, M7); aliados minuanes y charrúas | `construir empalizada`, `entrenar ariete`, `sobrevivir`, `proteger centro` (no alejarse de casa), `matar`; `edad 4` secundario |

### Etiopía — La corte que camina

Arco: un escriba en Gondar copia las crónicas reales. La pregunta de toda la campaña es moverse o asentarse. La corte camina hacia el enemigo (1445), se refugia en las ambas (1531), vuelve al llano con una alianza que tiene precio (1543) y se queda quieta, con las consecuencias anotadas (1636).

| # | Misión | Protagonistas | Mecánica que enseña (informe) | Cómo se representa |
|---|---|---|---|---|
| 1 | La luz de Debre Berhan (1445) | Zara Yaqob, sultán Badlay | Kätäma (M1), gult (M2), convocatoria a la corte (M8), tabot y fundación (M5) | `construir casa 5` (anillos del campamento), `construir granja 4` (parcelas que pagan `recursos`), `refuerzos jinete` (convocatoria), `edad 2` oculto (procesión del tabot) |
| 2 | La montaña de los príncipes (1531) | Lebna Dengel (en la narración), imán Ahmad ibn Ibrahim | Ambas (M6): un acceso, tesoro, rendición por hambre | `construir torre 3` en el acceso, `recolectar alimento` (graneros), `sobrevivir`, `proteger centro`, `matar` oculto (asalto de 1533) |
| 3 | Wayna Daga (1543) | Galawdewos, Seble Wongel, Cristóvão da Gama (en la narración) | Remonta por tributo (M3), cinco cuerpos (M7, solo en texto), alianza portuguesa con precio (M10) | `recolectar riqueza` que dispara `refuerzos jinete`, `entrenar lancero`, `matar`, `destruir_hitos`, `proteger arcabucero` |
| 4 | Gondar (1636) | Fasiladas | Asentarse (M9): castillos, fuego por comercio, riesgo de los señores | `recolectar piedra`, `construir torre 4`, `edad 4`, `sobrevivir`, `destruir_hitos` oculto secundario |

### Palmares — Lo más oculto

Arco: la narradora nació en Palmares hacia 1640 y habla hacia 1700 desde un mocambo de Camuanga que todavía no encontraron. Su vida cruza la campaña: es una niña cuando la columna holandesa encuentra el mocambo vacío (1645), ve caer la cerca real (1677), va a Cucaú con su hermano mientras su marido, que llegó de un ingenio, se queda con Zumbi (1678), y sale de la Barriga en 1694. La pregunta es cuánto secreto se gasta para crecer. Las misiones 3 y 4 muestran las dos ramas de la edad IV (Cucaú y Quilombo) como decisiones políticas con costo: Gana Zumba y Zumbi argumentan y ninguno es caricatura.

| # | Misión | Protagonistas | Mecánica que enseña (informe) | Cómo se representa |
|---|---|---|---|---|
| 1 | Cuatro fraguas (1645) | Dumbi (como "rey de los Palmares" en tiempos holandeses), expedición de Blaer y Reijmbach | Roça con mandioca como reserva enterrada (M4), tendas de ferreiros (M7), acolhida (M1), secreto y exposición (M3), dispersión (M11) | `construir granja 4`, `recolectar alimento`, `construir cuartel 2` (fraguas), `edad 2` (casa del consejo y anillo); `refuerzos aldeano` por tiempo (gente que llega); `sobrevivir` oculto (que encuentren las casas vacías), `matar` y `proteger aldeano` secundarios |
| 2 | La cerca real (1677) | Gana Zumba, Aca Inene, Gana Zona, el Zambi general de las armas, Fernão Carrilho | Cerca con estrepería (M6), erguer a cerca con potentados de la parentela (M9), refugio en otro mocambo (M11) | `construir empalizada 30`, `construir deposito 2` (Subupira y Amaro), `edad 3` que abre la defensa y dispara el asalto, `sobrevivir` oculto mientras la gente sale, `proteger deposito` |
| 3 | El papel de Cucaú (1678) | Gana Zumba, Gana Zona, Zumbi | Encrucijada de 1678, opción Cucaú (M10): roça a la vista y comercio legal que ya no expone (M5); el pacto con condición de ruptura | `construir granja 6`, `recolectar riqueza` (resgate legal), `edad 4` por la vía del pacto; al romperse, `sobrevivir` oculto (cerco de tres meses) y `proteger aldeano` oculto (salir hacia la mata) |
| 4 | Tres cercas (1694) | Zumbi, Camuanga, Domingos Jorge Velho, Bernardo Vieira de Melo | Correría al ingenio que trae gente y hierro (M2), triple cerca (M6), opción Quilombo (M10), refundación tras la caída (M11) | `destruir hito_economia` del ingenio (rival 3) que dispara `refuerzos aldeano` y `recursos`, `construir empalizada 40`, `edad 4` por la vía de Zumbi, `matar 40` (asalto de 1692); ocultos `sobrevivir` (1694) y `construir deposito 2` (mocambos nuevos) |

### Ayutthaya — El tiempo del agua

Arco: el escribano salió de la isla en 1767 con tres libros de cuentas y escribe en Thonburi. Lo que ordena la campaña es el calendario: se pelea en la seca y se aguanta hasta la crecida (1593), el puerto da riqueza pero se ahoga por la boca del río (1688), el enemigo aprende a quedarse durante la crecida (1767) y el reino renace desde un puerto y con comerciantes (1767). La edad III se llama *Ekkarat* (soberanía) en la primera y en la última misión, a propósito.

| # | Misión | Protagonistas | Mecánica que enseña (informe) | Cómo se representa |
|---|---|---|---|---|
| 1 | Nong Sarai (1593) | Naresuan, Ekathotsarot, uparat Mingyi Swa | Leva de *phrai* por *munnai* (M2), corral de elefantes (M10), elefantes con rango (M8), celo descontrolado (M9, sin duelo), junco de tributo (M7) | `entrenar lancero 12`, `recolectar alimento` que dispara `refuerzos jinete` (elefantes), `edad 3` (el junco va a los Ming y no a Pegu), `matar 30`, `destruir_hitos` oculto, `proteger jinete` |
| 2 | La boca del río (1688) | Narai, Kosa Pan, Phra Phetracha, Phaulkon (en la narración), jeque Ahmad Qomi (en la narración) | Almacén real y ventanas de monzón (M1), barrios extranjeros (M5), compañías por contrato (M6), junco hacia Versalles (M7, opción B), fuertes con baluartes (M11), 1688 (M15) | `construir casa 4` (barrios) que dispara `refuerzos arcabucero` (compañías), `recolectar riqueza 1200`, `edad 4`, `construir torre 3`, `destruir_hitos` oculto (fortaleza de Bangkok), `proteger deposito` (almacén) |
| 3 | Veintisiete fuertes (1767) | Phraya Tak, Maha Nawrahta, Ne Myo Thihapate | La crecida como defensa y su inversión (M4), foso de agua (M11), voluntarios chinos y portugueses (M6), preparar la ruptura (M14) | `construir empalizada 25` (fosos), `construir torre 4`, `sobrevivir 600` (la crecida que ya no alcanza), ocultos `destruir torre 2` del rival (romper el cerco) y `matar 25`; `proteger arcabucero` |
| 4 | La otra orilla (1767) | Phraya Tak (Taksin), comerciantes teochew, marinos makasares | Refundar la capital desde el mar (M14), barrios y compañías chinas (M5, M6), almacén con crédito de comerciantes (M1) | `recolectar riqueza` y `construir casa 3` que disparan `refuerzos`, `matar 30`, `destruir_hitos` (Pho Sam Ton), `edad 3` (coronación en Thonburi), `destruir_hitos` oculto secundario contra los otros señores siameses |

## Decisiones de tono

1. **Una sola voz por campaña, situada en el tiempo.** El narrador es siempre de la civilización y está fechado (1781, 1641, 1756, c. 1636). Mira hacia atrás desde un lugar concreto, con lo que eso implica: el khipukamayuq sabe cómo termina Tinta, el escribano escribe después de Caiboaté. Así la voz tiene memoria y no omnisciencia.
2. **La fuente indígena o propia primero.** Betanzos (testimonio de la panaqa), Titu Cusi Yupanqui, las crónicas reales etíopes, las cartas de Micaela Bastidas y de los cabildos guaraníes van antes que los cronistas europeos. Cuando la única fuente es hostil (Schmidl, Henis, Futuh al-Habasha), el narrador lo dice o lo deja ver ("Las nuestras callan. Callar también es una forma de escribir").
3. **Lo militante va en el relato, no en el discurso.** Nadie da arengas sobre el colonialismo. El tono sale de detalles concretos: la mit'a de Potosí que "se tragaba a uno de cada siete", los obrajes donde "se tejía encerrado", los reyes que "anularon el tratado como quien borra una cuenta", la frase "un pariente no es un criado".
4. **Sujetos, no víctimas.** Cada campaña tiene victorias reales y derrotas reales, y el jugador gana sus misiones. Las derrotas históricas (Caiboaté, la ejecución de Túpac Amaru II, Quiapo, la caída de Amba Geshen) se cuentan en los epílogos, sin fatalismo y con continuidad: Túpac Katari, el Biobío como frontera, Sepé como santo popular.
5. **Sin maniqueísmo.** Hay rivales indígenas y africanos con razones propias: chankas, cayambes y caranquis (frente a quienes el Tawantinsuyu es el conquistador), cañaris aliados de los españoles "con cuentas pendientes", las milicias de Mateo Pumakawa, los auxiliares tupí de la bandeira, los yanakuna de Valdivia "que no habían elegido esa guerra", los señores de Lasta. Adal no se presenta como horda: tiene sultán, imán, crónica propia y una viuda con nombre (Bati del Wambara).
6. **Nada de magia ni de exotismo.** Los pururawka son los ayllus que bajan cuando ven la obra en pie; el karai es autoridad de la palabra, no un guía hacia la Tierra sin Mal; el tabot no se destruye ni se captura; el toki kura es insignia de mando.
7. **Lo que el informe pide no modelar, no se modela.** No hay cautivos como recurso en el malón, el cuñadazgo es reciprocidad (un convite de comida), no hay antropofagia ni sacrificio como mecánica, y la esclavitud aparece como violencia de los invasores (malocas de 1608, bandeiras) y nunca como recurso del jugador.
8. **Lenguas.** Los nombres van en quechua, mapudungun, guaraní y amárico o ge'ez transliterados con grafías provisionales. El narrador usa palabras propias sin glosarlas en exceso (mit'a, lof, tekoha, gult) y deja que el objetivo de la misión las explique jugando.
9. **Palmares (sección 7 del informe).** La narradora es nacida en Palmares y su marido no, así que la cláusula de devolución de Cucaú se cuenta desde una familia partida y no desde un discurso. Gana Zumba explica su pacto con la lógica del soba de Angola (Lara) y Zumbi le responde. Ninguno de los dos es traidor ni santo. El asesinato de Gana Zumba se cuenta como "dicen": la narradora "no lo vio y no lo dice". No hay esclavitud interna, ni Dandara como hecho, ni el despeñadero de 1694, ni la infancia de Zumbi con un cura. La memoria de los nombres que "no están en sus papeles" queda en una frase del epílogo, sin nombrarlos. Los rivales tienen nombre institucional (Compañía, terços, tropa de Velho "paulistas, mamelucos e indígenas", hombres "que habían peleado en Angola") y nunca un color de piel. La correría libera gente (`refuerzos aldeano`) y no captura a nadie. La violencia del ingenio no se muestra: se rompe la casa de molienda y la gente camina hacia la mata.
10. **Ayutthaya (sección 7 del informe).** Sin templos dorados, bailarinas ni "misterio": el escribano habla de cuentas, cueros, estaño y monzones. El duelo de Nong Sarai aparece como versión de las crónicas y al lado va la reconstrucción de Terwiel (celo, elefante sin control, disparo). El escribano "copia las dos". Los birmanos son Estados con generales y con una obra de ingeniería ("tan grande como las nuestras"), no hordas. Los extranjeros entran contratados y titulados por la corona (Qomi "firmaba con sello siamés"), y la corona también los destruye (makasares, 1686). Kosa Pan devuelve la mirada en Versalles. La *sakdina* tiene costo visible: el hermano del narrador, *phrai*, lleva la marca del registro en la muñeca. El golpe de Phetracha en 1688 "no fue limpio". No se usa "Siam nunca fue colonizado" y la caída de 1767 es un paso del arco, no el final.

## Notas de implementación para el motor

- **Facciones de los rivales.** El esquema solo admite claves de civilización o `invasores`. Los pueblos que no tienen civilización propia usan la más cercana: chankas, cayambes, caranquis, cañaris y las milicias de Pumakawa usan `tawantinsuyu`; los auxiliares tupí usan `guaranies`; los señores de Lasta usan `etiopia`. Adal va como `invasores` porque así lo indica el encargo, pero su IA debería tener nombre y perfil propios cuando `08-ia-rival.md` lo permita (A-003).
- **`jinete` y `arcabucero` del jugador.** Representan la adopción (`03`, fila Adopción): los mapuches reciben jinetes al elegir el toqui de caballería (Curalaba) y los tienen de base en Quilín; los etíopes tienen caballería desde la edad I (matriz); los guaraníes reciben arcabuces por permiso de la Corona (Mbororé) y lanceros a caballo en 1754. Nunca se piden con `entrenar`: siempre llegan por `refuerzos` o como tropa inicial, porque no está confirmado que el jugador pueda producirlos.
- **Equivalencias de prototipo.** Lof = `deposito`; qollqa = `deposito`; pukara y torres de amba o castillo = `torre`; roça y parcela de gult = `granja`; tienda de señor = `casa`; arquero guaraní = `hondero`; cañón de tacuara = `ariete`; obrajes = `hito_economia` del rival; fosos, pozos y estacadas = `empalizada`.
- **Requisitos de la base rival.** Varias misiones piden destruir `granja`, `cuartel` o `hito_economia` del rival (mapuches-2, mapuches-4, tawantinsuyu-4). El escenario tiene que garantizar que esos edificios existan al inicio o que la IA los construya; si el motor no coloca bases prearmadas, hay que agregarlo al formato `[verificar con el motor]`.
- **Objetivos `matar`.** Se validó que la suma de unidades de los eventos `ataque` alcance para cada objetivo `matar` aunque la IA no produzca nada.
- **`proteger`.** Los objetivos principales de tipo `proteger` (guaranies-2, guaranies-4, etiopia-2) hacen perder la misión si cae todo lo de ese tipo; en el resto son secundarios.
- **Palmares y Ayutthaya: facciones y equivalencias.** Holandeses, terços, paulistas, ingenios, franceses y ejércitos toungoo y konbaung van como `invasores`. Igual que Adal, los birmanos deberían tener IA con nombre propio cuando `08` lo permita, porque no son una potencia colonial. Los señores siameses rivales de Taksin usan `ayutthaya`, como Lasta usa `etiopia`. La tropa de Velho no se separa en una facción indígena aparte: su composición va en el nombre del rival. Equivalencias nuevas: mocambo = `deposito`; tenda de ferreiro = `cuartel`; roça = `granja`; cerca y estrepería = `empalizada`; espingardeiro de resgate = `arcabucero` (solo tropa inicial); ingenio = `hito_economia` del rival 3; acolhida = `refuerzos aldeano`; chang suek (elefante de guerra) = `jinete`; compañía *asa* = `arcabucero` (llega por `refuerzos`); barrio extranjero (*ban*) = `casa`; almacén real = `deposito`; fosos y canales (*khu*) = `empalizada`; fuerte de esquina (*pom*) = `torre`. Palmares no recibe `jinete` ni `ariete` (no tuvo caballería y su asedio era casi nulo).
- **Requisitos de base rival (nuevos).** palmares-4 pide un ingenio con `hito_economia` (rival 3); ayutthaya-3 pide al menos 2 `torre` del rival 1 (los fuertes del cerco); ayutthaya-2 y ayutthaya-4 necesitan que la fortaleza de Bangkok y Pho Sam Ton sean hitos. Mismo `[verificar con el motor]` que arriba.
- **Semillas.** Son distintas en las 24 misiones. Los terrenos siguen la mecánica: montaña para red y ambas, bosque para lof y roças, río para el éxodo, Mbororé, los vados y la frontera del Biobío.

## Puntos [verificar]

Afirmaciones que están en los textos de las misiones y no tienen todavía fuente fuerte en los informes. Antes de H3 (voces y arte) deberían revisarlas historiadores y hablantes de cada lengua.

### Tawantinsuyu
- Fecha de la guerra chanka (1438) y nombre de la batalla (Yawarpampa); presencia de Urqon y retiro a Xaquixaguana (Betanzos y Sarmiento difieren).
- Interpretación de los pururawka como ayllus aliados: es una lectura del narrador, no un dato.
- Duración de la guerra de Pambamarca, nombre y fecha de Yawarqocha, y si los caranquis peleaban junto con los cayambes.
- Muerte de Wayna Qhapaq en Tumipampa por una epidemia previa a la llegada española (viruela, c. 1527).
- Detalle de piedras calientes "envueltas en algodón" (Pedro Pizarro) y de los canales de Ollantaytambo (Hemming).
- Que Manco montara a caballo hacia 1538 (informe: confianza media).
- Fecha del ahorcamiento de Arriaga (10 de noviembre de 1780), nombres de los obrajes (Pomacanchi y Parapuquio), papel de Pumakawa en la columna de Sangarará y la fecha de Sangarará (18 de noviembre).
- Fecha y víctimas de la ejecución del 18 de mayo de 1781 (incluido Hipólito).
- Proporción de la mita de Potosí ("uno de cada siete").
- Grafías quechuas: Kusi Yupanki, Wayna Qhapaq, Pumakawa, khipukamayuq, pururawka, Yawarpampa, Yawarqocha.

### Mapuches
- El *pron* como cuerda que cuenta los días para un parlamento (Zavala, Bachraty y Payàs: falta el texto completo).
- Fecha exacta de la muerte de Valdivia (25 de diciembre de 1553 o el 1 de enero de 1554 según la fuente).
- Lemucaguin, Quiapo (1558) y la renuncia a la pólvora: interpretación de Mendoza Pinto y Castro.
- Cantidad de caballos mapuches hacia 1598 y uso de jinetes en Curalaba.
- La ausencia de guardia en el campamento de Óñez de Loyola (tradición historiográfica).
- Lista de las siete ciudades abandonadas y fechas (1599–1604).
- Lientur en Las Cangrejeras (1629) y la captura de Núñez de Pineda y Bascuñán por Maulicán.
- Lincopichón como vocero en Quilín y la fecha de enero de 1641; ratificación de Felipe IV en 1643.
- Grafías: wingka, weichafe, kulliñ, butalmapu, koyagtun, lonko (grafemario sin elegir).

### Guaraníes
- El escribano narrador escribe en guaraní: existen cartas de cabildos guaraníes de 1753, pero hay que confirmar el corpus y su autoría.
- Jefe de la hueste en Lambaré (Juan de Ayolas o Domingo Martínez de Irala) y la cifra de cuatro mil arcos (Schmidl, testigo hostil).
- Ñezú y la muerte de Roque González (1628): usar la fuente indígena, no solo la hagiografía jesuita.
- Si fueron bandeiras de Raposo Tavares y Manuel Preto las que precipitaron el éxodo de 1631; cifra de doce mil personas y cuántos llegaron.
- Cifras de Mbororé (450 paulistas, unos 2.700 tupí, unos 300 arcabuces) y la duración del combate.
- La frase de Sepé ("esta tierra tiene dueño", en guaraní *co yvy oguereco yara*): atribución tradicional, el narrador la marca con "dicen".
- Fecha de muerte de Sepé (7 de febrero de 1756), cifras de Caiboaté y anulación del Tratado de Madrid en 1761 (Tratado de El Pardo).
- Lugar de la defensa de 1754 (vados del Jacuí, Rio Pardo) y presencia de jinetes minuanes y charrúas en ese momento.
- Grafías: tekoha, roça o kokue, mburuvicha, karai, Ñeenguirú, Abiarú.

### Etiopía
- Muerte de Badlay en Gomit (1445) según la crónica de Zara Yaqob.
- La luz en el cielo que dio nombre a Debre Berhan (1456) y la estadía de Zara Yaqob allí.
- La tienda real "en el punto más alto del llano" frente a "sobre una amba" (Álvares contra *EAe*, informe H3 y H6).
- Asaltos a Amba Geshen en 1531 y 1533, caída en 1540, y presencia de arcabuceros árabes u otomanos con el imán en esos años.
- Edad de Galawdewos en 1543, papel de Seble Wongel con los portugueses, cifras de Wofla y Wayna Daga, y que el imán devolviera a los mosqueteros otomanos.
- Quién mató al imán: las fuentes portuguesas y etíopes discrepan, y el texto lo dice así a propósito.
- Bati del Wambara y su venganza (Nur ibn Mujahid, muerte de Galawdewos en 1559).
- La batalla de 1632 que precedió a la abdicación de Susenyos (también en Wayna Daga, según algunas fuentes) y la rebelión de Lasta contra Fasiladas.
- Constructores beta israel de Gondar (informe H35, confianza media).
- Existencia y edición de una crónica de Fasiladas útil como fuente.
- Grafías: kätäma, gult, tabot, Galawdewos, Fasiladas, Seble Wongel.

### Palmares
- Que el mocambo de 1645 fuera el "mocambo do Dambij" y que Dumbi fuera "rey de los Palmares" en esa época (Damasceno; Lara en entrevista, confianza media). La misión no afirma que sean el mismo lugar.
- Cifras del diario de Blaer y Reijmbach (220 casas, iglesia, cuatro herrerías, casa de consejo) y la presencia de guías en la columna: confirmar en el original holandés.
- *Gana* como "señor" en kimbundu y la grafía Aca Inene (Lara, pendiente de lingüistas). El nombre *Angola Janga* no se usa en los textos hasta tener fuente de época.
- Que el "Zambi, general de las armas" de 1675 sea Zumbi: la misión 2 usa el nombre de la fuente y la misión 3 lo llama Zumbi.
- Ubicación de Macaco "al noroeste de Porto Calvo" y de Cucaú "al sur de Sirinhaém" (Lara 2021a, mapas).
- Que en la tropa de Carrilho hubiera "hombres que habían peleado en Angola" (Lara 2021a, n. 81, para las expediciones en general).
- Bajas de 1677 (la reina, dos hijos capturados, cuatro muertos y el maestre de campo), porque la fuente es el autoelogio de Carrilho.
- Comercio de farinha con moradores (Encyclopedia.com; confirmar en Carneiro o Gomes). Se sacó el vino de palma de los objetivos.
- Autoría y método del asesinato de Gana Zumba: se dejan como "dicen".
- Cifras de Cucaú (300 a 400 personas, cerco de tres meses, unos 200 reesclavizados) y la real cédula de 1682.
- Tropa de Velho "sobre todo indígenas y mamelucos" y la participación de Bernardo Vieira de Melo en 1694.
- Cifras de 1694 (232 casas, 40 tiendas de herreros, entre 350 y 500 presos) en Oliveira 2005.
- Fecha y autores de la muerte de Zumbi (20 de noviembre de 1695, tropas de André Furtado de Mendonça) y continuidad de Camuanga.
- La narradora y su familia son ficción situada. Hay que revisar que su cronología cierre (nacida c. 1640, viva c. 1700).

### Ayutthaya
- Caída de 1569 y "quince años" de tributo a Pegu; declaración de independencia de 1584 y su lugar (Khraeng).
- Sitio de Nanda Bayin (diciembre de 1586 a abril de 1587) y retirada por la crecida.
- Nong Sarai: fecha (enero o febrero de 1593), papel de Ekathotsarot y tesis de Terwiel (celo y disparo). Funerales del elefante en 1595 y su título.
- Que en 1592–1593 se enviara una misión de tributo a los Ming: el objetivo `edad 3` lo dice como hito y hay que confirmarlo en el *Ming Shilu*.
- Antigüedad del *Krom Tha Khwa* de Qomi ("casi ochenta años" antes de 1688).
- Bloqueo de la VOC (1663) y tratado de 1664; papel de Phaulkon en el comercio real; llegada de la guarnición francesa a Bangkok (1687) y su salida por acuerdo (noviembre de 1688).
- Embajada de Kosa Pan a Francia (1686). La frase que se le atribuye es inventada para el juego y hay que marcarla así en el documental.
- Muerte de Narai (julio de 1688, Lopburi), golpe de Phetracha, que fuera jefe del departamento de elefantes, y ejecución de Phaulkon y de los herederos.
- Que el puerto "siguió abierto" a chinos y holandeses después de 1688 (debate del aislamiento, Baker y Phongpaichit).
- Revuelta makasar de 1686 y que hubiera marinos makasares con Taksin.
- Generales birmanos de 1765–1767 (Maha Nawrahta, Ne Myo Thihapate), los 27 fuertes, los túneles y el fuego en los cimientos, la defensa de chinos y portugueses y la caída del 7 de abril de 1767.
- Ruptura del cerco de Phraya Tak en enero de 1767 ("unos pocos cientos"), Chanthaburi en junio, cinco mil hombres en octubre, guarnición birmana de Thonburi, campamento de Pho Sam Ton y coronación del 28 de diciembre de 1767.
- Rechazo Qing de 1768 y tatuaje de los *phrai* bajo Taksin (Akin Rabibhadana).
- Señores rivales de Phitsanulok, Phimai y Fang después de 1767.
- Grafías RTGS: phrai, munnai, sakdina, phaniat, Phra Khlang, uparat, Ekkarat, Ekathotsarot, Phetracha, Kosa Pan, Pho Sam Ton.

## Pendientes

- Decidir si la intro y el epílogo se leen con voz (H3) y en qué lengua: se sugiere narración en castellano con nombres y frases cortas en la lengua propia, grabadas por hablantes.
- Cuando existan los módulos reales (mit'a, lof, tekoha, kätäma), reemplazar las equivalencias de prototipo por tipos propios sin tocar los textos.
- A-004 (misión o monte): la campaña guaraní no la resuelve. Muestra las dos ramas en la historia, sin convertir ninguna en la "correcta".
