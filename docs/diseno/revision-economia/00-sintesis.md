# 00 · Síntesis de la revisión de la economía (2026-11-13)

Cinco perfiles revisaron la economía a pedido del autor (`proceso/11-revision-economia/`):

| # | Perfil |
|---|---|
| [01](01-sistemas-economicos.md) | Sistemas económicos |
| [02](02-facciones-asimetricas.md) | Facciones asimétricas |
| [03](03-legibilidad-y-mapa.md) | Legibilidad y mapa |
| [04](04-rigor-historico.md) | Rigor histórico |
| [05](05-balance-y-aperturas.md) | Balance y aperturas, con partidas medidas |

Este documento junta lo que comparten, dónde discrepan y qué tiene que decidir el autor. Nada de esto se aplicó todavía.

## 1. Diagnóstico compartido

- **El mapa cuenta una historia y las civs otra.** Cada base recibe el mismo anillo de AoE4: frutos, bosque, dos piedras y dos yacimientos de riqueza. El yacimiento es una roca gris con cristales dorados, y desde la cámara se lee como "mina de oro" (03).
- **En la edad I, cinco de las seis civs sacan la riqueza de esa mina.** Solo Etiopía tiene una vía propia, el gult. El resto llega tarde:
  - el aqllawasi, en la edad III;
  - los barrios y el puerto de Ayutthaya, en las edades II y III;
  - la feria mapuche, en la edad IV.

  El malón mapuche da kulliñ, no riqueza. Las correrías de Palmares dan fama (01, 02, 03, 05).
- **Los documentos se contradicen con los datos.** La matriz de roles (`03-matriz-de-roles.md`) promete "riqueza por malón" y "correrías y resgate", y `05-mecanicas-nucleo.md` exige una vía propia de riqueza para cada civ, pero los datos no lo cumplen (05).
- **La historia también lo pide** (04). La riqueza como "bienes para dar, intercambiar y legitimar" tiene sentido en los seis pueblos, pero no como mina de oro:
  - tela (cumbi) en los Andes;
  - ganado, ponchos y conchavo entre los mapuches;
  - prestigio y convite entre los guaraníes;
  - sal en barras (amole) y tributo en Etiopía;
  - comercio de farinha y resgate en Palmares;
  - almacén real y productos del monte en Ayutthaya.

  En dos casos la distorsión es alta: los mapuches, que hoy solo se enriquecen robando, y Palmares, que en la historia era agrícola y artesanal.

## 2. La pregunta del autor sobre los mapuches

**Respuesta medida (05): no es la apertura, ni es la riqueza.** A los 8 minutos tienen 306 de riqueza guardada, y el avance a la edad II pide 200. Les falta alimento, igual que a casi todas. Su bajo rendimiento sale de tres cosas:

| Origen | Qué pasa |
|---|---|
| IA | En la edad II elige el rewe militar en vez del económico. No entrena aldeanos en los lof extra. Gasta el kulliñ sin reservar el del próximo avance. A los 15 minutos queda trabada con 1582 de alimento y 890 de riqueza guardados. |
| Diseño | Sus edificios de victoria son frágiles: lof de 1600 de vida contra 2400 del centro, y rewe de 1800–2200 contra 3000–5000. Pierden en el medio juego. |
| Identidad | La economía no tiene una fuente propia y pacífica. Esto no los hace perder hoy, pero los vuelve una civ genérica que solo se distingue en la guerra. |

**Etiopía tiene un problema de diseño.** El gult cuesta alimento justo cuando falta y paga riqueza, que les sobra: tienen 389 sin usar a los 8 minutos. En 4 de cada 10 partidas no sale de la edad I. Un gult que cuesta madera y paga alimento lo corrige; el número intermedio está en 05.

## 3. El modelo recomendado: "una riqueza, seis motores"

Hay acuerdo de 01, 02, 03 y 04:

- **Recurso común.** La riqueza sigue siendo un solo recurso, con la misma clave y los mismos costos para todos. Esto mantiene D-006 y no multiplica el balance por seis.
- **Motor propio desde la edad I.** Cada civ la produce con un motor pacífico propio, que funciona en cualquier terreno; el terreno favorable da solo una bonificación (02).
- **Nombre e ícono por civ** en el HUD y en el mapa. Los nombres siguientes son propuestos y quedan por verificar:

