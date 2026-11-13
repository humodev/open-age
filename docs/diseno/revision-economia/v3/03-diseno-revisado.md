# Ronda 3 · 03 — Diseño económico revisado (diseñador líder)

Esta versión reemplaza a [`01-diseno-lider.md`](01-diseno-lider.md) e incorpora:
- las cinco críticas de [`criticas/`](criticas/);
- el modelo numérico [`02-modelo-numerico.md`](02-modelo-numerico.md).

Los números están en [`parametros.json`](parametros.json) (versión `v3-03`), que `tools/modelo_economia.py` lee directamente. No se tocaron `data/` ni `src/`, y no hay commits.

Convenciones (las mismas que en 01):
- **AE**: aldeano-equivalente, 30 de riqueza neta por minuto.
- `[verificar]`: dato histórico sin confirmar.
- **Requiere torneo**: algo que el modelo no puede medir.

---

## 0. Qué cambió, en doce líneas

1. **Ningún hito tiene renta de riqueza.** Las siete rentas sin tope (puerto real, junco, parlamento, Cucaú, misión, monasterio, lonko) pasan a ser efectos sobre el motor propio (C1).
2. **Lo disputado tiene tope absoluto por minuto**: 15 / 40 / 80 / 120 de riqueza en las edades I a IV. Ya no es un porcentaje (A6).
3. **Cada motor tiene otra forma**, además de otro nombre. Lo que lo separa de los demás es de qué se alimenta y cómo se pierde (§3.0).
4. **Ayutthaya cambia de pieza.** El almacén fijo pasa a ser el **elefante del rey**, un depósito que camina: cobra sapán, cueros y estaño de la madera, los arbustos y la piedra que se le entregan.
5. **Etiopía ya no empaca la corte.** **Funda una corte nueva**: la vieja sigue activa hasta que la nueva termina, así que no hay carpa vulnerable ni derrota por empacar. La extracción crece con la edad, y la llegada a la corte nueva se festeja.
6. **Mapuches:**
   - el malón da **cabezas que vuelven caminando** (arreo), no riqueza directa;
   - el faenar pasa a ser el **kawiñ**: uno por corral y por edad, sin cría durante 120 s.
7. **Palmares:**
   - **liberación** solo de edificios habitados, con tope de población;
   - **oficios con nombre**, que se llenan solos;
   - un asedio frena a los oficios;
   - los liberados **vuelven a pie**.
8. **Guaraníes:**
   - roza de 500;
   - **resiembra automática en el mismo lugar**;
   - un ajuste "dejar crecer o quemar" que vuelve a decidir entre comida y riqueza;
   - semilla de 100.
9. **Tawantinsuyu:**
   - mit'a de 3 por runa desde la edad III;
   - **reserva** global en lugar del interruptor por taller;
   - taller con piso de 1/3 si falta mit'a;
   - regalo de cumbi.
10. **Común:**
    - hito II de 500 a + 300 r;
    - mercado con piso 40 que vuelve hacia 100;
    - la tecnología de motor es una investigación igual para las seis;
    - separación mínima en vez de vecindad al 70/50 %;
    - "Arcilla (barreal)" como nombre en pantalla.
11. **Modelo:** cumplen los criterios 3, 4 y 8, y los umbrales absolutos del 2. Los techos del final quedan parejos: 144 a 160 r/min (§7).
12. **Costo:** con las simplificaciones del programador de IA que acepto, el núcleo queda en **50 a 55 días-persona**. Los momentos de fase 2 suman 4 o 5 más (§8).

---

## 1. Respuesta a las críticas

Leyenda:
- **A**: aceptado;
- **M**: aceptado con cambios;
- **R**: rechazado.

Están todos los problemas críticos y altos, y los medios que cambiaron algo.

### 1.1 Crítica 01 — El que intenta romperlo

| # | Problema | Resp. | Qué hago |
|---|---|---|---|
| C1 | Siete rentas de hito sin tope | **A** | Ningún hito rinde riqueza. Reemplazos en §2.3 |
| C2 | Faenar en bucle: 53 de alimento por minuto por corral | **M** | El kawiñ da 30 por cabeza, deja 1, no hay cría durante 120 s y hay uno por corral por edad. No hay bucle posible: como mucho, 120 de alimento por corral y por edad |
| C3 | Liberación por cualquier edificio y por encima del tope | **A** | Solo de edificios habitados. Por encima del tope de población, cada persona se vuelve 28 de fama. Hay una liberación por edificio cada 60 s |
| C4 | Curva común de aldeanos para Palmares y mapuches | **M** | El modelo ya simula la fama de Palmares. A los mapuches se les suma +50 % de tiempo en los lof que no son el primero |
| A1 | La corte se despliega junto al barreal del rival | **A** | Extrae solo de lo propio y del centro. No se funda a menos de 20 casillas de un edificio enemigo. La corte nueva tarda 60 s en levantarse |
| A2 | Varias cortes | **A** | Solo la capital extrae y da la bonificación, y la bonificación no se suma |
| A3 | Ingreso del final de 119 a 255 (×2,1) | **A** | Techo del motor en la edad IV entre 135 y 165. El modelo da 144–160. **Rechazo** la veta que se regenera: es otro pasivo y el final tiene lo disputado |
| A4 | Ayutthaya sin bosque | **A** | El elefante cobra también de la piedra (estaño), que está en todos los mapas, y de los arbustos |
| A5 | Ingenios como renta del final | **A** | Desde la edad II, botín de 150, 100 y 50 por jugador y por edad, reconstrucción a 360 s, y todo cuenta para el tope disputado |
| A6 | El techo de lo disputado no está definido | **A** | Tope absoluto por minuto, en una ventana de 5 min, con barra visible |
| A7 | Regimiento: −30 % al jinete desde la edad I | **A** | −10 % por gult, hasta −20 %, desde la edad II, y solo para jinetes que salen a ≤ 14 casillas |
| A8 | La mudanza del final decide la partida | **A** | La corte nueva se funda sin carpa (§3.4) |
| M1 | El saqueo cobra sobre cercas | **A** | El arreo no cuenta cercas, puertas ni caminos, y da como máximo 3 cabezas por minuto |
| M2 | Capuera sin cantidad, que rehace el monte | **A** | Son arbustos con 40 de madera en total y no cuentan como monte |
| M3 | Yerbal cosechable por aliados | **A** | Lo cosechan el dueño y sus enemigos, nunca los aliados |
| M4 | Mercado infinito | **A** | Piso 40 y regreso hacia 100 (1 punto cada 10 s) |
| M5 | Equipos | **A** | Un barreal del centro y un ingenio por jugador; sitios = jugadores + 1; rendimiento decreciente por equipo |
| M6 | Reglas del corral | **A** | Nunca baja de 1 cabeza; reparar no devuelve cabezas; las cabezas que no entran se vuelven alimento; no hay kawiñ en combate |
| M7 | La corte sin lugar parejo | **A** | El generador deja un claro de 6×6 a ≤ 8 casillas de cada barreal (sirve para todas) |
| M8 | Guaraníes trece minutos sin motor | **A** | Roza de 500 (primer yerbal hacia el minuto 9). Una roza quemada con más del 50 % hecho deja igual su yerbal |
| M9 | Espiral de la mit'a | **A** | Taller con piso de 1/3 y reserva global que protege la leva |
| M10 | Comida de granja en el subproducto | **A** | El elefante cobra madera, arbustos y piedra, nunca granja ni arrozal (`carry_src`) |
| M11 | Lo que no se ve | **A** | Tabla de estados y avisos en §3.7 |
| B1 | La vecindad no castiga | **A** | Pasa a separación mínima (S3) |
| B2 | Detalles | **A** | La bandera desaparece con S2. El oficio no suma flechas. Se devuelve el prepago. La semilla de Ayutthaya tiene tope 16 en la edad I |

