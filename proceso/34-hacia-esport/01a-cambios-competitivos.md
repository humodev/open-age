# 34 · Iteración 1a: cambios competitivos

> Pedido (aprobado por el autor el 2026-11-19, [CONSULTAS](../CONSULTAS.md)): las propuestas 1, 2, 3 y 6 de la [ronda 8 · 04](../22-testers/ronda-8/04-jugabilidad-competitiva.md). Triángulo más marcado, lancero en la I, sitios que paguen y asedio de área esquivable con ataque al suelo.

## Qué cambió

| Frente | Antes | Ahora | Dónde |
|---|---|---|---|
| Triángulo | Línea +6 contra choque, distancia +4 contra línea, choque +6 contra distancia | Línea **+6 contra choque y +6 más contra lo montado** (jinete, elefante: +12 en total); distancia **+6**; choque **+8** | `reglas.bonos`; `Sim.attack_bonus` lee también `bonos.<función>.montado` |
| Lancero | Desde la II (salvo mapuches y Tawantinsuyu) | Desde la **I** para todos; cada pueblo conserva su nombre (Chewa, Lanza larga, Lanceiro…) | `unidades.lancero.edad_min` |
| Sitios | 18/12/8 por minuto; se toman desde la I; tope de lo disputado 15/40/80/120 | **60/45/30** por minuto (+50 % en la IV); se toman **desde la II**; tope **15/80/160/240** | `reglas.sitios` (`captura_edad_min`), `reglas.disputado` |
| Asedio de área | Impacto inmediato (D-021): el área pegaba siempre | El tiro sale al **punto** donde está el blanco y pega ahí **8 ticks** después (0,8 s). Entero y determinista. Contra edificios sigue inmediato | `reglas.asedio_area.vuelo_ticks`; `Sim._fire_shell`, `_land_shells`, `_shell_hit`; **D-031** |
| Ataque al suelo | No había | Orden `suelo`: casilla **R** de la grilla militar, ícono propio (mira sobre el suelo), modo «Tirar acá». Para la catapulta y el asedio de área de cada pueblo (cañón de tacuara, pieza ligera, hondero de piedra caliente, cañón de muralla) | `controller.gd`, `glyphs.gd`, `interfaz.json` (`fijas.suelo`) |
| IA | — | Cada segundo, cada asedio de área que pelea tira al punto del rival más amontonado a su alcance (3 o más en su área) | `SimAI._aim_ground`, `reglas.ia_asedio.suelo` |
| Imagen y sonido | — | La piedra vuela el tiempo real del tiro y un anillo rojo marca dónde cae: así se ve y se esquiva | `world_view._on_shell`, `audio.gd` |

**Los sitios y la victoria por sitios.** La cuenta de victoria sigue corriendo desde el minuto 15 (`cuenta_desde_ms`). Como ahora se toman desde la II (~6 min en la IA difícil), hay unos 9 minutos de pelea por los sitios que solo dan riqueza antes de que puedan ganar la partida. Quien sigue en la I los **disputa** (su tropa frena la captura rival) pero no los toma. En la II, el tope de lo disputado (80 por minuto) corta los tres sitios (135): tener dos ya casi llena el tope; en la III (160) rinden enteros. El tutorial enseña a tomar un sitio en la I: su misión trae `captura_edad_min: 1`.

## Tropiezo: +12 contra todo el choque

Con línea +12 contra **todo** el choque, la primera victoria del principiante (guaraní con guerreros y honderos contra la IA fácil) bajó de **6 de 8 a 4 de 8** semillas (1 de 3 en las de siempre). La IA fácil inca mataba a sus guerreros con lanceros. En AoE4 el bono del lancero es contra la caballería, no contra el hombre de armas: se pasó a +6 contra choque más +6 contra lo montado. El jinete recibe lo mismo que con +12 (la matriz del triángulo da idéntico) y el guerrero, lo de antes. Primera victoria: **6 de 8**, **2 de 3** en 7, 21 y 3 (igual que antes de esta etapa: 6 de 8).

## Matriz de micro (`tools/micro_matriz.gd --variantes=5`, capa común, edad II)

