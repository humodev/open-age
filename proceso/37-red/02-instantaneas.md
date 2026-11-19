# 37 · 2 · Instantáneas del estado

## Pedido

1. Una foto completa y determinista de `Sim` en un tick, en binario comprimido, que al cargarla deje la partida idéntica.
2. Guardar la foto con los comandos, cargar en segundos sin re-simular desde el principio y que el autoguardado la use.
3. En las repeticiones, una foto cada N minutos para saltar rápido.
4. En red: la reconexión manda la foto, el retardo de entrada sigue al ping y se validan los mensajes entrantes.

Antes, cargar re-simulaba todo: unos 145 ticks por segundo en 2v2 (proceso/30-fluidez/07).

## Qué entró

| Archivo | Qué hace |
|---|---|
| `src/sim/sim_estado.gd` (`SimEstado`, nuevo) | `tomar(sim)` devuelve la foto (`var_to_bytes` con zstd y una cabecera «FOTO», versión y tamaño). `cargar(sim, bytes)` la vuelca y compara el hash |
| `src/game/guardado.gd` | Cada guardado lleva al lado un `.foto` con la foto de su tick y las periódicas. `armar(d, hasta)` vuelca la foto más cercana a `hasta` que no se pase y vuelve a programar los comandos grabados después de ella. `foto_periodica(sim)` saca una foto cada `fotos_cada_min`. `borrar` y `podar` también borran el `.foto` |
| `src/game/main.gd` (líneas `# --- instantaneas ---`) | La carga y el salto en la repetición usan `armar(d, hasta)`. La foto periódica se saca antes del autoguardado, así el autoguardado la reusa. El invitado de red que vuelve vuelca la foto antes de armar la vista |
| `src/net/sesion_red.gd` | Reconexión con foto, ping y pong, retardo adaptable y validación |
| `src/net/lockstep.gd` | `ajustar_retardo`, `desde_foto`, y `registro` y `hashes_de` desde un turno o un tick |
| `src/net/validar.gd` (`RedValidar`, nuevo) | Valida tipos y topes de cada mensaje y de cada comando |
| `src/net/transporte.gd` | Descarta los paquetes de más de `max_bytes` y lo que no es un diccionario |
| `data/interfaz.json` | `guardado.fotos_cada_min` (5) |
| `data/red.json` | Ping, rango del retardo (2 a 10 turnos), margen y `validacion` |

### La foto

- **Por reflexión.** Se recorre el grafo de objetos desde `Sim` con las variables de cada guión. Un campo nuevo entra solo, sin tocar `SimEstado`. Las entidades se leen de una vez con `inst_to_dict`, y solo se recorren sus campos compuestos.
- **Identidad.** Cada objeto de `src/sim/` va una sola vez a una tabla, y las referencias se escriben como `Vector4i(1, índice)` (la simulación no usa `Vector4i`). La misma entidad en `entities`, `by_id`, `_owned`, `_grid`, las colas de la IA o los proyectiles vuelve como un solo objeto.
- **Lo que no es estado.** `SimData`, la telemetría y el `Lockstep` de `SimRed` se toman de la partida armada. El `def` de una entidad, si es el mismo diccionario de los datos (`is_same`), se guarda como referencia (jugador, tabla, tipo). Si es una copia propia (los mercados con nombre, la presa sin carne), se guarda el contenido.
- **Grillas de caminos.** Las `AStarGrid2D`, la de cada jugador y la de las canoas, se guardan con sus casillas sólidas y sus pesos distintos de 1.
- **Arreglos tipados.** Llevan su tipo (y su guión) para volver tipados.
- **Cargar.** Primero se arma la misma partida en el tick 0, como antes, y después se vuelca la foto. Los objetos únicos (mapa, niebla, mods, grupos, comercio, azar, IA, escenario) se reusan por guión y orden de aparición. Las entidades se crean de nuevo. Al final se compara el hash guardado en la foto.

### Guardado y repeticiones

- Partida guardada: un `.json` como antes (sin la foto, así la lista sigue leyendo rápido) y un `.foto` con `{tick, foto, fotos}`. Los guardados viejos, sin `.foto`, cargan como antes.
- Repetición: lleva las fotos periódicas y la del final. Saltar en la línea de tiempo vuelca la foto anterior más cercana y re-simula solo desde ahí, como mucho 5 minutos.
- Los comandos que llegaron después de la foto se vuelven a programar desde la grabación. La foto trae lo grabado hasta su tick, y lo que sigue sale de `comandos[recording.size():]`.

### Red

- **Reconexión.** El `hola` del invitado dice hasta qué turno tiene la partida (−1 si volvió de cero). Si volvió de cero, el anfitrión manda la foto de su tick, el último turno inyectado, las pausas usadas y solo los turnos y hashes de después. El invitado arma la partida, vuelca la foto y sigue sin re-simular. Si solo se cortó un rato, recibe los turnos que le faltan.
- **Retardo según el ping.** Cada 500 ms va un `ping` y vuelve un `pong`. Cada 2 s el retardo pasa a ⌈(peor de los últimos 8 / 2 + 60 ms) / ms por turno⌉, entre 2 y 10 turnos. Cada jugador tiene el suyo: los turnos llevan su número, así que las dos máquinas inyectan lo mismo.
  - Subir el retardo llena los turnos del medio con mensajes vacíos.
  - Bajarlo deja lo juntado para el primer turno sin mandar. Antes, `_cerrar` vaciaba ese búfer, porque creía que era una re-simulación. Ahora solo lo vacía si el turno vino de afuera.
