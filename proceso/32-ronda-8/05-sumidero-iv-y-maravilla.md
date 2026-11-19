# Ronda 8 · 05: sumidero en la IV y contrajuego a la maravilla

> Pedido (decisiones del autor, ronda 8): «Sumidero en la IV: escuelas excluyentes y élite cara.
> Sí. Contrajuego a la maravilla: alerta, marca en el minimapa, que la IA la ataque, obra más
> corta. Sí. Frenar la cuenta de sitios con una maravilla en obra: no». Lo último no se tocó.

## Qué cambió

### 1. Caminos de la escuela (excluyentes, como las elecciones de AoE4)
`data/tecnologias.json`: tres caminos (`camino_de`). El primero que se compra cierra los otros
(`Sim.research_block`, `Sim.school_path`). Las seis mejoras de la escuela del diseño 27 (§1.3)
se reparten entre los caminos. Los registros quedan para todos.

| Camino | Abre | Repetible (`repite`: 5 veces, +100 % del costo base cada vez) |
|---|---|---|
| Guerra | adiestramiento del choque, maestros de la pólvora | Adiestramiento continuo: +2 % de ataque y +2 % de vida a las cinco líneas (400 A + 100 M) |
| Asedio | oficio del asedio, reparación en el campo | Oficio de las máquinas: +8 % de asedio contra edificios y +4 % de vida del asedio (400 A + 100 M) |
| Obras | puntería de las torres, **obras de defensa** (nueva: +15 % de vida de edificios, +2 de ataque) | Muros y guarniciones: +6 % de vida de edificios y +1 de ataque (300 A + 200 M) |

- **Por pueblo** (`SimData._merge`): el camino del asedio pide la línea del asedio
  (`requiere_linea`). Palmares, cañaris, caranquis, chankas y tupíes no tienen taller, así que
  les quedan **dos caminos**. Los demás tienen tres. `escuela.caminos` en el pueblo puede
  recortarlos más; hoy ninguno lo usa.
- **Interfaz** (`controller.gd`): en el submenú de la escuela se ven solo los caminos hasta
  elegir uno. Después se ven solo las mejoras del camino elegido. La repetible dice qué vez es
  («Muros y guarniciones 2/5») y cuánto sube el costo.
- Los nombres de los caminos son comunes. No se inventaron nombres por pueblo sin fuente.

### 2. La guardia: la élite cara común
`data/unidades.json → guardia`: edad IV, 2 de población, **400 de alimento + 50 de madera, sin
riqueza**, 420 de vida, 24 de ataque y 3/3 de armadura. Por casilla de población vale casi el
doble que dos guerreros. `junto_a: guerrero` la pone en cada edificio que entrena al guerrero
(el cuartel, el lof mapuche, el establo etíope y los hitos de guerra).
- Maqueta procedural (`tropas.tipos.guardia`: lanza larga y escudo cuadrado). En
  `tropas.por_civ`, seis pueblos le ponen tela, arma y tocado con lo que ya usa su tropa: el
  llawtu inca, el lomphok y la guja de Ayutthaya, la macana guaraní, la lanza larga mapuche, la
  espada etíope y la lanza de Palmares.
- Glifo propio `guardia` (`iconos.gd`): escudo alto con galón, lanza y tres puntas de élite.

### 3. La IA elige un camino y gasta en el sumidero
- **Camino** (`_pick_path`, `@camino` en `reglas.ia_compras_tardias.orden`): con una maravilla
  rival en pie elige el del asedio, si lo tiene. Si no, toma el primero de
  `escuela.ia_caminos` de su pueblo y después el de `reglas.ia_sumidero.caminos`. Las
  preferencias son de juego, no una afirmación histórica: Tawantinsuyu va por el asedio,
  mapuches y Etiopía por la guerra, guaraníes y Palmares por las obras y Ayutthaya por el asedio.
- **Sumidero** (`_sink`, `reglas.ia_sumidero`): en la IV, sin estar juntando para la maravilla,
  con lo que pasa de la reserva (400 de alimento, 50 de madera y 100 de riqueza), compra otra
  vez la repetible de su camino y entrena hasta 2 guardias por pensada mientras haya población.
  Si está juntando para la maravilla, no toca lo que la maravilla pide: gasta el resto. Si
  todavía no eligió camino (juntando no pasa por las compras tardías), lo elige acá.

### 4. Contrajuego a la maravilla
- **Aviso** (ya estaba y queda en el frente de avisos): la obra rival la ven todos, con el
  lugar. El texto ahora pide «Frenala antes de que termine».
- **Marca fija en el minimapa** (`minimap.gd`): un rombo del color del dueño sobre cada
  maravilla, en obra o terminada, aun con la niebla. Si es rival, un anillo rojo que late.
- **Cuenta de la obra visible** (`CuentaGrande`): mientras hay una maravilla en obra y no corre
  otra cuenta, todos ven «ROJO LEVANTA FASIL GƏBBI · 42 % · FRENALA». El número grande es lo que
  falta al ritmo de ahora, o «PARADA» si nadie la construye.
