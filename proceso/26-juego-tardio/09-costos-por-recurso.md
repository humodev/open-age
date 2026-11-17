# Qué cuesta qué: la riqueza (veterano de AoE4)

Fecha: 2026-11-16. Etapa 26. Respuesta al pedido del autor, mientras jugaba:

> "Tenemos que investigar mejor qué nos cuesta qué. Acumulo riqueza que debería gastar en mejoras, y las mejoras cuestan madera en general y poca riqueza, ¿no? ¿Qué dice el experto en AoE sobre eso?"

Sigue la voz y el criterio de [01-veterano-cantidades.md](01-veterano-cantidades.md). Las cifras de AoE4 son de mi experiencia de juego, no de una tabla: las que no sé con seguridad llevan [aprox].

## 0. La respuesta corta

Tenés razón a medias:
- **Que la economía cueste alimento y madera está bien.** En AoE4 es igual: las mejoras de recolección se pagan con alimento y madera para que todos puedan crecer. El oro no se toca para crecer.
- **Lo que estaba mal es la herrería y las mejoras militares de la II:**
  - pedían casi nada de riqueza (25 a 30 cada una);
  - las armaduras se pagaban con madera, que en la II es justo lo que falta.

  En AoE4 la herrería es alimento y oro, con más oro que alimento. El oro es la llave de la tropa mejorada y del tempo.
- **Medido:**
  - en la II, el 71 % de los minutos tenés 400 o más de riqueza en el banco;
  - los 600 de riqueza del hito de la III están a los 11 min, pero la III llega a los 18;
  - el cuello de botella de la II es el alimento, no la riqueza.
- **El cambio:**
  - la herrería pasa a alimento y riqueza, sin madera;
  - la marcha y los vigías, a riqueza;
  - la mampostería, a piedra (que también sobra);
  - todo con el mismo tiempo de aldeano.
- **Resultado:**
  - la riqueza ociosa de la II baja del 71 % al 59 % de los minutos;
  - la herrería se compra el doble;
  - la III llega 0,8 min antes (mediana).
- **El consejo de jugador, que vale ya:** si en la II te sobra riqueza, el mercado te la cambia por alimento para el hito. Es lo que hace la IA y lo que se hace en AoE4 para subir antes.

## 1. Cómo se midió

**Herramienta nueva: `tools/bancos.gd`.** Arma partidas de IA contra IA y no toca la simulación.

Por jugador y por minuto registra:
- el **banco sin gastar** de cada recurso;
- lo **gastado por destino**:
  - aldeanos, tropa, edificios e hitos;
  - investigaciones de economía, de herrería, de niveles y otras;
  - el mercado;
- lo **juntado por origen**, del libro de la simulación (`stats.origen`): casa, disputado, propio, sitios, mercado y los demás.

De dónde saca cada dato:
- lo que entra a las colas, con el costo que de verdad se pagó (`queue_paid`);
- los edificios nuevos, cimientos y rozas que se reabren;
- el libro del mercado.

Lo que no ve así queda en «otros», por diferencia con el libro: tributo, acogida con fama y cancelaciones. Da 0 a −2 % del gasto, así que lo medido cierra. El resumen sale de `tools/bancos_resumen.py`.

**Muestra:**
- 24 partidas de 25 minutos, 48 jugadores;
- los 6 pueblos, 2 semillas, dificultades experta y difícil;
- los mismos cruces antes y después.

Resultados en [pruebas/09-bancos-antes.txt](pruebas/09-bancos-antes.txt) y [pruebas/09-bancos-despues.txt](pruebas/09-bancos-despues.txt). Las cifras de abajo son de las dos dificultades juntas; separadas dicen lo mismo.

## 2. Lo medido (antes)

### 2.1 El banco sin gastar

| Minuto | Edad media | Alimento | Madera | Riqueza | Piedra |
|---|---|---|---|---|---|
| 4 | 1,0 | 505 | 99 | 201 | 93 |
| 8 | 1,6 | 268 | 91 | 338 | 146 |
| 12 | 2,0 | 231 | 81 | 553 | 305 |
| 14 | 2,0 | 251 | 101 | **669** | 395 |
| 18 | 2,3 | 248 | 149 | 568 | 419 |
| 22 | 2,6 | 923 | 377 | 479 | 423 |
| 25 | 2,8 | 1188 | 554 | 493 | 397 |

**Promedio mientras se está en cada edad:**

| Edad | Alimento | Madera | Riqueza | Piedra |
|---|---|---|---|---|
| I | 428 | 103 | 221 | 101 |
| II | 273 | **127** | **580** | **340** |
| III | **956** | 388 | 378 | 416 |

