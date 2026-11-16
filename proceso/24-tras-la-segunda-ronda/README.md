# 24 · Después de la segunda ronda de jugadores (desde 2026-11-15 16:30)

## Pedido del autor
> "Ok, vayamos uno a uno en esos puntos, completemos los 4 puntos grandes en orden:
> 1. The new bugs.
> 2. Landmarks and sites at 10 minutes.
> 3. Balance with everything together: Palmares at 88 % first, then the slow Mapuches.
> 4. The big items: expert AI, match options, art and sound.
>
> Al concluir los 4 ítems, volvamos a consultar a los jugadores."

La lista sale de la [síntesis de la segunda ronda](../22-testers/ronda-2/00-sintesis.md).

## Plan
| # | Qué | Prueba |
|---|---|---|
| 1 | **Errores nuevos:** IA fácil en el centro; aldeano que no carnea el animal suelto; carnear en cadena; sueltos más lejos; misiones por encima del tope de población; prueba del tutorial indefenso; bengala que no llega; aliado que no defiende si lo atacan; comisión del tributo sin explicar; frases de la IA fuera del registro; tributo de la IA demasiado temprano | Una prueba por error, determinismo, autotest |
| 1b | **Eficiencia de la IA** (pedido del autor, mirando IA contra IA: "la IA no hace almacenes para cortar madera, sino que sigue mandando gente a hacer madera súper lejos y depositándola en la plaza central, en lugar de gastar un poco de madera para hacer un almacén cerca"). Medir la distancia de cada viaje de recolección por recurso y por jugador, arreglar la IA y sumar la medida a la salud de la IA | Telemetría de viajes, `tests/salud_ia.gd` con distancia de viaje por recurso |
| 2 | **Hitos de 190/220/250 s y sitios a 10 minutos**, como AoE4 | Edades en paz, salud de la IA, torneo |
| 3 | **Balance con todo junto:** Palmares (88 %) primero, después los mapuches (edad III tardía) | Torneos de 5 semillas en paralelo, un cambio por vez |
| 4 | **Lo grande:** IA experta, opciones de partida, arte y sonido | Salud de la IA por dificultad, autotest, capturas |
| — | **Tercera ronda** con los mismos cuatro jugadores | Informes y síntesis comparada |

## Paso a paso

### Paso 1: los errores de la segunda ronda

| Error | Arreglo | Prueba |
|---|---|---|
| La IA fácil estaciona el ejército en el centro (en 1 contra 1 hay un sitio ahí) | `_map_spot` suma el centro del mapa solo si el nivel toma sitios (`dificultades.facil.toma_sitios: false`) | IA fácil contra IA: se queda en su punto de reunión |
| El aldeano mandado a un animal suelto lo reclama y queda ocioso | Reclamar y carnear en la misma orden | `tests/jugabilidad.gd`: aldeano a un animal suelto |
| Al terminar la carne, el aldeano va a los arbustos | Carnear en cadena: el animal propio más cercano dentro de `animales.cadena_radio` (10 casillas) | `tests/jugabilidad.gd`: 0 llamas quedan en pie |
| Los sueltos "cerca" estaban a 5 casillas | A 15 casillas en mapas de 2 y a 14 en los de varios | Explorador con trabajo; los aldeanos no los reclaman al pasar |
| Las misiones arrancan por encima del tope de población | `pob_extra`: lo que la misión pone de más se suma al tope (sin pasar `pob_max`) | Misiones sin el aviso de población excedida |
| `tutorial_letra --modo=indefenso` quedaba abierta | La prueba levanta el hito con los aldeanos que queden (sobreviven 2 con el combate nuevo); no era una falla del juego | Gana en los dos modos: letra 9:48, indefenso 11:04 |
| La bengala llega 1 de 4 veces | Las tropas que van a una bengala ya no se desvían: ni las incursiones (tomaban unidades en movimiento), ni la correa de los estilos que no entran a la base rival, ni la ayuda al aliado (`_at_flare`) | `tests/ordenes.gd`: "bengala: llegan 4 de 4" (3 minutos) |
| El aliado no defiende si a él también lo atacan, y no lo dice | Con las dos amenazas, `equipos.ia_ayuda_parte_pct` (33 %) va al aliado y el resto a casa; dice "Voy a defenderte con N" | `tests/equipos.gd` |
| "Te mando 200" llega como 160 sin explicar | "Te mando 200 de madera: llegan 160, el resto se pierde en el camino" (`{llegan}` con la misma cuenta que la simulación) | Autotest |
| Las frases de la IA no quedaban en el registro | También van al registro de sucesos (F5) con el color del aliado | Autotest |
| La IA daba tributo a los 3:00 | `equipos.ia_tributo.desde_ticks`: no antes de los 8 minutos | `tests/equipos.gd` (tributos por partida) |

