# 16 · Paisaje — 02 · Agua, orillas, suelo y atmósfera

Fecha: 2026-11-13. Rama: `worktree-agent-a62ad8cc0102e9e89` (la integra el líder).

## Pedido

> "Continuá mejorando la apariencia. El agua, los árboles, todo lo que se ve en el paisaje le falta mucho trabajo."

Reparto: otro agente hace árboles, arbustos, rocas y arcilla con Meshy. Esta parte es el agua, las orillas, el suelo y la atmósfera. No se tocan `src/sim/`, el HUD, `_build_resources` ni `_build_crags`.

## Qué cambió

### Agua (`src/game/shaders/water.gdshader`)
- **Espesor real del agua desde el buffer de profundidad.** El color, la transparencia, la espuma y las olas dependen de cuánta agua hay entre la superficie y el fondo dibujado. Así la orilla sigue el contorno exacto del terreno, en vez de la textura de una muestra por casilla, que dejaba escalones.
- **Reflejo del cielo con fresnel.** Se refleja la dirección de la vista con la normal de las ondas y se toma el color del cielo del bioma, entre el horizonte y el cenit. Va como emisión, con más peso en ángulos rasantes. Además hay un brillo suave del sol y destellos sueltos, más fuertes en los lagos que en los ríos.
- **Color por bioma** (`data/ambiente.json → agua`): verde y turbio en la selva y el delta, azul hondo y frío en el altiplano y el valle, turquesa en las islas. La turbidez sube la opacidad del agua baja.
- **Olas que llegan a la orilla**: bandas que avanzan hacia la costa siguiendo el espesor (paralelas al contorno) y espuma cortada con ruido justo en el borde. En los ríos son más débiles, porque manda la corriente.
- **Vados**: máscara propia (`ford_tex`). Dejan ver un lecho de arena y canto rodado, el agua es más transparente y aparecen rápidos con estrías de espuma a lo largo de la corriente.
- **Ondas alrededor de las unidades** que están en el agua: anillos en la normal y en la espuma. El nodo `OndasAgua` (`src/game/ondas_agua.gd`) pasa hasta 24 posiciones. Revisa la lista cinco veces por segundo y mueve las ondas en cada cuadro.
- **Niebla de guerra**: el brillo y el reflejo también se apagan en lo no visto.

### Orillas (`_build_terrain`, `ground.gdshader`, `_build_clutter`)
- **Sin escalones**: cerca del agua se agregan cuatro pasadas de suavizado. Un vértice que toca dos o más casillas de agua puede hundirse, pero no levantarse, para que los arroyos de una casilla de las campañas no queden en seco. La ondulación del llano ya no se corta de golpe a una casilla del agua: se apaga en tres casillas (antes dejaba dientes).
- **Franja húmeda**: barro oscuro y brillante (rugosidad 0,32) en la casilla que toca el agua y a ras de ella. Lleva el tono de la tierra del bioma.
- **Lecho bajo el agua**: arena y canto rodado en lo bajo, más oscuro en lo hondo.
- **Juncos y totora** en la orilla, en tierra o en el agua pegados al borde, nunca junto a un vado (los cruces quedan despejados). En el altiplano son más altos y amarillentos.

### Suelo (`ground.gdshader`, `_build_splat`)
- **Manchas de pasto alto**: un mismo ruido (`DetalleSuelo.lush_noise`) pinta el suelo más verde y oscuro y pone matas altas encima, así la mancha y las matas coinciden.
- **Tintes por bioma** (`ambiente.json → suelo`): pasto puna dorado en el altiplano y el valle, tierra rojiza en la selva, la sierra y las mesetas, roca rojiza en las mesetas.
- **Flores por bioma** (rojas, naranjas y violetas en la selva; violetas y amarillas en el altiplano, etc.), más frecuentes en el borde de las manchas de pasto alto.
- **Roca mejor integrada**: la mezcla de la ladera usa el brillo de la propia piedra, así el borde sigue las grietas, y las grietas se oscurecen. Alrededor de los peñascos hay un pedregal en un radio de unas tres casillas (`splat2.g`).
- **Menos repetición de lejos**: después de unos 30 m la textura pasa a una escala tres veces mayor, se suma una variación grande de tono y el relieve de la textura se suaviza.

### Detalle con viento (`src/game/detalle_suelo.gd`, `shaders/grass.gdshader`)
- Las mallas son nuevas: hojas de dos tramos con color en el vértice (oscuro abajo, claro en la punta). Hay matas, matas secas, pasto alto, flores, juncos y piedritas.
- **Viento** en el sombreador de vértices: el balanceo crece con el cuadrado de la altura y lleva ráfagas que recorren el mapa. La fuerza depende del bioma (más en el altiplano).
- **Niebla de guerra**: lo no explorado no se dibuja y lo explorado fuera de la vista se oscurece. Antes las matas y las piedritas se veían sobre lo negro.
- El detalle va en bloques de 32×32 casillas, así la cámara descarta lo que no ve.

### Atmósfera (`main.gd`, bloque `# --- ambiente por bioma ---`)
- Luz, cielo, exposición, saturación y contraste por bioma. En la selva el sol es más cálido y hay más bruma; en el altiplano el sol es alto, blanco y duro, el cielo azul profundo y hay menos luz ambiente.
- **Niebla de distancia** por profundidad: empieza a 40–90 m según el bioma y crece suave, con el color de cada lugar.
- SSAO y brillo moderados (radio 1,2, intensidad 1,8; brillo 0,3).
- **Sombras más suaves** con desenfoque 2,2 (1,3 en el altiplano, que tiene la luz dura).

