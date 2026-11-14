# Propuesta de jugabilidad: movimiento en grupo, almacenes y producción militar

Tercer documento del estudio de `proceso/21`. Parte de la referencia ([`01-referencia-aoe4.md`](01-referencia-aoe4.md)) y de la auditoría ([`02-auditoria.md`](02-auditoria.md)). Lo escribe un diseñador con mirada crítica: propone, cuenta qué puede salir mal y cómo medirlo. **No es una decisión.** Lo que acá aparece con números es una propuesta para `data/`; una vez implementado, el dato manda (D-008) y este texto describe solo la intención.

Pedido del autor, resumido: que deje de parecerse al AoE1. Grupos que se mueven juntos (aldeanos en bloque si van lejos, sueltos si el trabajo está cerca; militares siempre agrupados y en formación), almacenes distintos por recurso con aldeanos que se ponen a trabajar solos, y edificios militares separados para que la madera importe. Sin copiar AoE: entenderlo y adaptarlo a pueblos con nombre e historia propios.

---

## Resumen

1. **Grupo con ancla.** Una orden a dos o más unidades cercanas crea un *grupo*: un punto virtual (el ancla) recorre un solo camino A* a la velocidad de la unidad más lenta, y cada unidad sigue su lugar en la formación. Los rezagados corren un 40 % más rápido; si alguno queda a más de 5 casillas de su lugar, el ancla lo espera hasta 8 s y después lo suelta. Todo en enteros, con 16 rumbos fijos en vez de trigonometría.
2. **Orden de la formación por el triángulo, no por AoE.** Adelante la línea (lanzas y escudos), detrás el choque, después la distancia, el asedio y el apoyo. Los montados van a las alas. AoE4 pone la caballería adelante; acá el frente lo sostiene quien vence al choque (D-007).
3. **Cuatro formaciones y una salida:** bloque (por defecto), línea, abierta y columna, más *mover suelto* (Alt + clic derecho) para retirarse a la velocidad de cada uno. La columna no es un adorno: mete a todo el grupo en el Qhapaq Ñan y en los vados.
4. **Aldeanos:** a menos de 16 casillas cada uno corre a lo suyo; a más, viajan en bloque y se sueltan a 6 casillas del trabajo. 16 es el borde de los recursos de casa (los generamos entre 7 y 15 casillas del centro).
5. **Almacenes por recurso en la capa común:** granero (alimento), leñera (madera) y barrero (piedra y arcilla), a 50 de madera cada uno, 2×2. Cada pueblo los nombra y algunos los reemplazan.
6. **Unificados, como excepción:** los mapuches (el lof, que ya recibe todo) y Ayutthaya (el elefante del rey y el palacio, más un almacén de arcilla). Palmares usa el mocambo como leñera; Etiopía no tiene barrero porque lo que se cava va a la corte.
7. **Quien termina un almacén se pone a juntar** lo más cercano que ese almacén recibe. Punto de reunión sobre un almacén = recolectar lo que recibe.
8. **Producción militar separada:** cuartel (choque y línea, edad I), campo de tiro (distancia, I), corral de guerra (montados, II) y taller (asedio, II), todos de madera. Cada pueblo los nombra y cinco de seis se apartan del molde en algo con fundamento: el asedio inca sale del recinto de honderos, el kona mapuche sale del corral, el arquero guaraní se entrena junto al monte, el flecheiro sale del mocambo.
9. **La madera total casi no cambia** a los 20 minutos (estimado: baja en mapuches y Palmares, sube en Etiopía y Ayutthaya). Lo que cambia es que cada función pide su edificio: la madera decide *qué* ejército tenés, no *cuánto*. Si eso no alcanza, la palanca siguiente es poner madera en el jinete y el guerrero.
10. **El plan tiene 11 pasos**, del más barato y reversible (sacar números del código, almacén que pone a trabajar) al más riesgoso (edificios militares por función con la IA y el torneo).

---

## 1. Movimiento y formaciones

### 1.1 Qué es un grupo

Hoy cada unidad recibe su destino y se olvida de las demás (`_cmd_move`, `sim.gd`). La propuesta agrega una estructura nueva en la simulación, `SimGroup`, guardada en `Sim.groups` (diccionario id → grupo, recorrido siempre en orden de id).

| Campo | Qué guarda |
|---|---|
| `id`, `owner` | Identidad y dueño |
| `members` | Ids de las unidades, ordenados |
| `ax`, `ay` | Posición del ancla, en milésimas de casilla |
| `path`, `path_i` | El único camino A* del grupo y por dónde va el ancla |
| `spd` | Velocidad del ancla por tick (la del más lento, ver 1.4) |
| `rumbo` | Índice de 0 a 15 en la tabla de rumbos (ver 1.3) |
| `form` | `bloque`, `linea`, `abierta` o `columna` |
| `state` | `MARCHA`, `ESPERA`, `COMBATE`, `LLEGADA` |
| `wait` | Ticks que lleva esperando |
| `dest_x`, `dest_y` | Destino del ancla |
| `amove` | Si es ataque en movimiento |
| `then_target`, `suelta` | Para aldeanos y ataques a un blanco lejano: qué hacer y a qué distancia soltarse (ver 1.6 y 1.7) |

Y en `SimEntity`, tres campos: `group` (id o −1), `slot_lat` y `slot_fwd` (el lugar en la formación, en milésimas, relativo al ancla). Además, `rumbo` queda guardado en la unidad después de disolverse el grupo, para que "cambiar formación" en el lugar sepa hacia dónde mira.

**Todo esto entra en `state_hash`**: por grupo, `ax`, `ay`, `path_i`, `state`, `wait` y la cantidad de miembros; por unidad, `group`, `slot_lat` y `slot_fwd`.

**Trampa del código.** `_set_idle` hace `e.path.clear()`. Si el camino del grupo se comparte por referencia con las unidades, una sola que quede inactiva borra el camino de todas. El camino vive en el grupo; las unidades que lo siguen guardan solo el índice.

### 1.2 Cuándo se forma un grupo

Se evalúa al aplicar las órdenes `move`, `target` (cuando el blanco está lejos, ver 1.6) y la orden nueva `formar` (cambiar de formación sin moverse).

1. **Quiénes pueden entrar.** Militares (`is_military()`), aldeanos y unidades de carga (el elefante del rey). **Nunca**: explorador, cabeza de ganado, corte en marcha etíope y unidades adentro de un edificio.
2. **Mínimo:** 2 unidades que puedan entrar (`min_unidades`).
3. **Núcleo.** AoE4 forma solo si las unidades ya están "a pocas casillas" (referencia, §1.1). Acá: se cuentan las unidades por celdas de 8×8 casillas, se toma la celda con más unidades (empate: la que tiene la unidad de menor id) y su promedio de posiciones es el centro. Entran al grupo las que están a `formar_radio` (12 casillas) o menos de ese centro. Es O(n), sin comparar todos contra todos.
4. **Los de afuera del núcleo** reciben su lugar en la formación del destino, pero van solos y a su velocidad, sin corrida. Si una selección está partida en dos (la mitad en casa, la mitad en el frente), se arma un grupo con la mitad más numerosa y la otra llega por su cuenta.
5. **Solo aldeanos:** forman únicamente si el destino está a más de `aldeanos_bloque_dist` (ver 1.7).
6. **Con Alt** (o la casilla "Suelto" de la grilla) no se forma nada: cada uno va a su lugar a su velocidad. Es la retirada (ver 1.9).

### 1.3 Geometría en enteros

**Rumbos.** No hay trigonometría: se usa una tabla fija de 16 vectores unitarios multiplicados por 1000, redondeados una sola vez y escritos en el código como constante geométrica (no es un número de balance):

```
(1000,0) (924,383) (707,707) (383,924) (0,1000) (-383,924) (-707,707) (-924,383)
(-1000,0) (-924,-383) (-707,-707) (-383,-924) (0,-1000) (383,-924) (707,-707) (924,-383)
```

