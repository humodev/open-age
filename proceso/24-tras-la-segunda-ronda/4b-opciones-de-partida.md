# 24 · Paso 4b: opciones de partida

## Pedido
De la [síntesis de la segunda ronda](../22-testers/ronda-2/00-sintesis.md):
> "Opciones de partida: sitios sí o no, tiempo límite, conquista; también para el jugador nuevo."
> "Equipos juntos o mezclados."

Es el ítem "opciones de partida" del paso 4 del [plan de la etapa](README.md). La referencia es el lobby de AoE4: condiciones de victoria, recursos iniciales y ubicación de los equipos.

## Diseño

| Opción | Valores | Opción de `Sim.new` | Argumento de `main.gd` |
|---|---|---|---|
| Conquista | siempre | — | — |
| Victoria por sitios sagrados | sí / no | `sitios_sin_victoria` (ya existía, la usa el tutorial) | `--sitios=si\|no` |
| Victoria por hitos | sí / no | `hitos_sin_victoria` | `--hitos=si\|no` |
| Tiempo límite | sin límite / 30 / 45 / 60 min | `tiempo_limite_min` | `--tiempo=0\|30\|45\|60` |
| Recursos iniciales | normales / medios / altos | `recursos` | `--recursos=normal\|medios\|altos` |
| Ubicación de los equipos | aliados juntos / mezclados | `ubicacion_equipos` | `--ubicacion=juntos\|mezclados` |

