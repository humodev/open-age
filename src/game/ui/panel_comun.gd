extends RefCounted
## Piezas de dibujo comunes a los paneles de información (docs/07, "Interfaz").
## Mismas fuentes que el HUD (Hud.font, Hud.font_b) y la paleta de Palette.

const ORIGIN_NAMES := {
	"casa": "Cerca de casa",
	"disputado": "Lo disputado",
	"granja": "Granjas",
	"recoleccion": "Recolección",
	"sitios": "Sitios sagrados",
	"saqueo": "Saqueo y botín",
	"mercado": "Mercado",
	"renta": "Rentas de edificios",
	"propio": "Motor propio",
}
const ORIGIN_ORDER: Array[String] = ["casa", "granja", "recoleccion", "disputado", "sitios", "saqueo", "mercado", "renta", "propio"]
const EJE_NAMES := {"economia": "Economía", "militar": "Militar"}
const FN_NAMES := {"civil": "civil", "choque": "choque", "distancia": "distancia", "linea": "línea", "explorador": "exploración", "asedio": "asedio"}


static func text(ci: CanvasItem, pos: Vector2, s: String, size: int = 14, col: Color = Palette.UI_TEXT, bold := false, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	ci.draw_string(Hud.font_b if bold else Hud.font, pos, s, align, width, size, col)


static func title(ci: CanvasItem, pos: Vector2, s: String) -> void:
	ci.draw_string(Hud.font_b, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Palette.UI_ACCENT)


static func bar(ci: CanvasItem, r: Rect2, k: float, col: Color) -> void:
	ci.draw_rect(r, Color(0, 0, 0, 0.45))
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(k, 0.0, 1.0), r.size.y)), col)


static func sep(ci: CanvasItem, y: float, w: float) -> void:
	ci.draw_line(Vector2(14, y), Vector2(w - 14, y), Palette.UI_LINE, 1)


static func multiline(ci: CanvasItem, pos: Vector2, s: String, width: float, size: int = 13, col: Color = Palette.UI_DIM) -> float:
	ci.draw_multiline_string(Hud.font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, width, size, -1, col)
	return Hud.font.get_multiline_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, width, size).y


static func text_h(s: String, width: float, size: int = 13) -> float:
	return Hud.font.get_multiline_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, width, size).y


## Color e ícono de un recurso, también los propios (mit'a, fama, kulliñ).
static func res_color(sim: Sim, pid: int, k: String) -> Color:
	if Palette.RES.has(k):
		return Palette.RES[k]
	var rp: Dictionary = sim.dp(pid).mod("recurso_propio")
	if rp.get("clave", "") == k:
		return Color(rp.get("color", "#cccccc"))
	return Palette.UI_DIM


static func res_icon(sim: Sim, pid: int, k: String) -> String:
	if Palette.RES.has(k):
		return k
	var rp: Dictionary = sim.dp(pid).mod("recurso_propio")
	return rp.get("icono", "riqueza") if rp.get("clave", "") == k else "riqueza"


static func res_name(sim: Sim, pid: int, k: String) -> String:
	if Palette.RES_NAMES.has(k):
		return Palette.RES_NAMES[k]
	var rp: Dictionary = sim.dp(pid).mod("recurso_propio")
	return rp.get("nombre", k) if rp.get("clave", "") == k else k


## Recursos que muestra la economía del jugador: los cuatro comunes y el propio.
static func res_keys(sim: Sim, pid: int) -> Array[String]:
	var out: Array[String] = Sim.RES_KINDS.duplicate()
	var dd := sim.dp(pid)
	if dd.has_mod("recurso_propio"):
		out.append(dd.mod("recurso_propio")["clave"])
	return out


static func player_name(sim: Sim, pid: int, local: int) -> String:
	var civ: String = sim.dp(pid).civ.get("nombre", "")
	var who := "Vos" if pid == local else Palette.TEAM_NAMES[pid % Palette.TEAM_NAMES.size()]
	return "%s · %s" % [who, civ] if civ != "" else who


## Eje de un hito: el campo `eje` de los datos; los hitos comunes se deducen por su clave.
static func eje_of(def: Dictionary, key: String) -> String:
	if def.has("eje"):
		return def["eje"]
	return "militar" if key.contains("guerra") else "economia"


static func eje_color(eje: String) -> Color:
	return Palette.UI_GOOD if eje == "economia" else Palette.UI_BAD


## Caja con estilo del HUD y una pestaña de título con su tecla.
static func frame(ci: CanvasItem, size: Vector2, head: String, key: String) -> void:
	var sb := Hud.panel_box(8)
	sb.bg_color = Color(Palette.UI_BG, 0.97) # opaco: puede tapar los objetivos de campaña
	ci.draw_style_box(sb, Rect2(Vector2.ZERO, size))
	ci.draw_string(Hud.font_b, Vector2(16, 30), head, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Palette.UI_TEXT)
	ci.draw_string(Hud.font_b, Vector2(0, 28), "%s  ✕" % key, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 14, 13, Palette.UI_DIM)
	ci.draw_line(Vector2(14, 42), Vector2(size.x - 14, 42), Palette.UI_LINE, 1)


static func close_rect(size: Vector2) -> Rect2:
	return Rect2(size.x - 70, 6, 64, 32)


static func fmt_time(seconds: int) -> String:
	return "%02d:%02d" % [seconds / 60, seconds % 60]


static func fmt_rate(n: int) -> String:
	return ("+%d" % n) if n >= 0 else str(n)
