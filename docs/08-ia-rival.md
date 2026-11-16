# 08 — IA rival

## Principios

1. **La IA juega con las mismas reglas.** Emite comandos como un jugador, por la misma vía (`06-arquitectura.md`). No hace trampa en recursos ni en producción.
2. **Corre dentro de la simulación** y es determinista, para que las partidas IA contra IA sean reproducibles y sirvan como prueba (`01`, "Verificación").
3. **Las aperturas son datos.** Una apertura es un perfil con prioridades y umbrales; la IA no tiene órdenes de construcción escritas en el código. Así se pueden enfrentar aperturas distintas y buscar una dominante (`01`, test de las tres aperturas).
4. **Visión**: en H1 la IA ve todo el mapa porque todavía no hay niebla (`05`). Desde H2 solo usa lo que ve o recuerda.

## Estructura

La IA piensa una vez por segundo de juego y reparte su atención en gerentes:

| Gerente | Responsabilidad |
|---|---|
| Economía | Reparte aldeanos según la proporción de recursos del perfil; construye granjas cuando se agotan los arbustos |
| Construcción | Casas antes de llenar la población; depósitos cerca de recursos lejanos; edificios militares según el perfil |
| Avance | Construye el hito de la siguiente edad cuando se cumplen las condiciones del perfil |
| Ejército | Mantiene las colas llenas y elige la mezcla de funciones mirando la composición enemiga (triángulo, `05`) |
| Ataque y defensa | Defiende si hay enemigos cerca de su base; ataca en oleadas crecientes cuando su ejército supera un umbral |

## Perfiles (H1)

En H1 hay un solo perfil equilibrado, con los parámetros en el código de `sim_ai.gd` mientras se estabiliza. En H2 los perfiles pasan a `data/ia/<civ>-<apertura>.json`, uno por apertura de `03-matriz-de-roles.md`.

## Dificultad (H4)

Cuatro niveles por parámetros, no por trampas (`reglas.json` → `dificultades`): frecuencia de decisión, eficiencia económica (proporción de aldeanos inactivos tolerada), uso del triángulo y microgestión (retirar unidades heridas, enfocar fuego).

La **experta** juega como un veterano de AoE4: entrena aldeanos sin parar desde todos sus centros hasta su tope, levanta un segundo centro (y un tercero si hay lugar) junto a la riqueza, la piedra o el bosque de su lado del mapa, mantiene un ejército mínimo más alto mientras ahorra para el hito y ataca en oleadas más grandes. Los mapuches se expanden con lofs, que son su centro. Palmares no entrena aldeanos (los suma con la fama), así que solo gana lo demás. Normal es la del torneo de balance.

Además, la experta defiende en proporción (`defensa_proporcional`: a la amenaza va 1,5 veces lo que hay, y el resto sigue con lo suyo) y, si el rival tiene todos los sitios sagrados, va con todo el ejército libre a recuperar uno (`sitios_disputa`). Se mide contra la difícil con `tools/experta_vs_dificil.gd`.

Normal, difícil y experta atacan el hito rival en obra (`ataca_hito_en_obra`, `reglas.json` → `ia_hito_en_obra`) y defienden el propio como cualquier edificio. Ninguna dificultad vuelve a levantar un almacén donde perdió uno hace poco (`ia_economia.almacen_perdido_*`).

Sin victoria por hitos (opciones de partida), toda IA caza los edificios que cuentan para la victoria cuando el rival casi no tiene ejército o le saca el doble (`reglas.json` → `ia_caza`). Con hitos no cambia nada.

## Pruebas

- `tests/test_determinism.gd` usa una partida IA contra IA.
- Desde H2: torneo automático de perfiles contra perfiles con varias semillas; resultado en una tabla de victorias por apertura. Una apertura que gana en todos los cruces es un fallo de diseño (test de las tres aperturas).
