# 01 — Visión y pilares

## Visión en una frase

Un RTS con la calidad y la asimetría de Age of Empires IV donde las protagonistas son las civilizaciones del sur global, jugadas con sus propias lógicas y no como variantes de un reino europeo.

## Pilares

### 1. Asimetría radical
Cada civilización se juega de forma distinta desde el primer minuto: otro orden de construcción, otra economía, otra forma de expandirse, de defenderse y de ganar. La referencia es AoE4 (mongoles nómadas, Delhi con investigación gratuita y lenta, rus que ganan oro cazando), no AoE2, donde casi todas comparten el mismo árbol.

La asimetría es entre civilizaciones, no un guion dentro de cada una. Cada civilización debe admitir varias aperturas y órdenes de construcción viables, que favorezcan estrategias distintas y que la comunidad pueda descubrir y refinar, como pasa en AoE4. El diseño no prescribe un orden de construcción: ofrece decisiones con costo y deja que el óptimo dependa del mapa, del rival y de la estrategia.

### 2. Función antes que forma
No se copian unidades europeas con otro aspecto. Se define qué función hace falta (movilidad, choque, asedio, defensa) y se cubre con lo que esa civilización realmente tuvo: caminos en vez de caballos, emboscada en vez de murallas, tributo en vez de minas.

### 3. Historia desde adentro
Cada civilización se cuenta desde su punto de vista: nombres y voces en su lengua, edades con su propia periodización, campañas sobre sus protagonistas y piezas documentales. Son sujetos de su historia, no víctimas ni decorado. El tono militante se expresa en mecánicas y relatos, no en discursos.

### 4. Legibilidad AoE4
Arte estilizado y claro, siluetas reconocibles, interfaz limpia. En cualquier momento el jugador entiende qué unidad es cuál, quién gana una pelea y qué puede hacer.

### 5. Alcance de una persona
Pocos sistemas, profundos y dirigidos por datos. Cada mecánica única se implementa como módulo reutilizable y configurable, no como caso especial en el código. Primero se prueba que es divertido con cubos grises; el arte va al final.

## Reglas de asimetría

### Capa común (igual para todas)
Lo que se mantiene idéntico para que el juego sea aprendible y balanceable:
- Los cuatro recursos: alimento, madera, piedra, riqueza.
- El triángulo de contadores: choque vence a distancia, distancia vence a línea, línea vence a choque.
- Cuatro edades.
- Controles, interfaz y condiciones de victoria disponibles.

### Ejes que varían
Cada civilización debe diferenciarse fuerte en al menos cuatro de estos seis ejes:
1. **Economía**: cómo obtiene alimento y, sobre todo, riqueza.
2. **Expansión**: cómo ocupa el mapa (red, dispersión, migración, bastión).
3. **Avance de edad**: qué hay que hacer para pasar de edad.
4. **Movilidad**: cómo mueve tropas rápido.
5. **Defensa**: qué protege su base.
6. **Arco tardío**: cómo cambia entre 1600 y 1800 (adopción, resistencia, alianza).

### Presupuesto por civilización
Para que el alcance sea manejable, cada civilización tiene exactamente:
- 1 mecánica económica única.
- 1 mecánica de expansión o construcción única.
- 1 mecánica de avance de edad única.
- 1 mecánica militar única.
- 2 o 3 unidades únicas. El resto son unidades compartidas por función, con nombre y aspecto propios.

### Palancas para que surjan órdenes de construcción

Para que haya variedad real de aperturas y no una sola óptima:
- **Avance de edad con opciones**: cada avance ofrece al menos dos alternativas con bonificaciones distintas, que orientan la partida.
- **Mecánica única con varios usos**: el recurso propio de cada civilización se puede gastar en economía, en ejército o en avanzar, y no alcanza para todo.
- **Varias vías tempranas a la riqueza**: ninguna civilización depende de una sola fuente al inicio.
- **Ventanas de tiempo**: cada civilización tiene momentos fuertes y débiles conocidos, que el rival puede atacar o esperar.
- **Dependencia del mapa**: pendientes, ríos, bosques y distancia al rival cambian qué apertura conviene.
- **Verificación**: partidas automáticas de IA contra IA con aperturas distintas, para detectar una dominante antes de que la encuentre la comunidad.

### Tests obligatorios
- **Test de la frase**: la civilización se describe en una frase que no sirve para ninguna otra ("no hay capital que tomar").
- **Test de los cinco minutos**: si las aperturas típicas de dos civilizaciones se ven iguales, el diseño falla.
- **Test de las tres aperturas**: cada civilización tiene al menos tres aperturas viables y distintas (como mínimo una de presión, una económica y una de avance rápido). Si una domina a las otras en todos los casos, el diseño falla.
- **Test de la debilidad**: toda civilización tiene una debilidad clara que el rival puede explotar.
- **Test del módulo**: cada mecánica única se puede describir como un módulo con parámetros, sin excepciones escritas a mano.

## Qué no es

- No es un simulador histórico: la jugabilidad manda, y lo histórico inspira y pone límites.
- No es un AoE con otras texturas.
- No es un juego de fantasía ni de historia alternativa libre. Lo contrafáctico se limita a lo que una partida necesita (por ejemplo, que incas y etíopes se enfrenten).
- No presenta a las civilizaciones como víctimas pasivas ni como utopías sin conflicto.

## Referencias

- Age of Empires IV: asimetría, monumentos para avanzar de edad, legibilidad, documentales.
- Age of Empires II: solo como contraejemplo de civilizaciones demasiado parecidas.
- Age of Empires III: tratamiento de las civilizaciones no europeas, a revisar críticamente.
