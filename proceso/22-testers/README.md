# 22 · Jugadores de prueba (desde 2026-11-15 13:10)

## Pedido del autor
> "Generá un grupo de agentes que sean los jugadores testers del juego, y que nos hagan un feedback de qué les gustaría del juego y qué les parece que le falta para ser tan divertido como Age of Empires 4, y dejame todo eso en proceso. Continuá documentando y solucionando problemas que veamos con la telemetría."

## Cómo se hace
Cuatro agentes, cada uno con un perfil de jugador distinto. Un agente no puede jugar con mouse y pantalla como una persona; juega con lo que sí puede manejar:
- partidas con capturas a distintos minutos (`--shot`, `--cam`, `--select`, `--grilla`, `--panel`);
- IA contra IA para mirar ritmo y peleas;
- partidas guiadas por script con la API de la simulación (dar órdenes como un jugador y ver qué pasa);
- las campañas;
- la ayuda, los nombres y las descripciones del juego;
- la telemetría de sus propias partidas.

Ninguno toca código ni datos: solo escriben su informe y guardan sus capturas en `capturas/<perfil>/`.

| Perfil | Qué mira | Informe |
|---|---|---|
| Veterano de AoE4, competitivo | Ritmo, órdenes de construcción, macro, micro, atajos, información en pantalla | [01-veterano-aoe4.md](01-veterano-aoe4.md) |
| Nuevo en los RTS | Claridad, tutorial, primeras partidas, qué se entiende y qué frustra | [02-nuevo-en-rts.md](02-nuevo-en-rts.md) |
| Historia y estética | Pueblos, nombres, campañas, arte, sonido, si se siente cada cultura | [03-historia-y-estetica.md](03-historia-y-estetica.md) |
| Equipos y todos contra todos | 2v2, 3v3, 6 jugadores, mapas, estilos de IA, rejugabilidad | [04-equipos-y-ffa.md](04-equipos-y-ffa.md) |

Al final, una síntesis con lo que repiten varios y un plan priorizado: [00-sintesis.md](00-sintesis.md).

## Paso a paso
1. **(13:10) Etapa abierta;** los cuatro agentes trabajan en paralelo.
2. **(14:30) Llegaron dos informes.**
   - **Veterano de AoE4** ([informe](01-veterano-aoe4.md)):
     - **el ritmo de la edad I se parece a AoE4:** edad II a las 4:48 con una apertura limpia;
     - **la micro no paga:** los contadores multiplican el daño por 2 o más y kitear no sirve;
     - **la edad I no tiene decisiones:** no hay caza ni ganado, y el explorador no tiene trabajo;
     - **los hitos se levantan en menos de 1 minuto,** contra unos 3 en AoE4;
     - **faltan órdenes:** seleccionar todos los militares o los ociosos, patrullar, mantener posición, cola global;
     - **la IA se planta en 42 aldeanos en dificultad normal.**
   - **Historia y estética** ([informe](03-historia-y-estetica.md)):
     - **lo mejor son las campañas,** por sus narradores y sus fuentes;
     - **lo más grave:** los rivales históricos (Adal, Birmania, chankas, tupíes) juegan como "Invasores" europeos o con la cultura del jugador;
     - **no hay cambio por edad,** el ejército son maquetas blancas, no hay voces, y Etiopía no tiene música;
     - **nombres dudosos:** "Espingardeiro de resgate", "Inkarri" como edad, el Qorikancha en la edad IV;
     - **textos de prototipo** que rompen la inmersión.
   - **Errores concretos que encontraron**, que arreglo enseguida (paso 3):
     - el panel de la unidad muestra los valores de base, sin las mejoras;
     - `--shot` termina sin guardar la telemetría y con un volcado de memoria;
     - en IA contra IA salen los avisos de la IA del jugador 0;
     - "✓ ganada" se dibuja en vertical en la pantalla de campañas;
     - quedan textos "(… en el prototipo)" en los objetivos;
     - las demos y algunas misiones arrancan por encima del tope de población.
