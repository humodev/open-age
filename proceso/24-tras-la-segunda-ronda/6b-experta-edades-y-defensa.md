# 24 · Paso 6b: la experta sube de edad y se defiende al expandir

## Pedido
Del [informe del veterano, sexta ronda](../22-testers/ronda-6/01-veterano-aoe4.md) (puntos 4, 6 y 7):
1. **Sube lento de edad.** Experta contra experta a los 20 minutos: edad II a las 6:17–9:29 y una sola edad III en 6 jugadores; contra el veterano, nunca la III en 30 minutos.
2. **Es frágil cuando se expande.** Su ataque del minuto 12 la llevó de 36 a 20 aldeanos y de ejército a 4.

Metas del orquestador: edad II antes de 6:00 y edad III antes de 15:00 en espejo, sin perder la economía grande; ejército mínimo según el rival que ve, torre en cada centro nuevo, aldeanos al centro ante un ataque grande. **Sin cambiar fácil, normal ni difícil** (hash de `tests/test_determinism.gd`).

## Cómo se mide
- **`tools/experta_edades.gd`** (nueva): IA contra IA (por defecto experta contra experta, cada civ contra sí misma), hora a la que pone cada hito y a la que llega a cada edad, y aldeanos/ejército/centros/torres/edad a los 5, 10, 15 y 20 minutos. Cuenta cuántos llegan a la II antes de 6:00 y a la III antes de 15:00. Acepta `--ajuste` como `experta_vs_dificil.gd`.
- **`tools/ataque_veterano.gd`** (nueva): el script `apertura3.gd` con el que jugó el veterano (boom y ataque en movimiento al minuto 12), traído a `tools/`. Arreglo: el del veterano además hacía pensar a la IA a mano antes de cada paso, o sea dos veces por pensada. Ahora cuenta también los aldeanos de adentro (campana) y acepta `--nivel=clave=valor`.
- **`tools/experta_vs_dificil.gd`**: 24 partidas (semillas 41 y 42, llano y río).

## Paso a paso

**Primero, un error de la experta (y de la simulación).** En el espejo de Tawantinsuyu (semilla 41) el jugador 0 no pasó nunca de la edad I y perdió por sitios. Mirando de cerca ([sonda](pruebas/6b-edades-espejo.txt), línea "antes"): de 6:00 a 10:00 tenía **21 aldeanos del alimento parados** junto a unos árboles, con el banco en 0 de alimento. Una llama se carneó en un hueco cerrado por árboles (la carne a 2 casillas, sin camino); la IA manda a toda la gente del alimento a "la carne abierta más cercana" y la simulación no los suelta: se deslizan contra los árboles y nunca llegan a 25 pasos trabados. Arreglo de la experta (`comida_inalcanzable`): si un aldeano que junta está a 4 casillas o menos del recurso, no lo alcanza y no hay camino (`map.find_path`), ese recurso queda descartado y el aldeano va a otro.

Después, una idea por vez (espejo de expertas, semilla 41, 12 jugadores, [resultados](pruebas/6b-edades-espejo.txt)):

| # | Idea | II antes de 6:00 | II media | III antes de 15:00 | III en 20' |
|---|---|---|---|---|---|
| — | Antes | 1 | 9:25 | 3 | 4 |
| V1 | Comida inalcanzable | 1 | 8:31 | 2 | 7 |
| V2 | V1 + **hito antes que el resto con el mínimo hecho** (`ahorro_con_minimo`) | 1 | 8:31 | 3 | 9 |
| V3 | V2 + el centro no toca lo del hito (`expansion.reserva_hito`) | 1 | 8:31 | 2 | 8 |
| V4 | V2 + más alimento en la edad II (50/28/13/9) | 1 | 8:31 | 1 | 6 |
| V5 | V1 + **ahorro continuo** (`ahorro_continuo`: aunque falte tropa) | 1 | 8:30 | **6** | 8 |
| V6 | V5 + **8 aldeanos en el hito** (`hito_constructores`) | 1 | 7:57 | 4 | **10** |
| V7 | V6 + **más gente en lo que falta al hito** (`refuerzo_hito` 24, antes 12) | **3** | 7:42 | 5 | **10** |
| Final | V7 con `ahorro_con_minimo` en lugar de `ahorro_continuo`, + defensa | **3** | **7:23** | 2 | 8 |

