# Ronda 8 · 07: rendimiento con 7 y 8 jugadores, paso 2 (caminos y listas de la IA)

> Pedido: lo que quedó del paso 1 (`04-rendimiento.md`). Los picos del 4v4 y del tct7 eran
> caminos (cada 5 ticks una IA volvía a mandar a todo su ejército y cada soldado recalculaba su
> A*) y quedaban recorridos de `sim.actives` en `sim_ai.gd`. El autor: «Probemos y hagámoslo bien.»
> Metas: p95 bajo 40 ms y ningún tick sobre 100 ms con 7 a 8 jugadores; ×4 hasta el minuto 30 del tct7.

Base: main con la iteración 1a (24bdd61, hash 3870415820). Medido con `tools/perfil_sim.gd`
(semilla 42, 40 minutos) en una copia aparte de main (`git worktree`) y en la rama.
Salidas: `rendimiento-caminos/perfil-antes.txt` y `perfil-despues.txt`.

## 1. Qué pasaba con los caminos (medido)

Al perfilador se le agregó el resumen de caminos por resultado y por tipo de orden:

| 4v4, main | llamadas | ms en total | ms cada una |
|---|---|---|---|
| A* que llega | 198 964 | 14 901 | 0,07 |
| A* parcial (destino encerrado) | 1 121 | 6 572 | **5,9** |
| Pedidos por órdenes «mover atacando» | 18 716 órdenes → 81 059 caminos | 22 761 | — |

- El A* que llega es barato (`AStarGrid2D` es nativo). Lo caro es **la cantidad**: 18 716
  órdenes de la IA en 40 minutos, 4,3 caminos cada una. Cada pensada mandaba otra vez a todo el
  ejército hacia la amenaza (que se había corrido una casilla) y se rearmaba el grupo.
- Y **los destinos encerrados**: con murallas (etapa 06) o un soldado metido entre edificios, el
  A* parcial recorre toda la zona alcanzable (6–9 ms en el mapa de 240). Un soldado que persigue a
  otro adentro de una muralla lo repite cada 8 ticks. Con `--lentos=4`, todos los caminos lentos
  eran de estos (439 de 439).

## 2. Qué se eligió y por qué

| Opción | Medición | Decisión |
|---|---|---|
| Campo de flujo por destino | BFS de 8 vecinos en GDScript: **160 ms** por destino (`eleccion/flujo.txt`) | No: cuesta más que los 60 A* que reemplaza |
| Un A* por grupo y los demás en formación | Ya existe (`SimGroups`, etapa 21): el núcleo usa un solo A*. El costo venía de rearmar el grupo en cada pensada y de los de afuera del núcleo | Se conserva, y se evita rearmarlo |
| Que la IA no vuelva a mandar si el destino no cambió | 4v4: órdenes «mover atacando» de 16 436 a 8 292; caminos 30,4 s → 19,8 s (`eleccion/4v4-1-solo-reenvio.txt`) | Sí |
| Caché por (región de origen, región de destino) | Con lo anterior: caminos 19,8 s → 10,3 s, ticks > 100 ms de 638 a 74 (`eleccion/4v4-2-…`) | Sí |
| Destinos encerrados recordados por región de destino | Peor: un origen en otra zona hacía que el A* hacia la casilla recordada recorriera todo igual (2364 parciales; `eleccion/4v4-3-…`) | No |
| … por región de origen y de destino | Parciales 3,5 s (de 6,6 s) | Sí |

(Las corridas de `eleccion/` son sobre la base anterior, d638536; cada cambio de resultado da otra
partida, así que se comparan sobre todo los totales de caminos.)

Caminos jerárquicos por regiones: no hicieron falta. La caché por regiones ya cubre el caso caro
(muchos caminos parecidos a la vez) y el A* nativo es barato para lo demás.

## 3. Qué cambió

1. **`SimAI._no_resend`** (`reglas.ia_reenvio`, `tolerancia` 2000 y `max_ticks` 300): al final de
   cada pensada, de las órdenes de marcha que la IA acaba de dar se saca a quien ya va al mismo
   lugar (a 2 casillas o menos) con la misma orden (mover, atacar en movimiento, suelto). Pasados
   30 s se lo vuelve a mandar igual. La orden queda sin nadie, se descarta.
