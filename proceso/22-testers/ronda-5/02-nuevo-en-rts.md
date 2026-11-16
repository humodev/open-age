# Ronda 5 · Jugador nuevo en los RTS

Rondas anteriores: [1](../02-nuevo-en-rts.md), [2](../ronda-2/02-nuevo-en-rts.md), [3](../ronda-3/02-nuevo-en-rts.md) y [4](../ronda-4/02-nuevo-en-rts.md). Lo que se hizo desde la ronda 4: [4n](../../24-tras-la-segunda-ronda/4n-jugador-nuevo-ronda-4.md) (fila S de la etapa 24).

## Qué probé

Rama `main` (f6234d5). La máquina estaba cargada con un torneo de 9 procesos; nunca tuve más de dos procesos de Godot míos a la vez.

| Qué | Comando |
|---|---|
| El centro elegido | `godot --path . -- --civ=guaranies --terreno=llano --seed=7 --shot=x.png --shot-at=3 --select=centro` |
| Aldeanos elegidos (panel de varias unidades) | `… --select=aldeano` |
| La ciudad a los 10 minutos, con la escala nueva | `godot --path . -- --aivai --civ=guaranies --rival=tawantinsuyu --terreno=llano --seed=7 --speed=8 --shot=x.png --shot-at=600 --cam=b2,b2` |
| Opciones y teclas | `godot --path . -- --menu --abrir=opciones --shot=x.png --shot-at=2` |
| Controles reales | `godot --path . -- --autotest --civ=guaranies --terreno=llano` |
| Tutorial al pie de la letra | `godot --headless --path . -s tests/tutorial_letra.gd -- --modo=letra` |
| ¿Le gano a la fácil? | `novato5.gd`: mi script de la ronda 4, más lo que dice el aviso nuevo. Con `--asedio=1` levanta el taller y entrena arietes en la edad II; con `--ahorra=1`, en la edad I se queda con 8 soldados para llegar antes al hito. Ataca con 15 o más y 2 arietes o más. Sin sitios, guaraníes contra Tawantinsuyu fácil en llano, 30 minutos |
| Si una granja se trabaja sola | `granja_probe.gd`: un aldeano levanta una granja y se mira qué hace a los 2 minutos |

**Corregí otra vez mi script.** Mandaba siempre al mismo aldeano a levantar cada granja nueva, así que dejaba la anterior sin trabajar y tenía 1–3 aldeanos en la comida. No era culpa del juego: con `granja_probe.gd`, el aldeano que levanta una granja se pone a trabajarla solo, en guaraníes y en Tawantinsuyu. Las partidas de abajo son con el script corregido.

## Los arreglos de la ronda 4, uno por uno

| # | Pedido de la ronda 4 | ¿Quedó bien? |
|---|---|---|
| 1 | Aldeano en Q y Explorador en W en el centro | **Sí.** «Aldeano / Ava» en Q y «Explorador / Baqueano» en W. Las investigaciones bajaron a E R / A S D F / C, y la campana está en Z ([captura 1](capturas/nuevo/01-centro-aldeano-en-q.jpg)). El autotest lo verifica con lo que se dibuja: «la grilla del centro dibuja «Ava» en Q y «Baqueano» en W» |
| 2 | Tope para la fácil cuando la atacan | **Sí, el tope está.** Con mis ataques la fácil quedó en 36–58 de población (en la ronda 4 llegaba a 147). **Pero sigo sin poder ganarle** (ver abajo) |
| 3 | El aviso «atacá» dice dónde y con qué | **Sí, según el autotest:** «el aviso dice hacia dónde está la base rival y la marca en el minimapa» y «el aviso dice que los edificios caen con asedio». No lo pude capturar en pantalla |
| 4 | Granja en el tutorial | **Sí.** A las 4:15 aparece «Se acaban los frutos: construí una granja junto al centro…» con un mensaje de la Guía. Al pie de la letra, la granja queda hecha a las 4:36 y se gana a las 11:07 |
| 5 | Cursor sobre el animal propio | **Sí.** Autotest: «cursor de juntar alimento sobre un animal propio» y «con el aldeano pegado al animal, el cursor sigue en juntar». Autotest completo: **OK, 101 chequeos** |
| 6 | Nombres en la grilla prendidos la primera vez | **Sí** ([captura 4](capturas/nuevo/04-opciones-teclas.jpg): «Mostrar nombres en la grilla: Sí») |
| 7 | Ayuda en el panel de aldeanos elegidos | **Sí, muy bien.** Seis retratos y abajo «Clic derecho en un árbol, arbusto, veta o animal: juntan. En una obra: construyen. Q Economía · W Militar · S Detener · F Refugio» ([captura 2](capturas/nuevo/02-aldeanos-elegidos.jpg)) |
| 8 | Nombre común en el panel del edificio | **Sí:** «Centro · Oga guasu». Y además el panel explica el círculo: «Círculo en el mapa: alcance de las flechas, 7 casillas desde el borde». Me gustó mucho |
| 9 | Nombres sin cortar, la ficha sin tapar el título | **Casi.** En la grilla del centro se leen «Herramientas de tala», «Trabajo de la riqueza», «Expulsar guarnición». En la grilla de aldeanos, los hitos dicen «Hito · edad II» y se corta la última letra («Hito · edad I…») |
| 10 | «Barrero» | Ahora es «Depósito de piedra y riqueza», según el 4n. No lo capturé |

