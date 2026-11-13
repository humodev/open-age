"""Achica un GLB generado para el repositorio y el RTS: diezma la malla y reduce la textura.

    blender --background --python tools/optimizar_glb.py -- entrada.glb salida.glb [triangulos] [textura_px] [solo_color]

Con `solo_color` se descartan los mapas normal y de metal/rugosidad (el juego usa materiales mates).
"""
import sys
import bmesh
import bpy

argv = sys.argv[sys.argv.index("--") + 1:]
src, dst = argv[0], argv[1]
tris = int(argv[2]) if len(argv) > 2 else 6000
tex = int(argv[3]) if len(argv) > 3 else 1024
solo_color = "solo_color" in argv[4:]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
for ob in bpy.context.scene.objects:
    if ob.type != "MESH":
        continue
    # Meshy entrega los vértices partidos en cada costura de UV: sin soldarlos, el diezmado
    # no puede colapsar a través de ellas y a pocos triángulos la malla queda en astillas.
    size = max(ob.dimensions) or 1.0

    def soldar(dist):
        bm = bmesh.new()
        bm.from_mesh(ob.data)
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=size * dist)
        bm.to_mesh(ob.data)
        bm.free()

    dist = 1e-4
    soldar(dist)
    # Diezmado en pasos: con millones de polígonos un solo paso se queda corto. Si se
    # estanca (hojas sueltas que no colapsan), se suelda con más distancia y se sigue.
    last = None
    for _ in range(40):
        n = sum(len(p.vertices) - 2 for p in ob.data.polygons)
        if n <= tris * 1.2:
            break
        if last is not None and n > last * 0.95:
            if dist >= 1e-3:
                break
            dist *= 3
            soldar(dist)
        last = n
        mod = ob.modifiers.new("diezmar", "DECIMATE")
        mod.ratio = max(tris / n, 0.5)
        mod.use_collapse_triangulate = True
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.modifier_apply(modifier=mod.name)
    print("triangulos", ob.name, sum(len(p.vertices) - 2 for p in ob.data.polygons))
if solo_color:
    for mat in bpy.data.materials:
        if not mat.use_nodes:
            continue
        for node in list(mat.node_tree.nodes):
            if node.type == "BSDF_PRINCIPLED":
                for name in ("Normal", "Metallic", "Roughness"):
                    for link in list(node.inputs[name].links):
                        mat.node_tree.links.remove(link)
                node.inputs["Metallic"].default_value = 0.0
                node.inputs["Roughness"].default_value = 0.95
        for node in list(mat.node_tree.nodes):
            if node.type in ("TEX_IMAGE", "NORMAL_MAP", "SEPARATE_COLOR") and not any(o.links for o in node.outputs):
                mat.node_tree.nodes.remove(node)
    for img in list(bpy.data.images):
        if img.users == 0:
            bpy.data.images.remove(img)
for img in bpy.data.images:
    if img.size[0] > tex:
        img.scale(tex, tex)
        img.pack()
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", export_image_format="JPEG", export_jpeg_quality=85)
print("optimizado", dst)
