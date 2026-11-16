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

La **fácil** no va a buscar sitios sagrados (`toma_sitios: false`) y tampoco los toma al pasar: en su grilla de caminos el cuadro de cada sitio cuesta más y lo rodea, y quien queda adentro sin rivales sale al borde y sigue (`reglas.json` → `ia_sin_sitios`; prueba: `tests/facil_sitios.gd`). Con los sitios sin victoria no hace falta y no lo hace.

La **fácil** tiene un tope de tropa (`ejercito_max`) y, cuando le atacan la base, uno de emergencia más alto (`ejercito_max_amenazada`) en lugar de ninguno: antes, un principiante que la atacaba con 15 soldados la veía pasar de 39 a 147 de población (proceso/24, 4n; `tools/facil_atacada.gd`). Las demás dificultades no tienen tope.

Para que el principiante gane su primera partida (proceso/24, 4q; `tools/primera_victoria.gd`), la **fácil** además no tiende caminos (`caminos: false`: los tramos son edificios y la tropa en ataque en movimiento se quedaba pegándoles), no levanta torre (`torres_max: 0`), tiene a lo sumo dos edificios de su tropa preferida (`productores_max`), manda menos aldeanos al centro con la campana (`campana_por_enemigo`) y su tope de emergencia es 20. Y **se rinde** (`rendicion`) si perdió `edificios_perdidos` edificios terminados y tiene tropa enemiga en la base, o si su capital queda en la mitad de la vida: la partida termina con motivo `rendicion`.

Además, la experta defiende en proporción (`defensa_proporcional`: a la amenaza va 1,5 veces lo que hay, y el resto sigue con lo suyo). Se mide contra la difícil con `tools/experta_vs_dificil.gd`.

Para subir de edad a tiempo y defenderse al expandir (proceso/24, paso 6b), la experta: pone 8 aldeanos en el hito (`hito_constructores`); desde la edad II ahorra para el hito siempre, sin el ahorro intermitente (`ahorro_continuo`: la tropa que falta sale de lo que sobra por encima del hito); pone más gente en lo que le falta al hito (`refuerzo_hito`); toca la campana también por los centros nuevos (`campana_en_centros`); sube el ejército mínimo al tamaño del mayor ejército rival que vio hace poco (`ejercito_segun_rival`, con la niebla: solo lo que tiene a la vista), y levanta una torre junto a cada centro nuevo si la civ tiene torre (`torre_por_centro`). Las edades se miden con `tools/experta_edades.gd` y el ataque del veterano con `tools/ataque_veterano.gd`.

Normal, difícil y experta **disputan los sitios sagrados** como en AoE4 (`disputa_sitios`, `reglas.json` → `ia_disputa_sitios`): si el rival tiene dos sitios o más, o corre su cuenta de victoria, un grupo con 1,5 veces la vida de los enemigos que cuidan el sitio (2 veces con la cuenta corriendo; al menos 6 unidades) va al sitio rival más barato (cerca y poco defendido), y si se acercan enemigos a un sitio propio, va un grupo proporcional a defenderlo. Sin fuerza suficiente no va (nada de goteo): con la cuenta corriendo se junta en lugar de hacer oleadas o incursiones, y en los últimos 2:30 va con todo. El grupo se retira si pierde la pelea y ese sitio espera un minuto. El grupo chico que toma sitios libres ya no va a uno con enemigos. Se mide con `tools/disputa_sitios.gd` (cuántas cuentas arrancan, se cortan o llegan a cero).

Normal, difícil y experta atacan el hito rival en obra (`ataca_hito_en_obra`, `reglas.json` → `ia_hito_en_obra`) y defienden el propio como cualquier edificio. Ninguna dificultad vuelve a levantar un almacén donde perdió uno hace poco (`ia_economia.almacen_perdido_*`).

Sin victoria por hitos (opciones de partida), toda IA caza los edificios que cuentan para la victoria cuando el rival casi no tiene ejército o le saca el doble (`reglas.json` → `ia_caza`). Con hitos no cambia nada.

## Pruebas

- `tests/test_determinism.gd` usa una partida IA contra IA.
- Desde H2: torneo automático de perfiles contra perfiles con varias semillas; resultado en una tabla de victorias por apertura. Una apertura que gana en todos los cruces es un fallo de diseño (test de las tres aperturas).
