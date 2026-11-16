# Ronda 3 · Historia y estética

Mismo jugador de las rondas [1](../03-historia-y-estetica.md) y [2](../ronda-2/03-historia-y-estetica.md): juego por la historia, los paisajes, la música y cómo se siente cada pueblo. Esta vez miré lo que hizo la etapa 24 en arte y sonido.

## Qué miré

Leí:
- `proceso/24-tras-la-segunda-ronda/README.md`, `4c-arte-por-edad.md`, `4d-hitos-y-animales.md`, `4e-frentes.md` y `4g-sonido.md`;
- `data/arte_edades.json`, `data/arte_hitos.json` y `data/arte_animales.json` (con sus `_nota`);
- `data/audio.json`;
- `proceso/CONSULTAS.md`, C-39 a C-44 y C-53 a C-55.

Miré las capturas de `proceso/24-tras-la-segunda-ronda/capturas/` (grilla de hitos, vitrina de animales, torres, obras) y saqué las mías, de a dos procesos (`godot --path . -- …`):

| Qué | Argumentos |
|---|---|
| Etiopía en la edad I y en la IV | `--demo=base --civ=etiopia --edad=1` (y `--edad=4`) `--terreno=mesetas --seed=21 --nofog --shot-at=3` |
| Palmares y Ayutthaya en la edad IV | `--demo=base --civ=palmares --edad=4 --terreno=sierra …`; `--demo=base --civ=ayutthaya --edad=4 --terreno=delta …` |
| Hitos incas y mapuches en la edad IV | `--demo=hitos --civ=tawantinsuyu --edad=4 --terreno=llano --seed=21 --nofog --shot-at=2` (y `--civ=mapuches`) |

No pude escuchar los sonidos. Opino sobre su diseño (instrumentos, modos, uso), no sobre cómo suenan.

## Qué mejoró, deseo por deseo de la ronda 2

