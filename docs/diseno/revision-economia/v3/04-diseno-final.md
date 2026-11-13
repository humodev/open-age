# Ronda 3 · 04 — Diseño económico final (para el autor)

Este documento es autocontenido: reemplaza a [`01-diseno-lider.md`](01-diseno-lider.md) y a [`03-diseno-revisado.md`](03-diseno-revisado.md).

De dónde sale:
- dos vueltas de cinco críticas ([`criticas/`](criticas/));
- el modelo numérico ([`02-modelo-numerico.md`](02-modelo-numerico.md), `tools/modelo_economia.py`).

Los números están en [`parametros.json`](parametros.json) (versión `v3-04`), que el modelo lee directamente. No se tocaron `data/` ni `src/`, y no hay commits.

---

## Resumen en palabras llanas

**Qué es la riqueza.** Sigue siendo un solo recurso, el rombo dorado, con los mismos costos para todas las civs. Cada pueblo la consigue de dos maneras.

**Primera manera: la arcilla, igual para todos.**
- Junto a cada base hay pozos de arcilla, en lugar de la "mina de oro". Los aldeanos sacan arcilla y hacen las vasijas de la fiesta: con lo que se sirve en ellas se convida, se ofrenda y se paga.
- La elegimos porque **los seis pueblos tenían alfarería**. La sal no la tenían todos: Palmares la compraba.
- La arcilla de casa se acaba entre los minutos 12 y 24. Es la apertura, como el oro de la base en Age.

**Segunda manera: el motor propio, distinto en cada pueblo.**