Para un vector (dx, dy), el rumbo es el índice que hace máximo `dx·ux + dy·uy` (producto escalar entero); empate, el índice menor. No hace falta `isqrt`. Adelante es u = (ux, uy); el costado es p = (−uy, ux).

**Posición de un lugar.** `x = ax + (ux·fwd + px·lat) / 1000`, igual para y. La división entera de GDScript trunca hacia cero en todas las plataformas: es determinista.

**Separación entre lugares.** Para cada banda (ver abajo), `sep = 2 × radio mayor de la banda + hueco` (`hueco`: 250). Con el guerrero (radio 260) da 770, casi lo mismo que el 750 de hoy; con el elefante de guerra (620), 1490. Entre dos bandas, la distancia de fondo es `radio mayor de la de adelante + radio mayor de la de atrás + hueco`.

**Ancho.** En bloque, `W = isqrt(2n − 1) + 1`, hasta `ancho_max` (20). Con 24 unidades da 7 de ancho por 4 de fondo: el rectángulo 2:1 de AoE4.

**Bandas, de adelante hacia atrás** (`orden_funciones`):

| Banda | Quiénes | Por qué ahí |
|---|---|---|
| 1. Línea | `linea`: lanceros, chewa, lanza larga, awqa | Vence al choque (D-007, contadores 225 %). Aguanta la carga y protege a la distancia |
| 2. Choque a pie | `choque` sin `montado` ni `elefante` | Sale por los huecos contra la distancia enemiga, que es lo que vence |
| 3. Distancia | `distancia`: honderos, arqueros, jabalineros, arcabuceros | Dispara por encima de las dos primeras |
| 4. Asedio | `asedio` | Protegido y al final, como en AoE4 |
| 5. Apoyo | Aldeanos, elefante del rey | Escoltados (ver 1.8) |
| Alas | `choque` con `montado` o `elefante`: jinete, kona, jinete noble, chang suek | A los costados de las dos primeras filas, alternando izquierda y derecha, de a 2 de ancho por ala |

Las alas son una decisión propia, no de AoE4 (que pone la caballería al frente). Tiene base histórica general en las batallas de la época y, sobre todo, de juego: el montado es choque, y el choque pierde contra la línea, así que no conviene que sea lo primero que toca la línea enemiga.

**Asignación sin cruces.** Dentro de cada banda: se ordenan las unidades por su proyección hacia adelante (`(x − cx)·ux + (y − cy)·uy`), de mayor a menor, y se cortan en filas de W; dentro de cada fila se ordenan por la proyección al costado y se asignan de izquierda a derecha. Empates, por id. Es O(n log n) y nadie cruza a nadie en su banda. Cada banda empieza fila nueva; la última fila de cada banda se centra.

### 1.4 Marcha: ancla, velocidad común, corrida y espera

**Un solo camino.** El ancla nace en el centro del núcleo y pide un A* hasta el destino. Si no hay camino, el grupo no se forma y cada unidad recibe la orden de hoy. Un grupo de 60 hace 1 búsqueda en vez de 60 (la auditoría midió 8,2 ms el tick de esa orden).

**Velocidad del ancla.** `spd = mínimo de mods.speed(e)` entre los miembros del núcleo que no estén frenados (`slow_until`) ni peleando, recalculado cada `vel_cada_ticks` (5). Como `mods.speed` ya incluye el camino inca, si todos van por el Qhapaq Ñan el grupo acelera; si la mitad pisa tierra, manda la tierra. Por eso la columna (1.9) sirve.

**Cómo camina cada miembro.** Cada tick, su blanco es su lugar. Se mueve con `_step_toward` hacia él a su propia velocidad, sin pasarse. Como el lugar avanza a la velocidad del ancla, una unidad que está en su lugar camina, de hecho, a la velocidad común. No hace falta `mini(spd, group_speed)` en cada unidad.

**Corrida.** Si una unidad está a más de `holgura` (0,8 casillas) de su lugar, camina a `velocidad × (100 + corrida_pct) / 100`: 40 % para militares, como AoE4 hoy, y 25 % para aldeanos. **No corre** si recibió o dio un golpe en los últimos 30 ticks (3 s, `corrida_sin_combate_ticks`). Es la lección del parche de febrero de 2023 de AoE4 (referencia, §1.1): los aldeanos que huían con +100 % no se podían alcanzar. Acá la corrida sirve para acomodarse, no para escapar.

**Espera.** Cada 5 ticks se mira el mayor atraso (distancia de una unidad a su lugar) entre los miembros que cuentan: no frenados por boleadoras, no peleando. Si supera `espera_dist` (5 casillas), el ancla se detiene (`ESPERA`). Arranca de nuevo cuando el mayor atraso baja de `reanuda_dist` (3 casillas); la diferencia evita que pare y arranque en cada tick. Si espera más de `espera_max_ticks` (80, es decir 8 s) por la misma unidad, la suelta: esa unidad sale del grupo y va sola a su lugar del destino. Un ariete trabado no congela al ejército.

Por qué 5 casillas: a 0,99 casillas por segundo (lancero), una unidad con corrida descuenta 0,4 casillas por segundo al ancla en marcha. Con 5 de atraso tardaría 12 s en volver a su lugar: demasiado. Con el ancla parada cierra a 1,39 por segundo y en 1,5 s baja a 3. Menos de 5 haría parar al grupo en cada curva; más de 5 deja que la formación se estire hasta perder la forma.

**Pasos angostos.** Si el lugar de una unidad cae en una casilla sólida, o la unidad lleva más de 3 ticks trabada (`stuck`), deja de buscar su lugar y sigue el camino del ancla desde el punto más cercano que esté detrás del ancla, sin pedir otro A*. El grupo pasa en fila por un vado y se vuelve a abrir del otro lado. Recién si sigue trabada `stuck > 15` se pide un A* propio (hoy se rinde ahí: ver comodidades, 4).

**Giros.** El rumbo de la marcha es el del tramo del camino que el ancla recorre, pero cambia como mucho una vez cada `giro_min_ticks` (10) y solo si el nuevo rumbo está a 2 o más posiciones de la tabla (más de 22°). Así la formación no gira como un trompo en cada casilla del A*.

**Separación.** Dos miembros del mismo grupo, en `MARCHA`, se empujan al `separacion_grupo_pct` (25 %) de lo normal (`_separate`). Es una comparación entera por par, O(1).

### 1.5 Llegada y disolución

Cuando el ancla llega, el rumbo final es el de la orden (el arrastre del clic derecho lo elige, ver 1.9) o, si no hay, el del último tramo. Cada unidad va a su lugar final y, al llegar a menos de `holgura`, queda inactiva (como hoy). El grupo se disuelve cuando todos llegaron o a los `llegada_max_ticks` (100, 10 s). Los que no llegaron quedan con su orden individual.

### 1.6 Ataque en movimiento y ataque a un blanco lejano

- **Ataque en movimiento** (`amove`). Cada miembro sigue buscando enemigos cada 3 ticks como hoy. Cuando uno encuentra, pasa a `ATTACK` y el grupo pasa a `COMBATE`: **el ancla se detiene** y los demás quedan en su lugar, buscando enemigos en su visión. Así la línea se planta en vez de entrar de a uno. Cuando ningún miembro está en `ATTACK` durante 10 ticks, el ancla sigue, y los que pelearon vuelven **a su lugar** en la formación, no al punto suelto de `amove_x` (falla que marcó la auditoría).
- **Atacar un edificio o una unidad lejos** (`target` sobre un enemigo a más de 16 casillas): el grupo marcha en formación hasta `suelta = alcance mayor del grupo + 2 casillas` del blanco, y ahí cada uno recibe la orden de atacar. Cerca, cada uno ataca directo, como hoy.

### 1.7 Aldeanos: cerca, cada uno; lejos, en bloque

Pedido del autor: si el trabajo está cerca, que vayan todos corriendo; si está lejos, que se agrupen y se esperen. AoE4 no lo hace (los aldeanos no forman, a propósito); es una decisión propia de Raíces.

**Regla.** Sea d la distancia del centro del núcleo al blanco (recurso, cimiento, almacén o punto).

