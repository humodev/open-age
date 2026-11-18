# Fluidez para el que construye: informe del jugador de economía y defensa (ronda 7)

**Quién soy.** Juego de «boomer» y defensivo: partidas largas, en equipo (de 2v2 a 4v4), con una economía grande que se maneja sola, murallas, torres y una base ordenada. Vengo de AoE2 DE, de AoE4 y de los de construcción (Anno 1800, Manor Lords). La micro de combate me importa poco. Lo que no banco es repetir el mismo clic cien veces en una partida de una hora.

**Qué jugué y miré** (main en `ede1c5a`, 2026-11-17):

- Autotest con Etiopía en llano: 147 controles OK.
- `--demo=base` con Etiopía en la edad III ([captura 1](capturas/constructor-fluidez/01-base-demo.png)).
- Un 2v2 de IA a los 15 minutos, con el panel de economía abierto ([captura 2](capturas/constructor-fluidez/02-2v2-economia-15min.png)).
- La colocación de una granja ([captura 3](capturas/constructor-fluidez/03-colocar-granja.png)).
- Un 4v4 de IA a los 20 minutos, con 1.000 entidades activas ([captura 4](capturas/constructor-fluidez/04-4v4-20min.png)).
- El código de `src/game/controller.gd`, `hud.gd`, `minimap.gd`, `src/game/ui/*` (cola global, colocación, ficha, consejos, puntaje, economía) y de `src/sim/sim.gd` (órdenes, construcción, reunión, reparación y rebusca).

Escribí el informe antes de leer el del veterano. La comparación va al final.

> Nota de método: la primera vez que lancé el juego no arrancó. `main.gd` usa `Textos` (de `src/game/ui/textos.gd`), pero la caché de clases de `.godot/` no lo tenía. Lo arreglé regenerándola con `godot --headless --import`, sin tocar código. Si otro agente ve «Identifier "Textos" not declared», la causa es esa.

---

## Lo que ya está bien (para no romperlo)

Antes de las faltas, lo que me sorprendió para bien. Hay mucha calidad de vida que otros RTS en desarrollo no tienen:

- **Panel de economía (F2)** ([captura 2](capturas/constructor-fluidez/02-2v2-economia-15min.png)). Muestra el ingreso por minuto, el banco, los aldeanos por recurso con una barra, la riqueza por origen y todo lo juntado por fuente. Es mejor que lo que trae AoE4 de fábrica.
- **Aldeanos por recurso debajo de cada número de la barra.** Con un clic se eligen esos aldeanos (`atajos.trabajando`).
- **Ociosos**: botones con número, «.» para el siguiente y Mayús para todos. Además está el consejo «aldeanos sin trabajo» y aparecen marcados en el minimapa (`mundo_minimapa.gd`).
- **Reunión inteligente** (`sim.gd::_spawn_from`). Con la reunión en un recurso, en una granja o en un cimiento, el aldeano nuevo junta o construye solo. Además se reúne a varios edificios a la vez.
- **Los constructores encadenan las obras.** Al terminar, buscan el cimiento propio más cercano y después vuelven a lo que juntaban (`sim.gd`, cerca de la línea 1848). Al terminar un almacén, juntan al lado.
- **Cola global** arriba de la pantalla, como AoE4, con clic al edificio y Mayús para todos los de ese tipo.
- **Entrenar con varios edificios elegidos** va al de cola más corta, y con Mayús encola cinco en total.
- **Las granjas son infinitas** (sin `cantidad` en `data/edificios.json`), como en AoE4: no hay que resembrar.
- **Empalizada arrastrando**, sin huecos en diagonal. La puerta se puede poner sobre la empalizada.
- **Campana con tecla global (B)**, y H recorre los centros.
- **Marcadores de cámara** (Ctrl + Alt + número).
- **Avisos que enseñan.** Uno de ellos es el de «tus aldeanos caminan lejos: levantá el almacén ahí», que es oro para el boomer.
- **Tributo y «pedirle» a un aliado** desde el puntaje. Además hay bengalas que la IA aliada entiende y frases de la IA («voy con mi próxima oleada»).
- **El aura del hito al colocarlo**, con lo que queda adentro: «2 fuentes de alimento, 41 árboles…». Es exactamente lo que quiero para todo lo demás.

En resumen: la base de calidad de vida es buena. Lo que falta es lo que hace que una partida de 60 minutos en 4v4 no se convierta en una rutina de clics.

---

## 1. Construcción

### 1.1 Muro en cadena, huecos y puertas

- **AoE4 / AoE2 DE.**
  - Se arrastra el muro y la vista previa marca en rojo cada tramo que no se puede.
  - En AoE4 el muro rodea el obstáculo y se puede seguir el trazo desde el extremo anterior.
  - En AoE4 un tramo terminado se convierte en puerta con un botón. En AoE2, la puerta se pone encima del muro.
- **Raíces hoy.**
  - El fantasma de la línea pinta en rojo las casillas imposibles (`controller.gd::_show_line`).
  - Pero `sim.gd::_cmd_build_line` **se las saltea en silencio**: si en el trazo hay un árbol, una veta o un edificio, el muro queda con un hueco y nadie avisa.
  - Con Mayús el modo sigue activo, pero cada tramo nuevo arranca donde hago clic, no donde terminó el anterior.
  - El trazo se corta en 80 casillas.
  - La puerta es un edificio aparte: hay que salir del modo y elegirla en la grilla.
