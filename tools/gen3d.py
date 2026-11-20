"""Generación 3D local desde una imagen (proceso/43-3d-local).

Corre con el entorno de /home/humodev/_01_Projects/gen3d (no con el Python del sistema) y
SIEMPRE dentro de un scope con tope de memoria:

    cd /home/humodev/_01_Projects/gen3d
    systemd-run --user --scope -p MemoryMax=10G -p MemoryHigh=8G -p MemorySwapMax=1G \\
        venv_hy/bin/python /mnt/games/01_Projects/open-age/tools/gen3d.py \\
        --modelo hy-mini-turbo --entrada entradas/casa.png --salida salidas/casa_hy-mini-turbo

Modelos:
  hy-mini        Hunyuan3D-2mini (0,6 B), 50 pasos             · Tencent Hunyuan Community License
  hy-mini-turbo  Hunyuan3D-2mini turbo (destilado), 5 pasos    · ídem (excluye UE, RU y Corea del Sur)
  hy-mv          Hunyuan3D-2mv (1,1 B), varias vistas, 50 pasos · ídem
  hy-mv-turbo    Hunyuan3D-2mv turbo, 5 pasos                  · ídem
  triposr        TripoSR (Stability + VAST)                    · MIT

Con varias vistas: --entrada front=entradas/a.png,back=entradas/b.png (claves front, left,
back, right). Con --textura, después de la forma corre Hunyuan3D-Paint (necesita
custom_rasterizer compilado). Deja <salida>.glb y <salida>.json con el tiempo, los picos de
VRAM (nvidia-smi, todo el proceso) y de RAM (RSS máximo) y la cantidad de caras.
"""
import argparse
import json
import os
import resource
import subprocess
import sys
import threading
import time
from pathlib import Path

GEN3D = Path("/home/humodev/_01_Projects/gen3d")
os.environ.setdefault("HF_HOME", str(GEN3D / "hf"))
os.environ.setdefault("HF_HUB_OFFLINE", "1")  # todo se bajó antes con descargar.py
sys.path.insert(0, str(GEN3D / "Hunyuan3D-2"))
sys.path.insert(0, str(GEN3D / "TripoSR"))


class PicoVRAM(threading.Thread):
    """Muestrea la VRAM usada de toda la placa y guarda el pico sobre la base inicial."""

    def __init__(self):
        super().__init__(daemon=True)
        self.base = self._leer()
        self.pico = self.base
        self.seguir = True

    @staticmethod
    def _leer() -> int:
        out = subprocess.run(["nvidia-smi", "--query-gpu=memory.used", "--format=csv,noheader,nounits"],
                             capture_output=True, text=True).stdout
        return int(out.strip().splitlines()[0])

    def run(self):
        while self.seguir:
            self.pico = max(self.pico, self._leer())
            time.sleep(0.25)


def cargar(ruta: str):
    from PIL import Image
    im = Image.open(ruta).convert("RGBA")
    return im


def hunyuan(args, entradas):
    import torch
    from hy3dgen.shapegen import Hunyuan3DDiTFlowMatchingPipeline
    repo, sub = {
        "hy-mini": ("tencent/Hunyuan3D-2mini", "hunyuan3d-dit-v2-mini"),
        "hy-mini-turbo": ("tencent/Hunyuan3D-2mini", "hunyuan3d-dit-v2-mini-turbo"),
        "hy-mv": ("tencent/Hunyuan3D-2mv", "hunyuan3d-dit-v2-mv"),
        "hy-mv-turbo": ("tencent/Hunyuan3D-2mv", "hunyuan3d-dit-v2-mv-turbo"),
    }[args.modelo]
    turbo = args.modelo.endswith("turbo")
    pipe = Hunyuan3DDiTFlowMatchingPipeline.from_pretrained(repo, subfolder=sub, use_safetensors=True,
                                                             variant="fp16", device="cuda")
    if turbo:
        pipe.enable_flashvdm(topk_mode="merge")
    imagen = entradas if args.modelo.startswith("hy-mv") else entradas["front"]
    t0 = time.time()
    mesh = pipe(image=imagen, num_inference_steps=5 if turbo else args.pasos,
                octree_resolution=args.octree, num_chunks=args.chunks,
                generator=torch.manual_seed(args.semilla), output_type="trimesh")[0]
    t_forma = time.time() - t0
    from hy3dgen.shapegen import FaceReducer, FloaterRemover, DegenerateFaceRemover
    mesh = FloaterRemover()(mesh)
    mesh = DegenerateFaceRemover()(mesh)
    t_tex = 0.0
    if args.textura:
        mesh = FaceReducer()(mesh, max_facenum=args.caras_textura)
        del pipe
        torch.cuda.empty_cache()
        from hy3dgen.texgen import Hunyuan3DPaintPipeline
        paint = Hunyuan3DPaintPipeline.from_pretrained("tencent/Hunyuan3D-2", subfolder="hunyuan3d-paint-v2-0-turbo")
        paint.enable_model_cpu_offload()
        t1 = time.time()
        mesh = paint(mesh, image=entradas["front"])
        t_tex = time.time() - t1
    return mesh, t_forma, t_tex


