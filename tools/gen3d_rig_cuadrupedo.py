"""Rig general de cuadrúpedo con sus ciclos (proceso/47-pipeline-3d, proceso/63-montados-y-animales),
en Blender.

    blender --background --python tools/gen3d_rig_cuadrupedo.py -- entrada.glb salida_rig.glb render_prefijo
            [--tipo=caballo] [--modelo=elefante_guerra] [--cabeza=+x|-x|+y|-y] [--tiras]

Para cualquier animal de cuatro patas (generado con el pipeline, de Meshy o la silueta
procedural del juego exportada por tools/exportar_animales.gd). Lo normaliza (el largo sobre +x
con la cabeza en +x, apoyado en el suelo, alto 1), busca la cabeza, las cuatro patas, la cola y
(en el elefante) la trompa, y arma el esqueleto: root, hips, spine, chest, neck, head, tail.1-2,
trompa.1-3, por pata upper, lower y hoof (leg_front_l…), y silla (donde se sienta el jinete) y
cuello_asiento (el mahout del elefante). Pesos automáticos (bone heat); los vértices sin peso
van al hueso más cercano; los que el modelo trae montados arriba (rigido_desde_pct) van enteros
al lomo.

Todo lo que cambia de un animal a otro está en data/arte_cuadrupedos.json → tipos[tipo] (con lo
de modelos[modelo].rig encima): dónde va la silla, los arreos (la manta del color del equipo, de
material «equipo», y el howdah de madera) y el largo y la forma de cada clip.

Clips (pistas NLA, el GLB las lleva todas): quieto, pastar, caminar, galope, ataque (encabritar,
pisoton o cabezazo), golpeado y morir. El juego las reproduce y ajusta el paso a la distancia
recorrida (src/game/cuadrupedo_animado.gd).

Renders: el caminar en 4 cuadros de costado y, con --tiras, 6 cuadros de galope, ataque y
morir en tres cuartos (<prefijo>_<clip>_<i>.jpg; tools/gen3d_tiras.py las junta).
"""
import json
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Quaternion, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
pos = [a for a in argv if not a.startswith("--")]
opt = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in argv if a.startswith("--"))
src, dst, prefijo = pos[:3]
REPO = Path(__file__).resolve().parent.parent
DATOS = json.loads((REPO / "data/arte_cuadrupedos.json").read_text())
TIPO = opt.get("tipo", "caballo")
T = json.loads(json.dumps(DATOS["tipos"][TIPO]))
for k, v in DATOS.get("modelos", {}).get(opt.get("modelo", ""), {}).get("rig", {}).items():
    T[k] = v
CLIPS = T["clips"]
FPS = 24

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
for o in list(bpy.context.scene.objects):
    if o.type not in ("MESH",):
        bpy.data.objects.remove(o)
mallas = [o for o in bpy.context.scene.objects if o.type == "MESH"]
for o in mallas:
    o.select_set(True)
    o.modifiers.clear()
    if o.data.shape_keys:
        o.shape_key_clear()
bpy.context.view_layer.objects.active = mallas[0]
for o in mallas:
    for g in list(o.vertex_groups):
        o.vertex_groups.remove(g)
bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
if len(mallas) > 1:
    bpy.ops.object.join()
ob = bpy.context.view_layer.objects.active
bm = bmesh.new()
bm.from_mesh(ob.data)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
bm.to_mesh(ob.data)
bm.free()
ob.name = "animal"


def aplicar(m):
    ob.data.transform(m)
    ob.data.update()


# ------------------------------------------------------------------ normalizar
# El largo sobre x; la cabeza en +x (si no se dice, el extremo más alto); apoyado en z = 0,
# centrado y de alto 1.
V = [v.co for v in ob.data.vertices]
ext = [max(p[i] for p in V) - min(p[i] for p in V) for i in range(3)]
cab = opt.get("cabeza", T.get("cabeza", ""))
if cab in ("+y", "-y") or (not cab and ext[1] > ext[0]):
    aplicar(Matrix.Rotation(math.radians(-90 if cab != "-y" else 90), 4, "Z"))  # +y → +x (o −y → +x)
V = [v.co for v in ob.data.vertices]
H0 = max(v.z for v in V) - min(v.z for v in V)
x0, x1 = min(v.x for v in V), max(v.x for v in V)
cuerpo = [v for v in V if v.z < min(v.z for v in V) + H0 * float(T.get("rigido_desde_pct", 101)) / 100.0]
if cab == "-x" or (not cab and max((v.z for v in cuerpo if v.x < x0 + 0.2 * (x1 - x0)), default=0)
                   > max((v.z for v in cuerpo if v.x > x1 - 0.2 * (x1 - x0)), default=0)):
    aplicar(Matrix.Rotation(math.pi, 4, "Z"))