- **Por qué pesa.** El defensivo vive cerrando el perímetro. Un hueco que no se ve es una base abierta al minuto 25. En la [captura 2](capturas/constructor-fluidez/02-2v2-economia-15min.png), la empalizada de la IA tiene huecos por todos lados.
- **Propuesta.**
  1. Un aviso al cerrar el trazo: «La empalizada quedó con 3 huecos (árboles)». Que los huecos queden marcados unos segundos.
  2. Con Mayús, el tramo siguiente arranca en el extremo anterior.
  3. Mientras se arrastra, una tecla (por ejemplo G) marca la casilla bajo el cursor como puerta.
  4. En la grilla de una empalizada elegida, el botón «Convertir en puerta».
- **Prioridad: alta. Esfuerzo: chico a mediano**, casi todo en la interfaz. El aviso de huecos sale de comparar las casillas pedidas con las colocadas.

### 1.2 Muralla de piedra, torres en la muralla y mejorar la empalizada

- **AoE4.** Empalizada y muralla de piedra. Las torres se ponen sobre la muralla, la muralla se mejora (almenas, aceite) y los soldados caminan por arriba. **AoE2:** empalizada, muralla de piedra y luego fortificada, y torres aparte.
- **Raíces hoy.**
  - Solo hay `empalizada` (300 de vida, 4 de madera) y `puerta` (`data/edificios.json`). Ninguna civ tiene un muro de piedra (`grep linea data/civs` da solo el camino inca).
  - La torre es un edificio de 2×2 que no se apoya en el muro.
  - La línea defensiva del juego tardío no existe: en la III y la IV, contra el asedio de área, una empalizada de 300 de vida es papel.
- **Por qué pesa.**
  - Para el estilo defensivo es *la* mecánica.
  - Hay base histórica para varios pueblos: Sacsayhuamán y los pucarás incas, el Jugol de Harar (Adal), las murallas de Ayutthaya y las empalizadas dobles de los mocambos.
  - Así cada civ podría tener su muro propio, que encaja con el pilar de asimetría.
- **Propuesta.**
  - Un «muro» de la II con más vida y más costo, y la acción «Reforzar con piedra» sobre los tramos de empalizada.
  - Que la torre se pueda poner **encima** de una casilla de muro, reemplazándola como hoy lo hace la puerta (`_replace_wall`).
  - Va como **propuesta en `04-decisiones.md`**, porque toca el alcance y el arte.
- **Prioridad: media-alta para mi estilo. Esfuerzo: grande** (datos, arte por civ, IA que lo use y balance).

### 1.3 Colocar con información: almacenes, granjas y «pegar» al vecino

- **AoE4.**
  - Al colocar el molino o el campamento se ve su radio y los recursos que caen adentro.
  - Los edificios se pegan al borde del vecino.
  - Las granjas se apoyan contra el molino o el centro, y la vista previa marca el anillo ideal.
- **Anno 1800.** Muestra el radio de influencia con los recursos que cubre, y el edificio se acomoda solo a la calle.
- **Raíces hoy.**
  - El hito ya muestra su aura y lo que tiene adentro (`mundo_colocacion.gd::detalles`), y el inca ve si queda «conectado a la capital».
  - Pero **el almacén y la granja no dicen nada útil** ([captura 3](capturas/constructor-fluidez/03-colocar-granja.png): solo «El lugar está ocupado»).
  - No hay distancia al depósito, ni árboles o vetas a N casillas, ni un anillo guía alrededor del centro o del granero.
- **Por qué pesa.** La distancia de viaje es la economía. Ya existe el consejo de «viaje largo» (`consejos.gd::_far`): es mejor prevenirlo al colocar que avisarlo después.
- **Propuesta.**
  - Al colocar un almacén: «A 3 casillas: 38 árboles (≈4.500 de madera)» y «El depósito más cercano está a 14».
  - Al colocar una granja: «A 2 casillas del granero» o «Lejos: los granjeros caminan 9 casillas», y las casillas recomendadas en verde alrededor de los depósitos de alimento.
  - Que la huella se pegue al borde del edificio vecino cuando el cursor está a una casilla.
  - Se puede reutilizar `dentro_del_aura`.
- **Prioridad: alta. Esfuerzo: chico** (interfaz sola, sin tocar la simulación).

### 1.4 Construir en orden con Mayús

- **AoE2 / AoE4.** Con Mayús, los cimientos se ponen en cola y los aldeanos los levantan **en el orden en que los puse**.
- **Raíces hoy.** Con Mayús se pueden poner varios cimientos (`controller.gd::_place`), pero cada `build` reordena a los constructores hacia **el último**. Recién al terminarlo pasan al más cercano. Si pongo cuatro casas en fila, caminan a la cuarta y vuelven.
- **Por qué pesa.** Es la rutina del boomer: cuatro casas y dos granjas con un grupo de aldeanos.
- **Propuesta.** Con Mayús, el `build` se encola en `mundo_cola.gd`, que ya existe para las órdenes con Mayús. Se puede hacer sin tocar la simulación.
- **Prioridad: alta. Esfuerzo: chico.**

### 1.5 Planos: planear la base sin pagar

