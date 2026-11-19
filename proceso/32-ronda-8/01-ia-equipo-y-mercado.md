# IA en equipo: oleadas escalonadas y mercado

Pedido (decisiones del autor, ronda 8): que las IA de un mismo equipo no lleguen todas juntas
(«6 fáciles son 90 soldados a los 15–17 min»; «3 rivales salen juntas desde el minuto 8») y que
la IA use el mercado: comprar lo que falta y vender lo que sobra con criterio, por ejemplo la
piedra de un hito cuando sobra madera. Sin ventaja para nadie.

Solo se tocaron `src/sim/sim_ai.gd` y `data/reglas.json`, más una medición nueva:
`tools/ataques_equipo.gd` (1v3, 1v6 y 2v2 IA contra IA, sin vista).

## Qué cambió

**Turnos en el ataque** (`reglas.equipos.ia_escalon`, `SimAI._team_turn`):

- Una IA no larga su oleada si una aliada largó otra hace menos de `desfase_ticks` (45 s), ni
  mientras esa oleada siga en marcha o haya llegado hace menos del desfase. La marcha se sigue
  de verdad (`_track_wave`): llegó cuando el centro de la tropa está a `llegada` del blanco o
  cuando menos de la mitad sigue en marcha. Hay un tope: `marcha_max_ticks` (3 min).
- Por turno: entre las que tienen la oleada lista, va primero la que espera desde antes. Sin
  esto, la que repetía su oleada cada 50 s no dejaba salir nunca a las otras.
- Otro frente: si una aliada va al mismo edificio, va al siguiente más cercano.
- La fácil (`escalon_ticks: 600`, `escalon_marcha: false`) solo espera el desfase entre salidas
  (1 min). Con la espera de la marcha, en el mapa grande casi no atacaba.
- Las bengalas, la defensa y los envíos contra un hito o una maravilla no esperan turno.

**Mercado** (`reglas.ia_mercado`, `SimAI._trade`):

- Si a la meta (el hito de la edad siguiente o la maravilla) le falta algo, lo compra con la
  riqueza que sobre por encima de la meta. Si no alcanza, vende el recurso que más pase de lo
  que pide la meta más 300. Esto vale ahora en todas las edades. Antes, vender para la meta
  solo pasaba desde la III, y en la II la IA juntaba riqueza hasta 400 y se quedaba quieta: es
  el caso del inca de la ronda 8.
- Lo general (vender lo que pase de 900 con poca riqueza, comprar alimento o madera con mucha)
  ahora no vende lo que pide la meta. Antes vendía la piedra del hito.
- El mercado mira los recursos reales, sin lo apartado para niveles y mejoras que todavía no
  alcanzan. Con eso apartado, una IA veía todo en cero. Lo pedido por un aliado sigue apartado.
- Una operación cada `cada_ticks` (1 s). La fácil (`mercado: "poco"`) no comercia para la
  meta, solo lo general. `ia_edad_iv.vende_sobra` pasó a `ia_mercado.vende_sobra`.

## Antes y después

Llano, semilla 7, después de integrar main (recursos del mapa nuevos, hash 718068252). El
«antes» es la IA de main con los mismos contadores. Las salidas completas están en
`ia-equipo-*.txt`. Los 2v2 del «después» se corrieron una versión antes de sumar la espera tras
la llegada; el mercado es el mismo.

**1v3** (el 0 difícil contra 3 normales). Soldados rivales junto a la capital del 0, lo más en
cada minuto:

| | min 6–12 | 13–16 | pico | fin |
|---|---|---|---|---|
| Antes | 7–15 | 11–15 | 55 (22:15) | 23:24, gana el equipo de 3 |
| Después | 7–14 | 27–39 | 39 (15:40) | 23:09, gana el equipo de 3 |

Antes había 24 salidas en 23 minutos. Después son 13, más grandes y de a una: las llegadas
quedan separadas por 1 a 3 minutos. Antes, al final, se juntaban tres en 11 segundos (20:06,
20:13 y 20:17). El resultado y la duración no cambian.

**1v6** (el 0 difícil contra 6 fáciles, mapa grande):

| | salidas de las 6 | llegadas |
|---|---|---|
| Antes | 15:02 a 16:38 (las 6 en 96 s) | 17:00 a 18:30 casi juntas |
| Después | 15:02, 16:03, 17:05, 18:06, 19:07, 20:07 | 17:16, 18:17, 18:53, 19:20, 20:00, 21:55 |

El pico junto a la capital no baja en esta partida (de 47 a 68 a los 22 min). Las fáciles
llegan de a una, pero la difícil del 0 estaba atacando afuera y las deja quedarse en su base.
Contra un jugador que defiende, cada oleada es de unos 16 a 23 soldados, no de 90.

**Mercado (2v2 de normales, 45 min, semillas 7 y 11).** Con la piedra nueva del mapa (4000 a
5100 por jugador), ninguna IA queda trabada por piedra, ni antes ni después: 0 s en las dos
versiones (13 s una vez después). Por eso la compra baja: después compran piedra 2 a 4 lotes por
partida, contra 2 a 6 antes. También venden menos piedra: 1 a 15 lotes, contra 3 a 15. Lo que
mejoró es el paso por las edades:

- Semilla 7: la etíope antes se quedó en la II toda la partida; después llegó a la III a los 18:41.
- Semilla 11: la etíope llegó a la III a los 20:22, antes a los 39:00. La mapuche llegó a la
  IV a los 27:00, antes ni a la III. El inca llegó a la III a los 16:59, antes a los 25:41,
  pero esta vez no llegó a la IV (antes, a los 36:35). La partida terminó a los 41 min.

Con la piedra de antes (antes del merge), una etíope sin centro aparecía como «trabada»: era
una IA sin capital, no el mercado. Ahora la herramienta solo cuenta a quien tiene centro.

## Pruebas

- `tests/test_determinism.gd`: OK, hash 718068252 (igual al de main; la partida de la prueba es
  1v1 y no llega al mercado ni tiene aliados).
- `tests/equipos.gd`: OK. Sin fuego amigo, los espejos dan lo mismo y nadie queda encerrado.
- `tools/primera_victoria.gd --seeds=7,21,3 --min=30`: gana 2 de 3.
- `tests/bench.gd`: 9,9 ms de promedio y 67,9 ms el peor tick (presupuesto: 100).

## Tropiezos

- Estimar la llegada en línea recta no alcanzó: un río o un bosque alargan el camino, y dos
  oleadas «separadas» llegaban en el mismo minuto. Por eso ahora se sigue la marcha.
- Si la oleada en marcha no terminaba nunca (se quedaba peleando en el camino), las demás
  esperaban para siempre. Por eso termina cuando menos de la mitad sigue en marcha, o pasado
  el tope.
- Al salir no hay que mirar si la tropa está en marcha: la orden se aplica en el tick
  siguiente, y la oleada se daba por llegada en el acto.
