# 05 — Balance y aperturas (ronda 2)

Perfil: balance competitivo. Base: la ronda 1 (`../05-balance-y-aperturas.md`), la síntesis y la investigación de AoE4. Las mediciones nuevas salen de scripts propios del scratchpad, corridos en headless con la IA normal: `atencion.gd` y `pendientes.gd`, 2 partidas de 20 minutos por civ. No se tocaron código ni datos.

## 1. Cómo medir la atención

**En palabras llanas:** la atención que pide una civ es cuántas veces por minuto el juego la deja "esperando una orden" por culpa de su mecánica propia, y si esa orden es una elección o un trámite.

Contar comandos crudos de la IA no sirve: repite órdenes que fallan (registré de 3 a 12 "entrenar aldeano" por minuto). Propongo tres medidas.

### A. Pendientes de la mecánica propia (PMP), cada 10 minutos

Eventos del simulador que dejan la mecánica propia perdiendo rendimiento hasta que alguien actúa; valen igual para humanos y para la IA:
- una fuente propia se agota (la roza que pasa a yerbal, el yerbal que se termina);
- el recurso propio llega al tope y lo que entra se pierde;
- un edificio de renta queda parado o lleno;
- una unidad económica propia queda ociosa;
- una ventana temporal se abre (el puerto, si llega a existir).

Se registran también los segundos hasta resolverlo.

**Primer dato:** la mit'a inca pasa el **43 % del tiempo en el tope** (257 s de cada 600). La mecánica está ociosa: el tope es corto o el recurso no tiene en qué gastarse. Ninguna otra civ llega al tope de su recurso propio.

### B. Órdenes propias aceptadas por minuto (OPA)

Se toman de los comandos (`recording` para humanos y la cola `_pending` para la IA). Cuentan solo los que el simulador acepta, sin repetir, y que tocan algo exclusivo de la civ: sus edificios y unidades nuevas, empacar y desempacar, caminos.

| Civ | OPA hoy | De dónde sale |
|---|---|---|
| Ayutthaya | 0,62 | Kraal, barrios, elefantes |
| Etiopía | 0,12 | Gult |
| Guaraníes | 0 | La roza no pide órdenes propias |
| Mapuches | 0,10 | Corral, lof |
| Palmares | 0,13 | Mocambo |
| Tawantinsuyu | **2,16** | Caminos (~1 por minuto) y boleadores |

Entrenar una unidad propia no es impuesto: el umbral mira solo el mantenimiento (construir, reponer, mover, empacar).

### C. Decisiones por edad (se cuentan en la ficha de la civ, no en el simulador)

Cuenta si tiene al menos dos respuestas viables (dónde va el corral, si la corte se muda).

### Umbrales parejos

- **PMP ≤ 4 cada 10 minutos** por civ, sin más de **2 de diferencia** entre la más y la menos exigente.
- **Nada periódico con cadencia menor a 90 s.** Si un pendiente reaparece siempre igual, se automatiza. Es la regla de Stormgate y del Chrono de 2017.
- **Recurso propio en el tope ≤ 15 % del tiempo.** Por encima, la mecánica está ociosa o mal calibrada; hoy la mit'a está en 43 %.
- **OPA de mantenimiento ≤ 1,0 por minuto** y no más de 0,5 sobre la mediana.
- **Cada pendiente tiene al menos 2 respuestas válidas** (criterio 1 de la consigna).

**Medida indirecta para jugadores nuevos.** Torneo con las dos IA en `facil` (piensa cada 3 s, no cada 1 s) contra `normal`. Si una civ cae mucho más que el resto al pensar menos seguido, paga impuesto de atención (el patrón Zhu Xi / Orden del Dragón del catálogo). Umbral: ninguna cae más de 10 puntos por encima de la caída media.

## 2. Reglas de balance para motores asimétricos

