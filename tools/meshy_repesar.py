"""Arreglo de los pesos de un personaje riggeado por Meshy, sin créditos (proceso/56-rig-y-color).

    blender --background --python tools/meshy_repesar.py -- riggeado.glb salida.glb modo [radio_mano]

Diagnóstico de proceso/56: el rig de Meshy le da a la cabeza y al pelo peso de la mano que sostiene
la herramienta (y a la herramienta, peso de la cabeza); al mover la mano, la cara se estira en punta.
Antes de repesar, se detecta la herramienta pegada: vértices que domina una mano y que están a más
de `radio_mano` (0,25 m) de ella, crecidos por vecindad hasta la cápsula de la mano (antebrazo a
punta de los dedos). La cabeza es lo que queda por encima del cuello dentro de un cilindro.

modo:
- marcar: pinta herramienta (verde), cabeza (rojo) y cuello (naranja) en colores de vértice, para revisar;
- a: repesado sobre los pesos de Meshy: cabeza, gorro y pelo 100 % a Head, cuello en degradé, sin pesos
  de mano lejos de la mano, herramienta borrada (y astillas sueltas), torso y túnica suavizados;
- c: herramienta borrada y pesos nuevos de Blender (calor de huesos) sobre el mismo esqueleto de Meshy,
  con la cabeza rígida como en (a). Es el que mejor quedó; conserva los clips de Meshy del GLB.
Los clips del GLB de entrada se exportan tal cual.
"""
import bpy, sys, bmesh
from mathutils import Vector
from mathutils.kdtree import KDTree

a = sys.argv[sys.argv.index("--") + 1:]
src, dst, modo = a[0], a[1], a[2]
R_MANO = float(a[3]) if len(a) > 3 else 0.25
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
for o in list(bpy.context.scene.objects):
    if o.type == "MESH" and o.name.startswith("Icosphere"):
        bpy.data.objects.remove(o)
arm = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
ob = next(o for o in bpy.context.scene.objects if o.type == "MESH")
me = ob.data
names = {g.index: g.name for g in ob.vertex_groups}
VG = {g.name: g for g in ob.vertex_groups}
W = ob.matrix_world
AW = arm.matrix_world
B = {b.name: (AW @ b.head_local) for b in arm.data.bones}
P = [W @ v.co for v in me.vertices]
Winv = W.inverted()

# --- herramienta: dominada por una mano y lejos de ella, crecida por vecindad ---
def dominante(v):
    return names[max(v.groups, key=lambda g: g.weight).group] if v.groups else ""

manos = {"LeftHand": B["LeftHand"], "RightHand": B["RightHand"]}
# centro de cada mano: un poco más allá de la muñeca, hacia el antebrazo opuesto
ANTE = {"LeftHand": B["LeftForeArm"], "RightHand": B["RightForeArm"]}
hc0 = B["Head"]
cz0 = B["neck"].z
def en_mano(p, d):
    """Cápsula del antebrazo a la punta de los dedos (la muñeca más 12 cm)."""
    a0, a1 = ANTE[d], manos[d]
    u = (a1 - a0).normalized()
    b = a1 + u * 0.22
    t = max(0.0, min(1.0, (p - a1).dot(u) / 0.22))
    q = a1 + (b - a1) * t
    return (p - q).length < 0.065 or ((p - a1).dot(u) < 0 and (p - a1).length < 0.07)
def en_cabeza(p):
    r = ((p.x - hc0.x) ** 2 + (p.y - hc0.y) ** 2) ** 0.5
    return p.z > cz0 and r < 0.13 and (p - (hc0 + Vector((0, 0, 0.1)))).length < 0.2
semilla = set()
for v in me.vertices:
    d = dominante(v)
    p = P[v.index]
    if d in manos and not en_mano(p, d) and not en_cabeza(p) and (p - manos[d]).length > R_MANO:
        semilla.add(v.index)
# soldar por posición para crecer por las costuras del atlas
bm = bmesh.new(); bm.from_mesh(me); bm.verts.ensure_lookup_table()
kd = KDTree(len(P))
for i, p in enumerate(P):
    kd.insert(p, i)
kd.balance()
vec = [set() for _ in P]
for e in bm.edges:
    i, j = e.verts[0].index, e.verts[1].index
    vec[i].add(j); vec[j].add(i)
for i, p in enumerate(P):
    for (_, j, _) in kd.find_range(p, 1e-4):
        if j != i:
            vec[i].add(j)
# crecer la herramienta hacia vértices que la mano domina (el mango dentro del puño queda igual)
herr = set(semilla)
borde = list(semilla)
while borde:
    i = borde.pop()
    for j in vec[i]:
        if j in herr:
            continue
        v = me.vertices[j]
        d = dominante(v)
        if d in manos and not en_mano(P[j], d) and not en_cabeza(P[j]):
            herr.add(j); borde.append(j)
print("HERRAMIENTA", len(herr), "de", len(P))

# --- cabeza: esfera alrededor de la cabeza, por encima del cuello ---
hc = B["Head"]
cz = B["neck"].z
cab = set()
mezcla = {}
for i, p in enumerate(P):
    if i in herr:
        continue
    r = ((p.x - hc.x) ** 2 + (p.y - hc.y) ** 2) ** 0.5
    if p.z > hc.z - 0.01 and r < 0.16 or en_cabeza(p) and p.z > hc.z - 0.03:
        cab.add(i)
    elif cz <= p.z <= hc.z - 0.01 and r < 0.12:
        mezcla[i] = (p.z - cz) / max(0.001, hc.z - 0.01 - cz)
