# Frente 5 · Selección, órdenes y lectura

Pedido: la fila del frente 5 en [README.md](README.md) (V11, V12, V13, V14, V15, V17 y V24 del [veterano de la ronda 7](../22-testers/ronda-7/03-veterano-fluidez.md), §4.3, §4.5, §4.6, §6.2, §7.2, §7.4 y §8). El ataque al suelo (V22) ya estaba (esport 1a): no se tocó.

## Qué entró

- **Ctrl + clic** (`controller._left_release`): elige a todos los de ese tipo que se ven en pantalla, igual que el doble clic pero sin la ventana de 350 ms. Con Ctrl + Mayús se suman a lo elegido.
- **Mayús + mantener posición**: entra en la cola de órdenes del cliente (`mundo_cola`, paso `mantener`). La unidad termina el movimiento y después mantiene. Sin Mayús, vacía la cola y mantiene ya, como antes.
- **Patrulla de varios puntos**: en el modo patrullar, cada clic con Mayús suma un punto y el modo sigue abierto. El primer clic arma la patrulla y los siguientes mandan `patrullar` con `sumar`. La unidad recorre la ronda (salida → p1 → p2 → … → salida) atacando lo que ve. Cada unidad conserva su lugar en el reparto: el punto nuevo se corre lo mismo que su punto anterior respecto del centro del grupo. Con dos puntos sigue la ida y vuelta de siempre.
- **Seguir o escoltar**: el clic derecho sobre una unidad propia que no está elegida manda `escoltar`. La orden nueva `FOLLOW` se queda a `escolta_distancia` del protegido y rehace el camino cada `escolta_rehace_ticks`. El militar pelea con lo que llegue a `escolta_correa` del protegido y vuelve a su lado si muere el blanco o la pelea lo aleja. Cualquier otra orden la corta. Hay dos excepciones que siguen siendo `target`: la canoa con lugar (subir) y la máquina que los aldeanos pueden reparar.
- **Fondo por función en los retratos** del panel de varias unidades (`hud.SelectionPanel`): civil verde, a pie rojo, montado ámbar y asedio (y canoa) azul acero. El borde queda en el color del jugador. Vale para los dos modos: uno por unidad y uno por tipo.
- **Números de daño apagables**: interruptor «Números de daño» en Opciones → Teclas, al lado de «Grupos exclusivos». Se guarda en `opciones.cfg`. El perfil «aoe4» los apaga (`data/interfaz.json` → `perfiles.aoe4.numeros_danio: false`) y el de fábrica los prende.
- **Ficha compacta**: muestra el nombre, la función, lo que impide el clic, la barra, el costo, dos líneas de «Ahora» y el pie «Mayús o Alt: ficha completa». Mide 320 px en vez de 392. Con Mayús o Alt apretado se ve entera, y las fichas fijadas para capturas (`--ficha=`) también salen enteras.
- **Hoja de atajos**: dice «el botón del medio la arrastra; rueda: acercar y alejar», sin «girar». También suma Ctrl + clic, la escolta con clic derecho, Mayús + mantener y la patrulla de varios puntos.

Los números de la simulación están en `data/reglas.json` → `ordenes`: `patrulla_max_puntos` 8, `escolta_distancia` 1800, `escolta_rehace_ticks` 10 y `escolta_correa` 7000.

## Archivos

`src/sim/sim.gd` (comandos `patrullar` con `sumar` y `escoltar`, `_do_escort`, la vuelta del escolta en `_do_attack`, el hash), `src/sim/sim_entity.gd` (`FOLLOW`, `pat_pts`, `pat_i` y `esc`), `src/game/controller.gd` (marcado `# --- fluidez 5 ---`), `src/game/ui/mundo_cola.gd` (paso `mantener`), `src/game/hud.gd` (retratos), `src/game/ui/ficha.gd`, `src/game/ui/hoja_atajos.gd`, `src/game/ui/teclas.gd`, `src/game/ui/opciones.gd`, `src/game/ui/mundo_capa.gd` (una condición), `src/game/autotest_fluidez5.gd` y una línea en `main.gd`.

## Pruebas

- `tests/test_determinism.gd`: **OK, mismo hash (3059812827)**. La partida de prueba no usa estas órdenes. El hash solo suma `pat_pts` cuando hay más de dos puntos y `esc` cuando hay escolta.
- `tests/ordenes.gd`: OK, con tres comprobaciones nuevas: patrulla de 3 puntos (pasa por todos y vuelve a la salida), escolta (sigue hasta el destino, pelea con el que se acerca y vuelve a seguir) y «detener» corta la escolta.
- `tests/casillas.gd`: OK (600 grillas).
- Autotest guaraníes en llano (`autotest_fluidez5.gd`, con clics y teclas de verdad): Ctrl + clic, patrulla de 3 puntos con Mayús, escolta con clic derecho, Mayús + mantener en la cola, perfil «aoe4» sin números de daño, ficha compacta, hoja sin «girar» y retratos por función. Los 9 pasos dan OK. Capturas: [retratos por función](capturas/06-retratos.jpg) y [escolta con la patrulla](capturas/06-escolta.jpg).
- `tests/bench.gd`: promedio de 25,6 ms y peor de 186 ms, con la máquina cargada (carga 33, seis Godot de otros agentes). La corrida de referencia daba 9,2 y 58. El bench no usa estas órdenes, así que hay que repetirlo con la máquina libre.
- Al principio, una corrida del autotest completo falló en `autotest_fluidez2` (`vs[3]`) y en el empujón de `main.gd` (sin capital), por la carga. Las corridas siguientes no lo repitieron.

## Pendiente

- La simulación cambió: hay que confirmarla en el torneo conjunto de los frentes 1, 2 y 5.
- El cursor sobre una unidad propia sigue siendo «mover». Falta un cursor de «seguir».
