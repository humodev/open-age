# 45 · Rendimiento del 4v4 (2026-11-20)

> Pedido: el 1v6 ya no tiene ticks de más de 100 ms, pero el 4v4 seguía con un p95 de 67–77 ms y
> picos. `docs/09-estado.md` nombraba el paso siguiente: «caminos con caché por región». Medir
> primero, encontrar de dónde salen los picos (por sistema) y arreglarlo, sin cambiar el
> comportamiento más allá de caminos equivalentes. Determinismo y bench en verde.

Herramienta: `tools/perfil_sim.gd -- --partida=4v4 --minutos=40` (semilla 42; proceso/32-ronda-8/04).
Cada corrida, sola en la máquina (un Godot por vez, con tope de memoria de 4 GB).

## 1. Medición inicial: tres fuentes de picos

`pruebas/0-antes-perfil.txt` y `pruebas/0-antes-detalle.txt` (con `--ia-detalle --detalle --lentos=15`).

| Fuente | Qué se vio |
|---|---|
| **Caminos que no llegan** | 1557 A* «parciales» costaban 8,4 s (5,4 ms cada uno; 0,07 ms el que llega). Picos de 40–144 ms en un tick. Un aldeano a 2 casillas de un recurso encerrado: 22–31 ms por pedido, porque los caminos cortos no usaban ninguna caché |
| **La IA, un jugador** | j4 (Ayutthaya) al minuto 26: 110–147 ms cada 5 ticks (`ia._economy`, peor 127 ms). j5 (Tawantinsuyu): 130–140 ms cada ~1300 ticks |
| **El segundo** (`tick_second`) | 30–50 ms una vez por segundo; `sitios` 17 ms, `rentas` 19 ms |

Por qué el caché por región no alcanzaba: el recuerdo de destinos encerrados era por (jugador,
región del origen, región del destino) y vencía con `_ver_block`, que sube con **cada edificio
nuevo**: con 8 IA construyendo, casi nunca servía. Y los caminos de hasta 16 casillas no pasaban
por él.

## 2. Qué cambió

| # | Cambio | ¿Cambia el resultado? |
|---|---|---|
| 1 | **Destinos encerrados por región del destino** (`SimMap.find_path`, `_enclosed`, `reglas.caminos.encierro_margen`). Si hacia esa región ya hubo un A* que no llegó, primero un A* **del destino al origen**: si el destino está encerrado, ese A* solo recorre el encierro (barato, es nativo). Si no llega al origen, se va directo a la casilla más cercana recordada (si se la alcanza). Si llega, se hace el A* de siempre. Tapar casillas no puede abrir un encierro ni acercar otra casilla, así que el recuerdo ya no vence al construir; solo al abrir (destruir) y a los 150 ticks. Vale también para los caminos cortos | Sí, solo donde el destino está encerrado (la casilla final puede ser otra igual de cerca) |
| 2 | **Lugar de granja por centro y por tick** (`SimAI._farm_site`): dentro de una pensada el mapa no cambia (las órdenes se aplican en el tick siguiente); cada aldeano ocioso del mismo centro repetía la búsqueda junto al agua (hasta 600 casillas × 49). Y `Sim.near_water_cached`: el «¿hay agua a 2 casillas?» por casilla, guardado mientras no cambie el agua | No (mismo hash a 40 min) |
| 3 | **Caminos incas** (`SimAI._road_ok`): la búsqueda en anchura de `_road_tiles` llamaba a `can_place("camino")` por casilla (miles cuando un edificio no tiene paso). Para un tramo de 1×1 sin piezas encima, cupo ni agua pedida, `can_place` es «libre y en tierra»: se pregunta directo | No |
| 4 | **Sitios sagrados por cubos** (`SimMods._sacred`): la lista `sacred_sites()` en lugar de recorrer `actives`, y las unidades agrupadas por cubos de 8 casillas; cada sitio mira solo los cubos de su caja. Lo calculado no depende del orden (el menor dueño por equipo, una suma) | No |

El perfilador suma envoltorios para `_farm_site`, `_site_near`, `_expand`, `_center_towers`,
`_far_gatherers` y `_road_tiles`, la lista «Detalle por peor tick» (lo que hace picos aunque pese
poco de promedio) y cuántos destinos encerrados se resolvieron sin recorrer.

## 3. Paso a paso

| Corrida | Prom. | p95 | Peor | > 100 ms | Hash a 40 min | Nota |
|---|---|---|---|---|---|---|
| 0 · base (`0-antes-detalle`) | 39,4 | 80,8 | 286 | 242 | 1993518327 | con envoltorios de detalle |
| 1 · encerrados (`1-encerrados`) | 39,3 | 78,6 | 178 | 110 | 2009769046 | parciales 8,4 s → 2,6 s; pico de caminos 143 → 49 ms; 906 resueltos sin recorrer |
| 2 · granja (`2-granja`) | 39,8 | 79,5 | 193 | 87 | 2009769046 | `_farm_site` 54 → 13 ms; j4 sin picos |
| 3 · (descartado, `3-lugar-descartado`) | 39,9 | 78,6 | 184 | 80 | 2009769046 | ver tropiezos |
| 4 · caminos incas con recuerdo (`4-…`) | 40,4 | 82,2 | 194 | 177 | 2009769046 | no alcanzó: las casillas no se repiten |
| 5 · caminos incas directo (`5-…`) | 40,7 | 80,6 | **137** | 118 | 2009769046 | `can_place` fuera de los picos; j5 de 140 a 46 ms |

