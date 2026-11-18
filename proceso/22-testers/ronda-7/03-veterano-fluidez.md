# Jugador de prueba 1, séptima ronda (extra) · Veterano de AoE4: qué falta para que se sienta fluido

Main en `ab3c853`. El autor pidió un análisis con mucho detalle de jugabilidad, interfaz, calidad de vida y construcción. Lo armé con tres fuentes: jugar con el autotest, sacar capturas de las demos y leer el código de `src/game/` y `src/sim/` para no suponer nada. Cuando digo que algo «no está», es porque lo busqué en el código.

## 1. Qué corrí

| Qué | Comando | Resultado |
|---|---|---|
| Autotest | `godot --path . -- --autotest --civ=guaranies --terreno=llano` | 147 de 147, código 0 |
| Colocar una granja en lugar ocupado | `--demo=base --civ=guaranies --edad=2 --colocar=granja --shot-at=3` | [captura 1](capturas/veterano-fluidez/01-colocar-granja.jpg) |
| Tropas elegidas en plena pelea | `--demo=batalla --civ=mapuches --rival=palmares --select=lancero --shot-at=6` | [captura 2](capturas/veterano-fluidez/02-tropas-elegidas.jpg) |
| Batalla sin selección | `--demo=batalla … --shot-at=8` | [captura 3](capturas/veterano-fluidez/03-batalla.jpg) |
| Cuartel elegido con la ficha abierta | `--demo=base --edad=2 --select=cuartel --ficha=cmd:0 --banco=…` | [captura 4](capturas/veterano-fluidez/04-cuartel-ficha.jpg) |
| Arranque de una partida normal | `--civ=guaranies --terreno=llano --speed=4 --shot-at=30` | [captura 5](capturas/veterano-fluidez/05-arranque.jpg) |
| Cuadros por segundo | `--perf` en `--demo=base --edad=3` y en `--demo=batalla` | Base: 74 a 90 fps. Batalla de 60 tropas: 59 fps al chocar y 84 a 92 después. RTX 2060 SUPER, con otros dos Godot sin ventana corriendo |

## 2. Lo que ya está a la altura de AoE4 (no tocar)

Antes de pedir, quiero reconocer lo hecho: la base de controles es mejor que la de muchos RTS independientes. Esto ya funciona y lo verifiqué:

- **Selección:**
  - doble clic en una unidad elige las de su tipo en pantalla, y en un edificio, todos los de su tipo en el mapa;
  - Mayús + clic suma o saca;
  - el panel de varias unidades permite Mayús o Ctrl + clic por retrato o por tipo;
  - el arrastre prefiere unidades antes que edificios.
- **Grupos 0 a 9:**
  - con Ctrl se asigna, con Mayús se suma y dos toques centran;
  - hay una fila de pestañas;
  - la opción de grupos exclusivos funciona como en AoE4.
- **Órdenes:**
  - ataque en movimiento (A);
  - patrullar;
  - mantener posición;
  - cuatro formaciones;
  - rumbo al arrastrar el clic derecho;
  - Alt + clic derecho manda moverse sin formación;
  - Mayús encola mover, juntar y ataque en movimiento, también desde el minimapa (`src/game/ui/mundo_cola.gd`);
  - bengala con Alt + clic.
- **Economía:**
  - teclas para aldeanos y militares ociosos (`.` y `,`, con Mayús todos), con botones en la barra;
  - N elige todos los aldeanos, P toda la producción y Tab recorre los edificios;
  - cola global de producción arriba;
  - aldeanos por recurso debajo de cada recurso;
  - Mayús + Q entrena 5 repartidos en el edificio de cola más corta;
  - punto de reunión sobre un recurso, que pone a juntar, o sobre un cimiento, que pone a construir (`Sim._spawn_from`).
