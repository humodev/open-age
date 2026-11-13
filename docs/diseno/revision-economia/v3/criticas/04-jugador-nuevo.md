# Crítica 04 · El jugador nuevo y la legibilidad

Leo `../01-diseno-lider.md` como alguien que nunca jugó un RTS competitivo, y lo mido contra mis reglas de la ronda 2 (`../../v2/03-legibilidad-y-mapa.md`).

**Veredicto:** resuelve para qué está la mina y es honesto con la atención. Pero **casi todo lo que lo hace parejo son reglas invisibles** (radios, topes por edad, vecindad, pradera, "junto al monte", "cerca de la corte"). Una regla invisible no existe para el novato hasta que lo castiga. Y el diseño no dice nada del HUD ni de los avisos.

## 1. Barreal

**¿Se entiende que es la fuente común?** A medias.

- **La palabra.** En el Río de la Plata, "barreal" es un lodazal: algo que se evita, no que se trabaja. "Barreal (arcilla)" lo salva, pero el sustantivo que el jugador tiene que retener es **arcilla**. Propongo **"Arcilla (barreal)"** en el panel y "arcilla" en los tooltips: "Tus aldeanos sacan arcilla y hacen vasijas → riqueza".
- **El salto arcilla → riqueza** no es obvio. Se cierra con imagen:
  - El aldeano carga **una vasija** (no un terrón) cuando vuelve al depósito.
  - Las vasijas junto al pozo llevan **una banda dorada pintada**, el mismo dorado del rombo. El dorado sigue siendo solo de la riqueza, y acá la señala.
  - Al pasar el mouse sobre el barreal aparece el rombo junto a la cantidad: "◆ 900".
- **La silueta.** Un pozo rojizo es plano y el suelo ya mezcla tierra y barro: se pierde en la textura. Necesita altura (pila de vasijas, ramada u horno chico). Hay que probarlo con capturas en la sierra y el delta.
- **Tres barreales**: un solo nombre; el de 3×3 se lee solo como "más".

## 2. Las seis fichas: reescritura

Las fichas del líder (§10) sirven para el autor, no para el menú:

- **Tienen números** ("24 por minuto", "4 por cabeza"). En el menú no se leen; van en el tooltip.
- **Tienen jerga sin traducir**: runa, gult, faenar, cupo, bandera, capuera, kätäma.
- **No separan las dos capas.** La consigna pide "dos capas claras" (criterio 1) y solo Etiopía y Tawantinsuyu mencionan el barreal.
- **La línea 5 es bibliografía.** Sirve, pero en "Saber más", no en la ficha.

Plantilla nueva. La línea 5 pasa a ser **"Ojo"**, el error típico del principiante, que es la que salva la primera partida.

```
1. <frase>
2. Arcilla: igual que todos | mejor: … | distinta: …
3. Lo propio: <qué hacés> → <qué recibís>
4. Te pide: <la decisión, en una línea>
5. Ojo: <el error que no se nota>
```