V = [v.co for v in ob.data.vertices]
mn = Vector((min(v.x for v in V), min(v.y for v in V), min(v.z for v in V)))
mx = Vector((max(v.x for v in V), max(v.y for v in V), max(v.z for v in V)))
aplicar(Matrix.Scale(1.0 / (mx.z - mn.z), 4) @ Matrix.Translation(Vector((-(mn.x + mx.x) / 2, -(mn.y + mx.y) / 2, -mn.z))))

# Recorte: lo que el modelo trae arriba del lomo (el howdah del elefante del rey) se borra para
# ponerle los arreos propios (modelos[...].rig.recortar_desde_pct).
if "recortar_desde_pct" in T:
    corte = float(T["recortar_desde_pct"]) / 100.0
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    xs = [v.co.x for v in bm.verts]
    L0 = max(xs) - min(xs)
    lim = (min(xs) + L0 * float(T.get("recortar_x_pct", [15, 75])[0]) / 100.0,
           min(xs) + L0 * float(T.get("recortar_x_pct", [15, 75])[1]) / 100.0)
    fuera = [v for v in bm.verts if v.co.z > corte and lim[0] < v.co.x < lim[1]]
    bmesh.ops.delete(bm, geom=fuera, context="VERTS")
    # Islas sueltas que quedaron (cuerdas, flecos): se borran las chicas.
    bm.verts.ensure_lookup_table()
    visto = set()
    islas = []
    for v in bm.verts:
        if v.index in visto:
            continue
        pila, isla = [v], []
        visto.add(v.index)
        while pila:
            a = pila.pop()
            isla.append(a)
            for e in a.link_edges:
                b = e.other_vert(a)
                if b.index not in visto:
                    visto.add(b.index)
                    pila.append(b)
        islas.append(isla)
    grande = max(len(i) for i in islas)
    bmesh.ops.delete(bm, geom=[v for i in islas if len(i) < grande * 0.02 for v in i], context="VERTS")
    bm.to_mesh(ob.data)
    bm.free()
    V = [v.co for v in ob.data.vertices]
    mn = Vector((min(v.x for v in V), min(v.y for v in V), min(v.z for v in V)))
    mx = Vector((max(v.x for v in V), max(v.y for v in V), max(v.z for v in V)))
    aplicar(Matrix.Scale(1.0 / (mx.z - mn.z), 4) @ Matrix.Translation(Vector((-(mn.x + mx.x) / 2, -(mn.y + mx.y) / 2, -mn.z))))

V = [v.co.copy() for v in ob.data.vertices]
H = 1.0
x0, x1 = min(v.x for v in V), max(v.x for v in V)
L = x1 - x0
cy = 0.0
RIG = float(T.get("rigido_desde_pct", 101)) / 100.0
VC = [v for v in V if v.z < RIG] or V  # el cuerpo, sin lo que trae montado


def media(pts):
    s = Vector((0, 0, 0))
    for p in pts:
        s += p
    return s / max(len(pts), 1)


def cerca_x(x, ancho):
    return [v for v in VC if abs(v.x - x) < ancho]


# Patas: vértices bajo el 12 % del alto, partidos en delanteras y traseras por el centro del
# grupo, y cada grupo por su y media en izquierda (+y) y derecha.
bajos = [v for v in VC if v.z < 0.12 * H]
xm = media(bajos).x
grupos = {"front": [v for v in bajos if v.x > xm], "back": [v for v in bajos if v.x <= xm]}
patas = {}
for g, pts in grupos.items():
    pts = pts or bajos
    ym = media(pts).y
    for lado, sel in (("l", [v for v in pts if v.y > ym]), ("r", [v for v in pts if v.y <= ym])):
        patas[f"{g}_{lado}"] = media(sel or pts)
x_del = (patas["front_l"].x + patas["front_r"].x) / 2
x_tra = (patas["back_l"].x + patas["back_r"].x) / 2


def entre_patas(f):
    """x a una fracción f de las traseras (0) a las delanteras (1)."""
    return x_tra + f * (x_del - x_tra)


def lomo_en(x):
    """Alto del lomo en x (el vértice más alto del cuerpo cerca de x, del medio del ancho)."""
    pts = cerca_x(x, 0.04 * L)
    if not pts:
        return 0.6 * H
    w = max(abs(v.y) for v in pts)
    pts = [v for v in pts if abs(v.y) < 0.5 * w] or pts
    return max(v.z for v in pts)


def ancho_en(x, z_desde):
    pts = [v for v in cerca_x(x, 0.05 * L) if v.z > z_desde]
    return max((abs(v.y) for v in pts), default=0.1 * L)


