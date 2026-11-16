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
| [21](pruebas/21-torneo-hito-en-obra.txt) (10) | IA normal: ataca el hito en obra, no repite almacenes perdidos (4f) | 54 | **68** | **72** | 34 | 44 | **28** |
| [22](pruebas/22-torneo-micro-c2.txt) (10) | Micro C2 (C-64 por defecto): guerrero común a 1350, línea +6 contra el choque | 60 | 60 | **76** | 36 | 34 | 34 |
| [23](pruebas/23-torneo-todo-junto.txt) (10) | Todo junto: C2, hito en obra, equipos (movimiento nuevo), depósitos | 56 | 58 | **76** | 38 | 44 | **28** |
| [24](pruebas/24-torneo-roza-850.txt) (10) | Guaraníes: roza 850. **Descartado** | 58 | 60 | 72 | 36 | 46 | 28 |
| [25](pruebas/25-torneo-arquero-guarani.txt) (10) | Guaraníes: arquero 7 de ataque (antes 8); roza de vuelta a 900 | 58 | 60 | **66** | 38 | 44 | 34 |
| [26](pruebas/26-torneo-sitios-y-llamas.txt) (10) | IA que disputa sitios (5b) + una llama por vez | 62 | 58 | **80** | 34 | 32 | 34 |
| [27](pruebas/27-torneo-emboscada.txt) (10) | Guaraníes: emboscada 35 %. **Descartado** | 60 | 60 | 78 | 34 | 34 | 34 |
| [28](pruebas/28-torneo-alcance-guarani.txt) (10) | Guaraníes: alcance del arquero 5500 (antes 6000); emboscada de vuelta a 50 % | **68** | 60 | **68** | 38 | 32 | 34 |
| [29](pruebas/29-torneo-blancos.txt) (10) | Elección de blancos como AoE4 (5d) | **42** | 68 | **76** | 34 | 48 | 32 |
| [30](pruebas/30-torneo-sigilo-guarani.txt) (10) | Guaraníes: sigilo detectado a 4,5 casillas. **Descartado** | 42 | 66 | 76 | 38 | 46 | 32 |
| [31](pruebas/31-torneo-inalcanzable.txt) (10) | Recurso inalcanzable (6c) y experta (6b; no juega en el torneo) | 48 | 60 | **72** | 36 | 52 | 32 |

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
| G · Experta contra difícil | **Integrado (508d6ba).** La experta gana 33 de 48 a la difícil (69 %, igual que antes); las victorias claras suben de 10 a 17. Palmares queda en 25 % (necesita algo propio, no de la experta). Para todas las dificultades menos la fácil: la IA ataca el hito rival en obra y defiende el propio (5 de 6 partidas con enemigos cerca, antes 1); no reconstruye un almacén donde perdió uno (55 graneros → 2). La experta defiende en proporción y recupera sitios. Torneo 21 para la normal | [4f-experta-contra-dificil.md](4f-experta-contra-dificil.md) |
| H · Sonido | **Integrado (3b2faaf).** Instrumento propio por pueblo, sintetizado con numpy (`tools/audio/`, obra propia): quena y sikus, kultrun y trutruka, mbaraka y takuapu, kebero y masenqo, berimbau y atabaque, khong wong y ranat. Fanfarria de edad, alarma, entrenado y orden por pueblo (`data/audio.json`), con límite de ráfaga. Música de paz para Etiopía (C-24). `tests/sonido_civ.gd` OK (89 chequeos). Falta que alguien los escuche. Consultas C-53 a C-55 | [4g-sonido.md](4g-sonido.md) |
| I · Sonido con respeto | **Integrado (fbe38e4).** A pedido del jugador de historia (ronda 3), sin instrumentos sagrados en la tropa: mapuches con kakelkultrun, kull-kull y trutruka (sin kultrun); guaraníes con mimby y angu'apu (sin mbaraka ni takuapu); Etiopía con krar en vez de begena; Palmares con ngoma, ngongi, marimba y kisanji (sin berimbau ni capoeira). Consultas C-56 a C-60 | [4h-sonido-con-respeto.md](4h-sonido-con-respeto.md) |
| J · Arte, ronda 3 | **Integrado (261b22a).** Lo que marcó el jugador de historia: ushnu bajo, ancho y gris con portada trapezoidal; cantería inca de andesita gris; el rewe solo en el nguillatuwe y masa propia en los otros hitos mapuches; pewen con copa en paraguas; centro de piedra etíope en la edad IV; búfalo con cuernos en media luna y de arado; notas corregidas (tava, Cucaú sin bandera blanca, íbice de Walia y dukula en vez de nyala) | [4i-arte-ronda-3.md](4i-arte-ronda-3.md) |
| K · Veterano, ronda 3 | **Integrado (f090d7f).** Costo real del hito (adiós al "−300+"), radio del aura al colocar y seleccionar el hito, tiempo que falta de la obra con sus constructores, demos sin pasar el tope de población, ocho marcadores de cámara (Alt + 1…8; Ctrl + Alt para guardar), barras de vida de quien pelea | [4k-veterano-ronda-3.md](4k-veterano-ronda-3.md) |
| O · Depósitos de comida | **Integrado (9bc9785).** Pregunta del autor: "¿puede ser que no exista granero?" Todos los pueblos lo tienen, pero no se notaba: el tapyi guaraní se llamaba "Leñera". Ahora cada almacén dice qué recibe (tapyi: "Granero y leñera"; qollqa: "Granero"; lof: "Centro chico"; elefante: "Almacén que camina") y hay un aviso cuando 3 aldeanos o más llevan recursos a más de 12 casillas: "Levantá un Tapyi junto a la caza (Q Economía → E)". `tests/depositos_lejos.gd`: los cazadores usan el almacén nuevo desde el viaje siguiente, en los seis pueblos | [4m-depositos-de-comida.md](4m-depositos-de-comida.md) |
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

