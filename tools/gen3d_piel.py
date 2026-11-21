"""Corrige la piel de una persona pintada por Hunyuan3D-Paint (proceso/50-arreglos-arte).

    gen3d/venv_hy/bin/python tools/gen3d_piel.py <textura.glb> <salida.glb> <vista_front.png> [cabeza]

Paint oscurece la piel (el paso que quita luces y el multivista bajan la luminancia hasta un
40 %): en las pieles oscuras la cara queda casi negra y sin rasgos. Esto la lleva de vuelta al
tono de la hoja 2D sin tocar la ropa:

1. Cada texel del atlas se ubica en 3D y se proyecta de frente sobre la hoja (cámara
   ortográfica ajustada por la caja, como tools/gen3d_color.py), con prueba de profundidad.
2. Piel: los texels vistos de frente toman la etiqueta de la hoja (máscara por tono); los que
   la hoja no muestra (espalda, costados) se clasifican por vecinos en Lab contra esos
   ejemplos de piel y de no piel. Así el casco de bronce o la soga no pasan por piel.
3. Corrección en Lab, solo si Paint oscureció (la mediana de L bajó más de 6 puntos; con
   las pieles claras Paint casi no la baja y la corrección solo agregaría manchas): la luminancia va al percentil 70 de la piel de
   la cara en la hoja (la hoja ya está iluminada y el juego vuelve a sombrear), estirando el
   contraste (las sombras suben más, los rasgos quedan); el tono (a, b) va al de la hoja.
4. Con [cabeza] > 0 y si Paint bajó la mediana de la piel más de 6 puntos de L, la cara vista de frente
   (la caja de la cara en la hoja: la mancha de piel más alta) mezcla además el color de la
   hoja, con ese peso como máximo: tiene los rasgos a más resolución que el multivista. La
   cara de la hoja se calza antes sobre la vista de frente de Paint (plantilla con
   corrimiento y escala); si no calza (correlación < 0,4), no se mezcla: con
   pieles claras Paint ya deja los rasgos y la mezcla solo agrega una cara fantasma.

Deja <salida>.json con las medidas y <salida>.atlas.jpg.
"""
import json
import sys
from pathlib import Path

import cv2
import numpy as np
import trimesh
from PIL import Image
from scipy import ndimage
from scipy.spatial import cKDTree

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gen3d_color import ajustar, proyectar, zbuffer  # noqa: E402


def lab(rgb01):
    return cv2.cvtColor(np.asarray(rgb01, np.float32).reshape(-1, 1, 3), cv2.COLOR_RGB2LAB).reshape(-1, 3)


def rgb(lab_):
    return cv2.cvtColor(np.asarray(lab_, np.float32).reshape(-1, 1, 3), cv2.COLOR_LAB2RGB).reshape(-1, 3)


def mascara_piel(c):
    """c: (..., 3) en 0–1. Tono 5–38°, saturación 0,15–0,8, ni negro ni casi blanco."""
    mx, mn = c.max(-1), c.min(-1)
    s = (mx - mn) / (mx + 1e-6)
    r, g, b = c[..., 0], c[..., 1], c[..., 2]
    h = np.degrees(np.arctan2(np.sqrt(3) * (g - b), 2 * r - g - b)) % 360
    return (h > 5) & (h < 38) & (s > 0.15) & (s < 0.8) & (mx > 0.07) & (mx < 0.92)


def caja_cara(piel_ref, alfa):
    """La mancha de piel más alta y de buen tamaño: la cara (con el cuello)."""
    m = ndimage.binary_opening(piel_ref & alfa, iterations=1)
    et, n = ndimage.label(m)
    if n == 0:
        return None
    ys, _ = np.nonzero(alfa)
    alto = ys.max() - ys.min()
    mejor = None
    for i, sl in enumerate(ndimage.find_objects(et), 1):
        area = (et[sl] == i).sum()
        if area < (alto * 0.03) ** 2:
            continue
        if mejor is None or sl[0].start < mejor[0].start:
            mejor = sl
    if mejor is None:
        return None
    y0, y1, x0, x1 = mejor[0].start, mejor[0].stop, mejor[1].start, mejor[1].stop
    y1 = min(y1, y0 + int(1.35 * (x1 - x0)))  # sin el pecho
    my, mx = int(0.15 * (y1 - y0)), int(0.15 * (x1 - x0))
    return max(y0 - my, 0), y1 + my, max(x0 - mx, 0), x1 + mx


