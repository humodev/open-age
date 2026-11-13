# Ronda 3 · Crítica 03b — Programador de la IA, segunda vuelta

Revisión de [`../03-diseno-revisado.md`](../03-diseno-revisado.md) contra el código. Releí `sim.gd` (`_approach`, `_separate`, `find_enemy`, `_cmd_target`, `_exhaust`, `_do_return`, `nearest_dropoff`, `_check_victory`), `sim_entity.gd` y `sim_ai.gd`. No toqué código ni datos, y no hay commits. Los días son días-persona de programador, como en [`03-programador-ia.md`](03-programador-ia.md).

---

## Veredicto

1. **Las respuestas cierran.** Mis diez preguntas y los casos A a I quedan contestados. Quedan **cinco huecos chicos**, que salen de las piezas nuevas y no de mis preguntas (§1.3). Ninguno bloquea; tres conviene cerrarlos antes de programar.
2. **La cuenta de 50 a 55 días es aritméticamente correcta**: es mi base simplificada más los agregados. **Pero deja afuera unos 10 días** de trabajo que el propio diseño pide: los hitos que pasan de renta a efecto, la marca de dueño de cada arcilla con sus claros de 6×6, el traspaso de capital y otros (§2). **Planificaría con 60 a 65 días de núcleo**, más los 4 o 5 de la fase 2.
3. **Las cuatro piezas nuevas se pueden programar de forma determinista** y la IA las juega con reglas simples. Lo de Etiopía mejora mucho: sin carpa, desaparece la máquina de estados. Hay **dos trampas del código actual** que hay que resolver primero:
   - **`is_military()` cuenta como militar toda unidad que no sea `civil` ni `explorador`** (`sim_entity.gd:90`). El elefante del rey y las cabezas del arreo entrarían al ejército de la IA, harían sonar la campana del rival y contarían para los contadores.
   - **El cancelar devuelve el costo actual, no el que se pagó** (`sim.gd:320`). Con los descuentos que dependen de dónde está el edificio (regimiento, barrios), eso abre un exploit que da recursos gratis.
4. **Criterio 9: cumple.** Ninguna civ necesita estado propio en la IA más allá de una variable.

---

## 1. ¿Cierran las respuestas?

### 1.1 Las diez preguntas (§8.4 del diseño)

| # | Respuesta | ¿Cierra? | Nota para quien lo programe |
|---|---|---|---|
| 1 | Sin caza; madera, arbustos y piedra con `carry_src` | **Sí** | `carry_src` = tipo de la fuente (`arbusto`, `granja`, `arrozal`, `arbol`, `roca`) al cargar. Si la carga se mezcla, manda la última fuente |
| 2 | La tecnología inca es una investigación | **Sí** | |
| 3 | La bonificación sigue a la capital activa | **Sí** en escaramuza | En campaña sigue existiendo la carpa: definir que, con la carpa, no hay bonificación (una línea) |
| 4 | Fracción disponible/necesario con piso de 1/3 | **Sí** | 30 de mit'a por minuto son 0,5 por segundo: el consumo también necesita acumulador en milésimas. Fracción entera: `min(1000, disp·1000/nec)`, con piso de 333 |
| 5 | Reparar no devuelve cabezas | **Sí** | |
| 6 | Edificio que acoge más cercano a la capital; desempate por `id` | **Sí** | |
| 7 | Pradera al completar y cada 60 s | **Sí** | Con M6, las cabezas que sobran se vuelven alimento. Tiene que pasar en el mismo tick de la revisión |
| 8 | Radio 12, sin generador especial | **Sí** | Lo medí: la arcilla de base queda a 8 casillas del borde de la corte en los ejes y a ~7 en diagonal (`_scale_dir`, `sim.gd:1705`). Hay que medir **borde a borde** con `dist_to`, no de centro a centro |
| 9 | `owner = -1`, `hostil`, flechas, no persigue | **Sí, con dos cambios de código** | Ver §3.5: hoy nadie puede atacar algo con `owner < 0` |
| 10 | En escaramuza se funda; la carpa solo en campaña, con victoria | **Sí** | |

### 1.2 Los casos del código (§8.3 del diseño)

