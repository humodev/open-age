extends SceneTree
## Galería de la grilla (proceso/28): dibuja en una sola imagen las grillas reales del aldeano
## (economía y militar), del centro, del cuartel y de sus investigaciones en varios pueblos, con un
## banco a medias para que convivan los estados (disponible, falta recurso, bloqueado por edad, en
## cola, tope), más una fila con un mismo comando en cada estado. Guarda la imagen a color y en
## escala de grises para revisar que los estados se distingan sin el color.
##   godot --path . -s tests/galeria_grilla.gd -- [--salida=screenshots/galeria] [--civs=a,b,c] [--edad=2]
## (necesita ventana: no corre con --headless).

const SALIDA := "screenshots/galeria"

var _lienzo: Control


func _init() -> void:
	Hud.load_fonts()
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var civs: PackedStringArray = String(args.get("civs", "guaranies,tawantinsuyu,ayutthaya")).split(",")
	var edad := int(args.get("edad", "2"))
	var salida := String(args.get("salida", SALIDA))
	root.size = Vector2i(1820, 1060)
	var bg := ColorRect.new()
	bg.color = Color(0.16, 0.17, 0.15)
	bg.size = Vector2(root.size)
	root.add_child(bg)
	_lienzo = Lienzo.new()
	_lienzo.size = Vector2(root.size)
	_lienzo.civs = civs
	_lienzo.edad = edad
	root.add_child(_lienzo)
	_capturar.call_deferred(salida)


func _capturar(salida: String) -> void:
	for i in 4:
		await process_frame
	var img := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(salida.get_base_dir())
	img.save_png(salida + ".png")
	var gris := img.duplicate() as Image
	for y in gris.get_height():
		for x in gris.get_width():
			var c := gris.get_pixel(x, y)
			var l := c.get_luminance()
			gris.set_pixel(x, y, Color(l, l, l))
	gris.save_png(salida + "_gris.png")
	print("GALERIA: %s.png y %s_gris.png" % [salida, salida])
	quit(0)


class Lienzo:
	extends Control
	var civs: PackedStringArray
	var edad := 2
	var _grillas: Array = [] # [título, comandos, banco, rp, colas]

	func _ready() -> void:
		for civ in civs:
			_armar(civ)

	func _armar(civ: String) -> void:
		var s := Sim.new(7, 2, null, {"civs": [civ, "mapuches" if civ != "mapuches" else "guaranies"]})
		var dd: SimData = s.dp(0)
		s.players[0]["age"] = edad
		# Banco a medias: alcanza para lo barato y no para lo caro.
		var banco := {"alimento": 120, "madera": 160, "piedra": 40, "riqueza": 60}
		for k in s.players[0]["res"]:
			if not banco.has(k):
				banco[k] = 30
		s.players[0]["res"] = banco
		var ctl := Controller.new()
		ctl.sim = s
		ctl.local = 0
		var rp: Dictionary = dd.mod("recurso_propio")
		var ald := s.spawn_unit("aldeano", 0, 30, 30)
		ctl.selection = [ald.id] as Array[int]
		if _grillas.is_empty():
			_grillas.append(["estados (mismo comando)", _estados(ctl, s), banco, rp])
			ctl.selection = [ald.id] as Array[int]
		for m in [Grilla.RAIZ, Grilla.ECONOMIA, Grilla.MILITAR]:
			ctl.submenu = m
			_grillas.append(["%s · aldeano · %s" % [civ, m], ctl.commands(), banco, rp])
		ctl.submenu = ""
		var centro_t := "centro"
		for t: String in dd.edificios:
			if (dd.edificios[t].get("produce", []) as Array).has("aldeano") and dd.edificios[t].has("tam"):
				centro_t = t
				break
		for t in [centro_t, "cuartel"]:
			if not dd.edificios.has(t):
				continue
			var b := s.spawn_building(t, 0, 6, 6, true)
			ctl.selection = [b.id] as Array[int]
			var cmds := ctl.commands()
			_grillas.append(["%s · %s" % [civ, dd.edificios[t]["nombre"]], cmds, banco, rp])
			if cmds.any(func(c: Dictionary) -> bool: return c.get("menu", "") == Controller.INVESTIGAR):
				ctl.submenu = Controller.INVESTIGAR
				_grillas.append(["%s · %s · investigaciones" % [civ, dd.edificios[t]["nombre"]], ctl.commands(), banco, rp])
				ctl.submenu = ""
		ctl.free()

	## Una casilla en cada estado: disponible, en la cola, falta recurso, bloqueado por edad, tope,
	## población llena e investigación en curso (y una investigación de cada edad, para la franja).
	func _estados(ctl: Controller, s: Sim) -> Array[Dictionary]:
		var b := s.spawn_building("cuartel", 0, 40, 40, true)
		ctl.selection = [b.id] as Array[int]
		var cmds := ctl.commands()
		var base: Dictionary = Controller.cmd_at(cmds, 0).duplicate()
		var out: Array[Dictionary] = []
		var variantes := [
			{"cost": {"alimento": 50}},
			{"cost": {"alimento": 50}, "en_cola": 3},
			{"cost": {"alimento": 50, "madera": 400}},
			{"locked": "Requiere edad III", "edad": 3},
			{"locked": "Máximo en esta edad: 2", "tope": true},
			{"cost": {"alimento": 50}, "aviso": "Población llena"},
		]
		for i in variantes.size():
			var c := base.duplicate()
			c.merge(variantes[i], true)
			c["slot"] = i
			out.append(c)
		var techs: Dictionary = s.dp(0).tecnologias
		var i := 6
		for t in ["hachas", "canteria", "ataque_cc_2", "elite_choque", "oficio_motor"]:
			if techs.has(t):
				out.append({"slot": i, "id": t, "icon": Iconos.de_tecnologia(t, techs[t]), "kind": "research", "name": techs[t]["nombre"], "cost": {"alimento": 50}, "locked": "", "edad": int(techs[t].get("edad_min", 1))})
				i += 1
		out.append({"slot": i, "id": "x", "icon": Iconos.de_tecnologia("riego", techs["riego"]), "kind": "research", "name": "Riego", "cost": {}, "locked": "En investigación", "en_curso": true, "edad": 2})
		return out

	func _draw() -> void:
		var x := 16.0
		var y := 30.0
		var w := 4 * (Hud.SLOT + Hud.GAP) + Hud.GAP
		var h := 3 * (Hud.SLOT + Hud.GAP) + Hud.GAP
		for g: Array in _grillas:
			if x + w > size.x - 10:
				x = 16.0
				y += h + 36
			draw_string(Hud.font_b, Vector2(x, y - 8), g[0], HORIZONTAL_ALIGNMENT_LEFT, w + 40, 13, Palette.UI_TEXT)
			draw_style_box(Hud.panel_box(), Rect2(x, y, w, h))
			for i in 12:
				var r := Rect2(x + Hud.GAP + (i % 4) * (Hud.SLOT + Hud.GAP), y + Hud.GAP + (i / 4) * (Hud.SLOT + Hud.GAP), Hud.SLOT, Hud.SLOT)
				var c := Controller.cmd_at(g[1], i)
				if c.is_empty():
					var sb := StyleBoxFlat.new()
					sb.set_corner_radius_all(6)
					sb.bg_color = Color(1, 1, 1, 0.025)
					draw_style_box(sb, r)
					continue
				EstadoCasilla.dibujar(self, r, c, g[2], false, false, Controller.etiqueta(i), g[3])
			x += w + 26
