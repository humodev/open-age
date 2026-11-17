# 27 · Animaciones, paso 2: soldados a pie y el aspecto del aldeano (C-98 c)

## Pedido

Paso 2 de las animaciones, sobre el paso 1 (`README.md` de esta carpeta):

1. **C-98 c:** que el aldeano animado se integre mejor. Telas y pieles más terrosas, con menos blanco plano, y sombreado o un poco de textura procedural en las piezas. Compararlo con las capturas 04 y 05, a la misma distancia de juego.
2. **Soldados a pie:** guerrero, lancero, hondero o arquero, arcabucero, y las tropas propias a pie de cada pueblo que tengan forma de persona. Sumar al extractor las animaciones de combate de KayKit, con el arma en una mano y el escudo en la otra, el equipo por pueblo y por edad de la maqueta, el ataque sincronizado con la cadencia de la simulación (cada golpe reinicia el gesto) y la marcha en formación sin patinar.
3. **Rendimiento:** compartir esqueletos y animaciones entre las unidades iguales; medir con 200 soldados y 100 aldeanos en pantalla, con el LOD y el tope por cuadro; dejar el interruptor en `data/`.
4. **Caballos y elefantes:** no entran; anotar qué haría falta.
5. **Capturas y un video corto** de una batalla de cerca, en dos pueblos.

## Resultado

- **El aldeano, más terroso** (C-98 c): [antes y después a la misma distancia](capturas/11-c98-antes-y-despues.jpg) (Meshy, paso 1 y paso 2, recortes del mismo lugar de la partida), [la partida entera](capturas/12-c98-partida-guaranies.jpg) y [la vitrina de los seis pueblos](capturas/13-vitrina-aldeanos-paso2.jpg) (comparar con [la del paso 1](capturas/01-vitrina-seis-pueblos.jpg)).
- **Soldados a pie animados** en los seis pueblos y en los rivales de campaña: [vitrina del golpe](capturas/14-vitrina-soldados.jpg), [de cerca](capturas/15-soldados-de-cerca.jpg), [arqueros tensando y soltando](capturas/16-arqueros-tensar-y-soltar.jpg), [lanceros con la estocada](capturas/17-lanceros-estocada.jpg), [arcabuceros: disparo y recarga](capturas/18-arcabuceros-disparo-y-recarga.jpg).
- **Batallas de cerca:** [mapuches contra incas](capturas/19-batalla-mapuches-incas.jpg) y [guaraníes contra Ayutthaya](capturas/20-batalla-guaranies-ayutthaya.jpg). Videos de 9 s a velocidad real: [mapuches contra incas](videos/batalla_mapuches_incas.mp4) y [guaraníes contra Ayutthaya](videos/batalla_guaranies_ayutthaya.mp4).
- **Esqueletos compartidos:** con 283 figuras animadas en pantalla, la vista tarda 8,2 a 8,5 ms por cuadro con todas moviéndose en cada cuadro, contra 11,4 a 11,6 ms si cada una tiene su esqueleto (ver "Rendimiento").
- **Interruptores**, todos en `data/arte_animaciones.json`: `activo` (toda la gente animada), `tropas.activo` (solo los soldados; con `false` vuelven a la maqueta o al modelo de Meshy) y `rendimiento.compartir`. En la línea de comandos: `--animaciones=0` y `--compartir=0`.
- **Solo imagen:** el hash del determinismo no cambió (`2203695307`).

## 1. El aspecto del aldeano (C-98 c)

**Qué lo hacía blanco.** En el paso 1, la tela de los pueblos sin `tela` propia era la arcilla del pueblo aclarada (como la maqueta), y las prendas venían de la maqueta: el tipoy guaraní `#efe6cf`, la shamma etíope `#f2eee4`. Con el sol del juego y el suelo claro, de lejos se leían como figuras de yeso.

**Qué cambió:**

