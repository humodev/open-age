# 34 · 04 · Revisión de la iteración 2, a dos voces

> Pedido: los dos expertos miden lo nuevo de la iteración 2 (2a: golpe del aldeano, hitos de 150/180/210 s, la III con 100 de piedra, empalizada a 8, sumidero sin fin y guardia de distancia; 2b: bloqueo de rutas y comercio en el 1v1). La vara es la [revisión 1](02-revision-iteracion-1.md).

**Voces:** **V** = veterano competitivo de AoE4. **C** = constructor de partidas largas en equipo.
**Método:** main en a1a2d5b (hash 366120853), todo headless y de a un Godot por vez (con un torneo corriendo al lado):
- 12 partidas 1v1 de 25 minutos, experta contra experta, en llano: los mismos cuatro cruces de la revisión 1, con las semillas 7, 11 y 3. Los datos van sin parches. El guion es [partidas.gd.txt](pruebas-revision-2/partidas.gd.txt), el de la revisión 1 con la primera muerte militar arreglada, las bajas antes del minuto 12 y **qué parte de la renta de sitios cobra el que va atrás en edad**;
- `tools/micro_matriz.gd` en la IV, con compras y 5 variantes: guardia de distancia y golpe del aldeano;
- `tools/comercio_medida.gd`: un 2v2 de 45 minutos con la semilla 7 (la 3 ya estaba en [pruebas-it2](pruebas-it2/2v2-s3.txt));
- `tools/sumidero_iv.gd`: 2v2 con las semillas 7 y 3 (la 11 ya estaba en [pruebas-2a](pruebas-2a/sumidero-despues.txt));
- `tools/primera_victoria.gd`: se toma la del orquestador, que da 7 de 8.

Las salidas están en [pruebas-revision-2/](pruebas-revision-2/).
**Advertencia:** es IA contra IA, con pocas semillas, y la IA no rushea, no amuralla con empalizada y no ataca hitos en obra. Lo que depende de eso queda **sin medir**, y lo decimos en cada caso.

## 1. Lo nuevo, medido

### 1.1 Hitos de 150/180/210 s y la III con 100 de piedra

| | Revisión 1 (hitos parcheados, 16 partidas) | Ahora (12 partidas) |
|---|---|---|
| III: mediana (cuántos llegan) | 15:58 (13 de 16) | **16:08** (19 de 24) |
| III más rápida | — | 12:45 (mapuches), 12:50 (Ayutthaya) |
| Primera muerte militar | sin dato (el guion fallaba) | **4:00–7:40**; 8 a 39 bajas militares por jugador antes del 12 |
| Cierres antes del 25 (incluye a los 25:00 justos por sitios) | 3 de 8 | **4 de 12** (1 por conquista a las 20:08, 3 por sitios) |
| El primero en la III gana | — | **9 de 12** |

- **V:** «Hay pelea temprana: la primera baja militar llega entre el 4 y el 7, y antes del 12 caen de 8 a 39 soldados por lado. Eso antes no estaba. Ahora, ¿ventana de ataque? La hay en los papeles: 3 minutos de hito de la III en obra. Pero la IA no la usa nunca y no podemos decir si el fast castle se puede contrarrestar. Lo que sí vemos es que es *el* plan: el que llega primero a la III gana 9 de 12. Con la III a 1000 de alimento y 600 de riqueza, a la IA la frena la economía, no la obra: la mediana no se movió (16:08), y la meta era 14:30.»
- **C:** «La piedra a 100 hizo lo que pedí: la III ya no compite con el segundo centro: en 11 de 24 jugadores se levanta al menos un centro más. Pero en 12 partidas no hubo ni un ataque a un hito, y para mí es lo más importante del ritmo.»

### 1.2 Empalizada a 8: ¿se amuralla menos? ¿Paga el raid?

**Sin medir en la IA,** porque no la usa (0 en 24 jugadores; ningún archivo de la IA nombra `empalizada`). La muralla de piedra aparece en 6 de 24, igual que antes (6 de 32). Aldeanos muertos antes del 12: 0 a 2 por jugador, salvo uno (Etiopía, 13, contra Palmares en la semilla 7). El raid de la IA no existe, así que no se puede decir si paga.
- **V:** «La cuenta de la revisión 1 sigue valiendo: a 8, cerrar una madera cuesta 320, casi lo de 5 guerreros. Con humanos va a ser una decisión. Para medirla, la IA tiene que rushear: sin eso, no hay vara.»

### 1.3 El golpe del aldeano

| Pelea (IV, capa común) | Gana A | Costo |
|---|---|---|
| 4 aldeanos contra 1 explorador | 4/5 | 200 / 80 |
| 6 aldeanos contra 2 guerreros | 0/5 (los guerreros quedan 2,0 de 2 vivos) | 300 / 170 |

