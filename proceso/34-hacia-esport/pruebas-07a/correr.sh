#!/bin/bash
# Corre la matriz de 07a: antes y con cada parche. Uso: bash correr.sh [parches...] (vacío = ninguno)
cd "$(dirname "$0")/../../.."
D=proceso/34-hacia-esport/pruebas-07a
E2="hondero:30|jinete:13|nada;hondero:30|jinete:13|escalonar;hondero:10|jinete:5|nada;hondero:10|jinete:5|escalonar;hondero:30|guerrero:26|escalonar;hondero:30|guerrero:26|nada;hondero:30|lancero:22|nada;hondero:10|guerrero:9|escalonar"
E4="guardia_distancia:5|guardia:5|escalonar;guardia_distancia:5|guardia:5|mantener+escalonar;guardia_distancia:5|guerrero:26|escalonar;guardia_distancia:5|jinete:13|escalonar;guardia_distancia:5|lancero:22|nada;guardia_distancia:5|lancero:22|escalonar;guardia_distancia:5|hondero:30|nada;hondero:30|guerrero:26|escalonar;hondero:30|jinete:13|escalonar;hondero:30|jinete:13|nada;hondero:30|lancero:22|nada;hondero:10|jinete:5|nada"
for p in "$@"; do
	if [ "$p" = "antes" ]; then P=""; else P="--parche=$D/$p.json"; fi
	godot --headless --path . -s tools/micro_matriz.gd -- --edad=2 --reaccion=400 --variantes=5 $P --casos="$E2" > $D/$p-e2.txt 2>&1
	godot --headless --path . -s tools/micro_matriz.gd -- --edad=4 --compras --reaccion=400 --variantes=5 $P --casos="$E4" > $D/$p-e4.txt 2>&1
	godot --headless --path . -s tools/micro_matriz.gd -- --edad=2 --reaccion=400 --variantes=5 $P > $D/$p-matriz.txt 2>&1
done
echo listo
