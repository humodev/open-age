# 4l · Lo que pide el jugador de equipos (tercera ronda)

## Pedido
Del [informe del jugador de equipos en la tercera ronda](../22-testers/ronda-3/04-equipos-y-ffa.md), §4 y §5:

1. **Bengala de ataque.** Llega 1 de 4, con 3 a 7 unidades que se traban o mueren a mitad de camino. Que el aliado la sume a su próxima oleada o junte un grupo antes de salir, y que llegue.
2. **Pedidos de recursos.** Se cumplen 3 de 18, nunca la madera, mientras la IA regala de 3 a 30 tributos que nadie pidió. Que el pedido pese más que el tributo espontáneo.
3. **Todos contra todos sin final.** Un tiempo límite por defecto en el menú, solo para el todos contra todos, dicho en la línea de cómo se gana. El 1 contra 1 no cambia.
4. **Pantalla de fin por equipo.** Agrupada por equipo y con su nombre ("Equipo 1: Vos y Verde") en lugar de "ganó Rojo". Con 6 a 8 jugadores, que la línea de tiempo no tape los botones.
5. **Fortines 2v2.** 1504 caminos imposibles, sobre todo de unidades de Tawantinsuyu en el centro del mapa y junto al cerco del aliado.
6. **Interruptores del menú.** "Sitios sagrados" apagado se veía como un punto suelto y "Hitos" como un interruptor.

Otro agente trabaja la IA experta (oleadas, expansión, almacenes, hitos en obra) en `src/sim/sim_ai.gd`, y otro la pantalla de fin para el empate y la grilla. Mis bloques en esas zonas van marcados con `# --- equipos ronda 3 ---`, y en la pantalla de fin no toqué el color del título ("Victoria", "Empate", "Derrota").

## Herramienta de medida
`tools/equipos_ronda3.gd` (nueva) reproduce las pruebas del informe:
- **`--caso=bengalas`:** 2v2 de IA en llano (Etiopía, Mapuches, Palmares y Ayutthaya), con aliados juntos y mezclados, semillas 11, 23 y 41: 12 bengalas y 36 pedidos.
  - El jugador 0 tira una bengala de ataque sobre la capital rival más cercana a los 12 y a los 18 minutos.
  - Le pide madera y alimento al aliado (jugador 2) a los 8, 14 y 20 minutos.
  - Anota a los enviados (los que el aliado marca para la bengala) y cuántos llegan a 25 casillas de ella (la base rival).
  - También cuenta los aliados que hay a 12 y a 25 casillas a los 45, 90, 150 y 240 s, que es la medida del informe.
  - Anota qué pedidos se cumplieron y cuántos tributos dio la IA sin que se los pidieran.
- **`--caso=fortines`:** el 2v2 de fortines del informe (semilla 31, estilos pacífica, acosadora, agresiva y normal) durante 45 minutos. Muestra caminos imposibles y trabadas por jugador, tipo de unidad y destino, y guarda la telemetría para `tools/telemetria.gd`.
  - `--zona=x0,y0,x1,y1` dibuja esas casillas cada 10 minutos.
- **`--caso=bolsillos`:** cada vez que una unidad entra a un bolsillo, anota de dónde venía, su orden y su grupo, y si cortó una esquina. Un bolsillo es un grupo de casillas libres encerrado, de menos de 300, del que el buscador de caminos no la puede sacar.
- **`--caso=traza`:** sigue cada 15 s a la tropa que el aliado manda a la bengala: orden, distancia, a qué le pega y estado del grupo.

Para medir el antes, corrí la misma herramienta sobre una copia del commit anterior (`06d1442`).

## 1. Bengala de ataque

### Qué pasaba (traza, semilla 11, aliados juntos)
- **El piquete era chico:** el 50 % del ejército libre, de 3 a 11 unidades.
- **Se plantaban a mitad de camino.** Con ataque en movimiento, un hondero le pegaba a un **ingenio neutral** (es hostil y tiene mucha vida). El grupo entero quedaba en estado de combate, quieto a 105 casillas durante un minuto y a 31 casillas durante dos. Es la "distancia fija de ~96 casillas" del informe.
- **A los 60 s la IA los liberaba** (`dura_ticks × 4`): la reunión, las oleadas y la caza se los llevaban de vuelta, y morían en el camino.

