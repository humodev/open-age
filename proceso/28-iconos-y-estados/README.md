# 28 · Íconos de la grilla, color por edad y estados de un vistazo (2026-11-16)

## Pedido del autor
> "Quiero algunos íconos, si se puede, para las cosas a crear en el menú: para construir o para investigar. Y que cada edad a la que pertenece la mejora tenga un color distinto. También quiero una forma con colores de saber que no puedo investigar o construir algo, y no tener solo un candado, porque no es fácil de ver. Y la ayuda flotante tiene información en rojo incluso cuando podés hacer clic, y te hace pensar que no podés, porque es un mensaje rojo en el cuadro de información. Esas cosas también hay que encararlas. Cuando tengamos créditos de Meshy podemos crear imágenes para algunas de estas cosas, pero por ahora hagamos esto."

Solo interfaz: la simulación no cambia (mismo hash).

## Qué cambió

### 1. Un ícono propio por casilla
**Inventario de antes** (`tests/iconos.gd -- --ver`, seis pueblos, cuatro edades, 580 grillas):
- 10 íconos repetidos entre comandos distintos:
  - `torre`: torre, vigías, aspilleras y fortaleza reforzada; las dos últimas, en la misma grilla de la fortaleza.
  - `casa`: casa, mampostería y reparación rápida.
  - `hondero`: el campo de tiro, el hondero y el boleador; los dos últimos, en la misma grilla inca.
  - `jinete`: el establo y el jinete.
  - `ariete`: el taller, el ariete y los incendiarios.
  - `centro`: el centro y el lof.
  - `granja`: la granja y el riego.
  - `riqueza`: orfebrería y oficio maestro.
  - `elefante`: el elefante del rey y el de guerra.
  - `guerrero`: el guerrero y la compañía japonesa.
  - Además, el submenú «Investigaciones» usaba el mismo glifo (`carga`) que «Desarmar la corte».
- **Ahora:**
  - 69 íconos distintos y ninguno se repite dentro de una grilla. `tests/iconos.gd` lo verifica, y también que ningún comando caiga en el círculo de reserva.
  - Los únicos que se comparten son los hitos: en cada grilla son dos (Z economía, X militar), con distinto ícono, y la franja de la edad los separa entre edades.

**Glifos nuevos** (dibujo vectorial en código, `src/game/ui/iconos.gd`; sin imágenes bajadas):

| Para | Glifo |
|---|---|
| Campo de tiro | diana con flecha |
| Establo | galpón con herradura |
| Taller de asedio | rueda y martillo |
| Lof | ruka con bandera |
| Boleador | boleadoras girando |
| Incendiarios | antorcha |
| Awqa | porra estrellada (champi) |
| Compañía japonesa | espada curva |
| Elefante de guerra | lanza y banderín |
| Elefante del rey | el elefante con lo que recibe |
| Herramientas de tala | hacha (la segunda tanda, con dos palotes: `hacha#2`) |
| Cantería | pico |
| Trabajo de la riqueza | anillo con gema |
| Cestas | canasta con frutos |
| Riego | gota sobre surcos |
| Mampostería | muro de piedra labrada |
| Reparación | martillo sobre el muro |
| Vigías | ojo sobre la almena |
| Aspilleras | torre con tres flechas |
| Fortaleza reforzada | fortaleza con escudo |
| Oficio maestro | engranaje con corazón de riqueza |
| Herrería, cuerpo a cuerpo | espada con la clase y la tanda |
| Herrería, distancia | arco con la clase y la tanda |
| Adiestramiento | figura y muñeco de práctica |
| Submenú «Investigaciones» | pergamino |

**Listo para las imágenes de Meshy:** `data/iconos.json` → `imagenes` (`{"hacha": "res://assets/ui/iconos/hacha.png"}`).
- La imagen reemplaza al glifo en todos lados: grilla, ficha, cola y techos con Alt. Se atenúa igual que el glifo cuando la casilla está bloqueada.
- Si la ruta no existe, se dibuja el glifo.
- Para darle imagen a un comando que comparte ícono, primero se le da un nombre propio en `tipos` (edificios y unidades) o en `tecnologias` (investigaciones), y después la imagen.

### 2. Color por edad
**Paleta** en `data/iconos.json` → `edades`:

| Edad | Color | Luminancia relativa |
|---|---|---|
| I | violeta | 0,13 |
| II | azul pizarra | 0,21 |
| III | verde | 0,51 |
| IV | blanco celeste | 0,79 |

- Sube de luminancia de una edad a la siguiente, así que se ordenan también en grises.
- `tests/iconos.gd` exige:
  - ΔE ≥ 20 entre edades vecinas y contra el ámbar y el rojo, en las cuatro visiones de `tests/test_paleta.gd`;
  - que cada edad sea al menos un 30 % más luminosa que la anterior;
  - texto a 4,5:1 o más.
- Ningún color de edad es ámbar ni rojo, que ahora significan «falta» y «bloquea».

