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

### C-35 · (órdenes) Teclas de los marcadores de cámara
AoE4 guarda la cámara con Ctrl + F1…F8. Acá F1–F6 abren los paneles y F10 es la pausa, así que los marcadores quedaron en Ctrl + F7…F9 (tres). Detalle en `proceso/23-como-aoe4/02-ordenes-y-comodidades.md`.
a) Dejar F7–F9 *(por defecto)* · b) Pasar los paneles a otras teclas y usar F1–F4 para la cámara, como AoE4

### C-36 · (órdenes) ¿Cuánto da la IA aliada cuando le piden?
Hoy da 200 si después le quedan 300 (`reglas.json → equipos.pedido`), y a una bengala manda la mitad de su ejército libre, con un mínimo de 3 (`equipos.bengala`). Un aliado muy generoso se queda sin ejército; uno muy tacaño parece que no escucha.
a) Así *(por defecto)* · b) Más generosa (todo lo que le sobre, el ejército entero) · c) Más prudente (solo si no la están atacando)

### C-37 · (aprender a jugar) ¿Con qué pueblo se aprende?
El tutorial usa a los guaraníes, que no tienen torre, granero ni depósito, y cuyos edificios tienen nombre propio (Oga, Aty, Kokue). El jugador nuevo pidió aprender con un pueblo "más normal" (`proceso/22-testers/02-nuevo-en-rts.md`).
a) Dejar a los guaraníes: los nombres propios con el común debajo ya se entienden *(por defecto)* · b) Pasar el tutorial a Tawantinsuyu, que tiene todos los edificios comunes

**Respuesta:**

### C-38 · (aprender a jugar) "Arte de la guerra"
AoE4 tiene misiones cortas de una sola idea (economía temprana, defensa, contadores, sitios, asedio) con medalla de bronce, plata y oro. El motor de escenarios ya alcanza para hacerlas (objetivos `juntar`, `sitio`, cuentas y ataques con aviso).
a) Sí, cinco misiones cortas con medallas por tiempo, después de la etapa 23 *(por defecto)* · b) No por ahora

**Respuesta:**


### C-39 · (historia) Nombre de la edad IV del Tawantinsuyu: "Inkarri"
El mito de Inkarrí se documenta sobre todo en el siglo XX (Arguedas lo recogió en Puquio en 1956), aunque se lo vincula con el Taki Onqoy y con la muerte de Túpac Amaru I (1572). La edad IV cubre Vilcabamba (1537–1572) y Tinta (1780). Ya la investigación lo había dejado como "a consultar" (`docs/investigacion/tawantinsuyu.md`, punto 9). Sus dos hitos son Qorikancha y Vilcabamba.
a) Dejar Inkarri y explicarlo en el panel del pueblo como un guiño al arco de la campaña, no como un nombre de época *(por defecto)* · b) *Vilcabamba* (choca con el nombre del hito militar) · c) *Neo Inka* · d) Otro (escribilo)

**Respuesta:**

### C-40 · (historia) El Qorikancha como hito de la edad IV inca
El Qorikancha lo reconstruyó Pachakutiq hacia 1438: como obra de la última edad es anacrónico. Moverlo a la edad II o III cambia los hitos y, por lo tanto, el balance del Tawantinsuyu, que está en revisión (parte A).
a) Cambiarle el nombre a la opción económica de la edad IV (por ejemplo, *Wak'a rehenes* o *Huacas del Cusco*), sin tocar sus números *(por defecto)* · b) Pasarlo a la edad III y llevar el aqllawasi o la kallanka real a la IV (rebalancea) · c) Dejarlo así

**Respuesta:**

### C-41 · (historia) Orden de las edades guaraníes y "Amundá"
Los datos dicen *Tekoha → Amundá → Mbororé → Tava*. La investigación propone *Tekoha → cuñadazgo y conquista → Tava o monte → Mbororé y Guerra Guaranítica* (`docs/investigacion/guaranies.md`, "Periodización"). En los datos, la bifurcación misión o monte está en el avance a la III y los hitos de la IV (*Tava fortificada* y *Ñande retã*) son de la Guerra Guaranítica, así que el orden de los datos tiene lógica, pero termina en "Tava" y se lee como si la meta fuera reducirse. Además, **"Amundá" no tiene fuente ni explicación** en ningún documento.
a) *Tekoha → Tovaja (cuñadazgo) → Mbororé → Ñande retã* (la III es la de Mbororé, 1641, y la IV, la de 1754–1756) *(por defecto)* · b) Seguir la investigación: III *Tava ha ka'aguy* (pueblo y monte), IV *Mbororé* · c) Dejarlo así y explicarlo en el panel. En cualquier caso, ¿de dónde sale "Amundá"? [verificar *tovaja* con un hablante]