- **Anno / Manor Lords.** «Modo plano»: dibujo la base completa sin gastar, y después se construye cuando hay recursos. **AoE4** no lo tiene, pero los jugadores de equipo lo usan muchísimo en otros juegos.
- **Raíces hoy.** El recurso se paga al colocar (`_cmd_build` hace `_pay`). No hay forma de reservar el lugar para el segundo centro ni el anillo de granjas.
- **Por qué pesa.**
  - Es lo que más me hace disfrutar la base.
  - Le saca carga mental al minuto 30: «ese lugar es para la fortaleza».
- **Propuesta.**
  - Un cimiento fantasma propio, «plano», que no bloquea ni cuesta. Lo ve solo el dueño y sus aliados.
  - Un botón «Construir planos» con los aldeanos elegidos: pagan y levantan en orden mientras alcance.
  - Si se guardan como estado de la simulación, quedan en las repeticiones.
- **Prioridad: media. Esfuerzo: grande.**

### 1.6 Reparar en masa y reparación automática

- **AoE4 / AoE2 DE.** Ninguno repara solo: se elige a un grupo y se hace clic derecho en el edificio. Por eso, en las partidas de equipo de AoE2, la «reparación en masa» la hace el jugador a mano después de cada ataque. **Anno** repara solo con un edificio de servicio que cubre una zona.
- **Raíces hoy.**
  - Se repara con clic derecho y es gratis (`sim.gd`, cerca de la línea 1867).
  - No hay orden de «reparar todo lo dañado de esta zona», ni reparación automática, ni aviso de «la torre del norte está al 30 %».
  - Al terminar de reparar, el aldeano no busca el siguiente edificio dañado: la cadena solo vale para los cimientos (`_nearest_unbuilt`).
- **Por qué pesa.** Después de cada ataque hay diez tramos de empalizada y dos torres para arreglar uno por uno.
- **Propuesta.**
  1. Que la cadena de `_nearest_unbuilt` incluya los edificios propios dañados (radio de `ayuda_obra_radio`).
  2. En la grilla raíz del aldeano, el botón «Reparar (zona)», que reparte a los elegidos entre lo dañado a N casillas.
  3. La opción «Al tocar la calma, los aldeanos reparan lo dañado cerca antes de volver».
- **Prioridad: media-alta. Esfuerzo: mediano.**

### 1.7 Reconstruir lo que cayó

- **Anno.** Queda la ruina con un botón «Reconstruir». En los RTS eso no existe, pero después de un asalto en 4v4 rearmar cinco casas y un almacén a ojo es tedioso.
- **Raíces hoy.** Al morir, el edificio desaparece (`_kill`) y no queda ningún rastro para el dueño.
- **Propuesta.** Una «huella» fantasma propia durante unos minutos (como un plano de 1.5), con el clic derecho de los aldeanos: «Reconstruir». Si existen los planos, es casi gratis.
- **Prioridad: baja-media. Esfuerzo: mediano** (chico si ya están los planos).

### 1.8 Rotar edificios

- **Anno / Manor Lords.** Es esencial. En **AoE4** se rotan algunos edificios (puertas de la muralla, ciertos hitos).
- **Raíces hoy.** No hay rotación: la huella es fija y casi todo es cuadrado (2×2 o 3×3).
- **Por qué pesa poco.** Con huellas cuadradas solo es estética: la entrada del cuartel mirando hacia la plaza.
- **Prioridad: baja.** No entra en mis 25.

---

## 2. Economía en piloto automático

### 2.1 Recurso que se acaba: aviso y rebusca más amplia

- **AoE4.** Avisa «Tus aldeanos se quedaron sin recursos» y los aldeanos buscan un recurso del mismo tipo bastante lejos. **AoE2 DE:** el aviso de ocioso, y el aldeano camina al recurso cercano del mismo tipo.
- **Raíces hoy.**
  - Al agotarse, el aldeano busca en `radio_rebusca` = 10 casillas (`data/reglas.json`). Si no hay nada, queda ocioso.
  - Recién a los 20 s de ocio salta el consejo genérico «aldeanos sin trabajo» (`consejos.gd::_idle`).
  - No hay aviso de que **se está por agotar** («La veta de piedra del este tiene 300») ni de «se agotó: 4 mineros sin trabajo».
  - Lo único parecido es el aviso de los frutos cerca del centro (`_bushes`).
- **Por qué pesa.** En 60 minutos se agotan diez bosques y cinco vetas. El boomer no mira cada veta, y el aviso genérico de ocio no dice por qué ni qué hacer.
- **Propuesta.**
  - Un aviso con lugar: «Se agotó la veta de piedra (4 mineros)». El aviso trae el botón y el Espacio que llevan ahí y eligen a esos aldeanos.
  - Un aviso previo cuando a una veta trabajada le queda el 15 %.
  - Si no hay nada a 10 casillas, que el aldeano busque el mismo recurso **cerca de otro depósito propio que lo reciba**, en vez de quedarse quieto.
- **Prioridad: alta. Esfuerzo: chico.**

### 2.2 Granjas sin granjero y «rellenar»

- **AoE2 DE.** El molino tiene una cola de resiembra. **AoE4:** las granjas son infinitas, pero si matan al granjero la granja queda vacía y el juego lo marca con un ícono.
- **Raíces hoy.**
  - La ficha de la granja dice «Sin aldeano asignado» (`ficha.gd::_building_state`), pero **solo si la elijo**.
  - En el mundo no hay ningún ícono: `mundo_capa.gd::_draw_building_icons` saltea justamente las `fuente`.
  - Después de una incursión con tres granjeros muertos, encontrar las granjas vacías es mirar una por una.
