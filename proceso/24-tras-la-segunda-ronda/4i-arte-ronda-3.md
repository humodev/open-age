# 4i · Arte procedural: lo que marcó el jugador de historia en la ronda 3

## Pedido
Corregir lo que el informe de [historia y estética de la ronda 3](../22-testers/ronda-3/03-historia-y-estetica.md) marca en el arte procedural de [4c](4c-arte-por-edad.md) y [4d](4d-hitos-y-animales.md):

1. **Ushnu inca:** tiene que ser bajo, ancho y de piedra gris, con portada trapezoidal. Antes era una pirámide blanca y empinada, con escalinata y un bloque dorado arriba, y se leía como Chichén Itzá.
2. **Cantería inca:** gris como la andesita, no blanca como el mármol.
3. **Hitos mapuches:**
   - el rewe (el altar de la machi) estaba en 4 de los 6 hitos, y en el de malón con la toki kura al lado;
   - los hitos no tenían masa;
   - las araucarias parecían pinos de pisos.
4. **Etiopía en la edad IV (Gondar):** el centro seguía siendo la tienda real dentro de un muro. Era el pueblo que menos cambiaba de la I a la IV.
5. **Búfalo de agua:**
   - tenía los cuernos hacia adelante, como colmillos;
   - su texto decía "se carnea", cuando era el animal de arado.
6. **Notas de fuentes:**
   - la Tava de piedra del siglo XVIII fechada en 1641;
   - la bandera blanca de Cucaú, sin fuente;
   - la nyala y el órix de Etiopía, que son de otras regiones.

Solo vista y datos de arte (`src/game`, `data/arte_*.json` y la descripción del rebaño en `data/civs/ayutthaya.json`). No se tocó `src/sim` ni se gastaron créditos de Meshy.

## Paso a paso

### 1. Ushnu (`HitosMeshes._ushnu`, `data/arte_hitos.json`)
- **Forma.** Cinco cuerpos de 15 cm de alto (`alto_piso_cm`), en lugar de 36. La planta casi llena la huella de 4×4 (3,25 × 2,4 casillas) y cada cuerpo entra poco: queda una plataforma ancha de 0,75 de alto.
- **Escalinata.** Hay una sola rampa de peldaños al frente, más angosta.
- **Portada.** Arriba de la escalinata, una **portada trapezoidal de doble jamba**:
  - jambas que se inclinan hacia adentro (más angosta arriba), la exterior adelante y la interior un paso atrás;
  - dintel de piedra encima;
  - el vano abierto, así que se ve el piso y la sombra a través.
- **Tiana.** Detrás de la portada va la tiana: el asiento doble, de piedra.
- **Sin oro.** El ushnu ya no lleva oro en la edad IV: no hay bloque dorado ni banda.
- **Piedra.** El color sale del hito (`"piedra": "#8d8880"`, andesita gris) y no cambia con la edad. Así el ushnu es gris también en la edad II, cuando el resto todavía es pirca.

### 2. Cantería inca gris (`data/arte_edades.json`)
- **Muro.** En la edad III pasa de `#ddd3bd` (casi blanco) a `#8f8a81`, un gris cálido. Lo heredan la IV y todos los edificios y los hitos, que toman el muro de la edad: Qorikancha, kallanka y aqllawasi.
- **Cerco.** Su color era fijo en el código (`d6ccb6`). Ahora el cerco acepta `color` (`cerco.color`, `#87827a` para los incas), y `CivMeshes._cerco` lo usa si está.
- **Tinte de los GLB.** El `modelo_tinte` de los modelos generados no se tocó.

### 3. Hitos mapuches (`HitosMeshes`, `data/arte_hitos.json`)
- **El rewe solo en el nguillatuwe** (Rewe del lonko). Los otros hitos conservan el nombre, porque *rewe* también nombra a la agrupación de lof que comparte el ngillatun, pero ya no muestran el poste. Las ramadas del nguillatuwe son un poco más grandes.
- **Toqui de malón:**
  - una ruka grande del toqui (casi 2 × 1,35 casillas);
  - la toki kura en su propio poste, **junto a un canelo**, como propone el informe, y lejos de cualquier altar;
  - el haz de lanzas de colihue y el botín.