**Respuesta:**

### C-42 · (historia) "Cucaú o Quilombo" como nombre de la edad IV de Palmares
Se lee como una opción de menú, no como un nombre. La edad IV es la bifurcación entre el *Pacto de Cucaú* (Gana Zumba, 1678) y la *Guerra de Zumbi*, y esas ya son sus dos opciones de hito.
a) Un solo nombre: *Macaco* (la cerca real de la Serra da Barriga, donde siguió Zumbi) *(por defecto)* · b) *1678* · c) *Angola Janga* para la IV y otro nombre para la III · d) Dejarlo y explicar la bifurcación en el panel

**Respuesta:**

### C-43 · (textos) Palabras en portugués en los textos en castellano
Cambié "roças" por "rozas", "milho" por "maíz" y "farinha" por "fariña" (castellano del litoral) en las campañas de Palmares y guaraníes, porque tienen palabra propia en castellano. Dejé las que nombran instituciones o lugares sin equivalente (*mocambo*, *quilombo*, *terço*, *morador*, *bandeira*). Queda "la mata" en Palmares (en castellano rioplatense, "mata" es un arbusto; sería "el monte").
a) Ese criterio, y "la mata" pasa a "el monte" *(por defecto)* · b) Volver al portugués de época, siempre en cursiva y con un glosario en el juego · c) Ese criterio, pero "la mata" se queda (es la *mata atlántica*)

**Respuesta:**

### C-44 · (historia) Rivales con civilización propia: ¿alcanza o separamos más?
La parte D sumó seis civs solo de IA: Adal, Birmania (Toungoo y Konbaung juntos), chankas, caranquis y cayambes, cañaris y tupíes (`proceso/23-como-aoe4/04-rivales-propios.md`). Quedan con la civ del jugador las milicias de Pumakawa (incas), los señores de Lasta (etíopes) y los señores de Phitsanulok, Phimai y Fang (siameses), que sí son del mismo pueblo. Los holandeses, franceses, paulistas y la tropa de Jorge Velho siguen como `invasores`.
a) Así *(por defecto)* · b) Separar también a los europeos por potencia (Castilla, Portugal, Países Bajos, Francia), con nombres de edad propios en vez de *Virreinato* para todos

**Respuesta:**

### C-45 · (opciones de partida) Recursos medios y altos
Hoy son 500/500/300/300 y 1000/1000/700/700 (alimento, madera, piedra, riqueza), parecidos a los de AoE2 (`proceso/24-tras-la-segunda-ronda/4b-opciones-de-partida.md`).
a) Esos *(por defecto)* · b) Otros (decí cuáles)

**Respuesta:**

### C-46 · (opciones de partida) Ubicación de los equipos por defecto
Ahora el 2v2 y el 3v3 del menú arrancan con los aliados juntos, como el lobby de AoE4. Antes quedaban mezclados por el orden de los lugares.
a) Juntos *(por defecto)* · b) Mezclados

**Respuesta:**

### C-47 · (opciones de partida) Empate al tiempo límite
Si al cumplirse el tiempo los puntos empatan, hoy no gana nadie y la pantalla dice "Empate".
a) Empate *(por defecto)* · b) Desempate por edificios en pie o por sitios

**Respuesta:**

### C-48 · (opciones de partida) Conquista sin hitos: ¿cuentan las unidades?
Con "Hitos: no", pierde quien se queda sin edificios terminados. No cuentan muros, puertas ni caminos; sí granjas, casas y almacenes.
a) Solo edificios *(por defecto)* · b) También las unidades, como algunos modos de AoE4 (se alarga la caza del último aldeano)

