# Otros RTS: economías asimétricas y costo de atención

Investigación de referencia para el diseño de **Raíces**. Fecha de relevamiento: noviembre de 2026. No es una decisión: es material para que el equipo tenga criterio más allá de AoE4. Se cruza con el modelo "una riqueza, seis motores" de `../revision-economia/00-sintesis.md`.

## Cómo leer este documento

- **Fuentes.** Páginas oficiales (ageofempires.com, news.blizzard.com, classic.battle.net), Wikipedia, Game Developer (ex Gamasutra), prensa y foros oficiales. Varias fuentes clave **no se pudieron leer directamente**: las wikis de Fandom (402), Liquipedia (429), TeamLiquid (403), Reddit y algunos artículos de Kotaku y PC Gamer. Cuando un dato sale solo del resumen de un buscador o de una guía de terceros, lo marco **[no verificado de primera mano]**.
- **Números.** Los números de guías de terceros pueden estar desactualizados por parches. Sirven para ver órdenes de magnitud y formas de curva, no para copiar.
- **Citas.** Lo que va entre comillas es textual, en inglés, como aparece en la página enlazada. Cuando resumo, no uso comillas.
- **Vocabulario.** "Costo de atención" = cuántas veces por minuto el juego le pide al jugador mirar o tocar algo que no es mandar aldeanos ni pelear. "Trickle" = goteo: recurso que entra solo, sin trabajadores.

---

## 0. Respuestas cortas a las tres preguntas

1. **Mecánicas de "estar pendiente".** Suman cuando cada activación es una **decisión** (dónde, cuándo, a costa de qué) y cuando olvidarla cuesta algo proporcional y visible. Son tedio cuando son un **ritual** que siempre se hace igual, cada X segundos, sin elegir nada. Ese es el criterio que usaron Frost Giant para Stormgate y Blizzard al rediseñar el Chrono Boost en 2017 (secciones 4 y 5). El caso del inject zerg muestra el otro lado: ese ritual es una prueba de habilidad deliberada en el juego competitivo de élite, pero pocos juegos se lo pueden permitir.
2. **Una civ "comerciante" cuando todos comercian.** Un porcentaje sobre el comercio común (AoE2) funciona como sabor, pero no da identidad por sí solo. Los juegos que lo resolvieron le dieron a la civ un **verbo propio** dentro del comercio (el mercado de ganado hausa), un **producto distinto** del comercio (influencia en AoE3, influencia comercial que lleva a la victoria en Northgard) o una **contraparte distinta** (los clanes de Northgard que comercian con los gigantes neutrales).
3. **Que un recurso disputado no decida la partida.** Ingreso base garantizado, como el manpower de CoH. El recurso disputado da **tipo** o **aceleración**, no volumen. Además: rendimientos decrecientes y topes (griegos en AoM, límite comercial en Rise of Nations, mantenimiento o upkeep en Warcraft III), varios puntos en vez de uno, y una contra clara (cortar la línea de suministro en CoH).

---

## 1. Age of Empires II DE: bonificaciones casi pasivas

### Qué son

