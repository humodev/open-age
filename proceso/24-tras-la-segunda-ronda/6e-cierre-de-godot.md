# 24 · Paso 6e: Godot ya no se cae al cerrar

## Pedido
Godot abortaba al cerrar el juego, con código 134 y `corrupted size vs. prev_size` o `double free or corruption`: al cerrar la ventana desde el menú, al terminar cada autotest y cada `--shot`. Venía de varias etapas atrás. Las pruebas headless, además, dejaban `N resources still in use at exit` y `ObjectDB instances were leaked`. El «AUTOTEST: OK» salía antes, pero el código de salida quedaba en error. El pedido: reproducirlo de la forma más corta, encontrar la causa, arreglarlo en el juego si es nuestro (o documentar el error del motor y salir en orden) y bajar los avisos al salir.

## Reproducción más corta
- `godot --headless --path . --quit-after 1`: abre el menú, dibuja un cuadro y sale. **134** siempre.
- Pasa igual con ventana, sin ventana, con `--audio-driver Dummy` y con `--animaciones=0`. No hace falta pasar por una partida: el menú solo alcanza (detrás del menú corre una partida IA contra IA, que es la que arma todo).
- Con un `-s` vacío (`extends SceneTree` + `quit()`) sale con 0: no es el proyecto en sí ni algo que se cargue solo.

[Salida de antes](pruebas/6e-antes.txt): las 22 corridas, código 134 (menú con y sin ventana, sin audio, sin animaciones, cerrar la ventana, `--shot`, cinco autotest).

## Cómo se buscó
1. **gdb** (`gdb -batch -ex run -ex bt --args godot --headless --path . --quit-after 60`): se cae en el hilo principal, dentro de `free()` llamado desde `main()` después del último cuadro, o sea en la limpieza de salida. El paquete de Godot (CachyOS) no trae símbolos ni los sirve debuginfod: el resto del backtrace son direcciones ([salida](pruebas/6e-gdb-backtrace.txt)). Valgrind no está instalado.
2. **El registro de errores** (`OS.add_logger`, que en 22-testers se había señalado y que ya tenía un `remove_logger` en `_exit_tree`): sin él también se cae. Descartado, como ya decía 22-testers.
3. **Bisección cortando `main.gd`** con un `return` provisorio:
   - sin `_new_game()` (menú vacío): **0**;
   - solo la `Sim`: 0; `Sim` + `WorldView`: 0;
   - hasta la cámara: 134;
   - justo antes de `Palette.es_aliado = func(...)`: **0**; justo después: **134**.
4. **Reproducción en un proyecto vacío** ([detalle](pruebas/6e-repro-motor.txt)): un script con `class_name` y `static var cb := Callable()`, y otro que le asigna una lambda antes de `quit()`. Se cae siempre con `double free or corruption`. Con un método con nombre en vez de la lambda, o vaciando la variable antes de salir, sale con 0. Una lambda que no toca `self` también se cae.

## La causa
Un error de **Godot 4.7.2** que el juego disparaba: una **variable estática que guarda una lambda** al salir. Al cerrar, GDScript libera la función de la lambda junto con el script que la definió (`main.gd`) y recién después limpia las variables estáticas de `Palette`; el destructor de la `Callable` toca memoria ya liberada.

En el juego, `main.gd → _build_scene` hacía `Palette.es_aliado = func(a, b): return a != b and not sim.enemies(a, b)` (para el modo de colores relativo y los nombres «Aliado»/«Rival»). Entró el 2026-11-14 en `951f6f4` («Muchos jugadores, pasos 3 a 5»), una hora después de que `7042a26` agregara la variable. Coincide con lo que anotó 22-testers: «la versión de ayer cierra bien; con la de hoy falla casi siempre». Desde entonces lo mencionan todas las rondas (22-testers 02, 03 y 04; rondas 2 a 5), y la ronda 4 lo dio por «dentro del motor, sin causa encontrada».

## El arreglo
- **`main.gd`**: `Palette.es_aliado` recibe un método con nombre (`_es_aliado`), no una lambda, y `_exit_tree` lo vacía si apunta a esta escena. Cualquiera de las dos cosas solas alcanza; van las dos.
- **`palette.gd`**: el comentario de `es_aliado` avisa que nunca debe guardar una lambda, con el porqué.
- No hay otra variable estática que guarde una `Callable` en `src/` ni en `tests/` (revisado con grep).