### Paso 1b: eficiencia de la economía de la IA

**Medida nueva.** La telemetría anota cada viaje de un aldeano lleno: casillas del recurso al depósito más cercano, por jugador y recurso (`SimTelemetry.trip`, `viajes` en la cabecera del JSONL). Lo muestran:
- `tools/viajes.gd`: tabla por tramos de 5 minutos con los depósitos de cada uno;
- el informe de `tools/telemetria.gd`: sección "Viajes al depósito";
- `tests/salud_ia.gd`: falla si la madera viaja más de 12 casillas de media.

**Qué se vio** ([antes](pruebas/01-viajes-antes.txt), 10 partidas de IA contra IA):
- La mayoría de las civs hace leñeras y viaja 1–4 casillas.
- **Ayutthaya** no tiene leñera (su depósito es el elefante del rey) y lleva la madera a 2–7 casillas. Seguido minuto a minuto, el elefante está en el centro del grupo de leñadores. La distancia sale de 9–14 leñadores repartidos alrededor de un solo elefante (el segundo, desde el minuto 10, va al alimento). No es un error, es el diseño de la civ.
- El ciclo de almacenes de la IA cortaba en el primer recurso lejano aunque no construyera nada. Si el alimento lejano iba primero y no alcanzaba la madera o no había lugar, la madera se quedaba sin almacén.
- El tope era de 4 almacenes por tipo, contando los que quedaron junto a un bosque ya talado. Cuando el bosque se corría, no se hacía uno nuevo y los aldeanos volvían a caminar hasta el centro, que es lo que vio el autor.

**Arreglo:**
- Los recursos se ordenan por cuántos aldeanos trabajan lejos, y la madera compite igual que el resto.
- Si no hay lugar, se pasa al recurso siguiente; si no alcanza, se espera.
- Solo cuentan los almacenes con ese recurso todavía cerca: `ia_economia.almacen_utiles` (3), con un tope total de `almacen_max` (8).
- El elefante se reacomoda cuando el grupo se aleja más de 3 casillas (`ia_economia.elefante_cerca`; antes, 6).

**Después** ([medida](pruebas/02-viajes-despues.txt)):
- Madera a 1–4 casillas en todas las civs.
- Ayutthaya sigue en 2–7 casillas, por lo dicho del elefante.
- Los guaraníes llegan a 7–8 leñeras a los 25 minutos porque los bosques se corren.

