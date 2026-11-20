#!/bin/bash
# Compila las dos extensiones de Hunyuan3D-Paint (custom_rasterizer con CUDA y
# mesh_processor en C++) dentro de venv_hy, con el toolkit CUDA 12.8 y el gcc 14 del
# entorno conda gen3d/cuda128 (el gcc 16 del sistema es demasiado nuevo para nvcc 12.8).
# Proceso 47. Uso: tools/gen3d_compilar_paint.sh  (correrlo dentro de un scope con tope).
set -e
G=/home/humodev/_01_Projects/gen3d
C=$G/cuda128
export CUDA_HOME=$C
export PATH=$C/bin:$PATH
# gcc 14 del entorno conda, con su sysroot (glibc 2.39). El gcc-14 de pacman también pasa el
# chequeo de versión, pero con la glibc del sistema los encabezados de CUDA 12.8 chocan en
# mathcalls.h (sinpi, cospi, rsqrt sin noexcept).
export CC=$C/bin/x86_64-conda-linux-gnu-gcc CXX=$C/bin/x86_64-conda-linux-gnu-g++
export TORCH_CUDA_ARCH_LIST="7.5"   # RTX 2060 SUPER
export MAX_JOBS=2
export TORCH_DONT_CHECK_COMPILER_ABI=1   # la tabla de torch pide gcc < 14 para CUDA 12.8; nvcc 12.8 acepta 14
export CPATH=$C/targets/x86_64-linux/include:${CPATH:-}   # conda deja los encabezados en targets/
export LIBRARY_PATH=$C/lib:$C/targets/x86_64-linux/lib:${LIBRARY_PATH:-}
cd $G/Hunyuan3D-2/hy3dgen/texgen/custom_rasterizer
uv pip install --python $G/venv_hy/bin/python --no-build-isolation --no-deps . 2>&1 | tail -5
cd $G/Hunyuan3D-2/hy3dgen/texgen/differentiable_renderer
uv pip install --python $G/venv_hy/bin/python pybind11 2>&1 | tail -1
$G/venv_hy/bin/python setup.py build_ext --inplace 2>&1 | tail -3
$G/venv_hy/bin/python -c "import torch, custom_rasterizer_kernel; print('custom_rasterizer ok')"
cd $G/Hunyuan3D-2/hy3dgen/texgen/differentiable_renderer && $G/venv_hy/bin/python -c "import mesh_processor; print('mesh_processor ok')"
