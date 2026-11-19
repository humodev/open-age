# Recursos del mapa: dónde están y cuánto hay

Pedido del autor (ronda 8): «Analizaría en general los recursos: dónde están y qué cantidad.
Siento que estamos bastante por debajo de Age en un mapa normal». Antes de cualquier ventaja
para el 1vN, revisar el mapa: recursos y tamaño.

Herramientas nuevas:

- `tools/recursos_mapa.gd`: por terreno, 2, 4 y 8 jugadores y tamaño, lo que hay por jugador y
  a qué distancia de la base más cercana (cerca ≤ 20 casillas, media ≤ 40, lejos el resto).
  `--resumen=1` promedia los terrenos. Salidas: `recursos-antes.txt` y `recursos-despues.txt`.
- `tools/recursos_partida.gd`: partida IA contra IA sin vista (1v3 experta por defecto); cada
  minuto anota qué recurso le falta a cada uno para lo próximo grande (el hito o la maravilla),
  y al final lo juntado, lo que queda en el mapa y las vetas nuevas.

## 1. El mapa de hoy (antes)

Por jugador, promedio de dos semillas. El detalle por terreno está en `recursos-antes.txt`.

| Mapa | Lado | Casillas/j | Madera | Alimento natural | Piedra (c/m/l) | Riqueza (c/m/l) |
|---|---|---|---|---|---|---|
| 1v1, llano | 128 | 8 192 | 145 000 | 6 300 | **1 600** (800/800/0) | 3 400 (2 400/0/1 000) |
| 1v1, río / valle / selva | 128 | 8 192 | 70–210 mil | 6 100 | **1 200** | 2 400–2 900 |
| 1v1, islas | 128 | 8 192 | 26 000 | 4 700 | **800** | 3 400 |
| 4, normal (todos) | 176 | 7 744 | 37–115 mil | 4 800 | **1 600** (1 600/0/0) | 4 300 (3 300/0/1 000) |
| 4, chico / grande | 136 / 216 | 4 624 / 11 664 | 72 / 92 mil | 4 800 | **1 600** | 4 300 |
| 8, normal | 240 | 7 200 | 30–111 mil | 4 800 | **1 600** | 4 300 |

Lo que muestra:

- **La piedra es la misma en todo el mapa y en todos los terrenos: 1 600 por jugador, toda en
  casa.** El tamaño no suma nada; con 3 o más jugadores no hay piedra lejos ni disputada. En
  el 1 contra 1 la segunda veta de casa casi nunca entraba (iba pegada a la primera y el lugar
  no estaba libre): cada uno tenía una de casa y la del centro. Con río, valle o selva, la del
  centro caía al agua y se perdía (1 200); en islas, 800.
- **La riqueza** son 3 400–4 300, casi todo en casa, igual en todos los terrenos.
- **La madera sobra**: 30 000–225 000 por jugador. **El alimento natural** (arbustos, caza y
  rebaño, 4 800–6 300) ya es más que en AoE; después vienen las granjas.
- **El tamaño:** 7 200–8 200 casillas por jugador en un mapa normal, como AoE2 (7 000) y
  probablemente por debajo de AoE4. Chico y grande cambian el lado, pero solo cambia la
  madera del borde: los recursos son los mismos.

## 2. Lo que pide el juego

| Para | Alimento | Madera | Piedra | Riqueza |
|---|---|---|---|---|
| Hito de la II | 500 | – | – | 300 |
| Hito de la III | 1 000 | – | 200 | 600 |
| Hito de la IV | 1 800 | – | 400 | 1 200 |
| **Hasta la IV** | **3 300** | – | **600** | **2 100** |
| Maravilla | – | 1 500 | 1 500 | 1 500 |
| **IV + maravilla** | 3 300 | 1 500 | **2 100** | 3 600 |
| Centro (cada uno; la experta hace 2 más) | – | 400 | 300 | – |
| Torre / fortaleza | – | 50 / 200 | 150 / 450 | – |
| Mejoras con piedra (3) | – | 350 | 550 | 200 |
| **Economía de 60 min (estimada)**: IV, maravilla, 2 centros, 3 torres, 1 fortaleza, mejoras, sin muralla | ~3 300 + tropa | ~4 000 + tropa | **~4 100** | ~3 800 + tropa |

Con 1 600 en el mapa más 100 al empezar, **la IV y la maravilla (2 100) no entran**, ni hablar
de una economía de 60 minutos (~4 100). Lo dijo el constructor: el inca pasó 34 minutos en la II
con 10 000 de madera esperando 200 de piedra. Lo mismo dicen los dos expertos de la ronda
(jugabilidad competitiva): subir la piedra a unos 3 000, con una veta central disputada, porque
el boom, la torre, la III y la IV salen de la misma bolsa. Ellos proponen también que la III
pida poca piedra o ninguna; eso es un costo de edad y lo decide el autor (no se tocó).