### Pruebas del paso 1
- **Determinismo:** OK. **Rendimiento:** 8,35 ms de promedio con 200 unidades (presupuesto 100). **Jugabilidad, órdenes, civs y autotest:** OK ([resultados](pruebas/)).
- **Autotest:** la revisión de la cola global miraba 6 cuadros después de la orden. Con la máquina cargada, la orden todavía no había entrado. Ahora espera a que entre (hasta un segundo) y da población extra para que el tope no la frene.
- **Equipos:** los cuatro 2v2 sin fuego amigo, con 7 y 9 tributos en 30 minutos (antes había tributo desde los 3 minutos); dos terminan por conquista. El 3v3 y el todos contra todos no llegaron a correr dentro del tiempo límite de la prueba en paralelo: van con el paso 2.
- **[Salud de la IA](pruebas/03-salud-ia.txt):**
  - En el commit anterior fallaban 3 civs: guaraníes (ejército de 4, sin mercado), Palmares (sin mercado) y Ayutthaya (edad II a las 10:31).
  - Ahora fallan 2, las del mismo par: Palmares termina con Ayutthaya antes del minuto 12. Es el desbalance del paso 3 (Palmares 88 %), no un error de este paso.
  - La madera viaja 1–2 casillas en todas las civs.

## Tropiezos
- `var alt := dict.get(...).has(...)` no compila: Godot no infiere el tipo de lo que sale de un `get`. Hay que escribir el tipo, y una IA que no compila deja la prueba colgada hasta el tiempo límite.
- El primer "después" de Ayutthaya parecía un arreglo y no lo era: las cifras eran iguales a las de antes. Seguir al elefante minuto a minuto mostró que ya estaba junto a los leñadores. Se corrigió el texto en lugar de declarar una mejora.

### Paso 2: hitos como AoE4 y sitios a 10 minutos

**Qué se hizo (C-33):**
- **Obra de los hitos** (`edades.json`, `hito_tiempo_ms`): 190/220/250 s con un aldeano (antes, 60/90/120). Con el rendimiento decreciente (tiempo × 3/(n+2)), la IA los levanta con 4 aldeanos en 95, 110 y 125 s. Ahí está la ventana de riesgo que pidió el veterano.
- **Sitios sagrados:** se gana teniéndolos todos durante 10 minutos (`sitios.victoria_ms`; antes, 5), como en AoE4. La cuenta grande, la ficha y la pantalla de fin leen el mismo dato.
- **Auras según el lugar:** `reglas.aura_hito`, por eje. Un hito puede traer la suya en `aura`, que queda lista para darle identidad a cada pueblo.
  - Hito de economía: +15 % de recolección a 9 casillas o menos.
  - Hito militar: cura 2 de vida por segundo a la tropa propia y aliada a 9 casillas o menos.
  - Importa dónde se levanta: el de economía junto a los campos o el bosque, el militar donde se pelea. La ficha del hito lo dice.

**Pruebas:**
- `tests/jugabilidad.gd`:
  - aura de economía: tres leñadores juntan 300 contra 270 sin el hito (+11 %, con la caminata incluida);
  - aura militar: un guerrero herido pasa de 60 a 70 de vida en 5 s.
- Determinismo y autotest: OK.

**[Edades en paz](pruebas/06-edades-en-paz.txt)** (25 min, llano):

| Civ | Edad II antes | Después | Edad III antes | Después (con auras) |
|---|---|---|---|---|
| Tawantinsuyu | 5:05 | 5:50 | 14:55 | 15:50 |
| Mapuches | 6:50 | 7:50 | 18:00 | 17:50 |
| Guaraníes | 7:20 | 9:00 | 14:10 | 17:55 |
| Etiopía | 4:55 | 5:55 | 18:00 | 16:10 |
| Palmares | 7:15 | 8:15 | 16:05 | 16:40 |
| Ayutthaya | 6:15 | 7:10 | 20:05 | 19:05 |

- La edad II llega cerca de un minuto más tarde: es la obra más larga, como se buscaba.
- Los guaraníes pierden 1:40 en la II y 3:45 en la III. Se mira en el paso 3.
- Las auras devuelven parte en la III: mapuches, Etiopía y Ayutthaya llegan antes que con hitos de 60/90/120 s.

**[Salud de la IA](pruebas/07-salud-ia-hitos.txt):**
- El umbral de la edad II pasa de 9:30 a 10:30: son los 65 s más de obra con 4 constructores.
- Siguen fallando 3 civs, las mismas que en el commit anterior al paso 1:
  - guaraníes, con 3 de ejército al minuto 12 contra Etiopía;
  - Palmares, sin mercado;
  - Ayutthaya, con la edad II a las 10:59 y 4 de ejército contra Palmares.
