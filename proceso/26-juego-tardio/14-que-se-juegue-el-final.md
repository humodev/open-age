# Que se juegue el final

Fecha: 2026-11-17. Etapa 26. Responde al plan 2 de la [síntesis de la ronda 7](../22-testers/ronda-7/00-sintesis.md): las filas «Alta» 2 y 3 y la «Media» 1, que pidió el [veterano](../22-testers/ronda-7/01-veterano-aoe4.md#4-pedidos-por-gravedad).

> Pedido: que la victoria por sitios no cierre la partida antes de un mínimo, que la IA no se rinda demasiado pronto y que compre lo propio de su pueblo entre el minuto 10 y el 15. Meta: la IV en el 40–60 % de las partidas de 45 minutos y ninguna victoria por sitios antes del 25, salvo que el rival no dispute.

## Medición

`tools/maravilla_ia.gd`, 45 minutos, semillas 0 a 3 (24 partidas), de a dos procesos. Le agregué una línea por jugador con las mejoras propias (cuántas, cuántas hasta el 15 y el minuto de la primera) y las unidades propias que entrenó. Partida por partida: [pruebas/14-maravilla-ia-45.txt](pruebas/14-maravilla-ia-45.txt).

| | Antes (ab3c853) | Después (a81d2bc) |
|---|---|---|
| Partidas con la IV (algún jugador) | 15 de 24 (62 %) | 20 de 24 (83 %) |
| Jugadores en la IV | 18 de 48 (37 %) | 25 de 48 (52 %) |
| Terminan antes del 25 | 9: sitios 5 (20:08–24:41), rendición 3 (16:15–22:02), conquista 1 | 4: conquista 3 (14:08–24:14), rendición 1 (24:21) |
| Cómo terminan | abierta 8, sitios 8, rendición 6, conquista 2 | abierta 12, sitios 8, conquista 3, rendición 1 |
| Jugadores con alguna propia hasta el 15 | 21 de 48 | 32 de 48 |
| Primera compra propia (mediana) | 13,9 min | 12,8 min |
| Mejoras propias compradas (total) | 97 | 134 |
| Jugadores con 2 o más unidades propias | 8 | 19 (9 con las 3) |

Las victorias por sitios del después son al 25:00 justo (4) o entre el 36 y el 44 (4). Las del 25:00 son palizas: el que pierde sigue en la II y el que gana ya está en la IV, y en 10 minutos no recupera ningún sitio. Es el caso de «salvo que el rival no dispute».

La IV pasa de la meta si se cuentan partidas (83 %), pero cae dentro si se cuentan jugadores (52 %). Ahora las partidas duran más, así que la IV llega más seguido. No le bajé el ritmo a la IA para volver a la banda.

## Causas

1. **Sitios.** La cuenta de 10 minutos empezaba en cuanto alguien tenía los tres sitios. A los 10 u 11 minutos ya los tenía alguno, y con eso ganaba entre el 20 y el 24.
2. **Rendición.** La normal se rendía con 10 edificios perdidos en toda la partida, tropa enemiga en la base y menos del 33 % del ejército rival. Las casas que pierde en las incursiones suman a la cuenta. Así, a los 16 minutos se rendía con la capital entera.
3. **Propias.** Los guaraníes y los incas no compran mientras ahorran para el hito, y en la II casi siempre están ahorrando. Las demás apartaban la meta entera antes de comprar. Además, los galgueros incas no estaban en `ia_propias.unidades` y no salían nunca.

## Cambios

- `reglas.sitios.cuenta_desde_ms` = 900000: la cuenta no corre antes del minuto 15, así que nadie gana antes del 25:00. La toma y la renta no cambian. Queda `cuenta_edad_min` para pedir además una edad mínima del equipo, estilo AoE4 (sin usar). Se aplica en `sim_mods._sacred`.
- `rendicion.quedan_pct` = 60 en la normal, la difícil y la experta: además de lo anterior, tiene que quedarle como mucho el 60 % de los edificios que llegó a tener a la vez. La fácil no cambia.
- `reglas.ia_propias.temprana_desde_ms` = 600000 y `temprana_edad_max` = 2: desde el minuto 10, las propias de la II (cuestan entre 100 y 175) se compran aunque esté ahorrando, sin apartar la meta.
- Tawantinsuyu: los galgueros entran en `ia_propias.unidades` con `desde_edad: 3`. La clave nueva sirve para que, en la II, el orden quede igual que antes. Si los galgueros entraban al orden desde el principio, corrían el turno de `ia_unidades` (los boleadores) de la fácil, y la primera victoria bajaba de 3 de 3 a 1 de 3.
- `tests/opciones_partida.gd`: mide desde `cuenta_desde_ms` y comprueba que no se gane antes del 25.

## Pruebas

En [pruebas/14-pruebas.txt](pruebas/14-pruebas.txt), con main integrado:

- Determinismo OK, con el hash de main (2903543624).
- Bench: 9,67 ms de promedio.
- `opciones_partida`, `maravilla` y `facil_sitios`: OK.
- Primera victoria: 3 de 3 en la rama antes del merge, pero 1 de 3 después del merge. main solo da las mismas líneas (las semillas 7 y 21 no terminan), así que la baja viene de lo que integró main y no de esta etapa. Queda para revisar.

## Lo que no se hizo

- **La experta en la III antes del 15:00.** Sigue sin llegar. Con `tools/experta_edades.gd`, 2 de 12 jugadores llegan a la III antes del 15:00, y 9 de 12 llegan en 20 minutos, con un promedio cercano al 17. No lo forcé.
- **Las propias de la III y la IV** siguen saliendo tarde, porque dependen de condiciones (granjas, tropa) y de edificios que la IA hace tarde (el mercado o el kraal de Ayutthaya).
- **Textos:** el menú dice «10 minutos con todos» y no menciona el mínimo del 25. Queda para el frente de textos, porque esta etapa no toca `src/game`.
