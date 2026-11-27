"""Techos de la referencia sobre la textura de Hunyuan3D-Paint (proceso/58-edificios-locales).

    gen3d/venv_hy/bin/python tools/gen3d_mezcla.py <paint.glb> <salida.glb> <vista_front.png> [--todo] [--umbral=0.3]

Paint deja la paja como una lámina lisa naranja. El proyector (tools/gen3d_color.py) conserva el
gouache de la referencia pero mancha lo que la imagen no ve. Esto mezcla los dos sobre el atlas UV
de Paint, sin cambiar la malla ni las UV (la máscara del equipo se calcula después igual):

1. busca la cámara de la referencia por silueta (la de gen3d_color: azimut y elevación);
2. por cada texel del atlas, la posición y la normal en la malla; si se ve desde esa cámara
   (prueba de profundidad y alfa) y la cara mira hacia arriba (techos: normal.y > umbral), toma
   el color de la referencia, con peso (normal · cámara)²;
3. --todo: también las paredes que miran a la cámara.

Sin GPU: numpy, trimesh y PIL (venv de gen3d).
"""
import sys

import numpy as np
import trimesh
from PIL import Image

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from gen3d_color import ajustar, buscar, camara, proyectar, zbuffer  # noqa: E402

args = [a for a in sys.argv[1:] if not a.startswith("--")]
opt = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in sys.argv[1:] if a.startswith("--"))
src, dst, vista = args
umbral = float(opt.get("umbral", "0.3"))

esc = trimesh.load(src, force="scene")
nombre, m = max(esc.geometry.items(), key=lambda kv: len(kv[1].faces))
mat = m.visual.material
tex = np.array(mat.baseColorTexture.convert("RGB")).astype(np.float32)
H, W = tex.shape[:2]
uv = np.asarray(m.visual.uv, np.float64)
img = Image.open(vista).convert("RGBA")

# La cámara se busca sobre la malla, en el marco del GLB (y arriba, como gen3d_color con trimesh).
q, az, el, _ = buscar(m, img, range(0, 360, 10), [15, 25, 35, 45])
q, az, el, _ = buscar(m, img, range(az - 8, az + 9, 4), range(el - 6, el + 7, 3))
print(f"cámara: az {az}, elevación {el}, IoU {q:.2f}")
v, caras = m.vertices, m.faces
n = img.width
rgb = np.array(img.convert("RGB")).astype(np.float32)
alfa = np.array(img.getchannel("A")) > 127
xy, z = proyectar(v, az, el)
s, ox, oy = ajustar(xy, alfa)
px = np.stack([(ox + xy[:, 0] * s) * n, (oy - xy[:, 1] * s) * n], 1)
zb = zbuffer(px, z, caras, n)
eps = (z.max() - z.min()) * 0.01
cdir = camara(az, el)[2]
fn = m.face_normals

cambiados = 0
for fi, f in enumerate(caras):
    nf = fn[fi]
    if "todo" not in opt and nf[1] <= umbral:
        continue
    wf = max(0.0, float(nf @ cdir)) ** 2
    if wf < 0.05:
        continue
    p = uv[f] * [W, H]
    p[:, 1] = H - p[:, 1]
    x0, y0 = np.floor(p.min(0)).astype(int)
    x1, y1 = np.ceil(p.max(0)).astype(int)
    x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, W - 1), min(y1, H - 1)
    if x1 < x0 or y1 < y0:
        continue
    gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
    (ax_, ay), (bx, by), (cx, cy) = p
    den = (by - cy) * (ax_ - cx) + (cx - bx) * (ay - cy)
    if abs(den) < 1e-12:
        continue
    l1 = ((by - cy) * (gx - cx) + (cx - bx) * (gy - cy)) / den
    l2 = ((cy - ay) * (gx - cx) + (ax_ - cx) * (gy - cy)) / den
    l3 = 1 - l1 - l2
    dentro = (l1 >= -0.02) & (l2 >= -0.02) & (l3 >= -0.02)
    if not dentro.any():
        continue
    L = np.stack([l1[dentro], l2[dentro], l3[dentro]], 1)
    pos = L @ v[f]
    pxy, pz = proyectar(pos, az, el)
    ix = np.clip((np.stack([ox + pxy[:, 0] * s, oy - pxy[:, 1] * s], 1) * n).astype(int), 0, n - 1)
    vis = (pz >= zb[ix[:, 1], ix[:, 0]] - eps) & alfa[ix[:, 1], ix[:, 0]]
    if not vis.any():
        continue
    yy, xx = gy[dentro].astype(int)[vis], gx[dentro].astype(int)[vis]
    w = min(1.0, wf * 1.6)
    tex[yy, xx] = tex[yy, xx] * (1 - w) + rgb[ix[vis, 1], ix[vis, 0]] * w
    cambiados += int(vis.sum())

mat.baseColorTexture = Image.fromarray(tex.clip(0, 255).astype(np.uint8))
esc.export(dst)
print(f"listo: {dst}, {cambiados} texeles de la referencia ({cambiados / (W * H):.1%} del atlas)")