### 2.2 En qué se gasta cada recurso

Por jugador y por minuto en esa edad, con el % de cada recurso.

| Edad | Alimento | Madera | Riqueza |
|---|---|---|---|
| I | aldeanos 49 %, hito 26 %, tropa 22 % | edificios 70 %, tropa 27 % | **hito 78 %**, tropa 22 % |
| II | tropa 56 %, aldeanos 26 %, hito 11 % | edificios 48 %, tropa 47 % | tropa 50 %, hito 24 %, **mercado 15 %** (compra alimento y piedra para el hito), otras investigaciones 6 %, **herrería 5 %** |
| III | tropa 59 %, aldeanos 13 %, **mercado 8 %** (vende alimento por riqueza) | tropa 61 %, edificios 32 % | tropa 49 %, niveles 23 %, hito 9 %, herrería 8 %, mercado 8 % |

**Juntado y gastado por minuto:**
- II: riqueza 168 juntada y 148 gastada; alimento 506 y 510; madera 404 y 406.
- III: riqueza 262 y 255; alimento 959 y 774.

La edad IV casi no se ve: 1 jugador de 48 llegó, al minuto 24,9.

### 2.3 De dónde sale la riqueza

Lo que junta la IA, por minuto:

| Edad | Arcilla de casa | Motor propio | Sitios | Mercado | Total |
|---|---|---|---|---|---|
| I | 44 | 22 | 3 | 0 | 69 |
| II | 91 | 56 | 13 | 6 | 168 |
| III | 68 | 109 | 22 | 45 | 262 |

**El motor propio, por pueblo** (edad II / edad III):
- Palmares, oficios: 89 / 174;
- Etiopía, corte y gult: 64 / 68;
- Mapuches, ganado: 53 / 75;
- Tawantinsuyu, cumbi: 45 / 85, más el taller;
- Ayutthaya, tributo: 43 / 56;
- Guaraníes, yerbal: 41 / 158.

**Lo que junta un jugador humano típico.** La IA pone solo 7 % de sus aldeanos en riqueza al principio y 17 % al final (`proporcion_temprana` y `proporcion_tardia`). Un humano pone más. Las fuentes, desde `data/`:
- **Reparto inicial:** 100.
- **Arcilla:**
  - 0,7 por segundo por aldeano (42 por minuto sin caminar; unos 35 con la caminata);
  - en casa hay 900, en los flancos 1500 (a 18 casillas) y en el centro 1000 por jugador;
  - guaraníes +14 % en casa e incas +20 % con caminos.
- **Sitios sagrados:**
  - 18, 12 y 8 por minuto: el primero, el segundo y el tercero;
  - techo de lo disputado: 15, 40, 80 y 120 por minuto según la edad.
- **Motor propio:** el de arriba. Crece con la edad y no se agota.
- **Mercado:** vender 100 de alimento, madera o piedra da 70 de riqueza al precio inicial (comisión 30 %).
- **Ingenio:** botín ocasional.
- **No hay reliquias ni comercio que camine:** el mercado solo cambia.

En la II, con 4 o 5 aldeanos en arcilla, un motor medio y un sitio, son **unas 220 a 250 por minuto**. Es un 30–50 % más que la IA. En 10 minutos de II son 2200 a 2500.

Antes de este cambio, lo que se podía gastar en riqueza en la II:
- el hito de la III, 600;
- la herrería I, la marcha y los vigías, **260 entre todas**;
- y la tropa: guerrero 25, jinete 70, lancero 10, hondero 0.

Con honderos y lanceros (la mezcla barata de la II) la riqueza no tiene adónde ir. **Ahí está tu banco.**

## 3. AoE4, como lo conozco

| Edad | Pide oro | Se paga con alimento, madera o piedra |
|---|---|---|
| Oscura | casi solo el pase a la feudal (≈ 400 de alimento y 200 de oro [aprox]) | aldeanos, casas, lancero y arquero (alimento y madera), economía I (alimento y madera) |
| Feudal | **herrería I** (alimento y oro, con más oro: del orden de 50–75 de alimento y 100–175 de oro cada una [aprox]); el hombre de armas (≈ 100 de alimento y 20 de oro); el pase a castillos (≈ 1200 de alimento y 600 de oro) | lanceros, arqueros, jinetes (alimento y madera); **economía II** (alimento y madera); torres (piedra) |
| Castillos | **la tropa de élite:** caballero (≈ 140 de alimento y 100 de oro), ballestero (≈ 80 de alimento y 40 de oro); **los niveles veteranos** (mucho oro); **herrería II**; asedio (madera y oro); monjes; el pase a imperial | economía III (alimento y madera, algún oro [aprox]); torreón (piedra) |
| Imperial | todo lo tope: **élites, herrería III, universidad** (cientos de oro cada una [aprox]), pólvora (≈ 120 de alimento y 120 de oro), trebuchet y bombarda (madera y oro) | economía IV (alimento y madera, con oro en algunas [verificar]) |

