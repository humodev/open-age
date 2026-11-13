# Ronda 3 · Crítica 01 — El que intenta romperlo

Rol: *red team*. Leí la consigna ([`../00-consigna.md`](../00-consigna.md)), el diseño líder ([`../01-diseno-lider.md`](../01-diseno-lider.md)) y [`../parametros.json`](../parametros.json), y los contrasté con lo que ya existe en `data/civs/*.json`, `data/reglas.json`, `src/sim/sim.gd` y `src/sim/sim_mods.gd`. No toqué nada fuera de este archivo.

Cómo leerlo:
- **Gravedad.** *Crítico*: rompe la partida o invalida el modelo, y hay que arreglarlo antes de implementar. *Alto*: una estrategia dominante o una civ sin salida en un caso común. *Medio*: abuso posible con contrajuego, o hueco de especificación que se va a convertir en bug. *Bajo*: pulido.
- Cada punto tiene **escenario**, **por qué rompe**, **arreglo** (con números) y **cómo se verifica**.
- Cuando el problema ya existe en el código y el diseño lo hereda, lo marco **[ya existe]**, con archivo y línea.
- Las cuentas son a mano y con los números de `parametros.json`. Donde dependen de algo que no medí, lo digo.

---

## 0. Resumen por gravedad

| # | Gravedad | Problema | Civ |
|---|---|---|---|
| C1 | Crítico | Siguen vivas siete rentas fijas de hitos (hasta 95 r/min en Ayutthaya), fuera del modelo y sin tope | Todas menos Tawantinsuyu |
| C2 | Crítico | Faenar y volver a criar es una fábrica de comida sin aldeanos: 53 a/min por corral | Mapuches |
| C3 | Crítico | La liberación da 2 aldeanos por **cualquier** edificio enemigo, incluso un tramo de camino o de cerca, y pasa el tope de población **[ya existe]** | Palmares |
| C4 | Crítico | La curva común de aldeanos no vale para Palmares (no entrena) ni para mapuches (varios lof): el premodelo mide otra partida | Palmares, mapuches |
| A1 | Alto | Corte de asedio: la kätäma se despliega al instante, con flechas, junto al barreal del rival y se lo come | Etiopía |
| A2 | Alto | Varias kätäma (el centro se puede construir desde la edad II): extracción y +33 % multiplicados | Etiopía |
| A3 | Alto | Con el barreal agotado, después del minuto 40 el ingreso de riqueza pacífico va de 119 a 255 r/min (×2,1) | Todas |
| A4 | Alto | Ayutthaya en altiplano, valle o mesetas: el bosque se termina y el motor cae a cero; la tabla de terreno mira el minuto 20 | Ayutthaya |
| A5 | Alto | Ingenios neutrales que reaparecen cada 240 s: un ejército del final los cosecha como renta | Palmares y mapuches sobre todo |
| A6 | Alto | El "techo de lo disputado" como % de la riqueza no está definido; tal como está, castiga al que perdió su base | Común |
| A7 | Alto | Gult de regimiento: −30 % al jinete desde la edad I, con riqueza gratis de la corte | Etiopía |
| A8 | Alto | La mudanza obligatoria de la corte en el final es una ventana pública que decide la partida | Etiopía |
| M1 | Medio | El saqueo cobra igual sobre cercas de 2 de madera y caminos: 60 r/min (2 AE) sitiando una cerca **[ya existe en parte]** | Mapuches |
| M2 | Medio | Cadena guaraní madera → comida → riqueza → madera (capuera) sin cantidad definida; la capuera también rehace el bono de monte | Guaraníes |
| M3 | Medio | Yerbal cosechable por cualquiera: en equipos, los aliados se lo comen (las bayas escocesas de AoE4) | Guaraníes |
| M4 | Medio | Mercado: con piso 60 es un convertidor infinito de comida a riqueza; en el final premia al que tiene comida barata | Común; Tawantinsuyu en ladera |
| M5 | Medio | Lo disputado no escala con la cantidad de jugadores, y los rendimientos decrecientes por dueño se esquivan repartiendo entre aliados | Común (equipos) |
| M6 | Medio | Corral a cero cabezas, cabezas por encima del tope y faenar en pánico: reglas que faltan | Mapuches |
| M7 | Medio | La corte no encuentra "lugar parejo" en selva y mesetas: Etiopía queda con la capital empacada | Etiopía |
| M8 | Medio | Guaraníes sin motor hasta el minuto 13 a 15: el rush temprano no los frena, los congela | Guaraníes |
| M9 | Medio | Tawantinsuyu en espiral: una batalla perdida baja la mit'a y apaga todos los talleres a la vez | Tawantinsuyu |
| M10 | Medio | El subproducto del almacén real tiene que distinguir caza y arbustos de granja y arrozal; si no, el arrozal junto al agua es renta infinita | Ayutthaya |
| M11 | Medio | Información que el rival no ve y no puede contrarrestar | Todas |
| B1 | Bajo | La vecindad R3 a 8 casillas se esquiva sin costo: dispersa, no castiga | Todas |
| B2 | Bajo | Oficios que suman flechas al mocambo; la semilla de Ayutthaya vale más que las otras; la bandera de roza en territorio rival | Varias |

---

## 1. Críticos

### C1. Siete rentas de hito siguen vivas, sin tope y fuera del modelo

**Escenario.** El diseño convierte la renta de 40 del aqllawasi en tecnología de motor, pero no menciona las demás. En `data/civs/*.json` siguen estas rentas, que corren cada segundo en `sim_mods.gd:_rents`, sin tope y sin aldeanos:

| Civ | Hito (edad a la que lleva) | Renta |
|---|---|---|
| Ayutthaya | Puerto real (III) | **55 riqueza** |
| Ayutthaya | Junco de tributo (IV) | **40 riqueza** |
| Mapuches | Rewe del lonko (II) | 20 kulliñ → **20 riqueza** con la fusión |
| Mapuches | Parlamento (IV) | 40 riqueza + 20 kulliñ → **60 riqueza** con la fusión |
| Palmares | Pacto de Cucaú (IV) | 40 riqueza |
| Palmares | Macaco (II) | 40 fama = **1,4 personas gratis por minuto** |
| Palmares | Guerra de Zumbi (IV) | 30 fama |
| Guaraníes | Pueblo de misión (III) | 25 riqueza |
| Etiopía | Monasterio (II) | 20 riqueza |
| Tawantinsuyu | Ushnu (II) | 20 mit'a (≈ 16 riqueza vía taller) |

