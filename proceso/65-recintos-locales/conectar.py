#!/usr/bin/env python3
"""Conecta (o desconecta) las piezas del proceso 65 con un renglón de estilo.modelos.

    python3 proceso/65-recintos-locales/conectar.py <pueblo> tipo=valor [tipo=valor ...]
    python3 proceso/65-recintos-locales/conectar.py <pueblo> -tipo           borra el renglón

Edita el texto de data/civs/<pueblo>.json sin reformatearlo: solo agrega, cambia o borra el
renglón "<tipo>": "<valor>" dentro de estilo.modelos (valor: recinto/<clave> o local/<modelo>).
"""
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]


def main():
    civ, cambios = sys.argv[1], sys.argv[2:]
    f = REPO / f"data/civs/{civ}.json"
    s = f.read_text()
    i = s.index('"modelos": {', s.index('"estilo"'))
    j = s.index("}", i)
    bloque = s[i:j]
    lineas = bloque.split("\n")
    entradas = [l for l in lineas[1:] if l.strip()]
    sangria = re.match(r"\s*", entradas[0]).group(0)
    pares = [(json.loads("{" + l.strip().rstrip(",") + "}")) for l in entradas]
    orden = [list(p.items())[0] for p in pares]
    d = dict(orden)
    for c in cambios:
        if c.startswith("-"):
            d.pop(c[1:], None)
        else:
            k, v = c.split("=", 1)
            d[k] = v
    cierre = lineas[-1] if not lineas[-1].strip() else ""
    nuevo = '"modelos": {\n' + ",\n".join(f'{sangria}{json.dumps(k, ensure_ascii=False)}: {json.dumps(v, ensure_ascii=False)}' for k, v in d.items()) + "\n" + re.match(r"\s*", s[s.rindex("\n", 0, j) + 1:j]).group(0)
    s = s[:i] + nuevo + s[j:]
    json.loads(s)
    f.write_text(s)
    print(civ, "→", {k: d.get(k) for k in [c.lstrip("-").split("=")[0] for c in cambios]})


if __name__ == "__main__":
    main()