- **Toqui de caballería:** el corral grande, con cerca más alta y tres caballos, una ruka y un **palenque** con dos monturas.
- **Toqui del monte:**
  - un **pewenal** de tres araucarias grandes (2,9 a 3,9 de alto);
  - la ruka entre los troncos;
  - los piñones (*ngülliw*) en canastos y en pila;
  - la trampa de foso.
- **Parlamento:** la gran ramada sobre **doce postes** (4 × 3), que cubre casi toda la huella, con el techo de ramas, los bancos enfrentados, el canelo de la paz, los agasajos y la vaca de la feria.
- **Gran weichan:** dieciocho lanzas de dos altos (eran catorce), la toki kura, el fuego del consejo y **cuatro** caballos.
- **Araucaria** (`_araucaria`):
  - el tronco recto y desnudo llega al 84 % del alto;
  - arriba, la copa en **paraguas**: un cono invertido y achatado, plano encima, del que salen nueve ramas en rayos, con los mechones de hojas en la punta;
  - dos ramas bajas secas.

  Antes eran tres discos que se achicaban hacia arriba, como un pino.

### 4. Etiopía en Gondar (`arte_edades.json`, `WorldView._build_struct`, `CivMeshes._center`, `HitosMeshes.castillo`)
- **Dos claves nuevas** en el aspecto por edad:
  - `sin_modelo`: los tipos que en esa edad dejan el modelo generado y usan la maqueta;
  - `centro_forma: "castillo"`.

  En la edad IV etíope valen `"sin_modelo": ["centro"]` y `"centro_forma": "castillo"`.
- **El centro en la edad IV.** Ya no es la tienda real (el GLB `etiopia_centro`). Es un **castillo de piedra**:
  - cuerpo almenado de dos pisos, con ventanas en arco;
  - dos torres redondas con cúpula al frente;
  - detrás, un cuerpo más alto con balcón de madera y una cúpula con la cruz;
  - todo dentro del muro de piedra del cerco de la edad.

  En la IV ya no van las dos casas de los lados, porque le tapaban el frente.
- **Distinto del hito.** El castillo se arma con la misma pieza que el hito "Recinto de Gondar" (`HitosMeshes._keep`), pero es más chico y no tiene la torre cuadrada alta ni el muro bajo propio, así que no se confunden.
- **Edades I a III.** Siguen igual: la tienda real, que es la corte que camina.

### 5. Búfalo de agua (`Animales._bovine`, `arte_animales.json`, `civs/ayutthaya.json`)
- **Cuernos.**
  - Forma: salen de lo alto de la frente hacia los costados, se curvan hacia atrás y suben apenas, con las puntas hacia adentro. Es la media luna pegada a la cabeza, sin nada hacia adelante ni hacia abajo.
  - Color y grosor: gris (`cuerno_color: #6b665f`) y más gruesos en la base.
  - El color de los cuernos ahora sale del dato (`cuerno_color`) para todos los bovinos.
- **Texto del rebaño de Ayutthaya:** "Búfalo de agua: tiraba del arado en el arrozal y de la carreta, y se lo carneaba viejo o en fiestas [verificar]. Se arrea y da alimento."
- **Nota de `arte_animales.json`:** dice lo mismo, y aclara que la simulación lo sigue contando como alimento.

### 6. Notas de fuentes y fauna por región
- **Tava** (`arte_hitos.json`): la nota ya no dice "Mbororé, 1641". Ahora dice:
  - que la forma es la tava de la edad IV;
  - que las iglesias de piedra son del siglo XVIII (Trinidad, San Miguel), de la época de la guerra guaranítica (1754–1756);
  - que en 1641 eran de madera, adobe y paja [verificar].

  La forma no cambió. El informe prefiere la tava como cabildo y plaza y no como fachada; queda abierto (ver "Lo que queda").
- **Cucaú:**
  - **Se sacó la bandera blanca**, que no tiene fuente y es una imagen europea de rendición. La campaña cuenta el pacto como un juramento al modo de un soba angoleño.
  - En su lugar van un **paiol** (granero sobre pilotes, que la misión nombra) y dos palmeras.
  - La nota cita a Lara, *Palmares & Cucaú* (2021), que ya está entre las fuentes de la campaña [verificar].
