# 27 · Animaciones (paso 1: aldeanos)

## Pedido

> El autor (2026-11-16), sobre el plan de `proceso/24-tras-la-segunda-ronda/4s-recursos-gratuitos.md`: "Empecemos con KayKit, sí."

Es el pendiente de C-65 (la velocidad se dejó igual hasta tener animaciones). Paso 1, solo aldeanos:

1. Bajar KayKit Character Animations (CC0), verificar la licencia, dar el crédito y subir solo lo que se usa.
2. Un aldeano animado por pueblo: el mismo cuerpo con la ropa y el tocado de cada uno. Si los modelos de Meshy se pudieran riggear, probar el retargeting; si no, dejarlo documentado.
3. Una animación por estado: quieto, caminar (con el paso a la velocidad real, sin patinar), talar, picar, cosechar o juntar, construir, cargar, pegar y morir, con una mezcla corta entre estados.
4. Que 200 aldeanos en pantalla no hundan el juego, con un ajuste para volver a la figura de antes.
5. Capturas y videos de cerca, de dos o tres pueblos.

## Resultado

- **Aldeanos animados en los seis pueblos** (y en los rivales de campaña, con ropa neutra), con el esqueleto y 13 animaciones de KayKit: [vitrina](capturas/01-vitrina-seis-pueblos.jpg), [de cerca](capturas/02-vitrina-cerca.jpg), [el hachazo de costado](capturas/03-talar-ciclo-de-costado.jpg).
- **En la partida:** [antes, con los modelos de Meshy](capturas/04-antes-modelos-meshy.jpg) y [ahora](capturas/05-despues-aldeanos-animados.jpg); [incas picando piedra](capturas/06-tawantinsuyu-picar.jpg), [mapuches picando y cargando](capturas/07-mapuches-picar-y-cargar.jpg), [etíopes yendo a talar](capturas/08-etiopia-a-talar.jpg).
- **Videos** (7 s cada uno, a velocidad real): [incas picando](videos/tawantinsuyu_picar.mp4), [etíopes talando y cargando leña](videos/etiopia_talar.mp4), [guaraníes en el monte](videos/guaranies_trabajo.mp4). En el último se ven translúcidos: es el sigilo guaraní en el monte, que ya existía.
- **Volver a la figura de antes:** `"activo": false` en `data/arte_animaciones.json`, o `--animaciones=0` en la línea de comandos. Con eso los aldeanos vuelven a ser los modelos de Meshy (o la maqueta, en los pueblos sin modelo).
- **Solo imagen:** la simulación no se tocó. El hash del determinismo es el mismo de antes (`2203695307`, igual que en `proceso/24-tras-la-segunda-ronda/4p-escala.md`).

### Qué animación usa cada estado

Todo está en `data/arte_animaciones.json`:

| Estado (lo que lee la vista) | Animación de KayKit | Herramienta |
|---|---|---|
| Quieto | Idle_A | la del trabajo en curso, si tiene |
| Caminar (trote, si el paso pasa de 3,2 por segundo) | Walking_A (Running_A) | la del trabajo al que va o del que vuelve |
| Talar (árbol, capuera) | Chopping | hacha |
| Picar (piedra, riqueza), un 40 % más rápido | Pickaxing | pico |
| Juntar (arbustos, yerbal) | Working_A | cesto a la cadera |
| Cosechar (granja, corral: cualquier edificio que da recurso) | Digging | azada |
| Carnear (carne, venados, animales sueltos) | Working_A | cuchillo |
| Construir | Hammering | martillo |
| Pegar (al ritmo de `cadencia_ms`; cada golpe reinicia el hachazo) | Melee_1H_Attack_Chop | hacha |
| Morir (y se hunde, como antes) | Death_A | — |
| Cargar | el atado a la espalda, del color del recurso | — |

No hay animación de entregar: en la simulación, la entrega es instantánea y el aldeano sigue caminando en el mismo tick. Con un gesto de entrega patinaría.

## Paso a paso

### 1. Bajar el paquete y la licencia