### Qué se hizo (`SimAI`, datos en `reglas.equipos.bengala`)
- **Grupo mínimo (`ia_grupo_min` = 10).**
  - Si el ejército libre llega a 10, va entero, no la mitad.
  - Si no llega, el aliado dice **"Voy a tu bengala con mi próxima oleada"** (frase `voy_oleada`) y sale apenas junta el grupo, hasta `ia_espera_ticks` (5 minutos), salvo que le estén atacando la base.
  - Al vencer sin tropa, dice "Ahora no tengo tropa para mandar".
- **Marcha y después ataque.** El grupo marcha en formación, sin pelear, hasta `ia_escala` (14 casillas) antes de la bengala. Cuando la mitad está a `ia_escala_llegada` de ese punto, todos atacan en movimiento hasta la bengala (`_flare_march_step`).
  - Si alguno quedó pegándole a algo neutral, lo deja.
- **Protegidos durante `ia_queda_ticks` (4 minutos).** Las otras órdenes de la IA no los desvían: reunión, incursiones, oleadas, caza, control del mapa, ingenios, sitios y defensa.
  - Para eso, tres selecciones de `_military` que tomaban ociosos sin mirar la bengala ahora la miran: control del mapa, ingenios y sitios.
  - `_attack` deja afuera a los que van a la bengala.
- La bengala de defensa no cambió: ya llegaba 8 de 8.

### Probé y descarté
| Variante | Enviados que llegan a la base rival |
|---|---|
| Antes | 28 de 73 (38 %) |
| Grupo de 12, marcha sin pelear | 69 de 105 (66 %) |
| Grupo de 10, marcha con ataque en movimiento (ignorando lo neutral) | 39 de 86 (45 %): las peleas del camino desarman el grupo |
| Grupo de 10, marcha sin pelear | 105 de 121 (87 %) |
| **Lo mismo, y los enviados protegidos también del control del mapa, los ingenios y los sitios (queda)** | **93 de 125 (74 %)** |

### Antes y después ([antes](pruebas/4l-bengalas-antes.txt), [después](pruebas/4l-bengalas-despues.txt))
| | Antes | Después |
|---|---|---|
| Bengalas con al menos un enviado en la base rival | 5 de 12 | **9 de 12** |
| Enviados que llegan | 28 de 73 (38 %) | **93 de 125 (74 %)** |
| Tamaño de lo que manda | 3 a 11 | 10 a 27 |

- **Aliados juntos**, que es el caso del informe: antes no llegó ninguno de los 6 envíos; después llegan.
- Las variantes se movieron entre 87 % y 74 % con el mismo código de bengala: un cambio chico en otra parte de la IA cambia la partida entera. El salto contra el antes (38 %) se repite en todas.
- Las bengalas que siguen sin respuesta son de un aliado que se está quedando sin ejército. Dice que va con la próxima oleada y no la junta en 5 minutos, igual que no junta la suya.

## 2. Pedidos de recursos

### Qué pasaba
- La IA contestaba una sola vez, en el momento: si no tenía `lote + sobra` (200 + 300), decía "No me sobra" y el pedido se perdía.
- **La madera nunca alcanzaba,** porque la IA la gasta apenas entra.

### Qué se hizo (`SimAI._requests`, `_reserve`; datos en `reglas.equipos.pedido`)
- **Se atiende primero.** `_requests` corre al principio de cada pensada, antes de gastar en economía, edificios, producción e investigación.
- **Margen más chico:** `sobra` pasó de 300 a 100 (el tributo espontáneo pide 600).
- **Espera** hasta `espera_ticks` (2 minutos) y lo intenta en cada pensada. Mientras espera:
  - dice **"Junto madera y te lo mando"** (frase `junto`);
  - **aparta lo pedido** (`_reserve`): al decidir en qué gastar, la IA ve `lote + sobra` menos del recurso pedido. Se aparta y se devuelve dentro de la misma pensada, así que el banco real no cambia y el estado sigue siendo determinista;
  - **no regala nada.** `_tribute` no da tributos espontáneos con un pedido pendiente.
- **Al vencer**, si le sobran 300 de otro recurso (`sobra_otro`), lo manda: **"No me sobra madera; te mando 200 de piedra: llegan 160"** (frase `mando_otro`). Si no le sobra nada, dice "No me sobra madera".
- Las tres frases nuevas están en `data/interfaz.json → frases_ia`. El HUD las muestra solo al aliado al que van, como "te mando".

