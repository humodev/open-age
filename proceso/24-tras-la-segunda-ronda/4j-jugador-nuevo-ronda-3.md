# 24 · Paso 4j: lo que pide el jugador nuevo en la tercera ronda

## Pedido
Del [informe del jugador nuevo, ronda 3](../22-testers/ronda-3/02-nuevo-en-rts.md):

1. **La fácil gana por sitios sin buscarlos.** Tiene `toma_sitios: false`, pero los toma al pasar con el ejército. Que no deje unidades dentro del radio de un sitio (que se corra o lo rodee), sin cambiar las otras dificultades: el hash de `tests/test_determinism.gd` con la normal no cambia.
2. **La primera partida sin sitios.** La primera vez (sin opciones guardadas en `user://opciones.cfg`), el menú arranca en Fácil con "Sitios sagrados: no".
3. **Tutorial.**
   - La obra del hito (190 s) deja dos minutos y medio sin tarea ni mensaje.
   - «Abatí a los saqueadores» se cumple antes que «Entrená 5 guerreros».
4. **Grilla con nombres:** el nombre común («Casa», «Leñera») además del propio («Oga», «Tapyi»).
5. **Pantalla de fin:**
   - «Empate» con un color propio, no el naranja de «Derrota».
   - Con los sitios apagados, «Sitios 0/3» no tiene que parecer una cuenta para ganar.
6. **Un aviso que empuje a ganar:** con ejército grande en casa y recursos de sobra durante un rato, «Tenés ejército y recursos de sobra: atacá o subí de edad».

## Qué se hizo

### 1. La fácil no toma sitios al pasar
**Qué pasaba.** Medí con una prueba nueva, [`tests/facil_sitios.gd`](../../tests/facil_sitios.gd): guaraníes sin IA (pasivo) contra Tawantinsuyu en fácil, en llano. La prueba anota cada sitio que toma la IA y las órdenes de las unidades que estaban en el radio.
- Las capturas no eran de unidades estacionadas. Eran de un hondero o un ariete rezagado que cruzaba el cuadro del sitio, en marcha o en ataque en movimiento.
- La captura de un sitio **no se pierde cuando el que la hace se va** (`SimMods._sacred` solo la reinicia si llega otro). Así, varias pasadas cortas suman los 10 segundos.

**Qué hace ahora la IA que no toma sitios** (`SimAI._avoid_sites`; números en `reglas.json` → `ia_sin_sitios`):
- **Rodea.** En su propia grilla de caminos, cada casilla del cuadro de un sitio cuesta 4 veces más (`SimMap.set_weight`, sobre el A* de ese jugador). El buscador de caminos lo rodea si hay por dónde.
  - Probé antes un rodeo geométrico por las esquinas del cuadro. No servía: el camino real dobla por el terreno y volvía a entrar (ver Tropiezos).
- **Sale.** Si una unidad igual queda adentro de un sitio ajeno sin rivales cerca, va al borde más cercano del cuadro agrandado y, al llegar, retoma su destino.
- **No se para adentro.** Un destino adentro del cuadro se cambia por el borde.
- Mira también las órdenes que el resto de la IA acaba de dar en el mismo turno (`sim._pending`), para no trabajar con el destino viejo.
- **Cuándo no se aplica.** Solo con la dificultad que tiene `toma_sitios: false`, y solo si los sitios ganan la partida. Con "Sitios: no" o en el tutorial tomarlos no gana nada, así que la IA no hace nada distinto. Ahí los saqueadores del tutorial siguen como antes (ver Tropiezos).

**Resultado** (30 minutos, 5 semillas; [salida](pruebas/4j-facil-sitios.txt)):

| Semilla | Antes: sitios que toma la fácil | Antes: final | Ahora: sitios | Ahora: final |
|---|---|---|---|---|
| 7 | 0 | sigue a los 30:00 | 0 | sigue a los 30:00 |
| 21 | **3** (16:08, 18:15, 18:23) | conquista 18:28 | 0 | sigue a los 30:00 |
| 3 | **1** (18:09) | conquista 18:09 | 0 | conquista 18:09 |
| 11 | **1** (15:50) | conquista 17:10 | 0 | conquista 17:14 |
| 5 | **1** (15:52) | conquista 18:02 | 0 | conquista 18:19 |

- **Antes, 6 sitios en 5 partidas; ahora, ninguno.**
- La semilla 21 ya no termina por conquista. La fácil tiene un tope de 15 soldados (`ejercito_max`) y la segunda oleada pide 18, así que ataca una sola vez. Si en esa oleada los honderos se traban contra el centro y el ariete espera en la formación, no vuelve a atacar. Lo mismo ya pasaba antes en la semilla 7. No lo toqué: es de la IA fácil en general, no de los sitios (queda como consulta).
- **Determinismo:** el hash con la IA normal sigue siendo `1249639671`, el mismo de los pasos anteriores ([salida](pruebas/4j-determinismo.txt)).

