# 02 · Jugador nuevo en los RTS

## 1. Quién soy y qué probé

Jugué estrategia por turnos (Civilization, algo de Total War en el mapa de campaña) y juegos de construcción. Nunca jugué un RTS en serio. Me importa entender qué hacer, que el juego me enseñe y que no me castigue por no saber.

No puedo usar mouse ni ver la pantalla en vivo, así que jugué con capturas, con partidas guiadas por script (órdenes como las daría un principiante) y leyendo los textos del juego. No leí los documentos de diseño antes de jugar.

| Qué | Comando |
|---|---|
| Menú | `godot --path . -- --menu --shot=menu.png --shot-at=2` |
| Campañas | `godot --path . -- --menu --abrir=campanas --shot=campanas.png --shot-at=2` |
| Tutorial | `godot --path . -- --campana=tutorial --mision=0 --shot=tut1.png --shot-at=1` (y a los 8 s) |
| Escaramuza, aldeanos y grilla | `godot --path . -- --civ=guaranies --terreno=llano --seed=7 --shot=x.png --shot-at=3 --select=aldeano --grilla=economia` |
| Ficha de un botón | `… --select=aldeano --grilla=militar --ficha=cmd:0` |
| Paneles | `… --panel=economia,edad` y `… --panel=pueblo` |
| Sin hacer nada 2 minutos | `godot --path . -- --civ=guaranies --terreno=llano --seed=7 --dificultad=facil --speed=4 --shot=x.png --shot-at=120 --panel=sucesos` |
| Tutorial al pie de la letra | script `tutorial.gd` (Sim + `SimScenario.create` con la misión del tutorial) |
| Tutorial con criterio | script `tutorial2.gd` (mitad a comida, campana cuando atacan, aldeanos a la riqueza para el hito) |
| Principiante contra la IA | script `novato.gd`: guaraníes contra Tawantinsuyu, llano, 30 minutos, modos `tutorial`, `aplicado`, `tortuga` y `aplicado` + disputar sitios; IA fácil y normal; semillas 7 y 21 |

Los scripts quedaron en la carpeta de trabajo del agente, fuera del repo.

## 2. Lo que me gustó

- **El panel de Edad (F4) es lo mejor que vi para alguien nuevo.** Dice qué falta con barras («200 / 500»), con tildes y cruces, y explica las dos opciones de hito con lo que dan. «Recursos: falta un recurso que hoy no estás juntando» es exactamente el tipo de frase que necesito. ([captura 5](capturas/nuevo/05-esc_paneles.jpg))
- **La ficha de cada botón** al pasar el mouse: nombre propio arriba («Aty de guerra») y debajo el nombre común («Cuartel»), qué entrena, costo, tiempo y su debilidad. Que esté el nombre en castellano debajo me salvó. ([captura 4](capturas/nuevo/04-ficha_casa.jpg))
- **Mi pueblo (F1)** explica en dos minutos qué tiene de especial mi civilización: «Fuerte en», «Flojo en» y los hitos de cada edad. Es claro y corto. ([captura 6](capturas/nuevo/06-esc_pueblo.jpg))
- **Los aldeanos sin trabajo tienen un «Zz» encima.** Se ve al instante.
- **El tutorial existe, es corto y se puede ganar en unos diez minutos** si uno hace las cosas con algo de criterio. Los objetivos van apareciendo de a uno y dicen qué tecla tocar.
- **El arte de la pantalla de campañas** y la idea de «seis historias contadas desde adentro» me dan ganas de jugarlas. ([captura 8](capturas/nuevo/08-campanas.jpg))
- **La campana** (los aldeanos se refugian) es una idea que entendí enseguida y salva partidas: en mis pruebas, tocarla a tiempo hizo la diferencia entre perder a casi todos los aldeanos y no perder ninguno.

## 3. Lo que no entendí o me frustró, y lo que le falta frente a AoE4

### El tutorial enseña a hacer, no a no perder

