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
| 1b | Comercio: mercados neutrales, comerciante, rutas y bloqueo ([diseño](../33-comercio/README.md)) | En curso |
| 1c | Rendimiento, paso 2: caminos de grupo y caché | En curso |
| — | Revisión de los expertos y torneo | Después de 1a y 1b |
