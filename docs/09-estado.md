# 09 — Estado del proyecto

Qué está hecho, qué falta y qué sigue. Se actualiza al cerrar cada sesión de trabajo. Los hitos se definen en `02-alcance-y-epoca.md`.

## Resumen

| Hito | Estado |
|---|---|
| H0 — Documentos | Completo en borrador: todos los archivos del índice existen. Falta la revisión del autor y aprobar P-001 a P-005 (`04`) |
| H1 — Prototipo gris | Jugable. Criterios técnicos medidos (ver abajo). Falta que el autor lo juegue y decida si el núcleo es divertido |
| H2 en adelante | No empezado |

## H1: criterios de "terminado"

| Criterio (`02`) | Estado | Cómo se verifica |
|---|---|---|
| Recolectar | Hecho | `--autotest` (alimento entra al banco) |
| Construir | Hecho | `--autotest` (casa colocada y terminada) |
| Producir | Hecho | `--autotest` (aldeano encolado) |
| Pelear | Hecho | `--demo=batalla`; partidas IA contra IA con bajas |
| Avanzar de edad | Hecho | `tests/ai_match.gd`: ambas IA llegan a edad III–IV |
| 200 unidades sin caídas de rendimiento | Hecho, con margen | `tests/bench.gd`: promedio ≈4,5 ms por tick contra 100 ms de presupuesto; peor tick ≈67 ms (ver riesgos) |
| Simulación determinista desde H1 | Hecho | `tests/test_determinism.gd`: mismo hash en 3.000 ticks |

## Capa común contra AoE4

Comparación con la referencia de calidad (D-001). Detalle con fuentes en `investigacion/aoe4-capa-comun.md`.

| Sistema | Estado |
|---|---|
| Recolección, depósitos, granjas, población | Hecho |
| Centro con guarnición y andanadas, campana | Hecho (2026-11-11) |
| Investigaciones por edificio con cadenas por edad | Hecho (2026-11-11) |
| Dos hitos por edad con efecto permanente | Hecho (2026-11-11) |
| Reparación | Hecho; gratis (A-012) |
| Niebla de guerra y explorador | Hecho (2026-11-11) |
| Empalizada y puerta | Hecho (2026-11-11). Falta muralla de piedra |
| Asedio (ariete) | Hecho (2026-11-11) |
| Rendimiento decreciente de construcción | Hecho (P-006) |
| Solo la capital cuenta como hito | Hecho |
| Menú de inicio | Hecho |
| Caza y ganado | Falta: hoy la apertura de alimento es casi única (arbusto y después granja) |
| Mercado y comercio por riqueza | Falta |
| Sitios sagrados (victoria y riqueza tardía) | Falta |
| Colas de órdenes con Mayúsculas, puntos de ruta | Falta |
| Muralla de piedra, torres sobre muralla | Falta |
| Sonido | H3 |
| Repeticiones (gratis con lockstep: semilla + comandos) | Falta |

## Cómo correr

```
godot --path .                                  # menú de inicio
godot --path . -- --seed=42                     # directo a una escaramuza
godot --path . -- --aivai                       # mirar IA contra IA
godot --path . -- --demo=batalla                # 30 contra 30 en el centro
godot --path . -- --autotest                    # prueba de controles de punta a punta
godot --headless --path . -s tests/test_determinism.gd
godot --headless --path . -s tests/bench.gd
godot --headless --path . -s tests/ai_match.gd -- --seed=7 --minutes=30
```

Velocidad de juego: `F3` (×1, ×2, ×4). Pausa: `Esc` sin selección, o `F10`.

## Hecho en esta sesión (2026-11-10)

- Documentos `05`–`08`, plantilla y fichas de civilización (`civs/`), propuestas y preguntas nuevas en `04`.
- Datos de balance en `data/` (reglas, unidades, edificios, recursos, edades).
- Simulación determinista en enteros: economía, construcción, producción, combate con triángulo, edades por hito, victoria por hitos, mapa simétrico generado por semilla.
- IA de escaramuza que juega una partida completa (economía, casas, depósitos, cuarteles, hitos, ejército por contadores, defensa y oleadas).
- Presentación en estética de maqueta: modelos procedurales por función, luz y sombras, interpolación, animaciones de paso, trabajo y golpe, proyectiles, muertes y polvo.
- Interfaz: recursos con aldeanos por recurso, edad y reloj, minimapa orientado como la cámara, panel de selección (individual, grupo, cola de producción), grilla de comandos con atajos y costos, avisos, pausa y pantalla final.
- Controles de `07`: selección por arrastre y doble clic, órdenes contextuales, ataque en movimiento, grupos, aldeano inactivo, punto de reunión.

## Observaciones de las partidas IA contra IA

- Semilla 7: el jugador 0 avanzó a edad II a los 4:10 sin ejército; el jugador 1 presionó con 5 unidades a los 4:00, le destruyó la economía y ganó a los 16:00. Es una primera señal de "ventanas de tiempo" (`01`, palancas): avanzar rápido tiene un costo explotable. Falta comprobar que la presión no domine siempre (test de las tres aperturas, H2).
- Semilla 1234: partida pareja, ambos en edad III a los 13:30; ganador a los 26:40.

- Semilla 7 tras agregar guarnición, campana, investigaciones, arietes y empalizadas: el jugador que antes caía a los 16:00 resiste la presión temprana. Pero a los 40:00 no hay ganador: ninguna IA llega a la edad IV (le falta riqueza y piedra) y las defensas aguantan. Es ajuste de la IA (`08`), no de la capa común.

## Riesgos y deudas conocidas

| Tema | Detalle | Cuándo |
|---|---|---|
| Pico de búsqueda de caminos | Una orden a 200 unidades calcula 200 caminos en un tick (≈67 ms). Solución prevista: caminos compartidos por grupo o repartir el cálculo entre ticks | Antes de H2 |
| IA sin cierre | Partidas largas sin ganador; no usa empalizadas ni llega a edad IV | Antes de H2 |
| IA ve todo | No respeta la niebla todavía (`08`) | H2 |
| Sin sonido | Fuera de alcance de H1 | H3 |
| Fuente incluida | Fira Sans (OFL) en `assets/fonts/` | — |
| `AStarGrid2D` entre plataformas | A-009 | H5 |

## Próximos pasos sugeridos

1. **El autor juega H1** y anota qué se siente mal: ritmo económico, tamaño del mapa, velocidad de las unidades. Todo se ajusta en `data/`.
2. Aprobar o corregir P-001 a P-005 (`04`).
3. Resolver A-010 y A-011, que bloquean las fichas de H2.
4. Cerrar el pico de búsqueda de caminos.
5. H2: niebla de guerra, primer módulo de civilización (red de caminos de Tawantinsuyu) y segundo (lof dispersos de los mapuches), cada uno como módulo con parámetros en `data/civs/`.
