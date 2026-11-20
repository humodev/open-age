# Ronda 9 · Veterano competitivo de AoE4

> Probé lo que entró desde la ronda 8: las órdenes nuevas, la cola, la repetición, el muro, la muralla, el comercio, el asedio, el guardado, las repeticiones y el arte nuevo. Usé el autotest, sondas propias, tres capturas y un 1v1 de 30 minutos contra la difícil. Guiones y salidas: `scratchpad/testers/veterano9/`.

## Cómo lo medí

| Prueba | Resultado |
|---|---|
| Autotest con Etiopía en llano (ventana) | **OK**: 256 comprobaciones en 2:40 |
| `sonda.gd` (propia): asedio quieto o moviéndose, suelo, patrulla de 3 puntos, escolta, muralla | Abajo |
| `tests/comercio.gd` | **OK**: el corte por tropa, el corte por muralla, el retome y los bonos de pueblo |
| `tests/guardado.gd` | **OK**: hash igual al cargar (1v1, 2v2, campaña). La foto carga un 4v4 en 1,7 s |
| 1v1 por guion, guaraníes contra Etiopía difícil, 30 min, semilla 11 | Perdí por sitios a los 28:24 |
| Capturas | `capturas/veterano-asedio.jpg`, `veterano-min2.jpg`, `veterano-min15.jpg` |

## Qué anda bien

- **Ctrl + clic, en sus dos sentidos.** En el mundo elige el tipo en pantalla (7 guerreros), y con Ctrl + Mayús suma. En la grilla prende la repetición. Son contextos distintos y no se pisan.
- **Patrulla de varios puntos.** En la sonda, 3 lanceros con tres clics recorren la ronda de cuatro puntos. Pasan por los cuatro cuadrantes a los 6, 21 y 39 s y vuelven. El modo queda abierto con Mayús, como corresponde.
- **Escolta con clic derecho en una unidad propia.** Sigue y pelea: los 3 lanceros mataron a los 2 guerreros que atacaron al aldeano.
- **Mayús + mantener entra en la cola de órdenes.** Es lo que pedí en la ronda 7.
- **Ficha compacta.** Muestra lo justo, y con Mayús o Alt se ve la completa.
- **Repetición de producción.** Respeta el tope (10 de 10) y se frena sola sin recursos. La cola de 10 y el clic derecho para sacar también andan.
- **Muro con costo y huecos.** Dice «6 tramos · 60 de madera · alcanzan 6» y avisa el hueco por un árbol antes de soltar. Para un muro rápido en la puerta del rush, es oro.
- **Muralla de piedra.** Etiopía la pone sobre una empalizada en la II: cuesta 20 de piedra, se levanta en menos de 30 s y la reemplaza. En la I no deja. Los guaraníes no la tienen; es diseño de pueblo y está bien.
- **Comercio.** El cursor sobre un mercado neutral muestra la ganancia («81 casillas / ~110 de riqueza por viaje»). Hay punto de paso con Mayús y el botón «Rutas» en el minimapa. El aviso de comerciantes atacados sale una vez por ruta. El bloqueo funciona con tropa y con muralla. Es el primer motivo real para pelear el mapa en el medio.
- **Ataque al suelo.** La catapulta etíope tira al punto: 92 de daño a los enemigos y 0 a mis aldeanos, que pasaban por ahí.
- **Guardar y cargar.** Mismo hash al cargar. Que la foto cargue un 4v4 en 1,7 s es muy bueno.
- **Avisos.** «¡Nos atacan! ×6 Espacio» se lee al toque. La cola global arriba en el centro se ve siempre, aun en la captura del minuto 15 a ×8.
- **Base linda.** La tierra pisada alrededor del centro, los tocones y las granjas con surcos se ven bien. La base se lee de un vistazo (captura del minuto 15).

## Qué está roto