- **V:** «Está bien así: el aldeano espanta al explorador, pero no para un raid. Para eso está el lancero.»

### 1.4 El bloqueo de rutas

| 2v2, 45 min | Cortes | Comerciantes muertos | Comercio del equipo que lleva la edad | Comercio del otro | Comercio después del 30 |
|---|---|---|---|---|---|
| Semilla 3 ([it2](pruebas-it2/2v2-s3.txt)) | 23 | 30 | 10 847 (equipo 1) | 1606 | 28 % |
| Semilla 7 (nueva) | 14 | 32 | **20 570** (equipo 0, en la IV desde antes del 30) | **1251** (en la III) | **54 %** |

En la semilla 7, **todos los cortes y todas las muertes los sufre el equipo que va atrás**, y los suyos no despejan nunca: 37 esperas y ningún retome que pague. En el 1v1 hay 7 cortes en 12 partidas, siempre contra Etiopía, que iba atrás.
- **C:** «Ahora sí hay pelea por el mapa: plantar 3 de población corta, y la IA lo hace. Es lo que pedí. Pero el bloqueo lo gana el que tiene más ejército, y ese es el que va adelante. La herramienta para frenar al que lidera se volvió otra forma de ahogar al que va atrás. Y el 2v2 se pasó de la meta (54 % contra 30–45 %).»
- **V:** «Despejar se puede en teoría: si mandás tropa, el corte se libera. Pero para despejar hay que ganar la pelea, y entonces no es contrajuego: es ganar la pelea.»

### 1.5 Sitios y comercio en el 1v1: ¿quién cobra?

| 12 partidas 1v1 | Valor |
|---|---|
| Sitios en la riqueza total | 19,5 % (26 508 de 135 640) |
| **Renta de sitios que cobra el que va atrás en edad** | **4,5 %** (1184 de 26 508; meta de la revisión 1: 30 %) |
| Comercio en la riqueza total | 8,6 % (meta ≤ 15 %) |
| Partidas con un jugador sin ningún viaje | 7 de 12 (antes, 12 de 16) |

- **V:** «El comercio desde la II funcionó a medias: 5 jugadores más hacen viajes. Los sitios siguen siendo del que va adelante: 2405 contra 199, 2075 contra 553. Es lo que peor está del diseño.»

### 1.6 El sumidero sin fin

| 2v2 | Fin | Alimento sin gastar en la IV (promedio, el peor) | Riqueza al final (la más alta) | Repetibles | Guardias |
|---|---|---|---|---|---|
| Semilla 11 ([2a](pruebas-2a/sumidero-despues.txt)) | 45:00 | 2158 | **15 436** | 8 + 5 | 6 + 0 |
| Semilla 7 | 35:50, por sitios | 367 | 597 | 0 + 1 | 0 + 1 |
| Semilla 3 | 39:06, por sitios | 548 | **4137** | 3 + 5 | 0 + 1 |

- **C:** «El alimento ya no se apila: cumple la meta de menos de 5000 en las tres. Pero **no hay elección**. En las semillas 7 y 3 los cuatro que llegan a la IV eligen el camino de la guerra; después compran lo mismo, más caro cada vez. Las guardias casi no salen (1 en dos partidas), porque llegan con 206 a 210 de población sobre 200. Con el tope lleno, la guardia no es sumidero: es reemplazo. Y la riqueza sobra (4137 y 15 436), porque nada de la IV la pide.»
- **V:** «Una repetible sin tope a +50 % es un impuesto, no una decisión. Que sirva para que no se apile está bien, pero no suma diversidad.»

### 1.7 La guardia de distancia: ¿rompe el triángulo?

Matriz de la IV, con compras, a costo parecido (A / B):

| Pelea | Gana A | Costo |
|---|---|---|
| 5 guardias de distancia contra 5 guardias, sin micro | 0/5 | 2250 / 2250 |
| Lo mismo, **escalonando** | **4/5** (con «mantener + escalonar», 5/5) | 2250 / 2250 |
| 5 guardias de distancia contra 26 guerreros, sin micro | 0/5 | 2250 / 2210 |
| Lo mismo, **escalonando** | **5/5** (quedan 3,4 de 5) | 2250 / 2210 |
| 5 guardias de distancia, escalonando, contra 13 jinetes | 0/5 | 2250 / 2210 |
| 5 guardias de distancia contra 22 lanceros | 2/5 | 2250 / 2090 |
| 5 guardias de distancia contra 30 honderos | 0/5 | 2250 / 2250 |