### Antes y después (las mismas 6 partidas)
| | Antes | Después |
|---|---|---|
| Pedidos cumplidos con lo pedido | 7 de 36 (19 %) | **34 de 36 (94 %)** |
| De madera | 0 de 18 | **17 de 18** |
| Cumplidos con otro recurso | — | 0 (en corridas anteriores, de 1 a 4) |
| Regalos del aliado al jugador 0 sin pedido | 18 | 26 |

Los regalos no bajan: con más recursos en la cuenta del aliado (lo que junta mientras aparta), regala más después. Pero el pedido ya no se pierde.

## 3. Todos contra todos con tiempo límite por defecto
- **Datos:** `reglas.opciones_partida.todos_contra_todos_tiempo_min` = 60.
- **Menú** (`menu.gd`, `_ffa_default`). Al pasar a un todos contra todos de 3 o más con "Sin límite", el menú elige 60 minutos y la línea de cómo se gana dice: "A los 60 minutos gana quien tenga más puntos (tiempo límite por defecto en todos contra todos)."
  - Si el jugador elige otro tiempo, se respeta, incluso "Sin límite". En ese caso la línea avisa: "Sin tiempo límite, un todos contra todos puede no terminar."
  - Al volver a una partida con equipos o al 1 contra 1, vuelve lo de antes.
  - Lo que puso el menú solo no se recuerda en `Opciones.partida`.
  - `--tiempo=N` en la línea de comandos manda sobre el valor por defecto.
- **El 1 contra 1 no cambia:** no tiene lugares (`_slot_rows` vacío) y nunca entra a esa rama.
- **Por qué 60:** es el tope de los tiempos que ofrece el menú. En la ronda 3, el todos contra todos de 6 con 45 minutos terminó sin que cayera nadie, y los de 4 y 6 sin límite seguían abiertos a los 60 y a los 75 minutos.

[Captura del menú, todos contra todos (6)](capturas/4l-menu-ffa6.png).

## 4. Pantalla de fin por equipo (`panel_fin.gd`)
- **Agrupada por equipo, el tuyo primero:**
  - las columnas de la comparación;
  - las filas de riqueza por origen;
  - las filas de la línea de tiempo.
- **Encima de las columnas de cada equipo** va su nombre con el puntaje del equipo: "Equipo 1: Vos, Violeta y Rosa · 5051". Si no entra, queda "Equipo 1 · 5051".
- **Quién ganó, por equipo.**
  - Subtítulo: "ganó el Equipo 2: Rojo, Ciruela y Oliva".
  - Motivo: "Se cumplió el tiempo límite (30 minutos) y ganó el Equipo 2: Rojo, Ciruela y Oliva por puntos: 5297 contra tus 5051."
  - También en la conquista y en los sitios.
  - En 1 contra 1 y en todos contra todos sigue el jugador ("Rojo · Mapuches").
- **Con 6 a 8 jugadores nada tapa los botones.** La riqueza y la línea de tiempo terminan sobre los botones (`BUTTONS_H`), y el alto de cada fila es el que entra (entre 22 y 50 px).
  - Si la fila queda chica, la línea de tiempo muestra solo la edad junto al punto, sin el nombre del hito.
  - Con más de 4 jugadores, las columnas llevan solo el color.
- **No toqué el color del título.** La línea de "Victoria / Empate / Derrota" queda como estaba, para no pisar al agente del empate.

[Fin de un 3v3](capturas/4l-fin-3v3.png) (6 jugadores, 15 minutos, `--panel=fin-tiempo`) y [fin de un 4v4](capturas/4l-fin-4v4.png) (8 jugadores, 10 minutos).

## 5. Fortines 2v2: caminos imposibles
### Qué pasaba
- **Dónde.** El mapa de la zona (`--zona=84,72,124,104`) mostró las unidades de Tawantinsuyu **adentro de un monte**, al este del centro: en huecos de 1 a 3 casillas entre árboles. Desde ahí pedían camino a su base ((56,40)) o al este, y el buscador no las sacaba.
- **Cómo entraban.** `--caso=bolsillos` registró 155 entradas a bolsillos en 40 minutos ([resultado](pruebas/4l-bolsillos-antes.txt)), **todas cortando una esquina:** pasaban en diagonal entre dos casillas sólidas, como dos árboles, o un muro y una casa.
  - `_try_move` solo miraba la casilla de llegada.
  - El buscador (`DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES`) no deja pasar en diagonal si alguna de las dos casillas de al lado es sólida, así que no podía sacarlas.
  - Casi siempre eran miembros de un grupo en marcha o en combate, que caminan derecho a su lugar en la formación.
