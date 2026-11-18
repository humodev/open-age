# Síntesis de la séptima ronda (2026-11-17)

Jugaron el veterano de AoE4 y el jugador nuevo sobre main en `da4d074`, con el juego tardío completo salvo el paso 5, los costos por recurso, los íconos y estados, y los soldados animados. Informes: [veterano](01-veterano-aoe4.md) y [nuevo en los RTS](02-nuevo-en-rts.md). Ronda anterior: [sexta](../ronda-6/00-sintesis.md). Por el límite de uso, fue una ronda corta: dos jugadores e informes de 120 líneas como máximo.

## Lo que mejoró

- **Grilla nueva: "se entiende sin leer"** (los dos).
  - La franja de color dice la edad.
  - El ámbar con «−50» dice lo que falta.
  - El rojo aparece solo cuando de verdad no se puede.
- **La herrería al estilo AoE4 da decisiones en la II:** el script del veterano compró 10 cosas entre las 5:07 y las 12:09.
- **La experta se defiende:** aguantó el ataque del veterano de 62 unidades al minuto 14 y pasó de 50 a 64 aldeanos (en la ronda 6 quedaba en 20).
- **El cierre ya no se cae:** código 0 en todas las corridas de los dos.
- **De la ronda 6 quedaron bien** el consejo de «A y clic», el aviso de la pelea en tres renglones, Alt en la hoja de atajos y el festejo de la primera victoria.

## Lo que sigue, por gravedad

| Gravedad | Qué | Quién |
|---|---|---|
| **Alta** | **El jugador nuevo ya no le gana a la fácil:** 0 de 2 con su plan (en la ronda 6, 3 de 4). Los honderos le tiran todos los arietes: 10 de 10 en la semilla 21. Según los datos, la distancia le hace 15 % al asedio, así que hay que buscar la causa. Puede ser algo del paso 4 (ariete con más ataque pero sin niveles comprados, aura de los hitos militares cerca de la capital rival) o la herrería de la fácil | Nuevo |
| **Alta** | **El juego tardío casi no se juega en sus partidas:** 5 de 6 terminan entre los 16 y los 26 minutos (por sitios, rendición o conquista), y llegó a la IV 1 de 12. El 61 % del paso 7 se midió con 3 semillas, así que hay que mirar la dispersión. Pide que la victoria por sitios no cierre la partida antes de la IV, con un mínimo de minutos o una cuenta que crezca con la edad | Veterano |
| **Alta** | La experta llega a la III a los 18,2 minutos de promedio; la meta es antes de los 15:00 | Veterano |
| Media | **La IA compra tarde lo propio de su pueblo:** casi todo después del minuto 20. El capitão de mocambo, la kona y Suan Phlu no salieron nunca | Veterano |
| Media | **Qué comprar primero:** el cuartel en la III tiene 9 mejoras. Pide una estrellita de «recomendado» y nombres que distingan «Línea veterana» de «Choque veterano» | Nuevo |
| Media | La grilla del cuartel está llena en la III (12 de 12): no se ve dónde entra lo de la IV | Veterano |
| Media | Unas 114 notas «[verificar…]» de `data/` se le muestran al jugador | Nuevo |
| Media | Al final sobra madera (17 934 quieta al minuto 35), porque todo lo tardío pide alimento y riqueza. Parte es culpa del script, que pone las granjas tarde y no usa el mercado | Veterano |
| Baja | Nombres cortados («aller de asedio») y el texto en ámbar demasiado apagado | Nuevo |

## Plan

1. ~~Error de los arietes y la primera victoria~~ **Hecho (6f):** la fácil no compra los niveles de la herrería; la primera victoria vuelve a 3 de 3.
2. **Que se juegue el final:**
   - la victoria por sitios con un mínimo según la edad;
   - medir la IV con más semillas;
   - que la IA compre lo propio antes.
3. **Usabilidad:**
   - quitar del texto que ve el jugador los «[verificar]», que quedan solo en los documentos;
   - «recomendado» en la grilla;
   - nombres sin cortar.

## Análisis de fluidez del veterano (pedido del autor)

[Informe completo](03-veterano-fluidez.md).

**La base ya está a la altura de AoE4:** grupos, cola con Mayús, formaciones, cola global, cursores, Alt y marcadores. El autotest da 147 de 147 y la batalla de 60 tropas corre a 59–92 fps.

**Lo que más pesa:**
1. **Cimientos encadenados:** se construye solo el último, y los que quedan a más de 10 casillas no los levanta nadie.
2. **Sonidos:** no hay sonido al elegir ni al apoyar un cimiento.
3. **Producción parada:** no hay aviso cuando un edificio deja de producir.
4. **«¡Nos atacan!»:** el aviso es genérico, uno cada 15 s.
5. **La cola de producción:** se sacan unidades con clic derecho y el tope pasa de 5 a 10.
6. **El muro arrastrado:** muestra tramos y costo.
7. **Granjas:** se pegan al depósito.

**Paquetes propuestos:**
- **A · Respuesta inmediata:** sonidos y destellos.
- **B · Producción.**
- **C · Constructor.**
- **D · Avisos por zona.**
- **E · Órdenes finas.**
- **F · Pulido de lectura.**

A y B no tocan la simulación y son los que más cambian la sensación.
