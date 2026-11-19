# 01d · Primera victoria con los mercados neutrales

**Pedido:** con el comercio integrado, `tools/primera_victoria.gd` (principiante contra la fácil, semillas 7, 21, 3, 1, 2, 4, 5 y 6) bajó de 6 de 8 a 3 de 8. Encontrar la causa y arreglarla en la causa.

## Diagnóstico

- `primera_victoria.gd` acepta ahora `--sin_mercados` (pasa la opción a la simulación).
- Con `--detalle=1`, la semilla 7 con y sin mercados es idéntica hasta las 14:50; ahí la IA tiene 4 honderos cerca en vez de 5, y de ahí en adelante se separa (con mercados, la primera oleada no rinde y queda sin terminar).
- Los mercados se ponen al final del generador, sin talar: el mapa no cambia. Lo único que cambian es `next_id`: los dos neutrales toman 2 ids y todo lo que se crea después queda corrido en 2. Eso mueve la fase de los `(tick + id) % k` (búsqueda de blanco, retargeteo, cada 3 y cada 4 ticks).
- Prueba: sin mercados y sumando 2 a `next_id` donde irían, el resultado es **exactamente** el de con mercados (3 de 8, los mismos minutos y bajas). Sumando 1 da 6 de 8. No son caminos, ni recursos, ni la rendición, ni la IA: es la fase de los ids.

## Arreglo

`Sim.ID_APARTE` (1 << 28) e `id_aparte`: mientras vale más de 0, `_new_entity` toma de ahí y no de `next_id`. `sim_comercio._spawn` lo usa para los neutrales (1v1 y N jugadores). La partida queda igual a la sin mercados salvo lo que hacen los mercados de verdad.

## Resultados

| | Semillas 7, 21, 3, 1, 2, 4, 5, 6 |
|---|---|
| main antes del comercio / `--sin_mercados` | 6 de 8 |
| con mercados (5f287b2) | 3 de 8 |
| sin mercados + 2 ids | 3 de 8 (idéntico) |
| **con el arreglo** | **6 de 8** (pierde 3 y 2, como sin mercados) |

Pruebas: `test_determinism` OK, hash nuevo **289763931**; `comercio.gd` OK; `equidad.gd` OK; `bench.gd` 9,28 ms de promedio; autotest con guaraníes, captura `pruebas-1d/autotest.png` revisada (los dos neutrales en el minimapa).

**Tropiezo / ojo:** la primera victoria es muy sensible a la fase de los ids (6 → 3 de 8 por correr 2 ids). Mide el plan, pero una diferencia de 2 o 3 semillas entre dos versiones puede ser ruido de este tipo; conviene mirar también con `--salto` de ids o más semillas antes de concluir.

Salidas en `pruebas-1d/`.
