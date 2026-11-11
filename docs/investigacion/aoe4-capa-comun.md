# Investigación — La capa común de Age of Empires IV frente a Proyecto Sur

Fecha: 2026-11-11. Documento de investigación, no de diseño: no cierra decisiones (eso va en `04-decisiones.md`) ni fija números (eso va en `data/`, D-008). Los números de AoE4 se citan solo como referencia de escala.

**Base de las cifras.** Salvo que se indique otra cosa, los números de AoE4 salen de los datos extraídos de los archivos del juego por aoe4world (`github.com/aoe4world/data`, último commit 2026-10-28, parche 17.x). Las variantes de la civilización inglesa sirven de referencia "genérica". Las reglas que no están en esos datos (victorias, mercado, comercio, sitios sagrados) salen de la wiki de Fandom (leída por su API) y de las notas de parche oficiales. Si algo no se pudo verificar, se dice.

**Proyecto Sur hoy** (H1 más lo que se agrega en esta sesión): `data/*.json`, `docs/05`, `docs/09` y `src/sim/`. La reparación figura "en curso": todavía no aparece en `src/sim/`.

---

## 1. Tabla de sistemas

Prioridad = cuánto pesa para que la base se sienta un RTS completo (no para el slice de una civilización). Encaje = si entra en los pilares de `01` tal cual (sí), si choca (no) o si sirve cambiando la forma (adaptar).

