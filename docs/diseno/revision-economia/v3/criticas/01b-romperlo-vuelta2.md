# Ronda 3 · Crítica 01b — El que intenta romperlo, segunda vuelta

Sobre [`../03-diseno-revisado.md`](../03-diseno-revisado.md) y [`../parametros.json`](../parametros.json) (`v3-03`). Corrí `python3 tools/modelo_economia.py` y leí las partes del motor de cada civ (`motor_paso`, `hito_paso`). Contrasté con `data/` y `src/sim/`. No toqué nada fuera de este archivo.

Lo que el modelo **no** puede ver, y que pesa en esta vuelta:
- no agota el bosque: no hay ninguna variable de madera del mapa;
- trata cada yerbal como trabajado por un solo aldeano;
- no modela el arreo, el kawiñ, la fiesta etíope, la destrucción ni las unidades;
- los mapuches salen con la curva común de aldeanos (21 a los 5 minutos, igual que todas).

Varias conclusiones de abajo dependen de esos huecos.

---

## 1. Resuelto / no resuelto

| # | Problema de la vuelta 1 | Estado | Por qué |
|---|---|---|---|
| C1 | Rentas de hito sin tope | **Resuelto** | Ninguna renta queda en `parametros.json`; el modelo corre con `sin_rentas_de_hito`. Queda, sin cambios, la asimetría de las tasas de la edad IV (Cucaú +25 %, junco +15 %, qorikancha +15 % de recolección, contra hitos militares en las otras tres). Es una elección de hito, no un pasivo: **bajo** |
| C2 | Faenar en bucle | **Resuelto** | El kawiñ es uno por corral y por edad, a 30 por cabeza y con 120 s sin cría. Máximo de la partida: unos 1800 de alimento con 15 corrales-edad. Ya no hay bucle |
| C3 | Liberación por cualquier edificio y por encima del tope | **Resuelto** | Solo de edificios habitados, una cada 60 s, y por encima del tope se vuelve fama. Falta aclarar que la correría al ingenio (2 personas) no se suma a la liberación del mismo ingenio (otras 2) |
| C4 | Curva de aldeanos de Palmares y mapuches | **A medias** | Palmares sí está modelada (13 aldeanos a los 5 minutos, 21 a los 10). Los mapuches no: con +50 % de tiempo, dos lof producen ×1,67 y el modelo sigue dándoles 21 a los 5 minutos. Hay que simular N lof antes de dar por buena su curva |
| A1 | Corte de asedio junto al barreal rival | **Resuelto**, con una regresión | Extrae de lo propio y del centro, a más de 20 casillas de edificios enemigos y en 60 s. **Regresión:** Gondar "extrae 8 de **cualquier** barreal a ≤ 16 casillas". Tiene que decir "propio o del centro" |
| A2 | Varias cortes | **Resuelto** | Solo la capital extrae y da la bonificación, y la bonificación no se suma |
| A3 | Final de 119 a 255 r/min | **Resuelto en el modelo; no en la regla** | Da 144–160, pero solo con un aldeano por yerbal, bosque infinito, sin fiesta etíope y sin barrios chinos que se sumen. Los cuatro supuestos tienen que escribirse como reglas (N2, N3, N4 y A4). Si no, el techo real es 190–240 o no tiene límite |
| A4 | Ayutthaya sin bosque | **No resuelto** | La piedra **no está en todos los mapas en cantidad infinita**: son 2 afloramientos de 800 por jugador (`_res_sym("roca")`, `recursos.json`), y además los hitos III y IV la piden. 1600 de piedra al 25 % son 400 de riqueza en toda la partida. Los arbustos también se acaban. En el altiplano, después del minuto 40, el elefante vuelve a cero. El modelo no lo ve porque no agota el bosque |
| A5 | Ingenios como renta del final | **Resuelto para la riqueza** | Botín 150/100/50, 360 s y todo cuenta en el tope. **No resuelto para los extras:** las cabezas, la gente y el tambo inca no son riqueza, así que no los toca ni el tope ni el botín decreciente (N5, N6, N8) |
| A6 | Techo de lo disputado | **Resuelto en forma; faltan reglas** | Tope absoluto, ventana de 5 min y barra visible. Falta decir qué cuenta (N7): la extracción de la corte en el centro, las cabezas del arreo, las personas y qué pasa con lo que se extrae por encima del tope |
| A7 | Regimiento −30 % desde la edad I | **Resuelto** | −10 % por gult, tope −20 %, desde la edad II y solo a ≤ 14 casillas |
| A8 | Mudanza del final | **Resuelto**, y abre problemas nuevos | No hay carpa y no se frena la producción. Pero la corte nueva es gratis, se repite cada 5 minutos y trae fiesta (N1, N9 y N10) |
| M1 | Saqueo sobre cercas | **Resuelto** | El arreo no cuenta cercas, puertas ni caminos. Las granjas sí (N5) |
| M2 | Capuera | **Resuelto** | Arbustos de 40 que no cuentan como monte |
| M3 | Aliados en el yerbal | **Resuelto** | Nunca los aliados |
| M4 | Mercado | **Resuelto** | Piso 40 y regreso a 100 |
| M5 | Equipos | **Resuelto** | Lo disputado escala por jugador y los sitios bajan por equipo |
| M6 | Reglas del corral | **Resuelto** | — |
| M7 | Lugar parejo para la corte | **Resuelto** | Claro de 6×6 garantizado. Ojo: lo puede bloquear el rival (N9) |
| M8 | Guaraníes sin motor | **Resuelto** | Primer yerbal hacia el minuto 9 |
| M9 | Espiral de la mit'a | **Resuelto**, con un efecto lateral | El piso de 1/3 corre aun con la reserva puesta (N12) |
| M10 | Granja en el subproducto | **Resuelto** | `carry_src` |
| M11 | Lo que no se ve | **Resuelto** | Tabla de §3.7 |
| B1, B2 | Vecindad y detalles | **Resuelto** | Separación mínima. Los elefantes no tienen separación (N11) |