- **Colores terrosos** (`vestimenta` y `colores` en los datos): cada forma tiene su `tela` (ya no se aclara la arcilla), el tipoy pasó a algodón crudo `#a08054`, la shamma a `#b5a682` (sigue siendo la más clara), y la piel a `#8c5636`, más rojiza y oscura. Las herramientas, el cuero y la piedra también bajaron un tono.
- **Trama de tela procedural:** un material propio (`AldeanoAnimado._material`, un shader corto) multiplica el color de cada vértice por una trama de 64×64 hecha en código, con hilos cruzados y ruido. Cada pieza dice qué es (`Pieza`: tela, piel, metal, madera, pelo), así la trama se ve entera en la ropa, poco en la piel y casi nada en el metal, que además brilla un poco.
- **Sombra horneada:** cada vértice se oscurece hacia los pies (`aspecto.sombra_pies_pct`) y hacia abajo de su pieza. Da volumen sin luces extra.
- **Un tono por figura:** ±7 % (`aspecto.variacion_pct`) con un parámetro por instancia del shader, sin mallas nuevas. Un grupo no se ve clonado.

**Comparación** ([11](capturas/11-c98-antes-y-despues.jpg)): el mismo inicio de partida guaraní en llano, a los 3 s, a la distancia normal de la cámara. El aldeano del paso 2 queda en la gama de los modelos de Meshy (pardo rojizo), aunque sigue siendo más chico de silueta y menos detallado de cerca. La opción a de C-98 (riggear los modelos de Meshy) sigue abierta.

## 2. Soldados a pie

### Quiénes

Todos los que tienen forma de persona y van a pie (`tropas.funciones`: choque, línea, distancia y explorador; del asedio, solo los que tienen equipo en los datos, como los incendiarios mapuches):

| Tipo | Arma (mano derecha) | Izquierda | Golpe |
|---|---|---|---|
| Guerrero | maza de piedra; macana a dos manos (guaraníes, tupíes, mapuches); hacha (cañaris); espada recta y escudo (rodelero, Adal); espada (birmanos); dap, una en cada mano (Ayutthaya) | — | golpe con una mano, con dos, o con las dos espadas |
| Lancero | lanza (más larga para mapuches y piqueros) | escudo redondo; cuadrado para incas y la leva (awqa); sin escudo, con la lanza a dos manos, mapuches y piqueros | estocada (con una o con dos manos) |
| Hondero o arquero | honda (incas, cañaris, chankas); arco y carcaj (guaraníes, mapuches, Palmares, Ayutthaya, Adal); jabalina (Etiopía); estólica (caranquis); ballesta (invasores) | el arco va en la izquierda | lanzar (honda, jabalina, estólica); tensar y soltar (arco); disparar y recargar (ballesta) |
| Arcabucero | arcabuz | apoya el caño | disparar, recargar y apuntar |
| Propios | boleador (honda de tres piedras, incas), compañía japonesa (katana a dos manos), incendiarios (antorcha), exploradores (vara) | — | lanzar, golpe a dos manos, golpe, estocada |

Quedan afuera los montados (jinetes, el guerrero etíope), los elefantes, la corte móvil, las piezas de artillería, el ariete y la catapulta. Las armas por pueblo son una lectura de los nombres de las unidades y de la maqueta; las afirmaciones históricas siguen con `[verificar]` en las fichas (regla 5 del índice).

**Equipo por edad:** los soldados toman de `data/arte_edades.json → tropa` la tela (un 18 % más oscura que en la maqueta, `aspecto.tela_tropa_pct`), el casco (en lugar del tocado), el borde del escudo y el pectoral de oro. Cuando el pueblo sube de edad, la vista les cambia la malla (`AldeanoAnimado.equipar`).

### Las animaciones nuevas

`tools/kaykit_extraer.py` suma 16 a las 13 del paso 1, en el mismo glTF, que pasó a llamarse `personas_kaykit.glb` (1140 KB, antes 724 KB):

- Cuerpo a cuerpo: `Melee_1H_Attack_Chop` (ya estaba), `Melee_1H_Attack_Stab`, `Melee_2H_Attack_Chop`, `Melee_2H_Attack_Stab`, `Melee_Dualwield_Attack_Slice`, `Melee_2H_Idle` (guardia a dos manos), `Melee_Blocking` y `Melee_Block_Hit` (bloqueo).
- A distancia: `Ranged_Bow_Draw`, `Ranged_Bow_Release`, `Ranged_Bow_Idle`; `Ranged_2H_Shoot`, `Ranged_2H_Reload`, `Ranged_2H_Aiming` (arma de fuego). **La honda no está en KayKit**: se usa `Throw`, un lanzamiento por arriba.
- Generales: `Hit_B`, `Death_B`, `Throw`. Correr (`Running_A`) y recibir un golpe (`Hit_A`) ya estaban.