| Pueblo | Qué hacés | Qué recibís |
|---|---|---|
| Tawantinsuyu | Tu gente genera turnos de trabajo (mit'a) | Los talleres los convierten en tela, que es riqueza |
| Mapuches | Criás ganado en corrales | Cada cabeza da riqueza. En un malón, el ganado que tomás vuelve caminando a tu corral, y el rival lo puede cortar |
| Guaraníes | En vez de granjas abrís rozas | Dan comida, se agotan y dejan un yerbal que da riqueza. Después la roza se vuelve a abrir sola |
| Etiopía | Repartís tierras (gult) que pagan tributo en amole, las barras de sal | Rinden más cerca de la corte. La corte saca riqueza del pozo que tiene al lado y, cuando se agota, se funda en otro lugar con una fiesta |
| Palmares | No entrenás gente: llega sola por la fama | Los que trabajan en un oficio dentro del mocambo (herrero, alfarero, cestero) dan riqueza segura |
| Ayutthaya | Tus elefantes del rey son depósitos que caminan | Una parte de lo que reciben del monte (madera, piedra, lo que se junta) y del arroz es del rey |

**Cómo conviven las dos maneras.**
- Al principio todos viven de la arcilla. El motor se arma pieza por pieza.
- Cuando la arcilla se acaba, el motor sostiene la partida. Los seis motores rinden lo mismo al final: entre 144 y 160 de riqueza por minuto.
- Lo que se pelea en el centro (arcilla, sitios sagrados, ingenios neutrales) suma, pero **tiene un tope por minuto**. Nadie pierde la partida por perder una región.

**Qué te pide cada pueblo.** Una o dos decisiones de verdad por edad y nada que haya que cliquear cada tanto. Ninguna civ depende de esconderse, de comerciar, de un río ni de una ladera.

**Qué dice el modelo.**
- Las seis civs juntan riqueza parecida: ±12 % como máximo a los 5, 10, 20 y 30 minutos.
- Todas llegan a la edad II entre 6:30 y 8:50 y a la III entre 13:30 y 14:40.
- Ningún mapa favorece o castiga más de 6 %.
- Quedan cuatro puntos fuera de banda; se detallan en §8.

**Cuánto cuesta hacerlo.** Entre 62 y 67 días-persona, en siete etapas que se aprueban con números.

**Qué tenés que decidir vos.** Siete preguntas, al final (§12), cada una con una opción recomendada.

---

## 1. Problemas de la segunda vuelta y cómo se resolvieron

Leyenda:
- **A**: aceptado;
- **M**: aceptado con cambios;
- **R**: rechazado.

### 1.1 El que intenta romperlo (01b)

| # | Problema | Resp. | Resolución |
|---|---|---|---|
| A3 | El final en 144–160 solo se sostiene en el modelo | **A** | Las cuatro suposiciones del modelo pasan a ser reglas escritas (§3.6):<br>– un aldeano por yerbal;<br>– un solo barrio chino tiene efecto;<br>– una fiesta por arcilla;<br>– el bosque finito.<br>El modelo ahora agota el bosque y llega al minuto 45 |
| A4 | Ayutthaya sin bosque | **A** | El elefante cobra también el 10 % del arroz y de la comida de granja que se le entrega: tiene piso en cualquier mapa. Modelo: con el bosque cercano agotado (altiplano 32:50, valle 44:10), sigue en 160 r/min |
| A1 | Gondar extrae de "cualquier" arcilla | **A** | Extrae 24 de arcilla propia o del centro a ≤ 16 casillas. Con Gondar ya no se funda otra corte |
| A5 / A6 | Las cabezas y las personas esquivan el tope; no está dicho qué cuenta | **A** | Cuentan para el tope:<br>– la arcilla del centro, también la que saca la corte;<br>– sitios y botín;<br>– cabezas (16 r cada una);<br>– personas (28 r cada una);<br>– el regalo de cumbi.<br>Por encima del tope, **no se extrae**: el aldeano queda quieto con aviso y la arcilla se queda en el pozo |
| C4 | Curva de aldeanos de los mapuches | **A** | El modelo da al lof de flanco su propia cola (+50 % de tiempo). Cambia poco: los mapuches levantan ese lof tarde |
| N1 | La fiesta etíope es un temporizador | **A** | Solo si la corte nueva queda a ≥ 25 casillas de la anterior y a ≤ 12 de una arcilla con ≥ 300. Como máximo una fiesta por arcilla en toda la partida |
| N2 | Varios aldeanos por yerbal (~700 r/min) | **A** | **Un aldeano por yerbal**, como en la roza. Es regla y prueba de simulación |
| N3 | Barrios chinos que se suman | **A** | Un solo barrio chino tiene efecto: +4 de tope por elefante. Cuesta 100 de madera |
| N4 | La corte gratis como torre que se muda | **A** | El cimiento cuesta 150 m, nace con 25 % de vida, no tiene flechas ni guarnición hasta terminar y no se puede fundar con enemigos en combate a ≤ 15 casillas |
| N5 | El arreo como ingreso sin tope | **A** | De los ingenios, 2 cabezas solo al destruirlos. De granjas, casas y corrales, 1 cada 150 de daño real (la reparación no lo rehabilita). Cuentan para el tope |
| N6 | Personas de Palmares sin tope | **A** | 2 / 1 / 0 por ingenio y por edad; cuentan 28 r cada una |
| N7 | Qué pasa con lo que sobra del tope | **A** | No se extrae (ver A5/A6) |
| N8 | El regalo de cumbi le niega el ingenio al rival | **A** | Solo el ingenio de su mitad; el tambo no tiene flechas; si se destruye, vuelve a ser neutral a los 360 s; el botín es decreciente |
| N9 | El rival bloquea la mudanza etíope | **A** | Solo bloquean centros, torres, cuarteles y edificios de ≥ 150 de costo. Los claros de las arcillas propias **siempre** se pueden usar |
| N10 | Curarse mudando la corte | **A** | La corte nueva hereda el porcentaje de vida de la vieja. Si la vieja cae antes, se cancela el cimiento |
| N11 | Elefantes sin separación ni riesgo | **A** | Entre elefantes que reciben entregas hay 8 casillas; si están más cerca, cobra uno solo. Se entrenan en 45 s, no tienen ataque y su armadura a distancia es 0 |
| N12 | El piso de 1/3 vuelve la tela una renta | **A** | El piso rige solo con la reserva en 0, es decir, cuando la mit'a falta porque murieron runa |
| N13 | La fama paga guerreros por encima del tope | **A** | El guerrero por fama respeta el tope de población. Con la población llena, la fama se queda en 300 y lo que entra se pierde. El modelo no cuenta esos minutos como "en el tope" |
| N14 | Un hostigador apaga los oficios | **A** | Paran solo si el edificio pierde ≥ 2 % de vida en 5 s o hay ≥ 3 enemigos a ≤ 6 casillas |
| N15 | La resiembra se come la madera | **A** | La resiembra deja 100 de madera de reserva y avisa "rozas en espera" |
| N16 | Hitos convertidos que no deciden | **M** | El junco da +4 de tope por elefante (no el 30 %). El monasterio queda en radio 16; acepto que sea el hito débil del par |
| N17 | Parlamento con pradera pasa el techo | **A** | Un corral tiene como máximo 6 cabezas: pradera y tecnología no se suman |

### 1.2 Jugador competitivo (02b)

| Punto | Resp. | Resolución |
|---|---|---|
| Guaraníes en la edad III a las 10:20 | **A** | La palanca era la comida, como dijo. La roza pasa a 90 de madera y su tasa a 1000. Modelo: edad III a las 13:30 (antes 10:40), con la riqueza en la media |
| Regimiento roto | **A** | −15 % por gult, hasta −30 %, desde la edad II, para jinetes entrenados a ≤ 14 casillas. La cola guarda el costo pagado (trampa del cancelar) |
| Fiesta repetible y centro adelantado gratis | **A** | N1 y N4 |
| Un arquero apaga los oficios | **A** | N14 |
| El arreo no tiene adónde ir | **A** | La cabeza **siempre camina**: al corral con lugar o, si no hay, al más cercano. Al llegar sin lugar, da 40 de alimento. La persecución existe siempre |
| Sacarle a Ayutthaya el depósito común | **A** | Ayutthaya no construye depósito común: el elefante y el palacio son sus depósitos |
| Elefante como escudo | **A** | Sin ataque, armadura a distancia 0, no militar (`is_military` falso) |
| Cumbi y emboscada desde el yerbal, al núcleo | **A** | Los dos entran al núcleo. La captura de manadas sigue en la fase 2 |
| ¿La fiesta es núcleo o fase 2? | **A** | Núcleo (§3.5.4) |
| El kawiñ no es decisión | **A** | No lo cuento como decisión: es un paso de la apertura con tope |

### 1.3 Programador de IA (03b)

| Punto | Resp. | Resolución |
|---|---|---|
| H1 Gondar | **A** | Ver A1 |
| H2 Fiesta | **A** | Ver N1 |
| H3 Fama guardada para el hito | **A** | Botón "guardar fama para el hito", prendido por defecto |
| H4 Ventana de 5 min | **A** | Cinco baldes de un minuto, en el hash |
| H5 Capuera | **A** | La capuera no reabre roza: deja el suelo libre |
| Costo real de 60 a 65 días | **A** | Con el cumbi y la emboscada en el núcleo: **62–67** |
| J `is_military` | **A** | Lista blanca (`choque`, `distancia`, `linea`, `asedio`) |
| K Amenazas | **A** | La IA ignora a las unidades no militares |
| Cancelar devuelve el precio actual | **A** | La cola guarda el costo pagado |
| Ingenio neutral (tres funciones del núcleo) | **A** | Va en la etapa 4 |
| Orden de implementación | **A** | El suyo, en §9 |
| Guaraníes al 73 % de motor | **A** | Con la roza de 90 m: 51 % |
| Otros detalles | **A** | – la carpa de campaña no da bonificación;<br>– distancias medidas borde a borde;<br>– el mensaje de fundación no revela edificios ocultos;<br>– consumo de mit'a en milésimas;<br>– la cabeza con `pob: 0` y no seleccionable;<br>– el elefante quieto anclado frente a la separación |

---

## 2. Fuente común: "Arcilla (barreal)"

### 2.1 Por qué arcilla y no sal

| Pueblo | Sal propia | Alfarería y vasija de la fiesta |
|---|---|---|
| Tawantinsuyu | Sí (Maras, salares) `[falta cita]` | Urpu para la chicha estatal (Bray 2003) |
| Mapuches | Sí (salinas de la pampa, siglo XVIII) `[verificar]` | Metawe, para el muday |
| Guaraníes | Escasa `[verificar]` | Cambuchí, para el kaguĩ del convite (La Salvia y Brochado) |
| Etiopía | Sí: era moneda, el amole (Álvares, cap. XLIV) | Insəra, para la tälla `[verificar grafía]` |
| Palmares | **No: la compraba** (`palmares.md`) | Cerámica de la Serra da Barriga (Funari y Orser); vino de palma |
| Ayutthaya | Probable `[sin fuente]` | Jarras de Mae Nam Noi (exportación) |

**Simplificación declarada:** la arcilla no se agota en la realidad; que el pozo se termine es una regla de juego.

**En pantalla:**
- tooltip: "Tus aldeanos sacan arcilla y hacen las vasijas de la fiesta: con lo que se sirve en ellas se convida, se ofrenda y se paga";
- el aldeano vuelve con una vasija con una banda dorada;
- el pozo tiene una pila de vasijas.

### 2.2 Cantidades

| Lugar | Cantidad | Dueño | Se agota (modelo) |
|---|---|---|---|
| Base | 2 × 900 | El jugador | 13:30 a 18:40 |
| Flanco (a 18 casillas) | 1500 | El jugador | 17:10 a 24:10 |
| Centro | 1000 por jugador, en pares | Centro (disputado) | — |

El generador deja un **claro parejo de 6×6 a ≤ 8 casillas de cada arcilla**, antes de poner bosques y relieve.

---

## 3. El diseño

### 3.1 Reglas comunes

| Regla | Valor |
|---|---|
| Pieza pasiva | Como máximo 0,8 AE (24 r/min); repago de 5 a 8 min |
| Máximo por edad | 2 / 3 / 4 / 5, con las excepciones de cada civ |
| Separación | Corral a ≥ 8 casillas de otro corral; gult a ≥ 6; elefantes que reciben entregas a ≥ 8 |
| Tecnología de motor | Investigación en la edad III, +25 %, 200 a + 200 m + 100 r, igual para las seis |
| Techo del motor en la edad IV | 135–165 r/min |
| Motor en los minutos 15–25 | 35–65 % de la riqueza |
| Hito II | 500 a + 300 r |
| Mercado | Piso 40, paso 3, regreso hacia 100 a 1 punto cada 10 s |
| Rentas de hito | Ninguna (§3.3) |
| Cola de producción | Guarda el costo pagado |
| Unidades no militares | El elefante del rey y la cabeza de arreo: no cuentan como ejército, no hacen sonar la campana y la IA no las trata como amenaza |

### 3.2 Lo disputado

| Pieza | Regla |
|---|---|
| Tope | **15 / 40 / 80 / 120 r/min** por edad, contado en 5 baldes de 1 min, con la barra "Lo disputado: 52 / 80". Por encima, no se extrae |
| Qué cuenta | Arcilla del centro (aldeanos y corte), sitios, botín, cabezas (16), personas (28), regalo de cumbi |
| Arcilla del centro | 1000 por jugador |
| Sitios sagrados | Jugadores + 1, espejados; rinden 18 / 12 / 8 por equipo |
| Ingenios y estancias | Neutrales y hostiles: `owner = -1`, flechas propias, 1500 pv, no persiguen. 1 por jugador, desde la edad II. Botín 150 / 100 / 50 por jugador y por edad. Se rehacen a los 360 s si no hay enemigos a 12 casillas |

### 3.3 Hitos: sin renta, con efecto sobre el motor

| Hito | Efecto |
|---|---|
| Ushnu | Sin renta (+10 % de alimento, como hoy) |
| Aqllawasi | 5 talleres en la edad III |
| Rewe del lonko | Cría cada 35 s |
| Parlamento | 6 corrales en la edad IV |
| Pueblo de misión | Yerbal +50 |
| Monasterio | Radio de la corte 16 |
| Macaco | 20 de fama (antes 40) |
| Pacto de Cucaú | Sin renta (+25 % de recolección, como hoy) |
| Guerra de Zumbi | Sin renta |
| Puerto real | 4 elefantes en las edades III y IV |
| Junco de tributo | +4 de tope por elefante |

### 3.4 Lo que separa a cada motor

| Civ | Forma | Se alimenta de… | Se pierde por… | Momento |
|---|---|---|---|---|
| Tawantinsuyu | Conversión | Gente viva (mit'a) | Matar runa; los talleres caen a 1/3 | **Regalo de cumbi**: un ingenio sin pelear |
| Mapuches | Capital vivo | Tiempo (cría) y malón | Cabezas muertas en cada golpe | **El arreo**, que vuelve caminando y se puede cortar |
| Guaraníes | Sucesión en el mismo lugar | Trabajo sobre la tierra | Rozas quemadas; yerbales cosechados por el enemigo | **Arqueros que emboscan desde el yerbal** |
| Etiopía | Renta según dónde está una capital móvil | Tierra repartida y posición de la corte | Gult lejos de la corte o quemados | **La corte se funda en otro lugar**, con fiesta |
| Palmares | Gente adentro | Fama (gente que llega) | Un asedio de verdad frena los oficios | **Los liberados vuelven a pie** |
| Ayutthaya | Depósito que camina | Lo que entra del monte y del arroz, donde está el elefante | Matar al elefante (600 pv, sin ataque) | **Los elefantes del rey** (la captura de manadas, en la fase 2) |

### 3.5 Las seis civs

#### 3.5.1 Tawantinsuyu — "El trabajo que sobra se vuelve tela"

- **Capa 1, mejor:** arcilla unida por camino a la llaqta, +20 %.
- **Capa 2, taller de tejido:**
  - 120 m + 20 de mit'a, 600 pv;
  - consume 30 de mit'a por minuto (acumulador en milésimas) y da 24 de riqueza;
  - máximo 2 / 3 / 4 / 5, y 5 en la edad III con el aqllawasi.
- **Mit'a:** 4 por runa en las edades I y II, 3 desde la III. Tope de 200, +100 por qollqa y +50 por centro.
- **Reserva** (global: 0, 60 o 120; por defecto 0): los talleres consumen solo lo que está por encima.
- **Piso:** si falta mit'a con la reserva en 0, los talleres rinden 1/3.
- **Regalo de cumbi** (edad III):
  - 120 de mit'a por el ingenio de su mitad del mapa;
  - cobra el botín decreciente sin pelear;
  - queda un tambo inca sin flechas, que vuelve a ser neutral a los 360 s si lo destruyen.
- **Decisiones:** cuánta mit'a guarda para leva y cuánta va a tela; a qué ingenio regala cumbi y cuándo.
- **Historia:** el Estado cobraba en trabajo, y la tela fina (cumbi) era su regalo político (Murra).

#### 3.5.2 Mapuches — "La riqueza camina y se reproduce"

- **Capa 1:** igual. El lof es depósito.
- **Capa 2, corral:**
  - 120 m, 600 pv, separación de 8 casillas;
  - de 1 a 5 cabezas, o 6 en pradera (sin árboles a 3 casillas, calculada al completar y cada 60 s);
  - **nunca más de 6**;
  - 4 r/min por cabeza;
  - una cabeza cada 45 s, o 35 con el lonko;
  - máximo 2 / 3 / 4 / 5, y 6 con el parlamento.
  - Cada 25 % de vida perdida mata 1 cabeza, nunca por debajo de 1. Reparar no devuelve cabezas.
- **Kawiñ (la fiesta):**
  - 30 de alimento por cabeza;
  - deja 1 cabeza;
  - 120 s sin cría;
  - uno por corral y por edad;
  - no se puede en combate.
- **Malón = arreo:**
  - 1 cabeza cada 150 de daño real a granjas, casas o corrales, como máximo 3 por minuto;
  - de los ingenios, 2 cabezas solo al destruirlos;
  - la cabeza (60 pv, `pob: 0`, no seleccionable) **siempre camina** al corral con lugar más cercano, o al más cercano si no hay lugar;
  - al llegar entra al corral, o da 40 de alimento si está lleno;
  - el rival la puede matar en el camino;
  - cuenta 16 r para el tope de lo disputado.
- **Lof extra:** entrenan aldeanos con +50 % de tiempo.
- **Decisiones:** dónde va cada corral; malón al rival o a lo neutral.
- **Historia:** el ganado era riqueza y prestigio, y el malón lo arreaba (León Solís; Boccara).

#### 3.5.3 Guaraníes — "El campo que se agota deja un yerbal"

- **Capa 1, mejor:** +14 % en la arcilla.
- **Capa 2, roza:**
  - **90 m**, 500 de alimento, tasa **1000**;
  - +15 % con 4 árboles o más a 2 casillas;
  - al agotarse deja un yerbal de 300 (tasa 800) y **el mismo aldeano** lo cosecha: **un aldeano por yerbal**;
  - al agotarse el yerbal, la roza se reabre en el mismo lugar (resiembra con interruptor, que deja 100 de madera de reserva y avisa si espera);
  - yerbales activos 3 / 4 / 4 / 4; por encima, **capuera** (arbustos con 40 de madera, que no reabren roza ni cuentan como monte);
  - quemada con más del 50 % consumido, deja igual el yerbal;
  - el yerbal lo cosechan el dueño y sus enemigos, nunca los aliados.
- **Modo del monte** (global):
  - **dejar crecer** (por defecto): roza → yerbal → roza;
  - **quemar:** roza → roza al 60 %, sin yerbal.
- **Emboscada:** el yerbal cuenta como monte para el sigilo de los arqueros.
- **Semilla:** yerbal viejo de 100.
- **Decisiones:** dejar crecer o quemar; dónde abrir rozas nuevas al crecer (monte o casa).
- **Historia:** la chacra vieja se volvía huerto y yerbal (Noelli et al.), y en la colonia la yerba fue moneda.

#### 3.5.4 Etiopía — "La tierra paga a la corte que está cerca"

- **Riqueza = amole:** mismo recurso, otro nombre e ícono.
- **Capa 1, distinto:** la corte **capital** extrae de la arcilla propia o del centro a ≤ 12 casillas, medidas borde a borde, sin aldeanos:
  - 12 / 16 / 20 / 24 r/min según la edad;
  - nunca de la arcilla del rival;
  - lo que saca del centro cuenta para el tope.
- **Capa 2, gult:**
  - 100 m + 40 a, 500 pv, separación de 6 casillas;
  - renta base 3 a + 17 r; a ≤ 14 casillas de la corte, 3 a + 21 r, sin sumar dos cortes;
  - máximo 2 / 3 / 4 / 6;
  - **señor** (por defecto) o **regimiento**: desde la edad II, sin renta, −15 % a los jinetes entrenados a ≤ 14 casillas, hasta −30 %. No se cambia.
- **Corte nueva** (no hay carpa en escaramuza):
  - el cimiento cuesta 150 m, nace con 25 % de vida, no tiene flechas ni guarnición, y se levanta solo en 60 s;
  - la vieja sigue siendo capital y produciendo hasta que termina la nueva; la nueva hereda el porcentaje de vida;
  - si la vieja cae antes, el cimiento se cancela;
  - una cada 5 minutos como mínimo;
  - no se puede a menos de 20 casillas de centros, torres, cuarteles o edificios enemigos de ≥ 150, ni con enemigos en combate a ≤ 15. Los claros de las arcillas propias siempre se pueden usar.
- **Fiesta de llegada:**
  - los gult a ≤ 14 casillas rinden ×2 durante 60 s;
  - solo si la corte nueva está a ≥ 25 casillas de la anterior y junto a una arcilla con ≥ 300;
  - una por arcilla en la partida.
- **Gondar (IV):** capital fija que extrae 24 de lo propio o del centro a ≤ 16. Ya no se funda otra corte.
- **Decisiones:** dónde va el gult; señor o regimiento; cuándo y adónde se funda la corte.
- **Historia:** el gult se daba y se quitaba (Álvares; Tsehai Berhane-Selassie). La corte agotaba su entorno (Horvath). El amole era la moneda.

#### 3.5.5 Palmares — "La riqueza es lo que la comunidad sabe hacer"

- **Capa 1:** igual.
- **Capa 2, oficios** (herrero, alfarero, cestero, tejedor de palma):
  - 3 puestos por mocambo y 2 en la cerca real;
  - 15 r/min cada uno;
  - tope 4 / 7 / 8 / 8;
  - se llenan solos (el edificio que acoge más cercano a la capital; empate por `id`), y se saca gente con "desalojar";
  - separados de la guarnición: la campana no los vacía;
  - **paran** si el edificio pierde ≥ 2 % de vida en 5 s o hay ≥ 3 enemigos a ≤ 6 casillas;
  - no suman flechas.
- **Mocambo:** 130 m, sin `oculto`; +5 de fama por minuto con 6 árboles o más a 4 casillas o menos.
- **Fama:**
  - 90 iniciales, tope de 300;
  - el hito II pide 90 de fama (botón "guardar fama para el hito", prendido por defecto);
  - gente de guerra por 40 de fama + 30 a, dentro del tope de población.
- **Liberación:**
  - solo de edificios habitados, una por edificio cada 60 s;
  - por encima del tope de población, 28 de fama;
  - en los ingenios, 2 / 1 / 0 personas por edad, que cuentan 28 r para el tope;
  - los liberados **vuelven a pie**.
- **Decisiones:** correría o esperar la fama; desalojar oficios para mandar gente al campo.
- **Historia:** riqueza en personas (Miller; Guyer y Belinga) y las cuarenta herrerías de 1694.

#### 3.5.6 Ayutthaya — "El monte paga al rey"

- **Capa 1:** igual. **No construye depósito común**: sus depósitos son el palacio y los elefantes.
- **Capa 2, elefante del rey:**
  - unidad no militar: 80 a + 80 m, 45 s, 600 pv, sin ataque, armadura a distancia 0, población 2;
  - depósito de madera, alimento y piedra;
  - entra como riqueza **el 25 %** de la madera, los arbustos y la piedra (sapán, cueros y estaño) y **el 10 %** de la comida de granja y arrozal (el arroz del rey), según el origen de la carga (`carry_src`);
  - tope 16 en la edad I y 24 desde la II;
  - máximo 1 / 2 / 3 / 3, y 4 con el puerto real;
  - separación de 8 casillas entre elefantes que reciben (si están más cerca, cobra uno);
  - quieto, no lo empuja la separación de unidades.
- **Barrio chino** (100 m): +4 de tope a cada elefante, y uno solo tiene efecto.
- **Barrios japonés y portugués:** compañías, −15 % si tocan un cuartel. Ningún barrio da renta.
- **Arrozal junto al agua:** +25 %.
- **Decisiones:** dónde está cada elefante (bosque, piedra, granjas; cerca o lejos); qué barrio.
- **Historia:** el monopolio del almacén real sobre sapán, cueros y estaño (`ayutthaya.md` H19, H23) y los elefantes de la corona (H36–H38). El 10 % del arroz `[verificar el tributo en arroz]`.

### 3.6 Reglas que el modelo daba por supuestas (ahora escritas)

1. **Un aldeano por yerbal**, igual que por roza.
2. **El bosque se acaba.** La madera alcanzable por jugador es la del bosque de la base, la mitad de los bosques del mapa y el borde. Cuando se termina el bosque cercano, se tala lejos, a la mitad de la tasa.
3. **Una fiesta por arcilla**, con las condiciones de §3.5.4.
4. **Un solo barrio chino** tiene efecto.
5. **Un corral tiene como máximo 6 cabezas.**
6. **Ninguna renta de hito.**
7. **Lo que pasa del tope disputado no se extrae.**
8. **La cola guarda el costo pagado.**

### 3.7 Interfaz

**Vista previa al ubicar** (para todas las piezas):
- radio de separación;
- número de rendimiento, por ejemplo "+15 % junto al monte", "pradera: 6 cabezas" o "cerca de la corte: 21";
- botón con el contador, por ejemplo "Corral 2/3".

**Estados**, sin sonido:

| Civ | Estados |
|---|---|
| Tawantinsuyu | Mit'a neta; reserva; telar quieto |
| Mapuches | Cabezas por corral; recría del kawiñ |
| Guaraníes | Yerbales 4/4; modo del monte; rozas en espera |
| Etiopía | Radio de la corte; bandera de señor o de regimiento; amole que viaja de la arcilla a la corte |
| Palmares | Íconos de 0 a 3 oficios |
| Ayutthaya | Fardos en el elefante; tope |
| Todas | Barra de lo disputado; desglose de la riqueza por origen en el tooltip |

**Avisos**, como máximo 3 de decisión por civ en una partida típica:

| Clase | Aviso |
|---|---|
| Decisión | "La arcilla de la corte se agotó: fundá otra corte" |
| Decisión | "Yerbales al tope" (la primera vez) |
| Decisión | "Lo disputado llegó a su tope" (una vez por edad) |
| Pérdida | "Talleres a 1/3" |
| Pérdida | "Atacan corral, mocambo, gult o elefante" |
| Pérdida | "Arcilla agotada: N aldeanos inactivos" |
| Pérdida | "Rozas en espera: falta madera" |
| Hito | Primer yerbal; llega un arreo; tecnología de motor |

---

## 4. Terreno

Economía total al minuto 20 contra el llano de la misma civ. Valores del modelo v3-04:

| Civ | llano | montaña | río | bosque | valle | altiplano | b. templado | selva | mesetas | delta | sierra |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Tawantinsuyu | 0 | +5 | 0 | +1 | +3 | −3 | +5 | 0 | +3 | −1 | +5 |
| Mapuches | 0 | 0 | 0 | 0 | −1 | 0 | 0 | 0 | −2 | −1 | 0 |
| Guaraníes | 0 | 0 | 0 | +2 | −5 | −5 | +2 | +2 | −3 | −2 | +2 |
| Etiopía | 0 | 0 | 0 | 0 | −3 | −5 | 0 | 0 | −2 | −2 | 0 |
| Palmares | 0 | 0 | 0 | +1 | −5 | −5 | +1 | +1 | −4 | −2 | 0 |
| Ayutthaya | 0 | +1 | +1 | +1 | −3 | −4 | +1 | 0 | −4 | +2 | −3 |
| *Diferencia por mapa* | 0 | 4,6 | 1,4 | 2,4 | **8,1** | 5,4 | 4,9 | 2,4 | 7,0 | 4,0 | 7,3 |

Lectura:
- Todas las celdas están en ±6 y todas las columnas en ≤ 10.
- Ayutthaya en el final, con el bosque cercano agotado (altiplano 32:50, valle 44:10), mantiene 160 r/min gracias a la piedra, los arbustos y el arroz.
- El modelo no ve la pradera mapuche ni el claro del gult: el torneo lo confirma.

**Plan B por civ** (ninguna depende del agua, la ladera ni el monte):

| Civ | Plan B |
|---|---|
| Tawantinsuyu | En el llano, el andén es una chacra; el taller rinde igual |
| Mapuches | Talar alrededor del corral |
| Guaraníes | La roza sin monte rinde la base |
| Etiopía | Claro garantizado junto a cada arcilla |
| Palmares | Fama de la cerca real y las casas |
| Ayutthaya | El elefante, a la piedra y a las granjas |

---

## 5. Vida completa

Tiempos del modelo, en el llano y sin lo disputado.

| Civ | 0–5 | 5–15 | 15–30 | Final, con el mapa revelado |
|---|---|---|---|---|
| Tawantinsuyu | Camino a la arcilla; taller 1 a las 4:00 | Edad II a las 6:30, talleres 2 y 3. Edad III a las 13:50 con el aqllawasi | 5 talleres, cumbi, regalo a su ingenio | 150 r/min. **Rival:** mata runa; los talleres caen a 1/3, no a 0 |
| Mapuches | Corral inicial y corral 2 lejos | Edad II a las 6:50 (lonko); kawiñ antes del hito; malones | Edad III a las 14:40; corrales dispersos | 144 r/min. **Rival:** caza cabezas y corta arreos |
| Guaraníes | Yerbal viejo; rozas desde las 2:30 | Edad II a las 7:10; primeros yerbales; edad III a las 13:30 | Yerbales al tope; "quemar" si falta comida | 155 r/min. **Rival:** quema rozas, se cuida de las emboscadas en los yerbales |
| Etiopía | La corte extrae 12; gult 1 a las 3:30 | Edad II a las 8:50; corte nueva junto al flanco hacia las 14:00, con fiesta | Edad III a las 14:10; gult 4 a 6 | 148 r/min. **Rival:** quema gult lejanos; el cimiento es frágil y no puede ser una torre gratis |
| Palmares | Fama 90; mocambo 1 a las 3:00 | Edad II a las 6:40 (con 90 de fama); oficios llenos | Edad III a las 14:10; 8 puestos | 150 r/min. **Rival:** necesita un asedio de verdad para frenar los oficios |
| Ayutthaya | Elefante junto a los leñadores | Edad II a las 6:30; elefante 2 a la piedra; barrio chino | Edad III a las 14:00; 4 elefantes con el puerto | 160 r/min. **Rival:** caza elefantes (160 de recursos, 45 s para reponer uno) |

---

## 6. Esfuerzo

La vara que propongo (pregunta 1):
- **OPA del motor ≤ 0,6** por minuto;
- **PMP ≤ 2** cada 10 minutos;
- ninguna civ por encima de **1,5 veces la mediana** de la fase;
- nada periódico por debajo de 90 s.

Estimación de diseño:

| Civ | OPA f1 / f2 / f3 / final | PMP f1 / f2 / f3 / final | Decisiones reales por edad |
|---|---|---|---|
| Tawantinsuyu | 0,4 / 0,5 / 0,4 / 0,4 | 0,5 / 1 / 1 / 1,5 | 2 |
| Mapuches | 0,4 / 0,5 / 0,5 / 0,5 | 0,5 / 1 / 1,5 / 2 | 2 |
| Guaraníes | 0,3 / 0,3 / 0,3 / 0,3 | 0,5 / 0,5 / 1 / 1 | 2 |
| Etiopía | 0,4 / 0,5 / 0,4 / 0,4 | 0,5 / 1 / 1 / 1 | 3 |
| Palmares | 0,3 / 0,3 / 0,3 / 0,3 | 0,5 / 1 / 1 / 1,5 | 2 |
| Ayutthaya | 0,3 / 0,4 / 0,4 / 0,4 | 0,5 / 1 / 1 / 1,5 | 2 |

**Modelo:** OPA máxima 0,6 y PMP máximo 2.

Con la vara original (×1,5 entre la que más y la que menos), la fase 1 da ×1,7 **por abajo**: guaraníes y Palmares piden poco. Palmares, además, no encola aldeanos.

---

## 7. Números

| Civ | Pieza | Costo | Rinde | Tope | Repago | AE |
|---|---|---|---|---|---|---|
| Todas | Arcilla | — | 30 r/min por aldeano | 2×900 + 1500 propias | — | 1,0 |
| Tawantinsuyu | Taller | 120 m + 20 mit'a | 24 r (consume 30 de mit'a); 8 a piso | 2/3/4(5)/5 | 5,0 min | 0,8 |
| Mapuches | Corral | 120 m | 4 r por cabeza; 5 cabezas (6 como máximo) | 2/3/4/5(6) | 6,0 min | 0,67–0,8 |
| Guaraníes | Roza → yerbal | 90 m | 500 a, y después 300 r (un aldeano) | Yerbales 3/4/4/4 | — | 1,33 por aldeano |
| Etiopía | Gult | 100 m + 40 a | 3 a + 17 r; 3 a + 21 r cerca de la corte | 2/3/4/6 | 7,0 / 5,8 min | 0,67 / 0,8 |
| Etiopía | Corte (capital) | — | 12 / 16 / 20 / 24 r | Arcilla propia o del centro | — | — |
| Etiopía | Corte nueva | 150 m | Fiesta ×2 durante 60 s, una por arcilla | Cada 5 min | — | — |
| Palmares | Oficio | Una persona | 15 r | 4/7/8/8 | — | 0,5 por persona |
| Ayutthaya | Elefante del rey | 80 a + 80 m | 25 % de madera, arbustos y piedra; 10 % de granja | 16 / 24 (+4 barrio, +4 junco); 1/2/3(4)/3(4) | 6,7 min | 0,8 |
| Ayutthaya | Barrio chino | 100 m | +4 por elefante (uno solo) | — | 6,3 min con 4 elefantes | — |
| Todas | Tecnología de motor | 200 a + 200 m + 100 r | +25 % | Edad III | — | — |
| Todas | Lo disputado | — | — | 15 / 40 / 80 / 120 r/min | — | — |

---

## 8. Resultados del modelo

Comando: `python3 tools/modelo_economia.py`, en el llano, sin lo disputado, con el 35 % al ejército y hasta el minuto 45.

### 8.1 Curvas, edades y motor

| Civ | Riqueza m5 / m10 / m20 / m30 | Desvío (%) | Edad II / III | Motor m15–25 | Motor m40–45 |
|---|---|---|---|---|---|
| Tawantinsuyu | 268 / 1207 / 4516 / 5891 | −9 / +11 / +7 / 0 | 6:30 / 13:50 | 55 % | 150 |
| Mapuches | 275 / 1060 / 4136 / 5496 | −7 / −2 / −2 / −7 | 6:50 / 14:40 | 41 % | 144 |
| Guaraníes | 331 / 1032 / 4232 / 5687 | +12 / −5 / 0 / −3 | 7:10 / 13:30 | 51 % | 155 |
| Etiopía | 294 / 1006 / 4132 / 5615 | −1 / −7 / −2 / −5 | 8:50 / 14:10 | 53 % | 148 |
| Palmares | 322 / 1097 / 3728 / 6473 | +9 / +1 / −12 / +10 | 6:40 / 14:10 | 37 % | 150 |
| Ayutthaya | 283 / 1101 / 4549 / 6150 | −4 / +2 / +8 / +5 | 6:30 / 14:00 | 55 % | 160 |
| *Banda* | | ±15 | 6:30–9:00 / < 20:00 | 35–65 % | 135–165 |

### 8.2 Lo disputado y los golpes

**Lo disputado**, con la mitad de los aldeanos de la arcilla en el centro, un sitio e ingenios:

| Civ | Edad II | Edad III | Edad IV |
|---|---|---|---|
| Tawantinsuyu | 20 % | 18 % | 12 % |
| Mapuches | 22 % | 22 % | 11 % |
| Guaraníes | 28 % | 21 % | 12 % |
| Etiopía | 19 % | 21 % | 13 % |
| Palmares | 20 % | 26 % | 15 % |
| Ayutthaya | 21 % | 19 % | 10 % |

El tope absoluto se respeta siempre.

**Golpes:**
- perder lo disputado en el minuto 10 retiene entre 100 y 147 % del ingreso; en el minuto 20, entre 87 y 113 %; ninguna civ demora su edad;
- perder la arcilla de casa en el minuto 10: Etiopía 94 %, guaraníes 87 %, Tawantinsuyu 74 %, Palmares 57 %, Ayutthaya 54 % y **mapuches 29 %**; ninguna civ demora la edad III.

**Recurso propio en el tope:**
- fama, 7,4 % (sin contar los minutos con la población llena);
- **mit'a, 20,7 %**.

### 8.3 Fuera de banda (sin esconder nada)

| # | Qué | Valor | Banda | Lectura | Propuesta |
|---|---|---|---|---|---|
| 1 | Mit'a en el tope | 20,7 % | ≤ 15 % | Todo después del minuto 35, con 60 runa (180 de mit'a contra 150 de consumo). El modelo no gasta mit'a en levas | Aceptarlo: lo que sobra es la leva del final. Bajar la mit'a o subir el consumo dejan a Tawantinsuyu sin edad IV (probado) |
| 2 | Mapuches sin la arcilla de casa en el minuto 10 | 29 % | ≥ 60 % (síntesis) | Su motor es chico a los 10 minutos y el lof de flanco cuesta madera. No demora la edad (banco de 770). Dos cabezas iniciales no lo cambian (probado) | Aceptarlo como el costo de "sin capital", o lof de flanco más barato. **Decide el autor** (pregunta 6) |
| 3 | Guaraníes: lo disputado en la edad II | 27,8 % | 25 % (referencia) | El tope absoluto (40 r/min) se respeta; el porcentaje sube porque su ingreso propio baja después de la apertura | Ninguna: la regla es el tope absoluto |
| 4 | Etiopía: edad II | 8:50 | 6:30–9:00 | Dentro de la banda, en el borde: el gult cuesta 40 de alimento antes del hito | Medir en la etapa 3c. Palanca: primer gult sin alimento |
| 5 | Criterio 2 con la vara original | ×1,7 | ×1,5 | Por abajo: guaraníes y Palmares | Pregunta 1 |