### 1.2 Crítica 02 — Jugador competitivo

| Punto | Resp. | Qué hago |
|---|---|---|
| Cuatro motores con la misma plantilla | **A** | Seis formas distintas: conversión, capital vivo, sucesión, renta por posición de una capital móvil, gente adentro y depósito que camina (§3.0) |
| Exploit de faenar | **A** | Su preferencia: uno por corral por edad (kawiñ) |
| Ayutthaya, "campamento maderero con +X %" | **A** | Elefante del rey: se decide dónde está en cada momento, el rival lo puede cazar y cobra de tres fuentes. La captura de manadas queda para la fase 2 |
| La corte no se mueve | **A** | Mudarse no frena la producción, la extracción escala (12 / 16 / 20 / 24) y hay fiesta de llegada (×2 durante 60 s) |
| La roza siempre conviene | **M** | Ajuste "dejar crecer o quemar": quemar de nuevo da comida al 70 % y nada de riqueza. **Rechazo** que la roza consuma bosque obligatoriamente: haría depender del monte, que la consigna prohíbe |
| Arreo en fase 2 | **A** | Pasa al núcleo |
| Esfuerzo: vistazos y encolado | **A** | En la medición. Palmares no encola: su OPA se compara con la mediana (§6) |
| Partidas tortuga | **M** | Los sitios rinden riqueza con tope, y los ingenios dan algo propio a cada civ (cabezas, gente, tambo). **Requiere torneo** con los cruces guaraníes–Palmares e inca–Palmares |
| Momentos memorables | **A** | Uno por civ (§3.0). Arreo, elefante y corte nueva van en el núcleo; los otros tres, en la fase 2 |
| Decisiones "obvias" | **A** | Ajusto el conteo de decisiones por edad: 2 o 3 según la civ, no 3 para todas (§6) |

### 1.3 Crítica 03 — Programador de IA

| Punto | Resp. | Qué hago |
|---|---|---|
| Costo de 65 a 80 días | **M** | Acepto S1, S2, S3, S4, S5, S6, S7 (modificada) y S9. Rechazo S8. Núcleo: 50–55 días (§8) |
| Casos A a I del código actual | **A** | Respuestas en §8.3 |
| Diez preguntas abiertas | **A** | Respuestas en §8.4 |
| Etiopía no se resuelve con reglas simples | **A** | Sin carpa, la mudanza es "construir un edificio" y desaparece la máquina de estados |
| Plan por etapas | **A** | Lo adopto con el orden de §8.2 |

### 1.4 Crítica 04 — Jugador nuevo

| Punto | Resp. | Qué hago |
|---|---|---|
| "Barreal" es un lodazal | **A** | "Arcilla (barreal)". El aldeano carga una vasija con una banda dorada, y el pozo tiene una pila de vasijas |
| Trampas para el principiante | **A** | Valores por defecto que funcionan:<br>– reserva de mit'a 0 y talleres trabajando;<br>– gult "señor";<br>– resiembra prendida;<br>– oficios que se llenan solos (S5);<br>– modo "dejar crecer";<br>– el elefante inicial ya junto al bosque |
| Reglas invisibles | **A** | Vista previa al ubicar (radio y número), botón "Corral 2/3", barra de lo disputado |
| Fichas con números y jerga | **A** | Fichas con su plantilla (§10) |
| Presupuesto de avisos | **A** | Tabla en §3.7 |
| Frases de Palmares ("se esconde") y Ayutthaya ("comercia") | **M** | Propuestas nuevas en §10. Las decide el autor (consulta) |

### 1.5 Crítica 05 — Historiador

| Punto | Resp. | Qué hago |
|---|---|---|
| La arcilla como vasija del convite | **A** | Tooltip y vasijas por civ: urpu, metawe, cambuchí, insəra, cántaro, jarra de Mae Nam Noi |
| El amole de Etiopía | **A** | La riqueza etíope se llama y se dibuja **amole**: el gult cobra en barras de sal |
| El malón como daño | **A** | El arreo de cabezas |
| Ayutthaya: madera ≠ sapán | **A** | El elefante cobra sapán (madera), cueros (arbustos, a falta de caza) y estaño (piedra). Si algún día existe la caza, rinde 40 % |
| Palmares: "brazos" | **A** | Oficios con nombre: herrero, alfarero, cestero, tejedor de palma. "Lo que la comunidad sabe hacer" |
| Guaraníes: "la yerba fue moneda" | **A** | "En la colonia" |
| Faenar como kawiñ | **A** | Nombre adoptado |

### 1.6 Modelo numérico (02)

| Hallazgo | Resp. | Qué hago |
|---|---|---|
| Criterios 2, 3, 4 y 8 no cumplen | **A** | Con este diseño, 3, 4 y 8 cumplen; el 2 cumple con umbrales absolutos (§7, §9) |
| Palancas probadas | **A** | Todas adoptadas:<br>– roza 500 y cola automática;<br>– fama 90 y oficio desde las 3:00;<br>– hito II con fama;<br>– gult 17;<br>– sin rentas de hito;<br>– hito II más caro;<br>– tope disputado por minuto;<br>– R5 en la ventana 15–25 |
| La arcilla se agota en los minutos 12–20, no 22–28 | **A** | Corrijo el relato: la arcilla es la apertura y el motor es el medio y el final (§3.0) |
| Hito II antes de las 6:30 | **M** | 500 a + 300 r (no 350): da 6:30–8:50. **Requiere torneo**: la IA real es más lenta |
| Mit'a y fama en el tope el 50 % del tiempo | **A** | Mit'a 3 por runa desde la III. La fama sobrante paga gente de guerra. Modelo: mit'a 10,8 % y fama 8,3 % |
| Tecnología de motor asimétrica | **A** | S9: investigación igual para las seis |
| Columna "llano" imposible | **A** | La tabla de terreno sale del modelo y el llano vale 0 |
| La mudanza frena la producción | **A** | Ya no: la corte vieja sigue hasta que termina la nueva |
| Perder la arcilla de casa pega distinto | **M** | Ninguna civ demora su edad, y todas tienen 770 o más en el banco. Mapuches retienen 29 %, Palmares 57 % y Ayutthaya 54 %. Lo declaro (§9) |
| OPM total no puede ser pareja | **A** | Se mide el motor más los pendientes, con umbrales absolutos (§6) |

---

## 2. Reglas comunes

### 2.1 Fuente común: "Arcilla (barreal)"