**Dónde se ve:**
- **Franja a la izquierda** de cada casilla de investigación (de cualquier edad) y de lo que se habilita desde la II.
- **Pastilla con el número** (I, II, III, IV) en el color de la edad, en lo que está bloqueado por edad.
- **«Edad III» en su color** en la ficha, a la derecha del pueblo.
- **En la ayuda:** «Necesita la **edad III**», con la edad en su color.

### 3. Estado de cada casilla de un vistazo
`EstadoCasilla.estado()`. Captura 04 a color y 05 en grises:

| Estado | Cómo se ve |
|---|---|
| Disponible | Normal. |
| En la cola | Borde verde agua y pastilla «×3», que reemplaza al número suelto de arriba. |
| Falta recurso | Borde y tinte ámbar, glifo ámbar atenuado y la franja de lo que falta, con el número en el color del recurso, no en rojo. |
| Bloqueado por edad o requisito | Oscurecido (50 %), **rayado en diagonal**, glifo gris y la pastilla de la edad en su color. El candado queda chico y ya no es lo único que avisa. |
| Tope (máximo por edad) | Rayado y oscurecido como el bloqueo, con la pastilla celeste «Máx. 2». |
| Población llena | Borde celeste y pastilla con la figura de población y «!». No bloquea: el pedido entra a la cola. |
| Investigación en curso | Borde verde agua y tilde. Antes se veía como un bloqueo con candado. |

- **En grises:** el rayado separa lo bloqueado de lo que solo no alcanza, la franja de abajo marca lo que falta, y el tilde y las pastillas marcan el resto.
- **Dónde se arma:** el controlador marca `edad`, `tope`, `aviso`, `en_curso` y `en_cola` en `_marcar_estados` (función aparte, al final de `commands()`).

### 4. Ayuda flotante: rojo solo si bloquea
- **Primera línea, debajo del título** (`EstadoCasilla.lineas_ayuda`):
  - «Podés construirlo / entrenarlo / investigarlo», en verde;
  - «Falta: 15 de riqueza», en ámbar;
  - «Necesita la edad III», en rojo con la edad en su color;
  - «No se puede: ya hay un hito en obra», en rojo;
  - «Ya está en investigación», en verde agua;
  - con la población llena: «Podés entrenarlo», y debajo, en ámbar, «Población llena (14/14): entra a la cola…».
- **Costo:** el número que no alcanza va en ámbar, no en rojo.
- **Lo que salía en rojo y ya no:**
  - «Faltan…» en «AHORA»: ahora es la primera línea, en ámbar.
  - El bloqueo al pie: ahora es la primera línea.
  - «Débil: …» de toda ficha de tropa o edificio: informa, no bloquea. Ahora va en un tono cálido neutro.
  - «Detenido: población llena» y «Falta X: rinde al n %»: ahora en ámbar.
  - «Clic: investigar…» ya no aparece cuando el clic no hace nada.
- **La ayuda se quedaba vieja:** guardaba el comando del momento en que entró el mouse. Si después alcanzaban los recursos, se subía de edad o terminaba el hito, seguía diciendo lo de antes, por ejemplo en rojo. Ahora la ficha y la ayuda simple releen el comando de la grilla en cada cuadro. Este era el caso más probable del «rojo cuando podés hacer clic».
- **Detalle:** la ficha de una investigación que se hace en varios edificios decía «Investigación ·», con el punto colgando.

### 5. Otros casos del mismo tipo
**Arreglados:**
- La ayuda que se quedaba vieja.
- «Débil» en rojo.
- «Detenido: población llena» y «Falta…» de los motores en rojo.
- El número de la cola, que se encimaba con el candado.

**Anotados, sin tocar:**
- **«En combate» y «Frenado (boleadoras)»** siguen en rojo en la ficha de una unidad. Son peligro real, no un bloqueo.
- **La fortaleza (paso 4) no tiene casilla** en `data/interfaz.json → grilla.militar`. Cae en la primera libre y `tests/grilla.gd` falla («'fortaleza' no está en la tabla de militar», en los seis pueblos). Pasa igual sin estos cambios, así que le toca al paso 4 o al siguiente. Ayutthaya no tiene casilla libre en militar.
- **Con muchos recursos faltantes** (el hito, con cuatro renglones), la franja tapa casi todo el glifo. Pasaba antes; el nombre «Hito / Edad III» sigue.
- **Al salir, Godot aborta** («corrupted size vs. prev_size») después de terminar el autotest y las capturas. Las pruebas ya dieron OK antes. No se ve relación con estos cambios: las capturas de la copia de antes abortan igual.

## Paso a paso
1. **Lectura:** la grilla, `estado_casilla.gd`, `glyphs.gd`, la ficha, la ayuda simple y los textos del controlador, y las síntesis de las rondas de jugadores (el «candado sobre una casita no me dice qué es» del jugador nuevo y el «−300+» del veterano).
2. **Inventario:** `tests/iconos.gd -- --ver` ([antes](pruebas/iconos-antes.txt)). La galería `tests/galeria_grilla.gd` dibuja todas las grillas en una imagen, a color y en grises (captura 01).
3. **Íconos:**
   - `src/game/ui/iconos.gd`, una clase aparte para no pisar a quien toque `glyphs.gd`.
   - `data/iconos.json` (tabla nueva).
   - Ganchos de una línea en `Glyphs.draw` y `Grilla.icono`.
   - Los íconos de investigación se toman de la tabla, así `data/tecnologias.json` no se toca.