### 8.4 Lo que el modelo sigue sin ver

- no modela el arreo, el kawiñ, el regalo de cumbi, el regimiento, la destrucción ni los combates;
- trata los yerbales con un aldeano cada uno (que ahora es regla);
- toma el costo del hito II del diseño, pero la IA real es más lenta;
- cuenta una fiesta etíope en la mudanza al flanco aunque la corte nueva pueda quedar a menos de 25 casillas de la vieja. Si la regla la impide, Etiopía pierde unos 20 de amole en toda la partida: no cambia ningún resultado.

### 8.5 Cambios al modelo en esta vuelta

Todos se activan desde `parametros.json`. Las copias anteriores están en el scratchpad de la sesión.

1. **Bosque finito** (`madera_finita`, `madera_alcanzable_pct = 40`, `madera_lejos_pct = 50`): madera alcanzable por jugador estimada desde `_generate_map` (bosques, bosque de la base y borde). Cuando se termina, se tala a la mitad de la tasa, y se informa el minuto.
2. **Horizonte de 45 minutos** e informe del motor en los minutos 35–40 y 40–45.
3. **Ayutthaya:**
   - `ayu_granja_pct` (10 % de la comida de granja);
   - `barrio_chino_tope` (un solo barrio);
   - `tope_extra` del junco.
