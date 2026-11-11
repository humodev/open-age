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

## Cómo correr

```
godot --path .                                  # jugar contra la IA
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

## Riesgos y deudas conocidas

| Tema | Detalle | Cuándo |
|---|---|---|
| Pico de búsqueda de caminos | Una orden a 200 unidades calcula 200 caminos en un tick (≈67 ms). Solución prevista: caminos compartidos por grupo o repartir el cálculo entre ticks | Antes de H2 |
| Sin niebla de guerra | Mapuches y guaraníes la necesitan para sigilo y emboscada (`05`) | H2 |
| Sin asedio | El daño a edificios viene del triángulo con multiplicador reducido (`reglas.json` → `contadores.edificio`) | H2 |
| Un solo hito por edad | `01` exige dos opciones por avance | H2 |
| Sin sonido | Fuera de alcance de H1 | H3 |
| Fuente incluida | Fira Sans (OFL) en `assets/fonts/` | — |
| `AStarGrid2D` entre plataformas | A-009 | H5 |

## Próximos pasos sugeridos

1. **El autor juega H1** y anota qué se siente mal: ritmo económico, tamaño del mapa, velocidad de las unidades. Todo se ajusta en `data/`.
2. Aprobar o corregir P-001 a P-005 (`04`).
3. Resolver A-010 y A-011, que bloquean las fichas de H2.
4. Cerrar el pico de búsqueda de caminos.
5. H2: niebla de guerra, primer módulo de civilización (red de caminos de Tawantinsuyu) y segundo (lof dispersos de los mapuches), cada uno como módulo con parámetros en `data/civs/`.
