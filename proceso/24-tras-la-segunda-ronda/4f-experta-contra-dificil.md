# 24 · Paso 4f: experta contra difícil

## Pedido
[C-51](../CONSULTAS.md), opción por defecto: otro paso de ajuste para que la experta le gane a la difícil con claridad (meta: 70 % o más en partidas experta contra difícil, las seis civs, varias semillas y terrenos) **sin cambiar cómo juegan fácil, normal y difícil** (hash de `tests/test_determinism.gd`: 1249639671). Del [paso 4a](4a-ia-experta.md): la economía grande llega tarde, a los 10–15 minutos tiene igual o menos ejército, y tres centros se comen el alimento del hito.

Durante el paso, el orquestador sumó tres pedidos del veterano de AoE4 ([ronda 3](../22-testers/ronda-3/01-veterano-aoe4.md)):
1. La experta reconstruye graneros sin fin donde se los rompen (55 en 20 minutos, 2750 de madera).
2. Sube tarde de edad (los centros extra comen el alimento del hito).
3. Que la IA (normal, difícil y experta) ataque el hito rival mientras está en obra, y si se puede sin cambiar el hash de la normal.

## Cómo se mide
**`tools/experta_vs_dificil.gd`** (nueva): cada civ contra sí misma, experta contra difícil, con tiempo límite (`tiempo_limite_min`: a los 30 minutos gana por puntos, `Sim.score`). La experta cambia de lado con la semilla. Da quién gana y cómo (conquista, sitios o puntos), los puntos, y aldeanos/ejército/edad de cada una a los 10, 15 y 20 minutos. `--ajuste=clave=valor` cambia una clave de `dificultades.experta` sin tocar `reglas.json`: así se mide una idea por vez, y se pueden correr variantes en paralelo sin que una partida lea los datos de otra. `--parte=i/n` reparte las partidas entre procesos.

Medida principal: 6 civs × semillas 41, 42, 43 y 44 × llano y río = 48 partidas. Para cribar ideas, 12 o 24 partidas (semillas 41 y 42).

**`tools/hito_en_obra_ia.gd`** (nueva): IA contra IA, cuántos segundos pasa un enemigo militar a 12 casillas o menos de un hito en obra (la medida del veterano), cuántos hitos se pierden en obra y a qué hora sube cada uno de edad. `--apagado` lo mide como antes.

## Paso a paso

Las ideas del pedido, una por vez (todas en `dificultades.experta`). Cada línea es una variante contra el mismo código; "24" son semillas 41 y 42 en llano y río; "12 (s42)" es la semilla 42 sola, que era la difícil.

| # | Idea | Partidas | Experta gana | Antes (mismas partidas) | Resultado |
|---|---|---|---|---|---|
| — | Antes ([4f-antes](pruebas/4f-antes.txt)) | 24 | 17 (6 por conquista o sitios) | — | — |
| V1 | Ahorrando para el hito, aldeanos de un solo centro ([v1](pruebas/4f-v1-centros-ahorrando.txt)) | 24 | 16 | 17 | Igual: los mapuches pierden aldeanos y la edad III no llega antes. Se quitó |
| A | Centro nuevo solo con 25/40 de ejército ([cribado](pruebas/4f-cribado-expansion-oleadas.txt)) | 12 (s41) + 12 (s42) | 10 + 7 | 11 + 6 | Arregla el derrumbe de Tawantinsuyu en río (s41), pierde otra. Igual |
| B | Centro nuevo recién en la edad III | 12 + 12 | 10 + 7 | 11 + 6 | Igual |
| C | Centro nuevo con 36/60 aldeanos (antes 26/50) | 12 + 12 | 11 + 8 | 11 + 6 | Algo mejor en s42, dentro del ruido |
| D | A y C juntos | 12 (s42) | 7 | 6 | Igual |
| E | Oleada desde 10 (antes 16) | 12 (s42) | 5 | 6 | Peor |
| F | Ejército mínimo ahorrando 12/24/36 (antes 20/30/40) | 12 (s42) | 4 | 6 | Peor |

