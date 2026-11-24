# 09 — Estado del proyecto

Qué está hecho, qué falta y qué sigue. El paso a paso, con capturas y video, está en `../proceso/`. Las preguntas al autor, en `../proceso/CONSULTAS.md`.

## Resumen (2026-11-20)

| Hito (`02`) | Estado |
|---|---|
| H0 · Documentos | Completo. Decisiones cerradas por delegación del autor (D-012 a D-028) |
| H1 · Prototipo del núcleo | Completo y medido |
| H2 · Civilizaciones asimétricas | Superado en alcance: seis civilizaciones jugables con módulos propios |
| H3 · Arte, sonido e interfaz | Arte procedural por civilización (D-015), audio CC0, interfaz completa, menú y campañas |
| H4 · Cuatro civilizaciones e IA sólida | Seis civilizaciones. La IA juega todas, pero sin dificultades y con balance en ajuste |
| Economía nueva (`diseno/revision-economia/v3/04`) | Implementada (etapas 0–5): seis motores propios, ingenios neutrales, techo de lo disputado, nombres de la riqueza por pueblo. Balance (etapa 6) cerrado: torneo de confirmación con 5 semillas, cinco de seis civs entre 35 y 65 % (mapuches 68 %, con cría a 50 s). Las 25 misiones corren con la IA jugando, sin errores; Etiopía 2, Mapuches 2 y Palmares 1 piden revisar la dificultad con alguien jugando. Hecho; detalle en `proceso/14` |
| Partidas de muchos jugadores y equipos (`11`) | Hecho (`proceso/18`): equipos en la simulación, generador para 3 a 8 bases con simetría por giro (agua, islas, fortines; equidad con 50 semillas en 13 terrenos), puertas aliadas, tributo, IA que elige rival, defiende aliados y da tributo, menú de lugares (1v1 a 4v4 y todos contra todos) y puntaje por equipo con botones de tributo |
| Telemetría (`proceso/20`) | Funciona: `Sim.tele` registra trabadas, caminos imposibles, rechazos con su orden, IA sin lugar o sin ruta, ociosos y ticks lentos. Cada partida queda en `user://telemetria/`, y `tools/telemetria.gd` hace el informe y el mapa de calor. Ya encontró dos fallas de la IA, arregladas. Falta: guardar los SCRIPT ERROR del juego |
| Jugabilidad al estilo AoE4 (`proceso/21`) | Estudio hecho (`docs/diseno/jugabilidad/01–03`) y plan de 11 pasos. Hecho: grupos que marchan en formación (llegada de 23 s a 1 s), aldeanos en bloque solo si van lejos, recolección al terminar un almacén y tecnologías por capacidad. Falta: ataque en formación, escolta, formaciones elegibles, almacenes por recurso y edificios militares por función |
| Jugadores de prueba (`proceso/22`) | Cuatro perfiles de jugador (agentes) dan su opinión sobre qué falta para ser tan divertido como AoE4. Errores encontrados y arreglados: panel con valores de base, textos de prototipo, "✓ ganada" vertical, avisos de la IA en IA contra IA. El cierre que abortaba (código 134) está arreglado (`proceso/24`, 6e): era una lambda guardada en una variable estática, un error del motor 4.7.2 disparado por código nuestro |
| Hacia AoE4 (`proceso/23`) | Decidido por el autor (C-31 a C-34): combate con bonos planos y dos armaduras, animales por región y caza, hitos de 190/220/250 s con aura, comodidades y aprendizaje como AoE4, rivales con civ propia. En curso. Parte C hecha (`proceso/23-como-aoe4/03-aprender-a-jugar.md`): tutorial que se gana siguiéndolo y falla con motivo, avisos que enseñan, cuenta grande de los sitios, fin que explica, nombres en la grilla, registro de la Guía (F7), menú en Fácil Rivales con civ propia en las campañas: Adal, birmanos, chankas, caranquis, cañaris y tupíes (C-39 a C-44 sobre nombres). |
| Después de la segunda ronda (`proceso/24`) | En curso, en cuatro pasos. Paso 1 hecho: los errores de la ronda 2 y la **eficiencia de la IA**. La telemetría mide cada viaje al depósito por recurso (`tools/viajes.gd`, informe y `tests/salud_ia.gd`), y la IA rehace almacenes cuando el bosque se corre. Paso 2 hecho: obra de los hitos de 190/220/250 s, sitios a 10 minutos y auras según el lugar (`reglas.aura_hito`). Arte procedural por edad (paso 4c): obra en tres etapas, aspecto por edad y por pueblo, torres propias; hitos con arquitectura propia y animales por región (4d). Sonido propio por pueblo y música etíope (4g, sin lo sagrado en la tropa: 4h). Tercera ronda de jugadores (`proceso/22-testers/ronda-3/00-sintesis.md`). IA experta (4a): 100 aldeanos, hasta 3 centros y cacería de los últimos edificios sin hitos. Opciones de partida (4b): sitios y hitos sí o no, tiempo límite, recursos, equipos juntos o mezclados. Balance cerrado (torneo 28, 10 semillas, con la micro C2, el hito en obra, la IA que disputa sitios y el movimiento nuevo): todas entre 32 y 68 %. Antes: balance (Palmares 88 %), IA experta, opciones, arte y sonido |
| Revisión histórica (`proceso/25`) | Tres historiadores (América Latina, África, Asia) revisaron todo el contenido. Aplicadas 82 correcciones de texto, arte y sonido que no cambian mecánicas. Decisiones pendientes del autor: C-67 a C-74. Antes de publicar, consultas a comunidades (C-74) |
| Juego tardío y saberes (`proceso/26`) | Pasos 1, 2, 3, 4, 6 y 7 implementados: niveles, herrería, economía y escuela de la IV, asedio y fortaleza, 8 mejoras y unidades propias por pueblo basadas en sus saberes, y la maravilla con su final (la IV en el 61 % de las partidas de 45 min). Costos por recurso. Torneo 39: todas entre 34 y 64 %. Falta el paso 5 (unidades compartidas nuevas, que esperan arte; el arte de cada unidad va por civ) |
| Animaciones (`proceso/27`) | Aldeanos (10 estados) y soldados a pie (quieto, guardia, caminar, golpe de cerca y a distancia, reacción y dos muertes; paso 2) animados con KayKit (CC0) en los seis pueblos y los rivales de campaña, con esqueletos compartidos. Faltan caballos, elefantes y jinetes, y riggear los modelos de Meshy (C-98) |
| Íconos y estados (`proceso/28`) | 69 íconos propios, color por edad, estados de color en lugar del candado, rojo de la ayuda solo si bloquea |
| Balance (`proceso/24`, torneo 36) | Diagnósticos con causa: la casa del arco guaraní (a 150) y el weichafe barato (al costo común). Las seis entre 38 y 60 % |
| Hacia un diseño de esport (`proceso/34`) | Tres iteraciones con revisión de expertos. Entraron: triángulo de contadores más marcado; lancero en la I; sitios con guarnición visible (60/45/30); asedio de área esquivable y ataque al suelo; comercio con mercados neutrales, rutas y bloqueo; muralla de piedra en la II; sumidero de la IV con caminos excluyentes; hitos de 150/180/210 s. Torneo 42: todas entre 42 y 64 %, la IV en 115 de 150. Nota competitiva de los expertos: 5,5 de 10. Se cambia la vara con el torneo de estilos (etapa 35) |
| Fluidez y partidas largas (`proceso/30`, `31`, `32`) | Cola de producción siempre visible y menos mensajes; repetición de producción; Mayús en orden; muro con costo; avisos por zona; selección y órdenes finas; guardar y cargar con instantáneas (un 4v4 al minuto 30 carga en 1,6 s); repeticiones con línea de tiempo; panel «Mi base»; base linda; partida a medida con 8 jugadores. Rendimiento: el 1v6 sin ticks de más de 100 ms; el 4v4 de 40 min con 12 de 24 000 (eran 65), peor tick 121 ms y p95 64 (`proceso/45`) |
| Multijugador en red (`proceso/37`) | Prototipo 1v1 por IP: lockstep, verificación de sincronía, sala, pausas, reconexión por instantánea, caída del anfitrión, retardo según ping y validación de mensajes. Falta NAT o relevo y un servidor de partidas |
| Aprendizaje y arte (`proceso/36`, `38`, `39`) | Lecciones en la Guía y tutorial con las mecánicas nuevas. Fuentes gratuitas de arte 3D y 2D investigadas; 21 íconos genéricos, cursores y marcos propios; 1007 prompts para generar el arte de cada pueblo y edad (proceso/39-arte-interfaz/prompts.html) |
| 3D local (`proceso/43`, `47`) | Pipeline repetible: `tools/gen3d_pipeline.py <pieza|--todas>` (piezas en `data/gen3d_piezas.json`) hace imagen (o FLUX), forma con Hunyuan3D-2mini/2mv turbo, limpieza en Blender, textura con Hunyuan3D-Paint (o el proyector), rig y tamaño del juego, con caché por paso. Aldeano, kancha, kallanka y caballo inca en `assets/generados/modelos/local/` (500–750 KB), todavía sin usar en el juego (C-106). Rig del aldeano probado en Godot con KayKit (`tools/visor_rig.gd`); caballo con rig de cuadrúpedo, caminar y quieto. Falta el retarget dentro de `AldeanoAnimado` y las otras civilizaciones |
| Arte de los pueblos (`proceso/49`) | El gouache de los incas llevado a los otros pueblos, de a uno, con `tools/arte_gouache.py` (un arte por unidad, un ícono por edificio, hojas 3D por edad) y su entrada en `data/arte_pueblos.json`; por pueblo, aldeano, unidad propia, casa y centro en 3D por el pipeline (sin usar, C-106). Hecho en los cinco: mapuches, guaraníes, Etiopía, Palmares y Ayutthaya; los seis pueblos tienen arte pintado en la interfaz. Arreglos (`proceso/50`): caras de piel oscura con rasgos y tono de la hoja (paso `piel` del pipeline y sombreado suave en los 24 modelos), el sombrero siamés, sin paisaje del ícono en los edificios 3D, y el ariete mapuche con arte en la casilla. Falta decidir C-106 |
| Arte en la interfaz (`proceso/48`) | Los incas muestran su arte en gouache en el retrato, la grilla (construir, entrenar, mejoras), los hitos al subir de edad y la maravilla, con la ropa en el color del equipo. Por datos: para otro pueblo, su entrada en `data/arte_pueblos.json` y `tools/arte_pueblo.py`. Los otros cinco pueblos ya tienen su tanda (`proceso/49`). Leñera, depósito de piedra y taller de tejido rehechos con silueta propia y el chaski con arte en la casilla (`proceso/50`) |
| Versiones para amigos (`proceso/44`) | `tools/publicar.sh [--subir]` arma, prueba y (con `--subir`) sube a itch.io las versiones de Linux y Windows, selladas con fecha y commit. Relevo con systemd y Docker, y dirección configurable en el menú. Falta: dónde va el relevo y la página de itch (C-102, C-103) |
| Atajos, tutorial y Arte de la guerra (`proceso/52`) | Hecho (C-35 b, C-37 b, C-38 a). Marcadores de cámara como AoE4: `Ctrl + F1…F4` guarda y `F1…F4` vuelve; los paneles pasan a F5–F9 (economía, edad, sucesos, puntaje, ayuda), la velocidad a K, y los `opciones.cfg` viejos se migran solos. El tutorial se juega con el Tawantinsuyu, con un paso nuevo (almacén de madera) y derrota con motivo si quedan menos de 3 aldeanos. **Arte de la guerra**: cinco misiones cortas (economía temprana, defensa, contadores, sitios sagrados, asedio) con medallas de oro, plata y bronce por tiempo, guardadas en `user://arte_guerra.json`; entrada propia en el menú. El motor de escenarios suma edificios iniciales del jugador, rivales quietos (sin IA), `min` en `proteger` y sitios que buscan hueco |
| H5 · Multijugador en red | Prototipo 1v1 hecho (ver arriba); relevo listo para desplegar (`proceso/44`) |
| H6 · Acceso anticipado | Pendiente |

