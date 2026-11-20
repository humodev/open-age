# 27 · Animaciones, paso 4: aldeanos por retrato

## Pedido

El autor eligió dos retratos de aldeano del Tawantinsuyu por edad, uno de hombre y uno de mujer (`assets/ui/arte/tawantinsuyu/LEEME.md`), y pidió: «Los modelos 3D que hagamos se deberían parecer luego».

1. **Retratos en la interfaz:** una tabla en `data/` por pueblo, unidad, sexo y edad. El panel de la selección y la ficha muestran el retrato si existe; si no, lo de antes. Después llegaron las versiones recortadas con alfa (`retratos_recorte/`), y con ellas el fondo pasó a armarse en el juego: degradé del color del jugador (por defecto), de la tierra del pueblo o la imagen original.
2. **Aldeano 3D hombre y mujer del Tawantinsuyu por edad**, parecido a los retratos. La mitad de los aldeanos son mujeres, sin tocar la simulación.
3. **Los otros pueblos:** la estructura de hombre y mujer, con piezas básicas, sin inventar ropa sin referencia.

## Resultado

- **Tabla de retratos** (`data/retratos.json`): una fila por imagen (`pueblo`, `unidad`, `sexo`, `edad`, `ruta` con fondo y `ruta_alfa` recortada, una o las dos). Gana la fila más específica, y la edad vale desde la indicada hasta que aparezca otra más alta. Cuando lleguen imágenes nuevas, alcanza con agregar una fila. `recorte` define qué parte se ve: el torso en el panel y la ficha, la cara en los cuadritos de una selección múltiple.
- **Fondo de los retratos** (`fondo` en la misma tabla): `equipo` (por defecto), `pueblo` (`por_pueblo`, o la arcilla del estilo) u `original`. Hay degradé y viñeta, con números en `data/`. Se cambia en **Opciones → Fondo de los retratos**.
- **Interfaz** (`src/game/ui/retratos.gd`, `hud.gd`, `ficha.gd`): panel de una unidad, cuadritos de la selección múltiple, ficha de la unidad y del tipo. El aldeano lleva el retrato de su sexo y de la edad actual de su pueblo. [Panel, edad I](capturas/24-panel-retrato-edad1.jpg) · [ficha y selección, edad IV](capturas/25-ficha-y-seleccion-edad4.jpg).
- **Sexo de la figura:** sale de un hash del id de la unidad (`AldeanoAnimado.sexo`), con `personas.mujeres_pct` = 50. Vale para las funciones de `personas.funciones` (civil) y lo comparten la vista 3D y los retratos. La simulación no lo lee.
- **Ropa por capas** (`data/arte_animaciones.json → personas`): vestimenta de la forma → `base[sexo]` → `por_civ[pueblo][sexo]` → `edades[N]`. Al cambiar de edad, el aldeano se vuelve a vestir (`world_view.gd`).
  - **Mujer inca:** acsu hasta el tobillo con faja de tocapu, lliklla sobre los hombros con orilla y tupu, trenza larga y vincha tejida (en la IV, con borla). En las manos, la pushka cuando está quieta y la canasta o la azada cuando trabaja.
  - **Hombre inca:** unku hasta la rodilla, listado en la I y con damero de tocapu desde la II (también en la falda en la IV), vincha llawtu con su tejido, pelo corto con flequillo y la chakitaqlla para cosechar.
  - **Colores tomados de cada retrato:** café y crudo en la I; azul, rojo y crudo en la II y la III; azul, rojo y ocre con más tocapu en la IV. Vitrina al lado de los retratos: [I](capturas/23-retrato-y-3d-edad1.jpg) · [II](capturas/23-retrato-y-3d-edad2.jpg) · [III](capturas/23-retrato-y-3d-edad3.jpg) · [IV](capturas/23-retrato-y-3d-edad4.jpg). En partida: [grupo en la I](capturas/26-grupo-incas-edad1.jpg) · [grupo en la IV](capturas/27-grupo-incas-edad4.jpg).
- **Los otros pueblos:** `base.f` = vestido largo (del color de la prenda de hoy, con faja de la tela) y pelo largo. El hombre sigue como estaba. Se completa cuando el autor elija sus retratos.

## Herramientas

- `godot --path . -s tools/aldeanos_animados.gd -- --modo=personas [--civ=tawantinsuyu] [--edades=1,4]`: vitrina con hombres y mujeres por edad, cada uno con el trabajo de su retrato. Saca una captura por edad.
- Capturas en partida: `--select=aldeano:N` elige solo los primeros N (con 1, el panel de una unidad), y `--edad=N` ahora vale también fuera de `--demo`.

## Tropiezos

- La vincha a la altura de siempre, con el damero, parecía unas antiparras. Se subió al nacimiento del pelo y los cuadritos se achicaron.
- La cámara de la vitrina en filas (una detrás de la otra) tapaba la fila de atrás. Cada edad va ahora a 5 m de la anterior, de costado.
- La falda larga es rígida y va pegada a la cadera, así que al caminar o cosechar las piernas la atraviesan un poco. Para corregirlo hace falta un modelo con piel de verdad, de imagen a 3D, que tome los originales de `referencia_3d/` como referencia.

## Pruebas

- `tests/test_determinism.gd`: el hash no cambió (ver `pruebas/04-*.txt`).
- Autotest con `--civ=tawantinsuyu` y con `--civ=guaranies` (`--terreno=llano`): sin errores.