**Ciclos encadenados:** una acción puede pedir varias animaciones seguidas (`"anims"` en los datos). El arco es soltar y volver a tensar (`Ranged_Bow_Release` + `Ranged_Bow_Draw`); el arcabuz, disparar, recargar y apuntar. `AldeanoAnimado._encadenar` las junta en una sola animación en bucle al cargar.

### El arma en la mano

Las armas cuelgan de `handslot.r` y el escudo y el arco de `handslot.l`, como en KayKit Adventurers: el escudo redondo del Bárbaro está en `handslot.l` sin girar y con la cara hacia +z. Para el arco y el arcabuz se midieron los ejes de las manos en las animaciones (posición y ejes de cada `handslot` en el modelo):

- **Arco:** con el arco tenso, el +z de `handslot.l` apunta arriba y el +x, hacia el arquero. Las palas van por ±z y se curvan hacia +x, donde va la cuerda.
- **Arcabuz y ballesta:** el caño va de la mano derecha a la izquierda tal como quedan al apuntar (`Ranged_2H_Aiming`). La dirección se calcula al cargar (`TropaAnimada._apunte`), así las dos manos quedan sobre el arma.
- **Lanza:** el asta sale 30 cm por detrás del puño, por el +y de la mano, que en la estocada apunta adelante.

### El golpe, a tiempo con la simulación

- **El ciclo dura la cadencia:** mientras pelea, la animación de ataque avanza a `largo / cadencia_ms`, en tiempo de juego.
- **Cada golpe la lleva al impacto:** cuando llega el evento `hit` de la simulación, la animación salta al momento en que el arma pega (o sale el tiro). Como el ciclo dura la cadencia, el siguiente golpe cae justo y el salto es de cero. El momento se mide solo al cargar: es el instante en que la mano del arma va más rápido (`_impacto`). Se puede fijar en los datos (`impacto_pct`); el arco (5 %) y el arcabuz (4 %) lo fijan, porque la costura entre las dos animaciones encadenadas engaña a la medición.
- **Los de tiro también:** antes el evento `hit` a distancia no avisaba al tirador; ahora sí, y la flecha sale de los arqueros y ballesteros animados (antes salía una piedra de todos los tiradores de a pie).
- **Recibir un golpe:** el que recibe hace `Hit_A` o, si tiene escudo, `Melee_Block_Hit` el 60 % de las veces (`reaccion.bloquear_pct`). Solo de cerca (con esqueleto propio), si no camina y, si está peleando, si le alcanza el tiempo antes de su propio golpe; después vuelve al ciclo de ataque en el punto en que estaría, porque el reloj del ataque sigue corriendo aparte.
- **Morir:** los soldados caen de dos maneras (`Death_A`, `Death_B`).

### La marcha sin patinar

Como en el paso 1, con esqueleto propio el paso sigue a la distancia recorrida. Con esqueleto compartido (ver abajo), el paso se toma de la velocidad que manda la simulación: la del grupo en marcha (`SimGroups`, `spd`) o la de la unidad. Si la velocidad medida está a menos de un 12 % de esa (`ajuste_paso_pct`), toda la tropa en marcha comparte el mismo paso. Si no (empujado, arrancando), se usa la medida.

## 3. Rendimiento: esqueletos compartidos

**La idea.** En Godot 4, una malla con piel se dibuja donde está su `MeshInstance3D`, no donde está el `Skeleton3D`. Entonces un solo esqueleto animado puede mover a muchas figuras en lugares distintos. Se probó primero con tres figuras colgadas de un esqueleto fuera de cuadro, y cada una quedó en su lugar.

**Cómo quedó** (`AldeanoAnimado.Coro`):