- **Propuesta.**
  1. Un ícono de «granja vacía» sobre la granja, como el de ocioso, y un punto en el minimapa.
  2. Con aldeanos elegidos, el clic derecho en una granja ocupada los manda a la libre más cercana. La reunión del centro hacia «granjas» hace lo mismo.
  3. Un botón «Llenar granjas» en el granero: manda a los ociosos más cercanos a cada granja libre.
- **Prioridad: alta. Esfuerzo: chico.**

### 2.3 Población: avisar antes del tope

- **AoE4 / AoE2.** El número de población se pone en rojo **antes** de llenarse (en AoE2, al quedar 2 o 3 lugares libres), y se avisa una vez.
- **Raíces hoy.**
  - Avisa **cuando ya está llena** («Población llena», `hud.gd`, cerca de la línea 406) y la ficha dice «Detenido: población llena».
  - Con tres centros y cinco cuarteles, cuando llega el aviso ya perdí 30 segundos de producción en ocho edificios.
- **Propuesta.**
  - Cálculo: «A este ritmo te quedás sin lugar en 40 s». Sale de lo que hay en cola dividido por el tiempo, con las colas de todos los edificios.
  - Con eso, un aviso ámbar y el número de población en ámbar.
  - Que la casa en obra cuente como «viene en camino» (+10 en gris).
- **Prioridad: alta. Esfuerzo: chico.**

### 2.4 Reasignar desde el panel de economía

- **Ningún RTS lo trae de fábrica.** En **Anno**, el reparto de mano de obra se maneja desde las estadísticas. En AoE4, los jugadores de equipo hacen esto a mano todo el tiempo: elegir 5 de comida y mandarlos a la madera.
- **Raíces hoy.** El panel F2 muestra el reparto (Alimento 22 · Madera 15 · Piedra 3 · Riqueza 2) y la barra elige a los de un recurso, pero mover cinco de uno a otro requiere elegir, deseleccionar a mano y hacer clic derecho.
- **Propuesta.** En la barra de recursos o en F2, un «→» entre recursos. Ctrl + clic en el número de alimento elige los **5 más cercanos al recurso de destino**, y el clic derecho después los manda. En `atajos.gd`, como variante de `trabajando`.
- **Prioridad: media. Esfuerzo: mediano.**

### 2.5 Edificios de producción parados

- **AoE4.** La cola global muestra lo que produce. Los profesionales la usan para notar el hueco: el edificio que falta.
- **Raíces hoy.**
  - `cola_global.gd::items` lista solo los edificios con algo en cola. Un cuartel parado **no aparece**.
  - La ficha dice «Sin nada en producción», pero de nuevo solo si lo elijo.
- **Propuesta.** En la cola global, los edificios de producción parados aparecen apagados, con un borde ámbar, después de 10 s sin cola. O se agrega un botón «Parados: 3», como el de ociosos, que los recorre.
- **Prioridad: media. Esfuerzo: chico.**

---

## 3. Producción en varios edificios

### 3.1 Repetición automática («producción infinita» de AoE4)

- **AoE4.** Cada edificio tiene un modo de producción continua (desde la temporada 4, «auto-queue»): sigue sacando la unidad mientras haya recursos y lugar. **AoE2 DE** no lo tiene, y por eso el macro de AoE2 es más pesado.
- **Raíces hoy.**
  - No existe. No hay comando de simulación (`sim.gd`, `match c["t"]`) ni botón (`controller.gd::commands`).
  - La cola tiene un tope de **5** (`reglas.cola_max`).
  - En la [captura 4](capturas/constructor-fluidez/04-4v4-20min.png), el jugador de IA tiene cinco edificios produciendo a la vez.
  - Para un humano son cinco colas de 5 que se vacían cada 2 minutos: un clic cada 25 segundos solo para mantener los aldeanos y la tropa.
- **Por qué pesa.**
  - Es *la* diferencia entre una partida de equipo larga relajada y una agotadora.
  - Para mi estilo, que el centro saque aldeanos sin parar hasta el número que elijo es lo más importante de todo el informe.
- **Propuesta.**
  - Un comando `repetir` {edificio, tipo, on}. Al vaciarse la cola, si se puede pagar y hay población, entra otro.
  - Con un «tope» opcional para aldeanos: «hasta 80».
  - En la grilla, el botón de la unidad con clic derecho o Ctrl + clic alterna la repetición. Se ve un ícono de bucle en la casilla y en la cola global.
  - Es determinista (es estado del edificio), así que entra en las repeticiones.
  - La IA ya hace lo mismo por su cuenta.
- **Prioridad: la más alta. Esfuerzo: mediano.**

### 3.2 Cola más larga

- **AoE4.** La cola admite muchas unidades. **AoE2 DE:** de a 5, pero con Mayús se encolan muchas más.
- **Raíces hoy.** `cola_max: 5` en `data/reglas.json`. Con Mayús encola 5 en total entre los edificios elegidos.
- **Propuesta.** Subir el tope (a 10 o 15). Es un dato, así que no toca código. Con 3.1 importa menos, pero sin 3.1 es el parche barato.
- **Prioridad: media. Esfuerzo: mínimo.**

---

## 4. Partidas largas

