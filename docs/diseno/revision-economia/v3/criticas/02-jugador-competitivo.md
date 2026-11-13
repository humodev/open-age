# Ronda 3 · Crítica 02 — El jugador competitivo

Lo miro como jugador: Conqueror en AoE4, con horas de AoE2 y AoM. La pregunta no es si los números cierran (eso lo dice el modelo) sino **si yo me sentaría a jugar esto en ranked**, si cada civ me deja decidir algo de verdad y si todas me cansan más o menos igual.

Leí `00-consigna.md`, `01-diseno-lider.md`, `parametros.json`, `investigacion-aoe4/01` y `02`, y miré `data/civs/*.json` para saber con qué ejército pelea cada una. Todas las cuentas de abajo salen de `parametros.json`. Cuando adivino, lo digo.

---

## 0. Veredicto corto

- **Sí lo jugaría**, pero hoy jugaría **tres civs y media** con ganas: guaraníes, Palmares, mapuches y Etiopía a medias. Tawantinsuyu me interesa, aunque le falta un momento. **Ayutthaya, como está, es la Orden del Dragón de Raíces**: un campamento maderero con +X %.
- **El problema de fondo:** cuatro de los seis motores tienen la misma forma. Un edificio de unos 120 de madera, que rinde entre 20 y 24 por minuto, con tope de 2/3/4/5 y castigo por vecindad. Taller, corral, gult y almacén se juegan igual: "lo pongo en un lugar razonable y me olvido". El tope por edad y la regla de 0,8 AE son buenos para el balance, pero aplanan la sensación. Lo distinto está en la forma de alimentar el motor, y ahí hay mucho mejor material del que parece (§2).
- **Hay un exploit en el corral mapuche** (faenar), que convierte la mecánica en el ritual que el diseño quería evitar (§1.2). Es lo primero que yo abusaría en ranked.
- **El esfuerzo no es parejo**, aunque la OPM diga ×1,13. La OPM cuenta órdenes; lo que cansa es **mirar**. Etiopía y mapuches piden más de lo que dice la tabla, y Ayutthaya y Palmares menos (§3).

---

## 1. Civ por civ

Supuestos de apertura comunes: 6 aldeanos y arranque parecido a AoE4. El hito II pide 400 de alimento y 200 de riqueza. La comida es el cuello (ronda 1, 05), no la riqueza: a los 7 minutos todas tienen más de 600 de riqueza acumulada. Así que **en los primeros 10 minutos el motor compite contra el alimento y la madera, no contra el barreal**. Eso pesa en cada apertura.

### 1.1 Tawantinsuyu — "El trabajo que sobra se vuelve tela"

