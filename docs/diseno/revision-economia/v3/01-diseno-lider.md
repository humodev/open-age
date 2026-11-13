# Ronda 3 · 01 — Diseño económico consolidado (diseñador líder)

Base: la consigna [`00-consigna.md`](00-consigna.md), las rondas 1 y 2, la investigación de AoE4 y otros RTS, los dossiers históricos y los datos actuales (`data/`, `src/sim/sim_mods.gd`, `_generate_map` en `src/sim/sim.gd`). No se tocó código ni datos. Los números están también en [`parametros.json`](parametros.json) para el modelo numérico.

Convenciones:
- **AE** (aldeano-equivalente): 30 de riqueza neta por minuto, lo que rinde un aldeano en la fuente común descontando la caminata (v2/05, R4).
- `[verificar]`: dato histórico que no está en `docs/investigacion/` o que figura ahí con confianza baja.
- **Requiere modelo**: algo que no puedo asegurar sin el modelo numérico de la próxima etapa.

---

## 0. Las decisiones, en diez líneas

1. **La fuente común es el barreal, un pozo de arcilla**, no la sal. Arcilla tenían los seis pueblos; sal propia tenían cuatro: Palmares la compraba y en el Paraguay escaseaba.
2. Riqueza sigue siendo **un solo recurso** (D-006), con el mismo rombo. El barreal representa el oficio común de hacer vasijas para convidar y ofrendar. Lo que cada pueblo tenía de valioso y propio sale de su motor.
3. **Capa 1** (cómo usa el barreal): dos civs lo usan igual, dos lo usan mejor y una lo usa distinto. Ayutthaya lo usa igual, pero en la práctica lo necesita menos.
4. **Capa 2** (motor propio): tela de mit'a, rebaño, roza que deja yerbal, tierra que tributa, oficios dentro del mocambo y el almacén real que cobra del monte. Ninguno es comercio y ninguno depende de estar oculto.
5. Cada motor rinde **como máximo 0,8 AE por pieza**, se repaga en **5 a 8 minutos**, tiene **un máximo de piezas por edad** y **rinde menos si se amontona**.
6. Dos reglas para todas: una **tecnología de motor en la edad III** (+25 %) y una **semilla inicial** de valor parecido.
7. **Lo disputado**: barreales del centro, sitios sagrados espejados que rinden menos en manos de un mismo dueño, e ingenios o estancias neutrales que dan botín una vez. Tiene techo por edad.
8. **El terreno da como máximo ±6 %** por civ y mapa, y la diferencia entre dos civs en un mismo mapa no pasa de 10 puntos. Ninguna civ necesita agua, ladera ni monte.
9. Un **premodelo grueso** deja las seis curvas de riqueza dentro de ±10 % hasta el minuto 20. Hay dos alertas, guaraníes y Etiopía a los 30 minutos (§7.3).
10. Para implementarlo hacen falta **diez piezas nuevas**, todas como parámetros de módulo (§8).

---

## 1. La fuente común (pregunta A)

### 1.1 ¿Estaba la sal en los seis lugares? No

| Pueblo | Sal propia | Evidencia |
|---|---|---|
| Etiopía | **Sí**, y era moneda | Bloques de sal (*amole*) de la tierra baja afar, que valían más cuanto más lejos de la salina (Álvares, cap. XLIV; `etiopia.md` H18–H20) |
| Tawantinsuyu | **Sí** | Salineras de Maras y salares del altiplano `[verificar: fuera de investigacion/]` |
| Mapuches | **Sí** | Salinas de la pampa y de la costa; en el siglo XVIII la sal viajaba con el ganado `[verificar]` |
| Ayutthaya | **Sí** | Salinas costeras del golfo de Siam `[verificar]` |
| Palmares | **No**: la compraba | El comercio clandestino cambiaba farinha y vino de palma por "armas, pólvora, tejidos, sal y herramientas" (`palmares.md`, con fuente de confianza media) |
| Guaraníes | **Escasa** | En el Paraguay colonial la sal era un bien caro y traído de afuera `[verificar en Susnik o Garavaglia]` |

Una salina en cada base le daría a Palmares justo lo que no tenía y tenía que comprar. **La sal no sirve como fuente común.** Para Etiopía queda bien como nombre o aspecto de campaña.

### 1.2 Lo que sí tenían todos: arcilla y vasijas

| Pueblo | Alfarería | Para qué |
|---|---|---|
| Guaraníes | Es su marca arqueológica: la tradición tupiguaraní (Noelli, citado en `guaranies.md`) | Las grandes tinajas para la chicha del convite: "rico era el que podía convidar" (v2/04) `[verificar el nombre de las tinajas]` |
| Tawantinsuyu | Alfarería estatal de especialistas: aríbalos | Chicha para las fiestas con que el Estado devolvía el trabajo (`tawantinsuyu.md`: reciprocidad, Morris, Rostworowski) `[verificar el detalle de los aríbalos]` |
| Mapuches | Cerámica doméstica y ritual | Cántaros de bebida en las juntas `[verificar]` |
| Etiopía | Extendida, en manos de artesanos de rango bajo | Bebida fermentada y almacenamiento `[verificar]` |
| Palmares | La excavación de la Serra da Barriga (Funari y Orser) encontró sobre todo cerámica | Lara advierte que parte puede venir de la tropa de Velho (`palmares.md`); también se menciona el vino de palma |
| Ayutthaya | Hornos de jarras para almacenar y exportar | Hornos de Mae Nam Noi `[verificar]` |

**Decisión:** la fuente común es el **barreal**, un pozo de arcilla rojiza con vasijas secándose al lado. No tiene brillo dorado ni silueta de mina.
- **Nombre:** "Barreal (arcilla)".
- **Tooltip:** "Tus aldeanos sacan arcilla y hacen vasijas: riqueza para convidar, ofrendar y pagar."
- **Aspecto por civ:** cambia solo la vasija junto al pozo (aríbalo, tinaja, cántaro, jarra). Los barreales del centro son neutros.

**Simplificación declarada.** En ninguno de los seis pueblos la loza era el bien más valioso. El barreal representa el **oficio común**: lo que cualquier aldea fabrica para dar. Lo que cada pueblo tenía de valioso y propio (tela fina, ganado, yerba, tributo, hierro, productos del monte) sale de la capa 2. Así queda contestada la observación 1 del autor: **la mina común existe para lo mismo que el oro en Age**. Es el piso que todos pueden trabajar desde el minuto 2; lo propio se construye encima.

Alternativas descartadas:
- **"Piedra fina" o metal**: los guaraníes no tenían metales ("provincia sin metales", v2/04).
- **Un nombre abstracto** ("yacimiento"): es honesto, pero no le explica nada al autor.

### 1.3 Cantidades (reemplazan los dos yacimientos de 1400)

| Lugar | Cantidad | Cuántos | Dónde |
|---|---|---|---|
| Barreal de la base | 900 | 2 por jugador | A unas 10 casillas, donde hoy están los yacimientos |
| Barreal de flanco | 1500 (3×3) | 1 por jugador | A 18 casillas, de su propio lado (hoy `picks[5]`) |
| Barreal del centro | 1000 | 2 pares simétricos | Lo disputado |