Lo que se vio:
- En la edad II la experta casi nunca ahorraba: con el alimento en 0–100, el ahorro era intermitente (un tercio del tiempo) y, sin ahorro, todo el alimento iba a aldeanos de tres centros y a tropa. El ejército nunca llegaba al mínimo de 20 (lo mataban), así que `ahorro_con_minimo` casi no cambia nada. Ahorrar siempre (V5) sí: la III antes de 15:00 pasa de 3 a 6.
- El cuello de la edad I es la riqueza (Etiopía a los 4:00: 599 de alimento y 226 de riqueza, con 1–2 aldeanos en riqueza). Con `refuerzo_hito` 24 la II llega antes de 6:00 en 3 de 12.
- 8 aldeanos en el hito lo terminan en ~60 s en lugar de ~95 s.
- Reservar el hito antes del centro (V3) y más alimento (V4) no movieron nada.

**Pero el ahorro continuo pierde contra la difícil** ([24 partidas](pruebas/6b-experta-contra-dificil.txt)):

| Variante | Experta gana (24) |
|---|---|
| Antes (main, claves del 6b apagadas) | 14 (58 %) |
| Con `ahorro_continuo` (V7 + defensa) | **8 (33 %)** |
| **Final** (`ahorro_con_minimo`) | 13 (54 %) |

Con el ahorro continuo la tropa que falta sale solo de lo que sobra por encima del hito: a los 10 minutos tiene 0–10 militares y la difícil, que ataca a los 8–9, la tira. Por eso queda `ahorro_con_minimo` (ahorra siempre solo con el mínimo hecho) y `ahorro_continuo` queda en los datos, apagado.

**Defensa al expandir** (todo en la experta):
- **`ejercito_segun_rival`** (`pct` 100, `memoria_ticks` 1800, `tope` 60): el ejército mínimo es el de la edad o el mayor ejército rival que vio en los últimos 3 minutos, lo que sea más. "Vio" es con su niebla (`sim.fog.is_visible`): solo lo que tiene a la vista. Vale para el ahorro y para lo que se junta para el centro.
- **`torre_por_centro`** (`radio` 8 casillas, `adelante` 4, `constructores` 2): una torre junto a cada centro nuevo, del lado de la base rival, con la piedra que sobra después de lo que pide el hito. Guaraníes y mapuches no tienen torre. En el espejo final, Etiopía y Ayutthaya levantan 2 y Tawantinsuyu 1.
- **`campana_en_centros`**: la campana se toca también por un ataque a un centro nuevo (antes solo se miraba la capital). Con la campana ya iban `enemigos × 3` aldeanos al refugio más cercano: ante un ataque grande, todos.

**[El ataque del veterano](pruebas/6b-ataque-veterano.txt)** (Tawantinsuyu del veterano contra Etiopía experta, y al revés; semilla 7; aldeanos con los de adentro / ejército):

| Minuto | Etiopía experta, antes | Etiopía experta, ahora | Tawantinsuyu experta, antes | Tawantinsuyu experta, ahora |
|---|---|---|---|---|
| 12 (ataque) | 40 / 16 | 40 / 18 | 37 / 15 | 38 / 20 |
| 14 | 42 / 12 | 52 / 14 | 48 / 7 | 45 / 13 |
| 16 | 38 / 1 | 57 / 6 | 59 / 22 | 57 / 9 |
| 18 | 40 / 1 | 60 / 2 | 74 / 44 | 72 / 32 |
| 19 | 34 / 4 | **26 / 4** | 82 / 52 (edad III 18:19) | 80 / 26 |
| Edad II | 6:24 | **5:29** | 5:52 | **4:58** |

- Etiopía aguanta mejor el primer golpe: de 40 sube a 60 aldeanos (antes se quedaba en 38–42) y la campana la protege. Pero a los 19 minutos el ejército del veterano (64 unidades) entra a la base y la deja en 26. Con 2 a 18 militares no hay con qué pararlo: ver "Lo que queda".
- Tawantinsuyu llega a la II un minuto antes, pero esta vez no a la III antes de los 20 (antes, 18:19).

## Qué cambió

**Experta** (`reglas.json` → `dificultades.experta`, claves que las otras no tienen):

| Clave | Valor | Qué hace |
|---|---|---|
| `hito_constructores` | 8 | Aldeanos que van al hito (las demás, 4) |
| `ahorro_con_minimo` | sí | Desde la edad II, con el ejército mínimo hecho, ahorra para el hito siempre (sin el ahorro intermitente) |
| `ahorro_continuo` | no | Lo mismo aunque falte tropa (probado: pierde contra la difícil) |
| `refuerzo_hito` | 24 | % de aldeanos de más en lo que le falta al hito (las demás, `ia_economia.refuerzo_hito`: 12, que antes estaba en el código) |
| `comida_inalcanzable` | sí | Deja el recurso al que no hay camino |
| `campana_en_centros` | sí | Campana también por los centros nuevos |
| `ejercito_segun_rival` | 100 %, 3 min, hasta 60 | Mínimo de tropa según el ejército rival visto |
| `torre_por_centro` | 8 / 4 / 2 | Torre junto a cada centro nuevo |
| `expansion.reserva_hito`, `expansion.edad_min` | no, 1 | Probados y apagados (el centro no toca lo del hito; edad desde la que se expande) |