**Por qué rompe.**
- Puerto real + junco dan 95 r/min: **3,2 AE en dos edificios** que no se pueden destruir sin voltear un hito de 3000 pv. La regla común es 0,8 AE por pieza.
- La fusión kulliñ → riqueza convierte en riqueza dos rentas que hoy están en un recurso con tope (kulliñ, tope 120). El parlamento pasa a 60 r/min, más que un corral lleno.
- El monasterio da 20 r/min desde el minuto 8: le gana al gult (19 r/min cerca de la corte, 100 m + 40 a) sin costo y sin tope.
- El premodelo no las cuenta. Las curvas de §7.3 y la autoevaluación (criterio 3) están medidas sin ellas.
- La consigna prohíbe "pasivos sin tope" (F).

**Arreglo.**
1. Aplicar a todos los hitos la misma regla que al aqllawasi: **ningún hito tiene renta de riqueza**. La renta se cambia por un efecto sobre el motor propio, con el mismo tope:
   - puerto real: +1 almacén real al máximo por edad, o +8 de tope por almacén;
   - junco de tributo: el subproducto pasa de 25 a 30 %;
   - lonko: cría 45 → 36 s;
   - parlamento: +1 corral al máximo de la edad IV;
   - pacto de Cucaú: +2 puestos de oficio;
   - misión: +1 yerbal activo;
   - monasterio: gult a 16 casillas de la corte en vez de 14.
2. Si se quiere conservar alguna renta por sabor, que sea **≤ 12 r/min** (0,4 AE) y que cuente como una pieza del máximo por edad.
3. Las rentas de fama de Palmares tienen que entrar en el modelo como aldeanos (ver C4). Macaco a 40 de fama equivale a encolar aldeanos gratis desde la edad II.
4. Agregar al modelo una columna "rentas de hito" para cada civ y cada par de hitos.

**Cómo se verifica.** Un `grep '"renta"' data/civs/*.json` después del cambio tiene que mostrar solo el gult (y los barrios, si no se quitan). En el torneo, el informe de riqueza por origen separa "hito".

### C2. Faenar y volver a criar: comida sin aldeanos

**Escenario.** Corral lleno con 5 cabezas. Faenar da 4 × 40 = 160 de alimento y deja 1 cabeza. Con una cabeza cada 45 s, vuelve a 5 en 180 s. Se faena otra vez.

**Cuenta.**
- Comida: 160 cada 180 s = **53 a/min por corral**. En pradera: 5 × 40 = 200 cada 225 s, también 53 a/min.
- Lo que se pierde: mientras se cría, el corral tiene en promedio 2,5 cabezas en vez de 5, o sea, 10 r/min de los 20.
- Cinco corrales en la edad IV: **267 a/min**, es decir, 7,4 granjeros (36 a/min cada uno) sin población, a cambio de 50 r/min. Con el mercado en el piso (42 r por 100 de comida), esos 267 a/min valen 112 r/min: **faenar en bucle le gana a no faenar, incluso para hacer riqueza**.
- En la edad I: dos corrales faenados a las 4:30 y a las 7:30 dan 320 de comida. El hito II pide 400. Eso pone la edad II **antes de las 6:30**, fuera de la banda del criterio 4.
- Esfuerzo: una orden por corral cada 3 minutos. Con 5 corrales, 1,7 órdenes por minuto, el triple de la OPA de cualquier civ. El jugador de alto nivel lo hace igual; el que no, queda atrás. Es justo el "ritual" que el diseño quiso evitar al pasar de cabeza a corral entero.
- Es el mismo camino que el ganado malí de AoE4: *"so cost efficient that players would completely ignore farms"* (catálogo, §10).

**Arreglo** (en orden de preferencia):
1. **Faenar deja el corral en 1 cabeza y sin cría durante 90 s.** Además, alimento por cabeza 40 → **25**. Resultado: 100 de comida cada 270 s = 22 a/min por corral, menos que un granjero, a cambio de unos 12 r/min. Faenar vuelve a ser "comerse el capital" para cerrar un hito o aguantar un cerco, no un bucle.
2. Alternativa más simple: faenar **destruye el corral** (da 40 por cabeza y devuelve 0 de madera). Rehacerlo cuesta 120 m y 4 minutos de cría desde 1 cabeza. El costo real (120 m) hace que solo valga en emergencia.
3. En cualquier caso, mostrar el tiempo de recría en el corral.

**Cómo se verifica.** En el modelo: una estrategia "faenar cada vez que llega a 5" contra "no faenar nunca", con comida pasada a riqueza por mercado. La primera no puede ganar en riqueza + comida × 0,42.

### C3. Liberación: dos aldeanos por un tramo de camino [ya existe]

**Escenario.** `sim_mods.gd:278-282` (`on_kill`): si Palmares destruye **cualquier** edificio construido de otro jugador, aparecen `aldeanos: 2` junto al edificio. No mira tamaño, costo ni tipo. `spawn_near` no mira el tope de población (el tope solo se mira al encolar, `sim.gd:1068`, y en la acogida, `sim_mods.gd:91`).

**Cuenta.**
- Un camino inca es un edificio de 1×1, con 200 pv y costo de 2 de mit'a. Una tropa palmarista que camina por el Qhapaq Ñan y voltea 20 casillas gana **40 aldeanos**. El inca pierde 40 de mit'a.
- Lo mismo con cada tramo de cerca (2 de madera), cada roza guaraní (45 m), cada corral.
- En el final, con 200 de población, cada tramo da 2 personas **por encima del tope**. Ejemplo: 230 de población.
- El diseño suma "2 personas liberadas" en los ingenios neutrales, encima de esto.

**Arreglo.**
1. La liberación solo sale de edificios **habitados**: centro, casa, mocambo, lof, ingenio o estancia neutral y cuartel. Se marca con `habitado: true` en los datos. Nada de caminos, cercas, granjas, corrales, gult ni talleres.
2. Por encima del tope de población, cada persona liberada se convierte en **28 de fama** (el costo de una acogida). Si la fama está en el tope, se pierde.
3. Como máximo 1 liberación por edificio enemigo cada 60 s por jugador. Así no se puede limpiar un barrio de casas en 10 s y sacar 20 aldeanos.

