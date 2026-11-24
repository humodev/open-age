# 28 — Modo nómade (nota de diseño, a futuro)

Pedido del autor al contestar C-48 (2026-11-21): la conquista sin hitos cuenta solo edificios, «que esto no nos perjudique a la hora de hacer un **modo nómade** donde los jugadores eligen el lugar de la base». Esta nota fija qué tiene que cumplir la regla de conquista para no cerrarle la puerta. No es una decisión ni un plan de etapa: el modo no está en el alcance actual.

## Qué sería
Cada jugador arranca con aldeanos (y quizás un explorador), sin centro. Recorre el mapa y funda su centro donde quiere. Como en el modo nómade de AoE2. Para Raíces tiene sentido propio: los mapuches sin capital, el tekoha guaraní que se muda y la corte etíope que se funda en otro lugar (C-17) ya juegan con esa idea.

## Lo que la regla de conquista ya permite
- **La conquista se mira por edificios, no por posiciones.** `Sim._check_victory` cuenta los edificios terminados de cada jugador (`counts_for_victory`). No mira `bases[pid]` ni la distancia al punto de partida. Un centro fundado en cualquier lugar cuenta igual.
- **Gracia hasta fundar (proceso/51).** Con `opts.sin_base_inicial`, nadie pierde por quedarse sin edificios hasta haber fundado el primero que cuenta (`players[pid].fundo`). Sin la opción, nada cambia: hoy todos arrancan con un centro terminado.
- **Sin hitos** (C-48 a): cuenta cualquier edificio terminado salvo muros, puertas, caminos, sitios y trampas. Con hitos: la capital, los hitos y lo marcado `cuenta_victoria` (el lof mapuche, D-023).

## Lo que falta para el modo
1. **La capital.** Con hitos, la capital es el centro que arma el generador (`capital = true`). El modo tendría que marcar como capital el primer centro que se funda; la corte etíope ya lo hace al fundarse (`sim.gd`, «corte nueva»).
2. **`bases[pid]` como ancla.** El generador y la IA usan `bases[pid]` para casi todo: recursos de casa, depósitos, defensa, punto de reunión, cacería. En el modo, `bases[pid]` tendría que pasar a ser el lugar fundado, y los recursos de casa no se pueden poner antes (o se reparten parejos por el mapa).
3. **La IA nómade.** Elegir un lugar: agua, arcilla, monte, distancia al rival. Es un problema propio (docs/08).
4. **Un tope de tiempo para fundar.** Si alguien nunca funda, la partida no termina por conquista. Propuesta: perder si no fundó a los N minutos (dato en `reglas.json`), o contar las unidades hasta fundar.
5. **Equidad.** `tests/equidad.gd` mide hoy la distancia a los recursos desde bases fijas. En el modo, mediría la riqueza del mapa por zonas.

## Qué no hacer en el resto del código
- No asumir que un jugador sin edificios está derrotado fuera de `_check_victory` (por ejemplo, en la IA o en la interfaz): preguntar por `players[pid].defeated`.
- No usar la distancia a `bases[pid]` como regla de la simulación (sí como ayuda de la IA).
