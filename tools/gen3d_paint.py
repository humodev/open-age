"""Textura con Hunyuan3D-Paint turbo sobre una malla ya reducida (proceso/47-pipeline-3d).

    gen3d/venv_hy/bin/python tools/gen3d_paint.py <reducido.glb> <salida.glb> <imagen.png> [tex_px]

Necesita las extensiones compiladas con tools/gen3d_compilar_paint.sh. Carga el modelo de
quitar luces (delight) y el multivista, con descarga a CPU entre pasos (VRAM de 8 GB).
La malla se usa en el mismo marco que la da Hunyuan (y arriba, frente hacia +z): azimut 0 es
la imagen de entrada. Deja <salida>.json con tiempos y picos.
"""
import json
import os
import resource
import sys
import time
from pathlib import Path

GEN3D = Path("/home/humodev/_01_Projects/gen3d")
os.environ.setdefault("HF_HOME", str(GEN3D / "hf"))
os.environ.setdefault("HF_HUB_OFFLINE", "1")
os.environ.setdefault("HY3DGEN_MODELS", str(GEN3D / "modelos"))
os.environ.setdefault("PYTORCH_CUDA_ALLOC_CONF", "expandable_segments:True")
sys.path.insert(0, str(GEN3D / "Hunyuan3D-2"))
sys.path.insert(0, str(GEN3D / "Hunyuan3D-2/hy3dgen/texgen/differentiable_renderer"))


def pintar(mesh, imagen, tex):
    """Lo mismo que Hunyuan3DPaintPipeline.__call__, pero con un modelo por vez en memoria:
    primero el que quita luces y sombras, se libera, y después el multivista."""
    import gc
    import numpy as np
    import torch
    from hy3dgen.texgen.pipelines import Hunyuan3DPaintPipeline, Hunyuan3DTexGenConfig
    from hy3dgen.texgen.differentiable_renderer.mesh_render import MeshRender
    from hy3dgen.texgen.utils.dehighlight_utils import Light_Shadow_Remover
    from hy3dgen.texgen.utils.multiview_utils import Multiview_Diffusion_Net
    from hy3dgen.texgen.utils.uv_warp_utils import mesh_uv_wrap

    base = Path(os.environ["HY3DGEN_MODELS"]) / "tencent/Hunyuan3D-2"
    cfg = Hunyuan3DTexGenConfig(str(base / "hunyuan3d-delight-v2-0"),
                                str(base / "hunyuan3d-paint-v2-0-turbo"), "hunyuan3d-paint-v2-0-turbo")
    cfg.texture_size = tex
    cfg.render_size = max(1024, tex)
    p = Hunyuan3DPaintPipeline.__new__(Hunyuan3DPaintPipeline)
    p.config = cfg
    p.render = MeshRender(default_resolution=cfg.render_size, texture_size=cfg.texture_size)
    p.models = {}
    t0 = time.time()
    imagen = p.recenter_image(imagen)
    luz = Light_Shadow_Remover(cfg)
    imagen = luz(imagen)
    del luz
    gc.collect()
    torch.cuda.empty_cache()
    t_luz = time.time() - t0

    mesh = mesh_uv_wrap(mesh)
    p.render.load_mesh(mesh)
    elevs, azims, pesos = cfg.candidate_camera_elevs, cfg.candidate_camera_azims, cfg.candidate_view_weights
    normales = p.render_normal_multiview(elevs, azims, use_abs_coor=True)
    posiciones = p.render_position_multiview(elevs, azims)
    camara = [(((a // 30) + 9) % 12) // {-20: 1, 0: 1, 20: 1, -90: 3, 90: 3}[e]
              + {-20: 0, 0: 12, 20: 24, -90: 36, 90: 40}[e] for a, e in zip(azims, elevs)]
    t1 = time.time()
    mv = Multiview_Diffusion_Net(cfg)
    # 8 GB de VRAM: la unet (3,6 GB en fp16) baja a la CPU mientras decodifica el VAE, que
    # además va de a una vista.
    mv.pipeline.enable_model_cpu_offload()
    if hasattr(mv.pipeline, "vae"):
        mv.pipeline.vae.enable_slicing()
    t_carga = t_luz + time.time() - t1
    t2 = time.time()
    vistas = mv([imagen], normales + posiciones, camara)
    del mv
    gc.collect()
    torch.cuda.empty_cache()
    vistas = [v.resize((cfg.render_size, cfg.render_size)) for v in vistas]
    textura, mascara = p.bake_from_multiview(vistas, elevs, azims, pesos, method=cfg.merge_method)
    m = (mascara.squeeze(-1).cpu().numpy() * 255).astype(np.uint8)
    textura = p.texture_inpaint(textura, m)
    p.render.set_texture(textura)
    return p.render.save_mesh(), t_carga, time.time() - t2


def main():
    src, dst, img = sys.argv[1], sys.argv[2], sys.argv[3]
    tex = int(sys.argv[4]) if len(sys.argv) > 4 else 1024
    import torch
    import trimesh
    from PIL import Image

    mesh = trimesh.load(src, force="mesh")
    # Sin la textura vieja: Paint arma su propio atlas.
    mesh = trimesh.Trimesh(vertices=mesh.vertices, faces=mesh.faces, process=False)
    out, t_carga, t_tex = pintar(mesh, Image.open(img).convert("RGBA"), tex)
    Path(dst).parent.mkdir(parents=True, exist_ok=True)
    out.export(dst)
    info = {"entrada": src, "imagen": img, "tex_px": tex, "seg_carga": round(t_carga, 1),
            "seg_textura": round(t_tex, 1), "vram_torch_mb": int(torch.cuda.max_memory_reserved() / 2**20),
            "ram_pico_mb": int(resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024),
            "caras": int(len(out.faces))}
    Path(dst).with_suffix(".json").write_text(json.dumps(info, indent=1))
    print("PAINT", json.dumps(info))


if __name__ == "__main__":
    main()
