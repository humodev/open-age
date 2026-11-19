# 34 · 06 · Revisión de la iteración 3, a dos voces

> Pedido: los dos expertos repiten las medidas de la [revisión 2](04-revision-iteracion-2.md) con el mismo método sobre lo integrado en la iteración 3 ([3a](05a-iteracion-3.md): sitios con guarnición, hito en obra al 50 %, la III a 800/500/100; [3b](05b-iteracion-3.md): comercio decreciente y con escolta, guardia de distancia a alcance 5, Palmares) y el [torneo 42](pruebas-it3/42-torneo-iteracion-3.txt).

**Voces:** **V** = veterano competitivo de AoE4. **C** = constructor de partidas largas en equipo.
**Método:** main en b25eed8 (3a y 3b juntos; el lote de 3a se había medido antes de fusionar con 3b), headless, como mucho dos Godot a la vez:
- 12 partidas 1v1 de 25 min, experta contra experta, en llano, los mismos 4 cruces y semillas 7, 11 y 3, con [partidas.gd](pruebas-revision-3/partidas.gd.txt) sin parches; resumen con [resumen.py](pruebas-revision-3/resumen.py) y [extra.py](pruebas-revision-3/extra.py);
- `tools/micro_matriz.gd --edad=4 --compras --variantes=5`, con `--reaccion=400` y sin ella;
- `tools/comercio_medida.gd`: 2v2 de 45 min, semillas 7 y 3, equipos 0,0,1,1;
- `tools/sumidero_iv.gd`: 2v2 de 45 min, semillas 7 y 3.

Salidas en [pruebas-revision-3/](pruebas-revision-3/). **Advertencia, igual que antes:** IA contra IA, pocas semillas; la IA no rushea, no amuralla con empalizada (0 de 24 otra vez) y no tumba hitos en obra.

## 1. Las medidas, contra la revisión 2

### 1.1 La carrera a la III y la renta de sitios ([lote](pruebas-revision-3/lote.txt))

| 12 partidas 1v1 | Revisión 2 | Lote final de 3a (antes de fusionar) | **Ahora (main)** | Meta |
|---|---|---|---|---|
| El primero en la III gana | 9 de 12 | 6 de 12 | **8 de 12** | ≤ 7 |
| III, mediana | 16:08 | 14:29 | **14:25** (19 de 24 llegan) | ≤ 14:30 |
| Renta de sitios que cobra el que va atrás | 4,5 % | 8,8 % | **5,3 %** (1452 de 27 271) | ≥ 20 % |
| Sitios en la riqueza total | 19,5 % | — | 18,1 % | — |
| Cierres antes del 25 | 4 de 12 (3 por sitios) | 0 por sitios | **1 de 12** (conquista a las 23:14); **0 por sitios** | — |
| Primera muerte militar | 4:00–7:40 | — | 4:00–7:39 | — |

- **V:** «La III bajó a 14:25 y se sostiene. Pero el 6 de 12 de 3a era ruido: con el mismo guion y 3b adentro volvió a 8 de 12, y la renta del que va atrás, a 5,3 %. Con 12 partidas, ±2 victorias es el ruido; una meta de "≤ 7 de 12" no se puede juzgar con un lote. Y 11 de 12 partidas terminan a las 25:00 por puntaje, que suma 150 por edad: el "primero en la III gana" mide en parte la regla del puntaje.»
- **C:** «La guarnición hizo lo que dijimos: tener sitios cuesta ejército y se ve. Pero el que va adelante también tiene de 2 a 3 veces más tropa (al minuto 15, de 20 a 29 contra 0 a 12 en Etiopía y mapuches contra Palmares) y le alcanza para cubrir los tres. La regla es buena, la IA del que va atrás no la explota.»

### 1.2 Comercio y cortes en el 2v2 ([s7](pruebas-revision-3/2v2-s7.txt), [s3](pruebas-revision-3/2v2-s3.txt))

| 2v2, 45 min | Comercio después del 30 | Comercio del que va adelante / del otro | Cortes (adelante / atrás) | Comerciantes muertos (adelante / atrás) |
|---|---|---|---|---|
| s7, revisión 2 | 54 % | 20 570 / 1251 | 0 / 14 | 0 / 32 |
| **s7, ahora** | **36 %** | 11 743 / 3241 | **13 / 21** | 6 / 32 |
| s3, it2 | 28 % | 10 847 / 1606 | — / 23 | 30 en total |
| **s3, ahora** | **32 %** | 11 108 / 782 | **4 / 19** | **36 / 18** |