| Sistema | Cómo funciona en AoE4 (fuente) | Qué tiene Proyecto Sur hoy | Brecha | Prioridad | Encaje |
|---|---|---|---|---|---|
| **Centro urbano: producción y depósito** | Recibe todos los recursos, entrena aldeanos (50 alimento, 20 s) y exploradores, da 10 de población. Cuesta 400 madera y 300 piedra, tarda 165 s y tiene 2500 PV [aoe4world; Fandom TC] | `centro`: aldeanos (50 alimento, 18 s), depósito universal, 10 de población. Cuesta 400 madera y 300 piedra, tarda 120 s, 2400 PV | Casi ninguna. No produce explorador porque no existe | — | sí |
| **Centro capital y centros secundarios** | El centro inicial (capital) tiene 7000 PV y guarnición 15, dispara solo, detecta sigilo y cuenta como hito. Los secundarios tienen guarnición 8 y menos estadísticas, no disparan sin guarnición, no detectan sigilo, no cuentan como hito y desaparecen al destruirlos [aoe4world; Fandom TC] | Un solo tipo de `centro` con `"hito": true`: cada centro construido cuenta para la victoria por hitos | Falta distinguir capital de secundario. Hoy un segundo centro alarga la partida a la fuerza. Se relaciona con A-011 (mapuches sin capital) | alta | adaptar |
| **Guarnición y flechas** | Cada unidad en guarnición (aldeano, infantería, caballería) suma una flecha. Mejoras de emplazamiento: aspilleras (II), springald (III), cañón (IV), una por edificio. El update 17718 corrigió que cada plaza de guarnición active su arma [aoe4world; Fandom TC; notas 17718] | `guarnicion` y `flechas` en centro (15/2), torre (5/1) e hito de guerra (10/3). Las flechas escalan con la guarnición (esta sesión) | Faltan los emplazamientos como mejora por edificio. `vigias` es una mejora global | media | sí |
| **Campana** | "Ring the Town Bell": los aldeanos cercanos corren al edificio con lugar más cercano. "Return to work" los devuelve a su tarea; también existe "Seek shelter" por aldeano [Fandom TC, Villager] | Campana y toque de calma con `radio_campana`. La IA la usa | Ninguna relevante. Falta la orden individual de refugio | baja | sí |
| **Explorador** | Todos empiezan con uno, salvo mongoles (Khan) y malíes (Warrior Scout). Caballería ligera de 65 alimento con visión enorme: ve dentro de los bosques de sigilo, detecta unidades ocultas, caza a distancia y pastorea ovejas. Con *Professional Scouts* (II) carga presas [Fandom Scout; aoe4world] | No existe | Sin explorador no hay exploración ni pastoreo, y el sigilo no tiene contrajuego | **alta** | adaptar (sin caballo; ver §3) |
| **Fuentes de alimento variadas** | Arbustos (un molino al lado suma +100 de alimento), ciervos y jabalíes (cazados), ovejas que se pastorean, pesca y granjas infinitas de un aldeano cada una (37 madera) [aoe4world mill, farm; Fandom Farm, Scout] | Arbustos (150) y granja (60 madera, transitable, infinita) | Faltan la caza, el ganado pastoreable y la pesca. La apertura es casi única: arbusto y después granja | **alta** | adaptar (fauna y ganado de cada región) |
| **Campamentos de recolección** | Molino (alimento), aserradero (madera) y campamento minero (oro y piedra) a 50 madera cada uno; en cada uno se investigan las mejoras de ese recurso [aoe4world] | Un `deposito` universal de 75 madera con las mejoras de tala, cantería y riqueza | El depósito universal simplifica, pero quita decisiones: dónde poner cada campamento y qué mejorar | media | adaptar (o mantener universal y diferenciar por civilización) |
| **Mejoras económicas** | Wheelbarrow (+5 de carga y +15 % de velocidad, I), Forestry (×2 velocidad de tala, I), Survival Techniques (+15 % en caza, I), Horticulture y Specialized Pick (II), Textiles (+50 % de vida del aldeano, II), Precision Cross-Breeding (IV) [aoe4world] | `tecnologias.json`: tala ×2 niveles, cantería, riqueza, cestas de carga, riego ×2, mampostería y vigías | Equivalente en espíritu. Falta vida del aldeano y velocidad de aldeano | baja | sí |
| **Herrería / mejoras militares** | Herrería (II, 150 madera): +1 de daño cuerpo a cuerpo, +1 de daño a distancia, +1 de armadura cuerpo a cuerpo y +1 de armadura a distancia por edad. Daño y armadura por separado según tipo [aoe4world] | Armas ×3, escudos ×3, marcha y adiestramiento en el `cuartel` | Hay una sola armadura, sin separar cuerpo a cuerpo de distancia (ver fila "armaduras") | baja | adaptar (sin hierro para todos) |
| **Universidad / tecnologías tardías** | Universidad (450 madera; los datos actuales la ponen en edad IV). Military Academy (+33 % de velocidad de producción), Biology, Chemistry, Geometry, Incendiary Arrows, Siege Works [aoe4world] | No existe | Faltan las mejoras tardías que cambian de forma el ejército | baja | adaptar (por civilización) |
| **Mercado** | Edad II, 100 madera. Compra y venta en lotes de 100 o 500. Al inicio, 100 de alimento o madera se venden por 70 de oro y se compran por 130; la piedra, 90 y 170. **Los precios son globales**: se mueven con cada transacción de cualquier jugador y vuelven al valor base cada 30 s [Fandom Market] | No existe | Cuando sobra un recurso no hay cómo convertirlo en otro | **alta** | adaptar (riqueza no es oro) |
| **Comercio** | Los comerciantes (60 madera y 60 oro) van del mercado propio a un puesto neutral o a un mercado aliado. La ganancia crece con la distancia: ≈0,008x² + 0,1x de oro por viaje en un mapa micro, medido en el juego. Los puestos neutrales dan +20 % y no se pueden destruir [aoe4world trader; Fandom Trade] | No existe | Falta la riqueza tardía cuando se agotan los yacimientos. Pierde sentido el control de rutas | **alta** | adaptar (caminos incas, caravanas, yerba) |
| **Religiosos, reliquias y sitios sagrados** | El monje (III, 150 de oro) cura, convierte si lleva reliquia y captura sitios sagrados en 30 s. Cada sitio da 100 de oro por minuto. Una reliquia en un monasterio (máximo 3) da 80 de oro por minuto desde el parche 24916 [Fandom Sacred Site, Relic; notas 17718] | No existe. `05` pone la victoria por sitios sagrados en H2 | Falta la segunda condición de victoria y la riqueza de mitad de partida en el mapa | **alta** | adaptar (función ritual propia de cada civilización; las reliquias, con cuidado) |
| **Empalizada** | Edad I, 7 de madera por tramo, 1350 PV, se construye rápido. Se puede apoyar en recursos (árboles, minas), que pasan a funcionar como muro [aoe4world; Fandom Palisade] | No existe | No hay cómo cerrar la base ni encauzar al rival | **alta** | sí (tecnología común en América y África) |
| **Muralla de piedra, puertas y torres de muralla** | Edad II, 25 de piedra por tramo, 3000 PV. Solo la dañan el asedio, los edificios, los barcos y los elefantes, nada de antorchas. La infantería sobre la muralla recibe −25 % de daño a distancia y −50 % de daño de asedio, y gana +1 de alcance. Si cae un tramo, caen los dos vecinos. La puerta deja pasar a los propios y se cierra al rival. Mongoles, Horda de Oro y rus no tienen muralla de piedra [aoe4world; Fandom Stone Wall] | No existe | Falta la defensa fija de mitad de partida | media | adaptar (pukara, terrazas, recintos; sin muro para todos) |
| **Puesto avanzado (outpost)** | Edad I, 100 madera, 750 PV, guarnición 5, visión amplia, detecta sigilo. Se mejora con emplazamientos y con *Fortify* (+1000 PV) [aoe4world] | La `torre` (edad II) ya cumple la función defensiva | Falta una pieza barata de visión y control de mapa en la edad I | media | sí |
| **Fortaleza (keep)** | Edad III, 900 de piedra, 5000 PV, guarnición 15, arco con bono contra barcos. Desde el update 17718 se repara con piedra [aoe4world; notas 17718] | El hito de guerra cumple parte del papel | Falta una defensa pesada que el jugador pueda construir varias veces | baja | adaptar |
| **Reparación** | El aldeano repara edificios, asedio y barcos. Los hitos destruidos se pueden "reconstruir" reparándolos y solo con madera; vuelven a contar para la victoria al 100 %. Desde el update 17718, lo que cuesta solo piedra (muralla, keep, torre de muralla) se repara con piedra [Fandom Landmark; notas 17718] | En curso en esta sesión | No verifiqué la tasa de reparación ni si hay un retraso después de recibir daño | alta (ya en curso) | sí |
| **Asedio** | En el campo: la infantería construye **arietes** (200 madera, solo atacan edificios, llevan infantería adentro) y torres de asedio con *Siege Engineering* (II, 50 madera y 125 de oro). Taller de asedio (III): mangonel (área), springald (antiunidad y antiasedio), trebuchet, bombarda (IV). Todo soldado y todo aldeano lanza **antorchas** a los edificios (10 de daño fijo en el aldeano) [aoe4world; Fandom Siege Engineering, Battering Ram; aoe4labs] | Nada. El daño a edificios sale del triángulo con multiplicador reducido (`contadores.edificio` 20–45) | Las partidas se cierran tarde y por desgaste. No hay "momento de asedio" | **alta** | adaptar (galgas, incendio, cerco: `05`) |
| **Caballería** | Común a casi todas: jinete (II, contra distancia), caballero (III, pesado), arquero a caballo. El establo existe en 24 de 25 civilizaciones (II) [aoe4world] | No existe, a propósito (D-007: el triángulo es por función) | No es una brecha: es una decisión | — | no (ver §3) |
| **Hitos y avance de edad** | Dos hitos a elegir por edad; el otro se pierde. Costo para un inglés: II 400 de alimento y 200 de oro (190 s), III 1200 y 600 (220 s), IV 2400 y 1200 (250 s); los tiempos son para un aldeano. Los hitos son edificios con efecto propio y cuentan para la victoria. Varias civilizaciones rompen la regla: la Casa de la Sabiduría abasí, las dinastías chinas, la Tienda Dorada, las encomiendas templarias [aoe4world; Fandom Landmark] | `hito_economia` y `hito_guerra` (esta sesión). Costos en `edades.json`: II 400 de alimento y 200 de riqueza (60 s), III 1000, 600 y 200 de piedra (90 s), IV 1800, 1200 y 400 (120 s) | Ya hay dos opciones. Los tiempos son mucho más cortos que en AoE4, aunque es razonable con construcción lineal. Cuando entren los rendimientos decrecientes hay que revisarlos juntos | media | sí |
| **Influencia** | Algunos edificios proyectan un área que da bonos a los edificios de adentro, como la Casa de la Sabiduría, los cisternas bizantinos o los ovoo mongoles. Granjas y murallas no la reciben ni la propagan [Fandom Influence] | No existe | Es la herramienta típica de AoE4 para que la ubicación importe y para las mecánicas únicas | media | sí (encaja con la red de caminos inca) |
| **Rendimientos decrecientes de construcción** | Tiempo = base × 3 / (2 + constructores): cada aldeano extra aporta +33 %. Con 4 aldeanos se construye al doble de velocidad y con 10, al cuádruple [Fandom Villager; foro oficial] | Lineal (A-008 abierta) | Hoy avanzar de edad rápido es demasiado barato | **alta** | sí |
| **Niebla de guerra y sigilo** | Lo explorado deja ver el terreno pero no las unidades. Los **bosques de sigilo** ocultan a las unidades de adentro: solo el explorador, el halcón y algunos edificios ven dentro. El bosque bloquea la visión [ageofempires.com "Exploring the map"; Fandom Scout; gameskinny] | Todas las entidades tienen `vision`, pero no hay niebla (H2) | Bloquea las emboscadas mapuche y guaraní, el valor de la exploración y la lectura del rival | **alta** | sí |
| **Altura** | Según una guía de terceros (aoe4labs), en AoE4 la altura **no da bonos de daño**: solo afecta la visión (desde abajo no se ve hacia arriba). Un hilo del foro dice que el bono por altura se quitó después de la beta. **No encontré fuente oficial** | Mapa plano | Etiopía (bono en altura) y Tawantinsuyu (galgas) dependen de la altura | media | adaptar |
| **Armaduras y bonos por clase** | Armadura cuerpo a cuerpo, a distancia y contra fuego por separado. Bonos por clase: lancero +20 contra caballería, ballestero +10 contra pesados, arquero contra infantería ligera [aoe4world] | Una sola `armadura`; el triángulo va por multiplicador de función | El triángulo por función ya cubre lo esencial. Separar la armadura cuerpo a cuerpo de la de distancia haría más legibles las mejoras | baja | adaptar |
| **Carga y formaciones** | La caballería hace daño extra en el primer golpe después de moverse. Formaciones en línea, escalonada, etc. [aoe4labs, guía de terceros] | Ninguna de las dos | Le falta textura al combate y control para el jugador | media | adaptar (la carga, para el choque de cualquier tipo) |
| **Población** | 200 de población; la casa da 10 (50 madera) y el centro da 10. Mongoles y Horda de Oro empiezan con el máximo y sin casas [Fandom House; aoe4world] | `pob_max` 200, casa 10 (50 madera) | Ninguna | — | sí |
| **Condiciones de victoria** | Hitos: destruir todos los hitos enemigos, incluido el centro capital. Sitios sagrados: tenerlos todos durante 10 min. Maravilla: defenderla 15 min; costo de 5000 a 8000 de cada recurso según el mapa. Rendición. Una victoria por dominio de respaldo [Fandom Victory, Wonder]. Una guía dice 30 min para la maravilla: **dato contradictorio**, me quedo con los 15 de la wiki | Hitos y rendición (H1) | Faltan los sitios sagrados y la maravilla (`05` los tiene en H2) | alta (sitios) / baja (maravilla) | adaptar |
| **Naval** | Muelle, pesqueros, barcos de guerra y comercio marítimo en casi todas [aoe4world] | No existe | A-006: fuera hasta después de H6 | baja | adaptar (canoas guaraníes) |
| **Mapa y control de mapa** | Recursos repartidos por el mapa (oro, piedra, ciervos, jabalíes), puestos de comercio, sitios sagrados, reliquias y bosques de sigilo. El control de mapa se pelea por esos puntos [Fandom Feudal Age, Trade, Sacred Site] | Mapa simétrico por semilla con árboles, arbustos, rocas y yacimientos | Faltan objetivos neutrales que valga la pena disputar | alta | sí |