- itch.io no pide pagar: el botón de descarga lleva a la página de descargas sin pasar por el pago ("Free 1.1", 14 MB). Se bajó con `curl` siguiendo el mismo camino que la página (`download_url` y después `file/15799903`).
- El zip trae `License.txt`: **CC0 1.0**, de Kay Lousberg. El crédito no es obligatorio, pero quedó en `assets/CREDITOS.md` (sección "Animaciones"), con la licencia junto al recurso (`assets/animaciones/kaykit/License.txt`).
- El paquete trae dos esqueletos (Rig_Medium, Rig_Large), cada uno en FBX y glTF, ocho archivos de animaciones (161 en total) y un maniquí. **Se subió un solo glTF de 724 KB** (`assets/animaciones/kaykit/aldeano_kaykit.glb`), con el esqueleto Rig_Medium, el maniquí y las 13 animaciones que se usan, más su textura de 18 KB. Lo arma `tools/kaykit_extraer.py` con Blender; si hacen falta más animaciones (para los soldados), se agregan a la lista y se vuelve a correr.

### 2. El cuerpo

**Los modelos de Meshy no se pueden riggear tal como están:** los seis aldeanos generados (`assets/generados/modelos/*_aldeano.glb`) son una sola malla sin esqueleto ni pesos, con los brazos pegados al cuerpo y la herramienta y el cesto fundidos con la figura. Para animarlos hay que riggearlos primero (ver "Cómo retargetear los modelos de Meshy" más abajo). Sin créditos de Meshy, su autorrig no está disponible.

**Entonces, un cuerpo propio sobre el esqueleto de KayKit** (`src/game/aldeano_animado.gd`):

- **Proporciones de persona.** El maniquí de KayKit es cabezón: la cabeza ocupa la mitad del alto y las piernas, un cuarto. Se usa su esqueleto con los huesos estirados o acortados a una persona (`PROP`: cadera a la mitad, cabeza de un octavo). De cada animación quedan solo las **rotaciones**, más la altura de la cadera escalada. Así la misma animación sirve con otros largos de hueso, como el retargeting de Godot, porque los huesos conservan la orientación de reposo de KayKit.
- **Piernas y brazos más cerrados.** Con proporciones de persona, el muñeco de KayKit camina con las piernas abiertas, como un vaquero, y deja los brazos separados del cuerpo. Se cierra el ángulo hacia afuera de las piernas (en todas las animaciones) y de los brazos que cuelgan (quieto, caminar, correr), sin tocar el resto del movimiento (`_cerrar`).
- **Una pieza rígida por hueso**, como la maqueta: cabeza, pelo, tronco, cadera, faja del color del equipo, brazos, manos, piernas y pies. Todo va en una sola superficie con color por vértice, con piel y un solo material para todos los pueblos.
- **Ropa y tocado de cada pueblo**, con los colores de la maqueta (`vestimenta` en los datos): unku pardo con franja de tocapus y llawtu rojo (incas), poncho oscuro y trarilonko de plata (mapuches), tipoy de algodón y corona de plumas (guaraníes), shamma blanca (Etiopía), paño y turbante dorado (Palmares) y paño morado (Ayutthaya). Las afirmaciones históricas siguen con `[verificar]` en las fichas.
- **Herramientas** de mango de madera y cabeza de piedra (hacha, pico, martillo, azada, cuchillo) en el hueso `handslot.r`, orientadas como las armas de KayKit Adventurers: el mango por el +y del hueso y la hoja hacia +x. El cesto va a la cadera.
- La malla de cada combinación de pueblo, color de equipo, herramienta y carga se arma una vez y queda en caché.

### 3. Los estados y el paso

