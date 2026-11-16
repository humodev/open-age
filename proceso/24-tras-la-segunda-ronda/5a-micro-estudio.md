# 5a · Por qué la micro no paga: la mezcla y el kiteo (estudio y propuesta)

## Pedido
Del informe del veterano de AoE4 en las rondas 2 y 3 ([ronda 2](../22-testers/ronda-2/01-veterano-aoe4.md), [ronda 3](../22-testers/ronda-3/01-veterano-aoe4.md), §3.2, §3.6 y §7.2 y §7.6):

- **La mezcla no paga:** 5 lanceros y 5 honderos pierden contra 10 guerreros, a los que les quedan 4 (3 si la mezcla mantiene posición).
- **Kitear al choque no sirve:** 10 honderos que kitean mueren todos sin matar a ninguno. Kitear a la línea sí sirve.

Hay que entender por qué y proponer el cambio mínimo, al estilo AoE4 (C-31: bonos planos y dos armaduras) y sin perder la identidad de cada pueblo. **Es un estudio: el balance del repositorio no se toca.** Los cambios se probaron con un parche en memoria y una vez en `data/` (después se volvió atrás). Los torneos los corre el orquestador.

## Resumen
1. **La distancia no le hace nada al choque.** Un hondero le saca 7 por golpe al guerrero cada 1,75 s (4 de daño por segundo): tarda 31,5 s en matar a uno. En la mezcla, los 5 honderos aportan 20 de daño por segundo, y los 10 guerreros le sacan 72 al muro. Los 5 lanceros duran unos 10 s.
2. **El guerrero corre más que el hondero:** 1,44 contra 1,125 casillas por segundo. Por eso al escalonar el hondero pierde 0,89 casillas por ciclo, y le entran 6 tiros antes del contacto. En AoE4 es al revés: el hombre de armas (1,125) es más lento que el arquero (1,25). Nuestro guerrero funciona como un **jinete a pie**: rápido, +6 contra la distancia, con precio de infantería y desde la edad I.
3. **La micro que probó el veterano no era la que paga.** "Kitear" (alejarse 3 casillas cuando lo tocan) no deja disparar nunca. "Mantener" con todos deja a los honderos quietos mientras los guerreros rodean a la línea. **La micro que paga ya existe:** la línea mantiene y la distancia escalona detrás. Así la mezcla gana 5 de 5 hoy, en la capa común (quedan 5,2 de 10) y en guaraníes contra mapuches (quedan 4,6).
4. **Las pruebas fijas miden a un pueblo, no al sistema.** `tests/micro.gd` y `micro2.gd` enfrentan a guaraníes contra mapuches. El "guerrero" de B es el weichafe, que corre a 1750 en lugar de 1600 y cuesta 75 en lugar de 85, y el lancero guaraní tiene 115 de vida en lugar de 140. La matriz nueva usa la capa común en los dos bandos y prueba a los pueblos aparte.
5. **Propuesta recomendada (dos números):** el guerrero común baja de 1600 a 1350 de velocidad (el hombre de armas de AoE4) y el bono de la línea contra el choque sube de 5 a 6.
   - Sin micro, la mezcla pasa de ganar 1 de 5 a ganar 5 de 5 (le quedan 4 de 10).
   - Con micro le quedan más, de 6,2 a 6,4.
   - Los honderos que escalonan pasan de 1,6 vivos contra 3,4 guerreros a 5,2 contra 0,8.
   - Sin micro, los contadores siguen ganando.
   - El weichafe mapuche y el jinete noble etíope conservan su velocidad: son el choque que **no** se kitea, y esa es su identidad.

## Cómo se midió

### Herramientas nuevas
| Herramienta | Qué hace |
|---|---|
| `tools/micro_matriz.gd` | Matriz de peleas aisladas a partir de `tests/micro.gd` y `micro2.gd`. Los dos grupos arrancan a 14 casillas y el bando B va con ataque en movimiento. Por defecto usa la capa común en los dos bandos y la edad II. Opciones: `--civs=a,b`, `--edad=N`, `--parche=archivo.json` (fusiona reglas, unidades y pueblos en memoria, sin tocar `data/`), `--casos="A\|B\|modo[\|formación]; …"` y `--variantes=N` (otra semilla y el bando B corrido de costado: la pelea es caótica y una sola corrida engaña) |
| `tools/modelo_micro.py` | Modelo numérico. Calcula golpe, daño por segundo, golpes y segundos para matar, fuerza de Lanchester (daño por segundo × vida) y kiteo (tiros gratis al acercarse y cuánto se acerca el perseguidor por ciclo al escalonar). Además simula en una dimensión las peleas de grupo. Lee `data/` y el mismo parche |

