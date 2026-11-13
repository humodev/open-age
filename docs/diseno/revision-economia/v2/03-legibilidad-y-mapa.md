# 03 · Legibilidad y mapa, ronda 2: entender sin manual

Perfil: UX, legibilidad y mapas. Parte de `../03-legibilidad-y-mapa.md`, `../00-sintesis.md`, la consigna `00-consigna.md` y `../../investigacion-aoe4/`.

El autor diseñó el juego y no entiende qué hace cada mecánica: es la mejor prueba de usuario que tenemos. El problema no son los nombres indígenas, sino que **el nombre llega antes que el verbo**.

## 1. Cada mecánica se entiende sin manual

### Regla: primero el verbo, después el nombre

Cada mecánica se presenta en tres capas, siempre en el mismo orden:

1. **Qué hacés y qué recibís**, en castellano llano: "Encerrás ganado en el corral; el rebaño crece solo y vale riqueza".
2. **El nombre doble**, con el indígena primero y el llano entre paréntesis: "Kulliñ (ganado)". Va en todos lados: botón, tooltip, panel y aviso. El paréntesis no se saca nunca.
3. **De dónde sale**, una línea de historia en cursiva al pie del tooltip, que es opcional para jugar.

Opción en el menú, **Nombres: originales y llanos (por defecto) / solo originales**. Nunca "solo llanos": los nombres son parte del pilar 3.

### Plantilla de tooltip (igual para las seis civs)

```
Kulliñ (ganado)                                 [ícono de la civ]
Encerrás ganado en el corral. El rebaño crece solo hasta el tope.
Rinde: +1 cabeza cada 20 s por corral · Tope: 6 por corral
Te pide: decidir cuándo vender o faenar. Nada más.
—
Para los mapuches, el ganado era riqueza, dote y alianza.
```

Cuatro renglones fijos: **qué hacés, cuánto rinde, cuánta atención pide, de dónde sale**. "Te pide" es obligatorio: si no entra en una línea, la mecánica pide demasiado.

### Las seis, en los cuatro canales

Los motores los decide economía (01, 02); si uno cambia, cambia la fila, no el patrón. En Palmares y Ayutthaya, donde el autor objetó el comercio, pongo un ejemplo que cumple los criterios 2 y 5.

| Civ | Nombre doble | HUD | Mapa | Tutorial (primer objetivo de su campaña) |
|---|---|---|---|---|
| Tawantinsuyu | Mit'a (turnos de trabajo) → Cumbi (tela fina) | Mit'a en terracota, con tope; la riqueza muestra "de cumbi +N/min" | Telares con tela de colores que se acumula en el aqllawasi | "Destiná turnos al telar y juntá 100 de riqueza" |
| Mapuches | Kulliñ (ganado), que es su riqueza | Rombo dorado con una cabeza de vaca y una barra de rebaño/tope | Animales visibles en el corral: la cantidad **se ve** | "Construí un corral y esperá a que el rebaño llegue a 10" |
| Guaraníes | Kokue (roza) → Ka'a (yerbal) | La riqueza muestra "de yerbales +N/min"; aviso cuando una roza se agota | La roza amarillea a medida que se gasta y se convierte en yerbal | "Sembrá una roza, agotala y mirá el yerbal que deja" |
| Etiopía | Gult (tierra que paga tributo) | La riqueza muestra "de gult +N/min" | Figuras de tributarios que caminan del gult al centro con sacos (solo imagen) | "Asigná un gult y mirá llegar el tributo" |
| Palmares | Fama (reputación del quilombo) + motor propio a definir (por ejemplo, farinha de la roça) | Fama en blanco hueso, ya no en dorado | Gente que llega por el borde del monte cuando sube la fama | "Juntá fama y recibí a los primeros que llegan" |
| Ayutthaya | Suai (tributo del monte), como ejemplo de subproducto | La riqueza muestra "del almacén real +N/min" | Fardos que se apilan en el almacén real | "Llevá madera al almacén real: el monte paga tributo" |

En las seis, la riqueza es **el mismo rombo dorado** con un **sello chico de la civ**, y su tooltip desglosa el ingreso por fuente (ronda 1). El dorado es solo de la riqueza.

### Cómo enseña el tutorial

- **Tutorial común**: objetivo "juntá riqueza" y la roza que deja un yerbal (ronda 1).
- **Primera misión de cada campaña**: su primer objetivo económico usa el motor propio, con la plantilla como diálogo.
- **Escaramuza**: una tarjeta "Tu riqueza" a los 5 s, una sola vez por civ, con la línea 1 de la plantilla y un pulso en el minimapa sobre la fuente propia más cercana.
- **Pausa → "Cómo juega mi pueblo"**: la ficha (sección 4) y los tooltips de sus mecánicas.

## 2. Costo de atención: avisar solo cuando hay que decidir

La investigación: hay tedio cuando se repite una orden sin elegir nada (impuestos chinos, prelado, inject) y suma cuando cada vuelta es una decisión (envíos de AoE3, chrono de 2017). Los arreglos celebrados **automatizaron la tarea sin quitar la decisión**. La interfaz aplica la misma regla.

**Tres clases de aviso, y nada más:**

| Clase | Cuándo | Ejemplo | Sonido |
|---|---|---|---|
| Decisión | Aparece una opción con costo que antes no estaba | "El rebaño llegó al tope: vender, faenar o construir otro corral" | Uno corto |
| Pérdida | Se está perdiendo algo y el jugador puede evitarlo | "Atacan el corral", "3 aldeanos inactivos: se agotó el yerbal" | Uno corto |
| Hito | Algo cambió para siempre | "La roza dejó un yerbal", "Edad II" | Solo la primera vez por tipo |

**Prohibido:**