- **d ≤ 16 casillas** (`aldeanos_bloque_dist`: 16000): cada uno va solo, a su velocidad, como hoy.
- **d > 16:** se forma un bloque (formación `bloque`, banda de apoyo). Marcha con el ancla y la espera de 1.4. A 6 casillas del blanco (`aldeanos_suelta_dist`: 6000), el grupo se disuelve y cada uno ejecuta lo que se le pidió (`then_target`): recolectar, construir o entregar.

**Por qué 16.** Los recursos de casa se generan entre 7 casillas (arbustos) y unas 15 (el borde del segundo bosque) del centro de la base (`_generate_map`, `sim.gd`). La arcilla de flanco está a 18. Con 16, todo el trabajo de casa es "cerca" y todo lo que obliga a salir (flanco, centro del mapa, expansión, un cimiento adelantado) es "lejos". Además, a 1,125 casillas por segundo, 16 casillas son 14 s de viaje: por debajo, lo que se pierde esperando (2 a 4 s para juntarse) es una parte grande del viaje; por encima, es poco y lo que se gana es no llegar de a uno a donde puede haber enemigos.

**Por qué soltarse a 6.** Es más que el lado de una arcilla (2×2) o un bosque chico más un margen para que cada uno elija su árbol sin chocarse con el bloque. Menos, y llegan amontonados; más, y vuelve el goteo.

### 1.8 Grupos mixtos: aldeanos y militares

AoE4 no mezcla: los aldeanos no forman ni siquiera con militares. Acá el pedido del autor (militares siempre agrupados, aldeanos en bloque) sugiere una sola regla: **escolta**.

- **Mover o atacar en movimiento con aldeanos y militares seleccionados:** una sola formación, los aldeanos en la banda de apoyo (al fondo). La velocidad es la del más lento, como siempre. En `amove`, los aldeanos se mueven pero no buscan pelea: cuando el grupo entra en `COMBATE`, ellos se quedan en su lugar.
- **Mandar a recolectar o construir lejos con militares seleccionados:** el grupo marcha junto hasta la distancia de suelta; ahí los aldeanos se ponen a trabajar y los militares se quedan inactivos en sus lugares, alrededor del punto de suelta, mirando hacia afuera de la base (el rumbo de la marcha). Es una expansión escoltada con un solo clic.
- **Mandar a recolectar cerca (≤ 16)**: los aldeanos van solos a su trabajo y los militares se mueven en formación al blanco, como hoy (`plain` en `_cmd_target`).

### 1.9 Formaciones elegibles

Pocas, y cada una con un uso que el jugador pueda ver:

| Formación | Forma | Para qué sirve en Raíces |
|---|---|---|
| **Bloque** (por defecto) | Rectángulo 2:1 por bandas | Uso general |
| **Línea** | 2 filas de fondo (`linea_filas`), hasta 40 de ancho (`ancho_max_linea`) | Que la distancia reparta el daño y nadie quede atrás sin disparar; envolver |
| **Abierta** | Como el bloque, con el doble de hueco (`abierta_hueco_pct`: 200) | Contra el daño de área: el elefante de guerra siamés (`area` 1600) y las andanadas de los edificios con guarnición |
| **Columna** | 2 de ancho (`columna_ancho`) | Marchar por el Qhapaq Ñan (1 casilla de ancho: con bloque, la mitad del grupo pisa tierra y el ancla va a la velocidad de la tierra), por vados y entre peñas. Ningún AoE la da para tierra; acá tiene una razón concreta |
| **Suelto** (Alt + clic derecho) | Sin grupo | Retirarse a la velocidad de cada uno. Lo más pedido en el foro de AoE4 (referencia, §6). La IA lo usa al retirarse |

La orden `move` gana dos campos: `form` y `rumbo` (de 0 a 15). El cliente calcula el rumbo del arrastre con la misma tabla de enteros, así que la orden ya llega cerrada a la simulación. La orden nueva `formar` (ids, form) arma un grupo con destino en el centro actual y el último rumbo guardado: cambia la formación sin moverse, como en AoE4.

### 1.10 Números propuestos para `data/reglas.json`

Distancias en milésimas de casilla; tiempos en ticks de 100 ms.

```json
"grupos": {
  "_doc": "Movimiento en grupo (docs/diseno/jugabilidad/03, §1).",
  "min_unidades": 2,
  "formar_radio": 12000,
  "celda_nucleo": 8,
  "hueco": 250,
  "ancho_max": 20,
  "ancho_max_linea": 40,
  "linea_filas": 2,
  "columna_ancho": 2,
  "abierta_hueco_pct": 200,
  "ala_ancho": 2,
  "orden_funciones": ["linea", "choque", "distancia", "asedio", "apoyo"],
  "holgura": 800,
  "corrida_pct": 40,
  "corrida_aldeano_pct": 25,
  "corrida_sin_combate_ticks": 30,
  "vel_cada_ticks": 5,
  "espera_dist": 5000,
  "reanuda_dist": 3000,
  "espera_max_ticks": 80,
  "giro_min_ticks": 10,
  "trabado_sigue_camino": 3,
  "separacion_grupo_pct": 25,
  "llegada_max_ticks": 100,
  "combate_calma_ticks": 10,
  "ataque_lejos": 16000,
  "ataque_suelta_extra": 2000,
  "aldeanos_bloque_dist": 16000,
  "aldeanos_suelta_dist": 6000
}
```

Más tres números que hoy están escritos en el código y van a `reglas.json` en el primer paso: la separación del cuadrado (`750`, que pasa a ser `hueco` + radios), el radio para encadenar cimientos (`10000` en `_do_build`, como `encadenar_radio`) y la distancia de "recurso lejos del almacén" de la IA (`4500` en `_far_gather_point`, como `ia.almacen_lejos`).

**Ejemplo con la medición de la auditoría** (24 incas mixtos a 40 casillas): el más lento del grupo es el lancero (1100 × 90 % = 0,99 casillas por segundo; el "ariete" inca, el hondero de piedra caliente, va a 1,08). Llegarían todos juntos hacia los 42 o 43 s: 2 o 3 s después que el último de hoy (40,1 s), pero en formación, en vez de jinetes solos a los 19 s. Con el ariete común (750) el mismo grupo tardaría unos 59 s: ver la crítica, §5.4.

---

## 2. Almacenes

### 2.1 Capa común (`data/edificios.json`)

| Clave | Nombre común | Recibe | Costo | Tamaño | Tiempo | Vida |
|---|---|---|---|---|---|---|
| `almacen_alimento` | Granero | alimento | 50 de madera | 2×2 | 20 s | 600 |
| `almacen_madera` | Leñera | madera | 50 de madera | 2×2 | 20 s | 600 |
| `almacen_mina` | Barrero | piedra y riqueza (arcilla) | 50 de madera | 2×2 | 20 s | 600 |
| `deposito` | Depósito | los cuatro | 75 de madera | 2×2 | 20 s | 600 |

- **Por qué piedra y arcilla juntas:** las dos se cavan, y las dos están a 10 casillas del centro en la misma generación del mapa. Es el campamento minero de AoE4 (oro y piedra) con nuestra materia.
- **Por qué 50:** es el precio de AoE4 y es lo que hace que convenga poner uno al lado de cada recurso, en vez de uno grande y lejos. Hoy el depósito vale 75 y la IA hace hasta 4.
- **El `deposito` unificado queda en la capa común** porque lo usan los invasores (solo IA) y las campañas (como alias, `alias_campana`). Ningún pueblo jugable lo construye salvo que su ficha lo pida.
- **Grilla** (`data/interfaz.json` → `grilla.economia`): leñera en la casilla 2 (donde hoy está el depósito), granero en la 8 y barrero en la 9.

### 2.2 Por pueblo

Los nombres en lenguas originarias llevan `[verificar]` hasta que la ficha de la civ cite la fuente (regla 5 del índice). Donde no encontré un nombre confiable, propongo uno en castellano y lo marco.

