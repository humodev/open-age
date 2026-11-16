# Ronda 4 · Jugador nuevo en los RTS

Rondas anteriores: [1](../02-nuevo-en-rts.md), [2](../ronda-2/02-nuevo-en-rts.md) y [3](../ronda-3/02-nuevo-en-rts.md). Lo que se hizo desde la ronda 3: [etapa 24](../../24-tras-la-segunda-ronda/README.md), filas M y O y las secciones del final. Esta ronda mira sobre todo la calidad de vida y la usabilidad.

## Qué probé

Rama `main` (352136e). Nunca tuve más de dos procesos de Godot a la vez.

| Qué | Comando |
|---|---|
| Menú la primera vez | `godot --path . -- --menu --shot=menu.png --shot-at=2` |
| Opciones | `godot --path . -- --menu --abrir=opciones --shot=x.png --shot-at=2` |
| Grilla de economía con nombres y la ficha del tapyi | `godot --path . -- --civ=guaranies --terreno=llano --seed=7 --dificultad=facil --shot=x.png --shot-at=3 --select=aldeano --grilla=economia --nombres=1 --ficha=cmd:2` |
| Grilla militar | `… --select=aldeano --grilla=militar --nombres=1` |
| El centro elegido | `… --select=centro --nombres=1` (guaraníes) y `--civ=tawantinsuyu … --select=centro --nombres=1 --ficha=cmd:0` |
| Controles reales | `godot --path . -- --autotest --civ=guaranies --terreno=llano` |
| Tutorial al pie de la letra | `godot --headless --path . -s tests/tutorial_letra.gd -- --modo=letra` |
| Principiante contra la fácil | `novato4.gd`: mi script de las rondas anteriores, ahora sin sitios (como arranca el menú la primera vez) y con un modo `--ataca=1` que hace lo que dice el aviso nuevo (con 15 tropas, A y clic en la base rival). 6 partidas de 30 minutos, guaraníes contra Tawantinsuyu en llano |

**Corregí mi script.** Ahora solo manda aldeanos a recursos a menos de 30 casillas de su centro. En la ronda 3 vi que los mandaba a ciegas al otro lado del mapa.

Los scripts están en la carpeta de trabajo del agente, fuera del repo.

## Qué mejoró, deseo por deseo (ronda 3)

| # | Deseo | Ahora |
|---|---|---|
| 1 | Sitios apagados la primera vez y que la fácil no los tome | **Resuelto.** El menú arranca en Fácil, con «Sitios sagrados» apagado, y la línea dice «Se gana por conquista (capital e hitos). Los sitios sagrados dan riqueza, pero no ganan.» ([captura 1](capturas/nuevo/01-menu-primera-vez.jpg)) |
| 2 | Poder ganarle a la fácil | **No.** Sobrevivo, pero cuando la ataco, la fácil arma un ejército sin tope: pasa de 39 a 147 de población (ver abajo) |
| 3 | Nombre común en la grilla | **Resuelto.** «Casa / Oga», «Granja / Kokue (roza)», «Granero y leñera», «Cuartel / Aty de guerra», «Campo de tiro / Guyrapa róga». Era lo que pedía ([captura 2](capturas/nuevo/02-grilla-economia-tapyi.jpg), [5](capturas/nuevo/05-grilla-militar.jpg)). La opción viene apagada |
| 4 | Usar la espera del hito en el tutorial | **Resuelto.** Durante la obra hay cinco mensajes (barra de la obra, F4, auras, grupos, qué cambia en la edad II) y una tarea opcional. El tutorial se gana a las 11:10 |
| 5 | «Arte de la guerra» | **Falta** |
| 6 | Objetivos sugeridos en la escaramuza | **Falta.** El aviso «atacá o subí de edad» cubre una parte |
| 7 | Aviso «ejército y recursos de sobra» | **Resuelto** (el autotest lo verifica). Pero el consejo que da lleva a una trampa (ver abajo) |
| 8 | Campaña recomendada | **Falta** |
| 9 | Ordenar los objetivos 8 y 9 del tutorial | **Resuelto:** se cumplen juntos a las 7:46 |
| 10 | «Empate» con otro color, «Sitios (no ganan)» | **Resuelto** según la etapa 24; no lo volví a capturar |

