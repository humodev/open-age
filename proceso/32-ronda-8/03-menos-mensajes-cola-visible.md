# Ronda 8 · 03: menos mensajes, cola global siempre a la vista

> Pedido (decisión del autor, ronda 8): «En lugar de avisos con prioridad y agrupados, iría hacia
> algo más AoE: ver siempre la cola de producción, y verla en rojo, trabada, cuando estás al máximo.
> Creo que el juego tiene demasiados mensajes de que no estás gastando y esas cosas; el usuario
> debería darse cuenta solo.» Solo interfaz: `src/sim` no se tocó.

## Qué cambió
1. **Cola global siempre a la vista** (`src/game/ui/cola_global.gd`), con casillas de 38 px en vez de 44:
   - muestra todos los edificios de producción, no solo los que producen o los parados hace 10 s;
   - **roja con candado** si no puede seguir: población llena para lo primero de la cola, o la
     repetición frenada por población o por recursos. El motivo sale en la ayuda («Trabada:
     población llena (18/18). Construí casas (Oga).», «…no alcanza para otro X (faltan N de Y)»);
   - **gris** si está quieta; el borde late después de `parado_s`, como en el frente 1.
2. **Consejos de aprendizaje** (Opciones → Ayuda): `Tutorial y fácil` (de fábrica), `Siempre` o
   `Nunca`. Con «Tutorial y fácil» se prenden solo en la campaña del tutorial o cuando todos los
   rivales son IA fácil. Reemplaza al interruptor «Avisos que enseñan»; se guarda como `ayuda/aprendizaje`.
3. **La ficha de la maravilla dice qué hito pide o impide** y si ya está hecho: «Pide el hito
   Pueblo de misión… Todavía no lo levantaste» y «Con el hito Pacto de Cucaú no se puede levantar…».
4. Medición: `--contar-avisos=MIN` (con `--aivai`) cuenta lo que vería un humano en el lugar del
   jugador 0, y `--aprendizaje=auto|si|no` fuerza la opción sin guardarla.

## Inventario de mensajes
| Mensaje | Origen | Ahora |
|---|---|---|
| «Población llena», cada 10 s y por cada edificio trabado | sim (`notify`) | **Se va**: la casilla roja y el contador de población |
| «Población llena (N/N) · Construí casas» | `hud._check_pop` | Aprendizaje |
| «Población N/N: hay más gente que lugar» | `hud._check_pop` | Aprendizaje |
| «Población N/N: sin lugar en ~N s» | `hud._check_pop_pronto` | Aprendizaje |
| «N edificios de producción sin producir» | `cola_global` | Aprendizaje (ya lo era); queda el gris |
| «Estás juntando X que no gastás» | `consejos._floating` | Aprendizaje |
| «N aldeanos sin trabajo» | `consejos._idle` | Aprendizaje; queda el contador de ociosos de la barra |
| «Se acabaron los frutos cerca del centro» | `consejos._bushes` | Aprendizaje |
| «Tenés ejército y recursos de sobra: atacá…» | `consejos._push` | Aprendizaje |
| «Construí un almacén cerca» (aldeanos que caminan lejos) | `consejos._far` | Aprendizaje |
| «Perdiste N soldados lejos de casa…» | `consejos._fight` | Aprendizaje |
| «Se agota / Se acabó X acá» | `alertas` | Aprendizaje (texto y sonido) |
| «Granja vacía / N granjas vacías» | `alertas` | Aprendizaje; quedan la marca y el botón «Llenar granjas» |
| «Atacan a tu aliado (Rojo)» de la sim | `hud` («alert») | **Se va**: ya la daba la alerta por zona «Atacan a Rojo · junto a…» |
| Ataques por zona y tipo, «¡Nos atacan!», campana | `alertas`, `hud` | Quedan (con lugar y Espacio) |
| «X tiene todos los sitios sagrados: perdés en M:SS» | `consejos._sites` | Queda siempre: es una amenaza, no un consejo |
| Sitio tomado, edad propia y ajena, investigación terminada | `hud` | Quedan |
| Aliado que pide ayuda o avisa («Rojo: «¡Me atacan!»»), pedidos y tributos | `hud` | Quedan |
| Maravilla: obra, terminada, cae, sitiada, inundación | `hud._wonder_notice` | Quedan |
| Objetivos, rendición, diálogos de campaña | `hud` | Quedan |
| Respuestas a una orden («Recursos insuficientes», «No se puede construir ahí», «Cola llena», «No hay aldeanos inactivos»…) | sim, controlador | Quedan: contestan a lo que hizo el jugador |

## Mensajes en 15 minutos, antes y después
Medidos con `--aivai --recursos=altos --terreno=llano --seed=7 --speed=32 --contar-avisos=15`. La partida es la misma (el jugador 0 llega a 68/95 y a 87/95 en las dos).

| Partida | Antes | Después (aprendizaje apagado, de fábrica) | Después con aprendizaje |
|---|---|---|---|
| A: 1 contra 3 (guaraníes, todos contra todos) | **96** | **38** | 80 |
| B: 2 contra 2 (guaraníes y Palmares contra mapuches y Etiopía) | **130** | **62** | — |

- En A se fueron 16 «Población llena», 18 «Estás juntando…», 18 de población del HUD, 2 de recursos que se agotan, 1 de granja, 1 de frutos y 1 de parados.
- En B, además, 24 «Atacan a tu aliado (Rojo)» repetidos.
- Los 10 y 5 «Recursos insuficientes» que quedan son rechazos de las órdenes de la IA que juega en tu lugar: una persona los ve solo cuando hace clic.
- El caso del veterano (292 «Población llena» con 200/200) desaparece entero: ese aviso de la simulación ya no se muestra.

## Pruebas
- `tests/test_determinism.gd`: DETERMINISMO OK, hash 2903543624, sin cambios.
- `tests/casillas.gd`: 540 grillas, OK.
- Autotest guaraníes: OK, 211 comprobaciones. Autotest Palmares: OK, 210. Hay cuatro nuevas:
  - el centro queda trabado en la cola global con la población llena;
  - sin aprendizaje no sale «Población llena»;
  - la ficha de la maravilla nombra el hito, en guaraníes y en Palmares.
- Captura de la cola trabada, mirada: `capturas/03-cola-trabada.png`. Muestra el centro en rojo con el candado, «3» en cola y la ayuda con el motivo.

## Tropiezos
- La comprobación «cuando se acaba, avisa con lugar» de `autotest_avisos.gd` ya fallaba en main con Palmares, y a veces con guaraníes: el aldeano se iba y la veta no se acababa en 1200 cuadros. Ahora se lo vuelve a mandar y se acelera la partida.
- `/tmp` se llenó por copias de otros agentes en el scratchpad compartido. La copia de main para comparar se hizo dentro del worktree y después se borró.

## Commits
- `da1cef1` Ronda 8: menos mensajes, cola global siempre a la vista y en rojo si está trabada.
- El siguiente: las pruebas del autotest y este documento.