| Pueblo | Alimento | Madera | Piedra y arcilla | Recibe todo |
|---|---|---|---|---|
| Tawantinsuyu | **Qollqa** (ya existe) | **Llant'a wasi** | **Kamayuq wasi** | Llaqta; más adelante, **Tambo** junto al camino |
| Mapuches | — | — | — | **Lof** (unificado) |
| Guaraníes | **Tapyi** (alimento y madera) | (el mismo Tapyi) | **Ñai'ũ renda** | Oga guasu |
| Etiopía | **Gotära** | **Inchet bet** | — (la corte) | Kätäma |
| Palmares | **Paiol** | — (el mocambo) | **Olaria** | Cerca real, **Mocambo** |
| Ayutthaya | (elefante del rey) | (elefante del rey) | **Khlang din** (solo arcilla) | Wang, **elefante del rey** (alimento, madera, piedra) |

**Tawantinsuyu: el pueblo más especializado.**
- *Qollqa* (quechua: depósito del Estado). Ya recibe solo alimento y leva escuadrones (awqa). Se queda como está: 40 de piedra y 20 de mit'a. Las qollqas guardaban sobre todo comida, en hileras junto a centros y caminos (`investigacion/tawantinsuyu.md`, D'Altroy y Hastorf).
- *Llant'a wasi* (quechua: *llant'a*, leña; *wasi*, casa) `[verificar]`. Leñera, 50 de madera.
- *Kamayuq wasi* (quechua: casa de los *kamayuq*, los especialistas que el Estado asentaba junto a su materia: alfareros, canteros) `[verificar el uso de kamayuq para estos oficios]`. Barrero, 50 de madera.
- *Tambo* (quechua *tampu*: posta del camino con depósitos). Hoy es el nombre del depósito común. Propuesta, en un paso posterior: un almacén que recibe todo, a 100 de madera y 20 de mit'a, que **solo se puede poner pegado a un tramo de camino**. Así el único almacén unificado inca es el de la red, como en la historia (tambos a una jornada de marcha, `investigacion/tawantinsuyu.md`). Choca con la clave `tambo` que ya usa el regalo de cumbi: habría que renombrar esa a `tambo_real`.
- **Por qué no unificado:** el almacenamiento estatal inca es justamente el caso histórico de depósitos especializados y contados (khipu).

**Mapuches: unificado, y es la excepción con más sentido.**
- No hay almacenes propios. El *lof* (comunidad de parentesco que vive dispersa, cada una con su *lonko*) recibe todo, da 8 de población y entrena aldeanos: ya es "el centro chico" de la ficha. Se saca el *Troje* (depósito común renombrado; además "troje" es palabra castellana).
- **Historia:** no hubo Estado ni almacenes de gobierno; cada lof guardaba lo suyo `[verificar con la ficha]`. **Juego:** su identidad es la dispersión; cada almacén es una pequeña base. Un lof cuesta 110 contra 50 de un almacén, pero da población (lo que valdría media casa) y aldeanos.
- **Efecto buscado en el balance:** los mapuches son la civ que más gana en el torneo (68 % con la cría a 50 s, `09-estado.md`). Perder el almacén barato es un recorte con sentido, no un castigo arbitrario.

**Guaraníes: el monte y la roza son lo mismo.**
- *Tapyi* (guaraní: rancho, choza del monte). Recibe **alimento y madera**, 60 de madera. La roza se abre talando el monte, y la roza rinde +15 % con 4 árboles cerca (economía v3, §3.5.3): el mismo rancho al borde del monte sirve para las dos cosas.
- *Ñai'ũ renda* (guaraní: *ñai'ũ*, barro, arcilla; *renda*, lugar) `[verificar]`. Barrero, 50 de madera. La cerámica tupiguaraní (las grandes urnas) es de lo más documentado de su cultura material `[verificar con la ficha]`.

**Etiopía: lo que se cava va a la corte.**
- *Gotära* (amhárico: granero; la troja de cestería sobre zócalo de la meseta) `[verificar]`. Granero, 50 de madera.
- *Inchet bet* (amhárico: *inchet*, madera, leña; *bet*, casa) `[verificar]`. Leñera, 50 de madera.
- **Sin barrero.** La corte ya extrae arcilla sola a 12 casillas (economía v3, §3.5.4) y se muda cerca de la arcilla nueva. Que la piedra y la arcilla que juntan los aldeanos vayan a la corte refuerza la decisión de dónde fundarla. **Historia:** la corte vivía del tributo que llegaba a ella y agotaba su entorno (Horvath, citado en la economía v3).

**Palmares: el mocambo está en la mata.**
- *Paiol* (portugués: almacén de granos; también de pólvora). Granero, 50 de madera. Los atacantes de 1681 quemaron los "almacenes de mantenimientos" (`investigacion/palmares.md`).
- *Olaria* (portugués: alfarería). Barrero, 50 de madera. `[verificar alfarería en Palmares; la economía v3 nombra al alfarero entre los oficios]`.
- **Sin leñera.** El *mocambo* (del kimbundu *mukambu*, escondite `[verificar]`) ya recibe todo, da población y rinde más fama con 6 árboles cerca: se pone en el monte y hace de leñera. Es "semiunificado" con sentido: el pueblo vive escondido en la mata.

**Ayutthaya: el almacén camina.**
- Se queda el *elefante del rey* (*chang luang*), que recibe alimento, madera y piedra y cobra su parte (economía v3, §3.5.6), y el *wang* (palacio), que recibe todo.
- Se agrega un solo almacén: *Khlang din* (tailandés: *khlang*, almacén; *din*, tierra) `[verificar]`. Recibe **solo arcilla**, 50 de madera. Hoy toda la arcilla de Ayutthaya viaja hasta el palacio, porque el elefante no la recibe: es justo el ejemplo del autor ("un almacén de arcilla al lado de la arcilla").
- **Cambia una regla de la economía v3** ("No construye depósito común: sus depósitos son el palacio y los elefantes"). Hay que preguntarle al autor (§7).

**Invasores** (solo IA y campañas): siguen con el `deposito` unificado. Una expedición colonial con su fuerte y su almacén; no necesitan asimetría.

### 2.3 Comportamiento

1. **Terminó un almacén → recolecta.** En `_do_build`, cuando el edificio terminado tiene `deposito` y no tiene `produce` ni `pob` (o sea, no es un centro ni un lof): cada constructor, primero, entrega lo que carga si el almacén lo recibe (está al lado); después busca con `find_resource` el recurso aceptado más cercano **al almacén** (no a sí mismo), a `radio_al_terminar` (8 casillas) o menos. Si el almacén recibe dos recursos (barrero, tapyi), elige el que el jugador marcó al ponerlo (campo opcional `recurso` en la orden `build`, que la interfaz manda si el cimiento se puso sobre un recurso) o, si no, el más cercano. Esta regla va **antes** de encadenar otro cimiento: hoy un aldeano que termina un almacén junto a la arcilla se va a construir la casa de al lado o vuelve a juntar alimento.
2. **Terminó una granja → se queda** (ya existe). Si eran varios, los que sobran buscan otra granja libre o cimiento de granja a 10 casillas, y si no hay, alimento cerca. Es la queja más repetida en AoE4 (referencia, §2.3) y acá se resuelve de entrada.
3. **Punto de reunión sobre un almacén propio:** el aldeano nuevo recolecta el recurso aceptado más cercano al almacén (`_spawn_from`). Sobre un centro, lof o mocambo (que reciben todo), no se infiere nada: va al punto, como hoy.
4. **Se agotó el recurso:** busca otro del mismo tipo a 10 casillas de sí (como hoy) y, si no hay, a 10 casillas **del almacén** donde entregó la última vez (`aux`). Así no se aleja hacia el otro lado del mapa por haber quedado en el borde del bosque.
5. **Construyó o reparó un almacén estando de paso:** si después de reparar no hay recurso cerca, vuelve a lo que hacía (`gather_kind`), como hoy.

Números para `reglas.json`: `"almacenes": { "radio_al_terminar": 8000, "rebusca_desde_almacen": 10000 }`.

