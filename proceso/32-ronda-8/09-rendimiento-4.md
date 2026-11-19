# Rendimiento, paso 4: niebla, `mods.speed` y separación

Pedido: bajar el costo de lo que quedaba en «Lo que falta» de `08-rendimiento-3.md` sin tocar
la IA: pintado incremental de la niebla, `mods.speed` más barato y la separación con una grilla
plana. Prioridad: el mismo resultado. Bloques marcados `# --- rendimiento 4 ---` en
`src/sim/sim_fog.gd`, `src/sim/sim.gd` y `src/sim/sim_mods.gd`. No se tocó `sim_ai.gd`.

## 1. Qué cambió (todo con el mismo resultado)

- **Niebla incremental** (`sim_fog.gd`): cada círculo distinto (casilla, radio) suma 1 en las
  casillas que cubre (`_cnt`, una cuenta por casilla y por jugador). En cada pasada se arma el
  conjunto de círculos del turno y se compara con el anterior: solo se despintan los que
  desaparecen y se pintan los que aparecen. Visible (2) es cuenta > 0, que es la misma unión de
  antes; al bajar a 0 la casilla queda explorada (1). Un edificio o un aldeano quieto ya no
  repinta nada. Se despinta antes de pintar, así una casilla que sale y vuelve queda en 2.
- **Visión compartida** (`copy_from`): el aliado que copia aplica solo las casillas que
  cambiaron en la última pasada de la fuente (`_diff`), si su copia anterior fue de la versión
  anterior de esa fuente (siempre, con el orden de `_update_fog`); si no, recorre la grilla
  entera. Si un jugador que copiaba vuelve a calcular la suya, se recuenta de cero.
- **Separación con grilla plana** (`sim.gd`): el diccionario `_grid` (celda → arreglo) pasa a
  tres arreglos: `_cell_head` (n × n, primera ranura de la celda), `_cell_next` y `_cell_ent`,
  armados en `_rebuild_hashes` en el orden de `actives` (se agrega por la cola, como el
  `append` de antes). Lo usan `_separate`, `_claim_animals` y `tick_traps` (`sim_mods.gd`): sin
  búsquedas de diccionario ni arreglos vacíos por celda.
- **`mods.speed`**: los dos porcentajes de `reglas.movimiento` se leen una vez, la casilla se
  calcula una vez, y el agua (vado) se mira antes que el modificador del dueño. Las búsquedas de
  diccionario quedan solo en el agua y en el camino. No se guardó la velocidad por entidad: la
  validez depende del agua, los caminos, el freno de las inundaciones, los módulos y los
  modificadores, que se escriben en archivos ajenos a este paso; la comprobación costaría lo
  mismo que la cuenta, que ya es corta.

## 2. Medido

`tools/perfil_sim.gd -- --partida=4v4 --minutos=20`, semilla 42. La máquina estaba cargada con
otras partidas, así que se compara cada sistema contra la IA de la misma corrida (la IA no
cambió). Hash final igual en las dos: **1566358519**.

| sistema     | antes ms | ahora ms | antes / IA | ahora / IA | proporción |
|-------------|---------:|---------:|-----------:|-----------:|-----------:|
| IA          | 8.68     | 8.84     | 1          | 1          | —          |
| niebla      | 2.25     | 1.22     | 0.259      | 0.138      | **−47 %**  |
| separación  | 1.75     | 1.44     | 0.202      | 0.163      | **−19 %**  |
| movimiento  | 2.53     | 2.50     | 0.291      | 0.283      | −3 %       |
| tablas      | 2.14     | 2.08     | 0.247      | 0.235      | −5 %       |

Picos de la niebla: p95 8.79 → 5.40 ms, peor 25.7 → 16.8 ms. El tick entero: 32.5 → 31.2 ms
de promedio, 172 → 147 ms el peor.

## 3. Pruebas

- `tests/test_determinism.gd`: hash 3059812827, el mismo, después de cada paso.
- `tests/bench.gd`: promedio 12.7–13.8 ms contra 13.0–14.4 ms de main en tres corridas
  alternadas; el peor tick varía igual en las dos (80–130 ms, máquina cargada).
- `tests/jugabilidad.gd`: OK. `tests/guardado.gd`: OK (repeticiones y fotos, mismos hashes).

## 4. Lo que falta

1. Niebla: lo que queda es armar el conjunto de círculos (una lectura de `def` y de la altura
   por fuente). Una unidad que pasa a la casilla de al lado despinta y pinta su círculo entero;
   alcanzaría con los bordes.
2. Separación: el costo ya es la cuenta de cada par (`isqrt` y los dos `_try_move`).
3. Movimiento: `_try_move` y el camino (`_follow`), no la velocidad.

## Commits

1a96eda niebla incremental · c2c69cb grilla plana de celdas · 84bb6e6 `mods.speed`.