- **La IA la ataca con prioridad** (`_military`): la maravilla rival va antes que la disputa de
  los sitios. Antes, el ejército podía irse a los sitios con una obra rival corriendo.
- **Obra más corta:** `tiempo_ms` baja de 2 400 000 a 1 440 000. Con 10 constructores, por la
  obra decreciente, quedan **6 minutos** de cuenta teórica en lugar de 10. En la partida de la
  IA tardó **5:55**; antes, 10:20 (los 21 minutos del tester eran con menos constructores
  fijos). Es una propuesta pensada como en AoE4: una obra de minutos, no de media partida.

## Medición
`tools/sumidero_iv.gd` (nuevo): 2v2 de expertas, 45 minutos, sin vista, semilla 7. Juegan
Tawantinsuyu y guaraníes contra mapuches y Etiopía. Salidas:
[sumidero-antes.txt](sumidero-antes.txt) y [sumidero-despues.txt](sumidero-despues.txt).

| | Antes | Después |
|---|---|---|
| Tawantinsuyu: alimento sin gastar en la IV (promedio / máximo) | 7388 / 25 654 | 5545 / 19 219 |
| Tawantinsuyu: madera sin gastar en la IV (promedio / máximo) | 315 / 1536 | 187 / 1291 |
| Mapuches: alimento / madera sin gastar en la IV (promedio) | 398 / 119 | 677 / 35 |
| Camino de cada IA | — | Tawantinsuyu: asedio (28:36); mapuches: guerra (26:51); guaraníes y Etiopía no llegaron a la IV |
| Repetibles compradas | — | Tawantinsuyu: oficio de las máquinas 5/5; mapuches: adiestramiento 1/5 |
| Guardias entrenadas | — | 0 |
| Maravilla de Tawantinsuyu | empieza 31:01; obra de 10:20; ninguna cae | empieza 26:47; obra de **5:55**; la atacan (12 % de daño como máximo); no cae |
| Maravilla guaraní | empieza 34:16; no se termina en 45 min | no la empieza (no llega a la IV) |

Lectura:
- **En la IA, lo que sobra es alimento, no madera.** La madera anda en 100–300 todo el tiempo.
  Los 52 000 de madera del tester eran de un humano. Por eso los costos del sumidero se
  corrieron al alimento: con madera de por medio, en las primeras pruebas la IA no compraba nada.
- **Tawantinsuyu compró las cinco repetibles** y igual terminó con 19 000 de alimento. La guardia
  no entró nunca: estaba en **209/200 de población**. Con el tope lleno, solo sirven las mejoras.
  Queda para más adelante: que la IA venda en el mercado lo que sobra, o un tope de las
  repetibles más alto.
- Mapuches gastan lo que juntan en tropa; el sumidero les toma poco (una repetible).
- Una sola semilla, y con el cambio la partida se movió: los guaraníes no llegaron a la IV. Es
  una muestra, no un torneo.
- La IA atacó la maravilla en las dos versiones. Antes, la de los guaraníes quedó en obra. Nadie
  la tiró, y ninguna cuenta llegó a cero antes del minuto 45.

## Pruebas
- `tests/test_determinism.gd`: DETERMINISMO OK, hash **718068252**, sin cambios: la prueba no
  llega a la IV.
- `tests/juego_tardio.gd`: OK, con 12 comprobaciones nuevas (caminos, repetible, Palmares sin
  asedio, guardia en el cuartel y en el lof). `tests/maravilla.gd`: OK (la obra pasa a 360 s).
- `tests/saberes.gd`, `tests/grilla.gd`: OK. `tests/casillas.gd`: 540 grillas, OK.
- `tests/civ_smoke.gd`: corre sin errores.
- `tools/primera_victoria.gd --seeds=7,21,3 --min=30`: gana 2 de 3 (21 y 3).
- Autotest con guaraníes: AUTOTEST OK. Captura:
  [capturas/05-maravilla-minimapa.jpg](capturas/05-maravilla-minimapa.jpg) (`--demo=maravilla`,
  Tawantinsuyu). Muestra la cuenta grande y el rombo azul de la maravilla en el minimapa. La
  cuenta de la obra rival y el anillo rojo no tienen captura, porque piden una partida larga.

## Tropiezos
- La primera versión cobraba la guardia y las repetibles en madera. En la IA nunca alcanzaba, y
  hubo que hacer cuatro corridas de 20 minutos de reloj hasta ver gasto.
- Juntando para la maravilla, la IA no pasaba por el sumidero ni por las compras tardías. Con
  14 000 de alimento quietos, eligió camino recién a los 42 minutos.
- La primera versión de `_sink` descontaba el costo de los recursos de verdad, además del
  comando, y cobraba dos veces. Se arregló antes de medir: ahora aparta y devuelve, como
  `_late_buys`.

## Commits
- `8222a57` caminos excluyentes, repetibles, guardia y contrajuego a la maravilla.
- `a4a51ab` el sumidero gasta lo que la maravilla no pide; costos hacia el alimento.
- El siguiente: este documento y la captura.
