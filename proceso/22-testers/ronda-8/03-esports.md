# Ronda 8 · ¿Qué tan lejos está «Raíces» de jugarse profesionalmente?

> Pregunta del autor (síntesis de la ronda 8): «¿Qué tan lejos ven el juego de algo que se pueda jugar profesionalmente, estilo esports?»
> Responden el **veterano competitivo de AoE4** y el **constructor de partidas largas** (AoE2 DE, AoE4, Anno). Sin jugar de nuevo: lo dicen a partir de las rondas 7 y 8, de `docs/09-estado.md` y de `data/reglas.json`.

## 1. Notas por área (0 a 10)

| Área | Veterano | Constructor |
|---|---|---|
| Profundidad estratégica y diversidad | 5 | 6 |
| Asimetría y balance de los seis pueblos | 5 | 6 |
| Techo de habilidad (micro, macro, APM útil) | 4 | 5 |
| Legibilidad para espectadores | 2 | 3 |
| Claridad de reglas y predictibilidad | 6 | 5 |
| Duración razonable | 6 | 7 |
| Rendimiento | 4 | 5 |
| Multijugador en red (H5) | 0 | 0 |
| Matchmaking y ranking | 0 | 0 |
| Repeticiones y modo espectador | 4 | 4 |
| Anti-trampa | 1 | 1 |
| Mapas competitivos | 4 | 5 |
| Comunidad y modding | 3 | 5 |
| **Global** | **3/10** | **3,5/10** |

### Veterano: por qué

- **Profundidad, 5.** Hay decisiones de verdad: dos hitos por edad, la maravilla que depende del hito de la II, la escuela de la IV y los seis motores económicos. Pero en la ronda 7 la identidad de cada pueblo aparecía recién después del minuto 20, y la IV es «comprar todo» (61 compras en mi partida G, con 52 000 de madera sobrando). En AoE4 la build se define entre el 10 y el 15. Las escuelas excluyentes que aprobó el autor van bien encaminadas.
- **Balance, 5.** El torneo da a las seis entre 34 y 64 %, con 5 a 10 semillas y **IA contra IA**. Eso mide a la IA, no al pueblo. Un 64 % en manos humanas es un pueblo roto en rankeadas. Sin datos humanos no puedo dar más.
- **Techo de habilidad, 4.** La simulación responde (formación, ataque en movimiento, campana, guarnición), pero falta lo que separa a un pro de un buen jugador: atacar el suelo con la catapulta, Ctrl+clic por tipo, Mayús en patrullar, destello del blanco (ronda 7, §4). Con 90 soldados contra 20 (1v6 fácil), ningún micro alcanza, y eso habla de que el combate es más de masa que de manejo.
- **Espectadores, 2.** De lejos las tropas son manchas con un disco de color; el lancero no se distingue del guerrero. En el minimapa de 216 casillas en 230 px las unidades son puntos de 1 px. No hay vista de observador (producción de ambos, economía comparada, ejércitos).
- **Reglas, 6.** Bien: el combate no tiene azar, los bonos son planos y hay dos armaduras. Mal: auras que dependen del lugar, hitos con efecto global o local según la edad, y la maravilla que pide un hito que la ficha no dice. Para un caster, cada excepción es un minuto de explicación.
- **Duración, 6.** Que la cuenta de sitios no corra antes del minuto 25 fue un acierto. Pero un 1v1 parejo que llega a la IV va de 45 a 60 minutos; la final de un torneo de AoE4 promedia 20 a 30.
- **Rendimiento, 4.** En 1v1 sobra; con 7 jugadores, el peor tick va de 102 a 315 ms. En competencia un tirón en la pelea decide la partida.
- **Red, ranking y anti-trampa, 0, 0 y 1.** No existen. El 1 es porque la simulación determinista con enteros es la base correcta para el lockstep. Pero el lockstep le da a cada cliente el estado completo, y un mapa sin niebla se arma en una tarde.
- **Repeticiones, 4.** Existen y son por comandos, lo cual es lo más difícil. Falta saltar a un minuto, velocidad variable con línea de tiempo y cambiar de perspectiva.
- **Mapas, 4.** El generador con simetría por giro y la equidad medida en 50 semillas es mejor de lo que tienen muchos juegos indie. Pero no hay un pool fijo con nombre, y la piedra (1600 por jugador, igual en todo tamaño) hace que el final dependa de cuánto quede.
- **Modding, 3.** Que todo el balance esté en `data/` en JSON es oro para el modding. No hay comunidad ni herramientas publicadas (editor, workshop).

