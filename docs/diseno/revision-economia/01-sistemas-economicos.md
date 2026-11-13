# 01 — El modelo de recursos

Perfil: diseño de sistemas económicos (AoE II/IV, AoM, Northgard, Against the Storm, Manor Lords). Es una revisión: no cierra decisiones (`04`) ni fija números (D-008). Los rendimientos se comparan con un aldeano en el yacimiento actual.

## 1. Diagnóstico: hoy la riqueza ES la mina

En la edad I, **las seis** sacan la riqueza del mismo lugar: los dos yacimientos que `_generate_map` pone a 10 casillas de cada base (`picks[3]`). Las fuentes propias llegan tarde, son chicas o no dan riqueza:

| Civ | Fuente propia | Cuándo rinde de verdad |
|---|---|---|
| Tawantinsuyu | Aqllawasi | En la edad III, porque es un hito |
| Mapuches | Malón | **Nunca da riqueza**: `saqueo.recurso` es `kullin`. La riqueza sale de la mina y del parlamento (edad IV) |
| Guaraníes | Yerbal | Recién cuando se agota una roza |
| Etiopía | Gult | Desde la edad I, pero su renta es menos de la mitad de un aldeano en la mina, y cuesta como cuatro aldeanos |
| Palmares | Correrías | Dan fama; la riqueza llega con Cucaú (edad IV) |
| Ayutthaya | Barrios y puerto | En las edades II y III |

El hito de la edad II cuesta riqueza, y también el weichafe y el jinete etíope. La apertura óptima es la misma para todas: frutos, madera y mina. Por eso falla el test de los cinco minutos (`01`) y el mapa "parece AoE4". Mapuches y Etiopía pagan más, porque su choque come riqueza y su motor no la da o rinde poco.

Hay además un problema de modelo: el kulliñ es, según la propia investigación, **la riqueza mapuche** (`investigacion/mapuches.md`, M2). El jugador maneja dos monedas que representan lo mismo.

## 2. Requisitos

1. Que el mapa no muestre un objeto que "parece oro y no es nada".
2. Que cada civ tenga desde el minuto 0 una vía de riqueza propia y **pacífica**, más una vía común (`01`, "varias vías tempranas").
3. Que la capa común se pueda leer: cuánta riqueza tiene el rival y qué cuesta cada cosa.
4. Que lo pueda hacer una sola persona y que la IA lo pueda jugar (renta y edificios-fuente sí; micro de arreos, poco).

## 3. Tres modelos

### A — "Mina común, extractor propio" (AoE4: malíes, rus)
El yacimiento se queda, pero pasa a ser **salina** (la sal fue moneda en Etiopía y bien de intercambio en los Andes, la frontera mapuche y Brasil). Cada civ gana una bonificación sobre fuentes comunes.
- **Pro**: cambio mínimo.
- **Contra**: la salina sigue siendo el centro y la apertura no cambia. Arregla la estética, no el problema.