**Respuesta:**

### C-49 · (opciones de partida) Hitos apagados sin tiempo límite
En 4 partidas de IA contra IA de hasta 45 minutos, sin hitos ni sitios, la IA nunca termina la conquista (al mapuche le quedaban 41 edificios).
a) El menú sugiere un tiempo límite al apagar "Hitos", y la IA aprende a cazar los últimos edificios en el paso de la IA experta *(por defecto)* · b) Solo mejorar la IA

**Respuesta:**

### C-50 · (opciones de partida) Opciones del lobby de AoE4 que faltan
Faltan maravilla (no existe todavía), edad inicial, población máxima y "revelar mapa".
a) Población máxima y revelar mapa ahora; edad inicial y maravilla después *(por defecto)* · b) Ninguna por ahora · c) Todas

**Respuesta:**

### C-51 · (IA experta) ¿Tiene que ganarle a la difícil?
La experta llega a 100 aldeanos a los 25 minutos en tres civs y levanta un segundo o tercer centro, pero contra la difícil pierde 2 de 6 partidas, gana 1 y 3 quedan abiertas a los 25 minutos. Su economía grande llega tarde: a los 10–15 minutos tiene igual o menos ejército (`proceso/24-tras-la-segunda-ronda/4a-ia-experta.md`).
a) Otro paso de ajuste con torneo de la experta contra la difícil *(por defecto)* · b) Dejarla así por ahora

**Respuesta:**

### C-52 · (IA experta) ¿Cuenta para el balance?
El torneo de balance se juega con la normal. Palmares no crece con centros sino con la fama, así que con la experta queda abajo por diseño.
a) El balance se mide con la normal, y la experta solo se revisa para que ninguna civ quede inútil *(por defecto)* · b) Sumar un torneo con la experta y balancear también ahí

**Respuesta:**

### C-53 · (sonido) El kultrun en el juego
El sonido mapuche (fanfarria, alarma y órdenes) usa kultrun y trutruka sintetizados (`proceso/24-tras-la-segunda-ronda/4g-sonido.md`). El kultrun es un instrumento ceremonial de la machi. Ya estaba pendiente consultar la pifilka.
a) Dejarlo, y consultarlo con una organización mapuche junto con la pifilka antes de publicar *(por defecto)* · b) Usar solo la trutruka hasta tener esa consulta

*Mientras tanto se aplicó la opción b), la prudente (paso 4h, a pedido del jugador de historia en la ronda 3). Si contestás a), se vuelve: los modelos están en `456a59b`.*

**Respuesta:**

### C-54 · (sonido) La begena en la música de paz etíope
La música nueva de Etiopía (C-24) abre y cierra con begena, el arpa de la oración ortodoxa. Solo suena en la paz, nunca en combate ni en alarmas, y no hay voces ni nada que imite el zema.
a) Así, y consultarlo con alguien de la tradición ortodoxa etíope antes de publicar *(por defecto)* · b) Reemplazar la begena por krar, que es profano

*Mientras tanto se aplicó la opción b), la prudente (paso 4h, a pedido del jugador de historia en la ronda 3). Si contestás a), se vuelve: los modelos están en `456a59b`.*

**Respuesta:**

### C-55 · (sonido) El berimbau en Palmares
El sonido de Palmares usa berimbau y atabaque. El berimbau de arco con calabaza está documentado en Brasil sobre todo desde el siglo XIX [verificar]; en el Palmares del siglo XVII podría ser un anacronismo.
a) Dejarlo: es el instrumento afrobrasileño que más se reconoce *(por defecto)* · b) Solo atabaque y agogô

*Mientras tanto se aplicó la opción b), la prudente (paso 4h, a pedido del jugador de historia en la ronda 3). Si contestás a), se vuelve: los modelos están en `456a59b`.*

**Respuesta:**

### C-56 · (sonido) Mbaraka y takuapu guaraníes
Son instrumentos rituales del opy mbyá. Desde el paso 4h no suenan en la tropa: en su lugar, mimby (flauta de caña) y angu'apu (tambor de tronco), según Montoya, 1639 [verificar].
a) Así, hasta consultar con una organización mbyá *(por defecto)* · b) Volver a la mbaraka

