"""Rig de cuadrúpedo con ciclos de caminar y quieto (proceso/47-pipeline-3d), en Blender.

    blender --background --python tools/gen3d_rig_cuadrupedo.py -- entrada.glb salida_rig.glb render_prefijo

Para un animal generado de perfil (el caballo): alto 1, apoyado en el suelo, con el largo del
cuerpo sobre x (como lo deja tools/gen3d_blender.py). Busca la cabeza (el extremo más alto),
las cuatro patas (los grupos de vértices cerca del suelo, adelante y atrás, de cada lado) y
arma 18 huesos: root, hips, spine, chest, neck, head, tail.1, tail.2 y por pata upper, lower y
hoof (leg_front.l, leg_front.r, leg_back.l, leg_back.r). Pesos automáticos (bone heat), con
los vértices sin peso pasados al hueso más cercano.

Dos acciones, en pistas NLA para que el GLB las lleve:
  caminar  1 s (24 cuadros): paso de cuatro tiempos (trasera izq., delantera izq., trasera
           der., delantera der.), rodilla que se dobla al levantar, cabeceo y vaivén del lomo
  quieto   2 s (48 cuadros): respiración, la cabeza que baja un poco y la cola
Renders: el ciclo de caminar en 4 cuadros, de costado.
"""
import math
import sys

import bmesh
import bpy
from mathutils import Quaternion, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
src, dst, prefijo = argv[:3]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
ob = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
bpy.context.view_layer.objects.active = ob
ob.select_set(True)
bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bm = bmesh.new()
bm.from_mesh(ob.data)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
bm.to_mesh(ob.data)
bm.free()
ob.name = "animal"

V = [v.co.copy() for v in ob.data.vertices]
H = max(v.z for v in V)
xs = [v.x for v in V]
x0, x1 = min(xs), max(xs)
L = x1 - x0
cy = sum(v.y for v in V) / len(V)


def media(pts):
    s = Vector((0, 0, 0))
    for p in pts:
        s += p
    return s / max(len(pts), 1)


# La cabeza es el extremo más alto: se mira el alto máximo en el quinto de cada punta.
alto_a = max((v.z for v in V if v.x < x0 + 0.2 * L), default=0)
alto_b = max((v.z for v in V if v.x > x1 - 0.2 * L), default=0)
s = -1.0 if alto_a >= alto_b else 1.0  # dirección de la cabeza sobre x
punta_cab = x0 if s < 0 else x1
punta_cola = x1 if s < 0 else x0


def hacia(d):
    """Coordenada x a una fracción d del largo, desde la cola (0) hacia la cabeza (1)."""
    return punta_cola + s * d * L


# Patas: vértices bajo el 12 % del alto, partidos en delanteras y traseras por el centro del
# grupo, y cada grupo por su y media en izquierda y derecha (Blender −y es el lado que mira la
# cámara de la imagen de entrada).
bajos = [v for v in V if v.z < 0.12 * H]
xm = media(bajos).x
grupos = {"front": [v for v in bajos if (v.x - xm) * s > 0], "back": [v for v in bajos if (v.x - xm) * s <= 0]}
patas = {}
for g, pts in grupos.items():
    ym = media(pts).y
    for lado, sel in (("l", [v for v in pts if v.y > ym]), ("r", [v for v in pts if v.y <= ym])):
        sel = sel or pts
        patas[f"{g}.{lado}"] = media(sel)

lomo = 0.62 * H  # cruz y grupa
panza = 0.45 * H
x_del = media([patas["front.l"], patas["front.r"]]).x
x_tra = media([patas["back.l"], patas["back.r"]]).x
# Cabeza: el vértice más alto del tercio delantero (las orejas) y el más adelantado (el hocico).
frente = [v for v in V if (v.x - x_del) * s > -0.05 * L]
orejas = max(frente, key=lambda v: v.z)
hocico = max(frente, key=lambda v: (v.x * s, -abs(v.z - orejas.z)))
cola_pts = [v for v in V if (v.x - punta_cola) * s < 0.06 * L and v.z > 0.25 * H]
cola_fin = min(cola_pts, key=lambda v: v.z) if cola_pts else Vector((punta_cola, cy, 0.4 * H))