### 2.4 Tecnologías por capacidad

Hoy las tecnologías se atan al tipo de edificio. Eso ya rompe a dos civs (auditoría, §2): Ayutthaya no puede investigar tala, cantería ni orfebrería, y los mapuches no pueden investigar cestas, riego ni mampostería. Con almacenes separados se rompería más.

Propuesta: en `tecnologias.json`, `"en"` reemplaza a `"edificio"`:
- `"en": {"deposito": "madera"}`: se investiga en cualquier edificio propio terminado que reciba madera (leñera, tapyi, centro, lof, mocambo, wang). Así: `hachas`, `hachas_2` → madera; `canteria` → piedra; `orfebreria` → riqueza; `cestas`, `riego`, `riego_2` → alimento.
- `"en": {"tipo": "centro"}` para las que son del centro de verdad (`mamposteria`, `vigias`), con los lof contando como centro (D-023 ya lo dice).
- `"en": {"produce": ["choque", "linea"]}` para las militares (ver §3).

Se resuelve en `research_block` y `_cmd_research` (simulación), en `commands()` de `controller.gd` (interfaz) y en `_research` de `sim_ai.gd` (IA). Una tecnología ya investigada sigue sin poder repetirse aunque haya varios edificios.

---

## 3. Edificios de producción militar

### 3.1 Capa común (`data/edificios.json`)

| Clave | Nombre común | Edad | Costo | Tamaño | Tiempo | Produce |
|---|---|---|---|---|---|---|
| `cuartel` | Cuartel | I | 150 de madera | 3×3 | 35 s | Choque a pie (guerrero), línea (lancero) |
| `campo_tiro` | Campo de tiro | I | 150 de madera | 3×3 | 30 s | Distancia (hondero) |
| `establo` | Corral de guerra | II | 175 de madera | 3×3 | 35 s | Montados (jinete) |
| `taller` | Taller de asedio | II | 200 de madera | 3×3 | 40 s | Asedio (ariete) |

- **Por qué el campo de tiro en la edad I y no en la II, como AoE4:** nuestro triángulo está completo desde la edad I (el hondero es unidad básica y es la identidad de incas y guaraníes) y la edad I dura más que en AoE4 (la II llega entre 5:30 y 8:15 según la auditoría). Separar sí; quitar la distancia de la primera edad, no.
- **La pólvora no tiene edificio común.** El arcabucero llega por adopción (glosario del índice): por un hito (Vilcabamba, Misión, Alianza) o por un edificio propio (barrio portugués, tenda de ferreiro). Es el tema del juego, y separa a cada pueblo.
- **Las mejoras militares** (`armas_*`, `escudos_*`, `marcha`, `adiestramiento`) pasan a `"en": {"produce": [...]}` y se investigan en cualquier edificio que produzca esas funciones. No agrego una herrería: sería un edificio más sin decisión.
- **Los hitos militares siguen produciendo** lo que producen hoy.

### 3.2 Por pueblo

| Pueblo | Choque | Línea | Distancia | Montados | Asedio | Pólvora | Propios |
|---|---|---|---|---|---|---|---|
| Tawantinsuyu | Kallanka | Kallanka; Qollqa (awqa) | **Warak'a kancha** | Vilcabamba (hito) | **Warak'a kancha** | Vilcabamba (hito) | — |
| Mapuches | **Lof** (weichafe) | Ruka de guerra | Ruka de guerra | **Corral** (kona) | — | — | — |
| Guaraníes | Aty de guerra | Aty de guerra | **Guyrapa róga** | — | Taller de tacuara | Misión (hito) | — |
| Etiopía | **Färäs bet** (jinete noble, edad I) | Campamento de chewa | Campamento de chewa | Färäs bet | Taller | Alianza (hito) | — |
| Palmares | Casa de guerra | Casa de guerra | **Mocambo** | — | — | **Tenda de ferreiro** | — |
| Ayutthaya | Cuartel de la guardia | Cuartel de la guardia | Sanam ying thanu | Kraal (chang suek) | Taller | Barrio portugués | Barrio japonés |
| Invasores | Cuartel (todo) | Cuartel | Cuartel | Cuartel | Cuartel | Cuartel | — |

En negrita, donde el pueblo se aparta del molde.

**Tawantinsuyu: el asedio es honda.**
- *Kallanka* (quechua: gran galpón techado donde se alojaba la tropa y se hacían reuniones) `[verificar]`: guerrero de porra y lancero con escudo. 150 de madera, edad I.
- *Warak'a kancha* (quechua: *warak'a*, honda; *kancha*, recinto cercado) `[verificar el nombre compuesto]`: hondero (I), boleador (II) y **hondero de piedra caliente** (el asedio inca, II). 150 de madera, edad I. **Sin taller.** En el sitio de Cusco de 1536 los hombres de Manco Inca incendiaron los techos de paja con piedras calentadas lanzadas con honda (`investigacion/tawantinsuyu.md`). Que el asedio salga del recinto de honderos dice eso sin palabras.
- *Qollqa*: leva (awqa), como hoy.
- Montados y pólvora, solo por Vilcabamba: lo que se capturó después de 1537.

**Mapuches: cada lof pone su gente (como los mongoles de AoE4, pero por otra razón).**
- *Lof*: aldeano, explorador **y weichafe** (*weichafe*: guerrero). El lof tiene una sola cola: o hace gente o hace guerreros. Esa tensión es la decisión mapuche. **Historia:** la guerra se hacía con la gente de cada lof convocada por un toqui, no con un ejército permanente `[verificar con la ficha]`.
- *Ruka de guerra* (*ruka*: casa): lanza larga y arquero. **120 de madera** (más barata: no es un cuartel permanente). Edad I.
- *Corral*: **kona montado** desde la edad II (*kona*: guerrero joven; el caballo se crió en los rebaños mapuches desde fines del siglo XVI) `[verificar]`. El corral ya existe como pieza del motor (120 de madera, cabezas de ganado). El caballo sale de la hacienda: une economía y ejército. **Cuidado:** que entrenar no toque las cabezas, para no mezclar la cría con la producción.
- **Sin asedio**, como hoy.
- **Contradicción a resolver:** la descripción de la civ dice "el caballo desde la edad III", pero `unidades.jinete.edad_min` es 2 en `data/civs/mapuches.json`.

**Guaraníes: el arquero se entrena en el monte.**
- *Aty de guerra* (*aty*: reunión, asamblea): guerrero de macana y lancero. 150 de madera, I.
- *Guyrapa róga* (guaraní: *guyrapa*, arco; *róga*, casa de) `[verificar]`: arquero. **100 de madera, 2×2, y solo se puede poner con 4 árboles o más a 3 casillas.** Más barato y chico, para tener varios junto al monte. Encaja con el sigilo (emboscada +40 % desde el monte y el yerbal). La regla de lugar es la misma cuenta de árboles que ya usan la roza y el mocambo (`_engine_slot_ok`).
- *Taller de tacuara* (*tacuara*: caña gruesa): el cañón de tacuara, II. 150 de madera (más barato que el común: es caña). `[verificar los cañones de tacuara en las misiones, Mbororé 1641]`.
- Pólvora y lanceros extra por la Misión, como hoy.

**Etiopía: caballería desde la edad I, en su propio corral.**
- *Campamento de chewa* (*chewa*: regimientos asentados en tierras del rey) `[verificar]`: chewa (línea) y jabalinero (distancia). 150 de madera, I. Juntar línea y distancia en el mismo edificio es la única "unificación" etíope: los regimientos combinaban lanza y jabalina `[verificar]`.
- *Färäs bet* (amhárico: *färäs*, caballo; *bet*, casa) `[verificar]`: jinete noble (el `guerrero` etíope ya es montado). **Edad I**, 150 de madera. Para tener el triángulo en la edad I necesita dos edificios, como todos.
- Taller común (ariete), II.

