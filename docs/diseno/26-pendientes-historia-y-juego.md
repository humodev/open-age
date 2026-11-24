# 26 · Pendientes de historia y de juego

Fecha: 2026-11-16. Etapa 26, paso 2 ([`proceso/26-juego-tardio`](../../proceso/26-juego-tardio/README.md)).

> Pedido del autor: "Agrupá todos los errores históricos importantes que cometimos y todas las sugerencias del jugador experto que pueden mejorar el gameplay, y sumémoslas al diseño."

## De dónde sale

- **Historia:**
  - los tres informes de la revisión histórica ([01 América Latina](../../proceso/25-revision-historica/01-america-latina.md), [02 África](../../proceso/25-revision-historica/02-africa.md), [03 Asia](../../proceso/25-revision-historica/03-asia.md));
  - lo que ya se corrigió ([04](../../proceso/25-revision-historica/04-correcciones-aplicadas.md));
  - las rondas 1 a 3 del jugador de historia ([1](../../proceso/22-testers/03-historia-y-estetica.md), [2](../../proceso/22-testers/ronda-2/03-historia-y-estetica.md), [3](../../proceso/22-testers/ronda-3/03-historia-y-estetica.md));
  - [`CONSULTAS.md`](../../proceso/CONSULTAS.md), C-39 a C-44 y C-53 a C-74.
- **Juego:**
  - las seis rondas del veterano de AoE4 ([1](../../proceso/22-testers/01-veterano-aoe4.md), [2](../../proceso/22-testers/ronda-2/01-veterano-aoe4.md), [3](../../proceso/22-testers/ronda-3/01-veterano-aoe4.md), [4](../../proceso/22-testers/ronda-4/01-veterano-aoe4.md), [escala](../../proceso/22-testers/ronda-4/03-escala-veterano.md), [5](../../proceso/22-testers/ronda-5/01-veterano-aoe4.md), [6](../../proceso/22-testers/ronda-6/01-veterano-aoe4.md)) y sus síntesis;
  - la tabla de frentes de la [etapa 24](../../proceso/24-tras-la-segunda-ronda/README.md) y [`docs/09-estado.md`](../09-estado.md).

**Estado de las consultas al 2026-11-16.** De C-39 a C-74, el autor contestó solo C-65 (velocidad: c, "dejarla hasta tener animaciones"). Donde dice "en consulta", la consulta está **sin respuesta**. En varias se aplicó ya la opción prudente mientras tanto (C-53, C-54, C-55 y C-57 con la b; C-64 con la a); se aclara en cada fila.

**Códigos de estado:**
- **Corregido:** ya está en los datos o en el arte (commit `0af58e0` o etapa 24).
- **En consulta C-xx:** espera la respuesta del autor.
- **Pendiente sin consulta:** nadie lo preguntó todavía; se puede hacer o preguntar.
- **Pendiente técnico:** está decidido o no necesita decisión, pero pide código, mallas o un campo nuevo en los datos.

**"Toca balance"** quiere decir que cambia números de la simulación y hay que medirlo con torneo (`tests/torneo.gd -- --minutes=30 --seeds=2` como mínimo; la regla del proyecto es 10 semillas para cerrar).

No se incluyen los errores menores que ya se corrigieron (fechas, citas, frases sueltas: están en `04-correcciones-aplicadas.md`). Sí se incluyen los importantes aunque ya estén corregidos, para que el diseño no vuelva a caer en ellos.

---

# Parte 1 · Errores históricos importantes

## 1.1 Economía mal representada

La regla del juego es que la mecánica cuente la historia. Cuando la mecánica dice otra cosa, el panel miente aunque el texto esté bien, y por eso estos textos **no se tocaron** sin cambiar la mecánica.

