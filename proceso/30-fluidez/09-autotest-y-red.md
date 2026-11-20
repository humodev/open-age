# Autotest de fluidez 5 y dos pendientes de la red

Pedido: que el autotest (`--autotest --terreno=llano`) pase en los seis pueblos, porque con mapuches fallaban tres controles de fluidez 5, y cerrar dos pendientes de `proceso/37-red/03-caida-anfitrion.md`.

## Autotest

| Falla | Causa | Arreglo |
|---|---|---|
| Fluidez 5: «patrulla de 3 puntos con Mayús» (ronda de 3), «clic derecho en una unidad propia la escolta» y «el escolta va con la patrulla» (mapuches) | Una sola causa. Los tres puntos se buscaban con la cámara fija en la tropa, y `main._suelo_libre` no miraba la interfaz. Si el primer punto caía bajo la interfaz, el clic no llegaba al mundo y la ronda quedaba de 3. Por la misma razón tampoco entraba el clic derecho que salía del modo, así que el clic derecho del escolta solo cancelaba el modo patrullar. No era un error del juego. En esta máquina no se reprodujo: con mapuches pasó antes y después del arreglo. | `autotest_fluidez5._suelo`: la cámara se centra en cada punto, como haría el jugador, y busca una casilla libre que el cursor no tome, fuera de la interfaz y con camino desde la tropa (A* de la grilla, sin el caché de `find_path`, para no tocar la simulación). `main._suelo_libre` ahora descarta los puntos bajo la interfaz o en el borde de la ventana. El líder del escolta es uno de la patrulla que `pick` toma a él y no a otro de los que van juntos. |
| Fluidez 2: «el muro dice tramos, costo…» (Tawantinsuyu) | Ahora el Tawantinsuyu levanta un muro de piedra, y la prueba exigía «madera». | La prueba acepta cualquier recurso del costo del muro de ese pueblo. |
| Fluidez 4: «la veta chica avisa que se agota (0 de 0)» (Tawantinsuyu, de a ratos) | `alertas._queda` suma toda la piedra de la zona. La veta de prueba caía cerca de otra piedra, así que no bajaba del umbral ni se acababa. | `_lugar_libre` puede pedir un lugar sin otro recurso de esa clase dentro del radio de `_queda`. |

## Red

- **El jugador al cargar el guardado del invitado.** `main._cargar` vuelve a leer `red_jugador` después de restaurar `_args` desde el guardado (marca `# --- red ---`). El invitado vuelve a ser el jugador 1.
- **El `retomar` lleva un identificador.** `empezar_partida` le pone a los args un `red_partida`. Al arrancar, el anfitrión lo guarda en `user://red/retomable.json` con su jugador, y al abrir la sala lo vuelve a leer. El `retomar` del invitado lleva `partida` y `caido`, que es el jugador del anfitrión. El anfitrión solo lo acepta si coinciden la partida, que también tiene que estar en los args, y el jugador caído. Si no coinciden, lo descarta y lo cuenta en `rechazados`. `validar.gd` admite los dos campos nuevos y pone un tope al largo del identificador.
- Caso nuevo `retomar_ajeno` en `tests/red.gd`: no usa cliente. Le manda cuatro `retomar` ajenos al anfitrión: otra partida, otro jugador caído, uno sin identificador y uno con los args de otra partida. Los cuatro se descartan y la sala sigue abierta. El `retomar` de su partida sí se acepta.

## Pruebas

- Autotest, uno por vez, todo **OK**: Tawantinsuyu, mapuches, guaraníes, Etiopía, Palmares y Ayutthaya.
- `tests/red.gd`: los 9 casos OK (`anfitrion_vuelve` sigue pasando con el identificador).
- `tests/guardado.gd`: OK.
- `tests/test_determinism.gd`: OK, con el mismo hash **3059812827**.

## Tropiezo

- `--check-only -s` no mostró un error de tipos (`var lejos :=` con un valor sin tipo) en un script que carga `main.gd`. Recién se vio al correr el autotest, que quedó colgado.

## Commits

- «Autotest fluidez 5: puntos de patrulla y escolta en suelo libre y alcanzable; red: local al cargar y retomar con identificador»
- «Autotest: muro de piedra del Tawantinsuyu y veta de prueba lejos de otra piedra; documento»
