# Ronda 3 · Crítica 03 — Programador de la IA

Lectura de [`../01-diseno-lider.md`](../01-diseno-lider.md) y [`../parametros.json`](../parametros.json) contra el código: `src/sim/sim_ai.gd` (completo), `sim_mods.gd`, `sim.gd` (comandos, recolección, `_do_return`, `_exhaust`, rentas, saqueo, generación del mapa, victoria) y `sim_data.gd`, más `data/civs/*.json`, `data/reglas.json` y los diagnósticos `../../05-balance-y-aperturas.md` y `../../v2/05-balance-y-aperturas.md`. No toqué código ni datos. Las horas son **días-persona de programador** (jornadas de 6 a 8 horas) para alguien que ya conoce el repositorio.

---

## Veredicto en pocas líneas

- **Criterio 9 ("la IA lo juega con reglas simples"): se cumple en cinco civs y en Etiopía solo a medias.** Palmares, mapuches y Tawantinsuyu salen con dos o tres reglas cada una. Guaraníes y Ayutthaya necesitan además buscar un lugar con puntaje, que hoy la IA no sabe hacer. La mudanza de la corte etíope no es una regla: es una máquina de estados con cuatro casos de falla. Además, hoy **la civ pierde si empaca la corte en la edad I** (ver §1.4).
- **Las "diez piezas, todas como parámetros de módulo" (§8 del diseño) no son diez parámetros.** Cuatro son parámetros de verdad: el tope por edad, la extracción de la corte, el subproducto del depósito y la bonificación por cercanía. Las otras seis piden estado nuevo en las entidades, comandos nuevos, interfaz y cambios en la recolección: el rebaño, el oficio, la sucesión con cola y bandera, el interruptor, los ingenios neutrales con guardia y el informe por origen. Los ingenios con guardia son lo más profundo, porque hoy el motor **no tiene un bando neutral que se pueda atacar**.
- **Costo estimado del diseño tal como está: 65 a 80 días-persona.** Con las simplificaciones de §4, que no le sacan identidad a ninguna civ, baja a **40 a 45**.
- **La IA actual tiene que arreglarse antes de medir cualquier motor nuevo.** Si no, el torneo va a medir a la IA y no al diseño (ya lo advirtió la ronda 1). Lo más urgente es la elección del hito, la reserva y que el reparto de aldeanos no sabe que existe un motor.

---

## 0. Lo que hace la IA hoy y que choca con el diseño

| # | Comportamiento actual | Dónde | Por qué importa en v3 |
|---|---|---|---|
| A | Necesita un único `centro` construido. Si no lo hay, solo ataca y **corta toda la economía** | `sim_ai.gd:58-63` | Mientras la corte etíope viaja, la IA se queda sin economía |
| B | `_hito_type` toma `opts[1]` en la edad II y `opts[0]` en la I y la III, sin leer qué hace cada hito | `sim_ai.gd:79-81` | Tawantinsuyu nunca elige el **aqllawasi**, que el diseño convierte en su tecnología de motor: en la edad II la IA toma `kallanka_real`. Los mapuches siguen eligiendo `rewe_malon` en la edad I |
| C | Los edificios propios salen de una lista fija (`ia_edificios`), uno por paso, cuando hay `10 + 6·n` aldeanos, y se ubican en anillos alrededor del centro **sin mirar el lugar** | `sim_ai.gd:233-242`, `316-338` | Todos los motores v3 piden una **decisión de lugar**: pradera, monte, corte, bosque o entre dos almacenes. Hoy no existe ninguna búsqueda con puntaje |
| D | El reparto de aldeanos usa proporciones fijas (riqueza: 10 % y después 23 %) y no sabe cuánta riqueza entra por renta | `sim_ai.gd:18-19`, `124-170` | Con motores del 30 al 60 %, la IA pone aldeanos de más en el barreal y lo agota antes. Los guaraníes y Ayutthaya necesitan **sacar** gente del barreal |
| E | Busca recursos a 40 casillas del centro como máximo | `sim_ai.gd:152` | El barreal del centro, a unas 42 casillas, queda afuera: la IA no disputa nada (ronda 1). Eso le conviene al techo de lo disputado, pero ninguna IA va a ir al centro |
| F | Traza caminos en línea recta y **se saltea las casillas ocupadas** | `sim_ai.gd:541-554` | Si el camino queda cortado, el edificio sigue desconectado y la IA lo reintenta cada 20 s. **Es mi hipótesis principal para las 2,16 OPA incas de v2/05**, y hay que verificarla antes de sumarle a la mit'a un uso económico por caminos |
| G | `_research` investiga lo primero que puede pagar, en el orden del diccionario | `sim_ai.gd:84-101` | La tecnología de motor de la edad III (+25 %) puede quedar detrás de cualquier mejora militar |
| H | La campana mete en la guarnición a todos los aldeanos cercanos, y al apagarla se **vacían todos los edificios** | `sim.gd:451-470`, `_eject` en `525` | Si el oficio de Palmares usa la guarnición, cada falsa alarma le saca la gente de los oficios |
| I | La IA solo entiende comandos que ya existen: no hay `toggle`, `faenar`, `cupo`, `bandera` ni elegir variante al construir | `sim.gd:135-179` | Cada uno es un comando nuevo, con grabación, repetición e interfaz |

