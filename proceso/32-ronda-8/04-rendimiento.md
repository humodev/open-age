# Ronda 8 · 04: rendimiento con 7 y 8 jugadores

> Pedido (ronda 8, prioridad alta): «el 1v6 llega a 27 ms por tick, con picos de 100 a 315 ms;
> a ×4 no alcanza». El autor: «Probemos y hagámoslo bien.» Metas: p95 bajo 40 ms y ningún tick
> sobre 100 ms con 7 a 8 jugadores; ×4 (25 ms por tick) hasta el minuto 30 en 1v6.

## 1. El perfilador: `tools/perfil_sim.gd`

```
godot --headless --path . -s tools/perfil_sim.gd -- --partida=1v6|tct7|4v4|ambas|todas \
      [--minutos=40] [--semilla=42] [--picos=12] [--plano] [--detalle] [--ia-detalle] [--lentos=MS]
```

- Partidas IA contra IA armadas como la partida a medida (proceso/31): llano, tamaño normal,
  equipos juntos, tiempo límite 60. **1v6**: la experta sola contra experta ×2, difícil ×2 y
  normal ×2 (como `proceso/31-partida-a-medida/1v6.json`). **4v4**: experta, difícil ×2 y normal
  por lado. **tct7**: 7 contra todos (3 expertas, 2 difíciles, 2 normales).
- El reloj se mide **desde afuera**: subclases de `Sim`, `SimAI`, `SimMap`, `SimGroups`,
  `SimMods` y `SimTelemetry` que envuelven los métodos con una pila (cada sistema se lleva su
  tiempo propio; lo que llama adentro va a quien corresponde). `src/sim` no lee el reloj.
- Sistemas: ia (cada `think`), caminos (find_path), grupos, movimiento, blancos (find_enemy),
  combate, recolección, find_resource, edificios, separación, tablas, jugadores, niebla,
  telemetría, órdenes, «cada segundo» (mods, auras, maravillas), animales, victoria y el resto.
- Da promedio, p95 y peor de cada uno; los peores ticks con el sistema que más pesó (y qué
  jugador pensaba); el promedio por minuto y hasta qué minuto alcanza ×4.
- `--ia-detalle` reparte la IA por parte de `think`; `--detalle` anota ayudantes (approach,
  try_move, rents…) dentro de la parte que los llamó; `--lentos=MS` imprime cada búsqueda de
  camino más lenta con la pila de quién la pidió.
- **No cambia el resultado**: el hash final con envoltorios es el mismo que con `--plano`.
- El 1v6 IA contra IA termina por conquista a los 12–14 minutos (semillas 1, 2, 3 y 42): no
  sirve para mirar el minuto 30. Por eso está **tct7**: 7 jugadores que llegan a los 40.

## 2. Qué pesaba (antes, main de la ronda 8)

Medido con `perfil_sim.gd -- --partida=todas --minutos=40` sobre main (37a1f5e, hash
718068252), en una copia aparte (`git worktree`). Salida completa: `rendimiento/perfil-antes.txt`.

| Partida | Prom. ms | p95 ms | Peor ms | Ticks > 100 ms | IA prom / p95 | ×4 alcanza hasta |
|---|---|---|---|---|---|---|
| 1v6 (termina a los 14,3 min) | 20,6 | 80,2 | 119 | 142 | 7,9 / 59,9 | min 9 |
| tct7 (40 min) | 44,3 | 179,9 | 344 | 3196 | 17,4 / 122,0 | min 11 |
| 4v4 (40 min) | 62,9 | 272,6 | 524 | 3671 | 27,9 / 202,5 | min 7 |

Los peores ticks eran siempre de la IA (hasta 376 ms de `think` en un solo tick del 4v4).

Lo que más pesaba, en orden:

1. **La IA (40–44 %)**. Dos cosas:
   - *Todas pensaban en el mismo tick.* `thinks_now` usa la fase `jugador × 5`, y con
     `piensa_cada_ticks` de 5 (experta, difícil) o 10 (normal) esa fase es siempre múltiplo
     de 5: en el 4v4 las 8 IA pensaban juntas cada 5 ticks. De ahí los picos de 300–400 ms.
   - *Cada `think` recorre todo el mapa muchas veces.* `sim_ai.gd` tiene 36 recorridos de
     `sim.actives` (unas 2000 entidades al final); `_threat` sola se pedía hasta 11 veces por
     `think` y hacía dos pasadas cada vez (6,5 ms por tick de promedio a los 20 minutos del 4v4).
