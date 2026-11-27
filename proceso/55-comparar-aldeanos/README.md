# 55 · Comparar aldeanos (C-98 y C-99)

**Pedido (2026-11-26):** C-98 y C-99 quedaron sin contestar porque no había con qué comparar. Armar la comparación lado a lado, por pueblo:
- el aldeano animado de KayKit;
- el Meshy quieto;
- el del pipeline local, caminando con el retarget de `tools/visor_rig.gd`.

Además:
- una prueba de rig y animación de Meshy sobre el aldeano inca;
- una captura de los soldados con sus armas.

Página para mirar todo junto: [`index.html`](index.html), autocontenida; las imágenes van con rutas relativas.

## Paso a paso

1. **`tools/comparar_aldeanos.gd`.** Pone a las figuras lado a lado con la misma luz que las vitrinas de `proceso/27` y a la altura del juego: `FIGURE_H × unidad_pct` = 0,75 casillas.
   - Usa el material mate del juego (`WorldView._matte`).
   - Saca la cámara del juego (inclinación 54°, giro 45°, zoom 28, fov 30) y una toma de cerca.
   - Saca una tira de seis cuadros del ciclo de caminar.
   - El KayKit es `AldeanoAnimado` vestido como hombre de la edad I.
   - El local camina con `Walking_A` retargeteado; el retarget está copiado de `tools/visor_rig.gd`.
2. **`tools/meshy_rig.py`.** Rig (`POST /openapi/v1/rigging`) y animaciones (`POST /openapi/v1/animations` con `action_ids`). Anota el saldo antes y después de cada tarea en un registro propio y nunca imprime la clave.
3. **Prueba de Meshy:**
   - Rig del GLB original del aldeano inca: 5 créditos. Trae caminar y correr.
   - Diez clips de la biblioteca: 30 créditos.
   - Los carga `--modo=meshy` (hoja de clips y tropa a la distancia del juego, con la faja del equipo colgada de `Hips`).
4. **Soldados:** `--modo=soldados`, cada tipo a pie de la edad III, quieto, con un cartel con el tipo y el arma.

## Créditos de Meshy

| Paso | Créditos |
|---|---|
| Rig con `input_task_id` de la tarea de noviembre 13 (vencida, 400) | 0 |
| Rig del GLB original del aldeano inca (+ caminar y correr) | 5 |
| 10 clips: Idle, Charged_Axe_Chop, Heavy_Hammer_Swing, Pull_Radish, Collect_Object, Carry_Heavy_Object_Walk_inplace, Attack, Dead, Hit_Reaction, Male_Bend_Over_Pick_Up | 30 |
| **Total** (saldo 1223 → 1188) | **35** |

Registro: [`meshy-registro.jsonl`](meshy-registro.jsonl). Los GLB riggeados quedan en `.cache/meshy_rig/` (fuera del repositorio).

## Opciones de C-98, en una línea

| Opción | A favor | En contra |
|---|---|---|
| a) Animados (KayKit) y riggear los Meshy cuando se pueda | La prueba muestra que se puede: el inca de Meshy camina, trabaja y muere en el juego, con su textura. | Hay que rehacer los modelos con las manos vacías (la herramienta viene pegada y se dobla con el brazo) y recortar algunos clips. |
| b) Volver al Meshy quieto hasta riggear | Es lo que mejor se ve de lejos, con la textura y la piel de cada pueblo. | Se pierde todo el movimiento: los aldeanos se deslizan quietos y los soldados no pegan. |
| c) Animados, con colores más oscuros y terrosos | Es barato y se hace ya con data/arte_animaciones.json (vestimenta, aspecto y piel), sin modelos nuevos. | Sigue siendo la figura de bloques de madera: de cerca no gana textura ni cara. |
| 3) Pipeline local, riggeado y con el retarget de KayKit | Camina con las mismas animaciones del juego y es gratis (sin créditos). | Los seis salieron con la misma túnica roja, la cara se deforma y el de Palmares no tiene esqueleto. |

## Prueba de Meshy riggeado

