# Ronda 3 · Jugador nuevo en los RTS

Rondas anteriores: [1](../02-nuevo-en-rts.md) y [2](../ronda-2/02-nuevo-en-rts.md). Lo que se hizo desde la ronda 2: [etapa 24](../../24-tras-la-segunda-ronda/README.md).

## Qué probé

Igual que en la ronda 2: capturas, partidas guiadas por script y los textos del juego. Nunca tuve más de dos procesos de Godot a la vez.

| Qué | Comando |
|---|---|
| Menú con las opciones de partida | `godot --path . -- --menu --shot=menu.png --shot-at=2` |
| Grilla con nombres | `godot --path . -- --civ=guaranies --terreno=llano --seed=7 --dificultad=facil --speed=4 --shot=x.png --shot-at=45 --select=aldeano --grilla=economia --nombres=1` |
| Sin hacer nada, sin sitios | `… --seed=7 --dificultad=facil --sitios=no --speed=8 --shot=fin.png --shot-at=1380` |
| Fin por tiempo límite | `… --tiempo=30 --sitios=no --shot=x.png --shot-at=5 --panel=fin-tiempo` |
| Tutorial al pie de la letra | `godot --headless --path . -s tests/tutorial_letra.gd -- --modo=letra` y `--modo=indefenso` |
| Principiante contra la IA | `novato3.gd` (mi script de la ronda 2, con opciones de partida y telemetría al final): 8 partidas de 30 minutos, guaraníes contra Tawantinsuyu en llano, de a dos en paralelo |
| Quién mata a mis aldeanos | `novato3b.gd`: anota las tropas enemigas cerca de mis aldeanos cada vez que pierdo alguno |

Los scripts están en la carpeta de trabajo del agente, fuera del repo.

## Qué mejoró, deseo por deseo

| # | Deseo de la ronda 2 | Ahora |
|---|---|---|
| 1 | Que la fácil no se estacione en un sitio | **Resuelto.** Ya no hay honderos parados en el centro a los 6–7 minutos: el primer sitio enemigo cae recién entre las 15:06 y las 16:46, con el primer ataque. Pero la fácil todavía puede ganar por sitios (ver abajo) |
| 2 | Que un principiante le pueda ganar a la fácil | **Mejoró: ahora sobrevivo, pero no gano.** De 7 partidas contra la fácil, 3 llegaron vivas al minuto 30 (en la ronda 2, 1 de 6). Si no hago nada, a las 23:00 todavía tengo el centro en pie ([captura 3](capturas/nuevo/03-sin-hacer-nada-23min.jpg)); en la ronda 2 me barrían hacia el minuto 16. Detalle en la tabla de abajo |
| 3 | Un «arte de la guerra» | **Falta** |
| 4 | Nombres comunes en la grilla | **Igual que en la ronda 2.** Con la opción prendida sigue diciendo «Oga», «Kokue (roza)», «Tapyi», «Ñai'ũ renda» ([captura 2](capturas/nuevo/02-grilla-nombres.jpg)). La ficha sí dice «Cuartel» debajo de «Aty de guerra» |
| 5 | Jugar sin sitios | **Resuelto, y es lo que más me ayudó.** El menú tiene «Opciones de partida» con interruptores de sitios e hitos, tiempo límite, recursos, y una línea que dice en palabras cómo se gana: «Se gana por conquista (capital e hitos) o por sitios sagrados (10 minutos con todos)» ([captura 1](capturas/nuevo/01-menu-opciones.jpg)). La misma partida que perdí por sitios a las 28:49, sin sitios llega viva a los 30:00 con 25 soldados |
| 6 | Marcar la campaña para empezar | **Falta.** No lo vi |
| 7 | Que el tutorial no dé vuelta el orden (5 guerreros / saqueadores) | **Igual.** En la prueba al pie de la letra, «Abatí a los saqueadores» se cumple a las 7:26 y «Entrená 5 guerreros» a las 7:43 |
| 8 | Aviso cuando faltan aldeanos para el hito; arreglar la prueba indefensa | **La prueba pasa:** indefenso gana a las 12:35 y letra a las 11:06. Del aviso no vi nada nuevo |
| 9 | Objetivo sugerido en la escaramuza | **Falta.** Lo más parecido es el tiempo límite, que por lo menos le pone un final a la partida |
| 10 | Teclas sin doble sentido | **Igual** |

## La IA fácil, ronda 3

| Principiante | IA | Semilla | Opción | Primer ataque en mi base | Final |
|---|---|---|---|---|---|
| Como enseña el tutorial | fácil | 7 | — | 16:32 | **Vivo a los 30:00** (con 6 aldeanos) |
| Igual | fácil | 7 | recursos medios | 15:46 | **Vivo a los 30:00** |
| Igual | fácil | 21 | — | 7:30 (*) | Pierdo a las 18:23, por conquista |
| Aplicado (rozas, campo de tiro, riqueza, hito) | fácil | 7 | — | 17:24 | Pierdo a las 22:11, por conquista |
| Aplicado | fácil | 21 | — | 16:47 | Pierdo a las 28:49, **por sitios** |
| Aplicado | fácil | 21 | sin sitios | 16:47 | **Vivo a los 30:00** con 25 soldados y 20 aldeanos |
| Tortuga, sin ejército | fácil | 7 | — | 16:31 | Pierdo a las 19:18 |
| Como enseña el tutorial | normal | 7 | — | 7:38 | Pierdo a las 12:15 |

