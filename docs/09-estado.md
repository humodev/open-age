# 09 — Estado del proyecto

Qué está hecho, qué falta y qué sigue. El paso a paso, con capturas y video, está en `../proceso/`. Las preguntas al autor, en `../proceso/CONSULTAS.md`.

## Resumen (2026-11-13)

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
| Jugadores de prueba (`proceso/22`) | Cuatro perfiles de jugador (agentes) dan su opinión sobre qué falta para ser tan divertido como AoE4. Errores encontrados y arreglados: panel con valores de base, textos de prototipo, "✓ ganada" vertical, avisos de la IA en IA contra IA. Conocido: el juego a veces termina con un volcado de memoria al cerrar tras `--shot` (dentro del motor, después de guardar la captura) |
| Hacia AoE4 (`proceso/23`) | Decidido por el autor (C-31 a C-34): combate con bonos planos y dos armaduras, animales por región y caza, hitos de 190/220/250 s con aura, comodidades y aprendizaje como AoE4, rivales con civ propia. En curso. Parte C hecha (`proceso/23-como-aoe4/03-aprender-a-jugar.md`): tutorial que se gana siguiéndolo y falla con motivo, avisos que enseñan, cuenta grande de los sitios, fin que explica, nombres en la grilla, registro de la Guía (F7), menú en Fácil Rivales con civ propia en las campañas: Adal, birmanos, chankas, caranquis, cañaris y tupíes (C-39 a C-44 sobre nombres). |
| Después de la segunda ronda (`proceso/24`) | En curso, en cuatro pasos. Paso 1 hecho: los errores de la ronda 2 y la **eficiencia de la IA**. La telemetría mide cada viaje al depósito por recurso (`tools/viajes.gd`, informe y `tests/salud_ia.gd`), y la IA rehace almacenes cuando el bosque se corre. Paso 2 hecho: obra de los hitos de 190/220/250 s, sitios a 10 minutos y auras según el lugar (`reglas.aura_hito`). Arte procedural por edad (paso 4c): obra en tres etapas, aspecto por edad y por pueblo, torres propias; hitos con arquitectura propia y animales por región (4d). Sonido propio por pueblo y música etíope (4g, sin lo sagrado en la tropa: 4h). Tercera ronda de jugadores (`proceso/22-testers/ronda-3/00-sintesis.md`). IA experta (4a): 100 aldeanos, hasta 3 centros y cacería de los últimos edificios sin hitos. Opciones de partida (4b): sitios y hitos sí o no, tiempo límite, recursos, equipos juntos o mezclados. Balance cerrado (torneo 28, 10 semillas, con la micro C2, el hito en obra, la IA que disputa sitios y el movimiento nuevo): todas entre 32 y 68 %. Antes: balance (Palmares 88 %), IA experta, opciones, arte y sonido |
| Revisión histórica (`proceso/25`) | Tres historiadores (América Latina, África, Asia) revisaron todo el contenido. Aplicadas 82 correcciones de texto, arte y sonido que no cambian mecánicas. Decisiones pendientes del autor: C-67 a C-74. Antes de publicar, consultas a comunidades (C-74) |
| Juego tardío y saberes (`proceso/26`) | Diseñado, no implementado: niveles veterano y élite, herrería, unidades compartidas nuevas, 8 mejoras y 3 unidades propias por pueblo basadas en sus saberes (trepanación andina, khipu, imprenta guaraní, fäws, fuelle de Angola, recetario de Narai…), maravillas y final de partida. El paso 1 es neutro en poder según el modelo. Entra de a pasos con torneo; si un paso rompe el balance, queda como contenido |
| H5 · Multijugador en red | No empezado. La simulación determinista y por comandos ya lo habilita |
| H6 · Acceso anticipado | Pendiente |

## Qué tiene el juego