- **Construcción:**
  - el que termina un almacén junta lo más cercano de lo que recibe; el que termina una granja se queda en ella;
  - si hay un cimiento a menos de 10 casillas, el constructor lo sigue; si no, vuelve a lo que hacía (`Sim._do_build`);
  - empalizada arrastrando, y la puerta reemplaza un tramo del muro;
  - pasillos entre edificios pegados;
  - al borrar un cimiento se devuelve todo;
  - la vista previa dice por qué no se puede construir («El lugar está ocupado», captura 1) y muestra el aura de los hitos.
- **Cámara:**
  - 8 marcadores (Ctrl + Alt + número guarda, Alt + número vuelve; F7 a F9);
  - Espacio salta al último aviso con lugar e Inicio recorre los anteriores;
  - H recorre los centros;
  - las órdenes y el punto de reunión se dan también desde el minimapa.
- **Lectura:**
  - 12 cursores según el contexto;
  - barras de vida como en AoE4: de lo elegido, lo dañado o con la opción;
  - silueta del color del equipo detrás de árboles y edificios;
  - Alt muestra la función de cada tropa: mi pedido de la ronda 6, **cumplido**;
  - números flotantes de entrega y de golpes fuertes;
  - la ficha es muy completa (captura 4: estadísticas, costo, contra qué es fuerte, «Tenés 1 en el mapa»).
- **Teclas:** todas se reasignan y hay un perfil «aoe4».

Lo que sigue es lo que **falta** o está **a medias**. Para cada falta van cinco puntos: qué hace AoE4, qué hace Raíces, por qué pesa, la prioridad y el esfuerzo.

---

## 3. Construcción

### 3.1 Cimientos encadenados con Mayús: se construyen al revés y los lejanos quedan solos ★

- **AoE4:** pongo 4 casas con Mayús y los aldeanos elegidos las levantan **en el orden en que las puse**: primero la 1, después la 2. Los cimientos quedan puestos y pagados, como fantasmas en cola.
- **Raíces:**
  - Cada clic manda un `build` aparte (`Controller._place`). En `Sim._cmd_build`, cada uno reasigna a los aldeanos al **cimiento nuevo** con `_order_build`.
  - Resultado: los aldeanos dejan la casa 1 y van a la última. Al terminarla, `_nearest_unbuilt` busca el cimiento más cercano a menos de 10 casillas (`reglas.grupo.ayuda_obra_radio` = 10000).
  - Si encadené una casa en la madera y otra en el oro, la primera queda **sin constructores**.
- **Por qué pesa:** es el gesto más repetido de la partida. Una casa puesta primero que se termina última te bloquea la población. El jugador de AoE4 lo nota a los 3 minutos.
- **Arreglo sugerido, todo del lado del cliente y sin tocar la simulación:**
  - con Mayús, el primer `build` lleva los `ids` y los siguientes van con `ids: []`, que solo pone el cimiento y lo paga;
  - después, `cola.encolar(ids, {"t": "target", "target": id_del_cimiento})` en `mundo_cola`, que ya manda la orden siguiente cuando el aldeano se libera;
  - así se ven los puntos de la cola y la repetición queda igual.
- **Prioridad:** alta. **Esfuerzo:** medio. El cimiento nuevo hay que leerlo del suceso `placed`, porque el cliente no conoce su id de antemano.

### 3.2 Muro arrastrado: no dice cuánto cuesta ni cuántos tramos van

- **AoE4:** mientras arrastro el muro veo el costo total y los tramos que alcanzan; los que no alcanzan quedan en rojo.
- **Raíces:**
  - los tramos que no alcanzan sí quedan en rojo (`Controller._show_line`);
  - no hay ningún número: ni «12 tramos · 240 de madera» ni «alcanzan 7»;
  - el presupuesto solo mira la **madera** (`budget = res["madera"]`), así que un muro o una puerta con otro costo, de otro pueblo o con descuento, colorea mal;
  - el tope es de 80 casillas, sin aviso.