**R1. Sumidero común, motor propio, curvas comparadas.** Todas gastan la misma riqueza, como el favor de AoM. Lo que se compara entre civs es la riqueza acumulada a los 5, 10 y 20 minutos, no la tasa por segundo.
- Objetivo: a los 10 minutos, la riqueza acumulada del motor propio de cada civ queda dentro de ±15 % de la mediana.
- Hoy no se cumple: al minuto 10, Etiopía saca la mitad de su riqueza de fuentes que no son yacimientos (gult y otras); los mapuches y Palmares, casi nada.

**R2. Topes.** El ingreso pasivo sin tope se rompió siempre:
- Lancaster salió con 70 de comida y 45 de madera por mansión ("9 manors = 24 workers") y lo recortaron al día siguiente; después lo pasaron a un aura por aldeano.
- Las cabañas rus terminaron con un tope global de 420 de oro por minuto.
- Los yatai tienen un máximo de 3 y su base bajó de 20 a 10. Los estanques escoceses, un máximo de 4.

Regla para Raíces: cada fuente pasiva tiene **un máximo por edad (1 más 1 por edad)** o un tope global por minuto, y **una decisión de dónde** ponerla. El pasivo puro, que rinde igual en cualquier lugar, no pasa la revisión.

**R3. Rendimientos decrecientes.** La segunda y la tercera copia de una misma fuente rinden **70 % y 50 %**. Hay precedentes:
- los aldeanos griegos que rezan en AoM;
- los trabajadores de Stormgate;
- *Sanctity* de Delhi, que bajó de 50 % a 25 % porque daba "very binary games".

La regla sirve también para lo disputable: un sitio sagrado de más rinde menos que el anterior.

**R4. Calibrar una renta contra un aldeano.** La unidad de medida es el **período de repago**: costo dividido por rendimiento por minuto.
- Un aldeano en un yacimiento rinde unos 30 de riqueza por minuto: la tasa bruta es 42 y se pierde parte caminando, porque la `carga` es de 10. Cuesta 50 y se repaga en menos de 2 minutos, pero ocupa población, se lo puede matar y pide órdenes.
- Una renta no ocupa población ni pide órdenes. Por eso tiene que repagarse **entre 5 y 8 minutos** en las edades I y II, y rendir como máximo **0,8 aldeanos** por edificio.
- Con 3 minutos o menos rompe el boom. Lancaster de lanzamiento: 275 de costo por 115 por minuto, es decir 2,4 min.
- El gult de hoy (200 por 32 por minuto) se repaga en 6,25 min y está bien. La propuesta de la ronda 1 (140 por 30) queda en 4,7 min: hay que corregirla (sección 3).

**R5. Ni dominante ni inútil.** Para cada civ se mide qué parte de su riqueza sale de su motor propio al minuto 15:
- **por debajo del 20 %, el motor es inútil.** Le pasa hoy a los mapuches, por el kulliñ, y a Palmares;
- **por encima del 70 %**, y si además la civ ya no pisa ningún yacimiento, **el motor es dominante**;
- la banda sana va del **30 al 60 %**.

**R6. Corregir primero los números periféricos.** Cuando una civ se pasa, primero se tocan costos, tiempos y vida, y la mecánica identitaria va al final. Malí y las cabañas rus, recortadas casi a la mitad, quedaron "en terapia intensiva" por tocar el núcleo. Cada cambio en `data/` lleva una línea de por qué, con la misma vara para todas.

**R7. Lo agresivo, con piso pacífico.** Sin pelear, el motor agresivo tiene que rendir al menos el **50 %** de lo que rinde peleando. Es la caza doble de los nórdicos en Retold. Para el malón: el corral rinde aunque no haya incursión, y el botín suma por encima del tope.

## 3. Qué pasa con los arreglos "sin arrepentimiento"

