"""Último paso del pipeline 3D (proceso/47-pipeline-3d): tamaño del juego, GLB final y renders.

    blender --background --python tools/gen3d_final.py -- entrada.glb salida.glb '<medidas json>' render_prefijo

medidas (las calcula tools/gen3d_pipeline.py con data/reglas.json, edificios.json y
arte_edades.json, igual que WorldView._model_for y _stretch_k):
  {"modo": "alto", "alto": a}       personas y animales: alto total a (en casillas)
  {"modo": "huella", "lado": l, "alto_min": h, "estirar_max": k}
                                    edificios: el lado mayor de la planta mide l; si el alto
                                    queda por debajo de h, se estira solo en alto hasta h, con
                                    tope k (como el juego con los modelos generados)

Apoya en el suelo y centra en x/z. Con esqueleto, la escala va en el nodo raíz (pareja) y las
animaciones se conservan; sin esqueleto se aplica a la malla. Texturas en JPEG (calidad 85).
Renders Workbench de frente, costado, tres cuartos y cámara del RTS.
"""
import json
import math
import sys

import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
src, dst, med, prefijo = argv[0], argv[1], json.loads(argv[2]), argv[3]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
sc = bpy.context.scene
arm = [o for o in sc.objects if o.type == "ARMATURE"]
# El importador de glTF crea una «Icosphere» como forma de los huesos: no es parte del modelo.
formas = {b.custom_shape for a in arm for b in a.pose.bones if b.custom_shape}
for a in arm:
    for b in a.pose.bones:
        b.custom_shape = None
for o in formas:
    bpy.data.objects.remove(o)
for a in arm:
    a.data.pose_position = "REST"
bpy.context.view_layer.update()
mallas = [o for o in sc.objects if o.type == "MESH"]


def caja():
    dg = bpy.context.evaluated_depsgraph_get()
    pts = []
    for o in mallas:
        ev = o.evaluated_get(dg)
        m = ev.to_mesh()
        pts += [ev.matrix_world @ v.co for v in m.vertices]
        ev.to_mesh_clear()
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return mn, mx


mn, mx = caja()
w, d, h = mx.x - mn.x, mx.y - mn.y, mx.z - mn.z
if med["modo"] == "alto":
    k = med["alto"] / h
    kz = k
else:
    k = med["lado"] / max(w, d)
    kz = k
    if med.get("alto_min", 0) > 0 and h * k < med["alto_min"]:
        kz = k * min(med["alto_min"] / (h * k), med.get("estirar_max", 1.5))
raices = [o for o in sc.objects if o.parent is None]
centro = Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z))
for o in raices:
    o.location = Vector(((o.location.x - centro.x) * k, (o.location.y - centro.y) * k, (o.location.z - centro.z) * kz))
    o.scale = Vector((o.scale.x * k, o.scale.y * k, o.scale.z * kz))
bpy.context.view_layer.update()
if not arm:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
mn, mx = caja()
print(f"FINAL ancho={mx.x - mn.x:.3f} fondo={mx.y - mn.y:.3f} alto={mx.z - mn.z:.3f} k={k:.3f} kz={kz:.3f}")
for a in arm:
    a.data.pose_position = "POSE"
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", export_image_format="JPEG",
                          export_jpeg_quality=85, export_animations=True)

# Renders.
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"
sc.display.shading.color_type = "TEXTURE"
sc.display.shading.show_cavity = True
sc.display.shading.show_shadows = True
sc.render.resolution_x = sc.render.resolution_y = 512
sc.render.image_settings.file_format = "JPEG"
sc.render.image_settings.quality = 82
sc.world = bpy.data.worlds.new("w")
sc.world.color = (0.82, 0.8, 0.76)
sc.frame_set(0)
alto = mx.z - mn.z
radio = 0.5 * math.sqrt((mx.x - mn.x) ** 2 + (mx.y - mn.y) ** 2 + alto ** 2)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
sc.collection.objects.link(cam)
sc.camera = cam
c = Vector((0, 0, alto / 2))
for nombre, (yaw, pitch) in {"frente": (0, 8), "costado": (90, 8), "tres_cuartos": (45, 20), "rts": (45, 54)}.items():
    cam.data.angle = math.radians(30)
    dist = radio / math.sin(cam.data.angle / 2) * 1.05
    a, b = math.radians(yaw), math.radians(pitch)
    off = Vector((math.sin(a) * math.cos(b), -math.cos(a) * math.cos(b), math.sin(b))) * dist
    cam.location = c + off
    cam.rotation_euler = (-off).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = f"{prefijo}_{nombre}.jpg"
    bpy.ops.render.render(write_still=True)
