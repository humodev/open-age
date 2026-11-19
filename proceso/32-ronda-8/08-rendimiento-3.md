# Rendimiento, paso 3: costo por entidad de la recolección y el movimiento

Pedido: bajar el costo por entidad de la recolección y del movimiento (grilla espacial,
recurso más cercano guardado, no recalcular lo que no cambió, repartir en ticks), priorizando lo
que no cambia el resultado. Medir con `tools/perfil_sim.gd` el 1v6, el tct7 y el 4v4.
Bloques marcados `# --- rendimiento 3 ---` en `src/sim/sim.gd`, `sim_map.gd` y `sim_entity.gd`.
No se tocó `sim_ai.gd`, `sim_comercio.gd`, el combate ni las órdenes.

## 1. Qué cambió (todo con el mismo resultado)

Los tres hashes del perfilador a 40 minutos quedan **iguales** a los de main (1v6 566821624,
tct7 2719395208, 4v4 3800868535) y `tests/test_determinism.gd` da el mismo hash (3059812827).

- **Tasa de recolección guardada por aldeano** (`_do_gather`): la tasa se arma con la fuente,
  los modificadores, el bono por sitio y el aura. Ahora se guarda en el aldeano (`rate_t`,
  `rate_ep`, `rate_v`) y vale mientras no cambie la fuente ni la «época»: sube con cada
  `_add_mod` (el único lugar que escribe modificadores), cuando cambian las auras de los hitos y
  cuando cambia el agua del mapa (`map.water_ver`). La arcilla (bono por caminos) se calcula
  siempre. Los `def` no cambian en la partida (solo se duplican al carnear).
- **Aura por fuente** (`_aura_gather`): los hitos no se mueven; `_update_players` arma una firma
  de las auras y, si es la misma del tick anterior, el valor por (fuente, dueño, recurso) sale de
  una tabla.
- **Bono por sitio por granja** (`_site_bonus`): se guarda por granja con `map.water_ver`.
- **`find_resource`**: sin crear una entidad de sonda por consulta (`_dist_pt`), las celdas vacías
  sin arreglo nuevo (`_NONE`), el techo de lo disputado una vez por consulta y el anillo recorrido
  sin pasar por las casillas de adentro. Lo mismo en `nearest_dropoff`, `_rebusca_lejos` y
  `_nearest_unbuilt`.
- **`_exhaust`**: busca a los que trabajaban en la fuente en `_units` (las unidades de `actives`,
  en el mismo orden) en lugar de todo `actives`.
- **Niebla** (`_update_fog`): las fuentes salen de las listas de cada dueño del equipo en lugar
  de recorrer `actives` una vez por jugador. Otro orden, las mismas fuentes; la niebla pinta la
  unión, así que la grilla queda igual.
- **`_try_move`**: `map.is_solid` en línea (sin puertas es leer `solid`), de 4 a 8 llamadas
  menos por paso. Corre en el movimiento y en la separación.

Probado y **descartado**: reusar las celdas de `_grid` y `_ehash` entre ticks (vaciar las usadas
en lugar de `clear()`). Mismo hash, pero «tablas» costó un 13 % más en relación con la IA (dos
corridas del 1v6: 0,31 contra 0,27); volvió a como estaba.

No se hizo nada que cambie el resultado (repartir la recolección en ticks): no hizo falta correr
`tools/primera_victoria.gd`.

## 2. Medidas

**Ojo con los números absolutos.** Se midió con la máquina compartida por 7 agentes (carga 22 a
30) y la carga cambió entre la corrida de antes y la de después: la IA, que no se tocó, bajó de
22,8 a 12,6 ms en el tct7. Las corridas valen para comparar **cada sistema contra la IA** de la
misma corrida (columna «/IA»), no entre sí.