**Resumen:** de los 10 pedidos quedaron bien 9. El que no se cumple del todo es el 2: el tope está, pero el ataque igual no sirve.

## ¿Le gano a la fácil?

**No.** Ahora llego vivo a los 30 minutos casi siempre, pero no le tiro ni un edificio.

| Principiante | Semilla | Edad II | Asedio | Ataques | Final |
|---|---|---|---|---|---|
| Plan (ahorro, hito, taller, arietes, ataque) | 7 | entre 10 y 11 (hito encargado a las 8:20) | 2–4 arietes desde el minuto 14 | 5 (14:00 a 28:00) con 19–29 soldados | Vivo a los 30:00; perdí 49 soldados; **la capital rival sigue en 2400/2400** |
| Igual | 21 | entre 10 y 11 | 2–3 arietes | 3 | Vivo a los 30:00; perdí 50 soldados |
| Igual | 3 | entre 10 y 11 | 2–4 arietes | 5 | Vivo a los 30:00; perdí 36 soldados |
| Aplicado, ataca sin ahorrar | 7 | 28:00 | ninguno (la edad II llega tarde) | — | Vivo a los 30:00 |
| Como enseña el tutorial, sin granjas | 21 | nunca | — | — | Pierdo a las 18:04 (61 % ociosos, sin comida) |

**Mirando la semilla 7 por dentro** (`novato5b.gd` anota los edificios rivales en cada ataque):
- La fácil tiene un centro, 5 casas, 5 campos de tiro, un cuartel, una torre, 7 granjas, mercado y ushnu. Además, 61–91 tramos de **camino** inca, que el conteo de edificios suma.
- Entre el minuto 14 y el 26 no perdió **ningún** edificio. La capital, intacta.
- Mis tropas mueren en el camino o frente a los campos de tiro y la torre. Los arietes no llegan a la capital.

**Qué entiendo yo, jugando:**
- El juego me dice «atacá, con asedio», y lo hago. Pierdo 40–50 soldados sin saber qué pasó.
- La pantalla de fin me diría «ejército mucho más chico» o nada, porque la partida no termina.
- No hay forma de ver «por qué no avanzo». Me haría falta:
  - un aviso «tu ataque perdió: 20 de tus tropas cayeron frente a la torre y los arqueros»;
  - un consejo «los arietes tienen que ir protegidos; atacá primero el edificio más cercano».

**La comida sigue siendo la trampa del principio.** Quien no levanta granjas (lo que hacía el tutorial antes) se queda con 13 de 20 aldeanos ociosos desde el minuto 10. Ahora el tutorial enseña la granja, así que el que lo jugó debería saberlo. El aviso de frutos agotados también lo dice, aunque mi script no lo lee.

## Cómo se ve con la escala nueva

