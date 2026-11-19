# Etapa 37 · Multijugador en red (prototipo H5)

## Pedido

Prototipo de 1 contra 1 en LAN o por IP: lockstep determinista con `ENetMultiplayerPeer`, verificación de sincronía por hash, sala «Red» en el menú, pausa limitada (3 de 60 s por jugador) y reconexión básica (60 s de espera y re-simulación). Sin tocar `src/sim/`.

## Qué entró

| Archivo | Qué hace |
|---|---|
| `data/red.json` | Puerto, ticks por turno (1), retardo de entrada (3 turnos = 300 ms), hash cada 50 ticks, pausas, esperas y tiempos de ENet |
| `src/net/sim_red.gd` | `SimRed extends Sim`: solo pisa `push_command`. Los comandos de un jugador de la red no entran directo: los propios van al lockstep, los del rival se descartan (llegan por la red) |
| `src/net/lockstep.gd` | Turnos, retardo de entrada, inyección en orden de jugador, hashes, pausas, registro para reconectar. No sabe de red |
| `src/net/transporte.gd` | ENet para dos, mensajes como diccionarios confiables. `latencia_ms` y `vaiven_ms` simulan una red lenta |
| `src/net/sesion_red.gd` | La sesión bajo `/root`: sala, arranque, ganchos del bucle de `main`, pausa, reconexión y el rótulo de estado («Esperando al rival…», «Pausa de Rojo: 42 s», «Desincronización en el tick N») |
| `src/net/sala.gd` | La pantalla «Red»: crear (puerto) o unirse (IP y puerto), pueblo, color y listo de cada uno, mapa, semilla y condiciones de victoria del anfitrión, «Empezar» |
| `src/game/main.gd`, `menu.gd` | Cambios marcados `# --- red ---`: botón «Red», jugador local 1 para el invitado, `SimRed` en red, sin IA para el rival humano, el bucle pide permiso al lockstep antes de cada tick, Esc pide una pausa de red, sin cambio de velocidad en red |
| `tests/red.gd` | Dos instancias sin ventana en 127.0.0.1 |

El controlador no se tocó: todo comando de la interfaz pasa por `sim.push_command`, y `SimRed` lo desvía. El gancho de una línea quedó innecesario.

### Cómo funciona

- Un turno es un tick (100 ms). Al empezar el turno *n*, cada máquina cierra lo que juntó y lo manda como sus comandos del turno *n + 3*. El turno *n* se ejecuta solo con los mensajes de los dos (los turnos 0 a 2 están vacíos). Los comandos se inyectan con `Sim.schedule` en el primer tick del turno, primero los del jugador 0 y después los del 1, y se anotan en `sim.recording` (la repetición de la partida queda completa).
- Cada 50 ticks las dos máquinas mandan `state_hash()`. Si difieren, la partida se detiene con «Desincronización en el tick N».
- La pausa viaja dentro del mensaje de turno, así las dos la cuentan igual (3 por jugador). Cualquiera la levanta con Esc; si no, termina sola a los 60 s.
- Si el invitado se cae, el anfitrión espera 60 s. El invitado reintenta solo cada 2 s. Si volvió de cero (cerró el juego), entra por «Red → Unirse» y el anfitrión le manda los argumentos de la partida, todos los turnos jugados y sus hashes. El invitado arma la partida y la re-simula a 120 ticks por cuadro hasta el turno actual. Los hashes viejos del anfitrión validan esa re-simulación.

## Pruebas

| Prueba | Resultado |
|---|---|
| `tests/red.gd` caso directo: 3 min (1800 ticks), IA de los dos lados por la red, pausa del anfitrión en el tick 300 | OK, hash 2982043249 en los dos, 33 y 36 comandos por la red |
| caso latencia: 1 min con 80 ms más hasta 40 ms de vaivén por mensaje | OK, hash 1426406523 |
| caso reconexión: el invitado se cae en el tick 300, vuelve de cero y re-simula | OK, hash 4208062880 al tick 900 |
| caso desincronización: el invitado se suma 7 de madera en el tick 120 | Los dos la detectan en el tick 150 |
| `tests/test_determinism.gd` | OK, hash 3059812827 (el de la etapa 34: `src/sim` sin cambios) |
| `tests/test_replay.gd` | OK |
| Autotest con guaraníes en llano | `AUTOTEST: OK`, 221 controles OK y ninguno fallido |
| Dos ventanas del juego por la sala, 1 min | Hashes iguales hasta el tick 600 |

Salida de `tests/red.gd`: `red.txt`. Capturas: `sala.png` (la sala del anfitrión con el invitado unido), `anfitrion.png` y `cliente.png` (cada uno en su base), `un-jugador.png` (el modo de un jugador, igual que antes).