4. **Paleta de edades:** la primera elección (violeta, azul, verde agua) no pasaba ΔE 20 con deuteranopía (I–II, 13,2) ni con tritanopía (II–III, 15,5). Se buscó con el mismo modelo de `test_paleta.gd`, con tono fijo por edad y saturación mínima.
5. **Estados en la casilla y primera línea de la ayuda:** galería y capturas reales en tres pueblos, revisadas y corregidas.
6. **Autotest:** `src/game/autotest_iconos.gd`, archivo aparte; main.gd solo lo llama. 14 controles nuevos con la grilla real del centro:
   - falta, bloqueado por edad, disponible, en curso y población llena, cada uno con el color de su línea;
   - que la ficha releída no diga «Necesita…» después de subir de edad;
   - ningún ícono repetido y la edad marcada en cada casilla.

## Tropiezos
- **«Edad III» en la pastilla** tapaba el segundo renglón del nombre en las casillas compactas («Línea veterana»). Quedó el número solo, en el color de la edad; la ayuda lo dice entero.
- **La ayuda de las capturas** (`--ayuda=N`) se anclaba a la casilla y tapaba la fila de arriba. Ahora se ancla a la grilla, como con el mouse.
- **En el autotest,** la ficha tarda 0,1 s y un fundido en aparecer: con 4 cuadros no salía en la captura y hicieron falta 20. Además, el centro casi siempre tiene cola, así que no se puede exigir que esté vacía.
- **El sandbox no deja** compuestos de shell con variables: los recortes y montajes se hicieron con Python (PIL).

## Pruebas ([pruebas/](pruebas/))
| Prueba | Resultado |
|---|---|
| `tests/test_determinism.gd` | OK, hash 2203695307, el mismo que sin estos cambios |
| `tests/casillas.gd` | 504 grillas, OK |
| `tests/iconos.gd` (nueva) | 580 grillas, 69 íconos, paleta de edades OK |
| `tests/test_paleta.gd` | OK |
| `tests/grilla.gd` | FALLO previo de la fortaleza (ver arriba), igual que antes |
| Autotest `--autotest --civ=guaranies --terreno=llano` | OK, con los 14 controles nuevos |

## Capturas ([capturas/](capturas/))
- **01 y 02:** galería antes y después: guaraníes, inca y Ayutthaya; aldeano, centro, cuartel e investigaciones; edad II con un banco a medias.
- **03:** la galería en grises.
- **04 y 05:** un mismo comando en cada estado, y una investigación de cada edad, a color y en grises.
- **06:** la ayuda de Vigías antes («Faltan 15 de riqueza» en rojo en «AHORA») y después («Falta: 15 de riqueza» en ámbar como primera línea, con «Edad II» en su color).
- **07:** grillas reales del aldeano (economía y militar) y del cuartel en los tres pueblos.
- **08 a 15:** antes y después en el juego:
  - el cuartel inca, con «Necesita la edad III»;
  - el hito en obra;
  - Expulsar guarnición;
  - el centro de Ayutthaya.
- **16:** los cinco estados del autotest con la ficha.

## Riesgos de conflicto con el paso 3 del juego tardío
- **`glyphs.gd`:** una línea al principio de `draw`. Si el otro agente agrega glifos, no hay choque. Si los agrega con un nombre que ya está en `Iconos.PROPIOS` (p. ej. `hacha`), gana el de acá.
- **`controller.gd`:**
  - dos líneas cambiadas (ícono de la investigación y del submenú);
  - una llamada al final de `commands()`;
  - una función nueva después de `# --- fin casillas ---`.
  - `effects_text` y `unlocks_text` no se tocaron.
- **Tecnologías nuevas del paso 3:** usan su `icono` de `data/tecnologias.json`. Si repiten uno en la misma grilla, `tests/iconos.gd` lo marca, y se arregla agregándolas a `data/iconos.json → tecnologias`.
- **`main.gd`:** una línea en `_autotest` y el ancla de `--ayuda`.

## Integración (orquestador)

- **Conflictos:** en `controller.gd` y `ficha.gd`, con la escuela de la IV del paso 3. Se resolvieron conservando las dos cosas: la escuela usa el ícono por tecnología, y la ficha dice «Escuela de la edad IV · nombre».
- **`tests/grilla.gd` fallaba en los seis pueblos** porque la fortaleza del paso 4 no tenía casilla. Ahora `interfaz.json → grilla.militar` acepta una lista de casillas en orden de preferencia (`"fortaleza": [6, 7, 9, 5, 3, 2, 1]`): primero se ubican los de casilla fija, después los de lista. Queda en D o en F según el pueblo, sin pisar la puerta.
- **Pruebas después de integrar:** grilla, íconos (588 grillas), casillas (504), determinismo (mismo hash) y autotest: OK.