print("CABEZA", len(cab), "CUELLO", len(mezcla))

if modo == "marcar":
    ca = me.color_attributes.new("dbg", "FLOAT_COLOR", "POINT")
    for i in range(len(P)):
        c = (0.3, 0.3, 0.35, 1)
        if i in herr: c = (0.1, 0.9, 0.2, 1)
        elif i in cab: c = (0.95, 0.25, 0.2, 1)
        elif i in mezcla: c = (0.9, 0.6, 0.2, 1)
        ca.data[i].color = c
    me.color_attributes.active_color = ca


def solo(i, pesos):
    v = me.vertices[i]
    for g in list(v.groups):
        VG[names[g.group]].remove([i])
    for n, w in pesos.items():
        if w > 0:
            VG[n].add([i], w, "REPLACE")


def borrar(idx, min_parte=80):
    """Borra la herramienta y después las astillas que quedan sueltas (partes chicas)."""
    bm = bmesh.new(); bm.from_mesh(me); bm.verts.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[bm.verts[i] for i in idx], context="VERTS")
    bm.verts.ensure_lookup_table()
    pos = {}
    for v in bm.verts:
        pos.setdefault(tuple(round(c, 4) for c in v.co), []).append(v)
    visto = set(); sueltas = []
    for v in bm.verts:
        if v in visto: continue
        comp = []; st = [v]; visto.add(v)
        while st:
            x = st.pop(); comp.append(x)
            vec_ = [e.other_vert(x) for e in x.link_edges] + pos[tuple(round(c, 4) for c in x.co)]
            for o in vec_:
                if o not in visto:
                    visto.add(o); st.append(o)
        if len(comp) < min_parte:
            sueltas += comp
    print("ASTILLAS", len(sueltas))
    bmesh.ops.delete(bm, geom=sueltas, context="VERTS")
    bm.to_mesh(me); bm.free()


if modo == "a":
    # 1) la cabeza (con el gorro y el pelo) rígida a Head; el cuello, en degradé
    for i in cab:
        solo(i, {"Head": 1.0})
    for i, t in mezcla.items():
        solo(i, {"Head": t, "neck": 1 - t})
    # 2) fuera de la mano: ningún peso de mano en el cuerpo
    for v in me.vertices:
        if v.index in herr or v.index in cab:
            continue
        for g in list(v.groups):
            n = names[g.group]
            if n in manos and (P[v.index] - manos[n]).length > R_MANO * 0.6:
                VG[n].remove([v.index])
    # 3) la herramienta afuera (antes de soldar, mientras valen los índices)
    borrar(herr)
    # 4) suavizar el torso y la túnica (entre rodillas y cuello), sin tocar la cabeza
    bpy.context.view_layer.objects.active = ob
    rod = B["LeftLeg"].z
    for v in me.vertices:
        p = W @ v.co
        v.select = (rod < p.z < cz) and not en_cabeza(p)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.remove_doubles(threshold=1e-4)  # solo los seleccionados: une las costuras del atlas
    bpy.ops.object.mode_set(mode="WEIGHT_PAINT")
    me.use_paint_mask_vertex = True
    bpy.ops.object.vertex_group_smooth(group_select_mode="ALL", factor=0.5, repeat=4, expand=0.0)
    bpy.ops.object.vertex_group_limit_total(group_select_mode="ALL", limit=4)
    bpy.ops.object.vertex_group_normalize_all(lock_active=False)
    bpy.ops.object.mode_set(mode="OBJECT")

if modo == "c":
    # c) la herramienta afuera y pesos de Blender (calor de huesos) sobre el esqueleto de Meshy;
    #    después, la cabeza rígida como en (a).
    borrar(herr)
    # recalcular índices de cabeza tras borrar: por posición
    for g in list(ob.vertex_groups):
        ob.vertex_groups.remove(g)
    ob.parent = None
    ob.matrix_world = W
    for m in list(ob.modifiers):
        ob.modifiers.remove(m)
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
    bm.to_mesh(me); bm.free()
    # la cola de los huesos sale rara de la importación: enderezar hacia el hijo
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    for e in arm.data.edit_bones:
        if e.children:
            e.tail = e.children[0].head if (e.children[0].head - e.head).length > 1e-3 else e.head + Vector((0, 0, 5))
        elif e.parent:
            d = (e.head - e.parent.head)
            e.tail = e.head + d.normalized() * max(d.length * 0.5, 3)
        e.use_deform = e.name not in ("head_end", "headfront")
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True); arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    sin = sum(1 for v in me.vertices if not v.groups)
    print("SIN_PESO", sin, len(me.vertices))
    names = {g.index: g.name for g in ob.vertex_groups}
    VG = {g.name: g for g in ob.vertex_groups}
    Wn = ob.matrix_world
    for v in me.vertices:
        p = Wn @ v.co
        r = ((p.x - hc.x) ** 2 + (p.y - hc.y) ** 2) ** 0.5
        if p.z > hc.z - 0.01 and r < 0.16:
            solo(v.index, {"Head": 1.0})
        elif cz <= p.z <= hc.z - 0.01 and r < 0.12:
            t = (p.z - cz) / max(0.001, hc.z - 0.01 - cz)
            solo(v.index, {"Head": t, "neck": 1 - t})

bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", export_image_format="JPEG",
                          export_jpeg_quality=88, export_animations=True, export_vertex_color="ACTIVE" if modo == "marcar" else "NONE")
print("LISTO", dst, len(me.vertices))
