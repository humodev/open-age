# 61 · Balance después de los tamaños y el movimiento (2026-11-28)

> **Pedido:** una ronda de balance después de los tamaños (proceso/59) y el movimiento nuevo (proceso/60). (1) El torneo del hito sobre main con más semillas (`--seeds=4`). (2) Diagnosticar cada pueblo fuera de la banda con mediciones dirigidas, no con suposiciones; para Ayutthaya, probar la hipótesis del 59 (más arrozales de 2×2 en la franja del bono del agua). (3) Arreglos chicos en `data/`, uno por causa. (4) Volver a medir solo los pueblos tocados (`--civ`) y un torneo final. Meta: los seis entre 35 y 65 %.

## Resultado

`tests/torneo.gd -- --minutes=30 --seeds=4`: 60 partidas, 20 por pueblo (con 20 partidas, cada partida mueve 5 puntos). Las semillas 0 y 1 son las del torneo 59. El torneo tarda unos 70 minutos con un solo proceso.

| Pueblo | Torneo 59 (2 semillas, antes del movimiento) | **Torneo 61 antes** ([salida](pruebas/torneo_61_antes.txt)) | Medición dirigida (`civ_diag --civ`, 20 partidas) | **Torneo 61 después** ([salida](pruebas/torneo_61_despues.txt)) |
|---|---|---|---|---|
| Ayutthaya | 90 % | **75 %** | 50 % con el bono del agua en 25 | **45 %** |
| Etiopía | 30 % | **25 %** | 40 % (con Ayutthaya en 25) | **35 %** |
| Guaraníes | 70 % | 60 % | | 50 % |
| Mapuches | 60 % | 65 % | | 65 % |
| Palmares | 30 % | 50 % | | 50 % |
| Tawantinsuyu | 20 % | **25 %** | 55 % con la reserva de mit'a | **55 %** |

Los seis quedan entre 35 y 65 %. Etiopía y los mapuches quedan en los bordes (ver «Lo que queda»). La IV llegó en 51 de 60 partidas (eran 49).

## Causas y arreglos

### Ayutthaya: el arrozal de 2×2 casi siempre tiene el bono

`tools/civ_diag.gd` cuenta ahora, al final de cada partida, las granjas del pueblo estudiado, cuántas tienen el bono del sitio (agua o ladera) y el alimento de las granjas. Las mismas 20 partidas del torneo, con el arrozal de 2×2 y con el de antes (`--set="ayutthaya/edificios/granja/tam=[3,3]"`):

| Arrozal | Granjas por partida | Con el bono | Alimento de granjas | Gana |
|---|---|---|---|---|
| 3×3 (+35 %) ([salida](pruebas/diag_ayutthaya_3x3.txt)) | 18,4 | 7,5 (**41 %**) | 10 715 | 8 de 20 |
| 2×2 (+35 %) ([salida](pruebas/diag_ayutthaya_2x2.txt)) | 17,6 | 14,7 (**84 %**) | 12 042 | 15 de 20 |
| 2×2 (+20 %) ([salida](pruebas/diag_ayutthaya_bono20.txt)) | 18,5 | 14,9 (81 %) | 11 199 | 7 de 20 |
| 2×2 (**+25 %**) ([salida](pruebas/diag_ayutthaya_bono25.txt)) | 16,3 | 13,8 (84 %) | 10 707 | 10 de 20 |

**Confirmada la hipótesis del 59.** El bono vale si el arrozal toca la franja de 2 casillas alrededor del agua. Con el arrozal de 2×2, el doble de arrozales entra en esa franja: el 84 % tiene el bono, antes el 41 %. Con eso, Ayutthaya llegaba a la IV en 15 de 20 partidas (antes, en 11).

**Arreglo:** `ayutthaya.json → edificios.granja.bono_agua_pct` de 35 a **25**, y lo mismo en el texto del arrozal y en el `_doc` del khlong. El bono medio por arrozal queda en 21 % (era 14 % con el de 3×3 y 29 % con el de 2×2 a +35 %). Con +20 % bajaba a 35 %, en el borde. El tamaño no se tocó (D-033).

### Tawantinsuyu: la IA no guardaba la mit'a de la IV

Primero, en civ_diag ([salida](pruebas/diag_tawantinsuyu.txt)): los incas juntan **más** que sus rivales (37 624 contra 34 947), pero llegan a la IV en **2 de 20** partidas (los rivales, en 12). Para ver qué los frena, civ_diag cuenta ahora, desde el minuto 15 y por lado, los minutos sin alcanzar algún recurso del hito siguiente. En 10 partidas ([salida](pruebas/diag_tawantinsuyu_faltas.txt)), lo que más falta para la IV es la **mit'a** (94 minutos, más que el alimento y la riqueza). Los rivales no tienen mit'a.

