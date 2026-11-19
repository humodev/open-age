# 34 · Hacia un diseño de esport

> Pedido del autor (2026-11-19): «Iterá al menos dos veces, hasta que estemos cerca de un esport en cuanto a diseño.»

Cada iteración tiene tres pasos:
1. Implementar.
2. Los dos expertos (veterano competitivo y constructor) juegan y revisan la competitividad del diseño: diversidad de estrategias, contrajuego, información, control del mapa, techo de habilidad, ritmo, asimetría y varianza, con la misma vara que en [ronda-8/04](../22-testers/ronda-8/04-jugabilidad-competitiva.md).
3. Ajustar.

Al final de cada iteración se mide el balance con un torneo.

## Iteración 1

| Frente | Qué | Estado |
|---|---|---|
| 1a | Triángulo más marcado, lancero en la I, sitios que paguen, asedio de área esquivable y ataque al suelo | **Integrado (57fcb7f)**, [01a](01a-cambios-competitivos.md). Hash 3870415820. Primera victoria 2 de 3.

**Triángulo:**
- Línea: +6 contra el choque y +6 contra lo montado. +12 contra todo el choque se descartó porque bajaba la primera victoria.
- Distancia: +6. Choque: +8.
- 1 lancero contra 1 jinete: de 0/5 a 4/5.

**Lancero en la I:** todos los pueblos lo tienen, con su nombre.

**Sitios:** 60/45/30 de riqueza, y se toman desde la II.

**Asedio de área:**
- Contra tropa, el tiro tarda 8 ticks en llegar: esquivar paga (de 0/5 a 5/5 con un bot que esquiva perfecto).
- Ataque al suelo en R, que también usa la IA (D-031).
- La micro C2 queda intacta. |
| 1b | Comercio: mercados neutrales, comerciante, rutas y bloqueo ([diseño](../33-comercio/README.md)) | **Integrado (c9b6c97)**, [implementación](../33-comercio/02-implementacion.md). Hash 916860075.<br>• Los 8 pasos hechos: siempre 2 o más mercados neutrales (equidad: 3 % en el peor caso); comerciante con ganancia por distancia, cobrada al volver; bloqueo y avisos; ruta con línea y punto de paso; bonos de cada pueblo; IA que comercia, protege y corta rutas; maquetas.<br>• Metas: en 1v1, 13–14 % de la riqueza antes del minuto 25 (se cumple); en 2v2, 28 % después del 30 (la meta era 30–45 %; en una semilla le mataron 40 comerciantes).<br>• La primera victoria del principiante había bajado a 3 de 8 semillas (antes, 6 de 8): los dos neutrales corrían en 2 los ids de todo lo demás y con eso la fase de los `(tick + id) % k`. Con ids aparte vuelve a 6 de 8; hash 289763931 ([01d](01d-primera-victoria-mercados.md)). |
| 1c | Rendimiento, paso 2: caminos de grupo y caché | **Integrado (f480427)**, [07](../32-ronda-8/07-rendimiento-caminos.md)
- **Caché de caminos:** por región, y la IA no vuelve a mandar a quien ya iba al mismo lugar.
- **4v4:** promedio de 46,9 a 40,6 ms, p95 de 100 a 77 ms; los ticks de más de 100 ms bajan de 1232 a 22.
- **1v6:** p95 de 60 a 33 ms.
- **Caminos:** ya son el 1 % del tick. Lo que pesa ahora es el costo por entidad (IA, recolección, movimiento).
- **Pendiente:** la meta de p95 < 40 ms con 8 jugadores. El bench de 6 IA empeora su peor tick por `_expansion_site`.
- **Al fusionar todo:** hash **1417676642**; comercio, equidad y jugabilidad OK. |
| — | **Torneo 40** ([resultados](pruebas-it1/40-torneo-iteracion-1.txt)), con todo junto | Tawantinsuyu 42, mapuches 54, guaraníes 58, Etiopía 56, Palmares 48, Ayutthaya 42 %.<br>• **Banda:** todas entre 42 y 58 %, la más pareja de todo el proyecto (el torneo 39 daba 34–64).<br>• **Edad IV:** aparece en 86 de 150 partidas de 30 minutos (antes, 5 a 16).<br>• **Por destrucción:** bajan de 60–80 a 39; se juega más tiempo y gana más el que lleva ventaja en puntos. |
| — | Revisión de los expertos | **Hecha** ([02](02-revision-iteracion-1.md)).

