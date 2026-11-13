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
| D-012 | 2026-11-13 | Simulación determinista separada de la presentación, en GDScript y con estado solo en enteros (era P-001) | Delegada por el autor |
| D-013 | 2026-11-13 | Tick de 100 ms con interpolación visual (era P-002) | Delegada por el autor |
| D-014 | 2026-11-13 | Datos de balance en JSON con unidades enteras (era P-003) | Delegada por el autor |
| D-015 | 2026-11-13 | Estética de maqueta hasta definir el arte final; el arte final es estilizado y procedural, con audio libre (era P-004) | Delegada por el autor; "llevarlo hasta elegir arte" |
| D-016 | 2026-11-13 | La IA corre dentro de la simulación y emite comandos (era P-005) | Delegada por el autor |
| D-017 | 2026-11-13 | Rendimiento decreciente de construcción en la capa común; una civilización puede invertirlo con su módulo (potirõ guaraní) (era P-006, cierra A-008) | Delegada; resuelve la contradicción con `investigacion/guaranies.md` |
| D-018 | 2026-11-13 | Las potencias coloniales y otros rivales históricos son facciones solo de IA y de campaña, bajo la clave `invasores` (cierra A-003) | Delegada; alcance y tono |
| D-019 | 2026-11-13 | Los guaraníes tienen la bifurcación misión o monte, acotada a las dos opciones del avance a la edad III (cierra A-004) | Recomendación de `investigacion/guaranies.md` |
| D-020 | 2026-11-13 | Sin combate naval; las canoas son transporte fluvial rápido (cierra A-006) | Alcance de una persona |
| D-021 | 2026-11-13 | Impacto inmediato de proyectiles (cierra A-007) | Determinismo y rendimiento |
| D-022 | 2026-11-13 | Los andenes son la fuente de alimento inca, no su ranura económica (cierra A-010) | Coincide la ficha con la investigación |
| D-023 | 2026-11-13 | Los lof mapuches cuentan como centros y el rewe como hito; quien se queda sin hitos ve revelados sus centros al rival (cierra A-011) | Propuesta de `investigacion/mapuches.md` |
| D-024 | 2026-11-13 | Reparar es gratis (cierra A-012) | Favorece la defensa económica pedida por el autor |
| D-025 | 2026-11-13 | Se corrigen `03` y las fichas según las fuentes en las 15 contradicciones de `investigacion/README.md`, salvo donde la jugabilidad lo impida (queda anotado en la ficha) | Delegada; pilar 3 |
| D-026 | 2026-11-13 | Se suman dos civilizaciones: Quilombo dos Palmares (Brasil) y Reino de Ayutthaya (Siam) | Pedido del autor: una de Brasil o Amazonía y otra, probablemente de Asia |
| D-027 | 2026-11-13 | El mapa tiene relieve (alturas) y agua (ríos), porque varias mecánicas dependen de ellos (andenes, altura etíope, ríos guaraníes y siameses) | Necesario para la asimetría |
| D-029 | 2026-11-13 | El juego se llama **Raíces** (cierra A-005) | Respuesta del autor a C-01 |
| D-030 | 2026-11-13 | Se usa Meshy para arte generado, gastando lo necesario de forma eficiente (los créditos se renuevan cada mes) | Respuesta del autor a C-05 |
| D-028 | 2026-11-13 | Cada civilización tiene una campaña de 4 misiones, narrada desde adentro | Pedido del autor |

## Abiertas

| ID | Pregunta | Opciones | Nota |
|---|---|---|---|
| A-009 | ¿`AStarGrid2D` es determinista entre plataformas? | Confiar y medir en H5; caminos propios en enteros | Riesgo para el lockstep (`06`) |

## Historial de propuestas

P-001 a P-006 se cerraron el 2026-11-13 como D-012 a D-017.