- **V:** «La rompe a medias. El jinete la sigue matando (0 de 5): esa pata está bien. Pero con alcance 6 y un tiro cada 1,75 s, la guardia de distancia escalona y le gana al choque de a pie a igual costo, 5 de 5 contra 26 guerreros y 4 de 5 contra la guardia, que es su contador declarado. Es el mismo problema del hondero de la I, ahora en la élite y con alcance 6 contra 5,5. Y a 2 de población vale lo de 5 lanceros o 6 honderos en el ejército de 200: en la IV llena, pesa.»
- **C:** «Contra 22 lanceros pierde 3 de 5, que debería ser su presa. Por costo no es la reina; por población, sí. Y para el que tiene el tope lleno, la población es lo que importa.»

## 2. La vara, área por área (del 0 al 10)

| Área | Iteración 1 | Ahora | Por qué |
|---|---|---|---|
| Diversidad de estrategias | 5 | **5** | La III rápida existe (12:45), pero es el único plan que gana (9 de 12). Sin rush, sin empalizada y sin elección en la IV (todos eligen la guerra) |
| Contadores y contrajuego | 7 | **6** | Se suma otro caso en que la micro le gana al contador: la guardia de distancia escalonando contra el choque de a pie (5/5). Lo del hondero sigue sin medir con reacción humana |
| Información y scouting | 5 | **5** | El aviso de corte con lugar suma poco. Faltan el vigía de la I y la regla del sigilo |
| Control del mapa | 6 | **6** | El bloqueo funciona (23 y 14 cortes por 2v2), pero los sitios y las rutas van al que lidera: 4,5 % y 1251 contra 20 570 |
| Techo de habilidad | 6 | **6** | Escalonar con la guardia de distancia y cortar rutas con 3 de población suman techo. Los consejos de decisión siguen en el modo competitivo |
| Ritmo y decisiones | 4 | **5** | Pelea desde el 4–7; los equipos tienen eventos de mitad de partida (cortes). La III sigue en 16:08 y los cierres antes del 25 no suben (4 de 12) |
| Asimetría | 6 | **5** | Mapuches ganan 6 de 6; guaraníes, 0 de 3 (llegan a la III una vez, a las 24:32); Palmares, 1 de 6, y en la semilla 11 no llega ni a la II. La guardia común iguala la IV |
| Varianza | 6 | **6** | Sin cambios. La primera victoria de 7 de 8 dependió de ajustar la fácil, no del azar |
| **Promedio** | **5,6** | **5,5** | Meta de la iteración 2: 6,5 o más. **No se cumple** |

**Lectura:** la iteración 2 arregló lo que estaba roto (golpe, bloqueo, alimento apilado). Pero no tocó lo que hace al diseño competitivo: la vuelta y la elección. Con lo nuevo aparecieron dos cosas que bajan nota: la guardia de distancia y la bola de nieve del bloqueo.

## 3. ¿Qué tan cerca de un diseño de esport?

**Lejos.** Un RTS de esport anda por 8 en esta vara. Estamos en 5,5, más o menos donde estaba AoE4 antes de su primer gran parche: el combate está bien encaminado, pero la macro se decide sola. El que llega primero a la III gana 9 de 12. Los sitios dan el 95 % de su renta al que va adelante, y el bloqueo, que tenía que frenarlo, también juega para él. Además, todo lo que mide contrajuego es IA contra IA: ni el fast castle ni el raid ni la empalizada se pueden juzgar hasta que la IA rushee y ataque hitos, o hasta que jueguen humanos.

**Los 5 cambios que faltan, en orden:**

| # | Cambio | Números | Meta medible |
|---|---|---|---|
| 1 | Sitios que no se acumulen en el que lidera (§4, sin ventaja para el que pierde) | rotación cada 4 min a un punto equidistante, o renta con guarnición de 2 de población, a la vista de todos | el que va atrás cobra el 20 % o más de la renta de sitios (hoy, 4,5 %) |
| 2 | Hito en obra que se pueda atacar, y la IA que lo ataque | hito en obra con el 50 % de los PV hasta terminar; la experta ataca el hito si su ejército es ≥ 0,8 del rival. III a 800 A / 500 R / 100 P | el primero en la III gana 7 de 12 o menos; mediana de la III ≤ 14:30 |
| 3 | Comercio con rendimiento decreciente y escolta | cada comerciante después del 8.º en la misma ruta rinde un 10 % menos (piso, 40 %); el corte pide 3 de población **más que** la escolta en 8 casillas, no «sin tropa propia» | 2v2 en 30–45 % (hoy, 28 y 54); los cortes repartidos entre los dos equipos |
| 4 | Guardia de distancia que no le gane a su contador | alcance 6 → 5, velocidad 1200 → 1100; y la `micro_matriz` con 400 ms de reacción para ella y para el hondero | la guardia gana 3/5 o más contra la de distancia escalonando a igual costo (hoy, 1/5) |
| 5 | Cerrar la asimetría de abajo | emboscada guaraní (+50 % al primer golpe desde el monte con sigilo); Palmares con la II a menos de 8:30 (hoy, 8:44–11:59) | ningún pueblo con 0 de 3 ni con 6 de 6 en el lote de 12 |