x_mid = (x_del + x_tra) / 2
lomo_top = lomo_en(x_mid)
lomo = 0.84 * lomo_top  # la línea del espinazo, dentro del cuerpo
panza = 0.62 * lomo_top
# Cabeza: el vértice más alto delante de las manos (las orejas) y el más adelantado (el hocico).
frente = [v for v in VC if v.x > x_del + 0.05 * L] or [v for v in VC if v.x > x_mid]
orejas = max(frente, key=lambda v: v.z)
hocico = max(frente, key=lambda v: (v.x, -abs(v.z - orejas.z)))
cola_pts = [v for v in VC if v.x < x0 + 0.06 * L and v.z > 0.25 * H]
cola_fin = min(cola_pts, key=lambda v: v.z) if cola_pts else Vector((x0, cy, 0.4 * H))

J = {
    "root": Vector((x_mid, cy, 0)),
    "hips": Vector((x_tra, cy, lomo)),
    "spine": Vector((x_mid, cy, lomo)),
    "chest": Vector((x_del, cy, lomo)),
    "neck": Vector((x_del + 0.08 * L, cy, lomo + 0.05 * H)),
    "head": Vector((orejas.x - 0.02 * L, cy, orejas.z - 0.06 * H)),
    "head_end": Vector((hocico.x, cy, hocico.z)),
    "tail": Vector((x0 + 0.04 * L, cy, lomo + 0.02 * H)),
}
if J["head"].x <= J["neck"].x + 0.02 * L:
    J["head"].x = J["neck"].x + 0.04 * L
if (J["head_end"] - J["head"]).length < 0.04 * L:
    J["head_end"] = J["head"] + Vector((0.08 * L, 0, -0.02 * H))
J["tail_mid"] = J["tail"].lerp(Vector((cola_fin.x, cy, cola_fin.z)), 0.45)
J["tail_end"] = Vector((cola_fin.x, cy, cola_fin.z))
if (J["tail_end"] - J["tail"]).length < 0.03 * L:
    J["tail_end"] = J["tail"] + Vector((-0.03 * L, 0, -0.15 * H))
    J["tail_mid"] = J["tail"].lerp(J["tail_end"], 0.45)
for nombre, p in patas.items():
    J[f"leg_{nombre}"] = Vector((p.x, p.y * 0.6, panza + 0.04 * H))
    J[f"knee_{nombre}"] = Vector((p.x, p.y, 0.48 * lomo_top))
    J[f"fetlock_{nombre}"] = Vector((p.x, p.y, 0.08 * H))
    J[f"hoof_{nombre}"] = Vector((p.x + 0.02 * L, p.y, 0.0))
# Trompa (elefante): de la cara hasta la punta, que es el vértice más bajo delante de la cabeza.
TROMPA = bool(T.get("trompa", False))
if TROMPA:
    adelante = [v for v in VC if v.x > x_del + 0.25 * (x1 - x_del)]
    punta = min(adelante, key=lambda v: v.z - 0.3 * v.x)
    cara = [v for v in VC if 0.45 * lomo_top < v.z < 0.8 * lomo_top and abs(v.y) < 0.06 * L]
    x_cara = max((v.x for v in cara), default=hocico.x)
    raiz = Vector((x_cara - 0.03 * L, cy, 0.62 * lomo_top))
    J["head_end"] = raiz.copy()
    fin = Vector((punta.x, cy, max(punta.z, 0.04 * H)))
    medio1 = raiz.lerp(fin, 0.35) + Vector((0.03 * L, 0, 0))
    medio2 = raiz.lerp(fin, 0.7) + Vector((0.02 * L, 0, 0))
    J.update({"trompa_0": raiz, "trompa_1": medio1, "trompa_2": medio2, "trompa_3": fin})

# Silla (el jinete) y cuello_asiento (el mahout): sobre el lomo, más el grueso de los arreos.
x_silla = entre_patas(float(T.get("silla_pct", 0.6)))
alto_silla = float(T["silla_alto_pct"]) / 100.0 if "silla_alto_pct" in T else lomo_en(x_silla)
ARR = T.get("arreos", {})
grosor = 0.012 * H
howdah = ARR.get("howdah")
alto_asiento = alto_silla + grosor + (0.03 * H if howdah else 0.0)
J["silla"] = Vector((x_silla, cy, alto_asiento))
J["silla_end"] = J["silla"] + Vector((0, 0, 0.1 * H))
if "cuello_pct" in T:
    xc = entre_patas(float(T["cuello_pct"]))
    J["cuello_asiento"] = Vector((xc, cy, lomo_en(xc) + grosor))
    J["cuello_asiento_end"] = J["cuello_asiento"] + Vector((0, 0, 0.1 * H))

