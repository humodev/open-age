# Ronda 2 · Jugador nuevo en los RTS

Primer informe: [../02-nuevo-en-rts.md](../02-nuevo-en-rts.md). Lo que se hizo desde entonces: [../../23-como-aoe4/03-aprender-a-jugar.md](../../23-como-aoe4/03-aprender-a-jugar.md).

## Qué probé

Jugué igual que la primera vez: con capturas, con partidas guiadas por script y leyendo los textos del juego.

| Qué | Comando |
|---|---|
| Menú | `godot --path . -- --menu --shot=menu.png --shot-at=2` |
| Campañas | `godot --path . -- --menu --abrir=campanas --shot=campanas.png --shot-at=2` |
| Tutorial | `godot --path . -- --campana=tutorial --mision=0 --shot=tut.png --shot-at=1` (y a los 10 s) |
| Escaramuza sin hacer nada, con nombres en la grilla | `godot --path . -- --civ=guaranies --terreno=llano --seed=7 --dificultad=facil --speed=4 --shot=x.png --shot-at=45 --select=aldeano --grilla=economia --nombres=1` |
| Escaramuza sin hacer nada hasta el final | `… --seed=7 --dificultad=facil --speed=8 --shot=fin.png --shot-at=1380` |
| Tutorial al pie de la letra | `godot --headless --path . -s tests/tutorial_letra.gd -- --modo=letra` y `--modo=indefenso` |
| Mis scripts de la ronda 1 con el tutorial nuevo | `tutorial.gd` (los seis a la madera) y `tutorial2.gd` (mitad y mitad, campana, riqueza) |
| Principiante contra la IA | `novato.gd`, 8 partidas de 30 minutos: guaraníes contra Tawantinsuyu, llano; modos `tutorial`, `aplicado`, `tortuga` y `aplicado` + disputar sitios; IA fácil y normal; semillas 7 y 21 |
| Quién toma los sitios | `sitio_probe.gd`: IA fácil sola 20 minutos; anota qué unidades hay al lado de cada sitio cuando se toma |

Los scripts están en la carpeta de trabajo del agente, fuera del repo.

## Qué mejoró, deseo por deseo

| # | Deseo de la ronda 1 | Ahora |
|---|---|---|
| 1 | IA fácil de verdad, y el menú en Fácil | **Mejoró mucho.** El menú arranca en Fácil ([captura 1](capturas/nuevo/01-menu.jpg)). En 6 de las 7 partidas contra la fácil, el ataque llega entre el 15:18 y el 15:23; antes llegaba entre el 8:14 y el 9:08. Sin hacer nada, me barren recién hacia el minuto 16. Una partida aguantó los 30 minutos. **Pero sigo perdiendo casi siempre** (abajo explico por qué) |
| 2 | Tutorial que no se trabe y que pida todo | **Resuelto.** Pide madera y alimento juntos, después riqueza; enseña la cámara, el explorador y el sitio; avisa «llegan en 60 s» con una cuenta grande, y tiene la regla «Cuidá a tus aldeanos» siempre visible ([captura 2](capturas/nuevo/02-tut10.jpg)). La prueba al pie de la letra gana a las 9:46. Mi script viejo de «todos a la madera» ya no se traba: se queda en el primer objetivo, que dice claramente que faltan 100 de alimento |
| 3 | Un «arte de la guerra» | **Falta.** No lo vi en el menú ni en las campañas |
| 4 | Avisos que enseñan | **Resuelto.** A los 45 s sin hacer nada aparece «Tenés 6 aldeanos sin trabajo», con qué tecla tocar y cómo ponerlos a juntar ([captura 3](capturas/nuevo/03-ociosos.jpg)). Están también los de frutos agotados, recursos sin gastar y sitios |
| 5 | Sitios sagrados visibles y apagables | **A medias.** Hay cuenta grande y aviso «perdés en M:SS», y el tutorial los explica. No hay una opción en el menú para jugar sin sitios. Y la IA fácil los sigue tomando, sin querer (ver abajo) |
| 6 | Botón de aldeanos ociosos con número | **Resuelto.** Arriba, al lado de la población, en rojo cuando hay ociosos, y otro para los militares. Y debajo de cada recurso, cuántos aldeanos lo juntan: muy útil |
| 7 | Pantalla de fin que explique | **Resuelto, y muy bien.** «Perdiste por conquista: Rojo destruyó los edificios que cuentan para la victoria», más dos consejos concretos («el rival llegó a 22 aldeanos y vos a 6») y la línea de tiempo de edades ([captura 4](capturas/nuevo/04-fin.jpg)) |
| 8 | Nombres en la grilla | **A medias.** La opción existe, pero muestra el nombre propio: «Oga», «Kokue (roza)», «Tapyi», «Ñai'ũ renda». A alguien nuevo no le dice qué es. Lo que necesito es «Casa», «Granja», «Leñera» (el nombre propio puede ir en la ficha, como ya está) |
| 9 | Releer la Guía | **Resuelto.** Botón «Releer la guía G» bajo los objetivos, y los mensajes duran más |
| 10 | Camino después del tutorial | **Falta.** Las campañas siguen todas iguales, sin marcar cuál conviene empezar ni la dificultad ([captura 5](capturas/nuevo/05-campanas.jpg)). Lo bueno: el «✓ ganada» en vertical ya está arreglado |

