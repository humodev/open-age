# 24 · Paso 4a: IA experta

## Pedido
De la [síntesis de la segunda ronda](../22-testers/ronda-2/00-sintesis.md), el veterano de AoE4:
> "IA experta que llegue a 80–100 aldeanos."

Es el primer ítem del paso 4 del [plan de la etapa](README.md). Del orquestador: que llegue a 80–100 aldeanos con su tope de población, que levante un segundo centro (y un tercero si hay lugar) para expandirse como en AoE4, que no corte la producción de aldeanos ni de ejército mientras ahorra, que ataque con oleadas más grandes, que se elija en el menú y con `--dificultad=experta`, y que **no cambie cómo juegan las dificultades de antes** (normal es la del torneo de balance).

Después se sumó un pedido del paso 4b: con "Hitos: no", la IA no terminaba la conquista (4 partidas de 45 minutos; al mapuche le quedaban 41 edificios). Hay que hacer que **todas las dificultades** cacen los últimos edificios que cuentan para la victoria cuando el rival ya no tiene ejército, sin cambiar cómo juegan con hitos.

## Diseño

**Todo en datos** (`reglas.json` → `dificultades.experta`). El código lee claves que las otras dificultades no tienen, así que siguen igual.

| Clave | Experta | Qué hace |
|---|---|---|
| `piensa_cada_ticks` | 5 | Como la difícil |
| `max_aldeanos` | 100 | Normal: 42; difícil: 60 |
| `ataque_base` / `ataque_paso` / `ataque_espera_ticks` | 16 / 6 / 600 | Oleadas más grandes y menos seguidas (normal: 7 / 4 / 500) |
| `aldeanos_en_todos_los_centros` | sí | Entrena aldeanos sin parar desde todos sus centros, también ahorrando |
| `ejercito_minimo_ahorrando` | 0, 20, 30, 40 | Mínimo de tropa por edad mientras ahorra para el hito (las demás: 0, 10, 16, 20 de `ia_economia`) |
| `proporcion_temprana` / `proporcion_tardia` | 58/32/7/3 y 42/32/17/9 | Más alimento y madera (alimento/madera/riqueza/piedra): son los centros y las casas. Sin centros que entrenen aldeanos (Palmares), el reparto de siempre |
| `productores_max` | 7 | Cuarteles cuando sobra (las demás: 5) |
| `casas_a_la_vez` / `casas_margen_por_centro` | 2 / 3 | Solo con más de un centro: se produce más rápido |
| `expansion.centros_max` | 3 | Capital incluida |
| `expansion.aldeanos` | 26, 50 | Aldeanos para el 2.º y el 3.º centro |
| `expansion.recursos` | riqueza, piedra, madera | En ese orden de preferencia |
| `expansion.distancia_min` / `distancia_max` | 13 / 30 casillas | Desde la capital |
| `expansion.separacion` | 14 casillas | De los otros centros propios |
| `expansion.lado_pct` | 130 | El recurso tiene que estar 1,3 veces más lejos de toda base rival que de la propia |
| `expansion.radio_lugar` / `candidatos` / `cada_ticks` / `constructores` | 6 / 4 / 100 / 4 | Búsqueda del lugar y obra |
| `expansion.refuerzo_pct` | 15 | Más gente en lo que falta para pagar el centro |
| `expansion.junta_desde_pct` | 0 | Desde cuándo se junta para el centro y se deja de gastar en lo demás |