### Modos de micro del bando A (en `micro_matriz.gd`)
- **nada:** ataque en movimiento.
- **foco:** la distancia tira toda junta al enemigo con menos vida que tenga a su alcance.
- **kitear:** el kiteo del veterano. Si un enemigo está a 2,2 casillas, se aleja 3.
- **escalonar:** el kiteo de AoE4. Con la carga lista, tira. Mientras recarga, si un cuerpo a cuerpo está a menos del 60 % del alcance, se aleja 2 casillas.
- **mantener:** todos forman y mantienen posición. Es el caso J del veterano.
- **mantener+escalonar:** la línea mantiene y la distancia escalona detrás.

Para comprobar la herramienta, con `--civs=guaranies,mapuches` repite los números del veterano: caso I, quedan 4 guerreros; caso J, quedan 3.

### Comandos
```
godot --headless --path . -s tools/micro_matriz.gd -- --variantes=5
godot --headless --path . -s tools/micro_matriz.gd -- --variantes=5 --parche=c2.json
godot --headless --path . -s tools/micro_matriz.gd -- --variantes=5 --civs=guaranies,mapuches --casos="lancero:5+hondero:5|guerrero:10|mantener+escalonar"
python3 tools/modelo_micro.py [--parche=c2.json]
```

## La matriz antes (capa común, edad II, 5 variantes)
Cada fila dice cuántas de las 5 peleas gana A y cuántos quedan vivos de cada lado, en promedio. Los 10 lugares de población cuestan lo mismo: guerrero 85, mezcla 85, hondero 75, lancero 95, jinete 170 (ocupa 2). Archivo completo: [pruebas/5a-matriz-antes.txt](pruebas/5a-matriz-antes.txt).

| A | B | Micro de A | Gana A | Vivos A / B |
|---|---|---|---|---|
| 10 guerreros | 10 guerreros | (control) | 3/5 | 1,8 / 0,6 |
| 10 honderos | 10 guerreros | nada | 0/5 | 0 / 8,4 |
| 10 honderos | 10 guerreros | foco | 0/5 | 0 / 7,4 |
| 10 honderos | 10 guerreros | kitear (veterano) | 0/5 | 0 / 9,8 |
| 10 honderos | 10 guerreros | escalonar | 2/5 | 1,6 / 3,4 |
| 10 honderos | 10 lanceros | nada | 5/5 | 4,2 / 0 |
| 10 honderos | 10 lanceros | escalonar | 5/5 | 10 / 0 |
| 10 guerreros | 10 lanceros | nada | 0/5 | 0 / 5,8 |
| 5 jinetes | 10 honderos | nada | 4/5 | 3,6 / 0,2 |
| 10 lanceros | 5 jinetes | nada | 5/5 | 7,8 / 0 |
| 10 honderos | 5 jinetes | escalonar | 0/5 | 0 / 4,2 |
| **5 lanceros + 5 honderos** | 10 guerreros | **nada** | **1/5** | **1,2 / 2,6** |
| 5 lanceros + 5 honderos | 10 guerreros | mantener | 2/5 | 3,0 / 1,0 |
| 5 lanceros + 5 honderos | 10 guerreros | foco | 1/5 | 1,8 / 1,4 |
| 5 lanceros + 5 honderos | 10 guerreros | **mantener+escalonar** | **5/5** | **5,2 / 0** |
| 5 lanceros + 5 honderos | 5 jinetes | nada | 5/5 | 8,0 / 0 |
| 5 lanceros + 5 honderos | 10 honderos | nada | 3/5 | 1,4 / 1,4 |
| 5 lanceros + 5 honderos | 10 lanceros | nada | 5/5 | 7,8 / 0 |
| 5 guerreros + 5 honderos | 5 lanceros + 5 honderos | nada | 3/5 | 3,2 / 1,0 |

