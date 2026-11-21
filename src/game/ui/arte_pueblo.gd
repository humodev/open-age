class_name ArtePueblo
extends RefCounted
## Arte pintado de la interfaz, por pueblo (data/arte_pueblos.json; proceso/48-arte-en-la-interfaz).
## Un arte por unidad (el mismo en todas las edades) y un ícono por edificio, hito, maravilla y
## mejora. Si el pueblo no tiene arte para un id, todo devuelve {} y la interfaz sigue con el glifo
## o el retrato de data/retratos.json. La zona del equipo (la ropa roja de las unidades) viene en
## una capa gris aparte que se dibuja encima teñida con el color del jugador: la misma máscara de
## tools/recolorear.py, sin recalcular píxeles en el juego. Solo interfaz.

const RUTA := "res://data/arte_pueblos.json"

static var _cfg := {}


static func cfg() -> Dictionary:
	if _cfg.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA)) if FileAccess.file_exists(RUTA) else null
		_cfg = raw if raw is Dictionary else {"pueblos": {}}
	return _cfg


static func _pueblo(civ: String) -> Dictionary:
	return (cfg().get("pueblos", {}) as Dictionary).get(civ, {})


## La pieza de `id` (unidad, edificio o mejora) para `civ`, o "". `sx` elige entre {m, f}; sin
## sexo, la primera.
static func pieza(civ: String, id: String, sx := "") -> String:
	var pb := _pueblo(civ)
	if pb.is_empty():
		return ""
	for grupo in ["unidades", "edificios", "tecnologias"]:
		var v: Variant = (pb.get(grupo, {}) as Dictionary).get(id, null)
		if v is String:
			return v
		if v is Dictionary:
			var d: Dictionary = v
			if d.is_empty():
				return ""
			return str(d.get(sx, d.values()[0]))
	return ""


static func es_unidad(civ: String, id: String) -> bool:
	return (_pueblo(civ).get("unidades", {}) as Dictionary).has(id)


## {tex, equipo (o null)} del retrato (chico = el ícono de cabeza y torso) o {}.
static func arte(civ: String, id: String, sx := "", chico := false) -> Dictionary:
	var pz := pieza(civ, id, sx)
	if pz == "":
		return {}
	var base := str(_pueblo(civ).get("carpeta", "")) + pz + ("_icono" if chico else "")
	var tex := Retratos.textura(base + ".webp")
	if tex == null:
		return {}
	var eq := Retratos.textura(base + "_equipo.webp") if ResourceLoader.exists(base + "_equipo.webp") or FileAccess.file_exists(base + "_equipo.webp") else null
	return {"tex": tex, "equipo": eq, "pieza": pz}


## El arte de una casilla de la grilla, o {} si no hay o no se lee chico (sin_casilla).
static func casilla(civ: String, id: String) -> Dictionary:
	var pz := pieza(civ, id)
	if pz == "" or (_pueblo(civ).get("sin_casilla", []) as Array).has(pz):
		return {}
	return arte(civ, id, "", true)


## Dibuja `a` (de arte()) cuadrado y centrado en `r`, con la zona del equipo en `team`. `mod`
## atenúa todo (casilla bloqueada o sin recurso).
static func dibujar(ci: CanvasItem, a: Dictionary, r: Rect2, team: Color, mod := Color(1, 1, 1, 1)) -> void:
	var s := minf(r.size.x, r.size.y)
	var q := Rect2(r.get_center() - Vector2(s, s) / 2.0, Vector2(s, s))
	ci.draw_texture_rect(a["tex"], q, false, mod)
	var eq: Texture2D = a.get("equipo")
	if eq != null:
		ci.draw_texture_rect(eq, q, false, Color(team.r * mod.r, team.g * mod.g, team.b * mod.b, mod.a))
