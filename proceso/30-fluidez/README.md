# 30 · Fluidez: plan conjunto de los dos expertos

> Pedido del autor: "Corré un segundo análisis de experto con un jugador de otro estilo, compará lo que proponen los dos y juntalo. Tratemos de incluir y mejorar todo lo posible, pero con más análisis para hacerlo todo de una vez."

## Fuentes

| Experto | Estilo | Informe |
|---|---|---|
| Veterano competitivo de AoE4 | Micro, ritmo, respuesta inmediata | [03-veterano-fluidez.md](../22-testers/ronda-7/03-veterano-fluidez.md) |
| Constructor y economía (AoE2 DE, AoE4, Anno) | Partidas largas en equipo, base ordenada, economía que se maneja sola | [04-constructor-fluidez.md](../22-testers/ronda-7/04-constructor-fluidez.md) |

Los dos coinciden en que la base ya está a la altura de AoE4: grupos, cola con Mayús, formaciones, cola global, cursores, Alt y marcadores. Lo que falta es lo que hace que el juego responda, avise y se maneje solo.

## Dónde coinciden (prioridad máxima)

| Cambio | Veterano | Constructor |
|---|---|---|
| Mayús + colocar: los cimientos se levantan en el orden puesto | 5 | 2 |
| Producción parada a la vista en la cola global | 3 | 11 |
| Avisos de ataque por zona y por tipo (hoy, uno cada 15 s en general) | 4 | 9 |
| Cola de producción de 5 a 10 | 7 | 12 |
| Granjas que se pegan al depósito | 20 | 6 |
| Muro con información: tramos y costo (V) y huecos (C) | 8 | 7 |
| Reunión o rebusca cuando se agota el recurso | 9 | 3 |
| Minimapa con filtros y tamaño | 25 | 16 |

## Dónde difieren

- **El constructor pone arriba la producción que se repite sola y guardar la partida.** El veterano no los menciona, porque juega partidas cortas. Entran los dos: son baratos y el constructor juega partidas de una hora.
- **El veterano pone arriba el sonido y el destello**, y para el constructor pesan menos. Entran igual: son chicos y mejoran la respuesta para todos.
- **Reparar:** al veterano le molesta que sea gratis, y el constructor pide reparar en masa. Se hacen las dos cosas: se agrega reparar en cadena o por zona, y el costo va como decisión de balance (C-100).

## Plan: todo, en siete frentes por archivos

La lista combinada tiene unos 40 cambios. Para hacerlos de una vez sin que los agentes se pisen, cada frente es dueño de sus archivos. Se trabaja en dos tandas de frentes paralelos, porque la memoria aguanta como mucho cuatro procesos de Godot.

| Frente | Contenido (V = veterano, C = constructor) | Archivos dueños | ¿Simulación? | Tanda |
|---|---|---|---|---|
| **1 · Producción que se maneja sola** | **Repetición automática con tope de aldeanos (C1)**, cola de 10 (V7, C12), sacar de la cola con clic derecho y con Mayús (V6), parados en la cola global con pulso (V3, C11), aviso anticipado de población (C4), ingreso por minuto en la barra (V16) | `ui/cola_global.gd`, `hud.gd` (barra), producción en `controller.gd`, `reglas.cola_max`, `sim.gd` (repetición) | Sí (repetición) | 1 |
| **2 · Constructor** | Mayús en orden como cola de obras (V5, C2), muro con tramos, costo y huecos, encadenado y con la puerta en el trazo (V8, C7), granjas que se pegan con «x de 8 libres» (V20), colocación que informa recursos y distancia (C6), reparar en cadena o por zona (C10), reconstruir la huella fantasma (C23), reunión sobre un recurso agotado (V9, C3, parte de la simulación) | `ui/mundo_cola.gd`, `ui/mundo_colocacion.gd`, colocación en `controller.gd`, `_cmd_build_line` y rebusca en `sim.gd` | Sí (rebusca, línea) | 1 |
| **3 · Respuesta inmediata** | Sonido al elegir por categoría y de error (V1), sonido y polvo del cimiento (V2), destello del blanco (V10), pulso al saltar con la cámara (V18), estela de proyectiles (V19), voces por función y pueblo (V23, sin nada sagrado) | `audio.gd`, efectos de `world_view.gd` | No | 1 |
| **4 · Avisos y equipo** | Alertas por zona y tipo con sonidos distintos (V4, C9), recurso agotado o por agotarse (C3), granjas vacías marcadas y botón «Llenar granjas» (C5), tributo con cantidad y periódico (C13), bengalas con intención (C18), ver al aliado (C22), minimapa con filtros y tamaño (V25, C16) | `ui/avisos.gd`, `ui/mundo_minimapa.gd`, tributo y bengalas | Puede (límite de avisos) | 2 |
| **5 · Selección, órdenes y lectura** | Ctrl + clic (V13), Mayús + mantener posición (V14), color por función en los retratos (V11), números de daño apagables (V15), ficha compacta (V17), corregir la hoja de atajos (V12), atacar el suelo (V22), patrulla de varios puntos y escolta (V24) | Selección en `controller.gd`, `ui/ficha.gd`, `ui/hoja_atajos.gd`, órdenes en `sim.gd` | Sí (suelo, patrulla) | 2 |
| **6 · Partidas largas** | Guardar, cargar y autoguardado con semilla y comandos (C8), panel «Mi base» (C17), medir y mejorar el 4v4 tardío a ×1 (C21) | `main.gd` y menú (guardar), panel nuevo, caché de caminos | Sí (caché, sin cambiar el resultado) | 2 |
| **7 · Base linda** | Banderas más chicas y opcionales (C14), modo foto (C25), tierra pisada y pilas de recurso (C24). Planos sin pagar (C20) y muralla de piedra (C19) van a consulta | `civ_meshes.gd`, arte del suelo | No | 2 |

