# 5c · Palmares en partidas largas de varios (estudio y propuesta)

## Pedido
El jugador de equipos de la ronda 3 ([04-equipos-y-ffa](../22-testers/ronda-3/04-equipos-y-ffa.md), §4.E) vio que Palmares junta casi el doble que el siguiente en las partidas largas de varios:

| Partida | Palmares | El siguiente |
|---|---|---|
| Todos contra todos con 6, 75 minutos | 138.289 | 77.702 |
| Todos contra todos con 4 | 72.045 | 55.242 |
| 2v2 en fortines | 63.888 | 45.648 |

También gana por puntos el todos contra todos con tiempo límite. En el torneo de 1 contra 1 de 30 minutos está en torno al 40 %, después de que la acogida pasara de 28 a 34 de fama (paso 3, torneo 16).

La tarea: encontrar por qué escala y proponer 1 o 2 cambios que lo frenen en partidas de 45 a 75 minutos sin mover el 1 contra 1 corto. Esta etapa es solo de estudio: se commitean la herramienta y este documento. Los datos y el código quedan como en main, y la propuesta va abajo como diff.

## Herramienta
`tools/palmares_largo.gd`:

- **Partidas largas** (`--caso=ffa6|3v3|2v2`): cada `--cada` minutos (10) imprime, por jugador, la población, los aldeanos (todas las unidades civiles: también las guarecidas y las de los oficios), el ejército, el puntaje y lo juntado por origen (`players[pid].stats.origen`, con todos los recursos sumados).
- **Palmares, aparte:**
  - la fama ganada por origen (propio, renta del Macaco, saqueo, liberación);
  - la fama gastada en acogida y en hitos;
  - la fama que tiró el tope;
  - la gente acogida y la liberada;
  - los puestos de oficios y su riqueza;
  - sus casas y mocambos;
  - los segundos que pasó en el techo de población.
- **1 contra 1 corto** (`--caso=duelo`): Palmares contra cada civ, `--n` partidas por cruce alternando el lado, de `--minutes` (30). Si nadie destruye al otro, decide el criterio del torneo (edad, población, bajas). También imprime los aldeanos de cada lado al final.
- **Cambios sin tocar `data/`:** `--set="palmares/modulos/acogida/costo=31"`.

```
godot --headless --path . -s tools/palmares_largo.gd -- --caso=ffa6 --minutes=75 --seeds=61
godot --headless --path . -s tools/palmares_largo.gd -- --caso=duelo --minutes=30 --n=4 [--set=...]
```

## Causa

### Lo que **no** es
Las cuentas son del todos contra todos con 6 en llano, semilla 61 (la del jugador), a los 75 minutos ([5c-ffa6-base.txt](pruebas/5c-ffa6-base.txt)):

| Origen (Palmares, minuto 75) | Juntado | Parte |
|---|---|---|
| Granja | 71.894 | 48 % |
| Disputado | 21.754 | 15 % |
| Propio (fama 6.527 + oficios 12.672) | 19.199 | 13 % |
| Casa (lo de la base inicial) | 18.303 | 12 % |
| Recolección | 14.295 | 10 % |
| Renta (fama del Macaco), saqueo, liberación, sitios, mercado, ingenios | 4.063 | 3 % |
| **Total** | **149.508** | (el siguiente, Tawantinsuyu: 108.073) |

