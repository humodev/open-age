# Informe de telemetría

13 partidas leídas de `/tmp/claude-1000/-mnt-games-01-Projects-open-age/481c6f08-db17-4268-bf0b-14788944cecc/scratchpad/tele4`.

## Totales por tipo

| Tipo | Sucesos | Por partida |
|---|---|---|
| sin_camino | 215 | 16.5 |
| rechazo | 154 | 11.8 |
| tick_lento | 49 | 3.8 |
| ia_sin_ruta | 27 | 2.1 |
| trabada | 8 | 0.6 |
| ocioso | 4 | 0.3 |

## Por civ

| Civ | Trabadas | Sin camino | Ociosos | Rechazos | IA sin lugar | IA sin ruta |
|---|---|---|---|---|---|---|
| - | 0 | 0 | 0 | 0 | 0 | 0 |
| ayutthaya | 0 | 0 | 0 | 21 | 0 | 0 |
| etiopia | 5 | 30 | 0 | 31 | 0 | 0 |
| guaranies | 0 | 13 | 3 | 15 | 0 | 0 |
| mapuches | 3 | 4 | 0 | 22 | 0 | 0 |
| palmares | 0 | 15 | 0 | 21 | 0 | 0 |
| tawantinsuyu | 0 | 153 | 1 | 44 | 0 | 27 |

## Órdenes rechazadas más frecuentes

| Qué | Veces |
|---|---|
| palmares · Recursos insuficientes · train:hondero (IA) | 12 |
| tawantinsuyu · Recursos insuficientes · train:hondero (IA) | 9 |
| tawantinsuyu · Recursos insuficientes · build_line:camino (IA) | 8 |
| tawantinsuyu · Recursos insuficientes · build:granja (IA) | 8 |
| guaranies · Recursos insuficientes · train:hondero (IA) | 7 |
| mapuches · Recursos insuficientes · build:granja (IA) | 6 |
| mapuches · Recursos insuficientes · train:hondero (IA) | 6 |
| tawantinsuyu · No se puede construir ahí · build:granja (IA) | 6 |
| etiopia · No se puede construir ahí · build:granja (IA) | 6 |
| etiopia · Recursos insuficientes · build:granja (IA) | 6 |
| palmares · Recursos insuficientes · build:deposito (IA) | 5 |
| etiopia · Recursos insuficientes · train:hondero (IA) | 5 |
| tawantinsuyu · Recursos insuficientes · build:deposito (IA) | 5 |
| ayutthaya · No se puede construir ahí · build:granja (IA) | 5 |
| ayutthaya · Recursos insuficientes · build:granja (IA) | 4 |

## Unidades que se rinden (tipo y orden)

| Qué | Veces |
|---|---|
| aldeano (orden recolectar) | 6 |
| guerrero (orden atacar moviendo) | 2 |

## Ticks lentos

49 ticks por encima del presupuesto; mediana 30 ms, peor 54 ms.

## Partidas

Lugares con más problemas: celdas de 8 casillas, por trabadas, caminos imposibles y ociosos.

| Partida | Terreno | Civs | Duración | Sucesos | Lugares con más problemas |
|---|---|---|---|---|---|
| altiplano-2j-578 | altiplano | ayutthaya, guaranies | 19:50 | rechazo 12, ocioso 3, tick_lento 1 | (116, 108): 2; (108, 108): 1 |
| bosque-2j-552 | bosque | etiopia, tawantinsuyu | 20:00 | ia_sin_ruta 27, rechazo 17, sin_camino 8, tick_lento 5 | (60, 12): 8 |
| bosque_templado-2j-591 | bosque_templado | tawantinsuyu, etiopia | 20:00 | sin_camino 66, rechazo 18, tick_lento 13, trabada 2, ocioso 1 | (44, 76): 42; (84, 52): 21; (76, 52): 3 |
| delta-2j-630 | delta | etiopia, tawantinsuyu | 20:00 | rechazo 11, tick_lento 5 |  |
| fortines-2j-669 | fortines | tawantinsuyu, etiopia | 20:00 | sin_camino 109, rechazo 12, tick_lento 11 | (100, 100): 76; (28, 44): 18; (108, 100): 11 |
| islas-2j-656 | islas | ayutthaya, guaranies | 13:32 | rechazo 5 |  |
| llano-2j-513 | llano | tawantinsuyu, etiopia | 20:00 | rechazo 17, tick_lento 3, trabada 3 | (60, 68): 3 |
| mesetas-2j-617 | mesetas | guaranies, ayutthaya | 20:00 | sin_camino 13, rechazo 9 | (60, 12): 10; (92, 108): 3 |
| montana-2j-526 | montana | mapuches, palmares | 20:00 | sin_camino 19, rechazo 10, tick_lento 1 | (68, 116): 15; (60, 12): 4 |
| rio-2j-539 | rio | guaranies, ayutthaya | 20:00 | rechazo 10, tick_lento 4 |  |
| selva-2j-604 | selva | mapuches, palmares | 20:00 | rechazo 15, tick_lento 3 |  |
| sierra-2j-643 | sierra | palmares, mapuches | 18:38 | rechazo 11, tick_lento 2 |  |
| valle-2j-565 | valle | palmares, mapuches | 20:00 | rechazo 7, trabada 3, tick_lento 1 | (84, 60): 3 |