- **Seis civilizaciones** (`data/civs/`): Tawantinsuyu, mapuches, guaraníes, Etiopía, Palmares y Ayutthaya. Cada una tiene edades propias, dos hitos por edad, unidades y edificios únicos, módulos de mecánica y arquitectura propia.
- **Capa común**: recolección, construcción con rendimiento decreciente, población, triángulo de contadores, asedio, empalizadas y puertas, guarnición con andanadas, campana, 17 investigaciones, reparación, niebla de guerra, explorador, relieve y agua.
- **Seis campañas** (`data/campanas/`): 24 misiones narradas desde adentro, ejecutadas por el motor de escenarios.
- **Escaramuza** contra la IA con cualquier par de civilizaciones y cuatro tipos de mapa.
- **Sonido**: interfaz, mundo, ambiente y música CC0.
- **Arte generado con IA** (Meshy, C-03): láminas de las seis civilizaciones y modelos 3D de capitales, casas, el elefante, el kona, los aldeanos de los seis pueblos, el hondero inca, el arquero guaraní y el jinete noble etíope (`proceso/19-arte-y-sonido`), y del paisaje (cinco especies de árbol, arbustos, piedra, arcilla con vasijas, peñascos y yerbal, `proceso/16-paisaje`); el resto es la maqueta procedural.
- **Tutorial**, **mercado**, **sitios sagrados**, **tres dificultades**, **repeticiones**, **opciones** y **ayuda en partida (F1)**.

## Pruebas

| Prueba | Qué verifica |
|---|---|
| `tests/test_determinism.gd` | Mismo estado en 3.000 ticks con la misma semilla |
| `tests/bench.gd` | 200 unidades peleando dentro del presupuesto del tick |
| `tests/civ_smoke.gd` | Las seis civilizaciones juegan entre sí sin errores |
| `tests/campaign_smoke.gd` | Las 24 misiones se arman y corren |
| `tests/tutorial_letra.gd` | El tutorial seguido al pie de la letra se gana; sin defenderse, se pierde con motivo (`-- --modo=indefenso`) |
| `tests/torneo.gd` | Balance: todas contra todas |
| `tests/salud_ia.gd` | Cada IA en 12 minutos: edad II a tiempo, dos funciones, ejército, producción, mercado, recursos parados y madera a menos de 12 casillas del depósito |
| `tools/viajes.gd` | Viaje medio al depósito por recurso, cada 5 minutos, y los depósitos de cada uno |
| `--autotest` | Controles de punta a punta con eventos reales |
| `tests/test_paleta.gd` | Colores de equipo, recursos y vida distinguibles con daltonismo simulado; contraste de la interfaz |
| `tests/test_opciones.gd` | Opciones: ida y vuelta por `ConfigFile` y escala automática |

## Deudas conocidas

| Tema | Detalle |
|---|---|
| Balance | Lo mide el torneo; ver la última tabla en `proceso/` |
| IA y mecánicas propias | Juega los seis motores (talleres, corrales y kawiñ, rozas, gult y corte que se funda, oficios, elefantes), traza caminos rodeando obstáculos, asalta ingenios y usa la campana parcial. Falta: caminos incas hacia la arcilla, menos dependencia del mercado |
| Dificultades y estilos de la IA | Tres dificultades (fácil, normal, difícil) y cuatro estilos (pacífica, equilibrada, acosadora, agresiva) |
| Animación | Procedural (paso, galope, trabajo, golpe, muerte); sin esqueletos |
| Modelos generados | Capitales, casas, elefante, kona, aldeanos (seis), hondero inca, arquero guaraní, jinete noble etíope, flecheiro de Palmares y paisaje; el resto de los edificios y de las unidades militares son la maqueta procedural. Etiopía sigue sin música propia (C-24). Falta animación con esqueleto. Requisito nuevo del autor: obra por etapas y aspecto por edad en todos los modelos (`07`) |
| Interfaz, segunda tanda | Partes A y B integradas (`proceso/17`): escala de interfaz de 1366×768 a 4K, paleta apta para daltonismo con modos (`tests/test_paleta.gd`), estados de la grilla a 4,5:1, opciones guardadas en `user://opciones.cfg`, cursores contextuales, grilla estable con submenús, avisos con jerarquía y salto con Espacio, fila de grupos, HUD vacío que no tapa y errores puntuales. Pendiente: opción de texto grande |
| Partidas de muchos jugadores | Rendimiento: 6 IA a 18 ms por tick (entra a ×4); fin de partida y batallas de 900 unidades a 28–32 ms (entran a ×3). Siguiente: caminos con caché por región. Torneo 1v1 con 5 semillas tras los cambios de IA: cinco de seis civs entre 35 y 65 %; guaraníes 68 % (por puntos) y Tawantinsuyu 36 %, a mirar en la próxima ronda de balance |
| Escala y velocidad | Corregidas el 2026-11-13 (`escala_visual`, `velocidad_pct`); falta la opinión del autor a ×1 |
| Multijugador | H5 |
| Naval | Fuera de alcance (D-020) |