**Cómo se verifica.** Una prueba de sim: Palmares destruye 10 caminos y 10 cercas → 0 aldeanos. Destruye 1 casa con población al tope → +56 de fama, 0 unidades.

### C4. El premodelo usa una curva de aldeanos que dos civs no pueden seguir

**Escenario.** `premodelo_grueso` usa la misma curva para todas (6 → 19 → 30 → 40…). Pero:
- **Palmares no entrena aldeanos**: su centro solo produce exploradores. La gente llega por fama. Con 60 iniciales, 24 por minuto del centro, un mocambo a las 3:00 (15 por minuto) y unas casas (2 cada una), a los 5 minutos hay unos 210 de fama = 7 personas más: **unos 13 aldeanos, no 19**. A los 10, con el macaco (40 de fama), unos 25, no 30.
- **Los mapuches tienen varios lof**: cada lof (110 de madera) produce aldeanos. Con dos o tres lof producen al doble o al triple que una civ con un centro. Se pueden adelantar a la curva todo lo que quieran mientras haya comida.

**Por qué rompe.** El criterio 3 (curvas dentro de ±15 %) está medido sobre una partida que esas dos civs no juegan. La alerta "Palmares −9 % a los 5" puede ser un −25 %. Y el oficio, que saca gente del barreal, es más caro para Palmares de lo que parece. Los mapuches pueden estar por encima.

**Arreglo.**
1. El modelo numérico tiene que simular **la llegada de gente de Palmares** a partir de la fama (fuentes, acogida a 28, tope de población) y **la producción de aldeanos de los mapuches** con N lof (con el costo en madera de cada lof).
2. Si Palmares queda corto a los 5 minutos, la palanca no es solo la semilla de fama. El costo del aldeano de las demás civs (50 de comida) es comida que Palmares no gasta: hay que medir **economía total**, no solo riqueza.
3. Para los mapuches: un máximo de lof que producen aldeanos a la vez, de 2 en la edad I, o +50 % de tiempo de entrenamiento en los lof que no son el primero.

**Cómo se verifica.** El torneo ya existente (`tests/torneo.gd`) da la cantidad de aldeanos por minuto de cada civ. Se compara con la curva antes de usarla.

---

## 2. Altos

### A1. Corte de asedio: la kätäma junto al barreal del rival

**Escenario.** El barreal de la base del rival está a unas 10 casillas de su centro. La capa 1 etíope dice "kätäma desplegada a ≤ 8 casillas de **un** barreal": no dice de quién. Hoy:
- `_cmd_unpack` (`sim.gd:417`) arma el centro **construido al instante** (`spawn_building(..., true)`) en cualquier lugar parejo;
- el centro tiene 2 flechas, alcance 7000 y guarnición 15 (`data/edificios.json`);
- empacar conserva la vida en proporción, así que no hay curación en bucle, pero tampoco hay demora.

Etiopía lleva la carpa (2000 pv) del otro lado del barreal del rival, a 16 casillas de su centro, fuera del alcance de sus flechas, y la despliega. La corte le saca **12 r/min del barreal del rival**, dispara a sus aldeanos y tiene al lado sus jinetes y sus gult de regimiento. Es la *forward TC* de AoE4 con un plus: drena el recurso del otro.

**Por qué rompe.**
- El rival pierde su barreal de base a 12 r/min más rápido, justo en la fase en que todavía no tiene motor (minutos 6 a 12).
- Desplegar al instante también sirve como "fortaleza de bolsillo" en una pelea: una torre con 2400 pv que aparece en 1 segundo.

**Arreglo.**
1. **Extrae solo de barreales propios** (los dos de la base y el de flanco) y de los del centro. Los barreales de la base y del flanco del rival quedan marcados como suyos desde el generador.
2. **Desplegar tarda 30 s**: el centro aparece sin terminar, con 25 % de vida, y se construye solo. La extracción empieza cuando termina.
3. **No se puede desplegar a menos de 20 casillas de un edificio enemigo**, igual que no se puede construir encima de la base del rival.
4. Después de empacar, 60 s sin poder desplegar.

**Cómo se verifica.** Partida guionada: Etiopía empaca a las 5:00 y busca desplegar junto al barreal del rival → rechazado. En el torneo, ningún barreal del rival baja por la corte.

### A2. Varias cortes

**Escenario.** El centro común es construible desde la edad II (`edificios.json`, `edad_min: 2`) y Etiopía tiene `centro` en `construye`. Su centro es la kätäma, con `empaca_en`, así que **todo centro etíope es una corte**. El diseño dice "una fuente a la vez", pero por corte.

**Cuenta.** Dos cortes en la edad II: 24 r/min de extracción y dos radios de 14 casillas con +33 % para los gult. Con tres en la edad III, todos los gult están siempre cerca, y los barreales del centro y del flanco se vacían solos. Si los +33 % de dos cortes se suman, el gult cercano a las dos pasa de 19 a 23 r/min.

**Arreglo.**
- Solo la corte con `capital` (la que empezó la partida o la que la heredó) extrae y da el +33 %. Las otras son centros comunes: producen y reciben, no extraen.
- El +33 % **no se suma**: un gult cuenta una sola corte.
- Si se quiere una segunda corte con identidad, que sea la tecnología de la edad IV (Gondar): asienta la capital y permite una segunda corte que extrae a 6 r/min.

### A3. Después del minuto 40, con todo el barreal agotado

El diseño dice que el barreal se termina entre los minutos 22 y 28, y que desde ahí la riqueza sale del motor, del flanco y de lo disputado. El flanco también se termina: 1500 a 3 o 4 aldeanos dura unos 15 minutos. Los barreales del centro (4000 en total) se van antes del 35. A los 40 minutos queda **solo el motor, las rentas de hito y lo que se pelea**. Ingreso de riqueza pacífico sostenible en la edad IV, con la tecnología de motor y sin lo disputado:

