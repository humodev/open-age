# 36 · 02 · Lo que pidió el jugador nuevo (ronda 9)

> Pedido: los tres puntos principales de [ronda 9, jugador nuevo](../22-testers/ronda-9/02-nuevo.md)
> (mensajes que se pisan en el tutorial, «¿Cómo se usa?» que no parece un botón, índice de la Guía)
> y la tecla G, que servía para dos cosas. Solo interfaz: `src/sim` no se tocó.

## Qué cambió

1. **Los consejos esperan a la Guía.**
   - `hud.guia_ocupada()` es verdadero mientras la Guía habla o tiene mensajes en espera.
   - En el tutorial también lo es mientras haya un paso abierto: un objetivo principal activo que no sea de tipo *proteger*. Las misiones que entran en esta regla están en `interfaz.json → guia.calla_consejos_misiones`.
   - Mientras tanto, `consejos.gd` se calla, salvo la cuenta de los sitios, que es una amenaza. También se calla el aviso «edificio sin producir» de la cola, que era el que tapaba a la Guía en la captura 1.
2. **El cuadro de la Guía se corre.**
   - Va arriba, como antes. Si ahí tapa unidades propias, baja hasta quedar encima del panel de la selección.
   - Solo cambia de lugar si del otro lado tapa menos, así no salta con cada paso de un aldeano.
3. **«¿Cómo se usa?» es un botón.**
   - Tiene marco dorado, un «?» en un círculo y su tecla en una casilla. Es la acción nueva `como_se_usa`, con **U** de fábrica.
   - La Guía abierta ya no queda centrada sobre el panel. Se ubica entre la barra de arriba y el panel de la selección, así el botón queda visible.
   - **Índice:** muestra solo las lecciones del pueblo del jugador, agrupadas por edad («Edad I», «Edad II»…). Los datos nuevos son `edad` y `requiere` en `data/lecciones.json`.
   - Los guaraníes ven 10 lecciones, sin la muralla. Etiopía ve las 11.
   - **La G:** la puerta del muro pasa a la acción `puerta_muro`, con **Y** de fábrica, que se puede reasignar.
   - La lección de muralla usa el marcador nuevo `{tecla:puerta_muro}`. La ayuda que aparece al arrastrar el muro también toma la tecla de `teclas.gd`.
   - La G queda solo para la Guía. El «G: lección …» de los consejos sale de la tecla real.
4. **Avisos.**
   - Los sobrantes salen en un solo aviso, ordenado por lo que más se pasa: «Te sobra: alimento 1200, riqueza 640». Debajo va el consejo del recurso que más sobra y, desde la II, el del mercado.
   - El autoguardado ya no es un mensaje. Es un disquete chico en la esquina del reloj, que se apaga en 3 s.

## Pruebas

- `tests/lecciones.gd`: OK. Se agregaron cuatro comprobaciones: el índice va por edad, la muralla sale solo para los pueblos que la tienen, la puerta tiene una tecla propia que la lección nombra, y las teclas nuevas no chocan con otras.
- `tests/tutorial_letra.gd`: OK. Se gana siguiendo el texto en 11:34, igual que antes.
- `tests/test_determinism.gd`: DETERMINISMO OK. El hash no cambia porque `src/sim` no se tocó.
- Autotest con guaraníes (`--autotest --civ=guaranies --terreno=llano`): AUTOTEST OK.
- Captura: [la Guía con el índice guaraní y el botón debajo](capturas/r9-guia-indice.jpg).

## Tropiezos

- La G de la puerta estaba fija en el controlador (`KEY_G`), fuera de `teclas.gd`. Los autotests de muralla y fluidez 2 ahora piden la tecla a `Teclas`.