- Es el desbalance del paso 3, que va primero con Palmares.

**[Equipos](pruebas/08-equipos-3v3-ffa.txt):**
- 3v3: 947 bajas, 0 de fuego amigo y 26 tributos (el tributo de la IA ahora es desde los 8 minutos).
- Todos contra todos con 6: 974 bajas y 2 derrotados a los 30 minutos. Sigue abierto, y Palmares llega a la edad 4 en el 3v3.
- No hubo victorias por sitios a los 30 minutos: con 10 minutos de cuenta es más difícil.

### Paso 2b: caminar por la ciudad y depositar por cualquier lado (pedido del autor)

> "Algo muy molesto es que donde está construido no se pueda caminar por encima, es decir, entre los edificios en la ciudad, y que para depositar recursos hay que ir solo por un lugar específico y no se puede dejar desde cualquier lado."

**Depositar por un solo lugar:**
- **Causa:** para llegar a un edificio, el camino apuntaba a su centro, que es sólido. A* devolvía la casilla alcanzable más cercana a ese centro, que es siempre la misma (en un centro de 4×4, la del sur o la del este). El aldeano que venía del oeste o del norte caminaba hacia ese borde y entregaba solo si en el camino rozaba el edificio. Además, buscar un destino sólido recorre toda la región alcanzable.
- **Arreglo:** el destino es la casilla libre junto al edificio más cercana a quien llega (`Sim._side_tile`). Vale para depositar, construir, reparar y golpear edificios cuerpo a cuerpo. Los edificios que se pisan (granjas) siguen igual.
- **Medida** (`tests/jugabilidad.gd`, un aldeano cargado a 3 casillas de cada lado del centro): oeste y norte de 2,5 s a 1,8 s; este y sur, igual (5,9 y 2,7 s, ya iban a su lado). Los cuatro entregan parados de su lado.

**No se puede caminar entre los edificios:**
- **Causa:** el movimiento pasa por una casilla libre, pero dos edificios pegados eran una pared. La IA ya dejaba una casilla de paso.
- **Primer arreglo (descartado):** obligar a dejar una casilla entre edificios. El autor: "no debería hacer falta una casilla de separación; en AoE4, entre edificios pegados igual queda un caminito". Después: "o probá hacer caminable la casilla de adentro de los edificios".
- **Arreglo:** `reglas.pasillo_entre_edificios`.
  - Los edificios se pegan como antes. El más nuevo de dos que se tocan deja caminable su fila de casillas contra el más viejo (`Sim._refresh_corridor`, `SimMap.open_tile`), y queda un pasillo de una casilla dentro de la huella.
  - La casilla sigue ocupada (no se construye encima), y un edificio solo sigue tapando entero.
  - Si el viejo desaparece, el pasillo se cierra (`_close_corridors_of`, también cuando se muda la corte etíope o un taller se vuelve tambo).
  - Muros (`linea`), puertas y torres no abren: cierran a propósito.
- **Prueba** (`tests/jugabilidad.gd`): dos casas pegadas; la nueva abre su columna y el resto tapa; se cruza en línea recta; destruida la vieja, se cierra; una empalizada pegada no abre.
- **Pendiente para el arte:** la unidad que cruza pasa por el borde del modelo. Conviene que los modelos no llenen del todo la huella (`docs/07`).

**Pruebas:**
- Determinismo, órdenes, civs, las 25 misiones (sin errores), las puertas y los cercos de fortines, y autotest: OK. El tutorial se gana a las 10:42 (con la regla de separación).
- Rendimiento, sola en la máquina: 8,56 ms de promedio y 59 de peor caso (antes, 8,35 y 57,9). Con el torneo de 10 procesos en paralelo había dado 18 ms, que era la carga.

