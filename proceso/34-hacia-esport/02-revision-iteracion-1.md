# 34 · 02 · Revisión de la iteración 1, a dos voces

> Pedido: los dos expertos juegan y miden lo nuevo de la iteración 1 (1a: triángulo, lancero en la I, sitios, asedio esquivable; 1b: comercio), y lo comparan con la vara de la [ronda 8 · 04](../22-testers/ronda-8/04-jugabilidad-competitiva.md). Solo jugabilidad competitiva, sin infraestructura.

**Voces:** **V** = veterano competitivo de AoE4. **C** = constructor de partidas largas en equipo.
**Método:** main en 78c5317 (hash 1417676642). Todo headless, de a un proceso de Godot por vez:
- `tools/micro_matriz.gd` en la edad I, 5 variantes por pelea;
- 16 partidas 1v1 de 25 minutos, experta contra experta, en llano: cuatro cruces (mapuches–guaraníes, Etiopía–Palmares, Ayutthaya–Tawantinsuyu, Palmares–mapuches) con las semillas 7 y 11. Corren dos veces: con los hitos de hoy y con hitos de 150/180/210 s, parcheados en memoria. El guion es [partidas.gd.txt](pruebas-revision-1/partidas.gd.txt), que no toca `data/`;
- `tools/comercio_medida.gd`: un 2v2 de 45 minutos con la semilla 3;
- `tools/sumidero_iv.gd`: un 2v2 de 45 minutos con la semilla 11.

Las salidas están en [pruebas-revision-1/](pruebas-revision-1/).
**Advertencia:** todo es IA contra IA, con pocas semillas. Las notas son nuestro juicio sobre el diseño, no lo que dice un torneo.

## 1. Lo nuevo, medido

### 1.1 El triángulo y el lancero de la I

Matriz de la edad I, capa común. Cada fila dice cuántas de las 5 peleas gana A y, al lado, el costo de A contra el de B.

| Pelea | Gana A | Costo |
|---|---|---|
| 5 lanceros contra 5 guerreros | **4/5** | 475 / 425 |
| 5 lanceros contra 6 guerreros (igual costo) | **5/5** | 475 / 510 |
| 6 honderos contra 5 lanceros, sin micro | 5/5 | 450 / 475 |
| 6 guerreros contra 7 honderos, sin micro | 4/5 | 510 / 525 |
| 7 honderos **escalonando** contra 6 guerreros | **5/5** | 525 / 510 |
| 5 lanceros (guaraníes) contra 5 jinetes nobles (Etiopía) | 3/5 | 475 / 600 |
| 5 lanceros contra 5 weichafe (mapuches) | 5/5 | 475 / 425 |

- **V:** «El lancero de la I para al choque: gana mano a mano y sale más barato. El raid de guerreros ya tiene respuesta antes de que llegue a la madera. El jinete noble etiope gana 2 de cada 5 contra lanceros que cuestan un 20 % menos: eso es un pueblo con identidad, no un agujero. Ojo con una cosa: el hondero que escalona le gana **5 de 5** a su contador a igual costo, y en la II ya pasaba lo mismo (10 contra 10, [01a](01a-cambios-competitivos.md)). Que la micro premie está bien. Pero el bot reacciona en 0,2 s, y si un humano lo logra, el choque deja de ser contador.»
- **C:** «¿Hay rush viable? A medias. El guerrero ya no sirve contra quien saca dos o tres lanceros, y en la I no hay otra unidad rápida. En las 16 partidas la IA no rushea nunca: la primera toma de sitio es lo primero que pasa. El rush de la I queda para Etiopía y mapuches, que es como tiene que ser.»

### 1.2 Los sitios (60/45/30 desde la II)

| | Hitos de hoy | Hitos de 150/180/210 |
|---|---|---|
| Primera toma (rango) | 6:18–13:38 | 6:28–9:49 |
| Tomas por partida (los dos jugadores) | **11,0** | 9,2 |
| Parte de la riqueza que viene de los sitios | **18 %** | 18 % |
| Partidas cerradas antes del minuto 25 | 1 de 8 (por sitios) | **3 de 8** (1 por sitios, 2 por conquista) |

