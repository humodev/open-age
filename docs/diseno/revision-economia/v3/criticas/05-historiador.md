# Ronda 3 · Crítica 05 — Historiador

Reviso `v3/01-diseno-lider.md` contra el criterio 10 de la lista de control: fiel a la historia o con la simplificación declarada.

**Fuentes.** Cito las de `docs/investigacion/` por autor. La bibliografía reconocida que no está en el repositorio va marcada `[fuera]`. Lo que no pude confirmar con una obra concreta va marcado como **dudoso**. No consulté originales en esta pasada: el grado de confianza indica qué tan establecido está el dato en la literatura, no una página leída.

## Veredicto corto

El diseño es **fiel en lo esencial**, y casi todas sus simplificaciones están declaradas.

Corregiría tres cosas:
1. el texto del "monte paga al rey" (§2.6);
2. el nombre de la riqueza etíope, que perdió el *amole* (§2.4);
3. el malón como porcentaje del daño a edificios (§2.2).

El barreal es una elección **honesta**, con un ajuste de sentido: que represente **la vasija de la bebida del convite**, no "loza" en general.

## 1. La fuente común

### 1.1 ¿Había sal en los seis? No. La tabla del líder es correcta

| Pueblo | Sal | Confianza |
|---|---|---|
| Etiopía | Sí, y era moneda: bloques de la tierra baja afar (Álvares, cap. XLIV) | Alta |
| Tawantinsuyu | Sí. Las salineras de Maras (Cusco) y las salinas costeras y del altiplano son conocidas y anteriores a la conquista. La explotación de recursos en distintos "pisos" está en Murra (1972, citado en `tawantinsuyu.md`). No encontré la cita específica de la sal en el repositorio | Alta en el hecho; falta la cita |
| Mapuches | Sí, sobre todo desde el siglo XVIII. Las Salinas Grandes de la pampa estaban en territorio indígena: las expediciones desde Buenos Aires tenían que negociar el paso, y la sal formaba parte de la economía fronteriza junto al ganado `[fuera: Mandrini; Villar y Jiménez; verificar en León Solís 1991]` | Media-alta |
| Ayutthaya | Probable: salinas costeras del golfo de Siam | **Dudoso**: no tengo fuente concreta |
| Palmares | No. La compraba (`palmares.md`, confianza media). Además, en el Brasil colonial la sal fue un estanco de la Corona que limitaba la producción local `[fuera: verificar fechas del estanco do sal]` | Media |
| Guaraníes | Escasa en el Paraguay colonial | **Dudoso** sin Susnik ni Garavaglia a mano |

**Respuesta llana al autor.** La sal no estaba en todos lados: dos de los seis pueblos (Palmares y, probablemente, los guaraníes) tenían que conseguirla afuera. Ponerla en cada base le regalaba a esos dos justo lo que les faltaba.

### 1.2 ¿La arcilla es honesta? Sí, y es la mejor opción disponible

**Los seis pueblos tenían alfarería propia y bien documentada:**
- **Guaraníes.** Es su marca arqueológica. La tipología tupiguaraní usa nombres en guaraní tomados de Montoya. El nombre que pedía el líder es **cambuchí**: la vasija grande para la bebida fermentada, que también se usaba como urna funeraria. Junto a ella aparecen la *yapepó* (olla) y el *ñaembé* (plato) `[fuera: La Salvia y Brochado, *Cerâmica Guarani*, 1989; Noelli]`. Confianza alta en los términos.
- **Tawantinsuyu.** "Aríbalo" es un término de los arqueólogos tomado del griego. La vasija inca de chicha se llamaba **urpu**, y su producción estatal, en serie y por especialistas, está estudiada `[fuera: Bray, "Inka Pottery as Culinary Equipment", *Latin American Antiquity* 14, 2003]`. Confianza alta.
- **Mapuches.** El **metawe**, el jarro de la cerámica de tradición Valdivia y El Vergel, que incluye el *ketru metawe* con forma de pato, tenía uso ritual y servía la bebida `[fuera: Museo Chileno de Arte Precolombino]`. Confianza media-alta.
- **Etiopía.** La alfarería estaba en manos de grupos artesanos de rango bajo, entre ellos alfareras beta israel `[fuera: Quirin, *The Evolution of the Ethiopian Jews*, 1992; Pankhurst]`. Para la cerveza (*tälla*) y el agua se usaba un cántaro grande, el *insəra*. Confianza media: hay que verificar la grafía.
- **Palmares.** La Serra da Barriga dio sobre todo cerámica (Funari y Orser), con la advertencia de Lara sobre la tropa de Velho (`palmares.md`).
- **Ayutthaya.** Los hornos de **Mae Nam Noi** (Sing Buri) producían jarras de almacenamiento que se exportaron entre los siglos XVI y XVII y aparecen en naufragios y en Japón `[fuera: verificar en estudios de cerámica tailandesa de exportación]`. La confianza en la existencia del sitio es media-alta. Antes, Si Satchanalai había exportado mucha cerámica.