**Cómo se expande** (`SimAI._expand`, `_expansion_site`, `_expansion_need`):
- El "centro" de cada civ es el `centro` si lo construye; si no, el edificio más barato que entrena aldeanos. Los mapuches se expanden con lofs, que ya son su centro (D-023). Palmares no entrena aldeanos (los suma con la fama), así que no se expande con centros: solo gana lo demás.
- Lugar: junto al recurso más cercano de la lista, de este lado del mapa y lejos de los otros centros, como en AoE4 (centro sobre el oro, la piedra o el bosque).
- Mientras le falte para el centro, junta: la tropa sale de lo que sobra por encima de su costo, salvo que esté por debajo del mínimo de la edad (no se corta), y los edificios que no son casas ni el hito esperan, como ya se hacía con el mercado. Ahorrando para el hito, el centro no toca lo que pide el hito.
- Los aldeanos trabajan alrededor del centro más cercano (`_home`): buscan recursos y ponen granjas ahí.

**Cacería sin hitos** (`SimAI._hunt`, `reglas.ia_caza`, todas las dificultades):
- Solo con la opción `hitos_sin_victoria`. Con hitos no se llama: los hashes de una partida con hitos son iguales a los de `main` (ver Pruebas).
- Cuando el rival elegido tiene 3 unidades militares o menos (`ejercito_rival_max`), o se le saca el doble (`ventaja_pct`: 200), el ejército libre (ocioso o caminando, no el que ya va a un blanco) se reparte en grupos de 8 (`grupo`). Cada grupo va a un edificio que cuenta para la victoria, del más cercano al más lejano, cada 15 s (`cada_ticks`).
- Mientras caza, nadie vuelve al punto de reunión.

**Menú y línea de comandos:**
- El menú arma la lista de dificultades con las claves de `reglas.json` → `dificultades`, en su orden, en lugar de la lista fija de tres. Aparece "Experta" en el 1 contra 1 y en cada IA de los lugares.
- `--dificultad=experta` ya andaba (la IA lee la clave). Ahora, en el menú, `--dificultad` también la preelige (para las capturas; no se guarda en las opciones).

**Herramientas nuevas:**
- `tools/ia_experta.gd`: partidas en espejo de una dificultad contra otra, con aldeanos, centros, edad y ejército cada 5 minutos, quién gana y el tick por tramo (`--rival`, `--dificultad`, `--civs`, `--terreno`, `--minutes`, `--banco` para ver banco y edificios).
- `tools/sin_hitos_ia.gd`: las 8 partidas del paso 4b (con y sin hitos, con y sin victoria por sitios), con los edificios que cuentan para la victoria al final.

## Paso a paso
1. **Datos y código base.** Experta con 100 aldeanos, centros nuevos y aldeanos desde todos los centros. Primera partida (guaraníes contra normal): 1 solo centro en 25 minutos y pierde a los 24:05. Le faltaba madera y piedra para el centro (400 y 300).
2. **Más gente en lo que falta.** `refuerzo_pct` para el costo del centro. Etiopía levanta el 2.º centro a los 15 minutos y llega a 63 aldeanos a los 20; Tawantinsuyu se queda sin alimento (0 a 20 en el banco) y en 29 aldeanos.
3. **Reparto propio de la experta.** Más alimento: los centros comen 50 por aldeano cada 18 s. Tawantinsuyu y Etiopía mejoran.
4. **Palmares atascado.** A los 5 minutos tenía 13 de población y la campana tocada: un rush de honderos de la normal y la mitad de los aldeanos adentro. Las dos casas a la vez se comían la madera del cuartel. Las casas extra quedan solo con más de un centro.
5. **Juntar para el centro.** Ayutthaya y Tawantinsuyu tenían 500–700 de piedra y nunca 400 de madera: granjas, cuarteles y almacenes se la llevaban antes. Ahora se junta (como con el mercado). Con la primera versión, que juntaba solo con la mitad de cada cosa, no alcanzaba nunca; con `junta_desde_pct: 0`, Tawantinsuyu llega a 3 centros. Pero perdía tropa: el mínimo de la edad ya no se corta.
6. **Palmares con el reparto de siempre.** Sin centros que entrenen aldeanos, el reparto con más alimento no le sirve: contra la difícil quedaba en 17 aldeanos a los 10 minutos.
7. **Cacería sin hitos** (pedido del orquestador). Con solo "rival sin ejército", Etiopía–Palmares termina por conquista (24:53), pero Tawantinsuyu–Mapuches sigue abierta a los 45 (le quedan 25 edificios): la guerra es pareja hasta el minuto 40 y la caza empieza recién en el 41. Se suma la ventaja del doble (`ventaja_pct`).
8. **Rendimiento.** La IA experta costaba 8,6 ms por tick con dos expertas a los 25 minutos. Lo caro era `_far_gatherers`: un `Sim.nearest_dropoff` por aldeano, que recorre todas las entidades (100 aldeanos × ~700 entidades por pensada). Ahora junta los depósitos una vez, con el mismo filtro, orden y desempate: 3,9 ms, con la misma partida y el mismo hash.

