extends SceneTree
## Dibuja vistas cenitales de los mapas generados: altura, agua, vados, árboles y
## bases, para revisar variedad y equidad sin abrir el juego (docs/10).
## Uso: godot --headless --path . -s tools/vista_mapas.gd -- --terrenos=rio,llano --semillas=6 --salida=dir

func _init() -> void:
	var tipos: PackedStringArray = ["rio"]
	var semillas := 6
	var salida := "user://mapas"
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		match kv[0]:
			"terrenos":
				tipos = kv[1].split(",")
			"semillas":
				semillas = int(kv[1])
			"salida":
				salida = kv[1]
	DirAccess.make_dir_recursive_absolute(salida)
	for t in tipos:
		var k := 3
		var hoja := Image.create(semillas * (128 * k + 6), 128 * k, false, Image.FORMAT_RGB8)
		hoja.fill(Color(0.1, 0.1, 0.1))
		for i in semillas:
			var s := Sim.new(100 + i * 7, 2, null, {"terreno": t, "civs": ["guaranies", "mapuches"]})
			var img := _vista(s)
			img.resize(128 * k, 128 * k, Image.INTERPOLATE_NEAREST)
			hoja.blit_rect(img, Rect2i(0, 0, 128 * k, 128 * k), Vector2i(i * (128 * k + 6), 0))
			print("%s semilla %d: forma %s" % [t, 100 + i * 7, s.water_form])
		hoja.save_png("%s/%s.png" % [salida, t])
	quit()


func _vista(s: Sim) -> Image:
	var n := s.map.n
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	for y in n:
		for x in n:
			var h := s.map.h_at(x, y)
			var c := Color(0.42, 0.55, 0.3).lerp(Color(0.75, 0.68, 0.5), h / 3.0)
			var w := s.map.water[y * n + x]
			if s.map.rock[y * n + x] != 0:
				c = Color(0.35, 0.33, 0.32)
			elif w == 1:
				c = Color(0.16, 0.33, 0.55)
			elif w == 2:
				c = Color(0.45, 0.62, 0.75)
			img.set_pixel(x, y, c)
	for e in s.entities:
		if e.is_resource():
			var c := Color(0.12, 0.3, 0.12) if e.type == "arbol" else (Color(0.95, 0.8, 0.2) if e.type == "riqueza" else (Color(0.6, 0.6, 0.6) if e.type == "roca" else Color(0.8, 0.2, 0.3)))
			img.set_pixel(e.tx, e.ty, c)
		elif e.is_building():
			for yy in e.h:
				for xx in e.w:
					img.set_pixel(e.tx + xx, e.ty + yy, Color(1, 1, 1) if e.owner >= 0 else Color(0.8, 0.3, 0.9))
	return img
