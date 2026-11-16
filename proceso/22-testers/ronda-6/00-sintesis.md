# Síntesis de la sexta ronda (2026-11-16)

Jugaron el veterano de AoE4 y el jugador nuevo sobre main en `d54e949`. Informes: [veterano](01-veterano-aoe4.md) y [nuevo en los RTS](02-nuevo-en-rts.md). Ronda anterior: [quinta](../ronda-5/00-sintesis.md).

## Lo que cambió

- **El jugador nuevo le gana a la fácil por primera vez en seis rondas.**
  - Con el plan (ahorrar en la edad I, hito a los 8 min, taller a los 11, atacar con 15 soldados y 2 arietes), gana 3 de 4 semillas por rendición, entre las 17:38 y las 29:05.
  - Sin ahorrar, pero con arietes, también gana (26:59). Sin asedio, no.
  - "Ganarle a la fácil en la segunda o tercera partida y entender por qué es lo que hace volver."
- **La elección de blancos es "lo mejor de la ronda"** (veterano).
  - El ataque en movimiento va primero a los militares, después a los aldeanos, a los centros que tiran flechas y al final a los almacenes.
  - El ataque del veterano al minuto 12 hundió a la experta: de 36 aldeanos a 20, y 165 bajas.
  - Las bajas del jugador nuevo por ataque bajan de 36–50 a 4–37.
- **Micro C2 intacta:** la mezcla gana 3 de 3, y escalonar y kitear a la línea pagan.
- **Arreglos de la ronda 5: todos bien en los dos informes.** El autotest da 112 de 112.

## Lo que sigue, por gravedad

| Gravedad | Qué | Quién |
|---|---|---|
| **Alta** | El consejo de la pelea perdida (`consejos.gd`) y la hoja de atajos dicen que "A y clic ataca lo primero que ve": desde la elección de blancos no es cierto y enseña a no usar la orden que ahora anda bien | Veterano |
| **Alta** | La experta sube lento de edad (una sola edad III en 6 jugadores a los 20 min) y es frágil al expandirse | Veterano |
| Media | El resumen de la pelea en tres renglones cortos (hoy, seis de letra chica) | Nuevo |
| Media | La hoja de atajos no dice que Alt muestra qué es cada edificio; Alt también sobre las unidades | Ambos |
| Media | Festejar la primera victoria e invitar a la Normal; misiones o "arte de la guerra" que enseñen el plan | Nuevo |
| Media | Z X C V son formaciones en la grilla militar e hitos en la del aldeano: con los dos elegidos, ¿cuál gana? | Veterano |
| Baja | "Edad II" ya no se corta, pero se perdió la palabra "hito"; el chequeo "cuenta grande de sitios del rival" del autotest falla a veces con la máquina cargada | Ambos |
| — | Se cae al cerrar (código 134) | Ambos: sigue sin causa encontrada, está dentro del motor |

## Plan

1. Interfaz de la ronda 6 (6a): textos, resumen corto, Alt, festejo e invitación, Z X C V, chequeo inestable.
2. Experta (6b): defenderse al expandir y subir de edad a tiempo.
3. Torneo 29 (elección de blancos) y rebalance si hace falta.
