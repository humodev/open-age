class_name EstiloPintado
extends StyleBox
## --- interfaz pintada --- (proceso/68-interfaz-pintada) El StyleBox de Hud.panel_box (diálogos,
## paneles F5–F9, ficha, menú, avisos de campaña, listas): papel con gouache y la faja fina del
## pueblo del jugador (la común en los menús). Tiene las mismas propiedades que se le tocaban al
## StyleBoxFlat de antes (bg_color, border_color, sombra, radios), así los que lo usan no cambian.
## - Fondo oscuro y neutro (el de casi todos): se pinta el papel encima.
## - Fondo de color o claro (una fila elegida, un aviso): queda ese color con el grano encima y el
##   borde de siempre, sin faja; así no se pierde lo que el color quiere decir.
## Sin texturas (hud_estilo.pintado.activo false), dibuja como el StyleBoxFlat de antes.

const MARCO := preload("res://src/game/ui/marco_hud.gd")

var bg_color := Color(0.1, 0.1, 0.1, 0.9)
var border_color := Color(0.8, 0.8, 0.8, 0.5)
var shadow_color := Color(0, 0, 0, 0.35)
var shadow_size := 0
var shadow_offset := Vector2.ZERO
var draw_center := true
var border_width_left := 0
var border_width_top := 0
var border_width_right := 0
var border_width_bottom := 0
var corner_radius_top_left := 0
var corner_radius_top_right := 0
var corner_radius_bottom_left := 0
var corner_radius_bottom_right := 0
var anti_aliasing := true


func set_border_width_all(w: int) -> void:
	border_width_left = w
	border_width_top = w
	border_width_right = w
	border_width_bottom = w


func set_corner_radius_all(r: int) -> void:
	corner_radius_top_left = r
	corner_radius_top_right = r
	corner_radius_bottom_left = r
	corner_radius_bottom_right = r


## El StyleBoxFlat equivalente (el de antes): para dibujar sin pintado y para la sombra.
func plano() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.shadow_color = shadow_color
	sb.shadow_size = shadow_size
	sb.shadow_offset = shadow_offset
	sb.draw_center = draw_center
	sb.border_width_left = border_width_left
	sb.border_width_top = border_width_top
	sb.border_width_right = border_width_right
	sb.border_width_bottom = border_width_bottom
	sb.corner_radius_top_left = corner_radius_top_left
	sb.corner_radius_top_right = corner_radius_top_right
	sb.corner_radius_bottom_left = corner_radius_bottom_left
	sb.corner_radius_bottom_right = corner_radius_bottom_right
	sb.anti_aliasing = anti_aliasing
	return sb


## Fondo oscuro y casi gris (el de los paneles): lo tapa el papel. Si no, es un fondo que dice algo.
func _neutro() -> bool:
	var c := bg_color
	var sat := (maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b))) / maxf(0.001, maxf(c.r, maxf(c.g, c.b)))
	return c.get_luminance() < 0.16 and (sat < 0.3 or c.get_luminance() < 0.11) and draw_center


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if not MARCO.pintado():
		plano().draw(to_canvas_item, rect)
		return
	if _neutro():
		MARCO.panel_pintado(to_canvas_item, rect, [], false, shadow_size > 0, true, Color(1, 1, 1, bg_color.a if bg_color.a > 0.5 else 0.94))
		return
	plano().draw(to_canvas_item, rect)
	if draw_center:
		MARCO.superficie(to_canvas_item, rect.grow(-1), Color(1, 1, 1, MARCO.num("grano_alfa", 0.35, "pintado")))
