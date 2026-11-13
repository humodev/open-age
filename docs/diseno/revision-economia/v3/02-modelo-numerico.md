# Ronda 3 · 02 — Modelo numérico del diseño consolidado

Perfil: balance y aperturas. Mide `01-diseno-lider.md` con los números de `parametros.json` contra los criterios 2, 3, 4 y 8 de la lista de control. No toqué `data/` ni `src/`.

## 1. Qué es el modelo y cómo se corre

`tools/modelo_economia.py` (Python 3, solo biblioteca estándar) lee `parametros.json`, `data/*.json` y `data/civs/*.json`. Simula a las seis civs de 0 a 40 minutos en pasos de 10 s:

```
python3 tools/modelo_economia.py              # informe base
python3 tools/modelo_economia.py --palancas   # las palancas de este documento
python3 tools/modelo_economia.py --json x.json --militar 35 --sin-rentas-de-hito
```

**Qué modela.**
- **Aldeanos**: 18 s y 50 de alimento cada uno, hasta 60. Palmares no los entrena: le llegan por fama (acogida de 28).
- **Gastos comunes**: casas, granjas, cuartel y depósito o lof en el barreal de flanco.
- **Reparto de aldeanos**: en la edad I, 58 % alimento, 27 % madera y 3 aldeanos al barreal desde las 2:00. En la edad II, 45 / 25 / 20 / 10 % (alimento, madera, barreal, piedra), y en la III, 42 / 23 / 25 / 10 %. La mano de obra del motor se descuenta antes del reparto: los yerbales guaraníes y los oficios de Palmares.
- **Lo que pide el diseño**:
  - barreal 2×900 + 1500 + centro 2×1000 que se agota;
  - tasas netas de `parametros.json`;
  - alfarería fina +20 % en la edad II;
  - tecnología de motor +25 % en la edad III;
  - máximo de piezas por edad;
  - semillas;
  - capa 1 de cada civ: barreal conectado inca, tasa 800 guaraní, la corte etíope que extrae 12 por minuto y se muda cuando agota su barreal.
- **Hitos**: costos de `edades.json` más `costo_extra`, con el kulliñ convertido en riqueza. La IA elige la opción económica; se paga con 13, 21 o 29 aldeanos y cuartel, igual que `_wants_hito`.

**Supuestos propios**, declarados en `SUPUESTOS`:
- **Eficiencia del 75 % sobre las tasas netas.** Cubre obras, ociosos y caminatas a fuentes nuevas. Con ella, el modelo reproduce lo que juntó la IA real a los 10 minutos en la ronda 1: alimento entre 2500 y 3100 y madera entre 2200 y 2500.
- **El 35 % del alimento y la madera va al ejército** desde el cuartel. Se frena al ahorrar para el hito solo si cada recurso ya cubre la mitad, como en `sim_ai.gd`.
- **Una civ "genérica" sin motor**, con los yacimientos actuales de 1400, como referencia.

**Límites.**
- No hay rival: el golpe y la pérdida del barreal se simulan quitando la fuente.
- No hay destrucción, así que la fase final (30–40 min) no genera órdenes y su esfuerzo no se puede medir acá.
- El terreno se traduce con heurísticas a partir de `reglas.json → terrenos`: monte por bosques, ladera por relieve, agua por ríos y lagunas.

## 2. Resultado del diseño tal como está (llano, sin lo disputado)

| Civ | Riqueza a m5 / m10 / m20 / m30 | Desvío vs. media (%) | Motor al m15 (m15–25) | Edad II / III | Barreal de casa / de flanco agotado |
|---|---|---|---|---|---|
| Tawantinsuyu | 280 / 1275 / 4595 / 6095 | −11 / +6 / +2 / −4 | 23 % (60 %) | 5:30 / 13:20 | 13:20 / 17:00 |
| Mapuches | 280 / 1245 / 4503 / 6471 | −11 / +3 / 0 / +2 | 15 % (35 %) | 5:30 / 14:10 | 14:00 / 18:10 |
| Guaraníes | 481 / 1237 / 4021 / 6062 | **+53** / +2 / −10 / −4 | **0 %** (59 %) | 6:50 / 10:30 | 12:30 / 16:10 |
| Etiopía | 290 / 1194 / 4131 / 5198 | −8 / −1 / −8 / **−18** | 19 % (47 %) | 5:30 / 14:50 | 13:40 / 17:50 |
| Palmares | 232 / 1038 / 4946 / 7076 | **−26** / −14 / +10 / +12 | 34 % (45 %) | 5:20 / 12:20 | 15:30 / 20:00 |
| Ayutthaya | 323 / 1262 / 4705 / 7055 | +3 / +4 / +5 / +12 | 16 % (41 %) | 5:30 / 13:30 | 13:10 / 17:20 |
| *Genérica (hoy, sin motor)* | 203 / 998 / 4200 / 4200 | — | — | 5:30 / 14:10 | 16:00 / 19:10 |