| Civ | Motor | Rentas de hito hoy (C1) | Total | Comentario |
|---|---|---|---|---|
| Tawantinsuyu | 5 talleres × 24 × 1,25 = **150** | ushnu ≈ 16 | 150–166 | Necesita 150 de mit'a por minuto: ≥ 38 runa vivos |
| Mapuches | 5 corrales × 6–7 cabezas × 4 = **120–140** | lonko 20 + parlamento 60 | 120–220 | Más malón ≤ 60 |
| Guaraníes | 5 yerbales activos × 40 = **200** | misión 25 | 200–225 | Pide ~12 aldeanos en rozas y yerbales, pero esos mismos aldeanos dan 400 a/min |
| Etiopía | 5 gult × 19 × 1,25 = **119**; corte 0 (no queda barreal) | monasterio 20 | 119–139 | El gult también da 31 a/min |
| Palmares | 9 puestos × 15 × 1,25 = **169** | Cucaú 40 | 169–209 | Ocupa solo 9 de población. No se agota ni se raidea |
| Ayutthaya | 4 almacenes × 24 × 1,25 = 120, +40 con dos barrios chinos = **120–160** | puerto 55 + junco 40 | 120–255 | Mientras quede bosque (A4) |

**Por qué rompe.**
- Entre Etiopía (119) y Ayutthaya con rentas (255) hay ×2,1. Aun sin rentas de hito, entre Etiopía y los guaraníes hay ×1,7.
- La riqueza es lo que paga lo caro del final: elefante, 160 r; compañía japonesa, 95; jinete, 35 por unidad. Con 119 r/min, Etiopía saca un jinete cada 18 s y no mucho más.
- La alerta del premodelo (guaraníes +18 % y Etiopía −14 % a los 30) es el comienzo de esta divergencia, no el pico.
- En una partida de 50 minutos de AoE, la civ con la economía de oro infinita gana el *trash war*. Acá todas tienen "oro infinito", pero a ritmos muy distintos.

**Arreglo.**
1. Igualar el **techo del motor en la edad IV**, no solo el rendimiento por pieza. Objetivo: 150 r/min ± 10 % para las seis, con la tecnología incluida. Valores:
   - gult: 19 → 22 cerca de la corte, o tope de la edad IV en 6;
   - yerbales activos en la edad IV: 5 → 4 (160 r/min), como ya propone el diseño;
   - oficios en la edad IV: 9 → 8 (150 r/min);
   - talleres y almacenes ya están en 150 y 120–160.
2. Agregar al modelo el **minuto 45** como punto de control, con todo el barreal agotado.
3. Dar a todas las civs una salida común al final que no sea el mercado: **el barreal de flanco se regenera** a 8 r/min (sin aldeanos no rinde nada), como una veta lenta. Así nadie queda a cero, y la diferencia entre motores sigue importando.

### A4. Ayutthaya sin bosque

**Escenario.** Altiplano (3 bosques, `arboles: [4]`), valle (6 bosques) y mesetas (8). El almacén real cobra el 25 % de la madera, la caza y los arbustos que se entregan ahí. La tabla de terreno pone −6 % en el altiplano **al minuto 20**. Pero la madera, la caza y los arbustos del mapa se terminan. En el altiplano, a los 30 o 35 minutos, no queda bosque cerca.

**Por qué rompe.** El motor de Ayutthaya es el único que depende de un recurso agotable del mapa que además se pelea (los bosques). Con el bosque terminado, el almacén real rinde cero, y el plan B (caza y arbustos) también se agota antes. Ayutthaya queda en el final de A3 con 0 a 95 r/min (95 solo si sigue la renta de hitos de C1). Es la única civ que puede quedar sin motor por el mapa. Es "un recurso que decide la partida por un lugar", que la consigna prohíbe.

**Arreglo.**
1. El subproducto también se aplica, al **10 %**, a la comida de **granjas y arrozales** entregada en el almacén. Con el tope de 24 por almacén, eso da un piso: 240 a/min en arrozales = 24 r/min.
2. O bien: el almacén real tiene un **piso de 8 r/min** (el "tributo" del rey) aunque no reciba nada, y el tope sigue en 24.
3. Medir en el modelo la madera total que el generador pone en altiplano, valle y mesetas, y en qué minuto se agota con 8 a 12 leñadores.

### A5. Los ingenios neutrales como renta del final

**Escenario.** 2 pares (4 ingenios), botín 150 una vez, reconstrucción a los 240 s, guardia 4 que sube 2 en cada reconstrucción. En el final, con el mapa revelado, un ejército de la edad IV pasa por los 4 cada 4 minutos.

**Cuenta.**
- Una civ cualquiera: 600 cada 240 s = **150 r/min**, igual que un motor entero.
- Palmares: ×1,5 = 225 r/min, **más 8 personas cada 4 minutos**.
- Mapuches: 225 r/min más 4 cabezas.
- La guardia, después de 8 reconstrucciones, es de 20. Si son unidades de la edad I, un ejército del final no las siente.
- Acampar sobre el lugar de reconstrucción y matar a la guardia cuando aparece es "spawn camping".
- En la edad I, un Palmares que toma un ingenio a los 5 minutos suma 225 r (más que toda su riqueza acumulada, unos 400) y 2 personas.

**Arreglo.**
1. **El botín baja para el mismo jugador**: 150, después 100, después 50 por ingenio y por edad. Se reinicia al subir de edad.
2. **Reconstrucción a 360 s**, y no reaparece si hay unidades enemigas de la guardia a menos de 12 casillas.
3. **La guardia escala con la edad del jugador que más avanzó**: en la edad III, unidades de la edad III.
4. El botín cuenta para el techo de lo disputado (A6).
5. Edad mínima 2, no 1. En la edad I, un botín de 150 a los 5 minutos es más que la semilla de cualquier civ.

### A6. El techo de lo disputado no está definido

**Escenario.** `techo_pct_riqueza_por_edad: 10 / 25 / 40 / 50`. ¿Porcentaje de qué?

- **Si es un porcentaje del ingreso de riqueza propio**, el techo castiga al que perdió su base: Ayutthaya sin bosque, o Etiopía después de una mudanza fallida, tiene un ingreso propio bajo y, por eso, un techo bajo justo cuando necesita lo disputado para remontar. Con ingreso propio cero, el techo es cero: **una civ sin salida**.
- **Si es un porcentaje de la riqueza total**, el ratio se calcula sobre una ventana. Un botín de 150 junto llega todo en un tick y siempre pasa el techo instantáneo.
- En los dos casos, el jugador no ve el techo, así que manda el ejército a un sitio que ya no le rinde.

