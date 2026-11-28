"""Máscara del color del equipo para un modelo 3D texturizado (proceso/56-rig-y-color).

    blender --background --python tools/mascara_equipo_3d.py -- modelo.glb salida_mascara.png \
        [--metodo=ropa|rojo] [--banda=0.30,0.80] [--edificio] [--tono=10] [--sat=0.55] [--hoja=hoja.jpg]

La máscara va en el espacio UV de la textura del modelo (mismo atlas, mismo tamaño): blanco = se
tiñe con el color del jugador. La tiñe src/game/shaders/equipo_3d.gdshader (luz de la textura × color).

Métodos:
- ropa (para los Meshy de hoy, que no traen la ropa en rojo): se queda con los texeles de las caras
  que están en la banda del torso y la túnica (por alto, entre `banda` del alto del modelo) y que
  no son piel, pelo ni partes oscuras o metálicas. La piel se separa por color (rosada o cobriza,
  clara y algo saturada), el pelo por oscuridad. Sirve para cualquier pueblo sin generar de nuevo.
- rojo (para modelos generados desde una lámina con la ropa en rojo plano, como las unidades 2D de
  tools/recolorear.py y los locales que heredaron esa textura): tono rojo saturado, en cualquier
  parte del cuerpo; la banda no se usa salvo que se pase.

Además:
- la máscara se expande unos píxeles solo hacia el margen vacío del atlas (no hacia otras islas),
  para que el filtrado y los mipmaps no dejen un borde sin teñir;
- imprime `luz_ref` (luminancia lineal media de lo enmascarado), que el shader usa para que el
  color del equipo salga con el brillo de la tela original;
- --hoja arma la comprobación: atlas | máscara;
- --faja=f y --cumbrera=c (edificios): además del rojo de la textura, una faja en las paredes justo
  bajo el techo o una terraza (a menos de f × alto) y la cumbrera (los techos en el c × alto de
  arriba), para que el color del equipo se vea desde la cámara del juego;
- --edificio (proceso/58-edificios-locales): sin detección de manos ni brazos y un rojo más estricto
  (--tono, --sat, --val ajustan el corte), para las telas y fajas rojas de los edificios.

Corre en el Python de Blender (trae numpy); no necesita scipy ni Pillow.
"""
import json
import os
import sys

import bpy
import numpy as np

argv = sys.argv[sys.argv.index("--") + 1:]
pos = [a for a in argv if not a.startswith("--")]
opt = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in argv if a.startswith("--"))
src, dst = pos[0], pos[1]
metodo = opt.get("metodo", "ropa")
banda = [float(x) for x in opt.get("banda", "0.30,0.80").split(",")] if (metodo == "ropa" or "banda" in opt) else None

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
obs = [o for o in bpy.context.scene.objects if o.type == "MESH" and not o.name.startswith("Icosphere")]
ob = max(obs, key=lambda o: len(o.data.vertices))
me = ob.data

# Textura base del primer material.
img = None
for n in me.materials[0].node_tree.nodes:
    if n.type == "TEX_IMAGE" and n.image is not None:
        img = n.image
        break
if img is None:
    sys.exit("el modelo no trae textura")
W, H = img.size
tex = np.array(img.pixels[:], dtype=np.float32).reshape(H, W, 4)[..., :3]  # sRGB, fila 0 = abajo

# Alto de cada vértice en la pose de reposo, normalizado 0..1.
dg = bpy.context.evaluated_depsgraph_get()
mw = ob.matrix_world
z = np.array([(mw @ v.co).z for v in me.vertices], dtype=np.float32)
z = (z - z.min()) / max(1e-6, z.max() - z.min())

