# 47 · Pipeline 3D local repetible (2026-11-20)

> **Pedido del autor:** un pipeline repetible, para regenerar y mejorar arte y modelos más
> adelante: no la perfección ahora, sino todo armado de punta a punta.

(en curso)

## Paso a paso

1. **Hunyuan3D-Paint compilado.** El entorno `gen3d/cuda128` (a medio armar desde el cuelgue)
   se completó sin red desde el caché de micromamba (`gen3d/mamba`): nvcc 12.8.93, encabezados
   (cuBLAS, cuSPARSE, cuSOLVER…) y gcc 14.4 de conda-forge. Después se borró `gen3d/mamba`
   (5,3 GB). `tools/gen3d_compilar_paint.sh` compila `custom_rasterizer` (CUDA, sm_75) y
   `mesh_processor` (C++) en `venv_hy`, con MAX_JOBS=2 y dentro del scope de 12 GB.
2. **Paint con poca memoria** (`tools/gen3d_paint.py`): un modelo por vez (primero el que quita
   luces, se libera, después el multivista), la unet con descarga a CPU y el VAE de a una vista.
   Aldeano: 12,8 s de textura, 18 s de carga, VRAM 4,3 GB. Comparación con el proyector:
   [img/aldeano_paint_vs_proyector.jpg](img/aldeano_paint_vs_proyector.jpg) (arriba Paint,
   abajo el proyector): Paint deja la cara limpia y cubre el costado; el proyector mancha la cara
   con la espalda.

## Tropiezos

- `gen3d/cuda128` tenía solo 15 MB: el conda-meta listaba los paquetes pero faltaban los
  archivos (la instalación se cortó con el cuelgue). Todo estaba bajado en `gen3d/mamba`.
- torch 2.11 pide gcc < 14 para CUDA 12.8 (su tabla), aunque nvcc 12.8 acepta 14:
  `TORCH_DONT_CHECK_COMPILER_ABI=1`.
- Con el gcc-14 de pacman (14.3.1), los encabezados de CUDA 12.8 chocan con la glibc del
  sistema en `mathcalls.h` (sinpi, cospi, rsqrt sin `noexcept`). El gcc 14 de conda trae su
  sysroot (glibc 2.39) y compila limpio: se usa ese.
- conda deja los encabezados en `targets/x86_64-linux/include`: hace falta `CPATH`.
- `venv_hy` es de uv, sin pip: `uv pip install --python venv_hy/bin/python`.
- La unet del multivista se cargaba del `.bin` en fp32 (7,3 GB) y armaba el modelo en fp32:
  el proceso llegaba al tope de 12 GB y se trababa en swap (se cortó dos veces a mano). Parche
  ([hunyuan_paint_poca_ram.patch](hunyuan_paint_poca_ram.patch)): modelo en el dispositivo
  «meta», `.bin` con mmap y cada peso a fp16 de a uno. Ojo: diffusers no usa el `modules.py`
  del repo sino el de la carpeta de pesos (`unet/modules.py`), que se reemplazó por una copia
  parchada. El `.safetensors` de esa carpeta es otra variante (con IP-Adapter) y no calza.
- Con todo en la GPU, el VAE se quedó sin VRAM al decodificar las 6 vistas: descarga a CPU y
  VAE de a una vista.

## Commits