4. **Mapuches:** `cabezas_tope_abs`; `lof_extra_entrena` (segunda cola con +50 % de tiempo).
5. **Etiopía:** `cimiento_corte` (costo de mudarse) y `fiesta_s` (una fiesta por arcilla, sobre los gult cercanos).
6. **Guaraníes:** `roza_tasa_pct` y `arcilla_pct`; el costo de la roza sale de `capa2.costo`.
7. **Palmares:** el tope de la fama no cuenta los minutos con la población llena.

Las de la vuelta anterior (opciones de diseño, efectos de hito, mit'a por edad, extracción por edad, mudanza sin pausa, elefantes) siguen.

---

## 9. Implementación

### 9.1 Orden y compuertas (adoptado de la crítica 03b)

| Etapa | Qué | Días | Compuerta |
|---|---|---|---|
| 0 | Medir: `torneo.gd --paz`, informe por origen, uso del motor, OPA y PMP | 3–4 | Línea de base en `proceso/` |
| 1 | IA común: etiqueta `eje`, reserva, aldeanos virtuales, `_site_scored`, caminos sin huecos, campana, casos J y K | 4–5 | Edad II entre 6:30 y 9:00 con los datos de hoy |
| 2 | Capa común: arcilla con dueño y claros, hito II, mercado, sitios, separación y máximos, tecnología común, hitos sin renta, hash, costo pagado | 5–6 | Sin motores, curvas a ±5 %. **Edad II con la IA real ≤ 9:00** |
| 3a | Tawantinsuyu (con el regalo de cumbi una vez que existan los ingenios) | 3,5 + 1 | Mit'a en el tope ≤ 15 % antes del minuto 35; motor m15–25 45–65 % |
| 3b | Palmares | 3 + 0,5 | Puestos ≥ 80 %; riqueza m20 ≥ −15 % |
| 3c | Etiopía | 4 + 1 | Edad II ≤ 9:00; ninguna fiesta repetida |
| 3d | Guaraníes, con la emboscada | 3,5 + 0,5 | Edad III ≥ 12:30; motor m15–25 ≤ 65 % |
| 3e | Mapuches (arreo contra el rival) | 4 + 1 | Cabezas ≥ 4 por corral; un kawiñ por corral y por edad |
| 3f | Ayutthaya (cambia la entrega de todas) | 3,5 + 1 | `bench` con 3 elefantes y 15 leñadores |
| 4 | Lo disputado: ingenios hostiles, baldes, arreo y liberación desde los ingenios | 4–5 | Dentro del tope; prueba del golpe 20–40 % |
| 5 | Interfaz y avisos | 2,5–3 | `--autotest` con captura en las seis |
| 6 | Balance y campañas | 9–12 | 35–65 % de victorias; edad II con mediana 6:30–9:00 |
| **Núcleo** | | **62–67** | |
| Fase 2 | Captura de manadas (Ayutthaya) | 2 | Después de la etapa 6 |

### 9.2 Trampas del código a resolver primero

1. `is_military()` (`sim_entity.gd:90`) por lista blanca.
2. `_threat` sin unidades no militares.
3. `_cmd_cancel` que devuelva lo pagado (`sim.gd:320`).
4. `find_enemy`, `_cmd_target` y `on_kill` con blancos `owner < 0` y `hostil` (`sim.gd:1304`, `:224`; `sim_mods.gd:273`).
5. `_exhaust` que reasigne a los aldeanos a la fuente que deja.
6. `nearest_dropoff` que acepte unidades, con desempate por `id`.
7. `state_hash` con todo el estado nuevo.

### 9.3 Reglas de IA

| Civ | Regla |
|---|---|
| Tawantinsuyu | Taller si la mit'a neta es ≥ 30 y hay madera ≥ 180; reserva 60 si se ahorra para un hito o hay amenaza; regalo al ingenio propio en la edad III |
| Mapuches | Corral con puntaje (pradera, lejos de otros); kawiñ solo si falta alimento para el hito; malón con un grupo de ×1,5 |
| Guaraníes | Resiembra prendida; "quemar" si falta alimento para el próximo hito |
| Etiopía | Gult cerca de la capital; fundar cuando a su arcilla le quedan menos de 100: flanco, y después el centro en la edad III |
| Palmares | Mocambo junto al monte; contar a los del oficio como aldeanos |
| Ayutthaya | Elefante al bosque con más árboles, el segundo a la piedra; moverlo y reasignar leñadores cuando quedan menos de 10 árboles; retirarlo si baja de la mitad de vida |

---

## 10. Autoevaluación contra la lista de control

| # | Criterio | Estado |
|---|---|---|
| 1 | Dos capas claras en palabras llanas | **Cumple** (resumen y §11) |
| 2 | Esfuerzo parejo | **Cumple con la vara nueva**; con la original, ×1,7 por abajo en la fase 1 (pregunta 1) |
| 3 | Curvas ±15 % a los 5, 10, 20 y 30 | **Cumple** (máximo ±12) |
| 4 | Edad II 6:30–9:00 y III < 20:00 | **Cumple en el modelo** (II 6:30–8:50; III 13:30–14:40). Falta la IA real (pregunta 2) |
| 5 | Viable en los 11 mapas | **Cumple en el modelo** (±6; columnas ≤ 8,1). Falta el torneo |
| 6 | Nada se rompe con el mapa revelado | **Cumple en el diseño**: los diecisiete problemas nuevos de 01b tienen regla |
| 7 | Ni comercio genérico ni dependencia de estar oculto | **Cumple** |
| 8 | Lo disputado con techo y remontada | **Cumple** (tope absoluto; golpes sin demora de edad). Mapuches retienen 29 % al perder la arcilla de casa (pregunta 6) |
| 9 | La IA lo juega con reglas simples | **Cumple**: ninguna civ necesita más que una variable propia |
| 10 | Fiel a la historia | **Cumple con marcas**: insəra, sal guaraní y siamesa, tributo de arroz siamés |

---

## 11. Fichas para el autor (plantilla del jugador nuevo)

**Tawantinsuyu.** El imperio que se construye como una red.
1. **Arcilla:** mejor, si unís el pozo con un camino a tu pueblo.
2. **Lo propio:** tu gente da turnos de trabajo (mit'a) sola, y los talleres de tejido los vuelven riqueza.
3. **Te pide:** cuántos turnos guardás para soldados y a qué ingenio le regalás tela fina para ganarlo sin pelear.
4. **Ojo:** si te matan gente, se cortan los turnos y los talleres tejen a un tercio.
5. **Saber más:** el Estado inca cobraba en trabajo, y la tela fina (cumbi) era su regalo político.

**Mapuches.** No hay capital que tomar.
1. **Arcilla:** igual que todos.
2. **Lo propio:** el ganado (kulliñ) crece solo en los corrales y cada cabeza da riqueza. En el malón, el ganado que tomás vuelve caminando.
3. **Te pide:** dónde va cada corral, y si salís a malonear al rival o a una estancia.
4. **Ojo:** los corrales van separados, cada golpe al corral mata cabezas y el ganado del malón hay que traerlo a casa.
5. **Saber más:** el ganado era riqueza, dote y prestigio, y el malón lo arreaba.

**Guaraníes.** El pueblo que se mueve con el río y el monte.
1. **Arcilla:** mejor; tus aldeanos la trabajan más rápido.
2. **Lo propio:** en vez de granjas abrís rozas. Dan comida, se agotan y dejan un yerbal que da riqueza; después la roza se vuelve a abrir sola. Tus arqueros emboscan desde el yerbal.
3. **Te pide:** si dejás crecer el monte (riqueza después) o lo volvés a quemar (comida ya).
4. **Ojo:** la roza cuesta madera; sin madera no se reabre y se corta la comida.
5. **Saber más:** la chacra vieja se volvía huerto y yerbal, y en la colonia la yerba fue moneda.

**Etiopía.** La corte que camina.
1. **Arcilla:** distinta; tu corte saca amole del pozo que tiene al lado, sin aldeanos.
2. **Lo propio:** repartís tierras (gult) que pagan tributo, más si están cerca de la corte.
3. **Te pide:** dónde repartir, si una tierra paga o abarata jinetes, y cuándo fundar la corte en otro lugar.
4. **Ojo:** la corte nueva tarda un minuto y es frágil mientras se levanta. Fundala lejos de la pelea.
5. **Saber más:** el rey daba tierras que tributaban, y la sal en barras (amole) era la moneda.

**Palmares.** La libertad que llega sola y se defiende en la sierra *(frase propuesta)*.
1. **Arcilla:** igual que todos, pero la gente llega sola.
2. **Lo propio:** no entrenás aldeanos, llegan por la fama. Los que trabajan en un oficio dentro del mocambo (herrero, alfarero, cestero) dan riqueza segura.
3. **Te pide:** si salís a liberar gente de los ingenios o esperás la fama, y cuánta gente dejás en los oficios.
4. **Ojo:** si atacan en serio el mocambo, los oficios paran. Defendé la cerca.
5. **Saber más:** la riqueza de Palmares era su gente y lo que sabía hacer; en 1694 tenía cuarenta herrerías.

**Ayutthaya.** La ciudad isla del rey, sus elefantes y sus huéspedes *(frase propuesta)*.
1. **Arcilla:** igual, pero la vas a necesitar menos.
2. **Lo propio:** tus elefantes del rey reciben madera, piedra, lo que se junta del monte y arroz, y una parte es riqueza para el rey.
3. **Te pide:** dónde está cada elefante y qué barrio extranjero recibís.
4. **Ojo:** no tenés depósitos comunes: tus aldeanos entregan en el palacio o en un elefante. Un elefante solo, lejos, es una presa.
5. **Saber más:** el palo de sapán, los cueros y el estaño eran monopolio del almacén real.

---

## 12. Preguntas para el autor

1. **¿Cómo medimos que el esfuerzo sea parejo?**
   - a) **Umbrales absolutos:** ninguna civ pide más de 0,6 órdenes por minuto ni más de 2 pendientes cada 10 minutos, y ninguna supera 1,5 veces la mediana *(recomendada)*.
   - b) ×1,5 entre la que más y la que menos pide, como decía la consigna. Esta vara falla porque guaraníes y Palmares piden poco.