[Captura 3](capturas/nuevo/03-ciudad-minuto-10.jpg): la ciudad guaraní de la IA a los 10 minutos.
- **Los aldeanos se encuentran,** gracias al disco azul debajo de cada uno. Sin el disco serían difíciles de ver: son chicos y su color se mezcla con la tierra y el pasto. Las «Zz» de los ociosos se ven siempre.
- **Los edificios se distinguen a medias.**
  - El centro con su empalizada, las granjas (rectángulos verdes con surcos) y las casas (techo de paja a dos aguas) se reconocen.
  - Pero hay tres o cuatro edificios de techo color paja, casi iguales: tapyi, campo de tiro y cuartel. No sé cuál es cuál sin pasar el mouse.
  - Cada edificio tiene una bandera azul grande. Ayuda a saber que es mío, pero llena la pantalla de banderas iguales.
- **El monte** se ve alto y lleno; las siluetas detrás del bosque no las pude probar en una captura.
- **Lo que esperaría:** un ícono chico o una silueta propia por función sobre cada edificio (granero, casa, cuartel), al menos en el modo con nombres. Por ejemplo, el ícono de la grilla flotando sobre el techo al mantener una tecla.

## Calidad de vida y usabilidad, por gravedad

### Grave

**1. Atacar no da resultado y nadie me dice por qué.**
- **Qué hace hoy:** como cuenta la sección de arriba, tres partidas, 13 ataques, 0 edificios.
- **Qué esperaría:**
  - un resumen del ataque («perdiste 20, mataste 6; te frenaron la torre y los campos de tiro»);
  - que la fácil defienda con menos (¿sin torre en la fácil?);
  - o un «arte de la guerra» que enseñe a atacar.
- **Cómo se reproduce:** `novato5.gd -- --dif=facil --modo=aplicado --seed=7 --sinsitios=1 --ataca=1 --asedio=1 --ahorra=1 --min=30`.
- **Gravedad:** alta. Es el último paso para que un principiante gane su primera partida.

### Media

**2. Edificios del mismo color y forma.** Tapyi, campo de tiro y cuartel se parecen a la escala nueva (ver arriba).

**3. «Hito · edad II» se corta en la grilla de aldeanos** («Hito · edad I…»), y con eso parece que el hito es de la edad I ([captura 2](capturas/nuevo/02-aldeanos-elegidos.jpg)).

**4. «Teclas» en Opciones está bien,** pero un principiante no sabe qué tecla hace qué. Ayudaría una hoja de atajos de una pantalla (F1 o desde la pausa) con las más usadas: H, punto, Ctrl + número, A, Z, Espacio. Hoy los controles están al final de «Mi pueblo».

### Leve

**5. El crash al salir** de las capturas y el autotest sigue (`corrupted size` / `double free`).

**6. Las banderas de cada edificio** son muchas y grandes a la escala nueva.

### Lo que anda muy bien

- El panel del centro explica el círculo de alcance de las flechas.
- El panel de varias unidades, con retratos y ayuda de teclas.
- El tutorial con la granja.
- La grilla con nombres, prendida desde el principio.
- El autotest pasa entero (101 chequeos).

## Mis 10 deseos, actualizados

1. **Poder ganarle a la fácil atacando:** que la fácil tenga defensas más flojas (sin torre, menos campos de tiro) o que mi ataque se explique.
2. **Un resumen de cada pelea grande:** cuántos perdí, cuántos maté y qué me frenó.
3. **Un «arte de la guerra»** con una misión «tirá un centro con arietes».
4. **Que los edificios se distingan** a la escala nueva (ícono de función).
5. **Hoja de atajos de una pantalla.**
6. **«Hito · edad II» entero en la grilla.**
7. **Objetivos sugeridos en la escaramuza** («llegá a la edad II antes del minuto 12», «construí un taller»).
8. **Campaña recomendada** después del tutorial.
9. **Menos banderas, o más chicas.**
10. **El crash al salir.**

## ¿A los 10 minutos tengo ganas de seguir?

Sí, y cada vez más. Los primeros diez minutos ya están muy bien: el centro dice «Aldeano» donde tiene que decirlo, el tutorial me enseña hasta la granja, los paneles explican cada cosa y llego a la edad II entre los minutos 10 y 11 si ahorro. Lo que me falta es el final: la primera victoria. Ataqué trece veces con arietes, como me dijo el juego, y no tiré nada. Si la fácil se pudiera ganar, o si el juego me explicara por qué perdí la pelea, me quedaría jugando.
