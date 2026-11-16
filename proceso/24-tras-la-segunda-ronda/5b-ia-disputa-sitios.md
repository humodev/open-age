# 24 · Paso 5b: la IA disputa los sitios sagrados

## Pedido
Del veterano de AoE4 ([ronda 3](../22-testers/ronda-3/01-veterano-aoe4.md), pedido 5): la experta le ganó por sitios a las 20:11 con 94 militares suyos vivos; "que la IA dispute los sitios con el ejército y los vaya a buscar si yo los tengo". El orquestador lo pidió para normal, difícil y experta (la fácil no toma sitios):
1. Si el rival tiene 2 o 3 sitios, o corre su cuenta de victoria, mandar fuerza proporcional a recuperar el más cercano o el menos defendido, y defender los propios cuando se acercan enemigos. Con la cuenta corriendo, eso va antes que las incursiones.
2. Sin suicidarse en goteo: un grupo mínimo, y retirada si pierde la pelea.
3. Medir antes y después, IA contra IA (normal contra normal y experta contra difícil): cuántas veces la cuenta llega a cero, cuántas se corta y cuántas partidas terminan por sitios.

## Cómo se mide
**`tools/disputa_sitios.gd`** (nueva): partidas en espejo (cada civ contra sí misma) con tiempo límite de 30 minutos. `--modo=normal` es normal contra normal; `--modo=experta`, experta contra difícil (la experta cambia de lado con la semilla). Por partida da, para cada jugador, cuántas veces **arranca** su cuenta de sitios, cuántas **se corta** (el rival recupera un sitio) y cuántas **llega a cero** (gana por sitios), el máximo que llegó a correr, cuántos sitios le **quitó** al rival y, si alguien pierde por sitios, con cuántos militares vivos. `--apagado` borra `disputa_sitios` de todas las dificultades: para normal y difícil es exactamente el código de antes; para la experta no, porque su `sitios_disputa` viejo ya no existe (para ella el "antes" se midió con el código de antes).

Medida: 6 civs × semillas 41 y 42 en llano (12 partidas por modo), con el código de antes y con el nuevo. Normal contra normal, además, semillas 43 y 44 con `--apagado` y sin él (otras 12 + 12).

## Paso a paso
1. Herramienta primero, medida "antes" con el código sin tocar ([normal](pruebas/5b-antes-normal.txt), [experta](pruebas/5b-antes-experta.txt)). Lo que se ve: en normal contra normal casi todas las cuentas se cortan, pero las que llegan a cero ganan contra un rival que no hace nada (Etiopía s41: pierde por sitios **con 19 militares vivos**). Con la experta: la difícil le gana por sitios a Tawantinsuyu (s42) y a Palmares (s41), y la experta gana por sitios a una difícil guaraní **con 47 militares vivos**: la difícil manda grupitos de 4 que mueren de a uno.
2. **`_contest_sites`** (`src/sim/sim_ai.gd`), en lugar de `_retake_site` de la experta. Cada `cada_ticks` (5 s):
   - **Defensa**: si hay militares enemigos a 12 casillas o menos de un sitio propio, va un grupo con 1,5 veces su vida (descontando a los propios que ya están ahí), los más cercanos primero.
   - **Recuperar**: si un rival tiene 2 sitios o más, o corre su cuenta, elige el sitio rival más barato: distancia en casillas + vida enemiga a 10 casillas del sitio / 100. Va un grupo con 1,5 veces esa vida (2 veces con la cuenta corriendo) y al menos 6 unidades. Si no le alcanza, no va.
   - **Con la cuenta rival corriendo**: si no le alcanza para ningún sitio, el ejército se junta en el punto de reunión (ni oleadas, ni hito, ni incursiones) hasta que alcance; con 2:30 o menos en la cuenta va con todo. La defensa de la base también pasa a ser proporcional (como la de la experta), así una incursión chica no retiene a todo el ejército.
   - El grupo queda anotado (`_squad`): nada más le da órdenes, y con la cuenta corriendo recibe refuerzos en bloques de 3 o más. Se disuelve cuando el sitio es propio y no quedan enemigos, o a los 3 minutos.
   - **Retirada**: si la vida del grupo queda por debajo del 80 % de la enemiga (en el sitio o alrededor del grupo), vuelve suelto al punto de reunión y ese sitio espera un minuto (salvo en los últimos 2:30).
   - El grupo chico de siempre (4, u 8 la experta) que toma sitios libres ya no va a un sitio con enemigos: eso lo decide la disputa.