# Manos: por los huesos si el modelo está riggeado (grupos hand/wrist); si no, los vértices más
# alejados a cada lado entre el 35 % y el 65 % del alto (brazos abajo o pose A).
import re
mano = np.zeros(len(me.vertices), bool)
brazo = np.zeros(len(me.vertices), bool)  # brazos y manos: no se tiñen (piel o manga)
nombres = {g.index: g.name for g in ob.vertex_groups}
if "edificio" in opt:
    pass  # edificios (proceso/58): sin manos ni brazos que proteger
elif nombres:
    for vx in me.vertices:
        if vx.groups:
            gg = max(vx.groups, key=lambda e: e.weight)
            mano[vx.index] = bool(re.search(r"hand|wrist", nombres[gg.group], re.I))
            brazo[vx.index] = bool(re.search(r"hand|wrist|arm", nombres[gg.group], re.I))
else:
    x = np.array([(mw @ vx.co).x for vx in me.vertices], dtype=np.float32)
    zona = (z > 0.35) & (z < 0.65)
    if zona.any():
        lim = np.percentile(np.abs(x[zona]), 92)
        mano = zona & (np.abs(x) >= lim)
        brazo = mano

# Rasterizado de los triángulos en UV: qué texeles cubre alguna cara, cuáles están en la banda y
# cuáles son de las manos.
# Faja bajo el alero y cumbrera (edificios, proceso/58): superficie geométrica que también toma el
# color del equipo, aunque la textura no la traiga en rojo (una faja tejida bajo la paja, una
# cumbrera). --faja=f: paredes con un techo (o una terraza) a menos de f × alto por encima;
# --cumbrera=c: techos en el c × alto más alto del modelo.
faja = float(opt.get("faja", "0"))
cumbrera = float(opt.get("cumbrera", "0"))
dup = None
if faja > 0 or cumbrera > 0:
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    m3 = mw.to_3x3()
    wv = [mw @ vx.co for vx in me.vertices]
    bvh = BVHTree.FromPolygons(wv, [pl.vertices[:] for pl in me.polygons])
    zw = np.array([p.z for p in wv], np.float32)
    alto = float(zw.max() - zw.min())
    pn = [(m3 @ pl.normal).normalized() for pl in me.polygons]
    dup = np.full(len(wv), 10.0, np.float32)  # distancia al techo de arriba, en fracción del alto
    arriba = Vector((0, 0, 1))
    for i, p in enumerate(wv):
        o = p + (m3 @ me.vertices[i].normal).normalized() * (0.01 * alto) + arriba * (0.002 * alto)
        hit = bvh.ray_cast(o, arriba, alto)
        if hit[0] is not None and abs(pn[hit[2]].z) > 0.25:  # el alero por abajo (malla cerrada) o una terraza
            dup[i] = hit[3] / alto
me.calc_loop_triangles()
uv = me.uv_layers.active.data
cubre = np.zeros((H, W), bool)
en_banda = np.zeros((H, W), bool)
de_mano = np.zeros((H, W), bool)
de_brazo = np.zeros((H, W), bool)
geo = np.zeros((H, W), bool)  # faja y cumbrera
for t in me.loop_triangles:
    p = np.array([uv[l].uv[:] for l in t.loops], dtype=np.float64) * [W, H]
    zz = float(np.mean(z[list(t.vertices)]))
    ok = banda is None or (banda[0] <= zz <= banda[1])
    x0, y0 = np.floor(p.min(0)).astype(int)
    x1, y1 = np.ceil(p.max(0)).astype(int)
    x0, y0 = max(x0, 0), max(y0, 0)
    x1, y1 = min(x1, W - 1), min(y1, H - 1)
    if x1 < x0 or y1 < y0:
        continue
    xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
    (ax, ay), (bx, by), (cx, cy) = p
    d = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
    if abs(d) < 1e-12:
        continue
    l1 = ((by - cy) * (xs - cx) + (cx - bx) * (ys - cy)) / d
    l2 = ((cy - ay) * (xs - cx) + (ax - cx) * (ys - cy)) / d
    l3 = 1 - l1 - l2
    e = -0.02  # un poco de margen para no dejar huecos entre triángulos vecinos
    dentro = (l1 >= e) & (l2 >= e) & (l3 >= e)
    sub = (slice(y0, y1 + 1), slice(x0, x1 + 1))
    cubre[sub] |= dentro
    if ok:
        en_banda[sub] |= dentro
    if dup is not None:
        vi = list(t.vertices)
        nz = (m3 @ t.normal).normalized().z
        if faja > 0 and abs(nz) < 0.5:
            dd = l1 * dup[vi[0]] + l2 * dup[vi[1]] + l3 * dup[vi[2]]
            geo[sub] |= dentro & (dd < faja)
        if cumbrera > 0 and nz > 0.3:
            zt = l1 * z[vi[0]] + l2 * z[vi[1]] + l3 * z[vi[2]]
            geo[sub] |= dentro & (zt > 1.0 - cumbrera)
    if mano[list(t.vertices)].sum() >= 2:
        de_mano[sub] |= dentro
    if "con-brazos" not in opt and brazo[list(t.vertices)].sum() >= 2:
        de_brazo[sub] |= dentro

