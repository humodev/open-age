# 34 · 07a · Arreglos de combate de la revisión 3

**Pedido:** los cambios 1 y 4 de la [revisión de la iteración 3](06-revision-iteracion-3.md#3-qué-tan-cerca-de-un-diseño-de-esport): romper la masa de honderos (que 13 jinetes le ganen a 30 honderos a igual costo en la II, sin tocar el 10 contra 5) y darle un lugar a la guardia de distancia (que le gane a su presa, los lanceros, sin romper el resto).

## Qué cambió

| Qué | Antes | Ahora | Dónde |
|---|---|---|---|
| Jinete, armadura de distancia | 2 | **4** (el hondero le hace 3, no 5) | `unidades.jinete` |
| Guardia de distancia contra la línea | +6 (el de `reglas.bonos`) | **+18** (bono propio +12) | `unidades.guardia_distancia.bono` |
| Hondero, cadencia | 1750 | 1750 (sin cambio: se probó 2000 y no hizo falta) | — |

Los reemplazos de los pueblos (Kona montado, arquero guaraní, etc.) heredan los dos cambios: ninguno pisa esos campos.

## Cómo se eligió (`tools/micro_matriz.gd --reaccion=400 --variantes=5`, con `--parche`)

Se probaron cuatro parches ([correr.sh](pruebas-07a/correr.sh), [extra.sh](pruebas-07a/extra.sh)): armadura 4 sola, cadencia 2000 sola, las dos, y armadura 3. Edad II sin compras:

| A contra B (modo de A) | Antes | Armadura 3 | Cadencia 2000 | Armadura 4 + cadencia | **Armadura 4** |
|---|---|---|---|---|---|
| 30 honderos contra 13 jinetes (nada) | 5/5 | 2/5 | 3/5 | 0/5 | **0/5** (quedan 4,4 jinetes) |
| 30 honderos contra 13 jinetes (escalonar) | 3/5 | 0/5 | 3/5 | 0/5 | **0/5** |
| 10 honderos contra 5 jinetes (nada) | 1/5 | 0/5 | 0/5 | 0/5 | **0/5** (quedan 4,6 contra 3,4) |
| 10 honderos contra 5 jinetes (escalonar) | 0/5 | 0/5 | 0/5 | 0/5 | **0/5** |
| 30 honderos contra 26 guerreros (escalonar) | 5/5 | — | 4/5 | 4/5 | **5/5** |
| 10 honderos contra 9 guerreros (escalonar) | 1/5 | — | 2/5 | 2/5 | **1/5** |

La armadura 4 sola cumple la meta y es lo mínimo: solo toca al jinete. La cadencia sola no alcanza y además mueve al hondero contra todo. La armadura 3 todavía pierde 2 de 5 sin micro.

Guardia de distancia (edad IV con compras):

| 5 g. de distancia contra… | Antes (+6) | +12 en total | **+18** |
|---|---|---|---|
| 22 lanceros, sin micro | 0/5 (quedan 12,2) | 1/5 (quedan 6,8) | **4/5** (quedan 0,8) |
| 5 guardias, escalonar | 1/5 | 1/5 | **1/5** |
| 5 guardias, mantener+escalonar | 0/5 | 0/5 | **0/5** |
| 26 guerreros / 13 jinetes / 30 honderos | 0/5 | 0/5 | **0/5** |

El +12 que pedía la revisión (en total) no alcanza: deja 1 de 5 contra su presa. Con +18 le gana 4 de 5 y sigue perdiendo contra su contador (la guardia) y contra todo lo demás. Si se prefiere el +12 literal, es cambiar `bono.linea` de 12 a 6.

## La matriz por defecto, antes y después ([antes](pruebas-07a/antes-matriz.txt), [después](pruebas-07a/p_arm-matriz.txt))

Edad II, 400 ms, 5 variantes. De 36 peleas cambian **dos**, y solo en vivos: 5 jinetes contra 10 honderos (4/5 en las dos; quedan 4,0 en vez de 3,6) y 10 honderos escalonando contra 5 jinetes (0/5 en las dos).

- **El triángulo se lee igual:** lancero 9 contra jinete 5, 5/5; guerrero 9 contra hondero 10, 4/5; hondero 10 contra lancero 8, 5/5.
- **La micro C2 sigue pagando:** mezcla 5+5 contra 10 guerreros, 5/5 sin micro y 5/5 con mantener+escalonar.
- **El área:** sin cambio (hondero 10 contra catapulta+lanceros: 0/5 junto, 0/5 abierta, 1/5 esquivando; lancero 10 contra catapulta+honderos: 3/5 sin micro). Ojo: ya antes, con 400 ms, dispersarse no paga contra las catapultas; no es de este cambio.

## Lo que queda abierto

- **En la IV con compras, 30 honderos le siguen ganando a 13 jinetes** (4/5 sin micro, 3/5 escalonando; antes 5/5 y 5/5). Las mejoras de ataque del hondero (veterano y élite) se comen la armadura de más. Lo arregla una mejora de armadura de distancia para el choque, o subir la del jinete élite: está en las tecnologías, fuera de este frente.
- El 10 contra 5 en la II se movió un poco a favor del jinete (1/5 → 0/5 sin micro); ya lo ganaba.

## Balance (`tools/civ_diag.gd --seeds=3`, 30 partidas)

BALANCE_AQUI

## Pruebas

- `tests/test_determinism.gd`: OK, hash 3059812827 (igual: la prueba no llega a la II).
- `tests/micro.gd` ([salida](pruebas-07a/test-micro.txt)): corre; E. 8 jinetes contra 10 honderos, quedan 8 de 8.
- `tests/asedio.gd`: OK.
- `tools/primera_victoria.gd`, semillas 7, 21, 3, 1, 2, 4, 5, 6: **7 de 8** ([salida](pruebas-07a/primera-victoria.txt); la 21 queda sin terminar).

## Commits

COMMITS_AQUI