- **El paso no patina.** Al armar el esqueleto se mide cuánto avanza el cuerpo por segundo en la animación de caminar, con el pie de apoyo: mientras toca el suelo, se corre hacia atrás a la velocidad del cuerpo. Después, cada cuadro avanza la animación según la **distancia recorrida**: `tiempo = distancia / velocidad de la animación`. El paso sigue a la distancia a cualquier velocidad de juego (×1, ×2, ×4) y también cuando el aldeano va frenado o empujado.
- **Lo que dice de C-65:** con la velocidad de hoy (1,125 casillas por segundo, con una persona de 0,75 casillas de alto), el aldeano anda a 1,5 alturas de cuerpo por segundo. Walking_A pide 0,94, así que se reproduce a ×1,6, unos **3 pasos por segundo**: un paso apurado, no un paseo. Se ve lo que había dicho el veterano: anda rápido para su tamaño. Como el paso acompaña, no patina. Si se baja `velocidad_pct` (C-65 a), el paso se calma solo. El trote (Running_A) entra recién a más de 3,2 pasos por segundo, medido en tiempo de juego. Con la velocidad de hoy no entra.
- **Mezcla de 0,18 s** entre estados (`mezcla_s`).
- **Histéresis de 0,2 s** (`cambio_s`): en un montón, los aldeanos se empujan y el "se mueve / está quieto" titila de un tick a otro. Sin esto, había 50 cambios de animación por cuadro con 200 aldeanos.
- **Velocidad del juego:** las animaciones de trabajo siguen la velocidad del juego (`main.gd` le pasa `speed` a la vista) y se congelan en la pausa.

### 4. Rendimiento

Se midió con `tools/aldeanos_animados.gd --modo=fps`: 213 aldeanos en pantalla, la mitad caminando de un lado a otro y la otra mitad talando, en una RTX 2060 Super, a 1920×1080, con dos corridas de cada modo (`pruebas/fps_200_aldeanos.txt`).

| | Sin animar (modelos de Meshy) | Animados |
|---|---|---|
| Cuadros por segundo (mediana) | 15,4 y 12,8 | 14,4 y 13,6 |
| Tiempo de la vista por cuadro (`WorldView.render`) | 11,0 y 12,1 ms | 12,7 y 13,2 ms |
| GPU por cuadro | ~7 ms | ~6 ms |

**Aviso:** la máquina estaba cargada por otros procesos (carga promedio de 30 en 12 núcleos, con torneos de otras tareas). Los tiempos absolutos están inflados y los cuadros por segundo los limita la simulación de 200 unidades, no el dibujo. Lo que importa es la diferencia: **animar 200 aldeanos le suma a la vista entre 1 y 1,5 ms por cuadro**, dentro del ruido de los cuadros por segundo.

Para llegar a eso:

1. **Primera versión:** la vista tardaba 20 ms contra 11 ms. Casi todo era GDScript por aldeano, no la animación: lecturas de diccionarios de configuración y 50 cambios de animación por cuadro.
2. **Histéresis** (ver arriba) y una **clase tipada por aldeano** (`AldeanoAnimado.Estado`), con la configuración leída una sola vez.
3. **Presupuesto por cuadro** (`rendimiento.max_por_cuadro`: 80): con más aldeanos en pantalla, cada uno se actualiza cada 2 o 3 cuadros. Entre turno y turno se juntan la distancia y el tiempo, y se aplican de una vez, así que el paso sigue sin patinar. Con 200 en pantalla, la animación corre a unos 20 a 30 cuadros por segundo; de cerca, con menos aldeanos, va a cada cuadro.
4. **Fuera de la pantalla no se anima**, y **lejos de la cámara** (más de 46 casillas, `lejos_m`), se anima a la mitad de cuadros.

No hizo falta un nivel de detalle con la maqueta de lejos. Si los soldados duplican la cuenta, el próximo paso es compartir esqueletos entre los que hacen lo mismo (ver "Lo que falta").

### 5. Capturas y videos

`tools/aldeanos_animados.gd` tiene tres modos:

- `--modo=poses`: la vitrina de los seis pueblos, sin partida. Con `--tiempos=0,0.2,…` muestra una acción en varios momentos del ciclo; con `--lado`, de costado; con `--herramienta=ejes`, los ejes del hueso de la mano, para orientar una herramienta nueva.
- `--modo=trabajo --civ=X --mirar=madera|piedra|alimento|riqueza`: una partida con aldeanos en cada trabajo y una casa en obra. Con `--seguir=S` sigue S segundos después de la captura.
- `--modo=fps`: la medición de arriba.

Los videos se grabaron con el Movie Maker de Godot, que corre con paso fijo, así que el video sale a velocidad real aunque la grabación sea lenta. Después se recortaron con ffmpeg:

