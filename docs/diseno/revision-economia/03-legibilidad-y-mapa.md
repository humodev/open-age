# 03 — Legibilidad y mapa: de dónde sale la riqueza

Revisión de UX y mapas: qué entiende el jugador nuevo en el primer minuto. Propone cambios ordenados por impacto y costo.

## Diagnóstico

**Lo que ve el jugador** (capturas `proceso/04-seis-civilizaciones/03-guaranies.jpg`, `proceso/09-tutorial-y-prueba-de-campanas/01-tutorial.jpg`, `proceso/10-terreno-y-mapas/16-escala-nueva-palmares.jpg`):

1. **La misma base para los seis.** `_generate_map` (`src/sim/sim.gd`) pone alrededor de cada base lo mismo: arbustos a 7 casillas, bosque a 13, dos afloramientos de piedra a 10 y dos yacimientos de riqueza a 10, siempre del lado que mira al centro. Es el arranque de AoE4, y el jugador lo lee así: frutos, madera, piedra y la mina de oro.
2. **El yacimiento parece una mina de oro.** `rock_mesh("riqueza")` es una roca gris con siete cristales dorados. Para quien jugó un Age, eso es "oro". Y desde la cámara se distingue de la piedra solo por las motas: misma silueta, mismo tamaño.
3. **El HUD dice "riqueza" igual para todos.** Un rombo dorado y un número (`hud.gd`, barra de recursos). No tiene tooltip, no dice de dónde vino lo que hay ni cuánto entra por minuto. El "0" chico al lado cuenta solo aldeanos recolectando; la renta de un gult o de un sitio sagrado no aparece en ningún lado.
4. **Los recursos propios se pisan con la riqueza.** La fama de Palmares (`#d6a34a`) y la mit'a (`#c98a3b`) son dorados casi iguales a la riqueza (`#e3b23c`). En la captura de Palmares, el rombo de riqueza y el ícono de fama están lado a lado en el mismo tono: el ojo los agrupa.
5. **El tutorial no nombra la riqueza.** La misión da 150 de riqueza inicial y ningún objetivo la usa ni la explica. El jugador aprende madera, casa, aldeanos y cuartel, y la riqueza queda como "el oro".

**Lo que pasa en los datos**, que agrava la confusión. En la edad I, las vías propias de riqueza son pocas:

| Civ | Riqueza propia en edad I | Lo que el jugador junta de verdad |
|---|---|---|
| Tawantinsuyu | Ninguna: el aqllawasi es hito de la edad II | Yacimiento |
| Mapuches | Ninguna: el saqueo da **kulliñ**, no riqueza | Yacimiento |
| Guaraníes | La roza deja un yerbal, pero recién cuando se agota (550 de alimento) | Yacimiento |
| Etiopía | Gult (renta 18) | Gult y yacimiento |
| Palmares | Ninguna: el saqueo da **fama**, no riqueza | Yacimiento |
| Ayutthaya | Ninguna: el puerto real es hito | Yacimiento |

O sea: en cinco de seis pueblos, el yacimiento dorado **es** la riqueza de los primeros minutos. A la pregunta del autor ("¿para qué está?") la respuesta es incómoda: sin él no hay riqueza al principio. Además, la matriz (`03`) dice que Palmares saca riqueza de correrías y resgate, y los datos dicen fama. Lo resuelve economía; acá importa que el mapa y el HUD digan lo mismo que la mecánica.

## Principio

**El recurso es común y el origen es de cada pueblo.** "Riqueza" se queda como palabra y rombo dorado de la capa común (`01`): los costos, el mercado y el balance se leen igual en las seis civs. Lo que cambia por civ es **qué hay en el suelo, cómo se llama y qué dice el tooltip**. El jugador tiene que poder decir, sin leer el manual: "mi pueblo saca la riqueza de X; aquella cosa dorada del centro es de todos".

## Propuestas, por impacto y costo

### 1. Tooltip de la riqueza con el desglose de origen (impacto alto, costo bajo)

Al pasar el mouse por el contador:

