# Consultas

Preguntas concretas para el autor. Contestá debajo de cada una, en la línea **Respuesta:**, con una letra o una palabra. Se revisan en cada push.

Mientras no haya respuesta, sigo con la opción marcada como *(por defecto)*.

---

### C-01 · Nombre del juego (A-005)
a) Proyecto Sur *(por defecto)* · b) Tierra Adentro · c) Raíces · d) Otro: escribilo

**Respuesta:** c) **Raíces** (2026-11-13). Aplicado: el juego se llama Raíces en el menú, el proyecto, el README y los documentos (D-029).

### C-02 · Civilizaciones nuevas
Elegí Quilombo dos Palmares (Brasil) y Ayutthaya (Siam). ¿Te van?
a) Sí *(por defecto)* · b) Cambiar Palmares por tupinambá · c) Cambiar Ayutthaya por maratas (India)

**Respuesta:** a) Están bien (2026-11-13).

### C-03 · Imágenes generadas por IA
Para retratos y láminas de campaña puedo usar generación de imágenes, o quedarme con arte procedural y libre (CC0).
a) Solo procedural y CC0 *(por defecto)* · b) Generadas por IA, marcadas como tales

**Respuesta:** b, con Meshy (respondido en el chat el 2026-11-13). Se usa con un tope de unos 400 créditos; ver C-05.

### C-04 · Música
Si no aparece música libre que suene a estas regiones:
a) Solo ambiente y efectos, sin música *(por defecto)* · b) Música procedural simple generada por el juego

**Respuesta:** "Consigamos lo que podamos". Se busca más música libre que suene a cada región; el autor va a opinar cuando escuche lo que hay.

### C-05 · Presupuesto de Meshy
El saldo (1.442 créditos) se comparte con apex-open. Usé hasta unos 400: láminas de civilización y de campaña, más los modelos 3D clave. ¿Gasto más para modelar todas las unidades y edificios?
a) No, con eso alcanza *(por defecto)* · b) Sí, hasta ___ créditos más

**Respuesta:** "Gastá lo necesario, de la forma más eficiente posible; los créditos se renuevan una vez al mes" (2026-11-13).

### C-06 · ¿Terreno ahora o cerrar pendientes?
a) Arrancar ya con el plan de terreno y mapas (`docs/10`) · b) Cerrar antes balance e IA

**Respuesta:** a) "Continuá acorde al plan con todo el trabajo" (2026-11-13). Etapa 10 en `proceso/`.

### C-07 · ¿Aceptamos música con licencia CC BY-SA?
Hay buenas grabaciones de siku y sikuri para Tawantinsuyu en Wikimedia, pero son CC BY-SA. Esa licencia obliga a dar crédito y a compartir con la misma licencia cualquier cambio que se haga a la pista, no al juego. Hoy solo se usa CC0 y dominio público.
a) Sí, con crédito *(por defecto)* · b) No, solo CC0

**Respuesta:**

### C-08 · La pifilka mapuche tiene uso ceremonial (ngillatun)
Las grabaciones las publicó el propio intérprete en dominio público, pero suenan en el combate.
a) Dejarla solo en el menú o en la paz, no en el combate *(por defecto)* · b) Dejarla como está · c) Sacarla

**Respuesta:**

### C-09 · ¿Quedaron bien la escala y la velocidad?
Ahora una casa mide unas tres veces un aldeano y todos andan un 10 % más lento. Para probarlo, jugá a velocidad ×1, no con el autotest, que corre a ×4.
a) Están bien · b) Aldeanos todavía grandes · c) Todavía rápidos · d) Ahora demasiado lentos

**Respuesta:**

### C-10 · Modelo de la riqueza (resumen en `docs/diseno/revision-economia/00-sintesis.md`)
a) "Una riqueza, seis motores": un solo recurso, con nombre e ícono por civ, y que cada civ produce con su propio motor pacífico desde la edad I *(recomendado)* · b) Solo cambiar la imagen y los nombres, sin tocar las reglas · c) Un cuarto recurso distinto para cada civ

