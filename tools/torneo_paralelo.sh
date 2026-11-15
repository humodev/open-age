#!/usr/bin/env bash
# Torneo en paralelo (proceso/21): reparte los cruces de tests/torneo.gd en N procesos y junta
# las partidas con el resumen de victorias (con puntos) por civ.
# Uso: tools/torneo_paralelo.sh SALIDA.txt [MINUTOS=30] [SEMILLAS=2] [PROCESOS=6]
set -u
out="$1"; minutes="${2:-30}"; seeds="${3:-2}"; n="${4:-6}"
tmp="$(mktemp -d)"
for ((i = 0; i < n; i++)); do
	godot --headless --path . -s tests/torneo.gd -- --minutes="$minutes" --seeds="$seeds" --parte="$i/$n" 2>/dev/null \
		| grep -E " vs .*ganador:" > "$tmp/parte$i.txt" &
done
wait
cat "$tmp"/parte*.txt | sort > "$out"
python3 - "$out" <<'PY'
import re, sys, collections
f = sys.argv[1]
w = collections.Counter(); g = collections.Counter(); ko = 0; n = 0
for l in open(f):
    m = re.match(r'(\w+)\s+vs\s+(\w+)\s+terreno=\S+\s+(\S+)\s+ganador:\s+\(?(\w+)', l)
    if not m:
        continue
    n += 1
    a, b, t, win = m.groups()
    g[a] += 1; g[b] += 1; w[win] += 1
    if '(' not in l.split('ganador:')[1][:3]:
        ko += 1
lines = ["", "Partidas: %d · por destrucción de hitos: %d" % (n, ko), "Victorias (con puntos):"]
for c in sorted(g):
    lines.append("  %-13s %3d %%  (%d de %d)" % (c, 100 * w[c] // g[c], w[c], g[c]))
open(f, "a").write("\n".join(lines) + "\n")
print("\n".join(lines))
PY
rm -rf "$tmp"