**Respuesta:**

### C-57 · (sonido) La música de paz de Palmares
Tiene dos grabaciones de berimbau con toques de capoeira y una de ijexá (un ritmo del candomblé). El sonido de tropa ya es de raíz angoleña (paso 4h).
a) Dejarlas hasta tener una música propia sintetizada de ngoma y marimba *(por defecto)* · b) Sacarlas ya

*Aplicada la b) por la revisión histórica (etapa 25): la música de paz de Palmares quedó sin pistas propias. Si contestás a), se revierten dos líneas de `audio.gd`.*

**Respuesta:**

### C-58 · (sonido) El kebero etíope en la fanfarria, la alarma y el entrenado
El kebero también es tambor litúrgico [verificar]. La orden ya pasó al krar.
a) Dejarlo y preguntarlo junto con C-54 *(por defecto)* · b) Sacarlo también de esos tres

**Respuesta:**

### C-59 · (sonido) *Phleng Maha Nimit* en la música de Ayutthaya
Podría ser del repertorio ceremonial naphat [verificar].
a) Dejarla hasta confirmar *(por defecto)* · b) Sacarla

**Respuesta:**

### C-60 · (arte) La mbaraka del karai en el hito guaraní
El hito "Casa del karai" muestra bastones con plumas y una mbaraka (`data/arte_hitos.json`).
a) Dejarlo: es la casa del karai, donde corresponde *(por defecto)* · b) Sacar la mbaraka del modelo

**Respuesta:**

### C-61 · (IA fácil) Un solo ataque
La fácil tiene tope de 15 soldados, pero la segunda oleada pide 18 (12 + 6). Si la primera se traba, no vuelve a atacar y a veces la partida no termina (`proceso/24-tras-la-segunda-ronda/4j-jugador-nuevo-ronda-3.md`).
a) Bajar el paso de la oleada de la fácil para que ataque varias veces, con oleadas chicas: el principiante tiene un segundo ataque que rechazar *(por defecto)* · b) Subir su tope de ejército

**Respuesta:**

### C-62 · (sitios) Captura que se vacía sola
Hoy un sitio guarda lo que lleva de captura aunque el que lo toma se vaya, y varias pasadas cortas suman los 10 s. En AoE4, la captura se vacía de a poco sin nadie. Cambiaría la regla para todos y el balance.
a) Que se vacíe de a poco, como AoE4, medido con torneo *(por defecto)* · b) Dejarlo como está

**Respuesta:**

### C-63 · (menú) Sitios apagados para la IA contra IA
La primera partida en Fácil arranca con los sitios apagados. En IA contra IA, desde el menú, la opción depende de la dificultad elegida para el jugador.
a) Que IA contra IA siempre arranque con los sitios prendidos *(por defecto)* · b) Igual que la partida normal

**Respuesta:**

### C-64 · (combate) La micro: que la mezcla de línea y distancia pague
El veterano lo pide por tercera ronda. El estudio (`proceso/24-tras-la-segunda-ronda/5a-micro-estudio.md`) encontró dos causas. El guerrero común corre más que el hondero (1600 contra 1250), así que funciona como un jinete a pie y no se lo puede kitear. Y el hondero casi no le hace daño. Lo que ya paga: la línea mantiene y la distancia escalona detrás.
- Con a), 5 lanceros + 5 honderos sin micro pasan de ganar 1 de 5 a ganar 5 de 5 contra 10 guerreros, y los honderos que escalonan quedan con 5,2 vivos.
- El weichafe, el jinete noble y el jinete conservan su velocidad.

a) Guerrero común a 1350 y la línea +6 contra el choque (antes +5), como el hombre de armas de AoE4, medido con torneo *(por defecto)* · b) Solo la línea +10 contra el choque · c) Un hostigador montado por pueblo (pide modelo, edificio e IA) · d) Dejarlo así y enseñar en el juego la micro que ya paga

**Respuesta:**

