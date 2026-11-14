# Informe de telemetría

13 partidas leídas de `/tmp/claude-1000/-mnt-games-01-Projects-open-age/481c6f08-db17-4268-bf0b-14788944cecc/scratchpad/tele2`.

## Totales por tipo

| Tipo | Sucesos | Por partida |
|---|---|---|
| rechazo | 829 | 63.8 |
| sin_camino | 250 | 19.2 |
| tick_lento | 51 | 3.9 |
| ocioso | 19 | 1.5 |
| trabada | 8 | 0.6 |
| ia_sin_ruta | 3 | 0.2 |

## Por civ

| Civ | Trabadas | Sin camino | Ociosos | Rechazos | IA sin lugar | IA sin ruta |
|---|---|---|---|---|---|---|
| - | 0 | 0 | 0 | 0 | 0 | 0 |
| ayutthaya | 0 | 4 | 0 | 97 | 0 | 0 |
| etiopia | 6 | 60 | 19 | 174 | 0 | 0 |
| guaranies | 0 | 1 | 0 | 89 | 0 | 0 |
| mapuches | 0 | 108 | 0 | 93 | 0 | 0 |
| palmares | 0 | 4 | 0 | 177 | 0 | 0 |
| tawantinsuyu | 2 | 73 | 0 | 199 | 0 | 3 |

## Órdenes rechazadas más frecuentes

| Qué | Veces |
|---|---|
| tawantinsuyu · Recursos insuficientes | 189 |
| palmares · Recursos insuficientes | 176 |
| etiopia · Recursos insuficientes | 164 |
| ayutthaya · Recursos insuficientes | 92 |
| guaranies · Recursos insuficientes | 89 |
| mapuches · Recursos insuficientes | 87 |
| tawantinsuyu · No se puede construir ahí | 10 |
| etiopia · No se puede construir ahí | 7 |
| ayutthaya · No se puede construir ahí | 5 |
| mapuches · No se puede construir ahí | 4 |
| etiopia · Población llena | 3 |
| mapuches · Población llena | 2 |
| palmares · No se puede construir ahí | 1 |

## Unidades que se rinden (tipo y orden)

| Qué | Veces |
|---|---|
| guerrero (orden atacar moviendo) | 4 |
| aldeano (orden recolectar) | 4 |

## Ticks lentos

51 ticks por encima del presupuesto; mediana 28 ms, peor 53 ms.

## Partidas

Lugares con más problemas: celdas de 8 casillas, por trabadas, caminos imposibles y ociosos.

| Partida | Terreno | Civs | Duración | Sucesos | Lugares con más problemas |
|---|---|---|---|---|---|
| altiplano-2j-578 | altiplano | ayutthaya, guaranies | 20:00 | rechazo 51, tick_lento 1 |  |
| bosque-2j-552 | bosque | etiopia, tawantinsuyu | 20:00 | rechazo 77, tick_lento 8 |  |
| bosque_templado-2j-591 | bosque_templado | tawantinsuyu, etiopia | 20:00 | sin_camino 86, rechazo 71, trabada 4, tick_lento 4, ia_sin_ruta 3 | (44, 76): 73; (84, 52): 16; (44, 84): 1 |
| delta-2j-630 | delta | etiopia, tawantinsuyu | 20:00 | rechazo 65, sin_camino 18, tick_lento 6, ocioso 1 | (52, 52): 10; (60, 52): 8; (28, 20): 1 |
| fortines-2j-669 | fortines | tawantinsuyu, etiopia | 19:27 | rechazo 88, sin_camino 29, ocioso 15, tick_lento 8 | (100, 100): 25; (76, 76): 7; (108, 92): 4 |
| islas-2j-656 | islas | ayutthaya, guaranies | 20:00 | rechazo 27, tick_lento 1 |  |
| llano-2j-513 | llano | tawantinsuyu, etiopia | 20:00 | rechazo 72, tick_lento 11, trabada 4, ocioso 3 | (60, 68): 5; (68, 68): 2 |
| mesetas-2j-617 | mesetas | guaranies, ayutthaya | 20:00 | rechazo 43, sin_camino 5, tick_lento 2 | (60, 12): 4; (92, 108): 1 |
| montana-2j-526 | montana | mapuches, palmares | 20:00 | sin_camino 103, rechazo 94, tick_lento 1 | (36, 36): 91; (60, 12): 12 |
| rio-2j-539 | rio | guaranies, ayutthaya | 20:00 | rechazo 65, tick_lento 5 |  |
| selva-2j-604 | selva | mapuches, palmares | 20:00 | rechazo 62, sin_camino 9 | (68, 116): 4; (60, 12): 2; (92, 92): 2 |
| sierra-2j-643 | sierra | palmares, mapuches | 18:39 | rechazo 59, tick_lento 3 |  |
| valle-2j-565 | valle | palmares, mapuches | 20:00 | rechazo 55, tick_lento 1 |  |