| # | Pueblo | Qué está mal | Fuente | Estado | Propuesta de diseño |
|---|---|---|---|---|---|
| H-01 | Guaraníes | **La roza agotada deja un yerbal.** La yerba (*ka'a*) era un árbol silvestre del monte (Mbaracayú, Tarumá). En la colonia se cosechaba con trabajo forzado de encomienda, y solo las reducciones la plantaron, desde fines del siglo XVII. Una roza abandonada se vuelve *capuera*, no yerbal. La propia misión 4 dice "los yerbales que habíamos plantado" y contradice la mecánica | Garavaglia, *Mercado interno y economía colonial* (1983); Meliá, *El guaraní conquistado y reducido* (1986); Ganson (2003). Informe 01, E1 | En consulta **C-67** | Nodo silvestre de *ka'a* en el bosque, que se cosecha y se agota. Yerbal plantado recién en la vía misión (edad III). La roza agotada deja *capuera* (la clave ya existe). En la ficha, una línea: la yerba fue tributo y trabajo forzado. **Toca balance** (es el motor de riqueza guaraní) |
| H-02 | Guaraníes | **Sin ganado en la vía misión.** Las reducciones tuvieron grandes estancias (Yapeyú); el pecarí se amansaba en la casa (*mymba*), no en rebaño | Informe 01, E10 y S7 | Nota corregida; mecánica en **C-67** a) | Sin rebaño en la edad I; ganado vacuno desde la vía misión. Toca balance (poco) |
| H-03 | Palmares | **El Pacto de Cucaú sale gratis.** El texto dice "a cambio de cerrar la puerta a quienes llegan", pero el efecto es solo +25 % de tasa. El acuerdo de 1678 obligaba a devolver a los no nacidos en Palmares y a no recibir a nadie más: ese costo es el drama, y la campaña lo cuenta bien | Lara, *Palmares & Cucaú* (2021); Anderson, *JLAS* 28:3 (1996). Informe 02, n.º 1 | En consulta **C-68** | Al elegir el pacto se apagan la acogida y la liberación (o se reducen a la mitad), y el panel lo dice. La bifurcación de la edad IV pasa a ser una elección con precio, como en la misión. **Toca balance** |
| H-04 | Palmares | **La liberación es captura.** Destruir *cualquier* casa enemiga da "liberados": también las guaraníes, mapuches, etíopes o siamesas, que no eran ingenios | Anderson (1996); Lara (2021a); Thornton, "Palmares revisitado" (2022). Informe 02, n.º 2 | En consulta **C-68** | Liberación solo contra el ingenio neutral y los `invasores` (como `_neutral_loot` con `liberados_por_edad`). Contra los demás pueblos, nada, o nombrarlo con honestidad: "cautivos incorporados". **Toca balance** |
| H-05 | Etiopía | **El gult "rendía sin trabajo".** El gult no es la tierra sino el derecho a cobrar el tributo de los campesinos (*gäbbar*) que la tienen en *rist*. Borraba a quien paga | Crummey, *Land and Society…* (2000); Taddesse Tamrat (1972). Informe 02, n.º 18 | **Corregido** (ficha y descripción) | La mecánica (renta sin aldeanos propios) es fiel y queda. Regla para el futuro: toda renta dice quién la paga |
| H-06 | Tawantinsuyu | **El cumbi como "riqueza" de mercado.** La tela fina no se vendía: se regalaba a curacas y soldados, se quemaba en ofrendas y ataba lealtades | Murra, "Cloth and its Functions in the Inca State" (1962). Informe 01, R10 | Pendiente sin consulta (el panel del pueblo no tiene campo para esto) | La mecánica queda. Sumar a `data/civs/*.json` un campo de historia para el panel del pueblo (lo piden también H-08, H-34 y H-42) y escribir ahí la línea |
| H-07 | Ayutthaya | **"Tributo del rey"** confunde con el tributo entre reinos (el junco a China, el pago a Pegu). Lo que el monte paga es el *suai*, en productos y en lugar de corvée, que el Phra Khlang vende con monopolio | Akin Rabibhadana (1969); Baker y Pasuk, *A History of Ayutthaya* (2017). Informe 03, n.º 13 | Descripciones **corregidas**; el nombre del recurso, en consulta **C-72** | Recurso "Suai (pago al rey)". Opcional: que la caza del sambar sume al suai, porque los cueros de ciervo eran un gran negocio con Japón (Breazeale, 1999; informe 03, n.º 25). Lo opcional toca balance y está pendiente sin consulta |
| H-08 | Ayutthaya | **La sociedad *sakdina* no se ve.** No aparecen el *phrai luang* y el *phrai som*, los esclavos por deuda (*that*) ni las mujeres que llevaban el arroz y el mercado mientras los hombres hacían la corvée | Akin (1969); Reid, *Age of Commerce* I (1988); La Loubère (1691). Informe 03, n.º 14 | Pendiente sin consulta | Corto plazo: dos líneas en el panel y mujeres visibles entre los *phrai* de la granja y el mercado (arte). A futuro, la mecánica M8 de la investigación (*luang* y *som*), que toca balance |
| H-09 | Ayutthaya | **Arroz de riego por canal.** El arroz de Ayutthaya era de crecida natural, y los *khlong* de la época eran caminos de agua, no riego. Además el khlong se dibuja como un charco ovalado | Molle y Keawkulaya (1998); Baker y Pasuk (2017). Informe 03, n.º 15 | Textos **corregidos**; khlong recto: pendiente técnico | La mecánica (+35 % junto al agua) sirve. El khlong recto, como camino de agua, al rehacer el agua de los mapas: cambiar `largo` y `ancho` cambia las casillas de agua, así que **toca balance** |
| H-10 | Etiopía, Birmania, Palmares | **Rebaños que no son la economía del lugar.** Etiopía cría cabras, pero lo que define su agricultura es el buey de arado. En la Zona Seca birmana araba el cebú, no el búfalo del delta. El cerdo de Palmares no tiene fuente; las gallinas sí aparecen en Blaer | Crummey (2000); Lieberman, *Strange Parallels* I (2003); Blaer y Reijmbach (1645). Informe 02, n.º 32 y 35; informe 03, n.º 26 | En consulta **C-72** | Buey o cebú para Etiopía y Birmania; gallinas (o el cerdo con fuente) para Palmares. Es solo vista y nombre de la unidad |

## 1.2 Anacronismos

| # | Pueblo | Qué está mal | Fuente | Estado | Propuesta de diseño |
|---|---|---|---|---|---|
| H-11 | Tawantinsuyu | **Oro en todos los edificios y en la tropa de la edad IV.** El oro era del Qorikancha, de los palacios y de la vajilla del Inka, nunca de las kanchas ni de las qollqas. Y la edad IV es Vilcabamba (1537–1572), cuando el oro del Cusco ya se había fundido para el rescate de Cajamarca (1533): es la imagen inversa a la de la época | Bauer, Fonseca y Aráoz, *Vilcabamba and the Archaeology of Inca Resistance* (2015). Informe 01, A1 | **Corregido** (sin oro en la IV); pendiente técnico el oro solo en el centro y los hitos de la III | Una clave de `arte_edades` para poner oro solo en el centro y los hitos |
| H-12 | Tawantinsuyu | **Edad IV "Inkarri".** El mito se documenta en el siglo XX (Arguedas, Puquio, 1956); como nombre de época es anacrónico. Además, para muchos quechuas es una esperanza viva, no un guiño | Arguedas (1956); Flores Galindo, *Buscando un inca* (1986). Informe 01, A2 | En consulta **C-39** y **C-70** | *Willkapampa* para la edad, y el hito militar pasa a llamarse *Espíritu Pampa* para que no choquen. Preguntar a quechuahablantes del Cusco y Apurímac |
| H-13 | Tawantinsuyu | **El Qorikancha como hito de la edad IV.** Lo reconstruyó Pachakutiq hacia 1438. Con el muro curvo y el oro ya modelados, el anacronismo se nota más: lo más reconocible de Pachakutiq queda junto a Vilcabamba | Betanzos (1551); Bauer, *Ancient Cuzco* (2004). Informe 01, A3; historia, rondas 1 y 3 | **Aplicada la b) de C-40** (proceso/51): Qorikancha en la III y aqllawasi en la IV, con los números ajustados; C-70 sigue abierta | Pasarlo a la edad II o III (**toca balance**). Si no se quiere rebalancear, renombrar la opción de la IV: "Wak'akuna de Vilcabamba" o "Punchao" (la imagen del sol que Manco llevó a Vilcabamba) |
| H-14 | Tawantinsuyu | **La edad IV no parece Vilcabamba.** Sin oro (H-11) queda una edad III más alta. Vilcabamba era pirca más tosca, techos empinados de selva alta y teja española en algunos techos (Espíritu Pampa) | Bauer et al. (2015). Informe 01, A1 | Pendiente técnico | Clave de techo de teja en `arte_edades`; casco de hierro y lanza larga en la tropa de la IV (piezas nuevas). Solo vista |
| H-15 | Birmania | ***Bayingyi* y *kathe* en 1593.** Los *bayingyi* descienden de los portugueses tomados en Syriam en 1613; la caballería manipurí (*kathe*) es konbaung, posterior a 1758. En Nong Sarai están en el lado birmano. El jugador de historia lo marcó en las rondas 2 y 3 | Lieberman (2003); Charney, *Southeast Asian Warfare* (2004). Informe 03, n.º 3 y 4 | En consulta **C-71** | "Tiradores portugueses a sueldo" y "Jinete shan" hasta la edad III; *bayingyi* y *kathe* en la IV. Pide **nombres por edad** (o alias de misión) en el motor de civs: es el mismo mecanismo que H-16 |
| H-16 | Adal | **La Torre del Jugol** (obra de Nur ibn Mujahid, 1550–1567) aparece en misiones de 1445, 1531 y 1543 | Pankhurst, *The Ethiopian Borderlands* (1997). Informe 02, n.º 12 | Pendiente sin consulta (quedó fuera de C-67 a C-74) | Torre de piedra genérica de Harar o Zeila hasta la III y el Jugol desde la IV, con los nombres por edad de H-15 |
| H-17 | Palmares | **Tres anillos de la cerca real en la edad III** (1660–1678). Las tres cercas las describe Velho en la Barriga en 1692; para el Macaco de 1677 las fuentes hablan de una cerca de pau a pique con estrepes | Lara, "O território dos Palmares" (2021a). Informe 02, n.º 38 | Nota **corregida**; el modelo, pendiente sin consulta | El tercer anillo llega recién en la edad IV. Solo vista |
| H-18 | Ayutthaya | **"Ekkarat" y "Mueang Tha".** *Ekkarat* (independencia) es la palabra del nacionalismo del siglo XX sobre Naresuan. *Mueang Tha* no está documentado como nombre de época | Sunait Chutintaranond, *JSS* 80:1 (1992); Baker y Pasuk (2017). Informe 03, n.º 10 y 11 | En consulta **C-70** | Explicar *Ekkarat* en el panel. *Mueang Tha* → *Krung Thonburi*, o "Puerto real" hasta tener fuente. Revisar con un hablante (C-30) |
| H-19 | Mapuches | **Los cuatro *butalmapu* en 1641.** Se consolidan en la segunda mitad del siglo XVII y en el XVIII | Boccara, *Los vencedores* (2007); Zavala (2008). Informe 01, A6 | **Corregido** (misión 4) | *Butalmapu* queda como edad IV, que puede apuntar al siglo XVIII |

