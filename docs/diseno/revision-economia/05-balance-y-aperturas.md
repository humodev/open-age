# 05 — Balance y aperturas

Revisión del equipo de diseño (2026-11-13). Mirada de jugador competitivo: aperturas, tiempos de avance de edad y cómo juega la IA. No se tocó código ni datos.

## Respuesta corta al autor

**No: hoy los mapuches no dependen del malón para la riqueza, y ese no es el motivo de que les vaya mal.** El `saqueo` mapuche da **kulliñ**, no riqueza (`civs/mapuches.json` → `modulos.saqueo.recurso`). La riqueza de la edad I sale de los mismos yacimientos neutrales que usan todos. En la apertura les sobra riqueza: a los 8 minutos tienen 306 de banco (mediana) y el hito II pide 200. Lo que les falta es **alimento**, como a casi todos. Etiopía está peor: a los 8 minutos junta 389 de riqueza que no gasta, con 33 de alimento.

La pregunta sí destapa una incoherencia de diseño: la matriz (`03`) promete "riqueza por malón", y `05` exige "al menos una vía propia" de riqueza, pero la única vía propia mapuche es el parlamento de la edad IV.

## Método

Corrí scripts propios en el scratchpad de la sesión (`apertura.gd`, `medio.gd`, `mini.gd`, `ia_variante.gd`, `territorio.gd`). Los cambios se aplicaron en memoria y el repo no se tocó.
- **Apertura**: cada civ contra dos rivales en llano, montaña y río; 10 minutos; una foto cada 2 minutos.
- **Mini torneo**: una civ contra las otras cinco, ida y vuelta, 20 minutos, 10 partidas por variante. Con n = 10, el ruido es de ±2 victorias, así que solo leo diferencias grandes.
- **Origen de la riqueza**: dónde se recolecta cada unidad de riqueza.

## Aperturas de los primeros 8 minutos (IA normal, hoy)

Medianas de 6 partidas por civ.

| Civ | De qué vive | Aldeanos m4 / m8 | Banco a m8 | Edad II (≤10 min) |
|---|---|---|---|---|
| Guaraníes | Arbustos y después roza (45 madera, 550 de alimento, deja yerbal de riqueza) | 18 / 29,5 | A 483, R 51 | 6/6, ~8:20 |
| Palmares | No paga aldeanos: la fama los trae y el alimento se acumula | 12 / 20 | A 496, R 61 | 6/6, ~8:00 |
| Mapuches | Arbustos y granjas. Corral (75 m) a los 10 aldeanos, segundo lof (110 m) a los 16 | 17,5 / 27 | A 47, R 306, kulliñ 71 | 5/6, ~7:50* |
| Tawantinsuyu | Mit'a por aldeano, caminos y qollqa. Es la que más aldeanos tiene | 20 / 31,5 | A 36, R 202 | 5/6, ~9:40 |
| Ayutthaya | Arbustos y arrozales (+45 % junto al agua). Sin riqueza propia en la edad I | 18 / 29 | A 140, R 140 | 3/6, ~9:20 |
| Etiopía | Gult (120 a + 80 m) a los 10 aldeanos y otro a los 16. Jinete noble (70 a + 35 r) | 16,5 / 26 | **A 33, R 389** | **2/6, ~9:50** |

*Los mapuches promedian 7:50 por dos partidas de río a las 5:00. En el mini torneo a 20 minutos su edad II cae entre 9:30 y 10:00.

**Cuellos de botella comunes:**
1. **El alimento manda en la edad I.** El hito II cuesta 400 de alimento, lo mismo que 8 aldeanos. Con `carga` 10 se camina mucho, y las granjas cuestan 60 de madera justo cuando la madera también escasea. Las dos civs que esquivan el problema (roza guaraní, Palmares sin aldeanos pagos) son las que más rinden.
2. **La campana paraliza la economía.** En varias fotos aparecen de 15 a 31 aldeanos refugiados (16 = dos lof × 8). `_alarm` toca la campana con 2 enemigos cerca y solo la levanta tras 10 s sin enemigos. Una incursión de 3 unidades frena toda la economía por minutos.
3. **El ahorro congela al ejército.** `_wants_hito` corta la producción militar mientras se ahorra para el hito.

## Mapuches: qué es diseño y qué es IA