```
Riqueza — 340  (+42 por minuto)
  Yerbales ............ +28
  Yacimiento .......... +14
  Sitios sagrados ..... +0
Tu pueblo: la roza agotada deja un yerbal; los yerbales dan riqueza.
```

- La línea final es la frase de la matriz, por civ, en `data/civs/*.json` (campo nuevo, por ejemplo `riqueza_origen`).
- Los contadores por fuente pueden ser enteros en la simulación o armarse en el cliente con los eventos de entrega y renta.
- En el contador, sumar `+N/min` en chico en lugar del número de aldeanos para la riqueza: con rentas, "0 aldeanos" miente.

### 2. Separar los colores de los recursos propios (impacto alto, costo mínimo)

Sacar del dorado a la fama y a la mit'a (`color` en el módulo `recurso_propio`). Propuesta: fama en blanco hueso o celeste claro, mit'a en ocre rojizo o terracota apagado, siempre lejos de `#e3b23c` y de los colores de equipo. Regla para `07`: **el dorado es solo de la riqueza.**

### 3. Un yacimiento que no sea "la mina de oro", y que cambie según quién está cerca (impacto alto, costo medio)

Dos piezas:

**a) Cambiar la silueta común.** El yacimiento neutral deja de ser roca con cristales. Que se lea como "bienes" y no como "metal": un montículo bajo con fardos, cestos y vasijas, o un claro con un mojón y ofrendas. Necesita otra silueta que la piedra (más bajo y ancho, sin bloques grises) y el dorado en la parte alta, para que se lea desde la cámara de juego. Nombre común: **"Bienes de intercambio"** o **"Yacimiento de riqueza"**, si se prefiere no cambiarlo.

**b) Aspecto por el pueblo más cercano.** Solo cambia la imagen; la simulación no se entera. El par de yacimientos que rodea cada base se dibuja y se nombra según la civ dueña de esa base, con la misma cantidad y la misma tasa. Los del centro mantienen el aspecto común, porque son los disputados.

| Civ | El depósito cerca de la base se ve como | Nombre en el panel |
|---|---|---|
| Tawantinsuyu | Veta en la ladera, con apachetas | Veta del Sol (quri) |
| Mapuches | Salina blanca con bloques | Salina |
| Guaraníes | Mancha de yerba silvestre bajo el monte | Ka'a (yerbal silvestre) |
| Etiopía | Pila de barras de sal (amole) | Amole |
| Palmares | Palmar (dendê) con cestos | Palmar |
| Ayutthaya | Fardos de palo de sapán o pieles junto al agua | Bienes del bosque |

Los nombres los confirma `investigacion/`; el criterio es que sea algo que ese pueblo intercambiaba, no "oro" genérico. Para los guaraníes, usar el tipo `yerbal` que ya existe: el yerbal silvestre del minuto 1 enseña cómo se ve lo que deja la roza.

El panel de selección del depósito agrega una línea: "Riqueza común: cualquier pueblo la puede juntar."

### 4. Una base que cuente la historia de la civ (impacto alto, costo medio a alto)

Hoy el anillo de recursos es una constante del código. Propongo moverlo a `data/` como **entorno inicial** por civ, un bloque que `_generate_map` lea, y que cada pueblo arranque rodeado de lo que su economía usa:

- **Tawantinsuyu**: ladera o loma a ≤12 casillas, para los andenes; el yacimiento en la ladera.
- **Mapuches**: pradera abierta y amplia, para el ganado; un solo yacimiento cerca (su riqueza viene después, por el parlamento) y más alimento.
- **Guaraníes**: el monte pegado a la base (a 8 y no a 13), un yerbal silvestre chico en lugar del segundo yacimiento y, si el terreno lo permite, agua cerca.
- **Etiopía**: llano despejado de 4×4 para el primer gult y una altura (amba) a la vista.
- **Palmares**: bosque y relieve detrás de la base, donde se esconden los mocambos; el yacimiento más lejos, para que la riqueza tienda al centro y a las correrías.
- **Ayutthaya**: agua a ≤10 casillas, para los arrozales y el puerto.