Las corridas con envoltorios cuestan ~25 % más y la carga de la máquina cambió entre ellas (los
promedios suben solos de 39 a 41 ms con el mismo hash); sirven para ver **qué sistema** pesa.
Para el antes y después se corrió `--plano` (sin envoltorios), una detrás de la otra:

## 4. Antes y después (`--plano`, 4v4, semilla 42, 40 minutos)

| | Prom. ms | p95 ms | Peor ms | Ticks > 100 ms | > 40 ms | ×4 alcanza hasta |
|---|---|---|---|---|---|---|
| Antes (`plano-antes.txt`) | 32,3 | 68,2 | 193 | 65 | 7631 | min 14 |
| Después (`plano-despues.txt`) | **30,1** | **63,8** | **121** | **12** | 6601 | min 15 |

Promedio por minuto (ms por tick):

| Minuto | 5 | 10 | 15 | 20 | 25 | 30 | 35 | 40 |
|---|---|---|---|---|---|---|---|---|
| Antes | 7,5 | 16,3 | 25,7 | 32,2 | 39,4 | 44,6 | 53,0 | 58,9 |
| Después | 6,6 | 15,0 | 23,1 | 30,5 | 36,6 | 46,0 | 47,8 | 58,1 |

Las partidas no son iguales jugada a jugada desde el primer destino encerrado resuelto por el
recuerdo (al minuto 40 quedan 899 unidades contra 1044; ninguna termina). Los 12 ticks de más de
100 ms que quedan son del final (minutos 37–40), con el promedio ya en 58 ms: costo por entidad
(IA, recolección, movimiento), no picos de un sistema.

## 5. Pruebas

- `tests/test_determinism.gd`: OK, hash **3059812827**, el mismo de main (en 3000 ticks de 1v1 no
  hay destinos encerrados con recuerdo). Corrido después de cada paso.
- Hash del perfilador 4v4 a 40 min: 1993518327 → **2009769046**. Cambia solo por el paso 1 (los
  pasos 2–4 dan el mismo hash que el paso 1): el que va a un destino encerrado recibe el camino
  a la casilla más cercana que alcanzó otro, en lugar de recorrer de nuevo toda la zona.
- `tests/bench.gd`: 200 unidades 8,2 ms (peor 57,7); 6 × 150 unidades 21,3 ms (peor 53,2);
  6 IA 20 min 8,3 ms (último minuto 13,7, peor 38,5). En proceso/32 eran 8,8 / 26,1 / 11,3.
- `tests/salud_ia.gd`: **idéntico** a main, línea por línea (`salud-antes.txt`, `salud-despues.txt`;
  los avisos de mercado y ejército ya estaban).
- `tests/equipos.gd -- --minutes=30 --solo=3v3`: OK, fuego amigo 0, las seis en pie en la III y
  la IV, tributos 23 (`equipos-3v3.txt`). Es la prueba de que las partidas grandes, donde los
  caminos cambian, siguen jugándose bien.
- `tests/civ_smoke.gd`: sin errores.

## 6. Tropiezos

- **El primer «antes» con detalle** no mostraba los ayudantes que hacían picos: la lista ordenaba
  por promedio y `can_place` pesa 0,03 ms por tick de promedio con picos de 75 ms. Se sumó la
  lista por peor tick.
- **Paso 3, descartado**: un recuerdo de las búsquedas de lugar que fallaban (`_site_near`), que
  valía hasta que se liberara una casilla de la zona. Mismo hash, pero no bajó nada: el pico no
  venía de ahí sino de los caminos incas (j5 es Tawantinsuyu: el pueblo es `(lugar + semilla) % 6`).
  Se sacó para no sumar código sin ganancia.
- **Paso 4**: el recuerdo por tick de `_road_ok` tampoco alcanzó: en una búsqueda que no llega, cada
  casilla se prueba casi una sola vez. Lo que costaba era `can_place` en sí (~12 µs por casilla).
- Un error de tipo (`var memo :=` con un valor sin tipo) dejó al test de determinismo trabado
  repitiendo errores 10 minutos; desde ahí cada Godot corre con `timeout`.
- El `--import` del árbol nuevo terminó con un `core` la primera vez; la segunda anduvo.

## 7. Lo que falta

1. Al final del 4v4 el tick promedio es 58 ms: ×4 sigue llegando hasta el minuto 15. Es costo por
   entidad: IA 10 ms (`_military` 2,6), recolección 8 ms (`follow`/`approach`), movimiento 4 ms.
2. Caminos: quedan 1248 parciales (2,6 s en 40 min; el primero de cada encierro) y 50 «a sólido»
   (8 ms cada uno: el destino es un edificio). Picos de 40–47 ms en un tick.
3. El segundo: `_aura_heal` recorre la tropa por cada hito con cura; `_rents` y `_court_extract`
   (Etiopía recorre `sim.entities` buscando riqueza) dan picos de 8–14 ms.

## Commits

b968b33 destinos encerrados, granja, caminos incas y sitios · (este) documentación y perfilador.