**Notas, antes → ahora:** diversidad 4→5, contrajuego 5→7, información 5→5, control del mapa 3→6, techo 4→6, ritmo 3→4, asimetría 6→6 y varianza 6→6. Promedio de 4,5 a 5,6.

**Lo que falla:**
- Los sitios y el comercio quedan en manos del que va adelante.
- El bloqueo de rutas no se activó en ninguna de 20 partidas.
- El sumidero de la IV deja 17 643 de alimento sin gastar.
- El aldeano no le pega a nada: SCRIPT ERROR por la clave `carga` repetida. |

## Iteración 2

| Frente | Qué | Estado |
|---|---|---|
| 2a | Golpe del aldeano. Hitos de 150/180/210 s y la III con 100 de piedra. Empalizada a 8 de madera (mapuches a 4). Sumidero que no se agote: repetibles sin tope a +50 %, venta en el mercado sin piso y una guardia de distancia | **Integrado (d7e1062)**, [03a](03a-iteracion-2.md)<br>• **Golpe del aldeano:** sin SCRIPT ERROR (`carga_golpe`).<br>• **Hitos:** 150/180/210 s; la III pide 100 de piedra.<br>• **Empalizada:** 8 de madera (la mapuche, 4).<br>• **Sumidero de la IV:** repetibles sin tope a +50 %, mercado con piso 10, guardia de distancia; la IA vende lo que pasa de 2500. El alimento que queda en la IV baja de 8715 a 2158 de promedio, pero ahora sobra riqueza (15 436).<br>• **Primera victoria:** con los hitos nuevos daba 3 de 8, porque la fácil defendía antes. Con la fácil en 3 constructores, 7 de 8.<br>• **Al fusionar con 2b:** conflicto en reglas.json, resuelto con las dos cosas. Hash **366120853**; comercio, jugabilidad y juego tardío OK. |
| 2b | Bloqueo de rutas que funcione: 3 de población a 8 casillas; el comerciante espera. Comerciante desde la II al 40 % en el 1v1 | **Integrado (d4a9d4b)**, [03b](03b-iteracion-2-comercio.md)<br>• **Bloqueo:** ya funciona. En un 2v2 hubo 23 cortes y 30 comerciantes muertos (en la iteración 1, 0 cortes en 20 partidas).<br>• **1v1:** el comercio queda en 7 % y 6 % (meta ≤ 15 %).<br>• **2v2:** el comercio queda en 28 % (meta 30–45 %). |
| — | **Torneo 41** ([resultados](pruebas-it2/41-torneo-iteracion-2.txt)) | Tawantinsuyu **34**, mapuches **70**, guaraníes 50, Etiopía 38, Palmares 54, Ayutthaya 54 %.<br>• La banda se abre de 42–58 a 34–70: los hitos más cortos y la empalizada mapuche a 4 favorecen a los mapuches.<br>• La IV llega en 104 de 150 partidas (antes, 86).<br>• Los mapuches y el Tawantinsuyu se diagnostican al empezar la iteración 3. |
| — | Sitios con +50 % de renta para el que va atrás en edad | **Consulta al autor:** es una ayuda al que va perdiendo y el autor no quiso ventajas para el 1vN |


### Revisión de la iteración 2 ([04](04-revision-iteracion-2.md))

**Notas:** diversidad 5, contrajuego 6 (antes 7), información 5, mapa 6, techo 6, ritmo 5 (antes 4), asimetría 5 (antes 6) y varianza 6. El promedio pasa de 5,6 a 5,5. Un esport anda por 8.

**El problema de fondo:** la partida se decide en la carrera a la III, sin vuelta atrás.
- El que llega primero a la III gana 9 de 12 partidas.
- El que va atrás cobra el 4,5 % de los sitios.
- El comercio cortado lo sufre siempre el equipo que va atrás.

**Bajan dos áreas:**
- **Contrajuego:** la guardia de distancia escalonando le gana a todo.
- **Asimetría:** los mapuches ganan 6 de 6.

## Iteración 3

