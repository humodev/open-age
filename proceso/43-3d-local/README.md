# 43 · Generación 3D local (2026-11-20)

> **Pedido del autor:** «Hagamos esa prueba, sí, con edificios, el aldeano y quizás un caballo, y veamos qué podemos hacer.»

Página: [`index.html`](index.html). Todo lo pesado vive fuera del repo, en
`/home/humodev/_01_Projects/gen3d/` (entornos, pesos, GLB crudos). En el repo, solo los
scripts (`tools/gen3d*.py`), esta carpeta con renders JPG y los GLB reducidos de menos de 2 MB.

## Reglas de la corrida

- Todo lo pesado (bajadas, ComfyUI, cada modelo y Blender) corre dentro de
  `systemd-run --user --scope -p MemoryMax=10G -p MemoryHigh=8G -p MemorySwapMax=1G`.
- Antes de cada paso, `free -g` con 12 GB o más disponibles. Una sola cosa por vez.
- La PC se colgó dos veces por RAM antes de esta etapa (generación de imágenes y otro agente
  en paralelo con la bajada); por eso los topes.

## Paso a paso

1. Repos clonados: Hunyuan3D-2 (Tencent), stable-fast-3d (Stability) y TripoSR (VAST).
   Un solo entorno `venv_hy` (Python 3.12, torch 2.11 cu128) sirve para Hunyuan y TripoSR.
2. Pesos bajados a `gen3d/hf`: Hunyuan3D-2mini (normal y turbo), Hunyuan3D-2mv (normal y
   turbo), Hunyuan3D-Paint turbo y delight (textura) y TripoSR.
3. Entradas (`tools/gen3d_entradas.py`): la hoja 3D del aldeano (edad I) recortada en frente y
   espalda, la kancha (casa) y la kallanka (cuartel), con el alfa sacado del fondo liso.
4. Caballo criollo con FLUX schnell (ComfyUI en un scope de 10 GB, con `--cache-none`).
   Semilla 7 ([img/caballo_7.jpg](img/caballo_7.jpg)): de perfil puro, se ven solo dos patas.
   Semilla 11 ([img/caballo_11.jpg](img/caballo_11.jpg)), «caminando, las cuatro patas
   separadas»: sirve. 54 s. Después, `POST /free` y ComfyUI apagado.
   Entradas: [img/entradas.jpg](img/entradas.jpg).
5. **Hunyuan3D-2mini turbo** (5 pasos, octree 256, FlashVDM), las 4 piezas con
   `tools/gen3d_correr.sh`: forma en 4–8 s, 45–100 s con la carga; VRAM 5,0 GB; RAM pico
   8,9–9,4 GB (entra en el tope de 10). Caras crudas: aldeano 137 mil, casa 550 mil, kallanka
   189 mil, caballo 204 mil. Vista rápida sin GPU (`tools/gen3d_vista.py`):
   [img/crudo_hy-mini-turbo.jpg](img/crudo_hy-mini-turbo.jpg). Las formas son buenas: el
   aldeano conserva la túnica, el cordón y los pies; la kancha, el muro bajo; la kallanka, las
   puertas y el escudo en relieve; el caballo, las cuatro patas.
6. Aldeano con **Hunyuan3D-2mini** normal (50 pasos): 29 s de forma, RAM 8,2 GB; apenas más
   detalle que el turbo. Con **Hunyuan3D-2mv turbo** (frente + espalda): 5,6 s, VRAM 6,1 GB,
   RAM 10,2 GB de pico. La espalda sale mejor resuelta (sin el relleno que inventa la vista
   única), pero la diferencia no se ve a la escala del RTS.
   [img/crudo_aldeano_hy-mini_y_mv.jpg](img/crudo_aldeano_hy-mini_y_mv.jpg) (arriba mini,
   abajo mv).
7. **TripoSR** (MIT), las 4 piezas: 3 s de forma, VRAM 3,1 GB, RAM 4,1 GB. Las personas y el
   caballo salen blandos y con base; los edificios conservan la inclinación de la cámara
   isométrica del ícono y se arman con la planta torcida.
   [img/crudo_triposr.jpg](img/crudo_triposr.jpg).
   Mediciones de cada corrida en [medidas/](medidas/).
8. **Blender 5.2 headless** (`tools/gen3d_blender.py`): suelda, borra piezas sueltas, diezma
   (aldeano y caballo 4000 caras, kancha 4000, kallanka 5000), apoya en el suelo, deja 1 de
   alto y exporta GLB (~100 KB). 1–10 s por pieza. Renders de frente, costado, tres cuartos y
   cámara del RTS (pitch 54°, fov 30): `img/gris_*.jpg`. A 4000 caras no se pierde nada que
   se vea a la escala del juego.