## 3. Comparación con Age of Empires

Por jugador, en el mapa de referencia. **(aprox.)**: de memoria, sin fuente a mano; el orden de
magnitud es seguro, el número exacto no.

| | Raíces hoy | Raíces nuevo | AoE2 DE, Arabia | AoE4, Dry Arabia |
|---|---|---|---|---|
| Lado del 1v1 | 128 | 128 | 120 (tiny) | ~160 (micro) (aprox.) |
| Casillas por jugador | 7 200–8 200 | igual | 6 000–7 200 | ~12 000 (aprox.; casillas más chicas) |
| Piedra en casa | 800–1 600 | 2 000 (+1 200 a media distancia) | 1 750 (5 × 350) | ~2 000–3 000, una veta grande (aprox.) |
| Piedra lejos o disputada | 0–800 | 1 200 escalada (+vetas de la III y la IV: 1 800) | ~1 400 (aprox.) | ~2 000–4 000 (aprox.) |
| **Piedra total** | **1 600** | **4 400 + 1 800** | **~3 150** | **~5 000 o más (aprox.)** |
| Oro / riqueza en casa | 2 400–3 300 | igual | 5 600 (7 × 800) | ~3 000–3 600, una veta grande (aprox.) |
| Oro / riqueza lejos | 1 000 | 2 200 escalada (+1 000 en la IV) | ~6 400 (aprox.) | ~4 000–6 000 (aprox.) |
| Alimento natural | 4 800–6 300 | igual | ~2 700 (8 ovejas, 2 jabalíes, ciervos, 6 arbustos) (aprox.) | ~4 000 (ovejas, ciervos, jabalíes, arbustos de 200) (aprox.) |
| Madera | 30–225 mil | igual | decenas de miles | decenas de miles |
| Piedra para edades + maravilla | 2 100 | 2 100 | 1 000 (solo la maravilla) | 0 en edades; maravilla grande (aprox.) |

La cuenta clave: en AoE2 hay unas **3 veces** la piedra que pide la maravilla, y las edades no
piden piedra; en AoE4 las edades tampoco. Nosotros pedíamos **2 100** (III, IV y maravilla) y
dábamos **1 600**. El oro también está muy por debajo (AoE2 ~12 000), aunque la riqueza tiene
otras fuentes (sitios, mercado, yerbal, tributos). El tamaño del mapa no es el problema: por
jugador estamos como AoE2.

## 4. Lo que cambió (todo en `data/`; el generador solo lee)

`data/reglas.json → recursos_mapa` y `terrenos.<t>.minerales_pct`; `data/recursos.json`.

1. **Piedra de casa**: dos vetas de 1 000 (antes 800), y en el 1 contra 1 la segunda entra
   (estaba pegada a la primera).
2. **Piedra a media distancia**: una veta propia de 1 200 a 25 casillas, del lado de la piedra.
3. **Lejos y disputado, escalado con el mapa**: `roca_lejos` y `riqueza_lejos` son 1 200 por
   jugador con 7 500 casillas por jugador y cambian en proporción (un 4 chico da 60 %, un 4
   grande 155 %). Con 3 o más, entre cada par de bases vecinas hay una veta de piedra y una de
   riqueza que se disputan (el sitio sagrado queda a un tercio hacia el centro). En el 1 contra
   1, la piedra del centro y una riqueza nueva del otro lado.
4. **Vetas nuevas por edad** (`vetas_por_edad`): al llegar a la III, una de piedra de 800; a la
   IV, una de piedra de 1 000 y una de riqueza de 1 000, propias, a 16 casillas de la capital.
   Solo en escaramuza.
5. **Carácter de cada terreno** (`minerales_pct`, piedra/riqueza): montaña 140/110, mesetas y
   sierra 130/100, valle 120/100, altiplano 120/120 (seco y pobre en madera, rico en mineral),
   fortines 110/100, llano y río 100/100, islas 90/100, bosque 80/90, bosque templado 80/100,
   delta 80/110, selva 70/90 (mucha madera, poca piedra).
6. Si el lugar de una veta cae al agua o en otra cosa, se busca en espiral (antes se perdía).

No cambió: madera, alimento natural, tamaños de mapa, costos de edades y de la maravilla.

## 5. Después

Promedio de los 13 terrenos, por jugador (`--resumen=1`; detalle en `recursos-despues.txt`).
Cerca/media/lejos en cientos.

