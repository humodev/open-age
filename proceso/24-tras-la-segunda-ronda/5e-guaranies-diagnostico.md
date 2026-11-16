# 5e · Por qué ganan los guaraníes (diagnóstico y propuesta)

## Pedido
Desde el torneo 16, los guaraníes quedan entre 66 y 80 %. Se probaron seis palancas: riqueza 750, roza 850/900, emboscada 35 %, ataque del arquero 7, alcance 5500 y sigilo a 4,5 casillas. Cada una los movió poco, y el cambio siguiente los volvía a subir. En el torneo 30 ganaron 38 de 50, la mayoría por puntos a los 30 minutos.

La tarea: medir la causa con números, como en [5c](5c-palmares-largo.md), en lugar de seguir con nerfs a ciegas, y proponer 1 o 2 cambios medidos en partidas de prueba. Esta etapa es solo de estudio: se commitean la herramienta y este documento. Los datos quedan como en main.

## Herramienta
`tools/guarani_diag.gd` juega **las mismas partidas del torneo** en las que están los guaraníes: mismas semillas (`1000 + i·37 + j·11 + s`), mismos lados alternados y mismo terreno al azar. Con `--seeds=10` son los 50 cruces del torneo 30. Por partida mide:

- **Ganador:** con el criterio del torneo y con `Sim.score`.
- **Edades y obra:** el minuto de cada edad y cuánto tardó cada hito, con cuántos constructores.
- **Gente:** aldeanos y ejército cada 5 minutos.
- **Producción:** las unidades entrenadas por tipo y los edificios de producción al final.
- **Recursos:** lo juntado por origen y por recurso (`stats.origen`).
- **Bajas:** qué tipo de unidad mató a qué (militar, aldeano, edificio, hito, animal) y si la víctima estaba en el monte.
- **Sigilo:** qué parte del tiempo el ejército guaraní está oculto y sin detectar, y qué parte el ejército rival está en el monte.
- **Emboscada:** los golpes guaraníes con emboscada (la condición de `SimMods.damage`) y el daño de más que dieron.
- **Primer ataque:** el primer golpe militar de cada lado.

Opciones: `--parte=i/n` reparte las partidas entre procesos, como el torneo, y `--sumar=a.txt,b.txt` junta los totales de las partes. `--set=civ/ruta=valor` cambia los datos sin tocar `data/`. A diferencia de `palmares_largo.gd`, después del cambio vuelve a mezclar la civ con la capa común (`SimData._merge`); si no, los cambios en `unidades` y `edificios` no hacen nada.

```
godot --headless --path . -s tools/guarani_diag.gd -- --seeds=10 --parte=0/3     (y 1/3, 2/3)
godot --headless --path . -s tools/guarani_diag.gd -- --sumar=p0.txt,p1.txt,p2.txt
godot --headless --path . -s tools/guarani_diag.gd -- --seeds=6 --set='guaranies/edificios/campo_tiro/costo={"madera":150}'
```

**Control:** la línea de base da 38 de 50 (76 %), lo mismo que el torneo 30.

## Lo que medí (línea de base, 50 partidas, [5e-base.txt](pruebas/5e-base.txt))

### Cómo ganan
- **24 victorias por puntos y 14 por destrucción.** En 20 de las 24 por puntos, los guaraníes tienen más edad.
- **El criterio "por puntos" del torneo no es `Sim.score`:** `tests/torneo.gd` usa edad × 1000 + población × 10 + bajas, así que **decide la edad**.
  - De todos modos, `Sim.score` da el mismo ganador en 26 de las 29 partidas por puntos. El criterio no explica las victorias; solo dice que hay que mirar la edad.
- **Edad al final:**

  | | I | II | III | IV |
  |---|---|---|---|---|
  | Guaraníes | 2 | 3 | 26 | **19** |
  | Rivales | 1 | 26 | 23 | 0 |

  Lo mismo pasa en los torneos guardados: en el 29 y en el 30, los guaraníes llegan a la IV en 14 de las 30 partidas que duran 30 minutos, y ninguna otra civ más de una vez.

### Edades: la II llega más tarde y la III antes