## 1.3 Lo sagrado usado como mecánica

La investigación del propio juego pedía "no convertir la religión en *buff* místico" (`docs/investigacion/etiopia.md`). Regla que sale de esta sección: **un objeto o un lugar de culto vivo no da bonos de combate, no se construye como pieza del jugador y no suena en las órdenes de la tropa.**

| # | Pueblo | Qué está mal | Fuente | Estado | Propuesta de diseño |
|---|---|---|---|---|---|
| H-20 | Etiopía | **Lalibela es un hito que se construye** en la edad II y da +25 % de vida a los edificios. Es zagwe (siglos XII–XIII), anterior a la época del juego, y un lugar de peregrinación vivo, Patrimonio de la Humanidad. La investigación pedía que las iglesias excavadas fueran sitios del mapa | Phillipson, *Ancient Churches of Ethiopia* (2009); Taddesse Tamrat (1972); `docs/investigacion/etiopia.md` (M11, H43). Informe 02, n.º 9 | En consulta **C-69** | Lalibela pasa a **sitio sagrado neutral del mapa** (no se construye ni se destruye). El monasterio de la edad II se ve como **Debre Damo** (amba con cuerda de cuero, muros con "cabezas de mono"), que ya aparece en la misión etiopia-2. Malla nueva. **Toca balance** si cambia el efecto |
| H-21 | Etiopía | **La iglesia da +5 % de vida a las tropas.** El texto hablaba del tabot, lo más sagrado de una iglesia ortodoxa | `docs/investigacion/etiopia.md` §254; Taddesse Tamrat (1972). Informe 02, n.º 19 | Palabra "tabot" **sacada**; el efecto, en consulta **C-69** | Mantener la tasa +10 % y cambiar la vida de las tropas por algo económico o institucional: tierras de la iglesia, mercado junto a la iglesia, monjes y escritura (abastecimiento o población). Nunca trofeo ni blanco preferido. **Toca balance** |
| H-22 | Mapuches | **El kultrun sonaba en cada orden y en la fanfarria de guerra.** Es el tambor de la machi | Historia, ronda 3; informe 01, §4 | Opción prudente **aplicada** (b de **C-53**): kakelkultrun, kull-kull y trutruka | Preguntar a una organización mapuche antes de volverlo, junto con la pifilka (**C-08**, sin respuesta): las crónicas la ponen en la guerra (Ovalle, 1646; Rosales, c. 1674, pasajes a verificar) |
| H-23 | Guaraníes | **Mbaraka y takuapu** (instrumentos del *opy*) en la alarma y las órdenes, y la **mbaraka del karai** en el hito | Historia, ronda 3; informe 01, §4 | Tropa **cambiada** a mimby y angu'apu (**C-56**); el hito **la conserva**: C-60 a («es la casa del karai, donde corresponde»; proceso/51). Choca con lo que propone C-74 (sacarla hasta la consulta mbyá), que sigue sin contestar | Sacar la mbaraka del modelo hasta la consulta mbyá. Preguntar también por el uso de *opy*, *karai* y *yvyra'i* en un juego de guerra |
| H-24 | Etiopía | **Begena** (arpa de la oración y la Cuaresma) en la música de paz, y **kebero** (tambor litúrgico) en la fanfarria, la alarma y el entrenado | Ashenafi Kebede (1971). Historia, ronda 3; informe 02, n.º 37 | Begena **reemplazada** por krar (b de **C-54**); el kebero, en consulta **C-58** y **C-73** | **Nagarit** (el timbal real de guerra, profano) para la fanfarria y la alarma; el kebero, en ningún lado hasta consultar a la Iglesia Tewahedo |
| H-25 | Ayutthaya | ***Tra Nimit*** (*Phleng Maha Nimit*): casi seguro repertorio ceremonial *naphat*, asociado al *wai khru*, y en una grabación de banda naval de 1934. Hoy es la **única** pista propia de Ayutthaya, así que suena más | Morton, *The Traditional Music of Thailand* (1976). Informe 03, n.º 1 | En consulta **C-59** y **C-73** | Sacarla. Música propia de *piphat* que no imite ninguna pieza *naphat*, o encargada a músicos de *piphat* |
| H-26 | Ayutthaya | **El wat**: imagen del Buda en el modelo, destrucción del wat, "méritos y recolección" como bono | Informe 03, §4 | En consulta **C-74** | Ninguna imagen reconocible del Buda en modelos ni láminas hasta consultar (nunca a la altura del piso, nunca cortada). Preguntar si el wat puede ser destructible (en 1767 se quemaron wats) y si el bono trivializa el *bun* |
| H-27 | Mapuches | **El rewe en cuatro de seis hitos**, con la *toki kura* en el poste. Además, los nombres inventan cargos ("toqui de caballería", "toqui del monte"): el toqui se elegía para una guerra, no por rama | Bengoa (1985); Boccara (2007); Dillehay (2007). Historia, ronda 3; informe 01, R4 | Arte **corregido** (4i: el rewe solo en el nguillatuwe); los nombres, en consulta **C-72** | "Malón del toqui", "Nguillatuwe del rewe", "Corral de la remonta" (o *Kawellu*) y "Pewenal". Preguntar si el nguillatuwe puede ser un hito jugable |
| H-28 | Palmares | **Ijexá** (repertorio del candomblé) y toques de capoeira (siglos XIX y XX) en la paz | Kubik (1979). Informe 02, n.º 10 | **Sacados** (b de **C-57**); hoy Palmares no tiene música de paz propia | Ver H-42 |