**Respuesta:**

### C-11 · ¿Qué hay junto a cada base?
a) Una salina chica que se agota, más el paisaje propio de la civ; nada dorado *(recomendado)* · b) Dejar los dos yacimientos, pero con otro aspecto · c) Nada común: solo el motor propio

**Respuesta:**

### C-12 · Kulliñ mapuche
a) El kulliñ pasa a ser la riqueza mapuche: el ganado crece en el corral y el botín que supera el tope se vuelve riqueza *(recomendado)* · b) Mantenerlos separados, como hoy

**Respuesta:**

### C-13 · ¿Arranco ya con los arreglos "sin arrepentimiento"?
Son la IA mapuche, la campana, la vida de los edificios mapuches, el costo del gult, los colores y el tooltip de riqueza. Valen para cualquier modelo.
a) Sí, mientras decidís el resto *(recomendado)* · b) No, esperá

**Respuesta:**

> **C-10 a C-12 quedan reemplazadas** por las preguntas del diseño final de la ronda 3 (C-14 a C-20). Resumen en palabras llanas al principio de [`docs/diseno/revision-economia/v3/04-diseno-final.md`](../docs/diseno/revision-economia/v3/04-diseno-final.md).

### C-14 · ¿Cómo medimos que el esfuerzo sea parejo?
a) Umbrales absolutos: como máximo 0,6 órdenes por minuto y 2 pendientes cada 10 minutos por civ, y ninguna por encima de 1,5 veces la mediana *(recomendado)* · b) ×1,5 entre la que más y la que menos pide (falla porque guaraníes y Palmares piden muy poco)

**Respuesta:**

### C-15 · Costo del avance a la edad II
a) 500 de alimento + 300 de riqueza, y se mide con la IA real; si pasa de los 9:00, vuelve a 400 + 250 *(recomendado)* · b) Dejarlo en 400 + 200 (algunas civs llegan antes de los 6:30)

**Respuesta:**

### C-16 · Cuando se acaba la arcilla de casa (minutos 13 a 24), el ingreso de riqueza cae a la mitad
a) Aceptarlo: el final se pelea en el centro, con tope *(recomendado)* · b) Agregar una veta lenta en el flanco

**Respuesta:**

### C-17 · Etiopía en escaramuza: ¿la corte "se funda" en otro lugar en vez de viajar como carpa?
a) Sí: sin carpa vulnerable ni derrota por empacar; la carpa queda para la campaña *(recomendado)* · b) Volver a la carpa que viaja

**Respuesta:**

### C-18 · ¿Ayutthaya sin depósitos comunes, con el elefante del rey como depósito?
a) Sí *(recomendado)* · b) Que pueda construir depósitos comunes

**Respuesta:**

### C-19 · Mapuches: si pierden la arcilla de casa en el minuto 10, conservan el 29 % del ingreso de riqueza (no atrasan la edad)
a) Aceptarlo como el precio de "no hay capital" y mirarlo en el torneo *(recomendado)* · b) Abaratar el lof de flanco de 110 a 80 de madera

**Respuesta:**

### C-20 · Cambiar las frases de Palmares ("se esconde") y Ayutthaya ("comercia con el mundo"), que contradicen el diseño
a) Sí, con las propuestas de la sección 11 del diseño final *(recomendado)* · b) Dejarlas

**Respuesta:**

### C-21 · ¿La IA "Pacífica" puede ganar por sitios sagrados?
Hoy controla el mapa y toma sitios, así que puede ganar por ellos sin atacarte.
a) Sí, es parte de su juego: los sitios hay que disputarlos *(recomendado)* · b) No: toma sitios pero no cuenta para su victoria · c) No toma sitios

**Respuesta:**

### C-22 · (interfaz, parte B) Misión mapuche 2: se arranca con población 33/8
El malón trae 10 aldeanos y 22 guerreros con un lof que da 8 de tope. Hoy se explica con un aviso al empezar ("hay más gente que lugar: construí casas"). El motor de escenarios no puede dar casas al jugador.
a) Dejarlo explicado: es un malón, no hace falta entrenar *(recomendado)* · b) Que el motor de escenarios pueda dar rukas al jugador desde los datos de la misión · c) Bajar las tropas iniciales hasta entrar en el tope

