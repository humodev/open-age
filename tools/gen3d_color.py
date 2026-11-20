"""Pinta un GLB reducido proyectando la imagen de entrada (proceso/43-3d-local).

Hunyuan3D-Paint (la textura propia de Hunyuan) necesita compilar custom_rasterizer con el
toolkit de CUDA, que no está instalado. Esto es lo barato: sin GPU, solo numpy, xatlas y cv2.

    gen3d/venv_hy/bin/python tools/gen3d_color.py <reducido.glb> <salida.glb> <tipo> img1 [img2]

tipo:
  persona   img1 de frente (az 0) y img2 de espalda (az 180), a la altura de los ojos.
  edificio  img1 isométrica: se busca la cámara (az, elevación) que mejor calza la silueta;
            la cara opuesta usa la misma imagen (planta simétrica con media vuelta).
  animal    img1 de costado: se busca la cámara; el otro costado usa la imagen espejada.

1. Cámara ortográfica ajustada por silueta (IoU con el alfa).
2. Atlas UV con xatlas y textura de 512 px: cada texel toma el color de las vistas desde
   donde se ve (prueba de profundidad y peso por la normal).
3. Lo que no ve ninguna vista toma el color de los vértices vecinos vistos (se propaga por la
   malla), así el techo de atrás sigue siendo techo.
"""
import sys

import cv2
import numpy as np
import trimesh
import xatlas
from PIL import Image, ImageDraw

TEX = 512


def camara(az, el):
    a, e = np.radians(az), np.radians(el)
    c = np.array([np.cos(e) * np.sin(a), np.sin(e), np.cos(e) * np.cos(a)])
    r = np.cross([0, 1, 0], c)
    r /= np.linalg.norm(r)
    u = np.cross(c, r)
    return r, u, c


def proyectar(v, az, el):
    r, u, c = camara(az, el)
    return np.stack([v @ r, v @ u], 1), v @ c


def silueta(xy, caras, ajuste, n):
    s, ox, oy = ajuste
    im = Image.new("L", (n, n), 0)
    d = ImageDraw.Draw(im)
    p = np.stack([ox + xy[:, 0] * s, oy - xy[:, 1] * s], 1) * n
    for f in caras:
        d.polygon([tuple(p[i]) for i in f], fill=255)
    return np.array(im) > 0


def ajustar(xy, mask):
    """Escala y corrimiento (en fracción de la imagen) que alinean las cajas."""
    ys, xs = np.nonzero(mask)
    h, w = mask.shape
    mx0, mx1, my0, my1 = xs.min() / w, xs.max() / w, ys.min() / h, ys.max() / h
    x0, x1, y0, y1 = xy[:, 0].min(), xy[:, 0].max(), xy[:, 1].min(), xy[:, 1].max()
    s = min((mx1 - mx0) / (x1 - x0), (my1 - my0) / (y1 - y0))
    ox = (mx0 + mx1) / 2 - s * (x0 + x1) / 2
    oy = (my0 + my1) / 2 + s * (y0 + y1) / 2
    return s, ox, oy


def iou(m, mask_small, xy, caras, ajuste):
    sil = silueta(xy, caras, ajuste, mask_small.shape[0])
    return (sil & mask_small).sum() / max((sil | mask_small).sum(), 1)


def buscar(m, img, azs, els):
    mask = np.array(img.getchannel("A")) > 127
    chico = np.array(img.getchannel("A").resize((96, 96))) > 127
    mejor = (-1, 0, 0, None)
    for az in azs:
        for el in els:
            xy, _ = proyectar(m.vertices, az, el)
            aj = ajustar(xy, mask)
            q = iou(m, chico, xy, m.faces, aj)
            if q > mejor[0]:
                mejor = (q, az, el, aj)
    return mejor


def zbuffer(xy_px, z, caras, n):
    zb = np.full((n, n), -np.inf)
    for f in caras:
        p = xy_px[f]
        x0, y0 = np.floor(p.min(0)).astype(int)
        x1, y1 = np.ceil(p.max(0)).astype(int)
        x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, n - 1), min(y1, n - 1)
        if x1 < x0 or y1 < y0:
            continue
        gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        (ax, ay), (bx, by), (cx, cy) = p
        den = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(den) < 1e-12:
            continue
        l1 = ((by - cy) * (gx - cx) + (cx - bx) * (gy - cy)) / den
        l2 = ((cy - ay) * (gx - cx) + (ax - cx) * (gy - cy)) / den
        l3 = 1 - l1 - l2
        dentro = (l1 >= -1e-3) & (l2 >= -1e-3) & (l3 >= -1e-3)
        zz = l1 * z[f[0]] + l2 * z[f[1]] + l3 * z[f[2]]
        sub = zb[y0:y1 + 1, x0:x1 + 1]
        np.copyto(sub, np.where(dentro & (zz > sub), zz, sub))
    return zb