Seguro por jugador: 3300 (hoy, 4200). **Se agota entre los minutos 22 y 28** si se trabaja con 4 a 8 aldeanos. Es a propósito: desde ahí la riqueza sale del motor o de lo disputado, como el oro que se acaba en Age.

---

## 2. Reglas comunes que usan las seis civs

| Regla | Valor | De dónde sale |
|---|---|---|
| Rendimiento máximo de una pieza pasiva | 0,8 AE = 24 r/min | R4 (v2/05) |
| Repago de una pieza pasiva | 5 a 8 min | R4 |
| Máximo de piezas pasivas por edad | 2 / 3 / 4 / 5 (edades I a IV) | R2 ("1 más 1 por edad", con la edad I contada como 1) |
| Rendimiento por vecindad | En un radio de 8 casillas, la 2.ª copia rinde 70 % y la 3.ª, 50 % | R3, aplicado por cercanía (ver abajo) |
| Tecnología de motor | Edad III, +25 %; cuesta 200 a + 200 m + 100 r | Nueva: es la versión simétrica del "andén" o el "cumbi" |
| Motor al minuto 15 | 30 a 60 % del ingreso de riqueza | R5 |
| Piso pacífico de lo agresivo | ≥ 50 % sin pelear | R7 |
| Semilla inicial | Un empujón de unos 100 a 150 de valor, distinto en cada civ | Nueva, para que todas arranquen con algo propio |

**Por qué R3 va por cercanía y no por cantidad.** Si la 2.ª y la 3.ª copia rindieran menos en todo el mapa, además del máximo por edad, el tope quedaría duplicado. Con cuatro piezas a 100/70/50/50 % se llega a 2,7 piezas efectivas, y ningún motor alcanza el 30 % de R5 al minuto 15. Por cercanía, R3 cumple lo que buscaba (castigar el apilamiento y obligar a decidir dónde) sin vaciar el motor. Además pone el amontonamiento contra el riesgo: dispersar rinde más y expone más.

**Lo disputado** (techo por edad: 10 / 25 / 40 / 50 % de la riqueza):
- **Barreales del centro**: se agotan.
- **Sitios sagrados espejados** (v2/03): el primero rinde 18 r/min, el segundo 12 y el tercero 8.
- **Dos pares de ingenios o estancias neutrales con guardia**:
  - guardia de 4, y 2 más cada vez que se reconstruyen;
  - botín de 150 de riqueza una sola vez; se rehacen a los 240 s;
  - todas las civs pueden asaltarlos; mapuches y Palmares sacan ×1,5 y su extra propio.
- **Mercado como válvula**: mínimo 60 y paso 3 (ronda 1, 05).

**Remontada.** Lo del centro se agota, los sitios rinden menos al acumularse, los ingenios no dan renta y el barreal de flanco es de cada uno.

---

## 3. Las dos capas de cada civ (pregunta B)

### Cómo conviven las capas: la regla del cruce

En AoE4, los malíes también minan oro al principio. La mina de pozo empieza a valer más que el minero a mitad de partida. Acá pasa lo mismo:
- **Minutos 0–6:** todas viven del barreal y de la semilla, porque el motor todavía no se pagó.
- **Minutos 6–15:** el motor crece pieza por pieza. Conviene invertir en él mientras el barreal todavía rinde, para que esté maduro cuando el barreal se acabe.
- **Minuto 15 en adelante:** el motor da del 30 al 60 % del ingreso de riqueza. El barreal se termina entre los minutos 22 y 28, y desde ahí la riqueza sale del motor, del barreal de flanco y de lo disputado.

En cada ficha marco el **cruce**: el momento en que una pieza más del motor rinde más que un aldeano más en el barreal.

### 3.1 Tawantinsuyu — "El trabajo que sobra se vuelve tela"

- **Capa 1, mejor por la red.** Si el barreal queda a 3 casillas o menos de un edificio propio conectado a la llaqta por camino, se recolecta un **20 % más rápido**. Para eso hay que gastar mit'a en el camino. Se reutiliza `bono_conectado_pct`, que hoy solo acelera la producción.
- **Capa 2, el taller de tejido.**
  - Cuesta 120 de madera y 20 de mit'a.
  - Consume **30 de mit'a por minuto** y da **24 de riqueza por minuto**.
  - Tiene un interruptor: prendido o apagado.
  - Máximo 2 / 3 / 4 / 5 por edad.
  - En la edad III, el hito aqllawasi pasa a ser la tecnología de motor: el **cumbi** da +25 %, en lugar de la renta fija de 40 que tiene hoy, que no tiene tope.
- **Cómo conviven.** La mit'a tiene tres destinos: caminos (capa 1), talleres (capa 2) y levas o andenes (guerra y comida). Con 20 runa entran 80 de mit'a por minuto: alcanzan para dos talleres y deja 20 para obra. **Cruce:** el segundo taller (24 r) le gana a un aldeano conectado (36 r) solo si ese aldeano hace falta en la comida. Hacia el minuto 9 es la decisión típica.
- **Se resuelve un problema medido:** la mit'a ya no pasa el 43 % del tiempo en el tope, porque los talleres la consumen sin que nadie los toque.
- **Me aparto del equipo.** Agrego la capa 1 por caminos para que la red tenga un uso económico temprano y compita con la tela. Sin eso, el camino era una orden por minuto sin decisión.

### 3.2 Mapuches — "La riqueza camina y se reproduce"

- **Capa 1, igual.** El lof es depósito y centro chico, y se planta junto al barreal de flanco. Los mapuches no tienen ventaja en la arcilla, y la historia no pide inventarla.
- **Capa 2, el corral.**
  - Cuesta 120 de madera.
  - Empieza con 1 cabeza y suma **una cada 45 s**, hasta un tope de 5 cabezas, o de 6 en pradera (sin árboles a 3 casillas o menos).
  - Cada cabeza da **4 de riqueza por minuto**: 20 por corral, o 24 en pradera.
  - Rinde menos si se amontona.
  - Máximo 2 / 3 / 4 / 5 por edad.
  - **El kulliñ se fusiona con la riqueza**, y todos los costos en kulliñ pasan a riqueza.
- **Faenar** es una orden sobre el corral **entero**: cada cabeza da 40 de alimento al instante, y queda una cabeza para volver a criar. Es comerse el capital, una decisión grande y nunca un ritual.
  - Lo descarté como orden por cabeza porque, con la cría a 30 o 45 s, el corral se volvía una fábrica de comida cliqueable.
- **Variante agresiva (malón).**
  - El `saqueo` da riqueza (10 % del daño a edificios), con **un tope de 60 por minuto**.
  - Rinde ×1,5 contra los ingenios o estancias neutrales y suma 1 cabeza.
  - Más adelante, el botín puede llegar como **arreo**: ganado que camina hasta el corral y se puede interceptar.
  - **Piso pacífico:** el corral rinde sin pelear, así que la R7 se cumple de sobra.