```
godot --path . --write-movie /tmp/x.avi --fixed-fps 30 -s tools/aldeanos_animados.gd -- --modo=trabajo --civ=tawantinsuyu --terreno=llano --nofog --mute --seed=7 --mirar=piedra --zoom=8 --seguir=7 --ventana=1280x720
ffmpeg -ss 14.6 -i /tmp/x.avi -t 7 -vf scale=960:-2 -c:v libx264 -crf 28 -pix_fmt yuv420p -an videos/tawantinsuyu_picar.mp4
```

## Cómo retargetear los modelos de Meshy (cuando estén riggeados)

1. **Riggear el modelo.** Puede ser el autorrig de Meshy (pide créditos), Mixamo o Blender. En Blender, se importa el `.glb`, se le pone un esqueleto humanoide y se usa "With Automatic Weights". Antes conviene separar la herramienta y el cesto de la malla: van colgados de la mano y de la espalda, como acá. Los modelos están con los brazos pegados al cuerpo, así que los pesos automáticos van a necesitar retoques en las axilas.
2. **En Godot, al importar el `.glb` riggeado** (pestaña Importar → Skeleton3D → Retarget): un `BoneMap` con `SkeletonProfileHumanoid`, con "Rest Fixer → Overwrite Axis" y "Fix Silhouette" encendidos.
3. **Lo mismo con `aldeano_kaykit.glb`**, con este mapa de huesos de KayKit al perfil humanoide:

| SkeletonProfileHumanoid | KayKit (Rig_Medium) |
|---|---|
| Root | root |
| Hips | hips |
| Spine / Chest | spine / chest |
| Head | head |
| LeftUpperArm / LeftLowerArm / LeftHand | upperarm.l / lowerarm.l / wrist.l |
| RightUpperArm / RightLowerArm / RightHand | upperarm.r / lowerarm.r / wrist.r |
| LeftUpperLeg / LeftLowerLeg / LeftFoot / LeftToes | upperleg.l / lowerleg.l / foot.l / toes.l |
| RightUpperLeg / RightLowerLeg / RightFoot / RightToes | upperleg.r / lowerleg.r / foot.r / toes.r |

   (`hand.*` y `handslot.*` quedan sin mapear; la herramienta se cuelga de la mano del modelo nuevo.)

4. **Con los dos en el mismo perfil**, la `AnimationLibrary` de KayKit se le aplica al modelo de Meshy tal cual.
5. **En el código**, `AldeanoAnimado.crear` arma hoy el esqueleto y la malla rígida. Con un modelo riggeado, `crear` instanciaría el `.glb` del pueblo (`estilo.modelos.aldeano`) y le daría la misma biblioteca. Todo lo demás (estados, paso, presupuesto, muerte) no cambia. Se podría dejar `_cerrar` y `PROP` para la figura de maqueta y saltearlos con el modelo riggeado, que ya tiene sus proporciones.

## Tropiezos

- **El botón de itch.io pide "pay what you want".** No hace falta pagar: el enlace "No thanks, just take me to the downloads" lleva a las descargas. Desde la terminal, el pedido `file/<id>` con la clave de la página de descargas devuelve "invalid key"; anda el mismo pedido que hace la página del juego (`source=view_game`).
- **La herramienta salía como una prolongación del brazo.** El primer glTF usaba el esqueleto del maniquí (sin `handslot`), y esos huesos se agregaban en Blender. Las animaciones guardan la rotación relativa al reposo de Blender, así que con un reposo distinto la mano quedaba girada 90°. Ahora la base es el esqueleto completo de `Rig_Medium_General.glb`, que trae los `handslot` con su reposo original. Para saber hacia dónde apunta el mango se miró cómo cuelga el hacha del Bárbaro de KayKit Adventurers (CC0): bajo `handslot.r`, el mango por +y.
- **Piernas abiertas y brazos separados:** venían del maniquí cabezón (ver el paso 2).
- **50 cambios de animación por cuadro:** el titileo de moverse y quedarse quieto en los montones. Se arregló con la histéresis.
- **GDScript caro por aldeano:** ver el paso 4.
- **La máquina cargada:** las mediciones de cuadros por segundo fluctúan ±20 % entre corridas iguales. Se compara el tiempo de la vista, que también está inflado, pero en los dos modos por igual.
- **El autotest termina bien** (`AUTOTEST: OK`), pero **Godot se cae al salir** (`corrupted size vs. prev_size while consolidating`). Pasa igual con `--animaciones=0` y ya estaba anotado en `proceso/22-testers/ronda-6/02-nuevo-en-rts.md`. No viene de este cambio.

