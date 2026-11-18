# Ronda 8 · Constructor y economía: 1v3, 2v4 y 1v6 hasta el final

> Jugador de prueba: constructor (AoE2 DE, AoE4, Anno). Partidas largas, base cerrada y economía en piloto automático.
> Pedido del autor: poner a los expertos contra más IA (1v3, 1v6) para llegar al final y encontrar mejoras al diseño.
> Base: main en f27a46c (fluidez 1, 2 y 3 integradas; el frente 4, de avisos y equipo, todavía no entró).

## Cómo jugué

No hay forma de manejar la interfaz en headless durante 50 minutos, así que armé un guion (`guion.gd`, en el scratchpad de testers) que corre la simulación de punta a punta:

- **Piloto automático:** mi economía la maneja una `SimAI` experta de estilo «normal». Así se parece a lo que hago yo: aldeanos sin parar, granjas y subir de edad.
- **Encima, el guion hace lo mío:**
  - repetición de aldeanos en la capital (`repetir` + `tope_aldeanos`);
  - desde el minuto 5, un anillo de empalizada a 20 casillas con 4 puertas, que se completa cada minuto (`build_line`);
  - 4 torres en las diagonales y una fortaleza en la III;
  - campana si entran 6 o más enemigos;
  - reparar lo que baja del 60 % (cada 30 s);
  - en la IV: escuela y economía tardía, mercado para comprar piedra y maravilla;
  - en el 2v4, tributo al aliado cada 3 minutos si me sobra.
- **Mapa:** grande y llano, semilla 7. Medí la simulación pelada, sin dibujo: ms por tick, avisos por minuto, ociosos y enemigos dentro del muro.
- **Capturas:** las saqué reproduciendo la partida con `--replay`.

Lo que es de pura interfaz no lo pude tocar con este método: Mayús en orden, el letrero de costo y huecos del muro, las granjas pegadas, D para reparar por zona y el aviso de población. Lo comento por lectura del código y de las pruebas del frente.

## Resultados

| Partida | Yo | Rivales | Final | ¿IV? |
|---|---|---|---|---|
| 1v3 (a) | guaraníes, piloto difícil | 3 normales | derrota 24:58 | no (II) |
| 1v3 (b) | guaraníes, piloto experta | 3 normales | derrota 21:32 | no (II) |
| 1v3 (c) | etiopía, experta, con torres | 3 normales | rendición 19:55 | no (II) |
| 2v4 | tawantinsuyu + palmares (normal) | 4 normales | derrota **por sitios** 55:11 | **sí, 40'** (el aliado cayó en el 18') |
| 1v6 | guaraníes, experta | 6 fáciles | victoria **por sitios** 44:33–50:46 | **sí, 29'** |

Los rivales del 1v3 llegaron a la III y uno a la IV mientras me barrían. En el 2v4, los cuatro rivales llegaron a la IV con 130 a 150 de población cada uno.

## Qué se siente bien