## 1.4 Silencios

Lo que el juego calla o suaviza. El informe de África lo dice así: "lo más serio no es una fecha, es lo que el juego calla".

| # | Pueblo | Qué está mal | Fuente | Estado | Propuesta de diseño |
|---|---|---|---|---|---|
| H-29 | Etiopía | **Los oromo no aparecían nunca**, aunque entre 1550 y 1700 rehacen el reino (Susenyos se crió entre ellos) | Mohammed Hassen, *The Oromo and the Christian Kingdom of Ethiopia* (2015); Merid Wolde Aregay (1971). Informe 02, n.º 15 | Texto **corregido** (etiopia-4: gada, aliados y rivales, sin "galla"); la facción, en **C-74** (a futuro) | Los oromo como facción de IA, con la lógica del *gada* (mando que rota cada ocho años). Consultar a académicos del gada |
| H-30 | Etiopía | **Beta israel como "albañiles" contentos**, sin las guerras que los despojaron; **Debre Berhan como milagro**, sin la lapidación de los estefanitas | Kaplan (1992); Quirin (1992); Taddesse Tamrat (1972). Informe 02, n.º 16 y 17 | **Corregido** | Regla: cuando un texto muestra a un grupo en un oficio o a un rey en un milagro, decir de dónde viene |
| H-31 | Adal | **Adal existe solo como enemigo**: sin misión propia, sin hito (ni mezquita ni Harar) y con nombres genéricos (Aldeano, Arquero, Lancero, Cuartel) | *Futūḥ al-Ḥabaša*, trad. Stenhouse y Pankhurst (2003). Informe 02, n.º 20; historia, ronda 2 | En consulta **C-74** (a futuro); los nombres, pendiente sin consulta | Una misión desde Adal (narrador: un cronista de la corte del imán) o, al menos, que Bati del Wambara hable en etiopia-3. Hitos: la mezquita de Harar y el mercado de Zeila. Nombres de tropa del *Futūḥ*. Consultar a la comunidad hararí |
| H-32 | Birmania | **"Hanthawaddy" como edad III birmana.** Es el reino mon de Pegu: usarlo borra a los mon, actores de primer orden en estas guerras | Lieberman, *Burmese Administrative Cycles* (1984); Pamaree Surakiat (2006). Informe 03, n.º 5; historia, rondas 2 y 3 | En consulta **C-70** | "Toungoo" para la III, en paralelo con "Konbaung" para la IV. Consultar a un historiador birmano o mon |
| H-33 | Ayutthaya | **No hay barrio chino**, la comunidad extranjera más grande: defendió la muralla en 1767 y sostuvo a Taksin, como cuenta la propia campaña. Faltan también persas y makasares | Sarasin Viraphol, *Tribute and Profit* (1977); Breazeale (1999). Informe 03, n.º 12 | En consulta **C-71** | Barrio chino como tercer barrio extranjero (compañía de defensa de muralla o comercio de juncos). **Toca balance** |
| H-34 | Ayutthaya | **Solo víctima de Birmania.** No figuran Angkor (1431), Lan Na ni Lovek (1594): una potencia que también conquistó | Wyatt (2003); Baker y Pasuk (2017); Sunait (1992). Informe 03, n.º 22 | Rivales en **C-74** (a futuro); la línea del panel, pendiente sin consulta | Una línea en el panel (campo de H-06). A futuro, rivales Lan Na, Lan Xang o Camboya en escaramuza |
| H-35 | Palmares | **"La libertad que llega sola y se esconde"**: le quitaba agencia a gente que huía arriesgando la vida y que armó una formación política con rey, consejo, comercio y guerra | Lara (2021); Reis y Gomes, *Liberdade por um fio* (1996). Informe 01, R2; informe 02, n.º 21 | **Corregido** ("La libertad que se toma y se defiende en la sierra"); **C-20** sigue sin respuesta formal | Regla: ningún texto de Palmares dice "esconderse" como esencia |
| H-36 | Europeos | **Todos son "Invasores" con edades *Hueste… Virreinato*.** En Brasil no hubo virreinato efectivo en el siglo XVII, y la tropa de Jorge Velho era sobre todo indígena y mameluca, pero juega como europea | Monteiro, *Negros da terra* (1994). Informe 01, R8; historia, rondas 2 y 3 | En consulta **C-44** y **C-72** | Edades y nombres por potencia (Castilla, Portugal, Países Bajos, Francia), aunque los números sean los mismos. La tropa de Velho como facción "paulista" con base en los tupíes de las aldeias |

## 1.5 Nombres

