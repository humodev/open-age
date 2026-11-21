"""Primer plano de la cara de un GLB de persona (proceso/50-arreglos-arte).

    blender --background --python tools/gen3d_cara.py -- <modelo.glb> <salida.jpg> [px]

Encuadra el 16 % de arriba del modelo (la cabeza) de frente y de tres cuartos, con la misma
luz que los renders de tools/gen3d_final.py (Workbench, STUDIO, cavidad), y deja las dos vistas
lado a lado en un JPEG. Sirve para comparar la piel y los rasgos antes y después.
"""
import math
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
src, dst = args[0], args[1]
px = int(args[2]) if len(args) > 2 else 320

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
sc = bpy.context.scene
mallas = [o for o in sc.objects if o.type == "MESH"]
for o in sc.objects:
    if o.type == "MESH" and o.name.lower().startswith("icosphere"):
        bpy.data.objects.remove(o)
mallas = [o for o in sc.objects if o.type == "MESH"]
dg = bpy.context.evaluated_depsgraph_get()
pts = []
for o in mallas:
    ev = o.evaluated_get(dg)
    me = ev.to_mesh()
    pts += [ev.matrix_world @ v.co for v in me.vertices]
    ev.to_mesh_clear()
zmax = max(p.z for p in pts)
zmin = min(p.z for p in pts)
alto = zmax - zmin
cabeza = [p for p in pts if p.z > zmax - 0.16 * alto]
cx = sum(p.x for p in cabeza) / len(cabeza)
cy = sum(p.y for p in cabeza) / len(cabeza)
c = Vector((cx, cy, zmax - 0.075 * alto))

sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"
sc.display.shading.color_type = "TEXTURE"
# Sin cavidad: marca las aristas con líneas claras que el juego no dibuja.
sc.display.shading.show_cavity = False
sc.display.shading.show_shadows = True
sc.render.resolution_x = sc.render.resolution_y = px
sc.render.image_settings.file_format = "JPEG"
sc.render.image_settings.quality = 88
sc.world = bpy.data.worlds.new("w")
sc.world.color = (0.82, 0.8, 0.76)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
sc.collection.objects.link(cam)
sc.camera = cam
cam.data.type = "ORTHO"
cam.data.ortho_scale = 0.2 * alto
partes = []
for i, yaw in enumerate((0, 35)):
    a = math.radians(yaw)
    off = Vector((math.sin(a), -math.cos(a), 0.08)) * 3 * alto
    cam.location = c + off
    cam.rotation_euler = (-off).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = dst + f".{i}.jpg"
    bpy.ops.render.render(write_still=True)
    partes.append(sc.render.filepath)

img = bpy.data.images.new("lado", 2 * px, px)
buf = [0.0] * (2 * px * px * 4)
for i, f in enumerate(partes):
    im = bpy.data.images.load(f)
    p = list(im.pixels)
    for y in range(px):
        fila = p[y * px * 4:(y + 1) * px * 4]
        ini = (y * 2 * px + i * px) * 4
        buf[ini:ini + px * 4] = fila
img.pixels = buf
img.filepath_raw = dst
img.file_format = "JPEG"
img.save()
import os
for f in partes:
    os.remove(f)
print("CARA", dst)
