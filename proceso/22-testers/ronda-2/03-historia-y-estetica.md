# Ronda 2 · Historia y estética

Mismo perfil que en la [primera ronda](../03-historia-y-estetica.md): juego por la historia, los paisajes, la música y cómo se siente cada pueblo. Esta vez miré sobre todo lo que cambió en `proceso/23-como-aoe4` (rivales propios, nombres, animales por región).

## Qué miré

Leí:
- `proceso/23-como-aoe4/README.md` y `04-rivales-propios.md`;
- las seis civs nuevas solo de IA (`data/civs/{adal,birmanos,chankas,caranquis,canaris,tupies}.json`, con sus `_fuentes` y `_verificar`);
- los rivales de `data/campanas/*.json` (facción y nombre `corto`);
- `data/reglas.json → animales`, `data/recursos.json`, el `rebano` de cada civ;
- `proceso/CONSULTAS.md` (C-39 a C-44);
- `src/game/civ_meshes.gd` (formas nuevas y torres).

Capturas (`godot --path . -- …`):

| Qué | Argumentos |
|---|---|
| Animales junto a la capital, los seis pueblos | `--civ=<civ> --terreno=llano --seed=21 --shot=… --shot-at=3` |
| Palmares 1 | `--campana=palmares --mision=0 --shot-at=2` |
| Ayutthaya 1 contra Mingyi Swa | `--campana=ayutthaya --mision=0 --nofog --speed=4 --shot-at=400` |
| Pantalla de campañas | `--menu --abrir=campanas --shot-at=3` |
| Bases rivales | las siete capturas de `proceso/23-como-aoe4/capturas/rivales/`, en un montaje |

## Qué mejoró, deseo por deseo

| # | Mi deseo de la ronda 1 | Ahora |
|---|---|---|
| 1 | Rivales con identidad propia | **Hecho, y bien hecho.** Seis civs nuevas con fuentes y lo que falta verificar en cada JSON. El marcador dice "Rojo · Adal · Badlay", "Rojo · Mingyi Swa", "Rojo · Compañía holandesa". Hubo criterio para no inventar: los chankas van con nombres en castellano porque no se sabe qué lengua hablaban, y cañaris y caranquis van separados. La descripción de los tupíes dice que muchos eran cautivos llevados a la fuerza, y la de Adal cita su propia crónica (*Futūḥ al-Ḥabaša*). Esto es lo que más me gustó de la ronda. |
| 2 | Voces en la lengua de cada pueblo | Sin cambios |
| 3 | Aspecto por edad | Sin cambios |
| 4 | Modelos para las tropas | Sin cambios: las tropas propias y las rivales siguen siendo peones blancos (captura 6) |
| 5 | Hitos con arquitectura y maravilla | Sin cambios |
| 6 | Música (Etiopía primero) | Sin cambios (C-24 sigue abierta) |
| 7 | Relatos narrados entre misiones | Sin cambios. Apareció "Releer la guía (G)" en las misiones, que ayuda a no perder los diálogos |
| 8 | Paisaje y sonido por lugar | **A medias.** Los animales por región son un buen paso (captura 1): llamas, chilihueques, cabras, cerdos y búfalos, y los guaraníes sin rebaño y con más venados. Los arrozales siguen sin agua y el ambiente sonoro sigue siendo uno solo |
| 9 | Limpiar textos | **Hecho:** desapareció "en el prototipo" (0 apariciones en `data/campanas/`); hay *rozas*, *maíz* y *fariña*; "Espingardeiro" va sin "de resgate" y tiene una descripción que explica de dónde salían las armas. Lo discutible quedó bien planteado en C-39 a C-44, con opción por defecto y fuente |
| 10 | Rarezas visuales | **A medias.** "✓ ganada" ya se lee en horizontal (captura 5). La población por encima del tope al empezar las misiones **sigue** (ver abajo) |

## Respeto y fidelidad en lo nuevo