### C-65 · (escala) Velocidad de las unidades
Del análisis de escala del veterano (`proceso/22-testers/ronda-4/03-escala-veterano.md`): el aldeano anda a 1,86 m/s, un trote, cerca de 35 % más rápido que en AoE4 en relación con su cuerpo. Con la persona más chica (paso 1, solo vista) va a parecer más rápido todavía. Bajar `velocidad_pct` de 90 a 72 cambia toda la simulación: viajes, economía, llegada de ataques y micro.
a) Bajarla a 72 con un torneo de 10 semillas solo para eso, y mirarlo vos a ×1 *(por defecto)* · b) Probar 80 · c) Dejarla

**Respuesta:** c) Dejarla. El autor (2026-11-16): "¿Era solo un tema visual? Ignoremos entonces, porque necesitamos eventualmente hacer animaciones para los modelos que logremos generar, así que hasta que podamos no vale la pena." Se retoma con las animaciones de los modelos.

### C-66 · (escala) Huellas del centro y los hitos
En AoE4 el centro y los hitos dominan la ciudad. Acá ocupan 4×4 casillas (el lof mapuche, 3×3). Pasarlos a 5×5 (el lof a 4×4) toca la colocación, la IA, el generador de mapas (quizás un mapa de 136 en vez de 128), los caminos, las 25 misiones y el balance. Las casas, granjas y almacenes no cambian.
a) Esperar a ver el paso 1 (solo vista) y decidir después *(por defecto)* · b) Hacerlo ya, con su torneo · c) No

**Respuesta:**


> **C-67 a C-74 vienen de la revisión histórica** (`proceso/25-revision-historica/`): tres historiadores, de América Latina, África y Asia. Lo que no cambiaba mecánicas ya se corrigió (`04-correcciones-aplicadas.md`). Esto son las decisiones que cambian el juego o los nombres. La opción por defecto es la que recomiendan ellos.

### C-67 · (historia, guaraníes) La yerba
Hoy la roza agotada deja un yerbal. Pero la yerba (*ka'a*) era un árbol silvestre del monte. En la colonia se cosechó con trabajo forzado de encomienda, y solo las reducciones del siglo XVIII la plantaron (Garavaglia, 1983).
a) La yerba como recurso silvestre del monte; el yerbal plantado recién en la vía misión; la roza agotada deja capuera; ganado vacuno en la vía misión. Medido con torneo *(por defecto)* · b) Dejarlo y aclararlo en la descripción

**Respuesta:**

### C-68 · (historia, Palmares) Pacto de Cucaú y liberación
El Pacto de Cucaú promete "cerrar la puerta a quienes llegan", pero en los datos es un +25 % sin costo. La liberación "libera" gente de cualquier casa enemiga, también guaraní o etíope.
a) El pacto apaga o reduce a la mitad la acogida y la liberación; la liberación vale solo contra los ingenios y los invasores (contra los demás pueblos, nada). Medido con torneo *(por defecto)* · b) Dejarlo

**Respuesta:**

### C-69 · (historia, Etiopía) Lalibela y la iglesia
Lalibela es un sitio zagwe del siglo XIII con culto vivo: en el juego se construye y da +25 % de vida a los edificios. La iglesia da +5 % de vida a las tropas.
a) Lalibela pasa a sitio sagrado neutral del mapa (no se construye) y el hito se ve como Debre Damo; la iglesia cambia su bono de combate por uno económico o de población *(por defecto)* · b) Dejarlo

**Respuesta:**

### C-70 · (historia) Nombres de edad
Las propuestas de los historiadores:
- incas: *Inkarri* → *Willkapampa*, y el hito militar → *Espíritu Pampa* (C-39);
- guaraníes: *Tekoha → Guára → Mbororé → Ñande retã* (C-41; desaconsejan *tovaja*; *guára*, a confirmar con un hablante);
- birmanos: *Hanthawaddy* → *Toungoo*;
- Ayutthaya: *Mueang Tha* → *Krung Thonburi*, y explicar *Ekkarat* en el panel;
- Palmares: no la a) de C-42, sino la b) "1678" o la d);
- Qorikancha: a la edad II o III (C-40 b).

a) Todo eso *(por defecto)* · b) Elegir de a uno (decí cuáles)

**Respuesta:**