**Arreglo.**
1. Techo **absoluto**, por jugador y por edad: **15 / 40 / 70 / 90 r/min** de lo disputado, en una ventana móvil de 5 minutos. Lo que pasa del techo se pierde y se avisa.
2. Una barra en la interfaz: "Lo disputado: 52 / 70 por minuto".
3. Las cifras salen del 10/25/40/50 % aplicado al ingreso medio del premodelo en cada edad. Por eso se pueden comparar.

### A7. Gult de regimiento: descuento fuerte, temprano y permanente

**Escenario.** El regimiento abarata los jinetes 15 % por gult, con tope de −30 %. El "guerrero" etíope es un **jinete noble desde la edad I** (70 a + 35 r). La corte da 12 r/min gratis desde el minuto 0.

**Cuenta.**
- Dos gult de regimiento (200 m + 80 a) a los 4:00: el jinete pasa a 49 a + 24 r. Con la riqueza de la corte, eso es un rush de caballería en la edad I más barato que el de cualquier otra civ.
- En el final, si Etiopía gasta 300 r/min en jinetes, el −30 % le ahorra **90 r/min**, más que 4 gult de señor (76 r/min). Y no se puede raidear: el descuento sigue mientras el gult esté en pie.

**Arreglo.**
1. **−10 % por gult de regimiento, tope −20 %**.
2. El regimiento está disponible desde la edad II.
3. El descuento rige solo para los jinetes que salen de un edificio a ≤ 14 casillas de un gult de regimiento. Así el gult de regimiento también tiene ubicación y se puede raidear.
4. Señor o regimiento se elige al construir y no se cambia (el diseño lo dice "al ponerlo"; dejarlo explícito en los datos).

### A8. La mudanza de la corte en el final

**Escenario.** La capa 1 de Etiopía obliga a mudarse cada 5 a 8 minutos (el barreal de la corte se acaba). En el final, con el mapa revelado, la carpa (2000 pv, velocidad 650, la más lenta del juego) cruza el mapa a la vista de todos. Mientras se muda:
- no hay centro que produzca aldeanos;
- los gult pierden el +33 %;
- la capital es una unidad.

Un grupo de 8 jinetes o un elefante la alcanza. Lo que el diseño quiso evitar ("una incursión a la carpa decide la partida") vuelve por el lado de la capital, no del gult.

**Arreglo.**
1. **La corte extrae a 12 casillas en la edad III y a 16 en la IV**: puede quedarse más tiempo en el mismo lugar y alcanzar dos barreales.
2. **Mudanza sin ventana**: se coloca el cimiento de la nueva corte (gratis, 60 s), y la vieja se desarma sola cuando la nueva termina. Mientras tanto hay una sola corte activa (la vieja).
3. Gondar (edad IV) fija la capital y la extracción pasa a 8 r/min de **cualquier** barreal a ≤ 16 casillas, sin necesidad de mudarse.

---

## 3. Medios

### M1. Saqueo sobre cercas y caminos [ya existe en parte]

**Escenario.** `sim_mods.gd:267`: el saqueo cobra el % del daño a **cualquier** edificio de otro jugador, sin mirar el tipo. Con el diseño, 10 % del daño en riqueza y tope de 60 r/min.