| | Edad II | Edad III | Edad IV |
|---|---|---|---|
| Guaraníes | 9:47 (48 de 50) | **16:03 (45 de 50)** | 26:11 (19 de 50) |
| Rivales | 7:13 (49 de 50) | 19:10 (23 de 50) | — (0 de 50) |

- **Llegan a la II 2:30 más tarde que el rival** y aun así lo pasan en la III. La economía no es lo que los adelanta; es lo que le pasa al rival entre la II y la III (ver abajo).
- **La obra colectiva los frena, no los acelera** (hallazgo aparte). El hito de la II tarda 185 s con 5 constructores; el del rival, 97 s con 4.
  - `SimMods.build_step` da un total de t × (1 + 0,08 × (n − 1)) con n constructores. La regla común, decreciente, da t × (n + 2) / 3.
  - Con 5 constructores: guaraníes 1,32 veces, los demás 2,33 veces.
  - El potirõ "que acelera las obras" es más lento que la regla común desde el segundo constructor. Explica la II tardía y no explica que ganen; arreglarlo los haría más fuertes. Queda anotado para después del rebalance.

### Economía: juntan un poco más, sobre todo madera

| Promedio por partida | Guaraníes | Rivales |
|---|---|---|
| Juntado | 29.014 | 25.190 (+15 %) |
| Alimento | 12.933 | 11.637 |
| **Madera** | **10.860** | **8.066 (+35 %)** |
| Riqueza | 4.549 | 3.830 |
| Riqueza propia (yerbal / motor de cada civ) | 2.047 | 1.480 |

