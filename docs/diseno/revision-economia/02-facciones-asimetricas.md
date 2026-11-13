# Revisión de economía · 02 — Identidad de facción y fuentes de riqueza

Basada en `data/civs/*.json`, `data/reglas.json`, `data/edades.json`, `src/sim/sim_mods.gd`, `investigacion/` y `proceso/07-balance-por-torneos/`. Números al 2026-11-13. Es una propuesta: no cambia nada todavía.

## Diagnóstico en una línea

En la edad I **todas las civilizaciones juegan con la misma riqueza**: la sacan del yacimiento neutral. Las fuentes propias aparecen tarde (rentas de hitos de edad II–III) o no producen riqueza. Por eso el autor ve "oro" en todos lados, y por eso la civilización cuya fuente propia está más desconectada, la mapuche, queda última.

## Problemas, del más grave al menos grave

### 1. El malón mapuche no da riqueza, y lo que da no se puede gastar (grave)

Lo que dicen los datos, aunque `03` diga "Riqueza: malón":
- `saqueo` da **kulliñ**, no riqueza: 16 % del daño a edificios y 6 por aldeano muerto.
- En la edad I el kulliñ **no tiene en qué gastarse**. Solo lo pide el kona montado, desde la edad II. El rewe no cuesta ganado: `costo_extra` no existe en ningún rewe.
- Tiene **tope de 120** (+60 por corral). Un weichafe que golpea un edificio rinde unos 35 kulliñ por minuto. Cinco weichafes llenan el tope en menos de un minuto, y el resto se pierde.
- Mientras tanto, el weichafe cuesta 20 de riqueza y el avance a la edad II, 200. Esa riqueza sale **solo** del yacimiento neutral.

El mapuche que ataca de entrada gasta riqueza neutral para ganar un recurso que no le sirve para avanzar ni para reponer tropa. El que no ataca juega un AoE genérico sin centro. Ninguna apertura aprovecha la civilización: de ahí el 1 o 2 de 10 en los torneos, casi siempre una edad atrás. La IA explica una parte, pero el problema está en los datos.

### 2. La identidad económica llega tarde en casi todas

| Civ | Fuente propia de riqueza | Desde cuándo rinde |
|---|---|---|
| Tawantinsuyu | Aqllawasi (renta 40) | Hito de edad III |
| Mapuches | Ninguna (el malón da kulliñ); parlamento | Edad IV |
| Guaraníes | Yerbal al agotar la roza | Minuto 4–6 aprox. |
| Etiopía | Gult (renta 18 + 14 de alimento) | Edad I, se paga en unos 6 min |
| Palmares | Ninguna: el saqueo da fama, el resgate no está | — |
| Ayutthaya | Barrios (renta 8); puerto real (55) | Edad II / III |

Cuatro de seis pasan los primeros 8 a 12 minutos minando el mismo yacimiento. El test de los cinco minutos (`01`) falla en lo económico: las aperturas se distinguen por las unidades, no por cómo se hace la plata.

### 3. Riqueza ilegible

Un contador, un yacimiento, un ícono de "oro". AoE4 también tiene un solo oro, pero con **fuentes visibles distintas**: la caza rus, el ganado mongol. El número es igual; la acción que lo produce, no. Acá la acción también es la misma.

## Principio de corrección: "tres patas" por civilización

Cada civ necesita, **desde la edad I**:
1. **Una vía de boom propia**, que rinda sin pelear.
2. **Una vía de presión que se pague sola**, que devuelva riqueza (o lo que haga falta para avanzar) cuando golpea.
3. **El yacimiento neutral como respaldo**, no como columna vertebral.

