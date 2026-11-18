# Ronda 8 · Veterano de AoE4 contra varias IA (1v3, 1v6)

**Pedido:** poner al experto contra más IA para que llegue al final del juego y encuentre mejoras al diseño.
**Cómo jugué:** con un guion de jugador sobre la simulación (`Sim` + `SimAI`, igual que la partida a medida: `civs`, `equipos` [0,1,1…], `tamano: grande`, terreno llano, mapa de 216). Aldeanos con **repetición y tope** (95), hito apenas alcanza, almacenes junto al recurso, casas con **Mayús** (cimientos pagos con `ids: []`), **muro arrastrado** (`build_line`), torres, fortaleza, segundo centro, **repetición** en los cuarteles, **ráfagas de cola de 10**, toda la herrería, los niveles, la escuela y lo propio, mercado, asedio de área (catapultas), maravilla, defensa con campana y ataque en movimiento. El guion está en el scratchpad (`testers/veterano-1vN/jugador.gd`), no en el repo.
Las capturas son de partidas reales con `--preset`/`--jugadores --aivai --speed=16 --shot-at` (la captura no se puede sacar de una partida del guion).

## Partidas

| # | Partida | Pueblo | Resultado |
|---|---|---|---|
| A | 1v3 **difíciles**, semilla 7 | guaraníes | Muerto a los **10:32** y, con el guion mejorado, a los **11:26**. Ellos en la II a los 5:56, 7:21 y 9:33; a los 11 min tenían 14 + 26 + 17 = **57 soldados** contra mis 13. |
| B | 1v6 **normales**, semilla 11 | mapuches | Muerto a los **11:59**. A los 11 min los seis sumaban **109 soldados**. |
| C | 1v6 **fáciles**, semilla 11 | mapuches | Muerto a los **26:25** y, con muro y torres, a los **20:19**. Las seis fáciles tienen tope de 15 soldados y el primer ataque a los 15:00: llegan **juntas, unos 90**, entre los minutos 15 y 18. |
| D | 1v3 fáciles, semilla 7 | guaraníes | Llegué al minuto 58 y gané contra Palmares (54'), pero **quedé trabado en la III**: la piedra se quedó en 378 durante 30 min y el hito de la IV pide 400. |
| E | 1v3 fáciles, semilla 7 | mapuches | III a los 21:43. Mi **anillo de empalizada** (con hueco de 3) **encerró a 87 aldeanos**: 95 000 aldeano-segundos ociosos y la riqueza en 0. Nunca llegué a la IV. |
| F | 1v3 fáciles, semilla 7 (con mercado) | guaraníes | **IV a los 36:28.** Gané por conquista a los 58:47. Sin maravilla: elegí la `maravilla_monte`, que pide el hito «monte», y yo había hecho «misión». |
| G | Como F, eligiendo la maravilla que se puede hacer | guaraníes | IV a los 36:28. **Maravilla puesta a los 37:29 y terminada a los 58:20** (21 min, con hasta 10 constructores). Gané por rendición a los 59:17, antes de que corriera la cuenta. |

**Llegué a la IV y jugué el final solo en 1v3 contra fáciles.** Contra 3 difíciles, 6 normales o 6 fáciles no pasé del minuto 26. Una parte es mi guion: las IA subían a la II 4 o 5 minutos antes que yo, y un humano bueno defiende mejor. Pero la diferencia de ejército (57 contra 13 y 90 contra 20) no la cubre ningún micro.

## Capturas (`capturas/veterano/`)
- `1v6-normal-min10.png`: 1v6 normales, minuto 10. Ayutthaya (P0, IA) tiene 13 de población y ya la están atacando («Atacan tu wat mahathat»); «Sitios 0/8»; 32 sucesos nuevos. Las bases de los siete entran en el minimapa, pero las unidades casi no se ven.
- `1v3-dificil-min10.png`: 1v3 difíciles, minuto 10:30, todavía en la I y con 20/40. Hay **tres avisos apilados**, dos repetidos («3 granjas vacías» y «Granja vacía»), más «Atacan a tus aldeanos». El minimapa muestra los tres colores rivales encima.

## Qué se siente bien
- **El final existe y tiene peso.** En la IV compré hachas_3, riego_3 y cestas_2, cinco de las seis de la escuela (reparar, registros, choque, asedio y pólvora), ataque y armadura 3, los cinco élite, élite_asedio, la imprenta (propia) y reparación rápida: **61 compras en la partida**, con un orden de prioridades que se nota.
- **La maravilla depende del camino:** la guaraní sale de la misión y la del monte, del hito «monte». Es una decisión de la II que pesa en la IV. Me gustó, pero hay que decirlo en la interfaz (ver «Qué falta»).
- **La repetición con tope de aldeanos** anduvo sola los 60 minutos: 95 aldeanos y cero centros parados. La **cola de 10** responde «Cola llena» cuando corresponde.
- **El mercado como válvula:** con 88 a 897 canjes me salvó la IV (piedra comprada con la riqueza que sobraba).
- **Las IA en equipo se coordinan** (tributos, pedidos, frases en el chat) y la rendición de las fáciles cierra bien: 28', 43' y 59'.
- **El 1v3 entra en el mapa grande** y las bases quedan bien repartidas.

## Qué se rompe
1. **Rendimiento con 7 jugadores** (la simulación sola, sin dibujar; un tick dura 100 ms):
   - 1v3: de 2 ms por tick al principio a 17-20 ms desde el minuto 25.
   - 1v6 normales: **27 ms por tick a los 10-11 min**, con 568 entidades.
   - Peor tick: **102 a 132 ms**, más que el tick entero. Eso se ve como tirones, y a ×4 el juego ya no da abasto.
   - Lo que más crece es lo que está cerca de la pelea (los sucesos `hit`: 35 000 por partida).
2. **«Población llena» satura:** **292 avisos en 15 minutos** con 200/200. Cada edificio con repetición avisa cada 10 s (`sim.gd:2356`, `(tick+b.id)%100`). Debería ser uno por jugador y solo cuando cambia.
3. **«No se puede construir ahí»** salió 66 a 101 veces. Gran parte fueron los cimientos encolados con Mayús o los tramos del muro sobre casillas ocupadas. No avisa cuál falló.
4. **Pathing:** mi anillo de empalizada con un hueco de 3 casillas encerró a 87 aldeanos (partida E). El hueco quedó tapado por un edificio y **nadie avisa que hay aldeanos encerrados**: se quedan ociosos sin más. Además, un ejército de 100 tardó **más de 6 minutos** (51:00 a 57:45) en tirar un almacén de P2: lo sospecho trabado o dando vueltas (no lo verifiqué a fondo).
5. **La IA enemiga no escalona:** las 3 o 6 IA del mismo equipo tienen el mismo reloj (`primer_ataque_ticks`, `ataque_espera_ticks`) y **llegan juntas al único rival**. Con fáciles son 6 × 15 = 90 soldados a los 15-17 min, que es un nivel de experta, no de fácil.
6. **Las fáciles no prueban el final:** con `edad_max: 2` nunca levantan maravilla, así que no pude probar el **contrajuego contra la maravilla enemiga**. Mientras la mía estuvo 21 min en obra, nadie la atacó.
7. **Minimapa:** con un mapa de 216 en 230 px, las unidades son puntos de un píxel. Se ven las bases, pero no hacia dónde va la ola.

## Qué falta en el diseño del final
- **Sumideros de recursos:** en G terminé con **A 10 661, M 52 444 y R 3 394** sin nada en qué gastarlos: 200 de población, todo investigado y la maravilla hecha. En F la madera llegó a 67 000. AoE4 tiene el mismo problema y lo tapa con trabucos, reconstrucción y comercio. Acá falta un sumidero de la IV: tropa de élite cara, reparar a precio, tributar al aliado o «comprar» edad o renta.
- **Decisiones en la IV:** después de comprar la escuela, la IV es «comprar todo». Las escuelas no se excluyen entre sí, ni las élites. Habría que poner 2 de 3 escuelas, o una mejora final por línea que se elige.
- **Contrajuego a la maravilla:** la obra dura **2 400 s de base** (21 min con 10 constructores) y después hay 15 min de cuenta. Son 36 minutos en los que un 1v3 que va perdiendo no tiene «plan B». La maravilla en obra tendría que verse en el minimapa y dar aviso a todos (el suceso `maravilla_obra` existe: ¿llega a la IA fácil?).
- **Presión en varios frentes:** la IA ataca siempre «al más cercano o a la base» y por un solo frente. Mi ejército de 100 hizo lo mismo. No hay incentivos para dividirse: rutas de comercio, sitios lejanos que rindan más en la IV (ya +50 %), o hitos atacables con ventaja.
- **Comeback:** en el 1vN, el que queda atrás pierde la capital y los hitos y **pierde con 25 aldeanos vivos** (C, 20:19). Falta una red: un centro de reserva que se arma, una «última defensa» o una rendición parcial.
- **El 1vN no tiene escala:** el preset 1v3 o 1v6 no compensa al jugador solo con más recursos iniciales, más población o un retraso del primer ataque por cantidad de rivales.

## Qué cambiaría (prioridad · esfuerzo)
1. **Alta · bajo.** Que las IA de un equipo **escalonen sus ataques** contra el mismo rival: desfasar `primer_ataque_ticks` y `ataque_espera_ticks` por posición en el equipo (por ejemplo +25 % por IA), o un «presupuesto de ola» por equipo. Así el 1v6 fácil deja de ser una experta disfrazada.
2. **Alta · bajo.** **Un solo «Población llena»** por jugador cada 30 s, o solo al pasar de libre a llena. Lo mismo para «No se puede construir ahí» en lotes de Mayús y de muro, con un aviso con lugar.
3. **Alta · medio.** **Ventaja por desventaja numérica** en la partida a medida: +recursos iniciales, +10 % de recolección o 2 a 3 min de gracia por cada rival extra (en `data/reglas.json`, `opciones_partida`). Como opción visible: «Compensar al que juega solo».
4. **Alta · medio.** **Sumidero y decisión en la IV:**
   - escuelas excluyentes (2 de 6);
   - una unidad «de la IV» por pueblo, cara en riqueza;
   - la reparación de edificios cuesta piedra o madera;
   - en el mercado, comprar sitios o renta.
5. **Media · medio.** **Contrajuego a la maravilla:**
   - aviso global y marca en el minimapa cuando se pone;
   - la IA normal o superior que va perdiendo arma una ola dedicada (ya existe `ataca_maravilla`; hace falta que también la fácil la note);
   - bajar el tiempo base a unos 1 800 s, o que escale menos con los constructores.
6. **Media · medio.** **Rendimiento con 7 jugadores:** perfilar los picos de más de 100 ms (combate en masa: `hit`, búsqueda de blanco y grupos) antes de ofrecer el 4v4 o el 1v7. Objetivo: un peor tick de menos de 50 ms con 600 entidades.
7. **Media · bajo.** **Aviso de aldeanos encerrados** (el camino no llega a ningún recurso) y el hueco del muro marcado si un edificio lo tapa.
8. **Media · bajo.** **El hito de la II que habilita la maravilla:** en la ficha del hito y en la de la maravilla, decir «esta maravilla pide X». Yo caí en eso por guion; un humano también va a caer.
9. **Baja · medio.** **Minimapa en mapas grandes:** puntos de 2 px para las unidades, o un modo «olas» que agrupe ejércitos con flechas.
10. **Baja · bajo.** **Que se pueda ver la piedra de la IV:** en D me quedé 30 minutos con 378 de piedra. Si el hito no alcanza por un recurso, el panel «Edad» tiene que decir cuál y cuánto falta, con el atajo al mercado.

## Datos útiles
- Rendimiento del 1v6 normales, en ms por tick y por minuto: 3.7, 4.6, 5.6, 6.9, 8.0, 9.3, 10.8, 12.1, 14.2, 15.0, 27.0 (minuto 11).
- Avisos propios en G: 292 «Población llena», 131 alertas de ataque (unas 2 por minuto, bien), 101 «No se puede construir ahí», 14 «Cola llena».
- Los registros completos (`p1v3*.log`, `p1v6*.log`) están en el scratchpad del tester, no en el repo.
- Una vez lancé una captura con 3 GB libres (el límite era 4). No hubo problemas, pero lo dejo anotado.