### C-23 · (interfaz, parte A) Paleta apta para daltonismo: ¿rojo de equipo puro y alimento frambuesa?
Para que equipos y recursos se distingan también con daltonismo (`proceso/17-interfaz-segunda-tanda/01-escala-paleta-opciones.md`, paso 2), el jugador 2 pasó de rojo terracota a rojo puro, el alimento de rojo a frambuesa y la riqueza de dorado a amarillo dorado. Los equipos 3 y 4 son violeta y ciruela (antes verde y ocre).
a) Dejarlo así *(recomendado)* · b) Volver al terracota para el jugador 2 aunque se confunda con el alimento (ΔE 11) · c) Otra combinación (decir cuál)

### C-24 · (arte) Música para Etiopía: no hay grabaciones CC0 ni de dominio público (etapa 19)
Se revisaron Wikimedia Commons, Internet Archive (también la colección de discos de 78 rpm) y OpenGameArt; Freesound no permite descargar sin cuenta. Lo único etíope que apareció es CC-BY-SA (escala de begena, entrevistas de qene), está mal licenciado (discos comerciales subidos como CC0) o es un registro etnográfico o litúrgico (zema de estudiantes de Debre Libanos; Courlander, 1951; Leslau). Detalle en `proceso/19-arte-y-sonido/01-modelos-y-musica.md`.
a) Seguir con las pistas genéricas hasta conseguir algo propio *(recomendado)* · b) Encargar o grabar krar y masenqo con licencia propia · c) Aceptar CC-BY-SA para la música (obliga a compartir esas pistas con la misma licencia)

**Respuesta:**

### C-25 · (jugabilidad) Ayutthaya y el almacén de arcilla
La economía v3 dice que Ayutthaya no construye depósito: todo lo cobra el elefante. Tu ejemplo del almacén de arcilla junto a la arcilla le cabe justo. Propuesta: darle el *khlang din* (almacén solo de arcilla), sin tocar el cobro del elefante (`docs/diseno/jugabilidad/03-propuesta.md` §2.2).
a) Darle el khlang din *(por defecto)* · b) Dejarla sin almacenes

**Respuesta:**

### C-26 · (jugabilidad) Mapuches: el lof como único almacén
Los mapuches no levantarían almacenes baratos por recurso: llevan todo al lof (la comunidad familiar). Es parte de su identidad móvil, y además les baja el 68 % del torneo.
a) El lof como único almacén *(por defecto)* · b) Darles almacenes como al resto

**Respuesta:**

### C-27 · (jugabilidad) Orden de la formación
AoE4 pone la caballería adelante. La propuesta pone adelante la línea (lanceros), después el choque, la distancia y el asedio, y a los montados en las alas, siguiendo nuestro triángulo de contadores (D-007).
a) Nuestro orden *(por defecto)* · b) Como AoE4

**Respuesta:**

### C-28 · (jugabilidad) ¿Desde qué distancia los aldeanos van en bloque?
Hasta 16 casillas cada aldeano va por su cuenta, corriendo al trabajo. Más lejos van en bloque y se esperan, y se sueltan a 6 casillas del destino. El 16 sale de que los recursos de casa están entre 7 y 15 casillas del centro. Se cambia en el dato.
a) 16 casillas *(por defecto)* · b) Menos, para ver el bloque también en viajes medianos (decir cuánto)

**Respuesta:**

### C-29 · (jugabilidad) El ariete frena al ejército
Con velocidad común, un ejército con ariete marcha a la velocidad del ariete (un 47 % más lento que los lanceros), como en AoE4.
a) Aceptarlo y medir *(por defecto)* · b) Que el asedio marche aparte

**Respuesta:**

