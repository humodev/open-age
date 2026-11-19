#!/bin/bash
# 07b: hondero en masa contra jinete en la IV con compras. Uso: bash correr.sh nombre [parche.json]
# Corre los casos dirigidos (II y IV con compras) y la matriz por defecto (II y IV con compras).
cd "$(dirname "$0")/../../.."
D=proceso/34-hacia-esport/pruebas-07b
N=$1; P=""; [ -n "$2" ] && P="--parche=$2"
C="hondero:30|jinete:13|nada;hondero:30|jinete:13|escalonar;hondero:10|jinete:5|nada;hondero:10|jinete:5|escalonar;hondero:30|guerrero:26|escalonar;hondero:30|guerrero:26|nada;hondero:30|lancero:22|nada;guerrero:26|jinete:13|nada;lancero:22|jinete:13|nada"
for e in 2 4; do
	godot --headless --path . -s tools/micro_matriz.gd -- --edad=$e --compras --reaccion=400 --variantes=5 $P --casos="$C" > $D/$N-e$e.txt 2>&1
done
if [ "$3" = "matriz" ]; then
	for e in 2 4; do
		godot --headless --path . -s tools/micro_matriz.gd -- --edad=$e --compras --reaccion=400 --variantes=5 $P > $D/$N-matriz-e$e.txt 2>&1
	done
fi
echo listo