La genérica se planta en 4200 desde el minuto 20, porque es todo el yacimiento que tiene. **El motor es lo único que sostiene la riqueza después del minuto 18**, como anticipaba el diseño, pero ese momento llega antes de lo que el diseño calculaba (ver §5).

## 3. Lista de control (criterios 2, 3, 4 y 8)

| # | Criterio | Resultado del modelo | Estado |
|---|---|---|---|
| 2 | Esfuerzo parejo por fase (±×1,5) | Ver detalle abajo | **No cumple** (fases 1 y 3) |
| 3 | Riqueza acumulada a los 5, 10, 20 y 30 min dentro de ±15 % de la media | Ver detalle abajo | **No cumple** (m5 y m30) |
| 4 | Edad II entre 6:30 y 9:00 y edad III antes de 20:00, sin lo disputado | Ver detalle abajo | **No cumple** el piso de la edad II |
| 8 | Lo disputado con techo por edad y remontada | Ver detalle abajo | **Remontada sí, techo no** |

**Criterio 2, esfuerzo.**
- Órdenes económicas por minuto, comunes más motor: fase 1 entre 1,0 y 2,2 (×2,2); fase 2 entre 2,1 y 2,9 (×1,38); fase 3 entre 0,7 y 1,8 (×2,5).
- Órdenes del motor solo: entre 0 y 0,6 por minuto.
- Pendientes del motor cada 10 minutos: guaraníes **4 en la fase 3 y 8 en la final**; el resto, entre 0 y 2.
- Recurso propio en el tope: mit'a **50 %** y fama **50 %** del tiempo.

**Criterio 3, curvas.**
- Al minuto 5: guaraníes +53 % por la semilla de 250 con 2 aldeanos desde el minuto 0, Palmares −26 % y Tawantinsuyu y mapuches −11 %.
- Al minuto 30: Etiopía −18 %.
- Los minutos 10 y 20 cumplen.

**Criterio 4, edades.**
- Edad II entre 5:20 y 6:50: cinco de seis civs quedan antes de las 6:30.
- Edad III entre 10:30 y 14:50: todas cumplen.

**Criterio 8, lo disputado.**
- **Techo:** con un sitio, ingenios cada 240 s y la mitad de los aldeanos del barreal en el centro, lo disputado pesa entre 47 y 57 % en la edad II y entre 43 y 56 % en la III. Los techos son 25 y 40 %.
- **Remontada:** al perder todo lo disputado en el minuto 10 se retiene entre el 84 y el 100 % del ingreso; en el minuto 20, entre el 79 y el 87 %. Ninguna civ demora su próxima edad.

## 4. Palancas numéricas y lo que arreglan

Todas están probadas en `--palancas`. Respetan R6: primero los números periféricos.

