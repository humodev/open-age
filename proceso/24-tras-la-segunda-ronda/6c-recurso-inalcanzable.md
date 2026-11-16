# 24 · Paso 6c: el aldeano que no llega a su recurso va a otro

## Pedido
Del [paso 6b](6b-experta-edades-y-defensa.md), "Lo que queda": en el espejo de Tawantinsuyu (semilla 41) una llama se carneó en un hueco cerrado por árboles y **todos los aldeanos del alimento quedaban minutos parados** junto a los árboles. La experta lo esquivaba con `comida_inalcanzable` en la IA, pero el problema es de la simulación: les pasa a todas las dificultades y al jugador. Arreglarlo de fondo en `Sim._do_gather`, con una detección barata y el número en `data/`, una prueba en `tests/jugabilidad.gd` que falle antes y pase ahora, y decidir qué hacer con `comida_inalcanzable`.

## La causa
`_approach` manda al aldeano a la casilla libre junto al recurso más cercana a él (`_side_tile`). En un hueco cerrado por árboles esa casilla está **adentro** del hueco: el buscador (`find_path` con camino parcial) devuelve el tramo hasta lo más cerca que se puede, afuera de los árboles. Al terminar el tramo, `_approach` sigue en línea recta hacia la carne y `_try_move` lo **desliza** por un eje contra los árboles. El contador `stuck` solo sube cuando el movimiento queda bloqueado del todo (0), no cuando desliza (1), y la separación entre los 20 aldeanos los mueve todo el tiempo: nunca llegaban a los 25 pasos trabados que hacían rebuscar. Y si alguno se soltaba, la IA lo volvía a mandar a "la carne abierta más cercana", la misma.

## El arreglo (`src/sim/sim.gd`)
En `_do_gather`, cuando el aldeano todavía no está en alcance, dos señales:

1. **El camino no llega** (inmediata, sin costo: el camino ya se calcula). En el tick en que elige camino hacia el recurso, si la última casilla del camino no toca la huella del recurso (`_path_reaches`), no hay forma de llegar. Ese recurso queda anotado como inalcanzable **para el jugador** (`_unreach_res`, id × 64 + jugador → tick) durante `olvido_ticks` (1800, 3 minutos: un árbol talado puede abrir el paso), y `find_resource` lo saltea para todos sus aldeanos y para la IA. Así la IA no vuelve a mandar gente a esa carne: carnea otro animal.
2. **Sin avance** (respaldo): `sin_avance_ticks` (100, 10 s) a **más de una casilla** del recurso sin acercarse ni pasar de casilla del camino (campos nuevos `prog_d`, `prog_i`, `prog_tick` de `SimEntity`). Ese aldeano va a otro, sin anotar el recurso para los demás. A una casilla o menos no cuenta: es la cola de gente alrededor de una carne (ver Tropiezos).

En los dos casos (y en el `stuck > 25` de antes) busca primero otro del **mismo tipo** (`only_type`, como al agotarse), después cualquiera de su recurso, dentro de `radio_rebusca`; si no hay, vuelve a entregar si carga algo o queda ocioso.

Datos: `reglas.json` → `recurso_inalcanzable` (`sin_avance_ticks` 100, `olvido_ticks` 1800). Documentado en [docs/05](../../docs/05-mecanicas-nucleo.md) (Recolección).

## La experta
Con el arreglo de la simulación, `comida_inalcanzable` no hace nada: el espejo de Tawantinsuyu da lo mismo con y sin él (P0 a la edad II a las 5:50, 38 aldeanos a los 10 minutos; [sonda](pruebas/6c-trabados.txt)), porque los aldeanos dejan la carne apenas eligen el camino, lejos de las 4 casillas donde miraba la experta. **Lo saqué**: `_free_stuck_gatherers`, `_reachable`, `_unreach` y `_reach_ok` de `sim_ai.gd`, sus consultas en `_economy`, y las claves `comida_inalcanzable`, `ia_economia.inalcanzable_lejos` e `inalcanzable_recheck_ticks`. Una sola regla, en la simulación, para todos.

## Cómo se mide
- **`tests/jugabilidad.gd` → `_carne_encerrada`** (nueva): una carne en el medio de un hueco de 3×3 con árboles alrededor, cerca de la base inca; tres aldeanos mandados a ella. A los 2 minutos tienen que estar juntando otra cosa y el alimento tiene que haber subido.
  - Antes: **FALLA** — "3 de 3 siguen con ella, 0 juntan otra cosa, alimento de 200 a 200".
  - Ahora: ok — "0 de 3 siguen con ella, 3 juntan otra cosa, alimento de 200 a 460".