3. **Primer tropiezo** (traza de Tawantinsuyu s41, normal contra normal): los grupos se desangraban sin retirarse (uno de 6 bajó de 400 a 65 de vida entre las 12:54 y las 13:39). La pelea era en el camino, a más de 10 casillas del sitio, y la retirada solo miraba los enemigos del sitio. Ahora mira también los de alrededor del grupo: en la misma partida, ese grupo se retira a las 13:21. La partida, que con el código de antes se perdía por sitios a las 24:58, termina por puntos, y el estado de los sitios cambia 17 veces.
4. Medida "después" ([normal](pruebas/5b-despues-normal.txt), [experta](pruebas/5b-despues-experta.txt), [normal s43–44 apagado](pruebas/5b-apagado-normal-s43-44.txt) y [encendido](pruebas/5b-despues-normal-s43-44.txt)).

## Resultados

Cuentas de sitios (sumando los dos jugadores de cada partida):

| Medida | Partidas | Arrancan | Se cortan | Llegan a cero (fin por sitios) | Sitios quitados al rival | Militares vivos del que pierde por sitios |
|---|---|---|---|---|---|---|
| Normal contra normal, antes (s41–42) | 12 | 37 | 27 | 2 | 94 | 0 y **19** |
| Normal contra normal, después (s41–42) | 12 | 53 | 46 | 2 | 185 | 0 y 3 |
| Normal contra normal, apagado (s43–44) | 12 | 44 | 35 | 0 | 115 | — |
| Normal contra normal, después (s43–44) | 12 | 59 | 50 | 0 | 182 | — |
| **Normal, total antes / después** | 24 / 24 | 81 / 112 | **62 (77 %) / 96 (86 %)** | 2 / 2 | **209 / 367** | 0 y 19 / 0 y 3 |
| Experta contra difícil, antes | 12 | 28 | 21 | 4 (experta 2, difícil 2) | 95 | 1, 0, 0 y **47** |
| Experta contra difícil, después | 12 | 50 | 41 | 1 (experta) | 150 | 1 |

- **Los sitios se disputan**: los sitios que cambian de un jugador a otro casi se duplican (209 → 367 en 24 partidas normales; 95 → 150 con la experta) y se cortan más cuentas (77 % → 86 % en normal; 75 % → 82 % con la experta).
- **Nadie pierde por sitios con el ejército en casa.** Antes se perdía por sitios con 19 y con 47 militares vivos; después, todas las derrotas por sitios son de un jugador que ya no tenía ejército (0, 1 y 3 militares): ganar por sitios queda para quien ganó la pelea, que es lo que pedía el veterano.
- **La difícil ya no le gana por sitios a la experta** (antes 2 de 12; después 0).
- Las partidas terminan más por puntos: normal 19 → 20 de 24, experta 7 → 9 de 12. Con todos disputando, la cuenta casi nunca llega a cero.
- Cuentas que pasaron de 5 minutos (por jugador): normal 14 → 11 de 48; experta 9 → 10 de 24. La cuenta arranca igual de seguido (más, porque los sitios cambian más de mano), pero dura menos.

**Experta contra difícil**: la experta gana 9 de 12 antes y **7 de 12 después** (por puntos casi siempre). Está dentro del ruido de 12 partidas (±2), pero la dirección es la esperable: la difícil ahora también recupera sitios y la experta pierde una ventaja que solo tenía ella (`sitios_disputa`, paso 4f). Si el torneo lo confirma, la palanca está en `dificultades.experta.disputa_sitios`, que acepta un diccionario con claves propias (por ejemplo `{ "fuerza_pct": 120 }` para que vaya antes).

En normal contra normal, "gana A" no mide fuerza (las dos son la misma IA en espejo): cambia de 2 a 8 de 12 en las semillas 43–44 por el lado del mapa, no por la disputa.

