# 32 · Lo que sale de la octava ronda

Trabajo que decidió el autor a partir de la [síntesis de la ronda 8](../22-testers/ronda-8/00-sintesis.md).

| Frente | Qué | Estado |
|---|---|---|
| 1 | IA de equipo con ataques escalonados; la IA usa el mercado | En curso |
| 2 | Recursos del mapa: cantidad y lugar, comparados con AoE4 y AoE2, y que escalen con el tamaño | En curso |
| 3 | Cola de producción siempre a la vista, en rojo cuando está trabada; menos mensajes | **Integrado (44db138)**, [03](03-menos-mensajes-cola-visible.md):<br>• **Cola global:** siempre visible; en rojo y con candado cuando está trabada (el motivo, en la ayuda); en gris cuando está quieta.<br>• **Avisos:** los de gestión pasan a «Consejos de aprendizaje» (tutorial y fácil). Quedan los de AoE4 (ataque, edad, investigación, aliado, maravilla).<br>• **Mensajes en 15 min:** de 96 a 38 en el 1v3, de 130 a 62 en el 2v2. Desaparecen los 292 «Población llena».<br>• **Maravilla:** la ficha dice qué hito pide.<br>Mismo hash; autotest OK |
| 4 | Rendimiento con 7 u 8 jugadores: perfilado y arreglo | En curso |
| 5 | Sumidero en la IV (escuelas excluyentes, élite cara) y contrajuego a la maravilla | Segunda tanda |
| 6 | Muralla de piedra en la edad II (C-101) | Segunda tanda |
| — | Pregunta a los jugadores: ¿qué tan lejos está de jugarse como esports? | **Hecho** ([informe](../22-testers/ronda-8/03-esports.md)):<br>• **Nota:** veterano 3/10, constructor 3,5/10. Falta infraestructura más que contenido.<br>• **Requisitos duros:** juego en red (H5), lobby con salas, repeticiones compartibles.<br>• **Desacuerdo:** 1v1 corto sin maravilla, o formato largo tipo Arena. |