### 2. La primera partida sin sitios
- `reglas.json` → `opciones_partida.menu_por_dificultad.facil = {"sitios": false}`. Va encima de `menu` mientras no haya opciones de partida guardadas.
- Si alguien cambia la dificultad antes de tocar las opciones de partida, el interruptor sigue a la dificultad: Normal vuelve con los sitios prendidos (`menu.gd`, `_dif_defaults`).
- La línea que explica cómo se gana suma: «Los sitios sagrados dan riqueza, pero no ganan.»
- [Captura del menú la primera vez](capturas/4j-menu-primera-vez.png): Fácil, sitios apagados, «Se gana por conquista (capital e hitos).»

### 3. Tutorial
**Motor de escenarios** (`sim_scenario.gd`; documentado en [`docs/campanas/README.md`](../../docs/campanas/README.md)):
- `despues_de` en un objetivo: no se cumple antes que los objetivos que nombra. Lo que pasó antes cuenta igual.
- `params.nuevos` en `entrenar`: cuenta solo lo entrenado desde que aparece el objetivo.
- Disparador `obra` (`valor`: un tipo o `hito`): el jugador empezó a levantar uno. Con `espera` sirve para usar el tiempo de una obra larga.

**`tutorial.json`:**
- o9 («Abatí a los 4 saqueadores») lleva `despues_de: "o8"`, y su texto lo dice: «se cumple después de entrenar los 5 guerreros».
- Mientras sube el hito, cinco mensajes de la Guía, a los 0, 20, 60, 100 y 140 segundos de empezada la obra:
  1. la barra de la obra, y que más aldeanos la levantan más rápido;
  2. el panel de Edad (F4);
  3. el efecto de cada hito alrededor suyo (el de economía junta más rápido cerca, el de guerra cura): conviene levantarlo junto a los campos y los árboles;
  4. los grupos (Ctrl+1, 1, dos toques centran);
  5. qué cambia al llegar a la edad II.
- A los 20 segundos, una tarea opcional (o11, secundaria): «entrená 3 aldeanos más y mandalos a juntar». No traba la victoria.

**Pruebas** (`tests/tutorial_letra.gd`):
- Ahora falla si o9 se cumple antes que o8, o si la obra del hito pasa con menos de 2 mensajes.
- **Al pie de la letra:** gana a las 11:06; o8 y o9 se cumplen juntos a las 7:43; 5 mensajes durante el hito ([salida](pruebas/4j-tutorial-letra.txt)).
- **Indefenso:** gana a las 14:05; o8 y o9 a las 10:46 ([salida](pruebas/4j-tutorial-indefenso.txt)). Antes ganaba a las 12:35. Este jugador no entrena guerreros hasta que pasa el ataque, así que ahora o9 espera a o8, y o8 llega más tarde.
- **Campañas** (`campaign_smoke`): [sin errores](pruebas/4j-campaign_smoke.txt).

### 4. Grilla con nombres
- Con la opción (o `--nombres=1`), la casilla lleva el **nombre común arriba**, en negrita, y el **propio abajo**, más tenue: Casa / Oga, Granja / Kokue (roza), Leñera / Tapyi, Barrero / Ñai'ũ renda.
- Si el propio es el mismo que el común (Mercado), va uno solo.
- Si abajo hay franja (lo que falta) o edad, va solo el común.
- Los hitos dicen «Hito · edad II».
- El común sale de la capa sin civilización de los datos (`Controller.common_name`), como el que ya mostraba la ficha.
- **Varios recursos que faltan** (la franja alta del paso 4k): el glifo se achica y queda un solo nombre justo encima de la franja. Si no entra, va solo el glifo, como sin nombres.
- La letra se achica si el nombre no entra en la casilla (`EstadoCasilla._fit`).
- [Captura](capturas/4j-grilla-nombres.png): guaraníes, submenú Economía.

### 5. Pantalla de fin y cuenta de sitios
- **Empate.** «Empate» y «Fin de la partida» van en `Palette.UI_NEUTRAL` (azul claro `#9fc3e6`), en la pantalla de fin y en el título del HUD.
  - `tests/test_paleta.gd` exige que se distinga de la derrota y de la victoria con las tres formas de daltonismo (ΔE 40 o más). Peor caso: 56,2 contra el dorado con tritanopía.
  - Contraste sobre la casilla: 8,04:1.
- **Sitios sin victoria.** Con los sitios sin victoria (opción de partida o tutorial), el recuadro de edad dice «Sitios 0/3 (no ganan, dan riqueza)», siempre atenuado, nunca en el dorado de «vas ganando».
- [Captura de la pantalla de empate](capturas/4j-fin-empate.png): `--tiempo=30 --sitios=no --panel=fin-tiempo`. Arriba a la derecha se ve la cuenta de sitios.

### 6. Aviso que empuja a ganar
- Es un aviso más de los que enseñan (`consejos.gd`, `_push`), y se apaga con ellos en Opciones. Los umbrales están en `interfaz.json` → `consejos.empujon`.
- **Cuándo avisa:** con 15 tropas o más, el 75 % a 22 casillas o menos de la capital y 2.000 recursos o más (sumando los cuatro), durante 90 segundos seguidos. Se repite cada 4 minutos como mucho.
- **Qué dice:**

  > Tenés ejército y recursos de sobra: atacá o subí de edad
  > Elegí tus tropas, A y clic en la base rival; o con un aldeano encargá el hito de la próxima edad (Z o X).

  En la última edad se omite lo del hito. No sale en campañas, donde manda el objetivo.