### Constructor: por qué

- **Profundidad, 6.** Para el que construye hay más que en AoE4: empalizada barata que aguanta, torres, fortaleza, reparación, mercado y economía tardía. En el 1v6 cerré 149 tramos y nadie pasó en 30 minutos. Eso es estrategia, aunque no sea la que se transmite.
- **Balance, 6.** Las mecánicas propias aparecen y cambian el ejército. Me preocupa más la economía común: sin piedra, el inca pasó 34 minutos en la II. Un desequilibrio de recursos de mapa pesa más que uno de pueblo.
- **Techo, 5.** La macro tiene techo: 100 aldeanos, tres centros, muro, mercado y tributos. La micro no la puedo juzgar.
- **Espectadores, 3.** Un muro de 149 tramos se ve bien en una captura. Pero el público no entiende «kawiñ», «gult» ni «khipukamayuq» sin un panel que lo explique.
- **Reglas, 5.** La piedra que no alcanza, la maravilla que pide un hito y los mensajes que saturan (292 «Población llena») hacen que pierda por cosas que no entendí a tiempo.
- **Duración, 7.** A mí 45 a 60 minutos me gustan. Para competir sirve si hay modos: rápido de 25 y largo con maravilla, como AoE2 tiene Arabia y Arena.
- **Rendimiento, 5.** A ×1 y ×2 entra con 7 jugadores (25 a 47 ms por tick). Los picos sí son un problema.
- **Red, ranking, anti-trampa: 0, 0 y 1.** Igual que el veterano.
- **Repeticiones, 4.** Saqué las capturas de la ronda 8 reproduciendo con `--replay` y anduvo. Es la mejor señal de que la base es sólida.
- **Mapas, 5.** La simetría está, pero no hay un mapa «Arena» (base cerrada, recursos de oro adentro), que es el formato donde un constructor compite.
- **Modding, 5.** Los JSON comentados con `_doc` se leen como un manual. Con un editor de escenarios público, la comunidad de AoE2 se arma sola.

## 2. Qué falta

### Para un primer torneo amateur online (requisitos duros, en orden)

1. **Multijugador en red (H5):** lockstep por comandos, con verificación de sincronía (hash del estado por tick) y reconexión. Sin esto no hay torneo. *(Los dos)*
2. **Lobby con salas y código de invitación**, elección de pueblo y mapa, y pausa por jugador limitada. No hace falta matchmaking para un amateur: el organizador arma las llaves. *(Los dos)*
3. **Repeticiones guardadas automáticamente y compatibles entre clientes iguales**, con línea de tiempo y velocidad. Para resolver disputas y para que alguien lo transmita. *(Los dos)*
4. **Versión fija con número visible** y repeticiones atadas a esa versión: el balance no puede cambiar en medio del torneo. *(Veterano)*
5. **Pool de 3 a 5 mapas con nombre y semilla fija**, con los recursos revisados (piedra según el tamaño). *(Los dos; el constructor pone la piedra primero)*
6. **Rendimiento sin picos en 1v1 y 2v2:** peor tick por debajo de 50 ms. *(Veterano)*
7. **Modo observador en vivo** (aunque sea con el retraso de la repetición). *(Constructor)*

### Para algo semiprofesional