Las dos lecciones de la ronda 1 siguen en pie: el alimento manda en la edad I y la campana paraliza. Ninguna se arregló todavía.

---

## 1. Reglas de IA por civ

Para las seis valen las mismas tres reglas comunes; las detallo en §1.7. Abajo va lo propio de cada una. Cada umbral numérico va en `data/` (CLAUDE.md, regla 4), en un bloque `"ia"` del JSON de la civ, y no en `sim_ai.gd`.

### 1.1 Tawantinsuyu — taller de tejido

| Qué | Regla |
|---|---|
| **Dónde** | Dentro de la base, junto a la llaqta: el taller no depende del lugar. Un **depósito a 3 casillas o menos del barreal**, unido con camino a la llaqta |
| **Cuándo construir** | Si `talleres < máximo de la edad` y `ingreso de mit'a − consumo actual ≥ 30/min` y `madera ≥ 120 + 60` (reserva para granjas) |
| **Prender y apagar** | Apagar talleres, de a uno, si (a) se ahorra para un hito con `costo_extra` de mit'a que no llega al ritmo neto actual en 3 minutos, o (b) hay amenaza y se quiere leva. Prender si `mit'a ≥ 60 % del tope` y no se ahorra. **Con histéresis**: no cambiar el mismo taller más de una vez cada 60 s |
| **Orden** | Camino al barreal (una sola vez por barreal) → taller 1 (unos 4:00) → qollqa → taller 2 → hito II → talleres hasta el máximo |
| **Qué es difícil** | El ahorro de mit'a para los hitos. El aqllawasi pide **120 de mit'a** y el qorikancha **200**. Con 2 talleres prendidos, el neto baja a unos 20 por minuto y el hito tarda 6 minutos en llegar. Si la IA deja todo prendido, **nunca junta la mit'a del hito** |
| **Veredicto** | Factible: 3 reglas. Antes hay que arreglar el bug F de los caminos |

### 1.2 Mapuches — corral

| Qué | Regla |
|---|---|
| **Dónde** | Puntaje por casilla: +2 si es pradera (cero árboles a 3 casillas o menos), −3 por cada corral propio a 8 casillas o menos (vecindad), −1 por cada 4 casillas de distancia al lof más cercano y descartado si hay enemigos vistos a 12 casillas o menos. La primera vez gana la pradera; después, alejarse de los otros corrales |
| **Cuándo construir** | Corral cuando `corrales < máximo`, `madera ≥ 120 + 60` y no se ahorra. Desde el segundo, solo si el anterior ya tiene 3 cabezas o más (se evita invertir todo junto) |
| **Faenar** | Solo si (a) se ahorra para el hito y falta alimento, (b) lo que falta es ≤ `cabezas_faenables × 40`, (c) ese corral está lleno, y (d) no se faenó en los últimos 4 minutos. Se elige el corral **más expuesto** (el más lejano al lof) |
| **Malón** | La incursión que ya existe (`sim_ai.gd:436-455`) más un blanco nuevo: la estancia neutral, cuando el grupo supera 1,5 veces la guardia y la estancia no está en reconstrucción |
| **Orden** | Corral inicial (semilla) → 3 al barreal → corral 2 (4:00) → lof en el flanco → hito II (con `hitos` arreglado: lonko primero) → corral 3 y siguientes |
| **Qué es difícil** | Nada serio. La regla de faenar es un `if` con cuatro condiciones |
| **Veredicto** | Factible y simple. Con el kulliñ fusionado en la riqueza desaparece el problema de reserva medido en la ronda 1 |

### 1.3 Guaraníes — roza, yerbal, cola y bandera

| Qué | Regla |
|---|---|
| **Bandera** | Puntaje por casilla libre de 3×3, a 20 casillas o menos de un tapyi o depósito propio: +3 si hay 4 árboles o más a 2 casillas o menos (+15 %), −1 por cada 4 casillas de distancia y descartada si está más cerca del rival que de la base. **Mover la bandera** cuando quedan menos de 4 árboles cerca, como máximo cada 3 minutos |
| **Cola** | Mantenerla en 2 si `alimento < lo que pide el próximo hito`, y en 1 si sobra alimento. Nunca en 4: inmoviliza 180 de madera |
| **Aldeanos** | Desde el primer yerbal, el barreal pasa a reserva: el reparto cuenta cada yerbal activo como ~1,33 AE de riqueza y, si sobran aldeanos de riqueza, saca **primero los del barreal** y nunca los del yerbal |
| **Orden** | Arbustos → yerbal viejo (semilla) → rozas en lugar de granjas desde 2:30 → bandera junto al monte → hito II → cola en 2 |
| **Qué es difícil** | (1) **El "pase automático" no existe.** Cuando la roza se agota, `_do_gather` (`sim.gd:800-811`) busca otra fuente del mismo tipo (`gather_kind = "alimento"`), así que el aldeano se va a buscar comida y no se queda en el yerbal. Hay que reasignar el tipo de recurso en `_exhaust`. (2) **Hoy la IA construye la granja/roza en `_economy`** cuando no encuentra alimento; con la cola, eso choca. Para los guaraníes, la IA no tiene que poner rozas a mano: tiene que encolarlas. (3) La búsqueda de la bandera es la primera búsqueda con puntaje que hay que escribir, y es cara (hay que contar árboles en una ventana). Se hace cada 30 s, no en cada paso |
| **Veredicto** | Factible, con la búsqueda con puntaje de §1.7 escrita una vez y reutilizada |

### 1.4 Etiopía — gult y corte que se muda

| Qué | Regla |
|---|---|
| **Gult, dónde** | Puntaje: +3 si está a 14 casillas o menos de la corte, −3 por cada gult propio a 6 casillas o menos y +1 por terreno abierto. Lugar de 4×4 parejo |
| **Señor o regimiento** | Señor siempre hasta tener 3. Después, regimiento solo si `_counter_order` está pidiendo jinetes y la edad es III o más. Si no, señor |
| **Mudanza: cuándo** | Todas a la vez: (a) el barreal que la corte está extrayendo tiene menos de 100 o se agotó; (b) hay otro barreal no agotado a 25 casillas o menos, **del lado propio** (la IA conoce el de flanco desde la generación del mapa); (c) **hay otro edificio que cuenta para la victoria** (hito o `cuenta_victoria`); (d) ningún militar enemigo visto a 20 casillas o menos en los últimos 30 s; (e) no hay hito en obra y no se va a ahorrar para uno en los próximos 60 s; (f) pasaron 5 minutos desde la última mudanza |
| **Mudanza: cómo** | Máquina de estados: **PREPARAR** (vaciar la cola de la corte, que `_cmd_pack` exige vacía, y poner un depósito en el destino) → **EMPACAR** → **VIAJAR** (escoltar la carpa con el ejército hasta el lugar parejo de 4×4 que ya se calculó) → **DESPLEGAR** (si `can_place` falla, probar en anillos; si en 20 s no hay lugar, volver al origen). Si atacan la carpa, abortar: desplegar donde esté si se puede |
| **Orden** | Gult 1 (3:30, señor) → 3 al barreal → gult 2 → hito II → gult 3 → mudanza al barreal de flanco (unos 12:00) → gult 4 y 5 alrededor de la corte nueva |
| **Qué es difícil** | 1. **Hoy la IA se apaga mientras la corte viaja** (caso A): sin `centro` no hay economía, ni casas, ni aldeanos. Hay que darle un modo "corte en marcha" que siga mandando aldeanos a los depósitos. 2. **La victoria cuenta solo edificios** (`sim.gd:1549-1558`). La carpa es una unidad, así que **empacar la corte en la edad I, sin otro hito, es derrota inmediata** (en menos de 1 s). Le pasa también al humano. 3. Al empacar, el tope de población baja 10 y la producción de aldeanos se traba. 4. La corte es el depósito principal; si no hay depósito en el destino, los aldeanos caminan hasta la base vieja. 5. El "una fuente a la vez" con los aldeanos vaciando el mismo barreal adelanta el agotamiento y la mudanza: hay que medir que la mudanza no caiga cada 3 minutos |
| **Veredicto** | **Es la única civ que no se resuelve con reglas simples.** La máquina de estados es acotada, pero tiene fallas que solo aparecen en partida. Calculo 3 a 4 días solo para esto, y es la que más torneos va a pedir |

### 1.5 Palmares — oficios

| Qué | Regla |
|---|---|
| **Dónde** | Mocambo: +2 si hay 6 árboles o más a 4 casillas o menos (+5 de fama), −2 si está a más de 15 casillas del centro. La protección viene de la cerca, no del lugar |
| **Cupo** | Edad I: cupo 1 en el primer mocambo. Desde la edad II: cupo 3 en todos. Si el barreal más cercano a un depósito se agotó o está a más de 10 casillas, cupo 3 desde ya |
| **Orden** | Barreal con los primeros → mocambo 1 (3:00, cupo 1) → hito II → mocambo 2 junto al monte → cupos a 3 → correrías a ingenios (la misma regla del malón) |
| **Qué es difícil** | Contar. La IA cuenta aldeanos con `inside < 0` (`sim_ai.gd:47-49`). Los del oficio quedan adentro y **no se cuentan**, así que los umbrales de `_wants_hito` (13 + 8 por edad) y de `ia_edificios` (10 + 6·n) se retrasan, y la IA de Palmares demora el hito. Hay que contar a los del oficio como aldeanos |
| **Veredicto** | La más fácil de las seis |

### 1.6 Ayutthaya — almacén real y barrio chino

| Qué | Regla |
|---|---|
| **Almacén, dónde** | Puntaje: árboles a 6 casillas o menos (+1 cada 5, hasta +6), −1 por cada 4 casillas de distancia a la base y descartado si está más cerca del rival. Construir uno nuevo cuando el actual tiene menos de 10 árboles a 6 casillas o menos |
| **Depósitos comunes** | **No construir depósitos comunes para madera** mientras haya almacenes por debajo del máximo. `nearest_dropoff` (`sim.gd:1362`) lleva al depósito más cercano: un depósito común junto al bosque se queda con el subproducto |
| **Aldeanos** | Unos 3 leñadores por almacén (con 3 se llega al tope de 24) y la madera que sobra se gasta. El reparto cuenta cada almacén saturado como 0,8 AE de riqueza |
| **Barrio chino** | Casilla a 6 o menos de **dos** almacenes: intersección de dos cuadrados, que se calcula directo. Si no hay, junto al almacén con más uso del tope. Japonés o portugués: después del chino, pegado a un cuartel |
| **Qué es difícil** | La geometría del barrio entre dos almacenes es un cálculo chico. Lo delicado es que la IA ya construye depósitos solos (`sim_ai.gd:225-232`) y eso se come el motor |
| **Veredicto** | Factible: 3 reglas y la búsqueda con puntaje |

### 1.7 Reglas comunes a las seis (sin esto, el motor no se mide)

1. **El hito se elige por etiqueta**, no por posición: `"eje": "economia" | "guerra" | "motor"` en cada hito de `data/civs/*.json`. La IA toma `economia` en la I, `guerra` en la II (como hoy) y `motor` o `economia` en la III.
2. **Reserva del próximo hito**: no gastar ningún recurso por debajo de lo que pide el hito, incluido el `costo_extra` (mit'a, fama). Es lo que pidieron las rondas 1 y 2 y hoy no está.
3. **El reparto de aldeanos tiene en cuenta el motor**: `aldeanos virtuales de riqueza = ingreso del motor por minuto / 30`. La proporción objetivo de riqueza se calcula sobre aldeanos reales más virtuales. Es una línea, pero cambia la curva de agotamiento del barreal.
4. **Pieza de motor**: construir mientras `piezas < máximo de la edad`, no se ahorre y `madera ≥ costo + 60`. En la edad I, una sola pieza antes del hito II (premodelo §7.3: la madera del motor no puede atrasar la edad II).
5. **Tecnología de motor primero** al llegar a la edad III: etiqueta `"motor": true` en la tecnología, con prioridad sobre el resto en `_research`.
6. **Búsqueda con puntaje** (`_site_scored(tipo, centro_busqueda, radio, puntaje)`): una sola función reutilizable que recorre anillos como `_site_near` y se queda con el mejor puntaje, con desempate por casilla para que sea determinista. Se usa para corral, bandera, gult, mocambo, almacén y barrio. Corre cada 30 s como máximo y guarda el resultado.
7. **Barreal agotado**: cuando no queda barreal propio a 25 casillas o menos, los aldeanos de riqueza van al barreal de flanco con depósito (ya existe `_far_gather_point`), y desde la edad III, si el ejército controla el centro, al barreal del centro.

### 1.8 Resumen de factibilidad

| Civ | Reglas propias | Búsqueda con puntaje | Estado nuevo en la IA | Dificultad | Días IA |
|---|---|---|---|---|---|
| Palmares | 2 (cupo, contar) | Mocambo (simple) | No | Baja | 0,5–1 |
| Mapuches | 3 (corral, faenar, malón neutral) | Corral | No | Baja | 1–2 |
| Tawantinsuyu | 3 (taller, interruptor con histéresis, camino) | No | Histéresis por taller | Baja a media | 1–1,5 |
| Ayutthaya | 3 (almacén, sin depósitos comunes, barrio) | Almacén y barrio | No | Media | 1,5 |
| Guaraníes | 3 (bandera, cola, reparto) | Bandera (cara) | No | Media | 1,5 |
| Etiopía | 3 + máquina de estados | Gult y destino de la corte | **Sí (4 estados)** | **Alta** | 3–4 |
| Común | 7 (§1.7) | Función base | No | Media | 3–4 |
| **Total IA** | | | | | **12–16** |

---

## 2. Piezas nuevas: qué existe, qué es fácil y qué es profundo

### 2.1 Las diez piezas del diseño

| # | Pieza | ¿Existe algo? | Clase | Qué hay que hacer de verdad | Días (motor) | Días (vista e interfaz) |
|---|---|---|---|---|---|---|
| 1 | `maximo_por_edad` + `vecindad` | No | **Fácil** | Tope en `_cmd_build` (contando también los que están en obra). La vecindad necesita un orden fijo para decidir cuál es la 2.ª copia (por `id`) y recalcularse al construir o destruir, no cada segundo | 1 | 0,5 (mostrar "2/3" y el % en el cartel) |
| 2 | `conversion` con interruptor | No | **Media** | Comando nuevo `toggle` (grabación, repetición), estado `encendido` en la entidad, consumo por segundo con acumulador y regla "si no alcanza, no produce" | 1,5 | 0,5 (botón) |
| 3 | `rebano` | No | **Profunda** | Estado `cabezas` y temporizador de cría por corral; pradera (contar árboles; ¿al construir o cada tanto?); comando `faenar`; daño → cabezas por umbrales de vida; ¿reparar repone cabezas? (no está definido); interacción con la vecindad | 3 | 1,5 (cabezas visibles pastando) |
| 4 | `subproducto` en el depósito | No (gancho en `_do_return`, `sim.gd:889-908`) | **Fácil** | Porcentaje con tope por ventana de 600 ticks y por edificio. **"Caza" no existe en el juego** (`data/recursos.json` solo tiene arbustos como alimento silvestre); para distinguir arbusto de granja hay que guardar el origen de la carga (`carry_src`) | 1 | 0,25 |
| 5 | `oficio` | Parecido: guarnición (`inside`, `garrison`) | **Profunda** | Puestos aparte de la guarnición (si no, la campana los vacía, caso H); comando `cupo`; `_welcome` (`sim_mods.gd:86-102`) dirigido al cupo libre (hoy toma el primer edificio que acoge, por orden de `id`); al morir el edificio se liberan; contar en población y en la IA | 3 | 1 (cupo, gente adentro) |
| 6 | `extrae` | No, pero es un `_rents` con objetivo | **Fácil** | Cada segundo: la corte desplegada busca la fuente más cercana a 8 casillas o menos (desempate por `id`), descuenta y llama a `_exhaust` si llega a 0 | 1 | 0,25 |
| 7 | Sucesión con pase automático, cola, bandera, tope y capuera | Solo `deja` (`sim.gd:873-881`) | **La más profunda** | (a) El pase automático: hoy el aldeano busca alimento (§1.3). (b) Cola por tapyi con prepago. (c) Bandera (estado y comando). (d) **Ubicar edificios desde la simulación**: hoy solo la IA busca lugar (`_site_near`); hay que llevar esa función a `sim.gd` para que el aldeano abra la roza solo. (e) Tope de yerbales activos por jugador. (f) Capuera: recurso nuevo de madera de 3×3 | 4 | 1,5 (cola, bandera, aviso) |
| 8 | `bono_cerca_de` + conectado en la recolección | `bono_conectado_pct` solo en producción (`sim_mods.gd:229-233`) | **Fácil a media** | Gult y barrio: distancia a un tipo al calcular la renta. Barreal inca: el bono se aplica a un **recurso**, no a un edificio, así que hay que guardar qué recursos tienen un edificio conectado a 3 casillas o menos y recalcularlo cuando cambia la red (cada 50 ticks, como `_update_connection`) | 1,5 | 0,25 |
| 9 | Mapa: barreal, flanco, sitios decrecientes, **ingenios neutrales con guardia**, mercado | Barreal = renombrar `riqueza`; flanco = `picks[5]`; sitios y mercado = datos | Fácil salvo los ingenios | **Los ingenios son profundos:** `find_enemy` descarta todo lo que tiene `owner < 0` (`sim.gd:1304`) y `_cmd_target` no permite atacar unidades o edificios neutrales (`sim.gd:224`). Hay que crear un bando neutral hostil (¿un jugador extra?, que toca la victoria, la niebla y el torneo), su guardia, el botín único, la reconstrucción a los 240 s con +2 de guardia y los bonos por civ. Las **semillas por civ** (yerbal viejo, corral inicial, almacén inicial) tampoco pueden usar `_res_sym`, que espeja para los dos jugadores | 1,5 + **4–6** (ingenios) + 1 (semillas) | 1,5 |
| 10 | Tope por minuto del saqueo, `motor_pct`, informe por origen, PMP y OPA | No | Fácil a media | El tope y `motor_pct` son fáciles. **El informe por origen** obliga a etiquetar cada ganancia (`_gain`, `_do_return`, mercado, sitios, botín) con su origen | 0,5 + 1 + 1,5 + 1,5 | — |

### 2.2 Lo que el diseño no lista y también hay que hacer

| Pieza | Por qué | Días |
|---|---|---|
| Elegir **señor o regimiento** al construir el gult | Hace falta un parámetro `variante` en el comando `build` y el −15 % por gult (tope −30 %) en `cost_of` de los jinetes | 1 |
| Barrios −15 % "si tocan un cuartel" | Mirar adyacencia al entrenar | 0,5 |
| Mocambo +5 de fama junto al monte | Contar árboles al completarse | 0,25 |
| Victoria con la corte empacada | `_check_victory` tiene que contar la carpa como capital | 0,25 |
| Etiqueta `eje` en los hitos y `motor` en las tecnologías | Para la IA (§1.7) | 0,25 |
| Ampliar `state_hash` | Ver §3 | 0,5 |
| Acumulador exacto por minuto | Ver §3 | 0,5 |
| Fusionar el kulliñ con la riqueza | Datos e interfaz. Ninguna campaña ni código fuera de `data/civs/mapuches.json` lo nombra: es barato | 0,5 |
| Campañas | Usan el yacimiento, los `oculto`, la renta de los barrios y de los hitos: hay que revisar las 24 misiones con `tests/campaign_smoke.gd` | 2–4 |

### 2.3 Total del diseño tal como está

| Bloque | Días-persona |
|---|---|
| Simulación (§2.1 + §2.2) | 30–36 |
| Vista e interfaz | 7–9 |
| IA (§1.8) | 12–16 |
| Instrumentación del torneo (ver §5, etapa 0) | 3–4 |
| Iteración de balance con torneos | 8–12 |
| Campañas | 2–4 |
| **Total** | **≈ 65–80** |

---

## 3. Riesgos para el determinismo

Nada del diseño obliga a usar flotantes ni trigonometría: todo son tasas, porcentajes, radios y conteos. Los riesgos son de implementación:

1. **Divisiones que no cierran.** `_gain(pid, k, tasa_min * 1000 / 60)` trunca cada segundo: 24 r/min da 400 exactos, pero 19 r/min da 316 en vez de 316,67, y **se pierde un 0,2 % para siempre**. Es determinista, pero desvía los números del modelo. Solución: un acumulador en 1/60 000 (`_acc += tasa_min * 1000` y descontar de a 60 000), o declarar todas las tasas como múltiplos de 3 por minuto (12, 15, 24 y 30 cierran; 14 y 19 no).
2. **Porcentajes encadenados.** "+33 %" sobre 14 da `14 * 133 / 100 = 18`, no los 19 del diseño. Conviene que `data/` lleve **valores explícitos** (`renta_cerca: {alimento: 5, riqueza: 19}`) y no porcentajes sobre porcentajes. Lo mismo para ×1,5 (`150`) y para la tecnología +25 % aplicada sobre una renta con vecindad: hay que fijar el orden de las operaciones en el código y documentarlo.
3. **Orden de iteración.** La vecindad ("la 2.ª copia rinde 70 %"), el cupo ("el libre más cercano"), la extracción ("una fuente a la vez") y los sitios ("el primero rinde 18") eligen entre varios candidatos. Siempre: menor distancia, y si empatan, menor `id`. Los diccionarios de Godot conservan el orden de inserción, pero **no hay que iterar diccionarios armados con datos que dependan de la vista**.
4. **Distancias.** Para los radios conviene comparar distancias al cuadrado o usar la distancia de Chebyshev en casillas, y no `isqrt` (que llama a `sqrt` flotante y corrige; es seguro, pero también más caro).
5. **Ventanas por minuto.** Los topes (saqueo 60/min, almacén 24/min) se cuentan por ventanas de 600 ticks (`tick / 600`), nunca por reloj real.
6. **El hash no ve el estado nuevo.** `state_hash` (`sim.gd:2194-2204`) mira posición, vida, orden, carga y cantidad de cada entidad, y **solo los cuatro recursos comunes**: hoy ya no ve la mit'a ni la fama. Hay que sumarle las cabezas, el estado del interruptor, el cupo, la cola, la bandera, los recursos propios y los acumuladores de los topes. Si no, `test_determinism.gd` puede dar verde con partidas que divergen.
7. **Ubicar desde la simulación** (cola de rozas): si `_site_near` pasa a la simulación, el resultado no puede depender de la niebla de ningún jugador ni de nada de la vista. La versión actual cumple (solo mira `map` y `can_place`).
8. **La IA corre dentro del tick** (`sim.gd:619-621`). Las búsquedas con puntaje cuestan: contar árboles en 5×5 sobre 40×40 casillas son unas 40 000 operaciones. Con caché cada 30 s y sin recorrer `actives` por cada casilla, entra en el presupuesto; hay que confirmarlo con `tests/bench.gd`, que hoy no tiene IA con motores.
9. **El bando neutral** de los ingenios: si se hace como un jugador extra, cambia `players.size()`, que hoy usan la victoria, la niebla, los escenarios (`sim_scenario.gd`) y el reparto de bases. Es el cambio con más superficie de las diez piezas.

---

## 4. Simplificaciones que abaratan mucho sin quitar identidad

Ordenadas por ahorro. Cada una dice qué se pierde.

| # | Simplificación | Ahorro | Qué se conserva | Qué se pierde |
|---|---|---|---|---|
| S1 | **Ingenios neutrales sin guardia:** un edificio neutral con flechas propias (como una torre) que cualquiera puede atacar, con botín único y reconstrucción. Solo hay que permitir que los edificios con `owner < 0` y `hostil: true` puedan ser blanco | 3–5 días y casi todo el riesgo de §3.9 | El objetivo neutral que da botín y el ×1,5 de mapuches y Palmares | La guardia que crece |
| S2 | **Resiembra en el mismo lugar** (guaraníes): la cola reabre la roza **donde estaba el yerbal agotado**, como la resiembra del molino en AoE2. Sin bandera | 2–3 días de motor, 1 de IA, y no hay que llevar la búsqueda de lugar a la simulación | Roza → yerbal → roza, la cola como decisión comida o riqueza, y el +15 % del monte (se elige al poner la primera roza) | La base que "avanza sobre el monte" sola. Se puede recuperar a mano: el jugador pone rozas nuevas donde quiera |
| S3 | **Vecindad como restricción de lugar:** no se puede construir una pieza de motor a menos de N casillas de otra igual, en vez de rendir 70/50 % | 1 día de motor; la IA no calcula rendimientos (lo resuelve `can_place`); el jugador no tiene que hacer cuentas ocultas | Castigar el amontonamiento y obligar a decidir dónde; dispersar sigue exponiendo más | El matiz "amontonar a propósito, sabiendo que rinde menos" |
| S4 | **Etiopía:** (a) un radio de extracción que alcance el barreal de base estándar (10 casillas del centro de la base) en vez de un generador especial para una sola civ, que además `_res_sym` espejaría para el rival; (b) la IA conoce los destinos de antemano: base → flanco → (centro, solo en la edad III y con el centro controlado) | 1 día de generador y la mitad de la máquina de estados (el "adónde" ya está resuelto) | La corte que come su entorno y se muda | Ninguna, para el jugador humano |
| S5 | **Palmares sin cupo:** los puestos se llenan siempre con los que llegan; el jugador saca gente con "desalojar" (ya existe `ungarrison`). La decisión pasa a ser cuántos mocambos y dónde | 1 día (sin comando ni interfaz de cupo) | Riqueza en personas, adentro y protegida | El ajuste fino entre campo y oficio. La consigna pide decisiones con dos respuestas viables: esta queda en "mocambo o cuartel" |
| S6 | **Interruptor global inca:** un solo botón "tela / obra" por jugador, en vez de uno por taller | 0,5 días de interfaz; la IA tiene una sola variable con histéresis | La decisión "mit'a para tela o para leva" | Apagar talleres de a uno (poco valor: todos rinden igual) |
| S7 | **Ayutthaya cobra solo de la madera.** La caza no existe y los arbustos complican el origen de la carga | 0,5 días | El monte paga al rey | El plan B de arbustos en el altiplano; si hace falta, se compensa subiendo el porcentaje en mapas secos |
| S8 | **Corral sin daño por cabezas:** el corral pierde todas sus cabezas menos una solo si lo destruyen | 1 día | Ganado visible, que crece, se come y se pierde | El castigo gradual a un golpe parcial (que además era abusable reparando) |
| S9 | **Tecnología de motor igual para las seis:** una investigación con la misma estructura y la etiqueta `motor`, también para Tawantinsuyu. El aqllawasi queda como hito con otro efecto | Evita que la IA tenga que elegir un hito concreto en la edad II solo para una civ | Simetría (diseño §2) | Nada; hoy es la única civ que la consigue por hito |

**Con S1 a S9, el total baja a unos 40–45 días-persona**: simulación 18–22, vista e interfaz 4–5, IA 8–10, instrumentación 3, balance 6–8 y campañas 2. La IA de Etiopía queda en 2 días y la de los guaraníes en 0,5.

---

## 5. Plan de implementación por etapas

Cada etapa cambia una sola cosa y se aprueba con números, no con impresiones. Para eso, la etapa 0 le enseña al torneo a medir la economía. Hoy `tests/torneo.gd` solo imprime ganador, terreno y edades.

**Ruido.** Con `--seeds=2` cada civ juega 10 partidas: ±2 victorias de ruido (ronda 1). Las victorias se leen con `--seeds=4` o más y en dos torneos seguidos. **Las métricas económicas de cada partida (tiempo de la edad II, riqueza acumulada, % del motor) son mucho menos ruidosas y son las que aprueban cada etapa.**

### Etapa 0 — Medir (3–4 días)
- `torneo.gd` nuevo: `--paz` (las dos IA en `personality = "pasiva"`, sin ataques: mide el motor solo, comparable con el premodelo §7.3), `--civ=`, `--terreno=`, `--informe=archivo.json`.
- Informe por partida y jugador: tiempo de cada edad, riqueza acumulada a los 5/10/15/20/30 minutos, % de riqueza por origen (barreal propio, flanco, centro, motor, mercado, sitios, botín), banco a los 8 minutos, minuto en que se agota el barreal propio, **uso del motor** (piezas sobre el máximo de la edad a lo largo del tiempo; mit'a en el tope; cabezas promedio; puestos ocupados; almacén en el tope; yerbales activos) y OPA.
- El **uso del motor** es la métrica que separa "el diseño no rinde" de "la IA no lo usa".
- **Aprueba:** línea de base guardada en `proceso/` con `--minutes=30 --seeds=4` y `--paz`.

### Etapa 1 — IA común, sin tocar el diseño (3–4 días)
- §1.7, reglas 1, 2, 5 y 6 (etiqueta `eje`, reserva, prioridad de la tecnología, `_site_scored`), más la campana y el ahorro de la ronda 1. Arreglar los huecos del camino inca (caso F).
- **Aprueba:** edad II con mediana entre 6:30 y 9:00 en las seis, mapuches con lonko, OPA inca por debajo de 1,0. Si una civ mejora solo con la IA corregida, el problema era la IA (ronda 1).

### Etapa 2 — Capa común del mapa y reglas de techo (3–4 días)
- Barreal (900 × 2, flanco de 1500, centro de 1000), mercado mínimo 60 y paso 3, sitios con 18/12/8, `maximo_por_edad`, vecindad (S3), tecnología de motor común (S9, sin efecto todavía), acumulador exacto y hash ampliado.
- **Aprueba:** `test_determinism` y `bench` en verde; con `--paz` el barreal propio se agota entre los minutos 22 y 28; sin motor, las seis curvas quedan a ±5 % entre sí (son la misma civ económica).

### Etapa 3 — Motores, de a uno (en este orden)
El orden va de lo que reutiliza más a lo que reutiliza menos. Así, cada motor nuevo se mide contra los que ya entraron.

| Paso | Civ | Piezas | Días (motor + IA) | Aprueba (con `--paz` y torneo `--seeds=2`) |
|---|---|---|---|---|
| 3a | Etiopía (sin mudanza) | Gult nuevo, `bono_cerca_de`, `extrae`, señor o regimiento | 3 + 1 | Edad II entre 6:30 y 8:00; motor al m15 entre 28 y 40 % |
| 3b | Ayutthaya | Almacén real, subproducto (S7), barrio chino | 2 + 1,5 | Almacén en el tope ≥ 60 % del tiempo desde la edad II; motor al m15 de 30 a 40 % |
| 3c | Tawantinsuyu | Taller, interruptor (S6), bono conectado en recolección | 2,5 + 1,5 | Mit'a en el tope ≤ 15 %; el aqllawasi (o el hito de la edad III) llega antes del minuto 20 |
| 3d | Palmares | Oficio (S5) y quitar `oculto` | 2,5 + 0,5 | Puestos ocupados ≥ 80 % del máximo desde la edad II; riqueza a los 5 minutos a −9 % de la media o mejor |
| 3e | Mapuches | Corral (S8), fusión del kulliñ, faenar | 3 + 1 | Cabezas promedio ≥ 4 por corral; no más de un faenado cada 4 minutos |
| 3f | Guaraníes | Resiembra (S2), pase automático, tope de yerbales, capuera | 3 + 0,5 | Riqueza a los 30 minutos ≤ +15 % de la media (alerta 1 del diseño) |

Después de **cada** paso: `test_determinism`, `bench`, `civ_smoke` y la curva de riqueza de la civ nueva dentro de ±15 % de la media de las ya implementadas a los 5, 10, 20 y 30 minutos.

### Etapa 4 — La mudanza etíope (2–4 días)
- Modo "corte en marcha" en la IA, victoria con la carpa y la máquina de estados (S4).
- **Aprueba:** en `--paz`, al menos una mudanza por partida antes del minuto 15, ninguna derrota por empacar y ningún tramo de más de 60 s sin aldeanos en producción durante la mudanza. En el torneo, la riqueza a los 30 minutos de Etiopía queda a −10 % de la media o mejor (alerta 2 del diseño).

### Etapa 5 — Lo disputado (3–5 días)
- Ingenios neutrales (S1), tope del saqueo, botín ×1,5 y extras por civ, incursión de la IA a lo neutral.
- **Aprueba:** riqueza disputada dentro del techo por edad (10/25/40/50 %), medida con el informe por origen; prueba del golpe de la ronda 1 (`--golpe=10`): el castigado gana entre el 20 y el 40 %.

### Etapa 6 — Balance y atención (6–8 días)
- `torneo.gd -- --minutes=30 --seeds=4` dos veces seguidas: cada civ entre el 35 y el 65 %. Mediana de la edad II entre 6:30 y 9:00, con no más de 2 minutos de diferencia. Motor al m15 entre 30 y 60 %. Torneo `facil` contra `facil` frente a `normal` (atención, v2/05).
- Las correcciones siguen R6: primero los números periféricos (costos, tiempos), después la mecánica.

---

## 6. Huecos del diseño que hay que cerrar antes de programar

1. **"Caza" no existe.** El almacén real (§3.6) y el plan B de Ayutthaya en el altiplano cuentan con ella. ¿Se agrega como recurso o se usa S7?
2. **Tecnología de motor de Tawantinsuyu:** el diseño la da por un hito de la edad II (aqllawasi), y al resto como investigación de la edad III. ¿Es a propósito? (S9).
3. **Gult con la corte empacada:** ¿los gult cobran el +33 % mientras la carpa viaja? ¿Cerca de qué?
4. **Interruptor sin stock:** si la mit'a no alcanza para todos los talleres, ¿rinden en parte, se apagan en orden de `id` o no rinde ninguno?
5. **Corral dañado y reparado:** ¿reparar repone cabezas? Si sí, se abusa; si no, hay que decirlo en el cartel.
6. **Cupo "más cercano" de los recién llegados:** ¿más cercano a qué? Los acogidos aparecen junto al primer edificio que acoge (`sim_mods.gd:93-97`).
7. **Pradera:** ¿se calcula al construir o se recalcula si talan o crecen árboles (capuera)?
8. **Barreal a ≤ 8 casillas de la corte etíope "por generador":** un cambio en el generador para una sola civ queda espejado para el rival (`_res_sym`). ¿Se acepta, o se usa S4?
9. **Ingenios neutrales:** ¿el bando neutral es un jugador más? ¿Su guardia persigue o se queda en el lugar? ¿Cuenta para la victoria o para los puntos?
10. **Empacar la corte en la edad I** es derrota inmediata con el código actual. ¿Se arregla en la victoria (la carpa cuenta como capital) o se prohíbe empacar sin otro hito?

---

## Autoevaluación del criterio 9

| Civ | ¿Reglas simples? | Nota |
|---|---|---|
| Palmares | Sí | Contar bien a los del oficio |
| Mapuches | Sí | Faenar es un `if` |
| Tawantinsuyu | Sí | Con histéresis y reserva de mit'a para los hitos |
| Ayutthaya | Sí, con búsqueda con puntaje | No construir depósitos comunes junto al bosque |
| Guaraníes | Sí con S2; con bandera, búsqueda con puntaje | El pase automático hay que programarlo |
| Etiopía | **No del todo**: máquina de estados de 4 pasos | Con S4 es acotada y verificable con `--paz` |

**Estado del criterio 9: "Cumple con condiciones"**: Etiopía con S4, guaraníes con S2 o con la búsqueda con puntaje, y la IA común de §1.7 hecha **antes** de medir cualquier motor.