- **Por qué pesa:** el muro se tira apurado, con el rival encima. Sin la cifra, arrastro de más y la mitad no se paga.
- **Prioridad:** media. **Esfuerzo:** chico: un texto junto al cursor con lo que ya calcula `_show_line`, y el presupuesto con `can_afford` acumulado.

### 3.3 Granjas: no se pegan al depósito ni a la granja vecina

- **AoE4:** las granjas se acomodan rápido alrededor del molino o del centro porque el fantasma se apoya en el borde. Además, el área de influencia del molino se ve al colocar.
- **Raíces:**
  - la granja se ubica por casilla, al centro del cursor (`Controller._process`, modo «place»);
  - no se pega a nada;
  - el aura se ve solo en los hitos (`MundoColocacion.dentro_del_aura`), no en el depósito de alimento ni en el centro.
- **Por qué pesa:** en la II pongo 8 a 12 granjas seguidas. Si entre dos granjas queda una casilla libre, se arma un pasillo y se pierde lugar; para dejarlas pegadas hay que apuntar al píxel.
- **Arreglo sugerido:** que el fantasma de la granja se corra hasta 1 casilla para quedar pegado al depósito o a otra granja, si ahí entra. Mostrar «x de 8 lugares libres alrededor del depósito».
- **Prioridad:** media. **Esfuerzo:** medio, todo en la interfaz.

### 3.4 Sonido y golpe visual al colocar el cimiento

- **AoE4:** el cimiento suena a madera apoyada, con una nubecita de polvo, y el aldeano responde.
- **Raíces:**
  - suena «clic» al tocar la casilla de la grilla (`run_command`);
  - al apoyar el cimiento, `_place` solo agrega un marcador y no suena nada;
  - el sonido «terminado» existe para cuando la obra se termina.
- **Por qué pesa:** el cimiento es la confirmación de que gasté. Sin sonido, miro la barra de recursos para saber si entró.
- **Prioridad:** alta, porque cuesta casi nada. **Esfuerzo:** chico: `audio.ui("colocar")` y un sonido CC0.

### 3.5 Girar edificios

- **AoE4:** casi todo es cuadrado, así que girar no es central.
- **Raíces:** no se puede girar; `tam` es fijo.
- **Prioridad:** baja. **Esfuerzo:** medio, porque toca la ocupación del mapa.

### 3.6 Reparar

- **AoE4:** reparar cuesta una fracción del edificio. Varios aldeanos reparan más rápido.
- **Raíces:** reparar es gratis y va a la velocidad de construcción (`_do_build`, «Reparación… sin costo en H1»). Funciona y el cursor lo dice.
- **Por qué pesa:** poco en el feel; es balance. Lo dejo anotado: reparar gratis hace que la torre bajo asedio sea casi inmortal con 6 aldeanos.
- **Prioridad:** baja. **Esfuerzo:** chico, en `data/`.

### 3.7 Reunión sobre un recurso que se agota

- **AoE4:** si el punto de reunión está en un árbol y el árbol se cae, el aldeano nuevo junta en el árbol más cercano.
- **Raíces:** si el recurso ya no existe, `_spawn_from` cae en `_cmd_move` y el aldeano **queda ocioso** en ese punto.
- **Por qué pesa:** en el bosque la reunión dura un árbol. Cada minuto aparece un ocioso «sin motivo» y el aviso de ociosos me grita.
- **Arreglo sugerido:** guardar en el edificio el tipo de recurso de la reunión y, si el blanco murió, usar `find_resource` de ese tipo cerca del punto.
- **Prioridad:** media. **Esfuerzo:** chico, pero es simulación: hay que correr `test_determinism` y `bench`.

---

## 4. Selección y órdenes

### 4.1 Sin sonido al elegir ★

- **AoE4:** cada clic que elige hace un sonido corto propio del tipo, con voz en las unidades y sonido de edificio en los edificios. Al dar una orden, otra voz.
- **Raíces:**
  - `_set_selection` no suena;
  - al dar una orden suena `civ_sfx("orden")`: **uno solo por pueblo**, el mismo para aldeanos, lanceros y la catapulta;
  - el límite es de 0,35 s (`data/audio.json` → `momentos.orden`).