(*) **Corrección a mi informe de la ronda 2.** Las muertes tempranas de la semilla 21 las causa mi script, no el juego. Con `novato3b.gd` vi que, cuando se acaban los frutos cerca, mi script manda a los ociosos al arbusto «más cercano» sin mirar la niebla. Ese arbusto está a 100 casillas, al lado de la base rival, y ahí los matan los honderos. Una persona no los mandaría a un lugar que no ve. En la ronda 2 culpé de esto a los honderos estacionados en el sitio del centro. Esos honderos existían (los vi con `sitio_probe.gd`), pero una parte de las bajas era mía.

**Lo que se lee:**
- La fácil ataca hacia el minuto 16 en todas las semillas y ya no hace incursiones antes.
- Contra la fácil, perder ya no es seguro: aguanté 3 de 7 partidas. Ganar tampoco pasa nunca. El jugador «aplicado» termina con 3.381 de alimento, 2.043 de madera y 2.135 de riqueza sin gastar y un ejército de 25 que nunca sale.
- **La fácil sigue ganando por sitios.** Tiene `toma_sitios: false`, pero su ejército pasa por los sitios cuando va a atacarme. En la semilla 21 los tomó a las 16:08, 18:30 y 18:50, y diez minutos después ganó. El cartel grande avisa, pero un principiante con el ejército en casa no entiende por qué esa victoria vale si la IA «no juega a los sitios». Para alguien nuevo, la solución es la opción «Sitios sagrados: no», y conviene que venga apagada la primera vez, igual que la dificultad viene en Fácil.

## La ciudad

No puedo mirar la ciudad de cerca con el mouse, pero la telemetría de mis 8 partidas ayuda. Mi script pega casas, cuartel y rozas uno al lado del otro alrededor del centro, que es lo que hace un principiante.
- Aldeanos «trabados»: entre 0 y 2 por partida.
- «Sin camino»: entre 0 y 16.
- Viaje medio de la madera al depósito: 6–8 casillas.

No vi aldeanos encerrados entre edificios, que era lo que me preocupaba al pegarlos. No tengo la medida de la ronda 2 para comparar.

## Tutorial

- **Se gana en los dos modos de la prueba.** Al pie de la letra, a las 11:06; sin defenderse, a las 12:35.
- **El final se hace largo.** El hito ahora tarda más: entre que lo encargo (8:30) y la edad II (11:06) pasan 2 minutos y medio sin ninguna tarea nueva ni mensaje de la Guía. Para alguien nuevo ese es un rato muerto justo antes del final. Ayudaría que la Guía use ese rato: «mientras se construye, mirá el panel de Edad», «el hito de economía junta más rápido cerca de los campos» (las auras nuevas son algo lindo para enseñar ahí).
- El orden de los objetivos 8 y 9 sigue al revés (ver deseo 7).

## Errores nuevos o que siguen

| Qué | Cómo reproducirlo |
|---|---|
| La fácil gana por sitios aunque tiene `toma_sitios: false`: los toma al pasar con el ejército | `novato3.gd -- --dif=facil --modo=aplicado --seed=21 --min=30`: sitios a las 16:08, 18:30 y 18:50; derrota «sitios» a las 28:49 |
| Sigue el crash al cerrar tras la captura: `double free or corruption (!prev)` | Cualquier captura: me pasó con `--menu` y con `--panel=fin-tiempo` |
| La grilla con nombres muestra el nombre propio y no el común | Comando de la grilla, arriba |
| «Empate» sale en el mismo naranja que «Derrota»; a primera vista parece que perdí | `--tiempo=30 --sitios=no --panel=fin-tiempo` ([captura 4](capturas/nuevo/04-fin-tiempo.jpg)) |
| Con «Sitios sagrados: no», el panel de la derecha sigue diciendo «Sitios 0/3». Entiendo que dan riqueza, pero no sé si cuentan o no; faltaría un «(no ganan)» | `--sitios=no`, [captura 3](capturas/nuevo/03-sin-hacer-nada-23min.jpg) |
| Objetivos 8 y 9 del tutorial al revés | `tests/tutorial_letra.gd -- --modo=letra` |

## Mis 10 deseos, actualizados

1. **La primera vez, «Sitios sagrados: no»**, como la dificultad en Fácil. Y que la fácil no los tome al pasar, o que con la fácil no cuenten.
2. **Que la fácil se pueda ganar.** Hoy sobrevivo, pero nunca gano. Algo como que la fácil se rinda o pierda si le destruyen el ejército dos veces, o un objetivo sugerido «destruí su centro» con una pista de cómo (ariete, asedio).
3. **Nombres comunes en la grilla** («Casa», «Granja», «Leñera»).
4. **Usar la espera del hito en el tutorial** para enseñar las auras y el panel de Edad.
5. **Un «arte de la guerra»** con medallas.
6. **Objetivos sugeridos en la escaramuza** (20 aldeanos, cuartel, edad II, atacar).
7. **Un aviso de «tenés ejército de sobra y recursos sin gastar: atacá o subí de edad».** Mi jugador aplicado terminó con 7.000 recursos parados y 25 soldados en casa.
8. **Marcar la campaña recomendada** y su dificultad.
9. **Ordenar los objetivos 8 y 9 del tutorial.**
10. **«Empate» con otro color** y «Sitios (no ganan)» cuando están apagados.

## ¿A los 10 minutos tengo ganas de seguir?

Sí, y más que en la ronda 2. Los primeros 15 minutos son tranquilos y entiendo qué hago. Ahora el menú me deja elegir cómo se gana y me lo explica en una línea, así que puedo sacar los sitios, que eran lo que más me confundía. Por primera vez llegué al minuto 30 sin perder contra la fácil. Lo que todavía falta es el siguiente paso: aguanto, pero no sé cómo ganar, y el juego no me lo sugiere. Con un empujón para salir a atacar (objetivo sugerido, aviso o el «arte de la guerra»), me quedaría a jugar en serio.