## Calidad de vida y usabilidad, por gravedad

**Grave** = alguien nuevo se traba o se lleva una idea equivocada. **Media** = confunde, pero se sale. **Leve** = detalle.

### Grave

**1. En el centro, el botón del aldeano está tapado por «Herramienta de tala».**
- **Qué hace hoy:** elijo el centro (H). En la casilla Q de la grilla se ve un árbol y dice «Herramienta de tala»; en W, «Cantería»; en E, «Trabajo de la riqueza». No hay ningún botón de «Aldeano» ni de «Explorador». Si apoyo el mouse sobre Q, la ficha dice «Runa / Aldeano», y Q (o el clic) entrena un aldeano, aunque el botón dice otra cosa.
- **Causa probable:** las investigaciones de los depósitos (`hachas`, `canteria`, `orfebreria`, ranuras 0–2) se muestran en el centro porque el centro recibe madera, piedra y riqueza (`Sim.tech_here`). Comparten ranura con `aldeano` y `explorador`. La grilla dibuja la última (`hud.gd`, `by_slot[c["slot"]] = c`), pero el teclado y la ficha usan la primera (`controller.gd`, «if cmd["slot"] == slot»). Por eso esas investigaciones tampoco se pueden comprar desde el centro.
- **Qué esperaría:** ver «Aldeano» en Q y «Explorador» en W, y las investigaciones en otras casillas.
- **Cómo se reproduce:** `godot --path . -- --civ=tawantinsuyu --terreno=llano --seed=7 --shot=x.png --shot-at=3 --select=centro --nombres=1 --ficha=cmd:0` ([captura 3](capturas/nuevo/03-centro-boton-aldeano-tapado.jpg)). Con guaraníes, igual ([captura 4](capturas/nuevo/04-centro-guarani.jpg)).
- **Gravedad:** la más alta de la lista. Entrenar aldeanos es lo primero que se aprende, el tutorial dice «Seleccioná el centro con H y entrená aldeanos con Q», y lo que se ve en Q es un árbol que dice otra cosa. El autotest no lo agarra porque prueba la tecla, que sí entrena.

**2. Cuando ataco a la fácil, se arma sin tope y ya no le puedo ganar.**
- **Qué hace hoy:** seguí el aviso nuevo («elegí tus tropas, A y clic en la base rival») con 15–20 guerreros y honderos.
  - La fácil tiene un tope de 15 soldados, salvo si la atacan (`sim_ai.gd`, «salvo si atacan la base»). Con mi ejército rondando su base, queda «amenazada» todo el tiempo y produce sin parar.
  - Semilla 7: a los 12:00 tenía 13 honderos, 2 arietes y un boleador; a los 21:00, 46 honderos, 37 guerreros y 19 boleadores. Su población pasó de 39 a 147.
  - Mis 18–22 soldados no tiran ningún edificio: sin asedio, el centro aguanta.
- **Qué esperaría:**
  - que la fácil siga siendo fácil también cuando la atacan, por ejemplo con un tope de defensa de 2 veces el normal;
  - que el aviso y la ficha digan que para tirar edificios hace falta asedio (Taller de tacuara, en edad II).
- **Cómo se reproduce:** `novato4.gd -- --dif=facil --modo=aplicado --seed=7 --sinsitios=1 --ataca=1`. En los tres ataques (semillas 7, 21 y 3), la fácil nunca perdió un edificio.
- **Gravedad:** alta. Es justo el paso que me faltaba en la ronda 3 («aguanto, pero no sé cómo ganar»). Ahora el juego me dice «atacá», ataco, y la fácil se vuelve imposible.

**3. Se acaba la comida y el principiante se queda parado.**
- **Qué hace hoy:** con mi script corregido (solo recursos cerca de casa), el jugador que hace lo que enseña el tutorial (frutos y madera, sin granjas) se queda sin frutos cerca hacia el minuto 8–10.
  - Del minuto 10 en adelante tiene 12–14 de sus 20 aldeanos ociosos y 40 de alimento.
  - Ociosos en promedio: 57–61 %. Pierde a las 18:15 y a las 19:40.
  - El aviso «Se acabaron los frutos cerca del centro: construí Kokue (roza)» existe, pero el tutorial nunca hace construir una granja.
