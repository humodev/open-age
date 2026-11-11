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
- Varios constructores suman progreso de forma lineal en H1. Rendimientos decrecientes: ver A-008.
- Los edificios con `deposito` aceptan esos recursos. Los que tienen `produce` entrenan unidades por cola.

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
Fuera del triángulo (`02-alcance-y-epoca.md`). Regla de la capa común:
- Las unidades del triángulo hacen daño reducido a edificios (`contadores` → `edificio`).
- El daño real a edificios viene de unidades de asedio y de mecánicas propias (galgas, incendio). Llegan en H2 con las civilizaciones.

## Edades

- Cuatro edades (`02-alcance-y-epoca.md`). En la capa común se avanza construyendo un **hito**: un edificio que, al terminarse, sube la edad del jugador. Cada civilización reemplaza el hito genérico por su mecánica de avance (obra estatal, asamblea, fundación de aldea, iglesia) usando el mismo módulo con otros parámetros.
- Solo puede haber un hito en construcción a la vez. El costo y el tiempo dependen de la edad de destino (`edades.json`).
- Cada edad habilita unidades y edificios (`edad_min` en los datos) y una bonificación de ataque militar.
- Regla de opciones (`01`, palancas): cada avance ofrece al menos dos hitos con efectos distintos. En H1 hay uno solo; las opciones llegan en H2.

## Visión y niebla

- Cada entidad ve en un radio (`vision`). Lo no visto se muestra como explorado o negro.
- **Fuera de H1**: la niebla llega en H2, porque sigilo en bosque y emboscada (mapuches, guaraníes) dependen de ella. La simulación ya guarda `vision` en todas las entidades.

## Victoria

Condiciones comunes (`01`, capa común), configurables por partida:

| Condición | Regla | Estado |
|---|---|---|
| **Hitos** | Pierde quien se queda sin centros e hitos terminados | H1 |
| **Rendición** | El jugador abandona | H1 |
| **Maravilla** | Construir y defender una maravilla durante un tiempo | H2 |
| **Sitios sagrados** | Controlar todos los sitios sagrados durante un tiempo | H2 |

Las victorias preferidas de cada civilización (`03-matriz-de-roles.md`) tienen que ser posibles con estas condiciones; no se agregan victorias exclusivas.

## Unidades comunes de H1

En el prototipo gris todas las facciones usan las mismas unidades genéricas, una por función. En H2 cada civilización las reemplaza por las suyas (con nombre y aspecto propios) según su presupuesto (`01`).

| Clave de datos | Función | Notas |
|---|---|---|
| `aldeano` | civil | Recolecta, construye, pelea mal |
| `guerrero` | choque | Rápido, cuerpo a cuerpo |
| `hondero` | distancia | Frágil, alcance largo |
| `lancero` | línea | Lento, armadura alta; desde edad II |

## Edificios comunes de H1

| Clave | Función |
|---|---|
| `centro` | Produce aldeanos, depósito universal, población, dispara |
| `casa` | Población |
| `deposito` | Depósito de los cuatro recursos |
| `granja` | Alimento infinito, transitable |
| `cuartel` | Produce unidades militares |
| `torre` | Defensa a distancia; desde edad II |
| `hito` | Avanza de edad; cuenta para la victoria por hitos |
