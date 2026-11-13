# 05 — Mecánicas núcleo

Reglas de la capa común (`01-vision-y-pilares.md`, "Capa común"). Aquí no hay números: los valores están en `data/` (D-008). Cuando una regla cita un parámetro, lo nombra con su clave de datos entre comillas invertidas.

## Simulación y tiempo

- La partida avanza en **ticks** de duración fija (`data/reglas.json` → `tick_ms`). Toda la lógica de juego ocurre en ticks; la imagen interpola entre ellos.
- Posiciones, vida, recursos y tiempos son **enteros** (ver `06-arquitectura.md`, "Determinismo"). Las distancias se miden en milésimas de casilla.
- Las órdenes del jugador y de la IA entran como **comandos** con número de tick. Nada modifica el estado de la simulación por fuera de un comando.

## Economía

### Recursos
Los cuatro de D-006: alimento, madera, piedra, riqueza. En la capa común:

| Recurso | Fuentes comunes | Fuentes propias de civilización |
|---|---|---|
| Alimento | Arbustos (agotables), granjas (infinitas, más lentas) | Andenes, roza, ganado, arado (fichas en `civs/`) |
| Madera | Árboles (agotables) | — |
| Piedra | Afloramientos (agotables) | — |
| Riqueza | Yacimientos neutrales (agotables) | Tejidos, malón, yerba, tributo (fichas en `civs/`) |

Los yacimientos neutrales de riqueza existen para cumplir la regla de "varias vías tempranas a la riqueza" (`01`, palancas). Cada civilización debe tener al menos una vía propia además de ellos.

### Recolección
1. El aldeano camina hasta la fuente y recolecta a una tasa por segundo que depende del tipo de fuente (`unidades.json` → `aldeano.tasa`).
2. Al llenar su carga (`carga`) camina al **depósito** más cercano que acepte ese recurso, entrega y vuelve a la misma fuente.
3. Si la fuente se agota, busca otra del mismo tipo dentro de un radio (`reglas.json` → `radio_rebusca`); si no hay, queda inactivo.
4. Las granjas son edificios transitables: el aldeano trabaja parado sobre ellas.
5. Al terminar una obra, el aldeano retoma el recurso que recolectaba antes, dentro de `radio_retomar`.

### Población
- Cada unidad ocupa población (`pob`). El tope es la suma de lo que aportan los edificios terminados, con un máximo absoluto (`pob_max`).
- Si no hay población libre, la producción se detiene sin perder el progreso.

### Costos
Se pagan al encolar. Cancelar devuelve el costo completo. Construir descuenta al colocar el cimiento; demoler un cimiento sin terminar devuelve el costo.

## Construcción

- Los edificios ocupan un rectángulo de casillas (`tam`). No se pueden superponer a otros edificios ni a recursos, ni salir del mapa.
- Al colocarse aparece un **cimiento**. Los aldeanos asignados suman progreso; el edificio gana vida en proporción.
- Rendimientos decrecientes (P-006, como AoE4): con *n* constructores la obra tarda `tiempo × 3/(n+2)`. Se desactiva con `reglas.json` → `construccion_decreciente`.
- Los edificios con `deposito` aceptan esos recursos. Los que tienen `produce` entrenan unidades por cola.

## Reparación

Un aldeano con orden sobre un edificio propio dañado lo repara a la velocidad de construcción. En H1 reparar no cuesta recursos; ver A-012.

## Guarnición y defensa de la base

Sirve para que una economía sin ejército pueda sobrevivir a la presión temprana (palanca "ventanas de tiempo", `01`).
- Los edificios con `guarnicion` alojan hasta esa cantidad de unidades. Las alojadas no reciben daño ni ocupan lugar en el mapa, pero siguen contando población.
- Los edificios con `ataque` disparan una **andanada** cada `cadencia_ms`: `flechas` propias más una por unidad alojada.
- **Campana** (desde el centro): los aldeanos dentro de `radio_campana` se refugian en el edificio propio con lugar más cercano. El **toque de calma** los saca y vuelven a recolectar lo que recolectaban.
- Si el edificio cae, las unidades alojadas salen vivas.
- Orden "Refugiarse" para cualquier unidad; clic derecho sobre un edificio propio con guarnición también aloja.