## Tercera ronda de jugadores (desde 2026-11-16)

Con los pasos 1 a 4 integrados, los mismos cuatro jugadores de las rondas 1 y 2, con su memoria, juegan la versión nueva. La experta contra la difícil (G) sigue en ajuste y se les avisa.
- Informes en [`proceso/22-testers/ronda-3/`](../22-testers/ronda-3/): veterano de AoE4, nuevo en los RTS, historia y estética, equipos y todos contra todos.
- **[Síntesis comparada](../22-testers/ronda-3/00-sintesis.md):** el hito tiene ventana de riesgo, los sitios duran 10 minutos, la caza y la ciudad andan, el balance queda en 34–60 %, las opciones de partida son "lo que más me ayudó" (nuevo) y el arte "mejoró mucho" (historia).
- Se atiende ya:
  - lo sagrado en el sonido (4h) y el arte marcado (4i), integrados;
  - la interfaz del veterano (4k), integrada;
  - la IA que ataque el hito en obra (G), el jugador nuevo (4j) y los equipos (4l), en curso.
- Pedidos que siguen:
  - la micro (mezcla de línea y distancia), con torneo y consulta;
  - la IA que dispute sitios;
  - Palmares en partidas largas de varios;
  - modelos de tropas.

| N · Micro (estudio) | **Integrado como estudio (9967d70), sin cambiar el balance.** Matriz de peleas (`tools/micro_matriz.gd`, 5 variantes por pelea) y modelo numérico (`tools/modelo_micro.py`). Causa: el guerrero común corre más que el hondero. Propuesta C2 (guerrero a 1350, línea +6 contra el choque): la mezcla sin micro pasa de 1 a 5 victorias de 5. Consulta C-64; el torneo, después de integrar la experta. Aparte: los dos números de velocidad fijos en `sim_mods.gd` pasan a `reglas.movimiento` (hash igual) | [5a-micro-estudio.md](5a-micro-estudio.md) |
| P · IA que disputa sitios | **Integrado (bbd769a).** Normal, difícil y experta defienden sus sitios y recuperan el más barato del rival con 1,5 veces la vida de los defensores (2 veces con la cuenta corriendo), sin goteo: grupo anotado, refuerzos en bloque, retirada si pierde. Ninguna IA pierde por sitios con el ejército en casa (antes, con 19 y 47 militares vivos); sitios quitados de 209 a 367 en 24 partidas. Torneo 26 | [5b-ia-disputa-sitios.md](5b-ia-disputa-sitios.md) |
| Q · Veterano, ronda 4 | **Integrado (ba59151).** Teclas configurables en Opciones (43 acciones, perfiles "De fábrica" y "AoE4", intercambio y aviso de choques); producción como AoE4 en varios edificios (una por pulsación al de cola más corta; Mayús, 5 en total); H recorre los centros; panel de varias unidades con retratos y vida, Mayús/Ctrl+clic; M centra; grupos exclusivos opcionales y grupo 0; sin avisos de la IA en IA contra IA; el círculo del centro explicado; demo de batalla en llano. Autotest 96 OK | [4o-veterano-ronda-4.md](4o-veterano-ronda-4.md) |
| R · Escala, paso 1 (solo vista) | **Integrado (94879dd).** Pedido del autor ("estamos muy lejos" de la sensación de AoE4). Persona de 1,02 a 0,75 casillas. En alturas de persona: casa de 0,8 a 1,9, cuartel de 1,2 a 2,7, centro de 2,1 a 3,4, hitos de 2,4 a 5,6, árbol de 2,0 a 4,0. Muros y techos suben sobre un zócalo; maquetas militares al alto del aldeano; siluetas del color del equipo detrás del bosque; zoom 28. El informe del veterano medía con el estandarte: el problema era mayor. Mismo hash; autotest 96 OK. Sigue: velocidad (C-65) y huellas (C-66) | [4p-escala.md](4p-escala.md) |
| S · Jugador nuevo, ronda 4 | **Integrado (6f0e9b6).** El centro muestra Aldeano en Q y Explorador en W en los seis pueblos (antes, una investigación tapaba la casilla: se dibujaba una cosa y se ejecutaba otra); `tests/casillas.gd` revisa 480 grillas; un solo `Controller.cmd_at` para dibujo, tecla y clic. La fácil atacada tiene tope (30): de 54–81 a 35. El aviso "atacá" dice hacia dónde está la capital y qué asedio usar. El tutorial pide una granja al acabarse los frutos. Cursor y clic sobre el animal propio usan el mismo blanco. Nombres comunes en el panel ("Centro · Oga guasu") y sin cortar. Autotest 101 OK | [4n-jugador-nuevo-ronda-4.md](4n-jugador-nuevo-ronda-4.md) |
| T · Veterano, ronda 5 | **Integrado (53066f1).** Mercado con galpón que se levanta (de 1,5 a 2,6–3,2 personas) y ruka a 2,0; la caza de Palmares con más venados (el de 0,35 era el pecarí); `tools/escala.gd` sin nada bajo la regla. "Zz" del tamaño de la cabeza, encima del aldeano. Barras de 25×3 px solo en lo dañado, elegido o bajo el mouse (opción para las sanas al pelear). Atajos globales: campana en B, todos los aldeanos en N, producción en P. Los 8 marcadores en la lista. Autotest 107 OK | [4r-veterano-ronda-5.md](4r-veterano-ronda-5.md) |
| U · Primera victoria | **Integrado (b74dce1).** El jugador nuevo le gana a la fácil 4 de 5 semillas antes de los 30 min (antes, 0 de 5), por rendición entre las 18:20 y las 26:29; sin asedio en la edad I no la tira. Causa: los mataban los honderos (59 de 71 bajas), no la torre; "A y clic" se quedaba pegándole a almacenes y caminos; el cañón de tacuara no llegaba. La fácil: sin caminos ni torre, 2 edificios de su tropa, tope 20 atacada, campana con 1 aldeano por enemigo, y se rinde si pierde 6 edificios o media capital. Resumen de la pelea perdida (qué los frenó y qué llevar); hoja de atajos en F12; con Alt, ícono de función sobre cada techo. Autotest 112 OK | [4q-primera-victoria.md](4q-primera-victoria.md) |
| V · Palmares en partidas largas | **Estudio (3a6706d) y cambio 1 aplicado.** Causa: la IA de las demás civs deja de hacer aldeanos a los 42 (normal), pero la gente de Palmares llega por la acogida y nadie la frenaba. En un todos contra todos de 75 minutos, 167 aldeanos contra 48 y 149.508 juntado contra 108.073. Arreglo: comando `acoger` y la IA de Palmares pausa la acogida en su tope de aldeanos; la fama (y la mit'a) que tira el tope ya no suma al puntaje. Medida: 86.378 juntado (segunda; gana Tawantinsuyu); en 1 contra 1, las mismas 20 partidas con el mismo resultado. El jugador humano no cambia. Mismo hash | [5c-palmares-largo.md](5c-palmares-largo.md) |
| W · Elección de blancos | **Integrado (33776a8).** Como AoE4, para todas las dificultades y el jugador: militar > aldeano > edificio que dispara > otros edificios > piezas transitables; quien le pegaba a un edificio o aldeano por su cuenta se da vuelta contra el militar que lo golpea; la orden directa se respeta; los caminos no son blanco automático. Golpes a caminos en IA contra IA de 933 a 0; partidas con ganador antes de los 30 min de 2 a 5 de 6. La primera victoria sigue en 4 de 5 y la micro C2 igual. Torneo 29 | [5d-eleccion-de-blancos.md](5d-eleccion-de-blancos.md) |
| X · Interfaz, ronda 6 | **Integrado (f2e5a28).** La hoja de atajos y el consejo de la pelea enseñan la elección de blancos (no más "ataca lo primero que ve"); el resumen de la pelea en un título y tres renglones; Alt muestra la función sobre las unidades; festejo de la primera victoria contra la IA con "Jugar contra Normal"; selección mixta: manda la grilla del tipo más numeroso y Tab cambia; "Hito / Edad II"; el chequeo de la cuenta de sitios, firme. Autotest 132 | [6a-interfaz-ronda-6.md](6a-interfaz-ronda-6.md) |
| Y · Experta: edades y defensa | **Integrado (93f853e), a medias.** Edad II en espejo a las 7:23 en promedio (antes, 9:25), y llegan a la III en 20 min 8 de 12 (antes, 4); la III antes de 15:00 no se cumple. 8 constructores en el hito, ejército mínimo según el rival visto, torre en cada centro nuevo y campana en los centros: aguanta el primer golpe del veterano, no el segundo. Contra la difícil, 54 % (dentro del ruido). Encontró un error de todas las dificultades: aldeanos del alimento parados minutos junto a carne encerrada entre árboles (arreglo de fondo en la simulación, en curso) | [6b-experta-edades-y-defensa.md](6b-experta-edades-y-defensa.md) |
| Z · Recurso inalcanzable | **Integrado (300558b).** Error de todas las dificultades y del jugador: el aldeano mandado a una carne encerrada entre árboles se deslizaba contra ellos sin contar como trabado. Ahora, si el camino no llega, el recurso queda anotado como inalcanzable para ese jugador por un rato, y sin avance el aldeano busca otro del mismo tipo. En Tawantinsuyu espejo (semilla 41) la normal tenía 21 de 21 aldeanos del alimento parados y no salía de la edad I; ahora, 3 en el peor momento, edad II y 9015 recolectado (antes 3300). Mismo hash; prueba nueva. Torneo 31 |  [6c-recurso-inalcanzable.md](6c-recurso-inalcanzable.md) |
| L · Equipos, ronda 3 | **Integrado (e3514ed y 5645ef0).** La bengala de ataque espera un grupo de 10 o la próxima oleada, marcha sin pelear: llegan 74 % de los enviados (antes 38 %). Pedidos cumplidos: 34 de 36 (antes 7; madera 17 de 18). Todos contra todos: 60 min por defecto. Fin agrupado por equipo. Fortines: el movimiento sigue la regla del buscador de caminos y no queda en huecos entre árboles (caminos imposibles de 1297 a 481); cambia el hash (1328656416) y el torneo 23 lo mide | [4l-equipos-ronda-3.md](4l-equipos-ronda-3.md) |
| M · Jugador nuevo, ronda 3 | **Integrado (ac450c4).** La fácil rodea los sitios y no gana por ellos (0 de 6 en 5 semillas; `tests/facil_sitios.gd`); la primera partida en Fácil sin sitios; el tutorial usa la espera del hito (5 mensajes y una tarea) y ordena los objetivos; grilla con nombre común y propio; "Empate" en color neutro; "Sitios 0/3 (no ganan, dan riqueza)"; aviso "Tenés ejército y recursos de sobra". Hash de la normal igual. Consultas C-61 a C-63 | [4j-jugador-nuevo-ronda-3.md](4j-jugador-nuevo-ronda-3.md) |

### Después de la tercera ronda: balance otra vez

- **Torneo 21:** la IA normal que ataca el hito en obra corre el balance (guaraníes 72, mapuches 68, Ayutthaya 28 %).
- **Torneo 22:** se le suma la micro C2 (C-64 por defecto): guerrero común a 1350 y línea +6 contra el choque. Toca todo el combate, así que se rebalancea con los dos juntos.
- **Torneo 22:** C2 no rompe nada (mapuches de 68 a 60, Ayutthaya de 28 a 34). Queda; los guaraníes siguen arriba (76 %).
- **Torneo 23**, con todo integrado: guaraníes 76 % (29 de 38 por puntos) y Ayutthaya 28 %. Se rebalancea un cambio por torneo: guaraníes primero (roza 850).
- **Torneo 24:** la roza a 850 casi no mueve a los guaraníes (76 → 72, dentro del ruido). Vuelve a 900.
- **Puntaje por partes** (`tools/puntaje_partes.gd`, guaraníes contra mapuches, Tawantinsuyu y Etiopía en llano):
  - Los guaraníes no ganan por economía: juntan lo mismo o menos.
  - Ganan por bajas: 1488 contra 678, 2100 contra 792 y 702 contra 294 puntos.
  - Su arquero (8 de ataque, 70 de vida, 6000 de alcance) y la emboscada al 50 % kitean mejor desde que el guerrero es más lento (C2).
- **Torneo 25:** arquero guaraní a 7 de ataque. El alcance y la emboscada quedan: son su identidad.
- **Torneo 25:** guaraníes de 72 a 66 %; era el arquero. Todas quedan entre 34 y 66 %, y el rebalance de después de la tercera ronda se cierra ahí. Ayutthaya en 34 % está dentro del ruido.

### Pedido del autor: las llamas propias no se carnean

> "Algo gracioso que pasa es que, a lo que los animales pasan a ser nuestros, las llamas por ejemplo cuando empiezo la partida, mis aldeanos no las matan porque son aliados."

- **Causa:** el clic derecho sobre una unidad propia se tomaba como "mover ahí" (`Controller._right_click`) y nunca llegaba la orden de carnear. La simulación ya carneaba el animal propio si la orden llegaba (C-32); por eso las pruebas de la simulación pasaban: mandan la orden directo.
- **Arreglo:** un animal propio (`animal: true`) recibe la orden como un recurso, y el cursor muestra "juntar alimento".
- **Prueba:** el autotest suma un clic derecho con el mouse sobre una llama propia. Verifica el cursor y que el aldeano la carnee y junte alimento.

### Pedido del autor: del arbusto se iban a carnear

> "Si los mando a los arbustos y uno se termina, los trabajadores van a carnear animales en lugar de pasar al arbusto siguiente."

- **Causa:** el "carnear en cadena" del paso 1 corría para cualquier aldeano de alimento cuya fuente se agotara, no solo para el que venía de la carne.
- **Arreglo:**
  - Se carnea en cadena solo si se venía de carne o de un animal.
  - Al agotarse una fuente, primero se busca otra del mismo tipo (el arbusto, el árbol o la veta de al lado; `find_resource(..., only_type)`) y después cualquiera de ese recurso, como AoE4.
- **Prueba** (`tests/jugabilidad.gd`, "del arbusto al arbusto": incas con llamas cerca y el arbusto agotado):
  - antes del arreglo: 0 de 3 seguían con arbustos y quedaban 2 de 5 llamas;
  - ahora: 3 de 3 y 5 de 5.
  - Carnear en cadena desde la carne sigue andando.
- **Otras pruebas:** determinismo, mismo hash; civs sin errores; rendimiento 9,15 ms de promedio y 96 de peor caso, con la máquina cargada. Antes de C2 el peor caso era de unos 59: con el guerrero más lento hay más unidades vivas al final (129 contra 121). Queda anotado como riesgo.

## Cuarta ronda de jugadores (desde 2026-11-16)

> El autor: "Lo antes posible hay que correr otra prueba. Yo diría solo el jugador experto y el principiante, y que se concentren en calidad de vida y usabilidad, además de lo que ya miran."

- Juegan el veterano de AoE4 y el jugador nuevo, con su memoria de las rondas 1–3, sobre main con todo lo de la ronda 3 integrado.
- Cada informe trae una sección "Calidad de vida y usabilidad" ordenada por gravedad, en [`proceso/22-testers/ronda-4/`](../22-testers/ronda-4/).

### Pedido del autor: una llama por vez

> "No deberían matar todas las llamas de una: primero se mata una, se le termina de sacar la carne y luego se sigue con la otra, y todo así, a menos que se indique directamente lo contrario."

- **Antes:**
  - en la cadena, cada aldeano que terminaba una carne carneaba otro animal, aunque un compañero ya hubiera abierto uno;
  - la IA mandaba a cada aldeano a un animal distinto.
- **Arreglo:**
  - La cadena primero busca carne abierta cerca y carnea un animal nuevo recién cuando no queda.
  - La IA hace lo mismo: carne abierta antes que un animal.
  - Una orden directa sobre una llama la sigue carneando, y con varios aldeanos en una sola orden se carnea un solo animal y todos juntan su carne.
- **Prueba:** "una llama por vez" en `tests/jugabilidad.gd`: nunca más de una carne abierta. Los 4 aldeanos terminan las 5 llamas en unos 330 s, una tras otra, y siguen con los arbustos.
- **Determinismo:** cambia el hash (2203695307), porque la IA también carnea de a una. Se mide con torneo junto con la IA que disputa sitios (5b).
- **[Síntesis de la cuarta ronda](../22-testers/ronda-4/00-sintesis.md):**
  - Lo más grave: el botón de Aldeano que no se ve en el centro (todos los pueblos), la producción en varios edificios a la vez y las teclas sin configurar.
  - En curso: 4n (jugador nuevo) y 4o (veterano).
- **Torneo 26:** con la IA que disputa sitios terminan menos partidas por hitos (57 contra 77) y más por puntos. Los guaraníes suben a 80 % (27 de 40 por puntos, que salen de las bajas).
- **Torneo 27:** emboscada guaraní a 35 % (antes 50; la de Palmares, 30). Sigue siendo la mayor: es su identidad.

## Quinta ronda de jugadores (desde 2026-11-16)

Con lo de la cuarta ronda integrado (Q, R y S), juegan otra vez el veterano y el jugador nuevo:
- verifican cada arreglo de su ronda 4;
- juzgan la escala nueva contra AoE4 (¿alcanza el paso 1 o hacen falta la velocidad, C-65, y las huellas, C-66?);
- siguen con calidad de vida y usabilidad.

Informes en [`proceso/22-testers/ronda-5/`](../22-testers/ronda-5/).
- **Torneo 27:** la emboscada a 35 % no los mueve (78 %). Vuelve a 50.
- **Torneo 28:** alcance del arquero guaraní a 5500 (antes 6000; el hondero base, 5500). Con el guerrero más lento (C2), ese alcance de más les deja tirar sin que los alcancen.
- **[Síntesis de la quinta ronda](../22-testers/ronda-5/00-sintesis.md):**
  - El veterano tiene 9 de 9 arreglos bien y el jugador nuevo, 9 de 10.
  - La escala nueva es "el cambio que más acercó la sensación a AoE4", pero faltan la velocidad (C-65) y el centro de 5×5 (C-66).
  - El jugador nuevo todavía no le gana a la fácil (en curso: 4q).
- **Torneo 28:** guaraníes de 78 a 68 %; era el alcance. Todas quedan entre 32 y 68 %, con la IA que disputa sitios, la llama por vez, C2 y el movimiento nuevo. Se cierra ahí, dentro del ruido (±7).
- **Chequeo intermitente del autotest:** "cursor sobre un animal propio" fallaba de a ratos con "mover". El juego estaba bien (cursor y clic usan el mismo `pick`); era el animal que pastaba y se corría entre que la prueba ponía el mouse y miraba el cursor. Ahora la prueba toma la posición de la figura justo antes: 3 de 3 OK.

## Sexta ronda de jugadores (desde 2026-11-16)

Con T a W integrados, juegan otra vez el veterano y el jugador nuevo.
- **Veterano:** verifica sus arreglos de la ronda 5 y juzga las peleas con la elección de blancos nueva y la micro C2, y la experta.
- **Jugador nuevo:** dice si ahora le gana a la fácil y si el resumen de la pelea le enseña algo útil.
- **Los dos:** siguen con calidad de vida y usabilidad.

Informes en [`proceso/22-testers/ronda-6/`](../22-testers/ronda-6/).
- **[Síntesis de la sexta ronda](../22-testers/ronda-6/00-sintesis.md):**
  - El jugador nuevo le gana a la fácil por primera vez (3 de 4).
  - La elección de blancos es "lo mejor de la ronda" (veterano).
  - Siguen:
    - el consejo y la hoja que dicen "A y clic ataca lo primero que ve" (ya no es cierto);
    - la experta lenta de edad;
    - Alt sobre las unidades;
    - el festejo de la primera victoria.
- **Torneo 29:** con la elección de blancos, Tawantinsuyu baja de 68 a 42 % (perdió el escudo de los caminos, como se esperaba) y los guaraníes vuelven a 76 % (24 de 38 por puntos).
  - Los guaraníes quedaron arriba en casi todos los torneos desde el paso 1, a pesar de cinco palancas: riqueza, roza, emboscada, ataque y alcance del arquero. Cada una los movió un poco, y el cambio siguiente los volvía a subir.
  - Queda el sigilo: en el monte se los ve recién a 3 casillas.
- **Torneo 30:** sigilo guaraní detectado a 4,5 casillas (antes 3; Palmares sigue en 3).
- **Torneo 30:** el sigilo tampoco los mueve (76 %); vuelve a 3 casillas.
  - Seis palancas (riqueza, roza, emboscada, ataque, alcance y sigilo) sin efecto duradero: la causa es otra.
  - Se abre un estudio de diagnóstico (5e), como el de Palmares, que encontró la acogida, en lugar de seguir con nerfs a ciegas.
  - El paso 1 del juego tardío (los niveles en lugar del bono por edad) también puede moverlo.
- **Torneo 31:** con el arreglo del recurso inalcanzable, Tawantinsuyu sube de 42 a 48 % y Palmares de 46 a 52 %. Los guaraníes siguen arriba (72 %); se espera el diagnóstico (5e).
