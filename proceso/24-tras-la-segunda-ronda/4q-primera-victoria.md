# 4q · La primera victoria del jugador nuevo

Pedido: [informe del jugador nuevo, ronda 5](../22-testers/ronda-5/02-nuevo-en-rts.md), punto grave 1 y medios 2, 3 y 4. Con un plan razonable (edad II a los 10–11 minutos, taller con 2–4 arietes y ataques de 19–29 soldados), el principiante no le tiraba ni un edificio a la IA fácil. Sus tropas caían «frente a los campos de tiro y la torre», y nada le explicaba por qué.

## 1. Por qué fallaba el ataque (con números)

Herramienta nueva: `tools/primera_victoria.gd`. Juega el plan del principiante (`novato5.gd`: ahorra en la edad I, hito a los ~8 min, taller y arietes en la II, «A y clic» en la base rival cada 20 s con 15 soldados o más y 2 arietes o más). Le arreglé un error: su script volvía a pedir el hito cada 20 s en la edad II y mandaba 4 aldeanos a una obra que no podía pagar. La herramienta anota qué mata a cada tropa propia (el último golpe, por tipo de atacante), el daño recibido, si los arietes llegan y pegan, el daño a los edificios y qué tiene la IA. Con `--detalle=1` muestra la pelea cada 10 s: cuántos están en la base rival, qué orden tienen y a qué le pegan.

**Antes** ([pruebas/4q-antes.txt](pruebas/4q-antes.txt), guaraníes contra Tawantinsuyu fácil en llano, 5 semillas, 30 min): **0 de 5**. La capital quedó siempre en 2400/2400.

Semilla 7, mirada por dentro:

