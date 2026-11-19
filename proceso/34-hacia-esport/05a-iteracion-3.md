# 34 · 05a · Iteración 3, frente 3a

> Pedido: los cambios 1 y 2 de la [revisión 2](04-revision-iteracion-2.md) (§3 y §4, alternativa B): sitios con guarnición y a la vista, hito en obra más vulnerable, la III a 800 A / 500 R / 100 P. Además, el balance de los mapuches (70 % en el torneo 41) y del Tawantinsuyu (34 %).

## Qué cambió

| Cambio | Dónde |
|---|---|
| **Sitios con guarnición.** Un sitio rinde solo si el equipo dueño tiene 2 o más de población militar a 4 casillas. Si no la tiene, la renta y la cuenta de victoria se congelan: no pasan al rival ni se reinicia la cuenta. | `reglas.sitios.guarnicion_pob`, `guarnicion_radio`; `SimMods._sacred`, `Sim.site_guarded` |
| **Sitios a la vista.** Todos los jugadores ven 4 casillas alrededor de cada sitio. | `reglas.sitios.vision_publica`; `Sim._update_fog`, `SimFog.site_vision` |
| **La IA y la guarnición.** Deja 3 de población en cada sitio suyo, como mucho el 40 % del ejército. Esas tropas no salen en oleadas. Si persiguen a más de 10 casillas, vuelven sin pelear. Los sitios ajenos con tropa los desafía `_contest_sites`, con fuerza proporcional. Si están vacíos, va el grupo chico, y los que tienen enemigos los evita. | `reglas.ia_guarnicion`; `SimAI._garrison_step` |
| **Hito en obra al 50 %.** En obra llega como mucho a la mitad de sus PV. Al terminar suma el resto y conserva el daño recibido. | `reglas.hito_en_obra_pv_pct`; `Sim._obra_top` |
| **La III cuesta 800 A / 500 R / 100 P.** Los `costo_extra` de cada pueblo se suman igual (`SimData.cost_of`). | `data/edades.json` |
| **Tawantinsuyu.** El taller de tejido convierte la mit'a en 28 de riqueza, no en 22. | `data/civs/tawantinsuyu.json` |

La victoria por sitios sigue contando desde el minuto 15 (`cuenta_desde_ms` 900 000), y con 10 minutos de cuenta gana a los 25:00. `tests/opciones_partida.gd` suma un caso: con 3 sitios sin guarnición durante 25 minutos, no se gana y la renta es 0.

## ¿Por qué la experta no atacaba el hito en obra?

Sí lo atacaba, pero llegaba tarde. `_hit_hito` manda al ejército en cuanto lo ve: en el `tools/hito_en_obra_ia.gd` de la revisión, la tropa sale a 74–80 casillas de distancia. Pero la IA levanta la III en unos 60–100 s, con 4 o 5 constructores, y la marcha toma 60–70 s. Además, la orden necesita 6 tropas como mínimo. Con el hito al 50 %, la experta ahora pasa hasta 231 s cerca del hito rival en obra, y más de 45 s en 4 de 6 partidas (antes, de 0 a 18 s), pero en 6 partidas no se cae ninguno: siempre lo defienden ([hito-en-obra.txt](pruebas-3a/hito-en-obra.txt)). Sirve para el jugador humano, que puede salir antes.

## Medidas

El método es el de la revisión: [partidas.gd](pruebas-3a/partidas.gd.txt), con 12 partidas 1v1 de 25 minutos, experta contra experta, en llano, y semillas 7, 11 y 3. El resumen es de [resumen.py](pruebas-3a/resumen.py).