## Qué tiene el juego

- **Seis civilizaciones** (`data/civs/`): Tawantinsuyu, mapuches, guaraníes, Etiopía, Palmares y Ayutthaya. Cada una tiene edades propias, dos hitos por edad, unidades y edificios únicos, módulos de mecánica y arquitectura propia.
- **Capa común**: recolección, construcción con rendimiento decreciente, población, triángulo de contadores, asedio, empalizadas y puertas, guarnición con andanadas, campana, 17 investigaciones, reparación, niebla de guerra, explorador, relieve y agua.
- **Seis campañas** (`data/campanas/`): 24 misiones narradas desde adentro, ejecutadas por el motor de escenarios.
- **Escaramuza** contra la IA con cualquier par de civilizaciones y cuatro tipos de mapa.
- **Sonido**: interfaz, mundo, ambiente y música CC0.
- **Arte generado con IA** (Meshy, C-03): láminas de las seis civilizaciones y modelos 3D de capitales, casas, el elefante, el kona, los aldeanos de los seis pueblos, el hondero inca, el arquero guaraní y el jinete noble etíope (`proceso/19-arte-y-sonido`), y del paisaje (cinco especies de árbol, arbustos, piedra, arcilla con vasijas, peñascos y yerbal, `proceso/16-paisaje`); el resto es la maqueta procedural.
- **Tutorial**, **mercado**, **sitios sagrados**, **tres dificultades**, **repeticiones**, **opciones** **ayuda en partida (F9)** y **Arte de la guerra** (cinco misiones cortas con medallas).