- **Dice «mandá a tus aldeanos al bosque» y nada más.** Si le hago caso a la letra (los seis a la madera), entreno los tres aldeanos que pide, me quedo con 50 de alimento y **no puedo pagar ni un guerrero** (cuestan 60 de alimento y 25 de riqueza). El ataque de los saqueadores llega a los 3:39, me matan a todos los aldeanos y la misión queda **trabada para siempre**: el objetivo de los guerreros se cumple solo (el centro los mata), pero sin aldeanos no hay hito, y la misión no termina ni dice nada. Lo dejé correr 25 minutos.
- **Nunca dice que hay que juntar comida ni riqueza.** El hito pide 500 de alimento y 300 de riqueza; los guerreros se comen la riqueza inicial. En la prueba con criterio terminé el tutorial a los 10:38, pero solo porque fui por mi cuenta a la riqueza.
- **El ataque llega en cuanto termino el cuartel**, con cero soldados. El objetivo dice «Entrená 5 guerreros y defendé», pero los saqueadores ya vienen. En AoE4 el tutorial te da tiempo y te avisa «van a atacar en X».
- **Los mensajes de la Guía duran entre 5 y 14 segundos y desaparecen.** No hay dónde releerlos. A los 8 segundos de empezar ya no estaba el primero. ([captura 2](capturas/nuevo/02-tut1.jpg))
- **El orden de los objetivos se desarma.** Los dos primeros (300 de madera y la casa) aparecen juntos; si hago la casa antes, la Guía dice «Bien. Más gente necesita más casas» cuando ya la hice, y el de madera se cumple a los 2:48, después del cuartel.
- **No enseña a mover la cámara, a ver el minimapa, a explorar, ni los sitios sagrados**, que es justamente lo que me hizo perder (ver abajo). Tampoco enseña qué son «choque», «distancia» y «línea» más allá de una frase.
- **Usa a los guaraníes**, que no tienen torre, granero ni depósito, y cuyos edificios se llaman Oga, Tapyi, Aty, Kokue. Para aprender lo básico preferiría el pueblo más «normal»; los nombres propios suman, pero de a poco.
- **Le falta el «arte de la guerra» de AoE4**: misiones cortas, aparte, que enseñan una sola cosa (economía temprana, defender una ofensiva, contadores) con medalla de bronce, plata y oro. Es lo que hace que un principiante quiera repetir.

### La IA fácil no es fácil para alguien nuevo

Resultado de diez partidas guiadas por script (guaraníes contra Tawantinsuyu, llano):

| Cómo juega el principiante | IA | Semilla | Primer enemigo en mi base | Final |
|---|---|---|---|---|
| Como enseña el tutorial (cuartel a los 4 min, guerreros en casa) | fácil | 7 | 8:59 | Pierdo a los 13:26: me arrasan |
| Igual | fácil | 21 | 9:03 | Pierdo a los 13:58 |
| Igual | normal (la que viene elegida en el menú) | 7 | 7:54 | Pierdo a los 17:30 |
| «Aplicado»: rozas, campo de tiro, gente en la riqueza, hito | fácil | 7 | 8:14 | **Pierdo a los 13:52 con 25 soldados intactos en casa**: la IA tuvo los tres sitios sagrados 5 minutos |
| Igual | fácil | 21 | 9:08 | Pierdo a los 14:58, igual, por sitios |
| Aplicado y además disputo los sitios con el ejército | fácil | 7 | 8:14 | Pierdo a los 23:47 |
| Igual | fácil | 21 | 9:23 | Pierdo a los 27:42 |
| «Tortuga»: solo economía, sin ejército | fácil | 7 | 8:21 | Pierdo a los 10:01 |

- **Un principiante pierde siempre contra la IA fácil, entre el minuto 10 y el 28.** En AoE4 la IA fácil casi no ataca y sirve para aprender; acá a los 8–9 minutos ya está en edad II y manda un grupo, y a los 15 está en edad III.
- **Perdí por sitios sagrados sin entender por qué.** En la escaramuza hay una línea chica, «Sitios 0/3», y una cuenta regresiva en la misma caja; el tutorial no los nombra y el menú no deja apagarlos. Desde mi lado: tenía el ejército más grande que había hecho nunca y de golpe apareció «derrota». En AoE4 los sitios avisan con un cartel grande y un temporizador en el centro de la pantalla.
- **La dificultad del menú viene en «Normal».** Para alguien que abre el juego por primera vez debería venir en Fácil, o preguntar «¿es tu primera vez?».

### Leer lo que pasa

- **Dos minutos sin hacer nada y el juego no me dice nada.** Seis aldeanos con «Zz», el rival ya en 54 puntos y yo en 0; ningún aviso del tipo «tus aldeanos no trabajan», ni un botón con el número de ociosos como en AoE4. El atajo existe («.»), pero hay que saberlo. ([captura 7](capturas/nuevo/07-esc_120.jpg))
- **Cuando se acaban los frutos no hay aviso.** En mis partidas el alimento llegó a 0 a los 10 minutos con 2.000 de madera sin usar; nadie me dijo «se acabaron los frutos: hacé rozas». Tampoco hay un consejo cuando un recurso se acumula sin uso (llegué a tener 1.227 de riqueza parados).
- **La grilla son íconos sin nombre.** Con la ficha se entiende, pero hay que pasar el mouse por cada botón. Un candado sobre una casita no me dice qué es ni qué lo destraba. ([captura 3](capturas/nuevo/03-esc_aldeano.jpg))
- **El panel de abajo, con seis aldeanos elegidos, está casi vacío**: un ícono, un 6 y «6 seleccionadas». Ahí cabría «Clic derecho en un árbol, frutos o roca para recolectar».
- **La misma tecla hace cosas distintas según qué tenga elegido**: Z es hito de economía con un aldeano, campana con el centro, y otra cosa en el submenú militar. F1 abre «Mi pueblo», no «Cómo se juega» (los controles están al final de esa ficha, hay que bajar).
- **El minimapa está casi negro al empezar** y no entiendo qué representa el trapecio.
- **«Tekoha», «Amundá»**: los nombres de las edades me gustan, pero no sé al principio si son edades, lugares o mi pueblo.