### B — "Cuarto recurso distinto por civ" (Northgard, otomanos y macedonios de AoE4)
Cada civ tiene su propio cuarto recurso (cumbi, ka'a, amole, etc.) y las unidades comunes lo cobran.
- **Pro**: máximo sabor.
- **Contra**: rompe D-006. Todos los costos de riqueza (`unidades`, `edades`, `tecnologias`) dependerían de la civ, el mercado necesitaría seis tablas y el rival no podría leer tu economía. Es seis veces más balance para una persona sola.

### C — "Una riqueza, seis motores" (el favor de AoM) — **recomendado**
La riqueza sigue siendo **un solo recurso común** (misma clave y mismos costos), pero **cada civ la produce con su propio motor desde la edad I**. Es como el favor de AoM: los griegos rezan, los egipcios construyen y los nórdicos pelean, pero el héroe nórdico **también gana favor cazando**. La civ agresiva tiene una salida pacífica: ese es el antídoto para el malón.

Reglas:
1. **Se va el yacimiento de la base.** La riqueza neutral queda lejos (salinas a media distancia, nodos en el centro). Es la vía común, no la principal.
2. **Un motor de edad I por civ** que, bien atendido, rinda en cinco minutos lo que dos o tres aldeanos en la mina actual. Se apoya en un **rasgo del paisaje** que el mapa garantiza (sección 5).
3. **HUD**: la misma casilla, con nombre e ícono propios ("Riqueza · kulliñ").
4. **Quinto recurso solo si no es riqueza**: la mit'a (trabajo) y la fama (gente) se quedan, y **el kulliñ se fusiona con la riqueza mapuche**.
5. **El saqueo da riqueza**, pero como acelerador y nunca como única fuente.

- **Pro**: D-006 y los costos actuales quedan intactos. La apertura cambia de verdad y el mapa deja de mentir. Reutiliza módulos que ya existen (`renta`, `recurso_propio`, `saqueo`, `fuente`, `deja`).
- **Contra**: hay que balancear seis motores contra un piso común, el mapa pasa a depender de la civ y los nombres propios necesitan un tooltip claro.

## 4. Los primeros cinco minutos con el modelo C

| Civ | Motor de edad I | Paisaje | La decisión |
|---|---|---|---|
| **Tawantinsuyu** | **Taller de cumbi**: convierte mit'a en riqueza de forma pasiva. El aqllawasi lo mejora, no lo inventa | Ladera (andenes) | Cada turno va a camino, andén, qollqa o tela |
| **Mapuches** | **Kulliñ = riqueza**: el corral sobre pradera hace crecer el rebaño con interés compuesto, con tope por corral; faenar da alimento | Pradera | ¿Gastar en weichafe o dejar crecer? El malón suma, pero no hace falta. Un rebaño grande es un blanco: esa es la debilidad |
| **Guaraníes** | **Yerbal silvestre** en el monte, recolectable desde el minuto 0; las rozas agotadas dejan yerbales cerca de casa | Monte con yerbales | Yerbal lejano ya, o roza lenta pero cercana |
| **Etiopía** | **Gult** con una renta que valga la pena, y **mulas de sal**: el amole vale más cuanto más lejos de la salina se entrega (Álvares, H19) | Pradera fértil; salina a media distancia | ¿Vender cerca o mudar la corte para cobrar más? Usa el mismo objeto que todos, pero lo lee distinto |
| **Palmares** | **Palmar** (aceite y vino de palma) vendido de contrabando desde el mocambo; cada venta sube su exposición | Palmar en el monte | Riqueza contra secreto. Las correrías a ingenios **neutrales** suman gente y hierro |
| **Ayutthaya** | **Almacén real**: los arrozales junto al agua dejan un excedente que se vende como riqueza; los barrios lo escalan | Agua garantizada | Arrozales en el agua (rinden más, pero quedan expuestos) o tierra adentro |

- **Etiopía**: la idea del gult funciona; falla el número. La sal por distancia le da una vía activa y ata la corte móvil a la economía.
- **Mapuches**: hoy su choque cuesta un recurso que su motor no produce. Con la fusión, el weichafe se paga con ganado.
- **IA**: casi todo es "construí X sobre Y". La sal se resuelve con una regla de distancia mínima.

## 5. Que el mapa cuente la misma historia

Hoy cada base recibe frutos a 7 casillas, piedra a 10, **dos yacimientos a 10** y bosques. `_generate_terrain` aleja las lagunas (radio 18) y el relieve (radio 13), así que ninguna base tiene su paisaje. Propuesta:

1. **Kit común simétrico**: frutos, bosque cercano y piedra. **Se sacan los yacimientos de `picks[3]`.**
2. **Kit propio por civ**, generado antes de los recursos y declarado en datos (por ejemplo `paisaje_inicial` en `data/civs/`), con tipos reutilizables: `ladera` (una loma a 8–12 casillas), `pradera` (llano despejado con pasto marcado), `agua` (una laguna o un brazo que el filtro permite para esa base) y `monte` con nodos (yerbal o palmar). Va en la dirección donde hoy está la mina, así el espacio que ocupa es parejo.
3. **Salina a media distancia** (16–20 casillas, hacia el centro), una por jugador y simétrica: es la vía común, la base de la sal etíope y el primer punto de roce.
4. **Centro**: los yacimientos del centro pasan a ser salinas grandes o ferias, junto a los sitios sagrados.
5. **Ingenios neutrales con guardia**, simétricos y lejos: blanco de correrías y malones en la edad I, sin necesidad de atacar al rival.
6. **Aspecto**: nada dorado. Sal blanca, yerbal verde oscuro, palmar con su silueta y pradera ocre con ganado. Se lee de qué vive cada base.

Esto rompe un poco la simetría puntual, pero cada kit se balancea para su dueño y el generador sigue siendo determinista (civ + semilla). En las campañas se puede desactivar.

## 6. Dependencia territorial

Observación del autor: si la fuente común está lejos y es determinante, quien pierde esa región pierde la partida. El centro tiene que ser un **acelerador**, no un **interruptor**.

### Cuánto puede venir de lugares disputables

Son objetivos de diseño que mide el torneo; los valores concretos van en `data/`.

| Edad | Motor propio en la base | Lugares disputables (salinas, ferias, sitios, ingenios) |
|---|---|---|
| I | 80–90 % | 10–20 % |
| II–III | 65–75 % | 25–35 % |
| IV | 55–65 % | 35–45 % |

La regla que manda: **quien pierde todo lo disputable conserva al menos el 60 % de su ingreso de riqueza**. Pierde ritmo, no la partida. En la edad IV el centro pesa más, para que haya razones para salir y cerrar la partida, pero nunca la mitad.

Test automático: una IA que **nunca sale de su base** tiene que llegar a la edad II con poca demora frente a una que toma la salina, y a la edad III sin quedar fuera de la partida. Si no lo logra, el motor propio es débil o el centro rinde demasiado.

### Cómo evitar el bloqueo

1. **Nunca una sola fuente.** Cada civ tiene tres vías: el motor propio (renovable y en casa), el trueque o mercado (seguro, pero caro) y lo disputable. Ninguna tiene que bastar sola para ganar.
2. **Rendimientos decrecientes en lo disputable.** El segundo nodo del mismo tipo que controla un jugador rinde menos que el primero, y el tercero menos aún. Las salinas y ferias se agotan o tienen un tope por jugador. Quien domina el centro gana un margen, no el doble.
3. **Alternativas caras pero seguras:**
   - **Trueque en la edad I**: lotes chicos de alimento, madera o piedra a cambio de riqueza en el centro o en el edificio propio, con comisión alta y sin pelear.
   - **Mercado** desde la edad II, como hoy.
   - **Motor ampliable**: más aldeanos, corrales o gult rinden más, con su propio techo blando. Siempre se puede invertir en casa.
4. **Remontada:**
   - Lo disputable se agota, así que la ventaja de quien lo tiene es temporal.
   - Sostener el centro obliga a tener el ejército lejos de casa.
   - Retomar un nodo da un botín inmediato (mismo módulo `saqueo`).
   - La renta de los sitios sagrados se queda chica: su peso está en la victoria, no en la economía.

### Qué cambia en el modelo C y en el mapa

- **El motor propio es la columna vertebral.** Cada uno tiene que bastar solo para avanzar de edad en un tiempo razonable. Es la primera vara de balance.
- **Salina chica en la base**, dentro del kit común, cerca pero agotable. Es una vía común segura para recolectar desde el minuto 0. La **salina grande a media distancia** se queda como bonificación y primer roce.
- **Etiopía:** la mula cobra según la distancia entre la salina y la corte, así que mudar la corte lejos de la salina de casa ya rinde. Ir a la salina disputada suma, pero no es obligatorio.
- **Ferias del centro:** renta con rendimiento decreciente y tope por jugador, y además puesto de trueque neutral.
- **Ingenios:** botín de una sola vez que se rehace con más guardia. Nunca son una renta.

## 7. Recomendación

**Modelo C**: una riqueza común (D-006 intacta) y seis motores de edad I atados a un rasgo del paisaje garantizado. Esos motores dan la mayor parte de la riqueza (sección 6). Hay una salina chica en cada base, y lo disputable rinde con rendimientos decrecientes. Un quinto recurso solo si no es riqueza (se fusiona el kulliñ), y un saqueo que da riqueza pero nunca como única fuente. La fusión del kulliñ y el cambio del mapa piden una entrada "Propuesta" en `04`.

Orden de prueba, con cubos grises:
1. Sacar la mina de la base, agregar la salina y medir con el torneo.
2. Mapuches (fusión y rebaño) y Etiopía (gult y sal), que son las dos que están abajo.
3. `paisaje_inicial` y los otros cuatro motores.
4. Torneo y test de los cinco minutos con partidas grabadas.

Los nombres por civ (cumbi, kulliñ, ka'a, amole; para Ayutthaya, quizás *pot duang*) quedan `[verificar]` hasta que los revise el asesor histórico (informe 04).