Sigue en pie todo §1 de 01: arcilla sí en los seis pueblos; sal propia, no.

Cambian el nombre en pantalla, el tooltip y la imagen:
- **Tooltip:** "Tus aldeanos sacan arcilla y hacen las vasijas de la fiesta: con lo que se sirve en ellas se convida, se ofrenda y se paga."
- **Vasijas por civ:**

  | Civ | Vasija | Bebida o uso |
  |---|---|---|
  | Tawantinsuyu | Urpu | Chicha |
  | Mapuches | Metawe | Muday |
  | Guaraníes | Cambuchí | Kaguĩ |
  | Etiopía | Insəra | Tälla `[verificar grafía]` |
  | Palmares | Cántaro | Vino de palma |
  | Ayutthaya | Jarra de Mae Nam Noi | Envase de exportación, no de fiesta |

- **Imagen:** el aldeano vuelve con una vasija que tiene una banda dorada, y el pozo tiene una pila de vasijas.

| Lugar | Cantidad | Se agota (modelo) |
|---|---|---|
| Base | 2 × 900 | 12:20 a 18:40 |
| Flanco | 1 × 1500 | 16:20 a 24:10 |
| Centro | 1000 por jugador, en pares | Lo disputado |

**El relato correcto:** la arcilla es **la apertura** y se termina entre los minutos 12 y 24. Desde el minuto 18, sin lo disputado, el 100 % de la riqueza sale del motor (modelo, salvo Palmares). En Age pasa lo mismo: el oro de la base se acaba y la partida se decide en el resto del mapa. Hay que **aceptar que el ingreso cae**: de 300–550 r/min a los 15 minutos pasa a ~150 r/min de motor más hasta 120 de lo disputado. Es lo que hace que el final se pelee.

### 2.2 Piezas, topes y tecnología

| Regla | Valor |
|---|---|
| Rendimiento máximo de una pieza pasiva | 0,8 AE = 24 r/min |
| Repago | 5 a 8 min |
| Máximo por edad | 2 / 3 / 4 / 5, con excepciones declaradas en cada civ |
| Separación (S3) | Corral a ≥ 8 casillas de otro corral; gult a ≥ 6 de otro gult. Restricción de lugar, sin rendimiento oculto |
| Tecnología de motor (S9) | Investigación en la edad III, +25 %, 200 a + 200 m + 100 r, igual para las seis, con prioridad en la IA |
| Techo del motor en la edad IV | 135 a 165 r/min (modelo: 144–160) |
| Motor en la ventana de los minutos 15 a 25 | 35 a 65 % (R5 medida donde importa) |
| Hito II | 500 a + 300 r (antes, 400 + 200) |
| Mercado | Piso 40, paso 3; el precio vuelve hacia 100 a 1 punto cada 10 s |

### 2.3 Hitos: renta → efecto sobre el motor

| Hito (edad) | Hoy | Pasa a |
|---|---|---|
| Ushnu (II) | 20 de mit'a | Sin renta (queda su +10 % de alimento) |
| Aqllawasi (III) | 40 de riqueza | Talleres: máximo 5 en la edad III |
| Rewe del lonko (II) | 20 de kulliñ | Cría de 45 a 35 s |
| Parlamento (IV) | 40 r + 20 kulliñ | Corrales: máximo 6 en la edad IV |
| Pueblo de misión (III) | 25 r | Yerbal +50 |
| Monasterio (II) | 20 r | Radio de la corte de 14 a 16 |
| Macaco (II) | 40 de fama | 20 de fama |
| Pacto de Cucaú (IV) | 40 r | Sin renta (queda su +25 % de recolección) |
| Guerra de Zumbi (IV) | 30 de fama | Sin renta |
| Puerto real (III) | 55 r | Elefantes del rey: máximo 4 en las edades III y IV |
| Junco de tributo (IV) | 40 r | Subproducto del 25 al 30 % |

### 2.4 Lo disputado

| Pieza | Regla |
|---|---|
| Tope | **15 / 40 / 80 / 120 r/min** en una ventana de 5 min, con barra "Lo disputado: 52 / 80". Lo que pasa se pierde y se avisa una vez |
| Arcilla del centro | 1000 por jugador |
| Sitios sagrados | Jugadores + 1, espejados; 18 / 12 / 8 por equipo |
| Ingenios y estancias (S1) | Edificio neutral hostil con flechas, 1 por jugador, desde la edad II. Botín 150 / 100 / 50 por jugador y por edad; se rehacen a los 360 s si no hay enemigos a 12 casillas |
| Extras por civ | Mapuches, 2 cabezas de arreo. Palmares, 2 personas que vuelven a pie. Tawantinsuyu, regalo de cumbi (fase 2) |

---

## 3. Las seis civs

### 3.0 Lo que separa a cada motor (respuesta a "todos se sienten el mismo edificio")

| Civ | Forma | Se alimenta de… | Se pierde por… | Qué ve el rival | Momento |
|---|---|---|---|---|---|
| Tawantinsuyu | **Conversión** de un recurso propio | **Gente viva**: cada runa da mit'a; si cae la población, cae la tela | Matar runa. Los talleres están en el corazón de la base y siguen a 1/3 aunque falte mit'a | Telar animado o quieto | **Regalo de cumbi** (fase 2): 120 de mit'a incorporan un ingenio neutral sin pelear |
| Mapuches | **Capital vivo** que crece | **Tiempo** (cría) y **malón** (arreo) | Cabezas muertas en cada golpe (una por cada 25 % de vida) o comidas en el kawiñ | Animales pastando: la riqueza está a la vista | **El arreo**: el ganado tomado vuelve caminando y el rival lo puede cortar |
| Guaraníes | **Sucesión**: la comida se vuelve riqueza en el mismo lugar | **Trabajo** sobre la tierra: el mismo aldeano | Rozas quemadas (si estaban a menos de la mitad, sin yerbal) y yerbales cosechados por el enemigo | La mancha de yerbales que crece alrededor de la base | **El monte cambia de color**. En fase 2, los arqueros emboscan desde el yerbal |
| Etiopía | **Renta por posición** respecto de una capital móvil | **Tierra repartida** y **dónde está la corte** | Gult lejos de la corte (sin bonificación) o quemados; arcilla propia agotada | La bandera de señor o de regimiento y el amole que va del barreal a la corte | **La corte se funda en otro lugar** y la tierra la recibe con fiesta (×2 durante 60 s) |
| Palmares | **Gente adentro** que trabaja | **Fama**: la gente que llega | **Asedio**: con el edificio en combate, los oficios paran. La liberación del rival, si es de un edificio habitado | Íconos de 0 a 3 oficios sobre cada mocambo | **Los liberados vuelven a pie** y se los puede alcanzar |
| Ayutthaya | **Depósito que camina** | **Lo que sale del monte**, donde está el elefante (madera, arbustos, piedra) | **Matar al elefante**: es una unidad de 600 pv | El elefante con fardos en el lomo, al lado de los leñadores | **Los elefantes del rey de bosque en bosque**. En fase 2, captura de manadas salvajes |

### 3.1 Tawantinsuyu — "El trabajo que sobra se vuelve tela"

