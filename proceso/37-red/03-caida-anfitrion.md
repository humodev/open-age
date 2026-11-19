# 37 · 3 · Caída del anfitrión y fugas al salir

## Pedido

1. **Fuga al salir de una campaña.** `Sim.soltar()` no cortaba `comercio.sim`. Había que cortar ese ciclo y cualquier otro parecido. Prueba: `tests/cierre.gd` con `--partidas=3` y misiones de campaña, sin objetos ni recursos vivos al salir.
2. **Caída del anfitrión en red.** El invitado espera N segundos. Si el anfitrión vuelve, se re-sincroniza por foto. Si no vuelve, el invitado puede seguir contra la IA (que toma al jugador caído) o guardar y salir. Hay un caso nuevo en `tests/red.gd`.

## Qué entró

| Archivo | Qué hace |
|---|---|
| `src/sim/sim.gd` (`soltar`, línea `# --- soltar ---`) | Corta `comercio.sim` |
| `src/net/sim_red.gd` | `soltar()` corta también el ciclo `SimRed.red` ↔ `Lockstep.sim` |
| `src/net/sesion_red.gd` | `_exit_tree` cierra el transporte (el par ENet y sus señales apuntaban al transporte) y suelta la partida. Además: la caída del anfitrión (abajo) |
| `src/net/transporte.gd` | No atiende un par que ya se desconectó (antes tiraba «multiplayer instance isn't currently active» en cada cuadro) |
| `src/net/validar.gd` | El `log` de `retomar` se valida como el de `turnos`: ahora lo recibe también el anfitrión |
| `data/red.json` | `caida_anfitrion_s` (20) e `ia_toma_dificultad` («normal») |
| `tests/cierre.gd` | `--campana=clave`: las partidas son las misiones 0, 1, 2… de esa campaña |
| `tests/red.gd` | Casos `anfitrion_vuelve` y `anfitrion_no_vuelve` |

## Cómo funciona la caída del anfitrión

- El invitado que pierde al anfitrión sigue reintentando cada `reintento_s`. Ya no da la partida por terminada a los `reconexion_s`: el anfitrión sí.
- Su partida queda parada en el último turno completo. Hasta ahí, las dos máquinas tienen el mismo estado. Esa es «la última foto» de la que se parte.
- A los `caida_anfitrion_s` segundos aparecen dos botones, en la capa del rótulo de la sesión, sin tocar `main.gd`:
  - **Seguir contra la IA** (`seguir_con_ia`). Agrega una `SimAI` por cada jugador caído que no tenga una y mete en su turno lo propio que ya se había mandado y no se jugó. Lo juntado entra ahora. Después cierra la sesión: `SimRed` deja pasar los comandos y `main.gd` sigue sin red.
  - **Guardar y salir** (`guardar_y_salir`). Copia la partida a un `Sim` común (la foto sin la red y con el guion de `Sim`), le agrega la IA de los caídos y guarda en `user://partidas/red-<fecha>.json`. Después cierra y vuelve al menú.
- **El anfitrión vuelve de cero** y abre una sala en el mismo puerto. El invitado se reconecta y recibe `sala` en plena partida. Entonces le manda `retomar` con su foto, lo suyo de después y sus hashes. El anfitrión, que está en la sala, arranca la partida con esa foto, igual que el invitado que vuelve de cero (`adjuntar` y `volcar_foto`). Vale la partida del invitado: lo que el anfitrión jugó y no llegó a mandar se pierde.
- Si el anfitrión nunca se cayó del todo (un corte corto), sigue como antes: le manda los turnos que le faltan al invitado.

## Pruebas

| Prueba | Resultado |
|---|---|
| `tests/cierre.gd -- --menu --partidas=3 --campana=guaranies --verbose` | Antes: 10 781 instancias y 12 recursos vivos. Ahora: ninguno, sale con 0 |
| `tests/cierre.gd -- --menu --partidas=3` | Sin fugas |
| `tests/red.gd` (8 casos) | OK. Cada invitado dejaba unas 2300 instancias y 14 recursos vivos al salir. Ahora no deja ninguno |
| `anfitrion_vuelve` | El anfitrión se cae en el tick 300 y vuelve en 1,5 s. Sigue desde la foto del invitado (tick 302). Hash igual en el 900 |
| `anfitrion_no_vuelve` | El invitado espera 3 s y guarda. El guardado se carga con el mismo tick y el mismo hash. La IA toma al anfitrión en el tick 302 y entrena 3 unidades hasta el 900 |
| `tests/test_determinism.gd` | OK, hash 3059812827 (el de siempre) |
| `tests/guardado.gd` | OK |

## Tropiezos y pendientes

- La foto de un `SimRed` no se carga en un `Sim`: la raíz es de otro guion y `SimEstado` intenta crearla con `new()`, lo que tira el programa. Tampoco se carga si la partida armada tiene otras IA. Por eso guardar arma una copia en un `Sim` común con las mismas IA y después agrega las de los caídos.
- **Pendiente en `main.gd`, que no es de esta etapa:** al cargar un guardado del invitado, `local` sale de los argumentos de `--cargar` y queda en 0. Falta releer `red_jugador` después de restaurar `_args` en `_cargar`. El guardado ya lo lleva en `args`. Mientras tanto, se carga con el jugador del anfitrión en manos del humano.
- Un anfitrión con la sala abierta acepta el `retomar` de cualquier invitado que llegue con una foto. No hay una opción «retomar» en el menú del anfitrión.
- Los botones no se probaron con ventana; no hay captura.