2. **Caché de caminos en `SimMap.find_path`** (`reglas.caminos`): clave (jugador, región de 8×8 del
   origen, región del destino). Un camino guardado sirve a otro si entra en línea recta y libre a
   una de sus primeras 12 casillas y sale en línea recta y libre al destino desde una de las
   últimas 12 (en diagonal pide libres las dos vecinas, como la grilla). Invalidación: construir
   (casillas que se tapan, puertas, pesos) invalida todo; destruir un edificio invalida los que no
   llegaban; talar no invalida (se tala todo el tiempo); todo vence a los 150 ticks. Los caminos
   cortos (hasta 16 casillas) no usan la caché.
3. **Destinos encerrados**: si un A* de la misma región de origen hacia la misma región de
   destino no llegó, el siguiente va directo a la casilla más cercana que aquel alcanzó (y al
   destino si de ahí se ve en línea recta), sin volver a recorrer toda la zona.
4. **Los 11 recorridos de `sim.actives` que quedaban en `sim_ai.gd`** pasan a listas: enemigos
   militares y exploradores por dueño (`Sim.fighters_of`, nueva), sitios sagrados
   (`Sim.sacred_sites`, nueva), edificios neutrales (`buildings_of(-1)`) y `all_buildings()`. Donde
   se elige el más cercano, a igual distancia gana el de menor id, como al recorrer `actives`.
   No cambia el resultado (4v4 de 12 minutos: 1046660502 antes y después). El paso 1 hablaba de
   «unos 20»: eran 11 con `sim.actives`; los demás ya usaban `military()`/`all_buildings()`.
5. **Etiopía, la corte nueva**: un pico de 330 ms cada 50 ticks en el tct7 (minuto 23). Buscaba
   lugar probando ~200 casillas y cada una recorría `actives` (`_court_site_ok`). Ahora recorre las
   listas por dueño (mismo resultado: tct7 con el mismo hash) y, si no encuentra lugar, espera
   `ia_economia.corte_reintento_ticks` (600) antes de volver a buscar.

## 4. Antes y después

| Partida | Prom. ms | p95 ms | Peor ms | Ticks > 100 ms | IA prom / p95 | Caminos ms en total | ×4 alcanza hasta |
|---|---|---|---|---|---|---|---|
| 1v6 (main 22,8 min · rama 16,4) | 25,3 → **15,6** | 60,3 → **32,7** | 171 → 130 | 10 → **1** | 6,0 / 15,7 → 3,5 / 9,1 | 5 928 → 1 789 | min 13 de 23 → 13 de 17 |
| tct7 (40 min) | 34,7 → **32,6** | 66,7 → **59,4** | 156 → 128 | 12 → **5** | 9,1 / 23,7 → 7,2 / 17,8 | 5 974 → 4 323 | min 12 → **14** |
| 4v4 (40 min) | 46,9 → **40,6** | 100,5 → **76,9** | 474 → **205** | 1232 → **22** | 12,9 / 31,8 → 10,3 / 24,4 | 21 473 → 10 113 | min 10 → 11 |

Promedio por minuto (ms por tick):

| Minuto | 5 | 10 | 15 | 20 | 25 | 30 | 35 | 40 |
|---|---|---|---|---|---|---|---|---|
| tct7 main | 8,9 | 18,1 | 27,7 | 34,2 | 47,4 | 54,4 | 56,4 | 51,0 |
| tct7 rama | 8,5 | 16,9 | 26,4 | 36,6 | 42,8 | 51,0 | 47,7 | 50,0 |
| 4v4 main | 10,2 | 22,7 | 36,1 | 45,6 | 50,1 | 69,2 | 83,3 | 86,1 |
| 4v4 rama | 10,1 | 21,8 | 33,5 | 44,3 | 54,9 | 60,8 | 65,5 | 56,2 |

Las partidas no son las mismas jugada a jugada (cambia el resultado). Al minuto 40 del 4v4 quedan
842 unidades contra 1090; en tct7, 755 contra 703. El 1v6 termina antes (conquista a los 16,4
minutos contra 22,8). Caché del 4v4: 18 643 aciertos y 19 172 búsquedas.

`tests/bench.gd` (main → rama, uno detrás del otro):

| Prueba | Promedio | Peor |
|---|---|---|
| 200 unidades | 9,13 → 8,75 ms | 66,9 → 61,6 ms |
| 6 × 150 unidades | 25,8 → 26,1 ms | 51,8 → 54,4 ms |
| 6 IA, 20 min | 10,3 → 11,3 ms (último minuto 17,3 → 19,4) | 36,2 → 79,7 ms |