**Palmares: el flecheiro defiende su mocambo.**
- *Casa de guerra*: gente de guerra y lanceiro. 150 de madera, I.
- *Mocambo*: **flecheiro** (*flecheiro*: arquero). Palmares no entrena aldeanos, así que la cola del mocambo está libre: no hay la tensión mapuche, hay dispersión (cada aldea arma a los suyos).
- *Tenda de ferreiro* (portugués: taller de herrero): espingardeiro, II. 150 de madera y 50 de piedra. **Historia:** las fraguas de Palmares (las cuarenta herrerías de 1694, economía v3) arreglaban y hacían armas; las armas de fuego llegaban por rescate, comercio y saqueo. Hoy el espingardeiro sale de la casa de guerra.
- **Sin asedio**, como hoy.

**Ayutthaya: el ejército de todas las naciones.**
- *Cuartel de la guardia*: infantería de *dap* (espada) y lancero. 150 de madera.
- *Sanam ying thanu* (tailandés: campo de tiro con arco) `[verificar]`: arquero. 150 de madera, I.
- *Kraal*, *barrio japonés* y *barrio portugués*: como hoy.
- Taller común (ariete), II.
- Ya es la civ con más edificios de producción. Con la separación queda la que más madera pide, y es coherente: el elefante del rey cobra sobre la madera del monte.

**Invasores**: un cuartel que produce todo. Es solo IA y de campaña; una expedición colonial con su fuerte.

### 3.3 Por qué cinco de seis se apartan

AoE4 tiene una regla (cuartel, arquería, establo, taller) y unas pocas excepciones fuertes (mongoles, otomanos). Acá la proporción es al revés a propósito, por D-003 (asimetría radical): la capa común define las cuatro funciones de producción, y cada pueblo las reparte según su historia. Lo que **no** cambia en ninguno: cada función pide un edificio de madera que hay que decidir hacer. Ningún pueblo produce choque, distancia y línea desde un solo edificio (la excepción más cercana, Etiopía, junta línea y distancia, y paga el choque aparte).

### 3.4 Cuánta madera

Estimación con lo que la IA hace hoy a los 20 minutos (auditoría, §3): 2 a 5 cuarteles (300 a 750 de madera) y hasta 4 depósitos (300).

| Pueblo | Producción (típico a los 20 min) | Almacenes | Total | Hoy (cuarteles + depósitos) |
|---|---|---|---|---|
| Tawantinsuyu | 2 kallanka + 2 warak'a kancha = 600 | 2 leñeras + 2 barreros = 200 | 800 | 450–750 + 300 |
| Mapuches | 2 rukas de guerra = 240 (más lof y corral, que ya hace) | — (lof) | 240 + lof | 300–450 + 300 |
| Guaraníes | 2 aty + 3 guyrapa róga + 1 taller = 750 | 2 tapyi + 1 barrero = 170 | 920 | 600–750 + 300 |
| Etiopía | 2 campamentos + 1 färäs bet + 1 taller = 650 | 2 gotära + 2 inchet bet = 200 | 850 | 300–450 + 300 |
| Palmares | 2 casas de guerra + 1 tenda = 450 | 2 paiol + 1 olaria = 150 | 600 + mocambos | 450 + 300 |
| Ayutthaya | 2 cuarteles + 2 sanam + kraal + barrio + taller = 1150 | 2 khlang din = 100 | 1250 | 300–750 + 0 |

Lectura honesta: **la madera total casi no cambia.** Baja en mapuches (de 600–750 a 240 más lo que ya gastan en lof) y en Palmares (unos −150), queda igual en guaraníes y Tawantinsuyu (−250 a +50), sube en Etiopía (+100 a +250) y bastante en Ayutthaya (+500 a +950). La auditoría ya mostraba que la madera no sobra (26 a 33 % de lo juntado). Lo que cambia es la **decisión**: con un cuartel ya no alcanza para tener el triángulo, y cambiar de composición a mitad de partida cuesta un edificio nuevo. Eso es lo que el autor sintió que faltaba.

### 3.5 Precios a probar en el balance (no en el primer paso)

Si después de separar los edificios el torneo y la prueba con el autor dicen que la madera sigue sin pesar, la palanca siguiente es poner madera en las unidades que hoy no la piden, como AoE4 (lancero 20, jinete 20):

| Unidad | Hoy | A probar |
|---|---|---|
| Jinete (común) | 100 a + 70 r | 100 a + 20 m + 50 r |
| Guerrero (común) | 60 a + 25 r | 55 a + 15 m + 15 r |
| Kona montado | 70 a + 45 r | 70 a + 15 m + 30 r |

Se prueba de a una, con `tests/torneo.gd -- --minutes=30 --seeds=2` antes y después.

---

## 4. Comodidades, en orden

Primero las fallas, después lo que falta. "Costo" según la escala de la auditoría.

| # | Qué | Por qué ahora | Costo | Dónde |
|---|---|---|---|---|
| 1 | **Lo encolado con Mayús detrás de recolectar nunca sale** (falla) | Rompe una comodidad que ya existe | Chico | `mundo_cola.gd`: dar por terminada la orden de recolectar cuando el aldeano entrega y el recurso se agotó, o cuando cambia de blanco |
| 2 | **Tecnologías por capacidad** (falla: Ayutthaya y mapuches no pueden investigar) | Prerrequisito de los almacenes | Chico | §2.4 |
| 3 | **Volver a buscar camino antes de rendirse** (`stuck > 15` da la orden por cumplida) | Con grupos, una unidad trabada frena a las demás | Chico | `_follow`: un A* nuevo la primera vez; recién la segunda se rinde |
| 4 | **Números escritos en el código a `data/`** (750, 10000, 4500, proporciones de aldeanos de la IA) | Regla 4 de `CLAUDE.md`; el balance los va a tocar | Chico | §1.10 |
| 5 | **Botón de aldeanos ociosos** con la cuenta, junto al minimapa; Mayús + `.` toma a todos | Con almacenes que ponen a trabajar, el ocioso que queda es el que importa | Chico | `hud.gd` |
| 6 | **Seleccionar todo el ejército / el ejército inactivo** (una tecla cada uno) | Con grupos, es la orden más usada | Chico | `controller.gd` → `_key`; F2 hoy abre un panel: mover el panel o usar otra tecla |
| 7 | **Encolar repartido**: un clic con varios edificios encola en el de cola más corta | Con producción separada habrá más edificios del mismo tipo | Chico | `controller.gd` → `run_command`, rama `"train"` |
| 8 | **Seleccionar todos los edificios de un tipo** (Ctrl + doble clic) y **aviso de edificio militar parado** | Con 4 a 8 productores, no se ven todos | Chico | `controller.gd`, `hud.gd` |
| 9 | **Cola de construcción con Mayús de verdad** | Hoy se hace el último primero y los que están a más de 10 casillas quedan sin hacer | Medio | En el cliente, como `mundo_cola.gd` (no toca la simulación) |
| 10 | **Mantener posición** | La unidad inactiva persigue sin límite; con formaciones, una línea que se desarma sola pierde sentido | Chico | `SimEntity.stance`; `_do_idle` y `_do_attack` solo pegan a lo que está en alcance |
| 11 | **Patrullar** | AoE4 lo sumó en 2022 y se lo reclamaron | Chico | Orden `patrol` que alterna dos puntos con `amove`; en grupo, el ancla alterna |
| 12 | **Mostrar el costo total al arrastrar muros** | Pequeño, pero se nota | Chico | `controller.gd` → `_show_line` |

Quedan para después: posturas completas con correa (AoE4 tampoco las tiene), cola global de producción y orientación por arrastre en grupos que ya están quietos.

---

## 5. Crítica

### 5.1 Balance (torneo: 5 de 6 civs entre 35 y 65 %)