En la prueba, cada máquina corre las dos IA dentro de su simulación, pero `SimRed` deja pasar solo los comandos del jugador local: los del rival se descartan y llegan por la red, con su turno. Así la IA juega como dos humanos en red.

## Cómo probarlo a mano entre dos PC

1. Las dos con el mismo commit (el lockstep exige el mismo código, los mismos `data/` y la misma versión de Godot; ver A-009).
2. En la PC anfitriona: Menú → **Red** → Puerto (47800 por defecto) → **Crear sala**. Abrir ese puerto **UDP** en el firewall (`sudo ufw allow 47800/udp`, o el equivalente).
3. Averiguar su IP en la LAN (`ip -4 addr`, por ejemplo 192.168.0.10).
4. En la otra: Menú → **Red** → IP 192.168.0.10, puerto 47800 → **Unirse**.
5. Cada uno elige pueblo y color y marca **Listo**. El anfitrión elige mapa, semilla y condiciones, y aprieta **Empezar**.
6. Para probar la reconexión: cerrar el juego del invitado en plena partida, abrirlo y unirse de nuevo antes de 60 s.

Sin tocar nada, desde la línea de comandos (dos instancias en la misma PC):

```
godot --path . -- --menu --abrir=red --red-crear=47800 --red-civ=guaranies --red-terreno=llano --red-listo=1
godot --path . -- --menu --abrir=red --red-unirse=127.0.0.1:47800 --red-civ=mapuches --red-color=1 --red-listo=1
```

`--red-salir-a=MIN`, `--red-shot=archivo.png` y `--red-shot-at=S` pasan a la partida. Al cerrar, cada instancia imprime `RED: jugador N · tick T · hashes iguales hasta el tick H`.

## Qué falta para jugarlo por internet

- **NAT**: hoy el anfitrión necesita el puerto UDP abierto o redirigido en su router. Faltan: perforación de NAT (ENet no la trae; hay que hacer el intercambio de direcciones con un servidor de encuentro y mandar paquetes desde los dos lados a la vez) y un **relevo** (TURN o un servidor propio que reenvíe) para los NAT simétricos.
- **Servidor de partidas**: un lugar donde publicar salas y encontrarlas (hoy se pasa la IP a mano), con identidad de jugador y versión del juego. Debe rechazar a quien tenga otro commit o otros `data/`. Hoy eso no se verifica: una versión distinta termina en «Desincronización».
- **Latencia variable**: el retardo de entrada es fijo (300 ms). Por internet conviene ajustarlo según el ping medido y sincronizar el reloj de los dos, para que el más rápido no quede esperando a tirones.
- **Caída del anfitrión**: solo se recupera la del invitado. Si se cae el anfitrión, se pierde la partida. Hay que guardar el registro en disco y dejar que cualquiera retome.
- **Re-simulación larga**: volver a una partida de 30 min re-simula unos 18 000 ticks a 120 por cuadro (decenas de segundos). Faltan instantáneas del estado, que dependen del guardado que otro agente está agregando.
- **Seguridad**: los mensajes no se validan (un cliente modificado puede mandar comandos de más) ni se cifran. El comando lleva el jugador que lo envía, y `Lockstep` lo pisa con el emisor, pero no hay más control.
- **Interfaz**: la pausa usa el menú de Esc (abrir el menú gasta una pausa). Faltan chat, rendición, aviso de que el otro se fue y el ping en pantalla.
- **Más jugadores**: el lockstep ya acepta N jugadores, pero la sala y la sesión son de dos.
- **A-009**: `AStarGrid2D` entre plataformas distintas (Linux contra Windows) sigue sin medirse. Probar una partida mixta es el primer paso con dos PC.

## Tropiezos

- La primera prueba con dos ventanas no conectaba: el anfitrión tarda en cargar el menú, y el invitado abandonaba a los 5 s. Ahora espera `espera_conexion_s` (15 s).
- El invitado se caía (señal 11) al cortarse la sala: `ENetMultiplayerPeer.close()` dentro de la señal `peer_disconnected`, o sea, dentro de `poll()`. El transporte ahora difiere el cierre hasta que termina `poll()`.
- El mapa elegido por línea de comandos no llegaba: `elegir()` refrescaba la pantalla con las opciones de la sesión antes de mandar las propias.
- `--shot` y `--salir-a` en la línea de comandos valían también para la partida de fondo del menú. Para la partida en red se pasan con el prefijo `red-`.

## Commits

- `7222b93` lockstep por ENet (src/net), sesión con reconexión y tests/red.gd
- `79bec12` sala «Red» en el menú y lockstep en el bucle de main
- siguiente: cierre de ENet fuera de poll, argumentos `red-`, capturas, caso de pausa y este documento