- **Por qué pesa:** es la mitad del «se siente fluido». El oído confirma antes que la vista: elegí bien, entendió la orden. Sin eso, el clic se siente en el vacío, aunque el marcador verde esté.
- **Arreglo en dos pasos:**
  1. Ya: un sonido de selección suave por categoría (aldeano, tropa, edificio) y uno de error cuando el clic no hace nada.
  2. Después: tres variantes de la orden por función (civil, a pie, montado o asedio) para cada pueblo, con el mismo sintetizador de `tools/audio/`.
- **Prioridad:** alta. **Esfuerzo:** chico para el paso 1 y grande para el paso 2.

### 4.2 El blanco no destella al ordenar el ataque

- **AoE4:** con clic derecho sobre un enemigo, su contorno destella en rojo un instante. Con clic derecho sobre un árbol, el árbol destella.
- **Raíces:** en `_right_click` aparece un aro en el suelo con `view.add_marker(…)`, rojo o del color de acento, pero el blanco no se marca.
- **Por qué pesa:** en el montón (captura 3) el aro en el suelo queda tapado. El destello en el modelo dice «a ese» sin dudas.
- **Prioridad:** media. **Esfuerzo:** chico: ya existe el resaltado de `view.hovered`, y es reusarlo 0,3 s.

### 4.3 Ctrl + clic: todos los de ese tipo en pantalla

- **AoE4:** Ctrl + clic elige todas las unidades de ese tipo en pantalla. Es lo mismo que el doble clic, pero sin el riesgo de que el segundo clic caiga en otra.
- **Raíces:** `_left_release` no mira Ctrl. Solo funciona el doble clic, con 350 ms de ventana.
- **Prioridad:** baja. **Esfuerzo:** chico.

### 4.4 Atacar el suelo con la catapulta

- **AoE4:** el mangonel puede atacar el suelo (tecla en la grilla) para pegarle a un montón que se mueve o a lo que hay detrás de un muro.
- **Raíces:** la catapulta tiene daño en área (`data/unidades.json`: `area`, `area_borde_pct`), pero en `src/sim/` no hay orden de atacar el suelo. Busqué «suelo», «ground» y «ataque_suelo».
- **Por qué pesa:** el área existe y no la puedo apuntar. La catapulta persigue a una unidad y el montón se le escapa.
- **Prioridad:** media. **Esfuerzo:** medio, es simulación.

### 4.5 Mayús en patrullar y en mantener

- **AoE4:** la patrulla admite varios puntos con Mayús, y mantener posición se puede encolar después de un movimiento.
- **Raíces:**
  - el modo patrullar manda un solo punto y sale del modo (`_mouse_button`, «patrol»);
  - «hold» va directo.
- **Prioridad:** baja. **Esfuerzo:** chico para mantener, que va a la cola del cliente, y medio para la patrulla de varios puntos.

### 4.6 Seguir o escoltar una unidad propia

- **AoE4:** clic derecho sobre una unidad propia la sigue. Sirve para escoltar el asedio o al explorador.
- **Raíces:** clic derecho sobre una unidad propia es mover a ese punto (`_right_click`, la rama `else`).
- **Prioridad:** baja. **Esfuerzo:** medio, es simulación.

---

## 5. Economía y producción

### 5.1 Producción parada: no se ve ★

- **Contra AoE4:**
  - El AoE4 de fábrica no lo trae, pero todo jugador competitivo usa una superposición que avisa cuando el centro está quieto.
  - En AoE4, la cola global muestra los edificios que producen; el centro parado se nota porque no está.
- **Raíces:**
  - la cola global (`src/game/ui/cola_global.gd`) muestra solo los edificios con algo en cola;
  - no hay consejo de «tu centro no produce aldeanos»: busqué en `consejos.gd` y solo hay ociosos, frutos, recursos acumulados, sitios, empujón, viajes largos y pelea perdida.