arm = bpy.data.armatures.new("Rig")
rig = bpy.data.objects.new("Rig", arm)
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
huesos = [("root", "root", None, None), ("hips", "hips", "spine", "root"), ("spine", "spine", "chest", "hips"),
          ("chest", "chest", "neck", "spine"), ("neck", "neck", "head", "chest"), ("head", "head", "head_end", "neck"),
          ("tail.1", "tail", "tail_mid", "hips"), ("tail.2", "tail_mid", "tail_end", "tail.1"),
          ("silla", "silla", "silla_end", "spine")]
if "cuello_asiento" in J:
    huesos.append(("cuello_asiento", "cuello_asiento", "cuello_asiento_end", "neck"))
if TROMPA:
    huesos += [("trompa.1", "trompa_0", "trompa_1", "head"), ("trompa.2", "trompa_1", "trompa_2", "trompa.1"),
               ("trompa.3", "trompa_2", "trompa_3", "trompa.2")]
for nombre in patas:
    padre = "chest" if nombre.startswith("front") else "hips"
    huesos += [(f"leg_{nombre}.upper", f"leg_{nombre}", f"knee_{nombre}", padre),
               (f"leg_{nombre}.lower", f"knee_{nombre}", f"fetlock_{nombre}", f"leg_{nombre}.upper"),
               (f"leg_{nombre}.hoof", f"fetlock_{nombre}", f"hoof_{nombre}", f"leg_{nombre}.lower")]
eb = arm.edit_bones
for nombre, a, b, padre in huesos:
    e = eb.new(nombre)
    e.head = J[a]
    e.tail = J[b] if b else J[a] + Vector((0, 0, 0.1 * H))
    if (e.tail - e.head).length < 1e-3:
        e.tail = e.head + Vector((0, 0, 0.05 * H))
    if padre:
        e.parent = eb[padre]
bpy.ops.object.mode_set(mode="OBJECT")
NO_DEFORMAN = {"silla", "cuello_asiento", "root"}
for b in arm.bones:
    b.use_deform = b.name not in NO_DEFORMAN

bpy.ops.object.select_all(action="DESELECT")
ob.select_set(True)
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.parent_set(type="ARMATURE_AUTO")
segs = {b.name: (b.head_local.copy(), b.tail_local.copy()) for b in arm.bones if b.use_deform}


def dist_seg(p, a, b):
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / max(ab.length_squared, 1e-9)))
    return (a + ab * t - p).length


def solo(v, hueso):
    for g in v.groups:
        ob.vertex_groups[g.group].remove([v.index])
    (ob.vertex_groups.get(hueso) or ob.vertex_groups.new(name=hueso)).add([v.index], 1.0, "REPLACE")


def por_zonas(v):
    """Pesos por zonas, cuando bone heat no puede (mallas de Meshy grandes y abiertas): lo que
    está bajo la panza y cerca de la columna de una pata, a los huesos de esa pata; la trompa a
    la trompa; el resto, al cuerpo. En cada zona, los dos huesos más cercanos con 1/d⁴. Así la
    tela que cuelga entre las patas va con el cuerpo y no se estira con ellas."""
    p = v.co
    cands = None
    if p.z < panza + 0.04 * H:
        r_pata = 0.09 * L
        pn = min(patas, key=lambda n: (Vector((p.x, p.y)) - Vector((patas[n].x, patas[n].y))).length)
        if (Vector((p.x, p.y)) - Vector((patas[pn].x, patas[pn].y))).length < r_pata:
            cands = [f"leg_{pn}.upper", f"leg_{pn}.lower", f"leg_{pn}.hoof"]
    if cands is None and TROMPA and p.x > J["trompa_0"].x - 0.02 * L and p.z < J["trompa_0"].z:
        cands = ["trompa.1", "trompa.2", "trompa.3", "head"]
    if cands is None:
        cands = [n for n in ("hips", "spine", "chest", "neck", "head", "tail.1", "tail.2") if n in segs]
    ds = sorted((dist_seg(p, *segs[n]), n) for n in cands)[:2]
    ws = [1.0 / (d ** 4 + 1e-6) for d, _ in ds]
    for g in v.groups:
        ob.vertex_groups[g.group].remove([v.index])
    for (d, n), w in zip(ds, ws):
        (ob.vertex_groups.get(n) or ob.vertex_groups.new(name=n)).add([v.index], w / sum(ws), "REPLACE")