### Paso 3: balance con todo junto

Un cambio por torneo: 75 partidas, 5 semillas, 30 minutos, en 10 procesos.

| Torneo | Cambio | Tawantinsuyu | Mapuches | Guaraníes | Etiopía | Palmares | Ayutthaya |
|---|---|---|---|---|---|---|---|
| Etapa 23 | (antes de esta etapa) | 44 | 32 | 44 | 56 | 88 | 36 |
| [11 · base](pruebas/11-torneo-base.txt) | Pasos 1 y 2 | 64 | 52 | 76 | **8** | 68 | 32 |
| [12](pruebas/12-torneo-ejercito-minimo.txt) | IA: ejército mínimo mientras ahorra | 52 | 60 | 72 | 12 | 72 | 32 |
| [13](pruebas/13-torneo-jinete-noble.txt) | Etiopía: jinete noble 160 de vida y 13 de ataque (antes 140 y 10), mismo costo | 52 | 52 | 64 | **40** | 68 | 24 |
| [14](pruebas/14-torneo-khlong.txt) | Ayutthaya: khlong junto a la base y arrozales junto al agua | 52 | 52 | 60 | 36 | 68 | **32** |
| [15](pruebas/15-torneo-flecheiro.txt) | Palmares: flecheiro 7 de ataque (antes 8). **Descartado** | 52 | 48 | 56 | 32 | **84** | 28 |
| [16](pruebas/16-torneo-acogida.txt) (10 semillas) | Palmares: acogida a 34 de fama (antes 28) | 54 | 62 | **74** | 38 | **34** | 38 |
| [17](pruebas/17-torneo-riqueza-guarani.txt) (10) | Guaraníes: riqueza 750 (antes 800). **Descartado** | 54 | 64 | **78** | 34 | 34 | 36 |
| [18](pruebas/18-torneo-roza-y-kawin.txt) (10) | Guaraníes: roza 900 (antes 1000) + IA mapuche: kawiñ | 58 | **70** | **56** | 42 | 42 | 32 |
| [19](pruebas/19-torneo-kona.txt) (10) | Mapuches: kona montado 80/55 (antes 70/45; el base, 100/70) | 58 | **64** | 60 | 44 | 42 | 32 |
| [20](pruebas/20-torneo-arrozal.txt) (10) | Ayutthaya: arrozal +35 % junto al agua (antes +25) | 60 | 58 | 58 | 50 | 40 | 34 |

**Etiopía, de 56 % a 8 %.**
- Con la misma partida seguida en el commit anterior a la etapa (`tools/ia_por_dentro.gd`, sierra contra Tawantinsuyu), el ejército etíope ya era chico (unas 20 unidades). Lo que cambió fue el rival: los arreglos de economía del paso 1 destrabaron el alimento de Tawantinsuyu, que pasó de 15 a 60 unidades.
- El problema propio: mientras ahorra para el hito, la IA no entrenaba nada. A las 15:00 tenía 979 de alimento en el banco (el hito pide 1000) y 9 de ejército.
- **Primer intento (descartado):** producir con todo lo que sobra por encima del costo del hito. Etiopía no llegaba a la edad III, cuatro civs se quedaban sin mercado y, en paz, la edad III llegaba 3–4 minutos más tarde.
- **Queda:** mientras ahorra, la IA mantiene un ejército mínimo por edad (`ia_economia.ejercito_minimo_ahorrando`: 10, 16, 20) con lo que sobra por encima del hito. Etiopía, de 8 a 12 %.

**Jinete noble.**
- Costaba 80 de alimento y 40 de riqueza (el guerrero base, 60 y 25) y tenía apenas 17 % más de vida y un punto menos de ataque.
- La debilidad de la civ dice "unidades caras y pocas". Ahora son caras y fuertes: Etiopía pasa de 12 a 40 %.

