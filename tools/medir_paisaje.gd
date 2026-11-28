extends SceneTree
## Alto y ancho del paisaje medidos en aldeanos (proceso/64): árboles por especie, arbusto,
## piedra, arcilla, yerbal y peñasco, con la escala de data/reglas.json → escala_visual y la
## variación de WorldView._make_mm (escala 0,82–1,26 y alto 0,90–1,12). El aldeano mide
## WorldView.FIGURE_H × unidad_pct.
##   godot --headless --path . -s tools/medir_paisaje.gd


func _init() -> void:
	var reglas: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/reglas.json"))
	var ev: Dictionary = reglas.get("escala_visual", {})
	var aldeano := WorldView.FIGURE_H * float(ev.get("unidad_pct", 100)) / 100.0
	var ta := float(ev.get("arbol_alto_pct", 100)) / 100.0
	var tw := float(ev.get("arbol_ancho_pct", 100)) / 100.0
	var ba := float(ev.get("arbusto_alto_pct", 100)) / 100.0
	var bw := float(ev.get("arbusto_ancho_pct", 100)) / 100.0
	var ra := float(ev.get("roca_alto_pct", 100)) / 100.0
	var rw := float(ev.get("roca_ancho_pct", 100)) / 100.0
	# Medias de la variación por instancia (WorldView._make_mm): s en 0,82–1,26; alto × 0,90–1,12.
	var s_med := 0.82 + 0.22
	var h_med := 0.9 + 0.11
	print("Aldeano: %.3f casillas" % aldeano)
	print("%-14s %8s %8s %10s %10s" % ["modelo", "alto", "ancho", "alto/ald", "rango/ald"])
	for i in Meshes.TREE_MODELS.size():
		var m := Meshes.tree_mesh(i)
		var b := m.get_aabb()
		var h := b.size.y * ta * s_med * h_med
		var w := maxf(b.size.x, b.size.z) * tw * s_med
		var lo := b.size.y * ta * 0.82 * 0.9
		var hi := b.size.y * ta * 1.26 * 1.12
		print("%-14s %8.2f %8.2f %10.1f %4.1f–%4.1f" % [Meshes.TREE_MODELS[i], h, w, h / aldeano, lo / aldeano, hi / aldeano])
	var bm := Meshes.bush_mesh().get_aabb()
	print("%-14s %8.2f %8.2f %10.1f" % ["arbusto", bm.size.y * ba * s_med * h_med, maxf(bm.size.x, bm.size.z) * bw * s_med, bm.size.y * ba * s_med * h_med / aldeano])
	for k in ["piedra", "riqueza", "yerbal"]:
		var rb := Meshes.rock_mesh(k).get_aabb()
		print("%-14s %8.2f %8.2f %10.1f" % [k, rb.size.y * ra, maxf(rb.size.x, rb.size.z) * rw, rb.size.y * ra / aldeano])
	var pb := Meshes.rock_mesh("penasco").get_aabb()
	print("%-14s %8.2f %8.2f %10.1f" % ["peñasco", pb.size.y * 1.4, maxf(pb.size.x, pb.size.z) * 1.4, pb.size.y * 1.4 / aldeano])
	quit()
