#!/usr/bin/env python3
"""Cliente mínimo de la API de Meshy (copiado de apex-open, 2026-11-13).

    python3 tools/meshy_api.py saldo
    python3 tools/meshy_api.py imagen <salida.png> <modelo> <prompt> [--aspect=16:9] [--pose=t-pose] [--fondo] [--multivista]
    python3 tools/meshy_api.py editar <salida.png> <modelo> <imagen_base.png> <prompt>
    python3 tools/meshy_api.py modelo <salida.glb> <img1> [img2 img3 img4] [--poli=30000] [--pose=t-pose] [--pbr=1]
    python3 tools/meshy_api.py remesh <salida.glb> <id_de_tarea> [--poli=1500]

La clave sale de MESHY_ENV (por defecto ../apex-open/.secrets/meshy.env; nunca se versiona). Cada
tarea se anota en assets/generados/registro.jsonl (prompt, modelo, créditos,
id) para poder documentar de dónde salió cada asset (CREDITS.md).

Reglas: prompts con diseño propio, sin nombres de juegos ni obras ajenas;
todo lo generado se marca como tal en assets/CREDITOS.md.
"""
import base64
import json
import os
import sys
import time
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEYFILE = os.environ.get("MESHY_ENV", os.path.join(ROOT, "..", "apex-open", ".secrets", "meshy.env"))
API = "https://api.meshy.ai/openapi"
LOG = os.path.join(ROOT, "assets", "generados", "registro.jsonl")


def key():
    for line in open(KEYFILE):
        if line.startswith("MESHY_API_KEY="):
            return line.split("=", 1)[1].strip()
    raise SystemExit("falta MESHY_API_KEY en .secrets/meshy.env")


def call(method, path, body=None):
    req = urllib.request.Request(API + path, method=method, data=json.dumps(body).encode() if body else None,
                                 headers={"Authorization": "Bearer " + key(), "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read())


def data_uri(path):
    ext = os.path.splitext(path)[1].lower().lstrip(".")
    mime = {"jpg": "jpeg", "jpeg": "jpeg", "png": "png", "webp": "webp"}[ext]
    return "data:image/%s;base64,%s" % (mime, base64.b64encode(open(path, "rb").read()).decode())


def wait(kind, tid):
    while True:
        t = call("GET", "/v1/%s/%s" % (kind, tid))
        st = t.get("status")
        if st in ("SUCCEEDED", "FAILED", "CANCELED", "EXPIRED"):
            return t
        print("  %s %s%%" % (st, t.get("progress", 0)), flush=True)
        time.sleep(5)


def download(url, out):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=300) as r, open(out, "wb") as f:
        f.write(r.read())


def log(entry):
    os.makedirs(os.path.dirname(LOG), exist_ok=True)
    with open(LOG, "a") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def opts(args):
    o = {}
    for a in args:
        if a.startswith("--"):
            k, _, v = a[2:].partition("=")
            o[k] = v if v else True
    return o, [a for a in args if not a.startswith("--")]


def main():
    cmd, rest = sys.argv[1], sys.argv[2:]
    o, pos = opts(rest)
    if cmd == "saldo":
        print(call("GET", "/v1/balance"))
        return
    if cmd in ("imagen", "editar"):
        out, model = pos[0], pos[1]
        if cmd == "imagen":
            prompt = pos[2]
            body = {"ai_model": model, "prompt": prompt, "aspect_ratio": o.get("aspect", "1:1")}
            kind = "text-to-image"
        else:
            prompt = pos[3]
            body = {"ai_model": model, "prompt": prompt, "reference_image_urls": [data_uri(pos[2])]}
            kind = "image-to-image"
        if "pose" in o:
            body["pose_mode"] = o["pose"]
        if "fondo" in o:
            body["remove_background"] = True
        if "multivista" in o:
            body["generate_multi_view"] = True
        tid = call("POST", "/v1/" + kind, body)["result"]
        t = wait(kind, tid)
        if t.get("status") != "SUCCEEDED":
            raise SystemExit("falló: %s" % t.get("task_error"))
        urls = t.get("image_urls", [])
        paths = []
        for i, u in enumerate(urls):
            p = out if i == 0 else out.replace(".png", "_%d.png" % i)
            download(u, p)
            paths.append(p)
        log({"tarea": kind, "id": tid, "modelo": model, "prompt": prompt, "salida": paths, "creditos": t.get("consumed_credits"),
             "base": pos[2] if cmd == "editar" else None})
        print("listo", paths, "créditos", t.get("consumed_credits"))
        return
    if cmd == "modelo":
        out, imgs = pos[0], pos[1:]
        body = {"image_urls": [data_uri(p) for p in imgs], "ai_model": "latest", "topology": "triangle",
                "target_polycount": int(o.get("poli", 30000)), "should_texture": True}
        if "pose" in o:
            body["pose_mode"] = o["pose"]
        if o.get("pbr") == "1":  # mapas PBR (metal, rugosidad, normal) además del color
            body["enable_pbr"] = True
        kind = "multi-image-to-3d"
        tid = call("POST", "/v1/" + kind, body)["result"]
        t = wait(kind, tid)
        if t.get("status") != "SUCCEEDED":
            raise SystemExit("falló: %s" % t.get("task_error"))
        download(t["model_urls"]["glb"], out)
        log({"tarea": kind, "id": tid, "imagenes": imgs, "salida": out, "creditos": t.get("consumed_credits")})
        print("listo", out, "créditos", t.get("consumed_credits"))
        return
    if cmd == "remesh":  # rehace la malla de una tarea ya hecha con pocos polígonos y la textura rehorneada
        out, src = pos[0], pos[1]
        body = {"input_task_id": src, "target_formats": ["glb"], "topology": "triangle",
                "target_polycount": int(o.get("poli", 1500))}
        kind = "remesh"
        tid = call("POST", "/v1/" + kind, body)["result"]
        t = wait(kind, tid)
        if t.get("status") != "SUCCEEDED":
            raise SystemExit("falló: %s" % t.get("task_error"))
        download(t["model_urls"]["glb"], out)
        log({"tarea": kind, "id": tid, "base": src, "salida": out, "creditos": t.get("consumed_credits")})
        print("listo", out, "créditos", t.get("consumed_credits"))
        return
    raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