`ia_economia`: `refuerzo_hito` 12 (el número que estaba en `_economy`), `inalcanzable_lejos` 4000 e `inalcanzable_recheck_ticks` 600.

**Código** (`src/sim/sim_ai.gd`): `_min_army`, `_watch_rival_army`, `_center_towers`, `_free_stuck_gatherers`, `_reachable`; cambian `think` (cuenta del ejército, vigía del rival, aldeanos trabados), `_alarm` (varios centros), `_economy` (saltea lo inalcanzable, `refuerzo_hito`), `_wants_hito`, `_buildings` (constructores del hito, torres), `_production` (mínimo con `_min_army`) y `_expansion_need` (`reserva_hito`, `edad_min`). Sin las claves nuevas el código hace lo mismo que antes.

**Documentos:** [docs/08-ia-rival.md](../../docs/08-ia-rival.md).

## Pruebas
- **Determinismo** ([resultado](pruebas/6b-test_determinism.txt)): OK, hash **2203695307**, el mismo de `main` (paso 5d).
- **Rendimiento** ([`bench`](pruebas/6b-bench.txt)): 9,74 ms de promedio y 91,8 de peor caso con 200 unidades, con la máquina en carga 19–23 por el torneo ajeno.
- **Civs** ([`civ_smoke`](pruebas/6b-civ_smoke.txt)): las 3 partidas sin errores de script (el único "ERROR" es el de recursos al salir, de siempre).
- Ninguna de las ~170 partidas de este paso tuvo errores de script.

## Tropiezos
- **El uso.** El orquestador frenó el trabajo por un corte de uso a mitad de la medida de 48 partidas (semillas 43 y 44): quedó en 24. Con 24 partidas el ruido es ±3.
- **La carga** (torneo ajeno en 8–10 procesos, carga 19–23): 24 partidas de 30 minutos, una hora con 3 procesos.
- **El script del veterano pensaba dos veces** por pensada de la IA (la llamaba a mano y además dentro de `Sim.step`). Sus números de la ronda 6 son con esa IA "doble"; las medidas de este paso, con la herramienta arreglada, antes y después.
- **Aldeanos "adentro".** El "de 36 a 20" del veterano contaba solo los de afuera: con la campana los de adentro no aparecen. La herramienta ahora muestra los dos.

## Lo que queda
- **Edad III antes de 15:00:** no se cumple con la versión que queda (2 de 12 en espejo; 8 de 12 llegan antes de los 20). Lo que la adelanta (ahorrar siempre, V5–V7: 5–6 de 12) le saca tropa y pierde contra la difícil (8 de 24). Hace falta otra palanca: por ejemplo, menos aldeanos por centro ahorrando cuando el alimento del hito no alcanza, o que la tropa mínima se pague con riqueza y madera (unidades sin alimento).
- **Edad II antes de 6:00:** 3 de 12 (antes 1); la media bajó de 9:25 a 7:23. Mapuches y guaraníes ponen el hito a los 6–9 minutos; Palmares no cambia (no tiene centros).
- **Defensa:** sube los aldeanos tras el primer golpe (Etiopía, 40 → 60), pero un ataque de 60+ al minuto 19 todavía la desarma. El mínimo según el rival recién sube cuando ve al ejército, que llega junto con el ataque: falta que explore.
- **Contra la difícil:** 13 de 24 contra 14 de 24 antes, dentro del ruido; con menos victorias claras (conquista) y más por puntos.
- **La simulación** también traba a las otras dificultades con la carne en un hueco (el arreglo es solo de la experta, para no cambiar la normal). El arreglo de fondo sería en `Sim._do_gather` (quien se desliza sin acercarse cuenta como trabado), y cambia el hash.

## Riesgos
- **Conflictos con `src/sim/sim_ai.gd`:** `think`, `_alarm`, `_economy`, `_wants_hito`, `_buildings`, `_production`, `_expansion_need`, y las funciones nuevas después de `_buildings`. En `reglas.json`, las líneas de `ia_economia` y de `dificultades.experta`.
- La normal, la difícil y la fácil no cambian (hash igual); `refuerzo_hito` 12 es el número que ya estaba en el código.
