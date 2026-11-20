class_name Retratos
extends RefCounted
## Retratos pintados de la interfaz (data/retratos.json; proceso/27-animaciones/04): por pueblo,
## unidad, sexo y edad. El panel de la selección y la ficha los muestran cuando hay uno; si no,
## lo de antes (el glifo o el retrato pre-renderizado). El sexo del aldeano es el de su figura
## (AldeanoAnimado.sexo, por id) y la edad, la actual de su pueblo. Solo imagen.

static var _cfg := {}
static var _tex := {}


static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/retratos.json"))
		_cfg = raw if raw is Dictionary else {"retratos": []}
	return _cfg


## Modo del fondo: el de Opciones o, si no eligió, el de data (fondo.modo).
static func modo() -> String:
	return Opciones.fondo_retrato if Opciones.fondo_retrato != "" else str(cfg().get("fondo", {}).get("modo", "equipo"))


## La fila que mejor encaja, o {}. Pueblo y sexo vacíos en la fila valen para todos; la edad de
## la fila vale desde esa edad (la más alta que no pase `edad`).
static func fila(civ: String, type: String, sx: String, edad: int) -> Dictionary:
	var mejor := {}
	var mejor_p := -1
	for f: Dictionary in cfg().get("retratos", []):
		if str(f.get("unidad", "")) != type:
			continue
		var fc := str(f.get("pueblo", ""))
		var fs := str(f.get("sexo", ""))
		var fe := int(f.get("edad", 0))
		if (fc != "" and fc != civ) or (fs != "" and sx != "" and fs != sx) or fe > edad:
			continue
		var p := (100 if fc != "" else 0) + (50 if fs == sx and fs != "" else 0) + fe
		if p > mejor_p:
			mejor_p = p
			mejor = f
	return mejor


## Lo que hace falta para dibujar el retrato: {tex, fondo (Color; alfa 0 = la imagen trae el
## suyo)}, o {} si no hay. En los modos equipo y pueblo, la imagen recortada sobre el degradé;
## en original, la que tiene fondo. Si la fila trae una sola, se usa esa.
static func _armar(sim: Sim, owner: int, f: Dictionary) -> Dictionary:
	if f.is_empty():
		return {}
	var m := modo()
	var con_fondo := str(f.get("ruta", ""))
	var alfa := str(f.get("ruta_alfa", ""))
	var path := con_fondo if (m == "original" and con_fondo != "") or alfa == "" else alfa
	var tex := textura(path)
	if tex == null:
		return {}
	var fondo := Color(0, 0, 0, 0)
	if path == alfa:
		var civ := str(sim.players[owner].get("civ", ""))
		var fd: Dictionary = cfg().get("fondo", {})
		if m == "equipo":
			fondo = Palette.team(owner)
		elif (fd.get("por_pueblo", {}) as Dictionary).has(civ):
			fondo = Color(str(fd["por_pueblo"][civ]))
		else:
			fondo = Color(str(sim.dp(owner).civ.get("estilo", {}).get("arcilla", "#8a6a44"))).darkened(0.35)
	return {"tex": tex, "fondo": fondo}


static func textura(path: String) -> Texture2D:
	if path == "":
		return null
	if _tex.has(path):
		return _tex[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	elif FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null:
			tex = ImageTexture.create_from_image(img)
	_tex[path] = tex
	return tex


## El retrato de una unidad del mapa ({} si no hay).
static func de(sim: Sim, e: SimEntity) -> Dictionary:
	if e == null or e.is_resource() or e.owner < 0 or e.owner >= sim.players.size():
		return {}
	var civ := str(sim.players[e.owner].get("civ", ""))
	return _armar(sim, e.owner, fila(civ, e.type, AldeanoAnimado.sexo(e.id, e.def), int(sim.players[e.owner].get("age", 1))))


## El retrato de un tipo (botón de la grilla, cola): el primero que encaje, sin sexo.
static func de_tipo(sim: Sim, owner: int, type: String) -> Dictionary:
	if owner < 0 or owner >= sim.players.size():
		return {}
	return _armar(sim, owner, fila(str(sim.players[owner].get("civ", "")), type, "", int(sim.players[owner].get("age", 1))))


## La parte de la imagen que se ve («grande» o «chico»), en píxeles.
static func region(tex: Texture2D, tam: String) -> Rect2:
	var r: Array = cfg().get("recorte", {}).get(tam, [0, 0, 1, 1])
	var s := tex.get_size()
	return Rect2(float(r[0]) * s.x, float(r[1]) * s.y, float(r[2]) * s.x, float(r[3]) * s.y)


## Dibuja el retrato en `r` (recortado para que no se deforme), sobre su fondo: un degradé del
## color de fondo, más claro arriba y oscuro abajo, con viñeta (data/retratos.json → fondo).
static func dibujar(ci: CanvasItem, ret: Dictionary, r: Rect2, tam := "grande") -> void:
	var tex: Texture2D = ret["tex"]
	var c: Color = ret["fondo"]
	if c.a > 0.0:
		var fd: Dictionary = cfg().get("fondo", {})
		var top := c.lightened(float(fd.get("claro_pct", 8)) / 100.0)
		var bot := c.darkened(float(fd.get("oscuro_pct", 62)) / 100.0)
		var a := r.position
		var b := r.end
		ci.draw_polygon(PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)]), PackedColorArray([top, top, bot, bot]))
		var v := Color(0, 0, 0, float(fd.get("vineta_pct", 55)) / 100.0)
		var t := Color(0, 0, 0, 0)
		var ri := r.grow(-minf(r.size.x, r.size.y) * float(fd.get("vineta_ancho_pct", 24)) / 100.0)
		var o := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
		var n := [ri.position, Vector2(ri.end.x, ri.position.y), ri.end, Vector2(ri.position.x, ri.end.y)]
		for k in 4:
			var k2 := (k + 1) % 4
			ci.draw_polygon(PackedVector2Array([o[k], o[k2], n[k2], n[k]]), PackedColorArray([v, v, t, t]))
	ci.draw_texture_rect_region(tex, r, region(tex, tam))