### C-30 · (jugabilidad) Nombres en lenguas originarias sin fuente
La propuesta nombra almacenes y edificios militares de cada pueblo, y algunos nombres están marcados `[verificar]` porque no se encontró fuente.
a) Ponerlos y corregir cuando aparezca la fuente *(por defecto)* · b) Usar nombres en castellano hasta tener fuente

**Respuesta:**

### C-31 · (jugadores de prueba) Contadores más blandos para que la micro pague
Hoy un contador multiplica el daño por 2 o por 2,25. El jugador veterano midió que 10 guerreros le ganan a 10 honderos perdiendo una sola unidad, y que kitear o concentrar el fuego no cambia nada (`proceso/22-testers/01-veterano-aoe4.md`). En AoE4 los bonos son más chicos y la micro decide más.
a) Bajar a ×1,5–×1,75 y rebalancear con torneo *(por defecto, recién después de cerrar el balance actual)* · b) Dejar los contadores fuertes: la composición decide, no la micro

**Respuesta:** a) Sí, como AoE4: bonos planos por clase y armadura separada contra cuerpo a cuerpo y contra distancia (2026-11-15: "Me gustó todo lo sugerido para hacerlo más como AoE4, vayamos por ahí, siempre manteniendo identidad del sur global y las peculiaridades de cada civ"). Etapa 23.

### C-32 · (jugadores de prueba) Comida temprana con decisiones
La edad I tiene 8 arbustos y nada más: no hay caza ni ganado, las granjas llegan a los 4 minutos (en AoE4, entre los 7 y los 10) y el explorador no tiene trabajo. Propuesta: animales que el explorador arrea (llamas, guanacos, cabras, búfalos según el pueblo y el terreno) y caza mayor que se defiende.
a) Sí, con animales propios de cada región *(por defecto)* · b) No: la edad I corta es una decisión del juego

**Respuesta:** a) Sí: animales por región para arrear y caza que pelea, como las ovejas, ciervos y jabalíes de AoE4 (2026-11-15). Etapa 23.

### C-33 · (jugadores de prueba) Tiempo de obra de los hitos
Un hito se levanta en 41–53 s con tres constructores; en AoE4 son unos 190 s. Así no hay ventana de riesgo y no importa dónde se pone.
a) Subir a 120–150 s y medir las edades de nuevo *(por defecto)* · b) Dejarlo rápido

**Respuesta:** a) Sí: obra de los hitos como AoE4 (190/220/250 s) y auras que dependen del lugar (2026-11-15). Etapa 23.

### C-34 · (jugadores de prueba) ¿Qué va primero?
La síntesis (`proceso/22-testers/00-sintesis.md`) ordena: 1) errores que arruinan partidas (sitios faltantes, fortines sin peleas, aliado que no defiende, IA fácil, tutorial trabado); 2) sensación de juego (contadores, comida temprana, hitos); 3) aprender a jugar; 4) identidad (rivales propios, voces, aspecto por edad); 5) partidas de varios.
a) Ese orden *(por defecto)* · b) Otro (decir cuál)

**Respuesta:** a) Ese orden, en dirección AoE4 sin perder la identidad de cada pueblo (2026-11-15). Plan en `proceso/23-como-aoe4`.

### C-35 · (historia) Nombre de la edad IV del Tawantinsuyu: "Inkarri"
El mito de Inkarrí se documenta sobre todo en el siglo XX (Arguedas lo recogió en Puquio en 1956), aunque se lo vincula con el Taki Onqoy y con la muerte de Túpac Amaru I (1572). La edad IV cubre Vilcabamba (1537–1572) y Tinta (1780). Ya la investigación lo había dejado como "a consultar" (`docs/investigacion/tawantinsuyu.md`, punto 9). Sus dos hitos son Qorikancha y Vilcabamba.
a) Dejar Inkarri y explicarlo en el panel del pueblo como un guiño al arco de la campaña, no como un nombre de época *(por defecto)* · b) *Vilcabamba* (choca con el nombre del hito militar) · c) *Neo Inka* · d) Otro (escribilo)

**Respuesta:**