# Color de cada texel en HSV.
r, g, b = tex[..., 0], tex[..., 1], tex[..., 2]
mx, mn = tex.max(-1), tex.min(-1)
v = mx
s = np.where(mx > 1e-6, (mx - mn) / np.maximum(mx, 1e-6), 0)
dl = np.maximum(mx - mn, 1e-6)
h = np.where(mx == r, ((g - b) / dl) % 6, np.where(mx == g, (b - r) / dl + 2, (r - g) / dl + 4)) * 60
h = np.where(mx - mn < 1e-6, 0, h)

if metodo == "rojo":
    # --tono: medio ancho del tono rojo en grados; --sat y --val: mínimos. Los edificios usan un
    # rojo más estricto (--edificio: 15°, 0,55) para no tomar tejas, ladrillo ni tierra colorada.
    tono = float(opt.get("tono", "15" if "edificio" in opt else "12"))
    sat = float(opt.get("sat", "0.55" if "edificio" in opt else "0.45"))
    val = float(opt.get("val", "0.12"))
    m = ((h <= tono) | (h >= 360 - tono)) & (s >= sat) & (v >= val)
else:
    # Piel: por parecido al color de las manos (CIELAB), no por un tono fijo: la tela marrón de
    # los Meshy cae en el mismo tono que la piel y solo se separa por luz y saturación.
    lin_ = np.where(tex <= 0.04045, tex / 12.92, ((tex + 0.055) / 1.055) ** 2.4)
    xyz = lin_ @ np.array([[0.4124, 0.2126, 0.0193], [0.3576, 0.7152, 0.1192], [0.1805, 0.0722, 0.9505]], np.float32)
    xyz /= np.array([0.9505, 1.0, 1.089], np.float32)
    f_ = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    lab = np.dstack([116 * f_[..., 1] - 16, 500 * (f_[..., 0] - f_[..., 1]), 200 * (f_[..., 1] - f_[..., 2])])
    ref = de_mano & cubre & (v > 0.16)
    umbral = float(opt.get("umbral_piel", "14"))
    if ref.sum() > 50:
        # mediana de las manos (las uñas, sombras y el mango de la herramienta no la mueven)
        piel_lab = np.median(lab[ref], axis=0)
        dist = np.linalg.norm(lab - piel_lab, axis=-1)
        piel = (dist < umbral) | de_mano | de_brazo
        print("PIEL ref", piel_lab.round(1), "texeles", int(ref.sum()))
    else:
        piel = ((h <= 30) | (h >= 345)) & (r > 1.3 * g) & (s >= 0.2) & (v >= 0.22)
        dist = None
    pelo = v < 0.16
    gris = (s < 0.10) & (v < 0.55)  # metal, piedra
    m = ~piel & ~pelo & ~gris