| # | Pueblo | Qué está mal | Fuente | Estado | Propuesta de diseño |
|---|---|---|---|---|---|
| H-37 | Guaraníes | **Edades *Tekoha → Amundá → Mbororé → Tava*.** *Amundá* no aparece en ningún documento, y terminar en *Tava* se lee como si la meta fuera reducirse. Además, los hitos de la III y la IV son los dos una iglesia. La opción a) de C-41, *tovaja*, quiere decir "cuñado": el instrumento del pacto con los españoles | Susnik (1979–80); Meliá (1986). Informe 01, R1; historia, rondas 1 y 3 | **Aplicada la a) de C-41** (proceso/51): *Tekoha → Tovaja → Mbororé → Ñande retã*; *tovaja* queda [verificar] con un hablante, y C-70 sigue abierta | *Tekoha → Guára → Mbororé → Ñande retã* (*guára*: el conjunto de tekoha aliados), a verificar con un hablante y en Meliá. Que la imagen fuerte de la IV sea *Ñande retã* (la trinchera) y la tava, cabildo y plaza, no fachada. Explicar *tekoha* en el panel (hoy es palabra de lucha por la tierra) |
| H-38 | Palmares | **Edad IV "Cucaú o Quilombo"** se lee como opción de menú. Y la opción por defecto de C-42 ("Macaco, la cerca real de la Serra da Barriga") pone el Macaco en la Barriga, contra Lara y contra la propia campaña, y repite el nombre de un hito | Lara (2021a), n. 78. Informe 02, n.º 7 | **Aplicada la b) de C-42** (proceso/51): la IV se llama *1678*; C-70 sigue abierta | **No aplicar la a) de C-42.** La b) "1678" (el año del papel, donde se bifurca la partida) o la d), dejarlo y explicar la bifurcación |
| H-39 | Varios | **Nombres armados o de otra lengua:** *Baqueano* (criollo, no guaraní); *Ruka de guerra* (no hay registro de casas de guerra mapuches); *Kamayuq wasi* ("especialista", no dice qué guarda); *Tukul* (quizás del árabe del Sudán); *Sanam ying thanu* y *Khlang din* (gramaticales, pero no de época) | Informe 01, R5, R6 y S6; informe 02, n.º 29; informe 03, n.º 27 | En consulta **C-72** (Ruka, Kamayuq, Tukul) y **C-30** (los tailandeses); *Baqueano*, pendiente sin consulta | "Junta de guerra", *Qhuya wasi*, *Gojjo bet*, "Campo de tiro" y "Almacén de arcilla" hasta que un hablante confirme; "Explorador" o un término guaraní verificado. La regla de C-30 b) (castellano hasta tener fuente) evitaría que vuelva a pasar |
| H-40 | Rivales andinos, tupíes, Adal | **Edades por defecto** ("Asentamiento, Consolidación…") y tropas genéricas, al lado de pueblos con todo en su lengua | Historia, rondas 2 y 3 | Pendiente sin consulta | Donde no se sabe la lengua (chankas), castellano descriptivo y propio, no las edades genéricas. Para Adal, los nombres del *Futūḥ* (H-31) |
| H-41 | Varios | **Lo que el jugador necesita saber para no leer mal:** *Gana* (no "Ganga") Zumba, "Angola Janga" como nombre que la tradición atribuye a los palmaristas, "Fama" como noticia y no como prestigio, *Chewa* como soldado de los regimientos reales | Informe 02, n.º 28, 34 y 36, y "Lo que está bien" | Pendiente sin consulta (el panel no tiene campo) | Glosario en el panel del pueblo (el mismo campo de H-06) |

Quedan además, de menor peso: la clave interna `yvy_marane` (sin la ỹ dice "tierra con mal"; renombrarla toca datos y código) y *awqa kamayuq*, ya corregido con `[verificar]`.

## 1.6 Sonido y música