1. **Los europeos siguen como un solo "Invasores".** La Compañía holandesa (Palmares 1, 1645), la guarnición francesa de Bangkok (Ayutthaya 2, 1688), la bandeira paulista y Gomes Freire tienen las mismas edades (*Hueste… Virreinato*) y las mismas unidades (*Rodelero, Ballestero, Piquero*). Un "Virreinato" holandés o francés es tan raro como lo era un Adal con rodeleros. Además, la tropa de Domingos Jorge Velho era sobre todo indígena y mameluca (lo dice la misma misión) y juega como europea. Voto por la opción b) de C-44, al menos con edades y nombres por potencia, aunque los números sean los mismos.
2. **Los bayingyi en 1593.** Ayutthaya 1 (Nong Sarai, 1593) pone a Birmania en la edad III, con el arcabucero ya disponible, y el arcabucero birmano se llama *Bayingyi*. Pero los bayingyi como cuerpo se forman con los portugueses deportados de Siriam en 1613. Para 1593 conviene otro nombre (*mercenarios portugueses*) o arrancar al rival en la edad II.
3. **"Hanthawaddy" como edad III birmana.** Es el nombre del reino mon de Pegu. Bayinnaung gobernó desde ahí, pero usarlo para la edad de una dinastía birmana puede leerse como borrar a los mon. Una alternativa es *Pegu* o *Toungoo*. Se puede preguntar junto con C-44.
4. **"Capital en Dakar"** en la descripción de Adal: la grafía habitual es *Dakkar*, y "Dakar" lleva directo a Senegal.
5. **Adal tiene nombres genéricos**: Aldeano, Arquero, Lancero, Cuartel. Los tienen también los tupíes (Lancero) y los birmanos (Arquero, Lancero, Cuartel). Es honesto no inventar, pero el contraste con *Malassay*, *Fāris* y *Tüfekçi* se nota. Si hay fuente, el *Futūḥ* nombra cargos y tropas.
6. **Los rivales andinos tienen las edades por defecto** ("Asentamiento, Consolidación…"), porque sus JSON no traen `edades`. No es un error, pero contrasta con el resto. Si se ve en algún panel, queda raro.
7. **Torres que contradicen sus nombres** (`civ_meshes.gd → _tower`): todas las formas salvo `ayutthaya` y `etiopia` usan la misma torre redonda **almenada a la europea**. La ven:
   - el *Fuerte de cresta* caranqui (que era un muro de tierra y piedra en la cresta);
   - la torre de los cañaris y la de los tupíes (que no tenían torres de piedra);
   - la *Torre del Jugol* de Adal;
   - el pukara inca, como ya marqué en la ronda 1.

   El *Fuerte de troncos* birmano usa el cilindro de piedra con techo siamés. Se ve en la captura 6, en las bases de cañaris y tupíes.
8. **Tres pueblos andinos, una sola forma.** Chankas, caranquis y cañaris usan `redonda` y solo cambian de color (captura 6, las tres bases de la mitad). Para el marcador está bien, pero no se ven distintos. Con un detalle por pueblo alcanzaría para leerlos: la *tola* (montículo) bajo el centro caranqui y la "imagen de Uscovilca" como estandarte chanka.
9. **Animales por región, con matices:**
   - El **búfalo de agua** de Ayutthaya era animal de arado, no de carne; carnear el búfalo del arrozal se siente raro. Sirve igual como "alimento del rebaño", pero la descripción podría decir que se trabaja o se cambia, no que se carnea.
   - El **cerdo** de Palmares lleva `[verificar]`. Es plausible (llegó con los portugueses y se criaba en los sítios), pero conviene una cita: el diario de Blaer habla de roças, gallinas y palmeras.
   - Etiopía con **cabras** está bien, aunque lo emblemático es el buey: la misma Etiopía 1 habla de "parcelas trabajadas con bueyes".
   - Los **venados** son iguales para todos. El README de la etapa promete guanacos, pecaríes y tapires, pero no los encontré en los datos: solo `venado` y `rebano_salvaje`.
   - Los **animales sueltos** son los mismos en los trece terrenos: un cuadrúpedo pálido parecido a una oveja (captura 2, abajo). Pasan a ser de tu especie cuando los reclamás, pero en el altiplano o en el delta no se lee qué son.

## Errores y rarezas

