# 38 · Tripo por API (`tools/tripo_api.py`)

> Pedido: un cliente de Tripo igual en espíritu a `tools/meshy_api.py` (saldo, imagen a 3D, riggeo y animación si la API la trae), y el flujo para el aldeano inca.

Los endpoints salen de la documentación oficial de la **API v3** (`https://developers.tripo3d.ai/en/docs`, leída el 2026-11-19; agregando `.md` a cada página sale el texto crudo). La v2 (`api.tripo3d.ai/v2/openapi`, un solo `POST /task` con `type`) está en retiro: no se usa. Lo marcado **[verificar]** no quedó claro en la documentación.

**Saldo de la cuenta (2026-11-19): 105 créditos.** No son los 2000 de bienvenida que esperaba `README.md`: o ya se gastaron, o el regalo cambió [verificar en la consola]. Alcanza para **un aldeano** (modelo y riggeo), no para seis pueblos.

Lo único que se probó contra la API es `saldo`. Los otros comandos se probaron con `--seco` (arma el pedido y lo imprime sin mandarlo).

## Cómo usarlo

```sh
python3 tools/tripo_api.py saldo                       # gratis: imprime solo el número
python3 tools/tripo_api.py tarea <id>                  # gratis: estado y salida de una tarea
python3 tools/tripo_api.py imagen3d <png> <salida.glb> [--hoja] [--lado=left] [--poli=4000]
        [--modelo=v3.1-20260211] [--textura=standard|fast|detailed|no] [--pbr] [--sin-lowpoly] [--seco]
python3 tools/tripo_api.py riggear <id_tarea> <salida.glb> [--spec=mixamo] [--modelo=v3.0-20260909] [--seco]
python3 tools/tripo_api.py animar <id_rig> <salida.glb> preset:idle preset:walk ... [--en-lugar] [--seco]
```

- **Clave:** se lee de `TRIPO_ENV` (por defecto `../apex-open/.secrets/tripo.env`, línea `TRIPO_API_KEY=`), igual que Meshy con `MESHY_ENV`. Nunca se imprime ni se versiona.
- **Registro:** cada tarea cobrada se anota en `assets/generados/registro.jsonl` con `"servicio": "tripo"`, el id y los créditos.
- **`--seco`:** no gasta nada. Conviene correrlo antes de cada pedido real.
- **Por defecto, pensado para un RTS:** modelo `v3.1-20260211` (serie H) con `smart_low_poly` (topología limpia, de 500 a 20 000 triángulos) y `face_limit` 4000; textura `standard`; **sin PBR** (el juego usa solo color).
- **`--hoja`:** las hojas de `39-arte-interfaz` traen el **frente a la izquierda y el costado a la derecha** en una sola imagen de 1536×1024. El script la parte por la mitad y manda las dos vistas a `multiview-to-model` (`front` y `left`; `--lado=right` si el personaje mira para el otro lado). Sin `--hoja`, manda la imagen entera a `image-to-model`.
- **`riggear`** corre primero `rig-check` (gratis) y corta si Tripo no lo ve como humanoide (`biped`). Después riggea con `v3.0-20260909` (el recomendado para humanoides; el de la API por defecto sigue siendo `v1.0`) y huesos con nombres de **Mixamo**, que el `BoneMap` de Godot reconoce solo.
- **`animar`** existe porque la API la trae (retarget de animaciones prehechas, hasta 5 por tarea), pero **no hace falta**: las animaciones son las de KayKit (`27-animaciones`).

## Endpoints (base `https://openapi.tripo3d.ai/v3`, `Authorization: Bearer`)

| Uso | Endpoint | Notas |
|---|---|---|
| Saldo | `GET /account/balance` | `{balance, frozen}`, en créditos con decimales |
| Subir imagen | `POST /files` (multipart, campo `file`) | devuelve `file_token` (`file_…`); PNG o JPEG hasta 20 MB. Ya no se acepta base64 |
| Imagen a 3D | `POST /generation/image-to-model` | `input`, `model` (obligatorio), `face_limit`, `smart_low_poly`, `texture_quality`, `pbr`, `quad`, `geometry_quality` |
| Varias vistas a 3D | `POST /generation/multiview-to-model` | `inputs: [{front: …}, {left: …}, {back: …}, {right: …}]`; el frente es obligatorio, mínimo 2 |
| Serie P (low poly nativo) | los mismos, con `model: P1-20260311` o `P2-20260801` | P1: de 50 a 20 000 caras |
| ¿Se puede riggear? | `POST /animations/rig-check` | `{riggable, rig_type}` |
| Riggeo | `POST /animations/rig` | `input` (id de tarea), `model`, `rig_type: biped`, `spec: tripo/mixamo/unity/unreal/vrm/actorcore` |
| Animaciones | `POST /animations/retarget` | `animation` o `animations` (hasta 5); con rig v3.0: `preset:idle`, `walk`, `run`, `slash`, `shoot`, `hurt`, `fall`… |
| Estado de una tarea | `GET /tasks/{id}` | `queued`, `running`, `success`, `failed`, `cancelled`; el GLB en `output.model_url` |
| Bajar polígonos de uno hecho | `POST /mesh/decimate` | no está en el script; por si el low poly sale pesado |

## Costo por paso