| # | Pueblo | Qué está mal | Fuente | Estado | Propuesta de diseño |
|---|---|---|---|---|---|
| H-42 | Palmares | **Sin música de paz propia** desde que salieron el berimbau de capoeira y el ijexá (H-28). Palmares era mayoritariamente centroafricano (kimbundu y kikongo) | Kubik (1979); Heywood y Thornton (2007); Cavazzi (1687). Informe 02, n.º 10 | En consulta **C-73** | Música sintetizada de ngoma, marimba y kisanji, con el arco *hungu* tocado como arco angoleño, sin toques de capoeira. La tropa ya está así desde 4h |
| H-43 | Ayutthaya | **"Kingdom of a million elephants"** (el nombre de Lan Xang, reino lao) y **"Bamboo Blitz"** ("tambores tribales") como música siamesa | Wyatt (2003). Informe 03, n.º 2 | **Sacadas** de `CIV_MUSIC` | Con H-25, Ayutthaya se queda sin música propia: hace falta la de *piphat* de H-25 |
| H-44 | Ayutthaya | **Alarma con *piphat*,** que es música de teatro y de ceremonia | Morton (1976); La Loubère (1691). Informe 03, n.º 24 | En consulta **C-73** | Alarma con *klong chana*, *pi chawa* y *sang*; el *piphat*, solo en la fanfarria de edad |
| H-45 | Tawantinsuyu | **Charango y arpa** (coloniales, siglos XVII–XVIII) en la música de paz de las edades I a III | Stevenson (1968, a verificar). Informe 01, A5 | Pendiente técnico (no hay música por edad) | Música por edad en `audio.gd`: quena, siku, pinkillu y wankar en la I a III; charango solo en la IV o en la misión de 1780; pututu en la alarma |
| H-46 | Todos | **El menú suena con la flauta de pan andina** para todos los pueblos | Historia, rondas 1, 2 y 3 | Pendiente sin consulta | Música de menú del pueblo elegido, o una neutral que no sea de ningún pueblo |
| H-47 | Todos | **Ninguna voz.** "En AoE4 la mitad de la identidad está en la respuesta del aldeano." Es el deseo n.º 1 o 2 del jugador de historia en las tres rondas | Historia, rondas 1 a 3; informe 03, §4 | Pendiente (necesita hablantes y presupuesto) | Diez frases por pueblo grabadas por hablantes (quechua, mapudungun, guaraní, amhárico con ge'ez para el clero, portugués con kimbundu, tailandés central, birmano). **No sintetizarlas** |

Detalle: los nombres de los cuatro modos *qenet* etíopes se sistematizan en el siglo XX; alcanza con aclararlo en los créditos (informe 02, n.º 14).

## 1.7 Arte

| # | Pueblo | Qué está mal | Fuente | Estado | Propuesta de diseño |
|---|---|---|---|---|---|
| H-48 | Birmania | **Usa la arquitectura siamesa** (`estilo.forma: "ayutthaya"`): equivale a decir que el Sudeste Asiático es todo igual | Thant Myint-U (2006) como introducción; hace falta un especialista. Informe 03, n.º 6 | Paleta de teca **aplicada**; la forma, en consulta **C-71** | Forma `birmano` en `civ_meshes.gd`: casa de teca sobre pilotes, monasterio de madera (*kyaung*), techo *pyatthat* en la III o la IV, *zedi* blanca y dorada como remate. Mallas nuevas |
| H-49 | Etiopía | **Monasterio con forma de Lalibela** (H-20), **casco de bronce** en la edad III (el noble se distinguía por el escudo con plata y la *shamma*) y **Fasil Ghebbi blanco** (es basalto y toba pardos o grises) | Informe 02, n.º 9, 30 y 31 | Debre Damo en **C-69**; casco y color, pendiente técnico (solo `arte_edades`, fácil) | Escudo con borde de metal en lugar del casco; muro pardo grisáceo en la IV |
| H-50 | Todos | **Las tropas son maquetas** que solo cambian de tela y casco por edad; los rivales de campaña no tienen hitos; no hay maravilla por pueblo | Historia, rondas 1 a 3 | Pendiente (créditos de Meshy; maravilla en la etapa 26) | Primero las unidades únicas (chewa, weichafe, kona, leva inca, compañía japonesa) y un soldado por facción rival. Maravillas con raíz: Sacsayhuamán u Ollantaytambo, un gran *trawün*, Fasil Ghebbi, la cerca de la Barriga, Wat Phra Si Sanphet |
| H-51 | Varios | **Paisaje que no cuenta el lugar** (rondas 1 y 2): altiplano verde con flores, selva que arranca en pradera, sierra de Palmares con coníferas. Y tres pueblos andinos rivales con la misma forma y otro color | Historia, rondas 1 y 2 | Pendiente sin confirmar (no figura como integrado después de la ronda 2) | Puna en el altiplano, monte cerrado guaraní, palmeras y mata atlántica en Palmares. La *tola* bajo el centro caranqui y un estandarte chanka |

## 1.8 Consultas a comunidades antes de publicar

Están todas en **C-74** (sin respuesta). Ninguna es un trámite: los historiadores piden ofrecer crédito y, si se puede, pago por la revisión.

| Con quién | Qué |
|---|---|
| Iglesia ortodoxa Tewahedo | Lalibela, iglesia, tabot, kebero y begena (H-20, H-21, H-24) |
| Comunidades hararí, oromo y beta israel | Adal, la facción oromo y la línea de Gondar (H-29 a H-31) |
| Organizaciones mapuches | Kultrun, pifilka, kakelkultrun, toki kura, nguillatuwe, nombres y grafía (H-22, H-27) |
| Mbyá guaraní y paĩ-tavyterã | Mbaraka, opy y karai, *tekoha*, *guára*, *Ñande retã* (H-23, H-37) |
| Quechuahablantes del Cusco y Apurímac | *Inkarri* o *Willkapampa*, *awqa kamayuq*, *Qhuya wasi*; la identidad chanka actual (H-12, H-39) |
| CONAQ, quilombolas de Alagoas, Parque Memorial | Liberación, Cucaú, "Fama", Dandara, el 20 de noviembre (H-03, H-04, H-35, H-38) |
| Mestres de capoeira angola (Mestre Tucano Preto, cuya grabación estaba en el juego) | Las pistas de berimbau (H-28) |
| *Khru* de música tailandesa; comunidad theravada | *Tra Nimit*, el wat y las imágenes del Buda (H-25, H-26) |
| Hablantes de kimbundu, amhárico y ge'ez, tailandés y birmano | Grafías y nombres (H-39, H-41) |

---

# Parte 2 · Sugerencias de juego del veterano que siguen sin hacerse

**Sobre "cómo lo hace AoE4":** sale de los informes del veterano, que juega AoE4 en rankeada pero escribe de memoria; lo que él mismo marcó `[verificar]` sigue así.

**Lo que ya se integró** (no figura abajo): comida temprana con animales, caza y arreo, carnear en cadena y de a una llama; hitos de 190/220/250 s con aura y radio a la vista; costo real del hito; sitios a 10 minutos con cuenta y apagables; dos armaduras; mantener posición, patrullar y formaciones; ociosos, cola global, M, T, Tab, B, N, P; ocho marcadores; teclas configurables con perfil AoE4; producción repartida; H que recorre los centros; panel de varias con retratos; grupos exclusivos y grupo 0; barras finas; panel de unidad con valores reales; IA experta de 100 aldeanos; IA que disputa sitios; elección de blancos; micro C2; escala paso 1.

## 2.1 Economía

| # | Ronda | Qué pide | Cómo lo hace AoE4 | Estado | Balance |
|---|---|---|---|---|---|
| J-01 | 3 | **Avisar en la opción de recursos altos** que el hito se puede colocar en el segundo 1 (edad II a las 2:35) | Con recursos altos también se sube enseguida; el lobby lo deja claro | Pendiente sin consulta; los valores, en **C-45** | No (texto del menú) |
| J-02 | Etapa 26 | **Mejoras económicas propias por civ.** Hoy hay 18 mejoras compartidas y ninguna propia | Cada civ tiene tecnologías únicas, varias económicas, ligadas a su landmark o a su edificio | Pendiente: el veterano está dando las cantidades (etapa 26, paso 1) | Sí |

La economía es lo que el veterano más elogia desde la ronda 2 ("los primeros cinco minutos ahora tienen cosas que hacer"); no queda otro pedido abierto.

## 2.2 Combate y micro

| # | Ronda | Qué pide | Cómo lo hace AoE4 | Estado | Balance |
|---|---|---|---|---|---|
| J-03 | 1, 2, 3 (resuelto en la 4) | **Que la mezcla de línea y distancia pague** | Muro de lanceros u hombres de armas adelante, tiradores atrás: la base del juego | **Aplicada por defecto** la a) de **C-64** (C2: guerrero a 1350, línea +6 contra el choque), torneo 22. La mezcla gana 3 de 3 en la ronda 6. Falta que el autor confirme | Ya medido |
| J-04 | 1, 2, 3; matizado en la 4 | **Una unidad que pueda kitear al choque**: hostigador montado o jabalinero rápido, uno por pueblo donde tenga sentido | Arqueros a caballo y jinetes de jabalina en varias civs | En consulta **C-64** c). Con C2, escalonar ya paga contra el guerrero común; el weichafe sigue sin kitearse, y está bien (identidad mapuche) | Sí, y pide modelo, edificio e IA |
| J-05 | 1 | **Atacar el suelo** | El mangonel y el trabuquete atacan un punto del suelo | Pendiente sin consulta | Poco (solo asedio) |
| J-06 | 1, 2, 3, 6 | **Leer la batalla:** con Alt, el ícono de la función sobre las unidades (hoy solo sobre los techos); siluetas por función. Los etíopes siguen siendo blancos con disco rojo y en el montón no se sabe quién es lancero | Siluetas muy distintas por tipo y colores de jugador fuertes | Pendiente (plan 6a) | No |
| J-07 | 6 | **El consejo de la pelea perdida y la hoja de atajos dicen que "A y clic ataca lo primero que ve"**: desde la elección de blancos ataca primero a los soldados. "Enseña a no usar la orden que ahora funciona bien" | — | Pendiente (plan 6a): `consejos.gd`, línea 529; `hoja_atajos.gd`, línea 82 | No |
| J-08 | 6 | **Z X C V son formaciones en la grilla militar e hitos en la del aldeano.** Con los dos elegidos, ¿cuál gana? | — | Pendiente de revisar (plan 6a) | No |

## 2.3 Unidades y mejoras

