extends SceneTree
## Exporta a GLB la silueta procedural de cada especie (Animales, data/arte_animales.json) para
## riggearla en Blender con tools/gen3d_rig_cuadrupedo.py (proceso/63-montados-y-animales): así
## los animales del juego se animan con la misma figura que ya tenían, sin GPU ni créditos.
##
##   godot --headless --path . -s tools/exportar_animales.gd -- --salida=/ruta/carpeta [--solo=llama,cebu]
##
## Deja <especie>.glb (frente en +z, como en el juego) e imprime el alto de cada malla.

func _initialize() -> void:
	var salida := "user://animales_proc"
	var solo: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--salida="):
			salida = a.substr(9)
		elif a.begins_with("--solo="):
			solo = a.substr(7).split(",")
	DirAccess.make_dir_recursive_absolute(salida)
	var esp: Dictionary = Animales.data().get("especies", {})
	for sp: String in esp:
		if not solo.is_empty() and not sp in solo:
			continue
		var raiz := Node3D.new()
		raiz.name = sp
		var mi := MeshInstance3D.new()
		mi.name = "animal"
		mi.mesh = Animales.mesh(sp)
		raiz.add_child(mi)
		var doc := GLTFDocument.new()
		var st := GLTFState.new()
		var err := doc.append_from_scene(raiz, st)
		if err == OK:
			err = doc.write_to_filesystem(st, salida.path_join(sp + ".glb"))
		print("ANIMAL %s forma=%s alto=%.3f err=%d" % [sp, esp[sp].get("forma", ""), mi.mesh.get_aabb().size.y, err])
		raiz.free()
	quit()
