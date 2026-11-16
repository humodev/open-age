# Paso 3b: los mapuches lentos

**Pedido** (paso 3 del plan): en la economía en paz, los mapuches llegan a la edad III a las ~19:40 y las demás civs entre las 15 y las 17. Buscar la causa y probar **un** cambio que la acerque a 16–17 min sin romper la identidad (pueblo de lof, ganado, malón).

## Causa

Seguí la partida de `tests/economia.gd` minuto a minuto: mapuches contra guaraníes, llano, semilla 931. Usé una copia local de `tools/ia_por_dentro.gd` con la personalidad `paz`, una traza por minuto y lo acumulado del kawiñ ([antes](pruebas/3b-ia-por-dentro-antes.txt)).

| Minuto | Mapuches: alimento / riqueza en el banco | Ejército mapuche | Guaraníes: alimento | Ejército guaraní |
|---|---|---|---|---|
| 9:00 | 14 / 517 | 21 | 623 | 6 |
| 11:00 | 0 / 837 | 30 | 883 | 12 |
| 13:00 | 32 / 861 | 45 | 39 (ya levantan el hito) | 20 |
| 15:00 | 232 / 669 | 67 | 49 (edad III) | 38 |

- **El alimento nunca llega a la mitad del hito.** En la edad II, `_wants_hito` solo ahorra si cada recurso cubre al menos la mitad del hito: 500 de los 1000 de alimento. Si no, ahorra a ratos, 40 s de cada 2 minutos.
- Fuera de esos ratos, todo lo que entra se va en tropa. El ejército mapuche se paga con alimento y riqueza, y la riqueza sobra: los corrales la dan sola (837–901 parados entre los minutos 11 y 14). Entonces el único freno es el alimento, que es justo lo que pide el hito.
- Los mapuches tienen además más edificios que entrenan: 2 ruka de guerra, 2 lof que no son el principal (weichafe) y 3 corrales (kona montado desde la II). Son 7, contra 3–5 de las demás civs. A las 15:00 tenían 67 de ejército contra 38 de los guaraníes: unos 1200 de alimento de más, que es lo que pide el hito.
- Con el alimento en 0, el lof principal tampoco saca aldeanos a tiempo: 30 aldeanos a las 10:00 contra 37 de los guaraníes, y el tope de 42 a las 15:00 contra las 12:00.
- Los guaraníes llegan a 500 de alimento a las 9:00 porque su tropa también pide madera, y la madera no alcanza. Desde ahí ahorran sin cortes.
- **El kawiñ no se usaba.** La IA hacía la fiesta solo si con ella casi completaba los 1000 (alimento + fiesta ≥ 900). Eso no pasaba nunca: 0 de alimento por kawiñ hasta el minuto 19.
- El costo del hito (1000 de alimento, 660 de riqueza y 200 de piedra; el rewe pide 60 de riqueza más) no es la causa: a los mapuches les sobran riqueza y piedra.

## Cambio (uno: la IA usa el kawiñ para entrar en el ahorro)

`src/sim/sim_ai.gd`, motor mapuche (`_engine`):
- Desde la edad II, si el alimento no llega a la mitad del hito y la fiesta lo completa, la IA hace el kawiñ en los `ia_economia.kawin_corrales` corrales más llenos (con 4 cabezas o más y sin fiesta en esta edad). La fiesta solo cuenta si el resto de las condiciones del hito ya se cumplen (aldeanos, cuartel, riqueza y piedra a la mitad).
  - Cuando el alimento pasa la mitad, la IA entra en el ahorro de siempre: ejército mínimo, gente al alimento.
  - El ganado se vuelve el alimento que destraba la edad, que es lo que hace el kawiñ en la ficha.
- Queda la regla de antes: ahorrando, si con el corral más lleno casi alcanza, se hace la fiesta en ese.
- `_wants_hito` admite recursos por llegar (`extra`) y un modo `strict` sin el ahorro a ratos. Así la fiesta se decide con la misma regla que el hito.
- El alimento por cabeza sale del corral (`ganado.fiesta_alimento`). Antes había un 30 escrito en el código.