Conjuntos nuevos: `triangulo` (a igual costo y mano a mano) y `area` (contra 2 catapultas, con el modo `esquivar`: quien está donde cae un tiro se corre y vuelve al ataque). El «antes» de los conjuntos nuevos usa [parche-antes.json](pruebas-1a/parche-antes.json) (bonos viejos y vuelo de 1 tick, el impacto inmediato).

| Pelea | Antes (gana A · vivos A/B) | Ahora |
|---|---|---|
| 1 lancero contra 1 jinete | 0/5 · 0,2 / 1,0 | **4/5** · 1,0 / 0,2 |
| 5 lanceros contra 5 jinetes | 1/5 · 1,6 / 2,0 | **3/5** · 2,8 / 0,6 |
| 9 lanceros contra 5 jinetes (igual costo) | 5/5 · 7,6 / 0 | 5/5 · 8,4 / 0 |
| 10 honderos contra 8 lanceros (igual costo) | 5/5 · 8,4 / 0 (29 s) | 5/5 · 9,0 / 0 (24 s) |
| 9 guerreros contra 10 honderos | 4/5 · 5,2 / 0,4 | igual (el +8 no cambia los golpes para matar a un hondero) |
| Mezcla 5+5 contra 10 guerreros, sin micro / mantener+escalonar (**C2**) | 5/5 · 5/5 | **5/5 · 5/5** (sigue pagando) |
| Escalonar: 10 honderos contra 10 guerreros | 5/5 | 5/5 |
| Mezcla 5+5 contra 10 honderos | 4/5 | 1/5 (la distancia le gana a la línea: el triángulo se lee) |
| 10 honderos contra 2 catapultas + 4 lanceros, sin micro | 0/5 · 0 / 2,2 | 0/5 · 0 / 2,2 |
| … **esquivando** | 0/5 · 0 / 2,6 | **5/5 · 6,0 / 0** |
| … en formación abierta | 0/5 | 0/5 |
| 10 lanceros contra 2 catapultas + 6 honderos, sin micro / esquivando | 4/5 / 4/5 | 3/5 / **4/5** (2,4 vivos contra 1,0) |

Completas: [antes](pruebas-1a/matriz-antes.txt) y [después](pruebas-1a/matriz-despues.txt).

**Lectura.** El jinete ya no le gana al lancero mano a mano. Esquivar el área pasa de no servir a dar vuelta la pelea, con un bot que reacciona en 0,2 s y no falla. Una persona va a esquivar menos, pero ahora la micro sirve. La formación abierta sola no alcanza contra 2 catapultas.

## Pruebas

- `tests/test_determinism.gd`: OK. El hash pasa de **718068252** a **3870415820**.
- `tests/asedio.gd` OK, con tres casos nuevos: el tiro no pega al salir y pega al llegar; el bloque que se corre 2,5 casillas no recibe daño; atacar el suelo (la catapulta va y tira, el ariete no).
- `tests/sitios.gd`: OK, con un caso nuevo (en la I no se toma y en la II sí).
- OK: `tests/micro.gd`, `tests/casillas.gd` (576 grillas), `tests/grilla.gd`, `tests/iconos.gd` (721 grillas), `tests/civ_smoke.gd`, `tests/campaign_smoke.gd` y `tests/bench.gd` (200 unidades: 10 ms de promedio).
- Autotest con mapuches: OK.
- Captura de la demo de batalla con asedio: [batalla-asedio.png](pruebas-1a/batalla-asedio.png). El anillo rojo marca dónde cae el tiro.
- `tools/primera_victoria.gd`: [2 de 3](pruebas-1a/primera-victoria.txt) en 7, 21 y 3; 6 de 8 con 1, 2, 4, 5 y 6.
- `tools/civ_diag.gd`, 30 partidas: guaraníes (lancero en la I, cañón de tacuara esquivable) y Etiopía (Chewa en la I, pieza ligera). Ver abajo.

## civ_diag

CIV_DIAG_PENDIENTE

## Commits

Rama `worktree-agent-a2f9209bc4def8279`: 1bb89d1, b7d201c, la prueba de sitios, el +6 contra lo montado y el cierre.