- **Por qué pesa:** el error número uno del jugador medio es dejar el centro sin aldeanos. Acá es más fácil que en AoE4, porque la cola de 5 se vacía en 1:40.
- **Arreglo sugerido:**
  - en la cola global, la capital y cada centro **siempre** visibles: grises y con un pulso cuando no producen;
  - un consejo apagable «Tu centro no hace aldeanos desde hace 20 s».
- **Prioridad:** alta. **Esfuerzo:** chico.

### 5.2 Sacar de la cola desde la casilla

- **AoE4:** clic derecho en la casilla de la unidad saca una de la cola, y Mayús + clic derecho saca 5.
- **Raíces:**
  - clic derecho sobre la grilla vuelve a la raíz del aldeano (`hud.gd`, `_gui_input` de la grilla);
  - para cancelar hay que tocar el ícono en la fila de la cola del panel (`hud.gd:1326`), y solo con un edificio elegido.
- **Por qué pesa:** con 3 cuarteles elegidos y Mayús + Q, encolo 5 de más y no tengo cómo sacarlos sin elegir cada cuartel.
- **Prioridad:** media. **Esfuerzo:** chico: un comando `cancel` del último índice en el edificio de cola más larga, el reverso de `cola_mas_corta`.

### 5.3 Tope de cola de 5

- **AoE4 y AoE2:** la cola es larga. AoE2 deja 15 por edificio y en AoE4 no me acuerdo de haber chocado con un tope.
- **Raíces:** `reglas.cola_max` = 5. Con un solo cuartel, Mayús + Q ya la llena.
- **Por qué pesa:** al salir a pelear dejo la producción cargada. Con 5, vuelvo a la base cada 2 minutos. Además, el centro con 5 aldeanos encolados se vacía en 1:40, y eso suma al 5.1.
- **Prioridad:** media. **Esfuerzo:** chico (`data/`), pero hay que ver que la fila de la cola del panel dibuje más de 5, con «+n».

### 5.4 Grilla del cuartel llena en la III (repito, ronda 7)

- **AoE4:** las mejoras de unidad van en otra pestaña del edificio, o en la herrería.
- **Raíces:** 12 de 12 en la III. No hay lugar visible para la IV ni para la élite.
- **Prioridad:** media. **Esfuerzo:** medio: una pestaña o página, con la flecha en la casilla 12.

### 5.5 Tasa de ingreso en la barra de recursos

- **AoE4:** al pasar el mouse por un recurso veo los aldeanos y el ritmo por minuto.
- **Raíces:** la barra muestra los aldeanos por recurso. El ingreso por minuto está en el panel F2 (`panel_economia.gd`), no en la barra.
- **Prioridad:** baja. **Esfuerzo:** chico.

---

## 6. Cámara, minimapa y avisos

### 6.1 «¡Nos atacan!» genérico y uno por jugador ★

- **AoE4:**
  - el aviso dice qué te atacan: los aldeanos, la ciudad, el ejército, un aliado;
  - cada caso tiene su sonido;
  - el destello en el minimapa va donde pasa;
  - si te pegan en dos lugares, avisa en los dos.
- **Raíces:**
  - `Sim._hit` manda un `alert` con x e y, como mucho cada 150 ticks (15 s) **por jugador**, sin importar dónde;
  - el HUD siempre dice «¡Nos atacan!» con el mismo sonido de alarma (`hud.gd:451`, `audio.gd`);
  - el aviso de la pelea perdida (`consejos.gd`) es excelente, pero llega cuando ya terminó.
