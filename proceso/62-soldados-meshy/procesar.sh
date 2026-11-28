#!/bin/bash
# Receta de proceso/56 y 57 para un soldado crudo de Meshy, de a un proceso y con tope de memoria:
#   proceso/62-soldados-meshy/procesar.sh <civ>_<unidad>
# Entrada: .cache/meshy_soldados/<x>.glb. Salida: assets/generados/modelos/meshy_soldados/<x>.glb y
# <x>_mascara.png; luz_ref en .cache/meshy_soldados/proc/<x>_mascara.log.
set -e
x="$1"
R=/mnt/games/01_Projects/open-age
C=$R/.cache/meshy_soldados
P=$C/proc
D=$R/assets/generados/modelos/meshy_soldados
PY=/mnt/games/01_Projects/comfyui/venv/bin/python
mkdir -p "$P" "$D"
lim() { systemd-run --user --scope -q -p MemoryMax=4G -p MemorySwapMax=1G timeout 1800 "$@"; }
disp() { awk '/MemAvailable/{print int($2/1048576)}' /proc/meminfo; }
while [ "$(disp)" -lt 7 ]; do echo "esperando 7 GB libres ($(disp))"; sleep 30; done
lim blender --background --python $R/tools/optimizar_glb.py -- "$C/$x.glb" "$P/${x}_opt.glb" 15000 2048 solo_color > "$P/${x}_opt.log" 2>&1
lim blender --background --python $R/tools/gen3d_rig.py -- "$P/${x}_opt.glb" "$P/${x}_rig.glb" "$P/${x}_mixamo.fbx" "$P/${x}_prueba" --normalizar --cabeza-rigida --calor-escala=10 > "$P/${x}_rig.log" 2>&1
lim blender --background --python $R/tools/mascara_equipo_3d.py -- "$P/${x}_rig.glb" "$P/${x}_mascara.png" --metodo=rojo > "$P/${x}_mascara.log" 2>&1
$PY $R/proceso/62-soldados-meshy/glb_jpeg.py "$P/${x}_rig.glb" "$D/$x.glb" 80
cp "$P/${x}_mascara.png" "$D/${x}_mascara.png"
grep -hE "^RIG|MASCARA|triangulos" "$P/${x}_rig.log" "$P/${x}_mascara.log" "$P/${x}_opt.log" | tail -8
ls -la "$D/$x.glb"