### C-71 · (historia, Asia) Birmania y los extranjeros de Ayutthaya
- *Bayingyi* (tiradores) y *kathe* (caballería) son de 1613 en adelante y de la época Konbaung; en la edad II y en Nong Sarai (1593) son anacrónicos.
- Falta el barrio chino, la comunidad extranjera más grande de Ayutthaya (defendió la muralla en 1767 y sostuvo a Taksin).

a) Bayingyi y kathe solo en la edad IV (antes, "tiradores portugueses a sueldo" y "jinete shan"); barrio chino como tercer barrio de Ayutthaya; Birmania con monasterio de teca, pyatthat y zedi propios *(por defecto)* · b) Solo los nombres

**Respuesta:**

### C-72 · (historia) Otros nombres
- **Hitos mapuches:** Malón del toqui, Nguillatuwe del rewe, Corral de la remonta (o *Kawellu*) y Pewenal. Hoy inventan cargos como "toqui de caballería".
- **Edificios:** "Ruka de guerra" → "Junta de guerra"; "Kamayuq wasi" → *Qhuya wasi*; "Tukul" → *Gojjo bet*.
- **Ayutthaya:** la riqueza pasa a llamarse "Suai (pago al rey)".
- **Rebaños:** cerdo o gallinas en Palmares; buey cebú en Etiopía.
- **Rivales:** europeos por potencia, y Velho como facción "paulista" (C-44 b).

a) Todo eso *(por defecto)* · b) De a uno

**Respuesta:**

### C-73 · (historia, sonido) Lo que quedaba abierto
- C-58: nagarit (el timbal real de guerra) en la fanfarria y la alarma etíopes, en lugar del kebero litúrgico.
- C-59: sacar *Tra Nimit* (muy probablemente del repertorio ceremonial *naphat*; la grabación es de una banda naval de 1934). Hoy es la única pista propia de Ayutthaya.
- Alarma de Ayutthaya con klong chana, pi chawa y sang.

a) Todo eso, con música propia de paz para Palmares (ngoma y marimba) y para Ayutthaya, sintetizadas *(por defecto)* · b) De a uno

**Respuesta:**

### C-74 · (historia) Representación y consultas
- **Wat:** que no muestre una imagen del Buda reconocible hasta consultar, y revisar si conviene que se pueda destruir.
- **Hito guaraní:** la mbaraka sale del modelo hasta la consulta mbyá (C-60 b).
- **A futuro:** los oromo como facción de IA, con el gada; misiones de Adal; rivales Lan Na, Lan Xang y Camboya.
- **Consultas antes de publicar:**
  - la Iglesia ortodoxa Tewahedo;
  - las comunidades hararí, oromo y beta israel;
  - las organizaciones mapuches, mbyá, quechuas y quilombolas (CONAQ);
  - mestres de capoeira angola;
  - lingüistas de kimbundu.

a) Así *(por defecto)* · b) Otra cosa

**Respuesta:**


> **C-75 a C-83 vienen del diseño del juego tardío y los saberes** (`docs/diseno/27-juego-tardio-y-saberes.md`, etapa 26). Las consultas a comunidades de ese diseño se suman a C-74.

### C-75 · (juego tardío) Regla del ×2
¿"Una unidad de la edad IV no vale más de dos comunes" (ley cuadrada, como mide el modelo) o "ni el ataque ni la vida pasan de ×2" (más permisiva)?
a) Valor en comunes *(por defecto)* · b) Por estadística

**Respuesta:**

### C-76 · (juego tardío) Hitos militares con aura
En la III y la IV, el bono del hito militar vale solo cerca del hito, en lugar de ser global. Es lo que más desinfla la edad IV.
a) Sí, en el paso 4 *(por defecto)* · b) Solo el de la IV · c) No

**Respuesta:**

### C-77 · (juego tardío) Paso 1
Sacar el bono automático de ataque por edad y reemplazarlo por cosas que se compran: el +10 % de la II va a la herrería I, y los niveles veterano y élite se compran. El modelo da el mismo poder (0 a −2 %).
a) Sí, arrancar por ahí *(por defecto)* · b) Primero la herrería separada

**Respuesta:**