J = {
    "root": Vector(((x_del + x_tra) / 2, cy, 0)),
    "hips": Vector((x_tra, cy, lomo)),
    "spine": Vector(((x_del + x_tra) / 2, cy, lomo)),
    "chest": Vector((x_del, cy, lomo)),
    "neck": Vector((x_del + s * 0.08 * L, cy, lomo + 0.05 * H)),
    "head": Vector((orejas.x - s * 0.02 * L, cy, orejas.z - 0.06 * H)),
    "head_end": Vector((hocico.x, cy, hocico.z)),
    "tail": Vector((punta_cola + s * 0.04 * L, cy, lomo + 0.02 * H)),
}
J["tail_mid"] = J["tail"].lerp(Vector((cola_fin.x, cy, cola_fin.z)), 0.45)
J["tail_end"] = Vector((cola_fin.x, cy, cola_fin.z))
for nombre, p in patas.items():
    arriba = Vector((p.x, p.y * 0.6 + cy * 0.4, panza + 0.04 * H))
    rodilla = Vector((p.x, p.y, 0.30 * H))
    menudillo = Vector((p.x, p.y, 0.08 * H))
    J[f"leg_{nombre}"] = arriba
    J[f"knee_{nombre}"] = rodilla
    J[f"fetlock_{nombre}"] = menudillo
    J[f"hoof_{nombre}"] = Vector((p.x + s * 0.02 * L, p.y, 0.0))

arm = bpy.data.armatures.new("Rig")
rig = bpy.data.objects.new("Rig", arm)
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
huesos = [("root", "root", None, None), ("hips", "hips", "spine", "root"), ("spine", "spine", "chest", "hips"),
          ("chest", "chest", "neck", "spine"), ("neck", "neck", "head", "chest"), ("head", "head", "head_end", "neck"),
          ("tail.1", "tail", "tail_mid", "hips"), ("tail.2", "tail_mid", "tail_end", "tail.1")]
for nombre in patas:
    padre = "chest" if nombre.startswith("front") else "hips"
    huesos += [(f"leg_{nombre}.upper", f"leg_{nombre}", f"knee_{nombre}", padre),
               (f"leg_{nombre}.lower", f"knee_{nombre}", f"fetlock_{nombre}", f"leg_{nombre}.upper"),
               (f"leg_{nombre}.hoof", f"fetlock_{nombre}", f"hoof_{nombre}", f"leg_{nombre}.lower")]
eb = arm.edit_bones
for nombre, a, b, padre in huesos:
    e = eb.new(nombre.replace("leg_front.", "leg_front_").replace("leg_back.", "leg_back_"))
    e.head = J[a]
    e.tail = J[b] if b else J[a] + Vector((0, 0, 0.1 * H))
    if padre:
        e.parent = eb[padre.replace("leg_front.", "leg_front_").replace("leg_back.", "leg_back_")]
bpy.ops.object.mode_set(mode="OBJECT")

bpy.ops.object.select_all(action="DESELECT")
ob.select_set(True)
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.parent_set(type="ARMATURE_AUTO")
# Vértices sin peso (bone heat falla en mallas no cerradas): al hueso más cercano.
segs = {b.name: (b.head_local.copy(), b.tail_local.copy()) for b in arm.bones}


def dist_seg(p, a, b):
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / max(ab.length_squared, 1e-9)))
    return (a + ab * t - p).length


sin_peso = [v for v in ob.data.vertices if not v.groups]
for v in sin_peso:
    hueso = min(segs, key=lambda n: dist_seg(v.co, *segs[n]))
    g = ob.vertex_groups.get(hueso) or ob.vertex_groups.new(name=hueso)
    g.add([v.index], 1.0, "REPLACE")
print(f"RIG huesos={len(arm.bones)} cabeza_hacia={'-x' if s < 0 else '+x'} sin_peso_antes={len(sin_peso)} "
      f"de {len(ob.data.vertices)}")

# ------------------------------------------------------------------ animaciones
pb = rig.pose.bones
for b in pb:
    b.rotation_mode = "QUATERNION"