- **Por qué pesa:** con un raid de jinetes en la madera mientras peleo en el frente, el segundo ataque **no avisa**: el primero ya gastó los 15 s. Es justo la jugada que AoE4 te enseña a ver. Y sin saber qué atacan, no sé si tocar la campana o mandar el ejército.
- **Arreglo sugerido:**
  - el suceso lleva el id atacado; el límite va por zona de 16 × 16 y por categoría (aldeano, edificio, tropa);
  - textos «Atacan a tus aldeanos en la madera», «Atacan tu torre» y «Tu ejército pelea»;
  - el sonido de alarma solo para aldeanos y edificios, y un tambor más suave para el ejército;
  - Espacio ya salta al lugar.
- **Prioridad:** alta. **Esfuerzo:** chico a medio: el límite vive en `src/sim/`, así que hay que correr las pruebas de determinismo; otra opción es emitir siempre y limitar en el HUD.

### 6.2 La hoja de atajos dice que el botón del medio gira

- `hoja_atajos.gd:108` dice «Flechas, bordes — mover la cámara (botón del medio: girar)».
- En `rts_camera.gd`, el botón del medio **arrastra** la cámara: el giro está fijo en 45°.
- Es un error de texto, no de juego, pero el que lo prueba cree que algo está roto.
- **Prioridad:** baja. **Esfuerzo:** chico (una línea).

### 6.3 Saltos de cámara secos

- **AoE4:** salta seco también. El problema es solo de orientación: al saltar con Espacio o con el grupo, cuesta un instante saber dónde caí.
- **Raíces:** `look_at_point` mueve la cámara de golpe.
- **Arreglo sugerido:** un pulso de 0,4 s en el lugar del aviso, que ya existe para los marcadores del suelo, o una transición opcional de 0,15 s.
- **Prioridad:** baja. **Esfuerzo:** chico.

### 6.4 Minimapa

- **Bien:** marco trapezoidal de la cámara, destellos donde atacan, sitios, aldeanos ociosos, órdenes, reunión y bengala.
- **Falta:**
  - filtros (solo unidades, sin recursos);
  - poder agrandarlo;
  - en AoE4 hay un botón para cada cosa.
- **Prioridad:** baja. **Esfuerzo:** chico.

---

## 7. Lectura de la pelea

### 7.1 Qué tropa es cada una: ya está con Alt (cumplido)

El autotest lo confirma («Alt muestra la función sobre cada unidad: 23 íconos»). En la captura 2 los retratos del panel son todos iguales porque elegí solo lanceros, y está bien.

### 7.2 El panel de varias: glifos blancos en lugar de retratos

- **AoE4:** retratos pintados, con la vida en la misma tarjeta.
- **Raíces:** un glifo blanco por unidad con su barra (captura 2). Se entiende, pero en un ejército mixto de 4 tipos los glifos se parecen («lancero» y «lancero con escudo»).
- **Prioridad:** baja. **Esfuerzo:** grande (arte). Un paso intermedio chico: fondo de color por función (choque, línea, distancia, asedio) en la tarjeta, con los mismos colores que Alt.

### 7.3 Proyectiles e impactos

- **En la captura 3:** el disco de color dice de quién es cada uno y las barras aparecen al dañarse. Bien.
- **Lo que no pude juzgar quieto:** si las flechas y las piedras se leen en el aire. En las capturas no las distingo a la zoom de juego.
- **Pedido:** una estela corta en los proyectiles de distancia, para leer de dónde vienen los honderos.
- **Prioridad:** baja. **Esfuerzo:** chico.

### 7.4 Números de daño

- AoE4 **no** muestra números de daño. Acá salen los golpes fuertes (`MundoCapa._float_damage`).
- Me parece bien como ayuda para aprender, pero en una pelea de 60 tropas ensucian.
- **Pedido:** que se apaguen en Opciones, y apagados en el perfil «aoe4».
- **Prioridad:** baja. **Esfuerzo:** chico.

---

## 8. Información

- **Ficha (captura 4):** mejor que la de AoE4. Tiene estadísticas, contra qué es fuerte y débil, costo, «Tenés 1 en el mapa» y la tecla.
  - Lo único: tapa media pantalla a la derecha. En AoE4 la ficha de la grilla es más angosta y no tapa el centro.
  - **Pedido:** un modo compacto (nombre, costo y una línea), con el resto al mantener Mayús o Alt.
  - **Prioridad:** baja. **Esfuerzo:** chico.