- **Qué esperaría:** que el tutorial tenga un objetivo «construí una granja» (o «carneá un animal»). Es la tercera forma de juntar alimento y la que dura toda la partida.
- **Gravedad:** alta para la primera escaramuza después del tutorial.

### Media

**4. El cursor sobre un animal propio dice «mover».** El autotest falla en eso: «FALLO cursor de juntar alimento sobre un animal propio (mover)». El clic derecho sí lo carnea, pero el cursor anuncia otra cosa. Para alguien nuevo, el cursor es la pista de qué va a pasar. Se reproduce con `godot --path . -- --autotest --civ=guaranies --terreno=llano` (termina «AUTOTEST: FALLO»).

**5. El aviso «atacá» no dice dónde ni con qué.** «A y clic en la base rival», pero la base rival está en la niebla y no sé dónde queda. Esperaría «la base rival está hacia el noreste (mirá el minimapa)», o que el explorador ya la haya mostrado, y una línea sobre el asedio (ver 2).

**6. El panel de abajo, con aldeanos elegidos, sigue vacío.** Un ícono, un 6 y «6 seleccionadas» ([captura 2](capturas/nuevo/02-grilla-economia-tapyi.jpg)). Con el centro elegido, el panel sí ayuda: dice «Clic derecho en el mapa: punto de reunión» ([captura 4](capturas/nuevo/04-centro-guarani.jpg)). Con aldeanos esperaría lo mismo: «Clic derecho en un árbol, arbusto, veta o animal para juntar; Q Economía, W Militar».

**7. Los nombres de la grilla vienen apagados.** Es justo lo que necesita alguien nuevo, y está escondido en Opciones → Ayuda ([captura 6](capturas/nuevo/06-opciones.jpg)). Para la primera partida esperaría que vengan prendidos, como los sitios apagados.

**8. El panel de un edificio elegido dice solo el nombre propio.** «Oga guasu», «Llaqta», sin «Centro» debajo, cuando la ficha y la grilla ya dan los dos.

**9. Nombres cortados en la grilla del centro:** «Mamposteri», «Trabajo de», «Regalo de», «Expulsar guarnición» en dos renglones apretados ([captura 3](capturas/nuevo/03-centro-boton-aldeano-tapado.jpg)).

**10. La ficha tapa el título del submenú** («ECONOMÍA · Esc vuelve» queda debajo). Sigue desde la ronda 1. Mientras miro la ficha no sé en qué submenú estoy.

### Leve

**11. «Barrero».** Es el nombre común del Ñai'ũ renda (recibe piedra y riqueza). No me dice qué guarda: «Depósito de arcilla y riqueza» se entendería.

**12. Las teclas de doble sentido siguen:** Z es hito con un aldeano y campana con el centro. F1 abre «Mi pueblo», no la ayuda.

**13. El crash al salir sigue:** `corrupted size vs. prev_size` / `double free` con volcado de memoria, al cerrar el autotest y las capturas.

### Lo que funciona bien (para no tocar)

- **Defensa:** «¡Nos atacan!» con Espacio para ir, y la campana que refugia y el toque de calma que saca (autotest OK).
- **Edad:** la casilla del hito dice «Faltan 500 de alimento y 300 de riqueza». Al colocarlo se ve el aura, con cuántas fuentes quedan adentro, y la ficha de la obra dice «Faltan 1:54 con 4 constructores» o «Parada: sin constructores». Es lo mejor de la interfaz para alguien nuevo.
- **Aldeanos ociosos:** botón con número, aviso a los 20 s y Mayús + «.» para todos.
- **Recolectar lejos:** el aviso de viaje largo nombra el Tapyi y se calla cuando lo empiezo. La ficha del Tapyi dice «Granero y leñera… Recibe alimento y madera» y «levantalo junto a la caza o el monte» ([captura 2](capturas/nuevo/02-grilla-economia-tapyi.jpg)). Esto contesta la pregunta «¿dónde está el granero?».
- **Selección y cámara:** arrastrar, M (militares), «,» (militar ocioso), T (todos los del tipo), grupos con Ctrl + número, marcadores de cámara y la cola global con clic. Todo pasa en el autotest. Para un principiante son muchas teclas, pero no estorban.
- **Opciones:** claras y en castellano, con la sección «Ayuda» separada ([captura 6](capturas/nuevo/06-opciones.jpg)).

