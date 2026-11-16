# 5d · Elección de blancos como AoE4

Pedido: la causa de fondo que dejó [4q](4q-primera-victoria.md) en «Para el autor». En ataque en movimiento, una unidad que elegía un edificio no lo soltaba aunque la mataran, y los tramos de camino inca eran blanco como cualquier edificio. Vale para todas las dificultades y para el jugador:

1. La unidad que le pega a un edificio en ataque en movimiento (o por su cuenta) cambia a la unidad enemiga que le pega o que está cerca, antes de seguir con el edificio. El asedio (`solo_edificios`) sigue con los edificios. Con orden directa sobre un edificio, se respeta.
2. Los tramos de camino (y otras piezas transitables sin valor militar) no se eligen solos; con orden directa sí.
3. Medir antes y después.

## Qué cambió

**Prioridad al elegir** (`Sim.find_enemy` para unidades, `Sim.target_class`): militar > aldeano > edificio que dispara **y la tiene a su alcance** (torre, centro) > otro edificio > pieza transitable (granja, andén, gult, corral). Dentro de cada clase, el más cercano. Antes era la distancia con un recargo fijo (+3 casillas el aldeano, +6 el edificio): un almacén a 1 casilla le ganaba a un hondero a 8.

**El militar que le pega.** `_hit`: si la unidad pelea por su cuenta contra un aldeano o un edificio y la golpea un militar, se da vuelta contra ese militar en el mismo golpe. Ya lo hacía la inactiva.

**Rebusca.** La unidad que pelea por su cuenta contra un aldeano o un edificio mira cada `reglas.blancos.rebusca_cada_ticks` (3, como el ataque en movimiento) si tiene algo más importante en su visión. Contra militares no rebusca: así las peleas entre tropas y el bench quedan como estaban.

**Orden directa contra elegido por su cuenta.** `SimEntity.auto_tgt`: queda en verdadero cuando el blanco sale del ataque en movimiento, de la patrulla, de la inactiva que ve a alguien o de la respuesta a un golpe. Con clic derecho (`target`) queda en falso y la unidad no cambia de blanco. La IA usa la orden directa solo contra el hito en obra (`_hit_hito`), que sigue igual.

**Caminos.** Clave de datos nueva `sin_blanco_automatico` en el `camino` del Tawantinsuyu: `find_enemy` no lo elige nunca; `target` (orden directa) sí. Las granjas, los andenes, los gult y los corrales **no** quedan afuera: van al final de la lista (ver «Tropiezos» y «Para el autor»).

**Edificios que disparan.** La torre o el centro cuentan como «que dispara» solo si la unidad está dentro de su alcance. Un centro lejano no atrae a la tropa.

Los números están en `data/reglas.json → blancos` (con su `_doc`). `docs/05-mecanicas-nucleo.md` («Comportamiento») tiene la regla nueva.

## Medidas

### La primera victoria (tools/primera_victoria.gd, fácil, 5 semillas, 30 min)

Le agregué a la herramienta dos renglones: las unidades de la IA que mató el jugador y **a qué le pegaba su tropa** (sin el asedio). [Antes](pruebas/5d-primera-victoria-antes.txt) · [después](pruebas/5d-primera-victoria-despues.txt).

| | Antes | Después |
|---|---|---|
| Ganadas | 4 de 5 (19:26, 25:08, 18:20, 26:29) | 4 de 5 (19:56, 25:50, 19:23, **19:47**) |
| Tiempo medio de las ganadas | 22:21 | 21:14 |
| Golpes de la tropa a militares | 1327 (34 %) | 1313 (50 %) |
| … a aldeanos | 146 (4 %) | 234 (9 %) |
| … a edificios | 2106 (53 %) | 1078 (41 %) |
| … a granjas | 378 (10 %) | **0** |
| Militares de la IA muertos | 163 | 143 |
| Aldeanos de la IA muertos | 28 | 42 |
| Tropa perdida (la medida de 4q) | 83 | 101 |

