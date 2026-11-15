# Síntesis de los jugadores de prueba (2026-11-15)

Cuatro perfiles: [veterano de AoE4](01-veterano-aoe4.md), [nuevo en los RTS](02-nuevo-en-rts.md), [historia y estética](03-historia-y-estetica.md) y [equipos y todos contra todos](04-equipos-y-ffa.md). Ninguno jugó con mouse y pantalla: jugaron con capturas, partidas guiadas por script, IA contra IA y telemetría. Por eso opinan mejor de reglas, ritmo, textos y mapas que de cómo se siente el control.

## Lo que gustó

- **Las campañas:** narradores de adentro, fuentes citadas, rivales con matices. Es lo mejor del juego para tres de los cuatro.
- **El ritmo de la edad I** se parece al de AoE4: con una apertura limpia, la edad II llega a las 4:48 (AoE4, unos 4:30).
- **Comodidades:**
  - almacenes a 50 de madera donde el constructor recolecta al terminar;
  - punto de reunión sobre un recurso;
  - atajos como AoE4;
  - ir suelto con Alt: la retirada tarda 9,7 s contra 21,3 s en formación.
- **Paneles:** el de edad con "qué falta", "Mi pueblo" y las fichas con nombre propio y común.
- **Partidas de varios:** el menú de lugares, cero fuego amigo en unas 6400 bajas y los avisos de ataque a un aliado.

## Lo que más repiten, por orden de cuánto le quita a la diversión

### 1. Partidas que no se juegan bien (errores, se arreglan ya)
| Problema | Quién | Arreglo |
|---|---|---|
| Faltan sitios sagrados en mapas de varios: islas siempre tiene 1, y río, fortines y bosque, a veces 1–3 de 5–9. Un 3v3 terminó a los 9:04 con 32 bajas | Equipos | Buscarles otro lugar cuando caen en el agua; nunca menos que los previstos |
| En fortines nadie pelea: la IA se traba en sus puertas y no entra a los cercos rivales (0 bajas en 17 min; 4089 caminos imposibles en un 4v4) | Equipos, telemetría | La IA rompe puertas y empalizadas con asedio o elige otra salida |
| La IA aliada no defiende: radio de ayuda de 70 casillas con aliados a 90–192 | Equipos | Radio según la distancia al aliado |
| La IA casi no da tributo: solo cuando al aliado le quedan menos de 150 | Equipos | Dar para lo que el aliado está juntando (edad, tropa) |
| Todos contra todos con 6 no termina (abierta a los 60 min): un pueblo sin ejército sigue vivo por un edificio | Equipos | Revisar qué edificio cuenta para la victoria; tiempo límite o rendición |
| Pierde siempre contra la IA fácil (8 de 8); la fácil ataca a los 8–9 minutos ya en edad II | Nuevo | IA fácil de verdad; el menú en Fácil la primera vez |
| El tutorial, seguido al pie de la letra, deja la misión trabada sin salida | Nuevo | Pedir alimento y riqueza, avisar el ataque, fallar si se pierden todos los aldeanos |
| Derrota por sitios sagrados sin entender por qué | Nuevo, equipos | Cartel grande y cuenta regresiva en el centro; opción de apagarlos |

### 2. Sensación de juego (cambian el balance: van a consulta)
- **La micro no paga** (veterano): los contadores multiplican por 2 y 2,25; 10 guerreros le ganan a 10 honderos perdiendo una sola unidad, y kitear empeora el resultado. Propuesta: contadores de 1,5 a 1,75 (C-31).
- **La edad I no tiene decisiones** (veterano): 8 arbustos y nada más, sin caza ni ganado, y el explorador no tiene trabajo. Propuesta: animales para arrear y caza que pelea según el terreno (C-32).
- **El hito se levanta en menos de un minuto** (veterano): en AoE4 son unos 190 s. Propuesta: obra de 120–150 s (C-33).
- **Faltan órdenes:** mantener posición, patrullar y elegir la formación (ya en el plan, `proceso/21` paso 8); seleccionar todos los militares o los ociosos; marcadores de cámara; botón de aldeanos ociosos con número; cola global de producción.
- **Mejoras por unidad** y armadura separada contra cuerpo a cuerpo y contra distancia, y una IA "experta" que llegue a 80–100 aldeanos.

### 3. Aprender a jugar
- **Avisos que enseñen:** aldeanos sin trabajo, frutos agotados, riqueza que se acumula, "el rival tiene los tres sitios".
- **Un "arte de la guerra":** misiones cortas de una sola idea, con medallas.
- **La pantalla de fin explica por qué perdiste.**
- **El nombre visible en la grilla.**
- **Releer los mensajes de la guía.**

### 4. Identidad de cada pueblo
- **Rivales con identidad propia en las campañas:** Adal y Birmania hoy juegan como "Invasores" europeos; chankas, cayambes, cañaris y tupíes, con la cultura del jugador. Es barato y es lo que más pesa en el respeto.
- **Voces cortas en la lengua de cada pueblo.**
- **Aspecto por edad** (ya es regla en `docs/07`).
- **Modelos para las tropas:** hoy son maquetas blancas, y en una batalla no se distinguen los pueblos.
- **Hitos con arquitectura propia y una maravilla por pueblo:** la torre inca tiene almenas europeas y la iglesia etíope parece un hongo.
- **Música para Etiopía** (C-24).
- **Relatos narrados** entre misiones.
- **Paisaje por lugar:** arrozales sin agua, pasto más alto que las unidades.
- **Nombres a revisar:** "Espingardeiro de resgate" (en el portugués colonial, *resgate* era la compra de personas esclavizadas), "Inkarri" como edad, el Qorikancha en la edad IV y el orden de las edades guaraníes.

### 5. Partidas de varios
- **Bengalas y pedidos al aliado**, y frases de la IA ("Voy contra Rojo", "Te mando 200 de madera").
- **Condiciones de victoria y opciones en el menú:** conquista, sitios sí o no, tiempo límite, recursos iniciales.
- **Equipos juntos o mezclados.**
- **Más variedad entre semillas** en los mapas de N jugadores.
- **Pantalla de fin agrupada por equipo:** con 6 jugadores, una fila tapa el botón del menú.
- **Con 8 jugadores,** tres pares de colores se confunden.

## Plan

1. **Ya** (`proceso/22`, pasos siguientes): los errores de la sección 1 y lo de la sección 4 que es texto (rivales con nombre propio, nombres a revisar), porque no cambian el balance.
2. **Con respuesta del autor** (C-31 a C-34): contadores, comida temprana, tiempo de los hitos y el orden de prioridades.
3. **Después:** las comodidades de órdenes (plan de `proceso/21`, pasos 8 y 11) y los avisos que enseñan.
4. **Arte y sonido** (`proceso/19`), con los créditos del mes: tropas y aspecto por edad primero.