## Qué cambió
- **`src/sim/sim_ai.gd`**: `_contest_sites` (decisión), `_squad_step` (cuidar, retirar o disolver el grupo), `_contest_cfg`, `_site_clock` (cuánto le falta a la cuenta rival), `_site_need`, `_foes_hp`/`_foes_hp_at`, `_own_hp_near`, `_pick_for`, `_without`, `_squad_go`, `_hp_of`, `_hp_of_units`, `_regroup` (el reagrupado del final de `_military`, ahora función). Se quita `_retake_site` (y `last_retake`). `_defend_some` recibe la configuración por parámetro. En `_military`: el grupo de un sitio queda fuera del resto de las órdenes, la defensa es proporcional con la cuenta rival corriendo, y la disputa va antes que el hito en obra, las oleadas y las incursiones. El grupo chico que toma sitios no va a uno con enemigos.
- **`data/reglas.json`**: `ia_disputa_sitios` (nueva, antes de `ia_hito_en_obra`) con todos los números; `disputa_sitios: true` en normal, difícil y experta; se borra `sitios_disputa` de la experta.
- **`tools/disputa_sitios.gd`** (nueva) y **`docs/08-ia-rival.md`**.

## Pruebas
- **Determinismo** ([resultado](pruebas/5b-test_determinism.txt)): OK, hash **1328656416**, el mismo que HEAD (4e7677d, medido con el código de antes). En los 5 minutos de la prueba nadie tiene 2 sitios ni enemigos cerca de uno propio, así que la disputa no llega a actuar. Las partidas largas sí cambian.
- **Rendimiento** ([`bench`](pruebas/5b-bench.txt)): 16,97 ms de promedio y 155 de peor caso con 200 unidades (presupuesto 100), con la máquina a carga 25 (torneos ajenos). El banco no usa la IA.
- **Civs** ([`civ_smoke`](pruebas/5b-civ_smoke.txt)): sin errores de script.
- **La fácil no toma sitios** ([`facil_sitios`](pruebas/5b-facil_sitios.txt)): OK, 0 sitios tomados.
- **Equipos** ([`equipos --minutes=10`](pruebas/5b-equipos.txt)): OK, sin fuego amigo.
- **Campañas** ([`campaign_smoke`](pruebas/5b-campaign_smoke.txt)): todas las misiones corren sin errores de script.
- Las 72 partidas de medida corrieron sin errores de script.

## Tropiezos
- **`reglas.json` se lee en cada partida**: la medida "antes" corría mientras escribía el código, así que los datos nuevos se probaron en una copia (`SimData._load` de un archivo aparte) y se pasaron a `reglas.json` recién al terminar la medida.
- **La retirada que no se retiraba** (paso 3): la pelea era en el camino, no en el sitio.
- **La máquina cargada**: cada partida de 30 minutos tardó 5–6 minutos. Por eso 12 partidas por modo, y 12 + 12 más solo para normal contra normal.

## Riesgos
- **La normal cambia** (pedido del orquestador): disputa los sitios, se junta con la cuenta rival corriendo y defiende su base en proporción en ese caso. El hash no cambia, pero las partidas largas sí: el torneo de balance lo corre el orquestador. Para volver a la de antes: `disputa_sitios: false` (o borrar la clave) en `dificultades.normal`.
- **La experta podría quedar más cerca de la difícil** (9 → 7 de 12, dentro del ruido): la difícil ahora también recupera sitios. Medir con `tools/experta_vs_dificil.gd` en 48 partidas antes de tocar nada.
- **Juntarse con la cuenta corriendo** frena las oleadas: si el rival defiende sus sitios con mucho, la IA espera hasta tener el doble o hasta los últimos 2:30. Contra una persona que defiende bien los sitios puede quedar pasiva unos minutos.
- **Conflictos con `src/sim/sim_ai.gd`**: se toca `_military` (el principio y el lugar de `_retake_site`; el reagrupado del final pasa a `_regroup`), el bloque del grupo chico que toma sitios, `_defend_some` (firma nueva) y las variables del principio (`last_retake` sale; entran `last_contest`, `_squad`, `_site_cool`, `_contest_held`). En `reglas.json`, la línea nueva antes de `ia_hito_en_obra` y las de `normal`, `dificil` y `experta`.
