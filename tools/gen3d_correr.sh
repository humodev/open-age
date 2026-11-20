#!/bin/bash
# Corre una pieza con un modelo, de a una, dentro del scope de 10 GB (proceso/43).
# uso: correr.sh <modelo> <pieza> <entrada> [args extra]
cd /home/humodev/_01_Projects/gen3d
m=$1; p=$2; e=$3; shift 3
while [ "$(free -g | awk '/^Mem/{print $7}')" -lt 12 ]; do echo "esperando RAM"; sleep 20; done
systemd-run --user --scope -q -p MemoryMax=10G -p MemoryHigh=8G -p MemorySwapMax=1G \
  venv_hy/bin/python /mnt/games/01_Projects/open-age/tools/gen3d.py --modelo $m --entrada $e \
  --salida salidas/${p}_$m "$@" > salidas/log_${p}_$m.txt 2>&1
echo "$p $m salida=$? $(tail -1 salidas/log_${p}_$m.txt | cut -c1-400)"