### 4.1 Guardar y cargar la partida

- **AoE2 DE / AoE4 / Anno.** Guardado manual y automático. En Anno, el autoguardado es parte del ritmo.
- **Raíces hoy.**
  - No existe. El menú de pausa ofrece Reanudar, Ayuda, Atajos, Opciones, Nueva partida, Menú principal y Salir (`hud.gd`, cerca de la línea 200). No hay ningún «Guardar».
  - Una partida de 4v4 de 60 minutos se pierde si cierro la ventana.
- **La buena noticia.** La simulación es determinista y por comandos, y **ya existen las repeticiones** (`--replay`, `sim.recording`). Guardar es «semilla + opciones + comandos hasta el tick N». Cargar es reproducir rápido hasta N, en cabeza, con una barra de progreso.
- **Prioridad: alta para partidas largas. Esfuerzo: mediano.** Cargar un guardado del minuto 60 tarda lo que tarde la simulación sin dibujo, con 8 IA. Habría que medirlo.

### 4.2 Rendimiento del 4v4 tardío

- **Raíces hoy.** El 4v4 de IA a ×8 llegó a 1.004 entidades al minuto 20.
  - La simulación avanzó unos 12.000 ticks en 7 min 14 s, o sea unos 28 ticks por segundo, unas 2,8 veces el tiempo real.
  - La máquina estaba cargada con otras dos simulaciones y el menú del autor.
  - Los cuadros por segundo a ×8 no sirven como medida, porque la simulación los come.
  - A ×1 entra, pero queda poco margen para el minuto 40 con 8 × 200 de población posible (`pob_max: 200`).
- **Ya está anotado.** El estado (`09-estado.md`) ya dice «caminos con caché por región» como siguiente paso.
- **Propuesta.** Medir un 4v4 de 45 minutos a ×1 con `--perf` en una máquina libre, y hacer la caché de caminos. Para el boomer es lo único que puede arruinar la partida al final.
- **Prioridad: media. Esfuerzo: grande.**

### 4.3 Alertas por zona y por tipo; avisos de aliados agrupados

- **AoE4.** «Te atacan» con un sonido distinto si es un aldeano, un edificio o tropa, y la flecha en el minimapa. **AoE2 DE:** las campanas de ataque distinguen aliado y propio.
- **Raíces hoy.**
  - El texto «¡Nos atacan!» tiene un freno global de 150 ticks (15 s) por jugador (`sim.gd`, cerca de la línea 2132). Si atacan el norte y a los 5 s el sur, el segundo **no se avisa** en texto. El minimapa sí lo marca, por zona de 8×8 (`mundo_minimapa.gd`).
  - El texto no dice **qué** (aldeanos, torre, granjas) ni **dónde** (norte, sur).
  - En el 4v4 ([captura 4](capturas/constructor-fluidez/04-4v4-20min.png)) hay tres renglones «Atacan a tu aliado (Violeta/Rojo/Ciruela)» que tapan el centro de la pantalla.
- **Propuesta.**
  - Freno por zona en lugar de global.
  - Texto con objeto y rumbo: «Atacan a tus leñadores · noroeste». Ya existe `consejos.gd::_rumbo`.
  - Los avisos de aliados en un solo renglón: «Atacan a 3 aliados», con Espacio que recorre los tres.
  - Una opción para que los avisos de aliados vayan solo al minimapa.
- **Prioridad: media-alta. Esfuerzo: chico.**

### 4.4 Minimapa para 8 jugadores

- **AoE4 / AoE2 DE.** Minimapa con filtros (recursos, solo militar, solo lo mío), tamaño ajustable y los edificios grandes destacados.
- **Raíces hoy.**
  - El minimapa es de tamaño fijo, unos 235 px.
  - Ya tiene destellos de ataque, sitios, ociosos, bengalas y recursos.
  - En el 4v4 ([captura 4](capturas/constructor-fluidez/04-4v4-20min.png)), los puntos de 8 equipos se mezclan y no se distingue un centro de una casa.
  - No hay filtros.
- **Propuesta.**
  - Un tamaño en Opciones.
  - Botones o tecla para alternar la vista: todo, economía (recursos y depósitos), militar (tropas, torres y muros) y equipos.
  - Los centros, las torres y las fortalezas con un ícono, no con un punto.
- **Prioridad: media. Esfuerzo: mediano.**

### 4.5 «Mi base»: encontrar lo tuyo

- **AoE2 DE.** Teclas para recorrer cada tipo de edificio (casas, cuarteles, mercados…). **Anno:** el panel de estadísticas por isla, con lista de edificios, productividad y clic que lleva.
- **Raíces hoy.**
  - H recorre los centros y Tab la producción. T elige los del mismo tipo **en pantalla o a partir de uno elegido**.
  - No hay un inventario: «tengo 14 casas, 2 en obra, 3 dañadas; 9 granjas, 2 vacías; 4 torres».
- **Propuesta.** Un panel «Mi base» (F3 está ocupada por la velocidad: cualquier libre). Tiene una fila por tipo con el número, en obra, dañados y vacíos o parados. El clic recorre y Mayús + clic elige todos. Junta 1.6, 2.2 y 2.5 en un solo lugar.
- **Prioridad: media. Esfuerzo: mediano.**

---

## 5. Equipo

### 5.1 Tributo con cantidad y tributo periódico