- **Puntaje (F6), línea de tiempo y gráfico de edad en el final:** están.
- **Panel de economía (F2):** está.
- **Lo que falta para la lectura rápida** es lo de 5.1: el estado de la producción de un vistazo.

---

## 9. Ritmo, animación y respuesta

- **Latencia:**
  - la simulación corre a 10 ticks por segundo (`reglas.tick_ms` = 100) y el cuadro interpola (`view.render(alpha)`);
  - la orden entra en el próximo tick, a menos de 100 ms;
  - el marcador y el sonido de orden salen al instante;
  - se siente bien y no lo tocaría.
- **El clic derecho manda la orden al soltar**, por el arrastre del rumbo. AoE4 hace lo mismo y no se nota.
- **El cursor de colocar** es verde o rojo, con el motivo y el aura. Muy bien.
- **Feedback que falta:** el sonido al elegir (4.1), el sonido del cimiento (3.4) y el destello del blanco (4.2). Con esos tres, el juego pasa de «responde» a «se siente».

---

## 10. Rendimiento percibido

- **Base en la III:** 74 a 90 fps. **Batalla de 60 tropas:** 59 fps en el primer choque y 84 a 92 después. Todo con otros dos Godot corriendo en la máquina.
- **No noté tirones** en las capturas ni en el autotest.
- **Pedido:** medir en limpio una pelea de 150 tropas (3 contra 3 tardío) con `--perf`. El primer choque es el momento en que más cuesta y en el que más importa que no se trabe.
- **Prioridad:** baja por ahora. **Esfuerzo:** chico para medir.

---

## 11. Los 25 cambios que más fluidez dan

Están ordenados por prioridad × esfuerzo: primero lo alto y barato. «Sim» quiere decir que toca `src/sim/` y hay que correr determinismo y banco de pruebas.

| # | Cambio | Área | Prioridad | Esfuerzo | Sim |
|---|---|---|---|---|---|
| 1 | Sonido al elegir, por categoría (aldeano, tropa, edificio), y de error cuando el clic no hace nada | Respuesta | Alta | Chico | No |
| 2 | Sonido y polvo al apoyar el cimiento | Construcción | Alta | Chico | No |
| 3 | Producción parada visible: capital y centros siempre en la cola global, grises y con pulso al estar quietos, más el consejo apagable | Economía | Alta | Chico | No |
| 4 | Avisos de ataque por categoría y por zona, con sonidos distintos | Avisos | Alta | Chico–medio | Sí (o limitar en el HUD) |
| 5 | Mayús + colocar: cimientos en orden, como una cola de obras en `mundo_cola` | Construcción | Alta | Medio | No |
| 6 | Clic derecho en la casilla saca una de la cola, y Mayús saca 5, en el edificio de cola más larga | Producción | Media | Chico | No |
| 7 | Tope de cola de 5 a 10, con «+n» en el panel | Producción | Media | Chico | Datos |
| 8 | Muro arrastrado con «n tramos · costo · alcanzan k», y presupuesto con todos los recursos | Construcción | Media | Chico | No |
| 9 | Reunión sobre un recurso agotado: el más cercano del mismo tipo | Economía | Media | Chico | Sí |
| 10 | Destello del blanco al ordenar atacar o juntar | Respuesta | Media | Chico | No |
| 11 | Fondo de color por función en los retratos del panel de varias | Lectura | Media | Chico | No |
| 12 | Corregir la hoja de atajos: el botón del medio arrastra, no gira | Ayuda | Baja | Chico | No |
| 13 | Ctrl + clic: todos los del tipo en pantalla | Selección | Baja | Chico | No |
| 14 | Mayús + mantener posición en la cola del cliente | Órdenes | Baja | Chico | No |
| 15 | Números de daño apagables; apagados en el perfil «aoe4» | Lectura | Baja | Chico | No |
| 16 | Ingreso por minuto al pasar por cada recurso de la barra | Información | Baja | Chico | No |
| 17 | Ficha compacta, con el detalle al mantener Mayús o Alt | Información | Baja | Chico | No |
| 18 | Pulso en el lugar al saltar con Espacio o con un grupo | Cámara | Baja | Chico | No |
| 19 | Estela corta en flechas y piedras | Lectura | Baja | Chico | No |
| 20 | Granjas que se pegan al depósito o a la granja vecina, con «x de 8 lugares libres» | Construcción | Media | Medio | No |
| 21 | Pestaña o página en la grilla del cuartel para la IV y la élite | Producción | Media | Medio | No |
| 22 | Atacar el suelo con la catapulta | Órdenes | Media | Medio | Sí |
| 23 | Variantes de la orden por función (civil, a pie, montado, asedio) por pueblo | Respuesta | Media | Grande | No |
| 24 | Patrulla de varios puntos con Mayús, y seguir o escoltar una unidad propia | Órdenes | Baja | Medio | Sí |
| 25 | Minimapa con filtros y tamaño | Cámara | Baja | Chico | No |