Los nueve cierran. Agrego dos que no estaban:
- **J. `is_military()` (`sim_entity.gd:90-91`)** devuelve verdadero para cualquier `fn` que no sea `civil` ni `explorador`. Hay que pasar a una lista blanca (`choque`, `distancia`, `linea`, `asedio`) o darles `fn: "explorador"` al elefante del rey y a las cabezas. **Con lista blanca es más seguro**, porque `carpa_real` ya usa el truco del explorador y es frágil.
- **K. La IA trata como amenaza a cualquier unidad enemiga** (`_threat`, `sim_ai.gd:401-410`). Una cabeza de arreo que cruza la base corta el ahorro para el hito (`saving and not threatened`) y manda al ejército detrás de una vaca. Hay que excluir a los que no son militares.

### 1.3 Huecos nuevos

| # | Hueco | Por qué importa | Propuesta |
|---|---|---|---|
| H1 | **Gondar "extrae 8 de cualquier arcilla a ≤ 16"** choca con A1 ("nunca de la del rival") y con A2 ("solo la capital extrae"). ¿Gondar pasa a ser la capital? Si sí, la corte deja de extraer 24 y pasa a 8 | Es la única regla de Etiopía que no se puede programar tal como está | Gondar: capital fija que extrae **24 de lo propio o del centro a ≤ 16** y ya no se funda otra corte. Si se quiere menos, que sea un número explícito, sin "cualquier" |
| H2 | **Fundar la corte es gratis y da fiesta ×2 durante 60 s, cada 5 minutos** | Lo óptimo es fundar cada 5 minutos junto al racimo de gult, aunque la arcilla no se haya agotado. Es un temporizador que conviene cliquear (consigna F). Con 6 gult cerca son **~+25 r/min de promedio** que el modelo no ve (§7.3, "no modela la fiesta") | Fiesta solo si la corte nueva queda a ≥ 15 casillas de la anterior **y** junto a una arcilla con ≥ 300. O un costo (100 m) |
| H3 | **"La acogida espera mientras se junta la fama del hito II"** (Palmares): ¿espera siempre? ¿Y si el jugador no quiere avanzar? | Si la simulación pausa sola, el humano que no avanza se queda sin gente sin saber por qué. Si lo decide la IA, es una regla de reserva | Lo decide el jugador: un botón "guardar fama para el hito", prendido por defecto en la IA. O que la acogida espere solo con el hito ya ubicado |
| H4 | **El tope de lo disputado "en una ventana de 5 min"** | Una ventana deslizante exacta pide guardar 300 registros por jugador | **Cinco baldes de un minuto** (600 ticks cada uno), con un tope de 5 × el tope por minuto. Es entero, barato y va al hash |
| H5 | **Capuera y resiembra:** cuando se agota la capuera (arbustos de 40 de madera), ¿se reabre la roza? | El ciclo queda sin definir | Que no: la capuera deja el suelo libre, que es lo histórico. La roza se reabre solo desde un yerbal |

---

## 2. ¿Es realista el costo de 50 a 55 días?

La suma del diseño (§8.2) es mi base simplificada (40–45) más 11,5. La aritmética está bien. Faltan estas partidas, que el propio diseño pide:

| Partida no contada | Días |
|---|---|
| Once hitos que pasan de renta a efecto sobre el motor (§2.3): seis tipos de efecto nuevos (`maximo_edad`, `cria_s`, `subproducto_pct`, `radio_corte`, `fama`, `yerbal`) y quien los lea | 1,5 |
| Marca de cada arcilla (de cada jugador o del centro), necesaria para la extracción, el tope de lo disputado y M5; y el **claro de 6×6 parejo** junto a cada arcilla (M7), que el generador tiene que reservar antes de los bosques y el relieve | 1,5 |
| Elefante, lo que no entra en los +2: entregar con clic derecho sobre una unidad (`_cmd_target` solo acepta edificios, `sim.gd:234-242`); máximo por edad para **unidades**; dónde se entrena; anclaje frente a la separación (§3.1); que la IA reasigne leñadores al moverlo | 1,5 |
| Corte nueva, lo que no entra en los +0,5: obra que se levanta sola (hoy `_update_building` no toca lo que no está construido), traspaso de capital y de la cola (hoy `_kill` pierde lo encolado sin devolverlo), espera de 5 minutos, fiesta y Gondar | 1 |
| Arreo, lo que no entra en los +2,5: tipo de unidad que no es civil ni militar (caso J), llegada y absorción, lugar reservado en el corral, `pob: 0` (sin eso cuenta 1 de población, `sim.gd:663`) | 1 |
| Costo pagado guardado en la cola (§3.6), necesario para el regimiento y los barrios | 0,5 |
| Campañas: siete hitos pierden la renta con la que se calibraron las misiones, y la campaña etíope conserva la carpa | +1,5 sobre los 2 contados |
| Más iteraciones de balance. El propio diseño marca la edad II con la IA real como riesgo (hito II de 500 a + 300 r) | +2 |
| **Total no contado** | **≈ 10** |