- La semilla 42 gana 7 minutos antes (26:29 → 19:47). La tropa deja de pegarle a las granjas y se dedica a los defensores y a los aldeanos.
- En la semilla 7, la que se pierde, el primer ataque le pega **solo** a unidades (270 golpes a militares y 42 a aldeanos, ninguno a edificios). Antes eran 414 a militares y 311 a un almacén. Igual pierde: la fácil tiene 22–26 honderos en casa y el principiante llega con 22.
- La tropa perdida sube algo (83 → 101), sobre todo en las semillas 11 y 7. Ahora pelean contra los honderos en vez de pegarle a los edificios de la orilla, y eso lleva la pelea más adentro de la base. La rendición llega igual: las granjas cuentan como edificio perdido y los arietes las siguen tirando cuando no hay otra cosa.
- **Esto no hace ganable a la fácil por sí solo.** Lo que la hizo ganable fue 4q. Esto saca la trampa de «A y clic» (pegarle a lo que no importa mientras te matan) en todas las dificultades.

### IA contra IA (tools/blancos.gd, nuevo)

La herramienta cuenta los golpes de las unidades militares (sin el asedio) según el blanco, y las bajas militares que murieron pegándole a un edificio. Normal contra normal, guaraníes y mapuches contra el Tawantinsuyu y etíopes contra Ayutthaya, 2 semillas, 30 min. [Antes](pruebas/5d-ia-contra-ia-antes.txt) · [después](pruebas/5d-ia-contra-ia-despues.txt).

| | Antes | Después |
|---|---|---|
| Golpes a tramos de camino | 933 (2 %) | **0** |
| Bajas militares que murieron pegándole a un edificio | 429 de 1915 (**22 %**) | 194 de 1315 (**15 %**) |
| Partidas con ganador antes de los 30 min | 2 de 6 | **5 de 6** |

- Cambian los resultados. Antes ganaba el Tawantinsuyu las dos que terminaban. Ahora pierde con los mapuches las dos (19:29 y 27:45) y con los guaraníes una (29:39), y les gana a los guaraníes la otra (16:03). Los etíopes le ganan a Ayutthaya una (25:42). **Los caminos le servían al Tawantinsuyu de escudo:** la tropa rival les pegaba 933 golpes. El torneo tiene que mirar al Tawantinsuyu.
- Con menos tiempo perdido contra caminos, edificios de la orilla y granjas, los ataques terminan las partidas.

### Micro (que C2 siga pagando)

- `tests/micro.gd` ([5d-micro.txt](pruebas/5d-micro.txt)): igual en todo lo que mide. C pasa de 3 a 4 honderos vivos y A, D y E cambian en décimas de segundo o en vida.
- `tools/micro_matriz.gd --variantes=5` ([5d-micro-matriz.txt](pruebas/5d-micro-matriz.txt)). **Las filas de micro dan exactamente lo mismo**: honderos escalonando contra guerreros 4/5 · 5,8 vivos; mezcla con foco 4/5 · 7,2; mezcla con mantener+escalonar 5/5 · 6,0 (antes 6,2); mezcla sin micro 4/5 · 5,6. La micro sigue pagando lo mismo. Los espejos (10 contra 10 del mismo tipo) se mueven dentro del ruido: guerreros 3/5 → 4/5, honderos 2/5 → 3/5.

### Pruebas

| Prueba | Resultado |
|---|---|
| `tests/test_determinism.gd` | OK, **hash 2203695307, el mismo** ([5d-test_determinism.txt](pruebas/5d-test_determinism.txt)). La prueba corre 5 minutos y en ese tiempo nadie pelea (bajas 0), así que la elección de blancos no llega a cambiar el estado. Las partidas más largas sí cambian (IA contra IA, arriba) |
| `tests/bench.gd` | Alternando main y 5d con la misma carga: **8,90 / 8,98 / 8,47 ms antes, 9,10 / 8,62 / 8,94 después** (8,78 contra 8,89 de promedio) ([5d-bench.txt](pruebas/5d-bench.txt)) |
| `tests/ordenes.gd` | OK, con 6 chequeos nuevos de blancos ([5d-ordenes.txt](pruebas/5d-ordenes.txt)). Con el código de main fallan 2: el que suelta la casa y el que pasa de largo los caminos |
| `tests/civ_smoke.gd` | corre sin errores ([5d-civ_smoke.txt](pruebas/5d-civ_smoke.txt)) |
| `tests/equipos.gd -- --minutes=10` | OK, fuego amigo 0 ([5d-equipos.txt](pruebas/5d-equipos.txt)) |
| `tests/facil_sitios.gd` | OK, 0 sitios tomados ([5d-facil_sitios.txt](pruebas/5d-facil_sitios.txt)) |
| `tests/tutorial_letra.gd` | OK, victoria 11:16, como antes ([5d-tutorial_letra.txt](pruebas/5d-tutorial_letra.txt)) |
| `tests/campaign_smoke.gd` | corre: las 25 misiones abiertas a los 3:00, sin errores ([5d-campaign_smoke.txt](pruebas/5d-campaign_smoke.txt)) |

