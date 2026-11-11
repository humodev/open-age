# 06 — Arquitectura

Cómo está construido el juego en Godot (D-010). Las decisiones de esta página que todavía no están aprobadas figuran como propuestas en `04-decisiones.md` (P-001 a P-005).

## Principios

1. **La simulación no sabe que existe la pantalla.** `src/sim/` no usa nodos, escenas, física ni `Time`. Es código puro que recibe comandos y avanza ticks.
2. **La presentación no decide nada.** `src/game/` lee el estado de la simulación, lo dibuja y traduce la entrada del jugador en comandos.
3. **Todo número de balance está en `data/`** (D-008). El código lee claves; no tiene constantes de juego.
4. **Cada mecánica única es un módulo con parámetros** (test del módulo, `01`). Una civilización es un archivo de datos que activa módulos, no código propio.

## Estructura del repositorio

```
project.godot
docs/            Diseño (este directorio)
data/            Números de balance, JSON
  reglas.json    Tick, población, contadores, mapa
  unidades.json
  edificios.json
  recursos.json  Recursos del mapa (árboles, rocas…)
  edades.json    Nombres genéricos, costos de hito, bonificaciones
src/sim/         Simulación determinista (sin nodos)
  sim.gd         Estado, comandos, sistemas por tick
  sim_entity.gd  Entidad (unidad, edificio o recurso)
  sim_map.gd     Grilla, generación del mapa, búsqueda de caminos
  sim_data.gd    Carga de datos a enteros
  sim_rng.gd     Generador pseudoaleatorio propio
  sim_ai.gd      IA de escaramuza (emite comandos como un jugador)
src/game/        Presentación
  main.gd        Arranque, bucle de ticks, argumentos de línea de comandos
  world_view.gd  Mallas de entidades, interpolación, efectos
  meshes.gd      Construcción procedural de las piezas de maqueta
  rts_camera.gd  Cámara
  controller.gd  Selección, órdenes, colocación, atajos
  hud.gd         Interfaz
  minimap.gd     Minimapa
  overlay.gd     Barras de vida y rectángulo de selección
tests/           Pruebas sin ventana (determinismo, rendimiento)
```

## Determinismo

Requisito desde H1 (`02`, riesgos) para que el multijugador de H5 sea por **lockstep**: cada cliente corre la misma simulación con los mismos comandos y solo se transmiten comandos.

Reglas de código para `src/sim/`:
- **Solo enteros** en el estado. Posiciones en milésimas de casilla (`1000 = 1 casilla`). Tiempos en milisegundos. Porcentajes en enteros.
- Los datos JSON se convierten a enteros al cargarse (`sim_data.gd`); un valor con decimales en `data/` es un error.
- Raíz cuadrada entera (`Sim.isqrt`) con corrección; nunca `sin`, `cos`, `atan2` ni `Vector2` en el estado.
- Aleatoriedad solo con `SimRng` sembrado por la partida.
- Iteración en orden de `id` (las entidades se guardan en un arreglo ordenado por creación).
- La búsqueda de caminos usa `AStarGrid2D` del motor: es código nativo y determinista con las mismas entradas en la misma versión de Godot. Riesgo abierto entre plataformas: ver A-009.
- `Sim.state_hash()` resume el estado. `tests/test_determinism.gd` corre dos partidas IA contra IA con la misma semilla y compara los hashes en cada tick.

## Bucle

```
main._process(delta):
    acumulador += delta
    mientras acumulador >= tick:
        sim.step()            # aplica comandos del tick y corre sistemas
        world_view.on_tick()  # guarda posiciones previas para interpolar
        acumulador -= tick
    world_view.render(acumulador / tick)
```

Orden de sistemas dentro de `step()`: comandos → IA → producción → edificios que atacan → unidades (máquina de estados) → separación → limpieza de muertos → victoria. El orden es parte del contrato de determinismo; cambiarlo cambia los hashes.

## Entidades

Una sola clase (`SimEntity`) con categoría `UNIDAD`, `EDIFICIO` o `RECURSO`. Las capacidades salen de los datos: un edificio es depósito porque tiene `deposito`, produce porque tiene `produce`, dispara porque tiene `ataque`. No hay subclases por tipo.

Máquina de estados de unidades: `INACTIVA`, `MOVER`, `ATACAR_MOVIENDO`, `ATACAR`, `RECOLECTAR`, `ENTREGAR`, `CONSTRUIR`.

## Movimiento

- **Caminos**: A* sobre la grilla de casillas, con diagonales solo si no cortan esquinas. Las casillas de edificios y recursos son sólidas, salvo las de edificios transitables (granjas).
- **Grupo**: una orden de movimiento reparte destinos en formación alrededor del punto, en orden de `id`.
- **Separación**: tabla espacial de celdas; las unidades superpuestas se empujan a la mitad cada una sin entrar en casillas sólidas.
- **Persecución**: contra unidades se recalcula el camino cuando el objetivo cambia de casilla, como máximo cada pocos ticks; a corta distancia se avanza en línea recta.
- **Medición H1**: `tests/bench.gd` corre 200 unidades peleando y reporta milisegundos por tick. El criterio de H1 es que el tick promedio entre en el presupuesto (`reglas.json` → `tick_ms`) con margen para la imagen.

## Datos

JSON en `data/`, legible por agentes y por diffs de git. Convenciones:
- Claves en español sin tildes ni eñes (`pob`, `edad_min`, `vision`).
- Distancias en milésimas de casilla; velocidades en milésimas de casilla por segundo; tasas en milésimas de unidad de recurso por segundo; tiempos en milisegundos.
- Las civilizaciones (H2) serán archivos `data/civs/<clave>.json` que reemplazan unidades por función y activan módulos con parámetros.

## Presentación

- Una malla procedural por tipo, construida con primitivas (`meshes.gd`) en estética de maqueta (`07-arte-y-ui.md`).
- Interpolación lineal entre el tick previo y el actual.
- Selección por proyección a pantalla, sin física.
- La interfaz se construye por código con un tema común (`hud.gd`).

## Multijugador (H5)

Lockstep con retardo de entrada: los comandos locales se programan para `tick_actual + retardo`. La simulación ya recibe los comandos con número de tick, así que agregar red no cambia `src/sim/`. Detección de desincronización comparando `state_hash()` periódicamente.

## Pruebas

Se corren sin ventana:

```
godot --headless --path . -s tests/test_determinism.gd
godot --headless --path . -s tests/bench.gd
```