- recordatorios periódicos ("recordá vender ganado");
- avisar que algo automático sigue funcionando;
- "listo para cobrar": si se cobra, se cobra solo.

**Reglas de la interfaz:**

1. **Estado antes que alerta.** Un tope lleno cambia el tono del contador y agrega "lleno · pierde +12/min", sin sonido. El costo de olvidarlo es visible y proporcional (prueba 9.1 de `03-otros-rts`).
2. **Un aviso económico cada 30 s como máximo.** Si hay más, se agrupan ("2 rebaños llenos"). Los de pérdida militar tienen prioridad.
3. **Cada aviso de decisión se puede resolver con un clic**: lleva al edificio y abre los botones de la decisión.
4. **Atención pareja, medida.** En el autotest, contar por civ las órdenes económicas cada 5 minutos, sin contar recolectar ni encolar aldeanos. Ninguna civ pasa del doble de la más baja. Si a la IA le cuesta una mecánica, al jugador también.

"Te pide" es la promesa; esta medición la verifica.

## 3. Qué hay alrededor de cada base

### La base cuenta la historia de la civ

Ajusto la ronda 1 a la síntesis: una **fuente común chica que se agota** (la salina, sin silueta de mina) y un **paisaje inicial** que muestra el motor propio sin que dependa de él: el motor funciona en cualquier terreno y el paisaje solo bonifica.

| Civ | A ≤12 casillas del centro | Lo que el jugador "lee" |
|---|---|---|
| Tawantinsuyu | Una loma (andenes), un claro para el telar | "Acá se trabaja la ladera" |
| Mapuches | Pradera abierta, sin bosque entre la base y el borde | "Acá pasta ganado" |
| Guaraníes | Monte pegado a la base, un ka'a silvestre chico | "Acá se vive del monte" |
| Etiopía | Llano despejado de 4×4, una altura a la vista | "Acá hay tierra para dar" |
| Palmares | Bosque y relieve detrás de la base | "Acá uno se esconde" |
| Ayutthaya | Agua a ≤10 casillas, si el mapa la tiene; si no, el almacén real rinde igual | "Acá se cultiva y se acopia" |

Regla de equidad: **misma riqueza alcanzable en los primeros 5 minutos y distinta forma**. Se valida con el torneo.

### Lo disputable, en espejo de verdad

La queja más repetida de AoE4 sobre el mapa: mercados y sitios sagrados que aparecen más cerca de un jugador, o que faltan. Revisé `_generate_map` y **Raíces ya tiene ese defecto**:

- Los yacimientos usan `_res_sym`, que espeja bien: si uno de los dos lados no entra, no se pone ninguno.
- Los **sitios sagrados no se espejan**. Son tres puntos fijos: el centro, `(mid-18, mid+14)` y `(mid+16, mid-16)`. En un mapa de 128, el segundo queda a unas **58 casillas** del jugador 1 y a **64** del jugador 2. Además `nearest_free` puede correr cualquiera de ellos de forma distinta.

Propuestas:

1. **Sitios y todo lo disputable con `_res_sym` o su equivalente para edificios**: si el espejo no entra, se mueve el par entero.
2. **Medir la distancia como camino**, no en línea recta. Con ríos y laderas, dos puntos simétricos pueden quedar a tiempos de marcha distintos. Que el generador lo compruebe con el pathfinder (diferencia ≤ 10 %) y, si no se cumple, regenere.
3. **A los costados, no solo al centro.** Como en el pedido de los competitivos de AoE4, lo disputable va en pares hacia los flancos, más un punto central. Así hay una opción "segura y modesta" cerca y otra "arriesgada y valiosa" lejos.
4. **Que se vea la equidad**: al empezar, el minimapa marca un momento lo disputable de los dos lados.
5. **Test**: 50 semillas por tipo de mapa; falla si algún par supera esa diferencia de camino.

## 4. Ficha de civ para el menú (5 líneas)

Plantilla. Cada línea responde una pregunta del jugador nuevo y ninguna usa un nombre propio sin su traducción:

```
1. Quiénes son:   <frase de la civ>
2. Su riqueza:    <qué hacés> → <qué recibís>. <Nombre (llano)>.
3. Te pide:       <cuánta atención y de qué tipo, en una línea>
4. Fuerte si…:    <momento o terreno fuerte> · Débil si…: <debilidad explotable>
5. Lo distinto:   <lo que ninguna otra hace, o no tiene>
```

Ejemplo:

```
Mapuches — No hay capital que tomar.
Su riqueza: criás ganado en corrales; el rebaño crece solo y vale riqueza. Kulliñ (ganado).
Te pide: decidir cuándo vender, faenar o arriesgar el rebaño en un malón.
Fuerte si: pelea dispersa y en movimiento · Débil si: batalla frontal y asedio.
Lo distinto: sin centro único; los lof se reemplazan entre sí.
```

La línea 3 le contesta al autor: dice de antemano cuánto hay que estar pendiente, con la misma vara para las seis.

## Orden por impacto y costo

| # | Cambio | Costo |
|---|---|---|
| 1 | Espejar los sitios sagrados y medir la distancia como camino, con su test | Bajo |
| 2 | Nombre doble en todos los textos y opción de nombres | Bajo (datos) |
| 3 | Tooltip de cuatro renglones con "Te pide" | Bajo |
| 4 | Ficha de 5 líneas en el menú y en la pausa | Bajo |
| 5 | Tres clases de aviso, tope de frecuencia, estado antes que alerta | Medio |
| 6 | Medición de atención por civ en el autotest | Medio |
| 7 | Primera misión de cada campaña con el motor propio | Medio |
| 8 | Imagen del motor en el mapa (animales, tributarios, fardos) | Medio a alto |
| 9 | Paisaje inicial por civ | Alto, toca el balance |