![Clips](img/meshy_aldeano_clips.jpg)

![A la distancia del juego](img/meshy_aldeano_rts.jpg)

| Estado del juego | Clip de Meshy | Cómo queda |
|---|---|---|
| quieto | `Idle` | directo |
| caminar / correr | `walking / running (vienen con el rig)` | directo |
| talar | `Charged_Axe_Chop` | sustituto: golpe cargado de 7,7 s, con desplazamiento; hay que recortarlo |
| picar / construir | `Heavy_Hammer_Swing` | sustituto: la cadera se corre; hay que dejarlo en el lugar |
| cosechar | `Pull_Radish` | directo |
| juntar / carnear | `Collect_Object, Male_Bend_Over_Pick_Up` | directo |
| con carga | `Carry_Heavy_Object_Walk_inplace` | directo (el juego hoy no tiene este estado) |
| pegar | `Attack` | directo |
| golpeado | `Hit_Reaction` | sirve, pero se corre 85 cm; hay que dejarlo en el lugar |
| morir | `Dead` | directo |

Lo que se vio:
- Carga y anima en Godot sin conversión: 24 huesos, en centímetros bajo un Armature a 0,01. La escala sale de la malla.
- El color del equipo se resuelve con la faja colgada de la cadera. Hay una sola textura, así que no se puede teñir una parte.
- **El problema principal es la herramienta pegada al modelo:** el rig la ata al brazo y a la cabeza, y en casi todos los clips se dobla sobre la cara.
- Los soldados riggeados por Meshy necesitan modelos con las manos vacías.

## Por pueblo

### Tawantinsuyu

Único con la columna 4 (Meshy riggeado). El local viste túnica roja, lejos del unku claro del Meshy.

![Tawantinsuyu, distancia del juego, 3×](img/tawantinsuyu_rts.jpg)

![Tawantinsuyu, tamaño real](img/tawantinsuyu_rts_real.jpg)

![Tawantinsuyu de cerca](img/tawantinsuyu_cerca.jpg)

![Tawantinsuyu caminando](img/tawantinsuyu_caminata.jpg)

### Mapuches

El Meshy, con su poncho oscuro con guarda, es el que más se integra al pasto. El local otra vez de rojo.

![Mapuches, distancia del juego, 3×](img/mapuches_rts.jpg)

![Mapuches, tamaño real](img/mapuches_rts_real.jpg)

![Mapuches de cerca](img/mapuches_cerca.jpg)

![Mapuches caminando](img/mapuches_caminata.jpg)

### Guaraníes

El Meshy con plumas y piel cobriza. El KayKit se lee claro y gris al lado.

![Guaraníes, distancia del juego, 3×](img/guaranies_rts.jpg)

![Guaraníes, tamaño real](img/guaranies_rts_real.jpg)

![Guaraníes de cerca](img/guaranies_cerca.jpg)

![Guaraníes caminando](img/guaranies_caminata.jpg)

### Etiopía

El que más muestra el tono de piel: el KayKit sale casi del mismo color que el inca; el Meshy y el local, oscuros.

![Etiopía, distancia del juego, 3×](img/etiopia_rts.jpg)

![Etiopía, tamaño real](img/etiopia_rts_real.jpg)

![Etiopía de cerca](img/etiopia_cerca.jpg)

![Etiopía caminando](img/etiopia_caminata.jpg)

### Palmares

El aldeano local de Palmares no tiene esqueleto en el GLB (los huesos llegaron como nodos sueltos): no camina y su fila de caminata sale quieta.

![Palmares, distancia del juego, 3×](img/palmares_rts.jpg)

![Palmares, tamaño real](img/palmares_rts_real.jpg)

![Palmares de cerca](img/palmares_cerca.jpg)

![Palmares caminando](img/palmares_caminata.jpg)

### Ayutthaya

El Meshy con el sombrero de paja y el pha khao ma. El local, rojo y con un hombro al aire.

![Ayutthaya, distancia del juego, 3×](img/ayutthaya_rts.jpg)