| # | Ronda | Qué pide | Cómo lo hace AoE4 | Estado | Balance |
|---|---|---|---|---|---|
| J-09 | **1, 2, 3, 4, 5, 6** | **Mejoras por unidad en su edificio** (veterano y élite; por ejemplo, la del hondero en su campo de tiro). Es el único pedido que aparece **en las seis rondas** | Cada línea tiene su veterano y su élite en el edificio que la entrena; mejorar a los arqueros o a los hombres de armas es una decisión de composición | Pendiente: etapa 26 (las cantidades del veterano y el diseño del juego tardío) | Sí |
| J-10 | 1 (dos armaduras hechas en la 2) | **Mejoras de herrería separadas** por cuerpo a cuerpo y distancia. Hoy armas, escudos, marcha y adiestramiento valen para todos los militares | Herrería con líneas separadas de ataque y de armadura | Pendiente sin consulta | Sí |
| J-11 | 1 | **Sacar el bono automático de ataque por edad** (+10/20/35 %, `edades.json → bono_ataque`): hace que no haya nada que decidir | El ataque no sube solo con la edad: sube con lo que investigás | Pendiente sin consulta | Sí, mucho: va junto con J-09 y J-10 |
| J-12 | Etapa 26 | **Cantidad de unidades, mejoras y opciones por civ** | Cada civ tiene unas pocas unidades únicas, varias mejoras propias y dos landmarks por edad | Pendiente: etapa 26, paso 1 | Sí |

## 2.4 Edades y final de partida

| # | Ronda | Qué pide | Cómo lo hace AoE4 | Estado | Balance |
|---|---|---|---|---|---|
| J-13 | 3, 4, 5, 6 | **Que la IA pegue al hito en obra con lo que tenga**, aunque sean 4 soldados en la edad I, y lo defienda cuando es suyo. "La ventana existe, falta quien la use" | El landmark en obra es el blanco más rico de la edad I, y saber que te lo van a pegar es lo que tensa la apertura | **Parcial** (frente G): la normal, la difícil y la experta atacan y defienden; en la ronda 6, enemigos cerca del hito 0 a 53 s según el par y ningún hito perdido; contra el jugador, nunca | Sí (el torneo 21 movió a mapuches, guaraníes y Ayutthaya) |
| J-14 | Etapa 26 | **La edad IV no trae unidades nuevas** y llega en cerca del 15 % de las partidas, que se deciden antes | La imperial trae pólvora, asedio pesado, las mejoras élite y la maravilla | Pendiente: etapa 26, paso 3 (si rompe el balance, se pausa) | Sí |
| J-15 | Historia 1–3; C-50 | **Maravilla y victoria por maravilla** | Maravilla en la edad IV con cuenta regresiva para ganar | En consulta **C-50** (la opción por defecto la deja para después) | Sí |

## 2.5 IA

| # | Ronda | Qué pide | Cómo lo hace AoE4 | Estado | Balance |
|---|---|---|---|---|---|
| J-16 | 3, 5, 6 | **Experta que suba de edad a tiempo.** Edad II a las 6:07–9:29 y una sola edad III en 6 jugadores a los 20 minutos; contra el veterano, nunca la III en 30 | Un jugador de nivel alto hace el segundo centro y llega a la II a las 5 y a la III cerca del minuto 12 | Pendiente (plan 6b) | No para el torneo, que se mide con la normal (**C-52**), salvo que el cambio toque la normal |
| J-17 | 6 | **Experta que se defienda al expandir:** ejército según el del rival y una torre junto a cada centro nuevo. Con 11 militares al minuto 10 y 4 al 15, un ataque al minuto 12 la dejó de 36 a 20 aldeanos | Quien hace boom levanta una o dos torres junto al segundo centro y tiene la campana a mano | Pendiente (plan 6b) | Igual que J-16 |
| J-18 | 3, 4 | **Que la experta le gane a la difícil** | — | En consulta **C-51** (hoy gana 69 %) | Igual que J-16 |

## 2.6 Mapas y modos

El veterano no pidió cambios de mapas. Lo de modos:

| # | Ronda | Qué pide | Cómo lo hace AoE4 | Estado | Balance |
|---|---|---|---|---|---|
| J-19 | 2 (síntesis) | **Opciones del lobby que faltan:** población máxima, revelar mapa, edad inicial y maravilla | El lobby las tiene todas | En consulta **C-50** | No (son opciones); la maravilla sí (J-15) |
| J-20 | — | Relacionado: **la captura del sitio se vacía de a poco** sin nadie | La captura baja sola | En consulta **C-62** | Sí |

## 2.7 Interfaz y calidad de vida

| # | Ronda | Qué pide | Cómo lo hace AoE4 | Estado | Balance |
|---|---|---|---|---|---|
| J-21 | 1–3 (con `--shot`), 4, 5, 6 | **Que el juego no se caiga al cerrar** (código 134, `corrupted size vs. prev_size`). "Si le pasa a un jugador al salir, parece un juego roto" | — | Pendiente: sin causa encontrada, dentro del motor | No |
| J-22 | 6 | **El chequeo "cuenta grande de sitios del rival" del autotest** falla de a ratos con la máquina cargada | — | Pendiente (plan 6a) | No |

J-06, J-07 y J-08 (arriba, en combate) también son de interfaz.

## 2.8 Escala y animación

| # | Ronda | Qué pide | Cómo lo hace AoE4 | Estado | Balance |
|---|---|---|---|---|---|
| J-23 | 4, 5, 6 | **Velocidad de las unidades.** Con la persona a 0,75 casillas, el aldeano anda 1,5 personas por segundo, un trote. Propuesta: `velocidad_pct` de 90 a 72 | ≈ 0,8 personas por segundo [verificar] | **Respondida (C-65 c):** se retoma con las animaciones. El veterano lo acepta: "con buenas animaciones de paso, se nota menos" | Sí, el cambio más grande: viajes, economía, llegada de ataques, micro |
| J-24 | 4, 5, 6 | **Centro de 5×5** (el lof, 4×4); los hitos ya no tanto. Hoy el centro mide 4,2 personas de ancho y se pierde al lado de cuatro chacras | Un centro ocupa lo que 6 a 8 aldeanos en fila | En consulta **C-66** | Sí: colocación, IA, generador de mapas (quizás 136 en vez de 128), caminos, las 25 misiones |
| J-25 | Deuda (`docs/09`) | **Animación con esqueleto** para los modelos generados. Es la condición de J-23 | Animaciones de paso, trabajo y golpe por unidad | Pendiente | No |
| J-26 | 5 | **Soldados de maqueta un poco altos** (1,3 aldeanos; el lancero, 2,0 con la lanza) | 1,0–1,1 | Pendiente sin consulta (solo vista) | No |
| J-27 | 4 | **Verificar los números de AoE4** con dos capturas a 1080p (un centro con aldeanos; un landmark de la II junto a una casa y un bosque) | — | Pendiente | No |

---

# Parte 3 · Prioridad