- **V:** «Ahora sí se pelean: cambian de mano 9 a 11 veces por partida y salir de la base paga. Pero miren quién cobra. En mapuches–guaraníes (semilla 7), 2286 contra 264; en Ayutthaya–Tawantinsuyu, 1832 contra 440. El que va adelante en edad se queda con los sitios: hoy amplifican la ventaja en vez de dar una vuelta.»
- **C:** «Y quien está en la I no los toma, solo los frena. Con la II del rival a las 12–16 (Palmares), son 6 a 10 minutos mirando cómo el otro cobra 135 por minuto.»

### 1.3 El asedio esquivable y el ataque al suelo

La matriz de [01a](01a-cambios-competitivos.md) basta: 10 honderos contra 2 catapultas y 4 lanceros pierden 0 de 5 sin micro y ganan **5 de 5 esquivando**. La formación abierta sola no alcanza (0 de 5).
- **V:** «Es la micro que más separa en AoE, y ya está. El anillo rojo lo hace legible. Falta medirlo con reacción humana: el bot reacciona en 200 ms; hay que probar con 400 y 600 ms.»
- **C:** «Con el ataque al suelo, el asedio por fin ataca zonas, no unidades: sirve para cerrar una puerta o un paso. La IA lo usa con 3 o más amontonados. Bien.»

### 1.4 El comercio

| Partida | Comercio / riqueza | Comerciantes muertos | Rutas cortadas por presencia |
|---|---|---|---|
| 1v1 de 25 minutos, 16 partidas (las nuestras) | **7–8 %** del total; hasta el 20 % del que va adelante | 5 en total | **0** |
| 1v1 de 30 minutos, semillas 7 y 11 ([33/02](../33-comercio/02-implementacion.md)) | 13–14 % antes del 25 | 8 y 1 | 0 |
| 2v2 de 45 minutos, semilla 3 (nueva) | **45 %** después del 30; equipo 1: 15 268, equipo 0: 2661 | 11 | 0 |
| 2v2 de 45 minutos, semillas 7 y 11 (33/02) | 20 y 37 % | 29 y 45 | 0 |

- **¿Domina el 1v1 corto?** No: es el 7–8 % de la riqueza. Lo cobra solo el que llegó a la III, y en 12 de 16 partidas uno de los dos no hizo ni un viaje.
- **¿Vale en el equipo largo?** Sí: en el 2v2 de la semilla 3, el equipo que comercia junta 5,7 veces más por comercio, y esa riqueza lo define.
- **¿Se puede cortar?** Solo matando al comerciante: van 85 muertos en tres 2v2. El bloqueo por presencia (6 de población a 6 casillas, sin tropa propia) no se activó **nunca** en 20 partidas.
- **V:** «En el 1v1 el comercio no genera pelea: es un bono para el que ya ganó la carrera de edades.»
- **C:** «En el equipo largo sí genera pelea, y es lo que quería: una ruta atacada que decide algo. Pero cortar una ruta debería poder hacerse plantando tropa, no solo cazando burros.»

### 1.5 La muralla de piedra y la empalizada

En las 32 partidas, la IA levanta un lienzo de piedra recto de 11 a 16 tramos, con puerta y 2 torres, en **6 de 32**. Empalizada, ninguna, porque la IA no la usa. Para la persona hicimos la cuenta:

| | Empalizada a 4 de madera | A 8 |
|---|---|---|
| Cerrar una madera (~40 casillas) | 160 de madera, ~3 min de un aldeano | 320 de madera, ~6 min |
| Anillo de la base (~60 casillas) | 240 de madera (menos que 3 guerreros) | 480 (lo que cuestan 5 guerreros) |
| 5 guerreros rompen un tramo (300 PV, ~5 por golpe por el ×0,45) | ~15–19 s | igual |

- **V:** «A 4, cerrar la madera cuesta el 40 % de lo que cuesta el raid que para. Con la empalizada, el raid de la I no tiene sentido. "Todos amurallan" no se ve en la IA, pero en humanos sí se va a ver.»
- **C:** «La muralla de piedra está bien donde está: la IA amuralla en 1 de cada 5 partidas, y solo cuando la vinieron a buscar. A 8, la empalizada pesa en la I y la II. Después, con la economía de la III, ni se nota, y en el formato largo me sigue sirviendo. Acepto el 8.»

### 1.6 El sumidero de la IV