1. Ranking con Elo y matchmaking por cola, con servidor de cuentas.
2. Anti-trampa: como mínimo, que el cliente no reciba lo que no ve (o verificación de comandos imposibles) y registro de anomalías.
3. Interfaz de observador: producción, economía y ejércitos comparados, tabla de puntos y cámara del caster.
4. Balance medido con partidas humanas (estadísticas de rankeadas por pueblo y por mapa), no con IA contra IA.
5. Legibilidad: siluetas por función que se lean de lejos, minimapa con puntos de 2 px y flechas de ejército.
6. Formatos con nombre: 1v1 rápido (sin maravilla, sitios desde el 15) y por equipos largo.
7. Herramientas para la comunidad: editor de mapas, workshop de mods y servidor dedicado.

## 3. Decisiones de diseño que hoy le restan competitividad

### Según el veterano

1. **La IV que no obliga a elegir.** Si todo se compra, gana el que más recursos juntó, no el que mejor eligió. Las escuelas excluyentes (aprobadas) y la élite cara arreglan eso.
2. **El hito de la II que bloquea la maravilla en silencio.** Una decisión de minuto 8 que te castiga en el 40 sin aviso es información escondida para el jugador, no para el rival. En competencia eso se lee como trampa del juego.
3. **Las auras de los hitos según el lugar** (+15 % de recolección cerca, cura y bonos de combate locales en la III y la IV). Son ventajas muy situacionales: la pelea la gana quien la provocó cerca de su hito, y el espectador no lo ve.
4. **La ventaja por cantidad que el micro no cubre.** Mientras 90 contra 20 sea siempre derrota y no haya forma de dar vuelta un combate con posición o manejo, el techo se queda bajo.

### Según el constructor

1. **Los recursos fijos del mapa** (1600 de piedra por jugador, 2 afloramientos). En partidas largas, quien gana la piedra gana la edad. Es azar de generación disfrazado: depende de dónde caen los afloramientos.
2. **El mercado como válvula obligatoria** (sin mercado, sin maravilla). Si es la única salida, la IV la decide la cotización, no la estrategia.
3. **La maravilla de 21 minutos de obra más 15 de cuenta.** Treinta y seis minutos de partida resuelta son mortales para el público. El acortamiento aprobado ayuda.
4. **La niebla sin forma de leer al rival:** no hay vista de edad ni de hito del otro en la barra superior, cosa que AoE4 sí muestra. Esconde información que en la escena competitiva es pública.

## 4. Dónde coinciden y dónde no

**Coinciden en que:**
- la base técnica (simulación determinista, por comandos, repeticiones que funcionan, balance en datos) es la correcta y es lo más difícil de hacer bien;
- el bloqueo absoluto es H5: sin red, todo lo demás es teoría;
- el balance medido con IA no sirve para competir;
- la legibilidad para el que mira es la peor nota después de lo que no existe;
- la maravilla y la IV necesitan elección y contrajuego, y lo aprobado por el autor va en esa dirección.

**No coinciden en:**
- **La duración.** El veterano quiere un modo competitivo de 20 a 30 minutos y la maravilla fuera de los torneos de 1v1. El constructor quiere que el formato largo exista y compita como Arena en AoE2: «si todo es rush, el juego pierde lo que lo hace distinto».
- **Qué arreglar primero, después de la red.** Para el veterano, el techo de micro (comandos que faltan y legibilidad). Para el constructor, los recursos del mapa: «no hay torneo justo si la piedra decide».
- **El muro barato.** Al constructor le encanta la empalizada a 4 de madera el tramo. El veterano sospecha que en 1v1 entre humanos va a cerrar las partidas en un «todos amurallan y suben», como el viejo meta de Arena, y pide medirlo antes de que haya rankeadas.
- **La asimetría.** El veterano la quiere más marcada y más temprana (identidad antes del 15). El constructor prefiere que la economía común quede pareja primero.

**Veredicto compartido:** hoy es un buen juego para jugar contra la IA y un buen candidato a competir, pero está **a uno o dos años de trabajo** de un torneo amateur serio. Lo que falta no es contenido, es infraestructura (red, lobby, repeticiones con línea de tiempo, versión fija) y algunos ajustes de diseño. El veterano lo pone en 3 de 10 y el constructor en 3,5.