- **El título se cortaba** («…subí de eda»). Ahora un título largo achica la letra hasta 14 antes de cortarse (`avisos.gd`).
- El autotest lo prueba: suma 15 guerreros junto al centro y 2.000 de madera ([captura](capturas/4j-aviso-empujon.png)).

## Pruebas
| Prueba | Resultado |
|---|---|
| `tests/facil_sitios.gd -- --minutes=30 --seeds=7,21,3,11,5` (nueva) | [OK, 0 sitios](pruebas/4j-facil-sitios.txt) |
| `tests/test_determinism.gd` | [OK, hash 1249639671 sin cambios](pruebas/4j-determinismo.txt) |
| `tests/bench.gd` | [8,55 ms de promedio](pruebas/4j-bench.txt) (presupuesto 100) |
| `tests/opciones_partida.gd` | [OK](pruebas/4j-opciones-partida.txt) |
| `tests/tutorial_letra.gd -- --modo=letra` | [gana a las 11:06](pruebas/4j-tutorial-letra.txt) |
| `tests/tutorial_letra.gd -- --modo=indefenso` | [gana a las 14:05](pruebas/4j-tutorial-indefenso.txt) |
| `tests/campaign_smoke.gd` | [sin errores](pruebas/4j-campaign_smoke.txt) |
| `tests/civ_smoke.gd` | [sin errores](pruebas/4j-civ_smoke.txt) |
| `tests/test_paleta.gd` | OK (empate contra derrota ΔE 75,3; contra victoria 56,2) |
| Autotest `--autotest --civ=guaranies --terreno=llano` | [OK](pruebas/4j-autotest.txt), con el aviso nuevo. Al salir sigue el «corrupted size» / «double free» de siempre |

**Capturas:**
- [menú la primera vez](capturas/4j-menu-primera-vez.png);
- [grilla con nombres](capturas/4j-grilla-nombres.png);
- [empate](capturas/4j-fin-empate.png);
- [aviso que empuja a ganar](capturas/4j-aviso-empujon.png).

## Tropiezos
- **El rodeo geométrico no alcanzaba.**
  - Primero mandé a las unidades por las esquinas del cuadro del sitio. La captura bajó, pero seguía. El hondero iba a la esquina siguiendo un camino que doblaba por el terreno y cruzaba el cuadro igual.
  - Además, las órdenes del resto de la IA en el mismo turno (reagrupar, atacar) pisaban la salida.
  - La solución fue el peso en la grilla de caminos de ese jugador, más mirar las órdenes pendientes del turno.
- **Peso 10 trababa una oleada.** Con 10, en la semilla 21 el ejército quedaba quieto en formación frente al centro rival. Con 4 rodea igual y las demás semillas terminan como antes. La traba de la semilla 21 sigue: también pasa sin el peso, en la semilla 7 (ver arriba).
- **El tutorial cambió sin querer.** Los saqueadores del tutorial son una IA fácil. Con el rodeo, uno llegaba por otro lado y volvía a su base, y «abatí a los 4» no se cumplía nunca. En el tutorial los sitios no ganan, así que el rodeo ahora solo corre cuando los sitios ganan la partida.
- **La prueba del tutorial esperaba el orden viejo.** El modo indefenso empezaba a entrenar guerreros "cuando o9 está hecho", y con `despues_de` eso no llega nunca. Ahora espera a que caigan los saqueadores que pide o9. La campana se toca una sola vez: antes, la Guía cambiaba de mensaje justo al cumplirse o9 y eso la cortaba.
- **Una variable repetida en el autotest** (`k` en el mismo bloque) rompía el `main.gd` entero. El menú no arrancaba hasta corregirla.

## Consultas propuestas
1. **La fácil ataca una sola vez.** El tope de 15 soldados está por debajo de lo que pide la segunda oleada (12 + 6). Si la primera se traba, no vuelve. ¿Subimos el tope o bajamos el paso de la oleada en la fácil? Le daría al principiante un segundo ataque que rechazar, y a la fácil una forma de terminar.
2. **La captura que no se pierde.** Un sitio guarda lo que lleva de captura aunque el que lo toma se vaya, y eso suma pasadas cortas. ¿Hacemos que se vacíe de a poco sin nadie, como en AoE4? Cambia la regla para todos (y el hash), por eso no entró acá.
3. **¿Fácil sin sitios también para la IA contra IA del menú?** Hoy el valor depende de la dificultad elegida para vos.

## Commits
- `WIP 4j: la fácil rodea los sitios, menú sin sitios en Fácil, grilla con nombre común, empate neutro`
- `Merge main en la rama de 4j`
- `Jugador nuevo, ronda 3 (4j): …` (este, con el tutorial, el aviso y el documento)
