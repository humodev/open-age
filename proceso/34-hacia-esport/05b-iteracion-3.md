# 34 · 05b · Iteración 3, frente 3b: comercio, guardia de distancia y Palmares

**Pedido:** los cambios 3, 4 y 5 de la [revisión de la iteración 2](04-revision-iteracion-2.md#3-qué-tan-cerca-de-un-diseño-de-esport): comercio con rendimiento decreciente y escolta que suma al corte; guardia de distancia con alcance 5 y velocidad 1100, medida con 400 ms de reacción; guaraníes y Palmares en la II antes de las 8:30 de mediana.

## Qué cambió

| Qué | Antes | Ahora | Dónde |
|---|---|---|---|
| Saturación de una ruta | 10 libres, −3 % c/u, piso 60 % | **7 libres (baja desde el 8.º), −10 % c/u, piso 40 %** | `reglas.comercio.saturacion` |
| Corte de ruta | 3 de población militar enemiga y **ninguna** tropa propia o aliada | 3 de población **más que la escolta** propia o aliada del lugar | `sim_comercio.blocked_at` |
| Tope de comerciantes de la IA (normal, difícil, experta) | 16 | **12** | `reglas.dificultades.<n>.comercio.max` |
| Guardia de distancia | alcance 6000, velocidad 1200 | **5000, 1100** | `unidades.guardia_distancia` |
| Cuándo ahorra la IA para el hito | cuenta los aldeanos de afuera | cuenta también los de adentro (los **oficios** de Palmares) | `sim_ai.gd` (`inside_civ`) |
| `tools/micro_matriz.gd` | — | `--reaccion=MS`: las órdenes de micro de A salen MS después de decidirse | herramienta |

**Por qué el tope 12.** Con la saturación nueva y 16 comerciantes, el 2v2 quedaba en 46 % y 50 % ([s7](pruebas-3b/2v2-s7-tope16.txt), [s3](pruebas-3b/2v2-s3-tope16.txt)). En el 2v2 hay tres rutas: los dos neutrales y el mercado aliado. Con 16 comerciantes repartidos entre las tres, ninguna llega al 8.º y la saturación casi no se nota. Por eso bajamos el tope de la IA.

**Por qué los oficios.** Palmares no entrena aldeanos: le llegan con la fama, y de 2 a 5 están adentro, en los oficios. La IA empieza a ahorrar desde 13 aldeanos, pero contaba solo los de afuera. Por eso empezaba a guardar los 90 de fama del hito unos 2 minutos tarde, a las 6:15 y no a las 4:00. Primero probamos otra cosa: que Palmares no sacara tropa en la I, porque su mocambo hacía 8 honderos con madera. No sirvió: la madera se fue en 6 cuarteles y la II no se adelantó. Lo revertimos.

**Emboscada guaraní.** Ya pega +50 % al primer golpe desde el monte con sigilo (`modulos.sigilo.emboscada_pct`, +25 % con la asamblea). No la tocamos. Los guaraníes ya llegaban a la II antes de las 8:30: 6:52–7:47 contra mapuches.

## Metas medidas

| Medida | Meta | Resultado |
|---|---|---|
| 2v2 de 45 min, semilla 3 ([txt](pruebas-3b/2v2-s3.txt)) | 30–45 % después del 30 | **45 %**. El equipo que va atrás cobra 1865 (no lo pierde todo). Cortes: 8 al que lidera y 21 al otro |
| 2v2 de 45 min, semilla 7 ([txt](pruebas-3b/2v2-s7.txt)) | 30–45 % | **44 %**; gana el equipo 0 a los 38'. Al minuto 35, el que va atrás llevaba 516 cobrados. Todos los cortes los sufre el que va atrás |
| 1v1, semilla 7 ([txt](pruebas-3b/1v1-s7.txt)) | ≤ 15 % antes del 25 | **11 %** |
| Guardia de distancia escalonando contra 26 guerreros | que no gane 5/5 | **0/5**, con 400 ms y sin ellos |
| Guardia de distancia escalonando contra 5 guardias | que no gane 4/5 | **2/5** con 400 ms ([txt](pruebas-3b/micro-edad4-reaccion400.txt)), 1/5 sin reacción ([txt](pruebas-3b/micro-edad4-sin-reaccion.txt)). Con «mantener + escalonar», 2/5 y 0/5 |
| Palmares en la II ([antes](pruebas-3b/edades-antes.txt)) | mediana < 8:30 | **7:38**: 8:11, 7:53, 7:38, 6:52, 7:33, 7:38. Antes: 8:41, 8:44, 8:49, dos sin II a los 12' y 8:24 contra Etiopía |
| Guaraníes en la II | < 8:30 | 7:37 (sin cambios) |
| Primera victoria, 8 semillas ([txt](pruebas-3b/primera-victoria.txt)) | 5 de 8 o más | **7 de 8** (la 21 sin terminar) |

**Sigue abierto:**
- 30 honderos escalonando le ganan 5 de 5 a 26 guerreros, aun con 400 ms de reacción. Es el cambio 8 de la revisión 1 y no estaba en este frente.
- En la semilla 7, el bloqueo todavía lo gana el que tiene más ejército.
- El porcentaje de victorias de guaraníes y Palmares (50 y 54 %, techo 62 %) hay que medirlo en el próximo torneo: acá no corrimos ninguno.

## Pruebas

- `test_determinism`: OK. El hash sigue en 366120853, porque en los primeros 3000 ticks no hay comercio ni Palmares.
- `comercio.gd`: OK, con los casos nuevos: saturación 7/8/10/20 y «con una propia, 4 enemigos sí cortan».
- `equidad.gd`: OK.
- `micro.gd`: corre entera.
- `equipos.gd`, `civ_smoke.gd` y el autotest con guaraníes: ver el commit.

## Commits

3167051 (comercio), f4c124e (guardia y `--reaccion`), 932b0eb (tope 12), c9f6a92 (2v2 con tope 12), 60dcae1 (Palmares), 5dfb421 (matriz).