**Estimación realista del núcleo: 60 a 65 días-persona.** Puede llegar a 70 si las cabezas del arreo, la vasija por civ y los fardos del elefante necesitan modelos nuevos (no conté arte). La fase 2 (+4 a 5) me parece razonable.

**Lo que más puede crecer** es la iteración de balance. Con `--seeds=2`, cada torneo de 30 minutos da ±2 victorias de ruido. Por eso insisto en aprobar cada etapa con las métricas económicas de `--paz` (§4), que tienen poco ruido, y dejar las victorias para el final.

---

## 3. Las piezas nuevas: determinismo y reglas de IA

### 3.1 Elefante del rey (depósito que camina)

**Determinismo: sí.** Es una unidad con posición entera, y los aldeanos ya saben perseguir a una unidad: `_approach` recalcula el camino cada 8 ticks si el blanco cambió de casilla (`sim.gd:1236-1244`). `nearest_dropoff` tiene que recorrer también unidades, con desempate por `id`.

**Riesgo de rendimiento, no de determinismo.** `_separate` (`sim.gd:1254-1288`) empuja a todas las unidades. Con 4 a 6 leñadores entrando y saliendo, el elefante se mueve de casilla, y **todos los que vuelven a entregar recalculan su A\* cada 8 ticks**. Hay que hacer que el elefante quieto no se mueva por la separación (como un edificio: el que choca se corre) y medirlo con `bench.gd` usando 3 elefantes y 15 leñadores.

**Otros detalles:**
- clic derecho de un aldeano cargado sobre el elefante (caso de `_cmd_target`);
- `carry_src` para no cobrar granjas ni arrozales;
- **caso J**: con `fn` de militar, la IA lo manda al ataque con el resto del ejército.

**IA, 4 reglas:**
1. el primero, al bosque con más árboles a 6 casillas o menos (`_site_scored` sobre una casilla, no sobre un rectángulo);
2. el segundo, a la piedra;
3. moverlo cuando quedan menos de 10 árboles, y **en el mismo paso reasignar a sus leñadores** a árboles a 6 casillas o menos del destino; si no, siguen talando donde estaban y entregan lejos;
4. si lo atacan y su vida baja de la mitad, llevarlo a la capital.

No hacer depósitos comunes de madera mientras falten elefantes. **Simple: sí.**

### 3.2 Corte nueva sin carpa

**Determinismo: sí.** Es un edificio que se construye solo. Todo es entero: el progreso por tick, el traspaso del indicador `capital` al terminar y el `_kill` de la corte vieja.

Hay que cuidar tres cosas:
1. **La cola de la corte vieja:** devolver lo encolado o pasarlo a la nueva.
2. **La regla "a más de 20 casillas de un edificio enemigo"** se calcula con información que el jugador no ve. El mensaje "no se puede fundar acá" le revela un edificio oculto. Es aceptable, pero conviene que el mensaje no diga por qué, o limitar la regla a los edificios ya vistos (la niebla es por jugador, así que es determinista; `fog` existe).
3. **H1 y H2.**

**IA, 2 reglas:**
1. Fundar cuando a la arcilla de la corte le quedan menos de 100: primero en el claro reservado junto a la arcilla de flanco, y en la edad III, en el claro del centro si no hubo militares enemigos a 15 casillas en el último minuto.
2. El gult, cerca de la capital activa.