**¿Es "riqueza"?** La loza común, no. **La bebida del convite, sí.** En cinco de los seis pueblos hubo una gran vasija para la bebida que se servía en la fiesta de reciprocidad:

| Pueblo | Vasija | Bebida |
|---|---|---|
| Tawantinsuyu | urpu | chicha |
| Guaraníes | cambuchí | kaguĩ |
| Mapuches | metawe | muday |
| Etiopía | insəra | tälla |
| Palmares | — | vino de palma |

Es exactamente la *wealth finance* de reciprocidad de la ronda 1. Ayutthaya es la excepción: allí la jarra era un **envase de exportación**. Igual es honesta, pero con otro sentido.

**Propuesta de tooltip:** "Tus aldeanos sacan arcilla y hacen las vasijas de la fiesta: con lo que se sirve en ellas se convida, se ofrenda y se paga."

**Alternativas evaluadas:**

| Opción | Problema |
|---|---|
| Metal | Ni los guaraníes ni Palmares lo producían (v2/04) |
| Piedra fina | No hay ningún equivalente para todos |
| Fibra o tela | Era universal y más valiosa que la loza, pero choca con los motores inca (cumbi) y mapuche (ponchos) y les quita identidad |
| "Bienes" o "tributo" | Neutro y honesto, pero sin imagen. "Tributo" además es falso para guaraníes y mapuches, que no tributaban a un Estado |

**Simplificación aceptable y declarada:** la arcilla no se "agota" en la realidad. Que el pozo se termine es una regla de juego.

## 2. Capas 1 y 2

### 2.1 Tawantinsuyu: fiel

- **Taller que consume mit'a y da tela.** Responde a Murra (1962): el Estado entregaba la fibra de camélido o el algodón y los hogares tejían como obligación. El taller es una simplificación aceptable si el arte muestra **fibra que se reparte**, no una fábrica.
- **Aqllawasi como cumbi.** Fiel.
- **Barreal +20 % por camino.** Es invento de diseño, pero sin contradicción histórica.
- **Única objeción.** El alfarero estatal era un especialista, a menudo *mitmaqkuna*. El +20 % podría leerse como "especialistas trasladados", y no solo como efecto del camino.

### 2.2 Mapuches: fiel en el corral, discutible en el malón

- **Rebaño visible que crece en pradera.** Fiel al ganado como riqueza y prestigio (León Solís; Memoria Chilena). La pradera también es fiel: veranadas e invernadas, la trashumancia pewenche (`mapuches.md`).
- **El corral cerrado es una licencia.** Los rebaños pastaban sueltos. Es aceptable como pieza de juego.
- **Faenar el corral entero.** Es aceptable si se presenta como **kawiñ**: la fiesta comunitaria donde se sacrificaban muchos animales a la vez, el "cahuín" de los cronistas. Así deja de ser "comerse el capital" en abstracto y pasa a ser un acto social. Sugiero ese nombre.
- **Malón como 10 % del daño a edificios.** **Distorsiona.** El malón se llevaba ganado y bienes de las estancias. No buscaba destruir: Boccara dice que buscaba recursos "con escasas bajas y pocos riesgos" (`mapuches.md`, M1).
  - El arreo que el líder deja "para más adelante" es la forma fiel.
  - Si por ahora el botín sale del daño, que llegue como **cabezas** al corral y no como riqueza directa. La regla actual de +1 cabeza en ingenios y estancias va en esa dirección.

### 2.3 Guaraníes: fiel, con un matiz conocido

- **+14 % en el barreal.** Es la mejor capa 1 del diseño desde lo histórico: la cerámica tupiguaraní es su firma.
- **La roza que deja un yerbal.** Es la hipótesis de Noelli et al. (2019), de confianza media.
- **Ficha para el autor.** La línea 5, "la yerba fue moneda de la región", vale para la **colonia** (siglo XVII en adelante). Agregaría "en la colonia".

### 2.4 Etiopía: fiel, pero perdió su moneda

- **La corte agota su entorno.** Es Horvath (`etiopia.md`, F3). Fiel. Que "coma" el barreal es una licencia menor: históricamente agotaba comida y leña.
- **Gult con señor o regimiento.** Fiel: los chewa se sostenían con gult (H14), y el gult se daba y se quitaba (Álvares; Tsehai Berhane-Selassie).
- **Simplificación declarable.** Que el gult **cueste madera** es una regla de juego. El rey no "construía" el gult: lo concedía.
- **Objeción.** Con la sal fuera, el **amole** desapareció de la civ. Es el dato económico mejor documentado de los seis: Álvares lo vio como testigo directo. Propongo que, aunque la fuente común sea el barreal, **la riqueza etíope se llame y se dibuje "amole"**. Así el gult cobra en barras de sal, como el tributo en especie que Álvares describe. No cuesta nada en mecánica.