Fuera de los cinco y necesario para medir: **la IA tiene que rushear y amurallar con empalizada en 1 de cada 4 partidas.** Sin eso, la empalizada a 8 y el raid quedan sin vara.

## 4. Sitios: dos alternativas al +50 % del que va atrás

El autor no quiere ayudas al que pierde. Entonces, en vez de premiar al que va atrás, hay que hacer que **tener muchos sitios cueste**. Las dos son simétricas: valen igual para cualquiera.

**A. Sitios que rotan (V).** Cada 4 minutos se apaga el sitio más viejo y aparece otro, neutral, en un punto equidistante de las bases (como los mercados neutrales, que ya se ubican con 3 % de diferencia). Se toma en 10 s, como hoy. La victoria por sitios cuenta los sitios vivos, y su cuenta se reinicia con cada rotación que cambie de dueño.
- Por qué sirve: el que va adelante no puede atrincherarse (no hay torres ni muros en un sitio que tiene 4 minutos). Cada rotación es una pelea pareja en un lugar nuevo, como los sagrados del AoE4 en el pool competitivo.
- Números: `sitios.rotacion_ms` 240 000, `sitios.rotan` 1 por vez y 2 minutos de aviso en el minimapa.

**B. Sitios con guarnición y a la vista (C).** Un sitio solo rinde si el dueño tiene 2 o más de población militar a 4 casillas. Si no, la renta se congela; no pasa al rival. Además, lo que el dueño tiene en ese radio lo ven todos.
- Por qué sirve: con 3 sitios, el que lidera tiene 6 de población repartida en 3 puntos que el rival ve. El que va atrás elige dónde pegar con superioridad local, que es el juego de AoE4 contra un rival estirado. No recibe nada gratis: tiene que ganar esa pelea chica.
- Números: `sitios.guarnicion_pob` 2, `sitios.vision_publica` 4 casillas. Con 3 sitios, la renta de 60/45/30 se queda; el costo es de ejército, no de recursos.

**Cómo medirlas:** el mismo lote de 12 partidas. Meta: el que va atrás cobra el 20 % o más (hoy, 4,5 %), y el primero en la III no pasa de 8 de 12. Preferimos B: es más barata de programar, la IA la entiende (le alcanza con «mandá 2 a cada sitio») y no mueve el mapa.

## 5. ¿En qué gastar la riqueza que sobra en la IV?

Hoy nada de la IV pide riqueza: las repetibles y las guardias van con alimento y madera, y por eso sobran 4137 y 15 436. Tres opciones con identidad:

1. **Leva de un pueblo (C).** Con 800 de riqueza, aparece en el centro una tanda de 6 tropas del pueblo, que no ocupan población por 3 minutos y después se van. Cada pueblo tiene la suya: malón mapuche (jinetes), mita (honderos), ejército de los ras (lanceros montados), quilombolas, mercenarios de Ayutthaya y la leva del monte guaraní. El costo sube un 50 % cada vez, como las repetibles. Saca la riqueza del tope de población, que es justo lo que hoy traba las guardias.
2. **Tributo a la causa (V, para equipos).** Con 1000 de riqueza, el equipo suma 1 sitio virtual por 5 minutos en la cuenta de victoria por sitios, sin renta. Gastar riqueza acerca la victoria por sitios, y el rival lo ve en la cuenta. Es una carrera abierta que se puede contestar.
3. **Obras de legado.** Es un edificio único por pueblo en la IV, con 1500 de riqueza y 500 de piedra, y da un aura de 12 casillas. Puede ser el ushnu inca, que da +1 de armadura a las torres, o el rewe mapuche, que entrena un 20 % más rápido. Si cae, se pierde. Le da al final un objetivo de mapa que no es el centro.

**Preferimos la 1:** es la única que convierte riqueza en una decisión de combate (cuándo la soltás) y la única que no choca con el tope de población.

## 6. Dónde coinciden y dónde no

**Coinciden:**
- la iteración 2 arregló errores, pero no le dio vuelta a la partida;
- el bloqueo anda, pero juega para el que lidera;
- la guardia de distancia necesita alcance 5;
- sin una IA que rushee y ataque hitos no se puede juzgar el ritmo.

**No coinciden:**
- **Sitios:** V prefiere la rotación (A), por la pelea pareja; C prefiere la guarnición (B), porque la entiende la IA y sirve en 4v4.
- **Riqueza:** C quiere la leva; V cree que la leva vuelve a darle ventaja al que más riqueza tiene, que es el que va adelante, y prefiere el tributo a la causa, que el rival ve venir.