Los números están en `data/reglas.json`:
- `opciones_partida.recursos`: medios (500/500/300/300) y altos (1000/1000/700/700). Normal es `recursos_iniciales` (200/200/100/100). Los recursos propios de una civ (fama, mit'a) siguen igual.
- `opciones_partida.tiempo_limite_min`: lo que ofrece el menú.
- `opciones_partida.menu`: lo que el menú elige la primera vez. Después recuerda lo último (`user://opciones.cfg`, `[partida] opciones`).
- `puntaje`: pasó de `interfaz.json` a `reglas.json`, porque ahora decide la partida.

**Qué hace cada una:**
- **Sitios: no.** Los sitios siguen en el mapa y siguen rindiendo riqueza (como en AoE4), pero tenerlos todos no gana y la cuenta grande no aparece. Se reutiliza `sitios_sin_victoria`. No se usó `sin_sitios`: además de sacar los sitios, cambia el tamaño del mapa y la disposición en círculo (es la opción de las campañas).
- **Hitos: no.** La conquista sigue valiendo, pero ya no alcanza con destruir la capital y los hitos: pierde quien se queda sin edificios terminados. No cuentan los muros (`linea`), las puertas ni los caminos, para que una empalizada suelta no estire la partida. `Sim.counts_for_victory` decide qué cuenta. La IA ataca lo mismo (`SimAI._attack`), así que con esta opción va por cualquier edificio del rival que quede.
- **Tiempo límite.** En el paso del minuto pedido (`tick == minutos × 600`), la simulación termina la partida (`Sim.end_by_time`).
  - Gana el equipo en pie con más puntos. Los puntos de un equipo son la suma de los de sus jugadores, también los derrotados (`Sim.team_score`).
  - Si los dos primeros empatan, no gana nadie (`winner = -1`) y la pantalla dice "Empate".
  - En los últimos 5 minutos aparece la cuenta grande arriba al centro: "TIEMPO LÍMITE · VA GANANDO …", con el color de quien va adelante.
- **Puntaje en la simulación.** Antes lo calculaba la interfaz (`panel_datos.gd`), con un contador de edificios destruidos que llevaba la interfaz. Para que decida una partida tiene que ser determinista: ahora es `Sim.score(pid)`. Usa la misma fórmula, con el libro de ingresos (`stats.origen`) y un contador nuevo, `stats.edificios_destruidos`. El F6 y la pantalla de fin leen el de la simulación.
- **Equipos juntos o mezclados.** Con 3 o más jugadores, las bases van en círculo (`_generate_map_n`). `Sim._team_slots` da el lugar de cada jugador:
  - juntos: los de un equipo seguidos;
  - mezclados: uno de cada equipo por vuelta.
  - El terreno se arma con las bases en el orden del círculo, porque ríos, islas y cercos de fortines suponen que la 0 y la 1 son vecinas. Después cada jugador toma su lugar y los cercos pasan al dueño nuevo. Los sitios entre bases vecinas se calculan sobre el círculo.
  - **Sin la opción, el orden de siempre.** Las pruebas viejas, las repeticiones y `--equipos=0,1,0,1` (que ya alternaba) dan el mismo mapa.
- **Pantalla de fin.** Explica el motivo (`Sim.end_reason`: conquista, sitios o tiempo):
  - "Se cumplió el tiempo límite (30 minutos) y ganó Rojo · Mapuches por puntos: 53 contra tus 50."
  - Ganar o perder por conquista distingue "capital e hitos" de "arrasar todos los edificios".
  - El suceso `victory` lleva `motivo`.

**El menú.** Debajo de los lugares, en la columna de la derecha, hay un bloque "Opciones de partida":
- Victoria: "Conquista ✓" (fija) y dos interruptores, sitios sagrados e hitos.
- Tiempo límite y recursos, en un renglón.
- Equipos: aliados juntos o mezclados. Se apaga en el 1 contra 1 y en todos contra todos.
- Una línea dice en palabras cómo se gana ("Se gana por conquista (capital e hitos) o por sitios sagrados (10 minutos con todos). A los 45 minutos gana el equipo con más puntos."). Es lo que pedía el jugador nuevo.

Cada control tiene su explicación al pasar el mouse. Los recursos muestran los valores de cada nivel.

## Paso a paso
1. `reglas.json`: `opciones_partida` y `puntaje` (que sale de `interfaz.json`).
2. `Sim`:
   - recursos según la opción (`_starting_res`);
   - `counts_for_victory` en `_check_victory`;
   - `score`, `team_score` y `end_by_time`;
   - `end_reason` y `motivo` en el suceso de victoria;
   - `stats.edificios_destruidos`;
   - `_team_slots` en `_generate_map_n`.
3. `SimAI._attack`: los blancos salen de `counts_for_victory`.
4. `main.gd`: `match_opts` traduce los argumentos (documentados en el encabezado) y los suma a los opts de `Sim.new`. Quedan en la repetición. `--panel=fin-tiempo` termina la partida por tiempo para la captura.
5. `menu.gd`:
   - el bloque de opciones;
   - `match_args()`, que el menú pasa a `_start`;
   - `--sitios`, `--tiempo` y el resto también preeligen en el menú (para las capturas).
   - Se recuerda en `Opciones.partida`.
6. Interfaz:
   - `panel_fin.gd`: el motivo y el empate;
   - `hud.gd`: "Empate";
   - `cuenta_grande.gd`: la cuenta del tiempo límite;
   - `panel_datos.gd` y `panel_puntaje.gd`: el puntaje de la simulación.
7. Documentos: `docs/05` (victoria) y `docs/11` (bases).

## Pruebas
- **[`tests/opciones_partida.gd`](../../tests/opciones_partida.gd)** (nueva, [resultado](pruebas/4b-opciones-partida.txt); [con 30 minutos](pruebas/4b-opciones-partida-30min.txt)): OK.
  - Recursos normales, medios y altos: cada jugador arranca con lo de los datos.
  - Ubicación: 2v2, 3v3 y 2v2v2 en llano, islas y fortines.
    - Juntos: cada jugador tiene un aliado entre sus dos bases más cercanas.
    - Mezclados: ninguno.
    - En todos los casos, los sitios son al menos uno por jugador y cada cerco está más cerca de la base de su dueño.
    - Sin la opción, el mapa es el de siempre.
  - Hitos:
    - Con la victoria por hitos, sin capital pierde aunque tenga una casa.
    - Sin ella, sigue en pie. Al perder la casa pierde por conquista, aunque le quede una empalizada.
  - Sitios:
    - Con la victoria, todos los sitios del jugador 0 ganan a los 9:59 (10 minutos).
    - Sin ella, la partida sigue después de los 10 minutos y los sitios rinden riqueza.
  - Tiempo límite, con IA de estilo pacífico (no ataca la base, así ninguna partida termina antes por conquista):
    - 1v1 y 2v2 terminan justo en el minuto pedido (5 y 30), por tiempo. Gana el equipo con más puntos.
    - Sin puntos, empate y nadie gana. Sin la opción, la partida sigue.
- **[IA sin victoria por hitos](pruebas/4b-sin-hitos-ia.txt)** (45 minutos, dos pares, llano):
  - Con la victoria por sitios activa, las cuatro partidas se definen igual por sitios o siguen abiertas. Sacar los hitos cambia quién gana (la IA ataca otros blancos), pero no cómo termina.
  - Con solo conquista: con hitos, Tawantinsuyu gana a los 26:38. **Sin hitos, ninguna termina en 45 minutos.** Al mapuche le quedan 41 edificios y al etíope, 15.
  - Arrasar todo es largo, como en AoE4. Para la IA es un trabajo nuevo: hoy va al edificio más cercano del rival elegido y vuelve a reunirse entre oleadas. Mientras tanto, conviene que el menú sugiera un tiempo límite con "Hitos" apagado (consulta 5).
- **Determinismo**: [OK](pruebas/4b-determinismo.txt).
- **Rendimiento** ([resultado](pruebas/4b-bench.txt)): la máquina tenía carga de 26 por torneos ajenos, así que se midió el commit anterior en el mismo momento. Dio 19,15 ms contra 18,13 ms con las opciones: no hay pérdida.
- **Equipos** (`tests/equipos.gd -- --minutes=5`): [OK](pruebas/4b-equipos.txt). Sin fuego amigo; las puertas y los fortines de 4 y 6 siguen bien.
- **Civs** ([`civ_smoke`](pruebas/4b-civ_smoke.txt)) y **campañas** ([`campaign_smoke`](pruebas/4b-campaign_smoke.txt)): sin errores.
- **Autotest** (`--autotest --civ=guaranies --terreno=llano`): [OK](pruebas/4b-autotest.txt). El "double free" al salir ya estaba en las corridas anteriores de la etapa.
- **Capturas:**
  - [menú 2v2, 1920×1080](capturas/4b-menu-2v2.png): las opciones de siempre;
  - [menú 4v4 a 1366×768](capturas/4b-menu-4v4-1366.png): sin sitios, 45 minutos, recursos altos, mezclados. Entra entero;
  - [cuenta del tiempo límite](capturas/4b-cuenta-tiempo.png);
  - [pantalla de fin por tiempo](capturas/4b-fin-tiempo.png): la partida se cortó a los 2 minutos con `--panel=fin-tiempo`, que toma 30 como límite si no hay uno.

## Tropiezos
- **La casilla vacía no se veía.** El primer menú usaba `CheckBox`, y sobre el fondo oscuro la casilla sin marcar era invisible: "Sitios sagrados" apagado parecía un texto suelto. Quedan interruptores (`CheckButton`), como en el diálogo de Opciones. La línea de resumen dice en palabras lo que está activo.
- **`sin_sitios` no servía para "sitios: no".** Además de sacar los sitios, apaga los ingenios y el mapa para N jugadores (vuelve a 128 casillas con las bases de campaña). Por eso la opción del menú es `sitios_sin_victoria`.
- **El orden de las bases es geométrico.** Varias partes del generador suponen que las bases 0 y 1 son vecinas: el río de cada par, las islas, los bajíos y los sitios entre vecinas. Permutar las bases antes del terreno rompía eso. Se permutan después, y los cercos de fortines cambian de dueño con ellas.
- **La prueba de 30 minutos terminaba por conquista.** Con la IA equilibrada, el 1v1 terminó a los 28:14 y el 2v2 a los 23:29, antes del límite, y la prueba fallaba aunque la opción anduviera bien. Ahora la prueba usa IA pacífica y muestra el motivo real.
- **El tick del final.** `step()` corre el tick N y deja el reloj en N + 1. La prueba primero esperaba `tick == 3000` y veía 3001. La partida termina en el paso del minuto exacto (5:00,0).

## Consultas propuestas
1. **Valores de recursos medios y altos.** Hoy son 500/500/300/300 y 1000/1000/700/700 (alimento, madera, piedra, riqueza), parecidos a los de AoE2. ¿Van esos o preferís otros?
2. **Ubicación por defecto en el menú: "aliados juntos"**, como el lobby de AoE4. Antes, el 2v2 y el 3v3 del menú quedaban mezclados por el orden de los lugares. ¿Juntos o mezclados por defecto?
3. **Tiempo límite con empate:** hoy no gana nadie. ¿Preferís un desempate (por ejemplo, más edificios en pie o más sitios)?
4. **Conquista sin hitos:** no cuentan muros, puertas ni caminos; sí cuentan granjas, casas y almacenes. ¿Contamos también las unidades, como en algunos modos de AoE4, aunque se alargue la cacería del último aldeano?
5. **Hitos apagados sin tiempo límite:** la IA no termina las partidas (ver la prueba). ¿El menú sugiere un tiempo límite al apagar "Hitos", o mejoramos primero la caza de los últimos edificios en la IA (paso de IA experta)?
6. **Opciones que faltan del lobby de AoE4:** maravilla (no existe todavía), edad inicial, población máxima y "revelar mapa". ¿Alguna entra en este paso?

## Commits
- `Opciones de partida (etapa 24, paso 4b): victoria por sitios e hitos, tiempo límite, recursos y equipos juntos o mezclados` (este).