- Las figuras que hacen lo mismo (quieto, caminar al mismo paso, un trabajo, el mismo golpe) usan un esqueleto compartido por animación, paso y fase. Los esqueletos de una misma animación y un mismo paso forman un grupo con un reloj común, y cada uno va corrido una fracción del ciclo (`fases`: 3), así la multitud no se mueve al unísono.
- **El golpe también se comparte**, con 6 fases por ciclo (`fases_ataque`): cada figura toma el esqueleto cuya fase está más cerca de su propio ciclo de ataque. El error es de un doceavo de ciclo como mucho.
- **El esqueleto propio** se arma recién cuando hace falta: de cerca (a menos de `compartir_desde_m`, 34 casillas, o a menos de `cerca_m`, 18, cuando hay más de 90 figuras en pantalla), para la reacción a un golpe y para morir. Al pasar de uno compartido al propio, la figura sigue desde la misma pose.
- **Pasos:** un 8 % entre uno y otro (`paso_pct`). Caminando con la velocidad medida, un 15 % (`paso_caminar_pct`), y nunca más lento que la mitad (`paso_min_pct`), porque los empujados en un montón caminaban a 20 velocidades distintas.
- **Lo que se mantiene:** fuera de la pantalla no se anima; lejos (`lejos_m`), se miran a la mitad de cuadros; el tope por cuadro (`max_por_cuadro`: 80) vale aparte para las de esqueleto propio y para las compartidas. Las compartidas se mueven solas en cada cuadro: el tope solo decide cada cuántos cuadros se mira si cambiaron de estado.
- Un esqueleto compartido que nadie usó en los últimos 12 cuadros deja de avanzar; si se vuelve a usar, se pone en hora con el reloj de su grupo.

**Medición** (`tools/aldeanos_animados.gd --modo=fps --soldados=200 --aldeanos=100`; `pruebas/02-fps_200_soldados_100_aldeanos.txt`): 100 soldados que marchan en formación de un lado a otro, 100 que pelean en dos bandos (con vida de sobra, para que la cuenta no baje), 50 aldeanos que caminan y 50 que talan; 283 figuras dentro del cuadro. 1920×1080, RTX 2060 Super, con una carga de la máquina de 7 a 10 (más tranquila que en el paso 1). Dos corridas de cada modo, intercaladas:

| Modo | Vista por cuadro (`WorldView.render`) | Cuadros por segundo | Cómo se mueven |
|---|---|---|---|
| **Compartidos** (lo de `data/`) | 8,2 – 8,5 ms | 34,7 – 35,8 | todas, en cada cuadro |
| Esqueleto propio, 80 por cuadro (`--compartir=0`) | 7,7 – 7,9 ms | 34,7 – 35,1 | cada una, cada 4 cuadros |
| Esqueleto propio, todas en cada cuadro | 11,4 – 11,6 ms | 29,5 – 29,9 | todas, en cada cuadro |
| Sin animar (`--animaciones=0`) | 5,5 – 5,6 ms | 41,3 – 41,7 | maqueta y Meshy |

- **Con la misma fluidez, compartir ahorra unos 3 ms por cuadro** (8,3 contra 11,5) y 6 cuadros por segundo.
- Contra el modo del paso 1 (esqueleto propio con tope), cuesta 0,5 ms más, pero todas las figuras se mueven en cada cuadro en vez de a saltos de 4 cuadros.
- En la corrida típica quedan unos 80 esqueletos compartidos andando y 7 propios, para 283 figuras.
- La animación cuesta, en total, unos 3 ms por cuadro sobre la figura quieta de antes.
- **Lo que no baja:** el skinning en la GPU se hace por malla, compartan o no el esqueleto.

## 4. Caballos y elefantes (no entran en este paso)

Qué haría falta:

1. **El animal:** KayKit no trae cuadrúpedos. **Quaternius, Ultimate Animated Animal Pack (CC0)** tiene caballo con paso, trote, galope, quieto, ataque y muerte. Hay que verificar si trae elefante; si no, se puede buscar otro CC0 (por ejemplo, en Poly Pizza) o armar el elefante con piezas rígidas por hueso, como la gente. Pasaría por el mismo extractor, en un glTF aparte.
2. **El jinete:** el mismo esqueleto de persona, sentado. KayKit Character Animations trae `Sit_Chair_Idle` y `Sit_Floor_*` en el paquete Simulation (`Rig_Medium_Simulation.glb`, que ya está en la descarga). Se arma una animación por golpe con las piernas de la pose sentada y el torso y los brazos del golpe (copiar las pistas de `hips` para abajo de una y de `spine` para arriba de la otra, como hace `_encadenar` con el tiempo). El esqueleto del jinete cuelga de un hueso del lomo del caballo (como el arma de `handslot.r`).
3. **El paso del caballo:** el mismo método que el de la persona: medir la velocidad del casco de apoyo en el paso y en el galope, y avanzar la animación por la distancia. El cambio de paso a galope va por pasos por segundo, como el trote de la gente.
4. **El elefante:** paso lento, el howdah y el cornaca sentados (la misma pose sentada), y el golpe de área de la simulación como un cabezazo o una patada.
5. **Rendimiento:** los esqueletos compartidos sirven igual. El caballo y el jinete serían dos esqueletos por coro.
6. **Datos:** `tropas.funciones` y `usa()` hoy excluyen `montado` y `elefante`. Habría que sumar un bloque `montados` con el animal por pueblo (caballo, kona mapuche, el jinete noble etíope) y su equipo.