![Ayutthaya, tamaño real](img/ayutthaya_rts_real.jpg)

![Ayutthaya de cerca](img/ayutthaya_cerca.jpg)

![Ayutthaya caminando](img/ayutthaya_caminata.jpg)

## C-99: piel y armas

- **Piel:** los seis pueblos animados comparten un tono (`colores.piel = #8c5636`). `vestimenta.<forma>.piel` ya existe para darle uno a cada pueblo.
- **Armas:** las de `tropas`, tal como están:

**Tawantinsuyu:** guerrero maza · hondero honda · lancero lanza + escudo cuadrado · guardia maza + escudo cuadrado · guardia a distancia honda + escudo · galgueros galga · boleador boleadoras · awqa lanza + escudo cuadrado

![Soldados de Tawantinsuyu](img/soldados_tawantinsuyu.jpg)

**Mapuches:** guerrero macana a dos manos · hondero arco · lancero lanza larga (150 %) sin escudo · guardia lanza (140 %) · guardia a distancia arco + escudo cuadrado · incendiarios antorcha · infantería montada maza

![Soldados de Mapuches](img/soldados_mapuches.jpg)

**Guaraníes:** guerrero macana a dos manos · hondero arco · lancero lanza + escudo redondo · guardia macana · guardia a distancia arco + escudo cuadrado · kaaguygua maza

![Soldados de Guaraníes](img/soldados_guaranies.jpg)

**Etiopía:** hondero jabalina · lancero lanza + escudo redondo · guardia espada + escudo redondo · guardia a distancia jabalina + escudo redondo · guerrero gasa maza (no hay guerrero común a pie)

![Soldados de Etiopía](img/soldados_etiopia.jpg)

**Palmares:** guerrero maza · hondero arco · lancero lanza + escudo redondo · zagaieiro honda · guarnição da cerca lanza + escudo · capitão do mocambo maza

![Soldados de Palmares](img/soldados_palmares.jpg)

**Ayutthaya:** guerrero dap (una en cada mano) · hondero arco · lancero lanza + escudo redondo · guardia guja · ngao guja + escudo · defensores de Suan Phlu lanza + escudo · compañía japonesa katana

![Soldados de Ayutthaya](img/soldados_ayutthaya.jpg)

## Recomendación (decidís vos)

- **C-98:** la **a** por el camino de Meshy, generando a la gente con las manos vacías y colgando herramientas y armas del hueso de la mano. Mientras tanto, la **c** como paso barato.
- El pipeline local todavía no está para la gente: los seis visten igual, de rojo, y el de Palmares no tiene esqueleto.
- **C-99:** un tono de piel por pueblo; las armas, revisarlas con las fotos.
- **Antes de gastar más:** riggear un soldado sin arma (unos 35 créditos).

## Tropiezos

- **La tarea vieja de Meshy ya no existía** (400, sin costo). Se subió el GLB original en su lugar: 2,1 MB, de la caché de otra copia de trabajo; el del juego está optimizado.
- **El Meshy riggeado salía gigante:** el esqueleto está en centímetros y la caja medida con la escala del Armature daba 0,016. Ahora se mide la malla sola.
- **El aldeano local de Palmares no tiene esqueleto** (los huesos llegaron como `Node3D` sin piel): sale quieto.
- **Las seis texturas locales son rojas.** No es la luz: la imagen misma es roja.
- **La ventana mide 1920 × 1020 y la vista se estira a 2032 × 1080:** los recortes multiplican por esa escala.
- **El permiso para riggear el hondero (5 créditos más sus clips) fue denegado:** no se hizo.

## Pruebas

Ninguna del juego. `git diff` toca solo `proceso/55-comparar-aldeanos/`, `tools/comparar_aldeanos.gd` y `tools/meshy_rig.py`, más los índices: `proceso/README.md`, `proceso/CONSULTAS.md` y `docs/09-estado.md`.

## Commits

- Proceso 55: comparación de aldeanos (KayKit, Meshy, local, Meshy riggeado) y soldados para C-98/C-99.