Regla de equidad: **misma riqueza total al alcance en los primeros 5 minutos, distinta forma.** Si un pueblo tiene menos yacimiento cerca, recibe la diferencia en su vía propia o en distancia al centro. Se valida con `tests/torneo.gd` antes de mezclarlo; por eso va después de la 3, que no toca el balance. En escaramuza, la simetría espejo se mantiene **por posición**: cada base lleva su entorno y el resto del mapa sigue espejado.

### 5. El primer minuto de cada pueblo, en escaramuza (impacto alto, costo bajo)

A los 5 segundos de partida, una tarjeta como el diálogo de la Guía (el componente ya existe en el HUD), una sola vez por civ y desactivable:

> **Tu riqueza** — Los guaraníes no cavan minas: la roza rinde mucho, se agota y deja un yerbal. El yerbal da riqueza. Ese ka'a al norte ya es uno.

Mientras se muestra, el minimapa marca la fuente propia más cercana con un pulso. Texto por civ en `data/civs/*.json`. Para pueblos sin vía propia en la edad I (casi todos, ver tabla), la tarjeta tiene que decir la verdad: "Al principio, la riqueza sale de [nombre local]. Tu forma propia llega con [hito]: elegilo para avanzar." Eso convierte el hueco en una meta.

Avisos de un renglón cuando aparece una fuente nueva: "La roza se agotó y dejó un yerbal", "Primer gult: rinde riqueza sin aldeanos", "Saqueo: +6 kulliñ (no riqueza)".

### 6. El tutorial enseña la riqueza (impacto medio, costo bajo)

`data/campanas/tutorial.json` (guaraníes) agrega dos objetivos entre la casa y el cuartel:

1. "Mandá dos aldeanos al ka'a, el yerbal silvestre: juntá 100 de riqueza." Diálogo: "La riqueza paga lo valioso: guerreros mejores, hitos, el mercado."
2. "Sembrá una roza (kokue). Cuando se agote, va a dejar un yerbal." Para que no haya que esperar los 550 de alimento, que la roza del tutorial tenga menos cantidad o que haya una roza ya casi agotada en el mapa.

Epílogo: "Cada pueblo consigue la riqueza a su manera: los etíopes con tierras que pagan tributo, Ayutthaya con su puerto, los incas con el tejido…". Es la frase que conecta el tutorial con la asimetría.

### 7. Rentas visibles en los tooltips (impacto bajo, costo bajo)

Si un edificio rinde riqueza, el tooltip muestra "▲ +18/min" en dorado, aparte del costo. Hoy gult, aqllawasi y puerto real no dicen que son fuentes.

## Orden sugerido

| # | Cambio | Impacto | Costo | Toca balance |
|---|---|---|---|---|
| 2 | Colores fuera del dorado | Alto | Minutos | No |
| 1 | Tooltip con desglose y +N/min | Alto | Bajo | No |
| 5 | Tarjeta "Tu riqueza" y avisos | Alto | Bajo | No |
| 6 | Tutorial con riqueza y roza | Medio | Bajo | No |
| 3a | Silueta nueva del yacimiento común | Alto | Medio (un modelo) | No |
| 3b | Aspecto y nombre por pueblo cercano | Alto | Medio (seis variantes) | No |
| 7 | Rentas visibles en tooltips | Bajo | Bajo | No |
| 4 | Entorno inicial por civ en `data/` | Muy alto | Alto | Sí (torneo) |

Los primeros responden al autor sin tocar números. El 4 es el que hace que el mapa cuente la historia de la civ, pero va después de que economía decida si cada pueblo tiene vía propia en la edad I: si no la tiene, ningún dibujo saca al yacimiento del centro.

## Para medir

Prueba de pasillo: mostrar la base de cada civ a alguien nuevo y preguntar "¿de dónde sacan la riqueza?". Hoy contesta "de la mina" seis veces; la meta son seis respuestas distintas.