### 2.5 Palmares: fiel en el concepto, con dos cuidados

- **"Riqueza en personas".** Es una lectura sólida: Miller, *Way of Death* (1988), y Guyer y Belinga (1995) `[fuera]`, junto con la "sintaxis política centroafricana" de Lara (2021a). Las herrerías (4 en 1645, 40 en 1694) son el dato fuerte.
- **Cuidado 1: el lenguaje.** "Cada persona produce 15 de riqueza" y "los brazos no se pagan" pueden sonar a una plantación con otro dueño. En la literatura sobre África central, la "riqueza en personas" incluye el conocimiento y los vínculos, no solo el trabajo (Guyer y Belinga). Sugiero que los puestos sean **oficios con nombre**: herrero, alfarero, cestero, tejedor de palma. Que la ficha diga "lo que la comunidad sabe hacer" y no "brazos".
- **Cuidado 2: el monte.** Sacar `oculto` es una simplificación **declarada y aceptable**: el secreto fue real (los mocambos "en lo más oculto", Lara), pero el diseño lo descarta por razones de juego. La bonificación de fama por monte conserva la idea.

### 2.6 Ayutthaya: fiel en la institución, impreciso en el producto

- **El monopolio real y el almacén.** Fieles (H19, H23).
- **El problema: la "madera" del juego no es el palo de sapán.** Los productos del monte que monopolizaba la corona eran pocos y valiosos: sapán, maderas aromáticas, laca, cueros de venado, marfil, estaño. Llegaban como *suai* desde las provincias y los pueblos del bosque, no de los leñadores de la capital.
- **Simplificación aceptable si se declara así:** "una parte de lo que tus leñadores y cazadores encuentran es palo de sapán y cueros, y es del rey". El arte del almacén debería mostrar fardos de cueros y troncos de sapán, no tablones.
- **La caza es lo más fiel.** Los cueros de venado a Japón fueron un rubro grande del siglo XVII, y la VOC se quedó con su monopolio en 1664. Si hay que elegir, la caza debería rendir **más** riqueza que la madera, no lo mismo.
- **Mercaderes chinos en los juncos de la corona.** Bien respaldado: la corona usaba tripulaciones y factores chinos, y el *Krom Tha Sai* manejaba el comercio con China (`ayutthaya.md` H22, de confianza media) `[fuera: Sarasin Viraphol 1977; Ishii, *The Junk Trade from Southeast Asia*, 1998]`. El barrio chino que sube el tope está bien fundado.

## 3. Lo marcado para verificar

| Dato | Estado |
|---|---|
| Aríbalo inca | **Resuelto**: el término correcto es *urpu* (Bray 2003). "Aríbalo" puede quedar como nombre comercial |
| Tinajas guaraníes | **Resuelto**: *cambuchí* (La Salvia y Brochado 1989; Montoya) |
| Cántaros mapuches | **Resuelto** en lo general: *metawe*. Falta una cita académica precisa |
| Alfarería etiópica de rango bajo | **Probable**: falta verificar en Quirin 1992 la grafía de *insəra* |
| Hornos de Mae Nam Noi | **Probable**: el sitio existe; falta una cita de las exportaciones |
| Sal inca | **Hecho seguro**: falta la cita |
| Sal mapuche (pampa, siglo XVIII) | **Probable** y bien conocida: verificar en León Solís o Mandrini |
| Sal siamesa | **Dudoso**: sin fuente; no usar en textos |
| Sal guaraní escasa | **Dudoso**: verificar en Susnik o Garavaglia |
| Mercaderes chinos de la corona | **Bien respaldado** (Sarasin; Ishii): falta la página |

## 4. Simplificaciones

**Aceptables y ya declaradas, o fáciles de declarar:**
- un solo recurso de riqueza;
- el barreal que se agota;
- el gult que se construye;
- el corral cerrado;
- los oficios dentro del mocambo;
- el abandono del secreto palmarista;
- el yerbal en la roza;
- el +20 % del barreal por camino;
- la corte que "come" arcilla.

**Distorsionan y conviene corregirlas:**
1. **El malón como daño a edificios.** El malón buscaba ganado, no destrucción: que el botín llegue en cabezas.
2. **Ayutthaya: madera = riqueza.** Declararlo como sapán y cueros, y que la caza pese más.
3. **Etiopía sin amole.** Recuperarlo como nombre e ícono de su riqueza.
4. **Palmares: "brazos que producen".** Hablar de oficios y saberes, no de mano de obra.
5. **Guaraníes: "la yerba fue moneda".** Agregar "en la colonia".