- **AoE2 DE.** Panel de tributo con cantidades (100 o 500, y Mayús para más). **AoE4:** controles deslizantes de tributo. Los jugadores de equipo «de bolsillo» en 4v4 tributan todo el tiempo.
- **Raíces hoy.**
  - Un clic manda `tributo_lote` = 100, con un 20 % de comisión (`panel_puntaje.gd`).
  - Mandar 1.000 de madera son diez clics. No hay tributo periódico.
- **Propuesta.**
  - Mayús + clic manda 500 y Ctrl + clic manda «todo lo que sobra por encima de X».
  - Un tributo fijo: «100 de madera por minuto a Violeta» (estado de la simulación, como los pedidos), con una marca visible en el puntaje.
- **Prioridad: media. Esfuerzo: chico.**

### 5.2 Bengalas con intención

- **AoE4.** Bengala simple. **AoE2 DE:** bengala y burlas numeradas («11», «Ayuda»…). En los juegos modernos de equipo, la rueda de señales (atacar, defender, voy, necesito recursos, cuidado) es estándar.
- **Raíces hoy.**
  - Alt + clic. La simulación decide sola si es «atacar» o «defender», según si cae cerca de lo propio o de un aliado (`_cmd_flare`).
  - No puedo decir «voy», «construí acá», «cuidado: vienen por acá» ni «necesito madera».
- **Propuesta.**
  - Alt + arrastrar abre una rueda de 4 o 5 intenciones, y Alt + clic simple queda como hoy.
  - La IA aliada ya responde a dos: se agregarían «cuidado» (reforzar torres) y «necesito X», que se conecta con `pedir`.
- **Prioridad: media. Esfuerzo: mediano.**

### 5.3 Ver al aliado

- **AoE2 DE.** Las estadísticas del equipo (F4) muestran aldeanos, militares y edad de cada uno. **AoE4:** el puntaje del equipo y la edad.
- **Raíces hoy.**
  - El puntaje muestra la edad y los puntos por aliado, con la visión compartida.
  - No veo cuántos aldeanos o soldados tiene mi aliado de IA, ni si está avanzando de edad o qué está haciendo («ahorra para el hito», «junta ejército»).
- **Propuesta.** Al pasar el mouse sobre el aliado en el puntaje: aldeanos, militares, en cola y su intención (la IA ya tiene estados internos y las frases de `ia_dice`).
- **Prioridad: baja-media. Esfuerzo: mediano.**

---

## 6. Estética de la base: si da gusto armarla

**Lo que veo** ([capturas 1, 2 y 4](capturas/constructor-fluidez/)):

- Las casas y los centros por pueblo tienen identidad: la ruka, la casa larga y los tukul se distinguen al toque. La obra por etapas y el aspecto por edad son lindos.
- Pero **la base se ve como piezas sueltas sobre un suelo de arena**:
  - No hay caminos ni tierra pisada entre los edificios.
  - No hay pilas de leña ni de piedra junto a los almacenes.
  - Los aldeanos no dejan rastro.
- El inca tiene caminos (`camino` en `tawantinsuyu.json`). Para el resto no hay nada.
- **Las banderas azules de cada edificio** ensucian la vista de una base grande. En la [captura 4](capturas/constructor-fluidez/04-4v4-20min.png) hay unas veinte y compiten con las tropas.

### 6.1 Banderas con menos ruido

- **AoE4.** El color del jugador está en techos y estandartes integrados al modelo, sin un mástil por edificio.
- **Propuesta.** Banderas más chicas o solo en los edificios de producción y defensa, con una opción para ocultarlas. El color de equipo puede ir a una franja del techo (`civ_meshes.gd`, `flag_at`).
- **Prioridad: media. Esfuerzo: chico.**

### 6.2 Tierra pisada y detalle de base

- **Manor Lords.** Los caminos aparecen solos por donde camina la gente. **Anno:** calles. **AoE4:** el suelo se gasta alrededor de los edificios.
- **Propuesta.**
  - Una textura de «tierra pisada» que crece por las casillas más transitadas. La telemetría ya mide los viajes al depósito (`tools/viajes.gd`); la vista puede acumular un mapa de tránsito sin tocar la simulación.
  - Pilas de recurso junto a los almacenes que crecen con lo depositado.
  - Granjas con algo que cambie con el tiempo (brotes, cosecha).
- **Prioridad: baja. Esfuerzo: mediano a grande.**

### 6.3 Modo foto

- **AoE4 / Anno.** Una tecla oculta la interfaz, y Anno tiene un modo foto. Al que arma la base le gusta mirarla.
- **Raíces hoy.** El HUD solo se oculta para las capturas (`main.gd`, cerca de la línea 415). El zoom máximo es 70 (`rts_camera.gd`).
- **Propuesta.** Una tecla para ocultar el HUD, y algo más de zoom lejano solo en ese modo.
- **Prioridad: baja. Esfuerzo: chico.**

---

## Tabla: mis 25 cambios, por prioridad y esfuerzo

Esfuerzo: **mín.** (un dato), **chico** (≤ 1 día, casi siempre interfaz), **mediano** (2 a 4 días, toca la simulación o varios archivos), **grande** (una etapa).