- **No eran las puertas del aliado ni el punto de reunión:** las puertas aliadas dejan pasar bien (`tests/equipos.gd`), y el punto de reunión ya se busca alcanzable desde la etapa 20.

### Qué se hizo (`Sim._try_move`)
- **Sin cortar esquinas.** Una unidad no pasa en diagonal de una casilla a otra si alguna de las dos casillas de al lado es sólida para ella: es la misma regla que el buscador. Si no puede, se desliza por un eje, como antes.
- **La salida no cambia:** una unidad que ya está sobre una casilla sólida (un edificio recién puesto) sigue pudiendo salir.

### Antes y después (2v2 de fortines, semilla 31, 45 minutos; [antes](pruebas/4l-fortines-antes.txt), [después](pruebas/4l-fortines-despues.txt))
| | Antes | Después |
|---|---|---|
| Caminos imposibles | 1297 | **481** |
| Trabadas | 483 | **55** |
| Caminos imposibles de Tawantinsuyu (jugador 0) | 358 | **2** |
| Los cuatro en pie a los 45:00 | sí | sí |

- El informe midió 1504 con su propio script; con el mío, sobre el mismo commit, dan 1297.
- **Lo que queda** (481) es casi todo de los guaraníes (jugador 2), que atacan adentro del cerco del mapuche ((120,40)). El cerco rival está cerrado y el camino no llega: la tropa se para contra la empalizada.
  - Es elección de blanco de la oleada, la zona del otro agente. Lo dejo anotado para la IA experta: con fortines, la oleada tendría que apuntar a la puerta o a la empalizada.
- **Mapas de calor** de `tools/telemetria.gd`: [antes](capturas/4l-telemetria-fortines-antes.png) y [después](capturas/4l-telemetria-fortines-despues.png).

**Cambia el hash del determinismo.** Las unidades se mueven distinto cerca de las esquinas, también en 1 contra 1. Con solo los cambios de IA e interfaz el hash queda igual (1249639671), y con el de `_try_move` pasa a 1015433775. A los 5 minutos de la prueba, los recursos y las estadísticas de los dos jugadores son idénticos a los de antes. El balance se midió con el torneo (abajo).

## 6. Interruptores del menú
- **Qué pasaba.** El menú usa el `CheckButton` de Godot sin tema. Apagado, su píldora es gris oscuro sobre el panel oscuro y solo se ve la perilla: el "punto suelto" del informe ([antes](capturas/4l-menu-3v3-antes.png)). Prendido, la píldora es gris claro.
- **Qué se hizo.** `Opciones.interruptor()` dibuja el ícono: una píldora con la perilla, de color de acento si está prendido y gris claro si está apagado (también las versiones apagadas del control).
  - El menú lo aplica con `Opciones.interruptor_en`.
  - El tema de Opciones (`tema()`) usa los mismos íconos.
  - [Después](capturas/4l-menu-3v3.png).

## Pruebas
- **Órdenes** (`tests/ordenes.gd`): [OK](pruebas/4l-ordenes.txt).
  - La prueba de bengala ahora espera que vaya el grupo entero (14 de 14 llegan).
  - Dos casos nuevos: "bengala sin tropa", que avisa con "Voy con mi próxima oleada" y, al juntar el grupo, llegan 14 a 20 casillas; y "pedido sin madera", que avisa "Junto…" y la da después.
- **Opciones de partida** (`tests/opciones_partida.gd`): [OK](pruebas/4l-opciones-partida.txt).
- **Equipos** (`tests/equipos.gd -- --minutes=30`): [OK](pruebas/4l-equipos.txt).
  - Sin fuego amigo en las 7 partidas.
  - Las puertas del aliado dejan pasar y las del rival no.
  - En fortines de 4 y de 6 nadie queda encerrado.
  - Dos de los 2v2 terminan por conquista (26:53). Los 3v3 y el todos contra todos siguen abiertos a los 30 minutos, como antes, porque la prueba no usa tiempo límite.