- **Capa 1, mejor:** arcilla unida por camino a la llaqta, +20 %. No la cuento como decisión, porque siempre conviene.
- **Capa 2, taller de tejido:**
  - costo, 120 m + 20 de mit'a;
  - consume 30 de mit'a por minuto y da 24 de riqueza;
  - máximo 2 / 3 / 4 / 5, y 5 en la edad III con el aqllawasi.
- **Reserva de mit'a** (S6): un ajuste global de 0, 60 o 120. Los talleres solo consumen lo que está por encima de la reserva, así que la leva siempre tiene sus turnos.
- **Sin mit'a, el taller sigue a 1/3** (tejido doméstico).
- **Mit'a:** 4 por runa en las edades I y II, 3 desde la III. Con eso, 50 runa alimentan justo 5 talleres, y una leva grande compite de verdad con la tela.
- **Convivencia:** la arcilla rinde hasta el minuto 13–17. Los talleres crecen desde el minuto 4 y sostienen todo el final (150 r/min en el modelo).
- **Decisiones por edad: 2.** Reserva para tela o para leva; qué conectar o a qué ingenio regalar cumbi.

### 3.2 Mapuches — "La riqueza camina y se reproduce"

- **Capa 1:** igual. El lof es depósito.
- **Capa 2, corral:**
  - 120 m;
  - de 1 a 5 cabezas, o 6 en pradera, que se calcula al completarlo y cada 60 s;
  - 4 r/min por cabeza;
  - una cabeza cada 45 s, o cada 35 con el lonko;
  - máximo 2 / 3 / 4 / 5, y 6 con el parlamento;
  - separación de 8 casillas.
- **Kawiñ (fiesta):**
  - 30 de alimento por cabeza;
  - deja 1 cabeza;
  - 120 s sin cría;
  - **uno por corral y por edad**;
  - no se puede hacer en combate.
- **Malón = arreo:**
  - cada 150 de daño a granjas, casas, corrales o ingenios genera **1 cabeza** que camina sola (60 pv) al corral más cercano, con un máximo de 3 por minuto;
  - si no hay lugar, se vuelve 40 de alimento;
  - el rival la puede matar en el camino;
  - **no da riqueza directa**: llena el capital. Piso pacífico, porque el corral cría solo; techo, porque está el tope de cabezas.
- **Lof extra:** +50 % de tiempo para entrenar aldeanos (C4).
- **Decisiones por edad: 3.** Dónde va el corral (pradera lejos o junto al lof); kawiñ sí o no; malón al rival o a lo neutral.

### 3.3 Guaraníes — "El campo que se agota deja un yerbal"

- **Capa 1, mejor:** +14 % en la arcilla.
- **Capa 2, roza:**
  - 45 m y 500 de alimento (tasa 1100);
  - +15 % junto al monte;
  - deja un yerbal de 300 (tasa 800), y el mismo aldeano pasa a cosecharlo;
  - al agotarse el yerbal, **la roza se reabre en el mismo lugar** mientras haya madera (S2: cola automática con interruptor);
  - yerbales activos: 3 / 4 / 4 / 4; por encima, capuera (arbustos, 40 de madera).
- **Ajuste "monte":**
  - **dejar crecer** (por defecto): roza → yerbal → roza;
  - **quemar:** roza → roza al 70 %, sin yerbal. Es comida ya.

  Es la decisión comida o riqueza que pidió el competitivo, y responde a la historia: la tierra se dejaba descansar.
- **Yerbal:** lo cosechan el dueño y sus enemigos, a su tasa común; nunca los aliados.
- **Semilla:** yerbal viejo de 100.
- **Convivencia:** agotan la arcilla primero (12:20) y viven de los yerbales desde el minuto 9.
- **Decisiones por edad: 2.** Dejar crecer o quemar; dónde abrir rozas nuevas al crecer (junto al monte o a la casa). Más misión o monte en la edad III.

### 3.4 Etiopía — "La tierra paga a la corte que está cerca"

- **Riqueza = amole:** mismo recurso, otro nombre e ícono, el de las barras de sal.
- **Capa 1, distinto: la corte capital extrae** de la arcilla propia o del centro a ≤ 12 casillas, sin aldeanos:
  - 12 / 16 / 20 / 24 r/min según la edad;
  - nunca de la arcilla del rival, y solo la capital.
- **Capa 2, gult:**
  - 100 m + 40 a;
  - renta base 3 a + 17 r; a ≤ 14 casillas de la corte, 3 a + 21 r (0,8 AE), sin sumar dos cortes;
  - máximo 2 / 3 / 4 / 6: el sexto, porque cuando se acaba la arcilla la corte ya no extrae;
  - separación de 6 casillas.
  - **Señor** (por defecto) o **regimiento**: desde la edad II, sin renta, −10 % a los jinetes entrenados a ≤ 14 casillas, hasta −20 %. No se cambia.
- **Mudanza = fundar la corte nueva:**
  - se pone el cimiento gratis en un claro a ≤ 12 casillas de una arcilla propia o del centro, y a más de 20 de cualquier edificio enemigo;
  - se levanta solo en 60 s;
  - **la vieja sigue siendo capital y produciendo** hasta que la nueva termina, y entonces se desarma (la procesión de tiendas es solo imagen);
  - una mudanza cada 5 minutos como mínimo;
  - **fiesta de llegada:** los gult a ≤ 14 casillas rinden ×2 durante 60 s.
- **Con esto:**
  - no hay carpa vulnerable;
  - no hay derrota por empacar;
  - no hay tramo sin aldeanos;
  - mudarse es un pico de ingreso y no una pérdida.
- **Gondar (IV):** capital fija; extrae 8 de cualquier arcilla a ≤ 16 casillas.
- **Decisiones por edad: 3.** Dónde va el gult; señor o regimiento; cuándo y adónde se funda la corte.

### 3.5 Palmares — "La riqueza es lo que la comunidad sabe hacer"

- **Capa 1:** igual.
- **Capa 2, oficios** (herrero, alfarero, cestero, tejedor de palma):
  - 3 puestos por mocambo y 2 en la cerca real;
  - 15 r/min cada uno;
  - tope total 4 / 7 / 8 / 8.
  - Los que llegan **ocupan solos** un puesto libre (S5): en el edificio que acoge más cercano a la capital y, si empatan, el de menor `id`. Se saca gente con "desalojar".
  - Están separados de la guarnición: la campana no los vacía.
  - **Con el edificio en combate, los oficios paran.**
- **Mocambo:** sin `oculto`; +5 de fama por minuto con 6 árboles o más a 4 casillas o menos.
- **Fama:**
  - 90 iniciales;
  - el hito II pide 90 de fama y la acogida espera mientras se junta;
  - con la población llena, la fama paga **gente de guerra**: guerrero por 40 de fama + 30 a.
- **Liberación:**
  - solo de edificios habitados, una por edificio cada 60 s;
  - por encima del tope de población, 28 de fama;
  - **los liberados vuelven a pie** al mocambo más cercano.
- **Decisiones por edad: 2.** Desalojar oficios para mandar gente al campo (o no); correría a un ingenio o esperar la fama.