### C-78 · (juego tardío) Maravilla
Costo de 1500 de madera, piedra y riqueza; 600 s de obra; una cuenta de 15 minutos para ganar; opción del menú.
a) Así *(por defecto)* · b) Otros números

**Respuesta:**

### C-79 · (juego tardío) Maravilla de Ayutthaya
Krung, la ciudad isla con el fuerte Phom Phet (no es sagrada), o el Wat Phra Si Sanphet (con consulta).
a) Krung *(por defecto)* · b) El wat, si la consulta lo acepta

*Revisión histórica (etapa 26): el historiador de Asia recomienda cerrarla en a). Hacer del Wat Phra Si Sanphet una maravilla repite el saqueo de 1767.*

**Respuesta:**

### C-80 · (juego tardío) Unidades nuevas sin modelo
¿Esperan al arte o entran con una maqueta de silueta propia?
a) Esperan *(por defecto)* · b) Maqueta con silueta propia

**Respuesta:**

### C-81 · (saberes) Trepanación
El saber destacado inca: el 20 % de los caídos cerca del sanador o de la kallanka vuelve con media vida, en lugar de un sanador más fuerte. Evidencia arqueológica fuerte (Verano, 2016).
a) Así *(por defecto)* · b) Solo un sanador más fuerte

*Revisión histórica (etapa 26): la cifra queda corregida (en la época inca sobrevivía el 75–83 %; en la Guerra Civil de Estados Unidos moría el 46–56 %), como un saber de dos mil años que el Inka heredó. La mecánica pasa a "el 20 % de los que caen por golpe no muere y vuelve herido", para que no se lea como resurrección.*

**Respuesta:**

### C-82 · (saberes) Etiopía y el *Bahrä Hasab*
Un saber eclesiástico (el cómputo del calendario) usado en una mecánica económica.
a) Consultar a la Iglesia Tewahedo y, si no, "Cartógrafos de la corte" *(por defecto)* · b) Sacarlo ya

*Revisión histórica (etapa 26): el Bahrä Hasab es el cómputo de la Pascua, y ninguna fuente dice que ordenara las mudanzas de la corte. La opción nueva por defecto es el orden del kätäma (el campamento real armado siempre con el mismo plano), que está documentado.*

**Respuesta:**

### C-83 · (saberes) Saberes con evidencia "debatida"
El kilombo, el shotel, los armeros de Gondar y el yachaywasi tienen evidencia debatida.
a) Entran con la marca "debatido" en la ficha *(por defecto)* · b) Solo saberes documentados y arqueológicos

**Respuesta:**


> **C-84 a C-97 vienen de la revisión histórica del diseño de saberes** (`proceso/26-juego-tardio/02` a `04`; el diseño revisado está en `docs/diseno/27-juego-tardio-y-saberes.md`, §0).

### C-84 · (saberes, guaraníes) Élite de la vía monte
Sepé y la Guerra Guaranítica eran de los pueblos de misión. La élite de la vía monte pasa a los *ka'aguygua* ("monteses") [verificar grafía].
a) Sí *(por defecto)* · b) Otra

**Respuesta:**

### C-85 · (saberes, guaraníes) Maravilla
*Tekoha guasu* es una categoría del siglo XX, hoy usada en litigios por tierras. Pasa a llamarse "Aldea grande del monte" hasta la consulta.
a) Sí *(por defecto)* · b) Otra

**Respuesta:**

### C-86 · (saberes, mapuches) Ampive y poncho
*Lawentuchefe* es un término de fines del siglo XX y la platería, de fines del XVIII. Pasan a *ampive* [verificar] y al poncho (*makuñ*).
a) Los dos *(por defecto)* · b) Solo uno

**Respuesta:**

### C-87 · (saberes, incas) Pieza pesada de la IV
Las armas capturadas en Vilcabamba, en lugar de repetir las galgas.
a) Sí *(por defecto)* · b) Otra

**Respuesta:**

### C-88 · (saberes, incas) Huayrachina
El horno de viento que fundió la plata de Potosí: documentado y arqueológico. Entra en la IV, y los *mitmaqkuna* quedan para retomar.
a) Sí *(por defecto)* · b) No

**Respuesta:**