2v2 de la semilla 11: Tawantinsuyu elige el camino del asedio a las 23:45, compra las 5 repetibles y entrena 13 guardias. Aun así termina con **17 643 de alimento sin gastar**. Guaraníes eligen el camino de defensa a las 41:21 y entrenan 2 guardias. Con la ronda 8/05 (19 000 de alimento sin gastar) son dos semillas que dan lo mismo.
- **V:** «La elección existe (3 caminos excluyentes), pero dura cinco compras. Después, el alimento se apila.»
- **C:** «Para el equipo largo es lo más flojo: a partir del minuto 35 no hay en qué gastar.»

## 2. La vara, área por área (del 0 al 10)

Ronda 8 no puso números. La nota de «antes» es la que le ponemos hoy a lo que describimos entonces.

| Área | Antes | Ahora | Por qué |
|---|---|---|---|
| Diversidad de estrategias | 4 | **5** | Hay plan de mapa (sitios) y defensa barata contra el raid. La III sigue a las 16:46 de mediana: la III rápida todavía no es un plan |
| Contadores y contrajuego | 5 | **7** | El contador gana mano a mano (lancero contra jinete, de 0/5 a 4/5) y el área se esquiva. Quedan el hondero que escalona y le gana a su contador, el arcabucero y el elefante sin medir |
| Información y scouting | 5 | **5** | Sin cambios de fondo. Suman el anillo del tiro, las rutas en el minimapa y los neutrales visibles. Faltan el vigía de la I y la regla del sigilo |
| Control del mapa | 3 | **6** | Sitios: 18 % de la riqueza, ~10 tomas por partida. Comercio peleado en equipo. El bloqueo por presencia no anda (0 de 20) |
| Techo de habilidad | 4 | **6** | Esquivar, atacar al suelo, escalonar. Los consejos de decisión siguen en el modo competitivo |
| Ritmo y decisiones | 3 | **4** | Pelea por sitios desde el 6–9. Cierra 1 de 8 antes del 25; la III, a las 16:46. Sin vuelta: sitios y comercio van al que va adelante |
| Asimetría | 6 | **6** | El lancero de la I iguala un poco (incas y mapuches pierden la exclusiva) y los bonos de comercio suman. Guaraníes: 0 victorias en 4 partidas, y en 2 de 4 no llegan a la III antes del 25 |
| Varianza | 6 | **6** | Neutrales con 3 % de diferencia y piedra que alcanza (32/02). La primera victoria cambia por la fase de los ids (01d): el resultado es caótico, no aleatorio |
| **Promedio** | **4,5** | **5,6** | |

## 3. Las dos decisiones abiertas

**Hitos de 150/180/210 s: sí.** Medidos en las mismas 16 partidas:

| | II (mediana) | III (mediana, llegan) | IV (llegan) | Cierres antes del 25 |
|---|---|---|---|---|
| 190/220/250 | 7:07 | 16:46 (12 de 16) | 6 de 16 | 1 de 8 |
| 150/180/210 | 6:47 | **15:58** (13 de 16) | 4 de 16 | **3 de 8** |

- **V:** «En la IA, la III se adelanta menos de un minuto porque a la IA la frenan los recursos, no la obra. Para una persona son 40 s por edad, 2 minutos en total: la III rápida queda al 10–11, que es el pedido. La ventana para atacar el hito en obra sigue siendo de 2,5 minutos o más, como la de AoE4. Y con estos hitos se cerraron más partidas.»
- **C:** «Acepto, porque la piedra ya alcanza (32/02). Pido una sola cosa: que la III pida 100 de piedra en vez de 200, para que la III rápida no compita con el segundo centro.»

**Empalizada: 8 de madera.** Los mapuches pasan de 2 a 4, para conservar la proporción. La vida y la obra quedan como están. Las razones, en §1.5: a 4, cerrar una madera cuesta el 40 % del raid que para; a 8, la cuenta queda pareja y amurallar pasa a ser una decisión. C acepta porque a partir de la III el costo ya no pesa. Se mide en el torneo de la iteración 2 y, sobre todo, con humanos.

## 4. Fuera de lo pedido: un error