| Frente | Qué | Estado |
|---|---|---|
| 3a | Sitios que no se acumulen en el líder: rinden solo con 2 de población militar a 4 casillas, guarnición visible para todos (alternativa B de los expertos; no premia perder). Hito en obra con el 50 % de los PV y la experta que lo ataca. La III a 800 A / 500 R / 100 P. Balance de mapuches (70 %) y Tawantinsuyu (34 %) | **Integrado (9f6b375)**, [05a](05a-iteracion-3.md)<br>• **Sitios:** rinden solo con guarnición (2 de población a 4 casillas, visible para todos); la IA deja 3. El que va atrás cobra el 8,8 % (antes 4,5 %; meta 20 %, no cumplida).<br>• **Hito en obra:** 50 % de PV; la experta va a atacarlo, pero no lo tumbó en 6 partidas.<br>• **La III a 800/500/100:** cumplida. El primero en la III gana 6 de 12 (antes 9) y la mediana baja a 14:29.<br>• **Mapuches:** 46 %, sin tocar sus datos.<br>• **Tawantinsuyu:** 30 %, sigue abajo; Palmares lo apura a los 3:30–4:40.<br>• **Pruebas:** al fusionar con 3b, reglas.json se resolvió con las dos cosas. Hash 3059812827; comercio y sitios OK. Primera victoria 8 de 8. |
| 3b | Comercio con rendimiento decreciente desde el 8.º comerciante por ruta (piso 40 %); el corte pide 3 de población más que la escolta. Guardia de distancia con alcance 5 y velocidad 1100. Emboscada guaraní y Palmares con la II antes de las 8:30 | **Integrado (efcecfd)**, [05b](05b-iteracion-3.md)<br>• **Comercio:** rinde decreciente desde el 8.º comerciante; el corte pide 3 más que la escolta; la IA tiene un tope de 12 comerciantes (antes 16). En el 2v2 queda en 44–45 %, en el borde de la meta; el que va atrás conserva algo. En el 1v1, 11 %.<br>• **Guardia de distancia:** con 400 ms de reacción gana 0/5 contra 26 guerreros (antes 5/5).<br>• **Palmares:** llega a la II a las 7:38 (antes, a las 8:24–8:49). La IA no contaba los aldeanos de los oficios.<br>• **Abierto:** 30 honderos que escalonan le siguen ganando 5/5 a 26 guerreros.<br>• Mismo hash; primera victoria 7 de 8. |
| — | En qué gastar la riqueza que sobra en la IV: leva, tributo a la causa u obra de legado | **Consulta al autor** |

**Torneo 42** ([resultados](pruebas-it3/42-torneo-iteracion-3.txt)):

| Tawantinsuyu | Mapuches | Guaraníes | Etiopía | Palmares | Ayutthaya |
|---|---|---|---|---|---|
| 42 | 64 | 52 | 50 | 46 | 46 |

- **Banda:** vuelve a 42–64 (en el 41 era 34–70).
- **Edad IV:** llega en 115 de 150 partidas.
- **Victorias por destrucción de hitos:** bajan a 26; casi todo se define por puntos en partidas que llegan al final.

### Revisión de la iteración 3 ([06](06-revision-iteracion-3.md))

**Notas:** diversidad 5, contrajuego 5, información 6, mapa 6, techo 6, ritmo 4, asimetría 6, varianza 6. **El promedio sigue en 5,5**, igual que en la iteración 2.

**Medidas en main:**
- El primero en llegar a la III gana 8 de 12 (el 6 de 12 de 3a era ruido).
- El que va atrás cobra el 5,3 % de los sitios.
- El comercio del 2v2 queda en 32–36 %, dentro de la meta, y los cortes se reparten.

**Problemas nuevos:**
- La guardia de distancia ahora pierde contra todo.
- A igual costo, 30 honderos le ganan 5 de 5 a 13 jinetes: es un problema de escala.

## Lectura del orquestador: por qué no sube

Tres iteraciones en 5,5 dicen que el límite está en cómo medimos, no solo en el diseño:
1. **El torneo puntúa la edad** (edad × 1000 en los empates por tiempo). Ahí «gana el de más edad en 93 de 95» sale en parte de la vara, no solo del juego.
2. **La IA no juega como un rival competitivo.** No rushea, no amuralla, no busca superioridad local y llega tarde al hito en obra. Las estrategias que dan diversidad, contrajuego y ritmo nunca aparecen en las partidas que medimos.
3. **Los lotes de 12 son ruido.** Hacen falta 24 o más.