---

## 2. Qué falta para que la base se sienta un RTS completo (en orden)

El criterio es qué desbloquea más decisiones por unidad de trabajo, respetando "pocos sistemas, profundos y dirigidos por datos" (pilar 5).

1. **Niebla de guerra y explorador.** Sin niebla no hay información que conseguir, ni exploración, ni engaño, ni emboscada. Es requisito de dos de las cuatro civilizaciones (mapuches y guaraníes con sigilo en bosque, `05`) y del contrajuego al sigilo. La simulación ya guarda `vision`. El explorador es la unidad que le da sentido: rápido, frágil y con mucha visión. En AoE4 es la única unidad que ve dentro del bosque de sigilo.
2. **Asedio mínimo: ariete construido en el campo más antorchas.** Hoy las partidas terminan por desgaste: en la semilla 1234 el ganador apareció a los 26:40. En AoE4 el ariete de la edad II, construido por la infantería, es la pieza que vuelve letal un ataque temprano contra el centro (Fandom, Battering Ram). Basta con un módulo de "edificio-unidad construido por soldados" y la regla de que las antorchas hacen daño fijo a edificios. Las armas de asedio de cada civilización (galgas, incendio) vienen después, con el mismo módulo.
3. **Empalizada y puerta (después, muralla).** Es la respuesta defensiva barata a la presión temprana. En la semilla 7, cinco unidades a los 4:00 decidieron la partida (`09`), y sin empalizada esa presión puede volverse dominante y romper el test de las tres aperturas. Además, el apoyo en recursos (árboles y minas) hace que el terreno importe.
4. **Rendimientos decrecientes de construcción (cerrar A-008).** Cambiar a la fórmula 3/(2+n) es barato y cambia todo el equilibrio entre avance rápido y economía. Hay que hacerlo antes de ajustar los tiempos de hito, que hoy son entre 3 y 4 veces más cortos que en AoE4.
5. **Más fuentes de alimento: caza y ganado pastoreable.** Abren aperturas distintas (cazar lejos o quedarse en arbustos, pastorear o granjear) y le dan trabajo al explorador. Es la base natural de mecánicas propias como las llamas o el ganado del malón mapuche. Cada fuente sería un tipo más en `recursos.json` con un comportamiento: estática, que huye, que ataca o que sigue a una unidad.
6. **Mercado y comercio con puestos neutrales.** Resuelven el exceso de un recurso, crean una fuente de riqueza tardía para cuando se agotan los yacimientos y vuelven valioso el control de rutas, que es la base del chasqui y los tambos incas y de la yerba guaraní. La ganancia cuadrática con la distancia premia rutas largas y por eso expuestas, una decisión de riesgo muy de AoE4.
7. **Sitios sagrados y una unidad ritual que los captura.** Es la segunda condición de victoria y una fuente pasiva de riqueza (100 por minuto por sitio en AoE4). Obliga a salir de la base y rompe los empates defensivos, según el análisis de la wiki. Ya está prevista en `05` para H2.
8. **Centro capital distinto de los secundarios.** Si el centro capital es hito y los secundarios no, el segundo centro vuelve a ser una apuesta económica, no una vida extra. También aclara A-011: los lof mapuches pueden ser "centros secundarios que sí cuentan" como rasgo propio de la civilización.
9. **Puesto de visión de edad I y emplazamientos.** Control de mapa barato y mejoras por edificio en lugar de globales, como hoy `vigias`.
10. **Textura de combate: carga del choque, armadura a distancia separada de la de cuerpo a cuerpo, formaciones básicas.** Aportan legibilidad y control, pero el triángulo ya funciona sin ellas.
11. **Baja prioridad por ahora:** maravilla, universidad o tecnologías tardías, naval (A-006), keep construible.