- **Respuesta a la observación 2 del autor.** No necesitan dañar a nadie para tener riqueza. Al comienzo viven del barreal y de su corral inicial; el malón suma encima, con techo.
- **Cruce:** desde el segundo corral (minuto 4). Un corral lleno rinde 0,67–0,8 AE sin ocupar población.
- **Me aparto del equipo.** Descarto el "interés sobre lo guardado" de v2/01:
  - premia acumular, lo contrario de la regla del banco ≤ 250 a los 8 minutos;
  - no se ve en el mapa.

  Me quedo con las cabezas visibles de v2/02.

### 3.3 Guaraníes — "El campo que se agota deja un yerbal"

- **Capa 1, mejor en la mano.** Recolectan riqueza a 800 en vez de 700 (+14 %, ya está en los datos). Es la alfarería tupiguaraní.
- **Capa 2, la roza.**
  - Cuesta 45 de madera y tiene 750 de alimento, que se recolecta a 1100 (hoy 550 a 1250).
  - Junto al monte (4 árboles o más a 2 casillas o menos) rinde +15 %.
  - Al agotarse deja un **yerbal** de 300 de riqueza.
  - **El mismo aldeano sigue trabajando, ahora en el yerbal, sin orden nueva.**
  - **Cola de rozas** en cada tapyi (hasta 4 pagadas por adelantado) y una **bandera de roza** por tapyi. Cuando un yerbal se agota, su aldeano abre la roza siguiente de la cola junto a la bandera. Si la cola está vacía, busca riqueza cercana, como hoy.
  - Como máximo 3 / 4 / 5 / 5 yerbales activos por edad. Por encima del tope, la roza deja **capuera**: árboles jóvenes, es decir, madera. Es la sucesión de Noelli: no se pierde, cambia.
- **Cómo conviven.** El yerbal rinde 40 por minuto con un aldeano, más que el barreal (30 o 34). Por eso, desde el minuto 12, los guaraníes **sacan aldeanos del barreal**: lo usan menos que nadie y lo guardan para el final.
- **Cruce:** desde el primer yerbal, alrededor del minuto 13.
- **Me aparto del equipo.**
  - La roza pasa de 550 a 750 y entra la cola. Con 550, 8 rozas pedían una orden por minuto: era un ritual.
  - La cola automatiza la tarea sin quitar la decisión. Igual que la resiembra de AoE2, se elige cuánta comida y cuánta riqueza (el largo de la cola) y dónde (la bandera).
  - El yerbal viejo de la base pasa a ser su semilla (250), equiparada con las de las otras civs.

### 3.4 Etiopía — "La tierra paga a la corte que está cerca"

- **Capa 1, distinto: la corte agota lo que la rodea.**
  - La kätäma desplegada a 8 casillas o menos de un barreal le saca **12 de riqueza por minuto sin aldeanos**, una fuente a la vez. Es el patrón del ovoo mongol, con fundamento propio: "la corte que camina y agota su entorno" (`investigacion/README.md`).
  - Cuando el barreal se acaba, la corte "comió" su entorno y hay una razón concreta para mudarla.
- **Capa 2, el gult.**
  - Cuesta 100 de madera y 40 de alimento.
  - Renta base: 4 de alimento y **14 de riqueza** por minuto. A 14 casillas o menos de la corte rinde **+33 %**: 5 de alimento y **19 de riqueza**, es decir, 0,8 AE.
  - Rinde menos si se amontona (radio de 6).
  - Máximo 2 / 3 / 4 / 5 por edad.
  - Al ponerlo se elige: **señor**, que da renta, o **regimiento**, que no da renta y abarata 15 % a los jinetes por gult, hasta un 30 %.
- **Cómo conviven.** La corte se muda para comerse un barreal nuevo (capa 1), y al mudarse cambia qué gult cobran el +33 % (capa 2). Mudarse es la decisión que une las dos capas, cada 5 a 8 minutos.
- **Cruce:** el primer gult se repaga en 6 a 8 minutos y el segundo conviene antes de la edad II.
- **Me aparto del equipo.**
  - En v2/02 la tierra rendía *solo* dentro del radio de la corte. Lo dejo en bonificación: si no, mudar la corte apaga toda la economía, y una incursión a la carpa decide la partida.
  - Saco la opción monasterio (otra pieza más) y el escalón de oro (v2/04), que queda para la campaña.
  - El gult paga más riqueza que alimento. El problema de v2/05 era el **costo** en alimento, no el pago.

### 3.5 Palmares — "La riqueza es la gente que llega"

- **Capa 1, igual.** Trabajan el barreal como todos. La diferencia es que los brazos no se pagan: llegan por la fama.
- **Capa 2, los oficios.**
  - Cada mocambo tiene **3 puestos de oficio** y la cerca real tiene 2.
  - Cada persona en un puesto produce **15 de riqueza por minuto**, adentro del edificio, sin caminar y sin agotar nada.
  - El jugador fija un **cupo** por edificio (de 0 a 3), y los recién llegados llenan solos el cupo libre más cercano.
  - Hay un máximo de puestos totales por edad: 4 / 7 / 9 / 9.
  - La tecnología de motor es *tendas de ferreiro* (+25 %): cuatro herrerías en 1645 y cuarenta en 1694 (`palmares.md`).
- **Se descarta todo lo que dependa de estar oculto.**
  - El mocambo pierde `oculto`.
  - En su lugar, el monte da una bonificación: con 6 árboles o más a 4 casillas o menos, +5 de fama por minuto.
  - Los del oficio están protegidos porque están **adentro**, no porque no se los vea. Para sacarlos hay que voltear el mocambo, con su cerca de estrepes.
- **Variante agresiva:** la correría a los ingenios neutrales da botín ×1,5 y 2 personas liberadas (`liberacion` ya existe).
- **Cómo conviven.** Un oficio rinde la mitad que un aldeano en el barreal, pero es seguro y no se agota. **Cruce:** cuando el barreal cercano está a más de 10 casillas del depósito, o agotado, o bajo ataque. En la práctica conviene llenar los puestos desde el minuto 7 y mover cupos cuando el barreal se termina.
- **Historia:** "riqueza en personas" (Miller; Guyer y Belinga), las herrerías y los oficios de los mocambos.
- **Me aparto del equipo.** Combino la "riqueza en personas" de v2/04 con los trabajadores en la aldea de v2/02, sin el secreto.
  - Descarto la farinha (v2/01, v2/04 C), porque era la más parecida a un mercado.
  - Descarto la forja como conversión de madera, que choca con Ayutthaya. Queda como tecnología.

### 3.6 Ayutthaya — "El monte paga al rey"

**Elección entre las dos propuestas en conflicto.** El motor es **"el monte paga al rey"** (v2/04 A, con el almacén real de v2/01). Los **barrios extranjeros** quedan como modificador de vecindad y como vía militar, no como segunda fuente de renta.