| Mapa | Casillas/j | Piedra antes | Piedra después (c/m/l) | Riqueza antes | Riqueza después (c/m/l) |
|---|---|---|---|---|---|
| 1v1 | 8 192 | 1 400 | **4 600** (20/25/0) | 3 000 | **4 700** (24/0/22) |
| 4 chico | 4 624 | 1 600 | **4 000** (21/18/0) | 4 300 | **5 000** |
| 4 normal | 7 744 | 1 600 | **4 500** (20/12/12) | 4 300 | **5 400** |
| 4 grande | 11 664 | 1 600 | **5 100** (20/12/18) | 4 300 | **6 000** |
| 8 chico | 4 608 | 1 600 | **4 000** | 4 200 | **5 000** |
| 8 normal | 7 200 | 1 600 | **4 400** | 4 200 | **5 300** |
| 8 grande | 10 952 | 1 600 | **5 000** | 4 200 | **5 900** |

Más las vetas de la III y la IV: 1 800 de piedra y 1 000 de riqueza por jugador que llega.
Por terreno, en un 4 normal: selva 3 000 de piedra, montaña 6 100, llano 4 400. En islas la
riqueza lejana cae al agua y no entra (4 300): queda como mapa pobre en riqueza.

### Partidas IA contra IA (experta, llano normal, semilla 7, 45 minutos)

`tools/recursos_partida.gd`. «Min sin alcanzar»: minutos en que no le alcanzaba ese recurso para
el próximo hito o la maravilla (cuenta también el ahorro normal; sirve para comparar).

| | Antes | Después |
|---|---|---|
| **1v3** (el solo cae a los 21 min en las dos) | piedra en el mapa 6 400 → 719 a los 21 min | 17 600 → 15 165; 7 vetas nuevas |
| 1v3, edades del equipo de 3 | IV a los 18 y 21, III a los 19 | igual (IV 18 y 21, III 19) |
| **2v2, 45 min** | piedra del mapa **agotada** (6 400 → 0); 3 de 4 con 25–28 min sin piedra para lo próximo | quedan **2 911** de 17 600; los que ganan, 11–12 min sin piedra |
| 2v2, piedra juntada por jugador | 2 200–3 700 | 4 400–6 800 |
| 2v2, maravillas | 1 | **2** (el equipo ganador, las dos) |
| 2v2, riqueza en el mapa al final | 3 764 | 6 007 |

¿Alguien se traba? **Antes sí, por piedra**: en el 2v2 el mapa se quedaba sin piedra antes de
los 45 minutos y solo una maravilla salió. **Después, no por piedra**: sobra en el mapa y salen
las dos maravillas del equipo que gana. Lo que más falta ahora es riqueza (los dos que pierden
pasan 44–45 min cortos de riqueza, con la base atacada), pero queda riqueza en el mapa: es
pelea, no escasez. La madera sobra en las dos. El 1v3 no llega a la economía tardía: la experta
sola cae a los 21 minutos con o sin el cambio (eso es la IA y el 1vN, no el mapa).

Nota: el 2v2 «después» se jugó con la veta de media distancia a 22 casillas; después pasó a 25
por la prueba de equidad con 8 (no cambia la cantidad).

## Pruebas

- `tests/test_determinism.gd`: DETERMINISMO OK, **hash nuevo 718068252** (ticks 3000).
- `tests/equidad.gd`: OK (con la veta media a 22, con 8 bases quedaba en el borde de la medida de
  22 casillas: 37 % de diferencia de roca; a 25, 0 %).
- `tests/bench.gd`: promedio 9.41 ms, peor 62.85 ms (presupuesto 100).
- `tools/primera_victoria.gd --seeds=7,21,3 --min=30`: gana 2 de 3 (21 y 3; la 7 sin terminar).
- `tests/equipos.gd` (30 min): EQUIPOS OK, sin fuego amigo; fortines con 4 y 6 sin encerrados.

## Commits

- `496d638` Recursos del mapa: herramientas de medida, piedra y riqueza por jugador según tamaño y terreno, vetas nuevas en la III y la IV.
- Veta de media distancia a 25 casillas (equidad con 8), mediciones antes y después.
- Documento y resultados de las pruebas (este commit).

## Para el autor

- Los costos de las edades no se tocaron. Si se quiere, el paso siguiente que proponen los
  expertos es que la III pida menos piedra (hoy 200; la IV 400).
- La riqueza quedó en 5 000–6 000 por jugador, por debajo del oro de AoE2 (~12 000, aprox.); si
  en las partidas largas falta riqueza, el número a subir es `recursos_mapa.riqueza_lejos`.
- Las vetas nuevas aparecen sin aviso (para no sumar mensajes); se ven en el mapa.
