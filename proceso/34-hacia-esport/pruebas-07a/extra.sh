#!/bin/bash
# Pruebas sueltas de 07a: jinete con 3 de armadura de distancia, guardia de distancia a +18.
cd "$(dirname "$0")/../../.."
D=proceso/34-hacia-esport/pruebas-07a
godot --headless --path . -s tools/micro_matriz.gd -- --edad=2 --reaccion=400 --variantes=5 --parche=$D/p_arm3.json --casos="hondero:30|jinete:13|nada;hondero:30|jinete:13|escalonar;hondero:10|jinete:5|nada;hondero:10|jinete:5|escalonar" > $D/p_arm3-e2.txt 2>&1
godot --headless --path . -s tools/micro_matriz.gd -- --edad=4 --compras --reaccion=400 --variantes=5 --parche=$D/p_g18.json --casos="guardia_distancia:5|guardia:5|escalonar;guardia_distancia:5|guardia:5|mantener+escalonar;guardia_distancia:5|guerrero:26|escalonar;guardia_distancia:5|jinete:13|escalonar;guardia_distancia:5|lancero:22|nada;guardia_distancia:5|hondero:30|nada" > $D/p_g18-e4.txt 2>&1
for f in p_arm3-e2 p_g18-e4; do grep -h "^custom" $D/$f.txt | cut -d'|' -f2-4,7-9; done