Por qué:
1. **Dos motores de renta duplican la atención y el balance.** Ayutthaya sería la única civ con dos fuentes propias.
2. **Los barrios que pagan por sus vecinos** son, en la lectura del autor, otra vez "comercio con otro nombre": socios que pagan.
3. **El monopolio de los productos del monte** está mejor documentado: Phra Khlang Sinkha, el monopolio de Narai en 1662 y el de los cueros para la VOC en 1664 (`ayutthaya.md` H19, H23).
4. **Combinarlos tiene base histórica.** Eran mercaderes chinos los que manejaban los juncos de la corona y compraban esos productos `[verificar en Sarasin Viraphol]`.

La pieza:
- **Capa 1, igual.** En la práctica usan menos el barreal, porque sus leñadores también hacen riqueza.
- **Capa 2, el almacén real.**
  - Cuesta 200 de madera, y es también depósito de todo.
  - Máximo 1 / 2 / 3 / 4 por edad.
  - El **25 % de la madera y del alimento silvestre** (caza y arbustos) que se entrega ahí **entra además como riqueza**, con un tope de **24 por minuto** por almacén.
  - Se satura con unos 3 leñadores.
- **Barrios** (desde la edad II, uno por edad):
  - **chino**: +8 de tope a cada almacén real a 6 casillas o menos, hasta 2 almacenes;
  - **japonés** y **portugués**: habilitan sus compañías, que salen 15 % más baratas si el barrio toca un cuartel.
  - Pierden la renta de 8 que tienen hoy.
- **Cómo conviven.** La decisión espacial es poner el almacén junto al mejor bosque (rinde, pero está lejos y expuesto) o junto a la base. En la edad II se suma dónde va el barrio chino: entre dos almacenes rinde el doble.
- **Cruce:** inmediato con el primer almacén, porque es su semilla. Desde ahí, cada aldeano que pasa del barreal a la madera rinde 34 de madera y unos 8 de riqueza.

---

## 4. Terreno (pregunta C)

Efecto esperado sobre la economía total al minuto 20, en porcentaje respecto de la misma civ en el llano. Las bases son llanas y no tienen agua a menos de 13 casillas (D-027, `_generate_terrain`). Por eso la ladera y el agua bonifican solo fuera de la base, y los efectos son chicos.

| Civ | llano | montaña | río | bosque | valle | altiplano | bosque templado | selva | mesetas | delta | sierra |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Tawantinsuyu | 0 | +5 | 0 | −2 | +5 | +3 | 0 | −4 | +3 | −2 | +3 |
| Mapuches | +4 | 0 | +2 | −2 | +2 | +4 | −2 | −4 | +2 | 0 | −2 |
| Guaraníes | −2 | −2 | +2 | +4 | −4 | −5 | +4 | +5 | −2 | +2 | +3 |
| Etiopía | +2 | +3 | 0 | −2 | +2 | +3 | −3 | −5 | +4 | −2 | 0 |
| Palmares | −2 | 0 | 0 | +3 | −4 | −5 | +4 | +4 | 0 | 0 | +5 |
| Ayutthaya | 0 | −2 | +3 | +3 | −5 | −6 | +3 | +5 | −4 | +5 | +2 |
| *Diferencia máxima entre civs en el mapa* | 6 | 7 | 3 | 6 | 10 | 10 | 7 | 10 | 8 | 7 | 7 |

**De dónde sale cada signo y cuál es el plan B:**

| Civ | Bonificación | Penalidad | Plan B (nada es requisito) |
|---|---|---|---|
| Tawantinsuyu | Andén +60 % en ladera (montaña, valle, mesetas, sierra) | Monte cerrado y brazos de río cortan caminos (selva, delta) | En el llano el andén es una chacra. Los talleres rinden igual en cualquier mapa. Se hacen solo los caminos al barreal |
| Mapuches | Pradera: el corral sube a 6 cabezas (llano, altiplano) | Monte cerrado: no hay pradera (selva, bosque templado) | Talar 3 casillas alrededor del corral, que además da madera. En monte rinden más el sigilo y el malón (militar) |
| Guaraníes | Roza junto al monte +15 % (selva, bosque) | Pocos árboles (altiplano, valle) | La roza y el yerbal rinden la base en cualquier lado. En el altiplano: rozas junto a los pocos bosquecitos y más aldeanos en el barreal, donde tienen +14 % |
| Etiopía | Lugar abierto para gult de 4×4 (mesetas, altiplano); altura para la defensa | Monte cerrado: poco lugar (selva, bosque templado) | El gult se pone en claros talados. La corte se muda a lo abierto. Gult de regimiento si el monte favorece pelear de cerca |
| Palmares | Mocambo junto al monte: +5 de fama (sierra, bosque, selva) | Mapas pelados (altiplano, valle) | La fama base sale de la cerca real y las casas. Los oficios no dependen del terreno |
| Ayutthaya | Mucha madera y arrozal junto al agua fuera de la base (selva, delta, río) | Poca madera (altiplano, valle, mesetas) | El almacén real también cobra de la caza y los arbustos. El altiplano tiene `arbustos_extra`. Con menos madera, más aldeanos en el barreal |

**Reglas para el torneo:** ninguna celda pasa de ±6 % y ninguna columna de 10 puntos. Las campañas con nombre pueden pasarse; la escaramuza no. Las tres columnas que están en el límite (valle, altiplano y selva) son las primeras que hay que medir. **Requiere modelo y torneo.**

---

## 5. La vida completa de cada civ (pregunta D)

La fase "final" es con el mapa revelado, puestos de avanzada y tropas en todos lados. En cada celda: qué hace, de dónde sale la riqueza, qué decide y qué puede hacer el rival.

### Tawantinsuyu