Los chequeos nuevos de `ordenes.gd` son estos. Un lancero en ataque en movimiento le pega a una casa y deja la casa por el hondero que empieza a tirarle. Con orden directa sobre la casa sigue con la casa, y el ariete también. Con una casa al lado, un aldeano más lejos y un hondero todavía más lejos, elige primero al aldeano y después al hondero. El ataque en movimiento pasa de largo seis tramos de camino sin pegarles, y con orden directa les pega.

## Tropiezos

- **Primer intento: todas las piezas transitables afuera, y el centro siempre antes que los demás edificios** ([5d-primera-victoria-intento1-granjas-fuera.txt](pruebas/5d-primera-victoria-intento1-granjas-fuera.txt)). La primera victoria bajó de 4 de 5 a **2 de 5**. Sin granjas para tirar, la rendición de la fácil (6 edificios perdidos) no llegaba. Además, los arietes y la tropa sin unidades a la vista se iban contra el centro (2400 de vida, con guarnición), que estaba lejos, y morían bajo sus flechas: en la semilla 21, el centro mató a 22. Lo corregí así: las piezas transitables van **al final** (no afuera), solo el camino queda afuera (`sin_blanco_automatico`) y el edificio que dispara cuenta como tal **solo si la unidad está a su alcance**.
- **Segundo intento: entre militares, primero el que me tiene de blanco.** Era la lectura literal de «militares que la atacan > militares cerca». Costaba ~0,9 ms en el bench (9,68 contra 8,77), porque las unidades cruzaban la línea para perseguir al que les tiraba desde atrás. Además cambiaba las peleas entre tropas: la mezcla sin micro contra guerreros bajaba de 4/5 a 2/5. Quedó como reacción al golpe (`_hit`) cuando la unidad estaba con un aldeano o un edificio, que es el caso del pedido. Contra militares, el más cercano, como antes.
- `data.reglas["blancos"]["rebusca_cada_ticks"]` se leía por cada unidad que ataca en cada paso. Ahora se lee una vez al crear la simulación (`_retarget_every`).

## Para el autor

- **¿Las granjas deberían quedar afuera del todo?** El pedido decía «piezas transitables sin valor militar». Las dejé al final de la lista y no afuera, por dos razones: tirarlas es parte de cómo se gana (la rendición de la fácil las cuenta) y son blanco legítimo de una incursión. Si preferís que la tropa no les pegue nunca sin orden directa, alcanza con poner `"sin_blanco_automatico": true` en `granja` (y en `anden`, `gult` o `corral`), sin tocar código.
- **El Tawantinsuyu pierde su escudo de caminos.** En las IA contra IA, la tropa rival les pegaba casi mil golpes por partida a los tramos. Ahora no les pega ninguno y el Tawantinsuyu perdió 3 de las 4 partidas contra guaraníes y mapuches. Lo mide el torneo.
- **Las partidas IA contra IA terminan más** (5 de 6 con ganador antes de los 30 min, antes 2 de 6).

## Archivos

- `src/sim/sim.gd`: `target_class`, `_building_class`, `find_enemy` (prioridad y caminos), `_do_attack` (rebusca), `_hit` (se da vuelta), `_order_attack(…, auto)`.
- `src/sim/sim_entity.gd`: `auto_tgt`.
- `data/reglas.json → blancos`; `data/civs/tawantinsuyu.json → camino.sin_blanco_automatico`.
- `docs/05-mecanicas-nucleo.md`: la regla.
- `tests/ordenes.gd`: `_targets()`.
- `tools/primera_victoria.gd`: bajas hechas y golpes por blanco. `tools/blancos.gd`: nuevo.