## Los avisos al salir
| Qué quedaba | Por qué | Arreglo |
|---|---|---|
| Toda la partida (miles de `SimEntity`, los `GDScript` de `src/sim/` «still in use») | Ciclos de referencias: `sim.mods.sim`, `sim.groups.sim`, `sim.ais[i].sim` y `sim.scenario.sim`. Nunca se liberaba. En el juego, además, **cada reinicio dejaba la partida anterior en memoria**. | `Sim.soltar()` corta los ciclos. `main.gd` la llama en `restart()` (a la partida vieja, un cuadro después) y en `_exit_tree`. No cambia el estado: el hash sigue igual. |
| Lo mismo en las pruebas headless (8 753 objetos en `test_determinism`, 31 238 en `jugabilidad`, 9 565 en `casillas`: [antes](pruebas/6e-avisos-pruebas-antes.txt)) | Las pruebas crean `Sim` y nunca las sueltan. | `Sim` anota cada partida en una lista de referencias débiles (`_vivas`, no las retiene; se poda cada 64) y `Sim.soltar_todas()` las suelta. Las 33 pruebas que extienden `SceneTree` la llaman en `_finalize()`. |
| Un `Skeleton3D` | El esqueleto molde de `AldeanoAnimado` vive en un diccionario estático y nunca entra al árbol: como es un nodo, nadie lo libera. | `AldeanoAnimado.soltar()` lo libera; lo llama `main.gd → _exit_tree`. |
| A veces la música y el ambiente (`AudioStreamPlaybackOggVorbis`, 8 objetos y 4 recursos) | El servidor de audio suelta una pista parada recién en su próxima mezcla, en su hilo; si el programa termina antes, quedan colgadas. | Cierre ordenado: `main.salir()` calla el audio (`GameAudio.callar()`: para todo, suelta las pistas y no deja que nada vuelva a sonar), espera 3 cuadros y 0,15 s reales y recién ahí `quit()`. Pasan por ahí cerrar la ventana (`auto_accept_quit = false` + `NOTIFICATION_WM_CLOSE_REQUEST`), los tres botones «Salir» (menú, pausa, pantalla de fin), `--shot` y el autotest. |

Queda una sola cosa: con `--quit-after N` (la salida abrupta del motor, que no pasa por `salir()`), en 3 de 8 corridas sin ventana siguen apareciendo los 8 objetos del audio. El código de salida es 0. No hay forma de esperar al hilo de audio desde ahí; el juego nunca sale así.

## Prueba nueva: `tests/cierre.gd`
Arma `main.tscn` como lo haría el juego y pide cerrar la ventana (la misma notificación que manda el sistema). El juego tiene que salir solo, con 0; si a los 600 cuadros sigue abierto, «CIERRE: FALLO» y 1.
- `godot --headless --path . -s tests/cierre.gd`: menú y cerrar.
- `… -- --menu --partidas=3`: del menú a tres partidas seguidas (`_start`, como el botón) y cerrar.
- `… -- --menu --boton`: menú y botón «Salir».

Con el código de antes, «cerrar la ventana» no salía solo (nadie llamaba a `quit()` desde el juego: lo hacía Godot) y al salir por el tope se caía igual con 134.

## Pruebas
Antes y después, con las mismas órdenes ([antes](pruebas/6e-antes.txt), [después](pruebas/6e-despues.txt)):

| Caso | Antes | Después |
|---|---|---|
| Menú con ventana, `--quit-after 120` (×3) | 134, 134, 134 | 0, 0, 0 |
| Menú headless, `--quit-after 60` (×3) | 134, 134, 134 | 0, 0, 0 (una con los 8 objetos del audio) |
| Menú headless, `--audio-driver Dummy` | 134 | 0 |
| Menú headless, `--animaciones=0` | 134 | 0 (con los 8 objetos del audio) |
| `tests/cierre.gd`, menú y cerrar la ventana (×3) | 134 (FALLO: no salía solo) | 0, 0, 0, sin avisos |
| `tests/cierre.gd`, menú + 3 partidas y cerrar | 134 | 0, sin avisos |
| `tests/cierre.gd`, botón «Salir» (×3) | — | 0, 0, 0, sin avisos |
| `--menu --shot` | 134 | 0, sin avisos ([captura](capturas/6e-menu.png)) |
| Autotest guaraníes, llano (×5) | OK y 134 las cinco | **OK y 0 las cinco**, sin avisos |

- [Determinismo](pruebas/6e-test_determinism.txt): OK, hash **2203695307**, el mismo; sin avisos al salir.
- [`tests/jugabilidad.gd`](pruebas/6e-jugabilidad.txt): OK, sin avisos (antes 31 238 objetos).
- [`tests/casillas.gd`](pruebas/6e-casillas.txt): 532 grillas, OK, sin avisos (antes 9 565).
- [Bench](pruebas/6e-bench.txt): 9,0 ms de promedio con 200 unidades (8,4–9,7 en corridas anteriores): igual.

## Tropiezos
- El aislamiento del worktree rechazaba comandos con `cd` y bucles: las corridas repetidas van en guiones del directorio temporal.
- Con `--partida` como argumento de `tests/cierre.gd`, `main.gd` lo leía como su `--partida=N` y dejaba el modo menú: se usa `--partidas=N` y `--menu` explícito.
- La primera versión de `salir()` esperaba solo 3 cuadros: sin ventana los cuadros pasan en microsegundos y el hilo de audio no llegaba a mezclar; la música seguía «still in use» en algunas corridas del botón «Salir». Se agregó la espera de 0,15 s reales.

## Para avisar a Godot
Reproducción de 3 archivos en [6e-repro-motor.txt](pruebas/6e-repro-motor.txt): una `static var` de un script con `class_name` que guarda una lambda al salir da `double free or corruption` (4.7.2, Linux). No se mandó el reporte.

## Commits
- `Etapa 24, paso 6e: Godot ya no se cae al cerrar (lambda en una variable estática) y sale en orden`.
