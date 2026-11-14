# 20 · Telemetría (desde 2026-11-14 22:00)

## Pedido del autor
> "Si aún no hay, necesitamos un sistema de telemetría que nos pueda indicar problemas en el mapa, bugs, lugares que trancan a la IA o a las unidades, edificios que no se pueden construir, etc., para que podamos analizar seguido qué está pasando."

## Punto de partida
No hay telemetría. Lo más parecido son los libros de la simulación (`Sim.ledger`, `stats`) y las pruebas de humo, que solo dicen "trabado" o "no trabado" al final de la partida.

## Plan
1. Un registro de sucesos problemáticos que corre dentro de la simulación sin ser parte del estado (no entra en el hash). Registra:
   - unidades trabadas;
   - caminos que no llegan;
   - órdenes rechazadas, con su motivo;
   - edificios sin lugar;
   - aldeanos ociosos;
   - lugares donde la IA se repite sin avanzar;
   - picos de tiempo por tick.
2. Que se guarde en cada partida (jugada, IA contra IA y pruebas) en un archivo por partida.
3. Una herramienta que lo resuma: tabla por tipo y mapa de calor sobre el mapa, para encontrar los lugares problemáticos.
4. Que las pruebas largas (torneo, mapas) lo usen y dejen su informe en `proceso/`.

## Paso a paso
