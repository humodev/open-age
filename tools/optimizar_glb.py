"""Achica un GLB generado para el repositorio y el RTS: diezma la malla y reduce la textura.

    blender --background --python tools/optimizar_glb.py -- entrada.glb salida.glb [triangulos] [textura_px]
"""
import sys
import bpy

argv = sys.argv[sys.argv.index("--") + 1:]
src, dst = argv[0], argv[1]
tris = int(argv[2]) if len(argv) > 2 else 6000
tex = int(argv[3]) if len(argv) > 3 else 1024

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
for ob in bpy.context.scene.objects:
    if ob.type != "MESH":
        continue
    # Diezmado en pasos: con millones de polígonos un solo paso se queda corto.
    for _ in range(6):
        n = sum(len(p.vertices) - 2 for p in ob.data.polygons)
        if n <= tris * 1.2:
            break
        mod = ob.modifiers.new("diezmar", "DECIMATE")
        mod.ratio = max(tris / n, 0.1)
        mod.use_collapse_triangulate = True
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.modifier_apply(modifier=mod.name)
    print("triangulos", ob.name, sum(len(p.vertices) - 2 for p in ob.data.polygons))
for img in bpy.data.images:
    if img.size[0] > tex:
        img.scale(tex, tex)
        img.pack()
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", export_image_format="JPEG", export_jpeg_quality=85)
print("optimizado", dst)
