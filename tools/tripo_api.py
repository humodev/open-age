#!/usr/bin/env python3
"""Cliente mínimo de la API v3 de Tripo (2026-11-19), hermano de tools/meshy_api.py.

    python3 tools/tripo_api.py saldo
    python3 tools/tripo_api.py tarea <id>
    python3 tools/tripo_api.py imagen3d <imagen.png> <salida.glb> [--hoja] [--lado=left] [--poli=4000]
                                        [--modelo=v3.1-20260211] [--textura=standard] [--pbr] [--sin-lowpoly] [--seco]
    python3 tools/tripo_api.py riggear <id_de_tarea> <salida.glb> [--spec=mixamo] [--modelo=v3.0-20260909] [--seco]
    python3 tools/tripo_api.py animar <id_de_rig> <salida.glb> <preset> [preset ...] [--en-lugar] [--seco]

Documentación: https://developers.tripo3d.ai/en/docs (agregando .md a cada página sale el texto crudo).
Uso y costos: proceso/38-alternativas-a-meshy/tripo.md.

La clave sale de TRIPO_ENV (por defecto ../apex-open/.secrets/tripo.env; nunca se versiona ni se
imprime). Cada tarea se anota en assets/generados/registro.jsonl, como las de Meshy.

--seco imprime el pedido sin mandarlo: no gasta créditos. `saldo`, `tarea` y la revisión de
riggeo (rig-check) son gratis; el resto cobra.

Reglas: imágenes de diseño propio, sin nombres de juegos ni obras ajenas;
todo lo generado se marca como tal en assets/CREDITOS.md.
"""
import io
import json
import os
import sys
import time
import urllib.error
import urllib.request
import uuid

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEYFILE = os.environ.get("TRIPO_ENV", os.path.join(ROOT, "..", "apex-open", ".secrets", "tripo.env"))
API = "https://openapi.tripo3d.ai/v3"  # internacional; la de China es openapi.tripo3d.com
LOG = os.path.join(ROOT, "assets", "generados", "registro.jsonl")

# Valores por defecto pensados para un RTS (se ven chicos y en cantidad).
MODELO_3D = "v3.1-20260211"     # serie H; "P1-20260311" o "P2-20260801" para la serie P (low poly nativo)
MODELO_RIG = "v3.0-20260909"    # el recomendado para humanoides (el de la API por defecto es v1.0)
POLI = 4000                     # smart_low_poly acepta de 500 a 20000 triángulos


def key():
    for line in open(KEYFILE):
        if line.startswith("TRIPO_API_KEY="):
            return line.split("=", 1)[1].strip()
    raise SystemExit("falta TRIPO_API_KEY en .secrets/tripo.env")