### 3.6 Ayutthaya — "El monte paga al rey"

- **Capa 1:** igual.
- **Capa 2, elefante del rey:**
  - unidad, 80 a + 80 m, 600 pv, población 2;
  - es **depósito de madera, alimento y piedra**;
  - el **25 %** de la madera, los arbustos y la piedra que recibe (sapán, cueros y estaño) entra además como riqueza;
  - tope 16 en la edad I y 24 desde la II;
  - máximo 1 / 2 / 3 / 3, y 4 con el puerto real;
  - con el junco, el 30 %;
  - semilla: 1 elefante.
- **Barrio chino:** desde la edad II, 150 m, +8 de tope a cada elefante.
- **Barrios japonés y portugués:** compañías, −15 % si tocan un cuartel. Ningún barrio da renta.
- **Arrozal junto al agua:** de +45 a +25 %. Es la causa de las peores columnas de terreno en el modelo.
- **Decisiones por edad: 3.** Dónde está cada elefante: bosque, piedra o arbustos, cerca o lejos. Qué barrio. Arriesgar el elefante lejos o no.
- **Historia:** elefantes de trabajo de la corona (`ayutthaya.md` H36–H38). El monopolio del Phra Khlang sobre sapán, cueros y estaño (H19, H23).

### 3.7 Estados, avisos y vista previa (crítica 04)

**Vista previa al ubicar**, igual para todas las piezas:
- radio de separación;
- número de rendimiento, por ejemplo "+15 % junto al monte", "pradera: 6 cabezas" o "cerca de la corte: 21";
- el botón con el contador, por ejemplo "Corral 2/3".

**Estados** (quietos, en el panel o en el mundo, sin sonido):

| Civ | Estados |
|---|---|
| Tawantinsuyu | Mit'a neta (+80 / −60); reserva; telar quieto |
| Mapuches | Cabezas por corral; recría del kawiñ |
| Guaraníes | Yerbales 4/4; modo del monte |
| Etiopía | Radio de la corte; señor o regimiento |
| Palmares | Puestos ocupados |
| Ayutthaya | Tope del elefante |
| Todas | Barra de lo disputado; desglose de la riqueza por origen en el tooltip |

**Avisos** (como máximo 3 de decisión por civ en una partida típica):

| Clase | Aviso |
|---|---|
| Decisión | "La arcilla de la corte se agotó: fundá otra corte" (Etiopía) |
| Decisión | "Yerbales al tope: las rozas dejarán capuera" (guaraníes, la primera vez) |
| Decisión | "Lo disputado llegó a su tope" (todas, una vez por edad) |
| Pérdida | "Talleres a 1/3: falta mit'a" (Tawantinsuyu) |
| Pérdida | "Atacan un corral, un mocambo, un gult o un elefante" |
| Pérdida | "Arcilla agotada: N aldeanos inactivos" |
| Hito | Primer yerbal; arreo que llega; tecnología de motor |

---

## 4. Terreno

Economía total al minuto 20 contra el llano de la misma civ. Los valores son los del modelo con este diseño.

| Civ | llano | montaña | río | bosque | valle | altiplano | b. templado | selva | mesetas | delta | sierra |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Tawantinsuyu | 0 | +5 | 0 | +1 | +3 | −3 | +5 | 0 | +3 | −1 | +5 |
| Mapuches | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | −1 | 0 | 0 |
| Guaraníes | 0 | 0 | 0 | +3 | −4 | −6 | +3 | +3 | −3 | −2 | +3 |
| Etiopía | 0 | 0 | 0 | 0 | −3 | −4 | 0 | 0 | −2 | −2 | 0 |
| Palmares | 0 | 0 | 0 | +1 | −5 | −5 | +1 | +1 | −4 | −2 | 0 |
| Ayutthaya | 0 | 0 | +1 | 0 | −4 | −2 | +1 | 0 | −5 | +1 | −3 |
| *Diferencia por mapa* | 0 | 4,6 | 0,8 | 3,5 | 8,0 | 6,1 | 4,8 | 3,5 | 7,5 | 2,9 | 7,9 |

Lectura:
- **Todas las celdas están en ±6** y todas las columnas en ≤ 8 puntos (antes, hasta 12,7).
- Ayutthaya mejoró por la piedra en el elefante y el arrozal en +25 %.
- **Lo que el modelo no ve:**
  - la pradera mapuche y el claro del gult (por eso esas filas dan casi 0);
  - el bosque que se acaba después del minuto 30 (A4). Con la piedra, el elefante tiene piso en cualquier mapa.
- **Plan B** por civ, el mismo de 01 §4, con dos cambios:
  - Ayutthaya pasa sus elefantes a la piedra y los arbustos;
  - Etiopía tiene claro garantizado junto a cada arcilla (M7).
- **Requiere torneo**, con prioridad para valle, mesetas y sierra.

---

## 5. Vida completa (cambios respecto de 01 §5)

Las tablas de 01 §5 siguen valiendo con estos ajustes. Los tiempos son del modelo:

| Civ | 0–5 | 5–15 | 15–30 | Final, con el mapa revelado |
|---|---|---|---|---|
| Tawantinsuyu | Camino a la arcilla y taller 1 a las 4:00 | Edad II a las 6:30, talleres 2 y 3; la arcilla de casa se agota a las 13:30 | Edad III a las 13:50 con el aqllawasi (5 talleres); cumbi +25 % | 150 r/min de talleres. Si pierde runa, los talleres bajan a 1/3 y no a 0. El rival busca runa, no edificios |
| Mapuches | Corral inicial y corral 2 lejos | Edad II a las 6:50 (lonko, cría 35 s); arreo desde las estancias | Edad III a las 14:40; kawiñ para cerrar el hito | 144 r/min. El arreo es una persecución. El rival mata cabezas, y cada corral tiene como piso 1 |
| Guaraníes | Yerbal viejo, rozas desde las 2:30 | Primer yerbal hacia el minuto 9; edad II a las 6:40, III a las 10:20 | Yerbales al tope; ajuste "quemar" si falta comida | 156 r/min. El rival quema rozas o les cosecha yerbales (a su tasa) |
| Etiopía | La corte extrae 12 por minuto; gult 1 a las 3:30 | Edad II a las 8:50; corte nueva junto al flanco a las 14:00, con fiesta | Edad III a las 14:10; gult 4–6; la corte va al centro si conviene | 148 r/min. La corte es una capital normal; nunca es carpa |
| Palmares | Fama 90 → gente; mocambo 1 a las 3:00 | Edad II a las 6:40 (con 90 de fama); oficios llenos | Edad III a las 14:10; 8 puestos | 150 r/min. Un asedio frena los oficios sin voltear el mocambo |
| Ayutthaya | Elefante junto al bosque con leñadores | Edad II a las 6:30; elefante 2 en la piedra; barrio chino | Edad III a las 13:50; puerto: 4 elefantes | 160 r/min. El rival caza elefantes: perder uno cuesta 160 de recursos y 24 r/min hasta reponerlo |