**Apertura (10 min):**
1. 6 runa: 4 a comida, 2 a madera. La mit'a arranca en 60 y sube 24 por minuto.
2. 1:30: 3 runa al barreal de la base. Camino tambo → barreal (unas 6 casillas, 12 de mit'a). Es lo primero que hago, porque se paga solo.
3. 3:00–4:00: taller 1 (120 m + 20 mit'a). Lo prendo apenas tengo mit'a para sostenerlo. Con 12–14 runa entran 50 de mit'a por minuto y el taller consume 30.
4. 5:00–6:00: casa, más madera y granjas o andenes si hay ladera. Taller 2 cerca de las 6:00, cuando hay ~20 runa (80 de mit'a por minuto).
5. 7:30–8:30: hito II. Qollqa enseguida para subir el tope de mit'a, porque la leva es mi seguro contra el primer golpe.
6. Hasta las 10:00: taller 3. Arranca la pregunta real: ¿tercer taller o reservar mit'a para levas?

**Decisiones:**
- *Interesante:* **a qué va la mit'a.** Es la única civ con un recurso que compite entre economía y guerra en tiempo real: tela, camino, leva, andén y el hondero de piedra caliente, que cuesta mit'a. Si me hostigan, apago dos talleres y tengo la leva lista en 40 segundos. Esa es una decisión con costo visible.
- *Interesante:* **qué conectar en la edad III** (el centro, con camino largo y expuesto, o casa).
- *Obvia:* **camino al barreal.** 12 de mit'a por +20 % en 3–4 aldeanos (unos +20 r/min) se repaga en menos de un minuto. Nadie lo va a dejar de hacer. No es una decisión, es parte del orden de construcción. No está mal que exista, pero no lo cuenten entre las "3 decisiones por edad".
- *Obvia en la práctica:* **prender o apagar.** El 95 % del tiempo el taller está prendido. Se apaga solo en emergencia, y la emergencia la resuelve la leva, que ya sale de la qollqa. Sospecho que el interruptor es un botón que casi nadie toca. Si el taller se prende y apaga solo según una reserva que fija el jugador ("dejá siempre 60 de mit'a para leva"), se gana una decisión y se pierde un clic.

**Diferencia:** media. Convertir un recurso pasivo en riqueza es primo del aceite bizantino. Lo que la separa es la tensión obra o tela, que ninguna otra tiene. En la partida, sin embargo, el taller se ve como otro edificio de renta, igual que el gult o el corral.

**Esfuerzo:** bajo a medio. Mirar la barra de mit'a es como mirar el oro en AoE4, algo que ya hacés. El pico está en la edad III, si hay que reparar caminos cortados. Me preocupa poco.

**Ganas:** 6/10. La fantasía del Estado que organiza el trabajo está, pero el taller no me hace sentir que **tejo un imperio**. Me hace sentir que tengo un edificio de renta con mantenimiento.

**Momento memorable que falta:** la tela tiene que **hacer algo que la riqueza común no hace**. Históricamente el cumbi era regalo político. Propuesta: en la edad III, el cumbi permite **incorporar una estancia o ingenio neutral sin pelear** (gastás tela, la estancia pasa a ser tuya y rinde un poco, pero queda expuesta). Es lo que hace el emisario Jin con los puestos neutrales, y la comunidad lo percibió como "una civ nueva". Así la tela tiene un destino con identidad y el inca se expande por regalo, no por saqueo. Ojo: no es comercio, es un gasto único con efecto territorial.

---

### 1.2 Mapuches — "La riqueza camina y se reproduce"

**Apertura (10 min):**
1. 6 che: 4 a comida (caza o arbustos), 2 a madera. El corral inicial cría solo: a los 3 minutos ya tiene 5 cabezas (20 r/min).
2. 1:30–2:00: 3 al barreal.
3. 3:30–4:00: corral 2 (120 m) **lejos del primero y en pradera**. Si el mapa es llano, lo pongo hacia el lado de mi flanco.
4. 5:00–6:00: lof 2 junto al barreal de flanco. En este momento el lof es lo que me da forma de "civ sin capital".
5. 6:30–7:30: **faeno los dos corrales** y cierro el hito II antes que todos (§ exploit abajo).
6. 8:00–10:00: corral 3, weichafe y primer malón a una estancia neutral (botín ×1,5 y una cabeza).

**El exploit del faenar, con números:**
- Un corral lleno tiene 5 cabezas y rinde 20 r/min. Faeno: 4 cabezas × 40 = **160 de alimento al instante**, sin aldeano. Queda 1 cabeza.
- Volver a llenarse tarda 4 × 45 s = 3 minutos. En ese lapso pierdo (4+3+2+1) × 45 s = 7,5 cabeza·minuto × 4 = **30 de riqueza**.
- **Cambio 30 de riqueza por 160 de alimento instantáneo.** Son 5,3 de alimento por cada riqueza, y el alimento es justo el cuello de botella del hito. Un aldeano en granja tarda 4,4 minutos en juntar 160.
- Conclusión de ranked: **cada corral se faena cada 3 minutos durante toda la partida.** Cinco corrales en la edad IV son 800 de alimento cada 3 minutos (≈ 270/min, unos 7–8 granjeros gratis) a cambio de bajar la riqueza del motor a la mitad. Es la fábrica de comida cliqueable que el anexo dice haber descartado, solo que con el clic sobre el corral en lugar de la cabeza. Y es exactamente lo que le pasó al ganado malí a 75 de oro: *"players would completely ignore farms"*.
- **Arreglo posible** (cualquiera sirve):
  - después de faenar, el corral cría a la mitad de velocidad por 3 minutos;
  - o 20 de alimento por cabeza y que la carne la tenga que llevar un aldeano (como el ganado malí: se faena en el molino);
  - o tope de una faena por corral por edad, que la vuelve un "comerse el capital" de verdad.

  Mi preferencia es la tercera: la decisión del documento ("comerse el capital") se vuelve grande y rara, como quiere el diseño.

**Decisiones:**
- *Interesante:* **dónde va el corral.** La pradera da +20 % pero queda lejos del lof. Contra Etiopía, que tiene jinetes desde la edad I, esto pesa mucho. Contra Palmares, casi nada.
- *Interesante:* **malón al rival o a lo neutral.** Con tope de 60 r/min, el malón al rival rinde si además le rompe algo que le duele. Lo neutral es seguro y suma cabeza.
- *Obvia (hoy):* faenar, que es siempre (ver arriba). Arreglado, pasa a ser la mejor decisión de la civ.

**Diferencia:** alta. Es la única con un activo visible que crece y que el rival te puede matar a pedazos (cada 20 % de vida es una cabeza). Se juega distinto: dispersar, proteger, comerse el capital. Se parece al ganado malí y a las vacas escocesas, pero en Raíces no tiene equivalente.

**Esfuerzo:** **más alto de lo que dice la tabla.** Hay que mirar corrales dispersos (que el rival sabe dónde están) y, si el faenar no se arregla, hacer clic cada 3 minutos por corral. Con el arreglo baja a medio.

**Ganas:** 8/10. Es la que más se parece a "esto no lo jugué nunca".

**Momento memorable que falta:** el **arreo**, que está anotado como "fase 2". **Es el momento de la civ y tiene que estar desde el principio.** Volver de un malón con veinte cabezas caminando hacia el corral mientras el rival manda caballería a cortártelas es el equivalente al ovoo. Sin el arreo, el malón es "+10 % del daño como riqueza", un número. Con el arreo, es una persecución.

---

### 1.3 Guaraníes — "El campo que se agota deja un yerbal"

**Apertura (10 min):**
1. 6 ava: 2 al yerbal viejo (250), 2 a arbustos y 2 a madera. Pongo la bandera de roza junto al monte más cercano que no esté hacia el rival.
2. 1:30: 2 al barreal (+14 %).
3. 2:30 en adelante: **rozas en lugar de granjas**. 45 de madera por 750 de alimento a 60/min por aldeano, contra 36 en granja. Es la mejor comida del juego.
4. 4:00: cola de rozas a 2–3 y tapyi 2 junto al monte.
5. 7:00–8:00: hito II. Sale fácil, porque la roza da comida de sobra.
6. 8:00–10:00: sumo aldeanos a rozas. Los primeros yerbales aparecen hacia el minuto 13; antes de eso, la civ es "comida barata y barreal un poco mejor".

**Decisiones:**
- *Interesante:* **dónde va la bandera.** Junto al monte da +15 % y emboscada (los arqueros ya tienen `sigilo`), pero en el final queda lejos de la torre. Es una decisión espacial real.
- *Interesante:* **seguir quemando monte o pasar a la misión.** Si la bifurcación misión o monte del archivo de la civ sigue, se cruza linda con esto.
- *Obvia:* **cuántos aldeanos a la roza.** La roza da 60 de comida y deja un yerbal que da 40 de riqueza: **siempre conviene más que la granja y que el barreal.** No hay un "comida ahora o riqueza después": la roza da las dos cosas, en ese orden. El largo de la cola es solo "¿tengo 45 de madera?". Por eso el premodelo da +18 % a los 30 minutos: la civ no tiene que elegir.
  - Para que sea decisión, la roza tiene que costarle algo que la granja no cuesta. Por ejemplo: la roza **consume el bosque** (tala los árboles a su alrededor; ya existe la sucesión con capuera) y **tarda en estar lista** (30 s quemando). O el yerbal **no deja nada** si se lo cosecha antes de cierto punto.
  - La palanca que propone el documento (yerbal a 250) arregla el número, no la decisión.

**Diferencia:** alta. La base **avanza sobre el monte** y el barreal se guarda para el final. Es otra geografía de base, y eso se ve desde el minuto 5.

**Esfuerzo:** bajo gracias a la cola. Bien resuelto: la cola es la resiembra de AoE2 y nadie la extraña como micro. Lo único que pide mirar es si el rival te está cosechando un yerbal, y eso pasa poco: nadie manda aldeanos a la base enemiga.

**Ganas:** 8/10. Comida explosiva al principio y la sensación de que tu pueblo transforma el mapa.

**Momento memorable que falta:** que el cambio **se vea en grande.** El monte que se vuelve yerbal tiene que cambiar el color del mapa alrededor de tu base y que, en el final, el rival vea "esa mancha verde claro es guaraní". También la **emboscada desde el yerbal**: si los arqueros con sigilo se esconden también en el yerbal (no solo en el monte), cada yerbal es una trampa y la economía es la defensa. Eso es identidad de verdad, y es historia: el monte era su fortaleza.

---

### 1.4 Etiopía — "La tierra paga a la corte que está cerca"

**Apertura (10 min):**
1. 6 gäbbar: 4 a comida, 2 a madera. La kätäma ya está sacando 12 r/min del barreal de la base.
2. 1:30: 3 al **otro** barreal (el que no come la corte).
3. 3:30: gult 1, señor, a ≤ 14 casillas de la corte. Ojo con el costo de 40 de alimento, que sale del hito.
4. 4:00–6:00: jabalineros o jinete noble. Etiopía tiene caballería desde la edad I, y no usarla es tirar la civ.
5. 7:30–8:30: hito II. Gult 2.
6. ~12:00: el barreal se acaba y **la corte se muda** al barreal de flanco.

**El problema de la mudanza:** la kätäma **es el centro urbano** (`centro.empaca_en: carpa_real`). Mudarla significa:
- frenar la producción de aldeanos mientras viaja (en AoE4 es lo que hace caro mudar al mongol);
- dejar la base sin el edificio más fuerte;
- llevar 2000 pv lentos por el mapa.

Ningún competitivo va a mudar el centro **cada 5 a 8 minutos** por 12 r/min (0,4 AE). Lo haría **una vez** en la partida, o nunca, salvo que la mudanza pague mucho más. Encima, cuando se muda, los gult viejos pierden el +33 %. La "decisión que une las dos capas" va a quedar en "me quedo quieto".

**Decisiones:**
- *Interesante:* **señor o regimiento.** Dos gult de regimiento abaratan 30 % el jinete noble (70 a + 35 r → 49 a + 25 r). Contra mapuches o Ayutthaya, ir de caballería barata y perder ~38 r/min de renta es un plan real. Es la mejor decisión del documento: dos planes viables, cada uno con costo claro.
- *Interesante:* **acampar en el centro** en la edad III, si la mudanza se hace viable.
- *Obvia:* **dónde va el gult.** Siempre a ≤ 14 de la corte, porque el +33 % es demasiado para desperdiciarlo.
- *Obvia (por mala):* **mudar la corte**, como está.

**Diferencia:** potencialmente la más alta de las seis, pero hoy queda en "gult = renta". El gult, solo, es un taller con otra vasija.

**Esfuerzo:** bajo si no se muda; **muy alto** si se muda: hay que escoltar el centro, reubicar aldeanos, volver a armar depósitos y reubicar gult. La tabla le da 0,40 de OPA y no refleja ese pico.

**Ganas:** 7/10 por la caballería temprana y el regimiento. Pero la corte que camina es la fantasía de la civ (*"La corte que camina"*, dice el archivo) y hoy no camina.

**Momento memorable que falta:** **que mudarse sea un evento que valga la pena.** Propuestas, de menor a mayor:
- la extracción de la corte escala con la edad, como el ovoo (12 / 20 / 30 / 40), para que importe dónde está;
- al desplegarse en un lugar nuevo, los gult a ≤ 14 casillas tienen una **fiesta de llegada** (doble renta 60 s): mudarse es un pico de ingresos, no una pérdida;
- mientras está empacada, la carpa real **produce aldeanos igual**, más lento, como los vikingos. Así la mudanza deja de ser un castigo y pasa a ser una decisión de riesgo militar, no de economía.

Con eso, "la corte acampa frente al barreal del centro en la edad III" se vuelve la jugada que se recuerda de la partida.

---

### 1.5 Palmares — "La riqueza es la gente que llega"

**Apertura (10 min):**
1. Los palmaristas no se encolan: llegan por la fama. La semilla de 60 trae a 2 personas enseguida. Pongo a todos en comida y madera.
2. 1:30–2:00: 3 al barreal.
3. 3:00: mocambo 1 junto al monte (+5 de fama por minuto), con cupo 1.
4. 5:00: casas (+2 de fama cada una). El ritmo de crecimiento lo marca la fama, no los clics, así que la apertura es **lenta y tranquila**. El −9 % a los 5 minutos se nota.
5. 7:30–8:30: hito II. Mocambo 2 y cupos a 3.
6. 8:00–10:00: primera correría a un ingenio neutral si la guardia es de 4: botín ×1,5 y 2 personas.

**Decisiones:**
- *Interesante:* **campo u oficio.** El oficio rinde 15 contra 30 del barreal, pero no se lo puede matar. Contra un rival que no hostiga, la respuesta es "campo" hasta que se acabe el barreal; contra mapuches o Etiopía, "oficio". **Cambia según el rival**, que es lo que hace a una decisión buena.
- *Interesante:* **correría o mocambo.** Ir a buscar gente (riesgo, pero acelera la población) o esperar la fama.
- *Obvia:* **dónde va el mocambo.** Junto al monte siempre, porque +5 de fama es mucho al principio.

**Diferencia:** **muy alta.** Es la civ "vikinga" de Raíces: no encolás aldeanos. Eso solo ya cambia el ritmo de manos: la APM que el resto pone en encolar, Palmares la pone en el ejército. Para un competitivo esto es enorme, y el catálogo lo muestra: los vikingos están 57,8 % con 19,7 % de elección.

**Esfuerzo:** **el más bajo** de las seis. Fijar un cupo es una orden por edificio por edad. Sobre esto no tengo quejas, pero tengo un aviso: es el punto donde la consigna (esfuerzo parejo) se va a romper **a favor de Palmares**, porque además se ahorra encolar, que la métrica no cuenta. Hay que medirlo con `atencion.gd` contando el encolado aparte.

**Ganas:** 8/10. Jugar sin encolar y con una economía que el rival no puede hostigar es muy atractivo. La duda es si a nivel alto termina siendo "la civ que hace siempre lo mismo": fama, mocambos, cupos, correría.

**Momento memorable que falta:** **la correría tiene que traer gente caminando.** Igual que el arreo mapuche: liberás 2, 4 o 6 personas del ingenio y vuelven a pie al mocambo más cercano; si el rival las intercepta, vuelven al ingenio. Hoy son "2 personas liberadas" que aparecen. Que caminen es el momento.

---

### 1.6 Ayutthaya — "El monte paga al rey"

**Apertura (10 min):**
1. 6 phrai: 3 al almacén real (madera), 3 a caza o arbustos que entregan en el almacén.
2. 1:30: 2–3 al barreal.
3. 3:00–6:00: más leñadores al almacén hasta saturarlo (3–4 leñadores). Me sobran 200 de madera porque el almacén ya está construido, así que casa temprana y granjas o arrozal.
4. 7:00–8:00: hito II. Almacén 2 en el bosque siguiente.
5. 8:30: barrio chino entre los dos almacenes (+8 de tope a cada uno).
6. 10:00: kraal o compañía portuguesa, según el rival.

**Decisiones:**
- *Obvia:* **dónde va el almacén.** Al lado del bosque. Es lo que haría con un campamento maderero en cualquier RTS. No hay alternativa razonable.
- *Obvia:* **leña o barreal.** Siempre "leña hasta saturar el almacén", porque la madera hace falta igual y la riqueza es gratis encima.
- *Obvia:* **qué barrio.** El chino, porque los otros dos no dan economía. Lo de japonés o portugués es una decisión **militar**, no económica, y no debería contarse como decisión del motor.
- *Interesante (la única):* **dónde va el barrio chino**, si hay dos almacenes que puedo tocar.

**Diferencia:** **baja.** Es literalmente "tu campamento maderero da +25 % en riqueza, con tope". Es la crítica del Sacro Imperio de AoE4: *"just a basic Civ with nothing special"*. El documento lo vende como "la única que saca riqueza de la madera", pero en la partida no se siente: se siente como un bonus pasivo.

**Esfuerzo:** el más bajo junto con Palmares. No es un problema en sí. Pero acá el poco esfuerzo viene de **no tener nada que hacer**, y eso se nota más que el poco esfuerzo de Palmares, que viene de un sistema automático.

**Ganas:** 4/10 en la economía. Me darían ganas por los elefantes, no por la economía.

**Momento memorable que falta:** el **elefante**. Ayutthaya tenía elefantes que trabajaban (acarreo de troncos) y un kraal real para capturarlos.
- Propuesta: **el almacén real es un elefante de trabajo** (como el elefante obrero de Tughlaq): un depósito **móvil** que llevás al bosque o a la caza, con el mismo 25 % y el mismo tope. Cambia todo: se decide dónde está **en cada momento**, el rival lo puede cazar (es una unidad) y, en el final, pasa de bosque en bosque mientras el rey "cobra del monte".
- Alternativa más barata: que cada almacén **elija qué cobra** (madera, caza o piedra), como sugiere el propio documento en §6. Suma una decisión por almacén y arregla el ×1,67 de la OPA.
- Y el **kraal**: capturar elefantes salvajes del mapa (neutrales, como la caza) para convertirlos en elefantes de guerra o de trabajo. Esa caza de elefantes es lo que la gente contaría después de la partida.

---

## 2. ¿Cada civ es distinta o es "una normal con +X %"?

| Civ | Forma del motor | Se siente… | Por qué |
|---|---|---|---|
| Tawantinsuyu | Recurso propio → conversión | Algo distinta | La mit'a compite entre guerra y tela, pero el taller se ve como edificio de renta |
| Mapuches | Activo vivo que crece y se roba | **Distinta** | Dispersar, proteger, comerse el capital. Mejor con arreo |
| Guaraníes | Sucesión comida → riqueza en el mismo lugar | **Distinta** | La base avanza sobre el monte |
| Etiopía | Renta por cercanía a una capital móvil | Distinta en papel, normal en la práctica | La corte no se va a mover |
| Palmares | Población gratis + puestos protegidos | **Muy distinta** | No encolás aldeanos |
| Ayutthaya | % de la madera como riqueza | **"Normal con +X %"** | Es un campamento maderero con bonus |

**La trampa de la forma común.** Taller, corral, gult y almacén comparten la plantilla: 0,8 AE, tope 2/3/4/5, vecindad a 8 casillas, ~120 de madera. Para el balance es perfecto. Para el jugador, los cuatro se colocan con el mismo criterio ("lejos de los otros, cerca de mi base") y **en la partida se ven como el mismo edificio con otra vasija**. Lo distinto tiene que estar en **cómo se alimenta** cada motor (mit'a, cría, sucesión, cercanía a la corte, gente, entrega de madera) y en **cómo se pierde**. Ahí están los momentos que propongo arriba: tela que incorpora, arreo, yerbal-trampa, corte que acampa, gente que vuelve a pie, elefante que carga.

**Uniformidad sospechosa:** la tabla de esfuerzo le da **3 decisiones por edad a las seis**. Contando solo las que tienen dos respuestas viables, me da:

| Civ | Decisiones reales | Cuáles |
|---|---|---|
| Tawantinsuyu | 2 | Mit'a a tela o guerra; qué conectar en la III |
| Mapuches | 2 (3 con el faenar arreglado) | Dónde va el corral; malón propio o neutral |
| Guaraníes | 2 | Bandera; misión o monte |
| Etiopía | 1–2 | Señor o regimiento; mudarse (si se arregla) |
| Palmares | 2 | Campo u oficio según el rival; correría o esperar |
| Ayutthaya | 1 | Dónde va el barrio chino |

---

## 3. Esfuerzo: lo que la OPM no mide

La OPM cuenta órdenes. Lo que cansa en ranked es **cuántas veces tenés que mirar algo** y **qué pasa si no lo mirás**. Mi estimación, como jugador, de la atención que pide la economía propia:

| Civ | Qué hay que mirar | Cada cuánto | Costo de olvidarse | Atención |
|---|---|---|---|---|
| Tawantinsuyu | Barra de mit'a, caminos cortados | 1–2 min | Mit'a en el tope, sin leva | Media |
| Mapuches | Corrales dispersos (y faenar si no se arregla) | 1 min por los raids; 3 min por el faenar | Te matan cabezas sin que te enteres | **Alta** (media con el arreglo) |
| Guaraníes | Cola de rozas, bandera, emboscadas | 3–5 min | La cola vacía: los aldeanos se van al barreal | Media-baja |
| Etiopía | Si se muda: escolta y reubicación de todo | Pico de 1–2 min cada mudanza | Perdés el centro en marcha | Baja sin mudanza, **muy alta** con mudanza |
| Palmares | Cupos y correrías | 5 min | Poco | **Baja**, y además sin encolar |
| Ayutthaya | Leñadores (como cualquier civ) | — | Nada propio | **Muy baja** |

Entre la más exigente (mapuches con faenar, o Etiopía en mudanza) y la que menos pide (Ayutthaya, o Palmares contando que no encola) hay más de ×2. **La consigna E no se cumple en la experiencia, aunque se cumpla en la OPM.** Pido que `atencion.gd` cuente aparte el encolado de aldeanos, que Palmares no tiene, y los "vistazos" (selecciones de edificios del motor sin dar una orden).

---

## 4. Enfrentamientos

Cómo me imagino cada cruce, con los ejércitos de `data/civs`. Marco en negrita los que me parecen más ricos.

| A vs B | Qué hace A | Qué hace B | Lectura |
|---|---|---|---|
| **Mapuches vs Etiopía** | Malón a gult lejanos; corrales cerca de los lof | Jinete noble (edad I) cazando corrales; regimiento para abaratarlo | **El mejor cruce.** Dos civs con economía expuesta y caballería. Gana el que lee primero dónde está la renta del otro |
| **Mapuches vs Palmares** | Malón al mocambo… que tiene estrepes y gente adentro | Cupo a oficio y correrías a los ingenios | Palmares es el contra natural del malón. Los dos compiten por los **mismos ingenios** (los dos con ×1,5): carrera por lo neutral, muy linda |
| Mapuches vs Tawantinsuyu | Malón a lo que haya: los caminos rinden poco | Leva instantánea; talleres en el corazón | El inca casi no tiene blanco de raid. El mapuche tiene que ir por el barreal, no por el camino |
| Mapuches vs Ayutthaya | Matar leñadores (que son el motor) | Elefantes, compañía portuguesa | Ayutthaya es la víctima del raid: si le matás los leñadores, le matás la madera y la riqueza a la vez |
| **Guaraníes vs Tawantinsuyu** | Boom de rozas; yerbales al minuto 13 | Presión antes del 13 con honderos y leva | Partida de reloj. Si el inca no golpea antes de los yerbales, el guaraní se le va (+18 % a los 30) |
| Guaraníes vs Etiopía | Esperar en el monte con emboscada | Jinetes contra rozas, que son edificios en campo abierto | La roza junto al monte es la que manda: la caballería en el monte muere |
| Guaraníes vs Palmares | Los dos boom tranquilos | — | **Riesgo de partida pasiva**: dos economías seguras que no se tocan. Lo disputado tiene que obligar a salir |
| Palmares vs Tawantinsuyu | Oficios, cerca | Talleres, red | Lo mismo: dos tortugas. Ojo |
| Etiopía vs Ayutthaya | Corte al centro en la III | Almacenes en el bosque, elefantes | Etiopía le gana el centro, Ayutthaya se lo disputa con elefantes. Depende de la mudanza |
| Ayutthaya vs cualquiera | Elefantes en la III | — | La economía de Ayutthaya no genera interacción: no tiene nada que defender que sea suyo |

**Tres observaciones de los cruces:**
1. **Hay dos parejas de tortugas** (guaraníes-Palmares e inca-Palmares). Con motores protegidos y lo disputado con techo bajo en las edades I y II (10 % y 25 %), esas partidas pueden ser 20 minutos de boom espejado. Sugiero que los sitios sagrados o los ingenios den algo que **no** sea riqueza (alimento en la edad I, o un bono de población) para que valga salir temprano.
2. **Los ingenios neutrales son el punto caliente** de mapuches y Palmares. Con 2 pares y reconstrucción a los 240 s, en una partida mapuche contra Palmares los cuatro ingenios van a ser el mapa. Me gusta, pero hay que probar que la civ que no saquea (inca, Ayutthaya) no quede regalando ese botín.
3. **Las economías más expuestas** (mapuches, Ayutthaya y Etiopía con los gult lejos) **son también las que tienen caballería o elefantes.** Está bien: el que tiene economía frágil tiene con qué responder.

---

## 5. ¿Hay civs obligadas a un solo plan?

- **Ayutthaya: sí.** Almacén al bosque, barrio chino, saturar. La alternativa (japonés o portugués) es una elección de ejército, no de economía. Es el *"I found myself basically doing the same thing with that civ in every game"* de la beta de AoE4.
- **Guaraníes: casi.** La roza le gana a todo, así que el plan es siempre "rozas y yerbales". Lo salva la bifurcación misión o monte, si sigue viva, y la bandera.
- **Etiopía: sí, pero por otro motivo.** El plan es "gult alrededor de la corte y no moverse". El regimiento le da un segundo plan (caballería barata), y eso la salva a medias.
- **Tawantinsuyu: no.** Tela contra levas es un eje real: boom de talleres o presión con mit'a en levas.
- **Mapuches: no.** Corral pacífico o malón agresivo, con el faenar en el medio.
- **Palmares: no.** Fama tranquila o correrías.

---

## 6. Lo que le falta a cada una para tener "su momento"

| Civ | El momento que propongo | Referencia de AoE4 |
|---|---|---|
| Tawantinsuyu | Regalar cumbi para incorporar una estancia neutral sin pelear | Emisario Jin |
| Mapuches | **Arreo**: el ganado robado vuelve caminando y se puede interceptar. Ya, no en la "fase 2" | Ovoo (algo que solo ellos hacen y que se ve) |
| Guaraníes | El yerbal también esconde arqueros: la economía es la emboscada; el monte cambia de color | Vacas escocesas (la economía cambia el mapa) |
| Etiopía | La corte que acampa: renta que escala con la edad, fiesta de llegada, la carpa sigue produciendo | Ovoo + mudanza mongola |
| Palmares | La gente liberada vuelve a pie; no encolar ya es su momento vikingo | Vikingos |
| Ayutthaya | El almacén real es un elefante de trabajo; el kraal captura elefantes del mapa | Elefante obrero Tughlaq |

---

## 7. Pedidos concretos, en orden de urgencia

1. **Arreglar el faenar** (tope por edad o cría lenta después). Hoy es un exploit de 160 de alimento cada 3 minutos por corral.
2. **Hacer que mudar la corte etíope valga la pena.** Sin eso, la civ queda en "gult = renta". Lo mínimo: extracción que escale por edad y que la carpa no pare la producción de aldeanos.
3. **Darle a Ayutthaya una decisión económica.** Mínimo, que cada almacén elija qué cobra; ideal, el elefante de trabajo.
4. **Poner un costo a la roza** que la granja no tenga (el monte que se consume, o un tiempo de quema), para que "roza siempre" deje de ser automático. El +18 % a los 30 minutos sale de ahí.
5. **Sacar el arreo de la "fase 2".**
6. **Medir el esfuerzo con vistazos y encolado**, no solo con órdenes.
7. **Probar en el torneo los cruces tortuga** (guaraníes-Palmares e inca-Palmares) y mirar la duración de la partida y cuántas veces se toca lo disputado antes del minuto 15.

**Lo que está muy bien y no tocaría:** la cola de rozas, los cupos de Palmares, el regimiento etiope, la mit'a como recurso que compite entre guerra y economía, el tope de 60 por minuto del malón, el barreal que se agota como el oro de Age y el hecho de que ninguna civ dependa de estar oculta.