| # | Qué pasa | Cómo reproducirlo |
|---|---|---|
| 1 | **Las misiones siguen arrancando por encima del tope de población**, con el aviso "hay más gente que lugar": Palmares 1 15/10 (captura 3). En las capturas de la etapa 23: Etiopía 1 33/10, Ayutthaya 3 65/10, Tawantinsuyu 1 15/10, Tawantinsuyu 2 27/10, Tawantinsuyu 3 37/10, Guaraníes 2 39/10 | `--campana=palmares --mision=0 --shot-at=2` |
| 2 | Todos los animales tienen la misma silueta, con patas y cuello largos: el cerdo y el búfalo parecen llamas de otro color, y el búfalo no tiene cuernos (captura 2) | `--civ=palmares --terreno=llano --seed=21 --shot-at=3` |
| 3 | Las torres almenadas aparecen en pueblos sin torres de piedra (punto 7 de arriba) | Capturas de `proceso/23-como-aoe4/capturas/rivales/05` y `06` |
| 4 | En Ayutthaya 1, el rival empieza en la edad III y el jugador en la II. El aviso "Que siempre quede en pie un elefante de guerra" ya está fallado antes de que el jugador haga nada (captura 4, sin nadie que juegue del lado propio). Con alguien jugando puede no pasar, pero vale mirar que el primer ataque no llegue antes de que se pueda entrenar un elefante | `--campana=ayutthaya --mision=0 --nofog --speed=4 --shot-at=400` |
| 5 | Sigue "la mata" en Palmares 1 ("Abrí 4 rozas en la mata"): en rioplatense, una mata es un arbusto (está en C-43) | La misma misión |
| 6 | Cada `--shot` sigue terminando con `double free or corruption` al salir | Cualquier `--shot` |

## Mis 10 deseos, actualizados

1. **Voces** en la lengua de cada pueblo, para aldeano, tropa y aviso de edad. Sigue siendo lo que más identidad da por peso.
2. **Aspecto por edad** del centro y la casa, empezando por los seis modelos que ya existen.
3. **Modelos de tropas**, empezando por las unidades únicas y por un soldado rival por facción (el malassay, el bayingyi, el guerrero de tacape).
4. **Música para Etiopía** y pistas de paz o combate para los que no tienen; menú que suene al pueblo elegido.
5. **Separar a los europeos por potencia** (C-44 b), aunque sea con edades y nombres. Y la tropa de Jorge Velho como indígenas y mamelucos.
6. **Torres y fuertes según el pueblo**: sin almenas en los Andes, troncos para el fuerte birmano y *Jugol* de piedra y argamasa para Adal.
7. **Hitos con arquitectura propia y una maravilla por pueblo.**
8. **Animales con silueta propia** (llama, chilihueque, cabra, cerdo, búfalo con cuernos) y caza por región (guanaco o taruka, pecarí, tapir, antílope, sambar). Los sueltos con la especie de la región, no un animal neutro.
9. **Arreglar la población inicial de las misiones** y revisar los detalles de fidelidad nuevos: *bayingyi* en 1593, *Hanthawaddy*, *Dakkar* y el búfalo que se carnea.
10. **Relatos narrados entre misiones** y paisaje que cuente el lugar: arrozales con agua, monte cerrado guaraní, palmeras en Palmares, puna en el altiplano.

## Capturas

1. [Animales por pueblo junto a la capital](capturas/historia/01-animales-por-pueblo.jpg) (Tawantinsuyu, mapuches, guaraníes, Etiopía, Palmares, Ayutthaya)
2. [Animales de cerca](capturas/historia/02-animales-de-cerca.jpg): misma silueta; abajo, los sueltos, iguales en todos los pueblos
3. [Palmares 1: textos corregidos y población 15/10](capturas/historia/03-palmares-1-textos-y-15-de-10.jpg)
4. [Ayutthaya 1: "Rojo · Mingyi Swa" en la edad III](capturas/historia/04-ayutthaya-1-mingyi-swa.jpg)
5. ["✓ ganada" ya en horizontal](capturas/historia/05-campanas-ganada-arreglada.jpg)
6. [Montaje de los rivales propios](capturas/historia/06-rivales-propios.jpg) (de las capturas de `proceso/23`): Adal, Birmania, chankas, caranquis, cañaris y tupíes; torres almenadas y población por encima del tope
