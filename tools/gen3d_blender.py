"""Limpia, reduce y fotografía un GLB generado (proceso/43-3d-local).

    blender --background --python tools/gen3d_blender.py -- entrada.glb salida.glb caras render_prefijo [tipo]

- Suelda vértices, borra piezas sueltas chicas y diezma hasta `caras` triángulos.
- Apoya el modelo en el suelo (y = 0), lo centra en x/z y lo deja de 1 de alto (el juego lo
  escala solo: WorldView._model_for).
- tipo: persona | edificio | animal. Los edificios generados desde un ícono isométrico salen
  girados; no se corrigen acá.
- Renders 512×512 con Workbench (frente, costado, tres cuartos y la cámara del RTS:
  pitch 54°, yaw 45°, fov 30, como src/game/rts_camera.gd), en JPG.
Corre dentro del scope con tope de memoria, como todo lo pesado.
"""
import math
import sys

import bmesh
import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
src, dst, caras, prefijo = argv[0], argv[1], int(argv[2]), argv[3]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
mallas = [o for o in bpy.context.scene.objects if o.type == "MESH"]
bpy.ops.object.select_all(action="DESELECT")
for o in mallas:
    o.select_set(True)
bpy.context.view_layer.objects.active = mallas[0]
if len(mallas) > 1:
    bpy.ops.object.join()
ob = bpy.context.view_layer.objects.active
bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
for o in list(bpy.context.scene.objects):
    if o != ob:
        bpy.data.objects.remove(o)

antes = len(ob.data.polygons)
size = max(ob.dimensions) or 1.0
bm = bmesh.new()
bm.from_mesh(ob.data)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=size * 1e-4)
# Piezas sueltas de menos del 0,5 % de las caras: ruido del marching cubes.
islas, vistos = [], set()
for f in bm.faces:
    if f.index in vistos:
        continue
    pila, isla = [f], []
    vistos.add(f.index)
    while pila:
        g = pila.pop()
        isla.append(g)
        for e in g.edges:
            for h in e.link_faces:
                if h.index not in vistos:
                    vistos.add(h.index)
                    pila.append(h)
    islas.append(isla)
total = len(bm.faces)
for isla in islas:
    if len(isla) < total * 0.005:
        bmesh.ops.delete(bm, geom=isla, context="FACES")
bmesh.ops.triangulate(bm, faces=bm.faces[:])
bm.to_mesh(ob.data)
bm.free()

tris = len(ob.data.polygons)
if tris > caras:
    mod = ob.modifiers.new("diezmar", "DECIMATE")
    mod.ratio = caras / tris
    mod.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier=mod.name)
bpy.ops.object.shade_smooth_by_angle(angle=math.radians(40)) if hasattr(bpy.ops.object, "shade_smooth_by_angle") else None

# Al suelo, centrado y de 1 de alto.
pts = [ob.matrix_world @ v.co for v in ob.data.vertices]
mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
alto = (mx.z - mn.z) or 1.0
for v in ob.data.vertices:
    p = ob.matrix_world @ v.co
    v.co = Vector(((p.x - (mn.x + mx.x) / 2) / alto, (p.y - (mn.y + mx.y) / 2) / alto, (p.z - mn.z) / alto))
ob.matrix_world.identity()
if not ob.data.materials:
    m = bpy.data.materials.new("arcilla")
    m.diffuse_color = (0.78, 0.72, 0.64, 1)
    ob.data.materials.append(m)
despues = len(ob.data.polygons)
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", use_selection=False,
                          export_image_format="JPEG", export_jpeg_quality=85)
print(f"CARAS antes={antes} despues={despues}")

# Renders.
sc = bpy.context.scene
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"
sc.display.shading.color_type = "TEXTURE" if any(n.type == "TEX_IMAGE" for m in ob.data.materials if m and m.use_nodes for n in m.node_tree.nodes) else "MATERIAL"
sc.display.shading.show_cavity = True
sc.display.shading.show_shadows = True
sc.render.resolution_x = sc.render.resolution_y = 512
sc.render.image_settings.file_format = "JPEG"
sc.render.image_settings.quality = 82
sc.world = bpy.data.worlds.new("w")
sc.world.color = (0.82, 0.8, 0.76)
sc.render.film_transparent = False
w = (mx.x - mn.x) / alto
d = (mx.y - mn.y) / alto
radio = 0.5 * math.sqrt(w * w + d * d + 1)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
sc.collection.objects.link(cam)
sc.camera = cam
centro = Vector((0, 0, 0.5))
# glTF +z (frente del modelo) es -y en Blender.
vistas = {"frente": (0, 8), "costado": (90, 8), "tres_cuartos": (45, 20), "rts": (45, 54)}
for nombre, (yaw, pitch) in vistas.items():
    cam.data.lens_unit = "FOV"
    cam.data.angle = math.radians(30 if nombre == "rts" else 28)
    dist = radio / math.sin(cam.data.angle / 2) * 1.05
    a, b = math.radians(yaw), math.radians(pitch)
    off = Vector((math.sin(a) * math.cos(b), -math.cos(a) * math.cos(b), math.sin(b))) * dist
    cam.location = centro + off
    cam.rotation_euler = (-off).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = f"{prefijo}_{nombre}.jpg"
    bpy.ops.render.render(write_still=True)