`data/reglas.json`: `ia_economia.kawin_corrales: 1`.

### Primer intento (descartado): la fiesta de todos los corrales
Con la fiesta de todos los corrales juntos (hasta 3 × 150 de alimento), la edad III mapuche pasó de 18:43 a **13:30**: la primera de las seis civs, por un minuto ([medida](pruebas/3b-economia-paz-todos-los-corrales.txt)). La mitad del hito se completaba a los 10–11 minutos.

Con un solo corral (150 de alimento), la fiesta completa la mitad recién cuando el banco ya tiene unos 350. Eso llega más tarde (en la semilla 931, a las 14:30, después del mercado), y la edad III queda en 17:02.

## Medidas

**Economía en paz** (`tests/economia.gd -- --paz --minutes=25 --seeds=2`; promedio de 4 partidas por civ):

| Civ | Edad III antes | Después |
|---|---|---|
| Tawantinsuyu | 15:40 | 15:40 |
| **Mapuches** | **18:43** (19:40 con 1 semilla) | **17:02** |
| Guaraníes | 14:32 | 14:32 |
| Etiopía | 16:55 | 16:55 |
| Palmares | 17:32 | 17:32 |
| Ayutthaya | 18:12 | 18:20 |

La edad II mapuche no cambia (7:25): la regla nueva rige desde la II. Ayutthaya se mueve 8 s porque en una partida juega contra los mapuches.

- Antes: [1 semilla](pruebas/3b-economia-paz-antes.txt), [2 semillas](pruebas/3b-economia-paz-antes-2semillas.txt). La medida de 2 semillas se corrió sobre una copia del commit anterior.
- Después: [solo las partidas con mapuches](pruebas/3b-economia-paz-mapuches-1-corral.txt) y [la tabla completa](pruebas/3b-economia-paz-despues-2semillas.txt).
- Partida seguida ([después](pruebas/3b-ia-por-dentro-despues.txt)): la fiesta a las ~14:30 y la edad III a las ~16:30. Antes, la edad III llegaba a las ~20:30.

**Otras pruebas:**
- **Salud de la IA**: [antes](pruebas/3b-salud-ia-antes.txt) y [después](pruebas/3b-salud-ia-despues.txt) son idénticas (mapuches OK). La prueba corta a los 15 minutos, con guerra, y la fiesta nueva no llega a dispararse. Las 4 civs que fallan ya fallaban antes: Tawantinsuyu, guaraníes, Palmares y Ayutthaya, sin mercado al minuto 15, entre otras cosas. No es de este cambio.
- **Determinismo**: [OK](pruebas/3b-test_determinism.txt).
- **Civs**: [sin errores](pruebas/3b-civ_smoke.txt).
- **Rendimiento**: [19,4 ms de promedio y 162 de peor caso](pruebas/3b-bench.txt), con el torneo y otras pruebas corriendo en la máquina; el presupuesto es de 100 ms.
- El torneo no se corrió acá: lo corre el orquestador.

## Riesgos para el balance
- Con guerra, el ejército mapuche de la edad II va a ser más chico cuando la fiesta lo destrabe: entra el ahorro y la tropa queda en el mínimo (`ejercito_minimo_ahorrando`, 16). A cambio llegan antes al kona montado de la edad III. Hay que verlo en el torneo (mapuches 52 % en el torneo 14).
- La fiesta deja el corral en 1 cabeza y sin cría por 2 minutos: menos riqueza por un rato. A los mapuches de la IA les sobraba riqueza, así que no debería pesar.
- `kawin_corrales` es la perilla: con 1, 17:02; con todos, 13:30. Si el torneo pide más, se puede probar con 2.

## Tropiezos
- La primera copia del commit anterior para medir "antes" con 2 semillas salió vacía (`git archive` no dejó los datos) y la prueba se colgó hasta el tiempo límite. La segunda copia (rsync del árbol, con el `sim_ai.gd` del commit anterior) sí sirvió.
- La salida del primer intento parecía un éxito (la edad III bajó 5 minutos), pero se pasaba del objetivo y dejaba a los mapuches primeros. Por eso la fiesta se limitó a un número de corrales, en los datos.
