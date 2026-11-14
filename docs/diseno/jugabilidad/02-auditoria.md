# Auditoría de jugabilidad frente a AoE4

Qué tiene hoy el juego en movimiento de grupos, almacenes, edificios de producción, comodidades de órdenes e IA, comparado con lo que pidió el autor en `proceso/21-jugabilidad-aoe4/README.md` ("ahora parece más al 1 que al 4"). No es una decisión: es la base para el plan de `docs/diseno/jugabilidad/`.

**Cómo se miró.** Lectura de `src/sim/sim.gd`, `sim_map.gd`, `sim_entity.gd`, `sim_ai.gd`, `sim_data.gd`, `src/game/controller.gd`, `hud.gd`, `minimap.gd`, `src/game/ui/` y de `data/edificios.json`, `unidades.json`, `recursos.json`, `tecnologias.json`, `reglas.json` y `data/civs/*.json`. Mediciones sin ventana:

- `tests/economia.gd -- --minutes=20 --seeds=1` (lo pedido);
- un guion propio de una sola vez, que no queda en el repositorio, con las mismas parejas y semillas que `economia.gd`: cuenta la madera juntada y en qué se gasta (sección 3);
- otro guion de una sola vez que manda un grupo a 40 o 50 casillas y mide la llegada de cada unidad (sección 1);
- `tests/bench.gd`: 200 unidades, promedio 8,41 ms por tick, peor 80,79 ms, con 100 ms de presupuesto.

**Ojo con los números de línea.** Mientras se hacía esta auditoría, otra tarea (telemetría, `proceso/20`) estaba editando `sim.gd` y `sim_ai.gd`. Las líneas son las del 2026-11-14 a las 16:27 y pueden haberse corrido unas pocas. El nombre de la función sirve igual para buscar.

Dificultad: **chico** (horas, sin tocar el contrato de la simulación), **medio** (uno o dos días, toca la simulación y las pruebas), **grande** (varios días, cambia estructuras, la IA y los datos de las seis civilizaciones).

---

## 1. Movimiento

### Cómo funciona hoy

Una orden de mover (`"move"` → `_cmd_move`, `src/sim/sim.gd:253`) arma un cuadrado de `cols × rows` con 0,75 casillas de separación alrededor del punto pedido (`sp := 750`, línea 261). Reparte los lugares **por id** (`_own_units` ordena los ids, línea 241): la unidad de menor id va a la esquina de arriba a la izquierda, esté donde esté. Si el lugar cae en una casilla sólida, lo corre a la casilla libre más cercana (`map.nearest_free`, hasta 8 casillas). Después cada unidad pide **su propio camino** A* (`_set_goal`, línea 1445 → `SimMap.find_path`, `sim_map.gd:148`, sobre el `AStarGrid2D` del jugador). Camina a **su propia velocidad** (`_step_toward`, línea 1496, que usa `mods.speed(e)`), y cuando llega queda inactiva (`_update_unit`, línea 883, rama `O.MOVE`).

No existe la idea de "grupo" en la simulación: después del comando, ninguna estructura recuerda qué unidades fueron juntas. `SimEntity` (`src/sim/sim_entity.gd`) tiene una sola orden por unidad, sin campo de grupo, formación ni velocidad máxima.

### Medición

Grupo propio de Tawantinsuyu mandado hacia el centro del mapa (llano, semilla 1234), sin IA:

| Grupo | Distancia | Primera llegada | Última llegada | Diferencia | Dispersión máxima (de la unidad más lejana al centro del grupo) |
|---|---|---|---|---|---|
| 24 mixtos (6 guerreros, 6 honderos, 6 lanceros, 4 jinetes, 2 arietes) | 40 casillas | 18,9 s (jinetes) | 40,1 s (lanceros) | **21,2 s** | **14,3 casillas** |
| 12 aldeanos | 40 casillas | 33,2 s | 37,1 s | 3,9 s | 2,7 casillas |
| 60 militares (guerrero, hondero y lancero) | 50 casillas | 29,7 s | 50,5 s | **20,8 s** | 12,0 casillas |

Por tipo, en el grupo mixto: jinetes de 18,9 a 19,9 s; guerreros de 25,7 a 31,8 s; honderos de 29,7 a 36,6 s; arietes de 35,6 a 37,1 s; lanceros de 33,4 a 40,1 s. Los jinetes llegan **20 s antes** que los lanceros y pelean solos. El tick en que se aplica la orden de 60 unidades costó 8,2 ms (60 búsquedas A*); el de 24, 3,2 ms.

Velocidades en `data/unidades.json` (milésimas de casilla por segundo): jinete 2200, explorador 2100, guerrero 1600, compañía japonesa 1550, boleador 1300, aldeano y hondero 1250, arcabucero y awqa 1150, lancero 1100, chang suek 1050, elefante del rey 850, ariete 750, carpa real 650. Entre la más rápida y la más lenta del mismo ejército hay casi el triple.

### Tabla