**Por qué el oro es la llave del tempo y de la élite:**
1. **Es finito y se disputa.** Las vetas se agotan. Después el oro sale de reliquias, sitios sagrados y comercio, todo en el mapa. El alimento (granjas) y la madera (bosques) prácticamente no se acaban.
2. **Todo lo que da poder pide oro:** los pases de edad, la herrería, los niveles, las unidades de élite y la universidad. La economía no lo pide. Así cualquiera puede crecer, y la ventaja sale de quién controla más oro.
3. **Por eso el tempo es oro.** El que tiene más aldeanos en oro, o la reliquia y el sitio, sube antes y saca la élite antes. En la feudal casi nadie tiene oro de sobra: la herrería y el pase a castillos se lo comen. Si sobra, se compra alimento en el mercado y se sube antes.

**Raíces comparado:**
- La **economía** ya está como en AoE4: las 7 de recolección son alimento y madera.
- La **herrería I** estaba al revés:
  - 25–30 de riqueza;
  - armaduras con madera.
- La **marcha** pedía más alimento que riqueza. Los **vigías** pedían madera.
- La **tropa base** casi no usa riqueza: como en AoE4, y está bien. El lancero y el hondero son la respuesta barata.
- El **pase de edad** es parecido: II 500/300, III 1000/600, IV 1800/1200.

## 4. Diagnóstico

| Edad | ¿Sobra riqueza? | Cuello de botella | Lo que sobra sin uso |
|---|---|---|---|
| **I** | No. El 78 % va al hito de la II (300); queda un banco de ≈ 200 | **alimento** (aldeanos y hito) y **madera** (banco 103; 70 % en edificios) | la piedra inicial (100), intacta hasta la II |
| **II** | **Sí.** Banco medio 580, pico 669 al minuto 14. El 71 % de los minutos está en 400 o más. Los 600 del hito de la III están al minuto 11 y la III llega al 18: **7 minutos de riqueza quieta esperando alimento** | **alimento** (banco 273; el hito pide 1000) y **madera** (banco 127) | **riqueza** y **piedra** (340: después del centro y las torres no hay en qué gastarla) |
| **III** | No: se vuelve justa. Banco 378 contra 956 de alimento. La IA vende alimento para conseguir riqueza (45 por minuto del mercado) | **riqueza**, como los castillos de AoE4 | alimento (por el reparto de aldeanos de la IA) y piedra (416) |
| **IV** | sin datos: 1 de 48 llegó | — | — |

**¿Falta dónde gastarla, o la economía da demasiada?** Falta dónde gastarla, y solo en la II:
- en la III la riqueza ya alcanza justo;
- la economía no da de más: la IA junta 168 por minuto en la II y un humano 220–250, del mismo orden que AoE4 en feudal [aprox].

El problema es que **en la II casi todo lo que hay para comprar pide alimento y madera**. Los dos recursos que faltan.

**¿Hay alguno que nunca falta?** La **piedra**:
- 300 a 420 en el banco desde el minuto 12 hasta el final;
- se gasta 33 por minuto en la II y 15 en la III.

## 5. La propuesta (aplicada en `data/tecnologias.json`)

**Las reglas:**
1. **Solo costos.** No entra ni sale ninguna tecnología, para que el merge con los pasos 3 y 4 sea simple. No toqué la economía, que es lo que tocan ellos.
2. **El mismo tiempo de aldeano.** Cada costo nuevo pide los mismos segundos de un aldeano que el viejo (±2 %), con las tasas de `data/unidades.json`:
   - alimento 1,0 por segundo;
   - madera 0,85;
   - riqueza y piedra 0,7.

   Así no cambia el "cuánto", solo el "con qué". Lo controla `tools/costo_aldeano.py`.
3. **Cada edad con un sumidero de riqueza:**
   - la I, el hito;
   - la II, **herrería I, marcha y vigías**;
   - la III, herrería II, niveles y adiestramiento;
   - la IV, herrería III y élites.
