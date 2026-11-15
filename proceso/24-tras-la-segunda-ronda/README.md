# 24 · Después de la segunda ronda de jugadores (desde 2026-11-15 16:30)

## Pedido del autor
> "Ok, vayamos uno a uno en esos puntos, completemos los 4 puntos grandes en orden:
> 1. The new bugs.
> 2. Landmarks and sites at 10 minutes.
> 3. Balance with everything together: Palmares at 88 % first, then the slow Mapuches.
> 4. The big items: expert AI, match options, art and sound.
>
> Al concluir los 4 ítems, volvamos a consultar a los jugadores."

La lista sale de la [síntesis de la segunda ronda](../22-testers/ronda-2/00-sintesis.md).

## Plan
| # | Qué | Prueba |
|---|---|---|
| 1 | **Errores nuevos:** IA fácil en el centro; aldeano que no carnea el animal suelto; carnear en cadena; sueltos más lejos; misiones por encima del tope de población; prueba del tutorial indefenso; bengala que no llega; aliado que no defiende si lo atacan; comisión del tributo sin explicar; frases de la IA fuera del registro; tributo de la IA demasiado temprano | Una prueba por error, determinismo, autotest |
| 1b | **Eficiencia de la IA** (pedido del autor, mirando IA contra IA: "la IA no hace almacenes para cortar madera, sino que sigue mandando gente a hacer madera súper lejos y depositándola en la plaza central, en lugar de gastar un poco de madera para hacer un almacén cerca"). Medir la distancia de cada viaje de recolección por recurso y por jugador, arreglar la IA y sumar la medida a la salud de la IA | Telemetría de viajes, `tests/salud_ia.gd` con distancia de viaje por recurso |
| 2 | **Hitos de 190/220/250 s y sitios a 10 minutos**, como AoE4 | Edades en paz, salud de la IA, torneo |
| 3 | **Balance con todo junto:** Palmares (88 %) primero, después los mapuches (edad III tardía) | Torneos de 5 semillas en paralelo, un cambio por vez |
| 4 | **Lo grande:** IA experta, opciones de partida, arte y sonido | Salud de la IA por dificultad, autotest, capturas |
| — | **Tercera ronda** con los mismos cuatro jugadores | Informes y síntesis comparada |

## Paso a paso

### Paso 1: los errores de la segunda ronda

| Error | Arreglo | Prueba |
|---|---|---|
| La IA fácil estaciona el ejército en el centro (en 1 contra 1 hay un sitio ahí) | `_map_spot` suma el centro del mapa solo si el nivel toma sitios (`dificultades.facil.toma_sitios: false`) | IA fácil contra IA: se queda en su punto de reunión |
| El aldeano mandado a un animal suelto lo reclama y queda ocioso | Reclamar y carnear en la misma orden | `tests/jugabilidad.gd`: aldeano a un animal suelto |
| Al terminar la carne, el aldeano va a los arbustos | Carnear en cadena: el animal propio más cercano dentro de `animales.cadena_radio` (10 casillas) | `tests/jugabilidad.gd`: 0 llamas quedan en pie |
| Los sueltos "cerca" estaban a 5 casillas | A 15 casillas en mapas de 2 y a 14 en los de varios | Explorador con trabajo; los aldeanos no los reclaman al pasar |
| Las misiones arrancan por encima del tope de población | `pob_extra`: lo que la misión pone de más se suma al tope (sin pasar `pob_max`) | Misiones sin el aviso de población excedida |
| `tutorial_letra --modo=indefenso` quedaba abierta | La prueba levanta el hito con los aldeanos que queden (sobreviven 2 con el combate nuevo); no era una falla del juego | Gana en los dos modos: letra 9:48, indefenso 11:04 |
| La bengala llega 1 de 4 veces | Las tropas que van a una bengala ya no se desvían: ni las incursiones (tomaban unidades en movimiento), ni la correa de los estilos que no entran a la base rival, ni la ayuda al aliado (`_at_flare`) | `tests/ordenes.gd`: "bengala: llegan 4 de 4" (3 minutos) |
| El aliado no defiende si a él también lo atacan, y no lo dice | Con las dos amenazas, `equipos.ia_ayuda_parte_pct` (33 %) va al aliado y el resto a casa; dice "Voy a defenderte con N" | `tests/equipos.gd` |
| "Te mando 200" llega como 160 sin explicar | "Te mando 200 de madera: llegan 160, el resto se pierde en el camino" (`{llegan}` con la misma cuenta que la simulación) | Autotest |
| Las frases de la IA no quedaban en el registro | También van al registro de sucesos (F5) con el color del aliado | Autotest |
| La IA daba tributo a los 3:00 | `equipos.ia_tributo.desde_ticks`: no antes de los 8 minutos | `tests/equipos.gd` (tributos por partida) |