## Medidas

Todas en llano, semilla 41, 25 minutos, cada civ contra sí misma. Aldeanos a los 10/15/20/25 minutos; "centros" son los edificios terminados que entrenan aldeanos (los lofs mapuches cuentan; Palmares no tiene).

**[Experta contra normal](pruebas/4a-experta-contra-normal.txt):**

| Civ | Aldeanos experta | Aldeanos normal | Centros experta (25') | Edad a los 25' (E/N) | Gana |
|---|---|---|---|---|---|
| Tawantinsuyu | 40 / 53 / 96 / **100** | 29 / 42 / 44 / 29 | 3 (2.º a los 15') | III / II | nadie (la normal sin centro ni ejército) |
| Mapuches | 51 / 71 / 88 / **100** | 33 / 43 / 45 / 43 | 3 lofs | III / III | nadie |
| Guaraníes | 37 / 44 / 68 / 43 | 37 / 42 / 42 / 42 | 2 (15') | III / IV | nadie |
| Etiopía | 27 / 39 / 69 / **100** | 33 / 42 / 40 / 24 | 3 | III / III | nadie (la normal sin centro ni ejército) |
| Palmares | 19 / 31 / 47 / 57 | 20 / 33 / 48 / 65 | — | II / III | nadie |
| Ayutthaya | 29 / 36 / 50 / 72 | 29 / 42 / 42 / 42 | 2 (25') | III / III | nadie |

**[Experta contra difícil](pruebas/4a-experta-contra-dificil.txt):**

| Civ | Aldeanos experta | Aldeanos difícil | Centros experta | Edad (E/D) | Gana |
|---|---|---|---|---|---|
| Tawantinsuyu | 43 / 59 / — / — | 33 / 49 / — / — | 2 (15') | II / II | **difícil (19:47)** |
| Mapuches | 55 / 71 / 84 / **100** | 35 / 46 / 47 / 46 | 3 lofs | III / II | nadie (la difícil con 3 de ejército) |
| Guaraníes | 37 / 41 / 69 / 56 | 37 / 52 / 60 / 60 | 2 (15') | III / IV | nadie |
| Etiopía | 28 / 42 / 74 / **83** | 31 / 44 / 58 / 55 | 2 (15') | III / III | nadie |
| Palmares | 17 / 30 / 41 / — | 20 / 33 / 45 / — | — | II / II | **experta (20:13)** |
| Ayutthaya | 29 / 34 / 54 / — | 29 / 44 / 57 / — | 2 (20') | III / III | **difícil (21:46)** |

Lo que muestran:
- **Llega a 100 aldeanos a los 25 minutos** en Tawantinsuyu, mapuches y Etiopía. Ayutthaya llega a 72 y Palmares a 57 (sin centros). Contra la normal, a los 25 minutos la normal tiene 24–45.
- **Se expande** en las cinco civs con centro: 2.º centro entre los 15 y los 20 minutos (Ayutthaya, a los 25) y 3.º en Tawantinsuyu y Etiopía. Los mapuches ya tienen 3 lofs, como las otras dificultades.
- **No es todavía más fuerte que la difícil.** Pierde 2 de 6 (Tawantinsuyu y Ayutthaya, entre los 19 y los 22 minutos), gana 1 y en el resto nadie termina. La economía grande llega tarde: a los 10–15 minutos tiene el mismo ejército o menos, y la edad III le llega más tarde que a la normal en varias civs (guaraníes, Etiopía) porque los aldeanos de tres centros se comen el alimento del hito.
- **Guaraníes**: pasa de 68–69 aldeanos a 43–56 entre los 20 y los 25 minutos. El rival le mata aldeanos con 16–29 de ejército propio. Es la civ que menos ejército hace en la experta.
- Una sola semilla: sirve para ver la forma, no para el balance.

**[Cacería sin hitos](pruebas/4a-sin-hitos-caza.txt)** (las 8 partidas del paso 4b: 45 minutos, llano, semilla 321, IA normal):

| Partida | Hitos | Antes (4b) | Ahora |
|---|---|---|---|
| Tawantinsuyu–Mapuches, solo conquista | no | 45:00 sin ganador, al mapuche le quedan 41 | **conquista a los 40:30** (gana Tawantinsuyu) |
| Etiopía–Palmares, solo conquista | no | 45:00 sin ganador, a Palmares le quedan 58 | **conquista a los 25:04** (gana Etiopía) |
| Tawantinsuyu–Mapuches, con sitios | no | sitios a los 29:29 | sitios a los 24:31 |
| Etiopía–Palmares, con sitios | no | sitios a los 28:37 | sitios a los 22:31 |
| Las cuatro con hitos | sí | — | iguales a `main` (misma partida: la cacería no se llama) |

- Las dos partidas de solo conquista sin hitos ahora terminan. Con solo "rival sin ejército" (sin la ventaja del doble), Tawantinsuyu–Mapuches seguía abierta a los 45 minutos con 25 edificios.
- Con hitos, las partidas no cambian. Etiopía–Palmares con hitos sigue abierta a los 45 minutos (al etíope le queda 1 edificio que cuenta y a Palmares, 7). Eso no es de este paso: con hitos la IA ataca solo capital e hitos, como antes.

**Tick** ([perfil](pruebas/4a-tick-ia-perfil.txt), [dos expertas](pruebas/4a-tick-mapuches-expertas-carga-baja.txt), [dos normales](pruebas/4a-tick-mapuches-normales-carga-baja.txt)): mapuches en espejo, el único espejo de expertas que llegó a los 25 minutos. La máquina tenía carga de 10–12 por torneos ajenos.

| Tramo | Dos normales | Dos expertas (antes) | Dos expertas (ahora) |
|---|---|---|---|
| 10–15' | 8,4 ms (IA 1,4) | 16,7 ms (IA 5,1) | 13,9 ms (IA 2,3) |
| 15–20' | 10,9 ms (IA 1,6) | 25,3 ms (IA 7,7) | 21,1 ms (IA 3,3) |
| 20–25' | 11,8 ms (IA 1,7), peor 47 | 29,7 ms (IA 8,6), peor 126 | 25,6 ms (IA 3,9), peor 124 |

- El promedio entra en el presupuesto de 100 ms. Con ~190 unidades por lado, la mayor parte es el movimiento y el combate, no la IA.
- El peor tick (124 ms, con la carga) pasa los 100 ms. A ×4 de velocidad, el promedio de 25,6 ms tampoco entra. Ver riesgos.

## Pruebas
- **Determinismo** ([resultado](pruebas/4a-test_determinism.txt)): OK, hash 1249639671, igual al de antes del paso (la normal juega igual). Con hitos, la partida Etiopía–Palmares de 45 minutos da los mismos hashes cada 5 minutos en `main` y en esta rama.
- **Rendimiento** (`tests/bench.gd`, [resultado](pruebas/4a-bench.txt)): 9,86 ms de promedio y 75 de peor caso con 200 unidades (carga de 7–15).
- **Civs** ([`civ_smoke`](pruebas/4a-civ_smoke.txt)): sin errores. Además, las 12 partidas de la experta y las 8 sin hitos corrieron sin errores de script.
- **Autotest** (`--autotest --civ=guaranies --terreno=llano`, [resultado](pruebas/4a-autotest.txt)): 61 OK, AUTOTEST: OK. El código 134 al salir es el "double free" de siempre.
- **Capturas:** [menú 1 contra 1 con "Experta"](capturas/4a-menu-experta.png) y [2 contra 2 con "Experta" en cada IA](capturas/4a-menu-2v2-experta.png).

## Tropiezos
- **La experta perdía contra la normal al principio.** La primera versión hacía más aldeanos, pero se quedaba sin alimento y sin madera: el centro, las casas dobles y el ejército mínimo de la edad I competían con el cuartel. Cada arreglo se midió solo y alguno empeoró otra civ (el reparto con más alimento hundía a Palmares).
- **La espera del centro mataba al ejército.** Juntar 400 de madera sin cortar nada dejaba a Tawantinsuyu con la mitad de tropa y perdía a los 18:36 contra la normal. Por eso el mínimo de la edad no se corta.
- **`.godot` viejo después de traer `main`:** el menú no abría (`Animales` sin declarar). Hubo que reimportar (`godot --headless --path . --import`). Las pruebas sin ventana no lo notaban.
- **Las medidas del 4b cambian con `main`.** La partida Etiopía–Palmares con hitos daba [76, 53] edificios en `4b-sin-hitos-ia.txt` y da [21, 59] ahora, con los mismos hashes en `main` y en esta rama. La medida del 4b se tomó con otra versión de su código, no con la que quedó en `main`; no es de este paso. Las de Tawantinsuyu–Mapuches con hitos cambian además por el kawiñ mapuche que entró a `main` (3b): 26:13 en lugar de 26:38.
- **Carga de la máquina.** Con los torneos ajenos, la carga fue de 7 a 27. Los tiempos del tick se comparan solo dentro de una misma corrida o en corridas paralelas.

## Riesgos
- **Rendimiento:** dos expertas a los 25 minutos son unas 380 unidades. El tick sube a 25 ms de promedio y el peor pasa los 100 ms con carga. La IA ya es la parte chica (4 ms); lo que queda es el costo por unidad (caminos, separación, combate). Para ×4 de velocidad o para partidas de 4 expertas habría que mirar el perfil del tick (`tools/perfil_tick.gd`) con esa carga.
- **Fuerza:** la experta llega a 100 aldeanos, pero no le gana a la difícil (2 derrotas de 6). Para que sea "experta" de verdad falta convertir la economía en ejército antes de los 15 minutos. Se mide con el torneo.
- **Conflictos con `src/sim/sim_ai.gd`:** se tocan `think` (lista de centros), `_economy` (reparto, `_home`), `_buildings` (casas, expansión, espera), `_production` (aldeanos de todos los centros, mínimo de tropa, espera), `_far_gatherers` (depósitos una vez) y `_military` (cacería). Quien toque esas funciones en paralelo va a chocar.

## Consultas propuestas
1. **¿Qué tiene que ganarle la experta a la difícil?** Hoy llega a 100 aldeanos y 3 centros, pero pierde 2 de 6 contra la difícil. Opciones: (a) dejarla así, que el jugador la sienta grande y lenta; (b) otro paso de ajuste con torneo (`tests/torneo.gd`) contra la difícil, con más tropa temprana y la edad III antes; (c) sumar la experta al torneo de balance. La normal sigue siendo la del torneo.
2. **¿La experta cuenta para el balance?** Con tres centros, las civs con centro (todas menos Palmares) se benefician más que Palmares, que crece con la fama. Si la experta se usa para medir civs, Palmares va a quedar abajo por diseño.
