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
- Un caballo de perfil puro tapa las patas del otro lado: para 3D hay que pedirlo caminando.

## Licencias

| Modelo | Licencia |
|---|---|
| Hunyuan3D-2 / 2mini / 2mv / Paint | Tencent Hunyuan 3D Community License: excluye la UE, el Reino Unido y Corea del Sur (Uruguay está bien); más de 1 M de usuarios activos por mes pide licencia aparte |
| Stable Fast 3D | Stability AI Community License: gratis por debajo de 1 M USD de ingresos al año |
| TripoSR | MIT |
| Blender | GPL (la herramienta; lo que se exporta es nuestro) |

## Commits