En el 1v1: comercio en el 9,4 % de la riqueza (meta ≤ 15 %), 8 de 12 partidas con un jugador sin ningún viaje (antes, 7 de 12) y 3 cortes en 12 partidas, todos al Tawantinsuyu de la semilla 11, que iba atrás.
- **C:** «Es lo que más mejoró. Las dos dentro de la meta (36 y 32 %), y en s7 el equipo de adelante ya sufre 13 de 34 cortes. En s3 pierde 36 comerciantes: la escolta y el rendimiento decreciente obligan a pelear la ruta. Pero el que va atrás sigue cobrando de 4 a 14 veces menos.»
- **V:** «El corte ya no es una sola dirección. Sigue ganándolo el ejército más grande, pero ahora el grande también paga.»

### 1.3 La guardia de distancia ([400 ms](pruebas-revision-3/micro-r400.txt), [sin reacción](pruebas-revision-3/micro-r0.txt))

Edad IV con compras, 5 variantes, costo parecido (2250 contra 2090–2250):

| A contra B | Revisión 2 | Ahora, 400 ms | Ahora, sin reacción |
|---|---|---|---|
| 5 g. de distancia escalonando contra 5 guardias | 4/5 | **1/5** | 2/5 |
| Lo mismo, «mantener + escalonar» | 5/5 | 0/5 | 2/5 |
| 5 g. de distancia escalonando contra 26 guerreros | 5/5 | **0/5** | 0/5 |
| 5 g. de distancia escalonando contra 13 jinetes | 0/5 | 0/5 | 0/5 |
| 5 g. de distancia contra 22 lanceros (sin micro) | 2/5 | **0/5** (quedan 12 de 22) | 0/5 |
| 5 g. de distancia contra 30 honderos | 0/5 | 0/5 | 0/5 |

Nota: en el 05b el «2/5 con 400 ms, 1/5 sin reacción» está invertido; los archivos de 3b dicen 1/5 con 400 ms, igual que este.
- **V:** «Se arregló de más. Ya no le gana a su contador, pero tampoco a su presa: 0 de 5 contra 22 lanceros, y quedan 12 vivos. A 2 de población y 450 de costo, nadie la va a entrenar. Pasó de rota a trampa.»

### 1.4 Los 30 honderos (abierto desde la revisión 1)

| A contra B (costo 2250 / 2090–2250) | 400 ms | Sin micro |
|---|---|---|
| 30 honderos escalonando contra 26 guerreros (IV) | **5/5** (quedan 25 de 30) | 3/5 |
| 30 honderos contra 13 jinetes (IV) | 5/5 | **5/5** |
| 30 honderos contra 22 lanceros (IV) | 5/5 | 5/5 |
| 30 honderos contra 5 guardias (IV) | 5/5 | 4/5 |
| 30 honderos contra 13 jinetes, **edad II** ([txt](pruebas-revision-3/micro-e2-escala.txt)) | — | **5/5** |
| 10 honderos contra 5 jinetes, edad II ([txt](pruebas-revision-3/micro-e2-r400.txt)) | 0/5 escalonando | 1/5 |
| 10 honderos contra 5 jinetes, edad IV ([txt](pruebas-revision-3/micro-e4-chico.txt)) | — | 2/5 |

- **V:** «Esto es lo más grave que encontramos, y no es de la IV: es de la escala. A 10 contra 5 el jinete le gana al hondero; a 30 contra 13, el hondero gana 5 de 5 **sin micro** contra su contador declarado, y contra todo lo demás. Es la ley del cuadrado: 30 tiros de 5 de daño neto (7 − 2 de armadura) borran un jinete cada 2 s antes de que la carga llegue. En AoE4 el arquero en masa lo frena el jinete con armadura de distancia alta. Hoy, el ejército óptimo de cualquier pueblo con 2250 de recursos es "honderos". La IA no lo hace; un humano lo descubre en una tarde.»