| Qué | Número |
|---|---|
| Bajas propias por último golpe | **hondero 59**, lancero 11, boleador 1. **La torre, 0**; el centro, 0 |
| Daño recibido | hondero 5708, lancero 926, guerrero 77 |
| Arietes (cañones de tacuara guaraníes, 6 disparos) | lo más cerca que llegaron fue **15 casillas** de la capital; 3 perdidos (2 por honderos); 326 de daño, todo a un almacén |
| Edificios tirados | 1 almacén en 30 minutos |
| La fácil | 5 campos de tiro (*warak'a kancha*), 1 torre, 61–91 tramos de camino; ejército de 15, que sube a **32** cuando la atacan |

Qué pasa en el primer ataque (13:00, 22 soldados y 2 cañones contra 3 defensores en casa):

1. **Cuatro minutos de marcha.** La base rival queda a ~111 casillas y el grupo llega a las 16:50. Mientras tanto, la fácil se ve «amenazada» (la tropa pasa cerca de sus almacenes y caminos), su tope sube de 15 a 30 y sus 5 campos de tiro sacan honderos: tiene 26 cuando llega el ataque.
2. **La tropa le pega a los caminos y a los almacenes.** Con «A y clic», cada unidad ataca lo primero que ve. Una vez que elige un edificio, no lo suelta aunque le tiren. A las 17:00, 18 de 27 le pegaban a un almacén de madera y a las 17:10, 11 a **tramos de camino** (200 de vida, 4 de daño por golpe), mientras 26 honderos los mataban de a uno. En 40 s cayeron 18.
3. **Los cañones llegan solos y tarde** y les tiran al primer edificio de la orilla, nunca a la capital.

O sea, **los mataban los honderos, no la torre ni los campos de tiro** (los campos de tiro no disparan: entrenan a los honderos). El principiante veía morir a su tropa al lado de los campos de tiro y la torre, y por eso los culpó.

## 2. La fácil, ganable (solo la fácil)

En `reglas.json → dificultades.facil` (con su `_doc_4q`) y en `sim_ai.gd`, con claves que las demás dificultades no tienen (los valores por defecto dejan todo como estaba):

| Clave | Antes | Ahora | Por qué |
|---|---|---|---|
| `caminos` | sí | **false** | La tropa en ataque en movimiento se quedaba pegándole a los tramos |
| `torres_max` | 1 | **0** | Una defensa menos (casi no mató, pero el principiante la culpaba) |
| `productores_max` | 5 | **2** | Tenía 5 campos de tiro y rehacía 15 honderos por minuto |
| `ejercito_max_amenazada` | 30 | **20** | El tope de emergencia; el de siempre sigue en 15 |
| `campana_por_enemigo` | 3 (`ia_campana_por_enemigo`) | **1** | Menos aldeanos en el centro, menos flechas |
| `rendicion` | — | **6 edificios, 50 %** | Se rinde si perdió 6 edificios terminados (sin contar caminos) con tropa enemiga en su base, o si su capital queda en la mitad de la vida |

**La rendición** es como la de la IA de AoE4: la fácil usa la orden `resign` que ya tenía la simulación, ahora con `motivo: rendicion`. Si con eso termina la partida, `end_reason` es `rendicion`. La interfaz avisa «Rojo se rinde» y la pantalla de fin dice «Ganaste: … se rindió después de perder sus edificios con tu tropa en su base». Sin esto, el principiante tenía que derribar la capital (2400 de vida) y el hito con cañones que se rompen a los 6 disparos y le tiran a lo primero que ven.

**Después** ([pruebas/4q-despues.txt](pruebas/4q-despues.txt), mismo plan, con main integrado):

| Semilla | Resultado | Ataques | Tropa perdida |
|---|---|---|---|
| 7 | sin terminar a los 30:00 (1 edificio tirado) | 1 | 31 |
| 21 | **gana a las 19:26** (rendición) | 1 | 8 |
| 3 | **gana a las 25:08** | 1 | 17 |
| 11 | **gana a las 18:20** | 1 | 9 |
| 42 | **gana a las 26:29** | 1 | 18 |

**4 de 5 antes de los 30 minutos** (antes: 0 de 5). Antes de integrar main fueron 5 de 5 ([4q-despues-sin-main.txt](pruebas/4q-despues-sin-main.txt): 7 a las 26:29, 21 a las 20:11, 3 a las 25:11, 11 a las 20:44, 42 a las 27:20). La semilla 7 cambió con lo que trajo main: su único ataque se deshace sin que los cañones lleguen a 20 casillas, y el script del principiante no vuelve a juntar 2 cañones.

**¿Bolsa de boxeo antes de los 15?** No ([4q-apuro.txt](pruebas/4q-apuro.txt)). Un apuro sin asedio en la edad I (sale con 10 guerreros a los 8 minutos) **pierde 9–13 soldados y no tira nada** en las semillas 7, 21 y 3 hasta el minuto 15. Hasta la edad II la fácil defiende igual que antes; la torre y los productores de más llegaban recién en la II.

## 3. Resumen de la pelea (aviso que enseña)

En `consejos.gd`, un aviso nuevo (`pelea`, umbrales en `interfaz.json → consejos.pelea`). `hud.on_events` le pasa los sucesos de cada paso. Para cada tropa propia guarda quién le pegó último (unidad, edificio que dispara o edificio con guarnición) y si en ese momento le estaba pegando a un edificio. Cuenta las bajas a más de 25 casillas de la capital. Cuando pasan 12 s sin bajas, si fueron 10 o más, avisa ([captura](capturas/4q-aviso-pelea.png)):

> **Perdiste 11 soldados lejos de casa sin matar a nadie**
> Los frenaron: Arquero (6) y Wang (centro) con guarnición (5). Contra los edificios que tiran flechas (con aldeanos adentro tiran más), llevá Cañón de tacuara (Taller de tacuara) con clic derecho sobre el edificio. Contra los arqueros, llevá Guerrero de macana (Aty de guerra), que les gana. 6 le pegaban a edificios mientras los mataban: con A y clic atacan lo primero que ven; mandalos con clic derecho contra los soldados.

Todo sale de los datos: los nombres del pueblo rival (con el común para los edificios), el asedio propio y la tropa que gana a la que más mató (la función con bono en `reglas.bonos`). Con Espacio se va al lugar de la pelea. El autotest arma la pelea con sucesos como los de la simulación y verifica los tres renglones.

## 4. Media gravedad

- **«Hito · edad II» cortado:** la casilla del hito tiene una forma corta (`common_corto`: «Edad II»), que se usa cuando el común no entra a su tamaño ([captura](capturas/4q-grilla-edad-ii.png)).
- **Hoja de atajos de una pantalla** (`src/game/ui/hoja_atajos.gd`): acción nueva `atajos`, **F12** de fábrica, reasignable en Opciones → Teclas. También se abre desde la pausa («Atajos de teclado (F12)»), y Mi pueblo la nombra al principio de Controles. Tiene cuatro columnas: lo básico, elegir (con B, N y P del veterano), grupos y cámara, y paneles. Las teclas salen de `Teclas`, así que muestra lo que el jugador reasignó ([captura](capturas/4q-hoja-atajos.png)). F12 no choca en ningún perfil (test_opciones: «sin choques»).
- **Edificios que se confunden:** con **Alt** (la tecla de información, que ya mostraba alcances y barras), cada edificio a la vista muestra flotando su ícono de la grilla sobre el techo: los propios en dorado, los ajenos en el color de su dueño (`mundo_capa.gd`). No toqué las mallas ni `arte_edades.json`, así que el aspecto por edad sigue igual. No hay captura con Alt apretado: el modo de capturas no puede mantener la tecla.

## Pruebas

| Prueba | Resultado |
|---|---|
| `tests/test_determinism.gd` | **hash 2203695307, el mismo** antes y después ([4q-determinismo.txt](pruebas/4q-determinismo.txt)) |
| `tests/bench.gd` | 8,74 ms de promedio (máquina cargada con un torneo de 9 procesos) |
| autotest guaraníes/llano | **OK, 112 chequeos**, con los 3 nuevos de la pelea y 2 de la hoja de atajos ([4q-autotest.txt](pruebas/4q-autotest.txt)) |
| `tests/test_opciones.gd` | OK, sin choques de teclas |
| `tests/facil_sitios.gd` | OK, 0 sitios tomados |
| `tests/tutorial_letra.gd` | letra: victoria 11:16; indefenso: victoria 14:06 |
| `tests/civ_smoke.gd` | corre (la normal no cambia) |
| `tools/primera_victoria.gd` | 0/5 → 4/5 (5/5 sin main) |

## Tropiezos

- El primer intento de la rendición pedía también que el ejército de la fácil fuera chico (≤ 12). Nunca se cumplía, porque la fácil amenazada se queda en su tope de 20. Quedó solo «perdió edificios y hay enemigos en su base».
- Godot no vuelca la salida de `print` a un archivo hasta que termina; con el torneo corriendo, cada medida de 5 semillas tardó 15–25 min.

## Para el autor

- **La causa de fondo no es de la fácil.** En ataque en movimiento, una unidad que eligió un edificio no lo suelta aunque le tiren, y los tramos de camino inca se pueden atacar. Las dos cosas pasan en todas las dificultades. Arreglarlas (que la unidad responda a quien le pega y que los caminos no sean blanco, como en AoE4) cambiaría el hash y cómo juegan normal, difícil y experta. Lo dejo como propuesta.
- La rendición vale para cualquier IA en fácil, también en un escenario que la use (el tutorial pasa igual en los dos modos). Con equipos, `end_reason` queda en `rendicion` únicamente si con eso termina la partida.

## Commits

- `7740cff` 4q: la primera victoria contra la fácil…
- merge de main (veterano ronda 5) y el último commit de esta etapa (B, N y P en la hoja, autotest de la hoja, documento)
