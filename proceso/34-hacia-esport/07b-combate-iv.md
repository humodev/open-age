# 34 · 07b · El jinete contra la masa de honderos en la IV

**Pedido:** lo que dejó abierto [07a](07a-combate.md#lo-que-queda-abierto). En la IV con compras, 30 honderos le ganaban 4/5 a 13 jinetes sin micro y 3/5 escalonando: el +1 de la herrería I y el +25 % de la herrería, veterano y élite llevan al hondero de 8 a 10 de ataque, y contra la armadura 4 del jinete pasa de 4 a 6 de daño (+50 %). El jinete solo gana +10 % de vida. Meta: 2/5 o menos en los dos modos, sin tocar la II.

## Qué cambió

| Qué | Antes | Ahora | Dónde |
|---|---|---|---|
| Montados de élite (IV) | +10 % ataque, +5 % vida | lo mismo **y +1 de armadura contra distancia** a la función choque | `tecnologias.elite_montados` |

El efecto `armadura` va por función (no hay por línea sin tocar `src/sim`), así que también lo recibe el **guerrero** de quien compre montados de élite. Es el otro contador del hondero, así que refuerza el triángulo en vez de torcerlo; queda anotado en `_doc_niveles`. La herrería de armadura de distancia ya incluía al jinete (función choque): la primera opción del pedido ya estaba, pero `--compras` no la compra.

## Cómo se eligió (`tools/micro_matriz.gd --reaccion=400 --variantes=5 --compras`, [correr.sh](pruebas-07b/correr.sh))

| A contra B (modo de A) | II antes | IV antes | Armadura 5 del jinete: II / IV | **Élite +1: II / IV** |
|---|---|---|---|---|
| 30 honderos contra 13 jinetes (nada) | 0/5 (quedan 3,2 j.) | 4/5 | 0/5 (6,2) / 1/5 | **0/5 (3,2) / 1/5** |
| 30 honderos contra 13 jinetes (escalonar) | 1/5 | 3/5 | 0/5 / 2/5 | **1/5 / 2/5** |
| 10 honderos contra 5 jinetes (nada / escalonar) | 0/5, 0/5 | 0/5, 0/5 | igual | **igual** |
| 30 honderos contra 26 guerreros (escalonar / nada) | 5/5, 3/5 | 5/5, 3/5 | igual | **igual / 5/5, 3/5** (quedan 22,6 en vez de 25) |
| 26 guerreros / 22 lanceros contra 13 jinetes | 5/5, 5/5 | 5/5, 5/5 | igual | **igual** |

Las dos cumplen en la IV. La armadura 5 en la unidad le da más al jinete también en la II (le quedan 6,2 en vez de 3,2); la de élite deja la II **idéntica** (es de la IV), así que es la elegida. El bono del jinete contra distancia no se probó a fondo: es plano (los porcentajes no lo escalan) y no crece con los niveles sin código nuevo.

## La matriz por defecto con compras ([II antes](pruebas-07b/antes-matriz-e2.txt), [II después](pruebas-07b/p_elite1-matriz-e2.txt), [IV antes](pruebas-07b/antes-matriz-e4.txt), [IV después](pruebas-07b/p_elite1-matriz-e4.txt))

- **II:** sin una sola diferencia.
- **IV, el triángulo se lee:** lancero 9 contra jinete 5, 5/5; guerrero 9 contra hondero 10, 4/5; hondero 10 contra lancero 8, 5/5.
- **IV, la micro C2 sigue pagando:** mezcla 5+5 contra 10 guerreros, 4/5 sin micro y 5/5 con mantener+escalonar.
- Cambian solo los casos con guerreros contra honderos, a favor del guerrero y poco: 10 honderos kiteando contra 10 guerreros 1/5 → 0/5 (escalonar sigue 3/5); la mezcla con foco 4/5 → 3/5.

## Pruebas

- `tests/test_determinism.gd`: OK, hash 3059812827 ([salida](pruebas-07b/test-determinismo.txt)).
- `tests/micro.gd`: corre entero ([salida](pruebas-07b/test-micro.txt)); E: 8 jinetes contra 10 honderos, quedan 8/8.
- `tools/primera_victoria.gd`, semillas 7, 21, 3, 1, 2, 4, 5, 6: **7 de 8**, igual que en 07a ([salida](pruebas-07b/primera-victoria.txt)).