## Pruebas

- `tests/test_determinism.gd`: **DETERMINISMO: OK**, `hash=2203695307`, el mismo de antes (`pruebas/test_determinism.txt`).
- `tests/bench.gd`: 200 unidades, 600 ticks, promedio de 18,6 ms contra un presupuesto de 100 ms, con la máquina cargada (`pruebas/bench.txt`).
- Autotest `--civ=guaranies --terreno=llano`: **AUTOTEST: OK** (`pruebas/autotest.txt`). Se revisó la captura a los 3 s ([05](capturas/05-despues-aldeanos-animados.jpg)) contra la de antes ([04](capturas/04-antes-modelos-meshy.jpg)).
- Cuadros por segundo con 200 aldeanos: `pruebas/fps_200_aldeanos.txt`.

## Peso agregado al repositorio

- `assets/animaciones/kaykit/`: 760 KB (el glTF de 724 KB, la textura de 18 KB, la licencia y los `.import`).
- Esta carpeta: 1,7 MB de capturas y 650 KB de videos.
- Código: `src/game/aldeano_animado.gd` (unas 600 líneas), `tools/aldeanos_animados.gd`, `tools/kaykit_extraer.py` y `data/arte_animaciones.json`, más unas 70 líneas en `world_view.gd` y 4 en `main.gd`.

## Lo que falta para los soldados

1. **Animaciones:** agregar a `tools/kaykit_extraer.py` las de combate: `Melee_1H_Attack_*`, `Melee_2H_*` (lanza, maza), `Melee_Block*`, `Ranged_Bow_*` (arco), `Ranged_1H/2H_*` (honda, arcabuz), `Running_A` para la carga, y `Hit_A`/`Hit_B`. Son unos 2 MB más en un segundo glTF, o en el mismo.
2. **Cuerpos:** las tropas de cada pueblo tienen más variedad que el aldeano (lanceros, honderos, arqueros, guerreros con escudo, cascos y pectorales por edad en `data/arte_edades.json → tropa`). Hace falta pasar `CivMeshes._person` y el equipo por edad a piezas por hueso, y colgar las armas de `handslot.r` y el escudo de `handslot.l`.
3. **Estados:** distinguir el disparo (tensar y soltar, en sincronía con `cooldown` y el evento `hit`), la carga y el bloqueo. La "lunge" de la maqueta pasa a ser la animación de golpe.
4. **Montados y elefantes:** KayKit no trae caballos. Quaternius (Ultimate Animated Animal Pack, CC0) tiene caballo, y el jinete sentado se puede armar con `Sit_*` de KayKit (en el paquete Simulation). Es un paso aparte.
5. **Rendimiento:** con cientos de soldados más los aldeanos, conviene **compartir esqueletos** entre las unidades que hacen lo mismo: un esqueleto por animación y por fase, y cada malla apunta a uno. Así el costo depende de cuántas animaciones distintas hay en pantalla, no de cuántas unidades. Se perdería la mezcla individual, pero de lejos no se nota.
6. **Velocidad (C-65):** con las animaciones puestas, ya se puede mirar a ×1 si el aldeano anda demasiado rápido para su tamaño. Hoy da unos 3 pasos por segundo.

## Para consultar con el autor

Va a `proceso/CONSULTAS.md` cuando se integre, porque esta tarea no toca ese archivo:

- **Piel:** hoy todos los aldeanos tienen el mismo tono, uno medio (`colores.piel` en `data/arte_animaciones.json`). Se puede poner un tono por pueblo en `vestimenta.<forma>.piel`, o dejarlo parejo, como la maqueta. ¿Cuál preferís?
- **¿Modelos de Meshy o cuerpo de maqueta?** De cerca, los modelos de Meshy son más ricos, pero no se mueven. Con `"activo": false` se vuelve a ellos. ¿Riggear los seis aldeanos de Meshy (en Blender, a mano, o con créditos) es el siguiente paso, o primero los soldados con el cuerpo de maqueta?

## Commits

- `Etapa 27, paso 1: aldeanos animados con KayKit` (rama `worktree-agent-a406bc140224885c4`).
