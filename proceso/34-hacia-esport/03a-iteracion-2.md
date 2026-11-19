# 34 · 03a · Iteración 2, frente 2a

> Pedido: los cambios 1, 2 y 6 de la [revisión](02-revision-iteracion-1.md) (§5) y la empalizada (7): golpe del aldeano, hitos de 150/180/210 s con la III a 100 de piedra, empalizada a 8 y un sumidero de la IV que no se agote.

## Qué cambió

| # | Cambio | Dónde |
|---|---|---|
| 1 | La carga de la kona y del guerrero de gaša pasa de `carga` a `carga_golpe`. `aldeano.carga` sigue siendo la capacidad. | `data/civs/mapuches.json`, `etiopia.json`, `Sim._hit` |
| 2 | Hitos de 150, 180 y 210 s. La III pide 100 de piedra (antes, 200). Los `costo_extra` de cada pueblo (mita, riqueza, fama) no cambian. | `data/edades.json` |
| 7 | Empalizada: 8 de madera por tramo. Mapuches: 4 (antes, 2). | `data/edificios.json`, `mapuches.json` |
| 6a | Las tres repetibles no tienen tope. Cada compra cuesta 50 % más que la anterior (`repite.compuesto`): 400, 600, 900, 1350… | `data/tecnologias.json`, `Sim.tech_cost` |
| 6b | Mercado: el piso del precio baja de 40 a 10. Al piso, 100 de alimento dan 7 de riqueza. | `reglas.mercado.minimo` |
| 6c | Guardia de distancia: común a todos en la IV, se entrena junto al hondero. Cuesta 350 A y 100 M, sin riqueza; ocupa 2 de población; 190 PV, 17 de ataque y alcance 6. Tiene arte por pueblo (arco, honda o jabalina) y glifo. | `data/unidades.json`, `arte_animaciones.json`, `iconos.json`, `ui/iconos.gd` |
| 6d | La IA, en la IV, entrena las dos guardias. Si le sobran más de 2500 de alimento o de madera, por encima de la meta y de lo que pide su próxima repetible, los vende aunque tenga riqueza. | `reglas.ia_sumidero`, `sim_ai._sink_buys` y `_trade` |
| — | La fácil levanta el hito con 3 constructores, no con 4 (ver la primera victoria). | `reglas.dificultades.facil` |

## Medidas

**El golpe del aldeano.** Hay una prueba nueva en `tests/jugabilidad.gd`: un aldeano ataca a un explorador enemigo. Con el código de antes, la prueba también pasa (de 70 a 20 de vida), pero tira 7 SCRIPT ERROR. En headless, Godot sigue después del error: la línea de la carga se saltea y el daño se aplica. Entonces el aldeano sí pegaba, y el arreglo saca el error sin cambiar el daño.

**Sumidero de la IV.** `tools/sumidero_iv.gd`, 2v2 de 45 minutos, semilla 11. Las dos partidas ya llevan los hitos y la empalizada nuevos ([antes](pruebas-2a/sumidero-antes.txt), [después](pruebas-2a/sumidero-despues.txt)).

| | Tawantinsuyu, al final | Tawantinsuyu, promedio en la IV | Guaraníes, al final | Repetibles | Guardias |
|---|---|---|---|---|---|
| Antes (revisión: 17 643 al final) | **28 031** | 8715 | 2340 | 5 + 2 | 5 + 1 |
| Después | **1977** | 2158 | 3633 | 8 + 5 | 6 + 0 |

- Una primera versión vendía todo lo que pasara de 2500 y la IA nunca juntaba para la sexta repetible, que cuesta 3037. Ahora no vende lo que pide la próxima.
- **Ojo:** lo que sobra pasa a la riqueza. Tawantinsuyu termina con 15 436 de riqueza (antes, 13 591), porque la riqueza todavía no tiene sumidero en la IV.
- La meta era menos de 5000 de promedio, y se cumple. Pero es una sola semilla.

**Primera victoria.** `tools/primera_victoria.gd`, 8 semillas.

| Versión | Gana |
|---|---|
| Con los hitos nuevos, sin ajuste ([salida](pruebas-2a/primera-victoria-sin-ajuste.txt)) | 3 de 8 |
| Lo mismo, con los hitos de antes en `edades.json` ([salida](pruebas-2a/primera-victoria-hitos-viejos.txt)) | 6 de 8 |
| Hitos nuevos y la fácil con 3 constructores en el hito | **7 de 8** |

Con los hitos más cortos, la fácil llegaba antes a la II y defendía el primer ataque con 3 o 4 soldados en vez de 0 o 1. La diferencia es de 3 semillas, y las defensas cambian de verdad. Por eso no la tomamos por fase de ids. El arreglo toca solo a la fácil.

**`micro_matriz`.** No la corrimos: el combate no cambia (el golpe del aldeano ya hacía daño). La guardia de distancia es nueva y queda sin medir en la matriz.

## Pruebas

- `test_determinism`: OK, **hash 366120853** (antes, 1417676642).
- `bench`: 9,27 ms de promedio y 58,7 ms en el peor tick, con un presupuesto de 100.
- OK: `jugabilidad`, `juego_tardio` (con 4 controles nuevos: sin tope, costo compuesto y la guardia de distancia en tres pueblos), `casillas`, `grilla`, `iconos` y `civ_smoke` (sin errores).
- Autotest con mapuches: OK. La captura no muestra nada raro.

## Tropiezos

- La revisión decía que el aldeano «no pega». En headless sí pegaba, con un error en cada golpe.
- Quisimos medir la primera victoria en una copia de main con `git worktree`, pero el permiso no lo dejó correr. La comparación salió de cambiar `edades.json` en el worktree propio y volverlo atrás.