---

## 3. Qué NO conviene copiar de AoE4 y cómo adaptarlo

| Elemento de AoE4 | Por qué no se copia tal cual (pilar) | Adaptación sugerida |
|---|---|---|
| **Oro y minas de oro como fuente principal**; mercado que compra y vende contra oro | D-006 / "riqueza no es oro": la riqueza es tejido, ganado, yerba o tributo según la civilización | El mercado intercambia contra **riqueza** con precios globales que se mueven (la mecánica de AoE4 es buena y abstracta). Cada civilización conserva su vía propia de riqueza. Los yacimientos neutrales quedan como red de seguridad (`05`), no como centro de la economía. Una civilización sin mercado (en AoE4, Sengoku no lo tiene) puede tener trueque o tributo en su lugar |
| **Explorador a caballo para todos** | "Sin caballo para todos" (D-007, adopción en `02`) | Explorador **a pie** por función: rápido, frágil, con mucha visión y capaz de ver en el bosque. Para Tawantinsuyu puede ser el chasqui (más rápido sobre caminos). Para mapuches, a caballo solo después de la adopción. Etiopía tiene caballería desde la edad I (ficha) |
| **Establo y caballería como línea común** | Igual que arriba; el triángulo es por función | El **choque** puede ser infantería de asalto o caballería según la civilización. La "carga" se modela como bono del primer golpe para toda unidad de choque, no para "caballería" |
| **Herrería con mejoras de metal para todos** | Función antes que forma: no todas usaban hierro | Mantener las mejoras en el edificio militar o en uno propio de cada civilización (tejidos acolchados, porras de bronce, etc.; **[verificar]** cada material en su ficha). El efecto común (+daño, +armadura) sigue igual |
| **Murallas de piedra y castillo (keep) como defensa estándar** | Función antes que forma: "emboscada en vez de murallas" | Empalizada común (existe en casi todo el mundo). La defensa pesada es por civilización: pukara y terrazas incas, emboscada mapuche, monte guaraní, recintos etíopes **[verificar]**. En AoE4 mongoles, Horda de Oro y rus ya viven sin muralla de piedra: es un precedente válido |
| **Monje cristiano, monasterio y reliquias europeas** | Historia desde adentro; no es decorado | La **función** (capturar sitios, curar, convertir) es común. La unidad y el edificio son propios de cada civilización (especialista ritual con nombre en su lengua **[verificar]**). Las **reliquias portables** hay que tratarlas con cuidado: una huaca andina es un lugar, no un objeto transportable **[verificar con fuente]**. Conviene usar solo sitios sagrados o "bienes rituales" que cada ficha defina |
| **Trebuchet, bombarda y pólvora para todos en la edad IV** | Adopción por captura, comercio o alianza (`02`) | Asedio común mínimo: ariete o tronco, antorchas e incendio. El asedio pesado entra por mecánica propia (galgas desde altura) o por adopción. La pólvora nunca se regala por avanzar de edad |
| **Edades con nombre europeo (feudal, castillos, imperial)** | Historia desde adentro | Ya resuelto: nombres y periodización por civilización (`02` y fichas) |
| **Centro capital único como "corazón" que define la derrota** | Mapuches: "no hay capital que tomar" (A-011) | Capital como hito por defecto, más un parámetro de módulo "los asentamientos cuentan como hito" para civilizaciones descentralizadas. Precedente en AoE4: las fortalezas templarias funcionan como hitos (aoe4world, Knights Templar) |
| **Maravilla como edificio monumental europeo o asiático** | Función antes que forma | Victoria por "obra mayor" con forma propia de cada civilización; para los mapuches podría ser una condición equivalente (¿parlamento?). Baja prioridad. Recordar que `05` prohíbe victorias exclusivas: tiene que ser la misma condición con otra forma |
| **Barcos como capa completa** | Alcance de una persona (A-006) | Solo canoas de transporte fluvial cuando lleguen los guaraníes |
| **Cantidad de mecánicas por civilización** (las de 2025 y 2026 suman 6 a 10 sistemas propios cada una) | Presupuesto fijo de `01`: 1+1+1+1 mecánicas y 2–3 unidades únicas | Usar AoE4 como catálogo de ideas, no como medida del volumen. Las civilizaciones originales de 2021 son mejor referencia de tamaño |