| Punto | Qué hay hoy | Qué falta | Dificultad | Riesgo para el determinismo o el rendimiento |
|---|---|---|---|---|
| Reparto de destinos | Cuadrado de lado `ceil(√n)` con 0,75 casillas entre lugares, centrado en el clic (`sim.gd:253-276`). La separación de 750 está escrita en el código, no en `data/` (contra la regla 4 de `CLAUDE.md`). | Asignar cada lugar a la unidad más cercana a él, para que no se crucen. Separar más a las unidades grandes (radio de 420 a 900 en ariete, elefantes y carpa). | Chico (con asignación ávida en orden de id, en enteros) | Ninguno si se ordena por distancia entera y se desempata por id. Asignación ávida: O(n²); 200 unidades son 40 000 distancias, menos de 1 ms. |
| Formación | No hay. El cuadrado no mira hacia dónde se va: es el mismo vaya el grupo al norte o al sur. No pone el choque adelante ni la distancia atrás. | Formación en línea, perpendicular a la dirección (el vector del centro del grupo al clic, normalizado con `isqrt`), con choque y línea adelante, distancia atrás y asedio al fondo. Formaciones a elegir (línea, cuña, dispersa, columna). | Medio | Sin trigonometría: la perpendicular de (dx, dy) es (−dy, dx), así que alcanza con enteros e `isqrt`. Los tipos de formación y sus separaciones van en `data/reglas.json`. |
| Velocidad común | No hay. Cada unidad usa `mods.speed(e)` (`sim_mods.gd:582`). | Que el grupo camine a la velocidad de su unidad más lenta mientras dure la orden. Un campo por unidad (`group_speed`) que `_step_toward` respete con `mini(spd, group_speed)`. | Chico | Ninguno: es un entero más en el estado, y tiene que entrar en `state_hash`. |
| Espera y reagrupamiento | No hay. Nadie espera a nadie: el que llega primero queda inactivo y, si es militar, ataca lo que ve (`_do_idle`, línea 927). | (a) Reunirse antes de salir cuando el grupo está desparramado. (b) Que los rezagados apuren y los adelantados frenen según la distancia al centro del grupo. | Medio | Hay que calcular el centro del grupo en cada tick o cada pocos: O(n) por grupo, barato. Va todo en enteros. |
| Orden de llegada | Depende solo de la velocidad y del camino: llegan primero los jinetes y al final los lanceros y el asedio (ver la medición). | Llegada conjunta con velocidad común. Si se quiere "el choque primero", con salidas escalonadas. | Chico, si ya está la velocidad común | Ninguno |
| Caminos | Un A* por unidad sobre el `AStarGrid2D` del jugador (`sim_map.gd:36`, `find_path` en la 148), con diagonales solo sin esquinas. Hay una grilla por jugador por las puertas. | Un solo camino para el grupo (el del líder o el del centro) y desplazamientos fijos de cada lugar respecto de él. Hoy un grupo de 60 hace 60 búsquedas en el mismo tick. | Medio | **Mejora** el rendimiento (1 búsqueda en vez de n). El determinismo de `AStarGrid2D` entre plataformas sigue abierto (A-009); un camino compartido reduce cuántas veces depende de él. |
| Separación | Tabla espacial de 1 casilla, cada 2 ticks (`separacion_cada_ticks`), empuje a la mitad, menos a quien trabaja quieto (`anchored`) (`_separate`, línea 1562). | Que los del mismo grupo en marcha no se empujen entre sí (o mucho menos), así la formación no se deshace en los pasos angostos. | Chico | La separación ya es el sistema que más cuesta con muchas unidades; agregar la comparación de grupo es O(1) por par. |
| Aldeanos: cerca, cada uno corre; lejos, en bloque | No se distingue: el aldeano mandado a recolectar o construir va solo, por `_approach` (línea 1536), y el mandado a mover entra en el cuadrado. Los 12 aldeanos de la medición llegaron con 3,9 s de diferencia porque tienen todos la misma velocidad; no esperan a nadie. | Lo que pidió el autor: si el blanco está a menos de N casillas (dato), cada uno va por su cuenta; si está lejos, el grupo se forma y camina junto hasta N casillas del blanco y ahí se suelta. | Medio | Ninguno, si N está en `reglas.json` y la decisión se toma en `_cmd_target` y `_cmd_move` con distancias enteras. |
| Militares siempre agrupados | Los grupos de la IA salen juntos del punto de reunión (`_attack`, `sim_ai.gd:787`), pero se estiran en el camino igual que los del jugador. Los refuerzos que salen del cuartel van solos al punto de reunión (`_spawn_from`, `sim.gd:1411`, con `amove` si son militares). | Velocidad común y reagrupamiento por defecto para toda orden de más de una unidad militar. Para el jugador, una tecla para soltar la formación. | Medio | El mismo de la fila "Velocidad común". |
| Ataque en movimiento | Cada 3 ticks busca enemigos (`O.ATTACK_MOVE` en `_update_unit`); al encontrar uno, la unidad deja el grupo y no vuelve a la formación: retoma `amove_x/amove_y` cuando el blanco muere. | Que al retomar vuelva a su lugar en la formación, no al punto suelto. | Chico, si ya está la formación | Ninguno |
| Atascos | `stuck > 15` en `_follow` (línea 1471) da la orden por cumplida; `stuck > 25` en recolectar, construir o atacar la abandona. | Repetir la búsqueda del camino antes de rendirse. | Chico | Una búsqueda A* más por atasco: barato. |

---

## 2. Economía

### Almacenes por civilización

`deposito` (`data/edificios.json`): 75 de madera, 2×2, 600 de vida, 20 s; **recibe los cuatro recursos** (`"deposito": ["alimento", "madera", "piedra", "riqueza"]`). El centro también los recibe todos. Una civ puede renombrarlo, quitarlo (`sin_edificios`) o sumar edificios propios con `deposito` (`SimData._merge`, `sim_data.gd:45`).