**Tawantinsuyu.** El imperio que se construye como una red.
Arcilla: mejor, si unís el pozo con un camino a tu pueblo.
Lo propio: tu gente da turnos de trabajo (mit'a) sola; los talleres de tejido los convierten en riqueza.
Te pide: repartir los turnos entre tela, caminos y soldados.
Ojo: si gastás todos los turnos, los talleres se paran sin avisar. Mirá el contador de mit'a.

**Mapuches.** No hay capital que tomar.
Arcilla: igual que todos.
Lo propio: construís corrales; el ganado (kulliñ) se cría solo y cada cabeza da riqueza.
Te pide: dónde va cada corral, y si te comés el rebaño cuando falta comida.
Ojo: corrales pegados rinden menos. Comerse el rebaño lo deja casi vacío.

**Guaraníes.** El pueblo que se mueve con el río y el monte.
Arcilla: mejor; tus aldeanos la trabajan más rápido.
Lo propio: en vez de granjas, rozas (kokue). Dan comida, se agotan y dejan un yerbal que da riqueza.
Te pide: marcar dónde se abren las rozas nuevas y cuántas dejás pagadas.
Ojo: la roza no es una granja eterna. Sin rozas pagadas, la comida se corta.

**Etiopía.** La corte que camina.
Arcilla: distinta; tu corte saca riqueza del pozo que tiene al lado, sin aldeanos.
Lo propio: repartís tierras (gult) que pagan tributo, más si están cerca de la corte.
Te pide: dónde repartir y cuándo mudar la corte.
Ojo: una tierra "de regimiento" no paga riqueza, abarata jinetes. Cuando el pozo se agota, la corte deja de cobrar.

**Palmares.** La libertad que llega sola y se esconde en la sierra.
Arcilla: igual que todos, pero los brazos llegan solos.
Lo propio: no entrenás aldeanos, llegan por la fama. Los que trabajan adentro del mocambo (oficios) dan riqueza segura.
Te pide: cuántos trabajan adentro de cada mocambo.
Ojo: si nadie trabaja adentro, no hay riqueza propia.

**Ayutthaya.** La ciudad isla que comercia con el mundo y pelea sobre elefantes.
Arcilla: igual, pero la vas a necesitar menos.
Lo propio: la madera y la caza que entran al almacén real dejan, además, riqueza para el rey.
Te pide: dónde va cada almacén y qué barrio extranjero recibís.
Ojo: si entregan en otro depósito, el rey no cobra.

La frase de Palmares todavía dice "se esconde" y la de Ayutthaya "comercia con el mundo": contradicen el diseño nuevo. Que el autor las revise.

## 3. Los primeros 5 minutos

**Conceptos nuevos**, más allá de lo común, que hay que entender antes del minuto 5:

| Civ | Qué ve | Qué tiene que aprender | Conceptos | ¿Trampa? |
|---|---|---|---|---|
| Ayutthaya | Un almacén real ya construido y leñadores | Entregar ahí | 1 | No. **La más amable** |
| Mapuches | Un corral con una cabeza que crece | Hacer un segundo corral lejos del primero | 2 (corral, distancia entre corrales) | Leve: amontonar corrales |
| Guaraníes | Yerbal viejo; la granja se llama roza | La roza se agota; bandera | 3 | **Sí**: la comida se corta a los ~10 min si no entendió la cola |
| Tawantinsuyu | Contador de mit'a, camino, taller | Turnos → tela; camino → +20 %; interruptor | 3–4 | **Sí**: el taller se para en silencio cuando se acaba la mit'a |
| Etiopía | La corte "cobra" del pozo sin que nadie pique | Gult; señor o regimiento; radio de la corte; mudanza | 4 | **Sí, la peor**: elegir "regimiento" sin saberlo = sin riqueza propia. La extracción de la corte es invisible |
| Palmares | No hay botón de aldeano. Fama, mocambo, cupo | Fama → gente; cupo; oficio | 4 | **Sí**: si el cupo empieza en 0, el motor no arranca nunca |

**Arreglos mínimos para las trampas**, sin tocar el balance:

1. **Valores por defecto que funcionen**: cupo del mocambo en 1, gult "señor" por defecto, cola de rozas con 1 pagada, taller prendido. Quien no toca nada juega *bien a medias*, no *mal*.
2. **Lo invisible, visible en el mundo.** Un hilo o polvo entre la corte y el pozo que explota. Los talleres parados con el telar quieto y un ícono gris encima. El yerbal con hojas, la roza con surcos que amarillean.
3. **Vista previa al ubicar**, común a todos: el radio de vecindad y un número ("rinde 70 %: corral cerca", "+15 % junto al monte", "+33 % cerca de la corte", "pradera: 6 cabezas"). Es **la pieza de interfaz más importante**: seis reglas espaciales invisibles se vuelven una sola costumbre.
4. **Botón con contador de máximo**: "Corral 2/3". El tope por edad se ve antes de chocar con él.
5. **"Recomendada para empezar"** en el menú: Ayutthaya y mapuches. Exigentes: Etiopía y Tawantinsuyu.

## 4. Tutorial y menú

- **El tutorial es guaraní, y el motor guaraní ahora es de los más complejos.** Que enseñe solo **arcilla y roza → yerbal**; la cola y la bandera, la primera misión de su campaña.
- **Práctica guiada en escaramuza**: la primera vez con cada civ, el panel de objetivos (ya existe) muestra tres pasos opcionales:
  - Etiopía: "Repartí un gult cerca de la corte · Mirá el tributo en el contador · Mudá la corte cuando se agote el pozo".
  - Palmares: "Construí un mocambo · Poné a alguien en un oficio · Llegá a 100 de fama".
- **Menú de civs:** la ficha de 5 líneas, la dificultad y un botón "Saber más" con la línea histórica y las fuentes. La opción de nombres (originales y llanos) de la ronda 2 sigue en pie.
- **Tecnología de motor de la edad III**: nombre propio por civ, mismo ícono base con "+25 %".

## 5. Avisos y HUD: lo que agrega el diseño

El documento del líder **no especifica ni un aviso ni un elemento de HUD**. Lo que implica, contado:

**Estados nuevos** (van quietos en el panel o en el mundo, sin sonido): taller prendido o apagado; mit'a neta (+80 −60); cabezas por corral; cola de rozas (0–4) y bandera; yerbales activos/tope; radio y extracción de la corte; señor o regimiento; cupo y puestos por mocambo; saturación del almacén (24/min); tope de malón (60/min); máximo por edad en cada botón; vecindad; botín y reconstrucción de los ingenios; rendimiento decreciente de los sitios. Son **unos 15**, entre 2 y 4 por civ, más 4 comunes.

**Avisos que corresponden**, según mis tres clases:

| Clase | Aviso | Civ |
|---|---|---|
| Decisión | "El pozo de la corte se agotó: mudarla o quedarse" | Etiopía |
| Decisión | "La cola de rozas está vacía" | Guaraníes |
| Decisión | "Yerbales al tope: las rozas nuevas dejarán monte (madera)" (solo la primera vez) | Guaraníes |
| Pérdida | "Talleres parados: falta mit'a" | Tawantinsuyu |
| Pérdida | "Atacan un corral / un mocambo / un gult" (agrupado con los avisos de ataque) | Todas |
| Pérdida | "Pozo agotado: N aldeanos inactivos" | Todas |
| Hito | Primer yerbal; tecnología de motor | Todas |

**Prohibidos**, porque son estado o periódicos: "corral lleno", "ingenio reconstruido", "almacén saturado", "llegó gente".

**¿Respeta mis reglas?** En el fondo sí: no hay temporizadores para cliquear, faenar es de a corral entero y la roza tiene cola. Pero hay dos riesgos:

1. **La capuera silenciosa**: pasado el tope, la roza deja madera y el novato no sabe por qué no sube la riqueza. Necesita el aviso y "yerbales 4/4" en el tapyi.
2. **La mudanza de la corte**: si el novato no la ve, la corte extrae cero durante 20 minutos. Basta un aviso por pozo.

**Presupuesto propuesto:**
- La barra superior suma como máximo **un contador por civ** (mit'a o fama, que ya existen) y no agrega ninguno nuevo.
- El tooltip de la riqueza desglosa por origen: arcilla, motor, corte, malón, sitios y botín. Es lo único que deja ver el "cruce" sin hacer cuentas.
- El resto va en el panel de selección y en el mundo.
- Como máximo **3 avisos de decisión propios por civ** en toda la partida típica (Etiopía es la que más tiene). Hay que medirlo en el autotest junto con la OPM del líder.

## Orden por impacto

1. Valores por defecto que funcionen (cupo 1, gult señor, cola 1, taller prendido). Datos, costo casi nulo.
2. Vista previa al ubicar, con radio y porcentaje. Una pieza para seis motores.
3. Fichas con "Arcilla" y "Ojo", sin números, y dificultad en el menú.
4. Los seis avisos de la tabla y el desglose de la riqueza.
5. Silueta y nombre "Arcilla (barreal)", con la vasija cargada y la banda dorada.
6. Tutorial más corto y práctica guiada por civ.