| Cambio | Quién gana | Quién pierde | Qué mirar |
|---|---|---|---|
| Almacenes a 50 en vez de 75, y cerca | Todos, la economía sube algo | — | La edad II: la economía v3 la fijó entre 6:30 y 8:50. Si baja de 6:00, subir el costo a 60 |
| Mapuches sin almacén barato | — | Mapuches (hoy 68 %) | Que bajen a la banda sin pasar de largo |
| Etiopía sin barrero | — | Etiopía (viajes largos con piedra y arcilla) | Arcilla juntada por minuto antes y después; si cae más de 10 %, el barrero vuelve con nombre propio |
| Ayutthaya con khlang din | Ayutthaya | — | Hoy entra en la banda; un almacén de arcilla al lado puede subirla 3 a 5 puntos |
| Producción separada | Quien defiende | Quien rushea: mapuches (malón), Etiopía (jinetes desde la I) | Las dos civs de ataque temprano pagan un edificio más antes del primer golpe. Etiopía lo paga en la edad I con el färäs bet |
| Velocidad común | Quien defiende (el ataque llega junto pero más lento) | Ejércitos mixtos con asedio común | Duración de las partidas: si la mediana sube más de 15 %, revisar |
| Lof que entrena weichafe | Mapuches (más lugares para producir) | Mapuches (la cola compite con los aldeanos) | Aldeanos mapuches al minuto 10 antes y después |

**Regla de oro:** un cambio por vez en el torneo. Primero el movimiento (no debería mover el balance más de 3 puntos), después los almacenes, después la producción.

### 5.2 La IA (`sim_ai.gd`)

Lo que se rompe y cómo arreglarlo:

| Supuesto de hoy | Arreglo |
|---|---|
| Hay un `cuartel` (`_buildings`, `_wants_hito`, margen de casas) | Derivar al cargar, por civ, un mapa **función → edificios que la producen** desde los `produce` de los datos. La IA asegura un productor de choque o línea a los 11 aldeanos, uno de distancia a los 14, y los de montados y asedio en la edad II. Los extras ("si sobra") van al edificio que produce la primera unidad de `_counter_order` |
| `_makes_military` solo cuenta choque, distancia y línea | Sumar `asedio`. Y **excluir de la producción militar a los edificios que entrenan aldeanos** (lof) mientras falten aldeanos: si no, todos los lof que no son la capital se ponen a hacer weichafe y la economía mapuche se para |
| El `_wants_hito` de la edad III pide un `cuartel` | "Algún edificio que produzca militares" |
| Los almacenes se llaman `deposito` y reciben todo | Derivar, por civ, **recurso → almacén**: entre los tipos de `construye` que reciben ese recurso, el de lista `deposito` más corta y, si empatan, el más barato. Mapuches → lof; guaraníes, madera → tapyi. Hasta 3 por recurso. El constructor es el aldeano de ese recurso más cercano |
| Los aldeanos buscan recurso desde el centro (`_economy`) | Buscar desde el almacén de ese recurso más cercano al centro |
| La IA no se retira | Usar `move` con `suelto` cuando el ejército pierde (lo que ya decide `_military`) |
| Etiopía no tiene barrero | Ya funda la corte junto a la arcilla (`_found_court`); verificar que la piedra no quede sin juntar |
| Guyrapa róga necesita árboles cerca | `_site_near` con la misma regla de lugar; si no encuentra, el arquero sale del hito Aty guasu |

Los grupos, en cambio, la IA los aprovecha sin cambios: `_attack` ya manda a todo el ejército con un solo `move` con `amove`.

### 5.3 Rendimiento y determinismo

- **Banco de hoy:** 200 unidades, 8,41 ms de promedio por tick y 80,79 ms el peor, con 100 ms de presupuesto (auditoría). El peor está muy cerca del techo: cualquier pico nuevo se nota.
- **Lo que mejora:** un A* por grupo en vez de uno por unidad. La orden de 60 unidades pasa de 60 búsquedas (8,2 ms) a 1. También mejora A-009: menos llamadas a `AStarGrid2D`.
- **Lo que cuesta:** armar la formación es O(n log n) una vez por orden; el núcleo, O(n); por tick, el ancla es O(1) y la revisión de espera, O(n) cada 5 ticks. La separación suma una comparación por par. `nearest_dropoff` recorre todos los edificios por cada entrega: con 3 almacenes por recurso y por jugador, en partidas de 6 eso crece. Si el banco lo marca, indexar los almacenes por recurso (lista por jugador, actualizada al terminar o morir un edificio).
- **Determinismo:** todo entero; grupos recorridos por id; miembros ordenados; empates por id en todas las elecciones; la tabla de rumbos es constante. Lo único nuevo que puede romper el hash es olvidar un campo en `state_hash`: la prueba de determinismo con grupos lo detecta (dos corridas con la misma semilla y órdenes de grupo).
- **Repeticiones:** el grupo nace de un comando, así que la repetición lo reconstruye sola.

### 5.4 Riesgos de diseño (lo que puede salir mal con estas mismas reglas)

1. **El ariete común frena a todo el ejército.** A 0,675 casillas por segundo, un grupo con ariete tarda un 47 % más que uno con lanceros. Es la queja de AoE4 (referencia, §6). No propongo sacarlo de la regla (así el asedio es una decisión), pero hay que medir: si la IA pierde ataques por llegar tarde, que mande el asedio como grupo aparte, detrás. El ariete inca (1,08) y el guaraní (0,9) no tienen el problema.
2. **Las boleadoras incas frenarían a un grupo entero.** Un solo golpe frena a una unidad 45 %; si esa unidad contara para la velocidad y la espera, el boleador frenaría todo el ejército enemigo. Por eso las unidades frenadas no cuentan (1.4). Hay que probarlo con una pelea de boleadores contra un grupo.
3. **El elefante del rey en un grupo.** Es de apoyo y va a 0,765: un grupo que lo incluya va a su paso. Es raro mandarlo con el ejército, pero puede pasar con "seleccionar todo".
4. **El relevo mapuche** (cura fuera de combate) premia sacar heridos: con espera, el grupo no deja a nadie atrás, lo que ayuda. Con "suelto" se siguen pudiendo sacar.
5. **Caminos incas y formación ancha.** Con bloque, el ancla va a la velocidad de la tierra aunque el centro vaya por el camino. Si el jugador inca no descubre la columna, va a sentir que los caminos "dejaron de andar". Hace falta un aviso o que la IA y la ayuda (F1) lo enseñen; o que la formación por defecto inca sea la columna cuando el ancla está sobre camino.
6. **Aldeanos en bloque bajo ataque.** Un bloque de aldeanos que marcha por el centro del mapa es un blanco lindo. Que se suelten al recibir daño (cualquier miembro en combate disuelve un grupo solo de aldeanos) y sigan cada uno a lo suyo.
7. **El lof que entrena weichafe** puede volver a los mapuches demasiado fuertes en el rush (más productores desde el minuto 1). Si el torneo lo marca, el weichafe del lof tarda un 25 % más que el de la ruka.
8. **Demasiados edificios en pantalla.** Seis pueblos con cuatro a seis productores y tres almacenes: la base se llena. Es lo que AoE4 busca ("la base se vuelve visible"), pero hay que revisar las capturas: los almacenes 2×2 tienen que leerse distintos a la casa.

### 5.5 Qué medir para saber si mejoró la sensación

La telemetría (`sim_telemetry.gd`, `proceso/20`) ya registra `trabada`, `sin_camino` y `ocioso`. Propongo sumar:

| Suceso o contador | Qué guarda | Hoy (auditoría) | Objetivo |
|---|---|---|---|
| `grupo` (al disolverse) | Miembros, distancia recorrida, ticks reales, ticks ideales (distancia / velocidad del más lento), ticks esperando, soltados por espera | No existe | Ticks reales ≤ 115 % de los ideales; soltados ≤ 5 % de los miembros |
| `grupo_llegada` | Diferencia entre el primero y el último en llegar a su lugar | 21,2 s (24 mixtos, 40 casillas) | ≤ 3 s |
| `grupo_dispersion` | Mayor distancia de un miembro a su lugar cuando el ancla llega | 14,3 casillas | ≤ 4 casillas |
| `trabada` por minuto | Ya existe | Medir antes | No sube más de 10 % |
| `ocioso` por minuto | Ya existe | Medir antes | Baja al menos 30 % |
| `ocioso_tras_obra` (nuevo) | Aldeano inactivo en los 5 ticks después de terminar un edificio | Medir antes | Cerca de 0 para almacenes y granjas |
| `dist_recoleccion` (contador por recurso) | Suma y cantidad de la distancia del recurso al almacén en cada entrega, para sacar el promedio | Medir antes | Después del minuto 5, ≤ 4 casillas de promedio en madera y arcilla |
| `ordenes` por minuto (ya está en `stats`) | `target` a recursos que da el jugador o la IA | Medir antes | Baja: menos reasignaciones a mano después de cada almacén |
| `edificio_parado` | Segundos de edificios militares sin cola con recursos para producir | No existe | Solo informativo para el jugador |
| `tick_lento` | Ya existe | 80,79 ms el peor del banco | El peor no sube; el promedio, ≤ +10 % |

