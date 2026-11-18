# 30.1 · Frente 1: producción que se maneja sola

Pedido: la fila del frente 1 del [plan](README.md), con los puntos C1, C4, C11 y C12 del constructor y V3, V6, V7 y V16 del veterano.

## Qué entró

| Cambio | Cómo se usa | Dónde |
|---|---|---|
| **Repetición automática** (C1) | **Ctrl + clic** (o Ctrl + tecla) en la casilla de la unidad la prende o la apaga en los edificios elegidos de ese tipo. Cuando la cola se vacía, entra otra si alcanza **sin tocar lo apartado** (`reserva_<recurso>`) y hay lugar de población. La casilla lleva un borde y un bucle, y la cola global también muestra el bucle. | `sim.gd`: comandos `repetir` y `tope_aldeanos`, `repeat_block` y `_repeat_try`. `SimEntity.repeat` |
| **Tope de aldeanos** | Con aldeanos, el panel del edificio dice «Repite: Ava · hasta 80 aldeanos» y tiene los botones − y +. Cuentan los vivos y los que están en cola. | `data/reglas.json → repeticion` (80 de fábrica, entre 10 y 200, de a 5) |
| **Cola de 10** (V7, C12) | `cola_max` pasa de 5 a 10. El panel muestra cinco casillas, y la quinta dice «+n» (un clic saca la última). | `data/reglas.json`, `hud.gd` |
| **Sacar de la cola** (V6) | **Clic derecho** en la casilla saca una, y **Mayús + clic derecho** saca 5. Salen de atrás para adelante, del edificio elegido que tenga más de esa unidad. | `controller.sacar_de_cola`, grilla de `hud.gd` |
| **Parados a la vista** (V3, C11) | Después de 10 s sin cola, el edificio de producción aparece al final de la cola global, gris y con un borde que late. Con algo parado 45 s sale un consejo, como mucho uno cada 2 minutos, que respeta «Avisos que enseñan». **Clic derecho en un ícono gris** apaga el consejo, y queda guardado en las opciones. | `ui/cola_global.gd`, `data/interfaz.json → produccion`, `Opciones.aviso_parados` |
| **Aviso anticipado de población** (C4) | Con lo que hay en las colas y lo que se repite, calcula cuánto falta para quedarse sin lugar. Con 40 s o menos, avisa una vez: «Población 17/18: sin lugar en ~35 s». El número se pone ámbar, y la ayuda de la población dice el tiempo. | `hud.segundos_sin_lugar`, `_check_pop_pronto` |
| **Ingreso por minuto** (V16) | Al pasar el mouse por un recurso de la barra, se ve «Ingreso: +N por minuto (últimos 60 s) · n aldeanos». Es el mismo dato que el panel F2. | `TopBar` de `hud.gd` |

La IA no usa la repetición, porque ya encola por su cuenta. La repetición es un comando, así que la respetan las repeticiones de partidas y la red.

## Pruebas (`pruebas/01-*.txt`)

- **Determinismo:** OK, con el hash **2203695307**, igual que antes. Sin repetición prendida no cambia nada. La IA encola hasta dos por edificio, así que tampoco la afecta la cola de 10.
- **Bench:** 9,76 ms de promedio (antes, 9,35 ms).
- **Casillas** (540 grillas) y **grilla:** OK.
- **Autotest** (guaraníes, llano): 161 OK y AUTOTEST: OK. Las pruebas nuevas, en `src/game/autotest_produccion.gd`, cubren estos casos:
  - Ctrl + clic la prende, queda grabada y encola sola;
  - con todo apartado se frena;
  - llega al tope y no lo pasa (10 de 10);
  - Ctrl + clic la apaga;
  - la cola llega a 10;
  - el clic derecho saca una y Mayús + clic derecho saca 5;
  - avisa «sin lugar en ~35 s»;
  - el centro parado sale gris y el cuartel que repite lleva el bucle;
  - el consejo se apaga y se prende;
  - la ayuda del recurso muestra el ingreso.

## Capturas

- [01-cola-global.png](capturas/01-cola-global.png): arriba, el cuartel que repite (con el bucle) y el centro parado (gris, con el borde ámbar), junto al aviso anticipado de población.
- [01-repite.png](capturas/01-repite.png): la casilla Q con el borde y el bucle, y el panel con «Repite: Ava · hasta 80 aldeanos» y los botones − y +.
- [01-cola10.png](capturas/01-cola10.png): la cola de 10, con la quinta casilla en «+6».

## Tropiezos

- La primera versión del bucle de la casilla pisaba el nombre de la unidad. Lo pasé abajo de la pastilla «×n».
- Para no chocar con los otros frentes, las pruebas nuevas van en un archivo aparte. `main.gd` solo suma una línea.
- `opciones.gd` suma la opción `aviso_parados`, con su carga y su guardado (cuatro líneas).