| Partida · sistema | antes ms (/IA) | después ms (/IA) | cambio relativo |
|---|---|---|---|
| tct7 · recolección | 17,94 (0,79) | 8,27 (0,66) | −17 % |
| tct7 · niebla | 8,45 (0,37) | 2,95 (0,23) | −37 % |
| tct7 · find_resource | 3,14 (0,14) | 1,49 (0,12) | −14 % |
| tct7 · movimiento | 6,97 (0,31) | 3,87 (0,31) | 0 |
| tct7 · separación | 4,99 (0,22) | 3,12 (0,25) | ruido |
| 4v4 · recolección | 16,78 (0,64) | 9,02 (0,51) | −20 % |
| 4v4 · niebla | 7,07 (0,27) | 4,08 (0,23) | −14 % |
| 4v4 · find_resource | 2,74 (0,10) | 1,58 (0,09) | −14 % |
| 4v4 · movimiento | 8,61 (0,33) | 5,91 (0,33) | 0 |
| 1v6 · recolección | 7,64 (0,84) | 4,78 (0,70) | −17 % |

Tick entero (con la carga de cada momento; el «antes» con más carga):

| Partida | Prom. ms | p95 ms | Peor ms | Ticks > 100 ms | ×4 alcanza hasta |
|---|---|---|---|---|---|
| 1v6 (17,6 min) | 39,5 → 28,4 | 98,9 → 67,1 | 232 → 144 | 511 → 64 | min 6 → 9 |
| tct7 (40 min) | 100,4 → 52,3 | 224,8 → 110,6 | 506 → 248 | 11 293 → 1907 | min 5 → 9 |
| 4v4 (40 min) | 100,8 → 64,7 | 207,5 → 139,6 | 442 → 492 | 11 091 → 4394 | min 3 → 8 |

En el paso 2 (07), con la máquina libre, el tct7 daba 30 ms de promedio; acá el mismo código de
main dio 100. Las metas (p95 bajo 40 ms, nada sobre 100 ms, ×4 hasta el minuto 30 del tct7) no se
pueden juzgar con esta carga; por la proporción, lo ganado es del orden del 8 al 10 % del tick
(recolección y niebla son un cuarto del tick), lejos de la mitad que pide ×4 en el minuto 30.

`tests/bench.gd` (main → rama, misma carga): 200 unidades 13,99 → 13,69 ms; 6 × 150 unidades
41,14 → 41,02 ms; 6 IA 20 min 15,61 → 14,55 ms (último minuto 26,0 → 24,5). No empeora.

## 3. Pruebas

- `tests/test_determinism.gd`: OK, hash 3059812827 (igual que main).
- Perfilador: los tres hashes iguales a main.
- `tests/bench.gd`: no empeora (arriba).
- `tests/jugabilidad.gd`: OK.
- `tests/equipos.gd`: OK (2v2 ×4, 3v3 ×2 y todos contra todos con 6, 30 min; fuego amigo 0; el
  todos contra todos se corrió aparte con `--solo=ffa6` porque el `timeout` cortó la corrida entera).

## 4. Tropiezos

- La máquina con carga 22–30 hizo que una partida de 40 minutos tarde 40 minutos de reloj y que
  los tiempos absolutos no sirvan para comparar; se comparó contra la IA de la misma corrida.
- Reusar las celdas de las tablas parecía obvio y costó más (diccionario más grande, celdas
  vacías recorridas al vaciar).

## 5. Lo que falta

1. La IA (24–27 % del tick) es lo más grande y no se tocó en este paso.
2. Recolección: lo que queda es caminar (`_approach`/`_follow`) y las búsquedas de diccionario
   del aldeano quieto. Repartir la extracción cada 2 ticks (cambia el resultado) o pasarlo a
   código nativo.
3. Niebla: el pintado de los círculos (`sim_fog.gd`); con conteo por casilla, solo las fuentes que
   cambian de casilla repintan.
4. Movimiento y separación: `mods.speed` lee varios diccionarios por paso; la separación hace 9
   búsquedas de diccionario por unidad; una grilla plana (arreglos) los bajaría.

## Commits

986a69c find_resource, clave de tasa y bono por sitio · 547df7c aura por fuente, niebla por
dueño, `_try_move` en línea, sin sondas · 9cbe38e tasa guardada por aldeano · 48ce5e5 tablas
como en main.