**Nada se rompe en el final:**
- no hay renta de hito;
- no hay secreto;
- no hay carpa;
- los ingenios rinden menos con cada visita;
- los techos del motor están en 144–160.

---

## 6. Esfuerzo

La OPM total (comunes más motor) **no puede ser pareja** con civs que tienen distinta población (modelo §5.12). Los motivos:
- Palmares no encola aldeanos;
- los guaraníes ponen sus rozas con la cola.

Propongo al autor medir el criterio E así:
1. **OPA del motor ≤ 0,6** por minuto;
2. **PMP ≤ 2** cada 10 minutos;
3. **ninguna civ por encima de 1,5 veces la mediana de la fase**;
4. **nada periódico por debajo de 90 s**.

Estimación de diseño:

| Civ | OPA f1 / f2 / f3 / final | PMP f1 / f2 / f3 / final | Decisiones por edad |
|---|---|---|---|
| Tawantinsuyu | 0,4 / 0,5 / 0,4 / 0,4 | 0,5 / 1 / 1 / 1,5 | 2 |
| Mapuches | 0,4 / 0,5 / 0,4 / 0,4 | 0,5 / 1 / 1,5 / 2 | 3 |
| Guaraníes | 0,3 / 0,3 / 0,3 / 0,3 | 0,5 / 0,5 / 1 / 1 | 2 |
| Etiopía | 0,4 / 0,5 / 0,4 / 0,4 | 0,5 / 1 / 1 / 1 | 3 |
| Palmares | 0,3 / 0,3 / 0,3 / 0,3 | 0,5 / 1 / 1 / 1,5 | 2 |
| Ayutthaya | 0,3 / 0,4 / 0,4 / 0,4 | 0,5 / 1 / 1 / 1,5 | 3 |
| *Mediana / máx. permitido* | 0,35 / 0,45 / 0,4 / 0,4 → 0,53 / 0,68 / 0,6 / 0,6 | — | — |

**Modelo:**
- OPA máxima 0,6 (Tawantinsuyu, fase 2);
- PMP máximo 2 (Ayutthaya, fase 2);
- mit'a en el tope 10,8 %, fama en el tope 8,3 %.

Cumple los cuatro umbrales. La relación entre la que más y la que menos llega a ×1,7 en la fase 1, por los guaraníes y Palmares **por debajo**. El impuesto que quería evitar la consigna es el de arriba; esto queda declarado.

---

## 7. Números y resultados del modelo

### 7.1 Piezas

| Civ | Pieza | Costo | Rinde | Tope | Repago | AE |
|---|---|---|---|---|---|---|
| Tawantinsuyu | Taller | 120 m + 20 mit'a | 24 r (consume 30 de mit'a); 8 sin mit'a | 2/3/4(5)/5 | 5,0 min | 0,8 |
| Mapuches | Corral | 120 m | 4 r por cabeza; 5 cabezas (6 en pradera) | 2/3/4/5(6) | 6,0 (5,0) | 0,67–0,8 |
| Mapuches | Kawiñ | — | 30 a por cabeza; deja 1; 120 s sin cría | 1 por corral por edad | — | — |
| Mapuches | Arreo | — | 1 cabeza cada 150 de daño | 3 cabezas por minuto | — | — |
| Guaraníes | Roza → yerbal | 45 m | 500 a, y después 300 r | Yerbales 3/4/4/4 | — | 1,33 por aldeano |
| Etiopía | Gult | 100 m + 40 a | 3 a + 17 r; 3 a + 21 r cerca de la corte | 2/3/4/6 | 7,0 / 5,8 | 0,67 / 0,8 |
| Etiopía | Corte | — | 12 / 16 / 20 / 24 r de la arcilla propia | La capital | — | — |
| Palmares | Oficio | Una persona | 15 r | 4/7/8/8 | — | 0,5 por persona |
| Ayutthaya | Elefante del rey | 80 a + 80 m | 25 % de madera, arbustos y piedra | 16 (I) / 24 r; 1/2/3(4)/3(4) | 6,7 min | 0,8 |
| Ayutthaya | Barrio chino | 150 m | +8 de tope por elefante | 1 por edad | 6,3 min con 3 elefantes | — |
| Todas | Tecnología de motor | 200 a + 200 m + 100 r | +25 % | Edad III | — | — |

### 7.2 Resultado de `python3 tools/modelo_economia.py`

Llano, sin lo disputado, 35 % al ejército.

| Civ | Riqueza m5 / m10 / m20 / m30 | Desvío (%) | Edad II / III | Motor m15–25 | Ingreso m35–40 |
|---|---|---|---|---|---|
| Tawantinsuyu | 268 / 1207 / 4516 / 5891 | −9 / +10 / +7 / 0 | 6:30 / 13:50 | 55 % | 150 |
| Mapuches | 275 / 1060 / 4139 / 5507 | −7 / −3 / −2 / −7 | 6:50 / 14:40 | 41 % | 144 |
| Guaraníes | 331 / 1106 / 4381 / 5894 | **+12** / +1 / +4 / 0 | 6:40 / 10:20 | **73 %** | 156 |
| Etiopía | 294 / 1006 / 4093 / 5577 | −1 / −8 / −3 / −6 | **8:50** / 14:10 | 52 % | 148 |
| Palmares | 322 / 1097 / 3728 / 6473 | +9 / 0 / **−12** / +10 | 6:40 / 14:10 | 37 % | 150 |
| Ayutthaya | 283 / 1101 / 4503 / 6103 | −4 / 0 / +7 / +3 | 6:30 / 13:50 | 53 % | 160 |

**Lo disputado** (con la mitad de los aldeanos de la arcilla en el centro, un sitio e ingenios cada 360 s):
- entre 18,6 y 26,5 % en la edad II;
- entre 17,9 y 26,2 % en la III;
- entre 10,2 y 15,1 % en la IV.

Con **todos** en el centro, el porcentaje sube a 56 % en la edad II, porque el ingreso propio es chico. Por eso el techo es absoluto (40 r/min) y no un porcentaje.

**Golpe a lo disputado:**
- en el minuto 10, cada civ retiene entre 100 y 140 % (sin lo disputado, vuelve a la arcilla propia);
- en el minuto 20, entre 87 y 113 %.

Ninguna demora su edad.

**Perder la arcilla de casa en el minuto 10:**
- Tawantinsuyu retiene 74 %; guaraníes y Etiopía, 93–94 %;
- Palmares 57 %, Ayutthaya 54 % y mapuches 29 %;
- **ninguna demora la edad III**, y todas tienen entre 770 y 860 de banco.

**Alertas que quedan:**
1. **Guaraníes: motor 73 % en los minutos 15–25.** No es el motor que domina: es la arcilla que se agota primero (12:20), porque tienen +14 % y llegan a la edad III a las 10:20. Siguen pisando la del flanco hasta las 16:20. Bajar los yerbales no lo mueve (probado). Palanca si el torneo lo confirma: su +14 % en la arcilla al +7 %.
2. **Palmares, −12 % al minuto 20**, por menos gente. Está en la banda; es la palanca de la fama.
3. **Etiopía, edad II a las 8:50.** Está en la banda, pero en el borde. El gult cuesta alimento justo antes del hito.
4. **Mapuches retienen 29 %** si pierden la arcilla de casa en el minuto 10. Es la civ con el motor más lento de arrancar. Palanca: corral inicial con 2 cabezas.