### 1.5 El sumidero de la IV ([s7](pruebas-revision-3/sumidero-s7.txt), [s3](pruebas-revision-3/sumidero-s3.txt))

| 2v2 | Fin | Alimento sin gastar en la IV (promedio de los que llegan, el peor) | Riqueza al final (la más alta) | Caminos | Repetibles / guardias |
|---|---|---|---|---|---|
| s7, revisión 2 | 35:50, sitios | 367 | 597 | guerra ×2 | 1 / 1 |
| **s7, ahora** | 45:00 | **996** (1940; Tawantinsuyu con 3141 y 87/200 de población) | 1049 | asedio, guerra | 6 / 10 |
| s3, revisión 2 | 39:06, sitios | 548 | 4137 | guerra ×2 | 8 / 1 |
| **s3, ahora** | 45:00 | **1477** (1677; máximo 3943) | **3496** | asedio, defensa | 9 / 12 |

- **C:** «Hay elección: tres caminos distintos en cuatro jugadores (antes, todos guerra), y las guardias salen. Pero el alimento vuelve a subir (de 367–548 a 996–1477, bajo la meta de 5000), y un Tawantinsuyu con 87 de 200 de población guarda 3141 de alimento: la IA no gasta, no es que no haya en qué. La riqueza sigue sin destino (consulta abierta).»

## 2. La vara, área por área (del 0 al 10)

| Área | It. 2 | Ahora | Por qué |
|---|---|---|---|
| Diversidad de estrategias | 5 | **5** | Caminos de la IV variados (asedio, defensa, guerra). Pero sigue sin rush ni empalizada (0 de 24), la III primero gana 8 de 12 y la composición óptima a escala es una sola (honderos) |
| Contadores y contrajuego | 6 | **5** | La guardia de distancia dejó de romper el triángulo, pero quedó inútil (0/5 contra su presa). Y aparece algo peor: 30 honderos le ganan 5/5 a 13 jinetes sin micro, a costo igual |
| Información y scouting | 5 | **6** | Sitios a la vista (4 casillas para todos) y guarnición visible: el líder estirado se ve |
| Control del mapa | 6 | **6** | Cortes repartidos (13/21 y 4/19) y el que lidera pierde comerciantes. Pero los sitios siguen siendo del líder: 5,3 % |
| Techo de habilidad | 6 | **6** | Escolta, guarnición y dónde pegar suman decisiones. El escalonar con honderos rinde demasiado |
| Ritmo y decisiones | 5 | **4** | La III en 14:25 cumple. Pero 11 de 12 partidas van al reloj, 0 victorias por sitios (antes 3) y en el torneo los cierres por destrucción caen de 47 a 26 de 150: la guarnición del 40 % sacó tropa de las oleadas |
| Asimetría | 5 | **6** | El torneo cierra la banda de 34–70 a 42–64 en 150 partidas. Pero en el lote los mapuches ganan 5 de 6 y Palmares 0 de 6, sin III en 5 de 6 |
| Varianza | 6 | **6** | Primera victoria 8 de 8 y 7 de 8. Sin cambios de azar |
| **Promedio** | **5,5** | **5,5** | Meta: 6,5. **No se cumple** |

**Lectura:** la iteración 3 cumplió lo mecánico (III a 14:25, comercio en 32–36 %, guardia de distancia contenida, Palmares en la II a las 7:38) y arregló la dirección de los cortes. Pero no generó la vuelta: el que tiene más edad gana 93 de las 95 partidas del torneo 42 con edades distintas (106 de 107 en el 41). Y la guarnición, que era para frenar al líder, frenó a todos: hay menos ataques.

## 3. ¿Qué tan cerca de un diseño de esport?

**Igual de lejos que hace una iteración: 5,5 contra el 8 de un RTS de esport.** Lo que mejoró (comercio, información, asimetría en el torneo) lo compensan dos cosas: el ritmo, porque casi todo se decide por puntaje al final, y un contador roto a escala (los honderos). El diseño tiene las piezas de AoE4 (hitos, sitios, rutas, triángulo), pero todavía no tiene lo que hace a un esport: **que el que va atrás tenga una jugada que pague y que la partida termine en el mapa**. Y casi nada de eso se puede medir mientras la IA no rushee, no busque peleas chicas con ventaja y no ataque hitos a tiempo.

