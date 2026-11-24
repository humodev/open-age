class_name ArteGuerraUI
extends Control
## Arte de la guerra (C-38, proceso/52): cinco misiones cortas de una sola idea, como el Art of
## War de AoE4. Las misiones están en data/campanas/arte_guerra.json y las corre el motor de
## escenarios; acá van el menú, las medallas y las marcas del jugador.
##
## Medallas por tiempo de juego hasta ganar (misión → medallas: oro, plata, bronce, en segundos).
## Ganar después del tiempo del bronce cuenta como completada, sin medalla. Las marcas (mejor
## tiempo y mejor medalla de cada misión) se guardan en user://arte_guerra.json: son del jugador
## de esta instalación. Todas las misiones están abiertas desde el principio.

signal start_mission(index: int)
signal back

const CLAVE := "arte_guerra"
const RUTA := "res://data/campanas/arte_guerra.json"
const SAVE := "user://arte_guerra.json"
const ORDEN := ["oro", "plata", "bronce"]
const NOMBRES := {"oro": "Oro", "plata": "Plata", "bronce": "Bronce", "": "Completada"}
const COLORES := {"oro": Color(0.93, 0.76, 0.27), "plata": Color(0.78, 0.8, 0.84), "bronce": Color(0.78, 0.5, 0.3)}

var _camp: Dictionary = {}
var _detail: VBoxContainer


static func campana() -> Dictionary:
	if not FileAccess.file_exists(RUTA):
		return {}
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RUTA))
	return c


## La medalla de ganar la misión en `seg` segundos de juego ("oro", "plata", "bronce" o "").
static func medalla(m: Dictionary, seg: int) -> String:
	var md: Dictionary = m.get("medallas", {})
	for k in ORDEN:
		if md.has(k) and seg <= int(md[k]):
			return k
	return ""


static func marcas() -> Dictionary:
	if not FileAccess.file_exists(SAVE):
		return {}
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	return v if v is Dictionary else {}


## Guarda la victoria si mejora la marca. Devuelve {"medalla", "nueva" (mejoró), "antes" (segundos o -1)}.
static func registrar(m: Dictionary, seg: int) -> Dictionary:
	var all := marcas()
	var id: String = m["id"]
	var prev: Dictionary = all.get(id, {})
	var med := medalla(m, seg)
	var antes := int(prev.get("segundos", -1))
	var nueva := antes < 0 or seg < antes
	if nueva:
		all[id] = {"segundos": seg, "medalla": med}
		var f := FileAccess.open(SAVE, FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(all, "  "))
	return {"medalla": med, "nueva": nueva, "antes": antes}


static func fmt(seg: int) -> String:
	return "%d:%02d" % [seg / 60, seg % 60]


## "Oro 5:00 · Plata 6:30 · Bronce 9:00".
static func umbrales(m: Dictionary) -> String:
	var md: Dictionary = m.get("medallas", {})
	var parts: Array[String] = []
	for k in ORDEN:
		if md.has(k):
			parts.append("%s %s" % [NOMBRES[k], fmt(int(md[k]))])
	return " · ".join(parts)


## Texto del final de la misión, para el epílogo.
static func texto_fin(m: Dictionary, seg: int, reg: Dictionary) -> String:
	var med: String = reg["medalla"]
	var out := ("Medalla de %s: %s." % [NOMBRES[med].to_lower(), fmt(seg)]) if med != "" else ("Completada en %s, sin medalla." % fmt(seg))
	if int(reg["antes"]) >= 0:
		out += " Tu mejor marca era %s%s." % [fmt(int(reg["antes"])), " (¡la mejoraste!)" if reg["nueva"] else ""]
	return out + "\n" + umbrales(m)


func _ready() -> void:
	Hud.load_fonts()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.04, 0.05, 0.95)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_camp = campana()
	Textos.limpiar_todo(_camp)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 90
	root.offset_top = 60
	root.offset_right = -90
	root.offset_bottom = -40
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	root.add_child(_label(_camp.get("titulo", "Arte de la guerra"), 44, Palette.UI_TEXT, true))
	root.add_child(_label(_camp.get("resumen", ""), 17, Palette.UI_ACCENT))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 10)
	scroll.add_child(_detail)
	var mk := marcas()
	var misiones: Array = _camp.get("misiones", [])
	for i in misiones.size():
		_detail.add_child(_card(i, misiones[i], mk.get(misiones[i]["id"], {})))
	var volver := CampaignUI._button("Volver", func() -> void: back.emit(), 260)
	volver.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	root.add_child(volver)


func _card(i: int, m: Dictionary, marca: Dictionary) -> Control:
	var card := PanelContainer.new()
	var sb := Hud.panel_box(8)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	card.add_child(row)
	var med := Medalla.new()
	med.custom_minimum_size = Vector2(54, 54)
	med.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	med.cual = str(marca.get("medalla", "")) if not marca.is_empty() else "-"
	row.add_child(med)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 2)
	row.add_child(vb)
	vb.add_child(_label("%d. %s" % [i + 1, m["titulo"]], 21, Palette.UI_TEXT, true))
	vb.add_child(_label(str(m.get("lugar", "")), 15, Palette.UI_ACCENT))
	var mt := "Sin jugar." if marca.is_empty() else "Mejor: %s · %s" % [fmt(int(marca["segundos"])), NOMBRES[str(marca.get("medalla", ""))]]
	vb.add_child(_label("%s   ·   %s" % [mt, umbrales(m)], 14, Palette.UI_DIM))
	var b := CampaignUI._button("Jugar" if marca.is_empty() else "Mejorar", func() -> void: start_mission.emit(i), 170)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(b)
	return card


func _label(t: String, sz: int, col: Color, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", Hud.font_b if bold else Hud.font)
	l.add_theme_font_size_override("font_size", Hud.ts(sz))
	l.add_theme_color_override("font_color", col)
	return l


## Medalla dibujada: un disco del color del metal con cinta, o un círculo vacío si no hay.
class Medalla:
	extends Control
	var cual := "-"

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0 - 3.0
		if not COLORES.has(cual):
			draw_arc(c, r, 0, TAU, 40, Color(Palette.UI_DIM, 0.5), 2.0, true)
			if cual == "":
				draw_string(Hud.font_b, c + Vector2(-7, 8), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Palette.UI_GOOD)
			return
		var col: Color = COLORES[cual]
		draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.55, -r * 1.05), c + Vector2(-r * 0.1, -r * 1.05), c + Vector2(r * 0.25, -r * 0.2), c + Vector2(-r * 0.2, -r * 0.2)]), Color(0.55, 0.12, 0.1))
		draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.55, -r * 1.05), c + Vector2(r * 0.1, -r * 1.05), c + Vector2(-r * 0.25, -r * 0.2), c + Vector2(r * 0.2, -r * 0.2)]), Color(0.7, 0.18, 0.14))
		draw_circle(c + Vector2(0, r * 0.18), r * 0.78, col.darkened(0.35))
		draw_circle(c + Vector2(0, r * 0.18), r * 0.66, col)
		draw_arc(c + Vector2(0, r * 0.18), r * 0.48, 0, TAU, 32, col.lightened(0.35), 1.5, true)
