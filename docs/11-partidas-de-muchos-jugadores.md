# 11 — Partidas de muchos jugadores y equipos (plan, 2026-11-13)

Pedido del autor: "Que se pueda jugar de a más de 2 civs en un mismo mapa, pensando en 6 o más, y en equipos. Después de la economía."

## Punto de partida
- **Simulación.** Ya admite N jugadores: grilla de caminos, niebla, recursos y una IA por jugador.
- **Campañas.** Usan hasta 4 jugadores. Todos contra todos.
- **Escaramuza.** Solo 1 contra 1.
- **Generador del mapa.** Espeja todo para 2 (simetría puntual) y tiene 4 esquinas fijas para las bases.
- **Equipos.** No existe el concepto de aliado: la hostilidad es `owner != player`.

## Objetivo
- **De 2 a 8 jugadores**, con el foco en 6.
- **Formatos:**
  - todos contra todos;
  - equipos libres (2v2, 3v3, 4v4, 2v2v2, 3v1…);
  - con o sin la IA en cada lugar.

## Diseño

### 1. Equipos (simulación)
- `players[i]["equipo"]` es un entero. La hostilidad pasa a ser `hostil(a, b) = a != b and equipo(a) != equipo(b)`. Hay una función única, y la usan `find_enemy`, `_cmd_target`, las flechas, el saqueo, la liberación, la campana y los sitios sagrados.
- **Visión compartida dentro del equipo.** La niebla de cada jugador une las grillas de su equipo, como en AoE: se ve lo que ven los aliados.
- **Puertas.** Las de un aliado lo dejan pasar.
- **Victoria por equipo.** Gana el último equipo con hitos o capital. Los sitios sagrados cuentan por equipo: el equipo que los tiene todos.
- **Tributo entre aliados.** Comando `tributo` con una comisión, como en AoE.
- **Reglas en datos.** `reglas.json → equipos`: visión compartida, tributo y su comisión, y cómo se reparten los sitios.

### 2. Mapas para N jugadores
- **Tamaño según la cantidad de jugadores.** `reglas.json → mapa_tam_por_jugadores`: 2→128, 3–4→176, 5–6→208, 7–8→240.
- **Bases.** En un círculo alrededor del centro, a la misma distancia, con ángulos repartidos parejo. Con equipos, los aliados van juntos (vecinos en el círculo) o mezclados, según se elija.
- **Equidad sin simetría exacta.** Con 6 o más jugadores, la simetría de la grilla no alcanza: rotar 60° no cae en casillas enteras. Cada base recibe el mismo kit en coordenadas locales, orientadas hacia el centro: frutos, bosque, piedra, arcilla, sitios. El terreno se aplana alrededor de cada base igual que hoy.
  - Una prueba mide la equidad con 50 semillas: distancia por camino al centro y a los recursos disputados (±10 %) y recursos alcanzables en los primeros 5 minutos.
- **Lo disputado escala con los jugadores.**
  - Un sitio sagrado por jugador más uno central.
  - La arcilla del centro y los ingenios, en anillo.
  - Los techos de lo disputado de la economía (`v3/04`) son por jugador.
- **Formas de agua para N jugadores:**
  - `cruce` pasa a ser un río por cada par de bases vecinas o un lago central;
  - `anillo` es un foso alrededor del centro, que ya sirve;
  - `islas` da una isla por jugador y bajíos al vecino y al centro;
  - `fortines` pone un recinto por base;
  - los peñascos van entre bases.
- **Campañas:** siguen con su relieve real y sus posiciones fijas.

### 3. IA en equipo
- Elegir un rival: el enemigo más cercano o el más débil, según el estilo. La `Pacífica` sigue sin atacar ninguna base.
- Defender a un aliado cuando atacan su base, y unirse a su ataque si está cerca.
- Pedir y dar tributo cuando le sobra y al aliado le falta.

### 4. Interfaz
- **Menú.** Lista de lugares (2 a 8), y en cada uno: humano o IA, civ, equipo, dificultad, estilo y color. Hay atajos: "1v1", "2v2", "3v3", "Todos contra todos (6)".
- **Colores.** 8 colores de equipo bien distinguibles; el estandarte y el disco toman el color del jugador.
- **HUD y minimapa.** Puntaje por equipo, aliados con el borde de su color en el minimapa, panel de tributo y aviso cuando atacan a un aliado.

### 5. Rendimiento
- **Objetivo:** 6 jugadores × 150 unidades a ×4 de velocidad dentro del presupuesto de 100 ms por tick.
- **Medición:** `tests/bench.gd` con 6 jugadores.
- **Si no alcanza:** caminos con caché por región y niebla por bloques.

## Orden (después de la economía)
| Paso | Qué | Prueba |
|---|---|---|
| 1 | Equipos en la simulación: hostilidad única, visión compartida, puertas aliadas, victoria por equipo | Determinismo; partida 2v2 de IA |
| 2 | Generador para N bases: círculo, kit local y lo disputado que escala | Equidad con 50 semillas, de 3 a 8 jugadores |
| 3 | Formas de agua y mapas especiales para N | `mapas_smoke` con 4 y 6 jugadores |
| 4 | IA en equipo y tributo | Torneo 3v3 y todos contra todos con 6 |
| 5 | Menú de lugares, colores e interfaz | Autotest con 6 jugadores |
| 6 | Rendimiento con 6 | `bench` con 6 jugadores |

La economía nueva se implementa desde ya pensando en N jugadores: dueño de cada pozo de arcilla, techos por jugador y nada que suponga "el rival" en singular.