Fuera de la tabla, porque no los veo prioritarios: girar edificios, reparar con costo (es balance) y retratos pintados (arte).

## 12. Propuesta de paquetes de trabajo

Cada paquete se cierra con el autotest y una captura, como pide `CLAUDE.md`. Los que tocan la simulación, además, con `test_determinism` y `bench`.

| Paquete | Qué entra (números de la tabla) | Por qué junto | Pruebas |
|---|---|---|---|
| **A. «Se siente»: respuesta inmediata** | 1, 2, 10, 12, 15, 18 | Todo es interfaz y audio, sin simulación. Es lo que más cambia la sensación por hora de trabajo | Autotest: el sonido de selección se dispara y el destello dura 0,3 s |
| **B. Producción sin descuidos** | 3, 6, 7, 21 | Cola global, cola del edificio y grilla son un solo sistema | Autotest: el centro quieto aparece gris; el clic derecho saca una; la cola de 10 se dibuja |
| **C. Constructor** | 5, 8, 20, 9 | El ciclo «poner casas, muros y granjas». El 9 es el único que toca la simulación | Autotest: 3 casas con Mayús se terminan en el orden puesto; el muro muestra el costo. Además, determinismo y banco |
| **D. Avisos que ubican** | 4, 25 | El jugador sabe qué y dónde sin mirar | Autotest: dos ataques en zonas distintas dentro de 15 s dan dos avisos. Además, determinismo si se toca el límite en la simulación |
| **E. Órdenes finas** | 13, 14, 22, 24 | Para el jugador que ya domina lo básico | Determinismo y banco por el 22 y el 24 |
| **F. Pulido de lectura** | 11, 16, 17, 19, 23 | Arte y sonido; el 23 es el más caro | Captura de batalla y de panel |

**Orden que recomiendo:** A, B, C, D y después E y F. A y B juntos son un par de días y cambian la sensación más que cualquier otra cosa de esta lista. C es el que más le duele al que viene de AoE4: la casa que se termina última.

## Capturas

1. [Colocar una granja en lugar ocupado: el motivo se ve, el fantasma no se pega](capturas/veterano-fluidez/01-colocar-granja.jpg)
2. [Lanceros elegidos en la pelea: grilla militar, líneas de orden y retratos](capturas/veterano-fluidez/02-tropas-elegidas.jpg)
3. [Batalla, Mapuches contra Palmares, segundo 8](capturas/veterano-fluidez/03-batalla.jpg)
4. [Cuartel elegido con la ficha del guerrero](capturas/veterano-fluidez/04-cuartel-ficha.jpg)
5. [Arranque de una partida normal: aviso de ociosos y minimapa](capturas/veterano-fluidez/05-arranque.jpg)