## Investigaciones

- Viven en `data/tecnologias.json`. Cada una tiene edificio, ranura en la grilla, edad mínima, requisito opcional, costo, tiempo y `efectos`.
- Se encolan en el edificio como una unidad y se pagan al encolar. Una investigación solo puede estar en una cola a la vez.
- Tipos de efecto de la capa común (son el contrato del módulo; las civilizaciones reutilizan los mismos tipos):

| Tipo | Parámetros | Efecto |
|---|---|---|
| `tasa` | `recurso` (o `*`), `pct` | Recolección más rápida |
| `carga` | `n` | Más carga por viaje |
| `ataque` / `armadura` | `funciones`, `n` | Suma a unidades de esas funciones |
| `vida_pct` / `velocidad_pct` | `funciones`, `pct` | Porcentaje sobre la base |
| `edificio_vida_pct` | `pct` | Vida de todos los edificios |
| `edificio_ataque` / `edificio_alcance` | `n` | Andanadas de centros, torres e hitos |

- Los efectos son por jugador y se acumulan. Vida y velocidad se recalculan al instante; la vida actual conserva su proporción.

## Producción

- Cada edificio productor tiene una cola (`reglas.json` → `cola_max`). Solo el primer elemento avanza.
- Al terminar, la unidad aparece en la casilla libre más cercana al edificio y camina al **punto de reunión** si existe. Si el punto de reunión es un recurso, los aldeanos empiezan a recolectarlo.

## Combate

### Funciones y triángulo
Toda unidad militar tiene una **función** (D-007). El daño se calcula así:

```
daño = max(minimo, ataque × multiplicador[función atacante][función objetivo] / 100 − armadura)
```

- El triángulo (choque > distancia > línea > choque) vive en `reglas.json` → `contadores`. Una función que no figura usa 100.
- Los aldeanos tienen función `civil`; los edificios, `edificio`.
- Bonificaciones de edad y de civilización se aplican como porcentajes sobre `ataque` (fichas y `edades.json`).

### Comportamiento
- **Cuerpo a cuerpo**: se acerca hasta tocar el borde del objetivo.
- **Distancia**: se detiene a su `alcance` y dispara; el impacto es inmediato en la simulación y el proyectil es solo visual. Ver A-007 sobre proyectiles esquivables.
- Las unidades militares inactivas atacan solas a cualquier enemigo dentro de su `vision`.
- **Ataque en movimiento**: avanza hacia un punto y pelea con lo que encuentre en el camino.
- Prioridad de objetivo automático: unidades militares, después aldeanos, después edificios.
- Edificios con `ataque` (centro, torre) disparan solos a unidades enemigas en alcance.

### Asedio y defensas
Fuera del triángulo (`02-alcance-y-epoca.md`). Reglas de la capa común:
- Las unidades del triángulo hacen daño reducido a edificios (`contadores` → `edificio`).
- **Ariete** (`asedio`, desde la edad II, en el cuartel): solo ataca edificios y con un multiplicador muy alto. Es vulnerable al choque y casi inmune a la distancia. Es el asedio genérico; cada civilización lo reemplaza por el suyo (`investigacion/` propone, por ejemplo, el cañón de tacuara guaraní o los proyectiles incendiarios incas).
- **Empalizada**: cerco de troncos de una casilla, barato, que se coloca arrastrando una línea 4-conexa (sin huecos en diagonal).
- **Puerta**: deja pasar solo a su dueño y se puede poner sobre una empalizada propia. Cada jugador tiene su propia grilla de caminos (`06`).

## Edades