- **El anillo de empalizada aguanta contra la IA fácil.** En el 1v6 cerré 149 tramos y 4 puertas antes del minuto 15. Entraron enemigos una sola vez (campana en el 21') y después no pasó nadie en 30 minutos. A 4 de madera el tramo, amurallar a lo AoE2 es barato y se nota.
- **El muro no traba mi economía:** los aldeanos «quietos con orden de moverse» fueron 0 a 5 por minuto con 100 aldeanos y 4 puertas. El pathing con murallas propias anda.
- **La escuela de la IV y la economía tardía funcionan.** Registros en el centro (29:30) y después hachas III, riego III, cestas II, alcance de torres, reparación en el campo, fortaleza reforzada y reparación rápida. Todo se compró donde dice. Con Registros, la tanda de la IV sale más barata y se siente como un premio por llegar.
- **El mercado como fuente de piedra salva el final.** Comprando de a 100 (el precio llegó a 123), junté 1520 de piedra en 6 minutos. Con eso, el piloto experto empezó la maravilla del monte en el 38'.
- **Lo propio de cada pueblo aparece solo.** Guaraníes: kokue, oga takuara, pohã ñana, defensa de Mbororé; trinchera de tacuara como fortaleza. Tawantinsuyu: khipukamayuq, chuñu charki, trepanación, qeswa chaka, champi, chaski, wayrachina y warak'a trenzada; pukara como torre. Las listas de `ia_propias` hacen su trabajo.
- **Rendimiento a ×1:** 25 a 30 ms por tick con 7 jugadores y unas 750 entidades (1v6), y 33 a 47 ms en el 2v4 tardío (900 a 1000 entidades). El tick es de 100 ms, así que a ×1 y ×2 entra con margen.

## Qué se rompe

1. **El 1v3 contra normales no se puede jugar a lo constructor.** Las tres IA tienen `objetivo: cercano`, y el único cercano soy yo. Desde el minuto 8 llegan oleadas de las tres a la vez. Entre el 15' y el 18' paso de 55 a 21 de población en un minuto, con 44 enemigos adentro. Tres intentos, tres derrotas antes del 25'.
   - La empalizada de 300 PV cae enseguida: de 154 a 86 tramos en 4 minutos.
   - Sin piedra no hay torres (ver el punto 2), y los guaraníes directamente no tienen torre.
   - Para quien viene de AoE2, un 1v3 contra normales es un desafío jugable. Acá es un muro.
2. **La piedra se acaba en todo el mapa.** Medido al empezar: **1600 de piedra por jugador en todo el mapa (2 afloramientos de 800)**, en mapa normal o grande. El «grande» suma madera y nada de piedra.
   - A la vez, la III pide 200, la IV 400, la torre 150, la fortaleza 450 y la maravilla 1500.
   - Al final de las tres partidas largas quedaba **0 de piedra en el mapa**. Mi piedra se clavó en 90 desde el 35' hasta el final, con 15 000 de madera y 8000 de alimento sin usar.
   - En el 2v4, el inca quedó **34 minutos en la II** (del 6' al 40') con 10 000 de madera, esperando 200 de piedra. Las cinco pukara se la habían comido.
3. **La IA no usa el mercado para nada.** Ni el piloto ni las rivales venden lo que les sobra ni compran piedra. Sin mi guion comprando, la maravilla no salía nunca, y el inca habría salido de la II en minutos con un mercado.
4. **La IA aliada no sirve en el 2v4.** Palmares (normal) cayó en el 18', antes de que yo tuviera ejército. Me dejó solo contra cuatro: un 1v4 con un aliado que duró 18 minutos.
   - Le di 5 tributos de 300 y no cambió nada.
   - No hay forma de decirle «vení a mi base» o «defendé conmigo» (las bengalas con intención son del frente 4, todavía sin integrar).
5. **Los avisos saturan.** En el 2v4 conté 256 «ia_dice», 147 «nos atacan» propios y 42 del aliado, 52 investigaciones y 28 «Población llena», en 55 minutos.
   - Son unos 10 por minuto en promedio, con picos de 24.
   - Con 6 IA, los «X llegó a la edad Y» y lo que dicen las IA tapan lo que importa.
   - El freno del ataque sigue siendo global, de 15 s (`sim.gd:2214`): si atacan el norte y el sur, el segundo no se avisa.
6. **El muro deja huecos sin avisar desde la simulación.** `_cmd_build_line` saltea las casillas imposibles: 4 de 160 en el perímetro, por árboles y vetas. Si se acaba la plata, corta con «Recursos insuficientes» (13 a 32 avisos por partida). El letrero del frente 2 lo muestra al trazar, pero el muro ya puesto no dice que le falta un tramo.
7. **Rendimiento a ×4:** con 6 o 7 jugadores el tick supera los 25 ms del presupuesto. Hay picos de **90 a 315 ms** en un solo tick: tirones de un tercio de segundo, en el 1v6 y en los choques grandes del 2v4.
8. **La rendición del piloto** (etiopía, 19:55) llegó con el centro todavía en pie. Para una IA está bien, pero si alguien usa el piloto automático sería raro que se rinda solo.
9. **Los sitios cierran el final antes que la maravilla.** Las tres partidas largas terminaron por sitios: gané el 1v6 en el 44:33 y perdí el 2v4 en el 55:11.
   - En el 1v6, la obra de mi maravilla arrancó en el 38:08 y la cuenta por sitios terminó antes de que la levantara.
   - Contra 6 fáciles (que se quedan en la II, `edad_max: 2`) no hay final que jugar; contra 4 normales, los sitios me ganan mientras me defiendo.
   - En el 1v3, la cuenta por sitios del rival también corría mientras me barrían (captura).

## Qué falta en el final y la defensa larga

- **Muralla de piedra (C-101).** Hoy la defensa fija es una empalizada de 300 PV y torres que dependen de una piedra que no existe. Un constructor necesita un muro que valga lo que cuesta en la III: el «defensa larga» de AoE2 es eso.
  - Tawantinsuyu ni siquiera tiene empalizada (`sin_edificios`), y los guaraníes no tienen torre. Cada pueblo tiene huecos distintos, y la ficha de pueblo no lo dice claro al elegirlo.
- **Contrajuego a la maravilla.** Ninguna rival atacó mi obra en el 1v6 (las fáciles no lo hacen), y en el 2v4 no llegué. Falta probarlo con difíciles. Del lado del diseño, ver la cuenta de la maravilla rival en el minimapa y un aviso cuando arranca la obra (`maravilla_obra`) son lo mínimo.
- **Sumideros del final.** A partir del 35' me sobraban 10 000 a 16 000 de madera y 6000 a 8000 de alimento, sin nada en qué gastarlos: tope de 200, aldeanos a 100 y mejoras compradas. AoE4 tiene mercados, la piedra que se mina para siempre en las canteras de los pueblos y mejoras infinitas.
- **Economía tardía: falta piedra que se renueve.** Por ejemplo:
  - una veta lejana que aparece en la III;
  - una «cantera» de la IV, como el ingenio, con renta de piedra;
  - o más afloramientos según el tamaño del mapa.

## Lo de fluidez (frentes 1 y 2)

| Cambio | Lo que vi |
|---|---|
| Repetición de producción | Anda: el comando entra y la capital encola sola. El tope de 60 no se notó porque el piloto entrena por su cuenta hasta 100. |
| Cola de 10 | No se puede probar sin interfaz; el piloto no la usa. |
| Mayús en orden | Solo en la interfaz (`mundo_cola.gd`); no lo pude probar. |
| Muro con costo y huecos | En la simulación se saltean 4 huecos de 160 en silencio (ver «Qué se rompe», punto 6). |
| Granjas pegadas | Solo en la interfaz. El piloto llegó a 37 rozas guaraníes, con «Rozas en espera: falta madera» 10 veces. |
| Reparar | Mandar aldeanos a lo dañado anda: 11 a 24 reparaciones por partida. Lo de reparar por zona es de la interfaz. |
| Rebusca lejana | No vi aldeanos ociosos en el 1v6 (0 a 2 por minuto con 100). |
| Aviso de población | «Población llena» salió 24 a 28 veces por partida larga: con el tope de 200 alcanzado, avisa de más. |

## Qué cambiaría

| # | Cambio | Prioridad | Esfuerzo |
|---|---|---|---|
| 1 | **Piedra según el mapa y el final.** Más afloramientos por jugador (al menos 3 o 4, y más en el mapa grande) o una fuente que se renueve en la III y la IV (cantera o sitio de piedra). Revisar el costo en piedra de la III y la IV contra lo que hay. | Muy alta | Bajo (datos) a medio |
| 2 | **La IA usa el mercado:** vende lo que pasa de 2000 y compra lo que le falta para el hito o la maravilla. Desatasca a la IA aliada, al piloto y a las rivales. | Muy alta | Medio |
| 3 | **Que las IA rivales no se junten contra el único humano:** en el 1v3, objetivo repartido o escalonado (que no lleguen las tres a la vez antes del 15'), o una opción «IA en equipo coordinada / suelta». | Alta | Medio |
| 4 | **Muralla de piedra en la II o III** (C-101), con el doble o triple de PV de la empalizada, y una versión por pueblo para los que no tienen torre o empalizada. | Alta | Alto |
| 5 | **Avisos por prioridad:** «nos atacan» por zona sin el freno global; lo que dicen las IA y «X llegó a la edad» agrupados en uno cada tanto; «Población llena» una sola vez con el tope alcanzado. | Alta | Medio (frente 4) |
| 6 | **IA aliada que defiende:** si me atacan con más de N, que venga; y al revés, avisarme y pedirme ayuda. Tributo con efecto visible (que lo gaste). | Media | Medio |
| 7 | **Sumideros del final:** mejoras que se repiten (como las de AoE4 de la IV), un «banco» o mercado con precios que se recuperan más lento, y obras de prestigio que suman puntos. | Media | Medio |
| 8 | **Rendimiento a ×4 con 6 a 8 jugadores:** cortar los picos de más de 90 ms (probablemente caminos en choques grandes, `tick_lento` en la telemetría). | Media | Medio |
| 9 | **El muro puesto dice sus huecos:** un aviso si un tramo pedido no se puso y una marca permanente en el hueco. | Media | Bajo |
| 10 | **Sitios y maravilla en el final:** la cuenta por sitios se pausa (o corre más lento) mientras hay una maravilla en obra o en pie. Además, que el preset 1v6 fácil deje subir a la III. | Media | Bajo |

## Capturas

- `capturas/constructor/1v6-base-iv-maravilla.jpg`: el 1v6 en el 38:20.
  - La base guaraní en la IV, con el anillo de empalizada, rozas y la fortaleza.
  - El aviso dice «Tu pueblo empezó Aldea grande del monte» (la maravilla del monte), con 20 de piedra en la barra.
  - Arriba, «Tenés todos los sitios sagrados · 06:13» y «Sucesos: 307 nuevos». Con 307 sucesos, el registro ya no se lee.
- `capturas/constructor/1v3-arrollado.jpg`: el 1v3 de Etiopía en el 17:30.
  - Me quedan 13 de 45 de población, adentro del muro hay granjas vacías y las torres están rodeadas.
  - Los avisos se apilan: dos veces «Atacan tu empalizada · junto a empalizada» (redundante), «6 granjas vacías» y «¡Nos atacan!».
  - Arriba corre «Rojo tiene todos los sitios sagrados · 07:30»: mientras me barren, además corre la cuenta por sitios.
- La reproducción con `--replay` dio el mismo estado que el guion headless: la repetición es fiel con 4 y 7 jugadores.
- En la carga faltó `ui_alerta_tropa.ogg` (sin importar). Parece trabajo en curso del frente 4 en el checkout, y no frenó nada.

## Archivos del guion

En el scratchpad de testers (`constructor-1vN/`): `guion.gd`, `piedra.gd` (la piedra del mapa al empezar), las salidas `run_*.out` y las repeticiones `replay_*.json`. No toqué código ni datos del juego.