2. **Recolección (12–15 %)**: trabajo por aldeano en cada tick (tasa, modificadores, auras).
3. **Niebla (10–13 %)**: pintar el círculo de visión casilla por casilla.
4. «Cada segundo» (mods): recorridos de todo el mapa por jugador (rentas, rebaños, sitios).

## 3. Qué cambió

Todo sin cambiar el resultado, salvo el punto 1:

1. **La IA piensa escalonada** (`Sim._spread_ai`, en `sim.gd`, donde se llama a la IA; no
   dentro de `sim_ai.gd`). Cada IA conserva su fase de siempre si nadie más piensa en ese tick;
   si choca, toma la fase menos cargada, contando el tick de «cada segundo» (`tick % 10 == 0`)
   como media IA. **En 1 contra 1 nada cambia** (hash 718068252, el de main). Con 7 u 8
   jugadores el resultado cambia: las IA ya no piensan en el mismo tick que antes. Es el único
   cambio de resultado de esta etapa.
2. **`_threat` una vez por tick y centro** (`sim_ai.gd`, memo en la misma función): el estado no
   cambia dentro de un `think` (las órdenes van al tick siguiente).
3. **Listas por tipo y por dueño** en `Sim`, mantenidas en `_new_entity` y `_cleanup` igual que
   `actives`, en el mismo orden (por id): `owned(pid)`, `buildings_of(pid)`, `all_units()`,
   `all_buildings()` y `military()`. El dueño, la categoría y la función de una entidad no
   cambian nunca, así que recorrer la lista es recorrer `actives` filtrado. Se pasaron a ellas
   los recorridos cuyo primer `if` ya filtraba por eso (un guion revisó que el filtro fuera
   puro: `if A and B:` como único cuerpo o `if not …: continue`): unos 70 entre `sim.gd`,
   `sim_mods.gd`, `sim_ai.gd` y `sim_telemetry.gd`. En `sim_ai.gd` solo cambia la línea del
   `for`.
4. **`is_military`** con un diccionario constante en lugar de armar un arreglo en cada llamada.
5. **Niebla por renglones**: las mismas casillas que el círculo, recorridas por tramos.
6. **Aura de recolección** precalculada por tick en `_update_players`.
7. **Sitios sagrados**: la caja se mira antes que el resto de las condiciones.

Controles de que no cambia el resultado: 4v4 de 6 minutos (3774556062) y de 20 minutos
(3216230678) con el mismo hash antes y después de los puntos 2 a 7; `test_determinism` igual.

## 4. Antes y después

Misma herramienta y mismas partidas sobre la rama (salida: `rendimiento/perfil-despues.txt`).
Como el reparto de la IA cambia el resultado con 7 u 8 jugadores, las partidas no son las mismas
jugada a jugada (al minuto 40 del 4v4 quedan 613 unidades contra 867 antes; en tct7, 788 contra
682): comparar por minuto ayuda.

| Partida | Prom. ms | p95 ms | Peor ms | Ticks > 100 ms | IA prom / p95 | ×4 alcanza hasta |
|---|---|---|---|---|---|---|
| 1v6 (termina a los 12,9 min) | 20,6 → **12,1** | 80,2 → **24,8** | 119 → 93 | 142 → **0** | 7,9 / 59,9 → 2,8 / 7,0 | min 9 → **13 (todo)** |
| tct7 (40 min) | 44,3 → **30,6** | 179,9 → **59,5** | 344 → 127 | 3196 → **4** | 17,4 / 122,0 → 7,2 / 19,9 | min 11 → **16** |
| 4v4 (40 min) | 62,9 → **35,7** | 272,6 → **66,5** | 524 → 253 | 3671 → **28** | 27,9 / 202,5 → 8,5 / 21,5 | min 7 → **12** |

Promedio por minuto (ms por tick):

| Minuto | 5 | 10 | 15 | 20 | 25 | 30 | 35 | 40 |
|---|---|---|---|---|---|---|---|---|
| tct7 antes | 10,9 | 22,8 | 39,4 | 50,0 | 60,4 | 67,3 | 64,1 | 61,3 |
| tct7 después | 8,0 | 15,8 | 22,4 | 30,5 | 40,1 | 48,4 | 48,9 | 47,8 |
| 4v4 antes | 14,6 | 32,4 | 48,7 | 68,2 | 77,3 | 88,8 | 105,2 | 108,3 |
| 4v4 después | 9,3 | 19,8 | 30,4 | 43,0 | 57,6 | 48,9 | 53,3 | 45,0 |

