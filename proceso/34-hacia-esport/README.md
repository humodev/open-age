# 34 · Hacia un diseño de esport

> Pedido del autor (2026-11-19): «Iterá al menos dos veces, hasta que estemos cerca de un esport en cuanto a diseño.»

Cada iteración tiene tres pasos:
1. Implementar.
2. Los dos expertos (veterano competitivo y constructor) juegan y revisan la competitividad del diseño: diversidad de estrategias, contrajuego, información, control del mapa, techo de habilidad, ritmo, asimetría y varianza, con la misma vara que en [ronda-8/04](../22-testers/ronda-8/04-jugabilidad-competitiva.md).
3. Ajustar.

Al final de cada iteración se mide el balance con un torneo.

## Iteración 1

| Frente | Qué | Estado |
|---|---|---|
| 1a | Triángulo más marcado, lancero en la I, sitios que paguen, asedio de área esquivable y ataque al suelo | **Integrado (57fcb7f)**, [01a](01a-cambios-competitivos.md). Hash 3870415820. Primera victoria 2 de 3.

**Triángulo:**
- Línea: +6 contra el choque y +6 contra lo montado. +12 contra todo el choque se descartó porque bajaba la primera victoria.
- Distancia: +6. Choque: +8.
- 1 lancero contra 1 jinete: de 0/5 a 4/5.

**Lancero en la I:** todos los pueblos lo tienen, con su nombre.

**Sitios:** 60/45/30 de riqueza, y se toman desde la II.

**Asedio de área:**
- Contra tropa, el tiro tarda 8 ticks en llegar: esquivar paga (de 0/5 a 5/5 con un bot que esquiva perfecto).
- Ataque al suelo en R, que también usa la IA (D-031).
- La micro C2 queda intacta. |
| 1b | Comercio: mercados neutrales, comerciante, rutas y bloqueo ([diseño](../33-comercio/README.md)) | **Integrado (c9b6c97)**, [implementación](../33-comercio/02-implementacion.md). Hash 916860075.<br>• Los 8 pasos hechos: siempre 2 o más mercados neutrales (equidad: 3 % en el peor caso); comerciante con ganancia por distancia, cobrada al volver; bloqueo y avisos; ruta con línea y punto de paso; bonos de cada pueblo; IA que comercia, protege y corta rutas; maquetas.<br>• Metas: en 1v1, 13–14 % de la riqueza antes del minuto 25 (se cumple); en 2v2, 28 % después del 30 (la meta era 30–45 %; en una semilla le mataron 40 comerciantes).<br>• La primera victoria del principiante había bajado a 3 de 8 semillas (antes, 6 de 8): los dos neutrales corrían en 2 los ids de todo lo demás y con eso la fase de los `(tick + id) % k`. Con ids aparte vuelve a 6 de 8; hash 289763931 ([01d](01d-primera-victoria-mercados.md)). |
| 1c | Rendimiento, paso 2: caminos de grupo y caché | **Integrado (f480427)**, [07](../32-ronda-8/07-rendimiento-caminos.md)
- **Caché de caminos:** por región, y la IA no vuelve a mandar a quien ya iba al mismo lugar.
- **4v4:** promedio de 46,9 a 40,6 ms, p95 de 100 a 77 ms; los ticks de más de 100 ms bajan de 1232 a 22.
- **1v6:** p95 de 60 a 33 ms.
- **Caminos:** ya son el 1 % del tick. Lo que pesa ahora es el costo por entidad (IA, recolección, movimiento).
- **Pendiente:** la meta de p95 < 40 ms con 8 jugadores. El bench de 6 IA empeora su peor tick por `_expansion_site`.
- **Al fusionar todo:** hash **1417676642**; comercio, equidad y jugabilidad OK. |
| — | **Torneo 40** ([resultados](pruebas-it1/40-torneo-iteracion-1.txt)), con todo junto | Tawantinsuyu 42, mapuches 54, guaraníes 58, Etiopía 56, Palmares 48, Ayutthaya 42 %.<br>• **Banda:** todas entre 42 y 58 %, la más pareja de todo el proyecto (el torneo 39 daba 34–64).<br>• **Edad IV:** aparece en 86 de 150 partidas de 30 minutos (antes, 5 a 16).<br>• **Por destrucción:** bajan de 60–80 a 39; se juega más tiempo y gana más el que lleva ventaja en puntos. |
| — | Revisión de los expertos | En curso |