Cada civ tiene 3 o 4 bonificaciones de civ y una de equipo, casi todas numéricas y sin botón. Algunos ejemplos económicos, según una guía de jugadores ([gameplay.tips](https://gameplay.tips/guides/5828-age-of-empires-ii-definitive-edition.html)) **[valores posiblemente desactualizados]**:

| Civ | Bonificación | Qué toca |
|---|---|---|
| Chinos | "Start Game with 3 extra villagers but -200 Food and -50 Wood"; tecnologías más baratas por edad | Arranque y curva de tecnología |
| Mayas | "Resources last 15% longer" | Todo el mapa, sin acción |
| Francos | "Farm upgrades free", recolectores de bayas más rápidos | Granja y bayas |
| Vikingos | "Wheelbarrow, Hand Cart techs free" | Tecnologías económicas |
| Turcos | "Gold miners work 20% faster" | Un recurso |
| Malíes | "Buildings cost -15% wood", minería de oro gratis | Construcción y oro |
| Etíopes | "+100 gold, +100 food when advancing to the next age" | Un pulso en cada edad |
| Sarracenos | "Market trade cost is 5% of goods" | El mercado común |
| Portugueses | "All units cost -15% gold", Feitoria en edad imperial | Oro y un edificio de goteo |

También hay bonificaciones sobre el comercio común: según listados de la comunidad, los españoles tienen más oro por carro de comercio, los bohemios entrenan carros más rápido, los bengalíes sacan comida además de oro, y la tecnología Silk Road de los italianos abarata las unidades de comercio ([altarofgaming](https://altarofgaming.com/age-of-empires-ii-civilizations/), [brainscape](https://www.brainscape.com/flashcards/age-of-empires-ii-civilization-bonuses-3-17631293/packs/22551587)) **[no verificado de primera mano]**.

### Por qué funcionan

- **Costo de atención cero.** No agregan clics. Con decenas de civs (el juego pasó de 13 a más de 40), es la única forma de que un jugador conozca las civs ajenas sin un manual.
- **Cambian la decisión aunque no tengan botón.** "Minería de oro un 20% más rápida" empuja a los turcos a unidades caras en oro. El jugador decide distinto sin que la civ le pida nada. Las bonificaciones bien hechas **inclinan** la estrategia; las malas son un número que no cambia nada (el mismo diagnóstico que hacen los jugadores de AoE4 sobre el prelado del Sacro Imperio, ver `02-voz-de-los-jugadores.md`).
- **Equilibrio fino barato.** El equipo de Forgotten Empires describe un proceso de planillas y pruebas en LAN, y una política de subir lo débil en vez de bajar lo fuerte: *"Players prefer to see boosts to unpopular units, rather than seeing their beloved units being punished directly"* ([dev blog, 2015](https://www.forgottenempires.net/age-of-empires-ii-hd-dev-blog-6-balance-testing)). Un porcentaje se ajusta en una línea; una mecánica nueva, no.
- **El objetivo de diseño era la paridad, no el contraste.** Sandy Petersen, de Ensemble: *"As a game designer, I strive to get all the civs to be equally desirable"* ([Q&A de la MS Gaming Zone, c. 2000](https://forums.ageofempires.com/t/ms-gaming-zone-historical-dev-q-a-interview-circa-2000/101478)).

### Límites

- Las bonificaciones pasivas **no generan momentos**: nadie recuerda una partida por la bonificación maya.
- Son legibles para quien juega mucho e invisibles para quien empieza. No sirven como **identidad de primera vista**, que es lo que Raíces busca (pilar de asimetría).

---

## 2. Age of Empires III DE: metrópoli, nativos, asiáticos y africanos

### 2.1 Envíos de la metrópoli

- La metrópoli es una ciudad fuera del mapa, inatacable. Se gana experiencia (XP) construyendo, entrenando y combatiendo; cada tanto la XP habilita un **envío**, que es una carta del mazo: unidades, mejoras o recursos. El mazo se arma antes de la partida ([Wikipedia](https://en.wikipedia.org/wiki/Age_of_Empires_III)). Los envíos se espacian porque cada uno pide más XP. Matar unidades da una recompensa de XP del 10% del costo de la unidad muerta ([resumen del buscador sobre el wiki de Fandom](https://ageofempires.fandom.com/wiki/Home_City)) **[no verificado de primera mano]**.
- **Asimetría barata:** los españoles necesitan menos XP por envío y los alemanes más (misma fuente) **[no verificado de primera mano]**. Es el mismo sistema con un parámetro distinto.
- **Costo de atención:** bajo y **puntual**. Cada envío es una decisión real (qué carta y cuándo), con un aviso claro. Es el ejemplo canónico de una mecánica periódica que **no** es tedio: el jugador elige entre opciones de valor distinto según la situación, que es exactamente la definición de decisión interesante de Sid Meier (sección 8).
- **Lección:** que una mecánica sea periódica no la hace tediosa. Lo que la vuelve tediosa es que sea **siempre la misma**.

### 2.2 Nativos y puestos comerciales

- Se construye un puesto comercial en un asentamiento nativo para aliarse con él. Eso da unidades y tecnologías propias de cada tribu ([Wikipedia](https://en.wikipedia.org/wiki/Age_of_Empires_III)). Los puestos sobre las **rutas comerciales** dan XP o recursos según un selector ([resumen del buscador](https://www.alteredgamer.com/age-of-empires-3/123044-aoe3-age-of-empires-iii-complete-review)) **[no verificado de primera mano]**.
- Un hilo del foro oficial sobre nativos señala un problema de atención concreto: las habilidades de los nativos *"aren't passive abilities. You have to manually activate them which means they're very easily forgotten or ignored entirely"*. Y propone el criterio *"the idea is that they are useful when you want to use them"* ([foro oficial](https://forums.ageofempires.com/t/natives-or-minor-factions-general-discussion/248499)).
- **Lección:** una habilidad que se activa a mano, compite con todo lo demás y rinde poco se olvida. Si se pide atención, el retorno tiene que ser visible.

### 2.3 Los asiáticos: exportación, santuarios, maravillas

- **Exportación:** un quinto recurso solo de las tres civs asiáticas, que se junta despacio mientras los aldeanos recolectan y se gasta en el consulado para contratar tropas de un aliado extranjero (o en el aislacionismo, en el caso japonés) ([Wikipedia](https://en.wikipedia.org/wiki/Age_of_Empires_III:_The_Asian_Dynasties)). Es un recurso **derivado**: no tiene motor propio, depende del motor común.
- **Santuarios japoneses:** los japoneses no pueden cazar ni pastorear, pero sus santuarios dan un goteo de recursos, sirven de casa y **atraen animales**, y eso aumenta lo que producen ([Wikipedia](https://en.wikipedia.org/wiki/Age_of_Empires_III:_The_Asian_Dynasties); lo de atraer animales sale de un resumen del buscador, **[no verificado de primera mano]**). Ubicar los santuarios es una decisión espacial que se toma una sola vez.
- **India:** aldeanos que cuestan madera en vez de comida, y un campo sagrado que da XP cuando se le asigna ganado (misma fuente).
- **Edades por maravilla:** se cambia de edad construyendo una maravilla, cada una con un efecto propio (misma fuente).
- Para ser honestos, la propia página aclara que el equipo priorizó contenido nuevo sobre gameplay nuevo: *"Rather than introduce new methods of gameplay, most changes were focused on introducing new content to the game"*.

### 2.4 Los africanos: influencia y ganado (Etiopía y Hausa)

Es el antecedente más directo para Raíces: Etiopía está en los dos juegos.

- **Influencia:** recurso nuevo de las civs africanas. Sale de los puestos comerciales sobre rutas, de los monasterios de montaña etíopes y del ganado engordado ([página oficial](https://ageofempires.com/news/aoeiii-de-africanroyals)). Se gasta en las **alianzas**: *"gain new Alliances with every age and use your Influence to hire your allies' units or research their technologies"* ([página del DLC](https://ageofempires.com/games/aoeiiide/the-african-royals)).
- **Ganado:** *"sell a cow to build your first House or University, age up quickly by eating them early, or sell one to train several more as an investment for later"* ([página oficial](https://ageofempires.com/news/aoeiii-de-africanroyals)). El ganado funciona como un **activo** con varios usos: comida ya, influencia con el tiempo o dinero en el mercado.
- **Hausa:** la universidad es su edificio económico principal y rinde más cerca del centro urbano, el palacio y el puesto comercial. El mercado de ganado es mercado y corral a la vez (misma fuente).
- **Etiopía:** el monasterio de montaña produce influencia o monedas según un selector, junta recursos con los abunes y cura en batalla. Los graneros son gratis, tardan en construirse y aceleran a los aldeanos que juntan comida cerca (misma fuente).
- **La voz del diseñador** (Tilanus, en el foro oficial, [hilo](https://forums.ageofempires.com/t/development-of-african-royals/244133)):
  - *"Owning a large herd of cattle was an indicator of wealth and status."* El problema de diseño era encontrar *"a good gameplay reason to keep your livestock around for longer."*
  - Sobre la influencia: *"The Influence resource is a more consequential realization of the Export resource"*, y explica que la eligieron como **símbolo de estatus** (los cauris), no como moneda metálica.
  - *"Getting the cost conversions from food/wood/coin to Influence as well as the Influence gather rates right was quite the mathematical challenge."* Es una advertencia útil: un recurso con varios motores y varias conversiones multiplica el trabajo de balance.
- **Lección para Raíces:** el modelo africano de AoE3 se parece mucho a "una riqueza, seis motores" en pequeño: un recurso de estatus que sale de varias fuentes (rutas, monasterio, ganado) y se gasta en un sumidero común (alianzas). Y la observación del autor sobre el ganado vale para los mapuches: el ganado necesita una razón para **quedarse vivo** que pese más que comérselo.

### 2.5 Los goteos y el juego en equipo

Un hilo del foro oficial ataca los edificios de goteo (bancos holandeses, fábricas, torps suecos, santuarios japoneses, kanchas incas, la torre de porcelana china): *"There is no villager you should train to work at those building, no villager you should dispatch to occupy at those building, and no villager your opponent can kill at those building"* ([foro oficial](https://forums.ageofempires.com/t/building-providing-trickle-of-resources-should-be-reworked-in-team-game/111887)). La propuesta era exigir trabajadores dentro, para que el goteo compita con la población. Otros jugadores lo defienden como parte del juego. No hay respuesta de los desarrolladores en el hilo.

**Lección:** un goteo sin nadie que lo trabaje y sin nadie que lo pueda matar es un motor **sin contrajuego**. Si Raíces usa goteos, conviene atarlos a algo atacable: un edificio expuesto, trabajadores dentro o ganado.

---

## 3. Age of Mythology (y Retold): el favor, "una riqueza, varios motores"

Es **el precedente clave**. Ensemble lo armó en 2002: un recurso común (favor) que todos gastan en lo mismo (unidades míticas, algunas tecnologías y, en algunos casos, poderes divinos), pero que cada panteón produce de un modo distinto y temático. Retold (2024) cambió varios motores, y esos cambios enseñan tanto como el diseño original.

### 3.1 Los motores, panteón por panteón

| Panteón | Motor de favor | Forma de la curva | Costo de atención | Exposición al rival | Fuente |
|---|---|---|---|---|---|
| **Griegos** | Aldeanos rezando en templos | Lineal según aldeanos asignados, con **rendimientos decrecientes** | Bajo: asignar y olvidarse. El costo real es de oportunidad: un aldeano que reza no junta | Media: aldeanos en el templo | [oficial](https://www.ageofempires.com/games/aom/civilizations/greeks/), [foro](https://forums.ageofempires.com/t/zeus-aphrodite-give-20-bonus-to-favor-income-but-this-is-incorrect/262178) |
| **Egipcios** | Hasta cinco monumentos, cada uno más caro | Escalonada: cada monumento sube la tasa | Casi nulo: construir y listo | Baja a media: edificios resistentes | [oficial](https://www.ageofempires.com/games/aom/civilizations/egyptian-pantheon/), [notas de parche](https://www.ageofempires.com/news/age-of-mythology-retold-update-17-64528/) |
| **Nórdicos** | Daño infligido en combate y caza | Depende de la actividad: sin pelea no hay favor | Alto: hay que buscar pelea | Alta: el motor **es** el riesgo | [oficial](https://www.ageofempires.com/games/aom/civilizations/norse-pantheon/) |
| **Atlantes (original)** | Poseer centros urbanos; más centros, más favor | Atada a la expansión | Nulo | La del centro urbano | [Wikipedia](https://en.wikipedia.org/wiki/Age_of_Mythology:_The_Titans) |
| **Atlantes (Retold)** | Oráculos quietos, que no pueden estar cerca entre sí | Lineal según oráculos | Medio: ubicarlos y protegerlos | Alta: unidades frágiles y expuestas | [oficial](https://www.ageofempires.com/games/aom/civilizations/atlanteans/), [resumen del buscador](https://primagames.com/gaming/fastest-way-to-get-favor-in-age-of-mythology-retold) |
| **Chinos** | Cada edificio extiende la "tierra favorecida" | Atada al territorio | Bajo: es urbanismo | La de la base | [oficial](https://www.ageofempires.com/games/aom/civilizations/chinese-pantheon/) |
| **Japoneses** | Santuarios atendidos por miko, que rinden más cuantos más recursos tengan cerca | Atada a la ubicación | Bajo a medio: decisión espacial | Media | [oficial](https://www.ageofempires.com/games/aom/civilizations/japanese-pantheon/) |
| **Aztecas** | Ofrendas de colonos en el templo (picos de favor) y sacrificios en el Gran Templo; los sacerdotes guerreros recogen *tonalli* de los enemigos muertos | A pulsos: se cambia población por favor | Medio: decisiones de sacrificio | Variable | [oficial](https://www.ageofempires.com/games/aom/civilizations/aztec-pantheon/) |

Los números que circulan (todos de Retold):

- **Griegos:** con un aldeano, 0,1 de favor por segundo; con 100, unos 0,019 por aldeano ([reporte en el foro oficial](https://forums.ageofempires.com/t/zeus-aphrodite-give-20-bonus-to-favor-income-but-this-is-incorrect/262178)). En el mismo hilo se ve un efecto colateral: el +20% de Zeus se sumaba como un valor fijo y no como porcentaje, así que con muchos aldeanos valía mucho más de lo anunciado. **Lección de implementación:** con rendimientos decrecientes, hay que definir bien sobre qué se aplica cada bonificación.
- **Egipcios:** la actualización 17 cambió la tasa por monumento. El primero bajó de 0.1 a 0.075; el tercero subió de 0.1 a 0.125 y el cuarto de 0.1 a 0.15 ([notas de parche](https://www.ageofempires.com/news/age-of-mythology-retold-update-17-64528/)). El efecto es que el favor temprano egipcio baja y el tardío sube: **se balancea la forma de la curva, no solo el total**.
- **Nórdicos:** según guías, 1 de favor cada 80 de daño (cada 64 para algunas unidades de Odín), el doble cazando, rendimiento que baja al pasar de 100 de favor obtenido en combate y queda en la mitad hacia los 300, y un goteo pasivo mínimo de los hersir ([resumen del buscador sobre varias guías](https://primagames.com/gaming/fastest-way-to-get-favor-in-age-of-mythology-retold)) **[no verificado de primera mano]**. Es decir: Retold le agregó al motor agresivo **un piso pacífico (la caza)**, **un piso pasivo (los hersir)** y **un techo blando**.
- **Atlantes:** 0,08 de favor por segundo por oráculo quieto, según guías **[no verificado de primera mano]**. El motor original por centros urbanos sigue disponible como opción: con Rheia y Horns of Consecration, los centros urbanos producen favor **[no verificado de primera mano]**.

### 3.2 Lo que dice la comunidad del motor nórdico

El hilo [*Suggestion / Rework Norse Favors*](https://forums.ageofempires.com/t/suggestion-rework-norse-favors/261507) es el debate más útil para Raíces:

- La queja: *"Norse favor generation ingame feels slow and restrictive compared to other civilizations"*; *"Hersir passive favor generation is a joke"*; *"Atlanteans and Greeks can spam out myth units in base... Norse is more difficult on preparing myth units."*
- La defensa: *"Gaining favour from fighting is the core identity of the Norse. Watering it down would completely change the way the pantheon is played."*

Las dos cosas son ciertas. Un motor agresivo da **la identidad más fuerte** y **la frustración más fuerte**. La frustración aparece cuando el rival no acepta pelear o cuando el mapa no ayuda (poca caza), porque ahí el motor depende de lo que haga el otro.

### 3.3 Qué cambió Retold, y por qué importa

- **Atlantes: de pasivo a posicionable.** El favor por centro urbano (pasivo, atado a la expansión) pasó a los oráculos (unidades quietas, frágiles y que no se pueden amontonar). Un motor invisible se volvió un objeto en el mapa que se defiende o se caza. Las páginas oficiales no dan la razón; la lectura obvia es que el motor pasó a tener **contrajuego e interacción**, y que el oráculo, que era un explorador poco usado, ganó función.
- **Nórdicos: piso pacífico.** La caza cuenta doble, así que el motor agresivo tiene una salida que no depende de que el rival acepte pelear.
- **Egipcios: se ajustó la curva por tramos.** Es la herramienta fina de un motor escalonado.

### 3.4 Lecciones para "una riqueza, seis motores"

1. **El modelo funciona desde hace más de 20 años** y sobrevivió a una remasterización que agregó tres panteones con motores nuevos (territorio, ubicación, sacrificio). No es una apuesta.
2. **El sumidero tiene que ser común; el motor, propio.** En AoM todos gastan favor en cosas del mismo tipo. Eso es lo que permite balancear: se compara favor por minuto contra favor por minuto.
3. **Cada motor tiene una curva temporal distinta**, y esa curva es parte de la identidad: el griego escala con aldeanos, el egipcio escalona por inversión, el nórdico depende de la actividad y el atlante crece con la expansión o con los oráculos. Para balancear, hay que comparar **curvas**, no tasas sueltas: favor acumulado a los 5, 10 y 20 minutos.
4. **Cada motor tiene una exposición distinta.** Hay motores que se pueden atacar (oráculos, rezadores) y motores casi inmunes (monumentos). Los inmunes son los más cómodos y los menos interactivos (es lo mismo que la queja contra los goteos de AoE3).
5. **El motor agresivo necesita un piso pacífico.** Es exactamente lo que dice la tabla de `00-sintesis.md` ("variante agresiva que no sea la única"). AoM llegó a eso por la vía dura: veinte años de quejas sobre los nórdicos y un parche de caza en Retold.
6. **Los rendimientos decrecientes son la herramienta estándar** para que un motor no se dispare (griegos, nórdicos con techo blando). Hay que definir con cuidado cómo interactúan con las bonificaciones porcentuales (el caso Zeus).
7. **El costo de atención del favor es bajo en casi todos los panteones.** Ninguno pide clics periódicos. Lo que piden es una **decisión de asignación** (cuántos rezan, dónde va el oráculo, cuándo sacrificar). Es un buen techo para Raíces: el motor propio se decide; no se mantiene a mano.

---

## 4. StarCraft II: inject, chrono y MULE como "impuesto de atención"

### Qué son

- **Zerg, *Spawn Larva* (inject):** la reina gasta energía para que un criadero genere larvas extra. Se repite cada ~30 segundos por criadero.
- **Protoss, *Chrono Boost*:** acelera la producción de un edificio.
- **Terran, *MULE*:** el centro de mando orbital suelta una unidad temporal que junta minerales.

Las tres son habilidades periódicas con energía, y hacerlas a tiempo separa a un buen jugador de uno mediocre.

### La historia: casi se eliminan

- **Agosto de 2015, beta de Legacy of the Void.** Blizzard probó: *"Spawn Larva is reduced to 2 per injection, and set to autocast by default"*, *"M.U.L.E. is removed"*, *"Chrono Boost is removed"* ([vista previa del parche](https://news.blizzard.com/en-us/starcraft2/19875306)). La prensa lo cubrió como la eliminación de las mecánicas de macro ([VCPost](https://vcpost.com/articles/87064/20150826/starcraft-2-legacy-void-news-blizzard-entertainment-removes-macro-mechanics.htm)).
- **La comunidad se partió.** Kevin "qxc" Riley, a favor: el macro *"has become the least exciting and interesting task"*, porque son acciones repetidas a intervalos fijos. Stefan "Morrow" Andersson, en contra: los cambios *"are going too far"* (misma fuente).
- **Septiembre y octubre de 2015.** David Kim, en la actualización de la comunidad del 18 de septiembre: *"We don't agree with the idea that macro mechanics should be completely removed"* ([TL.net, citado vía buscador](https://tl.net/forum/legacy-of-the-void/495037-community-feedback-update-september-18)) **[no verificado de primera mano]**. Las mecánicas volvieron con menos rendimiento: los parches de balance de octubre ajustan otra vez la eficiencia del Chrono y bajan el retorno de la MULE de 3.85 a 2.05 ([2 de octubre](https://news.blizzard.com/en-us/starcraft2/19911023), [9 de octubre](https://news.blizzard.com/en-us/starcraft2/19919131)). La idea, según la cobertura, era que si rinden menos, hacerlas perfectas importa menos ([resumen del buscador](https://www.pcgamesn.com/starcraft-ii/legacy-of-the-void-gets-macro-mechanics-back-now-theyre-auto-cast)).
- **Noviembre de 2017, parche 4.0.** El Chrono se rediseñó como una habilidad del nexo que cuesta 50 de energía y que se apunta a un edificio. Al mes, Blizzard la cambió a 50% durante 20 segundos ([notas del 4.0](https://news.blizzard.com/en-us/article/21183638/starcraft-ii-4-0-patchnotes), [resumen del buscador sobre el parche de diciembre](https://tl.net/forum/starcraft-2/529546-starcraft-ii-balance-update-december-18)) **[detalle no verificado de primera mano]**.

### La filosofía de fondo

- Blizzard defiende el "fácil de aprender, difícil de dominar", y las mecánicas de macro son parte del "difícil de dominar" ([resumen del buscador sobre la cobertura de 2015](https://kotaku.com/blizzard-is-quietly-making-huge-changes-to-starcraft-ii-1722892531)) **[no verificado de primera mano]**.
- Dustin Browder, en la GDC 2011, presentó StarCraft II como un deporte electrónico: hacerlo era *"like inventing Basketball 2"* ([PC Gamer](https://www.pcgamer.com/blizzard-say-making-starcraft-2-was-like-inventing-basketball-2)). En un deporte, la **carga simultánea** es parte de la prueba: el inject compite con el control del ejército justo en el momento de la pelea, y ahí está la gracia.

### Lectura

- **Inject:** ritual puro, cada 30 segundos, sin elegir nada. Para la élite es **una prueba de multitarea deliberada**; para el resto, una tarea. Blizzard lo mantuvo porque su producto es un deporte.
- **Chrono (2017):** se convirtió en una **decisión**: qué edificio acelerar (trabajadores, ejército, mejoras). Es el modelo que Frost Giant toma como bueno (sección 5).
- **MULE:** es una decisión ligera, porque la misma energía sirve para escanear o para suministros. Ese costo de oportunidad la salva del ritual puro.
- **Para Raíces:** no somos un deporte electrónico. Un inject sería un costo sin retorno para nuestro público. Un chrono o una MULE (energía con usos alternativos) sí son modelos aprovechables.

---

## 5. Stormgate (Frost Giant): quitar las tareas sin decisión

Frost Giant la fundaron ex Blizzard: Tim Morten, productor de StarCraft II, y David Kim, su diseñador de balance. Su postura pública sobre el macro es la más explícita del género:

- Según la compilación de declaraciones de su AMA hecha por la comunidad: *"There'll be less macro busywork. Non-strategic actions that must be continually repeated throughout the match without any decision making, such as sc2 queens injecting larvae, where every half a minute you have to use each queen to inject a hatchery, will be removed or diminished."* Como modelo a seguir mencionan el chrono boost, donde el jugador elige qué acelerar ([compilación en devtrackers.gg](https://devtrackers.gg/stormgate/p/8121e455-everything-we-know-about-stormgate-a-giant-compilation-with-sources)).
- El lema que los acompañó: bajar el **piso** de habilidad sin bajar el **techo** (titular de [PC Gamer](https://pcgamer.com/games/rts/stormgate-developers-say-they-want-to-lower-the-rts-skill-floor-not-the-skill-ceiling-its-okay-to-be-a-high-skill-game)).
- En la economía mencionaron trabajadores con **rendimiento decreciente**, para premiar la expansión y que el acoso a los recolectores sea menos castigador, y casas con efectos tácticos para que no se construyan en masa sin pensar (misma compilación).

**Lección:** el criterio "se repite durante toda la partida **sin decisión**" sirve como regla de aceptación de cualquier mecánica de atención en Raíces.

---

## 6. Northgard: recursos por clan y estaciones

- **Estaciones.** En invierno las granjas producen menos y el consumo de leña sube, así que el resto del año se juega para acumular ([PC Gamer](https://www.pcgamer.com/northgard-is-like-a-viking-themed-age-of-empires-with-dynamic-seasons/), [resumen del buscador](https://northgard.fandom.com/wiki/Food)). Es una **presión global y previsible**: no pide clics, pide planificar. El clan del oso, por ejemplo, sufre menos penalización en invierno ([resumen del buscador sobre el wiki](https://northgard.fandom.com/wiki/Clans)) **[no verificado de primera mano]**.
- **Poca microgestión, a propósito.** Sébastien Vidal, diseñador principal: *"We wanted to keep micro management to a minimum. We thought it would distract too much from both the strong atmosphere we wanted for the game and long term strategy. That is why a lot of actions are automated or semi-automated in the game"* ([Game Developer](https://www.gamedeveloper.com/design/crafting-the-multiple-victory-states-of-the-rts-i-northgard-i-)).
- **Expansión por casillas, con costo creciente**, para controlar el ritmo: *"This allowed us to control the pace of expansion and make direct rushes impossible"* (misma fuente).
- **Victorias múltiples como identidad cultural:** *"they were also great explorers and merchants, and had a strong oral culture around folklore and mythology. These aspects of their culture are translated in the game through the Lore, Trade and Fame victories"* (misma fuente).
- **Victoria comercial:** las coronas (krowns) se gastan en grandes rutas comerciales, que dan "influencia comercial", y 2000 de influencia dan la victoria ([resumen del buscador](https://northgard.fandom.com/wiki/Commercial_Influence)) **[no verificado de primera mano]**. El comercio no es solo un ingreso: es un **camino a ganar**.
- **Clanes con economías distintas.** El cuervo coloniza con coronas y comercia con los gigantes neutrales ([guía](https://gameplay.tips/guides/1304-northgard.html)). El kraken tiene un recurso propio (*Wyrd*) y le cuesta construir lejos de la costa ([PC Gamer](https://www.pcgamer.com/au/northgards-clan-of-the-kraken-dlc-lets-you-play-as-squid-worshippers/)). El lince convierte las cacerías en trofeos ([GamingOnLinux](https://www.gamingonlinux.com/2020/09/northgard-hits-2-million-copies-sold-clan-of-the-lynx-dlc-is-out-now/page=2)). El buey tiene aldeanos más fuertes que comen más ([GoNintendo](https://gonintendo.com/stories/353770-new-clan-of-the-ox-muscles-their-way-into-northgard-with-new-dlc)).

**Lección:** las presiones globales y previsibles (estaciones) dan profundidad económica **sin costo de atención por minuto**. Y un recurso de clan como el Wyrd convive bien con los comunes si se gasta en cosas propias.

---

## 7. Company of Heroes: territorio y recursos por sector

### Cómo funciona

- El mapa está dividido en sectores. La infantería captura puntos, y **solo rinden los sectores conectados al cuartel general**: *"like electrical lines — if the chain has a missing link, the flow gets truncated"* (Brendon Chung, [Game Developer](https://gamedeveloper.com/design/on-company-of-heroes)). Cortar la cadena deja sin recursos al rival y también le baja la población máxima ([guía de coh2.org](https://www.coh2.org/guides/1987/introduction-to-coh-franchise)).
- **Tres recursos con roles distintos.** El manpower (unidades y construcción) sale *"through the base sector and the HQ. This income is therefore guaranteed"*. El combustible marca el ritmo tecnológico y la munición paga habilidades y mejoras; los dos dependen del territorio (misma guía).
- **La victoria va por otro carril:** puntos de victoria que consumen los "tickets" del rival (misma guía). El recurso y la victoria están separados.

### Cómo evitan que "quien controla el centro gana"

1. **Piso garantizado.** El manpower, el recurso de volumen, no se puede quitar. Lo disputado es el combustible y la munición: **ritmo y opciones**, no la existencia del ejército.
2. **El territorio rinde por cadena, no por punto.** Un punto rico en el centro no sirve si te cortan el flanco. El control del mapa es una **red**, y toda red tiene muchas formas de romperse.
3. **Varios puntos de alto valor**, repartidos en mapas en espejo (práctica general del género; la guía insiste en que *"High resource sectors are no less important than Victory Points!"*).
4. **El mantenimiento (upkeep).** Cada unidad en el campo resta manpower. En la primera versión de CoH2, según un hilo de coh2.org, la población de 0 a 25 no pagaba, la de 26 a 75 pagaba 4 por punto y la de 76 a 100 no pagaba. Con eso, un jugador que perdía todo su ejército podía ganar más manpower que uno que lo conservaba: *"a winning player can get +99 income while a losing player ... can get +250 to +300"* ([hilo](https://coh2.org/topic/2615/explaining-manpower-income-and-upkeep/post/33261)). Las mecánicas para remontar demasiado fuertes **castigan el buen juego**.
5. **Todo empuja a salir de la base.** Chung: el sistema *"builds the game on a foundation of one thing: pushing players out of their bases and onto the battlefield"*, y es *"rules-light and possibilities-heavy"*.

### Parientes cercanos

- **Warcraft III, mantenimiento.** Por encima de 50 de comida se recibe el 70% del oro, y por encima de 80, el 40% ([Blizzard, classic.battle.net](https://classic.battle.net/war3/basics/upkeep.shtml)). Blizzard explica que *"Players are more aggressive and turtle far less in their bases"* y que *"High Upkeep is MEANT to be very punishing"*. Brandon Casteel lo clasifica como un "límite de velocidad" (impuesto por el sistema, sin agencia) frente a los "lomos de burro" (obstáculos que el jugador decide cómo superar, como casas y tecnologías), y señala que los límites se sienten castigadores ([Game Developer, 2021](https://www.gamedeveloper.com/game-platforms/the-importance-and-challenge-of-speed-bumps-in-rts-economies)).
- **Rise of Nations, límite comercial y recursos raros.** Hay un tope a la tasa de recolección que se sube con tecnologías en la biblioteca. La riqueza sale de caravanas que van y vienen entre ciudades propias, y los recursos raros (especias, seda, ballenas…) se explotan poniendo un mercader al lado, que da bonificaciones globales ([Wikibooks](https://en.wikibooks.org/wiki/Rise_of_Nations/Resources), [resumen del buscador sobre Wikipedia](https://www.wikipedia.org/wiki/Rise_of_Nations)) **[parcialmente no verificado de primera mano]**. Como el tope existe, controlar más recursos rinde menos después de cierto punto, y el recurso raro da **sabor** (una bonificación), no volumen.

---

## 8. Charlas y principios de diseño

- **Sid Meier, GDC 2012, "Interesting Decisions"** ([Game Developer](https://gamedeveloper.com/design/gdc-2012-sid-meier-on-how-to-see-games-as-sets-of-interesting-decisions), [GDC Vault](https://gdcvault.com/play/1015756/Interesting)): *"If a player always chooses the first from among a set of three choices, it's probably not an interesting choice"*. *"Good decisions are situational"*. También pide información suficiente para decidir: *"It's almost worth erring on the side of providing the player with too much information"*. Es la vara para medir cualquier mecánica de atención: ¿la respuesta cambia según la situación?
- **Bruce Shelley (Ensemble)** ([entrevista en Game Developer](https://www.gamedeveloper.com/design/interview-bruce-shelley---the-mythology-of-empires)): *"great game-play is a stream of interesting decisions the player must resolve"* y *"the inverted pyramid of decision making (have few decisions to deal with first, and then let them multiply until the player is totally engrossed)"*. Aplicado acá: **el motor propio tiene que ser simple en la edad I** y complicarse después.
- **Sandy Petersen (Ensemble):** paridad de deseo entre civs como objetivo (sección 1).
- **Dustin Browder (Blizzard), GDC 2011:** StarCraft II como deporte; un juego para espectadores tiene que ser *"watchable, simple, and clear"* ([notas de una charla posterior](https://bowling-bash.blogspot.com/2012/06/starcraft2-e-sport-design-bowder-2011.html)). En el panel de veteranos de la misma GDC, Soren Johnson pidió juegos *"simpler"* con reglas *"transparent"* ([Game Developer](https://www.gamedeveloper.com/game-platforms/gdc-2011-strategy-game-veterans-look-at-the-genre-s-biggest-challenges)).
- **Sébastien Vidal (Shiro):** poca microgestión para dejar lugar a la estrategia y la atmósfera (sección 6).
- **Frost Giant:** fuera las tareas repetidas sin decisión (sección 5).
- **La contracara, Brandon Casteel:** automatizar la economía sin compensar con otra cosa **le quita agencia al jugador**. Ejemplo: Grey Goo perdió *"nuance of the C&C economic model"* ([Wayward Strategy](https://waywardstrategy.com/2015/11/23/rts-design-thought-control-of-economic-processes/)). No hay que confundir "menos clics" con "menos decisiones".
- **Relic (CoH):** no encontré una charla de la GDC con el diseño del territorio (Josh Mosqueira fue diseñador del juego). El análisis de Brendon Chung es la mejor fuente que conseguí **[hueco: buscar en GDC Vault]**.

---

## 9. Las tres preguntas, en detalle

### 9.1 ¿Cuándo "estar pendiente" suma y cuándo es tedio?

Una prueba de cinco preguntas para cualquier mecánica que pida atención más allá de recolectar:

| Pregunta | Suma si… | Tedio si… | Ejemplo |
|---|---|---|---|
| ¿Hay **decisión** en cada activación? | La respuesta cambia según la situación (Meier) | Siempre se hace lo mismo | Chrono 2017 o envío de metrópoli (suma), frente a inject (ritual) |
| ¿El costo de **olvidarla** es proporcional y visible? | Se ve y se entiende qué se perdió | Se pierde mucho sin aviso, o nada | Habilidades de nativos en AoE3: rinden poco y se olvidan |
| ¿Con qué **frecuencia** se repite? | Cada pocos minutos, o atada a eventos (edad, pelea, estación) | Cada 20 o 30 segundos durante toda la partida | Envíos de metrópoli frente a inject |
| ¿**Compite** con la pelea? | Es un juego de élite que quiere medir multitarea | Es un juego que quiere que la atención esté en el ejército y en el mapa | StarCraft II lo quiere; Northgard y Stormgate, no |
| ¿Tiene **contrajuego**? | El rival la ve y la puede castigar | Es invisible e inatacable | Oráculos y rezadores (sí); bancos y monumentos (casi no) |

**Recomendación para Raíces:** el motor de riqueza de cada civ se **decide** (dónde, cuánto, qué) y después corre solo. Lo que pide atención periódica tiene que ser **raro y con opciones**, al estilo de los envíos de metrópoli o la MULE (energía con usos alternativos), nunca un inject. Si se agrega un "estar pendiente", que sea por **eventos** (cambio de estación, una caravana que llega, ganado listo para vender) y que avise. La IA tiene que poder hacerlo: si a la IA le cuesta, al jugador también.

### 9.2 Si todos comercian, ¿la civ comerciante se siente sin mecánica?

**Sí, si su identidad es solo un porcentaje sobre lo común.** Los españoles de AoE2 tienen más oro por carro y nadie los recuerda como "la civ del comercio". Cómo lo resolvieron otros:

1. **Verbo propio dentro del comercio.** El mercado de ganado hausa es mercado y corral a la vez: comercia con un activo que solo ellos explotan así ([oficial](https://ageofempires.com/news/aoeiii-de-africanroyals)). En Rise of Nations, el mercader de recurso raro es otro verbo, aunque ahí lo tienen todos.
2. **El comercio produce otra cosa.** En AoE3, los puestos de las civs africanas en las rutas dan **influencia** (lo que compra alianzas), no oro. En Northgard, las rutas dan **influencia comercial**, que lleva a una victoria propia.
3. **Contraparte distinta.** El clan del cuervo comercia con los **gigantes neutrales** y coloniza con coronas ([guía](https://gameplay.tips/guides/1304-northgard.html)). Lo común es comerciar con aliados; lo propio es comerciar con quien los demás no pueden.
4. **El comercio cambia el mapa.** Una ruta propia es un objetivo: invita a la escolta y al saqueo y genera interacción. Las caravanas de Rise of Nations van **entre ciudades propias**, así que el comercio empuja a expandirse.
5. **Bonificación más verbo.** Combinar un porcentaje (sabor barato) con al menos uno de los puntos anteriores.

**Para Raíces:** si "comerciar" es común, conviene que el comercio común sea **pobre y genérico** (un intercambio de mercado básico) y que la civ comerciante tenga **la ruta como motor de su riqueza**, con una decisión propia (con quién, por dónde, qué lleva) y un producto que los demás no sacan del comercio. Es la misma lógica de "una riqueza, seis motores": la riqueza es común, pero el motor comercial es de una sola civ.

### 9.3 ¿Cómo evitar que un recurso disputado decida la partida?

1. **Ingreso base garantizado.** El grueso del volumen no se disputa (manpower en CoH, recolección común en AoE).
2. **Lo disputado da tipo o ritmo, no volumen.** Combustible y munición en CoH; recursos raros en Rise of Nations; puestos comerciales con selector en AoE3.
3. **Rendimientos decrecientes y topes.** Rezadores griegos, techo blando nórdico, límite comercial de Rise of Nations, recolectores de Stormgate.
4. **Varios puntos y no uno**, repartidos en espejo. Que controlarlo todo sea caro de defender.
5. **Contrajuego de bajo costo.** Cortar la cadena en CoH: el poseedor tiene que defender una red, no un punto.
6. **Victoria separada del recurso.** Los tickets de CoH; las victorias múltiples de Northgard.
7. **Frenos a la bola de nieve, con cuidado.** El mantenimiento de Warcraft III funciona, pero se siente castigador (Casteel). El de la primera versión de CoH2 premiaba perder unidades. Los frenos tienen que **limitar al que gana**, no **pagarle al que pierde por perder**.
8. **Atención a las civs cuyo motor depende del mapa.** Si el motor propio de una civ necesita el recurso disputado, esa civ pierde dos veces cuando lo pierde. Por eso `00-sintesis.md` exige un motor que "funciona en cualquier terreno" y deja el terreno favorable como bonificación.

---

## 10. Tipología de mecánicas económicas asimétricas

| Tipo | Ejemplos | Costo de atención | Riesgos | Cuándo conviene |
|---|---|---|---|---|
| **1. Bonificación numérica pasiva** | AoE2: mayas (recursos duran más), turcos (oro), chinos (arranque) | Nulo | No da identidad visible ni momentos; puede ser un número que no cambia ninguna decisión | Como capa de sabor y ajuste fino sobre cualquier otro tipo. Nunca como identidad única |
| **2. Goteo sin trabajadores** | Bancos holandeses (AoE3), monumentos egipcios (AoM), Feitoria portuguesa (AoE2), santuarios japoneses (AoE3) | Nulo después de construir | Sin contrajuego; se acumula en juegos largos y en equipo; favorece encerrarse en la base | Si el edificio es atacable, caro y con tope de cantidad. Bueno para civs defensivas |
| **3. Trabajadores asignados a un edificio** | Rezadores griegos (AoM), universidad hausa, monasterio etíope (AoE3) | Bajo: una decisión de reparto | Si no hay rendimiento decreciente, se acumula todo ahí; el costo de oportunidad debe ser real | Para el motor base de una civ "constructora". Muy legible |
| **4. Habilidad periódica (energía o recarga)** | Inject, MULE, Chrono (SC2); Empower del faraón (AoM) | Alto si es ritual; medio si es decisión | Tedio, brecha entre novatos y expertos, castiga la pelea si compite con ella | Solo si cada uso elige algo (qué acelerar, energía con usos alternativos). Evitar el ritual puro |
| **5. Unidad o edificio posicionado** | Oráculos atlantes (Retold), mercader en recurso raro (RoN), santuarios cerca de recursos (AoM y AoE3 japoneses) | Medio al ubicar; bajo después | Microgestión si hay que moverlos seguido; muy vulnerable si se amontonan | Para dar interacción y lectura del mapa sin costo por minuto. Muy buen equilibrio |
| **6. Recurso por combate o riesgo** | Favor nórdico, *tonalli* azteca (AoM); XP por muertes (AoE3) | Alto: hay que buscar pelea | El rival controla tu motor si no pelea; mapas sin caza; bola de nieve | Como **variante** con piso pacífico y techo blando (Retold). Nunca como única fuente |
| **7. Recurso por territorio** | Sectores de CoH; tierra favorecida china (AoM); centros urbanos atlantes (AoM original); fronteras en RoN | Bajo por minuto; alto en lo estratégico | "Quien controla el centro gana"; la civ que pierde el mapa pierde también el motor | Con ingreso base garantizado, cadena (no punto) y rendimiento decreciente |
| **8. Ganado o capital que crece** | Influencia por ganado engordado, mercado de ganado hausa (AoE3) | Bajo a medio: decidir cuándo vender o comer | Si comerse el ganado rinde más que conservarlo, el motor no existe (Tilanus); robo de rebaños | Para civs pastoriles: el dilema "ahora o después" es una decisión de verdad |
| **9. Comercio o rutas** | Caravanas (RoN), puestos en rutas (AoE3), grandes rutas y victoria comercial (Northgard) | Bajo a medio: armar la ruta y protegerla | Se siente sin mecánica si es solo un %; la ruta indefendible frustra; el comercio común borra la identidad | Si una civ tiene un verbo, un producto o una contraparte que los demás no tienen |
| **10. Mazo o elección de aliados** | Metrópoli (AoE3), consulado asiático, alianzas africanas por edad | Bajo y puntual | Mucha preparación previa; difícil de leer para el rival | Para variedad entre partidas sin tocar el ciclo por minuto |
| **11. Presión global previsible** | Invierno (Northgard) | Nulo por minuto; alto en planificación | Si castiga mucho y sin aviso, es injusto; si es igual para todos, no es asimétrico | Para dar ritmo a todo el juego, con civs que lo sufren distinto (clan del oso) |
| **12. Freno global** | Mantenimiento (WC3, CoH), límite comercial (RoN), rendimientos decrecientes (Stormgate) | Nulo | Se siente castigador; mal calibrado, paga por perder (primera versión de CoH2) | Para frenar la bola de nieve. Preferir frenos que el jugador decide cómo superar (los "lomos de burro" de Casteel) |

### Cómo combinarlos en Raíces

- **Motor base de cada civ:** tipos 3, 5 u 8 (decisión de asignación, posición o activo), con costo de atención bajo y algo atacable.
- **Variante agresiva:** tipo 6, siempre con piso pacífico y techo blando.
- **Sabor:** tipo 1 encima de todo.
- **Común a todos:** tipos 11 y 12 para el ritmo y los frenos, y un comercio común pobre (tipo 9) que solo una civ convierte en motor.
- **Evitar:** el tipo 4 en forma de ritual y el tipo 2 sin contrajuego.

---

## Huecos de esta investigación

- No pude leer de primera mano las publicaciones de David Kim en TeamLiquid (2015), las wikis de Fandom ni Liquipedia. Los datos marcados **[no verificado de primera mano]** se verifican cuando esas fuentes estén accesibles.
- No encontré la charla de la GDC de Relic sobre el diseño territorial de CoH, ni declaraciones de Ensemble sobre por qué los nórdicos ganan favor peleando.
- Faltan los datos de AoM Retold sobre el tope de favor y el detalle actual del favor de los aztecas.