**Lectura:**
- Contra la línea, la distancia gana y kitear sirve: así está bien, como en AoE4.
- Contra el choque, ni el foco ni el kiteo del veterano salvan a la distancia. Escalonar casi empata.
- La mezcla pierde con ataque en movimiento y empata cuando mantiene, pero **gana siempre si la línea mantiene y la distancia escalona**.
- La formación (bloque o línea) no cambia nada: el grupo ya pone la línea adelante.

## Por qué, con números

### Daño por golpe, edad II (+10 % de ataque)
| Atacante → blanco | Golpe | Daño por segundo | Segundos para matar |
|---|---|---|---|
| guerrero → hondero | 18 (11 + 1 de edad + 6 de bono) | 14,4 | 5,0 |
| guerrero → lancero | 9 (12 − 3 de armadura) | 7,2 | 20,0 |
| hondero → guerrero | **7** (sin bono; armadura de distancia 0) | **4,0** | **31,5** |
| hondero → lancero | 11 (7 + 4 de bono) | 6,3 | 22,8 |
| lancero → guerrero | 12 (8 + 5 de bono − 1) | 8,0 | 15,0 |
| lancero → jinete | 12 | 8,0 | 22,5 |
| jinete → hondero | 20 | 16,0 | 5,0 |

### Kiteo (velocidad con el 90 % de `velocidad_pct`, latencia de la orden 0,3 s)
| Tirador contra | Velocidad del tirador | Velocidad del perseguidor | Se acerca por ciclo | Tiros escalonando antes del contacto |
|---|---|---|---|---|
| hondero contra guerrero | 1,125 | 1,44 | +0,89 casillas | 6 |
| hondero contra lancero | 1,125 | 0,99 | +0,10 | 44 |
| hondero contra jinete | 1,125 | 1,98 | +1,83 | 3 |

### Qué falla
1. **El muro dura poco y lo de atrás no ayuda.**
   - Los 10 guerreros le sacan 72 de daño por segundo a 700 de vida de lanceros: el muro cae en unos 10 s.
   - En ese tiempo la mezcla les saca 40 (lanceros) + 20 (honderos) = 60 por segundo, unos 600 de 1200.
   - Después, los guerreros que quedan matan a un hondero cada 0,5 s. El resultado es el de la ley cuadrada de Lanchester: ganan los guerreros con 2 o 3 vivos.
2. **La distancia no puede kitear al choque.**
   - El guerrero es más rápido que el hondero, así que cada ciclo de recarga le descuenta casi una casilla.
   - La distancia no tiene ninguna unidad que corra más que el choque. El jinete (1,98) tampoco se kitea, y está bien: en AoE4 el arquero no le escapa al jinete.
3. **El guerrero es el jinete de AoE4, pero a pie y barato.** En AoE4 el triángulo de la edad feudal es lancero > jinete > arquero > lancero, y el hombre de armas (lento y blindado) va aparte. Nuestro "choque" junta los dos papeles en el guerrero, que es rápido (como el jinete) y le pega +6 a la distancia (como el jinete), pero cuesta 85 y sale en la edad I. Por eso la mezcla pierde a igual costo, cuando en AoE4, a igual costo, lanceros y arqueros le ganan al jinete.
4. **El veterano probó la micro equivocada.**
   - "Kitear" huye 3 casillas cada vez que lo tocan y no vuelve a tirar.
   - "Mantener" con todos deja a los honderos quietos: los guerreros que rodean el muro los alcanzan.
   - La micro de AoE4 es otra: la línea aguanta y los tiradores retroceden y tiran. **Esa ya gana hoy, 5 de 5.** Falta que se vea y se enseñe, por ejemplo con un aviso del "arte de la guerra".

### Modelo contra lo medido
`tools/modelo_micro.py`, con el 60 % de los cuerpo a cuerpo pegando a la vez y el 40 % del daño repartido ([pruebas/5a-modelo.txt](pruebas/5a-modelo.txt)):