## Paso a paso

1. **El extractor:** se agregaron las animaciones de combate a `ANIMS` y se volvió a correr con Blender 5.2 sobre la descarga del paso 1. El glTF pasó de 724 a 1140 KB. Ya no sale la textura del maniquí (era del maniquí, que no se usa).
2. **El cuerpo común:** el cuerpo del aldeano pasó a `AldeanoAnimado.cuerpo`, y el equipo de los soldados quedó en `src/game/tropa_animada.gd` (`TropaAnimada.equipo` lee los datos; `TropaAnimada.malla` arma la malla, en caché por combinación).
3. **La vitrina de soldados** (`--modo=tropas`), con `--tipo=X --tiempos=…` para ver un tipo en varios momentos del ciclo. Con ella y con los ejes de las manos se orientaron el arco, el escudo y el arcabuz.
4. **La batalla en la partida** (`--modo=batalla --civ=A --rival=B`): los dos bandos en filas (cuerpo a cuerpo adelante, tiro atrás), sin IA, que chocan en un campo abierto. Saca capturas y, con `--seguir=S`, sirve para grabar el video.
5. **El aspecto** (C-98): el material con la trama, los colores y la comparación al mismo encuadre que las capturas 04 y 05 (`--civ=guaranies --terreno=llano --shot-at=3`).
6. **Esqueletos compartidos:** primero por animación, paso y fase. Después, el golpe compartido por fase, el paso tomado de la simulación y los pasos gruesos para los empujados (ver "Tropiezos").

Los videos salen del Movie Maker de Godot, como en el paso 1:

```
godot --path . --write-movie /tmp/b.avi --fixed-fps 30 -s tools/aldeanos_animados.gd -- --modo=batalla --civ=mapuches --rival=tawantinsuyu --terreno=llano --nofog --mute --seed=7 --sin_hud --dx=1 --dz=0 --pitch=42 --zoom=7 --seguir=11 --ventana=1280x720
ffmpeg -ss 1.3 -i /tmp/b.avi -t 9 -vf scale=854:-2 -c:v libx264 -crf 32 -pix_fmt yuv420p -an videos/batalla_mapuches_incas.mp4
```

## Tropiezos

- **El arco salía acostado.** Se lo había puesto a lo largo del +y de la mano, como las armas de la derecha, pero en la mano izquierda, con el arco tenso, el que apunta arriba es el +z. Se midieron los ejes de los `handslot` en cada animación (posición y ejes en el modelo) en vez de adivinar.
- **El impacto del arco caía en la costura.** La medición automática (la mano más rápida) encontraba el salto entre el final de soltar y el principio de tensar. Se fijó `impacto_pct` para el arco y el arcabuz.
- **Demasiados esqueletos compartidos.** La primera versión armaba uno por cada velocidad medida: con la gente empujándose, 110 de caminar y 25 de correr, y compartir costaba más que no compartir. Se arregló con el paso de la simulación, los pasos gruesos para el paso medido y el piso de media velocidad: de 180 esqueletos andando a 80.
- **Todos terminaban con esqueleto propio.** Una versión solo compartía la caminata con el paso parejo. Al arrancar, todos pasaban por el propio y se quedaban con uno armado. Se sacó esa condición.
- **La cámara se iba sola en las mediciones:** el mouse quedaba en el borde de la ventana y la cámara se desplazaba. La herramienta apaga `edge_pan`.
- **La IA rival movía a los soldados de la batalla.** La herramienta vacía `sim.ais` para la batalla y la medición.
- **zsh no parte las variables:** una corrida con `$m="--compartir=0 --max_por_cuadro=1000"` pasó todo como un solo argumento, y el tope quedó en 80. Está marcada en el archivo de la medición y se repitió con los argumentos separados (las corridas "bis").
- **Autotest guaraní intermitente:** la primera corrida falló en «cursor de juntar alimento sobre un animal propio (mover)», con otro Godot corriendo al lado; las dos siguientes (animado y `--animaciones=0`) pasaron.