## Qué sigue frustrando

### La IA fácil gana con los sitios sin buscarlos
La IA fácil tiene `toma_sitios: false`, pero cuando no tiene a dónde ir manda su ejército **al centro del mapa** (`_map_spot` en `src/sim/sim_ai.gd`). En los mapas de dos jugadores, justo ahí hay un sitio sagrado. Resultado, con semillas 7 y 21:
- 3 honderos ociosos toman el sitio del centro a las 6:02 o a las 7:00;
- más tarde, un ariete de paso toma otro;
- en una partida (aplicado, semilla 21) tuvo los tres a las 20:17 y **ganó por sitios a las 25:16**, con mi ejército de 25 en casa.

Además, esos honderos parados en el centro **matan aldeanos** antes del minuto 15: en la semilla 21 perdí 10 aldeanos entre las 6:00 y las 7:40, mandándolos a frutos y madera lejanos. Para mí, eso es una incursión, aunque la IA no la haya «decidido».

### Sigo perdiendo contra la fácil

| Principiante | IA | Semilla | Primer enemigo en mi base | Final |
|---|---|---|---|---|
| Como enseña el tutorial | fácil | 7 | 15:21 | Pierdo a las 26:46 |
| Igual | fácil | 21 | 7:52 (los honderos del centro) | Pierdo a las 17:34 |
| Aplicado | fácil | 7 | 15:19 | **Sigo vivo a los 30:00** |
| Aplicado | fácil | 21 | 15:23 | Pierdo a las 25:16, por sitios |
| Tortuga, sin ejército | fácil | 7 | 15:18 | Pierdo a las 18:51 |
| Aplicado y disputo sitios | fácil | 7 | 15:20 | Pierdo a las 17:12 (salí a pelear y me quedé sin ejército en casa) |
| Como enseña el tutorial | normal | 7 | 7:16 | Pierdo a las 11:26 |
| Aplicado | normal | 21 | 7:10 | Pierdo a las 13:58 |

Comparado con la ronda 1 duro el doble, pero todavía pierdo 5 de cada 6. El ataque del minuto 15 me encuentra con 15 a 25 soldados y aun así me rompe el centro. La IA fácil está en edad II a los 4:50 y yo, siguiendo el tutorial, ni llego. En AoE4, la fácil es para ganar las primeras veces. Acá, un principiante que hace lo que le enseñaron todavía no gana nunca.

### La prueba del tutorial «indefenso» falla
`godot --headless --path . -s tests/tutorial_letra.gd -- --modo=indefenso` termina en **FALLA**: la misión queda abierta a los 30:00 con 2 aldeanos vivos, 990 de alimento y 1.001 de riqueza.
- El combate más blando hace que sobrevivan dos aldeanos, y el script solo construye el hito con 4.
- No es una trampa para una persona, porque podría entrenar más aldeanos. Pero la prueba ya no cubre el caso, y el juego no le dice nada a quien quedó así: un aviso tipo «entrená aldeanos para levantar el hito» ayudaría.