m &= cubre & en_banda if banda is not None else cubre
if dup is not None:
    print(f"FAJA/CUMBRERA: {geo.sum() / max(1, cubre.sum()):.1%} de la superficie")
    m |= geo & cubre
m &= ~de_mano  # las manos nunca (palmas rojizas, la herramienta en el puño)
if "dbg" in opt and metodo == "ropa":
    zona = cubre & en_banda
    if dist is not None:
        print("DBG dist piel", np.percentile(dist[zona & ~de_mano], [5, 20, 50, 80]).round(1), "manos", np.percentile(dist[ref], [50, 90]).round(1))
    for nom, k in (("piel", piel), ("pelo", pelo), ("gris", gris), ("tela", m)):
        sel = zona & k
        print("DBG", nom, f"{sel.sum() / max(1, zona.sum()):.1%}", "h", np.percentile(h[sel], [10, 50, 90]).round(0) if sel.any() else "-",
              "s", np.percentile(s[sel], [10, 50, 90]).round(2) if sel.any() else "-", "v", np.percentile(v[sel], [10, 50, 90]).round(2) if sel.any() else "-")


def vecinos_max(a):
    o = a.copy()
    o[1:] |= a[:-1]; o[:-1] |= a[1:]; o[:, 1:] |= a[:, :-1]; o[:, :-1] |= a[:, 1:]
    return o


def vecinos_min(a):
    o = a.copy()
    o[1:] &= a[:-1]; o[:-1] &= a[1:]; o[:, 1:] &= a[:, :-1]; o[:, :-1] &= a[:, 1:]
    return o


# Cierre chico (tapa puntitos sueltos de la textura) y apertura (saca motas aisladas).
m = vecinos_min(vecinos_max(m)) & cubre
m = vecinos_max(vecinos_min(m)) & cubre
# Expandir hacia el margen vacío del atlas (no hacia otras islas): 4 píxeles.
for _ in range(4):
    m |= vecinos_max(m) & ~cubre
# Borde suave: promedio 3×3.
mf = m.astype(np.float32)
pad = np.pad(mf, 1, mode="edge")
mf = sum(pad[1 + dy:1 + dy + H, 1 + dx:1 + dx + W] for dy in (-1, 0, 1) for dx in (-1, 0, 1)) / 9.0

# Luminancia lineal media de la tela, para el shader.
lin = np.where(tex <= 0.04045, tex / 12.92, ((tex + 0.055) / 1.055) ** 2.4)
lum = lin @ np.array([0.2126, 0.7152, 0.0722], np.float32)
luz_ref = float(lum[m].mean()) if m.any() else 0.25
cobertura = float(m.sum() / max(1, cubre.sum()))
print(f"MASCARA {dst}: {cobertura:.1%} de la superficie, luz_ref={luz_ref:.3f}, textura {W}x{H}")


def guardar(arr, ruta, ancho, alto, canales=1):
    im = bpy.data.images.new(os.path.basename(ruta), ancho, alto, alpha=False)
    if canales == 1:
        px = np.dstack([arr, arr, arr, np.ones_like(arr)])
    else:
        px = np.dstack([arr, np.ones(arr.shape[:2], np.float32)])
    im.pixels = px.astype(np.float32).ravel()
    im.filepath_raw = ruta
    im.file_format = "PNG" if ruta.endswith(".png") else "JPEG"
    im.save()


guardar(mf, dst, W, H)
with open(os.path.splitext(dst)[0] + ".json", "w") as f:
    json.dump({"modelo": os.path.basename(src), "metodo": metodo, "banda": banda, "luz_ref": round(luz_ref, 4),
               "cobertura": round(cobertura, 4)}, f, ensure_ascii=False)
if "hoja" in opt:
    over = tex * (1 - 0.6 * mf[..., None]) + np.array([1, 0, 1], np.float32) * 0.6 * mf[..., None]
    guardar(np.concatenate([tex, over], 1), opt["hoja"], 2 * W, H, 3)