- **`tools/aldeanos_trabados.gd`** (nueva): IA contra IA, cada civ contra sí misma, y cada minuto cuántos aldeanos del alimento están trabados (orden de juntar, sin carga ni trabajando, a 3 casillas o menos de su recurso y sin alcanzarlo). [Resultados](pruebas/6c-trabados.txt), Tawantinsuyu semilla 41, 12 minutos:

| Dificultad | Jugador | Antes: trabados (peor) | Antes: edad / recolectado | Ahora: trabados (peor) | Ahora: edad / recolectado |
|---|---|---|---|---|---|
| Normal | P0 | **21 de 21** desde el minuto 7 | I / 3300 | 3 | **II / 9015** |
| Normal | P1 | 9 | II / 6243 | 4 | II / 7031 |
| Difícil | P0 | **17 de 17** desde el minuto 8 | I / 3220 | 3 | **II / 9390** |
| Difícil | P1 | 10 | II / 6587 | 5 | II / 9406 |

El error no era solo de la experta: la normal y la difícil del jugador 0 quedaban en la edad I con toda la gente del alimento parada. El P1 también tenía 5–10 aldeanos a la vez deslizándose contra algo (otros huecos, otros recursos); ahora 1–5, casi siempre de paso.

## Pruebas
- **Jugabilidad** ([resultado](pruebas/6c-jugabilidad.txt)): OK, con la prueba nueva.
- **Determinismo** ([resultado](pruebas/6c-test_determinism.txt)): OK, hash **2203695307**, el mismo de `main`: en los 5 minutos de la prueba nadie cae en un recurso inalcanzable.
- **Rendimiento** ([`bench`](pruebas/6c-bench.txt)): 9,32 ms de promedio y 92,8 de peor caso con 200 unidades (6b: 9,74 y 91,8). El costo es una comparación por aldeano en camino y, solo si hay recursos anotados, una consulta al diccionario por candidato en `find_resource`.
- **Civs** ([`civ_smoke`](pruebas/6c-civ_smoke.txt)) y **campañas** ([`campaign_smoke`](pruebas/6c-campaign_smoke.txt)): sin errores de script.
- **Autotest** ([resultado](pruebas/6c-autotest.txt)): `AUTOTEST: OK`; después, el crash al salir de siempre (`corrupted size vs. prev_size`, ya anotado por los testers en la ronda 6).

## Tropiezos
- **La cola alrededor de la carne.** La primera versión contaba "sin avance" a cualquier distancia y cambió el hash (1998165433): 3 aldeanos que esperaban a menos de una casilla de una carne, con otros trabajando, no podían acercarse más (la separación los empuja) y se iban a otra; peor, anotaban la carne para todo el jugador y la IA carneaba otra llama. Ahora "sin avance" solo cuenta a más de una casilla y no anota el recurso para los demás; lo anota solo el camino que no llega, que es una prueba firme. Con eso el hash volvió al de `main`.
- **"Antes" sin `git stash`:** para medir el código de antes, una copia del proyecto en el scratchpad con `sim.gd`, `sim_ai.gd`, `sim_entity.gd` y `reglas.json` de `HEAD`.

## Lo que queda
- El balance (torneo) lo mide el orquestador. El hash no cambia, pero en partidas largas sí: cualquier jugador con una carne o un árbol en un hueco ahora junta en vez de esperar.
- "Sin avance" también suelta a un aldeano que da un rodeo muy largo sin pasar de casilla del camino durante 10 s; no lo vi pasar (cada casilla del camino cuenta como avance).
- Los otros que se acercan con `_approach` (construir, entregar, atacar edificios) siguen con el `stuck` de antes; si aparece el mismo deslizamiento ahí, la misma idea sirve.

## Riesgos
- **Conflictos:** `src/sim/sim.gd` (`_do_gather`, `find_resource`, `_path_reaches` nueva, la variable `_unreach_res`), `src/sim/sim_ai.gd` (se sacan `_free_stuck_gatherers` y `_reachable`, y líneas de `think` y `_economy`), `data/reglas.json` (`recurso_inalcanzable` nueva; `ia_economia` y `dificultades.experta` pierden claves).
- `_unreach_res` no entra en `state_hash`: es un recuerdo que solo cambia decisiones, y esas se ven en las entidades.