## Pruebas

| Prueba | Qué verifica |
|---|---|
| `tests/test_determinism.gd` | Mismo estado en 3.000 ticks con la misma semilla |
| `tests/bench.gd` | 200 unidades peleando dentro del presupuesto del tick |
| `tests/civ_smoke.gd` | Las seis civilizaciones juegan entre sí sin errores |
| `tests/campaign_smoke.gd` | Las 24 misiones, el tutorial y las 5 del Arte de la guerra se arman y corren |
| `tests/tutorial_letra.gd` | El tutorial (Tawantinsuyu) seguido al pie de la letra se gana; sin defenderse, se pierde con motivo (`-- --modo=indefenso`) |
| `tests/arte_guerra.gd` | Las cinco misiones del Arte de la guerra se ganan con un jugador que sigue a la Guía, y las medallas van oro < plata < bronce (`-- --mision=arte-3` para una sola) |
| `tests/torneo.gd` | Balance: todas contra todas |
| `tests/salud_ia.gd` | Cada IA en 12 minutos: edad II a tiempo, dos funciones, ejército, producción, mercado, recursos parados y madera a menos de 12 casillas del depósito |
| `tools/viajes.gd` | Viaje medio al depósito por recurso, cada 5 minutos, y los depósitos de cada uno |
| `--autotest` | Controles de punta a punta con eventos reales |
| `tests/red_relevo.gd` | Dos clientes por el relevo, con el rechazo de otra versión y el aviso que ve el jugador |
| `tools/publicar.sh` | Versión para compartir: exportación, versión igual a la del proyecto, arranque sin ventana, determinismo y relevo |
| `tests/test_paleta.gd` | Colores de equipo, recursos y vida distinguibles con daltonismo simulado; contraste de la interfaz |
| `tests/test_opciones.gd` | Opciones: ida y vuelta por `ConfigFile`, escala automática y texto grande |