- El rival levanta una cerca (2 de madera por tramo). Un grupo mapuche la golpea y la reparan sin parar. Los mapuches cobran **60 r/min = 2 AE**, más que el máximo de cualquier pieza, mientras el rival casi no pierde nada.
- Con el Tawantinsuyu: golpear caminos (200 pv, 2 de mit'a).

**Arreglo.**
1. Tope 60 → **30 r/min**.
2. El saqueo solo cuenta el daño a edificios con costo ≥ 75 o `habitado` (la misma marca de C3). No cuenta cercas, puertas, caminos ni granjas.
3. El saqueo de un edificio no supera el 10 % de su costo total por cada vez que se destruye. Repararlo no vuelve a habilitar el cobro.
4. La fase 2 (arreo) está bien: el botín se puede interceptar.

### M2. La cadena guaraní y la capuera

**Escenario.**
- Madera (45) → roza (750 a) → yerbal (300 o 375 r) → por encima del tope de yerbales, **capuera** = árboles jóvenes → madera → roza…
- `parametros.json` no dice cuánta madera tiene la capuera. Si son más de 45, cada roza por encima del tope se paga sola: la cadena es comida infinita y gratis en cualquier mapa, sin bosque.
- La capuera son **árboles**. El bono de monte de la roza (≥ 4 árboles a ≤ 2 casillas) se vuelve a cumplir con la capuera. Es decir, los guaraníes **fabrican su propio terreno favorable** también en el altiplano. La tabla de terreno (−5 %) no lo cuenta.

**Arreglo.**
1. Capuera: **4 árboles de 10 de madera** (40 en total), que **no cuentan** para el bono de monte ni para la pradera mapuche ni para el bono de monte del mocambo. Se ven distintos (arbustos, no árboles).
2. Alternativa: la capuera no da madera, solo bloquea la casilla durante 5 minutos (la sucesión).

### M3. Yerbal cosechable por cualquiera

**Escenario.** El diseño dice: "Mandar aldeanos a cosechar un yerbal ajeno: es un recurso, cualquiera puede". Hoy no hay equipos en `sim.gd` (todo jugador distinto es enemigo). Cuando haya equipos, los aliados del guaraní le van a vaciar los yerbales. En AoE4 ya pasó con las bayas de los escoceses: *"los aliados le comen las bayas al escocés"* (catálogo, §escoceses).

**Arreglo.** El yerbal es del dueño de la roza: solo él y sus **enemigos** pueden cosecharlo, nunca los aliados. El enemigo cosecha a su propia tasa de riqueza (700), no a 800.

### M4. El mercado como convertidor del final

**Escenario.** `reglas.json → mercado`: el jugador **vende** comida, madera o piedra por riqueza. Con el piso propuesto de 60 y comisión de 30 %, cada 100 de comida da al menos 42 de riqueza, para siempre. Los precios son por jugador (`p["precios"]`). Después del minuto 40 (A3), las civs con comida barata convierten:
- Tawantinsuyu con andenes en ladera (+60 %): 58 a/min por aldeano → **24 r/min por aldeano**, casi un aldeano en el barreal (30), y sin agotarse. En montaña, valle y sierra, el inca tiene un barreal infinito. La tabla de terreno (+5 %) mide el minuto 20, antes de que importe.
- Mapuches con faenar en bucle (C2).
- Guaraníes con rozas.

**Arreglo.**
1. **Piso 60 → 40** para vender (28 r por 100 de comida después de la comisión). El mercado sigue siendo válvula, no motor.
2. El precio vuelve **hacia 100** a razón de 1 punto cada 10 s. Así la válvula es para usos puntuales, y quien vende sin parar se queda en el piso.
3. En el modelo: un jugador que, desde el minuto 30, pone todos los aldeanos sobrantes a vender comida. Ninguna civ puede sacar del mercado más del 30 % de su riqueza en la edad IV.

### M5. Partidas por equipos: lo disputado no escala

**Escenario.** El diseño fija "2 pares" de barreales del centro e ingenios y 3 sitios (`reglas.json → sitios.cantidad: 3`).
- En un 1 contra 1, los 4000 de barreal del centro son 2000 por cabeza. En un 4 contra 4, 500. El techo por edad nunca se alcanza en equipos y siempre en 1 contra 1. El mismo diseño juega dos juegos distintos.
- Los sitios rinden 18 / 12 / 8 **por dueño**. En equipo, cada aliado toma uno: los tres rinden 18. El rendimiento decreciente se esquiva sin costo.
- El techo de lo disputado, por jugador, se esquiva igual: el aliado que no lo usa toma lo disputado.

**Arreglo.**
1. Barreales del centro: **1 por jugador**, en pares simétricos. Ingenios: **1 por jugador**. Sitios: **jugadores + 1**.
2. Rendimiento decreciente de los sitios **por equipo**, no por dueño.
3. Techo de lo disputado **por equipo** = techo por jugador × jugadores del equipo, repartido entre todos.
4. Cuando se programen los equipos, revisar todo lo que hoy usa `t.owner != pid` como "enemigo": saqueo, liberación, la extracción de la corte (A1), cosechar yerbales (M3), dejar recursos en el almacén de un aliado (hoy `nearest_dropoff` exige el mismo dueño, `sim.gd:1369`: que siga así).

### M6. Corral: reglas que faltan

**Escenario.** "Cada 20 % de vida perdida mata 1 cabeza." No está dicho:
- **¿Qué pasa con 0 cabezas?** Si la cría necesita una cabeza para empezar, dos exploradores a los 3:00 dejan el corral en 0 y muerto para siempre (hay que rehacerlo, 120 m). Es el rush que "impide arrancar el motor".
- **¿Reparar devuelve cabezas?** Si sí, reparar es criar al instante.
- **Botín y arreo**: "1 cabeza al corral más cercano". Si el corral ya está en el tope, ¿se pasa?
- **Faenar en pánico**: el rival ataca y el mapuche faena antes de que se pierda la primera cabeza. El atacante no saca nada y el mapuche recupera 160 de comida. Con C2 arreglado (25 por cabeza y 90 s sin cría) es aceptable.

**Arreglo.**
1. Un corral en pie **nunca baja de 1 cabeza** y cría desde 1.
2. Reparar devuelve vida, no cabezas.
3. Las cabezas por botín o arreo **no pasan el tope**. Si no hay lugar, se convierten en 40 de alimento.
4. Faenar no se puede usar mientras el corral está en combate (5 s desde el último golpe), igual que no se encola en un edificio bajo ataque en algunos RTS.

### M7. Etiopía sin lugar para desplegar

**Escenario.** `_cmd_unpack` exige lugar parejo para el centro (4×4) y, si no hay, avisa "No hay lugar parejo para armar la corte" y no hace nada. En la selva (32 bosques), en la sierra (20) y en las mesetas (paredes a pique, `umbrales` de 55 a 61), el barreal de flanco puede no tener 4×4 parejo a ≤ 8 casillas. Etiopía llega con la carpa y no puede desplegar: no tiene centro, ni producción de aldeanos, ni capa 1. La tabla de terreno pone Etiopía +4 en mesetas.

**Arreglo.**
1. El generador garantiza un **claro parejo de 6×6 a ≤ 8 casillas de cada barreal** (base, flanco y centro) para todas las civs, no solo para Etiopía. También sirve para que el inca ponga el taller y el mapuche el corral.
2. Si no hay lugar, la carpa despliega en el lugar parejo más cercano a ≤ 12 casillas, y el radio de extracción se estira hasta ahí.

### M8. Guaraníes: trece minutos sin motor

**Escenario.** El primer yerbal aparece cuando se agota la primera roza: 750 de comida a unos 60 a/min, abierta a las 2:30, se agota hacia el minuto 15 (el diseño dice 13). Hasta entonces, la capa 2 no rinde riqueza. Las rozas, junto al monte para el +15 %, están lejos y expuestas, y son edificios. Un rush a las 5:00 que quema dos rozas no solo cuesta 90 m: **atrasa 12 minutos la llegada de los yerbales**. Sin torres de piedra (`sin_edificios: torre`), la defensa temprana guaraní es solo militar.

Las otras civs, en el mismo rush, pierden una pieza de motor que ya rendía. Los guaraníes pierden la pieza **y el reloj**.

**Arreglo.**
1. **El yerbal aparece a la mitad de la roza**: con 375 de alimento consumido, la roza deja de dar comida y se convierte en yerbal. Es decir, la roza tiene 375 de alimento y deja un yerbal de 300. El primer yerbal llega hacia el minuto 9.
2. Alternativa: la semilla (yerbal viejo de 250) pasa a 400, para cubrir el hueco.
3. Si una roza se quema con más del 50 % consumido, deja igual el yerbal.

### M9. Tawantinsuyu: la espiral de la mit'a

**Escenario.** La mit'a sale de cada runa vivo (4 por minuto). Los talleres consumen 30 por minuto y "solo corren si hay stock". Las levas (awqa) cuestan 30 de mit'a.
- Pierde 15 runa en una batalla: −60 de mit'a por minuto.
- Para defenderse, gasta la mit'a en levas.
- Los talleres se quedan sin stock y **se apagan todos a la vez**.
- Sin riqueza, no puede rehacer el ejército de verdad, y la leva vuelve a gastar la mit'a.

Las otras civs pierden aldeanos o piezas de motor de a una; el inca pierde todo el motor por la misma batalla en la que pierde la población.

**Arreglo.**
1. Los talleres tienen **prioridad sobre la leva** hasta un piso: la leva no puede bajar la mit'a por debajo de 30 × talleres prendidos (con un aviso).
2. O: el taller sin mit'a sigue a 1/3 del rendimiento (8 r/min), como tejido doméstico.
3. Hacer visible "mit'a: +80 / −60 por minuto" en la barra de recursos.

### M10. El subproducto de Ayutthaya y la comida de granja

**Escenario.** Hoy la comida entra como `alimento` sin importar si vino de una granja, un arrozal, una caza o un arbusto (`_do_return`, `sim.gd:889-903`). Si el subproducto se engancha en `_do_return` mirando el `carry_res`, el **arrozal junto al agua (+45 %)** entra al 25 %: 52 a/min por aldeano → 13 r/min por aldeano, sin agotarse, con tope 24 por almacén.

**Arreglo.** Si se quiere el piso de A4, que sea explícito y al 10 %. Si no, el aldeano guarda **el tipo de fuente** (`carry_src`), y el subproducto solo cuenta `madera`, `caza` y `arbustos`. Hay que escribir una prueba para eso.

### M11. Lo que la interfaz no deja ver

Cosas que hoy pasan sin que el jugador o el rival lo sepan, y que hacen imposible contrarrestar:

| Qué | Quién no lo ve | Qué mostrar |
|---|---|---|
| La 2.ª y 3.ª copia rinden 70 y 50 % (vecindad) | El dueño | Círculo de 8 casillas al ubicar y "rinde 70 %" en el tooltip |
| Techo de lo disputado alcanzado | El dueño | Barra (A6) |
| Si un gult es de señor o de regimiento | El rival | Bandera distinta sobre el gult |
| Cuántos trabajan en los oficios de un mocambo | El rival | Íconos de 0 a 3 personas sobre el mocambo |
| Si el taller está prendido | El rival | Humo o telar animado |
| La corte está comiendo un barreal | El rival y el dueño | Carretas o vasijas que van del barreal a la corte; el número del barreal baja |
| Cuánto le queda al barreal | Todos | Número al pasar el cursor, como el oro en Age |
| Tope de saqueo alcanzado | El mapuche | Aviso "el malón ya cargó todo lo que puede" |
| Cola de rozas prepagada | El rival | No hace falta: es interna |
| Rentas de hito (si quedan) | El rival | En el panel del rival, ingreso por minuto |

Sin el gult de regimiento visible, el rival no puede decidir si conviene cazar gult (si son de señor) o pelear la caballería. Sin los oficios visibles, no sabe si vale sitiar un mocambo.

---

## 4. Bajos

### B1. La vecindad R3 no castiga, solo dispersa

Con un radio de 8 casillas, cinco piezas en un anillo de 10 casillas de radio alrededor del centro, separadas 9 casillas, rinden todas al 100 %. La R3 no le quita rendimiento a nadie que sepa ubicar: solo las desparrama. Está bien como intención (más exposición), pero el diseño no debería contarla como un tope. Solo pesa para Etiopía, que necesita los gult a ≤ 14 casillas de la corte, y aun ahí entran 6 o 7 gult a 6 casillas de distancia entre sí.

**Arreglo.** Ninguno obligatorio. Si se quiere que muerda, radio 12. Pero hay que medir que el corral, el taller y el gult entren en la base.

### B2. Detalles

- **Oficios y flechas.** Si los del oficio cuentan como guarnición, el mocambo dispara más (`flechas: 1` más guarnición). Los del oficio no suman flechas ni vida.
- **Semilla de Ayutthaya.** El almacén real inicial vale 200 m y rinde desde el minuto 1 con los leñadores que todos tienen igual. Es la semilla más grande (el diseño habla de 100 a 150). Palanca: el almacén inicial empieza con tope 12 en la edad I.
- **Bandera de roza en territorio rival.** La cola abre rozas "junto a la bandera". Si la bandera se puede poner en cualquier lado, las rozas aparecen junto a la base del rival y sirven de bloqueo. La bandera tiene que estar a ≤ 12 casillas de un tapyi.
- **Prepago perdido.** Si se destruye el tapyi con rozas en cola, ¿se devuelve la madera? Que se devuelva.
- **El camino inca acelera a todos** (`sim_mods.gd:speed`: mira solo la casilla). Un camino al barreal del centro es una autopista para el ejército rival. Está bien como costo, pero el diseño no lo cuenta al recomendar conectar el centro.

---

## 5. Lecturas transversales que pidió la consigna

### 5.1 El final con el mapa revelado

Lo que **resiste**:
- Nada depende de estar oculto. El mocambo sin `oculto` está bien.
- Los talleres están en el corazón de la base y no dependen del camino.
- Los yerbales son recursos, no edificios: no se pueden quemar.
- Empacar y desplegar conserva la vida en proporción (`sim.gd:409` y `:430`): no hay curación en bucle.

Lo que **se rompe**:
- La corte que se muda (A8).
- Los ingenios como renta (A5).
- El almacén real sin bosque (A4).
- Las rentas de hito, que no se pueden raidear (C1).
- **La asimetría de lo que se puede raidear.** Los oficios de Palmares están adentro: no se los mata sin voltear un mocambo de 900 pv con estrepes. Los leñadores de Ayutthaya, los corrales mapuches y los gult lejanos sí se pueden raidear. Los talleres incas están en la base. Por raideabilidad, en el final, de más difícil a más fácil: Palmares > Tawantinsuyu > Etiopía (gult cercanos) > guaraníes > mapuches > Ayutthaya. No es un problema si se compensa con el techo de A3, pero hoy Palmares tiene el techo más alto (169) **y** el más seguro.

### 5.2 Barreal agotado y partidas largas

Ver A3. Resumen: el diseño tiene un piso para todas (el motor), pero los pisos están entre 119 y 255 r/min. Hay que igualarlos en la edad IV, medir el minuto 45 y bajar el mercado para que no sea el motor de nadie.

### 5.3 Mapas extremos

| Caso | Mapas | Quién sufre | Por qué | Arreglo |
|---|---|---|---|---|
| Sin agua | Mesetas (sin río ni lagunas); llano con río "ninguno" (2 de 3 formas) | Ayutthaya, poco | Arrozal sin +45 %. El puerto real y la fortaleza de río no piden agua: el bono es solo de comida | Nada. Medir mesetas: es la peor combinación para Ayutthaya (sin agua **y** poco bosque) |
| Sin ladera | Llano, río, delta | Tawantinsuyu, poco | El andén es una chacra; el taller rinde igual | Nada |
| Todo monte | Selva, bosque templado, sierra | Etiopía (M7), mapuches (sin pradera) | No hay lugar parejo para la corte; el corral sin pradera rinde 20 | M7. Para los mapuches, talar 3 casillas está bien, y además da madera |
| Todo llano | Llano, altiplano | Guaraníes y Palmares (sin monte) | La roza sin +15 % y el mocambo sin fama extra. La capuera arregla lo guaraní por accidente (M2) | M2 |
| Sin bosque | Altiplano, valle | **Ayutthaya** | El motor se agota (A4) | A4 |

La tabla de terreno del diseño mide el minuto 20. Los efectos que importan aparecen después del 30: el bosque que se acaba (Ayutthaya), la capuera (guaraníes) y el andén con mercado (Tawantinsuyu, M4). **Pido una segunda tabla al minuto 40.**

### 5.4 Uno contra uno frente a equipos

- Hoy no hay equipos en la simulación: `_cmd_target` trata como enemigo a todo dueño distinto (`sim.gd:221`). No hay tributo.
- En 1 contra 1, lo disputado pesa el cuádruple que en 4 contra 4 (M5).
- En equipos:
  - las civs de bolsillo con motor seguro (Palmares, Tawantinsuyu) pueden ir solo al motor;
  - las de flanco con motor raideable (Ayutthaya y sus leñadores, mapuches y sus corrales) reciben la presión;
  - dos mapuches en el mismo equipo sacan 120 r/min de malón del mismo rival (con el tope de M1, 60).
- Lista de cosas que hay que cerrar antes de programar equipos: M3, M5 y la revisión de `owner` en saqueo, liberación y extracción.

### 5.5 Rushes muy tempranos

| Civ | ¿Arranca el motor bajo un rush a los 4:00–6:00? | Riesgo |
|---|---|---|
| Etiopía | Sí: la corte extrae desde el minuto 0 y el rush no la toca | Ninguno. Es el que **hace** el rush (A7) |
| Tawantinsuyu | Sí: el taller 1 está en la base con 600 pv | Bajo; ver M9 si pierde muchos runa |
| Ayutthaya | Sí: el almacén inicial está construido. Los leñadores sufren | Medio |
| Palmares | Sí: puede meter gente en los oficios (4 puestos en la edad I) y es inmune al raid. Lo que pierde son aldeanos, que valen 28 de fama y tardan 1 minuto | Medio por la lentitud de la fama (C4) |
| Mapuches | Con el corral a 1 o 2 cabezas, dos exploradores lo dejan en 0 (M6) | **Alto** sin la regla de M6 |
| Guaraníes | Pierden las rozas y el reloj de 13 minutos (M8) | **Alto** sin M8 |

Por qué Etiopía es la que rushea: riqueza gratis desde el minuto 0, caballería en la edad I y descuento del regimiento. Con A7 queda dentro de lo razonable.

### 5.6 Civs sin salida

- **Ayutthaya en el altiplano, en el final**: sin bosque no hay motor (A4).
- **Cualquier civ con el techo de lo disputado en porcentaje** y el ingreso propio en cero (A6).
- **Etiopía sin lugar para desplegar** (M7), o con la carpa muerta en una mudanza del final (A8).
- **Tawantinsuyu tras una batalla grande** (M9).
- **Palmares sin edificios que acojan**: si cae la cerca real y todos los mocambos, no llega más gente (`_welcome` necesita `capital` o `acoge`). Ya existe. Es comparable a perder todos los centros en Age, así que lo dejo.

---

## 6. Lo que intenté romper y resistió

- **Talleres incas en bucle de conversión**: consumen mit'a a ritmo fijo, el tope de mit'a es 200, y el interruptor no genera nada extra. No hay forma de convertir más rápido que 30 → 24 por taller.
- **Mocambo sin `oculto`**: no queda ningún motor que dependa del secreto. Las emboscadas (`sigilo`) son militares y no tocan la economía.
- **Empacar y desplegar para curarse**: no se puede; la vida va en proporción.
- **Dejar recursos en el almacén de un aliado**: hoy no se puede (`nearest_dropoff` exige el mismo dueño).
- **Acogida por encima del tope de población**: hoy no se puede (`sim_mods.gd:91`). El problema es solo la liberación (C3).
- **El taller, el oficio y el gult como piezas con tope por edad**: el tope por edad funciona como en las cabañas rus y los yatai de AoE4, siempre que el máximo cuente también los cimientos sin terminar (dejarlo escrito).

---

## 7. Pedidos concretos al modelo numérico

1. Sumar las rentas de hito que existen hoy (C1), y después medir sin ellas.
2. Curva de aldeanos propia de Palmares (fama) y de los mapuches (N lof) (C4).
3. Estrategia "faenar en bucle" contra "no faenar", con mercado (C2).
4. Puntos de control a los 40 y 45 minutos con todo el barreal agotado; techo del motor en la edad IV por civ (A3).
5. Madera total del generador en altiplano, valle y mesetas, y minuto de agotamiento con 8 a 12 leñadores (A4).
6. Ingenios: renta por minuto si un ejército los recorre cada 240 s, con y sin el arreglo de A5.
7. Mercado: un jugador que vende comida desde el minuto 30, con piso 60 y con piso 40 y retorno a 100 (M4).
8. Tabla civ × terreno al minuto 40, no solo al 20.