## La IA fácil, ronda 4 (sin sitios)

| Principiante | Semilla | Primer ataque en mi base | Final |
|---|---|---|---|
| Aplicado (rozas, campo de tiro, riqueza) | 7 | 16:37 | **Vivo a los 30:00**; edad II recién a las 29 |
| Aplicado y ataca cuando llega a 15 | 7 | 26:01 | Vivo a los 30:00; la fácil pasa de 39 a 144 de población |
| Aplicado y ataca | 21 | 16:29 | Vivo a los 30:00 con 4 aldeanos; perdí 39 soldados |
| Como enseña el tutorial y ataca | 3 | 16:31 | Pierdo a las 18:15 (sin comida, 57 % ociosos) |
| Como enseña el tutorial | 21 | 16:39 | Pierdo a las 19:40 (61 % ociosos) |
| Tortuga, sin ejército | 7 | 16:37 | Pierdo a las 18:33 |

- La fácil ataca hacia el minuto 16, siempre.
- Con granjas, aguanto. Sin granjas, me quedo sin comida y pierdo.
- **Atacar empeora las cosas**, por el punto 2.

## Errores nuevos o que siguen

| Qué | Cómo reproducirlo |
|---|---|
| El botón del aldeano y el del explorador no se ven en el centro; Q entrena un aldeano bajo un botón que dice «Herramienta de tala» | `--select=centro --nombres=1 --ficha=cmd:0` (cualquier pueblo) |
| La fácil, atacada, produce sin tope (población 147) | `novato4.gd -- --dif=facil --modo=aplicado --seed=7 --sinsitios=1 --ataca=1` |
| Autotest: «FALLO cursor de juntar alimento sobre un animal propio (mover)» | `godot --path . -- --autotest --civ=guaranies --terreno=llano` |
| Crash al salir (`corrupted size` / `double free`) | El mismo autotest, o cualquier captura |

## Mis 10 deseos, actualizados

1. **El botón «Aldeano» en el centro, visible y en Q**, con las investigaciones en otras casillas.
2. **Que la fácil siga siendo fácil cuando la ataco:** un tope de defensa, para que el ataque que pide el aviso se pueda ganar.
3. **Enseñar el asedio:** que el aviso «atacá» diga que los edificios caen con asedio, y dónde está el rival.
4. **Una granja en el tutorial** (o carnear), para no quedarme sin comida en la primera escaramuza.
5. **Nombres en la grilla prendidos la primera vez.**
6. **El cursor de carnear sobre el animal propio.**
7. **Una línea de ayuda en el panel de aldeanos elegidos**, y el nombre común en el panel de los edificios.
8. **Un «arte de la guerra»**, o objetivos sugeridos en la escaramuza.
9. **Que no se corten los nombres de la grilla** y que la ficha no tape el título del submenú.
10. **Campaña recomendada** después del tutorial.

## ¿A los 10 minutos tengo ganas de seguir?

Sí. Los primeros diez minutos ya son buenos: el menú me explica cómo se gana, el tutorial me acompaña hasta durante la obra del hito, la grilla dice «Casa» y «Granero y leñera», y los avisos me corrigen sin retarme. Me frenaron dos cosas:
- **La primera, en el minuto 1:** busco el aldeano en el centro y veo «Herramienta de tala». Para alguien nuevo es desconcertante y hay que arreglarlo ya.
- **La segunda, después:** cuando por fin el juego me empuja a atacar, la fácil se multiplica y no hay forma de ganar.

Con esas dos arregladas, Raíces ya sería un juego en el que un principiante puede ganar su primera partida, que es lo que hace que uno vuelva.
