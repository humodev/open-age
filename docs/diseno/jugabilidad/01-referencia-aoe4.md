# Referencia de jugabilidad: cómo se maneja Age of Empires IV

Investigación de referencia para **Raíces**, hecha el 14-11-2026. No es una decisión de diseño. Responde al pedido del autor: "Necesitamos acercarnos a un gameplay como el de Age of Empires 4. Ahora parece más al 1". Cubre movimiento en grupo, almacenes, edificios de producción, comodidades de órdenes y ritmo de partida. Las mecánicas propias de cada civilización ya están en [`../investigacion-aoe4/01-catalogo-mecanicas-civs.md`](../investigacion-aoe4/01-catalogo-mecanicas-civs.md); acá solo aparecen cuando cambian la producción o el movimiento.

## Cómo leer este documento

- **Fuentes.** Costos y tiempos: archivos de datos del juego que publica aoe4world ([aoe4world/data](https://github.com/aoe4world/data)). Comportamientos: wiki de Fandom (leída por su API), notas de parche oficiales y respuestas de los desarrolladores en el foro oficial. La lista completa está al final; en el texto cito con número entre corchetes.
- **Unidades.** AoE4 mide en *casillas* (tiles). Velocidades en casillas por segundo.
- **Marcas.** *[derivado]* = cuenta mía a partir de datos citados. *[sin dato]* = lo busqué y no lo encontré. Lo demás tiene fuente.
- **Límites.** Me quedé sin búsquedas web a mitad de camino. Reddit y aoe4world (resúmenes de partida) bloquean bots; Liquipedia ya había bloqueado en la investigación anterior. No hay transcripciones de videos. Los números de ritmo (sección 5) son los más flojos.

---

## 1. Movimiento en grupo

### 1.1 Qué hace AoE4

- **Todo grupo militar se mueve en formación.** Al dar una orden de mover, mover con ataque o atacar, las unidades militares seleccionadas arman *una* formación según cantidad y tipo [1]. No hace falta elegirla: es el comportamiento por defecto.
- **Solo forman si ya están cerca.** Las unidades viajan en formación únicamente cuando están "a pocas casillas" unas de otras [1]. Si la selección está desparramada por el mapa, cada una va por su lado. *[sin dato: la distancia exacta del umbral]*.
- **Velocidad común = la del más lento.** En formación, todo el grupo camina a la velocidad de la unidad más lenta [1]. Así la caballería no llega antes que los arqueros. El costo: un grupo mixto con asedio se arrastra, y los jugadores lo critican cuando quieren retirarse rápido [2][3].
- **Corrida para acomodarse ("catch-up").** Las unidades que quedan atrás o fuera de su lugar en la formación aceleran temporalmente para alcanzarlo [1]. Hoy ese extra es de **+40 %** para todas las unidades; los aldeanos tenían +100 % hasta febrero de 2023, y se bajó porque los grupos de aldeanos que huían eran casi imposibles de alcanzar [4]. Los jugadores lo explotan: mandar a los rezagados hacia el grupo para que "corran" [5][6].
- **La IA se retira sin formación.** Desde octubre de 2022 los ejércitos de la IA que se retiran no usan formación, "para escapar más rápido" [7]. Es una pista: la formación sirve para llegar juntos, no para huir.
- **Formación por defecto.** Un rectángulo de aproximadamente el doble de ancho que de profundidad, contado en unidades [1].
- **Formaciones elegibles** (botones en el panel de la unidad; el grupo se reacomoda al instante, aunque esté quieto) [1]:

| Formación | Forma | Para qué sirve |
|---|---|---|
| Por defecto | Rectángulo ~2:1 | Uso general |
| Línea | Una o dos filas de fondo, muy ancha | Que los arqueros repartan el daño (evita el *overkill*); flanquear; contra springaldas (daño que atraviesa) |
| Cuña | Pirámide: una unidad adelante, cada fila suma dos | Casi sin uso práctico; no da bonificación |
| Escalonada | Mismo ancho y fondo, pero mucho más espacio y filas alternadas | Contra daño de área (mangoneles) |
| Columna | Dos de ancho | Solo barcos, para disparar de costado al pasar |

- **Orden dentro de la formación** (de adelante hacia atrás) [1]: exploradores y caballería pesada → caballería ligera cuerpo a cuerpo → lanceros → infantería pesada → otra infantería ligera → unidades a distancia → asedio → religiosos. Entre los de distancia el orden no sigue el alcance de forma prolija (los arqueros a caballo, por ejemplo, se movieron atrás de las unidades pesadas en enero de 2024 [8]). El orden se ajusta parche a parche con reglas por tipo de unidad [7][8].
- **Orientación.** Arrastrando con el botón derecho se elige hacia dónde mira el grupo al llegar [9].
- **Los aldeanos no usan formación**, ni siquiera mezclados con militares. Un desarrollador lo confirmó: "funciona como fue diseñado y es poco probable que cambie" [10]. Pero sí tienen la corrida para acomodarse (ver arriba), así que un grupo de aldeanos que se mueve junto tiende a ir junto.

### 1.2 Mover y mover con ataque

- **Mover** (clic derecho en el suelo): van al punto. Al llegar, la unidad se queda ahí, ataca lo que tenga en rango o lo que la ataque, y vuelve a su lugar al terminar, según la descripción de un jugador en el foro [9]. Las quejas de los jugadores dicen lo contrario: que una unidad provocada persigue "sin correa" hasta perder de vista al blanco [9]. *[sin dato oficial sobre el radio de persecución]*.
- **Mover con ataque** (tecla A + clic): avanzan y pelean con lo que encuentran. Desde julio de 2024, mover con ataque sobre una unidad o un edificio enemigo se trata como un clic en el suelo y no como ataque forzado; antes los clics sobre granjas convertían la orden en "atacar la granja" [11]. Desde enero de 2024 los cuerpo a cuerpo con mover con ataque apuntan solos a los arietes [8]. Los religiosos curan mientras van con mover con ataque [12].
- **Al llegar**: la formación se arma en el destino con la orientación pedida; no hay "comportamiento de llegada" especial documentado más allá de eso.

### 1.3 Posturas y órdenes de unidad

- **No hay posturas al estilo AoE2** (agresiva / defensiva / mantener / no atacar). AoE4 tiene un botón **Mantener posición** ("Stand Ground"): la unidad no se mueve y ataca solo lo que tenga en rango. Se cancela con cualquier orden de mover; no es un modo permanente [9][13]. Los jugadores piden desde 2021 una postura defensiva con correa y una de mantener que no se borre [9][14].
- **Patrullar**: llegó en abril de 2022 (Temporada 1), seis meses después del lanzamiento, con quejas por la demora: "las unidades se mueven por un camino y atacan a los enemigos que ven" [15][16].
- **Proteger/escoltar** ("guard"): la wiki lo nombra en el panel de órdenes [17], pero en 2021 no existía [18]. *[sin dato: fecha en que se agregó]*.

### 1.4 Diferencias con AoE2

| | AoE2 | AoE4 |
|---|---|---|
| Formación por defecto | Línea | Rectángulo ~2:1 |
| Opciones | Línea, caja, escalonada, flanco [1] | Línea, cuña, escalonada, (columna para barcos) [1] |
| Cambio por distancia | Pasa de línea horizontal a columna si el destino está a más de 30 casillas (10 antes de 2024) [1] | No encontré algo equivalente *[sin dato]* |
| Orden interno | Caballería → infantería → arqueros → pólvora → monjes y asedio [1] | Parecido, con más categorías (sección 1.1) |
| Escape | Ctrl + clic derecho: mover sin armar formación (agregado en la actualización 153015 de AoE2 DE) [1] | No hay; los jugadores lo piden ("toggle" de formación) [2][19] |
| Aldeanos | No forman [1] | No forman, pero se aceleran para alcanzar al grupo [4] |
| Posturas | Agresiva, defensiva, mantener, no atacar [13] | Solo "mantener posición" como orden |

### 1.5 Lo que pidió el autor, contra lo que hace AoE4

| Pedido | AoE4 |
|---|---|
| Aldeanos en bloque que se esperan si van lejos | No: no forman. Solo aceleran para alcanzar al grupo cercano |
| Aldeanos que corren cada uno si el trabajo está cerca | Sí, es lo normal: cada uno va a su recurso |
| Militares siempre agrupados | Sí, si arrancan a pocas casillas entre sí |
| Formaciones | Sí: defecto, línea, cuña, escalonada |

Es decir, lo que pide el autor para los aldeanos (esperarse en viajes largos) es **más** de lo que hace AoE4. Se puede hacer, pero es una decisión propia, no una copia.

---

## 2. Economía: almacenes y comportamiento automático

### 2.1 Almacenes

Todos con datos de aoe4world [20] y Fandom [21][22][23]:

| Edificio | Recibe | Costo | Construcción | Vida | Tamaño | Tecnologías |
|---|---|---|---|---|---|---|
| Centro urbano | Todo | 400 madera + 300 piedra | 165 s | 2500 | — | Aldeanos, textiles, etc. |
| Molino | Comida | 50 madera | 20 s | 750 | 2×2 | Horticultura → Fertilización → Cruza de precisión (+10 % cada una a comida de no-caza); Técnicas de supervivencia (+15 % caza); Carretilla (+15 % velocidad, +5 carga); Exploradores profesionales |
| Campamento maderero | Madera | 50 madera | 20 s | 750 | 2×2 | Silvicultura (árbol cae el doble de rápido); Hacha doble, Conservación, Sierra (+15 % cada una; la sierra suma +5 carga) |
| Campamento minero | Oro y piedra | 50 madera | 20 s | 750 | 2×2 | Pico especializado, Minería de pozo (+15 % cada una); Copelación (+15 % de oro al descargar) |
| Muelle | Comida (pesca) | 150 madera | 30 s | 1750 | — | Barcos |

- **Radio de influencia de los almacenes:** en general **no tienen**. La influencia en AoE4 es cosa de ciertas civilizaciones: el molino inglés acelera las granjas a 2 casillas (+15/20/25/30 % por edad, entran 9–12 granjas) [21]; el molino abasí/ayubí/Delhi convierte arbustos a 5 casillas en huertos (+100 de comida) [21]; los malíes suman oro por casa o campamento minero cerca de la mina a cielo abierto [20].
- **Tamaño 2×2 y precio bajo (50 de madera)**: la idea es construir muchos y pegados al recurso. Con 3,33 casillas de visión, también son ojos baratos en el mapa [21].
- **Carga por viaje:** 10 de cualquier recurso; 25 de carne de caza [24]. La distancia al almacén es el costo central: por eso se construyen al lado.

### 2.2 Recursos y tasas

Tasas base por aldeano [25]:

| Fuente | Cantidad | Tasa (por s) | Notas |
|---|---|---|---|
| Oveja | 200 | 0,75 | Cada jugador arranca con 5 al lado del centro urbano |
| Arbusto | 250 | 0,69 | 0,8625 para abasíes, ayubíes y Delhi |
| Ciervo | 350 | 0,825 | Manadas de 3, 5, 7 o 10 |
| Jabalí | 2400 | 0,9 | Pelea; se recomienda 8 aldeanos [26] |
| Pescado de costa | 600 | 1,0 (aldeano) | |
| Granja | infinita | 0,75 | Un aldeano por granja; 75 de madera, 6 s |
| Árbol | 150 | 0,75 | |
| Oro (veta chica/grande) | 4000 / 8000 | 0,75 | |
| Piedra (chica/grande) | 1200 / 2400 | 0,75 | |

- **Las granjas no se agotan.** No hay resiembra: la granja es infinita [27]. Toda la discusión de AoE2 sobre resembrar no existe en AoE4. El momento crítico es la *transición a granjas*: cuando se acaba la comida gratis hay que pagar madera en granjas, y esa ventana es vulnerable [27].
- **Recursos iniciales estándar** [25]: 4 ovejas cercanas además de las 5 propias; un arbusto mediano dentro del alcance del centro urbano y otro más lejos; una manada grande de ciervos, por lo general fuera de la visión inicial; una veta chica de oro y una de piedra cerca, y otra de cada una más lejos; uno o dos bosques circulares grandes.
- **Distancias.** Un jugador del foro dice que la mayoría de las minas de oro y piedra nacen a 8–9 casillas del centro urbano [28] (no es dato oficial). Velocidad del aldeano: 1,125 casillas/s [20].

### 2.3 Comportamiento automático

Esto es lo que más "alivia" la economía, y es casi todo invisible:

1. **Construyó un almacén → recolecta.** Los aldeanos que terminan un molino, campamento maderero o minero empiezan solos a recolectar el recurso correspondiente más cercano. Un desarrollador lo confirma en el foro: el único caso en que quedan ociosos es un error al cancelar un edificio encolado [29]. Antes de ponerse a trabajar descargan lo que llevaban encima [30].
2. **Construyó una granja → se queda.** El que la termina la trabaja. Si son más constructores que granjas, los que sobran quedan ociosos, y hasta 2024 el atajo de "aldeanos ociosos en radio" no los encontraba [31][32]. Con varios aldeanos y varias granjas encoladas, todos construyen juntos una por una; recién al final se reparten [33][34]. Es la queja de economía más repetida: se pide que se quede uno en cada granja terminada, como en AoE2.
3. **Reparó una granja o un almacén → recolecta** (desde febrero de 2023) [4].
4. **Se agotó el recurso → busca el próximo del mismo tipo.** Así funciona el punto de reunión económico (abajo). Con una cola de órdenes Mayús + clic sobre recursos puntuales, en cambio, el aldeano queda ocioso al terminar el último [29].
5. **Ovejas:** desde enero de 2024 prefieren la oveja viva más cercana a ir lejos por un cadáver [8].
6. **Caza:** con *Exploradores profesionales* (edad II) los exploradores matan ciervos y ovejas y cargan el cadáver al almacén solos, más lentos (−55 %). Los cadáveres de ciervo pierden comida con el tiempo (1,3–1,4 por s) [35]. Los jugadores "empujan" ciervos hasta el molino o construyen el molino encima de la manada [36].

### 2.4 Punto de reunión

Tres tipos, con señal visual distinta [37]:

- **Genérico** (bandera dorada triangular): al suelo o a un edificio. Si es un edificio con lugar, las unidades entran a guarecerse.
- **Económico** (bandera azul cuadrada, línea azul): sale solo si el punto se pone *sobre* un recurso o un edificio de comercio, y solo desde edificios que hacen trabajadores. Existe para que el aldeano no quede parado *al lado* del recurso. **Si el recurso se agota, el aldeano va al más cercano del mismo tipo**.
- **Agresivo** (doble bandera roja): sobre edificios enemigos o un jabalí.

Más reglas: los puntos de reunión se pueden encolar con Mayús (ej.: rodear una zona peligrosa; mandar un aldeano a varios recursos) [37][11]. No se pueden poner sobre unidades enemigas [37]. Al salir de un edificio, las unidades salen por el lado más cercano al punto de reunión (2024) [38]. El muelle y la Casa de la Sabiduría tienen dos puntos: uno económico y uno militar [11]. *[sin dato: si se puede poner el punto sobre una unidad propia para que la sigan]*.

### 2.5 Cuántos aldeanos por recurso

No hay límites duros salvo la granja (1 por granja) [27]. Referencias:
- Jabalí: 8 recomendados [26].
- Ejemplo de apertura de un jugador del Sacro Imperio en un mapa con agua: 4 a comida y 2 a madera, después 6 más a comida, 5 a madera y 4 a oro [39].
- Las guías de inicio mandan los primeros 4 aldeanos a las ovejas [40].
*[sin dato: proporciones por minuto de partidas de alto nivel]*.

---

## 3. Producción militar

### 3.1 Qué produce cada edificio

Costos de [20]; contenido de [41][42][43][44]:

| Edificio | Edad | Costo | Construcción | Vida | Unidades genéricas | Tecnologías |
|---|---|---|---|---|---|---|
| Cuartel | I | 150 madera | 30 s | 1500 | Lancero (I); hombre de armas (III) | Mejoras de nivel de sus unidades; tecnologías únicas por civilización |
| Arquería | II | 150 madera | 30 s | 1500 | Arquero, ballestero, artillero de mano | Únicas por civilización |
| Establo | II (I para mongoles) | 150 madera | 30 s | 1500 | Explorador, jinete, lancero a caballo | *Catalejo*; únicas por civilización |
| Taller de asedio | III | 250 madera | 45 s | 2100 | Ariete, springalda, mangonel, trebuchet, bombarda, etc. | Ejes engrasados, Geometría, Vigas livianas, etc. |
| Herrería | II | 150 madera | 25 s | 1500 | — | Ataque y armadura |
| Monasterio | III | 200 madera | 25 s | 2100 | Monje | Religiosas |
| Universidad | IV | 450 madera | 60 s | 2100 | — | Tecnologías de nivel alto |
| Torre de avanzada | I | 100 madera | 60 s | 750 | — | Defensa y visión |
| Torreón | III | 900 piedra | 180 s | 5000 | — | Defensa |

- **Mejoras de nivel en el edificio que produce.** Lancero → endurecido → veterano → de élite se investiga en el cuartel; jinete → veterano → de élite en el establo [41][43]. La herrería solo da ataque y armadura.
- **La infantería construye asedio en el campo**: arietes y torres de asedio desde la edad II con *Ingeniería de asedio*; abasíes desde la edad I sin tecnología [45][46]. Las armas de asedio de campo tardan 80 s desde abril de 2022 [16].

### 3.2 Por qué importa la madera

- Los edificios de producción cuestan 150 de madera (250 el taller) [20].
- Las unidades baratas piden madera: lancero 60 de comida + 20 de madera; arquero 30 de comida + 50 de madera; jinete 100 de comida + 20 de madera [20].
- Las granjas cuestan 75 de madera; las casas, 50 [20]. La transición a granjas compite con la expansión militar por la misma madera [27].
- Los mapas con poca madera hacen más difícil sostener ejércitos de arqueros [25].

**[derivado] Cuánto "come" un edificio.** Un arquero vale 80 y tarda 15 s; un lancero, 80 en 15 s; un jinete, 120 en 22,5 s; un hombre de armas, 110 en 20,5 s. Todos dan **~320 recursos por minuto por edificio** produciendo sin parar. Un aldeano rinde ~45 por minuto (0,75/s). O sea: **cada edificio de producción en uso continuo necesita ~7 aldeanos** dedicados. Con 40 aldeanos en recursos militares, un jugador sostiene 5–6 edificios. Esta cuenta explica por qué en AoE4 se multiplican los edificios: no hay producción por lotes, cada edificio hace una unidad a la vez.

### 3.3 Colas y producción paralela

- **Una unidad a la vez por edificio.** No hay producción por lotes; los jugadores lo critican ("no quiero tener que hacer docenas de edificios") [47]. Mayús + atajo encola 5 de una [48].
- **Varios edificios seleccionados**: la orden se reparte; si uno tiene la cola llena, se encola en otro que tenga lugar (julio de 2022) [12]. *[sin dato: tamaño máximo de la cola]*.
- **Cola global de producción**: en la pantalla, con todo lo que se está haciendo en todos los edificios. Clic para ir al edificio; Ctrl + clic cancela lo último (abril de 2022) [15]. No muestra los edificios en construcción; los jugadores lo piden [49].
- **Tope de población**: si se llega al tope, la unidad termina pero no sale hasta que haya lugar; se puede encolar mientras se construye una casa [50]. Tope 200; se arranca con 10 [50].
- **Atajos para cancelar** el último o todo lo encolado del edificio seleccionado (2022) [15].

### 3.4 Civilizaciones que cambian la regla

- **Mongoles**: todos sus edificios se empacan y se mudan. El *ger* reemplaza molino, campamento maderero y minero (recibe comida, madera y oro; 100 de madera), y la piedra se saca con el *ovoo*, sin aldeanos. Dentro de la influencia del ovoo, gastando piedra, los edificios **producen de a dos unidades**. El establo está disponible desde la edad I. Arrancan con el tope de población máximo, sin casas [51][52][50].
- **Otomanos**: además de los edificios normales (30 % más baratos), tienen la **escuela militar** (150 madera + 100 piedra, una por edad), que produce **gratis y en bucle** una unidad elegida, a 4,75 veces el tiempo normal (lancero 71 s, jinete sipahi 142 s). Los edificios militares cerca de una herrería o universidad producen +20/30/40 % más rápido según la edad [53][54].
- **Abasíes**: edificios genéricos, pero lo que se construye dentro de la influencia de la Casa de la Sabiduría hace avanzar la Edad de Oro (más recolección y construcción). Edificios pegados entre sí ganan +8 % de vida por vecino con *Planificación urbana*. La Casa de la Sabiduría tiene dos puntos de reunión [55][41][11].
- **Malíes**: plantel de unidades distinto; el ganado sale del molino [56]. *Saber de Farari* abarata las mejoras de nivel veterano [56].

Ninguna civilización tiene "un solo edificio de producción para todo" como regla general. La variación está en cuánto cuesta producir (gratis, doble, más rápido), no en unificar.

---

## 4. Comodidades de órdenes e interfaz

Lista de lo que existe hoy, con la fecha en que llegó cuando la encontré. Muchas no estaban en el lanzamiento (octubre de 2021) y entraron como "novedad" de una temporada, cosa que los jugadores criticaron [57].

### Selección
- **Grupos de control** (Ctrl + número). Opción de exclusividad: si una unidad entra a un grupo, sale de los otros. Atajos para agregar, sacar y limpiar grupos (abril de 2022) [15].
- **Seleccionar todos los militares, todos los militares ociosos, recorrer los ociosos**; los barcos tienen su propio atajo aparte (2022). No incluyen monjes ni barcos pesqueros [12][7].
- **Seleccionar aldeano ocioso** (uno por vez o todos); **ociosos en un radio** [31]. **Mayús + clic en el panel de recursos**: todos los ociosos, o todos los que trabajan ese recurso (enero/marzo de 2024) [8][38]. El panel muestra cuántos aldeanos hay en cada recurso y cuántos ociosos [17].
- **Seleccionar todos los edificios de un tipo** (todos los cuarteles, todas las arquerías…) y **recorrer edificios** (abril de 2022) [15]. "Todos los edificios militares" sirve para poner un punto de reunión común [58].
- **Seleccionar todas las unidades** y **todas las de la pantalla**, por separado [15]. Doble clic: todas las del mismo tipo en pantalla *[no encontré fuente específica; es estándar del género]*.

### Órdenes
- **Cola con Mayús** para todo: mover, construir, recolectar, puntos de reunión. Mayús + Q + A encola varias granjas seguidas [7]. Los monjes pueden encolar "agarrar la reliquia y llevarla al monasterio" [7].
- **Mover con ataque**, **patrullar** (2022), **mantener posición**, **atacar el suelo**, **guarecerse** [15][24].
- **Orientación al llegar** arrastrando el clic derecho [9].
- **Reunión** sobre recurso (económica), sobre edificio (guarecerse) o sobre enemigo (agresiva) [37].

### Defensa de la economía
- **Buscar refugio** (aldeanos seleccionados van al edificio con lugar más cercano) y **Campana del pueblo** en el centro urbano (todos los aldeanos cercanos se refugian, 5 s de recarga; noviembre de 2023) [24][59][60].
- **Volver al trabajo** y **Todos vuelven al trabajo**: los aldeanos guarecidos vuelven a lo que hacían [59].

### Construcción
- **Atajos por cuadrícula** (tecla según posición en la grilla) y atajos remapeables; botones de construcción directos al seleccionar un aldeano, sin menú intermedio [17][7].
- **Muros arrastrando**: empalizada (7 de madera por tramo) y muro de piedra (25 de piedra) [20].
- **Compuertas**: se puede convertir un tramo de muro en puerta mientras todavía es un plano, pagando la diferencia (marzo de 2024); después hay que usar un aldeano [38].
- **Construcción compartida**: cada aldeano extra suma un tercio de la velocidad base; el tiempo es 3/(N+2) del tiempo base con N aldeanos [24].

### Cámara
- Guardar y saltar a lugares de cámara (Ctrl/Mayús + F1–F8) [15].

### Lo que falta o se critica
- Producción automática en bucle: no existe para la mayoría (sí la escuela militar otomana). Fuerte debate en el foro [61].
- Dejar un aldeano por granja al encolar granjas [33][34].
- Postura defensiva persistente [14].
- Opción de mover sin formación [2][19].

---

## 5. Ritmo de una partida típica

Los datos de tiempo de partida son sólidos; los de aldeanos y ejército, no.

- **Duración** (1 contra 1 por ranking, parches de noviembre de 2026, API de aoe4world) [62]: la mediana de las medianas por civilización es de **~23 min** en todos los niveles y de **~19 min** en Conqueror (Elo > 1400).
- **Costo de las edades** (cada landmark) [20]: edad II, 400 de comida + 200 de oro, 190 s; edad III, 1200 de comida + 600 de oro, 220 s; edad IV, 2400 de comida + 1200 de oro, 250 s. El tiempo baja con más constructores (sección 4).
- **Cuándo se pasa de edad** (testimonios del foro, no estadística):
  - Edad II "a las 4:30" se repite como referencia estándar [63][64].
  - Lo más rápido que vio un jugador en 2021: 4:30 a la II, 8:30 a la III [65].
  - Pasar a la III cerca de los 7 min después de una II a las 4:30 [66]; o a los 12 min si se presiona en la II [64].
  - Un profesional (Beasty) llegó a la IV en 11 min con unos 10 militares [67].
  - En niveles medios, los mongoles llegaban a la III cerca del minuto 15 [68].
- **Aldeanos [derivado].** El centro urbano hace un aldeano cada 20 s, o sea 3 por minuto [20]. Con producción continua desde un solo centro urbano: +15 a los 5 min, +30 a los 10, +45 a los 15. Los aldeanos de arranque no los confirmé con una fuente esta vez. El segundo centro urbano (400 de madera + 300 de piedra) duplica el ritmo y es "la mayor mejora económica" [59]. *[sin dato: conteos reales por minuto en partidas de alto nivel]*.
- **Tamaño de ejército y cantidad de edificios de producción**: *[sin dato]*. Solo testimonios sueltos: un jugador cuenta que en feudal solo le alcanza para 1–2 unidades en cola por edificio [69]; malíes y la Orden del Dragón "necesitan muchos edificios" [70]. La cuenta derivada de la sección 3.2 (~7 aldeanos por edificio en uso continuo) es la mejor estimación que tengo.

---

## 6. Lo que más cambia la sensación de juego

Ordenado por impacto estimado en "se parece a AoE4", de mayor a menor:

1. **Formación automática al mover militares**: rectángulo ~2:1, cuerpo a cuerpo adelante y distancia atrás, todos a la velocidad del más lento. Es lo primero que se nota en pantalla.
2. **Corrida para acomodarse (+40 %)**: sin esto, la formación se ve rígida y los rezagados nunca llegan. Vale también para aldeanos.
3. **Almacenes por recurso, baratos (50 de madera), 2×2, pegados al recurso**, y que los constructores **empiecen a recolectar solos** al terminar. Esto cambia el ritmo del juego: el jugador manda y se olvida.
4. **Punto de reunión económico sobre un recurso**, con salto al recurso vecino del mismo tipo cuando se agota.
5. **Edificios de producción separados por tipo** (cuartel I, arquería II, establo II, taller III), todos de madera, con las mejoras de nivel de cada unidad adentro. Hace que la madera sea el cuello de botella militar.
6. **Una unidad a la vez por edificio, sin lotes**: para ejército grande hacen falta muchos edificios (~1 cada 7 aldeanos militares). Esto es lo que vuelve visible la base.
7. **Granja infinita, un aldeano por granja, el constructor se queda**: sin resiembra. La transición a granjas como momento de riesgo.
8. **Aldeano ocioso visible** (contador en el panel de recursos, atajo, Mayús + clic) y **cantidad de aldeanos por recurso** en el panel.
9. **Mover con ataque** como orden principal del ejército, y **cola con Mayús** para todo (incluidos puntos de reunión).
10. **Seleccionar todos los militares** y **todos los edificios de un tipo** (para encolar en paralelo y poner un punto de reunión común).
11. **Cola global de producción** en pantalla.
12. **Campana del pueblo / volver al trabajo**: defensa de la economía con un botón.
13. **Formaciones elegibles** (línea, escalonada) como herramienta táctica, no como adorno: línea contra *overkill* y daño que atraviesa, escalonada contra daño de área.
14. **Muros arrastrando con puertas convertibles** en el plano.
15. **Construcción compartida con rendimiento decreciente** (3/(N+2)), que vuelve una decisión cuántos aldeanos mandar a la maravilla o al landmark.

Dos advertencias que dejan las quejas de los jugadores:
- La velocidad del más lento **molesta en la retirada**. AoE4 no ofrece salida; la IA rompe formación para huir. Conviene prever "mover sin formación" desde el principio.
- Encolar granjas con un grupo **deja aldeanos ociosos o amontonados**. Conviene que, al terminar cada granja, se quede uno y el resto siga.

---

## Fuentes

1. Fandom, *Unit formation* (secciones AoE4 y AoE2): https://ageofempires.fandom.com/wiki/Unit_formation
2. Foro oficial, *[Formation] Add movement formation toggle* (2022): https://forums.ageofempires.com/t/formation-add-movement-formation-toggle/191870
3. Foro oficial, *[Feature Request] Default to individual troop speeds*: https://forums.ageofempires.com/t/feature-request-default-to-individual-troop-speeds/289526
4. Notas oficiales, Update 6.0.878 / Temporada 4 (16-2-2023): https://www.ageofempires.com/news/ageiv_seasonfour_update_60878/ (copia en Fandom: https://ageofempires.fandom.com/wiki/Update_6.0.878)
5. Foro oficial, *Villagers run faster than horsemen* (2022): https://forums.ageofempires.com/t/villagers-run-faster-than-horsemen/204369
6. Foro oficial, *Les Ouvriers AOE 4 "workers"* (2024): https://forums.ageofempires.com/t/les-ouvriers-aoe-4-workers/254261
7. Notas oficiales, Update 24916 / Temporada 3 (25-10-2022): https://www.ageofempires.com/news/age_of_empires_iv_update_24916_season3/ (Fandom: https://ageofempires.fandom.com/wiki/Update_24916)
8. Notas oficiales, Patch 9.2.628 (30-1-2024): https://www.ageofempires.com/news/age-of-empires-iv-patch-9-2-628 (Fandom: https://ageofempires.fandom.com/wiki/Patch_9.2.628)
9. Foro oficial, *Where is the Defensive stance?* (2021): https://forums.ageofempires.com/t/where-is-the-defensive-stance/180406
10. Foro oficial, *Villagers don't use Unit Formations* (respuesta del equipo, 2022): https://forums.ageofempires.com/t/villagers-dont-use-unit-formations/203482
11. Notas oficiales, Update 11.0.782 / Temporada 8 (18-7-2024): https://www.ageofempires.com/news/age-of-empires-iv-update-11-0-782/ (Fandom: https://ageofempires.fandom.com/wiki/Update_11.0.782)
12. Notas oficiales, Season Two Update 17718 (12-7-2022): https://www.ageofempires.com/news/age-of-empires-iv-update-17718/ (Fandom: https://ageofempires.fandom.com/wiki/Season_Two_Update_17718)
13. Fandom, *Unit stance*: https://ageofempires.fandom.com/wiki/Unit_stance
14. Foro oficial, *A few hotkeys suggestions* (2022): https://forums.ageofempires.com/t/a-few-hotkeys-suggestions/211177 ; *Unit Stances*: https://forums.ageofempires.com/t/unit-stances/214365
15. Notas oficiales, Season One Update (7-4-2022): https://www.ageofempires.com/news/age-of-empires-iv-season-one-update-release-notes/
16. Fandom, *Season One Update*: https://ageofempires.fandom.com/wiki/Season_One_Update ; foro, *Seriously? 6 months for this?*: https://forums.ageofempires.com/t/seriously-6-months-for-this/184347
17. Fandom, *User interface* (sección AoE4): https://ageofempires.fandom.com/wiki/User_interface
18. Foro oficial, *No guard or patrol commands?* (2021): https://forums.ageofempires.com/t/no-guard-or-patrol-commands/178099
19. Foro oficial, *Modifications to game please*: https://forums.ageofempires.com/t/modifications-to-game-please-idea-and-vote/181919
20. aoe4world, datos extraídos del juego (`buildings/all-unified.json`, `units/`): https://github.com/aoe4world/data
21. Fandom, *Mill (Age of Empires IV)*: https://ageofempires.fandom.com/wiki/Mill_(Age_of_Empires_IV)
22. Fandom, *Lumber Camp (Age of Empires IV)*: https://ageofempires.fandom.com/wiki/Lumber_Camp_(Age_of_Empires_IV)
23. Fandom, *Mining Camp (Age of Empires IV)*: https://ageofempires.fandom.com/wiki/Mining_Camp_(Age_of_Empires_IV)
24. Fandom, *Villager (Age of Empires IV)*: https://ageofempires.fandom.com/wiki/Villager_(Age_of_Empires_IV)
25. Fandom, *Resource (Age of Empires IV)*: https://ageofempires.fandom.com/wiki/Resource_(Age_of_Empires_IV)
26. Fandom, *Boar*: https://ageofempires.fandom.com/wiki/Boar
27. Fandom, *Farm (Age of Empires IV)*: https://ageofempires.fandom.com/wiki/Farm_(Age_of_Empires_IV)
28. Foro oficial, *Tughlaq Dynasty* (2025): https://forums.ageofempires.com/t/tughlaq-dynasty/281669
29. Foro oficial, *Villagers not auto-collecting after building drop-off buildings* (respuesta del equipo, 2022): https://forums.ageofempires.com/t/villagers-not-auto-collecting-after-building-drop-off-buildings/209052
30. Notas oficiales, Update 9.1.176 (14-11-2023): https://www.ageofempires.com/news/age-of-empires-iv-update-9-1-109/ (Fandom: https://ageofempires.fandom.com/wiki/Update_9.1.176)
31. Foro oficial, *Select idle villagers in a radius*: https://forums.ageofempires.com/t/select-idle-villagers-in-a-radius/226752
32. Foro oficial, *Broken Idle for Farmers*: https://forums.ageofempires.com/t/broken-idle-for-farmers/221528
33. Foro oficial, *Bug or not? Villagers do not remain in farms…* (respuesta del equipo, 2022): https://forums.ageofempires.com/t/bug-or-not-villagers-do-not-remain-in-farms-if-last-queued-action-has-no-vill-cap/196148
34. Foro oficial, *[Feature Request] Villager Construction Distribution Option* (2026): https://forums.ageofempires.com/t/feature-request-villager-construction-distribution-option/287650
35. Fandom, *Professional Scouts*: https://ageofempires.fandom.com/wiki/Professional_Scouts
36. Fandom, *Deer*: https://ageofempires.fandom.com/wiki/Deer
37. Fandom, *Gather Point* (sección AoE4): https://ageofempires.fandom.com/wiki/Gather_Point
38. Notas oficiales, Update 10.0.576 / Temporada 7 (20-3-2024): https://www.ageofempires.com/news/age-of-empires-iv-season-seven-update-10-0-576/ (Fandom: https://ageofempires.fandom.com/wiki/Update_10.0.576)
39. Foro oficial, *How to dominate French in Boulder Bay as HRE*: https://forums.ageofempires.com/t/how-to-dominate-french-in-boulder-bay-as-hre/184269
40. Foro oficial, *HRE Build order?*: https://forums.ageofempires.com/t/hre-build-order/187867
41. Fandom, *Barracks (Age of Empires IV)*: https://ageofempires.fandom.com/wiki/Barracks_(Age_of_Empires_IV)
42. Fandom, *Archery Range (Age of Empires IV)*: https://ageofempires.fandom.com/wiki/Archery_Range_(Age_of_Empires_IV)
43. Fandom, *Stable (Age of Empires IV)*: https://ageofempires.fandom.com/wiki/Stable_(Age_of_Empires_IV)
44. Fandom, *Siege Workshop (Age of Empires IV)*: https://ageofempires.fandom.com/wiki/Siege_Workshop_(Age_of_Empires_IV)
45. Fandom, *Feudal Age (Age of Empires IV)*: https://ageofempires.fandom.com/wiki/Feudal_Age_(Age_of_Empires_IV)
46. Fandom, *Abbasid Dynasty*: https://ageofempires.fandom.com/wiki/Abbasid_Dynasty
47. Foro oficial, *Mechanics and characteristics of Age of Empires 3…*: https://forums.ageofempires.com/t/mechanics-and-characteristics-of-age-of-empires-3-which-should-not-be-missing-in-age-of-empires-4/179401
48. Foro oficial, *(PUP) Fully Remappable Hotkey issues*: https://forums.ageofempires.com/t/pup-fully-remappable-hotkey-issues/206104
49. Foro oficial, *[suggestion] Buildings in progress… global production queue*: https://forums.ageofempires.com/t/suggestion-buildings-in-progress-except-landmarks-should-be-displayed-in-global-production-queue/288990
50. Fandom, *Population* (sección AoE4): https://ageofempires.fandom.com/wiki/Population
51. Fandom, *Mongols (Age of Empires IV)*: https://ageofempires.fandom.com/wiki/Mongols_(Age_of_Empires_IV)
52. Fandom, *Ger*: https://ageofempires.fandom.com/wiki/Ger
53. Fandom, *Military School*: https://ageofempires.fandom.com/wiki/Military_School
54. Fandom, *Ottomans (Age of Empires IV)*: https://ageofempires.fandom.com/wiki/Ottomans_(Age_of_Empires_IV)
55. Fandom, *Influence (Age of Empires IV)*: https://ageofempires.fandom.com/wiki/Influence_(Age_of_Empires_IV)
56. Fandom, *Malians (Age of Empires IV)*: https://ageofempires.fandom.com/wiki/Malians_(Age_of_Empires_IV)
57. Foro oficial, *AoE4 is less interesting than AoE2…*: https://forums.ageofempires.com/t/aoe4-is-less-interesting-than-aoe2-because-its-units-lack-coolness-and-personality/192603
58. Foro oficial, *AOE 4 HOTKEYS: SELECT ALL MILITARY BUILDINGS*: https://forums.ageofempires.com/t/aoe-4-hotkeys-select-all-military-buildings/200624
59. Fandom, *Town Center (Age of Empires IV)*: https://ageofempires.fandom.com/wiki/Town_Center_(Age_of_Empires_IV)
60. Fandom, *Town Bell*: https://ageofempires.fandom.com/wiki/Town_Bell
61. Foro oficial, *Great Poll about autoqueue!*: https://forums.ageofempires.com/t/great-poll-about-autoqueue/238573 ; *We need Optional Auto Queue Feature*: https://forums.ageofempires.com/t/we-need-optional-auto-queue-feature/187031
62. aoe4world, API de estadísticas por civilización (consultada el 14-11-2026): https://aoe4world.com/api/v0/stats/rm_solo/civilizations y `?rank_level=conqueror`
63. Foro oficial, *Please no tower rush*: https://forums.ageofempires.com/t/please-no-tower-rush/127911
64. Foro oficial, *What are your best 1v1 strategies?*: https://forums.ageofempires.com/t/what-are-your-best-1v1-strategies/185818
65. Foro oficial, *Why do people keep suggesting… Starcraft 2 elements*: https://forums.ageofempires.com/t/why-do-people-keep-suggesting-trying-to-add-starcraft-2-elements-into-aoe-iv/174164
66. Foro oficial, *How to face burgrave rush as abbasid?*: https://forums.ageofempires.com/t/how-to-face-burgrave-rush-as-abbasid/223419
67. Foro oficial, *Is 9 mins imperial possible for HRE?*: https://forums.ageofempires.com/t/is-9-mins-imperial-possible-for-hre/232032
68. Foro oficial, *Already Nerfeen the Steppe, by God!*: https://forums.ageofempires.com/t/already-nerfeen-the-steppe-by-god/199907
69. Foro oficial, *Auto queue villagers?*: https://forums.ageofempires.com/t/auto-queue-villagers/227433
70. Foro oficial, *Mali Has Been on Life Support*: https://forums.ageofempires.com/t/mali-has-been-on-life-support/265617 ; *Order of the Dragon bad or not?*: https://forums.ageofempires.com/t/order-of-the-dragon-bad-or-not/266576