| # | Deseo de la ronda 2 | Ahora |
|---|---|---|
| 1 | Voces | Sin cambios. Lo dicen bien: no se pueden sintetizar con dignidad y hay que grabarlas |
| 2 | Aspecto por edad | **Hecho, con un camino propio por pueblo.** La pirca inca pasa a cantería y después a oro; la ruka crece y el rewe sube; el tukul suma zócalo y después muro de piedra; la cerca palmarista crece y se dobla; la casa siamesa sobre pilotes pasa a teja en tres pisos con chofa dorada. No hay un "medieval" genérico. La obra en tres etapas, con el andamio y el material de cada pueblo, está muy bien. Dos peros: en Etiopía la diferencia entre la I y la IV es leve (captura 1), y los modelos de Meshy solo cambian tamaño, tono y adornos |
| 3 | Modelos de tropas | **A medias:** la tropa de maqueta cambia de tela, casco y escudo según la edad (unku rojo y casco de cobre inca). Sigue siendo el peón blanco |
| 4 | Música | **Hecho para Etiopía:** un loop de begena, masenqo y kebero en ambassel. Además, cada pueblo tiene fanfarria de edad, alarma, entrenado y orden con sus propios instrumentos. Revisé los modos etíopes: bati mayor (re fa# sol la do#) y ambassel (re mib sol la sib) están bien. El menú sigue con la flauta andina para todos |
| 5 | Europeos por potencia | Sin cambios (C-44 sin respuesta) |
| 6 | Torres según el pueblo | **Hecho.** Ya no hay almenas europeas donde no corresponden (captura 6): pukara escalonado, fuerte de cresta andino, torre de la amba con "cabezas de mono", fortín de río con *bai sema*, fuerte de troncos birmano y torre del Jugol. El baluarte almenado queda solo para los invasores |
| 7 | Hitos y maravillas | **Hecho en hitos:** los 36 tienen forma propia y fuente (captura en `4d-hitos-grilla.png`). Destaco el Qorikancha con su muro curvo y la banda de oro, Lalibela tallada en la roca roja, Fasil Ghebbi con cúpulas, la iglesia redonda (ya no es un hongo), la cerca en tres anillos con las entradas desfasadas, la ferraria encendida, el prang del Wat Mahathat y el junco. Falta la maravilla, y los rivales de campaña no tienen hitos |
| 8 | Animales con silueta y caza por región | **Hecho:** 16 especies, con caza por pueblo y por terreno (guanaco y taruka en el altiplano, tapir y pecarí en la selva, órix y nyala en Etiopía, sambar en Siam). Los sueltos toman la especie del vecino. Los guaraníes reclaman pecaríes |
| 9 | Población inicial de las misiones y detalles de fidelidad | Población arreglada (`pob_extra`). *Bayingyi*, *Hanthawaddy* y *Dakar* siguen igual (ver abajo) |
| 10 | Relatos narrados y paisaje | Paisaje **a medias:** el khlong de Ayutthaya y los arrozales junto al agua son un buen gesto. Los relatos siguen sin narración |

## Respeto y fidelidad en lo nuevo

### Sonido: lo sagrado

Estoy de acuerdo con que C-53 y C-54 existan, y propongo una salida para cada una.

1. **Kultrun (C-53).** Es el tambor de la machi: su parche lleva pintado el cosmos y se toca en el *machitun* y el *ngillatun*. Que suene en **cada orden** de una tropa mapuche y en la fanfarria de guerra es el uso más trivial posible de un objeto sagrado. Para la guerra hay instrumentos documentados: la **trutruka**, el **kull-kull** (cuerno) y la **pifilka**, que llamaban al malón y al *koyagtun*. Si hace falta percusión, está el ***kakelkultrun*** (tambor de dos parches, profano) o un bombo. Voto por la b) de C-53, sumando kull-kull, y por sacar el kultrun de "orden" desde ya, haya o no consulta.
2. **Begena (C-54).** Es el arpa de la oración personal, propia de la Cuaresma (*Hudade*). Ponerla como fondo de una partida de guerra, aunque sea en la paz, choca con ese uso. El **krar** es la lira profana de los *azmari* y cumple la misma función estética. Voto por la b) de C-54. El cuidado de no usarla en combate y de no imitar el zema está muy bien.
3. **Mbaraka y takuapu.** No están en las consultas y deberían estarlo. En el *opy* (casa de rezo) mbyá son instrumentos rituales: la mbaraka del canto del *karai* y el takuapu de las mujeres. Usarlos para "alarma" y "orden" de tropas es el mismo problema que el kultrun. Para la guerra guaraní, las fuentes hablan de **trompetas y flautas de caña o hueso** y de **tambores**; los jesuitas también mencionan cornetas en las milicias [verificar]. Propongo una consulta igual a C-53.
4. **Berimbau (C-55)** y **"São Bento Grande"** en la alarma. El documento ya admite que el berimbau es del siglo XIX y que el toque es de capoeira. Para el siglo XVII, lo fiel son los **tambores de tradición centroafricana** (*ngoma*, *engoma*), la ***marimba*** y el ***nsambi***, y para los arcos, el *hungu* angoleño como tal. Prefiero la b) de C-55, sumando ngoma: la identidad de Palmares es Angola Janga, no la capoeira bahiana.
5. Tawantinsuyu (quena, sikus en ira y arka, wankara) y Ayutthaya (*piphat* con khong wong, ranat y ching, con La Loubère de 1691 como fuente de época) me parecen bien elegidos.

### Hitos

1. **El ushnu parece una pirámide mesoamericana** (captura 3): escalones blancos y empinados, escalinata central al frente y un bloque dorado arriba. A la distancia se lee como Chichén Itzá. El ushnu de Vilcashuamán es una **plataforma baja y ancha** de cinco cuerpos, de andesita gris, con una **portada trapezoidal doble** arriba de la escalinata y la tiana. Lo arreglaría así:
   - bajarlo y ensancharlo;
   - darle el gris de la piedra;
   - cambiar el bloque dorado por la portada trapezoidal.