| Incumplimiento | Palanca | Efecto medido |
|---|---|---|
| **Guaraníes**: +53 % al m5, motor 0 % al m15, 8 pendientes cada 10 min | Roza de 750 a **500**; semilla de 250 a **60**; **cola automática**: la roza se repone sola mientras haya madera, con un interruptor | m5 +3 %, motor al m15 28–30 %, 0 pendientes. Primer yerbal a las 13:50, no a las 18:40 |
| **Palmares**: −26 % al m5 y edad II demasiado temprana, porque no paga aldeanos | Oficio con cupo desde las 3:00; fama inicial **90**; **el hito II pide 90 de fama** y la acogida se pausa mientras se ahorra | m5 +9 %, edad II 6:40 |
| **Etiopía**: −18 % al m30 | Gult de **14 a 17 de riqueza** de base (23 cerca de la corte; el diseño fija 19) | −12 % al m30. Da 0,57 AE de base y 0,77 cerca de la corte: sigue dentro de la regla de 0,8 |
| **Rentas de hito sin tope** (§5.4): suben a mapuches y Ayutthaya | Sacar la renta de los hitos o darles tope por minuto | Mapuches y Ayutthaya bajan de 2 a 8 puntos al m30; Etiopía sube a −10 % |
| **Edad II antes de las 6:30** | Hito II de 400 a + 200 r a **500 a + 350 r** | Cinco civs entre 6:30 y 6:50; Etiopía 8:50; Palmares 6:40 con su palanca. La edad III queda entre 10:40 y 14:40 |
| **Techo de lo disputado** | **Tope de ingreso disputado por minuto: 40 / 90 / 150 r/min** en las edades II / III / IV, sumando barreal del centro, sitios e ingenios | Edad II ≤ 25 % y edad III ≤ 30 % con hasta la mitad de los aldeanos en el centro. Achicar el barreal central (1000 → 500) o espaciar los ingenios (240 → 480 s) mueve apenas de 2 a 9 puntos |
| **Motor al m15 por debajo del 30 %** | Medir R5 en el promedio de los minutos 15 a 25, con una banda de 35–65 %. No subir los motores | En la ventana 15–25 da entre 35 y 60 % (guaraníes con el conjunto: 76 %) |
| **Mit'a y fama en el tope el 50 % del tiempo** | Taller que consume 40 de mit'a, o mit'a de 4 a 3 por aldeano desde la edad III. La fama necesita un destino aparte de la acogida | Sin medir en detalle: el ingreso de mit'a (240 por minuto con 60 runa) duplica el consumo de 5 talleres (150) |

**El conjunto aplicado a la vez** (`CONJUNTO_CIV` y `CONJUNTO_COMUN` en el script):

| Civ | Desvío m5 / m10 / m20 / m30 | Edad II / III | Pendientes del motor |
|---|---|---|---|
| Tawantinsuyu | −9 / +11 / +9 / +2 | 6:30 / 13:50 | ≤ 1,3 |
| Mapuches | −7 / −3 / −1 / −11 | 6:50 / 14:40 | 0 |
| Guaraníes | −2 / −2 / +8 / +8 | 6:30 / 10:40 | 0 |
| Etiopía | 0 / −7 / −1 / −8 | 8:50 / 14:10 | 1 |
| Palmares | +9 / 0 / −15 / +13 | 6:40 / 14:30 | ≤ 1 |
| Ayutthaya | +9 / +1 / +1 / −5 | 6:30 / 12:50 | ≤ 1 |

- **Criterios 3 y 4: cumplen.** Palmares queda justo en el borde al minuto 20.
- **Criterio 8: cumple con el tope por minuto.**
- **Criterio 2:** el motor cumple, con a lo sumo 0,5 órdenes por minuto y 2 pendientes cada 10 minutos. La OPM total sigue en ×2 en las fases 1 y 3 (ver §5.6).

## 5. Supuestos del diseño que no cierran

1. **El barreal no dura hasta los minutos 22 a 28.**
   - Con un 20–25 % de los aldeanos en el barreal y las bonificaciones que el mismo diseño suma, el de casa se agota entre los minutos 12:30 y 15:30 y el de flanco entre 16 y 20. Las bonificaciones son: hito +10 %, alfarería +20 % y barreal conectado +20 % para los incas.
   - Los 22–28 minutos solo salen con 4 aldeanos fijos y sin tecnologías.
   - Consecuencia: el "cruce" llega antes y el motor pasa de cerca del 20 % al 60–100 % entre los minutos 15 y 20.
2. **El hito II no lo limita la economía.** Con una apertura razonable se paga a los 5:30. La banda de 6:30 a 9:00 venía de la IA actual, que es lenta por la campana, las órdenes repetidas y el ejército temprano. Si se quiere esa banda, hay que fijarla con el costo (500 a + 350 r).
3. **Hasta la edad II la riqueza sobra.** A los 10 minutos el banco va de 900 a 1100 en casi todas las civs. Lo que frena es el alimento y la madera, como ya se vio en la ronda 1. Los motores pesan en la segunda mitad, no en la apertura.
4. **Quedan pasivos sin tope.** El diseño solo cambió la renta del aqllawasi. Siguen sin tope:
   - el puerto real (55 por minuto);
   - el junco (40);
   - el pacto de Cucaú (40);
   - la misión (25);
   - el parlamento (40 más 20 de kulliñ);
   - el rewe del lonko (20 de kulliñ).

   Con la fusión, el kulliñ de esas rentas pasa a ser riqueza. Esto choca con el criterio F ("pasivos sin tope").