`data/unidades.json → aldeano.carga = 10` es la capacidad de carga. `Sim._hit` lee `a.def["carga"]["espera_ms"]`, la carga de la kona, que es otra cosa con el mismo nombre. Entonces, **cada golpe de un aldeano tira un SCRIPT ERROR y no pega**. Lo vimos en la matriz: guerreros contra exploradores y aldeanos. Viene de 596362b (juego tardío, paso 6). Afecta la defensa contra el raid en todas las partidas. Hay que renombrar una de las dos claves. No lo tocamos.

## 5. La iteración 2: lo que falta, en orden

| # | Cambio | Números | Por qué | Quién lo pide |
|---|---|---|---|---|
| 1 | Arreglar el golpe del aldeano | renombrar `carga` (la de la kona, a `carga_golpe`) | Sin esto, el raid de la I se mide mal | los dos |
| 2 | Hitos más cortos y una III más barata | 150/180/210 s; III con 100 P | La III rápida al 10–11; 3 de 8 cierres contra 1 | V, y C con la piedra |
| 3 | Sitios que den vuelta la partida | +50 % de renta si el dueño tiene menos edad que el rival más avanzado; en la I se toman con el 50 % de la renta | Hoy el que va adelante cobra 2286 contra 264 | V |
| 4 | Bloqueo de ruta que funcione | `bloqueo`: 6 → **3** de población a **8** casillas; con el mercado tomado, el comerciante espera en vez de volver vacío | 0 cortes en 20 partidas; hoy solo se corta matando | C |
| 5 | Comercio en el 1v1 para el que va atrás | comerciante desde la II al 40 % (`edad_pct` [0, 40, 60, 100]) | En 12 de 16 partidas uno no hizo ningún viaje | V |
| 6 | Sumidero de la IV que no se agote | repetibles sin tope, a +50 % por vez; venta del mercado sin piso para lo que sobra; una guardia de distancia (la élite de cada línea) | 17 643 y 19 000 de alimento sin gastar | C |
| 7 | Empalizada a 8 | mapuches de 2 a 4 | §3 | V; C acepta |
| 8 | El hondero que escalona no le gana a su contador | `micro_matriz` con 400 ms de reacción; si el hondero sigue ganando 5 de 5, guerrero de 1350 a 1450 de velocidad | El contador tiene que ganar a igual costo | V |
| 9 | Arcabucero | cadencia de 3200 a 2500 | Pendiente de la ronda 8 (§2) | V |
| 10 | Una herramienta de cierre para guaraníes | emboscada: +50 % al primer golpe desde el monte con sigilo | 0 de 4; en 2 de 4 no llegan a la III | los dos |
| 11 | Información en la I | puesto de vigía (75 M, visión 10) y explorador de 2100 a 2300 | Pendiente de la ronda 8 (§3) | V |
| 12 | Modo competitivo | sin consejos de decisión; radio del aura dibujado; pool de 5 mapas con veto | Pendiente de la ronda 8 (§5, §4 y §8) | los dos |

**Los seis primeros son la iteración 2.** Del 7 al 12, lo que alcance; ninguno pide más que datos y un parche chico. Meta de la iteración 2: promedio de **6,5** o más, con ritmo y control del mapa en 6 o más.
**Cómo medirla:**
- el guion de partidas con 3 semillas: cierres antes del 25 en 4 de 8 o más, y la III en 14:30 o menos de mediana;
- la parte de los sitios que cobra el que va atrás: 30 % o más;
- el bloqueo por presencia: que se active en al menos 1 de cada 3 2v2;
- el alimento sin gastar en la IV: menos de 5000 de promedio;
- y la matriz con la reacción humana.

## 6. Dónde coinciden y dónde no

**Coinciden:**
- la iteración 1 mejoró el combate (contrajuego y techo) más que la macro;
- los sitios se pelean, pero hoy hacen más fuerte al que va ganando;
- el comercio está bien para equipos y sobra en el 1v1;
- la empalizada pasa a 8 y los hitos a 150/180/210.

**No coinciden:**
- **Comercio desde la II.** V lo quiere, para que el 1v1 tenga ruta. C teme que en equipo se coma la meta del 30–45 % y prefiere mover solo el bloqueo. Proponen probarlo en el 1v1 solamente.
- **Velocidad del guerrero.** C prefiere dejar que el hondero escalone («es habilidad») hasta medir con reacción humana; V lo quiere atado ya.
