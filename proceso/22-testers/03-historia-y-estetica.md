# 03 · Tester: historia y estética

## 1. Quién soy y qué probé

Jugué las campañas de AoE4 por los documentales y por cómo suena y se ve cada civilización: los mongoles que arman la ciudad sobre ruedas, los rus con sus iglesias de madera, la voz que cambia de idioma al pasar de edad. Acá busqué lo mismo: que cada pueblo se vea, suene y se juegue distinto, que los nombres sean fieles y que el paisaje cuente algo.

Leí:
- `docs/00-indice.md`, `docs/09-estado.md` y `docs/07-arte-y-ui.md`;
- las seis fichas en `data/civs/*.json` y la de `invasores.json`;
- las seis campañas en `data/campanas/*.json` (introducciones, epílogos, fuentes, diálogos y rivales);
- `docs/campanas/README.md` y `docs/investigacion/*.md` (para contrastar nombres);
- `assets/audio/musica/README.md`, `src/game/audio.gd` (qué música suena con cada pueblo) y la lista de `assets/audio/`;
- `assets/generados/` y `proceso/19-arte-y-sonido`.

Capturas (todas con `godot --path . -- …`):

| Qué | Argumentos |
|---|---|
| Base de cada pueblo, de cerca | `--demo=base --civ=<civ> --cam=b12,b9,9 --shot=… --shot-at=3` |
| Base de cada pueblo, cámara de la demo | `--demo=base --civ=<civ> --shot=… --shot-at=3` |
| Edad III, IA pacífica a ×8 hasta el minuto 19 | `--aivai --civ=ayutthaya --rival=tawantinsuyu --estilo=pacifica --terreno=delta --seed=7 --speed=8 --shot-at=1140 --cam=b6,b6,20` (y lo mismo con `etiopia`/`mesetas`/`seed=3` y `tawantinsuyu`/`altiplano`/`seed=5`) |
| Menú y campañas | `--menu --shot=…` y `--menu --abrir=campanas --shot=…` |
| Relato antes de una misión | `--menu --abrir=intro --shot=…` |
| Misiones | `--campana=palmares --mision=0 --shot-at=1` y `--campana=etiopia --mision=0 --nofog --speed=4 --shot-at=250` |
| Panel del pueblo | `--civ=palmares --terreno=sierra --panel=pueblo --shot-at=4` |
| Otros | `--demo=batalla --civ=ayutthaya --rival=palmares --shot-at=9`, `--civ=guaranies --terreno=selva --cam=b6,b6,26` |

## 2. Lo que me gustó

- **Las campañas están muy bien escritas.** Cada una tiene un narrador de adentro con oficio y lugar: el khipukamayuq de Tinta, la tejedora de Purén que anuda el *pron*, el escribano guaraní del cabildo de San Miguel, el escriba de Gondar, la mujer nacida en Palmares, el escribano del Phra Khlang en Thonburi. Ningún narrador es un cronista europeo. Para mí es lo mejor del juego.
- **No hay buenos y malos de cartón.** Los cañaris y chachapoyas que pelean con Pizarro "tenían cuentas pendientes con los incas, y nadie se las había pagado"; Mateo Pumakawa del lado del rey; Cucaú contado desde quien queda libre y ve a su marido devuelto ("Ninguno de los dos estaba del todo equivocado. Por eso dolió tanto"). Tiene el tono de los mejores documentales de AoE4, y es más honesto.
- **Las fuentes están en cada misión** (Betanzos, Titu Cusi, Lara, Thornton, Avellaneda y Quarleri, Henis, crónicas reales etíopes) y la investigación marca con `[verificar]` lo que es de confianza media, como el *Dumbi* de 1645.
- **La mecánica cuenta la historia.** La corte etíope que se empaca y se muda, el gult que rinde sin aldeanos, el lof sin capital, la roza que se vuelve yerbal, la gente de Palmares que llega por la fama en lugar de entrenarse, los barrios japonés y portugués de Ayutthaya, la mit'a que se teje en cumbi. Es asimetría con raíz, como los mongoles o los abasíes de AoE4.
- **Nombres en la lengua propia**: Runa, Kallanka, Qollqa, Qhapaq Ñan; Che, Werken, Weichafe, Ruka; Ava, Oga guasu, Kokue; Gäbbar, Chewa, Tukul, Färäs bet; Paiol, Olaria, Casa de palha; Phrai, Wang, Ruean, Khlang din.
- **Los modelos de Meshy que ya están se ven muy bien** (captura 1): el palacio de techos escalonados de Ayutthaya, la tienda real roja y blanca de la corte etíope, la kancha de piedra con nichos y techo de paja del Tawantinsuyu, el tukul redondo, la ruka mapuche y la oga guaraní. El camino inca empedrado de la edad III (captura 5) es lo que más "se siente lugar" en todo lo que vi.
- **Las láminas pintadas** de las campañas y del relato (captura 9) dan clima: palmeras, cerca con estrepes, fraguas humeando.
- **El terreno *mesetas*** con tierra roja (captura 6) ya se siente Etiopía.
- **El panel del pueblo (F1)** explica el motor propio, fortalezas, flojeras y hitos en un vistazo.