sin_peso = [v for v in ob.data.vertices if not any(g.weight > 1e-4 for g in v.groups)]
ZONAS = len(sin_peso) > 0.05 * len(ob.data.vertices) or T.get("pesos") == "zonas"
for v in (ob.data.vertices if ZONAS else sin_peso):
    if ZONAS:
        por_zonas(v)
    else:
        solo(v, min(segs, key=lambda n: dist_seg(v.co, *segs[n])))
# Lo montado (por encima de rigido_desde_pct), entero al hueso del lomo más cercano en x.
lomo_x = {"hips": J["hips"].x, "spine": J["spine"].x, "chest": J["chest"].x, "neck": J["neck"].x}
rigidos = [v for v in ob.data.vertices if v.co.z > RIG]
for v in rigidos:
    solo(v, min(lomo_x, key=lambda n: abs(lomo_x[n] - v.co.x)))
for b in arm.bones:  # la silla deforma solo los arreos (el animal ya tiene sus pesos)
    b.use_deform = b.name != "root"
print(f"RIG tipo={TIPO} huesos={len(arm.bones)} zonas={ZONAS} sin_peso={len(sin_peso)} rigidos={len(rigidos)} "
      f"de {len(ob.data.vertices)} L={L:.2f} lomo={lomo_top:.2f}")

# ------------------------------------------------------------------ arreos


def pieza(nombre, verts, caras, mats, mat_de_cara, hueso="silla"):
    me = bpy.data.meshes.new(nombre)
    me.from_pydata(verts, [], caras)
    for m in mats:
        me.materials.append(m)
    for i, p in enumerate(me.polygons):
        p.material_index = mat_de_cara[i]
    o = bpy.data.objects.new(nombre, me)
    bpy.context.scene.collection.objects.link(o)
    sol = o.modifiers.new("grosor", "SOLIDIFY")
    sol.thickness = 0.008 * H
    sol.offset = 1.0
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.ops.object.modifier_apply(modifier="grosor")
    o.vertex_groups.new(name=hueso).add(list(range(len(o.data.vertices))), 1.0, "REPLACE")
    o.parent = rig
    mod = o.modifiers.new("Armature", "ARMATURE")
    mod.object = rig
    return o


def material(nombre, color):
    m = bpy.data.materials.new(nombre)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.9
    m.diffuse_color = (*color, 1.0)
    return m


M_EQ = material("equipo", (0.8, 0.05, 0.05))
M_BORDE = material("equipo_borde", (0.79, 0.64, 0.29))
M_MADERA = material("madera", (0.33, 0.22, 0.13))

if "manta" in ARR:
    mt = ARR["manta"]
    largo = float(mt.get("largo_pct", 26)) / 100.0 * L
    caida = float(mt.get("caida_pct", 25)) / 100.0 * H
    w = ancho_en(x_silla, 0.6 * alto_silla) + 0.012 * H
    zc = alto_silla - w * 0.9  # centro de la elipse del cuerpo
    hv = alto_silla - zc + 0.012 * H
    perfil = []  # (y, z) de un costado al otro, pasando por arriba
    nlados = 7
    for i in range(-nlados, nlados + 1):
        th = math.radians(90.0 * i / nlados)
        perfil.append((w * math.sin(th), zc + hv * math.cos(th)))
    abajo = max(0.0, caida - hv)
    if abajo > 0:
        perfil = [(-w, zc - abajo)] + perfil + [(w, zc - abajo)]
    nx = 4
    verts, caras, mi = [], [], []
    for ix in range(nx + 1):
        x = x_silla - largo / 2 + largo * ix / nx
        for (y, z) in perfil:
            verts.append((x, y, z))
    npf = len(perfil)
    for ix in range(nx):
        for j in range(npf - 1):
            a = ix * npf + j
            caras.append((a, a + 1, a + npf + 1, a + npf))
            mi.append(1 if (j == 0 or j == npf - 2) and abajo > 0 else 0)
    pieza("manta", verts, caras, [M_EQ, M_BORDE], mi)