4. **La identidad de cada pueblo, intacta.** Ningún pueblo trae costos propios de tecnologías (`data/civs/*.json` no tiene `tecnologias`). Sus tropas propias tampoco se tocan: la riqueza de Etiopía (guerrero 80/40), el arcabucero de Ayutthaya a 110 de riqueza, la compañía japonesa, el elefante y los motores.
5. **La tropa base y los edificios, sin tocar.** La tropa barata de la II (lancero y hondero) sin riqueza es como en AoE4. El problema no estaba ahí.

| Investigación | Edad | Antes | Después | Tiempo de aldeano | Por qué |
|---|---|---|---|---|---|
| ataque_cc_1 y ataque_dist_1 | II | 50 alimento, 25 riqueza | **20 alimento, 45 riqueza** | 86 → 84 s | Sumidero de la II; libera alimento, el cuello de la II |
| armadura_cc_1 y armadura_dist_1 | II | 60 madera, 30 riqueza | **20 alimento, 65 riqueza** | 113 → 113 s | Sin madera, que falta en la II; como en AoE4, alimento y oro |
| marcha | II | 100 alimento, 75 riqueza | **50 alimento, 110 riqueza** | 207 → 207 s | Igual |
| vigías | II | 75 madera, 75 riqueza | **40 piedra, 100 riqueza** | 195 → 200 s | Sin madera; usa piedra que sobra |
| mampostería | II | 100 madera, 100 piedra | **50 madera, 145 piedra** | 261 → 266 s | Menos madera, más piedra |
| ataque_*_2 | III | 120 alimento, 90 riqueza | **80 alimento, 120 riqueza** | 249 → 251 s | Herrería con más riqueza que alimento, como en AoE4 |
| armadura_*_2 | III | 120 madera, 90 riqueza | **80 alimento, 130 riqueza** | 270 → 266 s | Sin madera; en la III sobra alimento |
| ataque_*_3 | IV | 180 alimento, 150 riqueza | **120 alimento, 190 riqueza** | 394 → 391 s | Igual |
| armadura_*_3 | IV | 180 madera, 150 riqueza | **120 alimento, 215 riqueza** | 426 → 427 s | Igual |

**Sin cambios:**
- **la economía** (hachas, cestas, riego, cantería, orfebrería y oficio maestro): alimento y madera, como en AoE4;
- **los niveles** (veterano 150/150, élite 300/300) y el **adiestramiento**: ya son mitad riqueza, y en la III la riqueza es justa;
- **las unidades y los edificios**.

**Por edad, todas las comunes juntas** ([pruebas/09-costo-aldeano.txt](pruebas/09-costo-aldeano.txt)):

| Edad | Antes | Después | Tiempo de aldeano |
|---|---|---|---|
| I | 125 a, 125 m | igual | +0 % |
| II | 475 a, 645 m, 260 r, 100 p | 405 a, 400 m, **430 r**, 185 p | +0,3 % |
| III | 1790 a, 840 m, 1360 r | 1870 a, 600 m, 1500 r | 0 % |
| IV | 1860 a, 360 m, 2100 r | 1980 a, 0 m, 2310 r | −0,1 % |
| Las 34 | 4250 a, 1970 m, 3720 r, 100 p | 4380 a, 1125 m, 4240 r, 185 p | **0,0 %** |

**El poder total no cambia.**
- `tools/modelo_progreso.py` da **exactamente las mismas tres tablas** antes y después ([pruebas/09-modelo-progreso.txt](pruebas/09-modelo-progreso.txt)):
  - el modelo cuenta unidades y mejoras compradas, no lee costos;
  - con solo costos cambiados, por construcción da igual.
- Los efectos no se tocaron. Lo que mide si el poder por recurso gastado se mantiene es el tiempo de aldeano: 0,0 % en total y ±2 % por investigación.

Tabla 1 del modelo, igual antes y después:

| Pueblo | I | II | III | IV | Δ II | Δ III | Δ IV |
|---|---|---|---|---|---|---|---|
| tawantinsuyu | 100 | 93 | 173 | 195 | +0 % | −0 % | −2 % |
| mapuches | 100 | 111 | 166 | 201 | +0 % | −1 % | −1 % |
| guaranies | 100 | 108 | 123 | 152 | +0 % | −1 % | −1 % |
| etiopia | 100 | 144 | 193 | 197 | +0 % | −1 % | −1 % |
| palmares | 100 | 104 | 142 | 182 | +0 % | −0 % | −1 % |
| ayutthaya | 100 | 191 | 205 | 229 | +0 % | −1 % | −1 % |

(Δ: el paso 1 y 2 contra el bono por edad de antes. No cambia con este paso.)

## 6. Antes y después (la misma herramienta, los mismos 24 cruces)

