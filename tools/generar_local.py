#!/usr/bin/env python3
"""Genera imágenes con ComfyUI local (API HTTP), con IP-Adapter para copiar estilo.

ComfyUI vive fuera del repo, en /mnt/games/01_Projects/comfyui (ver
proceso/40-generacion-local/README.md). Arrancarlo antes con:

    /mnt/games/01_Projects/comfyui/arrancar.sh

Ejemplos (correr con el python del entorno de ComfyUI, que tiene Pillow y rembg):

    PY=/mnt/games/01_Projects/comfyui/venv/bin/python
    $PY tools/generar_local.py "Unit portrait of an Inka slinger, painterly" \
        --ref assets/ui/arte/tawantinsuyu/retratos/*.png --peso-ref 0.6 \
        --ancho 896 --alto 1152 --semilla 7 --cantidad 2 --salida /tmp/x/hondero

    $PY tools/generar_local.py "icon of a battering ram" --modelo flux --sin-fondo \
        --salida salida/ariete

Sin dependencias fuera de la biblioteca estándar, salvo --sin-fondo (rembg) y
--jpg (Pillow).
"""
import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

SERVIDOR = "http://127.0.0.1:8188"
CHECKPOINT_SDXL = "DreamShaperXL_Turbo_v2_1.safetensors"
FLUX_UNET = "flux1-schnell-Q4_K_S.gguf"
FLUX_T5 = "t5-v1_1-xxl-encoder-Q4_K_M.gguf"
FLUX_CLIP = "clip_l.safetensors"
FLUX_VAE = "ae.safetensors"
IPADAPTER = "ip-adapter-plus_sdxl_vit-h.safetensors"
CLIP_VISION = "CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors"
NEGATIVO = ("text, watermark, logo, signature, border, frame, blurry, deformed hands, "
            "extra fingers, extra limbs, lowres, jpeg artifacts, cross, religious symbol")


def pedir(servidor, ruta, datos=None, crudo=False):
    req = urllib.request.Request(servidor + ruta, data=datos)
    if datos is not None and not isinstance(datos, (bytes, bytearray)):
        raise TypeError("datos debe ser bytes")
    with urllib.request.urlopen(req, timeout=600) as r:
        cuerpo = r.read()
    return cuerpo if crudo else json.loads(cuerpo)


def subir_imagen(servidor, ruta):
    """Sube una imagen de referencia al input/ de ComfyUI y devuelve su nombre."""
    limite = uuid.uuid4().hex
    nombre = os.path.basename(ruta)
    with open(ruta, "rb") as f:
        contenido = f.read()
    cuerpo = (
        f"--{limite}\r\nContent-Disposition: form-data; name=\"image\"; filename=\"{nombre}\"\r\n"
        f"Content-Type: application/octet-stream\r\n\r\n").encode() + contenido + (
        f"\r\n--{limite}\r\nContent-Disposition: form-data; name=\"subfolder\"\r\n\r\nrefs"
        f"\r\n--{limite}\r\nContent-Disposition: form-data; name=\"overwrite\"\r\n\r\ntrue"
        f"\r\n--{limite}--\r\n").encode()
    req = urllib.request.Request(servidor + "/upload/image", data=cuerpo,
                                 headers={"Content-Type": f"multipart/form-data; boundary={limite}"})
    with urllib.request.urlopen(req, timeout=120) as r:
        res = json.loads(r.read())
    return f"{res['subfolder']}/{res['name']}" if res.get("subfolder") else res["name"]