2. **La cantería inca es blanca como mármol** en todos los edificios desde la edad III (captura 3). La cantería del Cusco es andesita gris oscura o caliza gris verdosa; el blanco hace que el Qorikancha, la kallanka y el aqllawasi parezcan de yeso. Un gris cálido alcanza.
3. **El rewe está en cuatro de los seis hitos mapuches** (captura 4): lonko, malón, caballería y monte. El rewe es el altar de la machi, el poste escalonado por el que sube en trance. Ponerle la *toki kura* en el poste del toqui de malón mezcla el altar con la guerra, y repetirlo como marca de todo hito lo vuelve decorado. En la organización política, *rewe* nombra a la agrupación de lof que comparte el lugar del ngillatun, y por eso el nombre tiene sentido. Pero la imagen podría ser otra:
   - el *toqui* con la toki kura junto a un **canelo** o un *chemamüll* (con cuidado: también es funerario);
   - el corral;
   - el **pewen**;
   - y el rewe solo en el nguillatuwe, donde corresponde.
4. **Las araucarias del "Rewe del toqui del monte" se ven como pinos de pisos** (captura 4). El *pewen* adulto tiene el tronco desnudo y la copa en paraguas plano, y es lo que más se reconoce del paisaje mapuche. Dentro del mismo hito, además, el pewen es sagrado y alimento (el *ngülliw*).
5. **Los hitos mapuches no tienen masa.** Son palos y ramadas chicas, y a la distancia no se leen como "hito" al lado de Gondar o del Wat (captura 4 contra `4d-hitos-grilla.png`). Mientras tanto, el parlamento podría ser la gran ramada con muchos postes y el weichan, un campo con caballos y lanzas más grande.
6. **El Qorikancha en la edad IV** sigue pendiente (C-40), y la barra de arriba sigue diciendo "Edad IV · Inkarri" (C-39). Con el muro curvo hecho, el anacronismo se nota más: lo más reconocible de Pachakutiq queda al final, junto a Vilcabamba.
7. **"Tava fortificada" con el frente de piedra arenisca de Trinidad**, y la nota de `arte_hitos.json` dice "Mbororé, 1641". Las iglesias de piedra son del siglo XVIII; en 1641 eran de madera, adobe y paja. Si la edad IV es la guerra guaranítica (1754), la piedra está bien, pero hay que corregir la nota.
8. **El camino guaraní termina en dos iglesias.** De los seis hitos, el de la edad III es una iglesia (misión) y el de la IV, un frente de iglesia. Se suma a lo de C-41 ("la meta es reducirse"). Si la IV tiene que ser de piedra, prefiero *Ñande retã* (la trinchera, que ya está muy bien) como la imagen fuerte, y la tava como cabildo y plaza, no como fachada.
9. **Etiopía en la edad IV ("Gondar") sigue con la tienda real como centro**, ahora dentro de un muro de piedra (captura 1). La edad se llama Gondar justamente porque la corte deja de caminar. El castillo existe como hito, pero el centro tendría que hacerse fijo de piedra en la IV, o al menos sumar una torre. Hoy, de la I a la IV, Etiopía es el pueblo que menos cambia.
10. **La "bandera blanca del pacto"** de Cucaú ya lleva `[verificar]`. Si no hay fuente, la sacaría: es una imagen europea de rendición, y la misión cuenta Cucaú como un juramento al modo de un *soba* angoleño, no como una rendición.

### Animales

1. **El búfalo de agua parece un elefante chico** (captura 5): los cuernos salen hacia adelante y abajo como colmillos, blancos. Los del búfalo son gruesos, grises y **se curvan hacia atrás** en media luna, pegados a la cabeza.
2. **El búfalo sigue siendo "para carnear"**, y lo mismo vale para Birmania. Era el animal de arado del arrozal. Lo marqué en la ronda 2 y no cambió el texto.
3. El **pecarí amansado** como rebaño guaraní tiene sentido (lo dicen las crónicas de reducciones [verificar]), y el **chilihueque** distinto de la llama sigue a verificar (`arte_animales.json` lo dice).
4. La **nyala de montaña** vive en Bale, en el sur, lejos de la Etiopía salomónica del norte; el **órix** es de las tierras bajas (Afar, Ogadén), es decir, de Adal. Para las tierras altas cristianas va mejor el **íbice de Walia** (Simien) o la gacela. Es un detalle, pero el juego ya distingue regiones.