**Los 5 cambios que faltan, en orden:**

| # | Cambio | Números | Meta medible |
|---|---|---|---|
| 1 | Romper la masa de honderos | jinete: armadura de distancia 2 → 4 (el hondero le hace 3, no 5); hondero: cadencia 1750 → 2000. Probar con `micro_matriz --parche` antes de tocar data/ | 30 honderos contra 13 jinetes sin micro ≤ 1/5, y escalonando con 400 ms ≤ 2/5; 26 guerreros contra 30 honderos escalonando ≥ 2/5; 10 contra 5 sin cambio |
| 2 | Que la partida se cierre en el mapa | guarnición de la IA del 40 % al 25 % del ejército y que salga en la oleada si el rival tiene menos de la mitad; cuenta de sitios de 10 → 6 min, desde el 12 (no el 15) | lote: 4 de 12 o más cierres antes del 25 (hoy, 1); torneo: 45 de 150 o más por destrucción (hoy, 26) |
| 3 | Sitios: probar la rotación (alternativa A) encima de la guarnición | `sitios.rotacion_ms` 240 000, uno por vez, 2 min de aviso, en un punto equidistante | el que va atrás cobra ≥ 15 % (hoy, 5,3 %) en **24** partidas (6 semillas), no 12 |
| 4 | Guardia de distancia con un lugar | bono contra línea +6 → +12 (sin tocar alcance ni velocidad) | 5 contra 22 lanceros sin micro ≥ 3/5; contra 5 guardias escalonando ≤ 2/5 |
| 5 | Palmares y la cola de la asimetría | Palmares: ejército mínimo de 6 en la II hasta la III, y la III 10 % más barata en fama; mapuches: −5 % en el ritmo de hitos (77/92/106 s contra 84/115/134 de los rivales) | torneo con todos en 42–58 %; en el lote, nadie con 0 de 6 ni 6 de 6 |

## 4. Prioridades propias

1. **El puntaje del torneo mide la carrera de edades.** `tests/torneo.gd` decide con `edad × 1000 + población × 10 + bajas`: con 124 de 150 partidas al reloj, el 42–64 % es casi «quién llega antes a la IV». Usar `Sim.score` (el de la partida) o informar aparte las victorias por destrucción. Hasta eso, el balance por pueblo vale poco.
2. **La IA que rushea y amuralla.** Sin ella, la empalizada a 8, el raid y el golpe del aldeano siguen sin vara (0 de 24 empalizadas, aldeanos muertos antes del 12: casi 0). Pedido mínimo: un perfil «rush» de la experta en 1 de cada 4 partidas (8–12 guerreros a las 4:30) y empalizada en la madera si ve un explorador enemigo.
3. **La IA que busca superioridad local.** La guarnición visible (alternativa B) solo sirve si el que va atrás pega donde el rival tiene menos. Hoy la IA desafía con «fuerza proporcional», no con ventaja: que elija el sitio ajeno con menos guardia y vaya con 2× lo que ve.
4. **El hito en obra:** 0 caídos en 6 partidas. La IA sale cuando lo ve; tiene que salir cuando ve al rival juntar 800/500/100 (o poner al explorador en su base desde el 11).
5. **Lotes más grandes para las metas finas.** El mismo guion dio 6 de 12 y 8 de 12, y 8,8 % y 5,3 %, entre dos commits cercanos. Para metas de «≤ 7 de 12» hacen falta 24 partidas.
6. **La IA que no gasta en la IV** (3141 de alimento con 87/200 de población) infla el sumidero; arreglarlo antes de decidir la consulta de la riqueza.

## 5. Dónde coinciden y dónde no

**Coinciden:** el comercio es el único frente cerrado; la guardia de distancia pasó de rota a inútil; el ritmo empeoró por la guarnición; sin una IA que rushee y elija peleas, el 60 % del diseño no se puede medir.

**No coinciden:**
- **Orden 1 y 2.** V pone primero los honderos («un humano rompe el triángulo el primer día»); C pone primero el cierre en el mapa («los honderos no los usa nadie hoy; las partidas al reloj, todas»).
- **Sitios.** V quiere la rotación ya; C prefiere primero la IA de superioridad local y repetir la B con 24 partidas antes de sumar otra regla.
