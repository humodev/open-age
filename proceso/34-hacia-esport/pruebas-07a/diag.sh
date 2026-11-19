#!/bin/bash
# civ_diag de 07a: 30 partidas (3 semillas × 10 cruces) de mapuches y guaraníes, con los datos nuevos.
cd "$(dirname "$0")/../../.."
D=proceso/34-hacia-esport/pruebas-07a
for c in mapuches guaranies; do
	timeout 5400 godot --headless --path . -s tools/civ_diag.gd -- --civ=$c --seeds=3 --breve 2>&1 | grep -v -E "WARNING|ERROR|^\s+at:" > $D/diag-$c.txt
done
echo fin