### Lo que seguía de la ronda 2
- *Bayingyi* en Nong Sarai (1593), *Hanthawaddy* como edad birmana y *Dakar* por Dakkar: sin cambios.
- Los rivales andinos y los tupíes siguen con las edades por defecto: en la captura de la torre caranqui se lee "Edad II · Consolidación".

## Errores y rarezas

| # | Qué pasa | Cómo reproducirlo |
|---|---|---|
| 1 | El búfalo tiene cuernos de colmillo, hacia adelante | `--demo=animales --cam=b9.6,b16.8,15,46` (`4d-animales-vitrina.png`) |
| 2 | Las araucarias del hito del monte son coníferas de pisos, no de paraguas | `--demo=hitos --civ=mapuches --edad=4 --terreno=llano --seed=21 --nofog --shot-at=2` |
| 3 | La demo de base sigue poniendo la empalizada en Etiopía y en Ayutthaya; es solo de la demo | `--demo=base --civ=ayutthaya --edad=4 --terreno=delta --seed=21` |
| 4 | El khlong de la demo es un charco ovalado, no un canal recto, y los arrozales de la demo no están al lado (captura 2) | La misma |
| 5 | En la edad IV, la tienda real etíope dentro de un muro de piedra se ve como una tienda en un corral | `--demo=base --civ=etiopia --edad=4 --terreno=mesetas --seed=21` |
| 6 | El menú suena con la flauta de pan andina para todos (`audio.gd`, `"menu"`) | `--menu` |
| 7 | Cada `--shot` sigue terminando con `double free or corruption` | Cualquier `--shot` |

## Mis 10 deseos, actualizados

1. **Sacar lo sagrado de los sonidos de tropa:** el kultrun, la mbaraka y el takuapu fuera de "orden" y de "alarma"; trutruka y kull-kull para los mapuches; caña, hueso y tambor para los guaraníes; krar en lugar de begena. Y consultar a una organización mapuche, a una mbyá y a alguien de la tradición ortodoxa etíope antes de publicar.
2. **Voces grabadas** por hablantes, aunque sean diez frases por pueblo.
3. **Palmares con raíz angoleña** en el sonido (ngoma, marimba) en lugar del berimbau de capoeira.
4. **El ushnu bajo y gris, y la cantería inca gris**, no blanca.
5. **Hitos mapuches con masa, pewen de paraguas y el rewe solo donde corresponde.**
6. **Etiopía que cambie de verdad al llegar a Gondar:** el centro de piedra en la IV.
7. **Responder las consultas de nombres:** C-39 (Inkarri), C-40 (Qorikancha), C-41 (edades guaraníes) y C-44 (europeos por potencia). Cerrar *Bayingyi*, *Hanthawaddy* y *Dakkar*.
8. **Una maravilla por pueblo** y hitos para los rivales de campaña.
9. **Modelos de tropas** de Meshy, empezando por las unidades únicas, y variantes por edad del centro y la casa.
10. **Relatos narrados entre misiones, música de menú por pueblo** y música de combate para los que no tienen.

## Capturas

1. [Etiopía en la edad I y en la IV](capturas/historia/01-etiopia-edad-1-y-4.jpg): cambia poco; en la IV la tienda real queda dentro de un muro
2. [Palmares y Ayutthaya en la edad IV](capturas/historia/02-palmares-y-ayutthaya-edad-4.jpg): cerca doble; techos de tres pisos, *bai sema* y el khlong
3. [Hitos incas en la edad IV](capturas/historia/03-hitos-inca-edad-4-ushnu.jpg): el Qorikancha muy bien; el ushnu parece una pirámide mesoamericana y la cantería es blanca
4. [Hitos mapuches en la edad IV](capturas/historia/04-hitos-mapuches-edad-4-rewe.jpg): el rewe repetido y las araucarias como pinos
5. [Vitrina de animales](capturas/historia/05-vitrina-animales-bufalo.jpg) (de `proceso/24`): el búfalo con cuernos de colmillo
6. [Torres por pueblo](capturas/historia/06-torres-por-pueblo.jpg) (de `proceso/24`): ya sin almenas europeas
