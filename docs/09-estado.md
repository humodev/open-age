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
| Economía nueva (`diseno/revision-economia/v3/04`) | Implementada (etapas 0–5): seis motores propios, ingenios neutrales, techo de lo disputado, nombres de la riqueza por pueblo. Balance (etapa 6): tras 5 ajustes, las seis civs entre 40 y 66 % de victorias; falta confirmar con 5 semillas y probar las campañas. Detalle en `proceso/14` |
| Partidas de muchos jugadores y equipos (`11`) | Planificado para después de la economía: de 2 a 8 jugadores (foco en 6), equipos, mapas para N, IA en equipo |
| H5 · Multijugador en red | No empezado. La simulación determinista y por comandos ya lo habilita |
| H6 · Acceso anticipado | Pendiente |

## Qué tiene el juego

- **Seis civilizaciones** (`data/civs/`): Tawantinsuyu, mapuches, guaraníes, Etiopía, Palmares y Ayutthaya. Cada una tiene edades propias, dos hitos por edad, unidades y edificios únicos, módulos de mecánica y arquitectura propia.
- **Capa común**: recolección, construcción con rendimiento decreciente, población, triángulo de contadores, asedio, empalizadas y puertas, guarnición con andanadas, campana, 17 investigaciones, reparación, niebla de guerra, explorador, relieve y agua.
- **Seis campañas** (`data/campanas/`): 24 misiones narradas desde adentro, ejecutadas por el motor de escenarios.
- **Escaramuza** contra la IA con cualquier par de civilizaciones y cuatro tipos de mapa.
- **Sonido**: interfaz, mundo, ambiente y música CC0.
- **Arte generado con IA** (Meshy, C-03): láminas de las seis civilizaciones y modelos 3D de capitales, casas, el elefante y el kona, y del paisaje (cinco especies de árbol, arbustos, piedra, arcilla con vasijas, peñascos y yerbal, `proceso/16-paisaje`); el resto es la maqueta procedural.
- **Tutorial**, **mercado**, **sitios sagrados**, **tres dificultades**, **repeticiones**, **opciones** y **ayuda en partida (F1)**.

## Pruebas

| Prueba | Qué verifica |
|---|---|
| `tests/test_determinism.gd` | Mismo estado en 3.000 ticks con la misma semilla |
| `tests/bench.gd` | 200 unidades peleando dentro del presupuesto del tick |
| `tests/civ_smoke.gd` | Las seis civilizaciones juegan entre sí sin errores |
| `tests/campaign_smoke.gd` | Las 24 misiones se arman y corren |
| `tests/torneo.gd` | Balance: todas contra todas |
| `--autotest` | Controles de punta a punta con eventos reales |

## Deudas conocidas

| Tema | Detalle |
|---|---|
| Balance | Lo mide el torneo; ver la última tabla en `proceso/` |
| IA y mecánicas propias | Juega los seis motores (talleres, corrales y kawiñ, rozas, gult y corte que se funda, oficios, elefantes), traza caminos rodeando obstáculos, asalta ingenios y usa la campana parcial. Falta: caminos incas hacia la arcilla, menos dependencia del mercado |
| Dificultades y estilos de la IA | Tres dificultades (fácil, normal, difícil) y cuatro estilos (pacífica, equilibrada, acosadora, agresiva) |
| Animación | Procedural (paso, galope, trabajo, golpe, muerte); sin esqueletos |
| Modelos generados | Capitales, casas, elefante, kona y paisaje (árboles, arbustos, rocas, arcilla, peñascos); el resto de los edificios y casi todas las unidades son la maqueta procedural |
| Interfaz, segunda tanda | Pendiente según `diseno/interfaz/00-auditoria.md`: escala de interfaz, paleta para daltónicos, cursores, grilla estable, avisos con jerarquía y opciones guardadas |
| Partidas de muchos jugadores | Planificado en `11`: de 2 a 8 jugadores y equipos, después de la economía |
| Escala y velocidad | Corregidas el 2026-11-13 (`escala_visual`, `velocidad_pct`); falta la opinión del autor a ×1 |
| Multijugador | H5 |
| Naval | Fuera de alcance (D-020) |