### Otras cosas que todavía no se entienden
- **El orden de los objetivos en el tutorial** sigue raro en un punto: «Entrená 5 guerreros» se cumple *después* de «Abatí a los saqueadores» (7:40 contra 7:22 en la prueba al pie de la letra; 10:49 contra 9:20 en la indefensa), porque el ataque llega antes de que entrenes los cinco.
- **Los frutos se acaban a los 5:30 en el tutorial** y a los 9–10 en la escaramuza. Hay aviso y ya no me quedo sin comida sin saber por qué; pero después tengo que entender qué es una «Kokue (roza)».
- **La misma tecla sigue sirviendo para varias cosas** (Z hito o campana), y F1 sigue abriendo «Mi pueblo».

## Errores nuevos o que siguen

| Qué | Cómo reproducirlo |
|---|---|
| La IA fácil toma el sitio del centro aunque tiene `toma_sitios: false`: estaciona su ejército en el centro del mapa | `sitio_probe.gd`: IA fácil sola, semillas 7 y 21; a las 6:02 / 7:00 aparecen 3 honderos quietos en el sitio |
| La IA fácil puede ganar por sitios | `novato.gd -- --dif=facil --modo=aplicado --seed=21`: tres sitios a las 20:17, derrota a las 25:16 |
| `tests/tutorial_letra.gd --modo=indefenso` da FALLA (misión abierta a los 30:00) | El comando de arriba |
| Sigue el `double free or corruption (!prev)` con volcado de memoria al cerrar el menú tras la captura | `godot --path . -- --menu --shot=x.png --shot-at=2` (me pasó las dos veces que lo corrí en esta ronda) |
| La pantalla de fin dice «5 aldeanos ociosos en promedio» cuando tuve los 6 quietos toda la partida | Escaramuza sin hacer nada hasta el final (comando de arriba) |
| El rival figura con 130 «edificios construidos» con 22 aldeanos; puede que cuente cada tramo de algo, pero se lee raro | Misma captura |
| Una línea roja vertical cerca del minuto 5 en el gráfico de Población, sin explicación | Misma captura |
| El recuadro «Partida · 1 contra 1» sigue suelto en el medio del menú | Captura 1 |

## Mis 10 deseos, actualizados

1. **Que la IA fácil no se estacione en un sitio**: que su punto de reunión sea cerca de su base, no el centro del mapa. Así no toma sitios ni caza aldeanos antes del minuto 15.
2. **Que un principiante pueda ganarle a la fácil**: ataques más chicos (5–6 unidades), un rato de respiro entre uno y otro, y que no destruya el centro en el primero.
3. **Un «arte de la guerra»** con medallas: economía, defensa con campana, contadores, sitios.
4. **Nombres comunes en la grilla** («Casa», «Granja», «Cuartel»), con el nombre propio en la ficha.
5. **Opción de jugar sin sitios sagrados** en el menú, al menos hasta que uno aprende.
6. **Marcar en las campañas cuál conviene empezar** y su dificultad.
7. **Que el tutorial entrene los 5 guerreros antes del ataque**, o que el objetivo diga «los que puedas», para que el orden no se dé vuelta.
8. **Un aviso cuando faltan aldeanos para el hito** (o para seguir), y arreglar la prueba indefensa.
9. **Un objetivo sugerido en la escaramuza** («llegá a 20 aldeanos», «construí un cuartel», «pasá a la edad II»), como en AoE4.
10. **Teclas sin doble sentido** para lo básico, o que la ficha diga «Z (con el centro): campana».

## ¿A los 10 minutos tengo ganas de seguir?

Sí, esta vez sí. En los primeros 10 minutos el juego me lleva de la mano: el tutorial explica cada cosa cuando hace falta, el aviso de ociosos me corrige y el panel de Edad me dice qué falta. Llegué al minuto 15 sin que nadie me atacara y entendiendo qué hacía. La pantalla de fin, cuando perdí, me dijo exactamente qué hice mal, y eso da ganas de volver a intentarlo en lugar de cerrar. Lo que todavía me desanima viene después: el primer ataque de la «fácil» me sigue rompiendo, y una vez perdí por sitios que la IA ni estaba buscando. Si eso se arregla, me quedo.