2. **¿Subimos el costo del hito II a 500 de alimento y 300 de riqueza?**
   - a) **Sí, y lo medimos con la IA real en la etapa 2.** Si pasa de 9:00, volvemos a 400 + 250 *(recomendada)*.
   - b) Dejarlo en 400 + 200: algunas civs llegan antes de las 6:30.
3. **Cuando se acaba la arcilla (minutos 13 a 24), el ingreso de riqueza cae a la mitad** (de 300–500 a ~150 por minuto, más lo disputado).
   - a) **Aceptarlo:** el final se pelea en el centro *(recomendada)*.
   - b) Agregar una veta lenta en el flanco, que sería otro ingreso pasivo.
4. **Etiopía en escaramuza: ¿la corte se "funda" en otro lugar en lugar de viajar como carpa?**
   - a) **Sí:** sin carpa vulnerable ni derrota por empacar. La carpa queda para la campaña *(recomendada)*.
   - b) Volver a la carpa que viaja.
5. **¿Ayutthaya sin depósitos comunes, con el elefante como depósito?**
   - a) **Sí:** es su identidad y evita que el rey "no cobre" sin que el jugador lo sepa *(recomendada)*.
   - b) Que pueda construir depósitos comunes.
6. **Mapuches: si pierden la arcilla de casa en el minuto 10, conservan solo el 29 % del ingreso de riqueza** (sin atrasar su edad).
   - a) **Aceptarlo como el precio de "no hay capital"** y mirarlo en el torneo *(recomendada)*.
   - b) Abaratar el lof de flanco de 110 a 80 de madera.
7. **¿Cambiamos las frases de Palmares ("se esconde") y Ayutthaya ("comercia con el mundo"), que contradicen el diseño?**
   - a) **Sí, con las propuestas de §11** *(recomendada)*.
   - b) Dejarlas.