Los cuatro cambios que tocan la misma función van en un solo frente. Por eso la rebusca está en el 2 y la repetición en el 1.

## Pruebas de cada frente

- `test_determinism` (avisar si el hash cambia y por qué) y `bench`.
- El autotest con controles nuevos que prueben cada cambio, por ejemplo: tres casas con Mayús en orden, cola de 10, la repetición que no pasa el tope, el aviso por zona y el sonido que se dispara.
- `casillas` y `grilla`.
- Una captura revisada.

Las simulaciones de los frentes 1, 2 y 5 se confirman en un solo torneo al final.

## Consultas

- **C-100:** ¿reparar cuesta, como en AoE4 (una fracción del costo), o sigue gratis? Por defecto, cuesta el 50 % del costo, proporcional a lo reparado.
- **C-101:** ¿muralla de piedra con torres encima y una empalizada que se refuerza (C19), y planos sin pagar (C20)? Son grandes y cambian el juego. Por defecto, la muralla de piedra sí, en la edad II, con la propuesta de `04-decisiones.md`; los planos, después.

## Avance

| Frente | Estado |
|---|---|
| 3 · Respuesta inmediata | **Integrado (ff8c166)** · [03-respuesta.md](03-respuesta.md):<br>• sonido al elegir, por categoría y por pueblo;<br>• error con clic sin efecto;<br>• golpe y polvo al apoyar un cimiento;<br>• destello del blanco y pulso al saltar;<br>• estela de flechas y piedras;<br>• orden por función.<br>40 sonidos sintetizados (227 KB), sin instrumentos sagrados. Todo se apaga en `data/respuesta.json`. Mismo hash |
| 1 · Producción | **Integrado (c87c493)**, [01-produccion.md](01-produccion.md):<br>• **Repetición automática:** Ctrl + clic; es un comando de la simulación, con tope de aldeanos (80, ajustable con − y +).<br>• **Cola:** de 10, con «+n».<br>• **Sacar de la cola:** clic derecho saca una; con Mayús, cinco.<br>• **Edificios parados:** se ven grises y con pulso en la cola global.<br>• **Población:** aviso «sin lugar en ~N s».<br>• **Ingreso por minuto:** se ve en la barra.<br>Mismo hash. Autotest: 161 OK |
| 4 · Avisos y equipo | **Integrado (fd3057e)**, [04-avisos-y-equipo.md](04-avisos-y-equipo.md):<br>• **Alertas de ataque:** por zona (12 casillas) y por tipo, con su sonido, su lugar y marca en el minimapa; otra zona avisa enseguida.<br>• **Recursos:** aviso cuando se agota o está por agotarse.<br>• **Granjas vacías:** marcadas, con el botón «Llenar granjas».<br>• **Tributo:** ×5 y ×10, y periódico.<br>• **Bengalas con intención:** rueda con Alt + arrastrar.<br>• **Aliados:** fila de cada uno en el panel de equipo.<br>• **Minimapa:** filtros y tamaño.<br>Mismo hash; equipos OK.<br>**Autotest de los seis pueblos en OK:** [05-autotest-seis-pueblos.md](05-autotest-seis-pueblos.md) |
| 2 · Constructor | **Integrado (8ee2edf)**, [02-constructor.md](02-constructor.md):<br>• Mayús + colocar levanta en el orden puesto, sin tope de distancia;<br>• muro con «n tramos · costo · alcanzan k», huecos marcados y puerta con G;<br>• granjas que se pegan, con «x de 8 libres»;<br>• colocación que informa recursos y distancia;<br>• reparar en cadena y por zona (D);<br>• huella fantasma de 3 minutos para reconstruir;<br>• rebusca lejana cerca de otro depósito propio.<br>**El hash cambia a 2903543624** por la rebusca (con `rebusca_lejos.max = 0` vuelve al anterior). Autotest OK |

**La primera victoria del principiante bajó a 1 de 3** con el frente 2. Medido con `tools/primera_victoria.gd`, semillas 7, 21 y 3:

| Rebusca lejana | Primera victoria |
|---|---|
| Apagada (`max` 0) | 3 de 3 |
| A 40 casillas | 1 de 3 |
| A 20 casillas | 2 de 3 |

La rebusca lejana ayuda más a la economía de la fácil que al principiante. Queda en **20 casillas**, que mantiene la meta de 2 de 3 o más.

**Autotest en los seis pueblos: OK (5fff26d)**, [05](05-autotest-seis-pueblos.md). Las fallas eran de las comprobaciones: cámara fija, esperas cortas, suelo a altura 0. Quedan anotados tres detalles del juego: el clic derecho en un arbusto con un aldeano encima, la empalizada de Ayutthaya aceptada por la simulación y la puerta sobre un camino.

**Segunda tanda de fluidez (2026-11-19):**
- **Frente 5:** selección y órdenes. Ctrl+clic, patrulla de varios puntos, escolta, ficha compacta, retratos por función y números de daño apagables. [06](06-seleccion-y-ordenes.md)
- **Frente 6:** guardar y cargar, con autoguardado, repeticiones con línea de tiempo y el panel «Mi base». [07](07-guardar-y-repeticiones.md)
- **Frente 7:** base linda. Estandartes más chicos, modo foto (O), tierra pisada, pilas de recursos, granjas con ciclo y tocones. [08](08-base-linda.md)

**Al integrar** se encontró que menu.gd no compilaba: la red y las repeticiones declaraban la misma variable. Se arregló antes del push. También se ajustó una comprobación del autotest que dependía de la carga de la máquina.

**Resultado:** autotest OK, y también determinismo, órdenes, lecciones, guardado, red, casillas y tutorial.