### Ritmo y progresión

- La escaramuza empieza con todo quieto y sin ninguna meta visible. AoE4 te pone «objetivos sugeridos» en la escaramuza también.
- No hay una pantalla de fin que me explique **por qué** perdí y qué podría haber hecho (en mis scripts: «el rival tuvo los sitios 5 minutos», «te quedaste sin comida», «tenías 1.200 de riqueza sin gastar»).
- No hay un camino claro después del tutorial: el menú pasa de «Primeros pasos» a seis campañas con la misma jerarquía, sin decir cuál es la más fácil.

## 4. Errores y rarezas

| Qué | Cómo reproducirlo |
|---|---|
| **El tutorial se traba sin salida**: si se muere todo aldeano, el hito es imposible y la misión no termina ni falla | Tutorial; mandar los seis aldeanos a la madera como dice, entrenar los tres aldeanos y el cuartel, no tocar la campana. A los 5:00 quedan 0 aldeanos y la misión sigue abierta (lo corrí hasta 25:00) |
| **«✓ ganada» escrita en vertical**, una letra por renglón, al lado de un botón «Volver a jugar» enorme | `godot --path . -- --menu --abrir=campanas --shot=x.png --shot-at=2` con el tutorial ganado ([captura 8](capturas/nuevo/08-campanas.jpg)) |
| El ataque del tutorial llega al terminar el cuartel, antes de poder entrenar los guerreros que pide el objetivo | Tutorial, evento `ataque` en `o4` de `data/campanas/tutorial.json` |
| Los dos primeros objetivos aparecen juntos y la Guía felicita por la madera hablando de casas que ya hice | Tutorial; construir la casa antes de juntar 300 de madera |
| La ficha del cuartel guaraní dice «Entrena unidades de choque, distancia y línea», pero entrena solo guerrero de macana y lancero (el arquero va en el Guyrapa róga) | `… --select=aldeano --grilla=militar --ficha=cmd:0` |
| La ficha tapa el título del submenú («MILITAR Y DEFENSA») | Misma captura |
| Al cerrar el juego tras la captura del menú: `double free or corruption (!prev)` y volcado de memoria | `godot --path . -- --menu --shot=x.png --shot-at=2` (me pasó una vez) |
| En el menú hay un recuadro suelto «Partida · 1 contra 1» en el medio de la pantalla, separado del resto de las opciones; no sabía si era parte del menú | [captura 1](capturas/nuevo/01-menu.jpg) |

## 5. Mis 10 deseos, en orden

1. **IA fácil de verdad**: que no ataque antes del minuto 15, con grupos chicos, que no vaya por los sitios sagrados y que no pase de la edad II. Y que el menú venga en Fácil la primera vez.
2. **Arreglar el tutorial**: decir que hace falta comida y riqueza, dar tiempo para entrenar antes del ataque (con aviso «llegan en 60 s»), fallar o reiniciar si se pierden todos los aldeanos, y ordenar los objetivos.
3. **Un «arte de la guerra»**: cuatro o cinco misiones cortas de una sola idea (economía, defensa con campana, contadores, sitios sagrados, asedio), con medallas.
4. **Avisos que enseñan**: «tenés aldeanos sin trabajo», «se acabaron los frutos», «estás juntando riqueza que no gastás», «el rival tiene los tres sitios: perdés en 5:00». Con un botón para apagarlos cuando ya sé.
5. **Sitios sagrados visibles**: cartel grande y cuenta regresiva en el centro, explicados en el tutorial y con opción de apagarlos en el menú.
6. **Botón de aldeanos ociosos con número** en la pantalla, como en AoE4.
7. **Pantalla de fin que explique**: por qué perdí, una línea de tiempo y uno o dos consejos concretos.
8. **Nombre visible en la grilla** (o una opción «mostrar nombres») y una línea de ayuda en el panel de la selección.
9. **Que la Guía se pueda releer** (un registro de mensajes) y que no desaparezca antes de que termine de leerla.
10. **Un camino después del tutorial**: marcar la campaña recomendada para empezar y su dificultad.

## 6. ¿A los 10 minutos tenía ganas de seguir?

A medias. El arte, las láminas de las campañas y los paneles de Edad y Mi pueblo me dieron ganas: se nota que hay mucho para descubrir y que cada pueblo juega distinto. Pero en todas mis partidas, a los 10 minutos ya me estaban atacando, al rato perdía y no sabía bien por qué: dos veces fue por sitios sagrados que nadie me había explicado, con el ejército entero en casa. El tutorial, si le hacía caso a la letra, me dejaba trabado sin aviso. Como jugador nuevo, después de perder tres veces seguidas contra «fácil» sin entender por qué, cierro el juego. Con una IA fácil más tranquila, avisos que enseñen y un tutorial que no se trabe, me quedaría: la base es linda y se entiende más de lo que esperaba.