### C-36 · (historia) El Qorikancha como hito de la edad IV inca
El Qorikancha lo reconstruyó Pachakutiq hacia 1438: como obra de la última edad es anacrónico. Moverlo a la edad II o III cambia los hitos y, por lo tanto, el balance del Tawantinsuyu, que está en revisión (parte A).
a) Cambiarle el nombre a la opción económica de la edad IV (por ejemplo, *Wak'a rehenes* o *Huacas del Cusco*), sin tocar sus números *(por defecto)* · b) Pasarlo a la edad III y llevar el aqllawasi o la kallanka real a la IV (rebalancea) · c) Dejarlo así

**Respuesta:**

### C-37 · (historia) Orden de las edades guaraníes y "Amundá"
Los datos dicen *Tekoha → Amundá → Mbororé → Tava*. La investigación propone *Tekoha → cuñadazgo y conquista → Tava o monte → Mbororé y Guerra Guaranítica* (`docs/investigacion/guaranies.md`, "Periodización"). En los datos, la bifurcación misión o monte está en el avance a la III y los hitos de la IV (*Tava fortificada* y *Ñande retã*) son de la Guerra Guaranítica, así que el orden de los datos tiene lógica, pero termina en "Tava" y se lee como si la meta fuera reducirse. Además, **"Amundá" no tiene fuente ni explicación** en ningún documento.
a) *Tekoha → Tovaja (cuñadazgo) → Mbororé → Ñande retã* (la III es la de Mbororé, 1641, y la IV, la de 1754–1756) *(por defecto)* · b) Seguir la investigación: III *Tava ha ka'aguy* (pueblo y monte), IV *Mbororé* · c) Dejarlo así y explicarlo en el panel. En cualquier caso, ¿de dónde sale "Amundá"? [verificar *tovaja* con un hablante]

**Respuesta:**

### C-38 · (historia) "Cucaú o Quilombo" como nombre de la edad IV de Palmares
Se lee como una opción de menú, no como un nombre. La edad IV es la bifurcación entre el *Pacto de Cucaú* (Gana Zumba, 1678) y la *Guerra de Zumbi*, y esas ya son sus dos opciones de hito.
a) Un solo nombre: *Macaco* (la cerca real de la Serra da Barriga, donde siguió Zumbi) *(por defecto)* · b) *1678* · c) *Angola Janga* para la IV y otro nombre para la III · d) Dejarlo y explicar la bifurcación en el panel

**Respuesta:**

### C-39 · (textos) Palabras en portugués en los textos en castellano
Cambié "roças" por "rozas", "milho" por "maíz" y "farinha" por "fariña" (castellano del litoral) en las campañas de Palmares y guaraníes, porque tienen palabra propia en castellano. Dejé las que nombran instituciones o lugares sin equivalente (*mocambo*, *quilombo*, *terço*, *morador*, *bandeira*). Queda "la mata" en Palmares (en castellano rioplatense, "mata" es un arbusto; sería "el monte").
a) Ese criterio, y "la mata" pasa a "el monte" *(por defecto)* · b) Volver al portugués de época, siempre en cursiva y con un glosario en el juego · c) Ese criterio, pero "la mata" se queda (es la *mata atlántica*)

**Respuesta:**

### C-40 · (historia) Rivales con civilización propia: ¿alcanza o separamos más?
La parte D sumó seis civs solo de IA: Adal, Birmania (Toungoo y Konbaung juntos), chankas, caranquis y cayambes, cañaris y tupíes (`proceso/23-como-aoe4/04-rivales-propios.md`). Quedan con la civ del jugador las milicias de Pumakawa (incas), los señores de Lasta (etíopes) y los señores de Phitsanulok, Phimai y Fang (siameses), que sí son del mismo pueblo. Los holandeses, franceses, paulistas y la tropa de Jorge Velho siguen como `invasores`.
a) Así *(por defecto)* · b) Separar también a los europeos por potencia (Castilla, Portugal, Países Bajos, Francia), con nombres de edad propios en vez de *Virreinato* para todos

**Respuesta:**