## Pruebas

- `tests/test_determinism.gd`: **DETERMINISMO: OK**, `hash=2203695307`, el mismo de antes (`pruebas/02-test_determinism.txt`).
- `tests/bench.gd`: 200 unidades, 600 ticks, promedio de 9,35 ms contra un presupuesto de 100 ms (`pruebas/02-bench.txt`).
- Autotest `--civ=mapuches --terreno=llano`: **4 fallas, las mismas con `--animaciones=0`**, así que no vienen de este cambio (`pruebas/02-autotest-mapuches.txt` y `02-autotest-mapuches-sin-animaciones.txt`): «otra H lleva al centro siguiente», «H dos veces seguidas centra la cámara en ese centro», «una investigación de la edad 0 queda bloqueado» y «en la grilla, lof dice que recibe alimento». Se revisó la captura de la pelea del autotest ([22](capturas/22-autotest-mapuches.jpg)).
- Autotest `--civ=guaranies --terreno=llano`: **AUTOTEST: OK** (ver el tropiezo de arriba; `pruebas/02-autotest-guaranies.txt`).
- Una partida de IA contra IA de 10 minutos a ×8 (Palmares contra Etiopía), sin errores de script.
- Cuadros por segundo: `pruebas/02-fps_200_soldados_100_aldeanos.txt`.

## Peso agregado

- `assets/animaciones/kaykit/personas_kaykit.glb`: 1140 KB, 416 KB más que el `aldeano_kaykit.glb` que reemplaza. Se borró la textura del maniquí (18 KB).
- Esta carpeta: 1,9 MB de capturas (11 a 22) y 2,0 MB de videos (dos de 9 s).
- Código: `src/game/aldeano_animado.gd` (de 600 a unas 1000 líneas: esqueletos compartidos, golpe, reacción, aspecto), `src/game/tropa_animada.gd` (210, nuevo), unas 45 líneas en `world_view.gd`, 5 en `main.gd`, y la herramienta `tools/aldeanos_animados.gd` (vitrina de soldados, batalla, medición con soldados).

## Lo que falta

1. **Caballos y elefantes:** ver la sección 4.
2. **Detalles de los soldados:**
   - El escudo cuadrado inca queda como una bandeja en la estocada a una mano, porque el brazo izquierdo se abre.
   - El arco va acostado mientras camina.
   - La honda es una cuerda rígida, no gira.
   - No hay flecha en la cuerda.
   - Los exploradores llevan una vara; el chaski, el werken y el mensajero podrían ir sin arma.
3. **Retrato del panel:** el retrato de la unidad en la interfaz sigue mostrando la maqueta.
4. **Los honderos de Meshy** (`guaranies_arquero`, `palmares_flecheiro`, `tawantinsuyu_hondero`) quedan reemplazados por la figura animada. Para volver a verlos: `tropas.activo: false`.
5. **C-98 a:** riggear los modelos de Meshy para tener el detalle y el movimiento (receta en el `README.md`).
6. **Rendimiento:** de lejos, una malla con menos vértices (nivel de detalle), porque el skinning en la GPU no se comparte.
7. **C-65 (velocidad):** con los soldados animados ya se puede mirar si la tropa camina demasiado rápido para su tamaño.

## Para consultar con el autor

Va a `proceso/CONSULTAS.md` cuando se integre, porque esta tarea no toca ese archivo:

- **C-98:** ¿alcanza el tono nuevo ([11](capturas/11-c98-antes-y-despues.jpg)) o lo bajamos más? La piel sigue siendo una sola para todos los pueblos (`colores.piel`). ¿Un tono por pueblo?
- **Armas por pueblo:** ¿están bien la macana a dos manos (guaraníes, tupíes, mapuches), las dos espadas del guerrero de Ayutthaya, la jabalina etíope en lugar de la honda y la estólica caranqui? Todo se cambia en `tropas.por_forma` y `tropas.por_civ`.
- **Autotest de los mapuches:** tiene 4 fallas que no vienen de las animaciones (H para recorrer los centros, una investigación de la edad 0 y la ayuda del lof). Quedan anotadas para otra tarea.

## Commits

- `Etapa 27, paso 2: soldados a pie animados, esqueletos compartidos y el aldeano más terroso (C-98 c)` (rama `worktree-agent-a6f7f27612aaa574b`).