El "adónde" ya viene del generador. **Simple: sí, y es la mejora más grande respecto de la primera vuelta** (de 3–4 días de IA a 0,5–1).

### 3.3 Arreo mapuche

**Determinismo: sí.**
- un acumulador de daño por atacante, solo contra tipos de una lista blanca (granja, casa, corral, ingenio; no cercas, puertas ni caminos);
- tope por balde de minuto;
- la cabeza aparece junto al edificio golpeado, con una orden de ir al corral con lugar libre más cercano (desempate por `id`) y **ese lugar queda reservado**;
- al llegar (quieta a 2 casillas o menos del corral) se absorbe en el `tick_second` de los módulos;
- si el corral murió o se llenó, busca otro, y si no hay, 40 de alimento.

Aparecer dentro de `_hit` ya se hace con `liberacion` y no rompe el orden: la unidad nueva entra a `actives` pero el bucle de ese tick usa un `count` fijo (`sim.gd:628`).

**Cosas a definir:** `pob: 0`, `fn` que no sea militar ni civil (casos J y K) y si el humano la puede seleccionar. Propongo que no: camina sola, sin órdenes.

**IA:** nada que decidir; el arreo es consecuencia del malón que la IA ya hace (`sim_ai.gd:436-455`). El que defiende sí necesita el caso K: no tratar a las cabezas como amenaza. Que los tiradores las maten al pasar ya lo hace `find_enemy`. **Simple: sí.**

### 3.4 Roza que se reabre sola

**Determinismo: sí.** Todo pasa en `_exhaust` (`sim.gd:873-881`):
- al agotarse la roza nace el yerbal, que guarda el dueño de la roza (sirve también para M3);
- al agotarse el yerbal, si el dueño tiene la resiembra prendida y 45 de madera, se cobra y aparece la roza **ya construida** en las mismas casillas, que `_kill` dejó libres;
- en los dos pasos se reasigna a los aldeanos cuyo `target` era la fuente agotada, recorriendo `actives` por `id`.

**Esto último es lo que falta hoy**: `_do_gather` busca otra fuente del mismo `gather_kind` (`sim.gd:800-811`), y el aldeano de la roza se va a buscar comida, y el del yerbal, arcilla.

La granja es `transitable`, así que nada queda atrapado. "Quemar con más de la mitad hecha deja el yerbal" (M8) se engancha en `on_kill`.

**IA, 2 reglas:**
1. resiembra siempre prendida, y modo "quemar" mientras el alimento no alcance el próximo hito;
2. al repartir aldeanos, si sobran de riqueza, sacar primero los de la arcilla y nunca los del yerbal.

**Simple: sí.**

### 3.5 Ingenio neutral (S1, como lo cerró el diseño)

**Determinismo: sí**, pero toca tres funciones del núcleo:
- `find_enemy` descarta todo lo que tiene `owner < 0` (`sim.gd:1304`), así que las tropas no lo atacan solas;
- `_cmd_target` manda a mover en vez de atacar cuando el blanco tiene `owner < 0` (`sim.gd:224`);
- `on_kill` sale antes de tiempo si `e.owner < 0` (`sim_mods.gd:273`), y el botín no se cobra.

Además, la reconstrucción a los 360 s necesita una "ruina" con temporizador en el estado (y en el hash). Sus flechas ya funcionan: `find_enemy` desde un edificio con `owner = -1` apunta a cualquier jugador.

**IA:** la regla del malón vale para cualquier civ: ir al ingenio con un grupo cuya vida total sea al menos 3 veces el daño por minuto de sus flechas. Hay que esquivar en los caminos de los aldeanos los ingenios que no son blanco, o ubicarlos fuera de las rutas en el generador. **Simple: sí.**

### 3.6 Dos riesgos transversales que no son de una pieza