`tests/bench.gd` (main → rama):

| Prueba | Promedio | Peor |
|---|---|---|
| 200 unidades | 9,77 → 9,16 ms | 64,3 → 63,8 ms |
| 6 × 150 unidades | 30,1 → 24,3 ms | 75,7 → 50,2 ms |
| 6 IA, 20 min | 15,9 → 10,8 ms (último minuto 29,9 → 18,5) | 235,1 → 81,6 ms |

Sin envoltorios (`--plano`) la simulación corre más rápido que lo de las tablas: tct7 da 26,6 ms de promedio en lugar de 30,6.

## 5. Lo que falta y por qué

**Metas no alcanzadas todavía:**

- *p95 bajo 40 ms con 7 a 8 jugadores*: el p95 de los 40 minutos queda en 59,5 (tct7) y 66,5
  (4v4); hasta el minuto 15 se cumple (tct7 22 ms de promedio, 4v4 30). Falta un 35–40 %.
- *Ningún tick sobre 100 ms*: quedan 4 (tct7) y 28 (4v4) de 24 000; ninguno en el 1v6.
- *×4 hasta el minuto 30 en 1v6*: en IA contra IA el 1v6 termina a los 13 minutos y ×4 alcanza
  toda la partida (máximo por minuto 21 ms). Con 7 jugadores hasta el final (tct7) alcanza hasta
  el minuto 16; en el minuto 30 el promedio es 48 ms por tick, el doble de los 25 que pide ×4.
  ×2 (50 ms) alcanza en toda la partida de tct7.

**Por qué:**

1. **Los picos que quedan son caminos**, no la IA: ticks con 60–70 búsquedas A* de punta a punta
   del mapa (1,5–2 ms cada una), casi todas desde órdenes (`ordenes/caminos`) y a destinos y
   orígenes distintos, así que una caché por (desde, hasta) no ayuda. Se repiten cada 5 ticks:
   una IA vuelve a mandar a todo su ejército en cada `think` y cada soldado recalcula su camino
   (ver `rendimiento/lentos.txt`). Arreglo propuesto: que la orden repetida al mismo blanco no
   recalcule (cambia el resultado, toca `sim_ai.gd`/`_cmd_target`), o caminos compartidos por
   grupo (`SimGroups` ya lo hace para el movimiento en grupo).
2. **La IA sigue recorriendo el mapa**: quedan unos 20 recorridos de `sim.actives` en
   `sim_ai.gd` que miran enemigos con condiciones mezcladas (`or`, exploradores, sitios); con
   las listas nuevas se pueden pasar a `military()`/`all_buildings()` a mano. Se dejaron para no
   pisar el trabajo en paralelo sobre `sim_ai.gd` (ataques en equipo y mercado).
3. **El costo por entidad crece con el ejército**: recolección (5,6–5,9 ms con 600–800 unidades),
   movimiento, separación y tablas son GDScript por unidad y por tick. Lo siguiente sería
   repartir trabajo en ticks (la tasa de recolección no cambia de un tick al otro; la separación
   ya va cada 2) o pasar el bucle de unidades a código nativo.

## 6. Pruebas

- `tests/test_determinism.gd`: OK, hash **718068252** (el de main: en 1 contra 1 nada cambia).
- Partidas de 3 o más IA: cambia el resultado por el reparto de la IA (punto 1 de §3). Hashes
  del perfilador a 40 minutos: 1v6 2078642622 (antes 1443411635), tct7 1213324295 (antes
  708132169), 4v4 383809084 (antes 2944067325).
- `tests/bench.gd` y `-- --jugadores=6`: mejoran el promedio y el peor (tabla de §4).
- `tests/jugabilidad.gd`: OK. `tests/equipos.gd` (30 minutos: 2v2, 3v3 y todos contra todos): OK, sin fuego amigo.
- `tools/primera_victoria.gd`: no se corrió: es 1 contra 1 con una sola IA y ahí el resultado
  no cambia (mismo hash).

## Commits

9106a04 perfilador · 3177605 IA escalonada y `_threat` · 8901252 niebla por renglones ·
1748d43 listas por dueño · ebbc12e militares · 05155f2 edificios · 841ac07 unidades, aura y
sitios · 42241eb la IA evita el tick de cada segundo · 32d2358, ece1f13, c7a0067 perfilador
(--lentos, tct7).