| Pelea | Modelo: vivos del ganador | Medido (promedio de 5) |
|---|---|---|
| 10 honderos contra 10 guerreros | guerreros 8 | guerreros 8,4 |
| 10 honderos contra 10 lanceros | honderos 5 | honderos 4,2 |
| 10 guerreros contra 10 lanceros | lanceros 5 | lanceros 5,8 |
| 5 jinetes contra 10 honderos | jinetes 4 | jinetes 3,6 |
| 10 lanceros contra 5 jinetes | lanceros 9 | lanceros 7,8 |
| mezcla contra 10 guerreros | guerreros 2 | guerreros 2,6 (gana la mezcla 1 de 5) |
| mezcla contra 5 jinetes | mezcla 8 | mezcla 8,0 |
| mezcla contra 10 lanceros | mezcla 8 | mezcla 7,8 |
| **Con C2:** mezcla contra 10 guerreros | mezcla 3 | mezcla 4,0 |
| **Con C2:** 10 guerreros contra 10 lanceros | lanceros 6 | lanceros 6,2 |

El modelo acierta quién gana y, con un margen de una unidad, cuántos quedan. No ve el rodeo en dos dimensiones (por eso "mantener" le da peor que lo medido) y los tiempos le dan entre 1,5 y 2 veces más largos.

## Propuestas
Todas se probaron con la matriz completa y 5 variantes ([pruebas/5a-matriz-propuestas.txt](pruebas/5a-matriz-propuestas.txt)). Las que tocan a los pueblos están en [pruebas/5a-pueblos.txt](pruebas/5a-pueblos.txt).

### A · Muro más fuerte (solo `reglas.bonos`)
`linea.choque` de 5 a 10. Variante A3: de 5 a 8, con el lancero a 1000 de velocidad (más lento).

| Pelea | Antes | A (+10) | A3 (+8 y lancero lento) |
|---|---|---|---|
| mezcla contra guerreros, nada | 1/5 · 1,2 / 2,6 | 4/5 · 6,2 / 0,2 | 5/5 · 4,0 / 0 |
| mezcla contra guerreros, mantener+escalonar | 5/5 · 5,2 | 4/5 · 5,8 | 5/5 · 5,6 |
| honderos que escalonan contra guerreros | 1,6 / 3,4 | 1,6 / 3,4 | 1,6 / 3,4 |
| guerreros contra lanceros | lanceros 5,8 | 7,4 | 7,0 |
| lanceros contra jinetes | 7,8 | **9,0** | 8,2 |
| mezcla contra 10 honderos | 3/5 · 1,4 / 1,4 | igual | **0/5 · 0 / 2,8** |

- **A favor:** la mezcla gana sin micro.
- **En contra:**
  - con +10, la micro deja de sumar (5,8 contra 6,2 sin micro);
  - la línea vuelve a ser un contador total, que es lo que el veterano criticó en la ronda 1;
  - el kiteo al choque no cambia;
  - con la línea más lenta, la distancia la castiga más, y la mezcla pasa a perder contra 10 honderos.

### B · El choque a pie como el hombre de armas de AoE4 (`unidades.guerrero.velocidad`)
De 1600 a 1350 (B2). También se probaron 1250 (B1) y 1350 con 1 de armadura de distancia (B3).

| Pelea | Antes | B1 (1250) | **B2 (1350)** | B3 (1350 y 1 de armadura de distancia) |
|---|---|---|---|---|
| honderos que escalonan contra guerreros | 2/5 · 1,6 / 3,4 | 5/5 · **8,8 / 0** | 2/5 · 5,2 / 0,8 | 2/5 · 3,6 / 1,2 |
| honderos sin micro contra guerreros | 0 / 8,4 | 0 / 7,6 | 0 / 8,0 | 0 / 8,6 |
| mezcla contra guerreros, nada | 1/5 · 1,2 / 2,6 | 1/5 · 0,8 / 1,6 | 2/5 · 1,4 / 1,0 | 1/5 · 0,6 / 2,2 |
| mezcla, mantener | 2/5 · 3,0 / 1,0 | 5/5 · 5,6 | 4/5 · 4,0 | 3/5 · 3,0 |
| mezcla, foco | 1/5 · 1,8 / 1,4 | 3/5 · 2,8 | 5/5 · 4,0 | 2/5 · 1,4 |
| mezcla, mantener+escalonar | 5/5 · 5,2 | 5/5 · 7,2 | 5/5 · 6,0 | 5/5 · 4,6 |