9. **Color sin Hunyuan-Paint** (`tools/gen3d_color.py`, solo CPU, 3–20 s): atlas UV con xatlas
   y textura de 512 px proyectando la imagen de entrada con una cámara ortográfica que se
   ajusta por silueta (IoU 0,79–0,95). Aldeano: frente y espalda de la hoja. Edificios: la
   misma imagen para la cara opuesta (planta simétrica). Caballo: el otro costado espejado.
   Lo que no ve ninguna vista toma el color de los vértices vecinos. `img/color_*.jpg`.
10. **En Godot** (`tools/visor_3d_local.gd`, escena aparte, sin tocar `src/sim` ni el arte del
    juego): los GLB pintados (aldeano de 2mv, kancha, kallanka y caballo de 2mini turbo,
    ~450 KB cada uno, textura JPG) en `assets/ui/arte/tawantinsuyu/modelos_prueba/`, junto a
    la maqueta procedural y al GLB de hoy (Meshy), con la cámara del RTS y la escala de
    `escala_visual` (personas a 0,75 de alto; edificios con el lado = tam − 2 × margen, sin
    el estiramiento a `altura_min_cm`). [img/juego_rts.jpg](img/juego_rts.jpg) y
    [img/juego_cerca.jpg](img/juego_cerca.jpg).

## Tropiezos

- **Stable Fast 3D** está «gated» en Hugging Face: sin cuenta y sin aceptar la licencia no se
  baja. No se crearon cuentas. Queda para el autor (ver abajo).
- **torchmcubes** (TripoSR) no compila sin el toolkit de CUDA (no está instalado): se cambió
  por un reemplazo en CPU con PyMCubes (`gen3d/TripoSR/torchmcubes.py`).
- La `*_mascara.png` de las hojas de proceso/42 es la de la túnica (para recolorear), no la
  silueta: el alfa sale del fondo.
- La hoja del aldeano muestra frente y **espalda**, no costado.
- FLUX con el tope de 10 GB se trabó en el decodificado (VAE) con la RAM al tope y el swap
  lleno: sin `--cache-none`, ComfyUI guarda el T5 y FLUX en RAM a la vez. Con `--cache-none`
  la imagen sale en menos de 80 s.
- hy3dgen 2.0 no carga con transformers 5 (cambiaron los nombres de DINOv2): se fijó
  transformers 4.49, diffusers 0.32 y huggingface_hub 0.36.
- En modo sin conexión, `snapshot_download` pide los `.ckpt` que no se bajaron: se apunta
  `HY3DGEN_MODELS` a enlaces a las instantáneas (`gen3d/modelos/tencent/...`).
- 2mv (1,1 B) no cargaba con el tope de 10 GB: hy3dgen arma todo en fp32 en RAM antes de
  pasarlo a la GPU. Parche: cada parte va a la GPU en fp16 apenas se carga
  ([hunyuan_cargador_poca_ram.patch](hunyuan_cargador_poca_ram.patch)).
- El reemplazo de torchmcubes tenía los ejes al revés (torchmcubes da z, y, x): las piezas
  salían acostadas. Corregido ([triposr_torchmcubes.py](triposr_torchmcubes.py)).
- Hay otro proceso del autor (perfil_sim de Godot, en su propio scope) corriendo a la vez:
  `tools/gen3d_correr.sh` espera a tener 12 GB disponibles antes de cada corrida.
- **Hunyuan3D-Paint** (textura) necesita compilar `custom_rasterizer` con nvcc. El paquete
  pip `nvidia-cuda-nvcc-cu12` trae solo `ptxas`, no `nvcc`, y el gcc 16 del sistema es más
  nuevo que el que acepta CUDA 12.8. Instalar el toolkit (paquete `cuda` de CachyOS o un
  entorno conda con `cuda-nvcc` y `gxx` 13) quedó para el autor: no se instaló nada fuera
  de gen3d. Por eso el color se proyecta con `tools/gen3d_color.py`.
- Un caballo de perfil puro tapa las patas del otro lado: para 3D hay que pedirlo caminando.

## Licencias

| Modelo | Licencia |
|---|---|
| Hunyuan3D-2 / 2mini / 2mv / Paint | Tencent Hunyuan 3D Community License: excluye la UE, el Reino Unido y Corea del Sur (Uruguay está bien); más de 1 M de usuarios activos por mes pide licencia aparte |
| Stable Fast 3D | Stability AI Community License: gratis por debajo de 1 M USD de ingresos al año |
| TripoSR | MIT |
| Blender | GPL (la herramienta; lo que se exporta es nuestro) |

## Commits

