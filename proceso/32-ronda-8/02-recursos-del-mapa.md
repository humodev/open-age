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
2. **Piedra a media distancia**: una veta propia de 1 200 a 22 casillas, del lado de la piedra.
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

RESUMEN_DESPUES

### Partidas IA contra IA (experta, llano normal, semilla 7, 45 minutos)

PARTIDAS_DESPUES

## Pruebas

PRUEBAS

## Commits

COMMITS