### Datos: `data/ambiente.json` (archivo nuevo)
Se justifica porque son números de imagen, no de balance. La simulación no los lee y `reglas.json` es la fuente de verdad del juego. Hay un bloque `base` y cada mapa pisa solo lo que cambia. Los colores van en hexadecimal y el resto en enteros (porcentajes, grados, metros), igual que en los otros datos. Lo carga `src/game/ambiente.gd`.

## Rendimiento

Medido con `--disable-vsync --aivai --perf`, la versión de `HEAD` (copia en `git archive`) contra la nueva, intercalando las corridas. La GPU (RTX 2060 SUPER) estaba compartida con el juego abierto del autor, así que los números valen para comparar entre sí.

| Mapa · zoom | Antes (fps) | Después (fps) |
|---|---|---|
| Delta · 32 | 93–98 | 92–98 |
| Islas · 32 (mucha agua) | 95–101 | 95–103 |
| Selva · 70 | 58–65 | 75–79 |

La selva lejana mejora porque el detalle ahora va en bloques que se descartan.

## Tropiezos

1. **El tamaño del sol (PCSS) costaba un 25 %** de cuadros (delta: 95 → 76). Se descartó (`sol.tamano = 0`) y las sombras se suavizan con `shadow_blur`, que es casi gratis. La clave queda en los datos por si algún día se quiere.
2. **Escalones en la orilla, tres causas.** La primera era la textura de profundidad de una muestra por casilla; se resolvió con el buffer de profundidad. La segunda, un tope "el agua honda no sube de −0,4" que recreaba el escalón. La tercera, la ondulación del llano, que se cortaba de golpe a una casilla del agua. Se encontraron imprimiendo las alturas de una orilla del delta con un script de prueba.
3. **Los arroyos de una casilla desaparecían** (Tawantinsuyu, misión 2) con el primer suavizado, porque ningún vértice toca cuatro casillas de agua. Ahora el tope se aplica a los vértices que tocan dos o más.
4. **Turbio no es gris**: con la turbidez al 70 % la selva parecía barro. Se bajó al 45 % con un fondo verde.
5. **Colores de vértice**: el sombreador usa `COLOR` crudo, sin pasar de sRGB a lineal. Hay que convertirlos (`srgb_to_linear`) al armar la malla.

## Capturas (antes a la izquierda, después a la derecha)

| Archivo | Qué muestra |
|---|---|
| `02-01-rio-antes-despues.jpg` | Río con vado: lecho visible, orilla curva, juncos |
| `02-02-rio_cerca-antes-despues.jpg` | Vado de cerca: rápidos, arena, espuma de orilla |
| `02-03-delta_cerca-antes-despues.jpg` | Orilla del delta: franja húmeda, pasto alto, juncos |
| `02-04-selva-antes-despues.jpg` | Lago de la selva: verde y turbio |
| `02-05-selva_baja-antes-despues.jpg` | Selva en vista baja: bruma y reflejo |
| `02-06-altiplano_baja-antes-despues.jpg` | Altiplano: pasto puna dorado, lagunas azules con totora |
| `02-07-islas_lejos-antes-despues.jpg` | Islas: bajíos claros que se leen como cruce |
| `02-08-tawa_baja-antes-despues.jpg` | Tawantinsuyu, misión 2: arroyos con agua y bordes curvos |
| `02-09-batalla-antes-despues.jpg` | Combate en un vado: ondas alrededor de cada unidad |
| `02-10-mesetas-antes-despues.jpg` | Mesetas: tierra y roca rojizas |

## Pruebas

- `godot --path . -- --autotest --civ=guaranies --terreno=llano --mute` → `AUTOTEST: OK`.
- Capturas en río, selva, delta, islas, altiplano, bosque templado, mesetas y llano, y en las campañas de Ayutthaya (misión 1) y Tawantinsuyu (misión 2), sin errores de sombreador.
- No se tocó la simulación (no hacen falta las pruebas de determinismo).

## Archivos

- `data/ambiente.json` (nuevo), `src/game/ambiente.gd` (nuevo)
- `src/game/shaders/water.gdshader`, `src/game/shaders/ground.gdshader`, `src/game/shaders/grass.gdshader` (nuevo)
- `src/game/detalle_suelo.gd` (nuevo), `src/game/ondas_agua.gd` (nuevo)
- `src/game/world_view.gd`: `_build_ground`, `_build_terrain` (suavizado de orillas y agua por bioma), `_water_texture`, `_build_splat`, `_build_clutter`
- `src/game/main.gd`: `_build_environment` guarda las referencias; bloque `# --- ambiente por bioma ---` con `_apply_ambiente`, llamado desde `_build_scene`

## Pendiente para el líder

- Agregar la etapa 16 al índice `proceso/README.md` y una línea en `docs/09-estado.md` cuando se integre junto con la parte del otro agente, para no pisarse.
- Ideas que quedaron afuera por costo o por tiempo: refracción real del fondo (necesita copiar la pantalla), estela detrás de las unidades que se mueven y pasto que se aparta al pasar.
