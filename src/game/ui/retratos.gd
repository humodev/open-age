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


## Ruta del retrato que mejor encaja, o "". Pueblo y sexo vacíos en la fila valen para todos; la
## edad de la fila vale desde esa edad (la más alta que no pase `edad`).
static func ruta(civ: String, type: String, sx: String, edad: int) -> String:
	var mejor := ""
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
			mejor = str(f.get("ruta", ""))
	return mejor


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


## El retrato de una unidad del mapa (null si no hay).
static func de(sim: Sim, e: SimEntity) -> Texture2D:
	if e == null or e.is_resource() or e.owner < 0 or e.owner >= sim.players.size():
		return null
	var civ := str(sim.players[e.owner].get("civ", ""))
	return textura(ruta(civ, e.type, AldeanoAnimado.sexo(e.id, e.def), int(sim.players[e.owner].get("age", 1))))


## El retrato de un tipo (botón de la grilla, cola): el primero que encaje, sin sexo.
static func de_tipo(sim: Sim, owner: int, type: String) -> Texture2D:
	if owner < 0 or owner >= sim.players.size():
		return null
	return textura(ruta(str(sim.players[owner].get("civ", "")), type, "", int(sim.players[owner].get("age", 1))))


## La parte de la imagen que se ve («grande» o «chico»), en píxeles.
static func region(tex: Texture2D, tam: String) -> Rect2:
	var r: Array = cfg().get("recorte", {}).get(tam, [0, 0, 1, 1])
	var s := tex.get_size()
	return Rect2(float(r[0]) * s.x, float(r[1]) * s.y, float(r[2]) * s.x, float(r[3]) * s.y)


## Dibuja el retrato en `r` (recortado para que no se deforme).
static func dibujar(ci: CanvasItem, tex: Texture2D, r: Rect2, tam := "grande") -> void:
	ci.draw_texture_rect_region(tex, r, region(tex, tam))