if howdah:
    lx = float(howdah.get("largo_pct", 24)) / 100.0 * L
    ly = float(howdah.get("ancho_pct", 22)) / 100.0 * L
    az = float(howdah.get("alto_pct", 9)) / 100.0 * H
    z0 = alto_silla + grosor + 0.02 * H
    verts, caras = [], []

    def caja(c, s):
        b = len(verts)
        for dx in (-1, 1):
            for dy in (-1, 1):
                for dz in (-1, 1):
                    verts.append((c[0] + dx * s[0] / 2, c[1] + dy * s[1] / 2, c[2] + dz * s[2] / 2))
        for f in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)):
            caras.append(tuple(b + i for i in f))
    caja((x_silla, cy, z0), (lx, ly, 0.02 * H))  # piso
    for dx in (-1, 1):
        for dy in (-1, 1):
            caja((x_silla + dx * lx / 2, cy + dy * ly / 2, z0 + az / 2), (0.018 * L, 0.018 * L, az))  # postes
    for dy in (-1, 1):
        caja((x_silla, cy + dy * ly / 2, z0 + az), (lx, 0.012 * L, 0.012 * L))  # barandas
    for dx in (-1, 1):
        caja((x_silla + dx * lx / 2, cy, z0 + az), (0.012 * L, ly, 0.012 * L))
    me = bpy.data.meshes.new("howdah")
    me.from_pydata(verts, [], caras)
    me.materials.append(M_MADERA)
    o = bpy.data.objects.new("howdah", me)
    bpy.context.scene.collection.objects.link(o)
    o.vertex_groups.new(name="silla").add(list(range(len(verts))), 1.0, "REPLACE")
    o.parent = rig
    o.modifiers.new("Armature", "ARMATURE").object = rig

# ------------------------------------------------------------------ animaciones
pb = rig.pose.bones
for b in pb:
    b.rotation_mode = "QUATERNION"
LAT = Vector((0, 1, 0))  # girar sobre el eje lateral: positivo baja lo de adelante (+x)
VERT = Vector((0, 0, 1))
LARGO = Vector((1, 0, 0))
ADEL = -1.0  # en las patas (que cuelgan): ADEL·g lleva el pie hacia adelante; en el cuerpo, sube la cabeza
ABAJO = 1.0  # en el cuello y la cabeza: ABAJO·g la baja
R, P = {}, {}


def girar(nombre, eje, grados):
    if nombre not in pb or abs(grados) < 1e-6:
        return
    m = pb[nombre].bone.matrix_local.to_3x3().inverted()
    R[nombre] = Quaternion((m @ eje).normalized(), math.radians(grados)) @ R.get(nombre, Quaternion())


def mover(nombre, v):
    m = pb[nombre].bone.matrix_local.to_3x3().inverted()
    P[nombre] = P.get(nombre, Vector()) + m @ v


def pivote(eje, grados, punto):
    """Gira todo el cuerpo (root) sobre `punto` (las manos al encabritarse, el costado al caer)."""
    girar("root", eje, grados)
    q = Quaternion(eje, math.radians(grados))
    r0 = J["root"]
    mover("root", (punto - r0) - q @ (punto - r0))


def clave(f):
    for b in pb:
        b.rotation_quaternion = R.get(b.name, Quaternion())
        b.location = P.get(b.name, Vector())
        b.keyframe_insert("rotation_quaternion", frame=f)
        b.keyframe_insert("location", frame=f)
    R.clear()
    P.clear()


def suave(t):
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def tramo(t, a, b):
    """0 antes de a, 1 después de b, suave en el medio."""
    return suave((t - a) / max(1e-6, b - a))


PATAS = ["back_l", "front_l", "back_r", "front_r"]


def pata(p, adelante, doblez):
    """Pata: `adelante` grados hacia la cabeza; `doblez` grados de rodilla (la mano dobla hacia
    atrás, el garrón hacia adelante) y el casco acompaña."""
    girar(f"leg_{p}.upper", LAT, ADEL * adelante)
    d = doblez if p.startswith("front") else -doblez
    girar(f"leg_{p}.lower", LAT, -ADEL * d)
    girar(f"leg_{p}.hoof", LAT, ADEL * 0.6 * d)


def cola(t, k=1.0):
    girar("tail.1", VERT, k * 10 * math.sin(2 * math.pi * t))
    girar("tail.2", VERT, k * 10 * math.sin(2 * math.pi * t - 0.8))


def trompa(curva, vaiven=0.0):
    """Curva > 0 la recoge hacia adelante y arriba; vaiven la mueve de costado."""
    for i, k in ((1, 0.6), (2, 1.0), (3, 1.3)):
        girar(f"trompa.{i}", LAT, -ABAJO * curva * k)
        girar(f"trompa.{i}", VERT, vaiven * k)


rig.animation_data_create()
sc = bpy.context.scene
sc.render.fps = FPS
acciones = {}


def accion(nombre, fn):
    c = CLIPS[nombre]
    n = max(4, round(float(c["ciclo_s"]) * FPS))
    act = bpy.data.actions.new(nombre)
    rig.animation_data.action = act
    for f in range(n + 1):
        fn(f / n, c)
        clave(f)
    acciones[nombre] = act


def f_quieto(t, c):
    girar("chest", LAT, ADEL * 1.2 * math.sin(2 * math.pi * t))
    girar("neck", LAT, ABAJO * 4 * (0.5 - 0.5 * math.cos(2 * math.pi * t)))
    girar("head", LAT, ABAJO * 3 * math.sin(2 * math.pi * t))
    cola(t, 1.2)
    if TROMPA:
        trompa(8 * math.sin(2 * math.pi * t), 6 * math.sin(2 * math.pi * t + 1))