5. **La tecnología de motor no es simétrica.** Tawantinsuyu la recibe con el hito aqllawasi, que cuesta 120 de mit'a. Las demás pagan 200 de alimento, 200 de madera y 100 de riqueza.
6. **La tabla de terreno tiene una columna imposible.** Es "contra el llano propio", así que la columna del llano debería ser 0, y trae de −2 a +4.
7. **El techo de lo disputado no lo garantiza ninguna regla.** Un sitio sagrado solo ya es el 15 % del ingreso en la edad II, y un ingenio cada 240 s suma 13 % más. Hace falta un tope por minuto (§4). Expresado en porcentaje no sirve: quien abandona su base y manda todo al centro tiene el 61 % de su ingreso "disputado" aunque el ingreso total sea chico.
8. **La mit'a y la fama siguen pasando el 50 % del tiempo en el tope.** El diseño daba por resuelto el problema de la mit'a. El de la fama aparece cuando se llega al máximo de aldeanos: la acogida es su único destino.
9. **Los guaraníes con roza de 750 y cola de 4:**
   - el primer yerbal aparece a las 18:40, no hacia el minuto 13;
   - la cola de 4 da entre 4 y 8 pendientes cada 10 minutos, contra los 2 que estima el diseño.

   Hay una tensión de fondo: una roza más chica adelanta el motor pero pide más reposición. La cola automática la resuelve.
10. **La mudanza de la corte detiene la producción de aldeanos** unos 60 s: la corte es el centro. El diseño no lo cuenta.
11. **Perder el barreal de casa en el minuto 10 pega distinto según la civ.**
    - Etiopía retiene el 95 % y los guaraníes el 105 %.
    - Tawantinsuyu, el 77 %; Ayutthaya, el 57 %.
    - Palmares y mapuches retienen alrededor del 40 %. A esa altura su motor es chico, y el lof de flanco cuesta 110 de madera.

    Todos tienen 900 o más guardados, así que no es letal, pero no se cumple "el motor alcanza" de la síntesis (60 % o más).
12. **La OPM total no puede ser pareja si las civs tienen distinta cantidad de aldeanos.** Las granjas y las casas dominan el conteo. Palmares tiene menos gente al principio (1,0 contra 2,2 órdenes por minuto) y los guaraníes ponen las rozas por cola. El ×1,5 conviene medirlo **sobre el motor más los pendientes**, con umbrales absolutos: OPA ≤ 0,6, PMP ≤ 2 y nada por debajo de 90 s. Con esa vara, el conjunto cumple.

## 6. Terreno (economía total al minuto 20 contra el llano propio)

| Mapa | Diferencia entre civs en el modelo | Celdas fuera de ±6 % |
|---|---|---|
| valle | 10,0 | Palmares −9,2 |
| altiplano | 8,5 | Palmares −11,2, Ayutthaya −8,3 |
| mesetas | **11,8** | Ayutthaya −8,5 |
| sierra | **12,7** | Ayutthaya −6,5, Tawantinsuyu +6,2 |
| montaña / bosque templado | 8,6 / 6,9 | Tawantinsuyu +6,2 |
| resto | ≤ 5,6 | — |

- **Coincide con la tabla del diseño en las columnas de riesgo:** valle, altiplano y selva.
- **Donde el modelo ve más castigo que la tabla:**
  - Palmares en los mapas pelados: con menos monte, menos fama y menos gente;
  - Ayutthaya en mesetas y sierra: con poco bosque, el almacén real rinde menos.
- **Donde se invierte el signo:** mapuches y Etiopía en el altiplano y las mesetas. El modelo no tiene en cuenta "lugar abierto para el gult" ni "pradera" como ventaja económica fuerte.
- **Palancas:**
  - Palmares: la fama base de la cerca real de 24 a 28 en mapas con menos de 8 bosques, o el bono de monte de 5 a 3 (achica la diferencia);
  - Ayutthaya: el almacén real cobra también el 25 % de la piedra, que hay en todos los mapas.

  Hay que confirmarlas con el torneo.

## 7. Qué falta para aprobar

1. Decidir sobre las rentas de hito (§5.4) y el tope disputado por minuto (§4). Las dos son reglas, no números finos.
2. Correr `tools/modelo_economia.py --palancas` cada vez que cambie `parametros.json`.
3. Implementar y medir con el torneo, que tiene rival, destrucción e IA real. El modelo solo descarta lo que no cierra en papel.