| | Antes | Después |
|---|---|---|
| Llegada a la II (mediana) | 7,4 min (48/48) | 7,4 min (48/48) |
| **Llegada a la III** (mediana) | 18,3 min (33/48) | **17,5 min (33/48)** |
| Llegaron a la IV | 1 | 2 |
| Minuto en que tiene los 600 de riqueza del hito de la III | 11 | 12 |
| **Minutos de la II con 400 o más de riqueza ociosa** | 422 de 598 (**71 %**) | 341 de 574 (**59 %**) |
| Banco medio en la II: alimento, madera, riqueza, piedra | 273, 127, **580**, 340 | 293, 122, **493**, 316 |
| Pico de riqueza (minuto 14) | 669 | 570 |
| Riqueza por minuto en la II: herrería y otras investigaciones | 7 + 9 = 16 | **17 + 15 = 32** |
| Madera por minuto en la II, herrería | 6 | 0 |
| Riqueza por minuto en la II al mercado (compras para el hito) | 22 | 16 |
| Banco medio en la III: alimento, madera, riqueza, piedra | 956, 388, 378, 416 | 822, 439, 323, 334 |
| Riqueza por minuto en la III, herrería | 20 | 38 |
| Alimento vendido por minuto en la III (para riqueza) | 65 | 110 |

**Por pueblo, llegada a la III** (mediana, y cuántos llegaron de 8):

| | Ayutthaya | Etiopía | Guaraníes | Mapuches | Palmares | Tawantinsuyu |
|---|---|---|---|---|---|---|
| Antes | 18,9 (6) | 20,5 (4) | 20,0 (8) | 14,3 (5) | 19,7 (5) | 16,9 (5) |
| Después | 18,5 (6) | 18,5 (4) | 17,9 (8) | 17,4 (6) | 17,5 (4) | 16,4 (5) |

**Lectura:**
- **La II tiene sumidero:** la IA gasta el doble de riqueza en investigaciones, la herrería no toca la madera y la riqueza ociosa baja 12 puntos.
- **La III llega antes en 4 de 6 pueblos.** El alimento y la madera que antes iban a la herrería van al hito.
- **Mapuches suben a la III más tarde** (14,3 → 17,4), pero llega uno más (5 → 6). Con 8 jugadores por pueblo es ruido posible; lo mira el torneo.
- **El banco de la II no desaparece**, y está bien: buena parte son los 600 que se juntan para la III. Lo que cambió es que ahora hay en qué gastar lo que sobra encima de eso.
- **En la III la riqueza es todavía más justa.** La IA vende más alimento para comprarla (65 → 110 por minuto). Es el comportamiento de AoE4 en castillos: el oro manda. Si el torneo muestra a la IA trabada por riqueza en la III, el ajuste va en su reparto de aldeanos (`proporcion_tardia`), no en los costos.

**Determinismo y bench** ([pruebas/09-determinismo-bench.txt](pruebas/09-determinismo-bench.txt)):
- `test_determinism`: OK, con el hash del paso 2 (2203695307);
- `bench`: sin cambios en su camino. 17 ms, con el torneo de otro agente corriendo al mismo tiempo.

**El torneo no lo corrí:** lo corre el orquestador al cierre del hito.

## 7. Lo que queda y los riesgos

- **La IV no se midió:** 1–2 de 48 llegan en 25 minutos. Cuando el paso 3 agregue la escuela y la economía de la IV, hay que medir con `tools/bancos.gd -- --minutes=40`.
- **La piedra sobra todo el juego.** Este cambio le da dos usos chicos: vigías y mampostería. El sumidero de verdad es el paso 4: fortaleza, torre pesada y asedio, que en AoE4 piden piedra y oro.
- **El hito de la III** pide 1000 de alimento y 600 de riqueza. La riqueza llega 6–7 minutos antes que el alimento. Una opción, que no apliqué porque toca el tempo de todos y AoE4 tiene incluso más alimento en el pase a castillos [aprox]: pasar 100 de alimento a riqueza.
- **El jugador humano** tiene más riqueza que la IA, así que el banco que ve el autor es más grande que el medido. La herramienta mide a la IA. Para verlo en el humano, `tools/bancos.gd` puede leer una partida grabada: queda para cuando haya grabaciones.
- **El tutorial y la ayuda** tendrían que decir lo que en AoE4 se aprende jugando: "la riqueza de sobra se cambia por alimento en el mercado para subir de edad".
- **Merge:** solo cambian 15 costos en `data/tecnologias.json` y el texto de `_doc_herreria`. Si el paso 3 o el 4 tocan esas mismas líneas, gana su efecto y se mantiene este costo.