- **Caza etíope:**
  - Las **tierras altas cristianas** cazan el **íbice de Walia** (Simien, en el norte). Es una especie nueva con forma de cabra y cuernos nudosos en arco (`cuernos: "ibice"`). También cazan la **dukula** (bushbuck de Menelik), un antílope oscuro de los bosques de altura, con los cuernos en espiral que antes tenía la nyala [verificar].
  - **Adal** se queda con el **órix**, que es de las tierras bajas (Afar, Ogadén).
  - La **nyala de montaña**, que es de Bale (en el sur), sale del juego.

## Pruebas
| Prueba | Resultado |
|---|---|
| `tests/test_determinism.gd` | `DETERMINISMO: OK` |
| `--autotest --civ=guaranies --terreno=llano` | `AUTOTEST: OK` (con el `double free` de siempre al salir) |
| `tests/civ_smoke.gd` (por el texto del rebaño en `civs/ayutthaya.json`) | Termina sin errores de script |
| Capturas `--demo=hitos` (tawantinsuyu y mapuches en la IV; tawantinsuyu en la II de cerca; palmares en la IV), `--demo=base --civ=etiopia --edad=4 --terreno=mesetas --seed=21` y `--demo=animales --terreno=llano --seed=21 --cam=b9.6,b16.8,15,46` | Revisadas una por una |

`tests/bench.gd` no se corrió, porque no hay cambios en la simulación.

## Capturas
1. [Incas en la edad IV, antes y después](capturas/4i-incas-ushnu-y-canteria.png): la cantería gris en el Qorikancha, la kallanka, el aqllawasi y la pukara; el ushnu bajo y ancho.
2. [El ushnu de cerca (edad II)](capturas/4i-ushnu-de-cerca.png): los cinco cuerpos bajos, la escalinata, la portada de doble jamba con el vano abierto y la tiana.
3. [Hitos mapuches en la edad IV, antes y después](capturas/4i-hitos-mapuches.png):
   - el pewenal con las copas en paraguas;
   - la ruka grande del toqui de malón;
   - el corral con la ruka;
   - la gran ramada del parlamento;
   - el rewe solo en el nguillatuwe.
4. [Etiopía en la edad IV, antes y después](capturas/4i-etiopia-edad-4.png): el castillo de piedra en lugar de la tienda.
5. [Vitrina de animales, antes y después](capturas/4i-animales.png):
   - el búfalo con los cuernos en media luna hacia atrás;
   - el íbice de Walia y la dukula;
   - con una especie más, el sambar pasa a una tercera fila, fuera de cuadro con esta cámara.
6. [Hitos de Palmares en la edad IV](capturas/4i-palmares-cucau.png): Cucaú sin la bandera blanca, con el paiol.

## Tropiezos
- **El primer ushnu nuevo tenía la portada maciza:** un bloque con un trapecio oscuro pintado. Desde la cámara alta casi no se leía como puerta. Se rehízo con jambas, dintel y el vano abierto.
- **El primer castillo etíope quedaba tapado** por las dos casas de los lados, que en la IV tienen techos cónicos altos. En la IV se sacaron y el castillo se ensanchó dentro del cerco.
- **La vitrina de animales sin `--seed`** salió con otro mapa, con rocas y monte encima. Las capturas finales usan `--terreno=llano --seed=21`.
- **Cada `--shot` termina con `double free or corruption`,** como antes. Las capturas se guardan bien.

## Lo que queda
- **La tava como cabildo y plaza, y no como fachada de iglesia** (informe, hitos 8): el camino guaraní sigue terminando en dos iglesias. Es una decisión de diseño que se suma a C-41.
- **El rewe del centro mapuche** (`rewe_cm` en `arte_edades.json`, junto al lof) sigue estando. El informe habla de los hitos; si el rewe del lof también molesta, se puede sacar con un dato.
- **El gran weichan** ganó lanzas y caballos, pero sigue siendo un campo abierto en 3×3: no tiene la masa de la ramada del parlamento.
- **Birmania** no tiene texto propio para su rebaño de búfalos: usa el genérico de `unidades.json`.
- **Las tablas de [4d](4d-hitos-y-animales.md)** describen las formas anteriores del ushnu y de los hitos mapuches. Este documento las reemplaza.

## Commits
- `Etapa 24 (4i): arte de la ronda 3 de jugadores: ushnu, cantería gris, hitos mapuches, Gondar de piedra y búfalo` (en la rama `worktree-agent-a17687d2e22fccf8c`).