| Civ | Dónde se entrega | Notas |
|---|---|---|
| Tawantinsuyu | Llaqta (centro, los 4), Tambo (depósito, los 4), **Qollqa** (solo alimento; además produce awqa) | La qollqa es el único almacén de un solo recurso en todo el juego. |
| Mapuches | Lof (los 4; reemplaza al centro), Troje (depósito, los 4) | Sin centro (`sin_edificios`). |
| Guaraníes | Oga guasu (centro), Tapyi (depósito) | Los 4 en los dos. |
| Etiopía | Kätäma (centro), Depósito (sin nombre propio) | El gult rinde sin aldeanos (`renta`). |
| Palmares | Cerca real (centro), Paiol (depósito), **Mocambo** (los 4, da población) | |
| Ayutthaya | Wang (centro), **elefante del rey** (unidad que camina; recibe alimento, madera y piedra, no riqueza) | **No tiene depósito**: `deposito` figura en `sin_edificios`, aunque `edificios.deposito.nombre` lo renombra a "Phra Khlang (almacén)" (dato muerto). |

Efecto lateral: las tecnologías se atan al **tipo** de edificio (`tecnologias.json` → `"edificio"`), no a una capacidad. Ayutthaya no puede investigar `hachas`, `hachas_2`, `canteria` ni `orfebreria` (las cuatro son del `deposito`), y los mapuches no pueden investigar `cestas`, `riego`, `riego_2`, `mamposteria` ni `vigias` (son del `centro`, y el lof es otro tipo). La interfaz las filtra por `t["edificio"] != first.type` (`controller.gd`, en `commands()`) y la IA busca el edificio con `by_type.get(t["edificio"])` (`sim_ai.gd:132`). Si los almacenes se separan por recurso, hay que decidir en qué almacén queda cada tecnología.

### Tabla

| Punto | Qué hay hoy | Qué falta | Dificultad | Riesgo |
|---|---|---|---|---|
| Almacenes por recurso | Un solo `deposito` para los cuatro recursos (`data/edificios.json`). La simulación ya admite almacenes de un recurso: `_accepts` (`sim.gd:1742`) y `nearest_dropoff` (línea 1687) leen la lista `deposito` de cada edificio, y la qollqa inca ya funciona así. | Datos: un almacén por recurso o por grupo de recursos (madera; piedra y riqueza; alimento), con costos y tamaños propios, en `edificios.json`, con nombres de cada civ en `data/civs/*.json`. Una civ puede quedarse con el almacén unificado como rasgo propio. | **Chico en la simulación, medio en datos e interfaz**: casillas de la grilla en `data/interfaz.json`, glifos y mallas por función (`glyphs.gd`, `civ_meshes.gd`, `meshes.gd` tienen `"deposito"` escrito a mano) | Ninguno para el determinismo. `nearest_dropoff` recorre todos los `actives` por cada entrega: con más almacenes cuesta un poco más (O(edificios)); habría que indexarlos por recurso si crece. |
| Al terminar el almacén, los constructores recolectan | `_do_build` (`sim.gd:1159`): al terminar busca otro cimiento propio a menos de 10 casillas (`_nearest_unbuilt(..., 10000)`, número escrito en el código) y, si no hay, **vuelve a lo que recolectaba antes** (`gather_kind`) en un radio de 30 casillas (`radio_retomar`) contado desde donde está. Un aldeano recién salido del centro (sin `gather_kind`) queda **inactivo**. Uno que juntaba alimento y construyó un almacén al lado de la arcilla vuelve a buscar alimento, no arcilla. Solo las granjas se ponen a trabajar solas (primera rama de `_do_build`). | Que el almacén diga qué se recolecta al terminarlo: el recurso más cercano de los que acepta (o el que eligió el jugador al colocarlo), y que los constructores se pongan a juntarlo. En AoE4, quien termina un aserradero se pone a talar. | Chico | Ninguno: `find_resource` ya es determinista (anillos de celdas, desempate por id). |
| Al agotarse un recurso | `_do_gather` (línea 977): si la fuente ya no sirve, busca otra **del mismo tipo** a menos de 10 casillas (`radio_rebusca`); si no hay, entrega lo que carga y queda inactivo. `_exhaust` (línea 1058) pasa a los trabajadores a lo que deja el recurso (roza → yerbal → roza). | Avisar "aldeanos inactivos" con lugar. Buscar desde el almacén y no desde el aldeano, para que no se aleje. | Chico | Ninguno |
| Punto de reunión sobre un recurso | Existe: `_cmd_rally` guarda `rally_target` (línea 767) y `_spawn_from` (línea 1411) pone a recolectar al aldeano nuevo si el blanco es un recurso o una granja propia, o a construir si es un cimiento. | Nada en lo básico. Falta que el punto de reunión sobre un almacén mande a juntar lo que el almacén recibe. | Chico | Ninguno |
| Granjas y resiembra | La granja común (`granja`: 60 de madera, 3×3) **no se agota**: no tiene `cantidad`. Un aldeano por granja (`_farm_free`). Solo la roza guaraní se agota (500) y deja yerbal o capuera (`_roza_follows`); el yerbal reabre la roza si alcanza la madera y está prendida la `resiembra` (`_roza_reopens`). | Si las granjas comunes se agotaran (como en AoE2), haría falta la resiembra automática; AoE4 no la necesita porque sus granjas son infinitas. Hoy está bien como en AoE4. | — | — |
| Ganado | No hay animales para arrear ni cazar. El alimento silvestre es el `arbusto` (150). El ganado mapuche son "cabezas" abstractas dentro del corral (`ganado` en `sim_mods.gd`, desde la línea 254). | Caza (animales que huyen) y ganado que se lleva al centro: son contenido nuevo, no correcciones. | Grande | Los animales que huyen necesitan movimiento propio y azar: tiene que salir del `SimRng`. |
| Cola de construcción con Mayús | Al colocar con Mayús se manda **un comando `build` por cimiento** a los mismos aldeanos (`controller.gd`, `_place`), y cada uno reemplaza al anterior. Funciona de casualidad: el último cimiento se hace primero y después `_nearest_unbuilt` encadena los que estén a menos de 10 casillas. Los que estén más lejos quedan sin hacer. | Cola real de cimientos por aldeano. | Medio | Si se guarda en la simulación es estado nuevo que entra en el hash; si se resuelve en el cliente (como `mundo_cola.gd`), no toca la simulación. |
| Distancia entre la fuente y el almacén | La IA construye un almacén cuando hay 3 o más aldeanos juntando lejos (`_far_gather_point`, `sim_ai.gd:476`, con 4,5 casillas escritas en el código). | Para el jugador, un aviso o un indicador de "camino largo" (AoE4 no lo tiene; es opcional). | — | — |