LAT = Vector((0, 1, 0))  # eje lateral: girar sobre él lleva la pata adelante o atrás
VERT = Vector((0, 0, 1))


def rot(nombre, eje, grados):
    b = pb[nombre]
    m = b.bone.matrix_local.to_3x3().inverted()
    b.rotation_quaternion = Quaternion((m @ eje).normalized(), math.radians(grados))


def limpiar():
    for b in pb:
        b.rotation_quaternion = Quaternion()
        b.location = Vector()


def clave(f):
    for b in pb:
        b.keyframe_insert("rotation_quaternion", frame=f)
        b.keyframe_insert("location", frame=f)


rig.animation_data_create()
sc = bpy.context.scene
sc.render.fps = 24
# Positivo sobre +y lleva hacia −x; la cabeza va hacia s·x: adelante = −s.
ADEL = -s
fases = {"back_l": 0.0, "front_l": 0.25, "back_r": 0.5, "front_r": 0.75}
acciones = []

act = bpy.data.actions.new("caminar")
rig.animation_data.action = act
N = 24
for f in range(N + 1):
    t = f / N
    limpiar()
    for pata, fase in fases.items():
        a = 2 * math.pi * (t + fase)
        rot(f"leg_{pata}.upper", LAT, ADEL * 18 * math.sin(a))
        levanta = max(0.0, math.sin(a + math.pi / 2))  # en el vuelo, la mitad que va hacia adelante
        doblez = 35 * levanta if pata.startswith("front") else -30 * levanta
        rot(f"leg_{pata}.lower", LAT, -ADEL * doblez)
        rot(f"leg_{pata}.hoof", LAT, ADEL * 0.6 * doblez)
    rot("neck", LAT, -ADEL * 4 * math.sin(4 * math.pi * t))
    rot("spine", VERT, 2.5 * math.sin(2 * math.pi * t))
    rot("tail.1", VERT, 8 * math.sin(2 * math.pi * t))
    pb["root"].location = Vector((0, 0.012 * H * math.sin(4 * math.pi * t), 0))  # y del hueso = arriba
    clave(f)
acciones.append(act)

act = bpy.data.actions.new("quieto")
rig.animation_data.action = act
N = 48
for f in range(N + 1):
    t = f / N
    limpiar()
    rot("chest", LAT, ADEL * 1.2 * math.sin(2 * math.pi * t))
    rot("neck", LAT, ADEL * 5 * (0.5 - 0.5 * math.cos(2 * math.pi * t)))
    rot("head", LAT, ADEL * 4 * math.sin(2 * math.pi * t))
    rot("tail.1", VERT, 12 * math.sin(2 * math.pi * t))
    rot("tail.2", VERT, 10 * math.sin(2 * math.pi * t - 0.8))
    clave(f)
acciones.append(act)

for act in acciones:
    for fc in getattr(act, "fcurves", []):
        for k in fc.keyframe_points:
            k.interpolation = "LINEAR"
    tr = rig.animation_data.nla_tracks.new()
    tr.name = act.name
    tr.strips.new(act.name, 0, act)
rig.animation_data.action = None
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", export_image_format="JPEG", export_jpeg_quality=85,
                          export_animations=True, export_animation_mode="NLA_TRACKS")

# Renders del caminar.
rig.animation_data.action = acciones[0]
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"
sc.display.shading.color_type = "TEXTURE"
sc.render.resolution_x, sc.render.resolution_y = 512, 400
sc.render.image_settings.file_format = "JPEG"
sc.world = bpy.data.worlds.new("w")
sc.world.color = (0.82, 0.8, 0.76)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
sc.collection.objects.link(cam)
sc.camera = cam
cam.data.angle = math.radians(30)
off = Vector((0, -1, 0.12)) * (max(L, H) * 2.2)
cam.location = Vector(((x0 + x1) / 2, cy, 0.45 * H)) + off
cam.rotation_euler = (-off).to_track_quat("-Z", "Y").to_euler()
for f in (0, 6, 12, 18):
    sc.frame_set(f)
    sc.render.filepath = f"{prefijo}_caminar_{f:02d}.jpg"
    bpy.ops.render.render(write_still=True)