| Fase | Qué hace | Riqueza de… | Decide | El rival puede |
|---|---|---|---|---|
| 0–5 | 3 runa al barreal a los 2:00. Camino de unas 6 casillas del tambo al barreal (12 de mit'a). Taller 1 a las 4:00 | Barreal +20 % y 100 iniciales | ¿Camino o taller primero? | Hostigar el barreal o cortar el camino (200 pv): pierde el +20 %, no el motor |
| 5–15 | Edad II alrededor de 8:00. Talleres 2 y 3. Qollqa para el tope de mit'a | 3 talleres (72) + 3–4 en el barreal (110–145): motor ~33 % | Mit'a para tela, leva o andén. Apagar un taller si se necesita una leva ya | Quemar talleres (600 pv) y qollqas |
| 15–30 | Edad III con el aqllawasi (cumbi +25 %). Talleres 4 y 5 en la edad IV. Barreal de flanco conectado | Talleres 120–150; flanco; centro hasta el techo | ¿Conectar el centro (camino largo y expuesto) o reforzar casa? | Cortar la red en varios puntos |
| Final | La red está a la vista, pero los talleres están en el corazón de la base | Talleres + lo disputado | Reparar caminos o pasar mit'a a levas instantáneas en la qollqa | Golpear los caminos. **No se rompe:** el taller no depende del camino, solo el +20 % del barreal |

### Mapuches

| Fase | Qué hace | Riqueza de… | Decide | El rival puede |
|---|---|---|---|---|
| 0–5 | Corral inicial (1 cabeza) creciendo. 3 al barreal. Segundo corral a las 4:00, lejos del primero, en pradera | Barreal + corrales (4–24) | Dónde: pradera lejos (rinde más) o junto al lof (seguro) | Golpear un corral: cada 20 % de vida es una cabeza |
| 5–15 | Edad II con el lonko. Segundo lof en el flanco. Corral 3 | 3 corrales (~65) + 3 en el barreal: motor ~35 % | ¿Faenar un corral para cerrar el hito II? ¿Malón a una estancia neutral? | Perseguir el ganado disperso, que se ve |
| 15–30 | Corral 4 y crianza (+1 cabeza). Malones con tope de 60 por minuto | Corrales 90–120 + malón ≤ 60 + flanco | Malón al rival o a lo neutral. ¿Rehacer o mover corrales? | Fortificar sus granjas (el malón rinde por daño) |
| Final | Corrales dispersos entre lof | Corrales + malón + centro | Dónde reponer lo perdido | Cazar corrales. **No se rompe:** no hay secreto, se reponen a 120, y la vecindad premia dispersar. Atacarlos aleja al rival de los lof |

### Guaraníes

| Fase | Qué hace | Riqueza de… | Decide | El rival puede |
|---|---|---|---|---|
| 0–5 | 2 al yerbal viejo (250) y 2 al barreal. Rozas en lugar de granjas desde las 2:30. Bandera de roza junto al monte | Yerbal viejo + barreal (+14 %) | Bandera junto al monte (+15 %, expuesta) o junto a la casa | Quemar rozas (son edificios) |
| 5–15 | Edad II alrededor de 8:00. Cola de rozas. Los primeros yerbales hacia el minuto 13 | Barreal 3–4 + yerbales (~160): motor ~37 % | Largo de la cola (comida ahora o riqueza después). Mudar el tapyi | Mandar aldeanos a cosechar un yerbal ajeno: es un recurso, cualquiera puede |
| 15–30 | Tope de yerbales: 4, y 5 en la edad III. Ka'a ete (yerbal 375). Barreal casi sin usar | Yerbales 160–200 + barreal de reserva | ¿Seguir quemando monte (la capuera da madera) o pasar a granjas comunes en la misión? | Emboscadas mutuas en el monte |
| Final | Base que avanza sobre el monte | Yerbales + barreal guardado + centro | Dónde poner la bandera ahora que todo está a la vista | Quemar rozas. **No se rompe:** el yerbal es un recurso del mapa y no depende del secreto |

### Etiopía

| Fase | Qué hace | Riqueza de… | Decide | El rival puede |
|---|---|---|---|---|
| 0–5 | La corte ya extrae 12 por minuto del barreal de la base. 3 aldeanos al otro barreal. Gult 1 a las 3:30 (señor) | Corte 12 + barreal + gult | ¿Gult o jabalineros? | Rondar la corte |
| 5–15 | Gult 2 y 3 alrededor de la corte. Edad II alrededor de 8:00. Hacia el minuto 12 el barreal se acaba y **la corte se muda** al barreal de flanco | Gult (~50) + corte 12 + barreal: motor ~28–32 % | Mudarse (los gult viejos pierden el +33 %) o quedarse. ¿Señor o regimiento? | Atacar la carpa en marcha (2000 pv, lenta) |
| 15–30 | Gult 4 y 5. Registro +25 %. La corte puede acampar junto al barreal del centro | Gult 75–95 + corte + centro | ¿Acampar en el centro (rinde y arriesga la capital)? | Asediar la corte avanzada; destruir gult lejanos (500 pv) |
| Final | Gult repartidos y la corte asentada (Gondar) o en marcha | Gult + corte + disputado | Asentarse (Gondar) o seguir moviéndose | Cazar gult lejanos. **No se rompe:** los de cerca de la corte rinden más y están protegidos |

### Palmares

| Fase | Qué hace | Riqueza de… | Decide | El rival puede |
|---|---|---|---|---|
| 0–5 | La fama trae gente (60 iniciales = 2 personas). 3 al barreal. Mocambo 1 hacia las 3:00 con cupo 1 | Barreal + 1–2 oficios | Cupo: campo u oficio | Hostigar el barreal: los palmaristas no cuestan, pero hay que defenderlos |
| 5–15 | Mocambo 2 junto al monte (+fama). Cupos a 3. Edad II alrededor de 8:00 | 4–6 oficios (60–90) + barreal: motor ~38 % | Correría a un ingenio neutral (botín y gente). ¿Más mocambos o más cupo? | Presionar mocambos lejanos (900 pv, estrepes) |
| 15–30 | 7 a 9 puestos. *Tendas de ferreiro* +25 %. Correrías | Oficios 130–170 + botín + flanco | ¿Mover gente del barreal agotado a oficios? ¿Cucaú o Zumbi? | Asediar un mocambo: libera a los del oficio, que vuelven al campo |
| Final | Mocambos con cerca de estrepes, a la vista de todos | Oficios + lo disputado | Dónde rehacer un mocambo caído | **No se rompe:** ya no hay secreto que perder; el ingreso está dentro de edificios que hay que voltear |

### Ayutthaya

| Fase | Qué hace | Riqueza de… | Decide | El rival puede |
|---|---|---|---|---|
| 0–5 | Empieza con el almacén real construido. Lo usan los leñadores y la caza. 3 al barreal | Almacén (hasta 24) + barreal | ¿Más leñadores (madera y riqueza) o más barreal? | Hostigar leñadores |
| 5–15 | Edad II alrededor de 8:00. Almacén 2 junto a un bosque nuevo. Barrio chino entre los dos | 2 almacenes (~60 con barrio) + barreal: motor ~31 % | ¿Chino (economía) o japonés o portugués (compañías)? | Golpear el almacén lejano (900 pv) |
| 15–30 | Almacén 3. Monopolio real +25 %. Kraal y elefantes | Almacenes 90–110 + flanco + centro | Arrozales junto al agua del centro (+45 %) o no | Matar leñadores, quemar el almacén expuesto |
| Final | Los bosques cercanos se acaban: los almacenes nuevos quedan lejos | Almacenes + caza y arbustos + centro | Dónde poner el almacén siguiente | **No se rompe:** el tope por almacén impide inundarlo de madera, y el plan B (caza y arbustos) sigue |

**Por qué nada se rompe en el final:**
- ningún motor depende de no ser visto;
- todas las piezas tienen tope por edad;
- lo agresivo tiene tope por minuto;
- lo disputado se agota o rinde menos al acumularse.

El riesgo del final es otro: **con el barreal agotado, la civ con el motor más frágil queda a merced de lo disputado.** Por eso el techo de la edad IV es de 50 % y no más (§9, punto 8).

---

## 6. Esfuerzo (pregunta E)

Métricas de v2/05:
- **PMP**: pendientes de la mecánica propia cada 10 minutos.
- **OPA**: órdenes propias del motor por minuto.
- **OPM**: órdenes económicas totales por minuto. Es lo común (casas, depósitos, granjas) más el motor, sin recolectar ni encolar aldeanos. Es la lectura que tomo de "la economía propia de cada civ" en la consigna.
- **Decisiones por edad**: decisiones con al menos dos respuestas viables.

La base común que estimo para la OPM es 1,2 / 0,9 / 0,6 / 0,5 por fase.

| Civ | PMP 0–5 / 5–15 / 15–30 / final | OPA (motor) por fase | OPM total por fase | Decisiones por edad |
|---|---|---|---|---|
| Tawantinsuyu | 1 / 1,5 / 1,5 / 2 | 0,40 / 0,50 / 0,40 / 0,40 | 1,60 / 1,40 / 1,00 / 0,90 | 3: mit'a para tela, obra o leva; prender o apagar; qué conectar |
| Mapuches | 0,5 / 1,5 / 1,5 / 2 | 0,40 / 0,50 / 0,35 / 0,40 | 1,60 / 1,40 / 0,95 / 0,90 | 3: dónde va el corral; faenar o no; malón o no |
| Guaraníes | 0,5 / 1,5 / 2 / 2 | 0,40 / 0,50 / 0,45 / 0,40 | 1,60 / 1,40 / 1,05 / 0,90 | 3: bandera; largo de la cola; mudar el tapyi |
| Etiopía | 0,5 / 1 / 1,5 / 2 | 0,40 / 0,50 / 0,40 / 0,40 | 1,60 / 1,40 / 1,00 / 0,90 | 3: dónde va el gult; señor o regimiento; mudar la corte |
| Palmares | 0,5 / 1 / 1 / 1,5 | 0,40 / 0,40 / 0,33 / 0,35 | 1,60 / 1,30 / 0,93 / 0,85 | 3: dónde va el mocambo; cupo; correría |
| Ayutthaya | 0,5 / 1 / 1,5 / 1,5 | 0,30 / 0,35 / 0,33 / 0,33 | 1,50 / 1,25 / 0,93 / 0,83 | 3: dónde va el almacén; qué barrio y dónde; leña o barreal |
| **Más / menos (OPM)** | — | — | **×1,07 / ×1,12 / ×1,13 / ×1,08** | — |

Lectura:
- **La OPM total queda dentro de ×1,5** en las cuatro fases.
- **La OPA del motor solo** va de 0,30 a 0,50, es decir, ×1,67 en el peor caso: Ayutthaya en la fase 1. Cumple las reglas de v2/05 (≤ 1,0 y no más de 0,5 sobre la mediana), pero no un ×1,5 estricto para el motor solo.
  - Si el autor lo quiere estricto, la palanca es que el almacén real de Ayutthaya cobre de **una** fuente elegida, madera o caza. Eso suma una decisión por almacén.
- **PMP ≤ 2** en todas, con diferencia ≤ 1. Nada vuelve con una cadencia menor a 90 s:
  - la roza se automatizó con la cola;
  - el taller y el oficio se llenan solos;
  - faenar es del corral entero;
  - la mudanza de la corte va cada 5 a 8 minutos.
- **Tope del recurso propio**: la mit'a tiene consumo continuo y la fama gasto automático (acogida). Objetivo: ≤ 15 % del tiempo en el tope. **Requiere modelo.**
- Todo esto es una estimación de diseño: se cuenta con `atencion.gd` y `pendientes.gd` (v2/05) una vez implementado, y con 3 partidas humanas grabadas por civ.

---

## 7. Números

### 7.1 Piezas de cada motor

| Civ | Pieza | Costo | Rinde | Tope | Repago | AE |
|---|---|---|---|---|---|---|
| Común | Barreal de la base / de flanco / del centro | — | 30 r/min por aldeano (700) | 900×2 / 1500 / 1000×2 pares | — | 1,0 |
| Tawantinsuyu | Taller de tejido | 120 m + 20 mit'a | 24 r/min; consume 30 mit'a | 2/3/4/5 por edad | 5,0 min | 0,8 |
| Tawantinsuyu | Barreal conectado | Camino a 2 mit'a por casilla | +20 % de tasa | — | — | — |
| Mapuches | Corral | 120 m | 4 r/min por cabeza; 5 cabezas (6 en pradera); +1 cada 45 s | 2/3/4/5; vecindad | 6,0 min (5,0 en pradera) más el llenado | 0,67–0,8 |
| Mapuches | Faenar | Todo el corral | 40 a por cabeza (deja 1) | — | — | — |
| Mapuches | Malón | — | 10 % del daño a edificios | 60 r/min | — | — |
| Guaraníes | Roza → yerbal | 45 m | 750 a (1100), y después 300 r (800) | 3/4/5/5 yerbales activos | — | 1,33 por aldeano |
| Guaraníes | Cola de rozas | Prepago | Hasta 4 | — | — | — |
| Etiopía | Gult (señor) | 100 m + 40 a | 4 a + 14 r; 5 a + 19 r cerca de la corte | 2/3/4/5; vecindad a 6 casillas | 7,8 / 5,8 min | 0,6 / 0,8 |
| Etiopía | La corte extrae | — | 12 r/min del barreal a ≤ 8 casillas | 1 fuente | — | 0,4 |
| Palmares | Oficio | 1 persona (28 de fama) | 15 r/min, adentro | Puestos 4/7/9/9; 3 por mocambo y 2 en la cerca real | — | 0,5 por persona |
| Ayutthaya | Almacén real | 200 m (es depósito) | 25 % de la madera, caza y arbustos como riqueza | 24 r/min por almacén; 1/2/3/4 | 5,2 min incremental (8,3 en total) | 0,8 |
| Ayutthaya | Barrio chino | 120 m | +8 de tope a cada almacén a ≤ 6 casillas | 1 barrio por edad desde la II | 7,5 min (2 vecinos) / 15 (1) | — |
| Todas | Tecnología de motor (edad III) | 200 a + 200 m + 100 r | +25 % | Una vez | — | — |

### 7.2 Semillas

| Civ | Semilla |
|---|---|
| Tawantinsuyu | 60 de mit'a (ya existe) |
| Mapuches | Corral inicial con 1 cabeza (reemplaza los 20 de kulliñ) |
| Guaraníes | Yerbal viejo de 250 a ≤ 8 casillas |
| Etiopía | La corte extrae desde el minuto 0. El generador pone un barreal de la base a ≤ 8 casillas |
| Palmares | 60 de fama (ya existe) |
| Ayutthaya | Almacén real inicial |

### 7.3 Premodelo grueso (no reemplaza al modelo numérico)

Script del scratchpad. Supuestos:
- paso de 1 s y curva común de aldeanos (6 → 19 → 30 → 40 → 48 → 58 a los 0, 5, 10, 15, 20 y 30 minutos);
- tasas netas de `parametros.json`;
- tecnología de motor en el minuto 19;
- **sin lo disputado**;
- el barreal propio se agota.

Riqueza acumulada, y en la última columna el porcentaje del ingreso que viene del motor al minuto 15:

| Civ | m5 | m10 | m15 | m20 | m30 | Motor al m15 |
|---|---|---|---|---|---|---|
| Tawantinsuyu | 432 | 1129 | 1982 | 3111 | 5682 | 33 % |
| Mapuches | 450 | 1104 | 1909 | 3100 | 5830 | 35 % |
| Guaraníes | 466 | 1134 | 1816 | 3268 | **6924** | 37 % |
| Etiopía | 445 | 1126 | 1892 | **2868** | **5081** | **28 %** |
| Palmares | **402** | 1123 | 2114 | 3386 | 6110 | 38 % |
| Ayutthaya | 442 | 1121 | 2050 | 3201 | 5686 | 31 % |
| Desvío respecto de la media | −9 / +6 % | ±2 % | −7 / +8 % | −9 / +7 % | −14 / +18 % | — |

Referencia: una civ sin motor llega a los mismos números hasta el minuto 20 y se hunde a los 30 (3400, −42 %). **El motor es lo que sostiene el final.**

**Alertas para el modelo:**
1. **Guaraníes, +18 % a los 30.** El yerbal rinde más que el barreal y no se agota de golpe. Palancas, en orden R6: el yerbal a 250, o el tope de la edad IV en 4.
2. **Etiopía, −14 % a los 30 y 28 % de motor al minuto 15.** El premodelo no suma el alimento del gult (5 por minuto por gult, que libera aldeanos). Si con ese alimento sigue corta, la palanca es el radio de la corte, de 14 a 16. Después, el gult a 15 de riqueza de base.
3. **Palmares, −9 % a los 5.** Es el costo de esperar la fama. Palanca: la semilla, de 60 a 90 de fama.

Las edades II (6:30–9:00) y III (< 20:00) **no las limita la riqueza**: en el premodelo, a los 7 minutos todas tienen más de 600 acumulados. El cuello sigue siendo el alimento (ronda 1, 05). Lo que hay que vigilar es que el costo en madera de los motores de la edad I no retrase el hito II:
- taller, 120;
- corral, 120;
- gult, 100 + 40;
- almacén real, 200, que Ayutthaya ya tiene;
- mocambo, 130.

**Requiere modelo.**

---

## 8. Implementación

**Lo que ya existe** (`sim_mods.gd`, `sim.gd`, `data/`):
- `renta` (gult, barrios);
- `recurso_propio` (mit'a, fama);
- `saqueo` y `liberacion`;
- `cantidad` y `deja` (roza → yerbal);
- `bono_agua_pct` y `bono_ladera_pct`;
- `caminos` con `bono_conectado_pct`;
- `acogida`;
- `empaca_en` y `despliega_en` (la corte que se muda);
- `costo_extra` de los hitos;
- sitios sagrados con renta;
- mercado;
- `_res_sym`.

**Piezas nuevas (diez), todas como parámetros de módulo:**

| # | Pieza | Qué es | Para quién |
|---|---|---|---|
| 1 | `maximo_por_edad` y `vecindad` (radio, %) por tipo de edificio | Topes R2 y R3 | Todas |
| 2 | `conversion` con interruptor | Consume X/min de un recurso y da Y/min; solo corre si hay stock | Taller inca |
| 3 | `rebano` | Cabezas que crecen hasta un tope (más en pradera), renta por cabeza, orden "faenar todo", el daño mata cabezas | Corral mapuche |
| 4 | `subproducto` en el depósito | Un % de lo entregado de ciertos recursos se suma como riqueza, con tope por minuto y por edificio. Se engancha en `_do_return` | Almacén real |
| 5 | `oficio` | Puestos dentro de un edificio que rinden por ocupante; cupo; la acogida llena el cupo | Mocambo y cerca real |
| 6 | `extrae` | Un edificio desplegado cerca de una fuente la consume sin aldeanos (el ovoo) | La corte etíope |
| 7 | Sucesión con pase automático, cola de rozas y bandera; tope de yerbales que deja capuera | Ajuste en `_exhaust` y en el depósito | Guaraníes |
| 8 | `bono_cerca_de` (tipo, radio, %) y bono conectado aplicado a la recolección | Gult cerca de la corte, barrio chino, barreal inca | Etiopía, Ayutthaya, Tawantinsuyu |
| 9 | Mapa | Barreal en lugar del yacimiento (`recursos.json`), barreal de flanco, sitios espejados con renta decreciente, ingenios o estancias neutrales con guardia, botín único y reconstrucción, mercado mínimo 60 | Común |
| 10 | Tope por minuto en `saqueo`, efecto `motor_pct` para la tecnología de la edad III e informe de riqueza por origen, PMP y OPA en el torneo | Medir y cerrar | Común |

**Datos que cambian sin código nuevo:**
- kulliñ → riqueza en los costos mapuches;
- se quita `oculto` del mocambo;
- se quita la renta de 8 de los barrios;
- la renta del aqllawasi pasa a ser la tecnología de motor;
- roza de 550 a 750 y tasa de 1250 a 1100;
- yerbal de 400 a 300;
- costos y renta del gult.

**IA, con reglas simples:**

| Civ | Regla |
|---|---|
| Tawantinsuyu | Taller cuando mit'a ≥ 50 y talleres < máximo; camino al barreal una vez por barreal |
| Mapuches | Corral a ≥ 8 casillas de otro, en pradera si hay; faenar solo si falta alimento para el hito |
| Guaraníes | Cola de rozas siempre en 2 o más; bandera junto al bosque más cercano |
| Etiopía | Gult a ≤ 14 casillas de la corte; mudar cuando el barreal de la corte se agota |
| Palmares | Cupo 3 en todo mocambo desde la edad II |
| Ayutthaya | Almacén junto al bosque con más árboles; barrio chino entre dos almacenes |
| Todas | Reservar lo que pide el próximo hito (ronda 1) |

---

## 9. Autoevaluación contra la lista de control

| # | Criterio | Estado | Por qué |
|---|---|---|---|
| 1 | Dos capas claras en palabras llanas | **Cumple** | §3 y fichas (§10). Dos civs usan el barreal igual, y lo digo |
| 2 | Esfuerzo parejo por fase (±×1,5) | **Cumple en la estimación**; requiere modelo | OPM total entre ×1,07 y ×1,13. La OPA del motor solo llega a ×1,67 en Ayutthaya, fase 1 (§6) |
| 3 | Curvas a los 5, 10, 20 y 30 min dentro de ±15 % | **No está asegurado** | El premodelo cumple hasta el minuto 20. A los 30, guaraníes +18 % y Etiopía −14 %. Hay palancas definidas |
| 4 | Edad II entre 6:30 y 9:00 y edad III antes de 20:00, sin lo disputado | **Requiere modelo** | La riqueza alcanza de sobra. El riesgo es la madera de los motores y el alimento |
| 5 | Viable en los 11 mapas | **Cumple en la tabla**; requiere torneo | Ninguna celda pasa de ±6 % y hay plan B en cada una. Valle, altiplano y selva están en el límite de 10 puntos entre civs |
| 6 | Nada se rompe con el mapa revelado | **Cumple en el diseño**; falta la crítica del que intenta romperlo | Sin secreto, con topes por edad y por minuto, y lo disputado que se agota. Lo que hay que atacar: Etiopía con la corte en el centro y Ayutthaya en mapas de mucho bosque |
| 7 | Ni comercio genérico ni dependencia de estar oculto | **Cumple** | Ayutthaya sin renta de barrios; Palmares sin `oculto`; ningún carro ni ventana de tiempo |
| 8 | Lo disputado con techo por edad y remontada | **Cumple en el diseño**; requiere modelo para el techo real | Los mecanismos están (§2). El porcentaje real sale del torneo con el informe por origen |
| 9 | La IA lo juega con reglas simples | **Probable** | Una regla por civ (§8). Lo más delicado: la mudanza de la corte y la bandera de roza |
| 10 | Fiel a la historia o con simplificación declarada | **Cumple con marcas** | El barreal es una simplificación declarada. Quedan `[verificar]`: sal mapuche, inca y siamesa; tinajas guaraníes; aríbalos; hornos siameses; mercaderes chinos de la corona |

---

## 10. Fichas para el autor (5 líneas por civ)

**Tawantinsuyu**
1. **Qué hacés:** tus runa juntan turnos de trabajo solos, y vos ponés talleres de tejido que convierten esos turnos en riqueza.
2. **Qué recibís:** 24 de riqueza por minuto por taller, sin aldeanos, y un barreal que rinde 20 % más si lo unís con un camino.
3. **Qué te pide:** decidir si el trabajo va a tela, a caminos o a soldados; podés apagar un taller cuando necesitás tropa.
4. **En qué es distinta:** es la única cuya riqueza compite con su propia obra: cada camino es tela que no se tejió.
5. **De dónde sale:** el Estado inca cobraba en trabajo (mit'a), no en dinero, y la tela fina (cumbi) era su regalo más valioso (Murra).

**Mapuches**
1. **Qué hacés:** construís corrales; el ganado crece solo y se ve pastando.
2. **Qué recibís:** 4 de riqueza por minuto por cabeza, hasta 5 por corral (6 en pradera). Si te falta comida, faenás un corral entero.
3. **Qué te pide:** elegir dónde va cada corral (lejos rinde más, pero se ve) y cuándo comerte el capital; el malón suma, con tope.
4. **En qué es distinta:** su riqueza es un activo vivo que crece, se come y se roba. No necesita pelear para tenerla.
5. **De dónde sale:** el ganado era riqueza, dote y prestigio de los caciques, y el malón lo arreaba (León Solís; `mapuches.md` M1 y M2).

**Guaraníes**
1. **Qué hacés:** abrís rozas en lugar de granjas; cuando una se agota, el mismo aldeano sigue en el yerbal que deja.
2. **Qué recibís:** comida primero y riqueza después, en el mismo lugar. Si dejás rozas en cola, se abren solas donde pusiste la bandera.
3. **Qué te pide:** decidir dónde va la bandera y cuántas rozas dejás en cola: comida ahora o riqueza dentro de diez minutos.
4. **En qué es distinta:** la riqueza es lo que queda de la comida; la base avanza sobre el monte y casi no necesita el barreal.
5. **De dónde sale:** la chacra vieja (*kokuéra*) se volvía huerto y yerbal (Noelli et al.), y la yerba fue moneda de la región.

**Etiopía**
1. **Qué hacés:** repartís tierras (gult) que pagan tributo, y mudás la corte, que se come el barreal que tiene al lado.
2. **Qué recibís:** cada gult paga riqueza y algo de comida, un tercio más si está cerca de la corte; la corte saca riqueza del barreal sin aldeanos.
3. **Qué te pide:** elegir dónde reparte y a quién (señor o regimiento), y cada 5 a 8 minutos si la corte se muda.
4. **En qué es distinta:** su mapa económico se mueve con la capital.
5. **De dónde sale:** el rey daba y quitaba señoríos, y la corte acampaba y agotaba su entorno (Álvares; Berhane-Selassie).

**Palmares**
1. **Qué hacés:** la fama trae gente sin pagarla, y vos decidís si va al campo o a un oficio dentro del mocambo.
2. **Qué recibís:** 15 de riqueza por minuto por persona en un oficio, sin caminar y sin agotar nada, protegida dentro de la cerca.
3. **Qué te pide:** fijar el cupo de cada mocambo una vez; los que llegan lo llenan solos. Las correrías a ingenios traen gente y botín.
4. **En qué es distinta:** su riqueza es la gente; no fabrica aldeanos, los recibe.
5. **De dónde sale:** riqueza medida en personas (economía política centroafricana) y las cuarenta herrerías de 1694 (`palmares.md`).

**Ayutthaya**
1. **Qué hacés:** tus leñadores y cazadores entregan en el almacén real, que se queda con una parte para el rey.
2. **Qué recibís:** un cuarto de esa madera y esa caza vuelve como riqueza, hasta 24 por minuto por almacén; el barrio chino al lado sube el tope.
3. **Qué te pide:** elegir dónde va cada almacén (uno por edad) y qué barrio extranjero recibís: el chino para la economía, el japonés o el portugués para la guerra.
4. **En qué es distinta:** es la única que saca riqueza de la madera; sus socios extranjeros viven dentro de su ciudad, pero no comercian por ella.
5. **De dónde sale:** los productos del monte eran monopolio del almacén real, el Phra Khlang (Narai, 1662; cueros a la VOC, 1664).

---

## Anexo · Lo que descarté y por qué

| Propuesta | Origen | Por qué no |
|---|---|---|
| Sal como fuente común | Ronda 1, síntesis, v2/01 | Palmares la compraba y en el Paraguay escaseaba (§1.1) |
| Interés sobre la riqueza guardada (mapuches) | v2/01 | Premia acumular y no se ve |
| Faenar cabeza por cabeza | v2/02 | Con la cría, era una fábrica de comida cliqueable (ritual) |
| Gult que rinde solo dentro del radio de la corte | v2/02 | Mudarse apagaba la economía; quedó como bonificación de +33 % |
| Oro como escalón del gult (Etiopía) y dorar el wat (Ayutthaya) | v2/04 | Más piezas sin decisión nueva; queda para las campañas |
| Aldeas ocultas que rinden mientras no se las vea | v2/02 | Prohibido (F); el final las rompe |
| Casa de farinha | v2/01, v2/04 C | Era la más parecida a un mercado |
| Forja que convierte madera en riqueza (Palmares) | v2/04 B | Choca con Ayutthaya; queda como tecnología de la edad III |
| Barrios que rinden por sus vecinos como motor | v2/02 | Segundo motor de renta; con lectura de comercio. Quedan como modificador y vía militar |
| R3 global (2.ª y 3.ª copia al 70 y 50 % en todo el mapa) | v2/05 | Junto con el máximo por edad, deja todos los motores por debajo del 30 % de R5; pasa a R3 por cercanía |