**Ayutthaya, de 24 %: el arrozal sin agua.**
- Siguiendo una partida (selva, contra los mapuches): Ayutthaya pasa toda la partida con 0–70 de alimento en el banco y no llega a la edad III antes del minuto 21. Junta piedra y riqueza que no usa.
- Su arrozal rinde +25 % a 2 casillas del agua, pero **ninguno** de los arrozales de la IA tenía el bono: 0 de 9–20 en selva, llano, río, delta y sierra.
  - En casi ningún mapa hay agua a menos de 30 casillas de la base. En delta, a 21; en islas, a 19.
  - Los jugadores de prueba ya lo habían visto: "arrozales sin agua".
- **Arreglo** (un solo cambio: una parte sin la otra no sirve):
  - **Khlong:** las bases de Ayutthaya empiezan junto a un canal de agua baja (`modulos.khlong`: a 8 casillas del centro, 9 de largo y 2 de ancho). Se camina y no se edifica. Ayutthaya era una ciudad de canales. Con relieve real (misiones), manda la geografía del lugar.
  - **IA:** si la granja rinde más junto al agua, la IA busca primero un lugar junto al agua a 13 casillas del centro o menos (`ia_economia.granja_agua_radio`).
- **Medida:** 6–9 arrozales con el bono de 10–21 en los cinco terrenos (antes, 0). Torneo 14: Ayutthaya de 24 a 32 %. Determinismo y equidad de los mapas, OK. [Captura](capturas/khlong-ayutthaya.png): el canal junto al centro, con los arrozales al lado.

## Trabajo en paralelo (desde 2026-11-16)

> El autor: "paralelizá lo que se pueda, seguí documentando y avanzá orquestando todo".

Cada frente tiene su agente en un worktree propio, con su rama y su documento. El orquestador corre los torneos (la máquina no da para dos a la vez), integra las ramas, resuelve conflictos, actualiza este README, el índice y `docs/09`, y publica.

| Frente | Qué | Documento |
|---|---|---|
| Balance (orquestador) | Un cambio por torneo: Etiopía, Ayutthaya, Palmares | Esta página, paso 3 |
| A · Mapuches | **Integrado (4b5243c).** Causa: la IA no hacía nunca el kawiñ y todo el alimento se iba en tropa, sin llegar a la mitad del hito. Desde la edad II hace la fiesta del corral más lleno si con eso entra en el ahorro (`ia_economia.kawin_corrales`). Edad III en paz de 18:43 a **17:02** (2 semillas), las demás civs igual. Falta el torneo | [3b-mapuches.md](3b-mapuches.md) |
| B · IA experta | **Integrado (217fd85).** Nueva dificultad Experta: hasta 100 aldeanos (3 civs llegan a los 25 min), hasta 3 centros (mapuches con lofs), oleadas de 16 + 6, ejército mínimo al ahorrar más alto. Todavía no le gana a la difícil (C-51). Cacería sin hitos para todas las dificultades: las partidas de solo conquista terminan (25:04 y 40:30; antes, abiertas a los 45). Depósitos juntados una vez por pensada: la IA pasa de 8,6 a 3,9 ms con dos expertas | [4a-ia-experta.md](4a-ia-experta.md) |
| C · Opciones de partida | **Integrado (2022235).** Sitios sí o no, hitos sí o no, tiempo límite (30/45/60), recursos (normal, medios, altos), equipos juntos o mezclados; el puntaje pasa a la simulación. `tests/opciones_partida.gd` OK. Consultas C-45 a C-50. Pendiente: sin hitos, la IA no termina la conquista (C-49) | [4b-opciones-de-partida.md](4b-opciones-de-partida.md) |
| F · Frentes | **Integrado (78b3686).** Las puertas de todos los edificios (procedurales y GLB) miran a la cámara; media vuelta, sin tocar huella ni margen | [4e-frentes.md](4e-frentes.md) |
| G · Experta contra difícil | En curso: que la experta le gane a la difícil (C-51) | [4f-experta-contra-dificil.md](4f-experta-contra-dificil.md) |
| E · Hitos y animales | **Integrado (d7f4a9d).** Los 36 hitos con forma propia (ushnu, Qorikancha, nguillatuwe, aty guasu, iglesia etíope redonda, Lalibela, cerca real, Wat Mahathat…; `data/arte_hitos.json`) y 16 especies con silueta propia (llama, chilihueque, búfalo, tapir, órix, sambar…; `data/arte_animales.json`), con la caza según el pueblo más cercano. Las puertas, en F | [4d-hitos-y-animales.md](4d-hitos-y-animales.md) |
| D · Arte por edad | **Integrado (cac669b).** Obra en 3 etapas, aspecto por edad y por pueblo (`data/arte_edades.json`), torres propias (solo los invasores conservan almenas), margen de 0,3 casillas en la huella; sin créditos de Meshy | [4c-arte-por-edad.md](4c-arte-por-edad.md) |