- **Validación.** Todo mensaje pasa por `RedValidar.motivo`, que revisa:
  - que el tipo sea conocido y cada campo tenga su tipo, sin campos de más;
  - que nadie mande turnos ni hashes a nombre del jugador local;
  - los topes: hasta 100 comandos por turno y 24 claves por comando, textos de hasta 64 caracteres, listas de hasta 2000 elementos y anidado de 2 niveles;
  - que las coordenadas e ids sean enteros.

  Lo que no pasa se descarta y se cuenta. El transporte descarta los paquetes de más de 16 MB y los que no son un diccionario.

## Pruebas

### Cargar un 4v4 en el minuto 30

`tests/carga_4v4.gd -- --minutos=30`: 8 IA difíciles en llano, 18 000 ticks, 5913 entidades (1626 activas). Salida en [pruebas/02-carga_4v4.txt](pruebas/02-carga_4v4.txt).

| | Tiempo | Hash |
|---|---|---|
| **Antes** (armar y re-simular desde el tick 0) | **805,7 s** (22 ticks/s) | igual |
| **Después** (armar y volcar la foto) | **1,6 s** | igual |
| Saltar al minuto 15 de la repetición (foto del 10 + 5 min re-simulados) | 16,6 s | — |
| Guardar (reusa la foto periódica del mismo tick) | 32 ms; `.foto` de 2,5 MB con 6 fotos | — |

### Pruebas

| Prueba | Resultado |
|---|---|
| `tests/guardado.gd`: foto en T y mismo hash en T+600 con y sin la foto, más la foto final byte a byte | OK en 1v1 (min 3), 2v2 (min 5), 4v4 (min 4) y Etiopía 1 (min 2). La foto pesa de 57 a 144 KB, tarda de 150 a 440 ms y carga en 0,4 a 1,1 s |
| `tests/guardado.gd`: por archivo, 1v1 de 7 min | Carga en el tick 4200 en 0,56 s. El salto al 6 sale de la foto del 5 y llega al mismo hash. OK |
| `tests/guardado.gd`: casos viejos (re-simular) | OK, los mismos hashes de la etapa 30 |
| `tests/red.gd` | 6 casos OK ([pruebas/02-red.txt](pruebas/02-red.txt)). Detalle abajo |
| `tests/test_determinism.gd` | OK, hash 3059812827 (el de siempre) |
| `tests/test_replay.gd` | OK |
| `tests/bench.gd` | Promedio 14,65 ms, peor 102 ms (sin cambios en `step`) |
| Autotest con Etiopía en llano | `AUTOTEST: OK`, con un control nuevo: cargar con la foto llega al mismo tick y hash. En una de tres corridas falló «fluidez 4: la veta chica» (`autotest_avisos`), que corre antes y no depende de esto |

Los casos de `tests/red.gd`:

- **reconexión:** el invitado se cae en el tick 300 y vuelve de cero. Recupera la partida en el tick 302 con la foto, en 232 ms, sin re-simular. Hashes iguales en el 900.
- **ping:** con 250 ms más hasta 50 ms de vaivén por mensaje, el retardo de entrada sube a 4 turnos.
- **latencia y directo:** el retardo baja a 2 turnos.
- **basura:** el invitado manda 8 mensajes rotos. El anfitrión descarta 6 mensajes y 2 paquetes, y la partida sigue con los mismos hashes.
- **desincronización:** sigue detectándose en el tick 150.

## Commits

- `5eef54d` Instantáneas del estado (SimEstado) y guardado con foto
- `491f8d7` Red: reconexión con la foto, retardo según el ping y validación de lo que llega
- `887a3f9` Autotest fluidez 6: también cargar con la foto
- (este) Retardo de arranque fijo para los turnos vacíos, ping sin el pico más alto, documento y pruebas

## Tropiezos y pendientes

- La foto se saca entre dos pasos y lleva unos 0,2 a 0,5 s en 4v4. El autoguardado ya tardaba eso, pero ahora la foto periódica también. Si molesta, puede sacarse en un hilo sobre una copia.
- Las partidas de campaña ya perdían objetos al salir antes de este cambio (pruebas sin foto: 1853 instancias de una misión). `Sim.soltar()` no corta `comercio.sim`. Quedó sin tocar porque es de `sim.gd`.
- `autotest_avisos` (fluidez 4, la veta chica) falló una de tres corridas con Etiopía. Corre antes del guardado y no lo toca esta tanda.
- En `tests/red.gd` el ping marca picos de 1 a 2 s. Cada instancia da 200 pasos por cuadro y contesta el `ping` recién al cuadro siguiente. Por eso se descarta el pico más alto de cada ventana, y el retardo vuelve a bajar a los 2 a 4 s. En el juego los cuadros son cortos.
- Al subir el retardo, `completo()` daba por vacíos los turnos menores que el retardo nuevo y el lockstep leía un mensaje que no estaba (error en el caso de latencia). Ahora usa el retardo de arranque (`D0`).
- Saltar dentro de una repetición todavía re-simula hasta 5 minutos (16 s en un 4v4 tardío). Con fotos cada 1 o 2 minutos bajaría, a costa de más memoria (unos 400 KB por foto en ese 4v4).
- El anfitrión que se cae sigue sin recuperarse. Ahora alcanza con guardar la foto en disco y dejar que cualquiera retome, pero falta hacerlo.