- **A favor:**
  - arregla el kiteo al choque a pie: con B2, los honderos que escalonan matan 9 de 10 guerreros y conservan la mitad;
  - toda forma de micro pasa a pagar;
  - lo que no toca al guerrero no cambia.
- **En contra:** sin micro, la mezcla sigue empatando (2 de 5). Con 1250 el kiteo sale gratis (8,8 contra 0), así que conviene 1350.

### C · Recomendada: B2 con un punto más de bono de la línea
```diff
--- a/data/unidades.json
+++ b/data/unidades.json
@@ -13,7 +13,7 @@
     "nombre": "Guerrero de choque", "funcion": "choque", "edad_min": 1, "pob": 1,
     "costo": { "alimento": 60, "riqueza": 25 }, "tiempo_ms": 16000,
     "pv": 120, "armadura": 1, "armadura_distancia": 0, "ataque": 11, "alcance": 450, "cadencia_ms": 1250,
-    "velocidad": 1600, "vision": 8000, "radio": 260
+    "velocidad": 1350, "vision": 8000, "radio": 260
   },
--- a/data/reglas.json
+++ b/data/reglas.json
@@ -90 +90 @@
-  "bonos": { "_doc": "Combate como AoE4 (proceso/23, C-31): daño = ataque + bono contra la función del blanco − armadura (la de distancia si el que pega tiene más de `alcance_distancia`). Reemplaza a los multiplicadores entre unidades, que eran de ×2 a ×2,25. Una unidad puede sumar los suyos en `bono`.", "linea": { "choque": 5 }, "distancia": { "linea": 4 }, "choque": { "distancia": 6 } },
+  "bonos": { "_doc": "Combate como AoE4 (proceso/23, C-31): daño = ataque + bono contra la función del blanco − armadura (la de distancia si el que pega tiene más de `alcance_distancia`). Reemplaza a los multiplicadores entre unidades, que eran de ×2 a ×2,25. Una unidad puede sumar los suyos en `bono`.", "linea": { "choque": 6 }, "distancia": { "linea": 4 }, "choque": { "distancia": 6 } },
```
Como parche de `micro_matriz.gd`: `{"reglas":{"bonos":{"linea":{"choque":6}}},"unidades":{"guerrero":{"velocidad":1350}}}`. Se aplicó también en `data/`: la matriz sin parche dio exactamente lo mismo ([pruebas/5a-matriz-despues.txt](pruebas/5a-matriz-despues.txt)). Después se volvió a main.

**La matriz con C2 (capa común, 5 variantes):**

| A | B | Micro | Antes | Después (C2) |
|---|---|---|---|---|
| 10 guerreros | 10 guerreros | control | 3/5 · 1,8 / 0,6 | 3/5 · 1,8 / 1,4 |
| 10 honderos | 10 guerreros | nada | 0/5 · 0 / 8,4 | 0/5 · 0 / 8,0 |
| 10 honderos | 10 guerreros | foco | 0/5 · 0 / 7,4 | 0/5 · 0 / 7,0 |
| 10 honderos | 10 guerreros | kitear (veterano) | 0/5 · 0 / 9,8 | 0/5 · 0 / 8,4 |
| 10 honderos | 10 guerreros | **escalonar** | 2/5 · 1,6 / 3,4 | 2/5 (y 3 sin terminar a los 150 s) · **5,2 / 0,8** |
| 10 honderos | 10 lanceros | nada | 5/5 · 4,2 / 0 | igual |
| 10 guerreros | 10 lanceros | nada | lanceros 5,8 | lanceros 6,2 |
| 5 jinetes | 10 honderos | nada | 4/5 · 3,6 / 0,2 | igual |
| 10 lanceros | 5 jinetes | nada | 5/5 · 7,8 | 5/5 · 8,0 |
| 10 honderos | 5 jinetes | escalonar | 0/5 · 0 / 4,2 | igual |
| **mezcla** | 10 guerreros | **nada** | **1/5 · 1,2 / 2,6** | **5/5 · 4,0 / 0** |
| mezcla | 10 guerreros | mantener | 2/5 · 3,0 / 1,0 | 4/5 · 4,2 / 0,2 |
| mezcla | 10 guerreros | foco | 1/5 · 1,8 / 1,4 | 5/5 · 6,4 / 0 |
| mezcla | 10 guerreros | mantener+escalonar | 5/5 · 5,2 | 5/5 · 6,2 |
| mezcla | 5 jinetes | nada | 5/5 · 8,0 | igual |
| mezcla | 10 honderos | nada | 3/5 · 1,4 / 1,4 | igual |
| mezcla | 10 lanceros | nada | 5/5 · 7,8 | igual |
| 5 guerreros + 5 honderos | mezcla | nada | 3/5 · 3,2 / 1,0 | 3/5 · 2,2 / 1,0 |