Ajustes transversales (datos y un parámetro de módulo):
- **Menos yacimiento neutral cerca de la base**: uno en vez de dos (`sim.gd`, `_res_sym`). La fuente propia pasa a ser la principal. El centro **no** gana yacimientos: ver "Dependencia territorial".
- **Sustitución en el costo de avance**: un parámetro de civ `hito_sustituye: {"riqueza": "kullin"}` con una proporción, para que una civ pague parte del hito con su recurso propio. Hoy `cost_of()` solo suma `costo_extra`. Es un módulo, no una excepción.
- **Legibilidad**: el contador de riqueza mantiene un ícono neutro (un fardo o un valor, no una pepita), y un desglose al pasar el mouse dice de dónde salió ("tejido 40 %, yacimiento 35 %, botín 25 %"). Los yacimientos neutrales pasan a llamarse y verse como lo que son en cada mapa (lavadero de oro, plata, salina), no como un "oro AoE" universal.

## Por civilización

### Mapuches — el enjambre
**Hoy:** la mecánica distintiva no funciona en el minuto 0, obliga a pelear y lo que gana no sirve. No hay camino de boom propio.
**Se mantiene:** lof dispersos, relevo, sigilo, malón, kulliñ como recurso propio.
**Se cambia:**
- **El kulliñ es la riqueza mapuche.** Es fiel a la investigación (M2: el ganado como paga, precio y prestigio). El weichafe y el rewe se pagan con kulliñ en vez de riqueza: el weichafe pasa a 55 de alimento y 20 de kulliñ, y el rewe a la edad II, con `hito_sustituye`, cobra la mitad de la riqueza en kulliñ. El yacimiento neutral queda para el mercado y la tropa de línea.
- **Boom propio desde el minuto 0:** el corral rinde por sí mismo (hoy 8 por minuto) y el ganado **crece con lo que hay**: un tanto por cada 10 cabezas, con tope por corral, como sugiere M2. Se arranca con un corral o con 60 de kulliñ inicial. El "banco vivo" es la apertura económica: más lof y más corrales, sin tropa.
- **Malón que paga:** el tope deja de cortar el botín, porque el excedente sobre el tope se convierte en riqueza a una tasa baja. El botín se pondera por tipo de edificio: alto en granjas, depósitos y casas, bajo en torres y empalizadas. Golpear la economía rinde y golpear muros no, tal como pide la ficha.
- **Contrapartida:** el ganado está a la vista y se roba, porque el saqueo del rival sobre un corral mapuche le da riqueza. Es la debilidad explotable (contra-malón).

**Resultado:** **corrales** (boom), **malón** (presión que se paga sola) y **rewe del lonko** (avance con renta de kulliñ). La pregunta deja de ser "¿ataco de primera?" y pasa a ser "¿crío o robo?". Esa es la identidad.

### Tawantinsuyu — la red
**Hoy:** la mit'a corre desde el minuto 0 (4 por aldeano y por minuto) y es la mejor mecánica de arranque del juego, pero no toca la riqueza hasta el aqllawasi de la edad III. La riqueza temprana es oro neutral, cuando la identidad es "trabajo, no metal".
**Se mantiene:** mit'a, caminos, qollqa, awqa (presión barata en edad I: 25 de alimento y 30 de mit'a), andenes.
**Se agrega:** el **tejido de cumbi** como destino de mit'a en la edad I. Un edificio chico (kancha de tejedoras) o una investigación en la qollqa convierte mit'a en riqueza a ritmo lento. El aqllawasi de la edad III queda como amplificador (+renta, tejido más rápido), no como la única fuente.
Así la decisión central ("en qué gasto la mit'a": camino, leva o tejido) existe desde el minuto 2. **Riesgo:** ya rinde bien (4 a 7 de 10). El tejido reemplaza riqueza neutral, no se suma.

### Guaraníes — el monte
**Hoy:** la mejor resuelta. La roza rinde mucho, se agota y deja un yerbal (400 de riqueza). La riqueza nace de la comida, sin pelear. La presión (arqueros con 6 de alcance y emboscada de +50 %) es real desde la edad I. Tienen las dos patas.
**Problema:** el yerbal es pasivo, está dentro de la base y no tiene riesgo.
**Se cambia:**
- El **yerbal se ve verde, no dorado**: es la primera civ que demuestra que la riqueza no es oro.
- Se agregan **yerbales silvestres lejanos** (M10) como pata de expansión y riesgo: más riqueza, lejos y expuesta, con un campamento destructible. El yerbal de capuera queda como fuente segura y chica, y se baja un poco (300) si los torneos lo piden.