## 3. Lo que le falta a cada pueblo para sentirse tan vivo como una civ de AoE4

### Lo que falta en todos

1. **El cambio por edad no existe todavía.** Comparé la edad I con la edad III de Ayutthaya, Etiopía y Tawantinsuyu (capturas 1, 4, 5 y 6): el centro, las casas y las granjas son idénticos. En AoE4 el salto de edad se ve desde el minimapa: madera → piedra, más altura, otros techos. `07-arte-y-ui.md` ya lo pide; hoy es la deuda que más le quita a la fantasía.
2. **El ejército es una maqueta blanca.** Aldeanos, el hondero inca, el arquero guaraní, el flecheiro y el jinete noble tienen modelo; el resto son peones de arcilla blanca con una banda de color (capturas 3 y 7). Al lado del elefante de Meshy, el contraste es enorme. En una batalla no se distingue un chewa de un weichafe.
3. **No hay voces.** Ni una línea. En AoE4 la mitad de la identidad está en la respuesta del aldeano al clic, en su idioma y cambiando con la edad. `07` lo tiene como pendiente desde H3. Con frases cortas grabadas por hablantes (quechua, mapudungun, guaraní, amhárico o ge'ez, portugués con kimbundu, tailandés) el juego cambia de categoría.
4. **Los hitos no tienen arquitectura.** Wat Mahathat, Qorikancha, el Recinto de Gondar, Aty guasu, el Macaco y el Parlamento son las "maravillas" de cada pueblo y hoy son maquetas parecidas entre sí (en la captura 1, el fortín almenado del Tawantinsuyu y el de Etiopía son casi el mismo). Son lo primero que pondría en la cola de Meshy después de los centros.
5. **No hay maravilla ni momento final.** AoE4 cierra cada civ con una maravilla propia. Acá hay candidatos que se cuentan solos: Sacsayhuamán u Ollantaytambo, un gran *ngillatun* o un *trawün*, la iglesia de San Miguel o un *tekoha* con *oga guasu* monumental, Fasil Ghebbi, la Cerca real de la Barriga, Wat Phra Si Sanphet.
6. **Sonido del mundo genérico.** El ambiente son dos pistas (pájaros y viento) para los trece terrenos: el altiplano, la selva, el delta de arrozales y la sierra de Palmares suenan igual. Tampoco hay sonidos por pueblo: el aviso de edad, la campana y los golpes son los mismos para todos.
7. **Música floja y pareja.** En el menú siempre suena la flauta de pan, que es andina, aunque elijas Etiopía. Faltan pistas de paz o de combate en casi todos (tabla abajo). En AoE4 la música cambia por edad y se vuelve más rica; acá no.
8. **No hay "documentales" ni relatos en el juego.** Los textos son excelentes pero son solo texto sobre una lámina. Pido un relato entre misiones con narración en voz, mapas animados o imágenes de piezas reales (khipus, tejidos *cumbi*, manuscritos etíopes iluminados, el diario de Blaer, el sello siamés), y una galería que se desbloquee al ganar, como los "Hands on History".
9. **Los terrenos no cuentan dónde estás.** *Altiplano* sigue verde con flores (captura 5), *selva* arranca en pradera abierta, *sierra* para Palmares tiene coníferas y pocas palmeras.

### Pueblo por pueblo

| Pueblo | Lo que ya tiene | Lo que le falta |
|---|---|---|
| **Tawantinsuyu** | Kancha con nichos (Meshy), camino empedrado, hondero, dos pistas andinas | Andenes que se vean como terrazas en la ladera (hoy son la misma granja plana); kallanka, qollqas en hilera y ushnu con forma propia; torre y fortín **sin almenas europeas** (hoy el pukara parece una torre de ajedrez y el fortín es un castillo almenado); quipus o tocapus en la interfaz; pututu como sonido de alarma; quena, siku y wankar en combate; voces en quechua |
| **Mapuches** | Ruka y lof (Meshy), jinete, pifilkas | Música de paz (kultrun, trutruka, kultrun con *ül*); el corral y el ganado como corazón visible de la base; el rewe (el tronco escalonado) como hito real en el mapa; boleadoras y lanzas largas en los modelos; voces en mapudungun; un *trawün* o parlamento como momento final |
| **Guaraníes** | Oga de paja (Meshy), arquero | Música propia (hoy una "selva genérica"); mbaraka y takuapu; la roza que se queme y se vea el yerbal; el monte cerrado alrededor de la aldea (el pueblo vive en el monte y el mapa lo pone en el pasto); un camino visual de edad de *tekoha* a *tava*: la iglesia de la misión aparece entera desde la demo de edad I (captura 1) sin transición; voces en guaraní |
| **Etiopía** | Tienda real (Meshy), tukul, jinete noble, tierra roja | **Ninguna música** (C-24); la iglesia circular con cruz es un hongo marrón (captura 6): pide un *bete* redondo con techo cónico o, más tarde, la iglesia excavada; la corte en marcha como caravana de tiendas, no como un ícono; el castillo de Gondar con piedra y torres redondas solo en la edad IV; *kebero* y *washint*; voces en amhárico (con ge'ez para el clero) |
| **Palmares** | Casa de palha (Meshy), flecheiro, berimbau | Las fraguas con humo (es su mecánica y su relato) sin modelo; la cerca con estrepes que se vea peligrosa; palmeras y mata atlántica en lugar de pinos; música con raíz centroafricana (*ngoma*, *marimba*, *urucungo*) en vez de ijexá y capoeira, que son posteriores; voces en portugués con palabras kimbundu (*gana*, *nganga*, *kilombo*) |
| **Ayutthaya** | Palacio, casa, elefante (Meshy), pieza de corte de 1934 | Arrozales con agua (hoy son losas verde agua secas, captura 4); los barrios japonés y portugués con su arquitectura (es su gancho histórico y hoy son galpones); prang y chedi para el wat; *piphat* real (ranat, khong wong, pi nai) en lugar del xilofón genérico; nombres propios para arquero, lancero, explorador y cuartel (son los únicos genéricos del juego); voces en tailandés |

## 4. Respeto, fidelidad y nombres dudosos

1. **Los rivales no europeos son "Invasores".** Adal (Etiopía 1–3), los ejércitos Toungoo y Konbaung de Birmania (Ayutthaya 1, 3 y 4) usan la facción `invasores`: edades *Hueste, Fuerte, Gobernación, Virreinato*, unidades *Rodelero, Ballestero, Piquero* y fuerte de piedra europeo. En el marcador sale "Rojo · Invasores" (captura 7). El sultanato de Adal con Rodeleros y Virreinato es un error de fidelidad, y meter a un vecino musulmán o a un reino birmano en la misma caja que la conquista colonial es injusto con ellos. Pido al menos: el nombre del rival de la misión en el marcador, y a mediano plazo dos facciones de campaña más (Adal, con caballería y mosqueteros otomanos; Birmania, con elefantes).
2. **Los rivales indígenas usan la cultura del jugador.** La "Confederación chanka" y los "Cayambes y caranquis" juegan como Tawantinsuyu (llaqta, kallanka, runa); los "auxiliares tupí" de la bandeira, como guaraníes; los cañaris, como incas. Es justo lo contrario de lo que cuentan los textos. Con cambiar nombres y colores alcanza para empezar.
3. **"Inkarri" como edad IV del Tawantinsuyu.** El mito de Inkarrí es colonial tardío y se documenta sobre todo en el siglo XX; la edad cubre Vilcabamba (1537–1572). Lo entiendo como guiño al arco de la campaña, pero conviene explicarlo en el panel o cambiarlo por *Vilcabamba* o *Neo Inka*. Además, el Qorikancha como hito de esa edad es anacrónico: es obra de Pachakutiq.
4. **El orden de las edades guaraníes contradice la investigación.** `docs/investigacion/guaranies.md` propone *Tekoha → … → Tava → Mbororé*; el dato tiene *Tekoha → Amundá → Mbororé → Tava*. Que la última edad guaraní sea el pueblo de misión sugiere que la meta es "reducirse". Pido revisar el orden o explicar la elección.
5. **"Espingardeiro de resgate" (Palmares).** En la investigación, *resgate* es el comercio clandestino con los moradores. Pero en el portugués colonial *resgate* era, ante todo, la compra de personas esclavizadas en África. Para un pueblo de gente que escapó de eso, el nombre puede leerse mal. Propongo *Espingardeiro* a secas o *Espingardeiro de correria*.
6. **"Cucaú o Quilombo" como nombre de edad** se lee como una opción de menú, no como un nombre. Si la edad IV es la bifurcación, el panel lo debería decir; si no, conviene un solo nombre (*Angola Janga* ya está en la III).
7. **Mezcla de idiomas en los objetivos**: "roças", "milho" y "mandioca" dentro del castellano. Si es elección (palabras de la época), que sea siempre en cursiva y con glosario; hoy parecen descuidos.
8. **Texto de trabajo a la vista del jugador**: "cuarteles en el prototipo", "honderos en el prototipo", "ariete en el prototipo" en objetivos de Palmares 1 y Guaraníes 3 y 4 (captura 8). Rompe la inmersión justo en los momentos más cuidados.
9. **Música con contexto a cuidar.** El propio README ya avisa que la pifilka tiene uso ceremonial (*ngillatun*). El ijexá es afoxé bahiano del siglo XIX en adelante y el berimbau se asocia a la capoeira posterior: no es Palmares del siglo XVII. La pieza tailandesa es de 1934, tocada por una banda de vientos naval. Nada de eso es irrespetuoso, pero no es "de época"; en el juego debería decir de dónde viene.
10. **Detalle menor**: el mapa base de la demo pone una empalizada en las bases del Tawantinsuyu y de Ayutthaya, que no pueden construirla.

## 5. Errores y rarezas visuales

| # | Qué pasa | Cómo reproducirlo |
|---|---|---|
| 1 | El pasto es más alto que las unidades y las tapa con la cámara cerca (captura 3) | `--demo=base --civ=etiopia --cam=b12,b9,9 --shot-at=3` |
| 2 | La etiqueta "✓ ganada" del tutorial se dibuja vertical, una letra por renglón (captura 10) | `--menu --abrir=campanas --shot=…` con el tutorial ganado |
| 3 | En el menú, el selector "Partida: 1 contra 1" flota en medio del paisaje, lejos del resto de las opciones (captura 10, arriba en el original) | `--menu --shot=…` |
| 4 | Palmares 1 arranca con población 15/10 y el aviso "hay más gente que lugar" (captura 8). Etiopía 1 llega a 43/10 con los refuerzos (captura 7) y la demo de batalla, a 33/10 | `--campana=palmares --mision=0 --shot-at=1`; `--campana=etiopia --mision=0 --speed=4 --shot-at=250` |
| 5 | Arrozales sin agua: losas verde agua planas (captura 4) | `--aivai --civ=ayutthaya --terreno=delta --speed=8 --shot-at=1140 --cam=b6,b6,20` |
| 6 | Mismo aspecto en la edad I y en la III (capturas 1, 4, 5 y 6) | Comparar `--demo=base` con las partidas de arriba |
| 7 | "Recursos insuficientes" y "¡Nos atacan!" en pantalla en IA contra IA, como si el que mira fuera el que juega | La misma partida de Ayutthaya |
| 8 | `--demo=batalla` deja la cámara en la base y no en la pelea | `--demo=batalla --civ=ayutthaya --rival=palmares --shot-at=9` |
| 9 | Cada captura termina con `double free or corruption (!prev)` y volcado de memoria al salir (código 134). La imagen se guarda bien | Cualquier `--shot` |
| 10 | Terreno *altiplano* verde con flores y *selva* que arranca en pradera abierta | `--civ=tawantinsuyu --terreno=altiplano`, `--civ=guaranies --terreno=selva --cam=b6,b6,26` |

## 6. Mis 10 deseos, en orden

1. **Rivales con su propia identidad** en las campañas: Adal y Birmania fuera de "Invasores", chankas, cayambes, cañaris y tupíes con nombre y color propios, y el nombre del rival en el marcador. Es barato y es lo que más pesa en el respeto.
2. **Voces cortas en la lengua de cada pueblo** para aldeano, tropa y aviso de edad, grabadas o revisadas por hablantes. Es lo que más identidad da por peso.
3. **Cambio visual por edad** del centro y la casa, empezando por los seis modelos que ya existen.
4. **Modelos para las unidades militares**, sobre todo la unidad única de cada pueblo (chang suek ya está; faltan chewa, weichafe, kona, leva inca, gente de guerra y compañía japonesa).
5. **Hitos con arquitectura propia** (Qorikancha, Wat Mahathat, Gondar, la Cerca real, el rewe y la casa del karai) y una maravilla por pueblo.
6. **Música para Etiopía** y pistas de paz o combate para los que no tienen; menú que suene al pueblo elegido. Si no hay CC0, encargarla a músicos de cada tradición.
7. **Relatos narrados entre misiones** con imágenes de piezas reales y una galería de historia que se desbloquee.
8. **Paisaje que cuente el lugar**: andenes en ladera, arrozales con agua, monte cerrado guaraní, palmeras en Palmares, puna en el altiplano, y ambiente sonoro por terreno.
9. **Limpiar los textos**: sacar "en el prototipo", decidir el criterio para las palabras en portugués, revisar *Inkarri*, *resgate* y el orden de las edades guaraníes.
10. **Arreglar las rarezas de la sección 5**, sobre todo la población inicial por encima del tope en las campañas y la etiqueta vertical.

## Capturas

1. [Seis bases en la edad I](capturas/historia/01-seis-bases.jpg) (Tawantinsuyu, mapuches, Etiopía, Palmares, Ayutthaya y guaraníes)
2. [Tawantinsuyu y Etiopía de cerca](capturas/historia/02-inca-y-etiopia-de-cerca.jpg): torre y fortín almenados
3. [Maqueta blanca y pasto gigante](capturas/historia/03-maqueta-blanca-y-pasto-gigante.jpg)
4. [Ayutthaya en la edad III](capturas/historia/04-ayutthaya-edad-3.jpg): mismo palacio, arrozales secos
5. [Tawantinsuyu en la edad III, con el Qhapaq Ñan](capturas/historia/05-tawantinsuyu-edad-3-qhapaq-nan.jpg)
6. [Etiopía en la edad III](capturas/historia/06-etiopia-edad-3.jpg): la iglesia es un hongo
7. [Etiopía 1: Adal figura como "Invasores"](capturas/historia/07-etiopia-1-adal-como-invasores.jpg)
8. [Palmares 1: "en el prototipo" y población 15/10](capturas/historia/08-palmares-1-prototipo-y-15-de-10.jpg)
9. [El relato de "Cuatro fraguas"](capturas/historia/09-relato-cuatro-fraguas.jpg)
10. [Campañas: "ganada" en vertical](capturas/historia/10-campanas-ganada-vertical.jpg)