- **La fama no es lo que infla el total:** toda la fama de la partida suma 9.248, el 6 %. La liberación dio 336 de fama y 4 personas en 75 minutos, y el saqueo 1.071.
- **Los oficios tampoco:** dan 12.672 de riqueza en 75 minutos, unos 170 por minuto con 9 puestos. Es parejo con los motores de las otras civs (la mit'a inca, 14.101).
- **El tope de fama sí tiene un error de cuenta:** Palmares pasó 2.391 s (40 minutos) en el techo de población, con la fama en 300. Lo que el tope tira se sigue anotando como juntado y suma al puntaje: 2.352 de fama tirada a los 75 minutos (235 puntos). Es poco, pero es un error, y le pasa también a la mit'a inca (ver la propuesta).

### Lo que **sí** es: la gente llega sin tope de aldeanos
La IA de las otras civs deja de entrenar aldeanos en `max_aldeanos` de la dificultad (42 en normal; `SimAI._production`). A Palmares la gente le llega por la acogida, en la simulación, y la IA nunca la frena. La acogida solo se para en el techo de población. Cada vez que el ejército de Palmares muere, el lugar libre se llena con aldeanos.

**Aldeanos en el mismo todos contra todos ([5c-ffa6-base.txt](pruebas/5c-ffa6-base.txt)):**

| Minuto | Palmares | Las otras 5 (máximo) | Ejército de Palmares | Juntado de Palmares / el primero de los otros |
|---|---|---|---|---|
| 20 | 42 | 47 | 4 | 14.605 / 24.432 |
| 30 | **68** | 42 | 81 | 26.416 / 39.684 |
| 40 | **69** | 47 | 130 | 45.661 / 54.803 |
| 50 | **81** | 42 | 119 | 70.632 / 69.132 |
| 60 | **137** | 50 | 65 | 100.164 / 85.192 |
| 75 | **167** | 48 | 32 | **149.508 / 108.073** |

- **Más gente juntando que cualquier otra:** desde el minuto 50, Palmares tiene más aldeanos que todas, y a los 75 tiene 3,5 veces los del que más tiene. La granja, de 14.460 a 71.894 entre los minutos 40 y 75, es justamente lo que juntan los aldeanos de más.
- **Por qué crece en las partidas largas:** las demás pierden ejército y lo reponen con ejército. Palmares lo repone con aldeanos que llegan solos. En 75 minutos llegaron 194 personas.
- **En el 1 contra 1 corto ya asoma, pero no decide** ([5c-duelo-base.txt](pruebas/5c-duelo-base.txt), 20 partidas de 30 minutos): 6 de las 7 victorias de Palmares terminan con 58 a 73 aldeanos, contra 28 a 45 del rival. Pero las mismas 20 partidas con el tope dan exactamente los mismos ganadores (ver "Efecto medido"): en 30 minutos esos aldeanos de más llegan tarde para cambiar el resultado.
- **Otra semilla dice lo mismo:** en el todos contra todos con 6, semilla 62, a los 60 minutos ([5c-ffa6-s62-base.txt](pruebas/5c-ffa6-s62-base.txt)), Palmares tiene 114 aldeanos contra 42 como mucho de las demás, y junta 123.224 contra 76.073 del segundo, Tawantinsuyu (1,6 veces).
- **El 3v3** (semilla 53, [5c-3v3-base.txt](pruebas/5c-3v3-base.txt)) terminó a los 40:35: cayó Palmares y su equipo perdió. A los 20 minutos ya tenía 47 aldeanos contra 42 de los demás. No sirve para medir lo largo.

## Propuesta

### Cambio 1 (el principal): la IA de Palmares respeta el tope de aldeanos, y la fama tirada no cuenta
1. **Comando nuevo de la simulación, `acoger`:** pausa o reanuda la acogida. Con la pausa, la fama se sigue juntando hasta el tope y no llega gente.
2. **La IA de Palmares pausa la acogida cuando llega a `max_aldeanos`** de su dificultad: 42 en normal, 60 en difícil, 100 en experta.
   - Cuenta todas sus unidades civiles, también las guarecidas.
   - No cuenta las de los oficios, que son el motor, como los "aldeanos virtuales" de las otras civs.
   - El número sale de `data/reglas.json`. No hay números nuevos.
3. **`_own_resource` descuenta del libro lo que el tope tira.** Así el puntaje no suma fama (ni mit'a) que se perdió.

```diff
diff --git a/src/sim/sim.gd b/src/sim/sim.gd
--- a/src/sim/sim.gd
+++ b/src/sim/sim.gd
@@ -268,6 +268,9 @@ func _apply(c: Dictionary) -> void:
 		"guardar":
 			# "Guardar <recurso> para el hito" (fama de Palmares): prendido por defecto.
 			players[pid]["guardar_" + str(c["res"])] = bool(c["on"])
+		"acoger":
+			# Acogida prendida o en pausa (Palmares): con la pausa la fama se junta y no llega gente.
+			players[pid]["acogida_pausa"] = not bool(c["on"])
 		"reserve":
 			# Reserva de un recurso propio que los motores de conversión no tocan.
 			players[pid]["reserva_" + str(c["res"])] = clampi(int(c["n"]), 0, 1000)
diff --git a/src/sim/sim_ai.gd b/src/sim/sim_ai.gd
--- a/src/sim/sim_ai.gd
+++ b/src/sim/sim_ai.gd
@@ -393,6 +393,19 @@ func _engine(p: Dictionary, vill: Array[SimEntity], centro: SimEntity, by_type:
 			# Guarda fama para el hito solo mientras ahorra para él; si no, la gente sigue llegando.
 			if bool(p.get("guardar_fama", true)) != saving:
 				sim.push_command({"t": "guardar", "player": player, "res": "fama", "on": saving})
+			# La gente que llega por la fama respeta el tope de aldeanos de la dificultad, como
+			# los centros de las otras civs. Cuentan también los guarecidos; los de los oficios
+			# no (son el motor, como los aldeanos virtuales de las otras civs).
+			var people := 0
+			for e in sim.actives:
+				if e.alive and e.owner == player:
+					if e.is_unit() and e.fn == "civil":
+						people += 1
+					elif e.is_building():
+						people -= e.crafts.size()
+			var welcome := people < max_villagers
+			if bool(p.get("acogida_pausa", false)) == welcome:
+				sim.push_command({"t": "acoger", "player": player, "on": welcome})
 		"tawantinsuyu":
 			var want_res := 60 if saving else 0
 			if int(p.get("reserva_mita", 0)) != want_res:
diff --git a/src/sim/sim_mods.gd b/src/sim/sim_mods.gd
--- a/src/sim/sim_mods.gd
+++ b/src/sim/sim_mods.gd
@@ -83,6 +83,10 @@ func _own_resource(pid: int, p: Dictionary) -> void:
 		per_v = int(by_age[clampi(int(p["age"]) - 1, 0, by_age.size() - 1)])
 	per_min += vill * per_v
 	_gain(pid, key, per_min * P / 60)
+	# Lo que pasa del tope se pierde: tampoco cuenta como juntado (puntaje).
+	var over := int(p["res"].get(key, 0)) - cap
+	if over > 0:
+		sim.ledger(pid, "propio", key, -over)
 	p["res"][key] = mini(p["res"].get(key, 0), cap)
 	p["tope_" + key] = cap
 
@@ -220,7 +224,7 @@ func _welcome(pid: int, p: Dictionary) -> void:
 	var cfg := m(pid, "acogida")
 	var key: String = cfg["recurso"]
 	var cost: int = cfg["costo"]
-	if int(p["res"].get(key, 0)) < cost or p["pop"] >= p["pop_cap"]:
+	if int(p["res"].get(key, 0)) < cost or p["pop"] >= p["pop_cap"] or p.get("acogida_pausa", false):
 		return
 	# "Guardar fama para el hito" (prendido por defecto): no gasta la fama que pide el próximo hito.
 	if p.get("guardar_" + key, true) and int(p["res"].get(key, 0)) - cost < sim.hito_extra_need(pid, key):
```

- **El jugador humano no cambia:** nadie manda `acoger` y la acogida sigue como hoy.
- **Lo que queda para después:** un botón "Pausar la acogida" en el panel del centro, igual que el jugador de otra civ deja de entrenar aldeanos.
- **Determinismo:** con el diff puesto, `tests/test_determinism.gd` da OK. Falta correr `civ_smoke`, `bench` y el torneo al aplicarlo.
- **La partida grabada no cambia:** el comando lo manda la IA dentro de la simulación, como `guardar`.

### Cambio 2 (no hace falta hoy; queda por si el torneo lo pide): abaratar la acogida
En las 20 partidas cortas, el cambio 1 no movió ningún resultado, así que la acogida puede quedar en 34. Si el torneo de 10 semillas con el cambio 1 dejara a Palmares por debajo del 35 %, la palanca es la acogida. Con el tope puesto, lo largo lo frena el tope y no el precio de la acogida. El punto de partida sería 31:

```diff
--- a/data/civs/palmares.json
+++ b/data/civs/palmares.json
   "acogida": {
    "recurso": "fama",
-   "costo": 34
+   "costo": 31
   },
```

## Efecto medido

### Partidas largas, todos contra todos con 6 en llano

**Semilla 61, 75 minutos** ([5c-ffa6-base.txt](pruebas/5c-ffa6-base.txt) y [5c-ffa6-cambio1.txt](pruebas/5c-ffa6-cambio1.txt)):

| Minuto | Aldeanos de Palmares, antes → con el cambio 1 | Juntado de Palmares, antes → con el cambio 1 | El primero de los otros (con el cambio 1) |
|---|---|---|---|
| 30 | 68 → 50 | 26.416 → 24.515 | 39.313 |
| 40 | 69 → 51 | 45.661 → 38.817 | 54.593 |
| 50 | 81 → 53 | 70.632 → 52.232 | 70.252 |
| 60 | 137 → 51 | 100.164 → 66.142 | 85.801 |
| 75 | 167 → 52 | **149.508 → 86.378** | 108.026 (Tawantinsuyu) |

- **Juntado:** Palmares pasa de 1,38 veces el segundo a 0,80 veces el primero. Termina segunda de las cinco que siguen en pie (Ayutthaya cae antes del minuto 50).
- **Puntaje a los 75:** antes, Palmares 21.528 y Tawantinsuyu 18.268. Con el cambio 1, Tawantinsuyu 18.545 y Palmares 15.474.
- **Los aldeanos de Palmares quedan en 50 a 53:** son los 42 más los 8 a 10 de los oficios.
- **Hasta el minuto 20 la partida es idéntica:** con menos de 42 personas, el cambio no hace nada.

**Semilla 62, 60 minutos** ([5c-ffa6-s62-base.txt](pruebas/5c-ffa6-s62-base.txt) y [5c-ffa6-s62-cambio1.txt](pruebas/5c-ffa6-s62-cambio1.txt)):

| Minuto | Aldeanos de Palmares, antes → con el cambio 1 | Juntado de Palmares, antes → con el cambio 1 | El primero de los otros (con el cambio 1) |
|---|---|---|---|
| 30 | 66 → 52 | 26.999 → 24.622 | 38.358 |
| 40 | 98 → 43 | 50.527 → 37.875 | 51.476 |
| 50 | 136 → 53 | 88.501 → 48.892 | 64.247 |
| 60 | 114 → 54 | **123.224 → 63.533** | 77.075 (Ayutthaya) |

- **Juntado:** Palmares pasa de 1,6 veces el segundo a 0,82 veces el primero. Queda tercera de seis.
- **Puntaje a los 60:** antes, Palmares 19.085 y Tawantinsuyu 11.681. Con el cambio 1, Palmares 12.454, Guaraníes 12.372 y Ayutthaya 12.103: las tres en 3 %, una partida abierta.

**Una corrida aparte, con el cambio 2:** cambio 1 con la acogida a 28, semilla 61 ([5c-ffa6-cambio1-acogida28.txt](pruebas/5c-ffa6-cambio1-acogida28.txt)). Palmares cayó antes del minuto 30. Una partida de 6 con una sola semilla es muy caótica, así que no saco conclusiones de esa corrida.

### 1 contra 1 de 30 minutos
Son 20 partidas por variante: Palmares contra cada una de las otras cinco, 4 por cruce, alternando el lado.

| Variante | Victorias de Palmares | Por cruce (tawa, mapu, guar, etio, ayut) | Archivo |
|---|---|---|---|
| Hoy (main) | 7 / 20 (35 %) | 1, 2, 0, 1, 3 | [5c-duelo-base.txt](pruebas/5c-duelo-base.txt) |
| **Cambio 1** | **7 / 20 (35 %)** | 1, 2, 0, 1, 3 | [5c-duelo-cambio1.txt](pruebas/5c-duelo-cambio1.txt) |
| Cambio 1 + acogida 28 | 10 / 20 (50 %) | 2, 2, 2, 1, 3 | [5c-duelo-cambio1-acogida28.txt](pruebas/5c-duelo-cambio1-acogida28.txt) |
| Cambio 1 + acogida 31 | 13 / 20 (65 %) | 3, 3, 3, 2, 2 | [5c-duelo-cambio1-acogida31.txt](pruebas/5c-duelo-cambio1-acogida31.txt) |

- **Con el cambio 1, las 20 partidas tienen el mismo ganador que hoy, en el mismo minuto y por la misma vía** (destrucción o puntos). Lo único que cambia son los aldeanos al final de las que pasan los 42 (por ejemplo, 73 → 53, 67 → 48, 68 → 52, 71 → 50) y algo de lo juntado.
- **El 35 % de main en estas 20 partidas** es coherente con el 34 a 44 % de Palmares en los torneos 16 a 23.
- **Abaratar la acogida sí mueve el corto:** con 28 y con 31 sube.
  - Con 20 partidas, el ruido es de ±11 %: que 31 dé más que 28 es ruido.
  - Por eso el cambio 2 queda solo como palanca, y no lo propongo hoy.

## Tropiezos
- **La primera versión del tope contaba solo los aldeanos de afuera** (la lista `vill` de la IA, sin los de adentro). Con alarma, la gente guarecida no contaba, y en el todos contra todos la acogida siguió hasta 68 aldeanos al minuto 30, igual que sin el cambio. Ahora cuenta todas las unidades civiles menos las de los oficios. Esa corrida quedó a medias, en [5c-ffa6-cambio1-primera-version.txt](pruebas/5c-ffa6-cambio1-primera-version.txt).
- **La primera línea de base del 1 contra 1 salió de una carpeta vieja.** La copia de main en el scratchpad no se creó (la carpeta ya existía con una versión vieja del juego), y corrió esa versión: 9 de 20, y una de las partidas largas se cortó con `score` inexistente. Lo noté por ese error, rehice la base con un `archive` de HEAD y volví a correr las dos. Las cifras de este documento son las nuevas.
- **La máquina estaba cargada** con un torneo de 10 procesos. Un todos contra todos de 75 minutos tardó entre 1 y 2,5 horas, así que hay una sola semilla de 75 y una de 60.
