# 18 · Partidas de muchos jugadores y equipos (desde 2026-11-14)

## Pedido del autor
> "Que se pueda jugar de a más de 2 civs en un mismo mapa, pensando en 6 o más, y en equipos. Después de la economía."
> "Move forward with 1, 3 and 4."

Plan: [`docs/11-partidas-de-muchos-jugadores.md`](../../docs/11-partidas-de-muchos-jugadores.md), en seis pasos:
1. Equipos en la simulación.
2. Generador para N bases.
3. Formas de agua y mapas especiales para N.
4. IA en equipo y tributo.
5. Menú de lugares e interfaz.
6. Rendimiento con 6 jugadores.

## Paso a paso
1. **(10:30) Paso 1, equipos en la simulación.**
   - **Equipo de cada jugador:** `players[i].equipo` (opción `equipos` de la partida). Por defecto cada jugador es su propio equipo, así que el 1 contra 1 no cambia.
   - **Hostilidad en una sola regla:** `Sim.team_of` y `Sim.enemies(a, b)`. Pasan por ahí la búsqueda de blancos, el daño en área, la campana, los oficios, el arreo, las bajas, la corte etíope y toda la IA (8 lugares). Los aliados no se atacan.
   - **Visión compartida** con el equipo (`reglas.json → equipos.vision_compartida`).
   - **Victoria por equipo:** termina cuando queda un solo equipo en pie (`Sim.winner_team`).
   - **Sitios sagrados por equipo:** los aliados no se los disputan, y la victoria por sitios cuenta los del equipo.
   - **Prueba nueva `tests/equipos.gd`:** dos 2v2 de IA de 30 minutos ([resultado](pruebas/01-equipos-2v2.txt)). **Cero fuego amigo** en 1346 bajas, y las dos partidas terminan con un equipo ganador.
   - **Pendiente:**
     - en las dos ganó el equipo 0, porque el mapa todavía no es justo para 4 (las bases extra reciben recursos sin simetría): es el paso 2;
     - las puertas de un aliado todavía no lo dejan pasar;
     - el tributo entre aliados llega en el paso 4.