| Civ | Nombre | Motor propio, pacífico, desde la edad I | Variante agresiva (que no sea la única) |
|---|---|---|---|
| Tawantinsuyu | Cumbi | La mit'a se destina a tejer: taller de cumbi | Hondero incendiario, caminos |
| Mapuches | Kulliñ (el kulliñ pasa a ser su riqueza) | Rebaño que crece en el corral; ponchos; conchavo | Malón: el botín por encima del tope se vuelve riqueza |
| Guaraníes | Convite, o yerba en la rama misión | Roza que deja yerbal (ya existe); yerbales silvestres lejanos | Emboscada en el monte |
| Etiopía | Amole (sal) | Gult rebalanceado; mulas de sal que valen más cuanto más lejos de la salina está la corte | Gult asignado a un regimiento: jinetes más baratos |
| Palmares | Resgate | Trueque de farinha con los moradores, a cambio de exponer el mocambo | Correrías a ingenios neutrales: botín una sola vez |
| Ayutthaya | Plata o almacén real | Excedente del arrozal vendido en el almacén real; el agua mejora el precio | Elefantes, compañías extranjeras |

- **La regla del quinto recurso: existe solo si no es riqueza.** La mit'a y la fama se quedan. El kulliñ se fusiona con la riqueza mapuche (01, 02 y 04 coinciden).

## 4. Dependencia territorial

El autor advirtió: "Si la riqueza está lejos y en otro lado, al perder esa región ya perdiste."

Los tres perfiles que lo trataron coinciden, y corrigieron sus propuestas:

- **El motor propio es la columna vertebral.** Solo, tiene que alcanzar para avanzar de edad. Quien pierde todo lo disputable conserva al menos el 60 % de su ingreso de riqueza (01).
- **Techo de riqueza disputable por edad:**

  | Edad | Techo |
  |---|---|
  | I | 10 % |
  | II | 25 % |
  | III | 35–40 % |
  | IV | 45–50 % |

  01 y 05 dan rangos casi iguales.
- **Siempre tres vías:**
  - el motor propio;
  - el mercado o trueque, caro pero seguro, con un precio mínimo;
  - lo disputable, que rinde menos en el segundo y el tercer punto del mismo tipo y tiene un tope por jugador.
- **Remontada:**
  - lo disputable se agota;
  - sostener el centro aleja al ejército de casa;
  - retomar un punto da botín;
  - los ingenios dan botín una vez, nunca renta.
- **Base:** cada base conserva una fuente común chica que se agota, una salina, en lugar de la mina dorada (01 corrigió su propuesta de sacarla del todo).
- **Lo más expuesto hoy** (02):
  - Ayutthaya, por el agua;
  - los mapuches de hoy, cuya única riqueza es la mina;
  - Tawantinsuyu, por las laderas y la red de caminos.

  Arreglo: el andén en llano rinde como una granja, y Ayutthaya vende en su palacio aunque no tenga agua.

## 5. Dónde discrepan

| Tema | Posturas |
|---|---|
| **Cuánto cambiar el mapa** | 03 propone empezar solo por la imagen: nombre, ícono y silueta del yacimiento según la civ. 01 y 02 cambian el reparto: una salina chica por base y un paisaje inicial por civ. |
| **Mapuches** | 05 midió que el arreglo de IA y de vida de los edificios pesa más que el modelo económico; ninguna de seis variantes económicas los sacó de 1–2 victorias de 10. 02 y 04 piden igual el motor propio, por identidad y por historia. Las dos cosas son compatibles. |
| **Nombres** | 04 propone nombres históricos con fuentes para verificar. 03 pide que la palabra "Riqueza" y el rombo sigan visibles como ancla común. |

## 6. Orden propuesto

1. **Sin arrepentimiento**: no depende de ninguna decisión y vale para cualquier modelo.
   - IA mapuche: el rewe económico primero; reservar el kulliñ del próximo avance; los lof extra entrenan aldeanos.
   - IA común: la campana refugia como máximo a 3 aldeanos por enemigo; no congelar el ejército más de 60 s.
   - Vida de los edificios mapuches: lof 1900, rewe 2800.
   - Gult etíope: 100 de madera y 40 de alimento; renta de 18 de alimento y 12 de riqueza.
   - Colores: sacar a fama y mit'a del dorado de la riqueza.
   - Tooltip de la riqueza con el ingreso por fuente.
   - Corregir los textos de la matriz y del gult.

   Se valida con el torneo `--seeds=4`, con cada civ entre 7 y 13 victorias de 20.
2. **Modelo**: los motores propios desde la edad I, la fusión del kulliñ, el mercado o trueque desde la edad I y el techo de lo disputable.
3. **Mapa**: la salina chica en cada base, el aspecto del yacimiento según la civ y el paisaje inicial por civ.
4. **Validación territorial**:
   - Prueba de "la IA que no sale de su base": tiene que llegar a la edad III antes del minuto 20.
   - "Prueba del golpe" en el minuto 10: el castigado gana entre el 20 y el 40 %.
   - Torneo en mapas desfavorables para cada civ.

Las preguntas para el autor están en `proceso/CONSULTAS.md`, de C-10 a C-13.