| # | Cambio | Área | Prioridad | Esfuerzo | Dónde hoy |
|---|---|---|---|---|---|
| 1 | Repetición automática de producción (con tope de aldeanos) | Producción | **Muy alta** | Mediano | No existe; `cola_max` 5 |
| 2 | Construir en orden con Mayús (cola de obras) | Construcción | Alta | Chico | `_place` → los constructores van al último |
| 3 | Aviso de recurso agotado o por agotarse, y rebusca cerca de otro depósito | Economía | Alta | Chico | `radio_rebusca` 10, solo el aviso de ocio |
| 4 | Aviso anticipado de población («sin lugar en 40 s») | Economía | Alta | Chico | Solo avisa con la población llena |
| 5 | Granjas vacías marcadas en el mundo y botón «Llenar granjas» | Economía | Alta | Chico | Solo en la ficha, si la elijo |
| 6 | Colocación informativa del almacén y la granja (recursos en radio, distancia y pegado) | Construcción | Alta | Chico | Solo el hito muestra su aura |
| 7 | Empalizada: avisar los huecos, encadenar desde el extremo y puerta en el trazo | Construcción | Alta | Chico-mediano | `_cmd_build_line` saltea en silencio |
| 8 | Guardar, cargar y autoguardado (semilla + comandos) | Partidas largas | Alta | Mediano | No existe; las repeticiones sí |
| 9 | Alertas por zona y con objeto y rumbo; avisos de aliados en un renglón | Partidas largas | Media-alta | Chico | Freno global de 15 s; tres renglones de aliados |
| 10 | Reparación en cadena, «Reparar (zona)» y reparar con la calma | Construcción | Media-alta | Mediano | Solo con clic derecho, uno a uno |
| 11 | Edificios de producción parados en la cola global | Producción | Media | Chico | `items()` solo los que producen |
| 12 | Cola más larga (10 o 15) | Producción | Media | Mín. | `reglas.cola_max` |
| 13 | Tributo con cantidad (Mayús, Ctrl) y tributo periódico | Equipo | Media | Chico | 100 por clic |
| 14 | Banderas más chicas, solo donde importan y con opción | Estética | Media | Chico | Una por edificio |
| 15 | Reasignar N aldeanos entre recursos desde la barra o F2 | Economía | Media | Mediano | Solo elegir por recurso |
| 16 | Minimapa con tamaño, filtros e íconos de edificios grandes | Partidas largas | Media | Mediano | Fijo, sin filtros |
| 17 | Panel «Mi base» (inventario, dañados, vacíos y parados) | Partidas largas | Media | Mediano | H y Tab recorren; no hay lista |
| 18 | Bengalas con intención (rueda con Alt + arrastrar) | Equipo | Media | Mediano | Atacar o defender automático |
| 19 | Muralla de piedra, torre sobre la muralla y reforzar la empalizada (propuesta) | Construcción | Media-alta (para mí) | Grande | Solo empalizada de 300 de vida |
| 20 | Planos: planear la base sin pagar | Construcción | Media | Grande | Se paga al colocar |
| 21 | Rendimiento del 4v4 tardío a ×1 (caché de caminos) y su medición | Partidas largas | Media | Grande | ~2,8× con 1.000 entidades y la máquina cargada |
| 22 | Ver al aliado (aldeanos, ejército e intención) | Equipo | Baja-media | Mediano | Edad y puntos |
| 23 | Reconstruir lo que cayó (huella fantasma) | Construcción | Baja-media | Mediano | Desaparece sin rastro |
| 24 | Tierra pisada, pilas de recurso y granjas que cambian | Estética | Baja | Mediano-grande | Suelo de arena uniforme |
| 25 | Modo foto (ocultar el HUD) | Estética | Baja | Chico | Solo en las capturas |

---

## Propuesta de paquetes

Cada paquete sale en una sola etapa, con su autotest. Van en el orden en que yo los haría.

| Paquete | Contenido | Por qué juntos | Pruebas |
|---|---|---|---|
| **A · La economía se maneja sola** | 1, 12, 11, 4 | Producción continua, cola larga, parados y población anticipada: todo gira alrededor de «la cola nunca se vacía» | `test_determinism` y `bench` (1 toca la simulación); autotest: la repetición sigue sacando, se corta sin recursos y vuelve |
| **B · Avisos que trabajan por mí** | 3, 5, 9 | Recurso agotado, granjas vacías y alertas por zona: el juego me dice qué se rompió y dónde, y el Espacio me lleva | Autotest con una veta chica que se agota; captura de un 4v4 con avisos de aliados agrupados |
| **C · Construir rápido y bien** | 2, 6, 7 | Mayús en orden, colocación informativa y muro sin huecos: la rutina de levantar la base | Autotest: cuatro casas con Mayús en orden; un trazo con un árbol avisa el hueco |
| **D · Partidas largas** | 8, 17, 16 | Guardar o cargar, inventario y minimapa: lo que hace soportable el minuto 60 | `test_determinism` con guardar y cargar a mitad de partida (mismo estado final); medición del tiempo de carga |
| **E · Equipo** | 13, 18, 22 | Tributo, bengalas con intención y ver al aliado | `tests/equipos.gd`; autotest con un aliado de IA |
| **F · Defensa** | 10, 19 (con propuesta en `04`) | Reparar en masa tiene sentido con muros que valga la pena reparar | `civ_smoke`, `torneo` (la muralla toca el balance) |
| **G · Base linda** | 14, 24, 25, 23, 20 | La parte de «da gusto armarla»: no es urgente, pero es lo que me hace volver | Capturas de la demo base, antes y después |
| Aparte | 15, 21 | La reasignación espera a ver si A y B la vuelven innecesaria; el rendimiento ya está en el plan (`09`) | `bench`, `--perf` |