**Diseño**
- La riqueza propia no existe hasta la edad IV, y el malón alimenta un recurso que ya sobra en la edad I.
- **Los edificios que cuentan para la victoria son frágiles.** El lof tiene 1600 de vida (el centro, 2400) y los rewe, 1800 a 2200 (iglesia y wat, 3000; amba, 4200; Gondar, 5000). No tienen torre. El "no hay capital" se vuelve "hay tres objetivos blandos".
- **El kulliñ ahoga a mitad de partida.** Un corral rinde 8 por minuto. El hito III pide 60, el IV 100 y cada kona 35. En `medio.gd`, a los 15 minutos tienen **A 1582 y R 890 guardados con 30 a 43 de kulliñ**: la IA ahorra para el rewe III y no produce ejército.

**IA**
- `_hito_type` elige `hitos[0]` en la edad II, suponiendo que es la opción económica. En los mapuches `hitos[0]` es `rewe_malon` (+10 % de velocidad). Son la única civ que no recibe +10 % de recolección en la edad II.
- Los lof extra no entrenan aldeanos (la IA usa un solo "centro"). El enjambre no se juega.
- La IA gasta kulliñ en kona sin reservar lo que pide el hito siguiente.

**Experimentos** (mini torneo, destrucción + puntos sobre 10):

| Variante | Resultado |
|---|---|
| Base | 1 + 1 |
| IA elige lonko | 1 + 2 |
| IA entrena aldeanos en todos los lof | 2 + 2 (edad II 60 a 90 s más tarde) |
| Corral rinde 8 de riqueza + rewe con 3000 de vida | 1 + 2 |
| Corral rinde 14 de kulliñ y la IA hace dos corrales | 1 + 2 |
| Lo anterior + rewe más baratos en kulliñ + lonko | 2 + 2 |

**Lectura:** ninguna variante económica mueve a los mapuches de forma clara. Su apertura no es peor que la de otras. Pierden en el medio juego por puntos (menos población) o por destrucción de edificios blandos. Lo que más pesa es el combate y la fragilidad, más que la riqueza. En el torneo de escala ya subieron a 4/10, coherente con un problema de ritmo y de pelea más que de economía.

## Etiopía: qué es diseño y qué es IA

**Diseño**
- **El gult cobra alimento en el momento en que falta alimento, y paga en riqueza, que sobra.** Cuesta 200 en total y rinde 32 por minuto (18 r + 14 a): se repaga en unos 6 minutos y le saca 2,4 aldeanos a la apertura. Encima, la civ no puede gastar esa riqueza: el mercado llega en la edad II.
- El jinete noble (70 a) es la unidad de choque de la edad I y se come el alimento del hito.

**IA**
- Hace los dos gult a los 10 y 16 aldeanos y entrena nobles en la edad I.
- Resultado: en el mini torneo base, **4 de 10 partidas terminan en la edad I a los 20 minutos**, y el resto avanza hacia las 11:30.

**Experimentos**

| Variante | Edad II | Resultado |
|---|---|---|
| Base | ~11:30 o nunca | 1 + 2 |
| IA sin gult ni noble en la edad I | ~9:40 | 3 + 2 |
| Gult de 130 madera que rinde 20 a + 12 r | **~4:20 en 7/10** | 3 + 2 |

El costo del gult es la palanca. Con 4:20 se pasa: llega a la edad II casi el doble de rápido que el resto. Hay que buscar un punto medio.

## Propuestas (medibles)

**Mapuches**
1. `hitos[0]`: invertir el orden a `["rewe_lonko", "rewe_malon"]`. Es el arreglo inmediato. A largo plazo, la IA debería leer una etiqueta `"eje": "economia"` en el hito.
2. Riqueza propia temprana: corral con `"renta": {"riqueza": 6}`, o el saqueo partido en 12 % de kulliñ y 6 % de riqueza (esto requiere que `saqueo` acepte varios recursos). Así se cumple `05` y el malón tiene el sentido que promete `03`.
3. Kulliñ: `corral` de 8 a **12** por minuto, `tope` de 120 a **150**, `costo_extra` de 60 a **40** en los rewe III y de 100 a **70** en los IV.
4. Fragilidad: vida de los rewe de 1800–2200 a **2800**; lof de 1600 a **1900**.
5. IA: reservar el kulliñ del próximo hito antes de entrenar kona. Que los lof extra entrenen aldeanos recién desde la edad II.

**Etiopía**
1. `gult`: `costo` `{"madera": 100, "alimento": 40}`, `renta` `{"alimento": 18, "riqueza": 12}`. Objetivo: edad II entre 6:30 y 8:00.
2. IA: primer gult a los 14 aldeanos y el segundo en la edad II. Nada de jinete noble en la edad I salvo amenaza; la unidad base de la edad I pasa a ser el jabalinero.