def _request(method, path, data=None, ctype=None):
    headers = {"Authorization": "Bearer " + key()}
    if ctype:
        headers["Content-Type"] = ctype
    req = urllib.request.Request(API + path, method=method, data=data, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            res = json.loads(r.read())
    except urllib.error.HTTPError as e:  # el cuerpo del error no trae la clave
        raise SystemExit("HTTP %d en %s: %s" % (e.code, path, e.read().decode(errors="replace")[:500]))
    if res.get("code", 0) != 0:
        raise SystemExit("error %s en %s: %s" % (res.get("code"), path, res.get("message", res)))
    return res["data"]


def call(method, path, body=None):
    return _request(method, path, json.dumps(body).encode() if body is not None else None,
                    "application/json" if body is not None else None)


def upload(name, raw):
    """Sube una imagen (PNG o JPEG, hasta 20 MB) y devuelve su file_token."""
    b = uuid.uuid4().hex
    mime = "image/jpeg" if name.lower().endswith((".jpg", ".jpeg")) else "image/png"
    body = (("--%s\r\nContent-Disposition: form-data; name=\"file\"; filename=\"%s\"\r\n"
             "Content-Type: %s\r\n\r\n") % (b, os.path.basename(name), mime)).encode() + raw + ("\r\n--%s--\r\n" % b).encode()
    return _request("POST", "/files", body, "multipart/form-data; boundary=" + b)["file_token"]


def halves(path, lado):
    """Parte una hoja de referencia (frente y costado lado a lado) en dos PNG en memoria."""
    from PIL import Image
    im = Image.open(path).convert("RGB")
    w, h = im.size
    out = []
    for box in ((0, 0, w // 2, h), (w // 2, 0, w, h)):
        buf = io.BytesIO()
        im.crop(box).save(buf, "PNG")
        out.append(buf.getvalue())
    return {"front": out[0], lado: out[1]}


def wait(tid):
    while True:
        t = call("GET", "/tasks/" + tid)
        st = t.get("status")
        if st in ("success", "failed", "cancelled"):
            return t
        print("  %s %s%%" % (st, t.get("progress", 0)), flush=True)
        time.sleep(4)


def download(url, out):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=300) as r, open(out, "wb") as f:
        f.write(r.read())


def log(entry):
    os.makedirs(os.path.dirname(LOG), exist_ok=True)
    with open(LOG, "a") as f:
        f.write(json.dumps(dict(servicio="tripo", **entry), ensure_ascii=False) + "\n")


def opts(args):
    o = {}
    for a in args:
        if a.startswith("--"):
            k, _, v = a[2:].partition("=")
            o[k] = v if v else True
    return o, [a for a in args if not a.startswith("--")]


def run(path, body, out, extra, seco):
    """Crea la tarea, la espera, baja output.model_url y la anota en el registro."""
    if seco:
        print("POST", path, json.dumps(body, ensure_ascii=False))
        return None
    tid = call("POST", path, body)["task_id"]
    print("tarea", tid, flush=True)
    t = wait(tid)
    if t.get("status") != "success":
        raise SystemExit("falló: %s %s" % (t.get("error_code"), t.get("error_msg", t)))
    download(t["output"]["model_url"], out)
    log(dict(tarea=path, id=tid, salida=out, creditos=t.get("credits_consumed"), **extra))
    print("listo", out, "tarea", tid, "créditos", t.get("credits_consumed"))
    return t


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    cmd, rest = sys.argv[1], sys.argv[2:]
    o, pos = opts(rest)
    seco = "seco" in o
    if cmd == "saldo":
        print(call("GET", "/account/balance")["balance"])
        return
    if cmd == "tarea":
        print(json.dumps(call("GET", "/tasks/" + pos[0]), indent=1, ensure_ascii=False))
        return
    if cmd == "imagen3d":
        img, out = pos[0], pos[1]
        modelo = o.get("modelo", MODELO_3D)
        body = {"model": modelo}
        if o.get("textura") == "no":
            body["texture"] = False
        else:
            body["texture_quality"] = o.get("textura", "standard")
        body["pbr"] = "pbr" in o  # el RTS no usa metal ni rugosidad: solo color
        if modelo.startswith("v3"):
            if "sin-lowpoly" not in o:
                body["smart_low_poly"] = True  # +10 créditos; topología limpia, de 500 a 20000 triángulos
            body["face_limit"] = int(o.get("poli", POLI))
        elif modelo.startswith("P"):
            body["face_limit"] = int(o.get("poli", POLI))  # P1: de 50 a 20000 caras
        if "hoja" in o:  # hoja de referencia: frente a la izquierda, costado a la derecha
            lado = o.get("lado", "left")  # left: el personaje mira hacia su izquierda en el costado [verificar]
            vistas = halves(img, lado)
            path = "/generation/multiview-to-model"
            if seco:
                body["inputs"] = [{k: "<%s>" % k} for k in vistas]
            else:
                body["inputs"] = [{k: upload("%s_%s.png" % (img, k), v)} for k, v in vistas.items()]
        else:
            path = "/generation/image-to-model"
            body["input"] = "<file_token>" if seco else upload(img, open(img, "rb").read())
        run(path, body, out, {"imagen": img, "modelo": modelo}, seco)
        return
    if cmd == "riggear":
        src, out = pos[0], pos[1]
        if not seco:  # gratis: dice si se puede riggear y con qué tipo de esqueleto
            chk = wait(call("POST", "/animations/rig-check", {"input": src})["task_id"])
            res = chk.get("output", {})
            print("rig-check:", res)
            if not res.get("riggable", False):
                raise SystemExit("Tripo dice que el modelo no se puede riggear")
            if res.get("rig_type", "biped") != "biped":
                raise SystemExit("Tripo lo ve como %s, no como humanoide" % res.get("rig_type"))
        body = {"input": src, "model": o.get("modelo", MODELO_RIG), "rig_type": "biped",
                "spec": o.get("spec", "mixamo"), "out_format": "glb"}
        run("/animations/rig", body, out, {"base": src, "spec": body["spec"]}, seco)
        return
    if cmd == "animar":  # retarget de animaciones de Tripo, hasta 5 por tarea
        src, out, presets = pos[0], pos[1], pos[2:]
        if not presets or len(presets) > 5:
            raise SystemExit("hace falta de 1 a 5 presets (preset:idle, preset:walk, preset:run, ...)")
        body = {"input": src, "out_format": "glb", "animate_in_place": "en-lugar" in o}
        if len(presets) == 1:
            body["animation"] = presets[0]
        else:
            body["animations"] = presets
        run("/animations/retarget", body, out, {"base": src, "animaciones": presets}, seco)
        return
    raise SystemExit(__doc__)


if __name__ == "__main__":
    main()