1. **Exploit del cancelar.** `_cmd_cancel` devuelve `cost_of(tipo, edad)` con los precios de ese momento (`sim.gd:320`). Con el regimiento (−20 % si el gult está cerca), alcanza con encolar jinetes con descuento, borrar el gult propio (el comando `delete` lo permite) y cancelar: **se recupera el precio entero**. Lo mismo pasa con los barrios. **Arreglo: guardar el costo pagado en cada lugar de la cola.** Medio día, y cierra también el caso actual de los hitos con costo por edad.
2. **El hash.** El elefante y las cabezas son unidades y entran solos. Hay que sumar: reserva de mit'a, recurso propio, cabezas por corral, kawiñ usado por edad, modo del monte, baldes de lo disputado, espera de la corte, fiesta, ruinas de ingenio y precio del mercado (que ahora vuelve solo hacia 100). Sin esto, `test_determinism` no ve las divergencias.

### 3.7 Resumen

| Pieza | ¿Determinista? | Reglas de IA | Días (motor + IA), con lo no contado |
|---|---|---|---|
| Elefante del rey | Sí (anclarlo en la separación por rendimiento) | 4 | 3,5 + 1 |
| Corte nueva | Sí | 2 | 2 + 0,5–1 |
| Arreo | Sí | 0 (+ caso K) | 3,5 + 0,25 |
| Roza que se reabre | Sí | 2 | 2 + 0,5 |
| Ingenio hostil | Sí (tres funciones del núcleo) | 1 | 2,5 + 0,5 |

---

## 4. Orden de implementación final

Cambio el orden de la etapa 3 respecto del diseño (que empezaba por Etiopía). **Primero va el motor que no pide infraestructura nueva**, para validar la cadena de medición con lo más simple, y al final lo que toca el núcleo de la recolección.

Cada etapa se cierra con:
- `test_determinism`, `bench` y `civ_smoke`;
- cuando cambia la interfaz, `--autotest` con una captura (CLAUDE.md, punto 6);
- y su compuerta numérica, siempre en `torneo.gd --paz` contra el modelo (§7.2 del diseño) **con ±15 %**.

Si la IA real queda más de 15 % por debajo del modelo, el problema es la IA (uso del motor) y no el diseño.

