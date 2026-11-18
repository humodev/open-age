# Autotest en los seis pueblos

Pedido: que `godot --path . -- --autotest --civ=<x> --terreno=llano` dé OK en tawantinsuyu, mapuches, guaraníes, etiopía, palmares y ayutthaya. Venían fallando guaraníes (frente 2, casas con Mayús) y Palmares (frente 1, producción).

## Fallas, causa y arreglo

Todas eran de las comprobaciones, no del juego. No se tocó `src/sim`: del juego solo cambia `alertas.gd`, que ahora guarda un registro de sus avisos de recurso.

| Falla | Causa | Arreglo |
|---|---|---|
| Fluidez 2: «los tres cimientos están puestos», «dos obras en la cola», «orden puesto» (guaraníes; también salió en mapuches y Palmares) | Dos causas. **(a)** La cámara miraba un punto fijo y, con el giro que dejan las pruebas anteriores, una casa quedaba en el borde de abajo, bajo el panel: el clic no llegaba al mundo (por eso, «dos obras en la cola» fallaba). **(b)** El último cimiento sale en el próximo paso de la simulación, y la comprobación esperaba solo 4 cuadros: a veces el paso no había llegado (`puestas [id, id, -1]`). | La cámara se centra en cada lugar antes del clic, como haría el jugador. Después de colocar, se esperan dos pasos de la simulación (`sim.tick`) en vez de 4 cuadros. |
| Producción: «hay un centro que entrena aldeanos» (Palmares) | Palmares no entrena aldeanos: su centro entrena exploradores. | La prueba usa el aldeano si el centro lo entrena y, si no, lo primero de su `produce`. La reserva usa el primer recurso del costo de esa unidad. El tope de aldeanos se prueba solo si la unidad es civil; si no, el registro lo dice. |
| Fluidez 2: puerta con G, hueco marcado y puerta puesta (Palmares, intermitente) | `main._screen()` proyectaba la casilla a altura 0, pero el cursor busca el suelo a su altura (`RtsCamera.ground_at`). Donde el llano tiene relieve, un extremo del trazo caía una fila corrido y el muro salía en diagonal. | `_screen()` proyecta sobre `WorldView.height_at()`. Sirve a todas las pruebas que hacen clic en el mundo. |
| Fluidez 4: «la veta chica avisa que se agota (2)» (guaraníes, intermitente) | Al limpiar el seguimiento, el aviso de recursos de los otros aldeanos (en guaraníes, el monte se ralea) salía en la misma revisión que el de la veta, y se contaba junto. | Una revisión antes de mandar al aldeano absorbe los avisos ajenos, y se cuentan solo los avisos con lugar en la veta. `alertas.gd` guarda los últimos 16 avisos de recurso en `avisos_recurso`, porque la lista visible tiene 4 lugares y no sirve para contar. |
| Fluidez 2: muro en el Tawantinsuyu («12 de mita», G no marca, «la puerta quedó: camino») | La prueba tomaba el primer edificio `linea`, y en el Tawantinsuyu es el Qhapaq Ñan: un camino, no un muro. El Tawantinsuyu no levanta muros, y Ayutthaya tampoco tiene la empalizada en su `construye`: la prueba ponía una que el jugador no puede construir. | El muro tiene que ser `linea`, no `transitable` y estar en el `construye` del aldeano. Si el pueblo no tiene muro, la prueba se saltea y lo dice en el registro (el almacén usa el árbol más cercano). |
| Cursor de mover sobre el suelo y destello del arbusto (Palmares, intermitente) | El lugar «vacío» era una casilla fija (base −6, +10), que en ese mapa caía en un árbol. El arbusto más cercano tenía un aldeano encima, y el clic tomaba al aldeano. | `main._suelo_libre()` busca cerca una casilla sin nada (mapa libre y `pick` vacío); la usan las dos pruebas. El destello usa el arbusto más cercano que `pick` toma como arbusto. |
| Aviso anticipado de población: «~-1 s» (mapuches y Tawantinsuyu, intermitente) | La HUD recalcula `pob_eta` cada 5 pasos de la simulación (30 cuadros a velocidad 1), y la prueba esperaba 30 cuadros: justo en el límite. Además, el lugar sin el extra se calculaba restándolo del tope, que puede estar recortado por `pob_max`. | Se esperan hasta 120 cuadros, y el lugar sin el extra se suma de los edificios. |
| «Aviso de aldeanos sin trabajo» (Palmares, intermitente: «0 de 6 quietos») | El alto se daba y se esperaban 6 cuadros: menos que un paso de la simulación (100 ms). Los aldeanos seguían trabajando. | Se frenan todos los aldeanos de ese momento y se esperan dos pasos de la simulación. El mensaje dice cuántos están quietos y qué avisos hay. |

## Pruebas

- Autotest (`--terreno=llano`), dos rondas seguidas con todo arreglado: **OK en los seis pueblos** las dos veces. Tawantinsuyu: 200 controles; mapuches: 208; guaraníes: 208; Etiopía: 209; Palmares: 207; Ayutthaya: 197. El Tawantinsuyu y Ayutthaya tienen menos porque saltean el muro.
- `tests/test_determinism.gd`: OK, hash **2903543624** (el mismo).

## Para mirar en el juego (no se tocó)

- Con un aldeano parado sobre un arbusto, el clic derecho en el arbusto toma al aldeano (`Controller.pick` da prioridad a las unidades).
- La simulación deja poner una empalizada a Ayutthaya, aunque no está en su `construye` (no la tiene en la grilla).
- G marca puerta también en un trazo de camino (`marcar_puerta` no mira si la línea es un muro).

## Commits

- «Autotest: OK en los seis pueblos» (este documento).