- Bajar la mit'a de los hitos de la IV de 150 a 120 no cambió nada: la IV llegó en 3 de 20 partidas y la falta de mit'a siguió igual ([salida](pruebas/diag_tawantinsuyu_mita120.txt)). Se volvió a 150.
- **Causa:** los talleres de tejido consumen 30 de mit'a por minuto cada uno, y la IA tiene 3 o 4. Mientras ahorra para el hito, la IA apartaba **60 fijos** (`sim_ai.gd`, un número en el código). Eso alcanzaba para los 60 de la II. Para los 120 de la III y los 150 de la IV, los talleres se comían el resto.
- **Arreglo:** mientras ahorra, la IA aparta la mit'a que pide el hito siguiente según los datos (el más caro de los dos con `cost_of`). Ya no queda un número en el código. La IV llega en **13 de 20** partidas y el pueblo gana el **55 %** ([salida](pruebas/diag_tawantinsuyu_reserva.txt)).

**El andén** también pasó a 2×2 en el proceso 59, pero la IA no lo construye (no figura en `sim_ai.gd`). No influye en el torneo y no se tocó. Su bono de ladera vale si una sola casilla está en ladera o en alto. Con 2×2 eso pasa en menos lugares que con 3×3: **le pega más al jugador que a la IA**. Lo mide la próxima prueba con jugador.

### Etiopía: le falta alimento para la IV

Con Ayutthaya en 25 y antes del arreglo inca, Etiopía gana 8 de 20 (40 %, [salida](pruebas/diag_etiopia.txt)). Llega a la IV en 4 de 20. Lo que más le falta es alimento: 206 minutos sin el alimento de la IV, contra 133 de los rivales. Tiene **más granjas** que los rivales (20,8 contra 17,4 por partida) pero junta **menos** de ellas (7 577 contra 10 545). En una partida con `tools/viajes.gd` contra los mapuches en llano ([salida](pruebas/viajes_etiopia_mapuches.txt)), su viaje medio con alimento pasa de 2 a 7 s después del minuto 20 (el de los mapuches, 1 s): las granjas quedan lejos del depósito cuando la corte se muda. No se tocó. El 35 % entra en la banda, y el arreglo es de la IA (dónde planta las granjas cuando la corte se muda), no de un número.

## Lo que queda

- **Etiopía (35 %):** las granjas lejos del depósito cuando se muda la corte. Medir con `viajes.gd` en varias semillas y llevar las granjas a la corte nueva o levantar un granero junto a ellas.
- **Mapuches (65 %):** en el borde, como en el 53 (70 %) y el 59 (60 %). Ganan casi todo por puntos (1 de 13 por hitos). No hay una causa medida para tocar.
- **Andén de 2×2:** medir el bono de ladera con alguien jugando.

## Cambios

- `data/civs/ayutthaya.json`: arrozal `bono_agua_pct` 35 → 25, con su texto y el `_doc` del khlong.
- `src/sim/sim_ai.gd` (rama `tawantinsuyu`): la reserva de mit'a mientras ahorra sale del costo del hito siguiente (`cost_of`), no de 60 fijos.
- `tools/civ_diag.gd`: granjas con bono y alimento de las granjas por partida; minutos sin alcanzar el hito siguiente por edad y recurso (desde el minuto 15), en la partida y en los totales.

## Pruebas

| Prueba | Resultado |
|---|---|
| `tests/test_determinism.gd` | OK, **hash 3617052205, igual que el 60**: la prueba usa la capa común, sin pueblo ([salida](pruebas/determinismo.txt)) |
| `tests/bench.gd` | 10,05 ms por tick de promedio, el peor 73,7 (el presupuesto es 100; el 60 daba 9,9) ([salida](pruebas/bench.txt)) |
| `tests/civ_smoke.gd` | Sin errores ([salida](pruebas/civ_smoke.txt)) |
| `tests/campaign_smoke.gd` | 30 escenarios, sin errores ([salida](pruebas/campaign_smoke.txt)) |
| `tests/tutorial_letra.gd` | Al pie de la letra, victoria a las 9:31. Indefenso, derrota con motivo a las 7:55 ([letra](pruebas/tutorial_letra.txt), [indefenso](pruebas/tutorial_indefenso.txt)) |
| `tests/arte_guerra.gd` | Las cinco misiones ganadas, con oro ([salida](pruebas/arte_guerra.txt)) |
| `tests/movimiento_qol.gd --estricto` | MOVIMIENTO: OK, 12 de 12 salen del lado de la reunión ([salida](pruebas/movimiento_qol.txt)) |
| `tests/salud_ia.gd` | 2 avisos, los mismos que en el 60: guaraníes sin mercado al minuto 15 y Palmares con recursos parados. Ayutthaya ya no avisa ([salida](pruebas/salud_ia.txt)) |

No hubo cambios en la interfaz: no hizo falta el autotest con ventana.

## Tropiezos

- La copia de trabajo no tenía `.godot/`: se copió la de main (en disco) y se reimportó.
- Un `timeout 590` de más alrededor de una medición la habría cortado a la mitad. Se paró solo ese proceso, buscado por su línea de comando entera, y se relanzó.
- Bajar el costo inca (150 → 120) no servía: la causa era la reserva de la IA, no el costo. Por eso se mide qué falta antes de tocar un número.

## Commits

- El commit de los cambios, los torneos, las mediciones y la documentación.