### Etiopía — la corte que camina
**Hoy:** el gult funciona desde la edad I (renta de 18 de riqueza y 14 de alimento por 200 de recursos). Es la única renta propia temprana. Pero el boom (gult) y la presión (jinete noble: 70 de alimento y 35 de riqueza) compiten por los mismos recursos en los mismos minutos, y la corte móvil no se usa. Queda en el medio: ni crece ni pega (2 a 4 de 10).
**Se cambia, con el gult como palanca doble (M2 de la investigación):** al construirlo se **asigna a un titular**, con dos opciones de datos sobre el mismo módulo `renta`:
- **A un señor:** la renta actual (riqueza y alimento). Es el boom.
- **A un regimiento:** menos renta, y a cambio el jinete noble cuesta menos riqueza o se entrena más rápido mientras ese gult exista. Es la presión que se financia con tierra, fiel a "los caballos no se compran" (M3).
- La reasignación tiene costo (tiempo sin renta), para que no sea un interruptor gratuito.
**Más adelante:** la **ruta de la sal** (M4), que paga más cuanto más lejos está la corte. Así la kätäma tiene una razón económica para mudarse.

### Palmares — el refugio
**Hoy:** gana los torneos (7 a 9 de 10) con una mecánica de población: la fama trae gente y la liberación convierte edificios rivales en aldeanos. Su riqueza es 100 % yacimiento neutral, y el resgate ("cada riqueza cuesta secreto") no existe. El problema es de identidad, no de poder.
**Se cambia:**
- **Resgate** como pata de boom: un sítio de moradores neutral donde se cambia alimento (farinha) por riqueza. Cada viaje **revela el mocambo de origen** un tiempo, usando el `sigilo` existente con un temporizador de exposición. Riqueza que cuesta secreto.
- **Correría a ingenios neutrales** (M2) como pata de presión que no depende de pegarle a la base rival en el minuto 4: libera gente y algo de riqueza, con guardia neutral que crece en cada correría.
- **Compensación:** como ya están arriba, se bajan el yacimiento neutral cercano y la fama pasiva del centro (24 por minuto). Su fuerza se mueve a mecánicas propias con contrajuego.

### Ayutthaya — el puerto
**Hoy:** en la edad I es una civ genérica con arrozales (+45 % junto al agua). Los barrios (renta 8) llegan en la edad II y el puerto real en la III. El elefante, que es la identidad militar, también es de edad II. Los primeros 8 minutos no se distinguen de nadie.
**Se agrega:** el **almacén real (Phra Khlang) en la edad I**, en versión mínima de M1. El excedente de arroz se deposita como stock y se vende **en ventanas de puerto** visibles en un reloj público, un minuto cada cuatro o cinco, a buen precio. Fuera de la ventana no se vende. Boom = arrozales junto al río y una ventana bien cargada.
**Presión:** el hito `kraal_real` ya produce elefantes. Se adelanta una **captura de elefante** barata (un solo chang suek de edad I con tope de 1) como golpe de la primera seca (apertura 1 de la investigación). Si es demasiado, alcanza con la infantería de dap y su ventaja de vida.
**Debilidad:** el calendario es público, y el rival sabe cuándo atacar el almacén.

## Dependencia territorial

Observación del autor: si la riqueza común está lejos y en un solo lugar, controlar ese punto define la partida. Hoy el mapa pone 2 yacimientos por base y 4 disputados (3 en el centro y 1 más afuera), además de 3 sitios sagrados que rinden riqueza. Con mi ajuste anterior (un yacimiento por base) el centro pesaría todavía más, así que corrijo: **la riqueza disputada tiene que ser un plus, nunca el piso**.

### Qué le queda a cada civ sin las fuentes disputadas

