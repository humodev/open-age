#!/usr/bin/env python3
"""Rig y caminata de Meshy sobre un modelo ya hecho (proceso/55-comparar-aldeanos). Solo herramienta.

    MESHY_ENV=/ruta/meshy.env python3 tools/meshy_rig.py <salida_dir> (--tarea=<id> | --glb=<modelo.glb>) [--alto=1.6]
    MESHY_ENV=/ruta/meshy.env python3 tools/meshy_rig.py <salida_dir> --animar=<id del rig> --acciones=0,237,8 [--nombre=acciones]

POST /openapi/v1/animations con action_ids (3 créditos por acción): un GLB con un clip por acción,
en el orden pedido, con el nombre de la biblioteca de Meshy.

POST /openapi/v1/rigging (5 créditos): devuelve el personaje riggeado y, de regalo, la caminata y
la carrera (basic_animations). Anota cada tarea y el saldo antes y después en
<salida_dir>/registro.jsonl. La clave nunca se imprime.
"""
import base64
import json
import os
import sys
import time
import urllib.error

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import meshy_api as M  # noqa: E402


def main():
    out = sys.argv[1]
    o = dict(a[2:].split("=", 1) for a in sys.argv[2:] if a.startswith("--") and "=" in a)
    os.makedirs(out, exist_ok=True)
    antes = M.call("GET", "/v1/balance")["balance"]
    if "animar" in o:
        return animar(out, o, antes)
    body = {"height_meters": float(o.get("alto", "1.6"))}
    if "tarea" in o:
        body["input_task_id"] = o["tarea"]
    else:
        body["model_url"] = "data:application/octet-stream;base64," + base64.b64encode(open(o["glb"], "rb").read()).decode()
    try:
        r = M.call("POST", "/v1/rigging", body)
    except urllib.error.HTTPError as e:
        print("error", e.code, e.read().decode()[:500])
        sys.exit(1)
    tid = r.get("result")
    print("tarea", tid, flush=True)
    t = M.wait("rigging", tid)
    print("estado", t.get("status"), t.get("task_error"))
    res = t.get("result") or {}
    bajados = {}
    pares = [("riggeado.glb", res.get("rigged_character_glb_url"))]
    for k, v in (res.get("basic_animations") or {}).items():
        if k.endswith("_glb_url"):
            pares.append((k.replace("_glb_url", ".glb"), v))
    for nombre, url in pares:
        if url:
            M.download(url, os.path.join(out, nombre))
            bajados[nombre] = os.path.getsize(os.path.join(out, nombre))
    time.sleep(2)
    despues = M.call("GET", "/v1/balance")["balance"]
    entrada = {k: v for k, v in body.items() if k != "model_url"}
    if "glb" in o:
        entrada["glb"] = o["glb"]
    reg = {"tarea": "rigging", "id": tid, "entrada": entrada, "estado": t.get("status"),
           "saldo_antes": antes, "saldo_despues": despues, "creditos": antes - despues, "archivos": bajados}
    with open(os.path.join(out, "registro.jsonl"), "a") as f:
        f.write(json.dumps(reg, ensure_ascii=False) + "\n")
    print(json.dumps(reg, ensure_ascii=False))


def animar(out, o, antes):
    ids = [int(x) for x in o["acciones"].split(",")]
    try:
        r = M.call("POST", "/v1/animations", {"rig_task_id": o["animar"], "action_ids": ids})
    except urllib.error.HTTPError as e:
        print("error", e.code, e.read().decode()[:500])
        sys.exit(1)
    tid = r.get("result")
    print("tarea", tid, flush=True)
    t = M.wait("animations", tid)
    print("estado", t.get("status"), t.get("task_error"))
    res = t.get("result") or {}
    nombre = o.get("nombre", "acciones") + ".glb"
    bajados = {}
    if res.get("animation_glb_url"):
        M.download(res["animation_glb_url"], os.path.join(out, nombre))
        bajados[nombre] = os.path.getsize(os.path.join(out, nombre))
    time.sleep(2)
    despues = M.call("GET", "/v1/balance")["balance"]
    reg = {"tarea": "animations", "id": tid, "rig": o["animar"], "acciones": ids, "estado": t.get("status"),
           "consumidos": t.get("consumed_credits"), "saldo_antes": antes, "saldo_despues": despues,
           "creditos": antes - despues, "archivos": bajados}
    with open(os.path.join(out, "registro.jsonl"), "a") as f:
        f.write(json.dumps(reg, ensure_ascii=False) + "\n")
    print(json.dumps(reg, ensure_ascii=False))


if __name__ == "__main__":
    main()