1. **El asedio casi no se esquiva.** Con la catapulta etíope durante 60 s contra 5 aldeanos, los quietos reciben 250 de daño y los que se mueven de costado sin parar, 213: un 15 % menos. Con un vuelo de 8 ticks y un radio de una casilla, al aldeano no le alcanza el tiempo para salir. En AoE4, un buen split contra el mangonel te salva casi todo. Hoy esquivar no paga, y la mecánica se nota solo en el papel. Hay que probarlo con caballería, pero contra la infantería no rinde.
2. **El juego no compiló un momento después de un merge.** Hoy, a las 23:2x, `RedRelevo` no estaba en la caché de clases y `--replay` cayó con «Could not find type RedRelevo». Se arregló solo cuando otro proceso reimportó. Un jugador que baja el repo y lanza sin abrir el editor puede comérselo. Habría que sumar un `--import` al guion de arranque o a la prueba.
3. **La cola global para un edificio parado está en gris, no en rojo.** El autotest dice «el centro parado aparece gris». Según `cola_global.gd`, el rojo es solo para «trabado» y el gris para «quieto». Para mí, el centro sin producir aldeanos es el error número uno y tiene que gritar, no quedar gris. Ver C-pedido 1.
4. **Las partidas con `--shot` y `--aivai` no dejaron repetición.** La última de `user://repeticiones` es de las 20:47. No sé si es a propósito; si «se guardan solas al salir», deberían estar.

## El 1v1 contra la difícil (guion, 30 min)

| Min | Yo (guaraníes) | IA difícil (Etiopía) |
|---|---|---|
| 5 | 22 aldeanos, edad I | 22 aldeanos, edad I |
| 10 | 21 ald., II a los 7:15, 1 militar | 33 ald., II a los 5:28, 14 militares |
| 15 | 44 ald., 14 militares, ataco | III a los 14:35, 23 militares |
| 20 | 28 ald. (me barrió), 6.957 de madera parada | 57 ald., 30 militares |
| 25 | 30 ald., 4 militares | IV a los 22:51, 35 militares |
| 28:24 | **Pierdo por sitios** | Gana |

- La IA difícil ya juega de verdad: II a los 5:28, IV a los 22:51, 5 comerciantes con 18 ventas, 27 granjas y torres. No gasta en aldeanos a lo loco (56 contra mis 864 intentos encolados) y siempre tiene ejército.
- Mi guion es viejo: se queda sin comida (granja recién a los 16:22) y deja la riqueza quieta 1.270 s. Es culpa del guion, no del juego. Igual sirve como dato: **con 2.000 de riqueza parada el juego no me empujó al mercado.**
- Ganar por sitios a los 28 min contra alguien que no los disputa está bien. Lo que falta es que el jugador **vea venir** la cuenta. En la captura del minuto 15 dice «Sitios 1/3», pero no cuánto le falta al rival.

## Qué falta, por gravedad

**Alta**
1. **El edificio de producción parado, en rojo y con sonido** (al menos el centro), no en gris. Es lo que más partidas define en el rango medio.
2. **Que esquivar el asedio pague:** más vuelo (12 a 14 ticks), un borde más chico o una marca en el suelo del impacto, para que el split dé. Medirlo con la sonda: hoy salva el 15 %, y la meta es un 50 % o más.
3. **Una cuenta regresiva de sitios visible para los dos**, con un aviso a 2 minutos y a 1 minuto del final.

**Media**
4. Un cursor de «seguir o escoltar» sobre la unidad propia. Sigue siendo «mover», como ya anota `06-seleccion-y-ordenes.md`.
5. Un aviso de recursos parados («2.000 de riqueza sin usar: mercado o tropa»). El contador está en la barra, pero nadie lo mira en una pelea.
6. Revisar la escolta: va 4 casillas atrás del protegido y el aldeano murió igual. La distancia de escolta podría ser de 2 casillas.
7. Asegurar la importación de clases después de un merge, en el arranque o en la prueba de humo.

**Baja**
8. Sin fuego amigo del asedio de área, el suelo no tiene riesgo. AoE4 sí lo tiene. Es para decidir en balance (consulta).
9. La IA difícil tiene 3 aldeanos ociosos en el minuto 15 (captura): a esa altura no debería tenerlos.
10. No pude probar a mano el modo foto (O) ni la línea de tiempo con una repetición larga: no había ninguna reciente guardada. El autotest tampoco recorre una carga en partida. Quedan para la próxima ronda.

## Nota

De 5,5 a **6,5 sobre 10** en competitivo. Lo que más sumó fue el comercio con bloqueo, la muralla y las órdenes finas. Lo que más resta es que el asedio no se esquive y que el parado no grite.