---

## 4. Rarezas de AoE4 que funcionan (ejemplos verificados)

Todas salen de los textos del juego en `aoe4world/data` (archivos `civilizations/*.json`), salvo que se cite otra fuente. Vikingos y escoceses salieron el 2026-10-29 con *Raiders of the North* (gematsu, notebookcheck), así que su balance puede cambiar pronto. Para cada una: la regla, por qué funciona y a qué civilización de Proyecto Sur le sirve de inspiración.

| Civilización (AoE4) | Rareza | Por qué funciona | Inspiración para |
|---|---|---|---|
| **Mongoles** | Todos los edificios se desarman y se vuelven a armar en otro lugar. Empiezan con la población máxima y sin casas. **Saqueo**: incendiar o destruir edificios enemigos en construcción da +25 de alimento y +25 de oro. El *Ovoo* sobre piedra permite producir unidades dobles pagando con piedra | La economía y la defensa cambian de raíz, pero siguen dentro de los mismos recursos | Guaraníes (tekoha mudable), Etiopía (campamento real móvil), mapuches (malón: riqueza por dañar) |
| **Malíes** | **Pit Mine** sobre vetas de oro: genera oro sin agotar el yacimiento. Ganado producido en el molino. Unidades que se ocultan para emboscar. El centro urbano cuesta oro en vez de piedra | Una fuente de riqueza propia que convive con la común; "cinco unidades únicas con otra lectura del sistema de contadores" | Guaraníes (yerba como fuente que no se agota en el lugar), emboscada |
| **Rus** | **Recompensa de caza**: cazar animales da oro, y al llegar a 100, 400 y 1000 puntos se desbloquean bonos de alimento y de las cabañas de caza. Las cabañas generan oro según la cantidad de árboles cerca | Una actividad común (cazar) se vuelve vía de riqueza, con umbrales que crean metas | Cualquier civilización con "riqueza no es oro": riqueza que sale de una actividad propia |
| **Sultanato de Delhi** | **Toda la tecnología es gratis pero muy lenta**. Los eruditos en guarnición la aceleran y las investigaciones se pueden pausar | Cambia el recurso escaso: de recursos a tiempo y eruditos | Tawantinsuyu (mita: trabajo por turnos en vez de recursos) |
| **Abasíes y ayubíes** | Avanzan de edad **agregando alas a un solo edificio**, sin aldeanos. La **Edad de Oro** se gana construyendo dentro de la influencia de la Casa de la Sabiduría: los umbrales son 10, 20, 30, 50 y 75 edificios | La densidad y la ubicación de la base se vuelven el motor económico | Tawantinsuyu (red de caminos: bono por edificios conectados) |
| **Chinos** | Si construye los **dos** hitos de una edad, entra en una **dinastía** con unidades y bonos propios. Los funcionarios imperiales recorren la base cobrando un impuesto en oro que generan la producción y las entregas | Rompe la regla de "un hito por edad" con un costo claro; el impuesto se cobra caminando | Etiopía (tributo cobrado por una unidad que recorre las tierras asignadas) |
| **Otomanos** | **Escuelas militares** que producen unidades sin parar y sin costo. Puntos de visir según lo que se gasta, canjeables por bonos | El ejército pasivo cambia el ritmo y castiga al rival que no presiona | Mapuches (asamblea: puntos de prestigio para elegir toqui) |
| **Bizantinos** | **Aceite de oliva** como recurso extra para mercenarios. **Cisternas y acueductos** forman una red con modos que el jugador elige (producción, investigación o defensa) | Una red de infraestructura con elecciones activas | Tawantinsuyu (qollqas y caminos como red con modos) |
| **Orden del Dragón** | Aldeanos dorados (+27 % de recolección, +40 % de carga) y tropas mucho más fuertes **que ocupan el doble de población** | Calidad contra cantidad con una sola regla legible | Cualquier civilización con pocas unidades de élite |
| **Horda de Oro** | Las unidades **siempre se reclutan en lotes**. Empieza con población máxima. Avanza de edad eligiendo bonos en la Tienda Dorada | Un ritmo de producción distinto, en oleadas | Mapuches (leva por convocatoria) |
| **Caballeros Templarios** | Avanzan de edad en el centro eligiendo **encomiendas** (aliados europeos) que desbloquean unidades. Los **peregrinos generan oro yendo a sitios sagrados**. Las fortalezas son hitos pero se pueden destruir del todo | Avanzar es elegir aliados; los sitios sagrados son también una ruta económica | Arco tardío por **alianza** (`02`), guaraníes (misión o monte, A-004) |
| **Jin** | Hasta 20 **aldeanos montados** rápidos. **Emisarios** que establecen tributarios (dan alimento) y sobornan soldados enemigos | Economía con movilidad y diplomacia dentro de la partida | Etiopía (tributo), Tawantinsuyu (anexión de grupos) |
| **Tughlaq** | **Elefantes de trabajo** que son depósitos móviles. **Toda la tecnología es más cara pero se investiga casi al instante**. Gobernadores elegidos en los fuertes | Invierte la relación entre tiempo y costo; el depósito móvil premia la expansión | Guaraníes y Etiopía (base móvil) |
| **Vikingos** (2026) | Los centros **reclutan aldeanos solos y gratis** hasta un tope que suben las casas largas (+10 cada una). **Sagas**: misiones que dan bonos permanentes. La infantería se cura comiendo de fuentes de alimento (arbustos, ciervos) | Elimina la micro de producir aldeanos y cambia la decisión a "cuántas casas largas"; las misiones guían sin prescribir un orden | Mapuches (crecer por lof), cualquiera con "metas" en vez de árbol de tecnologías |
| **Escoceses** (2026) | El ganado de las tierras altas **pasta solo en los arbustos**. Ghillies con sigilo **en terreno abierto**. Las casas-torre reemplazan a los puestos, producen ganado y dan población | Alimento pasivo atado a un lugar defendible | Tawantinsuyu (llamas; **[verificar]**), sigilo |
| **Sacro Imperio** | **Reliquias en puestos, torres y fortalezas** que dan bonos defensivos y económicos. El prelado "inspira" a los aldeanos (+40 % de recolección durante 30 s) | Le da otro uso a un objeto común | Sitios sagrados con usos propios |
| **Japoneses** | Entregar oro da piedra extra y al revés. La forja también es depósito de oro y piedra | Vincula dos recursos con una regla simple | Ejemplo de regla única de una línea |
| **Ingleses** | *Network of Castles*: centros, puestos, torres y fortalezas dan +20 % de velocidad de ataque a las unidades cercanas cuando hay enemigos | La defensa es un aura, no un muro | Bono defensivo de terreno propio |
| **Dinastía Macedonia** | Plata extraída del oro y la piedra como moneda de tecnologías únicas | Un recurso propio derivado de los comunes | Tejidos de Tawantinsuyu como riqueza derivada de la mita |