| Civ | Sin el centro le queda | Exposición territorial propia | Riesgo |
|---|---|---|---|
| Mapuches (con el ajuste) | Corrales y crecimiento del ganado, en cualquier lugar | Ninguna: el lof se rehace en otra parte y el malón va a buscar al rival | Bajo. Hoy, sin el ajuste, es **alto**: su única riqueza es el yacimiento |
| Guaraníes | Roza → yerbal, que se rehace en cualquier claro | Necesitan bosque para el sigilo, no para la economía | Bajo |
| Etiopía | Gult (renta sin aldeanos) | Defensa en altura; la corte se muda si pierde la zona | Bajo: es la que mejor remonta |
| Palmares | Fama pasiva y acogida | Sigilo en el monte; con el resgate, los sítios neutrales | Medio: el resgate y los ingenios son lugares fijos |
| Tawantinsuyu | Mit'a (sale de los aldeanos) y tejido | Andenes en ladera y red conectada a la capital | Medio: en llano los andenes no rinden y un camino cortado apaga el bono |
| Ayutthaya | Arrozales y almacén | **Agua**: arrozal +45 % junto al agua, y puerto y barrios pensados para el río | **Alto**: en montaña o llano seco pierde su motor de alimento y, con mi propuesta, el de riqueza |

Las más expuestas son **Ayutthaya**, que depende del agua, y los **mapuches actuales**, que dependen del yacimiento. Después vienen Tawantinsuyu, que necesita ladera y red, y Palmares si se agrega el resgate en sítios fijos.

### Ajustes a las "tres patas"

1. **El piso no depende del mapa.** La pata de boom propia rinde en cualquier terreno, aunque menos. El terreno favorable es un bono, no la condición. El arrozal sin agua rinde como una granja común (hoy pasa eso, y se mantiene). El andén en llano rinde como granja. El almacén siamés vende en el **propio palacio** a precio base, y el muelle o el borde de agua solo mejoran el precio.
2. **Ningún punto único.** Toda fuente fija de una civ tiene al menos dos lugares posibles o se puede construir: varios sítios de moradores e ingenios repartidos, y el yerbal silvestre en dos o tres zonas. Si se pierde uno, queda el otro, más lejos.
3. **El centro rinde más pero no es imprescindible.** Los yacimientos centrales y los sitios sagrados no superan, sumados, lo que rinde la fuente propia de una civ con economía media. Meta medible en `tests/torneo.gd`: una civ que nunca toca el centro debe poder llegar a la edad III antes del minuto 20.
4. **Remontada por la identidad.** Cada civ tiene una salida si la encierran: el lof y la corte se mudan, el mocambo se esconde, la roza se reabre, la mit'a sale de la gente que quede y el mercado convierte excedentes (comisión del 30 %). Ayutthaya necesita la suya: barrios que rinden aunque no haya río.
5. **Mapas de prueba.** Correr el torneo en `montana` y `llano` seco para Ayutthaya, y en `llano` para Tawantinsuyu. Si su porcentaje de victorias cae más de 15 puntos frente a su mapa favorable, el bono de terreno pesa demasiado.

## Prioridades

1. **Mapuches**: kulliñ como riqueza, crecimiento del ganado, botín sin tope perdido. Sin esto, cualquier ajuste de números es parche.
2. **Transversal**: un solo yacimiento neutral por base, el parámetro `hito_sustituye` y la legibilidad del contador.
3. **Ayutthaya y Tawantinsuyu**: fuente propia en la edad I (almacén con ventanas, tejido de cumbi).
4. **Etiopía**: gult con titular.
5. **Palmares**: resgate y correría neutral, con recorte compensatorio.
6. **Guaraníes**: retoques visuales y yerbales lejanos.

## Cómo verificarlo

- Que `tests/torneo.gd` registre **de qué fuente sale la riqueza** de cada civ. Meta: en el minuto 8, al menos el 50 % sale de la fuente propia.
- IA con aperturas forzadas (boom y presión) por civ. Ninguna debe quedar por debajo del 35 %.
- Capturas del minuto 5: seis economías que se distingan a simple vista.