### Paso 1b: eficiencia de la economía de la IA

**Medida nueva.** La telemetría anota cada viaje de un aldeano lleno: casillas del recurso al depósito más cercano, por jugador y recurso (`SimTelemetry.trip`, `viajes` en la cabecera del JSONL). Lo muestran:
- `tools/viajes.gd`: tabla por tramos de 5 minutos con los depósitos de cada uno;
- el informe de `tools/telemetria.gd`: sección "Viajes al depósito";
- `tests/salud_ia.gd`: falla si la madera viaja más de 12 casillas de media.

**Qué se vio** ([antes](pruebas/01-viajes-antes.txt), 10 partidas de IA contra IA):
- La mayoría de las civs hace leñeras y viaja 1–4 casillas.
- **Ayutthaya** no tiene leñera (su depósito es el elefante del rey) y lleva la madera a 2–7 casillas. Seguido minuto a minuto, el elefante está en el centro del grupo de leñadores. La distancia sale de 9–14 leñadores repartidos alrededor de un solo elefante (el segundo, desde el minuto 10, va al alimento). No es un error, es el diseño de la civ.
- El ciclo de almacenes de la IA cortaba en el primer recurso lejano aunque no construyera nada. Si el alimento lejano iba primero y no alcanzaba la madera o no había lugar, la madera se quedaba sin almacén.
- El tope era de 4 almacenes por tipo, contando los que quedaron junto a un bosque ya talado. Cuando el bosque se corría, no se hacía uno nuevo y los aldeanos volvían a caminar hasta el centro, que es lo que vio el autor.

**Arreglo:**
- Los recursos se ordenan por cuántos aldeanos trabajan lejos, y la madera compite igual que el resto.
- Si no hay lugar, se pasa al recurso siguiente; si no alcanza, se espera.
- Solo cuentan los almacenes con ese recurso todavía cerca: `ia_economia.almacen_utiles` (3), con un tope total de `almacen_max` (8).
- El elefante se reacomoda cuando el grupo se aleja más de 3 casillas (`ia_economia.elefante_cerca`; antes, 6).

**Después** ([medida](pruebas/02-viajes-despues.txt)):
- Madera a 1–4 casillas en todas las civs.
- Ayutthaya sigue en 2–7 casillas, por lo dicho del elefante.
- Los guaraníes llegan a 7–8 leñeras a los 25 minutos porque los bosques se corren.

### Pruebas del paso 1
- **Determinismo:** OK. **Rendimiento:** 8,35 ms de promedio con 200 unidades (presupuesto 100). **Jugabilidad, órdenes, civs y autotest:** OK ([resultados](pruebas/)).
- **Autotest:** la revisión de la cola global miraba 6 cuadros después de la orden. Con la máquina cargada, la orden todavía no había entrado. Ahora espera a que entre (hasta un segundo) y da población extra para que el tope no la frene.
- **Equipos:** los dos 2v2 sin fuego amigo y con 7 tributos en 30 minutos; antes había tributo desde los 3 minutos. El 3v3 y el todos contra todos no llegaron a correr dentro del tiempo de la prueba en paralelo.
- **[Salud de la IA](pruebas/03-salud-ia.txt):**
  - En el commit anterior fallaban 3 civs: guaraníes (ejército de 4, sin mercado), Palmares (sin mercado) y Ayutthaya (edad II a las 10:31).
  - Ahora fallan 2, las del mismo par: Palmares termina con Ayutthaya antes del minuto 12. Es el desbalance del paso 3 (Palmares 88 %), no un error de este paso.
  - La madera viaja 1–2 casillas en todas las civs.

## Tropiezos
- `var alt := dict.get(...).has(...)` no compila: Godot no infiere el tipo de lo que sale de un `get`. Hay que escribir el tipo, y una IA que no compila deja la prueba colgada hasta el tiempo límite.
- El primer "después" de Ayutthaya parecía un arreglo y no lo era: las cifras eran iguales a las de antes. Seguir al elefante minuto a minuto mostró que ya estaba junto a los leñadores. Se corrigió el texto en lugar de declarar una mejora.