def main():
    src, dst, tipo = sys.argv[1:4]
    imgs = [Image.open(p).convert("RGBA") for p in sys.argv[4:]]
    m = trimesh.load(src, force="mesh")
    m = trimesh.Trimesh(m.vertices, m.faces, process=True)
    if tipo == "persona":
        vistas = [(0, 0, imgs[0]), (180, 0, imgs[1] if len(imgs) > 1 else imgs[0].transpose(Image.FLIP_LEFT_RIGHT))]
    elif tipo == "edificio":
        q, az, el, _ = buscar(m, imgs[0], range(0, 360, 10), [15, 25, 35, 45])
        q, az, el, _ = buscar(m, imgs[0], range(az - 8, az + 9, 4), range(el - 6, el + 7, 3))
        print(f"cámara: az {az}, elevación {el}, IoU {q:.2f}")
        vistas = [(az, el, imgs[0]), (az + 180, el, imgs[0])]
    else:
        q, az, el, _ = buscar(m, imgs[0], range(0, 360, 10), [0, 10, 20])
        q, az, el, _ = buscar(m, imgs[0], range(az - 8, az + 9, 4), range(max(el - 6, 0), el + 7, 3))
        print(f"cámara: az {az}, elevación {el}, IoU {q:.2f}")
        vistas = [(az, el, imgs[0]), (az + 180, el, imgs[0].transpose(Image.FLIP_LEFT_RIGHT))]

    v, caras = m.vertices, m.faces
    nv = m.vertex_normals
    acum = np.zeros((len(v), 3))
    peso = np.zeros(len(v))
    proy = []
    for az, el, img in vistas:
        n = img.width
        rgb = np.array(img.convert("RGB")).astype(np.float32)
        alfa = np.array(img.getchannel("A")) > 127
        xy, z = proyectar(v, az, el)
        s, ox, oy = ajustar(xy, alfa)
        px = np.stack([(ox + xy[:, 0] * s) * n, (oy - xy[:, 1] * s) * n], 1)
        zb = zbuffer(px, z, caras, n)
        eps = (z.max() - z.min()) * 0.01
        proy.append((camara(az, el)[2], s, ox, oy, n, rgb, alfa, zb, eps, az, el))
        ix = np.clip(px.astype(int), 0, n - 1)
        vis = (z >= zb[ix[:, 1], ix[:, 0]] - eps) & alfa[ix[:, 1], ix[:, 0]]
        w = np.clip(nv @ camara(az, el)[2], 0, 1) ** 2 * vis
        acum += rgb[ix[:, 1], ix[:, 0]] * w[:, None]
        peso += w
    # Colores por vértice y propagación a los no vistos.
    col = np.where(peso[:, None] > 1e-4, acum / np.maximum(peso, 1e-4)[:, None], np.nan)
    vecinos = m.vertex_neighbors
    for _ in range(200):
        falta = np.isnan(col[:, 0])
        if not falta.any():
            break
        nuevo = col.copy()
        for i in np.nonzero(falta)[0]:
            c = col[vecinos[i]]
            c = c[~np.isnan(c[:, 0])]
            if len(c):
                nuevo[i] = c.mean(0)
        col = nuevo
    col = np.nan_to_num(col, nan=160.0)

    # Atlas y textura.
    vmap, idx, uv = xatlas.parametrize(v, caras)
    v2, n2, c2 = v[vmap], nv[vmap], col[vmap]
    tex = np.zeros((TEX, TEX, 3), np.float32)
    lleno = np.zeros((TEX, TEX), bool)
    for f in idx:
        p = uv[f] * TEX
        p[:, 1] = TEX - p[:, 1]
        x0, y0 = np.floor(p.min(0)).astype(int)
        x1, y1 = np.ceil(p.max(0)).astype(int)
        x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, TEX - 1), min(y1, TEX - 1)
        gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        (ax, ay), (bx, by), (cx, cy) = p
        den = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(den) < 1e-12:
            continue
        l1 = ((by - cy) * (gx - cx) + (cx - bx) * (gy - cy)) / den
        l2 = ((cy - ay) * (gx - cx) + (ax - cx) * (gy - cy)) / den
        l3 = 1 - l1 - l2
        dentro = (l1 >= -0.02) & (l2 >= -0.02) & (l3 >= -0.02)
        if not dentro.any():
            continue
        L = np.stack([l1[dentro], l2[dentro], l3[dentro]], 1)
        pos = L @ v2[f]
        nor = L @ n2[f]
        nor /= np.linalg.norm(nor, axis=1, keepdims=True) + 1e-9
        base = L @ c2[f]
        ac = np.zeros_like(base)
        pw = np.zeros(len(pos))
        for cdir, s, ox, oy, n, rgb, alfa, zb, eps, az, el in proy:
            xy, z = proyectar(pos, az, el)
            ix = np.clip((np.stack([ox + xy[:, 0] * s, oy - xy[:, 1] * s], 1) * n).astype(int), 0, n - 1)
            vis = (z >= zb[ix[:, 1], ix[:, 0]] - eps) & alfa[ix[:, 1], ix[:, 0]]
            w = np.clip(nor @ cdir, 0, 1) ** 2 * vis
            ac += rgb[ix[:, 1], ix[:, 0]] * w[:, None]
            pw += w
        out = np.where(pw[:, None] > 0.05, ac / np.maximum(pw, 1e-6)[:, None], base)
        yy, xx = gy[dentro].astype(int), gx[dentro].astype(int)
        tex[yy, xx] = out
        lleno[yy, xx] = True
    tex8 = tex.clip(0, 255).astype(np.uint8)
    tex8 = cv2.inpaint(tex8, (~lleno).astype(np.uint8), 3, cv2.INPAINT_TELEA)
    mat = trimesh.visual.material.PBRMaterial(baseColorTexture=Image.fromarray(tex8), metallicFactor=0.0, roughnessFactor=1.0)
    out = trimesh.Trimesh(v2, idx, visual=trimesh.visual.TextureVisuals(uv=uv, material=mat), process=False)
    out.export(dst)
    print(f"listo: {dst} ({len(idx)} caras)")


if __name__ == "__main__":
    main()