| Arreglo de la ronda 1 | ¿Sigue? | Ajuste por los criterios nuevos |
|---|---|---|
| IA mapuche: rewe económico primero | **Sí** | Ninguno. Es un error de la IA, no de diseño. |
| IA: reservar el kulliñ del próximo avance | **Sí, generalizado** | Si el kulliñ se fusiona con la riqueza, la regla pasa a ser "reservar lo que pide el próximo hito". Vale para las seis civs. |
| Lof extra que entrenan aldeanos | **Sí, con matiz** | Para un humano, cada lof es otra cola que atender. Es atención propia, pero es una decisión (expandirse o no), no un ritual. Opción a evaluar: que el lof recluta solo, más lento, como el centro vikingo. Baja la atención y refuerza el "no hay capital". Medirlo con OPA. |
| Campana: 3 por enemigo y calma automática | **Sí, y sube de prioridad** | Medí 1500 a 1700 aldeanos-segundo refugiados cada 10 min en mapuches y Palmares: unos 2,5 aldeanos perdidos todo el tiempo. Para el humano, la calma manual es un trámite. Propongo calma automática a los 10 s sin enemigos también para el jugador, con opción de desactivarla. |
| Vida: lof 1900, rewe 2800 | **Sí** | Es el arreglo ideal según R6: número periférico, no tocan la identidad ni la atención. |
| Gult: 100 de madera y 40 de alimento; renta de 18 a + 12 r | **Sí, recalibrado** | Con R4, el repago de 4,7 min es corto. Nuevo valor: renta de **16 a + 10 r** (repago de 5,4 min). Con el criterio 3 se agregan un **máximo de 1 gult más 1 por edad** y una decisión de lugar: **+25 % si toca 3 granjas o más**. El rango de edad II para validar sigue siendo de 6:30 a 8:00. |

**Hallazgo nuevo para la lista de arreglos.** La mit'a pasa el 43 % del tiempo en el tope, y la IA tiende caminos a un ritmo de alrededor de uno por minuto. Hay dos lecturas:
- subir el tope de mit'a o darle un gasto continuo;
- revisar que los caminos sean una decisión de red y no un mantenimiento.

Esto toca a Tawantinsuyu, la civ con más órdenes propias.

## 4. Plan de prueba para la ronda de implementación

**Instrumentación** (se escribe en `tests/`, en la ronda de implementación). Un informe por partida, junto al torneo:
- momento de cada avance de edad;
- banco a los 8 minutos;
- riqueza por origen: yacimiento propio, disputado, motor propio, mercado, sitios;
- PMP con sus segundos de espera;
- OPA de mantenimiento;
- tiempo con el recurso propio en el tope;
- aldeanos-segundo ociosos y refugiados.

**Fases.** Cada fase cambia una sola cosa, para separar diseño de IA:

| Fase | Cambio | Prueba |
|---|---|---|
| 0 | Línea de base | `torneo.gd -- --minutes=30 --seeds=6`: 30 partidas por civ, con un margen de ±18 % al 95 % |
| 1 | Solo IA: rewe, reserva, campana, lof | Igual a la fase 0 |
| 2 | Datos periféricos: vida, gult recalibrado | Igual a la fase 0 |
| 3 | Modelo de motores propios | Igual a la fase 0, más las pruebas del golpe y sin centro de la ronda 1 |
| 4 | Atención | Torneo `facil` contra `facil` y comparación con `normal` |

**Criterios de aprobación** (dos torneos seguidos, para no perseguir ruido):

| Aspecto | Criterio |
|---|---|
| Victorias | Cada civ entre 35 y 65 % |
| Ritmo | Edad II con mediana entre 6:30 y 9:00, sin más de 2 min de diferencia entre civs |
| Motor | Entre 30 y 60 % de la riqueza sale del motor propio al minuto 15 (R5) |
| Territorio | Techo disputable por edad de la síntesis; con la prueba del golpe, el castigado gana entre 20 y 40 % |
| Atención | PMP ≤ 4 cada 10 min con diferencia ≤ 2; nada periódico por debajo de 90 s; recurso propio en tope ≤ 15 %; OPA de mantenimiento ≤ 1,0 |
| Jugador nuevo | Ninguna civ cae más de 10 puntos por encima de la media entre `normal` y `facil` |
| Banco | Riqueza guardada a los 8 min ≤ 250 (mediana) |

**Límite.** La IA no se aburre ni se olvida: PMP mide lo que el juego *pide*, no lo que cuesta. Antes de cerrar el modelo, grabar 3 partidas humanas por civ (`recording`) y medir OPA y PMP con las mismas fórmulas.