Tabla oficial de precios por modelo (`developers.tripo3d.com/en/models/…`, en yuanes: 20 créditos = ¥1,40). Desde el 1 de diciembre de 2026 la consola muestra dólares, a 1 crédito = 0,01 USD; la API sigue contando en créditos. Las tareas que fallan o se cancelan **no cobran**.

| Paso | Créditos |
|---|---|
| `saldo`, `tarea`, `rig-check` | **0** |
| Imagen o varias vistas a 3D (H 3.1), sin textura | 20 |
| … con textura `standard` | **30** |
| … con textura `detailed` / 8K | 40 / 50 |
| + `smart_low_poly` | **+10** |
| + geometría `detailed` | +20 |
| + cuadriláteros (`quad`) | +5 |
| Serie P2 (100 sin textura, 110 con textura `standard`) | 100 a 130 |
| Serie P1 | ~80 + textura [verificar] |
| Riggeo | **25** |
| Retarget de animaciones | [verificar]: la tabla oficial no lo lista |

El ejemplo de respuesta de la documentación dice `credits_consumed: 100` para una imagen a 3D, que no cuadra con la tabla: **ver los créditos reales de la primera tarea** (el script los imprime y los anota) [verificar].

**Aldeano con el flujo por defecto:** 30 (vistas + textura standard) + 10 (low poly) + 25 (riggeo) = **65 créditos**. Con 105 sale uno, y queda para un reintento del modelo sin textura (30).

## Flujo propuesto para el aldeano inca

1. **Hoja 3D.** Generar `assets/ui/arte/tawantinsuyu/hojas3d/aldeano_m_e1.png` con el prompt de `39-arte-interfaz/prompts.html` (A-pose, manos vacías, frente y costado, fondo gris liso). La carpeta todavía no existe: hoy solo están los retratos de `referencia_3d/`. Las herramientas y el cesto **no** van en la hoja: se cuelgan de `handslot.r` y de la cadera, como ahora.
2. **GLB (40 créditos):**
   ```sh
   python3 tools/tripo_api.py imagen3d assets/ui/arte/tawantinsuyu/hojas3d/aldeano_m_e1.png \
       assets/generados/modelos/tawantinsuyu_aldeano_m_e1.glb --hoja --seco   # revisar, después sin --seco
   ```
   Mirar el GLB en Godot o Blender antes de seguir: si el costado salió espejado, repetir con `--lado=right`. Anotar el id de la tarea (sale en pantalla y en `registro.jsonl`).
3. **Rig (25 créditos):** `python3 tools/tripo_api.py riggear <id> assets/generados/modelos/tawantinsuyu_aldeano_m_e1_rig.glb`. Riggear desde el **id de la tarea**, no desde el archivo: así no se sube nada y Tripo usa su propia malla.
4. **Importar en Godot y mapear al esqueleto de KayKit** (lo que ya dejó escrito `27-animaciones/README.md`, "Cómo retargetear los modelos de Meshy"):
   - En el `.glb` riggeado: Importar → Skeleton3D → Retarget → `BoneMap` con `SkeletonProfileHumanoid`, "Rest Fixer → Overwrite Axis" y "Fix Silhouette" encendidos. Con nombres de Mixamo (`Hips`, `Spine`, `LeftArm`, `LeftForeArm`, `LeftUpLeg`…) el autocompletado del `BoneMap` los acierta casi todos [verificar si Tripo les pone el prefijo `mixamorig:`].
   - `personas_kaykit.glb` con el mismo perfil y la tabla de huesos de `27-animaciones` (`hips`, `upperarm.l`, `wrist.l`, `upperleg.l`…).
   - Con los dos en `SkeletonProfileHumanoid`, la `AnimationLibrary` de KayKit se le aplica al modelo nuevo tal cual. En `AldeanoAnimado.crear`, si `estilo.modelos.aldeano` apunta a un GLB riggeado, se instancia ese y se saltean `PROP` y `_cerrar` (el modelo ya tiene sus proporciones).
   - La herramienta: `handslot.r` no existe en el rig de Tripo. Se agrega un `BoneAttachment3D` en `RightHand` con el mismo giro que el de KayKit [verificar el giro a ojo].
5. **Si sale bien,** repetir por edad y por sexo. Ocho aldeanos incas (2 sexos × 4 edades) son **520 créditos**: hace falta recargar (5,20 USD) o esperar créditos gratis.

## Fuentes

- [Índice de la documentación](https://developers.tripo3d.ai/llms.txt), [imagen a 3D](https://developers.tripo3d.ai/en/docs/generation-image-to-model/standard), [varias vistas](https://developers.tripo3d.ai/en/docs/generation-multiview-to-model/standard), [riggeo](https://developers.tripo3d.ai/en/docs/animations-rig), [retarget](https://developers.tripo3d.ai/en/docs/animations-retarget), [archivos](https://developers.tripo3d.ai/en/docs/files), [cuenta](https://developers.tripo3d.ai/en/docs/account), [facturación](https://developers.tripo3d.ai/en/docs/billing), [migración v2 → v3](https://developers.tripo3d.com/assets/developer/tripo-v2-to-v3-migration/SKILL.md).
- Precios: [H 3.1](https://developers.tripo3d.com/en/models/v3-1), [P](https://developers.tripo3d.com/en/models/p1), [riggeo](https://developers.tripo3d.com/en/models/rig).