---

## Dónde coincido y dónde no con el veterano (`03-veterano-fluidez.md`)

*(Lo leí después de escribir todo lo anterior.)*

### Coincidimos (llegamos solos a lo mismo)

| Tema | Él | Yo | Comentario |
|---|---|---|---|
| Mayús coloca los cimientos y los aldeanos van al último | 3.1 (★, su n.º 5) | 1.4 (mi n.º 2) | Mismo diagnóstico y mismo arreglo: la cola del cliente en `mundo_cola`. Él aporta el detalle útil: el id del cimiento hay que leerlo del suceso `placed` |
| Producción parada invisible en la cola global | 5.1 (★, su n.º 3) | 2.5 (mi n.º 11) | Él la pone más alta. Tiene razón para el centro en 1v1; para mí, con la repetición (mi n.º 1), el problema casi desaparece |
| Alerta de ataque con freno global de 15 s, sin objeto ni zona | 6.1 (★, su n.º 4) | 4.3 (mi n.º 9) | Idéntico. Yo le sumo los avisos de aliados agrupados en un renglón, que en 4v4 tapan la pantalla ([captura 4](capturas/constructor-fluidez/04-4v4-20min.png)) |
| Tope de cola de 5 | 5.3 (su n.º 7) | 3.2 (mi n.º 12) | Los dos decimos de 10 a 15, en `data/` |
| Granjas que no se pegan y almacén sin información al colocar | 3.3 (su n.º 20) | 1.3 (mi n.º 6) | Él pide que se peguen; yo además pido distancia al depósito y recursos en el radio del almacén. Yo lo pongo alto y barato, él medio |
| El muro arrastrado necesita más información | 3.2 (su n.º 8: costo y tramos) | 1.1 (mi n.º 7: huecos en silencio, encadenar y puerta) | Complementarios: él ve el costo, yo los huecos. Conviene hacerlos juntos |
| Minimapa con filtros y tamaño | 6.4 (su n.º 25, baja) | 4.4 (mi n.º 16, media) | Para él es un detalle; para mí, en 4v4 con 8 colores, es necesario |
| Rotar edificios | Baja, fuera | Baja, fuera | Igual |
| Lo que ya está bien | Sección 2 | «Lo que ya está bien» | Los dos reconocemos lo mismo: reunión inteligente, cadena de obras, ociosos, cola global y F2 |

### No coincidimos (o vemos cosas distintas)

- **La repetición de producción no está en su lista, y para mí es lo primero.**
  - Él juega 1v1 de 20 a 25 minutos, con la mano en la cola: encolar es parte de su ritmo.
  - Yo juego 4v4 de una hora con 3 centros y 6 a 8 edificios militares: sin «producción infinita», la mitad de mis clics son reponer colas.
  - Creo que hay que hacerla, como opción por edificio, porque no le quita nada al que prefiere la cola manual.
- **Guardar y cargar.** No lo menciona, porque sus partidas son cortas. En partidas largas es imprescindible, y la simulación determinista lo deja barato.
- **Muralla de piedra y torres en la muralla.** Él no lo pide (le basta la empalizada para su juego); para el defensivo es el centro del estilo. Lo dejo como propuesta en `04-decisiones.md`, porque toca el alcance y el arte.
- **El sonido es su prioridad n.º 1 y 2** (selección y cimiento). Estoy de acuerdo en que suma y es barato, pero en mi estilo pesa menos que un aviso de «se agotó la veta». Lo apoyo igual: el sonido del cimiento le sirve también al que construye en cadena.
- **Reparar.** Él dice que reparar gratis es un problema de balance (la torre casi inmortal). Yo pido lo contrario en comodidad: reparar en masa y en cadena. No es contradictorio: se puede cobrar la reparación **y** hacerla cómoda. Si se cobra, que sea barata, porque si no el defensivo pierde su única ventaja.
- **Lectura de pelea, órdenes finas y catapulta al suelo** (sus secciones 4 y 7): no las evalué, porque no es mi juego. Confío en su juicio.
- **Lo que solo veo yo:**
  - el recurso que se agota sin aviso (él lo ve solo para la reunión, en su 3.7, y es el mismo problema de fondo);
  - las granjas vacías invisibles;
  - la población anticipada;
  - el tributo con cantidad y periódico, las bengalas con intención y ver al aliado;
  - las banderas que ensucian la base;
  - los planos;
  - el rendimiento del 4v4 tardío (él midió una batalla de 60 tropas; yo, un 4v4 con 1.000 entidades).

### Una propuesta común de orden

Juntando los dos informes:

1. **Su paquete A** (sonido y destello, dos días), en paralelo con **mi paquete A** (repetición, cola larga, parados y población). Así la cola se llena sola y además se oye.
2. **Constructor**: su C y mi C son el mismo paquete. Juntos son Mayús en orden, el muro con costo y sin huecos, y las granjas pegadas con información.
3. **Avisos**: su D y mi B, con alertas por zona y tipo, recurso agotado, granjas vacías y la reunión sobre el recurso agotado (su 9).
4. Después, mi D (guardar y la base), mi E (equipo) y su E y F (órdenes y lectura), según lo que pida el autor.
