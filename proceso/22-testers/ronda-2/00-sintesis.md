# Síntesis de la segunda ronda (2026-11-15)

Los mismos cuatro jugadores, con la memoria de la primera ronda, jugaron la versión con lo de la etapa 23: combate con bonos y dos armaduras, animales y caza, órdenes y comodidades, aprender a jugar y rivales con civ propia. Informes: [veterano de AoE4](01-veterano-aoe4.md), [nuevo en los RTS](02-nuevo-en-rts.md), [historia y estética](03-historia-y-estetica.md), [equipos y todos contra todos](04-equipos-y-ffa.md). La primera ronda: [síntesis](../00-sintesis.md).

## Qué cambió entre una ronda y otra

| Tema | Primera ronda | Segunda ronda |
|---|---|---|
| Ritmo de la edad II | 4:48–6:53 | **4:30–4:49**, como AoE4 (unos 4:30) |
| Comida silvestre a 30 casillas | 1200 | **4800**; primera granja a las 11:32 (antes, 4:00) |
| Micro | "no paga": el contador perdía 1 unidad | **existe**: con foco al guerrero le quedan 6 de 10; kitear a la línea sale sin bajas |
| Comodidades | faltaban casi todas | **casi completas** (ociosos, cola global, M, T, Tab, mantener, patrullar, formaciones) |
| Jugador nuevo contra la fácil | pierde a los 8–9 minutos, sin saber por qué | primer ataque a las 15:20; **"ahora sí tengo ganas de seguir"**; igual pierde 5 de 6 |
| Tutorial | se traba | se gana haciéndole caso; falla con motivo |
| Rivales de campaña | "Invasores" europeos | **seis civs propias** con fuentes; "Rojo · Adal · Badlay" |
| Sitios en mapas de varios | islas con 1 | uno por jugador en todos los terrenos; el 3v3 en río dura 24:45 (antes 9:04) |
| Fortines con 8 | 439 bajas, 6 de 8 sin pelear | **1558 bajas**, termina por conquista |
| Tributo de la IA | 0–2 por partida | 3–11 en 2v2, 45 en 4v4 |

## Errores nuevos o que siguen (se arreglan ya)

| Error | Quién | Arreglo |
|---|---|---|
| La IA fácil estaciona el ejército en el centro, donde hay un sitio en 1 contra 1: gana por sitios sin buscarlos | Nuevo | La fácil se reúne cerca de su base |
| Un aldeano mandado a un animal suelto lo reclama y se queda ocioso al lado | Veterano | Reclamar y carnear en la misma orden |
| Al terminar la carne, el aldeano va a los arbustos en lugar del animal siguiente | Veterano | Carnear en cadena: el próximo animal propio cercano |
| Los sueltos "cerca" están a unas 5 casillas: los reclaman los aldeanos al pasar y el explorador no tiene trabajo | Veterano | Llevarlos a 10–15 casillas |
| Todas las misiones arrancan por encima del tope de población | Historia, veterano | Revisar la población inicial de cada misión |
| `tutorial_letra --modo=indefenso` queda abierta: con el combate nuevo sobreviven 2 aldeanos | Nuevo | Ajustar la prueba (no es una falla del juego) |
| La bengala de ataque llega 1 de 4 veces; las tropas se quedan a mitad de camino | Equipos | Revisar el envío (grupo, camino) y avisar si no se puede |
| La IA aliada no defiende si a ella también la atacan, y no lo dice | Equipos | Defender igual con una parte, y decirlo |
| "Te mando 200" llega como 160 sin explicar la comisión | Equipos | Decirlo en la frase |
| El todos contra todos con 6 sigue abierto a los 60 minutos; Palmares junta más del doble que el siguiente | Equipos | Es balance: Palmares (88 % en el torneo) |
| El volcado de memoria al cerrar tras `--shot`, ahora en 4 de 4 capturas | Todos | Sigue sin causa encontrada; dentro del motor |

## Lo que más piden ahora, juntando los cuatro

1. **Hitos con ventana de riesgo** (190/220/250 s), ya decidido (C-33) y pendiente.
2. **Sitios sagrados a 10 minutos** (hoy 5; en AoE4, 10). Dos jugadores perdieron con 70 militares vivos.
3. **Opciones de partida:** sitios sí o no, tiempo límite, conquista; también para el jugador nuevo.
4. **Que la mezcla de línea y distancia pague,** y una unidad que pueda kitear al choque.
5. **IA experta** que llegue a 80–100 aldeanos.
6. **Identidad visual y sonora** (historia): voces, aspecto por edad, modelos de tropas, torres según el pueblo (hoy casi todas almenadas a la europea), siluetas propias para los animales y caza por región (guanaco, pecarí, tapir).
7. **Europeos separados por potencia** (holandeses, franceses, paulistas), C-44.
8. **Arte de la guerra** (C-38), y marcar la campaña para empezar.

## Plan

1. **Ya:** los errores de la tabla, que no mueven el balance.
2. **Después:** hitos de 190/220/250 s y sitios a 10 minutos. Son de AoE4 y ya están pedidos; se miden con torneo.
3. **Balance con todo junto:** Palmares (88 %) primero, y los mapuches (edad III tardía).
4. **Lo grande:** IA experta, mejoras por unidad, una unidad que kitee, opciones de partida, y arte y sonido con los créditos del mes.