def grafo_sdxl(a, refs):
    g = {
        "ckpt": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": a.checkpoint}},
        "pos": {"class_type": "CLIPTextEncode", "inputs": {"text": a.prompt, "clip": ["ckpt", 1]}},
        "neg": {"class_type": "CLIPTextEncode", "inputs": {"text": a.negativo, "clip": ["ckpt", 1]}},
        "lat": {"class_type": "EmptyLatentImage",
                "inputs": {"width": a.ancho, "height": a.alto, "batch_size": 1}},
        "ks": {"class_type": "KSampler", "inputs": {
            "model": ["ckpt", 0], "positive": ["pos", 0], "negative": ["neg", 0],
            "latent_image": ["lat", 0], "seed": a.semilla, "steps": a.pasos, "cfg": a.cfg,
            "sampler_name": a.sampler, "scheduler": a.scheduler, "denoise": 1.0}},
        "dec": {"class_type": "VAEDecode", "inputs": {"samples": ["ks", 0], "vae": ["ckpt", 2]}},
        "save": {"class_type": "SaveImage", "inputs": {"images": ["dec", 0], "filename_prefix": a.prefijo}},
    }
    if a.base_subida:
        # img2img: parte de una imagen (p. ej. la composición de FLUX) y la repinta con SDXL.
        g["base"] = {"class_type": "LoadImage", "inputs": {"image": a.base_subida}}
        g["lat"] = {"class_type": "VAEEncode", "inputs": {"pixels": ["base", 0], "vae": ["ckpt", 2]}}
        g["ks"]["inputs"]["denoise"] = a.fuerza
    if refs:
        imagen = None
        for i, nombre in enumerate(refs):
            g[f"ref{i}"] = {"class_type": "LoadImage", "inputs": {"image": nombre}}
            if imagen is None:
                imagen = [f"ref{i}", 0]
            else:
                g[f"lote{i}"] = {"class_type": "ImageBatch",
                                 "inputs": {"image1": imagen, "image2": [f"ref{i}", 0]}}
                imagen = [f"lote{i}", 0]
        g["ipa_m"] = {"class_type": "IPAdapterModelLoader", "inputs": {"ipadapter_file": IPADAPTER}}
        g["clipv"] = {"class_type": "CLIPVisionLoader", "inputs": {"clip_name": CLIP_VISION}}
        g["ipa"] = {"class_type": "IPAdapterAdvanced", "inputs": {
            "model": ["ckpt", 0], "ipadapter": ["ipa_m", 0], "image": imagen,
            "weight": a.peso_ref, "weight_type": a.tipo_ref, "combine_embeds": "average",
            "start_at": 0.0, "end_at": 1.0, "embeds_scaling": "V only",
            "clip_vision": ["clipv", 0]}}
        g["ks"]["inputs"]["model"] = ["ipa", 0]
    return g


def grafo_flux(a):
    g = {
        "unet": {"class_type": "UnetLoaderGGUF", "inputs": {"unet_name": FLUX_UNET}},
        "clip": {"class_type": "DualCLIPLoaderGGUF",
                 "inputs": {"clip_name1": FLUX_CLIP, "clip_name2": FLUX_T5, "type": "flux"}},
        "vae": {"class_type": "VAELoader", "inputs": {"vae_name": FLUX_VAE}},
        "pos": {"class_type": "CLIPTextEncode", "inputs": {"text": a.prompt, "clip": ["clip", 0]}},
        "neg": {"class_type": "ConditioningZeroOut", "inputs": {"conditioning": ["pos", 0]}},
        "lat": {"class_type": "EmptySD3LatentImage",
                "inputs": {"width": a.ancho, "height": a.alto, "batch_size": 1}},
        "ks": {"class_type": "KSampler", "inputs": {
            "model": ["unet", 0], "positive": ["pos", 0], "negative": ["neg", 0],
            "latent_image": ["lat", 0], "seed": a.semilla, "steps": a.pasos, "cfg": 1.0,
            "sampler_name": "euler", "scheduler": "simple", "denoise": 1.0}},
        "dec": {"class_type": "VAEDecode", "inputs": {"samples": ["ks", 0], "vae": ["vae", 0]}},
        "save": {"class_type": "SaveImage", "inputs": {"images": ["dec", 0], "filename_prefix": a.prefijo}},
    }
    if a.base_subida:
        # img2img: conserva la pose y la composición de la base (p. ej. la honda bien armada).
        g["base"] = {"class_type": "LoadImage", "inputs": {"image": a.base_subida}}
        g["lat"] = {"class_type": "VAEEncode", "inputs": {"pixels": ["base", 0], "vae": ["vae", 0]}}
        g["ks"]["inputs"]["denoise"] = a.fuerza
    return g


def esperar(servidor, pid):
    while True:
        hist = pedir(servidor, f"/history/{pid}")
        if pid in hist:
            estado = hist[pid].get("status", {})
            if estado.get("status_str") == "error":
                raise RuntimeError(json.dumps(estado.get("messages", ""), ensure_ascii=False)[:2000])
            if estado.get("completed", True):
                return hist[pid]["outputs"]
        time.sleep(0.4)