def main():
    src, dst, ref_p = sys.argv[1:4]
    peso_cabeza = float(sys.argv[4]) if len(sys.argv) > 4 else 0.0
    m = trimesh.load(src, force="mesh")
    uv = m.visual.uv
    tex = np.asarray(m.visual.material.baseColorTexture.convert("RGB")).astype(np.float32) / 255
    T = tex.shape[0]
    v, f = m.vertices, m.faces
    fn = m.face_normals

    ref = Image.open(ref_p).convert("RGBA")
    n = ref.width
    rrgb = np.asarray(ref.convert("RGB")).astype(np.float32) / 255
    alfa = np.asarray(ref.getchannel("A")) > 127
    xy, z = proyectar(v, 0, 0)
    s, ox, oy = ajustar(xy, alfa)
    px = np.stack([(ox + xy[:, 0] * s) * n, (oy - xy[:, 1] * s) * n], 1)
    zb = zbuffer(px, z, f, n)
    eps = (z.max() - z.min()) * 0.01

    # Rasterizar el atlas: por texel, punto en la hoja y cuánto mira de frente (0 si tapado).
    ty, tx, q_all, vis_w = [], [], [], []
    for i, cara in enumerate(f):
        p = uv[cara] * T
        p[:, 1] = T - p[:, 1]
        a0, b0 = np.floor(p.min(0)).astype(int)
        a1, b1 = np.ceil(p.max(0)).astype(int)
        a0, b0, a1, b1 = max(a0, 0), max(b0, 0), min(a1, T - 1), min(b1, T - 1)
        if a1 < a0 or b1 < b0:
            continue
        gx, gy = np.meshgrid(np.arange(a0, a1 + 1) + 0.5, np.arange(b0, b1 + 1) + 0.5)
        (ax, ay), (bx, by), (cx, cy) = p
        den = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(den) < 1e-12:
            continue
        l1 = ((by - cy) * (gx - cx) + (cx - bx) * (gy - cy)) / den
        l2 = ((cy - ay) * (gx - cx) + (ax - cx) * (gy - cy)) / den
        l3 = 1 - l1 - l2
        dentro = (l1 >= -0.01) & (l2 >= -0.01) & (l3 >= -0.01)
        if not dentro.any():
            continue
        L = np.stack([l1[dentro], l2[dentro], l3[dentro]], 1)
        q = L @ px[cara]
        zz = L @ z[cara]
        ix = np.clip(q.astype(int), 0, n - 1)
        vis = zz >= zb[ix[:, 1], ix[:, 0]] - eps
        ty.append(gy[dentro].astype(int))
        tx.append(gx[dentro].astype(int))
        q_all.append(q)
        vis_w.append(np.clip(fn[i][2], 0, 1) * vis)
    ty, tx = np.concatenate(ty), np.concatenate(tx)
    q_all, vis_w = np.concatenate(q_all), np.concatenate(vis_w)
    pcol = tex[ty, tx]
    info = {}

    # Registro: la vista de frente de Paint contra la hoja (en grises, dentro del alfa).
    fr = vis_w > 0.2
    img_p = np.zeros((n, n, 3), np.float32)
    cnt = np.zeros((n, n), np.float32)
    ix = np.clip(q_all[fr].astype(int), 0, n - 1)
    np.add.at(img_p, (ix[:, 1], ix[:, 0]), pcol[fr])
    np.add.at(cnt, (ix[:, 1], ix[:, 0]), 1)
    lleno = cnt > 0
    img_p[lleno] /= cnt[lleno, None]
    _, (iy2, ix2) = ndimage.distance_transform_edt(~lleno, return_indices=True)
    img_p = img_p[iy2, ix2]
    ih = np.clip(q_all.astype(int), 0, n - 1)
    rcol = rrgb[ih[:, 1], ih[:, 0]]
    vis_w = vis_w * alfa[ih[:, 1], ih[:, 0]]

    # Etiquetas de piel: de frente, por la hoja; el resto, por vecinos en Lab.
    piel_ref = mascara_piel(rrgb)
    lab_p = lab(pcol)
    frente = vis_w > 0.4
    et_frente = piel_ref[ih[:, 1], ih[:, 0]]
    info["texels_frente"] = int(frente.sum())
    if (frente & et_frente).sum() < 200:
        info["nota"] = "poca piel vista de frente: sin corrección"
        m.export(dst)
        Path(dst).with_suffix(".json").write_text(json.dumps(info, indent=1))
        print("PIEL", json.dumps(info))
        return
    rng = np.random.default_rng(0)
    idx = np.nonzero(frente)[0]
    idx = rng.choice(idx, min(len(idx), 30000), replace=False)
    arbol = cKDTree(lab_p[idx] * [0.6, 1, 1])
    _, vec = arbol.query(lab_p * [0.6, 1, 1], k=12)
    prob = et_frente[idx][vec].mean(1)
    prob = np.where(frente, 0.5 * prob + 0.5 * et_frente, prob)
    wpiel_t = np.clip((prob - 0.45) / 0.25, 0, 1)

    # Meta: la piel de la cara en la hoja.
    caja = caja_cara(piel_ref, alfa)
    info["caja_cara"] = [int(x) for x in caja] if caja else None
    par = frente & et_frente & (wpiel_t > 0.5)
    lp = lab_p[par]
    if caja:
        y0, y1, x0, x1 = caja
        lrc = lab(rrgb[y0:y1, x0:x1][piel_ref[y0:y1, x0:x1] & alfa[y0:y1, x0:x1]])
    else:
        lrc = lab(rcol[par])
    mp = np.median(lp, 0)
    mr = np.median(lrc, 0)
    meta = float(np.percentile(lrc[:, 0], 70))

    def iqr(x):
        return np.percentile(x, 75) - np.percentile(x, 25)

    info.update({"texels_piel": int((wpiel_t > 0.5).sum()), "L_meta": round(meta, 1), "L_hoja": round(float(mr[0]), 1),
                 "L_paint": round(float(mp[0]), 1), "ab_hoja": [round(float(x), 1) for x in mr[1:]],
                 "ab_paint": [round(float(x), 1) for x in mp[1:]]})

    out = tex.copy()
    if mr[0] - mp[0] > 6:
        k = float(np.clip(iqr(lrc[:, 0]) / max(iqr(lp[:, 0]), 1e-3), 1.1, 1.6))
        nuevo = lab_p.copy()
        nuevo[:, 0] = np.clip(meta + (lab_p[:, 0] - mp[0]) * k, 0, 95)
        # Al subir la luminancia con el mismo a, b la piel se ve gris: el tono va al de la hoja,
        # con la saturación que le corresponde a la luminancia nueva.
        sat = np.clip(meta / max(mr[0], 1.0), 1.0, 1.4)
        nuevo[:, 1:] = lab_p[:, 1:] - mp[1:] + mr[1:] * sat
        corr = rgb(nuevo).clip(0, 1)
        # Lo muy oscuro (pelo, barba, cejas) casi no se mueve.
        w = wpiel_t * np.clip((lab_p[:, 0] - 6) / 8, 0, 1)
        # Suavizado en el atlas: sin esto la clasificación por vecinos deja manchas.
        W = np.zeros((T, T), np.float32)
        W[ty, tx] = w
        w = cv2.GaussianBlur(W, (0, 0), 2.5)[ty, tx]
        out[ty, tx] = pcol * (1 - w[:, None]) + corr * w[:, None]
        info["contraste"] = round(k, 2)
    else:
        info["nota"] = "Paint no oscureció la piel: sin corrección de tono"

    # La cara de la hoja solo donde Paint perdió los rasgos (la piel bajó mucho) y si la cara de
    # la hoja calza bien sobre la vista de frente de Paint (plantilla con corrimiento y escala).
    oscurecio = mr[0] - mp[0]
    if peso_cabeza > 0 and caja and oscurecio > 6:
        y0, y1, x0, x1 = caja
        cy, cx = (y0 + y1) / 2, (x0 + x1) / 2
        hy, hx = 0.35 * (y1 - y0), 0.35 * (x1 - x0)
        plant = cv2.cvtColor(rrgb[int(cy - hy):int(cy + hy), int(cx - hx):int(cx + hx)], cv2.COLOR_RGB2GRAY)
        g_p = cv2.cvtColor(img_p, cv2.COLOR_RGB2GRAY)
        mejor = (-1.0, 0.0, 0.0, 1.0)
        for e in np.arange(0.88, 1.13, 0.02):
            t = cv2.resize(plant, None, fx=e, fy=e, interpolation=cv2.INTER_AREA)
            th, tw = t.shape
            m0y, m0x = int(cy - th / 2 - 30), int(cx - tw / 2 - 30)
            zona = g_p[max(m0y, 0):m0y + th + 60, max(m0x, 0):m0x + tw + 60]
            if zona.shape[0] < th or zona.shape[1] < tw:
                continue
            r = cv2.matchTemplate(zona, t, cv2.TM_CCOEFF_NORMED)
            _, val, _, loc = cv2.minMaxLoc(r)
            if val > mejor[0]:
                mejor = (val, max(m0x, 0) + loc[0] + tw / 2, max(m0y, 0) + loc[1] + th / 2, e)
        val, pcx, pcy, e = mejor
        if len(sys.argv) > 5:
            Image.fromarray((np.concatenate([rrgb[y0:y1, x0:x1], img_p[y0:y1, x0:x1]], 1) * 255).astype(np.uint8)).save(sys.argv[5])
        info["cara_calce"] = {"nc": round(float(val), 3), "dx": round(float(pcx - cx), 1),
                              "dy": round(float(pcy - cy), 1), "escala": round(float(e), 3)}
        if val > 0.4:
            # Punto de la vista de Paint → punto de la hoja.
            qh = np.stack([cx + (q_all[:, 0] - pcx) / e, cy + (q_all[:, 1] - pcy) / e], 1)
            ih2 = np.clip(qh.astype(int), 0, n - 1)
            rcol2 = rrgb[ih2[:, 1], ih2[:, 0]]
            dentro = (qh[:, 1] >= y0) & (qh[:, 1] < y1) & (qh[:, 0] >= x0) & (qh[:, 0] < x1)
            borde = np.minimum.reduce([qh[:, 1] - y0, y1 - qh[:, 1], qh[:, 0] - x0, x1 - qh[:, 0]])
            suave = np.clip(borde / (0.12 * (x1 - x0)), 0, 1)
            w = peso_cabeza * dentro * suave * np.clip((vis_w - 0.35) / 0.3, 0, 1)
            out[ty, tx] = out[ty, tx] * (1 - w[:, None]) + rcol2 * w[:, None]
            info["texels_cabeza"] = int((w > 0.05).sum())

    # El margen de cada isla del atlas toma el color del texel cubierto más cercano (el filtrado
    # de la textura lo mezcla en las costuras).
    cubierto = np.zeros((T, T), bool)
    cubierto[ty, tx] = True
    dist_c, (iy, ix) = ndimage.distance_transform_edt(~cubierto, return_indices=True)
    relleno = ~cubierto & (dist_c <= 8)
    out[relleno] = out[iy[relleno], ix[relleno]]
    info["L_despues"] = round(float(np.median(lab(out[ty, tx][par])[:, 0])), 1)
    img = Image.fromarray((out.clip(0, 1) * 255).astype(np.uint8))
    m.visual.material.baseColorTexture = img
    m.export(dst)
    img.save(Path(dst).with_suffix(".atlas.jpg"), quality=88)
    Path(dst).with_suffix(".json").write_text(json.dumps(info, indent=1))
    print("PIEL", json.dumps(info))


if __name__ == "__main__":
    main()