---

## 3. Producción militar y uso de la madera

### Quién produce qué

Base (`data/edificios.json`): **un solo `cuartel`** (150 de madera, 3×3, 35 s) produce guerrero, hondero, lancero y ariete, es decir choque, distancia, línea y asedio. Los hitos militares de cada civ también producen.

| Civ | Edificios comunes que producen | Propios que producen | Hitos que producen |
|---|---|---|---|
| Tawantinsuyu | Llaqta: aldeano, explorador. Kallanka (cuartel): guerrero, hondero, lancero, **boleador**, ariete | Qollqa (40 de piedra, 20 de mit'a): awqa | Pukara mayor (awqa, hondero), Kallanka real (guerrero, hondero, lancero, boleador), Vilcabamba (jinete, arcabucero) |
| Mapuches | Ruka de guerra (cuartel): guerrero, hondero, lancero, **jinete** | Lof (110 de madera): aldeano, explorador | Rewe de caballería (jinete) |
| Guaraníes | Centro: aldeano, explorador. Aty de guerra (cuartel): guerrero, hondero, lancero, ariete | — | Aty guasu (hondero, guerrero), Misión (arcabucero, lancero) |
| Etiopía | Kätäma: aldeano, explorador (el base). Campamento de chewa (cuartel): guerrero, hondero, lancero, ariete | — | Remonta (guerrero), Alianza (arcabucero) |
| Palmares | Cerca real: **solo explorador**. Casa de guerra (cuartel): guerrero, hondero, lancero, **arcabucero** | Mocambo (130 de madera): no produce | Mocambo de guerra (guerrero, hondero, arcabucero), Ferraria (arcabucero) |
| Ayutthaya | Wang: aldeano, explorador, elefante del rey. Cuartel de la guardia: guerrero, hondero, lancero, ariete | **Kraal** (200 de madera y 50 de riqueza): chang suek. **Barrio japonés** (150 de madera): compañía japonesa. **Barrio portugués** (150 de madera): arcabucero | Kraal real, Guardia extranjera |
| Invasores (solo IA) | Cuartel: guerrero, hondero, lancero, jinete, arcabucero, ariete | — | — |

Ayutthaya es la única civ con edificios separados por tipo de unidad, y solo para sus unidades propias. En las otras cinco el cuartel común lo hace todo, también el asedio y, según la civ, la caballería y la pólvora.

### Costos (base, `data/unidades.json`)

| Unidad | Función | Costo | Madera |
|---|---|---|---|
| guerrero | choque | 60 de alimento, 25 de riqueza | 0 |
| hondero | distancia | 30 de alimento, **45 de madera** | 45 |
| lancero | línea | 60 de alimento, 25 de madera, 10 de riqueza | 25 |
| jinete | choque | 100 de alimento, 70 de riqueza | 0 |
| arcabucero | distancia | 60 de alimento, 70 de riqueza | 0 |
| ariete | asedio | **200 de madera**, 60 de riqueza | 200 |
| explorador | — | 80 de alimento | 0 |

Las civs cambian varios (`data/civs/*.json`): el ariete inca cuesta 60 de alimento, 40 de madera y 20 de mit'a; el guaraní, 120 de madera y 40 de riqueza; el hondero etíope, 35 de alimento y 35 de madera; el lancero mapuche, 50 de alimento y 25 de madera.

### Cuánto se usa la madera (20 minutos, IA contra IA, llano)

Guion de una sola vez con las mismas parejas y semillas que `tests/economia.gd` (`900 + i·31`, la civ i contra la i+1). "Gasto" suma el costo de cada unidad al salir y de cada cimiento al colocarse (una cota alta: no descuenta las cancelaciones).

| Civ (rival) | Edad al minuto 20 | Madera juntada | Parte de lo juntado (los 4 recursos) | Madera en edificios | … en granjas | … en casas | Cuarteles (madera) | Madera en unidades | Madera en el banco al final | Aldeanos en madera |
|---|---|---|---|---|---|---|---|---|---|---|
| tawantinsuyu (mapuches) | III | 6378 | 28 % | 3015 | 1260 | 350 | 3 (450) | 2330 | 83 | 11 de 42 |
| mapuches (tawantinsuyu) | III | 5245 | 30 % | 3475 | 1560 | 400 | 2 (300) | 1515 | 245 | 15 de 47 |
| mapuches (guaraníes) | III | 5562 | 30 % | 3145 | 1380 | 250 | 3 (450) | 1650 | 442 | 11 de 43 |
| guaraníes (mapuches) | III | 6349 | 30 % | 3235 | 1710 | 300 | 5 (750) | 1880 | 664 | 12 de 42 |
| guaraníes (etiopía) | III | 5220 | 31 % | 3235 | 1710 | 450 | 4 (600) | 2060 | 10 | 21 de 42 |
| etiopía (guaraníes) | II | 4100 | 33 % | 2460 | 660 | 250 | 2 (300) | 1765 | 40 | 4 de 17 (perdió la base) |
| etiopía (palmares) | III | 6191 | 31 % | 3415 | 1440 | 300 | 3 (450) | 2200 | 101 | 13 de 42 |
| palmares (etiopía) | II | 4995 | 33 % | 2675 | 1140 | 350 | 3 (450) | 1750 | 220 | 11 de 47 |
| palmares (ayutthaya) | II | 5175 | 33 % | 2815 | 1380 | 250 | 3 (450) | 2240 | 95 | 13 de 49 |
| ayutthaya (palmares) | II | 4000 | 26 % | 2635 | 1260 | 350 | 2 (300) | 1280 | 105 | 12 de 46 |
| ayutthaya (tawantinsuyu) | III | 5358 | 30 % | 3015 | 1140 | 400 | 5 (750) | 2195 | 38 | 13 de 44 |
| tawantinsuyu (ayutthaya) | III | 6038 | 30 % | 2925 | 1320 | 350 | 2 (300) | 2375 | 298 | 18 de 47 |

Lectura:

- **La madera no sobra, por lo menos para la IA.** Es entre el 26 y el 33 % de lo juntado, y en 9 de las 12 partidas el banco termina con menos de 300. La IA pone en madera a unos 12 de cada 44 aldeanos.
- **Más de la mitad de la madera va a edificios, y casi la mitad de eso son granjas** (de 660 a 1710 por partida). Los cuarteles son poco: de 300 a 750, y la IA hace 2 a 5 solo porque su regla de "sobra" (`sim_ai.gd:426`) los pide, no porque los necesite para producir cosas distintas.
- **En unidades, la madera la piden el hondero (45), el lancero (25) y el ariete (200).** Los incas gastaron 2330 con 14 arietes y 42 lanceros; Ayutthaya, 1280 con 52 guerreros, que no piden madera.
- La sensación del autor ("la madera pasa a ser un poco innecesaria") no sale de que falte madera en los números, sino de que **un solo edificio de 150 alcanza para todo el ejército**: una vez hecho el cuartel, la madera ya no decide qué ejército se puede hacer. Separar los productores la vuelve una decisión (qué edificio hago primero, cuántos de cada uno).

`tests/economia.gd -- --minutes=20 --seeds=1` (las mismas seis partidas) da las edades II entre 5:30 (Etiopía) y 8:15 (Ayutthaya), la III entre 12:00 (guaraníes) y 18:40 (Ayutthaya; Palmares no llega), y las órdenes de producción por minuto: los incas mandan 2,17 lanceros, 1,70 guerreros, 1,18 honderos y 0,75 arietes por minuto; los guaraníes, 3,60 honderos y 3,02 guerreros. Las órdenes de construir cuarteles van de 0,12 a 0,23 por minuto, contra 0,97 a 2,30 de granjas.

### Tabla

| Punto | Qué hay hoy | Qué falta | Dificultad | Riesgo |
|---|---|---|---|---|
| Edificios por tipo de unidad | Un cuartel lo hace todo (`edificios.json` → `cuartel.produce`; cada civ lo pisa con `produce`, `sim_data.gd:47-49`). La simulación no supone un solo productor: `_cmd_train` acepta cualquier edificio cuyo `produce` incluya la unidad. | Datos: separar en cuartel (choque y línea), arquería o campo de tiro (distancia), establo o corral de guerra (caballería, solo donde haya caballo) y taller de asedio, con costos en madera. Cada civ decide su reparto (Ayutthaya ya tiene barrios; los mapuches podrían tener la caballería en el cuartel como rasgo propio). | **Medio**: datos de las seis civs, grilla (`data/interfaz.json` → `militar`), glifos y mallas, y la IA (sección 5) | Ninguno para el determinismo. Rendimiento: más edificios con cola. `_update_building` es O(1) por edificio. |
| Que la madera importe | La madera ya pesa (ver la tabla de arriba), pero sobre todo por granjas, casas y arietes. Las unidades de madera son el hondero y el lancero; el guerrero, el jinete y el arcabucero no usan madera. | Edificios de producción de 150 a 200 de madera cada uno, y un segundo o tercero de cada tipo para producir en paralelo. Revisar si el hondero sigue siendo la única unidad básica que pide madera de verdad. | Chico (datos), pero pide `tests/torneo.gd` para el balance | — |
| Cola en varios edificios | Con varios edificios del mismo tipo seleccionados, cada clic encola **una unidad en cada uno**; con Mayús, cinco en cada uno (`controller.gd`, `run_command`, rama `"train"`). | En AoE4, cada clic va al edificio de cola más corta. | Chico | Ninguno (es la interfaz). |
| Investigaciones militares | Las 8 militares están en el `cuartel` (`tecnologias.json`). | Si se separan los edificios, hay que repartirlas (arquería: alcance; establo: caballería) o atarlas a una capacidad y no al tipo. | Chico | — |

---

## 4. Comodidades de órdenes e interfaz

| Comodidad | Estado | Dónde | Qué falta | Dificultad | Riesgo |
|---|---|---|---|---|---|
| Grupos de control | **Sí.** Ctrl+n asigna, Mayús+n suma, n selecciona y n dos veces seguidas centra la cámara. Fila de pestañas con el tipo más numeroso y la cantidad. | `controller.gd:678-702` (`_key`), `src/game/ui/grupos.gd` | Alt+n para robar unidades a otros grupos; guardar los grupos de edificios (hoy se puede, pero no hay producción por grupo). | Chico | Ninguno: es la interfaz. |
| Seleccionar el mismo tipo | **Sí**, con doble clic: los del mismo tipo **en pantalla**. | `_select_same_type_on_screen`, `controller.gd:595` | Ctrl+doble clic para todo el mapa; filtrar la selección por tipo desde el panel (clic en el ícono). | Chico | Ninguno |
| Aldeano inactivo | **Sí**: tecla `.` recorre los inactivos y centra la cámara. Ícono "Zz" sobre cada aldeano inactivo en el mundo. El panel de economía dice "N ociosos (tecla .)". | `controller.gd:704` y `_select_idle_villager` (línea 738); `mundo_capa.gd:459`; `panel_economia.gd:62` | Un **botón** con la cuenta siempre visible (AoE4 lo tiene junto al minimapa) y Mayús+`.` para tomarlos a todos. | Chico | Ninguno |
| Ejército inactivo | **No.** | — | Tecla y botón para seleccionar a los militares inactivos (o a todo el ejército, como el F2 de StarCraft). Hoy F2 abre un panel (`panel_partida.gd:148`). | Chico | Ninguno |
| Cola de órdenes con Mayús | **Sí, en el cliente.** Mayús+clic derecho y Mayús+A encolan mover, atacar y recolectar; se envían como comandos normales cuando la unidad queda `IDLE`. Dibuja la línea de los puntos. También desde el minimapa. | `src/game/ui/mundo_cola.gd`, `controller.gd:520` y `625`, `minimap.gd:177` | (a) Una orden de recolectar nunca termina en `IDLE`, así que lo encolado detrás de ella no sale nunca. (b) No encola construcción (ver la sección 2). (c) Como vive en el cliente, la IA no la usa y una repetición la ve como comandos sueltos. Está bien para el lockstep. | Chico para (a) y (b) | Ninguno (cliente). |
| Patrullar | **No.** | — | Orden `patrol`: ida y vuelta entre dos puntos en ataque en movimiento. | Chico (simulación: una orden nueva que alterna `amove` entre dos puntos) | Estado nuevo (dos puntos) que entra en `state_hash`. |
| Mantener posición | **No.** Toda unidad inactiva persigue lo que ve (`_do_idle`, `sim.gd:927`). `"stop"` la deja inactiva y vuelve a perseguir. | Orden de mantener posición (solo pegar a lo que está en alcance). | Chico | Un campo nuevo en `SimEntity`. |
| Posturas (agresiva, defensiva, firme, sin atacar) | **No.** Una sola conducta: persigue sin límite a lo que entra en su visión y no vuelve al lugar. | Postura por unidad, con radio de persecución y regreso a la posición original, como en AoE4. | Medio | Estado nuevo; el regreso necesita guardar el punto de origen. |
| Punto de reunión sobre un recurso | **Sí** (ver la sección 2). Clic derecho con un edificio que produce elegido. | `controller.gd:615` (`_right_click`), `sim.gd:767` y `1411` | Punto de reunión sobre un almacén (que se ponga a juntar lo que el almacén recibe). | Chico | Ninguno |
| Muros arrastrando | **Sí.** Si el edificio tiene `"linea": true` (empalizada; la cerca palmarina), se arrastra y la orden `build_line` pone un cimiento por casilla; los aldeanos van de uno al siguiente. | `controller.gd:510` (`_line_drag`), `_show_line` (835), `_finish_line` (857); `sim.gd:1903` | Muro de piedra (hoy no hay); mostrar el costo total mientras se arrastra. | Chico | Ninguno |
| Puertas | **Sí.** `puerta` (20 de madera) reemplaza un tramo de empalizada propia (`_replace_wall`) y es pasable para el dueño y sus aliados, y sólida para los demás, con una grilla A* por jugador. | `sim_map.gd:88-106` (`mark`), `sim.gd`, `_replace_wall` | Abrir y cerrar a mano. Tawantinsuyu no tiene empalizada ni puerta (`sin_edificios`). | Chico | Una grilla A* por jugador ya existe; abrir y cerrar cambia los puntos sólidos de esas grillas y entra en el hash. |
| Formaciones (elegir) | **No** (ver la sección 1). | — | Botones en la grilla de unidades militares (hoy usa las casillas A, S y F). | Medio | Ver la sección 1. |
| Encolar en varios edificios | Parcial (ver la sección 3). | `controller.gd:318-322` | Repartir entre edificios. | Chico | Ninguno |
| Seleccionar todos los edificios de un tipo | **No** (sí con doble clic en pantalla). | — | Ctrl+doble clic o atajos por tipo de edificio. | Chico | Ninguno |
| Producción y punto de reunión desde un grupo de edificios | Punto de reunión: sí, a todos los seleccionados que producen (`_right_click`). | — | — | — | — |
| Edificio inactivo (sin cola) | **No.** | — | Indicador de edificios de producción parados (AoE4 lo marca). | Chico | Ninguno |

---

## 5. La IA (`src/sim/sim_ai.gd`)

La IA ya produce desde **todos** los edificios que producen militares (`_production`, línea 559, recorre `by_type` y filtra con `_makes_military`), y cada edificio entrena solo lo que figura en su `produce` (comentario en la línea 587). Pero tiene nombres de tipos escritos a mano y supuestos que se rompen si se separan los edificios:

| Supuesto | Dónde | Qué pasa si se separan los edificios | Arreglo |
|---|---|---|---|
| El edificio militar se llama `cuartel` | `_buildings`, líneas 425-429: decide cuándo hacer el primero (11 aldeanos), el segundo (edad II y 24 aldeanos) y hasta 5 si sobra (alimento > 800 y madera > 300) | Nunca construye una arquería, un establo ni un taller: no tendría honderos, jinetes ni arietes. | Una lista de edificios militares por civ en datos (como `ia_edificios`), con orden y condiciones, o elegir el edificio según la unidad que pide `_counter_order`. |
| El avance a la edad III exige un `cuartel` | `_wants_hito`, línea 231 | Si una civ no tiene un tipo llamado `cuartel`, nunca ahorra para el hito de la edad III. | Exigir "algún edificio que produzca militares" (`_makes_military`). |
| Las casas se adelantan según la cantidad de cuarteles | `_buildings`, línea 417 (`margin := 3 + cuarteles·2`) | Con producción repartida, el margen de población queda corto. | Contar todos los productores militares. |
| `_makes_military` solo cuenta choque, distancia y línea | línea 883 | **Un taller de asedio (que solo produce `asedio`) no cuenta como productor**: no entra en `_production`, no recibe punto de reunión y no hace arietes. | Sumar `asedio` a la lista o usar `is_military()` de la definición. |
| Los arietes salen del edificio que tenga `ariete` en `produce` | `_production`, línea 580 | Bien, si se arregla el punto anterior. | — |
| Los almacenes se llaman `deposito` y reciben todo | `_buildings`, líneas 431-437: hasta 4, cuando 3 aldeanos juntan a más de 4,5 casillas del almacén más cercano; manda un solo aldeano, el más cercano a la fuente, sea del recurso que sea | Con almacenes por recurso, construiría el `deposito` (que ya no existiría) o el que no corresponde. El constructor no es necesariamente de ese recurso, y al terminar vuelve a lo suyo (sección 2). | Tabla recurso → tipo de almacén por civ (en datos), y mandar a los aldeanos de ese recurso. |
| Los aldeanos se asignan buscando desde el centro | `_economy`, líneas 193 y 202: `find_resource(..., centro.x, centro.y, 40000)` | No mira dónde están los almacenes: manda gente a fuentes cercanas al centro aunque el almacén esté en otro lado. | Buscar desde el almacén de ese recurso. |
| Las granjas se llaman `granja` | `_economy` (línea 195) y `_engine` (línea 266) | Bien mientras se llamen así (los andenes incas no son `granja`). | — |
| Las tecnologías se buscan por tipo de edificio | `_research`, línea 132 | Con las tecnologías del `deposito` repartidas, hay que cambiar el dato, no el código. | — |
| Las proporciones de aldeanos y el tope de aldeanos están en el código | `ratio_early` y `ratio_late` (líneas 31-32), `max_villagers` (pisado por la dificultad) | Con edificios de 150 a 200 de madera, la proporción de madera (33 % y 25 %) puede quedar corta. | Pasarlas a `data/` (regla 4 de `CLAUDE.md`; `docs/08` ya lo prevé para H2). |
| Ejército: un solo grupo, un `move` con `amove` | `_attack` (línea 787), `_military` (633), refuerzos al `rally` | Sin velocidad común llegan estirados (sección 1). Si la simulación agrega grupos, la IA los aprovecha sin cambios. | — |

---

## 6. Lo que habría que tocar para cada mejora

| Mejora | Datos | Simulación | Interfaz | IA | Pruebas |
|---|---|---|---|---|---|
| **Destinos sin cruces y en línea según la dirección** | `reglas.json` → `formacion`: separación por radio, profundidad máxima, orden de funciones (choque, línea, distancia, asedio) | `sim.gd` → `_cmd_move` (reparto por cercanía, perpendicular con enteros y `isqrt`). Sacar el `750` del código. | — | — | `test_determinism.gd`, `bench.gd`; prueba nueva: el grupo llega sin cruces y en filas |
| **Velocidad común y reagrupamiento** | `reglas.json`: distancia para soltar el grupo, tolerancia de dispersión | `sim_entity.gd`: `group` (id del grupo) y `group_speed`. `sim.gd`: `_cmd_move` los asigna; `_step_toward` respeta `group_speed`; `_update_unit` (`O.MOVE` y `O.ATTACK_MOVE`) frena a los adelantados según el centro del grupo; `_separate` empuja menos dentro del grupo; `state_hash` los incluye. | Tecla para soltar la formación | Nada (la aprovecha) | Determinismo; la medición de la sección 1 como prueba (diferencia de llegada menor a N s) |
| **Camino compartido por grupo** | — | `_cmd_move`: un `find_path` para el centro del grupo; cada unidad sigue los mismos puntos con su desplazamiento. `_follow` con desplazamiento. | — | — | `bench.gd` con órdenes de 60 a 200 unidades |
| **Aldeanos: cerca, cada uno; lejos, en bloque** | `reglas.json` → `aldeanos_bloque_casillas` | `_cmd_target` (cuando el blanco es un recurso, un cimiento o un almacén): si la distancia supera el umbral, primero un movimiento de grupo y después la orden; un campo `then_target` en `SimEntity` | — | — | Prueba nueva con 12 aldeanos a 5 y a 40 casillas |
| **Formaciones elegibles** | `reglas.json` → formaciones (línea, cuña, columna, dispersa) | Campo `formation` en el comando `move` | Botones en la grilla de unidades (`controller.gd` → `commands()`, `data/interfaz.json` → `fijas`) y glifos | — | Captura con `--autotest` |
| **Almacenes por recurso** | `edificios.json`: `almacen_madera`, `almacen_piedra` (piedra y riqueza), `almacen_alimento` (o los nombres que se elijan), con costos; `data/civs/*.json`: nombres, `construye`, `sin_edificios`; `tecnologias.json`: a qué almacén va cada una; `interfaz.json` → `grilla.economia` | Nada obligatorio (`_accepts` y `nearest_dropoff` ya lo soportan) | `glyphs.gd`, `meshes.gd`, `civ_meshes.gd`, `overlay.gd` (`HEIGHTS`) tienen `"deposito"` escrito a mano; `controller.gd` → `DESCS` | `sim_ai.gd` → `_buildings` (líneas 431-437) y `_far_gather_point`: tabla recurso → almacén | `civ_smoke.gd`, `torneo.gd -- --minutes=30 --seeds=2` |
| **Recolectar al terminar el almacén** | `edificios.json`: `"recolecta_al_terminar": true` en los almacenes (o deducirlo de `deposito`) | `sim.gd` → `_do_build`: si el edificio terminado tiene `deposito`, buscar con `find_resource` el recurso aceptado más cercano **al edificio** y ponerse a recolectar antes de buscar otro cimiento. Sacar el `10000` a `reglas.json`. | — | Mandar al almacén a aldeanos de ese recurso | Prueba nueva: 3 aldeanos construyen junto a la arcilla y al terminar juntan arcilla |
| **Punto de reunión sobre un almacén** | — | `_spawn_from`: si `rally_target` es un almacén propio, recolectar el recurso más cercano de los que recibe | — | — | — |
| **Edificios de producción por tipo** | `edificios.json`: `cuartel` (choque y línea), `arqueria` (distancia), `establo` (caballería), `taller` (asedio), con madera; `data/civs/*.json` → `produce` y `construye` de cada civ; `tecnologias.json` → `edificio` de las 8 militares; `interfaz.json` → `grilla.militar` | Nada obligatorio | Grilla, glifos y mallas por función; `controller.gd` → `DESCS` | `sim_ai.gd` → `_buildings` (425-429), `_wants_hito` (231), margen de casas (417), `_makes_military` (883, sumar `asedio`) | `civ_smoke.gd`, `torneo.gd`, `economia.gd` (gasto de madera) |
| **Cola de producción repartida** | — | — | `controller.gd` → `run_command`, rama `"train"`: elegir el edificio de cola más corta | — | `--autotest` |
| **Ejército inactivo, botón de aldeanos inactivos** | — | — | `controller.gd` → `_key`, `hud.gd` (botón junto al minimapa) | — | `--autotest` y captura |
| **Patrullar, mantener posición, posturas** | `reglas.json` → `posturas` (radio de persecución y regreso) | `sim_entity.gd`: `stance`, `home_x`, `home_y`, `patrol_x`, `patrol_y`; `SimEntity.Order` gana `PATROL` y `HOLD`; `sim.gd` → `_apply` (comandos nuevos), `_do_idle` y `_do_attack` (respetar la postura y volver), `state_hash` | Botones y atajos en `commands()`; texto de ayuda en `hud.gd:394` y `panel_pueblo.gd:129` | La IA puede patrullar su base | Determinismo |
| **Cola de órdenes completa** | — | — | `mundo_cola.gd`: considerar terminada una orden de recolectar o construir cuando cambie el blanco o quede inactiva; encolar cimientos con Mayús en `_place` | — | `--autotest` |
| **Tecnologías por capacidad (arregla Ayutthaya y mapuches)** | `tecnologias.json`: `"edificio"` como lista, o `"en": "deposito:madera"` | `research_block` y `_cmd_research` (validar contra el edificio) | `controller.gd` → `commands()` (el filtro `t["edificio"] != first.type`) | `_research` (línea 132) | `civ_smoke.gd` |

### Orden sugerido

1. **Recolectar al terminar el almacén** y **destinos sin cruces**: chicos, sin estado nuevo o con muy poco, y se notan enseguida.
2. **Velocidad común y reagrupamiento** (y con eso, llegada conjunta de militares): es lo que más acerca el movimiento a AoE4. Estado nuevo en la simulación.
3. **Almacenes por recurso** y **edificios de producción por tipo**: casi todo es datos, más la IA de la sección 5 y el torneo para el balance.
4. **Aldeanos en bloque cuando van lejos**, **formaciones elegibles** y **posturas**.
5. Comodidades de interfaz: ejército inactivo, botón de aldeanos inactivos, cola repartida, cola de órdenes completa.