Y lo que no mide ninguna máquina: una partida del autor a ×1 con cada pueblo, con la pregunta concreta de `proceso/21` ("¿se parece más al 4?") y una captura y un video de un ejército marchando y de aldeanos yendo a la arcilla de flanco.

### 5.6 Contradicciones encontradas

- Mapuches: la descripción dice "el caballo desde la edad III", el dato del kona dice edad II (`data/civs/mapuches.json`).
- Ayutthaya: `edificios.deposito.nombre` = "Phra Khlang (almacén)" está en los datos, pero `deposito` figura en `sin_edificios`: es un dato muerto (ya lo dijo la auditoría).
- Tawantinsuyu: el depósito común se llama "Tambo" y además existe el edificio `tambo` del regalo de cumbi, con el mismo nombre visible.
- Agregar el khlang din cambia una regla escrita de la economía v3 (§3.5.6). Va a consulta.

---

## 6. Plan por pasos

Ordenado para que lo primero sea barato, reversible y medible, y lo que mueve el balance quede al final, de a un cambio por torneo. Todos los pasos que tocan `src/sim/` corren `tests/test_determinism.gd` y `tests/bench.gd` (regla 5 de `CLAUDE.md`); cada paso deja su registro en `proceso/21` con capturas y resultados.

| # | Paso | Prueba | Terminado cuando |
|---|---|---|---|
| 1 | **Línea de base y números al dato.** Sacar 750, 10000, 4500 y las proporciones de la IA a `reglas.json`, sin cambiar sus valores. Sumar a la telemetría `ocioso_tras_obra`, `dist_recoleccion` y los contadores de grupo (en cero). Correr la medición de la auditoría como prueba nueva (`tests/grupos.gd`: 24 mixtos y 12 aldeanos a 40 casillas; 60 militares a 50) | Determinismo con **el mismo hash de antes**; `tests/grupos.gd` reproduce los números de la auditoría; `economia.gd` y torneo de 30 min con 2 semillas como base | El hash no cambió y la base está guardada en `proceso/21` |
| 2 | **Comodidades que son fallas** (§4: 1, 2, 3). Tecnologías por capacidad; cola de Mayús tras recolectar; un A* más antes de rendirse | `civ_smoke.gd` (Ayutthaya investiga `hachas`; los mapuches, `cestas`); `--autotest` con cola de Mayús; `trabada` no sube | Las dos civs investigan todo lo de su edad; lo encolado sale |
| 3 | **Almacén que pone a trabajar** (§2.3: 1 a 4), con el depósito de hoy. Prueba nueva: 3 aldeanos construyen un depósito junto a la arcilla de flanco | `tests/almacenes.gd`: a los 3 s de terminar, los 3 juntan arcilla; con granja, se queda uno; punto de reunión sobre el depósito | `ocioso_tras_obra` cerca de 0 en 3 partidas de IA |
| 4 | **Formación quieta:** rumbos, bandas, ancho y asignación sin cruces, sin grupo en marcha todavía (cada uno camina a su lugar como hoy) | `tests/grupos.gd`: cero cruces de trayectorias en la asignación; la línea al frente en el rumbo pedido; captura desde arriba | Captura revisada; el hash cambia solo en las pruebas con órdenes de grupo |
| 5 | **Grupo en marcha:** `SimGroup`, ancla, camino compartido, velocidad común, corrida, espera, giros, pasos angostos, llegada | `tests/grupos.gd`: diferencia de llegada ≤ 3 s y dispersión ≤ 4 casillas (24 mixtos); grupo por un vado de 1 casilla llega entero; `bench.gd` con orden de 200 | Objetivos de §5.5 cumplidos; el peor tick del banco no sube |
| 6 | **Ataque en movimiento, blanco lejano y suelto.** Grupo en `COMBATE`, regreso al lugar, retirada sin formación; la IA se retira suelta | Pelea de 20 contra 20 en `amove`: la línea se planta; prueba de boleadores contra un grupo (el grupo no queda frenado entero); torneo de 30 min con 2 semillas | Balance dentro de ±3 puntos de la base del paso 1 |
| 7 | **Aldeanos en bloque y escolta** (§1.7, §1.8) | `tests/grupos.gd`: 12 aldeanos a 5 casillas van sueltos; a 40, en bloque y se sueltan a 6; con 4 militares, escolta; bloque atacado se disuelve | Captura y video de aldeanos yendo a la arcilla de flanco |
| 8 | **Formaciones elegibles e interfaz:** botones, Alt para suelto, arrastre para el rumbo, orden `formar` | `--autotest --civ=guaranies --terreno=llano`, captura con `--shot-at=3`; `tests/grilla.gd` | Se ven las cuatro formaciones; la columna va por el camino inca (captura con Tawantinsuyu) |
| 9 | **Almacenes por recurso** (§2.1, §2.2), datos de las seis civs, nombres, grilla, glifos y mallas de reemplazo; IA con recurso → almacén | `civ_smoke.gd`, `campaign_smoke.gd` (alias de campaña), `economia.gd` (`dist_recoleccion` y edades), torneo de 30 min con 2 semillas | Edad II dentro de 6:30–8:50; 5 de 6 civs entre 35 y 65 %; distancia de recolección ≤ 4 casillas |
| 10 | **Producción militar por función** (§3), datos de las seis civs, tecnologías militares por capacidad, IA con función → edificios, lof que entrena weichafe | `civ_smoke.gd`, `campaign_smoke.gd` (el tutorial pide un cuartel), `economia.gd` (madera en edificios), torneo de 30 min con 5 semillas | 5 de 6 civs entre 35 y 65 %; las seis producen las tres funciones antes del minuto 12 |
| 11 | **Comodidades restantes y prueba con el autor** (§4: 5 a 12); posturas: mantener posición y patrullar. Actualizar `09-estado.md`, fichas y consultas | `--autotest` y capturas; determinismo (estado nuevo de postura) | El autor jugó con al menos dos pueblos y contestó la consulta de sensación |

Si el paso 9 o el 10 sacan el balance de la banda, se ajusta con precios (§3.5) antes de pasar al siguiente, nunca dos cambios juntos.

---

## 7. Preguntas para el autor (para `proceso/CONSULTAS.md`)

1. **Ayutthaya y el almacén de arcilla.** La economía v3 dice que no construye depósito. ¿Le damos el *khlang din* (solo arcilla) o queda como está? Recomiendo darlo: es tu ejemplo exacto y no toca el cobro del elefante.
2. **Mapuches sin almacén barato.** ¿Te parece bien que el lof sea su único almacén? Recomiendo que sí: es su identidad y además los baja del 68 %.
3. **Formación con la línea adelante y los montados a las alas**, en vez de la caballería al frente como AoE4. Recomiendo la nuestra: sigue el triángulo.
4. **Aldeanos en bloque a partir de 16 casillas.** ¿Querés que se vea el bloque también en viajes medianos? Se baja el número en el dato.
5. **El ariete común frena al ejército.** ¿Lo aceptás como costo (como AoE4) o preferís que el asedio marche aparte? Recomiendo aceptarlo y medir.
6. **Nombres en lenguas originarias** marcados `[verificar]`: ¿preferís esperar a tener fuente para cada uno o ponerlos y corregir después?
