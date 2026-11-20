"""Autorrig de un aldeano generado en pose A (proceso/43-3d-local), sin servicios externos.

    blender --background --python tools/gen3d_rig.py -- entrada.glb salida_rig.glb salida_mixamo.fbx render_prefijo

- Ubica las articulaciones mirando la malla (alto 1, frente −y en Blender, como la deja
  tools/gen3d_blender.py): las manos son los vértices más alejados a cada lado, las piernas
  salen de un corte a la altura de las canillas y el resto, de proporciones de persona.
- Arma un esqueleto con los nombres de KayKit Rig_Medium (root, hips, spine, chest, head,
  upperarm.l, lowerarm.l, wrist.l, upperleg.l, lowerleg.l, foot.l, toes.l y los .r), para usar
  el mismo BoneMap de proceso/27-animaciones con SkeletonProfileHumanoid.
- Pesos automáticos (bone heat) después de soldar las costuras del atlas UV.
- Exporta el GLB riggeado, un FBX sin esqueleto para Mixamo y dos renders de prueba con una
  pose (brazos abajo y un paso), para ver si los pesos aguantan.
"""
import math
import sys

import bmesh
import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
src, dst_rig, dst_fbx, prefijo = argv[:4]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
ob = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
bpy.context.view_layer.objects.active = ob
ob.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bm = bmesh.new()
bm.from_mesh(ob.data)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
bm.to_mesh(ob.data)
bm.free()
ob.name = "aldeano"

# FBX para Mixamo: malla sola, con la textura adentro.
bpy.ops.export_scene.fbx(filepath=dst_fbx, use_selection=True, path_mode="COPY", embed_textures=True,
                         axis_forward="-Z", axis_up="Y")

V = [ob.matrix_world @ v.co for v in ob.data.vertices]
H = max(v.z for v in V)


def media(pts):
    s = Vector((0, 0, 0))
    for p in pts:
        s += p
    return s / max(len(pts), 1)


# Manos: lo más lejos a cada lado entre el 45 % y el 85 % del alto.
brazos = [v for v in V if 0.45 * H < v.z < 0.85 * H]
mano_l = max(brazos, key=lambda v: v.x)  # Blender +x = izquierda del personaje que mira a −y
mano_r = min(brazos, key=lambda v: v.x)
# Piernas: corte a la altura de las canillas.
canilla = [v for v in V if 0.10 * H < v.z < 0.16 * H]
pie_l = media([v for v in canilla if v.x > 0])
pie_r = media([v for v in canilla if v.x <= 0])
# Tronco: ancho a la altura del pecho, sin los brazos (los vértices cerca del centro).
pecho = [v for v in V if 0.72 * H < v.z < 0.76 * H and abs(v.x) < 0.14 * H]
hombro_x = max(abs(v.x) for v in pecho) * 0.85 if pecho else 0.1 * H
cy = media([v for v in V if 0.5 * H < v.z < 0.8 * H and abs(v.x) < 0.1 * H]).y

J = {
    "root": Vector((0, cy, 0)),
    "hips": Vector((0, cy, 0.52 * H)),
    "spine": Vector((0, cy, 0.60 * H)),
    "chest": Vector((0, cy, 0.70 * H)),
    "neck": Vector((0, cy, 0.83 * H)),
    "head": Vector((0, cy, 0.87 * H)),
    "head_end": Vector((0, cy, H)),
}
for lado, s, mano, pie in (("l", 1, mano_l, pie_l), ("r", -1, mano_r, pie_r)):
    hombro = Vector((s * hombro_x, cy, 0.80 * H))
    dedos = Vector((mano.x, mano.y, mano.z))
    muneca = hombro.lerp(dedos, 0.86)
    codo = hombro.lerp(muneca, 0.5) + Vector((0, 0.02 * H, -0.01 * H))
    cadera = Vector((s * abs(pie.x) * 0.95, cy, 0.50 * H))
    tobillo = Vector((pie.x, pie.y, 0.045 * H))
    rodilla = cadera.lerp(tobillo, 0.5) + Vector((0, -0.01 * H, 0))
    J |= {f"upperarm.{lado}": hombro, f"lowerarm.{lado}": codo, f"wrist.{lado}": muneca,
          f"wrist_end.{lado}": dedos, f"upperleg.{lado}": cadera, f"lowerleg.{lado}": rodilla,
          f"foot.{lado}": tobillo, f"toes.{lado}": Vector((pie.x, pie.y - 0.06 * H, 0.01 * H)),
          f"toes_end.{lado}": Vector((pie.x, pie.y - 0.10 * H, 0.01 * H))}

