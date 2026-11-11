# 04 — Registro de decisiones

Las decisiones cerradas no se reabren sin una entrada "Propuesta" aprobada. Formato: identificador, fecha, decisión, motivo.

## Cerradas

| ID | Fecha | Decisión | Motivo |
|---|---|---|---|
| D-001 | 2026-11-10 | La referencia de calidad, interfaz y experiencia es Age of Empires IV, no el II | Decisión del autor |
| D-002 | 2026-11-10 | El juego cubre c. 1400–1800 | Final de partida más rico: caballo, pólvora, resistencia y rebelión |
| D-003 | 2026-11-10 | Asimetría radical: cada civilización tiene orden de construcción y forma de jugar muy distintos | Decisión del autor; es lo que distingue al AoE4 del AoE2 |
| D-004 | 2026-11-10 | Lo desarrolla una sola persona con agentes de IA; la documentación es modular y vive en el repositorio | Los agentes trabajan mejor con archivos cortos y una sola fuente de verdad |
| D-005 | 2026-11-10 | Proyecto con conciencia militante y meta comercial eventual | Decisión del autor |
| D-006 | 2026-11-10 | Cuatro recursos comunes: alimento, madera, piedra, riqueza | Capa común aprendible; "riqueza" evita asumir oro y moneda |
| D-007 | 2026-11-10 | Triángulo de contadores por función: choque, distancia, línea | Permite civilizaciones sin caballería sin romper el balance |
| D-008 | 2026-11-10 | Los números de balance viven en archivos de datos, no en documentos | Evita que diseño y juego se desincronicen |
| D-009 | 2026-11-10 | Cada civilización admite varias aperturas y órdenes de construcción viables, descubribles por la comunidad; el diseño no prescribe un orden | Decisión del autor; así funciona la escena de AoE4 |
| D-010 | 2026-11-10 | El motor es Godot | Decisión del autor; proyecto en archivos de texto, apto para agentes |
| D-011 | 2026-11-10 | Las cuatro civilizaciones iniciales son Tawantinsuyu, mapuches, guaraníes y Etiopía | Decisión del autor: priorizar a América Latina, que casi nunca está representada |

## Abiertas

| ID | Pregunta | Opciones | Nota |
|---|---|---|---|
| A-003 | ¿Las potencias coloniales son jugables? | Solo IA y escenarios; jugables más adelante; jugables desde el inicio | Afecta alcance y tono |
| A-004 | ¿Los guaraníes tienen la bifurcación misión o monte? | Sí; no, un solo camino; sí pero después de H6 | Duplica el trabajo del arco tardío |
| A-005 | Nombre definitivo del juego | — | "Proyecto Sur" es provisional |
| A-006 | ¿Hay combate naval más allá de canoas de transporte? | No hasta después de H6; sí, limitado | Afecta a los guaraníes y a futuras civilizaciones del Índico |
| A-007 | ¿Los proyectiles se pueden esquivar? | Impacto inmediato (H1); proyectiles simulados | Esquivar premia la microgestión, pero cuesta rendimiento y determinismo |
| A-008 | ¿Varios constructores tienen rendimiento decreciente? | Lineal (H1); decreciente | Afecta el valor de las aperturas de avance rápido |
| A-009 | ¿`AStarGrid2D` es determinista entre plataformas? | Confiar y medir en H5; caminos propios en enteros | Riesgo para el lockstep (`06`) |
| A-010 | ¿Andenes cuentan como mecánica económica de Tawantinsuyu o como fuente de alimento? | Fuente de alimento (propuesta en la ficha); ranura económica | Presupuesto por civilización (`01`) |
| A-011 | ¿Cómo pierden los mapuches con la victoria por hitos? | Sus lof cuentan como hitos; condición de victoria propia | Debe respetar "no hay capital que tomar" sin crear victorias exclusivas (`05`) |

## Propuestas

Decisiones técnicas que el prototipo de H1 ya usa de forma provisional. Esperan aprobación del autor para pasar a "Cerradas".

| ID | Fecha | Propuesta | Motivo | Estado |
|---|---|---|---|---|
| P-001 | 2026-11-10 | Simulación determinista separada de la presentación, en GDScript, con estado solo en enteros (`06`) | Habilita lockstep en H5 sin reescribir | Pendiente |
| P-002 | 2026-11-10 | Tick de simulación de 100 ms (10 por segundo) con interpolación visual | Margen de rendimiento en GDScript con 200 unidades | Pendiente |
| P-003 | 2026-11-10 | Datos de balance en JSON en `data/`, con unidades enteras (milésimas de casilla, milisegundos) | Legible por agentes y diffs; entero evita errores de redondeo | Pendiente |
| P-004 | 2026-11-10 | Estética de maqueta para H1–H2 (`07`) | Cumple "nada de arte antes de H3" y aun así se lee y se ve cuidado | Pendiente |
| P-005 | 2026-11-10 | La IA corre dentro de la simulación y emite comandos como un jugador (`08`) | Partidas IA contra IA reproducibles como prueba | Pendiente |