def f_pastar(t, c):
    g = float(c.get("cuello_grados", 50))
    girar("neck", LAT, ABAJO * g)
    girar("head", LAT, ABAJO * (g * 0.3 + 4 * math.sin(4 * math.pi * t)))
    girar("head", VERT, 6 * math.sin(2 * math.pi * t))
    girar("chest", LAT, ABAJO * 3)
    pata("front_l", 4, 2)
    pata("front_r", -3, 0)
    cola(t, 1.5)
    if TROMPA:  # el elefante arranca pasto con la trompa y se lo lleva a la boca
        k = 0.5 - 0.5 * math.cos(2 * math.pi * t)
        trompa(-10 + 70 * k, 0)


def f_andar(t, c):
    fases = c["fases"]
    amp = float(c["pierna_grados"])
    dob = float(c["doblez_grados"])
    galope = c is CLIPS.get("galope")
    for p, fase in zip(PATAS, fases):
        a = 2 * math.pi * (t + fase)
        levanta = max(0.0, math.cos(a))  # en el vuelo (la mitad que va hacia adelante)
        pata(p, amp * math.sin(a), dob * levanta)
    rb = float(c.get("rebote_pct", 1)) / 100.0 * H
    lg = float(c.get("lomo_grados", 1))
    cb = float(c.get("cabeceo_grados", 4))
    if galope:  # un rebote por ciclo: arriba en el vuelo; el lomo se arquea y se estira
        fa = 2 * math.pi * (t + fases[0])
        mover("root", Vector((0, 0, rb * (0.5 + 0.5 * math.cos(fa - 1.2)))))
        girar("root", LAT, ADEL * lg * 0.6 * math.sin(fa))
        girar("spine", LAT, ABAJO * lg * math.sin(fa + 0.8))
        girar("neck", LAT, ABAJO * cb * math.sin(fa + 1.6))
    else:
        mover("root", Vector((0, 0, rb * math.sin(4 * math.pi * t))))
        girar("spine", VERT, lg * math.sin(2 * math.pi * t))
        girar("neck", LAT, -ABAJO * cb * math.sin(4 * math.pi * t))
    cola(t, 1.0)
    if TROMPA:
        trompa(6 * math.sin(2 * math.pi * t), 8 * math.sin(2 * math.pi * t))


def f_ataque(t, c):
    g = float(c.get("alto_grados", 30))
    forma = T.get("ataque", "cabezazo")
    if forma == "encabritar":
        # sube (0–35 %), manotea arriba (35–65 %), baja y pisa (65–90 %)
        k = tramo(t, 0.0, 0.35) * (1 - tramo(t, 0.62, 0.88))
        pivote(LAT, ADEL * g * k, Vector((x_tra, cy, 0)))
        for p, ph in (("front_l", 0.0), ("front_r", 0.5)):
            mano = math.sin(2 * math.pi * (t * 3 + ph))
            pata(p, k * (35 + 15 * mano), k * (95 + 20 * mano))
        for p in ("back_l", "back_r"):
            pata(p, k * g * 0.9, k * 25)
        girar("neck", LAT, ABAJO * -k * 12)
        girar("head", LAT, ABAJO * k * 20)
        girar("tail.1", LAT, ABAJO * k * 25)
    elif forma == "pisoton":
        # levanta una mano y la trompa (0–50 %), pisa fuerte (50–65 %) y vuelve
        k = tramo(t, 0.0, 0.5) * (1 - tramo(t, 0.5, 0.62))
        pivote(LAT, ADEL * g * k, Vector((x_tra, cy, 0)))
        pata("front_l", k * 30, k * 55)
        pata("front_r", k * 8, k * 8)
        for p in ("back_l", "back_r"):
            pata(p, k * g * 0.8, k * 6)
        girar("neck", LAT, -ABAJO * k * 10)
        trompa(k * 60 - (1 - k) * tramo(t, 0.5, 0.65) * (1 - tramo(t, 0.75, 1.0)) * 15)
        impacto = tramo(t, 0.5, 0.56) * (1 - tramo(t, 0.56, 0.75))
        girar("chest", LAT, ABAJO * impacto * 3)
    else:
        # cabezazo: baja la cabeza, embiste hacia adelante y vuelve
        k = tramo(t, 0.0, 0.4) * (1 - tramo(t, 0.55, 0.95))
        emb = tramo(t, 0.3, 0.45) * (1 - tramo(t, 0.5, 0.9))
        girar("neck", LAT, ABAJO * k * g)
        girar("head", LAT, ABAJO * k * g * 0.4)
        mover("root", Vector((emb * 0.07 * L, 0, 0)))
        pata("back_l", -emb * 14, 0)
        pata("back_r", -emb * 10, 0)
        pata("front_l", emb * 10, emb * 15)
    cola(t, 1.5)