**Palmares y el ruido del torneo.**
- Con el flecheiro más débil (torneo 15), Palmares *subió* de 68 a 84 %. La simulación es determinista, pero cualquier cambio altera todas las partidas que siguen.
- Con 25 partidas por civ, el ruido de un porcentaje es de unos ±10 puntos: el 68 → 84 dice que ese no era el resorte, no que el flecheiro la fortalezca. Se vuelve a 8.
- **Desde acá, las decisiones van con 10 semillas** (150 partidas, 50 por civ, ±7 puntos).
- **El resorte de Palmares es la acogida.** Llega gente sin costo de alimento a cambio de fama (24 por minuto del centro, 15 por mocambo), y eso explica sus victorias rápidas y las por puntos. Torneo 16: acogida a 34 de fama (antes, 28), unas 18 % menos de personas regaladas. **Palmares de 68 a 34 %** con 10 semillas: era el resorte. Queda en el borde de abajo; se vuelve a mirar cuando cambien las demás. Ahora el que sobra es guaraníes (74 %).

**Guaraníes (74–78 %).**
- Ganan casi todo por puntos al minuto 30 (31 de 37 en el torneo 16), y el puntaje es sobre todo lo recolectado.
- Bajarles la riqueza (800 → 750, torneo 17) no movió nada: 78 %. Se vuelve a 800.
- El motor es la roza: 500 de alimento a 1000 (33 % más que la granja común, 750) y, al agotarse, un yerbal que da riqueza.
- Torneo 18: roza a 900, todavía 20 % sobre la granja. Entra junto con el kawiñ mapuche (un arreglo de IA que queda igual). Son dos civs distintas: se mira cada una.
- **Torneo 18:** guaraníes de 78 a 56 %; era la roza. Los mapuches suben de 64 a 70 % con el kawiñ, el riesgo que había anotado el frente A: llegan antes a la edad III y al kona montado.
- **Torneo 19:** el kona montado costaba 30 % menos que el jinete base. Ahora cuesta 80/55: sigue más barato, porque el malón es su identidad. Mapuches de 70 a 64 %, y todas quedan entre 32 y 64 %.

**Cierre del paso 3.**
- Con el torneo 20 (150 partidas), todas las civs quedan entre 34 y 60 %. Antes de la etapa: 32–88 %.
- Ayutthaya en 34 % está dentro del ruido (±7). El arrozal más fuerte junto al agua refuerza su identidad, así que queda.
- Cambios que quedaron, todos en `data/`:
  - IA: ejército mínimo al ahorrar;
  - Etiopía: jinete noble más fuerte;
  - Ayutthaya: khlong, arrozales junto al agua, arrozal +35 %;
  - Palmares: acogida a 34 de fama;
  - mapuches: kawiñ en la IA y kona a 80/55;
  - guaraníes: roza a 900.
- Lección: con 5 semillas el ruido (±10) confundía; con 10, cada cambio se lee bien.