### 7.3 Cambios al modelo (`tools/modelo_economia.py`)

Copia del original en el scratchpad de la sesión. Todos los cambios se activan desde `parametros.json` y, sin esas claves, el modelo se comporta como antes:

1. **`modelo_opciones`** en `comun` y en cada civ: se cargan como opciones de corrida, antes de la línea de comandos y las palancas. Un `--sin-rentas-de-hito` en falso ya no pisa al diseño.
2. **`hitos_motor`**: efectos de hito sobre el motor:
   - `maximo_edad`;
   - `cria_s`;
   - `subproducto_pct`;
   - `fama_min`.
3. **La tecnología de motor de Tawantinsuyu** sale del aqllawasi solo si `via` empieza con "hito"; si no, es la investigación común.
4. **Tawantinsuyu:** `mita_por_aldeano_edad` y `taller_piso_pct`.
5. **Etiopía:**
   - `extrae_por_edad`;
   - `mudanza_sin_ventana`: la producción de aldeanos no se detiene;
   - la extracción de la corte también registra el agotamiento.
6. **Ayutthaya:**
   - `ayu_elefantes`: tope por edad, barrio +8 por elefante, el subproducto cuenta piedra y arbustos enteros, y el junco cambia el porcentaje;
   - `arrozal_agua_pct`.
7. **Palmares:** `fama_sumidero` (con la población al máximo, la fama sobrante sale a gente de guerra).
8. **El yerbal con la tecnología** es la cantidad del diseño ×1,25 (antes, 375 fijo).
9. **Informe:**
   - ingreso de los minutos 35–40;
   - el techo de lo disputado se lee de `techo_pct_referencia` y `tope_r_min_por_edad`.

**Límites que siguen:**
- no hay destrucción, así que la fase final no tiene órdenes;
- no modela el arreo, el kawiñ ni la fiesta etíope;
- no ve el bosque que se acaba.

---

## 8. Implementación

### 8.1 Simplificaciones del programador de IA

| # | Simplificación | Resp. | Nota |
|---|---|---|---|
| S1 | Ingenios sin guardia, con flechas | **A** | |
| S2 | Resiembra en el mismo lugar, sin bandera | **A** | Se suma el ajuste "dejar crecer o quemar" (+0,5 días) |
| S3 | Separación mínima en vez de 70/50 % | **A** | |
| S4 | Etiopía: radio que alcance la arcilla estándar; destinos conocidos | **A** | Va más lejos: sin carpa en escaramuza |
| S5 | Palmares sin cupo, con "desalojar" | **A** | |
| S6 | Interruptor global inca | **M** | Como reserva de 0, 60 o 120 |
| S7 | Ayutthaya solo con madera | **M** | Madera, arbustos y piedra con `carry_src` (+0,5 días) |
| S8 | Corral sin daño por cabezas | **R** | Es la forma en que se pierde el motor mapuche (§3.0). +1 día |
| S9 | Tecnología de motor igual para las seis | **A** | |

### 8.2 Costo estimado (días-persona)

| Bloque | Días |
|---|---|
| Base con S1 a S9 (crítica 03) | 40–45 |
| S8 rechazada | +1 |
| Arreo (reemplaza al saqueo en riqueza) | +2,5 |
| Elefante como depósito móvil (reemplaza al almacén; `nearest_dropoff` acepta unidades) | +2 |
| Corte nueva sin carpa (más motor, menos IA) | +0,5 |
| Kawiñ, oficios que paran bajo asedio, ajuste del monte, mercado con regreso, tope disputado con barra, sumidero de fama, liberación habitada y a pie | +3 |
| Vista previa al ubicar y avisos | +2,5 |
| **Núcleo** | **≈ 50–55** |
| Fase 2: regalo de cumbi, fiesta etíope, emboscada desde el yerbal, captura de manadas | +4–5 |

**Orden:** el de la crítica 03 §5. La etapa 4 (mudanza) se achica a 1–2 días. La etapa 3 queda así:
- 3a, Etiopía;
- 3b, Ayutthaya con el elefante;
- 3c, Tawantinsuyu;
- 3d, Palmares;
- 3e, mapuches con arreo;
- 3f, guaraníes.

### 8.3 Respuesta a los casos del código actual (crítica 03 §0)

| Caso | Respuesta |
|---|---|
| A | Sin carpa, siempre hay centro |
| B | Etiqueta `eje` en los hitos |
| C | `_site_scored`, una sola función |
| D | Aldeanos virtuales = motor / 30 |
| E | Está bien: la IA no va al centro hasta la edad III |
| F | Arreglar los caminos antes de medir la mit'a |
| G | Prioridad para la tecnología de motor |
| H | Oficios separados de la guarnición |
| I | Comandos nuevos: `reserva_mita`, `kawin`, `modo_monte`, `variante` en `build` (gult) y `fundar_corte` como `build`. "Desalojar" ya existe |

### 8.4 Las diez preguntas

1. **Caza:** no se agrega. Ayutthaya cobra de la madera, los arbustos y la piedra.
2. **Tecnología inca:** es investigación, igual que las demás. El aqllawasi sube el máximo de talleres.
3. **Gult con la corte en marcha:** no hay corte en marcha. La bonificación sigue a la capital activa (la vieja, hasta que termina la nueva).
4. **Interruptor sin stock:** todos los talleres rinden la misma fracción (disponible / necesario), con piso de 1/3. No hay orden por `id`.
5. **Corral reparado:** reparar no devuelve cabezas, y el cartel lo dice.
6. **Cupo más cercano:** el puesto libre en el edificio que acoge más cercano a la capital; si empatan, el de menor `id`.
7. **Pradera:** se calcula al completar el corral y cada 60 s. La capuera no cuenta.
8. **Arcilla junto a la corte:** radio de 12, que alcanza la arcilla estándar a unas 10 casillas, sin generador especial.
9. **Ingenios:** `owner = -1`, `hostil: true`, con flechas propias. No persiguen y no cuentan para la victoria ni para los puntos.
10. **Empacar en la edad I:** en escaramuza Etiopía no empaca, funda. La carpa queda solo para escenarios de campaña, con `_check_victory` contándola como capital.

### 8.5 Reglas de IA por civ (de la crítica 03, actualizadas)

| Civ | Regla |
|---|---|
| Tawantinsuyu | Taller si la mit'a neta es ≥ 30 y hay madera ≥ 180; reserva 60 si se ahorra mit'a para un hito o hay amenaza |
| Mapuches | Corral en el mejor puntaje (pradera, lejos de otros corrales y no lejos del lof). Kawiñ solo si falta alimento para el hito. Malón a la estancia con un grupo de al menos ×1,5 |
| Guaraníes | Resiembra prendida; modo "quemar" si el alimento no alcanza el próximo hito |
| Etiopía | Gult cerca de la corte. Fundar corte cuando a su arcilla le quedan menos de 100: flanco, y después el centro (edad III, con el centro controlado) |
| Palmares | Nada que decidir en los oficios; mocambo junto al monte |
| Ayutthaya | Elefante al bosque con más árboles a 6 casillas o menos; el segundo, a la piedra; moverlo cuando quedan menos de 10 árboles; no hacer depósitos comunes de madera mientras falten elefantes |