El «6 IA» es otra partida (393 unidades al final contra 345). Medido con los envoltorios del
perfilador, sus picos son `SimAI._economy` (la búsqueda de lugar para un centro nuevo,
`_expansion_site`, que ya está en main), no caminos; en esa partida se da y en la de main no. Con
la caché apagada da otra partida más (308 unidades, 9,9 ms). No se tocó en esta etapa.

## 5. Pruebas

- `tests/test_determinism.gd`: OK, hash **1947898069** (main 3870415820). Cambia porque los
  caminos salen de la caché (enganches en línea recta en lugar del A* de cada uno) y porque la IA
  ya no rearma el grupo de quien ya iba al mismo lugar.
- Hashes del perfilador a 40 minutos: 1v6 1484959102, tct7 3009845559, 4v4 154053497.
- `tests/jugabilidad.gd`: OK. `tests/equipos.gd` (2v2, 3v3 y todos contra todos, 30 min): OK, sin
  fuego amigo. `tests/civ_smoke.gd`: sin errores.
- `tools/primera_victoria.gd --seeds=7,21,3`: **2 de 3** (main también 2 de 3).
- `tools/micro_matriz.gd --variantes=3`: **las mismas victorias en las 36 peleas** que main; la
  micro C2 igual (la mezcla gana 3/3, escalonar y kitear a la línea pagan). Cambian 4 tiempos
  medios en menos de 3 s.
- `tests/grupos.gd` (marcha en formación): igual que main (24 militares 0,7 s de diferencia de
  llegada, 12 aldeanos a 40 casillas 0,3 s, a 6 casillas 3,8 s; todos llegan).
- Autotest con guaraníes: OK. Captura: `capturas/07-caminos-autotest.jpg`.

## 6. Tropiezos

- **El kiteo**: con la caché para todos los caminos, el escalonado de honderos contra guerreros
  pasó de 3/3 a 0/3 en la micro. En un camino corto el enganche elegía la casilla más avanzada del
  camino guardado y el que retrocedía salía para adelante. Arreglo: los caminos de hasta dos
  regiones van directo al A* (son baratos). Con eso la matriz da lo mismo que main.
- **Destinos encerrados por región de destino** empeoró: ver §2.
- **Fusión con main** (iteración 1a): dos conflictos en `sim_ai.gd` (`_aim_ground` junto a
  `_no_resend`; `_map_spot` con `can_take_sites` sobre `sacred_sites()`). Se midió todo de nuevo
  contra esa base.

## 7. Lo que falta y por qué

**Metas no alcanzadas:**

- *p95 bajo 40 ms con 7 a 8 jugadores*: 59 (tct7) y 77 (4v4). Se cumple en el 1v6 (33).
- *Ningún tick sobre 100 ms*: quedan 5 (tct7) y 22 (4v4) de 24 000, y 1 en el 1v6.
- *×4 hasta el minuto 30 del tct7*: alcanza hasta el 14; en el minuto 30 el promedio es 51 ms.

**Por qué:** los caminos ya pesan poco en promedio (0,2–0,45 ms por tick, 1 % del total). Lo que
queda es costo por entidad, que crece con el ejército: IA 7–10 ms, recolección ~6 ms, movimiento,
niebla, separación y tablas 2–3 ms cada uno. Para ×4 en el minuto 30 hay que bajar el tick a la
mitad. Lo siguiente, en orden:

1. Recolección cada 2 o 4 ticks por aldeano (la tasa no cambia de un tick a otro) o en código nativo.
2. Los picos que quedan: caminos parciales que todavía se hacen una vez por región (76–132 ms
   en un tick cuando muchos persiguen a la vez detrás de una muralla), órdenes con muchos
   `build`, y `_expansion_site` (40–60 ms al buscar lugar para un centro).
3. Recorridos de recursos (`sim.entities`) en la IA (`_expansion_site`, riqueza, reclamables):
   una lista de recursos por tipo los evitaría.

## Commits

d8cd839 perfilador (caminos por resultado y por orden) · 49d81b2 los 11 recorridos de la IA a
listas · d7f5477 caché por regiones y no reenviar · 5097643 destinos encerrados · a6e77b2 fusión de main ·
1eed32a caminos cortos sin caché · 92c3983 la corte nueva espera · 6596e53 `_court_site_ok` por listas.