**Patrones que se repiten en las rarezas que funcionan:**
- Se apoyan en un sistema común (caza, hitos, población, sitios sagrados, influencia) y le cambian **una** regla, en lugar de inventar un subsistema aislado. Eso coincide con el "test del módulo" de `01`.
- Cambian **qué es escaso**: tiempo (Delhi), población (Orden del Dragón), ubicación (abasíes), distancia (comercio, peregrinos).
- Se leen en una frase: "no construye casas", "la tecnología es gratis pero lenta".
- Implicación para Proyecto Sur: cuanta más capa común exista (caza, sitios sagrados, comercio, influencia), más baratas salen las rarezas, porque cada una es un parámetro sobre un módulo existente.

---

## 5. Fuentes

**Datos del juego (fuente principal de números)**
- aoe4world, *AoE4 World Data* (extraído de los archivos del juego, último commit 2026-10-28, parche 17.x): https://github.com/aoe4world/data. Se usaron `buildings/all-unified.json`, `units/all-unified.json`, `technologies/all-unified.json` y `civilizations/*.json`.
- aoe4world Explorer (la misma base, en web): https://aoe4world.com/explorer

**Wiki (reglas; leída con la API de MediaWiki)**
- Town Center: https://ageofempires.fandom.com/wiki/Town_Center_(Age_of_Empires_IV)
- Landmark: https://ageofempires.fandom.com/wiki/Landmark
- Victory: https://ageofempires.fandom.com/wiki/Victory
- Wonder: https://ageofempires.fandom.com/wiki/Wonder_(Age_of_Empires_IV)
- Sacred Site: https://ageofempires.fandom.com/wiki/Sacred_Site
- Relic: https://ageofempires.fandom.com/wiki/Relic_(Age_of_Empires_IV)
- Market: https://ageofempires.fandom.com/wiki/Market_(Age_of_Empires_IV)
- Trade: https://ageofempires.fandom.com/wiki/Trade_(Age_of_Empires_IV)
- Villager (fórmula de construcción): https://ageofempires.fandom.com/wiki/Villager_(Age_of_Empires_IV)
- Scout: https://ageofempires.fandom.com/wiki/Scout_(Age_of_Empires_IV)
- Influence: https://ageofempires.fandom.com/wiki/Influence_(Age_of_Empires_IV)
- Siege Engineering: https://ageofempires.fandom.com/wiki/Siege_Engineering
- Battering Ram: https://ageofempires.fandom.com/wiki/Battering_Ram_(Age_of_Empires_IV)
- Palisade Wall: https://ageofempires.fandom.com/wiki/Palisade_Wall_(Age_of_Empires_IV)
- Stone Wall: https://ageofempires.fandom.com/wiki/Stone_Wall_(Age_of_Empires_IV)
- Farm: https://ageofempires.fandom.com/wiki/Farm_(Age_of_Empires_IV)
- House: https://ageofempires.fandom.com/wiki/House_(Age_of_Empires_IV)
- Feudal Age: https://ageofempires.fandom.com/wiki/Feudal_Age_(Age_of_Empires_IV)

