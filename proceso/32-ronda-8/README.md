# 32 · Lo que sale de la octava ronda

Trabajo que decidió el autor a partir de la [síntesis de la ronda 8](../22-testers/ronda-8/00-sintesis.md).

| Frente | Qué | Estado |
|---|---|---|
| 1 | IA de equipo con ataques escalonados; la IA usa el mercado | **Integrado (afd6474)** · [01](01-ia-equipo-y-mercado.md)<br>**Turnos de ataque:** una IA no sale mientras dura la oleada de una aliada, ni 45 s después de que llegó; si una aliada ya va a un edificio, va a otro frente. Bengala, defensa, hito y maravilla no esperan.<br>**Mercado:** compra lo que le falta para el hito o la maravilla, desde la II.<br>**Resultados:**<br>• 1v3: el pico de enemigos junto a la capital baja de 55 a 39, y llegan cada 1–3 min (antes, tres en 11 s).<br>• 1v6: salen una por minuto.<br>• Con el mercado, la etíope llega a la III a los 18:41 (antes se quedaba en la II).<br>• Mismo hash. Primera victoria: 2 de 3. |
| 2 | Recursos del mapa: cantidad y lugar, comparados con AoE4 y AoE2, y que escalen con el tamaño | **Integrado (34bed45)** · [02](02-recursos-del-mapa.md)

**Antes**
- La piedra era de 1 600 por jugador, toda en casa.
- La III, la IV y la maravilla piden 2 100.
- En el 1v1, a veces había solo 800.
- Como referencia, AoE2 Arabia trae ~3 150 y AoE4 ~5 000, y en esos juegos las edades no piden piedra.

**Ahora**
- 4 000–5 100 de piedra por jugador: en casa, una veta propia y vetas disputadas entre bases.
- Escala con el tamaño y la cantidad de jugadores; cada terreno tiene su `minerales_pct`.
- Vetas nuevas en la III y la IV.
- La riqueza va de 3 000–4 300 a 4 700–6 000.

**Resultado**
- En un 2v2 de 45 min, nadie se traba por piedra.
- Hash nuevo: 718068252.
- Primera victoria: 2 de 3. |
| 3 | Cola de producción siempre a la vista, en rojo cuando está trabada; menos mensajes | **Integrado (44db138)**, [03](03-menos-mensajes-cola-visible.md):<br>• **Cola global:** siempre visible; en rojo y con candado cuando está trabada (el motivo, en la ayuda); en gris cuando está quieta.<br>• **Avisos:** los de gestión pasan a «Consejos de aprendizaje» (tutorial y fácil). Quedan los de AoE4 (ataque, edad, investigación, aliado, maravilla).<br>• **Mensajes en 15 min:** de 96 a 38 en el 1v3, de 130 a 62 en el 2v2. Desaparecen los 292 «Población llena».<br>• **Maravilla:** la ficha dice qué hito pide.<br>Mismo hash; autotest OK |
| 4 | Rendimiento con 7 u 8 jugadores: perfilado y arreglo | **Integrado (2504148)**, [04](04-rendimiento.md)

**Qué pesaba:** la IA, el 40–44 % del tiempo. Todas las IA pensaban en el mismo tick y recorrían el mapa entero unas 36 veces cada vez.

**Cambios:**
- Las IA piensan en ticks repartidos. Solo cambia el resultado con 3 o más IA.
- Listas de entidades por dueño y por tipo.
- La amenaza y el aura se calculan una vez por tick.

**Resultados** (promedio / p95 en ms):

| Partida | Antes | Después |
|---|---|---|
| 1v6 | 20,6 / 80 | 12,1 / 25 |
| 4v4 | 62,9 / 273 | 35,7 / 67 |

- 1v6: los ticks de más de 100 ms bajan de 142 a 0, y el ×4 alcanza en toda la partida.
- 4v4: quedan picos por los caminos. Cada 5 ticks una IA vuelve a mandar a todo su ejército, y cada soldado recalcula su camino.
- La meta del p95 por debajo de 40 ms con 8 jugadores no se cumple.

**Pruebas:** mismo hash en 1v1 (718068252); el bench mejora; el autotest da OK. |
| 5 | Sumidero en la IV (escuelas excluyentes, élite cara) y contrajuego a la maravilla | **Integrado (d8f2cac)**, [05](05-sumidero-iv-y-maravilla.md)

**Sumidero en la IV**
- Escuela con caminos excluyentes (guerra, asedio, obras).
- Cada camino tiene una mejora repetible 5 veces, a costo creciente.
- Guardia: élite común de 400 de alimento.
- La IA elige un camino y gasta en el sumidero.

**Contrajuego a la maravilla**
- Marca en el minimapa para todos y cuenta con «FRENALA».
- La IA la ataca antes que a los sitios.
- La obra con 10 constructores baja de 10 a 6 minutos.

**Medido** (2v2, una semilla)
- El alimento sin gastar en la IV baja de 7 388 a 5 545 en promedio.
- La IA no entrenó guardias porque estaba al tope de población. Falta que venda lo que le sobra en ese caso.

**Al fusionar:** conflicto en `iconos.gd` con la muralla; quedaron las dos. Mismo hash, íconos (143 distintos) y autotest OK. |
| 6 | Muralla de piedra en la edad II (C-101) | **Integrado (7d20c11)**, [06](06-muralla-de-piedra.md)
- **Muralla de piedra:** tramo con 1800 de vida y armadura 6, 20 de piedra y 12 s de obra. Puerta y torre encima.
- **Arrastre:** igual que la empalizada.
- **Refuerzo:** arrastrar sobre la empalizada la refuerza.
- **Daño:** el ariete y la catapulta le pegan al 400 %; la tropa, 1 por golpe; los incendiarios, poco.
- **Por pueblo:** muro de la amba (Etiopía), pirca y punku (Tawantinsuyu), kamphaeng de ladrillo (Ayutthaya). Mapuches, guaraníes y Palmares quedan sin muralla, como en su diseño.
- **IA:** solo la difícil y la experta; amurallaron 6 de 16 jugadores, no «todos».
- **Pruebas:** mismo hash; asedio, casillas y autotest OK. Primera victoria: 2 de 3. |
| — | Pregunta a los jugadores: ¿qué tan lejos está de jugarse como esports? | **Hecho** ([informe](../22-testers/ronda-8/03-esports.md)):<br>• **Nota:** veterano 3/10, constructor 3,5/10. Falta infraestructura más que contenido.<br>• **Requisitos duros:** juego en red (H5), lobby con salas, repeticiones compartibles.<br>• **Desacuerdo:** 1v1 corto sin maravilla, o formato largo tipo Arena. |