**Impacto:** cuánto mejora la verdad histórica (V) o la diversión (D). **Costo:** bajo (horas, datos o textos), medio (código o una malla), alto (sistema nuevo, modelos, música o personas de afuera).

| Grupo | Qué junta | Impacto | Costo | ¿Rompe el balance? | Orden |
|---|---|---|---|---|---|
| A · Textos que enseñan mal | J-07 (consejo de "A y clic"), J-08, J-22 | D alto (el jugador aprende al revés) | Bajo | No | **1** |
| B · Leer la batalla | J-06, J-26 | D medio | Bajo–medio | No | **1** |
| C · Responder las consultas de nombres | H-12, H-15 a H-18 (nombres), H-27, H-32, H-36 a H-39: C-39, C-41, C-42, C-44, C-70, C-71 (nombres), C-72 | V alto | Bajo una vez contestadas, salvo los nombres por edad (H-15, H-16), que piden un campo en el motor de civs | No (solo nombres) | **2** |
| D · Panel del pueblo con historia y glosario | H-06, H-08 (texto), H-34, H-41, explicar *Ekkarat* y *tekoha* | V medio | Bajo (un campo en los datos y el panel) | No | **2** |
| E · Sonido con respeto | H-24, H-25, H-42 a H-46 (C-58, C-59, C-73) | V alto (hoy Ayutthaya suena con repertorio ceremonial y Palmares sin música propia) | Medio (síntesis con `tools/audio/`; música por edad) | No | **2** |
| F · Arte barato | H-11 (oro solo en centro e hitos), H-17, H-49 (casco y color) | V medio | Bajo | No | **3** |
| G · Experta | J-16, J-17, J-18 | D alto para quien quiere practicar | Medio | No (se mide con la normal, C-52) | **3** |
| H · Lo sagrado con efecto | H-20, H-21 (C-69) | V alto | Medio (malla de Debre Damo, sitio neutral) | **Sí** (Etiopía) | **4**, en la pasada de balance |
| I · Economías que dicen otra cosa | H-01, H-02 (C-67), H-03, H-04 (C-68), H-33 (C-71), H-07 opcional | V alto: es lo que más contradice la historia **en la mecánica** | Medio | **Sí** (guaraníes, que ya están arriba en casi todos los torneos; Palmares; Ayutthaya, que está abajo) | **4**, en la pasada de balance |
| J · Progreso y final de partida | J-02, J-09 a J-12, J-14, J-15 | D alto: J-09 es el pedido más repetido (seis rondas de seis) | Alto | **Sí**, mucho | **4**, con la etapa 26; si rompe el balance, se pausa |
| K · IA y el hito en obra | J-13 | D medio | Medio | Sí | **4**, en la pasada de balance |
| L · Kitear al choque | J-04 | D medio (con C2 ya se puede escalonar) | Alto (modelo, edificio, IA) | Sí | **5** |
| M · Arte grande | H-14, H-48, H-50, H-51, J-25 | V y D altos | Alto (Meshy, mallas, animación) | No | **5**, con los créditos del mes |
| N · Escala en la simulación | J-23 (con J-25), J-24 (C-66) | D alto ("lo que más rompe la sensación de realidad") | Alto | **Sí**, todo | **6**: la velocidad, cuando haya animaciones; el centro, cuando el autor conteste |
| O · Facciones y misiones nuevas | H-29 (oromo), H-31 (Adal), H-34 (Lan Na, Camboya) | V alto | Alto | Sí (civs de IA nuevas) | **6** |
| P · Voces | H-47 | V y D altos | Alto (hablantes, grabación) | No | Antes de publicar |
| Q · Consultas a comunidades | §1.8 (C-74) | V decisivo | Alto (personas, tiempo, pago) | Puede (si piden cambiar mecánicas) | **Antes de publicar**; conviene empezar ya, porque tardan |
| R · Caída al cerrar | J-21 | D alto al publicar | Desconocido (motor) | No | Antes de publicar |

## Orden propuesto

1. **Ya, sin tocar el balance** (A y B): el consejo y la hoja de atajos, Z X C V, el chequeo del autotest, Alt sobre las unidades. Es el plan 6a.
2. **Pedirle al autor que conteste C-39 a C-44 y C-67 a C-74.** Están todas con opción por defecto; la mayoría son nombres y sonido. Con las respuestas, aplicar de un tirón C, D y E, que no mueven el balance. Ojo con C-42: los historiadores piden **no** aplicar su opción por defecto.
3. **La experta** (G, plan 6b) y el arte barato (F), en paralelo.
4. **Una sola pasada de balance** que junte todo lo que mueve números: la etapa 26 (mejoras por unidad, herrería separada, sin el bono por edad, edad IV con contenido), la yerba y el ganado guaraní (C-67), el costo de Cucaú y la liberación (C-68), la iglesia y Lalibela (C-69), el barrio chino (C-71) y la IA que pega al hito en obra. Conviene así porque los guaraníes y Ayutthaya están en los bordes del torneo y varios de estos cambios los tocan; medirlos de a uno pero dentro de la misma etapa evita rebalancear dos veces. Si el conjunto rompe el balance, se hace lo que dice la etapa 26: queda diseñado y se retoma con más contenido.
5. **Arte grande y kitear al choque** (M y L), cuando haya créditos y modelos.
6. **Escala en la simulación** (N): la velocidad con las animaciones (C-65) y el centro de 5×5 si el autor lo aprueba (C-66). Después, las facciones nuevas (O).
7. **Antes de publicar:** las consultas a comunidades (Q), las voces (P) y la caída al cerrar (R). Las consultas conviene arrancarlas ya: son las que más tardan, y alguna respuesta puede pedir cambiar una mecánica.

## Reglas para el diseño que salen de esto

Para sumar a `docs/04-decisiones.md` si el autor está de acuerdo:

1. **La mecánica no contradice la historia.** Si el texto y la mecánica dicen cosas distintas, se cambia la mecánica o se consulta; no se arregla solo el texto.
2. **Un pacto, una alianza o una ventaja histórica con costo tiene costo en el juego** (Cucaú).
3. **Lo sagrado vivo no da bonos de combate, no se construye como pieza del jugador y no suena en las órdenes de la tropa.** Los lugares de culto vivos van como sitios neutrales del mapa.
4. **Nombres de época, o castellano.** Un nombre sin fuente va en castellano hasta que un hablante lo confirme (C-30 b).
5. **Nombres y arte por edad cuando la historia cambia dentro de la partida** (*bayingyi*, Jugol, la cerca, Vilcabamba).
6. **Toda renta dice quién la paga** (gult, suai, mit'a, yerba).
7. **Ningún pueblo existe solo como enemigo de otro**: a mediano plazo, cada rival con civ propia tiene al menos un hito y una voz en la campaña.