## Deudas conocidas

| Tema | Detalle |
|---|---|
| Balance | Lo mide el torneo; ver la última tabla en `proceso/` |
| IA y mecánicas propias | Juega los seis motores (talleres, corrales y kawiñ, rozas, gult y corte que se funda, oficios, elefantes), traza caminos rodeando obstáculos, asalta ingenios y usa la campana parcial. Falta: caminos incas hacia la arcilla, menos dependencia del mercado |
| Dificultades y estilos de la IA | Tres dificultades (fácil, normal, difícil) y cuatro estilos (pacífica, equilibrada, acosadora, agresiva) |
| Animación | Gente a pie con esqueleto (KayKit, `proceso/27`); caballos, elefantes y artillería siguen con la animación procedural |
| Modelos generados | Capitales, casas, elefante, kona, aldeanos (seis), hondero inca, arquero guaraní, jinete noble etíope, flecheiro de Palmares y paisaje; el resto de los edificios y de las unidades militares son la maqueta procedural. Etiopía sigue sin música propia (C-24). Falta animación con esqueleto. Requisito nuevo del autor: obra por etapas y aspecto por edad en todos los modelos (`07`) |
| Interfaz, segunda tanda | Partes A y B integradas (`proceso/17`): escala de interfaz de 1366×768 a 4K, paleta apta para daltonismo con modos (`tests/test_paleta.gd`), estados de la grilla a 4,5:1, opciones guardadas en `user://opciones.cfg`, cursores contextuales, grilla estable con submenús, avisos con jerarquía y salto con Espacio, fila de grupos, HUD vacío que no tapa y errores puntuales. Texto grande hecho (`proceso/46`): opción guardada que agranda la letra chica del HUD (`data/interfaz.json → texto_grande`) |
| Partidas de muchos jugadores | Rendimiento: 6 IA a 18 ms por tick (entra a ×4); fin de partida y batallas de 900 unidades a 28–32 ms (entran a ×3). Caminos con caché por región y destinos encerrados por región del destino (`proceso/32`, `45`). Siguiente: el costo por entidad del final del 4v4 (IA, recolección y movimiento; ×4 alcanza hasta el minuto 15). Torneo 1v1 con 5 semillas tras los cambios de IA: cinco de seis civs entre 35 y 65 %; guaraníes 68 % (por puntos) y Tawantinsuyu 36 %, a mirar en la próxima ronda de balance |
| Escala y velocidad | Corregidas el 2026-11-13 (`escala_visual`, `velocidad_pct`); falta la opinión del autor a ×1 |
| Multijugador | H5 |
| Naval | Fuera de alcance (D-020) |