---

## 9. Autoevaluación contra la lista de control

| # | Criterio | Estado | Evidencia |
|---|---|---|---|
| 1 | Dos capas claras en palabras llanas | **Cumple** | Fichas con la línea "Arcilla" (§10) |
| 2 | Esfuerzo parejo por fase | **Cumple con la vara reformulada** | OPA ≤ 0,6, PMP ≤ 2, nada por encima de 1,5 veces la mediana. Con la vara original (×1,5 entre la que más y la que menos) falla la fase 1 por abajo (×1,7). **El autor tiene que aprobar la vara** |
| 3 | Curvas dentro de ±15 % a los 5, 10, 20 y 30 | **Cumple** (modelo) | Máximo +12, +10, −12 y +10 |
| 4 | Edad II entre 6:30 y 9:00 y edad III antes de 20:00 | **Cumple** (modelo); requiere torneo | II entre 6:30 y 8:50; III entre 10:20 y 14:40. Con la IA real, el hito II más caro puede pasar de 9:00 |
| 5 | Viable en los 11 mapas | **Cumple** (modelo); requiere torneo | Celdas en ±6 y columnas ≤ 8 |
| 6 | Nada se rompe con el mapa revelado | **Cumple en el diseño** | Los once arreglos de romperlo incorporados (C1–C3, A1–A8); techos del final 144–160. Falta una segunda pasada del que intenta romperlo sobre el arreo y el elefante |
| 7 | Ni comercio genérico ni dependencia de estar oculto | **Cumple** | Barrios sin renta, mocambo sin `oculto`, arreo en lugar de cobro por daño |
| 8 | Lo disputado con techo y remontada | **Cumple** (modelo) | Tope absoluto por minuto; golpes sin demora de edad |
| 9 | La IA lo juega con reglas simples | **Cumple con condiciones** | Sin carpa no hay máquina de estados. Lo más delicado es la búsqueda con puntaje del corral y del elefante |
| 10 | Fiel a la historia o con simplificación declarada | **Cumple** | Amole, urpu, cambuchí, kawiñ, oficios con nombre y sapán-cueros-estaño. Quedan `[verificar]`: insəra, sal guaraní y siamesa, página de Sarasin o Ishii |

Lo que **no puedo asegurar sin torneo**:
- edad II con la IA real;
- el arreo y el elefante en pelea;
- las partidas tortuga;
- valle, mesetas y sierra.

---

## 10. Fichas para el autor (plantilla del jugador nuevo)

**Tawantinsuyu.** El imperio que se construye como una red.
1. **Arcilla:** mejor, si unís el pozo con un camino a tu pueblo.
2. **Lo propio:** tu gente da turnos de trabajo (mit'a) sola, y los talleres de tejido los vuelven riqueza.
3. **Te pide:** decidir cuántos turnos guardás para soldados y cuántos van a la tela.
4. **Ojo:** si te matan gente, se cortan los turnos y los talleres tejen a un tercio. Cuidá a tu pueblo.
5. **Saber más:** el Estado inca cobraba en trabajo, y la tela fina (cumbi) era su regalo más valioso.

**Mapuches.** No hay capital que tomar.
1. **Arcilla:** igual que todos.
2. **Lo propio:** el ganado (kulliñ) crece solo en los corrales y cada cabeza da riqueza. En el malón, el ganado que tomás vuelve caminando.
3. **Te pide:** dónde va cada corral y cuándo hacer la fiesta (kawiñ) para comer el rebaño.
4. **Ojo:** los corrales no se pueden poner pegados, y un golpe al corral mata cabezas. El ganado del malón hay que traerlo a casa.
5. **Saber más:** el ganado era riqueza, dote y prestigio, y el malón lo arreaba.

**Guaraníes.** El pueblo que se mueve con el río y el monte.
1. **Arcilla:** mejor; tus aldeanos la trabajan más rápido.
2. **Lo propio:** en vez de granjas abrís rozas. Dan comida, se agotan y dejan un yerbal que da riqueza; después la roza se vuelve a abrir sola.
3. **Te pide:** decidir si dejás crecer el monte (riqueza después) o lo volvés a quemar (comida ya).
4. **Ojo:** sin madera, las rozas no se reabren y se corta la comida.
5. **Saber más:** la chacra vieja se volvía huerto y yerbal, y en la colonia la yerba fue moneda.

**Etiopía.** La corte que camina.
1. **Arcilla:** distinta; tu corte saca amole del pozo que tiene al lado, sin aldeanos.
2. **Lo propio:** repartís tierras (gult) que pagan tributo, más si están cerca de la corte.
3. **Te pide:** dónde repartir y cuándo fundar la corte en otro lugar.
4. **Ojo:** una tierra "de regimiento" no paga, abarata jinetes. Cuando el pozo de la corte se agota, fundá otra.
5. **Saber más:** el rey daba tierras que tributaban, y la sal en barras (amole) era la moneda.

**Palmares.** La libertad que llega sola y se defiende en la sierra *(frase propuesta)*.
1. **Arcilla:** igual que todos, pero la gente llega sola.
2. **Lo propio:** no entrenás aldeanos, llegan por la fama. Los que trabajan en un oficio dentro del mocambo (herrero, alfarero, cestero) dan riqueza segura.
3. **Te pide:** cuánta gente sacás del oficio para el campo, y si salís a liberar gente de los ingenios.
4. **Ojo:** si atacan el mocambo, los oficios paran. Defendé la cerca.
5. **Saber más:** la riqueza de Palmares era su gente y lo que sabía hacer; tenía cuarenta herrerías en 1694.

**Ayutthaya.** La ciudad isla del rey, sus elefantes y sus huéspedes *(frase propuesta)*.
1. **Arcilla:** igual, pero la vas a necesitar menos.
2. **Lo propio:** tus elefantes del rey reciben la madera, la piedra y lo que se junta del monte, y una parte es riqueza para el rey.
3. **Te pide:** dónde está cada elefante y qué barrio extranjero recibís.
4. **Ojo:** si entregan en otro depósito, el rey no cobra. Y un elefante solo, lejos, es una presa.
5. **Saber más:** el palo de sapán, los cueros y el estaño eran monopolio del almacén real.

---

## Consultas para el autor (a copiar en `proceso/CONSULTAS.md` cuando se apruebe)

1. **Vara del criterio E:** umbrales absolutos y "no más de 1,5 veces la mediana", en lugar de ×1,5 entre la que más y la que menos.
2. **Hito II a 500 a + 300 r.** Hay que confirmarlo con la IA real.
3. **Frases nuevas de Palmares y Ayutthaya.**
4. **Etiopía sin carpa en escaramuza.** La "corte que camina" pasa a ser "la corte que se funda en otro lugar".
5. **Aceptar que el ingreso de riqueza cae a la mitad al agotarse la arcilla**, y que el final se pelea en lo disputado.