- Cuatro edades (`02-alcance-y-epoca.md`). En la capa común se avanza construyendo un **hito**: un edificio que, al terminarse, sube la edad del jugador. Cada civilización reemplaza el hito genérico por su mecánica de avance (obra estatal, asamblea, fundación de aldea, iglesia) usando el mismo módulo con otros parámetros.
- Solo puede haber un hito en construcción a la vez. El costo y el tiempo dependen de la edad de destino (`edades.json`) y son iguales para todas las opciones.
- Cada edad habilita unidades, edificios e investigaciones (`edad_min`) y una bonificación de ataque militar.
- Regla de opciones (`01`, palancas): cada avance ofrece dos hitos. El hito queda en el mapa y su efecto es permanente (`efectos`, mismos tipos que las investigaciones):

| Hito genérico | Qué da |
|---|---|
| `hito_economia` (abundancia) | Recolección más rápida, depósito de todo, población |
| `hito_guerra` (guerra) | Entrena tropas, dispara andanadas, aloja guarnición, más vida militar |

Las civilizaciones reemplazan estos dos por los suyos (obra estatal, asamblea, fundación, iglesia o monasterio) con el mismo módulo.

## Relieve y agua (D-027)

- Cada casilla tiene una altura entera. Los tipos de mapa son llano, montaña, río y bosque (`reglas.json` → `terrenos`); las campañas eligen el suyo.
- Ataque a distancia desde más arriba: `+bono_altura_pct` por nivel de diferencia. Visión: `+vision_por_nivel` por nivel.
- El agua profunda es intransitable. Los vados se caminan pero no se edifican. Los edificios exigen terreno parejo.

## Visión y niebla

- Cada entidad ve en un radio (`vision`). Estados por casilla y por jugador: sin explorar, explorado y visible. Se calcula en la simulación cada `niebla_cada_ticks`, porque sigilo y emboscada (H2) dependen de ella.
- Las unidades enemigas solo se ven en casillas visibles. Los edificios y recursos explorados quedan a la vista, atenuados.
- Cada jugador empieza con un **explorador**: a pie (no hay caballo para todos, pilar 2), rápido, de visión amplia y débil en combate.
- La IA de H1 todavía ve todo el mapa (`08`).

## Victoria

Condiciones comunes (`01`, capa común), configurables por partida:

| Condición | Regla | Estado |
|---|---|---|
| **Hitos** | Pierde quien se queda sin su centro inicial (capital) ni hitos de edad terminados. Los centros extra no cuentan | H1 |
| **Rendición** | El jugador abandona | H1 |
| **Maravilla** | Construir y defender una maravilla durante un tiempo | H2 |
| **Sitios sagrados** | Controlar todos los sitios sagrados durante un tiempo | H2 |

Las victorias preferidas de cada civilización (`03-matriz-de-roles.md`) tienen que ser posibles con estas condiciones; no se agregan victorias exclusivas.

## Unidades comunes de H1

En el prototipo gris todas las facciones usan las mismas unidades genéricas, una por función. En H2 cada civilización las reemplaza por las suyas (con nombre y aspecto propios) según su presupuesto (`01`).

| Clave de datos | Función | Notas |
|---|---|---|
| `aldeano` | civil | Recolecta, construye, repara, pelea mal |
| `explorador` | explorador | Descubre el mapa; fuera del triángulo |
| `guerrero` | choque | Rápido, cuerpo a cuerpo |
| `hondero` | distancia | Frágil, alcance largo |
| `lancero` | línea | Lento, armadura alta; desde edad II |
| `ariete` | asedio | Solo edificios; desde edad II |

## Edificios comunes de H1

| Clave | Función |
|---|---|
| `centro` | Produce aldeanos y exploradores, depósito universal, población, guarnición y andanadas. El inicial es la capital y cuenta como hito |
| `casa` | Población |
| `deposito` | Depósito de los cuatro recursos |
| `granja` | Alimento infinito, transitable |
| `cuartel` | Produce unidades militares |
| `torre` | Defensa a distancia y guarnición; desde edad II |
| `empalizada`, `puerta` | Cerco y paso propio |
| `hito_economia`, `hito_guerra` | Avanzan de edad; cuentan para la victoria por hitos |