Ninguna idea de economía o de tiempos movía el resultado más que el ruido (±2 partidas de 12). Entonces miré una partida perdida de cerca: Tawantinsuyu en llano, semilla 42, perdida por sitios a las 17:58. La difícil tomó los tres sitios a los 8 minutos y la experta, con 19 a 61 unidades, **no salió nunca de su base**: todo el ejército en ataque-movimiento entre su base y un explorador o un grupito rival junto a un almacén. `_military` mandaba a *todo* el ejército libre contra cualquier amenaza, y una amenaza chica cerca de un edificio alejado duraba toda la partida.

| # | Idea | Partidas | Experta gana | Antes | Resultado |
|---|---|---|---|---|---|
| G | Graneros (pedido 1), hito en obra (pedido 3) y **recuperar sitios** (`sitios_disputa`, `sitio_grupo` 8) ([g](pruebas/4f-g-graneros-hito-sitios-s42.txt)) | 12 (s42) | 7 | 6 | Recuperar sitios solo no alcanza: el ejército sigue atado a la amenaza |
| H | G + **defensa proporcional** ([h](pruebas/4f-h-defensa-proporcional.txt)) | 24 | 17 (**11** por conquista o sitios) | 17 (6) | Igual en victorias, pero casi el doble de victorias claras; la difícil gana por conquista o sitios 1 vez (antes 3) |
| I | H + A ([i](pruebas/4f-i-mas-ejercito-antes-del-centro.txt)) | 24 | 16 | 17 | Igual. A no queda |
| J | H + gente fuera de lo que sobra desde 300 (antes 600) ([j](pruebas/4f-j-banco-sobra.txt)) | 24 | 16 | 17 | Igual. No queda |
| K | H + con menos de 60 % de ejército por aldeano, sin aldeanos ([k](pruebas/4f-k-ejercito-por-aldeano.txt)) | 24 | 14 | 17 | Peor (los guaraníes y los mapuches se frenan). No queda |
| L | H + unidades propias siempre primero ([l](pruebas/4f-l-unidades-propias.txt)) | 24 | 16 | 17 | Igual. No queda |
| P1 | H + Palmares (sin centros) con las oleadas y el mínimo de la difícil ([p1](pruebas/4f-palmares-sin-centros-1.txt)) | 8 (Palmares) | 2 | 2 | Igual |
| P2 | P1 + sin defensa proporcional ni sitios ([p2](pruebas/4f-palmares-sin-centros-2.txt)) | 8 (Palmares) | 3 | 2 | Igual: la experta Palmares juega como la difícil, y las semillas 42 y 43 dan la misma partida espejada. No queda |

Queda **H**. La medida final, con dos semillas nuevas (43 y 44, [después](pruebas/4f-h-semillas-43-44.txt), [antes](pruebas/4f-antes-semillas-43-44.txt)), junta 48 partidas:

| Civ | Antes | Después | Victorias claras de la experta (antes / después) | Victorias claras de la difícil (antes / después) |
|---|---|---|---|---|
| Ayutthaya | 7/8 (87 %) | 6/8 (75 %) | 2 / 1 | 0 / 1 |
| Etiopía | 6/8 (75 %) | 6/8 (75 %) | 1 / 3 | 2 / 1 |
| Guaraníes | 6/8 (75 %) | 5/8 (62 %) | 0 / 0 | 1 / 0 |
| Mapuches | 8/8 (100 %) | 8/8 (100 %) | 6 / 6 | 0 / 0 |
| Palmares | 5/8 (62 %) | 2/8 (25 %) | 0 / 2 | 1 / 2 |
| Tawantinsuyu | 1/8 (12 %) | **6/8 (75 %)** | 1 / 5 | 6 / 2 |
| **Total** | **33/48 (69 %)** | **33/48 (69 %)** | **10 / 17** | **10 / 6** |
| Sin Palmares | 28/40 (70 %) | **31/40 (78 %)** | | |

"Clara" es por conquista o por sitios; el resto se decide por puntos a los 30 minutos, muchas veces por menos de 5 %.

