# 5f · Por qué ganan los mapuches (diagnóstico y propuesta)

## Pedido
En el torneo 33 los mapuches ganaron 35 de 50 (70 %) y el resto quedó entre 42 y 54 %. Desde el torneo 16 andan entre 58 y 70 %, sin que nadie los tocara. La tarea: buscar la causa con el método de [5e](5e-guaranies-diagnostico.md) (repetir los mismos cruces del torneo y medir variantes con dosis creciente) y proponer el ajuste mínimo que respete su identidad. Es solo estudio: se commitean la herramienta y este documento. Los datos quedan como en main; el cambio va como diff.

**A mitad de camino cambió la base.** El orquestador integró en main los pasos 2 a 4 del juego tardío y los costos por recurso (la herrería y las mejoras militares pasan a riqueza y alimento). En el torneo 34 (sin los costos por recurso) los mapuches bajaron a 60 %; en el torneo 35 (con ellos) volvieron a 70 %. Hice `git merge main` y medí todo de nuevo. Lo de la base vieja queda al final, como antecedente.

## Herramienta
`tools/civ_diag.gd` es `tools/guarani_diag.gd` con `--civ=` (por omisión, guaraníes). Juega **las mismas partidas del torneo** en las que está la civ: mismas semillas, mismos lados y mismo terreno. Con `--seeds=10` son sus 50 cruces.

**Control:** la base vieja dio 35 de 50 con los mismos minutos de fin que el torneo 33, partida por partida. La base nueva da 35 de 50, partida por partida igual que el torneo 35.

Mide lo mismo que la de los guaraníes (ganador, edades, obra de los hitos, aldeanos y ejército cada 5 minutos, recursos por origen, bajas por tipo, sigilo y emboscada, primer ataque) y además:

- **Pérdidas propias por tipo de unidad,** y las bajas de ganado aparte (antes contaban como militares).
- **Edificios terminados al final, por tipo,** y los que cuentan para la victoria al minuto 20.
- **Hitos elegidos.**
- **Arreos** (cabezas del malón) y ganado en los corrales al final.
- **Relevo:** la vida que recupera la tropa fuera de combate, contra el daño que recibe.
- **Lo de antes del minuto 15:** tropa entrenada por tipo y aldeanos perdidos.
- **Investigaciones:** en cuántas partidas se compró cada una y en qué minuto.

Opciones: `--parte=i/n`, `--sumar=a.txt,b.txt` y `--set=civ/ruta=valor;...`. `--set` acepta también `reglas/...` para tocar `data/reglas.json`.

```
godot --headless --path . -s tools/civ_diag.gd -- --civ=mapuches --seeds=10 --parte=0/4     (y 1/4, 2/4, 3/4)
godot --headless --path . -s tools/civ_diag.gd -- --civ=mapuches --sumar=p0.txt,p1.txt,p2.txt,p3.txt
godot --headless --path . -s tools/civ_diag.gd -- --civ=mapuches --seeds=6 --set='mapuches/unidades/guerrero/costo={"alimento":60,"riqueza":25}'
```

## Lo que medí (base nueva, 50 partidas, [5f-base.txt](pruebas/5f-base.txt))

### Cómo ganan
- **35 de 50: 16 por destrucción y 19 por puntos.**
- **Por rival:** Ayutthaya 7 de 10, Etiopía 8, guaraníes 4, Palmares 8, Tawantinsuyu 8. Solo los guaraníes les empatan.
- **Edad al final:** mapuches en la III en 43 de 50; los rivales llegan a la III en 22.
- **Las edades salen parejas hasta la II** (7:29 los dos). La diferencia aparece entre la II y la III.

### Se decide antes del minuto 15
Partidas ganadas contra perdidas ([5f-ganadas-y-perdidas.txt](pruebas/5f-ganadas-y-perdidas.txt)):

| | Ejército mapuche / rival | Aldeanos mapuches / rival |
|---|---|---|
| **Ganadas (35)**, minuto 10 | **13 / 6** | 31 / **25** |
| Ganadas, minuto 15 | 27 / 12 | 41 / **28** |
| Ganadas, minuto 20 | 40 / 14 | 42 / 31 |
| **Perdidas (15)**, minuto 10 | 10 / 7 | 31 / 31 |
| Perdidas, minuto 15 | 14 / 16 | 41 / 40 |