### C-89 · (saberes, Palmares) Escuela de la IV
*Oficinas do Macaco*: herreros, alfareros y tejedores de palma.
a) Sí *(por defecto)* · b) Otra

**Respuesta:**

### C-90 · (saberes, Etiopía) Guerrero de gaša
El "shotel que pasa por encima del escudo" es folclore moderno. Pasa a ser el guerrero de *gaša* (escudo) con jabalinas, sin ese bono.
a) Sí *(por defecto)* · b) Otra

**Respuesta:**

### C-91 · (saberes, Etiopía) Jinetes oromo aliados
El *gadaa* es un sistema de grados de edad, no un cuerpo montado. La élite de la IV pasa a ser jinetes oromo aliados por un tratado que se puede romper.
a) Sí *(por defecto)* · b) Otra

**Respuesta:**

### C-92 · (saberes, Palmares) Hierro de Angola Janga
El hierro iba a armas y herramientas: la mejora da +1 de ataque en lugar de armadura.
a) Sí *(por defecto)* · b) Otra

**Respuesta:**

### C-93 · (saberes, Palmares) Erveira y sanguar
El sanador es la *erveira* (Sweet, 2003, nivel "debatido"; nunca *nganga*). La mejora de curadores pasa al *sanguar*, la técnica de esquivar proyectiles, aclarando que no es capoeira.
a) Las dos *(por defecto)* · b) Solo una

**Respuesta:**

### C-94 · (saberes) Saberes nuevos de Etiopía y Palmares
*Ṭef* y *gotära*, *kosso*, los mercaderes *jabarti*, los *ṣäḥafe tə'əzaz*; tejido de palma y cerámica de los mocambos.
a) Como quedan en el diseño *(por defecto)* · b) Elegir

**Respuesta:**

### C-95 · (saberes, Ayutthaya) Sin astrología de corte
La astrología de corte (los *hon*) se usaba como bono. Pasa a astilleros de juncos y al Phra Khlang con sus intérpretes.
a) Sí *(por defecto)* · b) Otra

**Respuesta:**

### C-96 · (saberes, Ayutthaya) Saberes nuevos
La cerámica de Si Satchanalai, los *khlong lat* y el *nuat*.
a) Sí *(por defecto)* · b) Elegir

**Respuesta:**

### C-97 · (saberes, Palmares) La maravilla
La Cerca do Outeiro da Barriga queda "sitiada" hasta consultar si se puede mostrar su caída.
a) Así *(por defecto)* · b) Otra

**Respuesta:**

## Respuestas del 2026-11-16

- **Animaciones con KayKit:** "Lets start with kaykit yes." Las animaciones de los aldeanos arrancan con KayKit Character Animations (CC0). Etapa 27.
- **Íconos, color por edad y estados de la grilla** (observación al jugar): íconos propios para construir, entrenar e investigar; un color por edad; estados de color en lugar del candado; y el rojo de la ayuda flotante solo cuando de verdad bloquea. Cuando haya créditos de Meshy se harán imágenes para algunas cosas. Etapa 28.
- **C-98 · (animaciones) Aspecto de los aldeanos animados.** De lejos, el aldeano animado se ve más claro y menos integrado que el modelo de Meshy (ver `27-animaciones/capturas/04` y `05`): ganamos el movimiento y perdimos textura. Opciones:
  - a) dejarlos animados y riggear los modelos de Meshy cuando se pueda (Mixamo o a mano), para tener las dos cosas;
  - b) volver a Meshy quieto hasta riggear;
  - c) animados, pero con colores más oscuros y terrosos ya.

  Por defecto: a + c. Preguntas del agente: ¿un tono de piel por pueblo? ¿Riggear los aldeanos de Meshy antes que los soldados?
- **C-99 · (animaciones) Tono y armas.**
  - ¿Alcanza el tono nuevo del aldeano (`27-animaciones/capturas/11`), o lo oscurecemos más? ¿Querés un tono de piel por pueblo?
  - ¿Están bien las armas de cada pueblo (`27-animaciones/02-soldados.md`)? Por ejemplo: macana a dos manos para guaraníes y mapuches, dos espadas para Ayutthaya, jabalina etíope y estólica caranqui.
  - Por defecto: así como está, hasta que lo veas.
