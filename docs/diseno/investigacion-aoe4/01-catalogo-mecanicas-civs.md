# Catálogo de mecánicas económicas de las civilizaciones de AoE4

Investigación de referencia para el diseño de **Raíces**. Relevamiento hecho el 13 de noviembre de 2026, con el juego en la versión 17.0 (expansión *Raiders of the North*). No es una decisión de diseño: es material para discutir. Complementa a [`02-voz-de-los-jugadores.md`](02-voz-de-los-jugadores.md), que trata la recepción general.

## Cómo leer este documento

**Qué cubre.** Las 25 civilizaciones y variantes que existen hoy ([Wikipedia, lista por expansión](https://en.wikipedia.org/wiki/Age_of_Empires_IV)):

| Lanzamiento | Civilizaciones |
|---|---|
| Juego base (28-10-2021) | Ingleses, franceses, Sacro Imperio, rus, mongoles, Sultanato de Delhi, chinos, abasíes |
| Actualización aniversario (25-10-2022) | Otomanos, malíes |
| *The Sultans Ascend* (14-11-2023) | Bizantinos, japoneses; variantes: ayubíes, Jeanne d'Arc, Orden del Dragón, Legado de Zhu Xi |
| *Knights of Cross and Rose* (8-4-2025) | Variantes: Caballeros Templarios, Casa de Lancaster |
| *Dynasties of the East* (4-11-2025) | Variantes: Horda de Oro, Dinastía Macedonia, Daimyo Sengoku, Dinastía Tughlaq |
| *Yue Fei's Legacy* (7-5-2026) | Dinastía Jin |
| *Raiders of the North* (29-10-2026) | Vikingos, escoceses |

**De dónde salen los números.**
- *Mecánica actual*: textos y costos que el sitio aoe4world extrae de los archivos del juego y publica en GitHub ([aoe4world/data](https://github.com/aoe4world/data), carpeta `civilizations/`, más `buildings/` y `units/`). Cada ficha enlaza su archivo.
- *Historia de parches*: notas oficiales de ageofempires.com. Las leí a través del espejo comentado de aoe4world ([aoe4world/explorer, `src/data/patches`](https://github.com/aoe4world/explorer/tree/main/src/data/patches)), que copia las notas con las aclaraciones de los desarrolladores. En cada cambio enlazo la nota oficial.
- *Tasas de victoria*: API de aoe4world, 1v1 por ranking, parches 17.0.12182, 17.0.12260 y 17.0.12303, consultada el 13-11-2026. Doy dos cifras: todos los niveles ([API](https://aoe4world.com/api/v0/stats/rm_solo/civilizations)) y Conqueror, es decir, Elo mayor a 1400 ([API](https://aoe4world.com/api/v0/stats/rm_solo/civilizations?rank_level=conqueror)). La muestra en Conqueror es chica: entre 177 y 5746 partidas por civilización. Los vikingos y los escoceses llevan apenas dos semanas en el juego, y además hubo un exploit de recursos (lo detallo en sus fichas).
- *Opinión de los jugadores*: foros oficiales ([forums.ageofempires.com](https://forums.ageofempires.com)) y alguna reseña de prensa. Las citas van en inglés, textuales.

**Límites.** Liquipedia me bloqueó tras pocas consultas y Fandom pide pago; Reddit solo lo vi a través de resultados de búsqueda; no encontré transcripciones de casters (Beasty, Vortix, Spirit of the Law) y no cito nada de ellos. La búsqueda web se agotó antes de terminar las fichas más nuevas, así que vikingos, escoceses y Jin tienen menos fuentes de opinión. Donde no encontré un dato, lo digo.

**Escala de atención (APM).** Es una evaluación mía, hecha a partir de cómo funciona cada mecánica, no una medición:
- **Bajo**: se construye o se elige una vez y rinde sola ("lo pongo y funciona").
- **Medio**: pide decisiones puntuales (dónde ubicar, qué elegir al subir de edad, cuándo gastar) o mover algo cada varios minutos.
- **Alto**: pide acciones repetidas cada pocos segundos o minutos, o micro de unidades económicas que se mueren si las descuidás.

---

## 1. Ingleses — red de granjas

- **Cómo funciona.** Las granjas cuestan 50 % menos. Cerca de un molino rinden +20/25/30/30 % según la edad. Con *Enclosures* (edad IV), cada aldeano que trabaja una granja genera 1 de oro cada 6 s. Desde la temporada 12, exploradores y hombres de armas pueden poner fogatas, que dan +10 % a la caza cercana ([english.json](https://github.com/aoe4world/data/blob/main/civilizations/english.json)).
- **Atención: baja.** Molino, granjas alrededor, y listo. Es la economía más "de manual" del juego.
- **¿Única o variante?** Variante de la agricultura común: no hay recurso nuevo, solo descuento y multiplicador por cercanía.
- **Parches.**
  - Temporada 4 (16-2-2023): *Enclosures* pasó de 1 oro cada 3,5 s a 1 cada 5 s ([nota](https://www.ageofempires.com/news/ageiv_seasonfour_update_60878/)). Hoy los datos dicen 6 s; no encontré el parche de ese último paso.
  - Temporada 11 (26-6-2025): el bono de granja subió de 15/20/25 % a 20/25/30 % en las edades I a III ([nota](https://www.ageofempires.com/news/age-of-empires-iv-season-eleven-update-14-0-4963/)).
  - Temporada 12 (30-10-2025): la fogata ahora mejora la caza ([nota](https://www.ageofempires.com/news/age-of-empires-iv-season-twelve-update-15-1-6970/)).
- **Recepción.** Se la recomienda para empezar: *"I suggest you start with the English. They are the easiest to use"* ([foro, 2022](https://forums.ageofempires.com/t/most-defensive-civilization-for-a-beginner-hre-vs-eng/209209/4)). Tasa de victoria: 46,7 % en general y 51,8 % en Conqueror. Rinde mejor cuanto más alto el nivel.

## 2. Franceses — economía continental y comercio flexible

- **Cómo funciona.** Los centros urbanos producen +15/15/20/25 % más rápido según la edad. Los puntos de entrega cuestan 50 % menos y las tecnologías económicas, 35 % menos. Los comerciantes pueden traer comida, madera u oro, y los barcos mercantes rinden +20 %. La *Chamber of Commerce* entrega un comerciante gratis por cada tecnología económica; *Merchant Guilds* hace que cada comerciante activo genere 1 de oro cada 6 s ([french.json](https://github.com/aoe4world/data/blob/main/civilizations/french.json)).
- **Atención: baja** en la economía base y **media** si se juega comercio, porque hay que proteger la ruta.
- **¿Única o variante?** Variante de lo común: descuentos más el comercio estándar, con un botón para elegir qué recurso devuelve.
- **Parches.**
  - Temporada 4 (2023): la Chamber dejó de dar recursos extra y empezó a regalar comerciantes ([nota](https://www.ageofempires.com/news/ageiv_seasonfour_update_60878/)).
  - 6.1.130 (4-4-2023): la producción del centro urbano subió de 10/10/15/20 % a 10/15/20/25 % ([nota](https://www.ageofempires.com/news/age-of-empires-iv-season-four-patch-6-1-130/)).
  - Temporada 5: llegó *Merchant Guilds* ([nota](https://www.ageofempires.com/news/age-of-empires-iv-season-five-update-7-0-5861/)).
  - Temporada 13 (30-4-2026): los comerciantes gratis salen al instante ([nota](https://www.ageofempires.com/news/age-of-empires-iv-update-16-1-9737-and-yue-feis-legacy-dlc-release-preview/)).
- **Recepción.** Sin polémica económica: se discuten sus caballeros, no su economía. 49,1 % en general y 51,7 % en Conqueror, con 8,5 % de elección.

## 3. Sacro Imperio Romano Germánico — prelados que "inspiran"

- **Cómo funciona.** El prelado lanza *Holy Inspiration* sobre un aldeano: +40 % de recolección durante un rato. Los aldeanos cargan 40 % más. Las reliquias van en puestos, torres y torreones, y dan defensa y oro ([hre.json](https://github.com/aoe4world/data/blob/main/civilizations/hre.json)). Con *Cistercian Abbeys* (temporada 10), un monasterio con un prelado adentro inspira en área a los aldeanos cercanos y funciona como punto de entrega ([nota](https://www.ageofempires.com/news/age-of-empires-iv-season-ten-update-preview/)).
- **Atención: alta.** Es el caso de manual de micro económica: el prelado inspira de a un aldeano por vez, y hay que volver a hacerlo cuando se vence el efecto. La abadía cisterciense es justamente la salida "automática" que se agregó después.
- **¿Única o variante?** Única en su forma, aunque el efecto es un multiplicador temporal de recolección.
- **Parches.**
  - Mayo 2022: arrancan con 0 de oro y un prelado gratis. Los desarrolladores explicaron que, según su modelo, el Sacro Imperio generaba menos recursos que el resto ([nota](https://www.ageofempires.com/news/age-of-empires-iv-server-side-patch-14681/)).
  - Inspiración: bajó de 40 % a 35 % en la temporada 11 ([nota](https://www.ageofempires.com/news/age-of-empires-iv-season-eleven-update-14-0-4963/)); la duración pasó de 35 a 38 s en el 15.3 ([nota](https://www.ageofempires.com/news/age-of-empires-iv-patch-15-3-8338/)); volvió a 40 % en el 17.0 ([nota](https://www.ageofempires.com/news/age-of-empires-iv-update-17-0/)). El texto de la civilización todavía dice 30 s, contra los 38 s del parche: hay una inconsistencia en los datos.
- **Recepción.** Mala por el costo de atención. En el foro la llaman *"tedious, annoying and just not thought through"* y se quejan de que, mientras otras civs aplican sus bonos en área, el prelado va uno por uno, lo que escala mal con partidas más grandes ([foro](https://forums.ageofempires.com/t/hre-uniqueness-mechanic-and-army-rant-there-is-a-lot-of-potential-lying-fallow/176231?page=4); [prelados que dejan de inspirar](https://forums.ageofempires.com/t/prelate-stops-buffing-villagers-early-game-cruicial/189920)). 48,8 % en general y 49,4 % en Conqueror.

## 4. Rus — recompensa por caza y cabañas de caza

- **Cómo funciona.** Cazar animales da oro (la "recompensa"). Al acumular 100, 400 y 1000 de recompensa, la recolección de comida sube +10/15/20 % y las cabañas generan +10/25/40 % de oro. La cabaña de caza reemplaza al molino, produce exploradores y genera oro según los árboles cercanos ([rus.json](https://github.com/aoe4world/data/blob/main/civilizations/rus.json)). Cuesta 75 de madera ([hunting-cabin](https://github.com/aoe4world/data/blob/main/buildings/rus/hunting-cabin-1.json)).
- **Atención: media-alta.** Al principio pide disputar ciervos con exploradores y matar animales activamente. Las cabañas, en cambio, son baja atención: se ubican junto al bosque y rinden solas.
- **¿Única o variante?** Única. Convierte una fuente de comida común en un segundo recurso.
- **Parches** (es de las mecánicas más retocadas):
  - Temporada 3 (2022): se eliminó la recompensa por ovejas ([resumen](https://www.ageofempires.com/news/age_of_empires_iv_update_24916_season3/)).
  - Temporada 5 (16-5-2023): rehicieron las cabañas. Antes se penalizaban las áreas superpuestas; desde entonces cada árbol pertenece a la primera cabaña que lo toma. El oro llega en intervalos fijos de 30 s y el tope global queda en 300 a 500 de oro por minuto. Los desarrolladores dijeron: *"We have made a pass on Hunting Cabins to make them less punishing, easier to understand, and better balanced"* ([nota](https://www.ageofempires.com/news/age-of-empires-iv-season-five-update-7-0-5861/)). En ese mismo parche, el Khan mongol pasó a matar un ciervo en dos disparos *"to allow bounty counterplay"*.
  - Temporada 10 (2025): los umbrales subieron de 250 a 400 y de 750 a 1000 ([nota](https://www.ageofempires.com/news/age-of-empires-iv-season-ten-update-preview/)).
  - Temporada 12: el ingreso de las cabañas bajó 15 %, con el tope en 420 de oro por minuto ([nota](https://www.ageofempires.com/news/age-of-empires-iv-season-twelve-update-15-1-6970/)).
  - 16.2 (1-6-2026): el bono de comida subió de 5/10/15 % a 10/15/20 % ([nota](https://www.ageofempires.com/news/age-of-empires-iv-patch-16-2-10475/)).
- **Recepción.** Dividida. Unos la ven *"good and cool"*; otros, *"illogical, frustrating and tedious"*, sobre todo porque los cadáveres bloquean la construcción en partidas por equipos ([foro](https://forums.ageofempires.com/t/rus-hunting-whats-wrong-with-it-and-possible-solutions/216717); [*The Rus bounty system should reward differently*](https://forums.ageofempires.com/t/the-rus-bounty-system-should-reward-differently/188569?page=2)). 47,5 % en general y 52,1 % en Conqueror.

## 5. Mongoles — ovoo y piedra como "moneda de mejora"

- **Cómo funciona.** El ovoo se construye sobre un afloramiento de piedra y la extrae sin aldeanos: 70/100/140/170 por minuto según la edad. Cerca de un ovoo, la piedra sirve para producir unidades de a dos o para investigar versiones mejoradas de las tecnologías. Los mongoles no construyen casas, empiezan con la población máxima, pueden empacar todos sus edificios, usan pasturas con ovejas en lugar de granjas y saquean +25 de comida y oro al quemar edificios enemigos ([mongols.json](https://github.com/aoe4world/data/blob/main/civilizations/mongols.json)).
- **Atención.** El ovoo en sí es **bajo**: se pone y extrae solo. Gastar la piedra (producción doble, tecnologías mejoradas) es **medio**. Empacar, mudar la base y jugar de saqueo es **alto**: en el foro se los compara con los zerg de StarCraft ([foro](https://forums.ageofempires.com/t/mongols-base-relocation-ability/124761)).
- **¿Única o variante?** Única: un recurso común (la piedra) se convierte en un multiplicador de producción.
- **Parches.**
  - 11963 (25-2-2022): de 105 fijos por minuto a 80/100/120/150 según la edad ([nota](https://www.ageofempires.com/news/age-of-empires-iv-patch-11963/)).
  - Temporada 7 (2024): 70 en la edad oscura ([nota](https://www.ageofempires.com/news/age-of-empires-iv-season-seven-update-10-0-576/)).
  - 15.3 (2026): 130/160 en las edades III y IV ([nota](https://www.ageofempires.com/news/age-of-empires-iv-patch-15-3-8338/)); 16.2: 140/170 ([nota](https://www.ageofempires.com/news/age-of-empires-iv-patch-16-2-10475/)).
  - Las pasturas pasaron de 120 a 140 s por oveja, con la explicación: *"Pastures are still more cost effective than farms, we just wanted to reduce the delta"* ([nota](https://www.ageofempires.com/news/age-of-empires-iv-server-side-patch-5-1-148-1/)).
  - En 9.2.628 (2024) recortaron la piedra de *Tithe Barns* con este argumento: *"We want Stone to be a limited resource in the later stages of the game so defenses cannot be amassed too much"* ([nota](https://www.ageofempires.com/news/age-of-empires-iv-patch-9-2-628/)).
  - *Silk Road*: los umbrales pasaron de 3/5/7/9 a 5/10/15/20 comerciantes ([nota](https://www.ageofempires.com/news/age-of-empires-iv-season-four-patch-6-1-130/)).
- **Recepción.** Se la considera una civ de techo alto. Tasa de victoria: 49,7 % en general y **58,7 % en Conqueror**, la mejor de esa liga. Rinde mucho más en manos expertas.

## 6. Sultanato de Delhi — tecnologías gratis pero lentas, y eruditos

- **Cómo funciona.** Todas las tecnologías son gratis, pero se investigan mucho más lento y se pueden pausar. Los eruditos guarnecidos en mezquitas, madrazas o muelles aceleran la investigación según cuántos haya en total. Además, un molino junto a arbustos los convierte en huertos (+100 de comida), las bayas se recolectan +25 % más rápido y no se puede cazar jabalí ([delhi.json](https://github.com/aoe4world/data/blob/main/civilizations/delhi.json)).
- **Atención: media.** No hay micro, pero sí decisiones constantes de cola: qué investigar primero, cuándo pausar, cuántos eruditos producir.
- **¿Única o variante?** Única: cambia la moneda de las tecnologías, de recursos a tiempo.
- **Parches.**
  - Temporada 2 (2022): el multiplicador de tiempo de las tecnologías imperiales bajó de 15× a 12×, con esta explicación: *"Delhi free Imperial technologies provide a gigantic amount of Gold. But that doesn't matter if you die before the research completes"* ([nota](https://www.ageofempires.com/news/age-of-empires-iv-update-17718/)).
  - Temporada 5 (2023): *Sanctity* (oro por sitios sagrados) bajó de +50 % a +25 %, porque *"can create very binary games where the Delhi player has three Sacred Sites and a gigantic advantage or no Sacred Sites and is far behind"* ([nota](https://www.ageofempires.com/news/age-of-empires-iv-season-five-update-7-0-5861/)).
  - Los eruditos gratis con la primera madraza llegaron en 8.2 (2023) y se quitaron en 12.2 (2025) ([nota](https://www.ageofempires.com/news/age-of-empires-iv-patch-12-2-3327/)).
- **Recepción.** La idea gusta, pero en la práctica se la siente lenta: *"the technologies are NOT practically free beyond feudal because they would take too long"* ([foro](https://forums.ageofempires.com/t/suggestion-delhi-research-time/192961)). También: *"No one likes Delhi anymore, it's super boring"* ([foro, 2022](https://forums.ageofempires.com/t/delhi-sultanate-and-ottomans-are-not-fun-so-boring/220919)). 48,1 % en general y 49,8 % en Conqueror; 1,4 % de elección.

## 7. Chinos — dinastías e impuestos

- **Cómo funciona.** Si construís los dos monumentos de una edad, entrás en una dinastía con bonos y edificios propios: Song (aldeanos +33 % más rápido), Yuan (velocidad +15 %) o Ming (+15 % de vida). Entrenar, investigar y entregar recursos genera impuesto en oro, que el funcionario imperial recoge a pie. Con *Supervise*, el funcionario acelera +150 % la producción de un edificio o da +20 % a lo que se entrega en uno económico ([chinese.json](https://github.com/aoe4world/data/blob/main/civilizations/chinese.json)).
- **Atención: alta.** Los funcionarios caminan, recogen, entregan y supervisan, y la automatización falla: van al frente y mueren, o se quedan ociosos ([foro, 2026](https://forums.ageofempires.com/t/many-imperial-official-bugs-and-room-for-improvement/284368)). La dinastía, en cambio, es una decisión puntual (**media**).
- **¿Única o variante?** Única, aunque el impuesto es un "goteo de oro" que necesita transporte.
- **Parches.**
  - Temporada 1 (2022): *Supervise* bajó de 200 % a 150 %, y el funcionario pasó a costar oro porque *"China was able to rapidly accelerate their age … by skipping a mining camp and using tax gold"* ([nota](https://www.ageofempires.com/news/age-of-empires-iv-season-one-update-release-notes/)).
  - Se fue agregando más lugares para entregar el impuesto: monumentos en la temporada 5 y *Barbican* en la 7.
  - Temporada 13 (2026): el impuesto por entrega dejó de ser 1 de oro fijo y pasó a ser el 8 % de lo entregado (4 % en pesca) ([nota](https://www.ageofempires.com/news/age-of-empires-iv-update-16-1-9737-and-yue-feis-legacy-dlc-release-preview/)).
  - 17.0: el funcionario ya no puede supervisar puntos de interés.
- **Recepción.** El impuesto aparece seguido como tedioso. Hay propuestas de que se deposite solo, sin viajes ([foro, abril de 2025](https://forums.ageofempires.com/t/the-tax-system-for-the-chinese-civilization-and-zhu-xis-legacy-needs-changes/272490)). Ya en el lanzamiento había quejas porque el funcionario figura como "aldeano ocioso" ([foro, 2021](https://forums.ageofempires.com/t/chinese-imperial-official-same-afk-villager-status-not-ok/178539)). 45,6 % en general y 50,1 % en Conqueror.

## 8. Abasíes — Casa de la Sabiduría y Edad de Oro

- **Cómo funciona.** Se sube de edad construyendo alas en la Casa de la Sabiduría, sin usar aldeanos. Cada edificio dentro de su influencia suma un punto hacia la Edad de Oro, con umbrales en 10, 20, 30, 50 y 75 edificios. El primer nivel da +15 % de recolección; los siguientes, +20 % de construcción, daño de camellos, +20 % de comercio y daño de infantería. Tienen huertos como Delhi ([abbasid.json](https://github.com/aoe4world/data/blob/main/civilizations/abbasid.json)).
- **Atención: baja.** La Edad de Oro se alcanza con urbanismo: hay que pensar dónde construir, pero no requiere acciones repetidas. Las alas son decisiones de edad (**media**, puntual).
- **¿Única o variante?** Única en la forma ("densidad urbana = economía"), aunque los premios son multiplicadores genéricos.
- **Parches.**
  - Temporada 1: el huerto bajó de +250 a +100 de comida, porque *"it gives a boon for too long. We want them to have to move out on the map"* ([nota](https://www.ageofempires.com/news/age-of-empires-iv-season-one-update-release-notes/)).
  - Temporada 2: el primer nivel de Edad de Oro pasó de +10 % a +15 %, porque *"they still struggle early"* ([nota](https://www.ageofempires.com/news/age-of-empires-iv-update-17718/)).
  - *Fresh Foodstuffs* (aldeanos más baratos): 50 % → 35 % → 40 %.
  - 16.2 (junio de 2026): rediseño grande. El ala de comercio se reemplazó por una administrativa (+50 % a los bonos de la Edad de Oro) y se pasó de 3 a 5 niveles ([nota](https://www.ageofempires.com/news/age-of-empires-iv-patch-16-2-10475/)).
- **Recepción.** Se la considera débil y aburrida. Tras el rediseño de junio: *"removed Abbasid's most universal strengths … and replaced them with narrower, delayed, conditional bonuses"* ([hilo](https://forums.ageofempires.com/t/abbasids-re-work-june-patch/286595); [informe de balance](https://forums.ageofempires.com/t/abbasid-dynasty-balance-report-season-12-post-dynasties-of-the-east-update/281704)). 46,5 % en general y 48,1 % en Conqueror.

## 9. Otomanos — escuelas militares y Consejo Imperial

- **Cómo funciona.** Cada escuela militar produce sin costo y sin parar un tipo de unidad, pero tarda 5 veces lo normal. Entrenar y subir de edad da experiencia hacia los Puntos de Visir (hasta 5), que desbloquean bonos. Los edificios militares y de tecnología son más baratos ([ottomans.json](https://github.com/aoe4world/data/blob/main/civilizations/ottomans.json); [military-school](https://github.com/aoe4world/data/blob/main/buildings/ottomans/military-school-1.json)).
- **Atención: baja.** Es el ejemplo más puro de "lo pongo y funciona": la escuela es un ingreso pasivo convertido directamente en ejército.
- **¿Única o variante?** Única. La economía se salta el paso del recurso.
- **Parches.**
  - 8.2.218 (2023): el sipahi pasó de 28 a 30 s porque *"provides more resources per minute, compared to other units, when trained from Military Schools"* ([nota](https://www.ageofempires.com/news/age-of-empires-iv-patch-8-2-218/)). El valor de una escuela se mide en recursos por minuto según la unidad elegida.
  - Temporada 7: la producción de la escuela pasó de 4,5× a 5× el tiempo normal.
  - El descuento de edificios fue 33 % → 40 % (12.2) → 30 % (17.0) ([nota 17.0](https://www.ageofempires.com/news/age-of-empires-iv-update-17-0/)).
- **Recepción.** Mala en identidad: *"lame and boring"*, *"a lazy civ concept"*. Quienes la defienden calculan unos 100 de comida más oro o madera por minuto por escuela, y señalan que es *"the only civ that still get their passive generation turn into military"* incluso con la economía cortada ([foro](https://forums.ageofempires.com/t/ottoman-general-discussion/219111); [*Ottomans needs urgent rework*](https://forums.ageofempires.com/t/ottomans-needs-urgent-rework/237901)). **La tasa de victoria más baja del juego**: 42,0 % en general y 42,4 % en Conqueror.

## 10. Malíes — minas de pozo, ganado y peajes

- **Cómo funciona.**
  - La mina de pozo se construye sobre una veta de oro y extrae 36 de oro por minuto sin agotarla; sigue funcionando aunque la veta se termine ([pit-mine](https://github.com/aoe4world/data/blob/main/buildings/malians/pit-mine-1.json)). Las casas y campamentos mineros en su influencia aumentan su producción; aoe4world calcula +25 % por edificio ([explorer](https://aoe4world.com/explorer/civs/malians/buildings/pit-mine)).
  - El ganado se compra con oro en el molino. Se lo puede faenar, y los malíes lo hacen más rápido que otras civs, o se lo guarece en un corral para que dé comida pasiva.
  - Los puestos de peaje cobran oro a las caravanas que pasan.
  - El centro urbano cuesta oro en lugar de piedra ([malians.json](https://github.com/aoe4world/data/blob/main/civilizations/malians.json)).
- **Atención: media.** La mina es **baja**. El ganado pide decisiones (faenar o guarecer, cuándo comprar) y algo de pastoreo. El peaje es baja atención, pero depende de cómo se arme la ruta.
- **¿Única o variante?** Única. Oro como recurso infinito y comida comprada con oro.
- **Parches.**
  - Ganado: de 100 a 75 y después a 90 de oro, porque *"at 75 gold it was so cost efficient that players would completely ignore farms … Cattle are meant as a supplement to farms"* ([nota](https://www.ageofempires.com/news/age-of-empires-iv-server-side-patch-5-1-148-1/)).
  - Temporada 5: los aldeanos faenan más lento (0,9 → 0,81 por segundo), para *"push players towards garrisoning cattle in ranches"* ([nota](https://www.ageofempires.com/news/age-of-empires-iv-season-five-update-7-0-5861/)). El corral pasó de 28 a 25 de comida por minuto en la temporada 6.
  - Mina: 30 → 35 → 36 de oro por minuto.
  - *Fulani Corral*: 20 → 18 → 16 por cabeza de ganado (15.2 y 17.0).
- **Recepción.** En identidad, la mejor considerada: *"Malians feels like a unique civ that feels fresh to play"* ([foro, 2022](https://forums.ageofempires.com/t/mali-is-how-i-imagined-all-of-aoe-iv-would-be/213682)). En balance, no: 44,3 % en general y 44,5 % en Conqueror. Un jugador de nivel alto se queja de que el jugador promedio hace vacas y minas sin importar el rival ([foro](https://forums.ageofempires.com/t/mali-has-been-on-life-support/265617)).

## 11. Bizantinos — aceite de oliva, cisternas y acueductos

- **Cómo funciona.**
  - El aceite de oliva es un recurso aparte para contratar mercenarios. Los aldeanos lo generan como porcentaje de la comida: 50 % de las bayas, 15 % de los olivares y 10 % del pescado de costa. Los barcos pesqueros y los comerciantes aportan 20 %.
  - La cisterna da +10/14/18/22/24 % de recolección según el nivel de la red. Hay que elegir qué potencia su influencia (producción, investigación o defensa), y los acueductos la mejoran.
  - Cada edificio construido devuelve algo de piedra ([byzantines.json](https://github.com/aoe4world/data/blob/main/civilizations/byzantines.json); [cistern](https://github.com/aoe4world/data/blob/main/buildings/byzantines/cistern-1.json)).
- **Atención: alta.** Hay que tender la red de acueductos, elegir el modo de cada cisterna, administrar un recurso extra, y los mercenarios tardan en salir.
- **¿Única o variante?** El aceite es único (un subproducto de la comida); la cisterna es un aura de recolección clásica sostenida con infraestructura.
- **Parches.**
  - Cisterna: el bono subió en 9.2.628 (de 5–25 % a 10–26 %). El costo pasó de un tope de 300 de piedra, creciente con cada cisterna, a 125 fijos, después 120 y hoy 100. En 17.0 el máximo bajó de 26 % a 24 %.
  - Olivar: de 20 % a 15 % (16.2).
  - Más de diez rebajas de mercenarios entre 2025 y 2026 ([temporada 10](https://www.ageofempires.com/news/age-of-empires-iv-season-ten-update-preview/); [16.2](https://www.ageofempires.com/news/age-of-empires-iv-patch-16-2-10475/)).
- **Recepción.** Floja. *"Aqueducts … a less fun way"* que el funcionario chino: el funcionario *"can take care of multiple things"* y la cisterna no tiene motivos para cambiar de modo ([foro, diciembre de 2023](https://forums.ageofempires.com/t/byzantines-feels-off-not-a-balance-thread/246752)). Hay un hilo titulado [*Request: Byzantine Changes and Macro Heavy Reduction*](https://forums.ageofempires.com/t/request-byzantine-changes-and-macro-heavy-reduction/281869) (noviembre de 2025) que pide sacar los campamentos madereros y se queja de que *"by the time I make the connections the research is already complete"*. 43,6 % en general y 41,4 % en Conqueror.

## 12. Japoneses — granja-casa, fragua y daimyo

- **Cómo funciona.**
  - La *Farmhouse* es casa y punto de entrega de comida a la vez; la *Forge* recibe oro y piedra y además es herrería.
  - Al entregar oro se produce un 20 % extra de piedra, y al revés.
  - El centro urbano se mejora a Mansión, Palacio y Castillo Shogunal, con +20/40/60 % a las granjas cercanas y más cupo de abanderados samurái ([japanese.json](https://github.com/aoe4world/data/blob/main/civilizations/japanese.json)).
- **Atención: baja.** Fusionar edificios ahorra clics y caminatas; el daimyo es una mejora puntual.
- **¿Única o variante?** Variante: es la agricultura común con edificios fusionados y multiplicadores.
- **Parches.**
  - 12.2 (2025): la Mansión Daimyo bajó de 225 a 175 de piedra.
  - Temporada 6: el *Kura Storehouse* pasó a generar granjas cada 50 s en lugar de 45.
  - 9.2.628: rediseño religioso, con *Zen* (+25 de oro por minuto por monje). La nota dice: *"We want the sacred choice for the Japanese to be far more meaningful"* ([nota](https://www.ageofempires.com/news/age-of-empires-iv-patch-9-2-628/)).
- **Recepción.** Buena en sabor (*"really fun to play and some of the mechanics really bring out many Japanese historical…"*, [foro](https://forums.ageofempires.com/t/incorrect-translations-for-age-of-empires-iv-dlc/243544/63)). 48,8 % en general y 46,9 % en Conqueror.

## 13. Ayubíes (variante abasí) — alas a elección

- **Cómo funciona.** Como los abasíes, pero al subir de edad se elige entre 8 alas, cada una con un bono inmediato que crece si se toma más tarde. La Edad de Oro da +10 % de recolección, +25 % de investigación, +20 % de producción, asedio 20 % más barato y camellos 20 % más rápidos. El ala de comercio ofrece canjes de recursos ([ayyubids.json](https://github.com/aoe4world/data/blob/main/civilizations/ayyubids.json)).
- **Atención: baja**, con decisiones puntuales en cada edad.
- **¿Única o variante?** Variante de la Casa de la Sabiduría.
- **Parches.** En 9.2.628 se recortó el ala *Advancement*: la subida de edad pasó de 40 % a 20 % más rápida y el descuento bajó de 500 a 400 en la edad III. En la temporada 6, el bazar perdió la opción de canjear por aldeanos. En la temporada 12, el ala *Industry* pasó a dar más madera ([nota](https://www.ageofempires.com/news/age-of-empires-iv-season-twelve-update-15-1-6970/)).
- **Recepción.** Poco jugada: 1,1 % de elección. 48,4 % en general y 45,3 % en Conqueror.

## 14. Jeanne d'Arc (variante francesa) — heroína que sube de nivel

- **Cómo funciona.** Jeanne empieza como aldeana y gana experiencia recolectando, construyendo y peleando. Al subir de nivel desbloquea habilidades económicas y de combate, y en el nivel 3, compañeros. Las tecnologías económicas cuestan 35 % menos ([jeannedarc.json](https://github.com/aoe4world/data/blob/main/civilizations/jeannedarc.json)).
- **Atención: media-alta.** Es un héroe que hay que cuidar y llevar a donde gane experiencia.
- **¿Única o variante?** Única como sistema de progresión; la economía de fondo es la francesa recortada.
- **Parches.** En la temporada 6, la experiencia por jabalí bajó de 50 a 25. En 9.2.628 dejó de ganar experiencia con lobos y se recortaron sus formas tardías, con la intención de *"reduce Jeanne d'Arc's effectiveness in the Feudal Age"* ([nota](https://www.ageofempires.com/news/age-of-empires-iv-patch-9-2-628/)). En 10.1.48 perdió las mejoras gratis de herrería.
- **Recepción.** Polarizante: *"As much as I hate the Jeanne d'Arc variant…"* ([foro, mayo de 2026](https://forums.ageofempires.com/t/are-variants-becoming-something-different-some-thoughts-on-current-variants/286083)). 47,9 % en general y 49,2 % en Conqueror.

## 15. Orden del Dragón (variante del Sacro Imperio) — aldeanos dorados

- **Cómo funciona.** Los aldeanos recolectan 27 % más rápido, cargan 40 % más y construyen 20 % más rápido, pero cuestan 20 % más de comida. El ejército es de élite y ocupa el doble de población ([orderofthedragon.json](https://github.com/aoe4world/data/blob/main/civilizations/orderofthedragon.json)).
- **Atención: baja**, incluso menor que la normal: menos unidades, cada una más valiosa.
- **¿Única o variante?** Variante pura de estadísticas.
- **Parches.** Recolección: 25 % → 28 % (9.2.628) → 27 % (16.2) ([nota](https://www.ageofempires.com/news/age-of-empires-iv-patch-16-2-10475/)).
- **Recepción.** *"Jd, zhu xi and order of the dragon however not even a civ"* ([foro](https://forums.ageofempires.com/t/are-variants-becoming-something-different-some-thoughts-on-current-variants/286083)). Tiene la mayor diferencia entre niveles: 51,0 % en general y **40,3 % en Conqueror**, la peor de esa liga. Una economía "fácil" rinde abajo y se agota arriba.

## 16. Legado de Zhu Xi (variante china) — funcionarios mejorados

- **Cómo funciona.** El mismo impuesto chino, pero con tecnologías que mejoran mucho a los funcionarios. Las dinastías dan descuentos: Song, −30 % de madera en edificios económicos y de población; Yuan, −10 % en todas las unidades ([zhuxi.json](https://github.com/aoe4world/data/blob/main/civilizations/zhuxi.json)).
- **Atención: alta**, como la china.
- **¿Única o variante?** Variante.
- **Parches.** En 9.2.628, el descuento Song bajó de 40 % a 30 % y pasó a aplicarse a edificios económicos y de población. En la temporada 13 heredó el impuesto del 8 % de lo entregado.
- **Recepción.** Fuerte: 51,9 % en general y **56,5 % en Conqueror**, segunda en esa liga. Aunque pide mucha atención, rinde arriba.

## 17. Caballeros Templarios (variante francesa) — peregrinos

- **Cómo funciona.** No tienen comerciantes. Desde la edad II, cada 60 s sale un grupo de peregrinos desde el cuartel general hacia el sitio sagrado elegido. Al llegar generan oro según la distancia, con tope de 130 por viaje. El grupo crece en 1 por cada fortaleza, hasta 10. Los leñadores depositan sin campamento, recolectan +20/15/15 % por edad y el 20 % de la madera se convierte en comida extra ([templar.json](https://github.com/aoe4world/data/blob/main/civilizations/templar.json)).
- **Atención: baja-media.** El flujo es automático; la decisión está en elegir el destino y proteger la ruta con fortalezas. La madera sin campamentos ahorra trabajo.
- **¿Única o variante?** Variante del comercio, pero automatizada y atada al mapa (sitios sagrados).
- **Parches.**
  - Temporada 12: *Genoa* pasó de +30 % a +20 % al oro de los peregrinos, y la madera base bajó a 0,60 por segundo con escalado del 20 % ([nota](https://www.ageofempires.com/news/age-of-empires-iv-season-twelve-update-15-1-6970/)).
  - 16.2: ingreso de los peregrinos −10 %.
  - 17.0: la fortaleza pasó a costar 350 de oro y 650 de piedra.
- **Recepción.** Positiva: es la variante más elegida, con 6,1 %. 51,0 % en general y 53,1 % en Conqueror. Hay reportes de errores con los peregrinos ([foro](https://forums.ageofempires.com/t/ranking-list-knights-templar-pilgrim-bug-multiplayer-boulder-bay/288510)).

## 18. Casa de Lancaster (variante inglesa) — mansiones

- **Cómo funciona.** La mansión cuesta 175 de madera y 100 de piedra. Genera 30 de comida y 10 de madera por minuto, más un extra por cada aldeano cerca, y funciona como punto de entrega universal. Ese extra es 3 de comida y 2 de madera según los datos, pero 4 y 2 según el texto de la civilización y la nota de la temporada 12: no está claro cuál vale. Cada centro urbano trae 4 ovejas, y los aldeanos recolectan ovejas +20 % más rápido ([manor](https://github.com/aoe4world/data/blob/main/buildings/lancaster/manor-2.json); [lancaster.json](https://github.com/aoe4world/data/blob/main/civilizations/lancaster.json)).
- **Atención.** Al lanzamiento fue **baja**, ingreso pasivo puro. Tras el rediseño es **media**: hay que ubicar las mansiones donde trabajan los aldeanos.
- **¿Única o variante?** Única en la forma: un generador pasivo que se puede apilar.
- **Parches.** Es el ejemplo más claro del riesgo del ingreso pasivo.
  - Al lanzamiento (abril de 2025), cada mansión daba 70 de comida y 45 de madera por minuto. En Reddit se calculaba *"9 manors up five minutes after hitting Feudal … equal to having a 24-worker advantage"* ([r/aoe4, espejo](https://redlib.ssps.io/r/aoe4/comments/1jw2s0d/lancaster_is_still_broken)).
  - 13.0.4343 (9-4-2025, un día después del lanzamiento): bajó a 60/45 ([nota](https://www.ageofempires.com/news/age-of-empires-iv-patch-13-0-4343/)).
  - Temporada 12: pasó a un aura por aldeano, con esta explicación: *"Lancaster players will need to strategically place their Manors to make sure they capture as many Villagers as possible"* ([nota](https://www.ageofempires.com/news/age-of-empires-iv-season-twelve-update-15-1-6970/)).
- **Recepción.** Pasó de *"insanely OP at initial release"* a *"lower ends of the spectrum"*, con la queja de que le falta oro ([foro, junio de 2026](https://forums.ageofempires.com/t/how-to-fix-house-of-lancaster/286623)). Hoy: 50,3 % en general y 51,7 % en Conqueror.

## 19. Horda de Oro (variante mongola) — corrales y varios ovoos

- **Cómo funciona.** Como los mongoles, pero no empacan edificios. El ovoo se puede construir en varios afloramientos (uno más por edad). El *Stockyard* (275 de madera) reemplaza a granjas y pasturas: hasta 4 aldeanos trabajan carcasas de oveja ahí mismo. Las unidades salen de a dos. Se sube de edad mejorando la *Golden Tent*, que fija un edicto para los puestos fortificados ([goldenhorde.json](https://github.com/aoe4world/data/blob/main/civilizations/goldenhorde.json); [stockyard](https://github.com/aoe4world/data/blob/main/buildings/goldenhorde/stockyard-1.json)).
- **Atención: media.** Menos micro que los mongoles (no hay que empacar), con decisiones de edicto y de piedra.
- **¿Única o variante?** Variante.
- **Parches.** En la temporada 13, *Ovoo Offering* y *Ovoo Ceremony* bajaron de +30 % a +20 % de piedra y la madera inicial de 225 a 200. En 16.2, el *Stockyard* pasó de 250 a 275 de madera.
- **Recepción.** Buena como variante: *"it perfectly fulfills what a 'variant' civilization should … having the good stuff from Mongol but with different gameplay feels great"* ([foro, noviembre de 2025](https://forums.ageofempires.com/t/golden-horde-suggestions/281686)). Débil ante la agresión temprana. 49,8 % en general y 43,6 % en Conqueror.

## 20. Dinastía Macedonia (variante bizantina) — plata

- **Cómo funciona.** Al minar oro o piedra, los aldeanos extraen además plata, igual al 40 % de lo minado. Se gana plata pasiva en campamentos y centros urbanos dentro de la influencia del *Varangian Arsenal*; el texto de esa influencia falta en los datos ("translation not found"). La plata compra tecnologías militares que superan los tres niveles normales. El *Warcamp* repone gratis a los varegos caídos ([macedonian.json](https://github.com/aoe4world/data/blob/main/civilizations/macedonian.json)).
- **Atención: baja-media.** La plata sale sola de la minería; la decisión es cómo gastarla.
- **¿Única o variante?** Recurso propio que sale como subproducto, igual que el aceite bizantino.
- **Parches.** En 15.3, los niveles 2 y 3 del arsenal pasaron a costar 550 y 1100 de plata (antes 500 y 1000). En 16.2 subió el umbral de refuerzo del *Warcamp* (de 6× a 7× el costo de lo caído). En 17.0, *Grand Winery* pasó de 80 a 100 de plata por reliquia, y *Cistern's Favor* ahora también hace que los molinos generen comida ([nota](https://www.ageofempires.com/news/age-of-empires-iv-update-17-0/)).
- **Recepción.** Se critica la mezcla temática (*"weird mash up"* de bizantino y nórdico) y que la plata reemplace al aceite sin que se explique el porqué ([foro](https://forums.ageofempires.com/t/disillusioned-comment-on-dynasties-of-the-east/278685)). 51,1 % en general y 48,8 % en Conqueror.

## 21. Daimyo Sengoku (variante japonesa) — yatai y matsuri

- **Cómo funciona.** El *Matsuri* es un mercado temprano que produce *yatai* (125 de madera; hasta 3, uno más por edad; no ocupan población). El yatai se estaciona junto a una fuente de comida y la ordeña sin consumirla, con una base de 10 de comida por minuto. Cada 215 de comida juntada manda un comerciante al Matsuri, que agrega +5 % al aura de recolección del mercado y +50 de comida. Además, los ciervos y jabalíes del mapa aparecen revelados ([sengoku.json](https://github.com/aoe4world/data/blob/main/civilizations/sengoku.json); [yatai](https://github.com/aoe4world/data/blob/main/units/sengoku/yatai-1.json)).
- **Atención: media.** Hay que ubicar y proteger los yatai, pero después producen solos.
- **¿Única o variante?** Única: un recolector pasivo que no agota la fuente.
- **Parches.** En 15.2, los yatai dejaron de ocupar población. En 16.1.10056 (mayo de 2026), la base bajó de 20 a 10 y la reparación de 20 a 5 ([nota](https://www.ageofempires.com/news/age-of-empires-iv-minor-patch-16-1-10056/)). En 17.0, el umbral del comerciante bajó de 250 a 215. No encontré la explicación de los desarrolladores para el recorte de mayo.
- **Recepción.** Poca discusión; la variante se ve *"pretty solid"* ([foro](https://forums.ageofempires.com/t/disillusioned-comment-on-dynasties-of-the-east/278685)). Es la civ menos elegida (0,6 %): 45,2 % en general y 41,9 % en Conqueror.

## 22. Dinastía Tughlaq (variante de Delhi) — elefantes obreros y gobernadores

- **Cómo funciona.** El elefante obrero (25 de comida y 50 de madera) es un punto de entrega universal y móvil: se lo manda al recurso y los aldeanos trabajan ahí. Entregar en elefantes, centros urbanos y muelles da recursos extra. Las tecnologías son más caras pero casi instantáneas: lo contrario de Delhi. Los fuertes Tughlaqabad, disponibles desde la edad II, desbloquean gobernadores con bonos de economía, ritmo, ejército, investigación o religión ([tughlaq.json](https://github.com/aoe4world/data/blob/main/civilizations/tughlaq.json); [worker-elephant](https://github.com/aoe4world/data/blob/main/buildings/tughlaq/worker-elephant-1.json)).
- **Atención: baja.** El elefante elimina el micro de construir y mudar campamentos. Los gobernadores son decisiones puntuales.
- **¿Única o variante?** Variante del punto de entrega (como el *Ger* mongol), llevada al extremo.
- **Parches.** En 15.2, el elefante dejó de recibir mejoras de herrería. En 16.2, los barcos pesqueros dejaron de recibir el bono de entrega de los elefantes. En 15.3, *Hisar Academy* subió de 50 a 70 de comida y oro por gobernador activo ([nota](https://www.ageofempires.com/news/age-of-empires-iv-patch-15-3-8338/)).
- **Recepción.** Al anunciarse se criticó el exceso de elefantes y la inversión de la regla de Delhi (*"Literally the opposite of 'free but time consuming'"*, [foro](https://forums.ageofempires.com/t/disillusioned-comment-on-dynasties-of-the-east/278685)). En ranking, el "spam" de fuertes funciona en ciertos mapas ([foro](https://forums.ageofempires.com/t/tughlaq-dynasty/281669/78)). 47,1 % en general y 43,2 % en Conqueror.

## 23. Dinastía Jin — aldeanos a caballo y tributarios

- **Cómo funciona.**
  - Hasta 20 aldeanos montados (65 de comida, 50 de oro, 35 s) que recolectan, construyen y se mueven bastante más rápido.
  - El emisario (150 de oro, máximo 2) convierte puestos de comercio neutrales en tributarios. Cada tributario da comida, +15 % al comercio y +3 aldeanos montados al límite.
  - Al subir de edad se elige dónde poner una pradera, que cría caballos cada 75/60/45 s ([jindynasty.json](https://github.com/aoe4world/data/blob/main/civilizations/jindynasty.json); [mounted-villager](https://github.com/aoe4world/data/blob/main/units/jindynasty/mounted-villager-1.json)).
- **Atención: media.** Aldeanos caros que hay que cuidar, más la expansión diplomática con el emisario.
- **¿Única o variante?** Única: es "calidad sobre cantidad" en la mano de obra, más una expansión por diplomacia.
- **Parches.** En 16.2, el caballo de la pradera en la edad II pasó de 90 a 75 s. El resto fueron correcciones.
- **Recepción.** Mixta. Un análisis del foro calcula que el aldeano montado *"COST 35% more resources per second"* y tarda minutos en pagarse ([foro, mayo de 2026](https://forums.ageofempires.com/t/jin-dynasty-critical-analysis-and-unit-types-and-eco-mechanics/286241)). Otro usuario: *"Jin is the best variant so far its like a new civ"* ([foro](https://forums.ageofempires.com/t/are-variants-becoming-something-different-some-thoughts-on-current-variants/286083)). Steam: 51 % de reseñas positivas sobre 170 ([pulse.bot](https://www.pulse.bot/gaming/news/age-of-empires-iv-yue-feis-legacy-launches-with-jin-dynasty-04d8d180-b43c-4a42-ba4b-bdc813fe8c6f/)). 54,4 % en general, segunda; 50,5 % en Conqueror.

## 24. Vikingos — migración automática y casa larga

- **Cómo funciona.**
  - Los centros urbanos reclutan aldeanos **solos y gratis**, más lento de lo normal, hasta una capacidad. Cada casa larga (150 de madera) suma +10 a esa capacidad y +25 de población.
  - A la casa larga se le agrega un anexo: huerta, colmenas (50 de oro por minuto; hasta 6 casas con colmenas), telar o herrería. Telar y herrería mejoran solos la armadura y el daño.
  - La *Völur* acelera la producción de las casas.
  - Las sagas son misiones con bonos permanentes.
  - La infantería se cura comiendo de fuentes de comida ([vikings.json](https://github.com/aoe4world/data/blob/main/civilizations/vikings.json); [longhouse](https://github.com/aoe4world/data/blob/main/buildings/vikings/longhouse-1.json); [bee-skeps](https://github.com/aoe4world/data/blob/main/technologies/vikings/bee-skeps-1.json)).
- **Atención: muy baja** en economía. Es la primera civ que elimina la tarea más repetida del género: encolar aldeanos. Las mejoras de herrería también se automatizan.
- **¿Única o variante?** Única.
- **Parches.** Lleva dos semanas en el juego. Hubo correcciones urgentes por un exploit de reembolso infinito en los anexos de la casa larga ([reporte](https://forums.ageofempires.com/t/bug-viking-longhouse-infinite-resources/291033)). No hay cambios de balance todavía.
- **Recepción.** Domina: **57,8 % de victorias en general, con 19,7 % de elección**, y 52,6 % en Conqueror con 26 % de elección. El foro matiza: *"They only leading up to Elo 1600"*, y *"Tons of people exploited vikings infinite resources"*, lo que contamina la estadística ([hilo](https://forums.ageofempires.com/t/vikings-leading-the-win-rates/291383)). El diseño gusta: *"The new mechanics and gameplay brought by the two civilizations fit exactly what I want"* ([foro](https://forums.ageofempires.com/t/two-useful-suggestions-regarding-the-new-civilizations-hoping-they-will-be-adopted/291043)). Un usuario de Xbox reporta que el control superpone teclas y apaga la producción automática ([foro](https://forums.ageofempires.com/t/queing-attack-move-on-controller-turns-off-villager-production-when-playing-viking/290988)).

## 25. Escoceses — vacas de las Tierras Altas y estanques monásticos

- **Cómo funciona.**
  - Las casas torre reemplazan a los puestos, dan población y producen vacas de las Tierras Altas (75 de comida y 25 de oro).
  - La vaca pasta junto a un arbusto de bayas y produce 30 de comida por minuto. El cupo empieza en 9 y suma 4 por cada monumento de las Tierras Altas.
  - El *Kirkman* (150 de oro) crea estanques: 40 de oro por minuto y +20 % de recolección a los trabajadores cercanos. El máximo es 1 por monumento de las Tierras Bajas, hasta 4 ([scots.json](https://github.com/aoe4world/data/blob/main/civilizations/scots.json); [highland-cattle](https://github.com/aoe4world/data/blob/main/units/scots/highland-cattle-1.json); [fishpond](https://github.com/aoe4world/data/blob/main/buildings/scots/fishpond-1.json)).
- **Atención: media.** Hay que proteger el ganado y asegurar los arbustos. La elección entre Tierras Altas y Bajas en cada edad decide la economía.
- **¿Única o variante?** Única: ganado que convierte un recurso agotable (las bayas) en ingreso continuo.
- **Parches.** Ninguno de balance todavía.
- **Recepción.** Se la elige mucho (12,8 %), pero gana poco: 46,4 % en general y 47,2 % en Conqueror. La queja concreta es que los aliados le comen las bayas al escocés, y se propone cercarlas como el corral malí ([foro, noviembre de 2026](https://forums.ageofempires.com/t/we-need-to-talk-about-scotch-highland-cattles/291306)).

---

## Tabla resumen

Las tasas son de 1v1 por ranking, primero en general y después en Conqueror, para el parche 17.0 ([API general](https://aoe4world.com/api/v0/stats/rm_solo/civilizations); [API Conqueror](https://aoe4world.com/api/v0/stats/rm_solo/civilizations?rank_level=conqueror)).

| Civ | Mecánica | Costo de atención | ¿Única o variante? | Recepción de los jugadores |
|---|---|---|---|---|
| Ingleses | Granjas baratas, bono cerca del molino, oro por granja (*Enclosures*) | Bajo | Variante (agricultura) | Fácil y confiable; 46,7 / 51,8 % |
| Franceses | Descuentos económicos, centro urbano rápido, comercio con elección de recurso | Bajo (medio con comercio) | Variante (descuentos y comercio) | Sin polémica; 49,1 / 51,7 % |
| Sacro Imperio | Prelado inspira aldeanos uno por uno (+40 %) | Alto | Única en forma | Tedioso, escala mal; 48,8 / 49,4 % |
| Rus | Recompensa de oro por caza; cabañas generan oro por árboles | Medio-alto (bajo en cabañas) | Única | Dividida, retocada muchas veces; 47,5 / 52,1 % |
| Mongoles | Ovoo extrae piedra sola; piedra = producción doble y tecnologías mejoradas; edificios empacables | Ovoo bajo; civ alta | Única | Techo de habilidad muy alto; 49,7 / **58,7 %** |
| Delhi | Tecnologías gratis pero lentas, aceleradas por eruditos | Medio (decisiones) | Única | Idea buena, se siente lenta; 48,1 / 49,8 % |
| Chinos | Dinastías; impuesto recogido a pie por funcionarios; *Supervise* | Alto | Única | Funcionarios tediosos y con errores; 45,6 / 50,1 % |
| Abasíes | Edad de Oro por densidad de edificios; subir de edad por alas | Bajo | Única en forma | Débil y "aburrida", rediseño discutido; 46,5 / 48,1 % |
| Otomanos | Escuelas militares: unidades gratis y continuas | Bajo | Única | "Aburrida, perezosa"; la peor del juego, 42,0 / 42,4 % |
| Malíes | Mina de pozo infinita, ganado comprado con oro, peajes | Medio | Única | Mejor identidad, balance flojo; 44,3 / 44,5 % |
| Bizantinos | Aceite de oliva como subproducto; cisternas y acueductos; mercenarios | Alto | Aceite único; cisterna, aura común | "Macro pesado", poco gratificante; 43,6 / 41,4 % |
| Japoneses | Granja-casa, fragua, oro↔piedra, centro urbano daimyo | Bajo | Variante | Buena en sabor; 48,8 / 46,9 % |
| Ayubíes | 8 alas a elección, Edad de Oro alternativa | Bajo (decisiones) | Variante | Poco jugada (1,1 %); 48,4 / 45,3 % |
| Jeanne d'Arc | Heroína que gana experiencia y desbloquea habilidades | Medio-alto | Única como progresión | Polarizante; 47,9 / 49,2 % |
| Orden del Dragón | Aldeanos dorados: +27 % de recolección, +40 % de carga, más caros | Bajo | Variante (estadísticas) | "Ni siquiera una civ"; 51,0 / **40,3 %** |
| Zhu Xi | Impuesto chino con funcionarios potenciados | Alto | Variante | Fuerte arriba; 51,9 / 56,5 % |
| Templarios | Peregrinos automáticos a sitios sagrados; madera sin campamento | Bajo-medio | Variante del comercio, automatizada | Positiva, la variante más elegida; 51,0 / 53,1 % |
| Lancaster | Mansiones con ingreso pasivo más aura por aldeano | Bajo → medio tras el rediseño | Única en forma | "Insanamente fuerte" al salir, hoy media; 50,3 / 51,7 % |
| Horda de Oro | Varios ovoos, corral de ovejas, producción por lotes, edictos | Medio | Variante | "Lo que debe ser una variante"; 49,8 / 43,6 % |
| Macedonios | Plata como subproducto de la minería; tecnologías más allá del nivel 3 | Bajo-medio | Recurso propio (como el aceite) | Mezcla temática criticada; 51,1 / 48,8 % |
| Sengoku | Yatai: ordeña comida sin agotarla, mejora el aura del mercado | Medio | Única | Casi nadie la juega (0,6 %); 45,2 / 41,9 % |
| Tughlaq | Elefante obrero (entrega móvil), tecnologías caras e instantáneas, gobernadores | Bajo | Variante (punto de entrega) | Concepto criticado, fuertes eficaces; 47,1 / 43,2 % |
| Jin | Aldeanos montados limitados; emisarios y tributarios; praderas de caballos | Medio | Única | Mixta (Steam 51 %); 54,4 / 50,5 % |
| Vikingos | Aldeanos automáticos gratis, casa larga con anexos, sagas | Muy bajo | Única | Gusta y domina; **57,8 %** con 19,7 % de elección; 52,6 % en Conqueror |
| Escoceses | Vacas que pastan bayas, estanques de oro del *Kirkman* | Medio | Única | Muy elegida, rinde poco; 46,4 / 47,2 % |

## Patrones para Raíces

1. **El ingreso pasivo apilable se rompe.** Lancaster, el ganado malí y las cabañas rus terminaron recortados o convertidos en algo que pide ubicación o tiene tope. La fórmula que sobrevive es "pasivo con tope y con decisión espacial": tope global en las cabañas, aura por aldeano en las mansiones, límite de yatai por edad, límite de estanques por monumento.
2. **La atención alta solo se tolera si el techo lo paga.** Chinos y Zhu Xi rinden en Conqueror; el Sacro Imperio y los bizantinos, con atención alta y retorno flojo, son los más criticados. Cuando corrigen la micro, los desarrolladores la automatizan: abadías cistercienses, depósitos de impuesto más cercanos, impuesto como porcentaje de lo entregado.
3. **"Lo pongo y funciona" no alcanza para dar identidad.** Otomanos y Orden del Dragón tienen atención mínima y son las civs peor vistas en identidad. Malíes y vikingos son igual de automáticos, pero obligan a decidir dónde y qué: veta, corral, anexo.
4. **El subproducto de una acción común es un buen patrón de recurso propio.** El aceite sale de la comida y la plata de la minería: el jugador no aprende una tarea nueva. Pero el recurso necesita un destino con identidad: los mercenarios, unidades ajenas, debilitaron a los bizantinos.
5. **Las variantes que solo tocan números no generan apego.** Las que cambian el verbo económico sí (Templarios, Jin, Horda de Oro).

El análisis de recepción por temas está en [`02-voz-de-los-jugadores.md`](02-voz-de-los-jugadores.md).