## Qué cambió

**Experta** (`reglas.json` → `dificultades.experta`, claves que las otras no tienen):
- **`defensa_proporcional`** (`factor_pct` 150, `minimo` 6, `radio` 10 casillas): a la amenaza va 1,5 veces los enemigos que hay a 10 casillas de ella (al menos 6), contando a los propios que ya están ahí, los más cercanos primero. El resto sigue con su plan (oleada, sitios, hito). `SimAI._defend_some`.
- **`sitios_disputa`** (`ejercito_min` 6, `cada_ticks` 150): si un rival tiene todos los sitios y corre su cuenta, todo el ejército libre va al sitio suyo más cercano. `SimAI._retake_site`.
- **`sitio_grupo`** 8: el grupo que va a tomar un sitio (las demás: 4, como antes).

**Todas las dificultades** (pedidos del veterano):
- **Graneros** (`ia_economia.almacen_perdido_radio` 8, `almacen_perdido_espera_ticks` 3000, `almacen_perdido_max` 1): la IA recuerda los almacenes que perdió (`_track_stores`) y no levanta otro a 8 casillas o menos de uno perdido en los últimos 5 minutos (`_store_lost_near`). Con el script del veterano (`apertura3.gd --civ=tawantinsuyu --rival=etiopia --min=21 --plan=boom --ataque=14 --const=4 --dif=experta`): **55 graneros → 2** ([antes](pruebas/4f-granero_antes.txt), [después](pruebas/4f-granero_despues.txt)). La experta le sigue ganando por sitios (20:11 antes, 19:41 ahora).
- **Hito en obra** (`ataca_hito_en_obra` en normal, difícil y experta; `reglas.ia_hito_en_obra`: `ejercito_min` 6, `cada_ticks` 100): con 6 unidades o más, el ejército libre va a pegarle al hito rival en obra (`_hit_hito`, antes que la oleada) y el hito propio en obra cuenta para la amenaza (`_threat`), así se defiende. La fácil no lo hace.

[Hito en obra, normal contra normal, 16 minutos](pruebas/4f-hito_on.txt) ([antes](pruebas/4f-hito_off.txt)), segundos con un enemigo a 12 casillas o menos del hito en obra (jugador 0 / jugador 1):

| Partida | Antes | Ahora |
|---|---|---|
| Tawantinsuyu–Etiopía s7 | 0 / 0 | 0 / 0 |
| Tawantinsuyu–Etiopía s8 | 0 / 0 | 31 / 0 |
| Guaraníes–Mapuches s7 | 0 / 0 | 32 / 0 |
| Guaraníes–Mapuches s8 | 0 / 0 | 21 / 0 |
| Ayutthaya–Palmares s7 | 0 / 0 | 7 / 79 |
| Ayutthaya–Palmares s8 | 0 / 41 | 10 / 36 |

- Ahora en 5 de 6 partidas alguien va al hito en obra. Ningún hito se perdió en obra: el hito tiene mucha vida y los primeros grupos son chicos. Las edades no cambian salvo en Ayutthaya–Palmares (Palmares sube a la II a las 13:29 en lugar de 11:45 en s7 y a las 10:21 en lugar de nunca en s8).
- La ventana de la edad II casi no se usa: en la edad I, ahorrando para el hito, la IA no hace ejército (mínimo 0), así que rara vez tiene 6 unidades. Para que el hito de la edad II también se ataque habría que bajar `ejercito_min` (con 1–3 unidades es acoso, no un ataque).

**Probado y quitado** (no movían el resultado; el código y los datos no quedan): aldeanos de un solo centro ahorrando (V1), centro nuevo con ejército mínimo o en la edad III (A, B), oleadas y mínimos más bajos (E, F), gente fuera de lo que sobra antes (J), freno de aldeanos con poco ejército (K), unidades propias siempre primero (L), otro plan para Palmares (P1, P2).