def quitar_fondo(ruta):
    os.environ.setdefault("U2NET_HOME", "/mnt/games/01_Projects/comfyui/modelos_rembg")
    from rembg import new_session, remove  # import tardío: solo si se pide
    if not hasattr(quitar_fondo, "sesion"):
        quitar_fondo.sesion = new_session("isnet-general-use")
    with open(ruta, "rb") as f:
        datos = remove(f.read(), session=quitar_fondo.sesion)
    salida = ruta[:-4] + "_sinfondo.png"
    with open(salida, "wb") as f:
        f.write(datos)
    return salida


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("prompt")
    p.add_argument("--negativo", default=NEGATIVO)
    p.add_argument("--ref", nargs="*", default=[], help="imágenes de referencia de estilo (IP-Adapter, solo SDXL)")
    p.add_argument("--peso-ref", type=float, default=0.6)
    p.add_argument("--tipo-ref", default="style transfer",
                   help="weight_type de IP-Adapter: 'style transfer' (solo estilo), 'linear' (estilo y contenido)…")
    p.add_argument("--ancho", type=int, default=1024)
    p.add_argument("--alto", type=int, default=1024)
    p.add_argument("--semilla", type=int, default=1)
    p.add_argument("--cantidad", type=int, default=1, help="imágenes; la semilla sube de a una")
    p.add_argument("--salida", required=True, help="prefijo de salida: carpeta/nombre (se agrega _semilla.png)")
    p.add_argument("--modelo", choices=["sdxl", "flux"], default="sdxl")
    p.add_argument("--checkpoint", default=CHECKPOINT_SDXL)
    p.add_argument("--pasos", type=int, default=None, help="por defecto 8 (SDXL turbo) o 4 (FLUX schnell)")
    p.add_argument("--cfg", type=float, default=2.0)
    p.add_argument("--sampler", default="dpmpp_sde")
    p.add_argument("--scheduler", default="karras")
    p.add_argument("--sin-fondo", action="store_true", help="además guarda una copia sin fondo (rembg)")
    p.add_argument("--jpg", type=int, default=0, help="además guarda un JPG con este lado máximo")
    p.add_argument("--base", default=None, help="img2img (SDXL o FLUX): imagen de partida, p. ej. una composición de FLUX")
    p.add_argument("--fuerza", type=float, default=0.5, help="denoise del img2img: 0 deja la base, 1 la ignora")
    p.add_argument("--servidor", default=SERVIDOR)
    a = p.parse_args()
    if a.pasos is None:
        a.pasos = 4 if a.modelo == "flux" else 8
    if a.ref and a.modelo == "flux":
        sys.exit("IP-Adapter solo está armado para SDXL.")
    a.prefijo = "generar_local/" + os.path.basename(a.salida)
    try:
        pedir(a.servidor, "/system_stats")
    except (urllib.error.URLError, OSError):
        sys.exit(f"No responde ComfyUI en {a.servidor}. Arrancarlo con /mnt/games/01_Projects/comfyui/arrancar.sh")

    refs = [subir_imagen(a.servidor, r) for r in a.ref]
    a.base_subida = subir_imagen(a.servidor, a.base) if a.base else None
    os.makedirs(os.path.dirname(os.path.abspath(a.salida)), exist_ok=True)
    semilla0 = a.semilla
    resumen = []
    for i in range(a.cantidad):
        a.semilla = semilla0 + i
        grafo = grafo_flux(a) if a.modelo == "flux" else grafo_sdxl(a, refs)
        t0 = time.time()
        pid = pedir(a.servidor, "/prompt", json.dumps(
            {"prompt": grafo, "client_id": "generar_local"}).encode())["prompt_id"]
        salidas = esperar(a.servidor, pid)
        seg = time.time() - t0
        for img in salidas["save"]["images"]:
            q = urllib.parse.urlencode({"filename": img["filename"], "subfolder": img["subfolder"], "type": img["type"]})
            datos = pedir(a.servidor, "/view?" + q, crudo=True)
            destino = f"{a.salida}_{a.semilla}.png"
            with open(destino, "wb") as f:
                f.write(datos)
            extra = []
            if a.sin_fondo:
                extra.append(quitar_fondo(destino))
            if a.jpg:
                from PIL import Image
                im = Image.open(destino).convert("RGB")
                im.thumbnail((a.jpg, a.jpg))
                jpg = destino[:-4] + ".jpg"
                im.save(jpg, quality=85)
                extra.append(jpg)
            resumen.append({"archivo": destino, "semilla": a.semilla, "segundos": round(seg, 1),
                            "modelo": a.modelo, "extra": extra})
            print(f"{destino}  semilla {a.semilla}  {seg:.1f} s", flush=True)
    with open(a.salida + "_meta.json", "w") as f:
        json.dump({"prompt": a.prompt, "negativo": a.negativo, "refs": a.ref, "peso_ref": a.peso_ref,
                   "tipo_ref": a.tipo_ref, "base": a.base, "fuerza": a.fuerza, "ancho": a.ancho, "alto": a.alto, "pasos": a.pasos,
                   "cfg": a.cfg, "imagenes": resumen}, f, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