**Oficiales**
- Notas del Season Two Update 17718 (12 de julio de 2024): https://www.ageofempires.com/news/age-of-empires-iv-update-17718/
- *Learn to play: Exploring the map*: https://www.ageofempires.com/learn-to-play/expanding-your-empire-xbox/
- *Dynasties of the East* (expansión del 4 de noviembre de 2025): https://www.ageofempires.com/games/age-of-empires-iv/dynasties-of-the-east/
- Preguntas frecuentes sobre expansiones: https://support.ageofempires.com/hc/en-us/articles/18699125259540-Age-of-Empires-IV-Expansions-FAQ

**Prensa (fechas de expansiones)**
- *Raiders of the North* anunciado (vikingos y escoceses): https://www.gematsu.com/2026/06/age-of-empires-iv-anniversary-edition-expansion-raiders-of-the-north-announced
- Fecha del 29 de octubre de 2026: https://www.notebookcheck.net/Age-of-Empires-4-Raiders-of-the-North-is-set-for-October-29.1432160.0.html

**Guías y foros (menor confianza; se usaron solo donde se indica)**
- Progresión de edades: https://guildorder.com/games/aoe4/wiki/age-progression-landmarks
- Fundamentos de combate (altura, antorchas, carga, formaciones): https://aoe4labs.pages.dev/mechanics.html
- Bosques de sigilo: https://www.gameskinny.com/v4jaa/age-of-empires-4-stealth-forests-explained
- Velocidad de construcción, foro oficial: https://forums.ageofempires.com/t/villager-build-speed-training-time-of-units-and-technology-timings/35871

**Cosas que no pude verificar con fuente**
- Si la altura da algún bono de combate en AoE4 (una guía de terceros dice que no; no hay fuente oficial).
- La tasa exacta de reparación y si existe un retraso para reparar después de recibir daño.
- La fórmula oficial del comercio: la wiki da una aproximación medida en el juego y advierte que las fórmulas del editor no coinciden.
- El temporizador de la maravilla: la wiki dice 15 min y una guía dice 30. Me quedo con los 15 de la wiki.
- La cantidad de alimento de ovejas, ciervos y jabalíes, y las tasas de recolección de AoE4: no las consulté, porque no hacían falta para la comparación.
- La universidad aparece con edad mínima IV en los datos actuales; no busqué en qué parche cambió.