- **La micro paga.** Sin micro la mezcla le gana al choque por poco: le quedan 4 de 10. Con foco o escalonando le quedan más de 6.
- **El contador gana sin micro y pierde caro con micro.** Los honderos sin micro siguen perdiendo contra los guerreros (quedan 8). Los mismos honderos, escalonando, matan 9 de cada 10 guerreros.
- **No se vuelve un contador total.** Los lanceros le ganan al guerrero con 6 vivos, como hoy (5,8), y al jinete con 8.
- **C3 (bono +8 en vez de +6) se pasa.** La mezcla sin micro queda en 6,6 y la micro casi no suma (6,8).

**Con los pueblos** (C2 no cambia a los que ya tienen su propia velocidad de choque):

| Pelea (5 variantes) | Antes | C2 |
|---|---|---|
| Guaraníes contra mapuches · mezcla contra weichafe, nada | 1/5 · 1,0 / 3,8 | 1/5 · 1,4 / 3,8 |
| … mantener+escalonar | 5/5 · 4,6 / 0 | 5/5 · 4,6 / 0 |
| … arqueros que escalonan contra weichafe | 1/5 · 2,2 / 4,0 | igual |
| Mapuches contra guaraníes · mezcla contra guerrero de macana, nada | 1/5 · 0,8 / 3,8 | 3/5 · 3,4 / 1,2 |
| … mantener | 2/5 · 2,4 / 1,0 | 4/5 · 4,8 / 0,4 |
| … arqueros que escalonan | 2/5 · 2,0 / 3,2 | 4/5 · 5,8 / 0,2 |
| … weichafe contra guerrero de macana (control) | 5/5 · 3,2 / 0 | 4/5 · 2,8 / 0,2 |
| Tawantinsuyu contra guaraníes · 10 honderos escalonan | 1/5 · 1,6 / 3,4 | 4/5 · 6,0 / 0,8 |
| … 5 lanceros + 3 honderos + 2 boleadores, mantener+escalonar | 5/5 · 4,2 | 5/5 · 7,8 |

- **El weichafe sigue siendo el malón que no se kitea.** La mezcla guaraní necesita la micro buena para ganarle, y con ella gana 5 de 5. Eso es identidad.
  - **Para el orquestador:** el weichafe corre más y cuesta 75 contra 85 del guerrero común. Si el torneo muestra a los mapuches muy fuertes, lo que hay que mirar es eso, no el sistema.
- **El boleador inca ahora rinde.** Frena al 55 % y, con el guerrero a 1350, el hondero inca kitea con margen.
- **El jinete noble etíope (2100, montado) no cambia.**

**Riesgos que debe mirar el torneo:**
- **El rush de edad I con guerreros llega más tarde y persigue peor.** El guerrero queda a 1,215 casillas por segundo contra 1,125 del aldeano: todavía lo alcanza.
- **Los grupos que tienen guerreros marchan más lento** (marchan a la velocidad del más lento del grupo).
- **Los pueblos sin velocidad propia de choque pierden algo de presión temprana.** Son guaraníes, Tawantinsuyu, Palmares y Ayutthaya, más los rivales de las campañas.
- **La IA no escalona.** Con C2, la IA que tira con honderos contra guerreros no gana nada nuevo; el jugador sí.

### D · Un hostigador montado para los pueblos con caballo (más adelante, no mínimo)
Es la "unidad que kitee al choque" que pide el veterano en §7.6. Se probó como unidad nueva por parche, sin arte ni IA:
- distancia, montado, 2 de población, 170 de costo;
- 120 de vida, 9 de ataque, 4 casillas de alcance;
- velocidad 1900 y armadura 0/1.