- **Determinismo:** [OK](pruebas/4l-determinismo.txt), con hash nuevo (ver §5).
- **Rendimiento** ([bench](pruebas/4l-bench.txt)): 9,15 ms de promedio, contra 9,28 ms del commit anterior en el mismo momento.
- **Civs** ([civ_smoke](pruebas/4l-civ_smoke.txt)) y **campañas** ([campaign_smoke](pruebas/4l-campaign_smoke.txt)): sin errores.
- **Torneo** (`tests/torneo.gd -- --minutes=30 --seeds=2`), por el cambio de movimiento: [antes](pruebas/4l-torneo-antes.txt) y [después](pruebas/4l-torneo-despues.txt), corridos a la vez en la misma máquina.

  | Victorias (también por puntos a los 30) | Antes | Después |
  |---|---|---|
  | Ayutthaya | 3 / 10 | 3 / 10 |
  | Etiopía | **9 / 10** | **4 / 10** |
  | Guaraníes | 5 / 10 | 7 / 10 |
  | Mapuches | 5 / 10 | 7 / 10 |
  | Palmares | 4 / 10 | 2 / 10 |
  | Tawantinsuyu | 4 / 10 | 7 / 10 |
  | Terminadas antes de los 30 minutos | 16 de 30 | 16 de 30 |
  | Duración media | 26,2 min | 27,0 min |

  - Con 10 partidas por civ, el ruido es grande: cambiar el movimiento cambia todas las partidas desde el primer roce con una esquina. Etiopía de 9 a 4 es lo único que llama la atención.
  - **No lo atribuyo** sin otra corrida: pide un torneo con más semillas.
  - El cambio de `_try_move` va en un **commit aparte**, para poder sacarlo solo si el autor prefiere no mover el balance del 1 contra 1 ahora.
- **Autotest** (`--autotest --civ=guaranies --terreno=llano`): [OK](pruebas/4l-autotest.txt). [Captura](capturas/4l-autotest.png).
- **Capturas:**
  - [menú, todos contra todos (6)](capturas/4l-menu-ffa6.png);
  - menú 3v3 con sitios apagados: [antes](capturas/4l-menu-3v3-antes.png) y [después](capturas/4l-menu-3v3.png);
  - [fin, 3v3](capturas/4l-fin-3v3.png);
  - [fin, 4v4](capturas/4l-fin-4v4.png).

## Tropiezos
- **La medida del informe engaña.** Contar aliados a 12 casillas de la bengala a los 45, 90, 150 y 240 s suma las oleadas propias del aliado que van al mismo lugar, y deja afuera a los que pelean a 15 casillas, en la base. Por eso la herramienta sigue a los enviados uno por uno.
- **La primera medida del después se veía peor que la traza.** Con los pedidos, la partida cambia: el grupo llegaba a 20 casillas justo entre dos muestras. Pasé a medir el máximo cada 5 s.
- **Ataque en movimiento contra neutral.** Ignorar el ingenio arregló la parada, pero las peleas del camino deshacían el grupo. Quedó la marcha sin pelear hasta la escala.
- **Los enviados volvían.** Ya en la base rival, el control del mapa, los ingenios y los sitios se llevaban a los ociosos aunque fueran de la bengala. Esas tres selecciones no miraban `_at_flare`.
- **Apartar recursos sin tocar el banco.** Probé darle prioridad al pedido sin más, y la madera igual no juntaba 300: la IA la gastaba en la misma pensada. Apartarla mientras decide (y devolverla al final) no cambia el estado y alcanza.

## Para el agente de la IA experta
- Con fortines, la oleada apunta a edificios adentro del cerco rival y el camino no llega: 226 caminos imposibles de los guaraníes hacia (120,40) en el 2v2 de la semilla 31.
- Las oleadas normales también usan ataque en movimiento y pueden quedar plantadas por un hondero que le pega a un ingenio neutral (`SimGroups`: el grupo queda en combate mientras alguien pelea). En la bengala lo resolví en la IA (`_flare_march_step`). Para las oleadas convendría lo mismo, o que el grupo no se plante por una pelea con lo neutral.

## Commits
1. `Equipos, ronda 3 (4l): bengala con grupo y marcha, pedidos que pesan, tiempo límite en todos contra todos, fin por equipo e interruptores`: la IA, los datos, la interfaz, las pruebas y este documento. No cambia el hash del determinismo.
2. `Movimiento sin cortar esquinas (4l): se acaban los bolsillos de fortines`: solo `Sim._try_move`. Cambia el hash y el 1 contra 1.