| Lote | El que va atrás cobra (meta ≥ 20 %) | El primero en la III gana (meta ≤ 7 de 12) | III, mediana | Victorias por sitios |
|---|---|---|---|---|
| Revisión 2 | 4,5 % | 9 de 12 | 16:08 | 3 |
| Guarnición 3, sin correa ([lote](pruebas-3a/lote-guarnicion3.txt)) | 5,0 % | **6 de 12** | **14:40** | 0 |
| Con `sitios_rival_min` 1 ([lote](pruebas-3a/lote-rival-min1.txt)) | 4,9 % | 8 de 12 | 15:19 | 0 |
| Con guarnición de 2 y `sitios_rival_min` 1 ([lote](pruebas-3a/lote-guarnicion2-rival-min1.txt)) | 2,7 % | 5 de 12 | 15:31 | 1 |
| **Final**: guarnición de 3 con correa ([lote](pruebas-3a/lote-final.txt)) | LOTE_ATRAS | LOTE_III | LOTE_MED | LOTE_SIT |

**Lo que no se cumple: la renta del que va atrás.** Una traza de mapuches contra guaraníes con la semilla 7 lo muestra:
- el que va adelante en edad también lleva de 2 a 3 veces más ejército (de 24 a 45 contra 5 a 15);
- con 3 de guarnición por sitio, le alcanza para tener los tres;
- el que va atrás toma un sitio y lo pierde, porque no gana la pelea chica.

Antes de la correa, además, su guarnición se iba detrás del rival y el sitio quedaba sin renta. Con la correa, guaraníes lo sostienen del 13 al 15, que es cuando van atrás. La regla es simétrica y hace lo que pide la alternativa B: un líder estirado tiene que pagar con ejército, y lo que tiene se ve. Pero en IA contra IA la diferencia de ejército pesa más que eso. Para llegar al 20 % hace falta que el que va atrás elija dónde pegar, y eso queda para un humano o para una IA que busque superioridad local.

## Balance

Con `tools/civ_diag.gd` (30 partidas, 30 minutos, las semillas y los terrenos del torneo):

| Pueblo | Torneo 41 | Con las reglas de 3a | Final |
|---|---|---|---|
| Mapuches | 70 % | **46 %** ([diag](pruebas-3a/diag-mapuches.txt)) | 46 % (no cambia nada mapuche) |
| Tawantinsuyu | 34 % | 30 % ([diag](pruebas-3a/diag-tawantinsuyu.txt)) | TAWA_FINAL ([diag](pruebas-3a/diag-tawantinsuyu-cumbi28.txt)) |

- **Mapuches.** Con las reglas nuevas ya quedan en la banda, sin tocar sus datos. La sospecha de la empalizada no aplica a la IA: no la levanta nunca (la IA solo amuralla con piedra y los mapuches no tienen muralla). Sus hitos tardan 77, 92 y 106 s, contra 84, 115 y 134 s de los rivales, porque llegan con la misma cantidad de constructores y antes. Lo que los bajó fueron la III más barata, que también ayuda al rival, y la guarnición.
- **Tawantinsuyu.** Pierde 0 de 6 contra Etiopía y 1 de 6 contra Palmares. Con Palmares, 4 veces lo destruyen después de un apuro a los 3:30–4:40, cuando tiene 1 o 2 soldados. Su II es la más rápida (6:03), pero la III llega a las 16:26 (en 24 de 30 partidas) y la IV solo en 6 de 30. Junta lo mismo que los mapuches (32 206 contra 32 175), pero tiene menos riqueza (5789 contra 7119). El ajuste mínimo es en esa riqueza: el cumbi pasa de 22 a 28.

## Otras medidas

- **Primera victoria** (`tools/primera_victoria.gd`, 8 semillas): **8 de 8** ([salida](pruebas-3a/primera-victoria.txt)).
- **Determinismo:** OK, hash **HASH_FINAL** (antes, 366120853). **Bench:** promedio de 9,17 ms y peor de 58 ms (el presupuesto es 100).
- `tests/sitios.gd`, `opciones_partida.gd`, `facil_sitios.gd`, `jugabilidad.gd` y `civ_smoke.gd`: OK. El autotest con mapuches da OK ([captura](pruebas-3a/autotest-mapuches.jpg)).

## Tropiezos

- `tests/opciones_partida.gd` daba los sitios a un jugador sin tropa, y con la regla nueva ya no ganaba: se le suman 2 guerreros por sitio.
- La primera versión de la guarnición del que iba atrás perseguía al rival y se moría lejos del sitio (orden de ataque durante minutos). Se agregó la correa.
