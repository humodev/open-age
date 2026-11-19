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
| 4 | Rendimiento con 7 u 8 jugadores: perfilado y arreglo | En curso |
| 5 | Sumidero en la IV (escuelas excluyentes, élite cara) y contrajuego a la maravilla | En curso |
| 6 | Muralla de piedra en la edad II (C-101) | **Integrado (7d20c11)**, [06](06-muralla-de-piedra.md)
- **Muralla de piedra:** tramo con 1800 de vida y armadura 6, 20 de piedra y 12 s de obra. Puerta y torre encima.
- **Arrastre:** igual que la empalizada.
- **Refuerzo:** arrastrar sobre la empalizada la refuerza.
- **Daño:** el ariete y la catapulta le pegan al 400 %; la tropa, 1 por golpe; los incendiarios, poco.
- **Por pueblo:** muro de la amba (Etiopía), pirca y punku (Tawantinsuyu), kamphaeng de ladrillo (Ayutthaya). Mapuches, guaraníes y Palmares quedan sin muralla, como en su diseño.
- **IA:** solo la difícil y la experta; amurallaron 6 de 16 jugadores, no «todos».
- **Pruebas:** mismo hash; asedio, casillas y autotest OK. Primera victoria: 2 de 3. |
| — | Pregunta a los jugadores: ¿qué tan lejos está de jugarse como esports? | **Hecho** ([informe](../22-testers/ronda-8/03-esports.md)):<br>• **Nota:** veterano 3/10, constructor 3,5/10. Falta infraestructura más que contenido.<br>• **Requisitos duros:** juego en red (H5), lobby con salas, repeticiones compartibles.<br>• **Desacuerdo:** 1v1 corto sin maravilla, o formato largo tipo Arena. |