| Pelea (5 variantes) | Gana A | Vivos A / B |
|---|---|---|
| 5 hostigadores contra 10 guerreros, nada | 0/5 | 0 / 9,2 |
| … escalonando | 3/5 | 3,8 / 1,6 |
| … escalonando contra 10 weichafe | 3/5 | 2,6 / 1,0 |
| … escalonando contra 5 jinetes | 0/5 | 0,2 / 3,8 |
| … escalonando contra 10 lanceros | 5/5 | 5 / 0 |

- **Cómo se comporta:** sin micro pierde todo; con micro le gana al choque a pie y al weichafe, y el jinete lo caza.
- **Por qué no ahora:** pide un modelo, un edificio, IA y un nombre propio por pueblo `[verificar]`, como el jinete jabalinero etíope o adalí. No es el cambio mínimo; queda para cuando se haga la caballería por pueblo.

## Consulta propuesta para el autor
**C-xx · (combate) Que la mezcla y el kiteo paguen.** El veterano midió que 5 lanceros y 5 honderos pierden contra 10 guerreros y que kitear al guerrero no sirve. La causa es que nuestro guerrero es un jinete a pie: corre más que el hondero (1,44 contra 1,125 casillas por segundo) y le pega +6, al precio de un infante. La micro que paga en AoE4 (la línea aguanta y la distancia escalona detrás) ya gana hoy 5 de 5, pero sin ella la mezcla pierde. Detalle y números en `proceso/24-tras-la-segunda-ronda/5a-micro-estudio.md`.
- a) **El guerrero común, más lento, como el hombre de armas de AoE4 (1600 → 1350), y la línea con +6 en lugar de +5 contra el choque.** Sin micro la mezcla gana por poco; con micro, por mucho. La distancia que escalona le gana al guerrero. El weichafe, el jinete noble y el jinete conservan su velocidad *(recomendada)*.
- b) Solo un bono de la línea más grande (+10). La mezcla gana sin micro, pero la micro deja de sumar y la línea vuelve a ser un contador total.
- c) Una unidad hostigadora montada por pueblo con caballo, que kitee al choque. Es más trabajo (modelo, edificio, IA) y se puede sumar después de a) o b).
- d) Dejarlo así y enseñar la micro que ya paga (la línea mantiene y la distancia escalona) con un aviso del arte de la guerra.

## Pruebas
- [pruebas/5a-veterano-antes.txt](pruebas/5a-veterano-antes.txt): `tests/micro.gd` y `micro2.gd` del veterano con los datos de main (I: quedan 4 guerreros; J: quedan 3).
- [pruebas/5a-matriz-antes.txt](pruebas/5a-matriz-antes.txt): la matriz en la capa común, con 5 variantes y con una sola corrida.
- [pruebas/5a-matriz-propuestas.txt](pruebas/5a-matriz-propuestas.txt): A1 (+8), A2 (+10), A3 (+8 y lancero 1000), B1, B2, B3, C1 (1350 y +7), C2 (recomendada), C3 (1350 y +8), cada una con su parche.
- [pruebas/5a-matriz-despues.txt](pruebas/5a-matriz-despues.txt): C2 aplicada en `data/`, la matriz y las dos pruebas fijas. En `micro.gd` y `micro2.gd` casi no cambia nada, porque el guerrero de B es el weichafe.
- [pruebas/5a-pueblos.txt](pruebas/5a-pueblos.txt): guaraníes contra mapuches y al revés, Tawantinsuyu con boleador y el hostigador (D).
- [pruebas/5a-modelo.txt](pruebas/5a-modelo.txt): el modelo numérico con los datos de main, con C2 y con D.

No se tocó la simulación ni los datos de main, así que no corresponden determinismo ni banco. Los torneos los corre el orquestador.

## Aparte: números de balance en el código
`SimMods.speed` (`src/sim/sim_mods.gd`) tiene dos números fijos que deberían ir a `data/` (regla 4 de CLAUDE.md):
- la frenada del boleador, `s * 55 / 100`;
- el 30 % de los caminos cuando nadie tiene el módulo `caminos`.

No se tocaron.