## Lo que queda
- **La meta no se cumple del todo.** 69 % en 48 partidas, igual que antes; sin Palmares, 78 %. Lo que mejoró es la forma: el doble de victorias claras (17 contra 10) y la difícil gana menos por conquista o sitios (6 contra 10). Tawantinsuyu pasa de 1/8 a 6/8.
- **Palmares queda en 25 %** (antes 62 %, por puntos y con márgenes chicos). Sin centros que entrenen aldeanos, la experta Palmares es casi la difícil: con el plan de la difícil (P2) las partidas se espejan y queda en 3/8. Para que la experta Palmares sea más fuerte hace falta algo propio de Palmares (la fama, los mocambos), no de la experta.
- **Guaraníes en río** y los derrumbes tempranos de Tawantinsuyu y Etiopía en río (3–4 de ejército a los 10 minutos, s41 y s43) siguen: la difícil ataca con 6 a los 8–9 minutos y la experta, sin ejército mientras ahorra en la edad I, pierde aldeanos.
- **Sube de edad tarde** (pedido 2 del veterano): ninguna idea lo arregló (V1, F). La edad III de la experta sigue llegando a los 15–20 minutos, a veces después que la difícil.
- **Ruido**: con 12 partidas, ±2 victorias es ruido; con 24, ±3. Las decisiones se tomaron sobre 24 o 48. Para el balance fino de la experta conviene un torneo más largo (más semillas y terrenos).

## Pruebas
- **Determinismo** ([resultado](pruebas/4f-test_determinism.txt)): OK, hash **1249639671**, el mismo de antes. La normal ataca el hito en obra, pero en los 5 minutos de la prueba no llega a pasar.
- **Rendimiento** (`tests/bench.gd`, [resultado](pruebas/4f-bench.txt)): 8,68 ms de promedio y 59 de peor caso con 200 unidades.
- **Civs** ([`civ_smoke`](pruebas/4f-civ_smoke.txt)): las 3 partidas sin errores de script (el único "ERROR" es el de recursos al salir, de siempre). Además, las ~350 partidas de este paso corrieron sin errores de script.

## Tropiezos
- **La carga de la máquina** (torneos ajenos, 5 a 19) hizo que cada partida de 30 minutos tardara 7–10 minutos: 24 partidas, una hora con 3 procesos. Por eso el cribado se hizo con 12 partidas.
- **Cribar con la semilla fácil.** El primer cribado (A, B, C) fue con la semilla 41, donde la experta ya ganaba 11 de 12. No servía: hubo que repetirlo con la 42.
- **`reglas.json` se lee en cada partida.** Cambiar los datos con una medida corriendo cambia las partidas que faltan. De ahí `--ajuste` en la herramienta. (Los cambios de código no: cada proceso ya cargó el script).
- **Ataque-movimiento eterno.** El ejército de la experta estaba siempre en orden 2 (`ATTACK_MOVE`) y parecía que "iba" a algún lado; las posiciones mostraron que daba vueltas en su base detrás de un explorador.
- **Python con tabs.** Dos reemplazos fallaron por la sangría (dos tabs, no uno) y uno por editar los datos en el mismo script: se separaron.

## Riesgos
- **La normal cambia** (pedido 3 del orquestador): ataca el hito en obra y defiende el suyo, y deja de reconstruir almacenes donde los pierde. El hash de la prueba no cambia, pero las partidas largas sí: el torneo de balance (`tests/torneo.gd`) lo corre el orquestador. Para volver a la normal de antes: `ataca_hito_en_obra: false` en `dificultades.normal` (los almacenes no tienen llave por dificultad).
- **Conflictos con `src/sim/sim_ai.gd`:** se tocan `_buildings` (almacenes perdidos), `_threat` (hito propio en obra) y `_military` (defensa proporcional, sitios, hito en obra), y se suman `_track_stores`, `_store_lost_near`, `_defend_some`, `_retake_site` y `_hit_hito`. En `reglas.json`, las líneas de `ia_economia`, `ia_hito_en_obra` (nueva, antes de `ia_caza`) y las de `normal`, `dificil` y `experta`.