def triposr(args, entradas):
    import numpy as np
    import torch
    from PIL import Image
    from huggingface_hub import snapshot_download
    from tsr.system import TSR
    from tsr.utils import resize_foreground
    ruta = snapshot_download("stabilityai/TripoSR")
    model = TSR.from_pretrained(ruta, config_name="config.yaml", weight_name="model.ckpt")
    model.renderer.set_chunk_size(8192)
    model.to("cuda")
    im = resize_foreground(entradas["front"], 0.85)
    a = np.array(im).astype(np.float32) / 255.0
    a = a[:, :, :3] * a[:, :, 3:4] + (1 - a[:, :, 3:4]) * 0.5
    im = Image.fromarray((a * 255.0).astype(np.uint8))
    t0 = time.time()
    with torch.no_grad():
        codes = model([im], device="cuda")
        mesh = model.extract_mesh(codes, True, resolution=args.mc)[0]
    # TripoSR deja la malla con +z arriba; se pasa a +y arriba como glTF.
    mesh.apply_transform(np.array([[1, 0, 0, 0], [0, 0, 1, 0], [0, -1, 0, 0], [0, 0, 0, 1]], dtype=float))
    return mesh, time.time() - t0, 0.0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--modelo", required=True)
    ap.add_argument("--entrada", required=True)
    ap.add_argument("--salida", required=True)
    ap.add_argument("--semilla", type=int, default=12345)
    ap.add_argument("--pasos", type=int, default=50)
    ap.add_argument("--octree", type=int, default=256)
    ap.add_argument("--chunks", type=int, default=8000)
    ap.add_argument("--mc", type=int, default=256)
    ap.add_argument("--textura", action="store_true")
    ap.add_argument("--caras-textura", type=int, default=40000)
    args = ap.parse_args()

    entradas = {}
    for parte in args.entrada.split(","):
        k, _, v = parte.rpartition("=")
        entradas[k or "front"] = cargar(v)
    vram = PicoVRAM()
    vram.start()
    t0 = time.time()
    fn = triposr if args.modelo == "triposr" else hunyuan
    mesh, t_forma, t_tex = fn(args, entradas)
    total = time.time() - t0
    vram.seguir = False
    salida = Path(args.salida)
    salida.parent.mkdir(parents=True, exist_ok=True)
    mesh.export(str(salida.with_suffix(".glb")))
    import torch
    info = {
        "modelo": args.modelo, "entrada": args.entrada, "semilla": args.semilla,
        "octree": args.octree, "textura": args.textura,
        "seg_forma": round(t_forma, 1), "seg_textura": round(t_tex, 1), "seg_total_con_carga": round(total, 1),
        "vram_pico_mb": vram.pico - vram.base, "vram_torch_mb": int(torch.cuda.max_memory_reserved() / 2**20),
        "ram_pico_mb": int(resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024),
        "caras": int(len(mesh.faces)) if hasattr(mesh, "faces") else None,
    }
    salida.with_suffix(".json").write_text(json.dumps(info, indent=1))
    print(json.dumps(info))


if __name__ == "__main__":
    main()