arm = bpy.data.armatures.new("Rig")
rig = bpy.data.objects.new("Rig", arm)
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
huesos = [  # nombre, cabeza, cola, padre
    ("root", "root", None, None), ("hips", "hips", "spine", "root"), ("spine", "spine", "chest", "hips"),
    ("chest", "chest", "neck", "spine"), ("head", "head", "head_end", "chest"),
]
for l in ("l", "r"):
    huesos += [
        (f"upperarm.{l}", f"upperarm.{l}", f"lowerarm.{l}", "chest"),
        (f"lowerarm.{l}", f"lowerarm.{l}", f"wrist.{l}", f"upperarm.{l}"),
        (f"wrist.{l}", f"wrist.{l}", f"wrist_end.{l}", f"lowerarm.{l}"),
        (f"upperleg.{l}", f"upperleg.{l}", f"lowerleg.{l}", "hips"),
        (f"lowerleg.{l}", f"lowerleg.{l}", f"foot.{l}", f"upperleg.{l}"),
        (f"foot.{l}", f"foot.{l}", f"toes.{l}", f"lowerleg.{l}"),
        (f"toes.{l}", f"toes.{l}", f"toes_end.{l}", f"foot.{l}"),
    ]
eb = arm.edit_bones
for nombre, a, b, padre in huesos:
    e = eb.new(nombre)
    e.head = J[a]
    e.tail = J[b] if b else J[a] + Vector((0, 0, 0.1 * H))
    if padre:
        e.parent = eb[padre]
        e.use_connect = False
bpy.ops.object.mode_set(mode="OBJECT")

bpy.ops.object.select_all(action="DESELECT")
ob.select_set(True)
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.parent_set(type="ARMATURE_AUTO")
sin_peso = sum(1 for v in ob.data.vertices if not v.groups)
print(f"RIG huesos={len(arm.bones)} vertices_sin_peso={sin_peso} de {len(ob.data.vertices)}")
bpy.ops.export_scene.gltf(filepath=dst_rig, export_format="GLB", export_image_format="JPEG", export_jpeg_quality=85)

# Pose de prueba: brazos abajo y un paso.
bpy.ops.object.mode_set(mode="POSE")
pb = rig.pose.bones


def girar(nombre, eje_mundo, grados):
    b = pb[nombre]
    m = (rig.matrix_world @ b.bone.matrix_local).to_3x3().inverted()
    eje = (m @ Vector(eje_mundo)).normalized()
    from mathutils import Quaternion
    b.rotation_mode = "QUATERNION"
    b.rotation_quaternion = Quaternion(eje, math.radians(grados)) @ b.rotation_quaternion


girar("upperarm.l", (0, 1, 0), 40)
girar("upperarm.r", (0, 1, 0), -40)
girar("lowerarm.l", (1, 0, 0), 25)
girar("upperleg.l", (1, 0, 0), 25)
girar("lowerleg.l", (1, 0, 0), -30)
girar("upperleg.r", (1, 0, 0), -20)
bpy.ops.object.mode_set(mode="OBJECT")

sc = bpy.context.scene
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"
sc.display.shading.color_type = "TEXTURE"
sc.render.resolution_x = sc.render.resolution_y = 512
sc.render.image_settings.file_format = "JPEG"
sc.world = bpy.data.worlds.new("w")
sc.world.color = (0.82, 0.8, 0.76)
rig.show_in_front = True
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
sc.collection.objects.link(cam)
sc.camera = cam
cam.data.angle = math.radians(28)
for nombre, yaw in (("pose_frente", 0), ("pose_costado", 90)):
    a = math.radians(yaw)
    off = Vector((math.sin(a), -math.cos(a), 0.15)) * 2.4
    cam.location = Vector((0, 0, 0.5)) + off
    cam.rotation_euler = (-off).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = f"{prefijo}_{nombre}.jpg"
    bpy.ops.render.render(write_still=True)