**IA común**
1. Campana: refugiar como máximo a 3 aldeanos por enemigo y levantarla a los 5 s.
2. Ahorro: no congelar el ejército más de 60 s. Si lo que falta es un recurso de renta (kulliñ, mit'a, fama), no ahorrar.

## Dependencia territorial

Medición actual (`territorio.gd`, 12 partidas a 15 minutos): la riqueza tomada de yacimientos a más de 20 casillas de la base es **0 % hasta el minuto 10 y 0 a 5 % al 15**. La IA ni siquiera disputa el centro: `find_resource` busca a 40 casillas del centro propio, y el centro del mapa queda a unas 42. Si el centro pasa a ser *la* fuente (salinas, ferias), la IA no va a ir, y un humano que lo controle deja sin recurso a un rival que no tiene a dónde ir. El autor tiene razón: no puede ser determinante.

### 1. Techo de riqueza disputable por edad

| Edad | Máximo de riqueza desde lugares disputables | Regla de control |
|---|---|---|
| I | 10 % | El hito II (200 r) se paga entero con lo de la base |
| II | 25 % | El hito III (600 r) se paga con fuentes seguras en ≤ 5 min con 6 aldeanos |
| III | 40 % | — |
| IV | 50 % | El centro acelera, pero no es condición |

"Seguras" son los yacimientos de la base, la renta propia de la civ y el mercado. Hoy cada jugador tiene 2 yacimientos de 1400 a 10 casillas y uno a 18: 4200 en total, suficiente para los hitos (2000) pero no para un ejército caro. Está bien que el ejército caro de la edad IV obligue a salir.

### 2. Mecanismos de remontada
- **Rendimientos decrecientes para quien controla.** Sitios sagrados: el primero rinde 18 por minuto y los siguientes 12 y 8. En salinas o ferias, más de 5 aldeanos propios en el mismo punto recolectan al 60 %. Los yacimientos centrales siguen siendo agotables (1400) para que el control se gaste.
- **Mercado como válvula real.** Hoy, una venta al `minimo` (25) con 30 % de comisión da 17 de riqueza por cada 100: es una válvula muerta. Propongo `minimo` 60 y `paso` 3, que dan al menos 42 por cada 100. Queda caro pero es una salida.
- **Fuentes seguras más caras.** Cada civ debería tener desde la edad II un edificio de renta (gult, corral, barrios, aqllawasi) que rinda entre el 50 y el 70 % de un aldeano en un yacimiento disputado (~12 a 18 r por minuto por 150–200 de costo), sin territorio en juego.

### 3. Cómo medirlo en el torneo
- **Origen de la riqueza en cada partida**: sumar al informe del torneo el reparto entre base, disputada, renta, mercado y sitios por edad, con la lógica de `territorio.gd`. Criterio: respetar los techos de la tabla.
- **Prueba del golpe**: opción `--golpe=10` que, en el minuto 10, le quita a un jugador el centro (si ya tiene hito) o todo lo que tenga en la región central, y le da los sitios al rival. Con 4 semillas por cruce:
  - el castigado gana entre el **20 y el 40 %**. Por debajo del 10 %, el punto es determinante; por encima del 45 %, el centro no importa;
  - su ingreso de riqueza vuelve al 60 % del previo en 3 minutos o menos;
  - su próxima edad se demora 3 minutos o menos.
- **Prueba sin centro**: un jugador no puede recolectar a más de 25 casillas de su base. Tiene que llegar a la edad III antes del minuto 16.

## Criterios de validación de los cambios

- `tests/torneo.gd -- --minutes=30 --seeds=4`: cada civ entre **7 y 13 victorias de 20** (destrucción más puntos), en dos torneos seguidos.
- Edad II, mediana por civ, entre **6:30 y 9:00**, con no más de 2 minutos entre la más rápida y la más lenta (hoy Etiopía no llega en el 40 % de los casos).
- Banco de riqueza a los 8 minutos de 250 o menos (mediana). Hoy Etiopía tiene 389 y los mapuches, 306.
- Mapuches: ningún tramo de más de 90 s con más de 800 de alimento y ejército sin crecer.
- Aldeanos refugiados: no más de 60 s acumulados en los primeros 10 minutos, salvo un ataque real (5 enemigos o más).
- Separar diseño de IA: correr cada cambio de datos con la IA actual y con la IA corregida. Si la civ solo mejora con la IA corregida, el problema era la IA.