- **Cuando ganan, al minuto 10 ya tienen el doble de tropa y el rival ya perdió aldeanos.** Cuando pierden, el rival llega entero al 15.
- **Los aldeanos del rival:** pierde 26 por partida, 9 antes del minuto 15. Los mapuches pierden 3.
- **Los mataron:** el arquero mapuche (712 en 50 partidas) y el weichafe (468). La kona, 90.
- Sin aldeanos, el rival no junta el hito de la III: llega en 22 de 50 partidas.

### Economía y producción: casi pareja
| Promedio por partida | Mapuches | Rivales |
|---|---|---|
| Juntado | 26.842 | 23.791 (+13 %) |
| Riqueza | 4.282 | 3.703 |
| Riqueza del motor propio (ganado / gult, mit'a...) | 1.380 | 1.397 |
| Arreo (malón) | 133 | — |
| Tropa entrenada antes del minuto 15 | 23 weichafe, 33 arqueros, 6 lanzas largas | 14 guerreros, 27 arqueros/honderos, 2 lanceros, 3 de otras |
| Productores al final | 3,7 corrales, 2,8 ruka de guerra, 2,8 lof | unos 5 (cuartel, campo de tiro, establo, taller, propios) |

- **El ganado rinde lo mismo que el motor de las demás** (1.380 contra 1.397 de riqueza). Es el 32 % de su riqueza: dentro de la banda sana de R5 (30 a 60 %, [revisión de economía](../../docs/diseno/revision-economia/v2/05-balance-y-aperturas.md)).
- **El juntado de más (+13 %) viene de los aldeanos que no pierden.** Al minuto 10 tienen 30 contra 26 del rival, y al 15, 41 contra 31.
- **Tienen más edificios que entrenan, pero la diferencia no es de cantidad,** como pasaba con la casa del arco guaraní: antes del minuto 15 entrenan unas 62 unidades contra 46.

### Qué tienen de distinto: el weichafe
| | Weichafe mapuche | Guerrero común |
|---|---|---|
| Velocidad | **1750** | 1350 |
| Costo | **55 de alimento, 20 de riqueza** | 60 de alimento, 25 de riqueza |
| Ataque, vida, armadura | 11, 120, 1 | iguales |

- Corre un 30 % más que el guerrero común y un 40 % más que el aldeano y el arquero (1250). Es más barato. Sale del lof, junto con los aldeanos, desde la edad I.
- **Alcanza a los aldeanos que huyen y a los arqueros que se retiran.** Es la tropa de choque más rápida antes de la kona (2200, desde la II, y casi no se entrena: 7 por partida).

### Lo que **no** es
- **Ni el malón ni las incursiones:**
  - el arreo trae 133 de recursos por partida (6 cabezas);
  - con `ia_incursiones` apagado (base vieja) ganan 19 de 30, contra 20 de 30 ([5f-vieja-sin-incursiones.txt](pruebas/5f-vieja-sin-incursiones.txt)).
- **Ni la kona:** 7 por partida, y mata 4 militares y 2 aldeanos por partida.
- **Ni el relevo:** la tropa recupera 861 de vida por partida, el 6 % del daño que recibe.
- **Ni el sigilo ni la emboscada:** la emboscada suma 2.393 de 768.239 de daño (0,3 %).
- **Ni el ganado como riqueza de más:** rinde lo mismo que el motor de los rivales. Bajarlo mueve el resultado (ver variantes), pero porque recorta toda la economía, no porque sobre.
- **Ni el lof barato,** salvo un borde de la IA (ver la base vieja).

### La riqueza y la herrería (pregunta del orquestador)
Con los costos por recurso, la herrería se paga en riqueza y alimento. Investigaciones en las 30 partidas de [5f-base6.txt](pruebas/5f-base6.txt):

| | Ataque cuerpo a cuerpo I | Ataque a distancia I | Armadura cuerpo a cuerpo I | Armadura a distancia I | Veteranos (choque / distancia) |
|---|---|---|---|---|---|
| Mapuches | 30 (min 7) | 30 (min 7) | **30 (min 12)** | 28 (min 13) | **24 / 24** |
| Rivales | 28 (min 7) | 28 (min 8) | 22 (min 11) | 23 (min 12) | 11 / 13 |

- **La riqueza los ayuda en la herrería, sobre todo en las armaduras I y en los veteranos:** las compran siempre, y los rivales en tres de cada cuatro partidas.
- **La riqueza no viene de la kona ni del malón** (7 konas y 133 de arreo por partida). Viene del ganado (1.380) y de lo recolectado (2.117), como en las demás.
- **El weichafe pide poca riqueza (20) y nada de madera.** El ejército mapuche se paga con alimento y riqueza, igual que ahora la herrería, y el ganado da riqueza sin aldeanos. Por eso los costos por recurso los devolvieron al 70 %: la herrería dejó de competir con la madera de casas y edificios.
- El ataque I del cuerpo a cuerpo (minuto 7) le cae justo al weichafe, en el momento en que sale a buscar aldeanos.

## Causa
**El weichafe rápido y barato desde la edad I.** Sale del lof, corre un 40 % más que aldeanos y arqueros, y con el ataque I de la herrería (minuto 7, pagado en riqueza) mata aldeanos que no pueden escapar.
- Entre los minutos 7 y 15 el rival pierde 9 aldeanos y otros 17 hasta el final.
- Sin esos aldeanos no junta el hito de la III, y la edad decide el criterio por puntos y la pelea del final.

La riqueza que les sobra (ganado sin aldeanos, tropa sin madera) agrava el cuadro con la herrería temprana, pero lo que se mide en las bajas es la combinación de velocidad y precio.

**Medida directa** (las mismas 30 partidas, 6 semillas por cruce; ruido de ±9 % con 30 partidas):

| Variante (solo datos mapuches) | Victorias | Ejército al minuto 15 (mapuche / rival) | Aldeanos rivales perdidos | Archivo |
|---|---|---|---|---|
| Hoy (main, torneo 35) | **22 / 30 (73 %)** | 24 / 15 | 26 | [5f-base6.txt](pruebas/5f-base6.txt) |
| Weichafe a 1650 de velocidad | 21 / 30 (70 %) | 22 / 17 | 23 | [5f-weichafe-1650.txt](pruebas/5f-weichafe-1650.txt) |
| **Weichafe al costo común (60 de alimento, 25 de riqueza; sigue a 1750)** | **18 / 30 (60 %)** | 20 / 16 | 23 | [5f-weichafe-costo.txt](pruebas/5f-weichafe-costo.txt) |
| Weichafe a 1550 (sigue a 55/20) | 17 / 30 (56 %) | 26 / 14 | 25 | [5f-weichafe-1550.txt](pruebas/5f-weichafe-1550.txt) |
| Ganado a 3 de riqueza por cabeza (hoy 4) | 16 / 30 (53 %) | 22 / 18 | 23 | [5f-ganado-3.txt](pruebas/5f-ganado-3.txt) |
| Weichafe común (1350 y 60/25) | 10 / 30 (33 %) | 21 / 18 | 14 | [5f-weichafe-comun.txt](pruebas/5f-weichafe-comun.txt) |

- **La velocidad tiene dosis:** 1750 → 1650 no mueve nada (73 → 70 %); 1550 baja a 56 %; con 1350 y el costo común, 33 %.
- **El costo solo** baja a 60 % y deja la velocidad entera.
- **Las dos juntas se pasan** (33 %): el weichafe común deja de alcanzar aldeanos (mata 98 en 30 partidas, contra 229) y el rival pierde la mitad.
- **El ganado a 3** también baja (53 %), pero:
  - la riqueza del motor queda en el 26 % de su riqueza, debajo de la banda sana de R5;
  - pierde sobre todo en el final (aldeanos 32 al minuto 30, contra 42), no en lo que los hace ganar. Es tocar el núcleo, y R6 dice tocar primero los números periféricos.

## Propuesta

### Cambio 1 (el principal): el weichafe cuesta lo que el guerrero común
Sigue rápido (1750), que es lo que dice la matriz ("weichafe rápido"). Deja de ser también más barato. Es un número de `data/`, sin código.

```diff
--- a/data/civs/mapuches.json
+++ b/data/civs/mapuches.json
@@ -39 +39 @@
-  "guerrero": {"nombre": "Weichafe", "velocidad": 1750, "ataque": 11, "costo": {"alimento": 55, "riqueza": 20}},
+  "guerrero": {"nombre": "Weichafe", "velocidad": 1750, "ataque": 11, "costo": {"alimento": 60, "riqueza": 25}},
```

- **Medido:** 73 → 60 % en 30 partidas (18 de 30). Por rival: Ayutthaya 4 de 6, Etiopía 4, guaraníes 2, Palmares 5, Tawantinsuyu 3.
- **Toca la riqueza, que es lo que preguntó el orquestador:** cada weichafe pide 5 más, la misma riqueza que ahora compite con la herrería.
- **Falta:** el torneo de 10 semillas (lo corre el orquestador), `civ_smoke` y `test_determinism`. El hash cambia, porque cambian los datos de una civ que está en la prueba.
- **La interfaz** toma el costo de los datos. No hace falta tocar nada más.

### Cambio 2 (solo si el torneo deja a los mapuches arriba del 62 % con el cambio 1): weichafe a 1550
```diff
-  "guerrero": {"nombre": "Weichafe", "velocidad": 1750, "ataque": 11, "costo": {"alimento": 60, "riqueza": 25}},
+  "guerrero": {"nombre": "Weichafe", "velocidad": 1550, "ataque": 11, "costo": {"alimento": 60, "riqueza": 25}},
```

- **Medido solo** (con el costo de hoy): 56 %. Sigue un 15 % más rápido que el guerrero común y un 24 % más que el aldeano.
- **No lo medí junto con el cambio 1.** La medida más cercana es el weichafe común (1350 y 60/25): 33 %. Las dos palancas juntas pueden pasarse; por eso va segunda y hay que medirla antes de aplicarla.

### Lo que no conviene tocar
- **El ganado:** rinde como el motor de las demás y está en la banda sana. Bajarlo baja a los mapuches, pero en el final y con toda la economía.
- **El malón, la kona, el relevo y el sigilo:** no pesan.
- **El costo del lof por encima de 150:** rompe la IA (ver abajo).

## Antecedente: la base vieja (torneo 33, antes del merge)
Las mismas medidas sobre `b5da5a8`, antes de los pasos 2 a 4 y de los costos por recurso:

| Variante | Victorias | Archivo |
|---|---|---|
| Base, 50 partidas | 35 / 50 (70 %) | [5f-vieja-base.txt](pruebas/5f-vieja-base.txt) |
| Base, 30 partidas | 20 / 30 (66 %) | [5f-vieja-base6.txt](pruebas/5f-vieja-base6.txt) |
| Sin incursiones de la IA | 19 / 30 (63 %) | [5f-vieja-sin-incursiones.txt](pruebas/5f-vieja-sin-incursiones.txt) |
| Lof a 130 de madera | 21 / 30 (70 %) | [5f-vieja-lof-130.txt](pruebas/5f-vieja-lof-130.txt) |
| Lof a 150 | 18 / 30 (60 %) | [5f-vieja-lof-150.txt](pruebas/5f-vieja-lof-150.txt) |
| Lof a 200 | **5 / 30 (16 %)** | [5f-vieja-lof-200.txt](pruebas/5f-vieja-lof-200.txt) |
| Weichafe común (1350 y 60/25) | 16 / 30 (53 %) | [5f-vieja-weichafe-comun.txt](pruebas/5f-vieja-weichafe-comun.txt) |

- **El mismo cuadro:** al minuto 10, 13 contra 6 de ejército en las ganadas ([5f-vieja-ganadas-y-perdidas.txt](pruebas/5f-vieja-ganadas-y-perdidas.txt)).
- **El weichafe ya era la palanca,** pero pesaba menos (53 % contra el 33 % de ahora). Los costos por recurso le sumaron la herrería pagada con la riqueza que les sobra.
- **El lof a 200 no es una dosis, es un borde de la IA.** Los mapuches no tienen almacenes; la IA usa el lof como almacén mientras cueste `ia_economia.almacen_alternativo_max` (150) o menos. A 200 deja de levantarlo: 0,7 lof al final, la economía cae a la mitad y ganan 5 de 30. Entre 110 y 150 el lof casi no cambia nada (el número de lof sigue en 2,6).
- **Lo que los subió de 60 (torneo 34) a 70 % (torneo 35)** fueron los costos por recurso: la herrería en riqueza y alimento les cae justo a una civ con tropa sin madera y riqueza sin aldeanos.

## Tropiezos
- **La base cambió a mitad del estudio.** Las variantes de la base vieja (sin incursiones, lof a 130, 150 y 200, weichafe común) quedaron como antecedente. Las de la propuesta se midieron sobre main con los costos por recurso (`15bbd8a`, el torneo 35).
- **El torneo 34 no reproduce main:** se corrió antes de integrar los costos por recurso. Mi base nueva dio 70 % y no el 60 % del torneo 34. Lo aclaró el torneo 35, que coincide partida por partida con la herramienta.
- **El relevo daba 0 de vida recuperada:** la muestra se tomaba un tick antes del segundo en que cura (`tick_second` corre con `tick % 10 == 0`, antes de sumar el tick). Se corrigió antes de la base.
- **Al hacer merge,** los `.uid` que generó el `--import` local chocaban con los de main. Los borré y el merge pasó.
- **La máquina estaba cargada** con otros agentes: cada tanda de 30 partidas tardó unos 25 minutos con 4 procesos.