**Resumen:** de 4 críticos y 8 altos, quedan resueltos 3 críticos y 6 altos. C4 está a medias, A4 no está resuelto, y A3 y A6 dependen de reglas que todavía no están escritas.

---

## 2. Problemas nuevos

| # | Gravedad | Problema | Escenario | Arreglo |
|---|---|---|---|---|
| N1 | **Alto** | **La fiesta etíope es un temporizador que hay que cliquear** | La mudanza es gratis y no tiene ventana, así que lo óptimo es mudarse **cada 300 s exactos** entre dos claros a menos de 14 casillas de todos los gult. Por ejemplo, entre los dos barreales de la base, aunque estén agotados, porque la regla no pide que la arcilla tenga algo. Con 6 gult × 21 × 1,25 = 157 r/min, ×2 durante 60 s cada 300 s, son **+31 r/min (+20 %)**: 188, fuera del techo 135–165. Es exactamente lo que prohíbe la consigna en F | La fiesta solo si la corte nueva está a **≥ 25 casillas** de la anterior **y** a ≤ 12 de una arcilla con **≥ 300** restantes. Como máximo **una fiesta por arcilla** en la partida |
| N2 | **Alto** (crítico si se deja) | **Yerbal con varios aldeanos** | `recursos.json` define el yerbal de 3×3, como una mina. Si lo pueden trabajar varios aldeanos, el tope de 4 yerbales activos no limita la riqueza: con 20 rozas que terminan cada 8 minutos salen unos 2,4 yerbales por minuto, y 18 aldeanos a 40 r/min dan **~700 r/min** de una fuente renovable que rinde más que la arcilla (30). El techo de 156 del modelo es un artefacto de un aldeano por yerbal | **Un aldeano por yerbal**, igual que en la roza, escrito en la regla y en una prueba de sim |
| N3 | **Alto** | **Barrios chinos que se suman** | "+8 de tope **a cada** elefante" sin distancia ni límite. En la edad IV entran 3 barrios. Si los tres son chinos: 4 elefantes × (24 + 24) × 1,25 = **240 r/min**. Con el junco al 30 % alcanzan unos 19 leñadores. El modelo usa un solo barrio chino, como booleano | **Un solo barrio chino tiene efecto** (o +8 solo a los elefantes a ≤ 8 casillas del barrio, sin sumar dos barrios) |
| N4 | **Alto** | **La corte gratis es una fortaleza que se teletransporta** | Un centro cuesta 400 m + 300 de piedra y 120 s. La corte nueva no cuesta nada, sube en 60 s y tiene 2400 pv, 2 flechas, alcance 7000 y guarnición 15. A las 9:00 Etiopía funda junto a la arcilla del centro (las bases suelen estar a más de 20 casillas) y gana una torre gratis en lo disputado. Cada 5 minutos la lleva a donde está la pelea, siempre a más de 20 casillas de edificios enemigos | El cimiento nace con **25 % de vida**, sin flechas ni guarnición hasta que termina. No se puede fundar con unidades enemigas en combate a ≤ 15 casillas. Opcional: el cimiento cuesta **150 m** |
| N5 | **Alto** | **El arreo como ingreso que esquiva el tope** | Cada 150 de daño a un **ingenio** genera una cabeza, y las cabezas no son riqueza: no cuentan para el tope de lo disputado ni bajan con el botín decreciente. Un grupo mapuche **golpea el ingenio sin voltearlo**: 3 cabezas por minuto. Con los corrales llenos, cada cabeza son 40 de alimento, o sea, 120 a/min del ingenio, para siempre. Contra granjas del rival pasa lo mismo, porque la granja se repara | Las cabezas del arreo **cuentan para el tope de lo disputado** (1 cabeza = 16 r, cuatro minutos de renta). Del ingenio, el arreo sale solo **al destruirlo** (2 cabezas, como dice §2.4), no por daño. De granjas, una cabeza cada 150 de daño **real** (la reparación no vuelve a habilitarla) |
| N6 | Medio | **Las personas de Palmares tampoco cuentan** | 2 personas por ingenio, sin botín decreciente ni tope. En un 4 contra 4 hay 8 ingenios: unas 16 personas cada 6 minutos, es decir, 2,7 aldeanos por minuto gratis. Con la población llena, cada una pasa a fama, y la fama paga gente de guerra | Las personas de la correría siguen el botín decreciente (2 / 1 / 0 por ingenio y por edad), y cada una cuenta 28 de riqueza para el tope |
| N7 | Medio | **El tope no dice qué cuenta ni qué pasa con lo que sobra** | (a) La corte etíope en el centro saca 24 r/min en la edad IV: si no cuenta, Etiopía se salta medio tope. (b) "Lo que pasa se pierde": el que va ganando puede vaciar la arcilla del centro sin ganar nada, solo para negársela al otro | Cuentan la corte en el centro, el botín, las cabezas (N5) y las personas (N6). Por encima del tope, **lo disputado no se extrae**: el aldeano queda quieto con aviso y la arcilla queda en el pozo |
| N8 | Medio-alto | **Regalo de cumbi: le niega el ingenio al rival** | "1 ingenio por jugador" y el regalo incorpora el ingenio **para siempre** como tambo. En un 1 contra 1, el inca regala cumbi a los dos ingenios en la edad III (240 de mit'a): se lleva 300 de botín, el rival pierde su fuente para el resto de la partida, y si el tambo conserva las flechas del ingenio, gana una torre de su lado | El regalo solo vale para el ingenio de **su mitad del mapa**. El tambo no tiene flechas, cuenta como edificio inca común, y si se destruye el ingenio vuelve a ser neutral a los 360 s. El botín sigue la tabla decreciente |
| N9 | Medio-alto | **El rival le bloquea la mudanza a Etiopía** | "A más de 20 casillas de **cualquier** edificio enemigo." Un camino inca (2 de mit'a), una casa, un tramo de cerca o un corral a 20 casillas del barreal de flanco etíope le prohíbe fundar ahí. Cuando se acaba la arcilla de casa, Etiopía no tiene adónde ir: la capa 1 muere | Cuentan solo centros, torres, cuarteles y edificios de ≥ 150 de costo. Los barreales de la base y del flanco propios **siempre** se pueden usar (el claro garantizado es del dueño) |
| N10 | Medio | **Curación por mudanza** | La corte vieja tiene 400 de vida bajo asedio. Etiopía funda lejos, la nueva sube en 60 s con la vida llena y la vieja se desarma sin morir. Es una curación de 2000 pv cada 5 minutos, y además nunca hay que reconstruir un centro de 700 recursos | La corte nueva hereda el **porcentaje de vida** de la vieja (como hoy empacar, `sim.gd:408`). Si la vieja cae antes de que termine la nueva, el cimiento se cancela |
| N11 | Medio | **Los elefantes sin separación ni riesgo** | No tienen separación mínima. Los 4 se quedan juntos en el bosque de la base, con la guardia encima, y la "decisión espacial" desaparece hasta que el bosque se termina. Si los atacan, se retiran (600 pv, unidad) y se reponen en 30 s por 160 recursos. Es el motor más difícil de castigar | Separación de 8 casillas entre elefantes que están entregando (si hay dos juntos, solo cobra uno). Tiempo de entrenamiento 30 → **45 s** |
| N12 | Medio | **El piso de 1/3 del taller convierte la tela en renta** | Con la reserva en 120 y la mit'a por debajo, los talleres no consumen nada y siguen rindiendo 8 r/min cada uno: **50 r/min sin costo** con 5 talleres y la tecnología, mientras toda la mit'a va a levas instantáneas (5 awqa por minuto). La tensión tela o leva baja a 2/3 | El piso de 1/3 rige **solo con la reserva en 0** (es decir, cuando falta mit'a porque murieron runa, no porque se guardó) |
| N13 | Medio | **"Con la población llena, la fama paga gente de guerra"** | Si llena es llena, el guerrero no entra. Si entra igual, es un desborde del tope de población, como en C3 | El guerrero por fama respeta el tope de población. Con la población llena, la fama se queda en su tope de 300 y se pierde |
| N14 | Medio | **Oficios parados con un solo hostigador** | "En combate = 5 s desde el último golpe." El alcance del mocambo es 6000. El cañón de tacuara (6500) o cualquier unidad que pegue y se vaya cada 4 s deja quietos 3 oficios (45 r/min) sin arriesgar nada | Los oficios paran mientras el mocambo **pierde ≥ 2 % de vida en 5 s** o hay ≥ 3 enemigos a ≤ 6 casillas, no con cualquier golpe |
| N15 | Bajo | **La roza que se reabre sola gasta la madera sin avisar** | Con 15 rozas, unos 67 m/min se van solos. En una emergencia militar, el guaraní descubre que no tiene madera | Un aviso "rozas en espera: falta madera", y que la resiembra deje 100 de madera de reserva antes de gastar |
| N16 | Bajo | **Hitos convertidos que no son decisión** | El aqllawasi da 5 talleres en la III, pero en la IV son 5 igual: solo adelanta una edad. El junco sube el subproducto al 30 % pero no el tope de 24: solo ahorra un leñador por elefante. El monasterio (radio 16) pierde contra la iglesia (+10 % de recolección) casi siempre | Junco: +4 de tope por elefante en vez del 30 %. Monasterio: radio 16 **y** el gult de regimiento hasta −25 %. Aceptable si el autor lo prefiere así |
| N17 | Bajo | **Parlamento con pradera pasa el techo** | 6 corrales × 7 cabezas × 4 = 168, por encima de 165 | Tope de la edad IV a 6 sin pradera adicional, o pradera +1 solo hasta la edad III |

---

## 3. Lo que probé contra los seis puntos pedidos

- **Elefante del rey.** Lo rompen la suma de barrios chinos (N3), la piedra finita (A4) y la falta de separación (N11). No pude romperlo con depósitos de aliados ni del rival (`nearest_dropoff` exige el mismo dueño) ni con la comida de arrozal (`carry_src`).
- **Corte nueva sin carpa.** Resuelve A8 y crea N1, N4, N9 y N10. Es la pieza que más cambió y la que más necesita reglas.
- **Arreo y kawiñ.** El kawiñ resiste: no hay bucle. El arreo esquiva el tope por no ser riqueza (N5).
- **Roza que se reabre sola.** Está bien si el yerbal es de un solo aldeano (N2). Si no, es el abuso más grande del diseño.
- **Tope absoluto.** Bien como forma. Le faltan qué cuenta y qué pasa con el excedente (N7), y lo esquivan las cabezas y las personas (N5, N6).
- **Hitos convertidos.** No queda ningún pasivo sin tope. Lo que sobra son efectos débiles (N16) y uno que pasa el techo (N17). Hay que corregir el texto de Gondar (A1).

---

## 4. Pedidos al modelo

1. Agotar el bosque, la piedra y los arbustos por mapa, y medir Ayutthaya en el altiplano y en las mesetas a los 40 y 45 minutos.
2. Simular la mudanza etíope cada 300 s con fiesta, para confirmar N1.
3. Simular N lof mapuches.
4. Dejar como parámetro "aldeanos por yerbal" y correr con 1 y con 3.