| Etapa | Qué | Días | Compuerta |
|---|---|---|---|
| **0. Medir** | `torneo.gd`: `--paz`, `--civ`, `--terreno`, `--informe`. Riqueza por origen (con las marcas de origen que después usa el tope de lo disputado), uso del motor, banco a los 8 minutos, minuto de agotamiento de la arcilla, OPA y PMP | 3–4 | Línea de base guardada en `proceso/` |
| **1. IA común** | Etiqueta `eje`; reserva con `costo_extra`; aldeanos virtuales; `_site_scored`; prioridad de la tecnología de motor; caminos sin huecos (F); campana y ahorro (ronda 1); lof extra que entrenan; casos J y K | 4–5 | Edad II con mediana entre 6:30 y 9:00 con los datos de hoy; OPA inca < 1,0 |
| **2. Capa común** | Arcilla (nombre, cantidades, marca de dueño, claros de 6×6); **hito II de 500 a + 300 r**; mercado con regreso; sitios; separación y máximo por edad (edificios y unidades); tecnología de motor común; hitos sin renta (efectos todavía sin consumidor); acumulador exacto; hash ampliado; costo pagado en la cola | 5–6 | Sin motores, **las seis curvas a ±5 % entre sí** (control). Arcilla de base agotada entre 12 y 19 minutos. **Edad II con la IA real ≤ 9:00**: si no se cumple, se resuelve acá (consulta 2), antes de seguir |
| **3a. Tawantinsuyu** | Taller, reserva global, piso de 1/3, mit'a por edad, aqllawasi = máximo 5, bono conectado en la arcilla | 2,5 + 1 | Mit'a en el tope ≤ 15 %; motor m15–25 entre 45 y 65 % (modelo: 55) |
| **3b. Palmares** | Oficios separados de la guarnición; se paran en combate; contarlos como aldeanos en la IA; mocambo sin `oculto` con bono de monte; fama 90; sumidero de guerreros; H3 | 3 + 0,5 | Puestos ocupados ≥ 80 % del tope desde la edad II; riqueza a los 20 minutos ≥ −15 % de la media |
| **3c. Etiopía** | Gult (variante, separación, 3 a + 17/21 r); extracción por edad desde lo propio o el centro; corte nueva; fiesta con H2; Gondar con H1; carpa solo en campaña, con victoria | 4 + 1 | Edad II ≤ 9:00 (el modelo da 8:50: es la más ajustada); al menos una corte nueva antes del minuto 16; ninguna derrota por mudarse |
| **3d. Guaraníes** | Roza de 500, yerbal con dueño, reasignación en `_exhaust`, resiembra, modo del monte, tope de yerbales y capuera, quema con más de la mitad, semilla de 100 | 3 + 0,5 | Motor m15–25 ≤ 75 % (el modelo da 73: **la banda de R5, 35–65, no la cumple el propio modelo**; o se acepta la excepción o se baja el +14 % al +7 %, como dice el diseño) |
| **3e. Mapuches** | Corral con cabezas, pradera, daño por cabezas (S8 rechazada), kawiñ, cría del lonko, fusión del kulliñ. **El arreo, solo contra el rival** | 4 + 1 | Cabezas promedio ≥ 4 por corral; no más de un kawiñ por corral y por edad; riqueza a los 30 minutos ≥ −15 % |
| **3f. Ayutthaya** | Elefante del rey, `carry_src`, `nearest_dropoff` con unidades, anclaje, barrio chino, arrozal +25 %. **Va último porque toca el camino de entrega de las seis civs** | 3,5 + 1 | `bench` con 3 elefantes y 15 leñadores dentro del presupuesto; elefante en el tope ≥ 60 % del tiempo desde la edad II |
| **4. Lo disputado** | Ingenios hostiles (las tres funciones del núcleo, ruinas, botín por edad); tope con baldes y barra; arreo y liberación desde los ingenios; incursión de la IA a lo neutral | 4–5 | Riqueza disputada dentro de 15/40/80/120 por minuto; prueba del golpe (ronda 1): el castigado gana entre el 20 y el 40 % |
| **5. Interfaz y avisos** | Vista previa al ubicar, botones "2/3", estados y avisos de §3.7. Cada motor ya trajo su botón mínimo en la etapa 3 | 2,5–3 | `--autotest` en las seis civs con captura |
| **6. Balance y campañas** | `torneo.gd -- --minutes=30 --seeds=4` dos veces; `facil` contra `normal`; revisión de las 24 misiones con `campaign_smoke` | 9–12 | Cada civ entre 35 y 65 %; edad II con mediana entre 6:30 y 9:00 y ≤ 2 minutos de diferencia; criterio E con la vara nueva |
| **Fase 2** | Regalo de cumbi, emboscada desde el yerbal, captura de manadas | 4–5 | Después de aprobada la 6 |

**Total del núcleo: 60 a 65 días-persona** (etapas 0 a 6).

**Por qué este orden:**
- La etapa 2 mide primero el **hito II más caro** con la IA real. Es el riesgo que el propio diseño marca, y si falla mueve los tiempos de todos.
- Tawantinsuyu y Palmares no necesitan claros, marcas de dueño, unidades nuevas ni cambios en la entrega: prueban la medición con lo más simple.
- Etiopía va tercera porque usa los claros y las marcas de la etapa 2.
- El arreo contra el rival se prueba en la 3e, pero hasta la 4 no se puede probar contra los ingenios.
- Ayutthaya va al final de la etapa 3 porque `nearest_dropoff` con unidades cambia el camino de entrega de todas las civs. Si rompe algo, se ve aislado.

---

## 5. Criterio 9, segunda vuelta

| Civ | Reglas | Estado propio de la IA | Veredicto |
|---|---|---|---|
| Tawantinsuyu | Taller, reserva (con histéresis de 60 s) | 1 variable | Simple |
| Mapuches | Corral con puntaje, kawiñ, malón | No | Simple |
| Guaraníes | Resiembra prendida, modo según el hito, reparto | No | Simple |
| Etiopía | Gult cerca de la capital, fundar en el claro conocido | No | **Simple** (antes: máquina de estados) |
| Palmares | Mocambo junto al monte; contar los oficios | No | Simple |
| Ayutthaya | Elefante con puntaje, mover y reasignar, huir, sin depósitos comunes | No | Simple, con búsqueda con puntaje |

**Criterio 9: cumple**, siempre que la etapa 1 (IA común y casos J y K) se haga antes de medir cualquier motor.