def f_golpeado(t, c):
    k = math.sin(math.pi * tramo(t, 0.0, 1.0)) * (1.0 - t * 0.3)
    girar("root", LARGO, 4 * k)
    girar("neck", LAT, -ABAJO * 10 * k)
    girar("head", VERT, 10 * k)
    girar("spine", VERT, -4 * k)
    pata("front_l", 6 * k, 15 * k)
    cola(t, 2.0)
    if TROMPA:
        trompa(30 * k)


W_CUERPO = ancho_en(x_mid, 0.6 * lomo_top)


def f_morir(t, c):
    # se le doblan las manos (0–35 %) y cae de costado (25–85 %); queda tendido
    kd = tramo(t, 0.0, 0.35)
    kc = tramo(t, 0.25, 0.85)
    pivote(LAT, ABAJO * 10 * kd * (1 - kc), Vector((x_tra, cy, 0)))
    mover("root", Vector((0, 0, -0.08 * H * kd * (1 - kc))))
    pivote(LARGO, -84 * kc, Vector((x_mid, -W_CUERPO, 0)))
    for p in ("front_l", "front_r"):
        pata(p, -10 * kd + 25 * kc, 60 * kd * (1 - kc) + 10 * kc)
    for p in ("back_l", "back_r"):
        pata(p, -15 * kc, 20 * kd * (1 - kc) + 10 * kc)
    girar("neck", LAT, ABAJO * (12 * kd + 10 * kc))
    girar("neck", VERT, 15 * kc)
    girar("head", LAT, ABAJO * 15 * kc)
    girar("tail.1", LAT, ABAJO * 20 * kc)
    if TROMPA:
        trompa(-15 * kc, 10 * kc)


accion("quieto", f_quieto)
accion("pastar", f_pastar)
accion("caminar", f_andar)
accion("galope", f_andar)
accion("ataque", f_ataque)
accion("golpeado", f_golpeado)
accion("morir", f_morir)

for act in acciones.values():
    for fc in getattr(act, "fcurves", []):
        for k in fc.keyframe_points:
            k.interpolation = "LINEAR"
    tr = rig.animation_data.nla_tracks.new()
    tr.name = act.name
    tr.strips.new(act.name, 0, act)
    tr.mute = True

# ------------------------------------------------------------------ renders
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"
sc.display.shading.color_type = "MATERIAL" if not ob.data.uv_layers else "TEXTURE"
sc.render.image_settings.file_format = "JPEG"
sc.world = bpy.data.worlds.new("w")
sc.world.color = (0.82, 0.8, 0.76)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
sc.collection.objects.link(cam)
sc.camera = cam
cam.data.angle = math.radians(30)
centro = Vector((0, cy, 0.45 * H))


def camara(off):
    cam.location = centro + off
    cam.rotation_euler = (-off).to_track_quat("-Z", "Y").to_euler()


def ver(nombre, frames, sufijo, off, res):
    rig.animation_data.action = acciones[nombre]
    sc.frame_start, sc.frame_end = 0, frames[-1]
    sc.render.resolution_x, sc.render.resolution_y = res
    camara(off)
    for i, f in enumerate(frames):
        sc.frame_set(f)
        sc.render.filepath = f"{prefijo}_{sufijo}_{i:02d}.jpg"
        bpy.ops.render.render(write_still=True)


d = max(L, H) * 2.3
nc = round(float(CLIPS["caminar"]["ciclo_s"]) * FPS)
ver("caminar", [round(nc * i / 4) for i in range(4)], "caminar", Vector((0, -1, 0.12)) * d, (512, 400))
if "tiras" in opt:
    tres_cuartos = Vector((0.55, -1, 0.45)).normalized() * d
    for nombre in ("galope", "ataque", "morir"):
        n = round(float(CLIPS[nombre]["ciclo_s"]) * FPS)
        ver(nombre, [round(n * i / 5) for i in range(6)], nombre, tres_cuartos, (240, 200))

bpy.data.objects.remove(cam)
rig.animation_data.action = None
for tr in rig.animation_data.nla_tracks:
    tr.mute = False
sc.frame_set(0)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", export_image_format="JPEG", export_jpeg_quality=85,
                          export_animations=True, export_animation_mode="NLA_TRACKS", use_selection=False,
                          export_def_bones=False)
print("RIG listo", dst)