- **Nada sin freno, como la acogida de Palmares:** los aldeanos quedan en 40–41 desde el minuto 20 (el tope de la normal es 42).
- **El yerbal da unos 70 de riqueza por minuto,** parecido a los motores de las demás (la mit'a, los gult).

### Ejército: el doble que el rival

| Minuto | 5 | 10 | 15 | 20 | 25 | 30 |
|---|---|---|---|---|---|---|
| Aldeanos guaraníes / ejército | 20/0 | 35/8 | 39/28 | 41/34 | 40/51 | 40/60 |
| Aldeanos rivales / ejército | 19/3 | 30/10 | 38/14 | 35/22 | 32/24 | 32/27 |

Desde el minuto 15, los guaraníes tienen el doble de ejército, y los aldeanos del rival bajan de 38 a 32. Con la composición, en las 30 partidas de [5e-base-6semillas.txt](pruebas/5e-base-6semillas.txt):

| Por partida | Guaraníes | Rivales |
|---|---|---|
| Entrenadas | 117 arqueros, 44 guerreros, 9 lanceros, 5 arietes | 78 honderos/arqueros, 53 guerreros, 10 lanceros, 4 arietes, 5 boleadores y otras |
| Campos de tiro al final | **4,1** | 0,8 |
| Cuarteles | 1,6 | 1,6 |
| Talleres | 1,6 | 0,4 |
| Total de edificios de producción | **7,3** | unos 5 (contando lof, corral, mocambo, qollqa y otros) |

- **La casa del arco guaraní (Guyrapa róga) es de 2×2 y cuesta 100 de madera.** El campo de tiro común es de 3×3 y cuesta 150. La descripción lo dice: "más chica y barata, para tener varias".
- **Para la IA es su edificio principal,** porque `ia_unidades` empieza por el hondero (`SimAI._main_producer`). Ese edificio se multiplica cada vez que sobra (`rich`) hasta `productores_max` (5).
- **Con 4 o 5 casas del arco produce el doble de arqueros que el rival** con la misma economía. La madera de más (+35 %) es la que se va en arqueros (45 cada uno) y en casas del arco.

### Bajas
- **Son del arquero:** en las 50 partidas, el arquero guaraní mata 5.596 militares, 1.135 aldeanos y 257 edificios. El guerrero, 759 militares.
- **Las del rival:** su hondero mata 2.384 militares, su guerrero 1.335 y su centro 860.
- **Los 1.135 aldeanos muertos** (23 por partida) son los que frenan al rival entre la II y la III. Sin aldeanos no junta el hito de la III: solo 23 de 50 llegan, y a las 19:10.

### Lo que **no** es
- **Ni el sigilo ni la emboscada:**
  - el ejército guaraní está oculto y sin detectar el 10 % del tiempo;
  - la emboscada entra en 578 de 259.900 golpes y suma 2.786 de 1.044.577 de daño (**0,3 %**).
  - Por eso el sigilo a 4,5 (torneo 30) y la emboscada al 35 % (torneo 27) no movieron nada.
- **Ni el monte:**
  - las unidades que matan los guaraníes están en el monte en 584 de 8.441 casos (7 %);
  - el ejército rival anda por el monte el 18 % del tiempo, y la IA rival no se traba ahí.
- **Ni el terreno:**

  | Terreno | Victorias guaraníes |
  |---|---|
  | Mesetas | 8 de 10 |
  | Bosque templado | 7 de 8 |
  | Selva | 4 de 6 |
  | Montaña | 4 de 6 |
  | Bosque | 3 de 4 |
  | Delta | 3 de 4 |
  | Río | 3 de 3 |
  | Fortines | 3 de 3 |
  | Islas | 2 de 3 |
  | Llano | 1 de 3 |

  Ganan igual en terreno abierto que en bosque.
- **Ni la riqueza que les sobra porque el arquero no la pide** (otros ejércitos sí la pagan: guerrero 25, kona 55, espingardeiro 65). Con el arquero a 30/30/15 de riqueza, ganan 21 de 30 (70 %; base 73 %, [5e-arquero-con-riqueza.txt](pruebas/5e-arquero-con-riqueza.txt)).
- **Ni el primer ataque:** los dos lados atacan a las 7:15, en promedio.
- **Ni la IA guaraní:** usa la misma lógica que las demás. Lo distinto es el edificio que multiplica.
- **Por rival** pierden todos: Ayutthaya 10 de 10, Etiopía 8, mapuches 7, Palmares 7, Tawantinsuyu 6.

## Causa
**La casa del arco barata y chica.** La IA multiplica su edificio principal, que en los guaraníes cuesta dos tercios del común y ocupa menos de la mitad. Así llega a 4 o 5 casas del arco y 7 productores, contra unos 5 del rival, y a partir del minuto 15 tiene el doble de ejército.
- Con ese ejército mata aldeanos y frena al rival entre la II y la III.
- Llega solo a la III y a la IV, y la edad decide el criterio por puntos del torneo.

Las seis palancas anteriores tocaban la calidad de cada arquero (ataque, alcance, emboscada, sigilo) o la economía (riqueza, roza). El problema es la **cantidad** de arqueros.

**Medida directa:** el mismo cambio, con distintas dosis, en las mismas 30 partidas (6 semillas por cruce):

| Variante (solo datos guaraníes) | Victorias | Campos de tiro al final | Ejército a los 15 / 30 min | Edad IV | Archivo |
|---|---|---|---|---|---|
| Hoy (main) | **22 / 30 (73 %)** | 4,1 | 27 / 69 | 11 | [5e-base-6semillas.txt](pruebas/5e-base-6semillas.txt) |
| Arquero 30/30/15 de riqueza | 21 / 30 (70 %) | 4,3 | 22 / 87 | 6 | [5e-arquero-con-riqueza.txt](pruebas/5e-arquero-con-riqueza.txt) |
| Casa del arco a 125 | 20 / 30 (66 %) | 3,7 | 23 / 67 | 7 | [5e-casa-del-arco-125.txt](pruebas/5e-casa-del-arco-125.txt) |
| Casa del arco de 3×3 (sigue a 100) | 19 / 30 (63 %) | 3,5 | 26 / 58 | 11 | [5e-casa-del-arco-3x3.txt](pruebas/5e-casa-del-arco-3x3.txt) |
| **Casa del arco a 150 (sigue de 2×2)** | **17 / 30 (56 %)** | 3,3 | 19 / 56 | 10 | [5e-casa-del-arco-150.txt](pruebas/5e-casa-del-arco-150.txt) |
| Campo de tiro común (150 y 3×3) | 11 / 30 (36 %) | 2,5 | 17 / 46 | 6 | [5e-casa-del-arco-comun.txt](pruebas/5e-casa-del-arco-comun.txt) |

- **El efecto crece con la dosis** (125 → 150 → 150 y 3×3), y es el único cambio de este estudio que movió algo fuera del ruido (±9 % con 30 partidas).
- **Con la casa del arco a 150:**
  - el ejército guaraní al minuto 10 cae de 8 a 4 (el rival tiene 13);
  - los aldeanos del rival al minuto 30 suben de 29 a 33;
  - el rival llega a la III en 19 de 30 partidas (antes, 12).

## Propuesta

### Cambio 1 (el principal): la casa del arco cuesta lo que el campo de tiro común
Sigue de 2×2: más chica, para levantarla junto al monte, como dice su identidad. Ya no es más barata. Es un número de `data/`, sin código.

```diff
--- a/data/civs/guaranies.json
+++ b/data/civs/guaranies.json
@@ -69,3 +69,3 @@
  "edificios": {
-  "campo_tiro": {"nombre": "Guyrapa róga", "tam": [2, 2], "costo": {"madera": 100}, "desc": "Casa del arco, junto al monte: más chica y barata, para tener varias."},
+  "campo_tiro": {"nombre": "Guyrapa róga", "tam": [2, 2], "costo": {"madera": 150}, "desc": "Casa del arco, junto al monte: más chica, para levantarla entre los árboles."},
   "taller": {"nombre": "Taller de tacuara", "costo": {"madera": 150}},
```

- **Medido:** 73 → 56 % en 30 partidas (17 de 30).
- **Por rival:** Ayutthaya 3 de 6, Etiopía 5, mapuches 2, Palmares 3, Tawantinsuyu 4.
- **Falta:** el torneo de 10 semillas (lo corre el orquestador), `civ_smoke` y `test_determinism`. El hash cambia, porque cambian los datos de una civ que está en la prueba.
- **La interfaz** toma el costo y la descripción de los datos. No hace falta tocar nada más.

### Cambio 2 (solo si el torneo deja a los guaraníes arriba del 65 % con el cambio 1): de 3×3, como el campo de tiro común
```diff
-  "campo_tiro": {"nombre": "Guyrapa róga", "tam": [2, 2], "costo": {"madera": 150}, "desc": "Casa del arco, junto al monte: más chica, para levantarla entre los árboles."},
+  "campo_tiro": {"nombre": "Guyrapa róga", "costo": {"madera": 150}, "desc": "Casa del arco, junto al monte."},
```

- **Medido junto con el cambio 1:** 36 % (11 de 30). Puede quedarse corto del otro lado.
- **Se pierde algo de identidad:** la casa del arco sería igual al campo de tiro común, salvo por el nombre.
- Por eso queda como segunda palanca y no la propongo hoy.

### Lo que no conviene tocar
- **El sigilo, la emboscada y el alcance:** no pesan (0,3 % del daño). Bajarlos de nuevo solo quita identidad.
- **La obra colectiva:** hoy los frena (la II llega a las 9:47 contra 7:13 de los demás). Si se la corrige para que acelere de verdad, como dice su descripción, hay que hacerlo junto con un torneo, después del cambio 1.

## Tropiezos
- **La primera tanda de variantes no cambió nada.** `--set` cambiaba `civ.civ`, pero `unidades` y `edificios` se mezclan con la capa común al cargar (`SimData._merge`). Las corté y ahora la herramienta vuelve a mezclar la civ después de cada cambio. `palmares_largo.gd` solo tocaba `modulos`, que se leen en vivo, y por eso ahí andaba.
- **`is_hito` contra los datos comunes:** los hitos guaraníes están en `edificios_nuevos` y no se veían. Ahora se mira con los datos de cada jugador (`s.dp(pid)`).
- **Un corte de uso** frenó la línea de base de 6 semillas y las dos primeras variantes a las 3 partidas. Se volvieron a correr completas.
- **La máquina estaba cargada** con otros torneos: cada tanda de 30 partidas tardó unos 50 minutos con un proceso.
