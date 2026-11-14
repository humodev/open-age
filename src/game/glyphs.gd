class_name Glyphs
extends RefCounted
## Íconos vectoriales de maqueta: función, edificio, recurso y orden (docs/07).


static func draw(ci: CanvasItem, kind: String, r: Rect2, col: Color) -> void:
	var c := r.get_center()
	var s := minf(r.size.x, r.size.y)
	var w := maxf(1.5, s * 0.07)
	match kind:
		"alimento":
			ci.draw_circle(c + Vector2(-s * 0.12, s * 0.06), s * 0.2, col)
			ci.draw_circle(c + Vector2(s * 0.14, s * 0.1), s * 0.17, col.darkened(0.15))
			ci.draw_circle(c + Vector2(0, -s * 0.12), s * 0.15, col.lightened(0.1))
			ci.draw_line(c + Vector2(0, -s * 0.26), c + Vector2(s * 0.14, -s * 0.38), Palette.RES["madera"], w)
		"madera":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.4), c + Vector2(s * 0.3, s * 0.18), c + Vector2(-s * 0.3, s * 0.18)]), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.06, s * 0.18), Vector2(s * 0.12, s * 0.2)), col.darkened(0.45))
		"piedra":
			ci.draw_colored_polygon(_ngon(c, s * 0.36, 6, 0.3), col)
			ci.draw_colored_polygon(_ngon(c + Vector2(-s * 0.05, -s * 0.06), s * 0.16, 5, 0.0), col.lightened(0.25))
		"riqueza":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.4), c + Vector2(s * 0.3, 0), c + Vector2(0, s * 0.4), c + Vector2(-s * 0.3, 0)]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.4), c + Vector2(s * 0.3, 0), c + Vector2(0, 0)]), col.lightened(0.3))
		"pob":
			ci.draw_circle(c + Vector2(0, -s * 0.18), s * 0.14, col)
			ci.draw_colored_polygon(_round_top(c + Vector2(0, s * 0.22), s * 0.3, s * 0.3), col)
		"aldeano":
			_figure(ci, c, s, col, 0.9)
		"explorador":
			_figure(ci, c + Vector2(-s * 0.08, 0), s, col, 0.85)
			ci.draw_line(c + Vector2(s * 0.12, -s * 0.05), c + Vector2(s * 0.42, -s * 0.05), col, w)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.46, -s * 0.05), c + Vector2(s * 0.34, -s * 0.16), c + Vector2(s * 0.34, s * 0.06)]), col)
		"guerrero":
			_figure(ci, c + Vector2(-s * 0.06, 0), s, col, 1.1)
			ci.draw_line(c + Vector2(s * 0.12, s * 0.2), c + Vector2(s * 0.3, -s * 0.18), col, w * 1.2)
			ci.draw_circle(c + Vector2(s * 0.3, -s * 0.2), s * 0.09, col)
		"hondero":
			_figure(ci, c + Vector2(-s * 0.1, 0), s, col, 0.85)
			ci.draw_arc(c + Vector2(s * 0.1, -s * 0.05), s * 0.24, -PI * 0.7, PI * 0.2, 12, col, w)
			ci.draw_circle(c + Vector2(s * 0.32, -s * 0.0), s * 0.05, col)
		"lancero":
			ci.draw_line(c + Vector2(-s * 0.26, -s * 0.42), c + Vector2(-s * 0.26, s * 0.4), col, w)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.26, -s * 0.5), c + Vector2(-s * 0.2, -s * 0.36), c + Vector2(-s * 0.32, -s * 0.36)]), col)
			_figure(ci, c + Vector2(-s * 0.02, 0), s, col, 0.9)
			ci.draw_colored_polygon(_ngon(c + Vector2(s * 0.12, s * 0.06), s * 0.22, 14, 0.0), col.darkened(0.25))
			ci.draw_arc(c + Vector2(s * 0.12, s * 0.06), s * 0.22, 0, TAU, 16, col, w * 0.7)
		"centro":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.36, s * 0.0), Vector2(s * 0.72, s * 0.3)), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.42, s * 0.02), c + Vector2(0, -s * 0.36), c + Vector2(s * 0.42, s * 0.02)]), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.08, s * 0.1), Vector2(s * 0.16, s * 0.2)), col.darkened(0.5))
			# --- grilla --- (mástil con bandera: el centro no se confunde con la casa)
			ci.draw_line(c + Vector2(0, -s * 0.34), c + Vector2(0, -s * 0.5), col, w * 0.8)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.5), c + Vector2(s * 0.22, -s * 0.45), c + Vector2(0, -s * 0.4)]), Palette.UI_ACCENT)
		"casa":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.26, -s * 0.02), Vector2(s * 0.52, s * 0.32)), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.34, 0), c + Vector2(0, -s * 0.32), c + Vector2(s * 0.34, 0)]), col)
		"granja":
			for i in 4:
				var y := c.y - s * 0.3 + i * s * 0.18
				ci.draw_rect(Rect2(Vector2(c.x - s * 0.36, y), Vector2(s * 0.72, s * 0.1)), col if i % 2 == 0 else col.darkened(0.3))
		"deposito":
			ci.draw_line(c + Vector2(-s * 0.3, -s * 0.12), c + Vector2(-s * 0.3, s * 0.32), col, w)
			ci.draw_line(c + Vector2(s * 0.3, -s * 0.12), c + Vector2(s * 0.3, s * 0.32), col, w)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.4, -s * 0.1), c + Vector2(0, -s * 0.36), c + Vector2(s * 0.4, -s * 0.1)]), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.18, s * 0.08), Vector2(s * 0.2, s * 0.22)), col)
			ci.draw_rect(Rect2(c + Vector2(s * 0.04, s * 0.14), Vector2(s * 0.16, s * 0.16)), col.darkened(0.2))
		"cuartel":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.36, -s * 0.04), Vector2(s * 0.72, s * 0.34)), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.4, -s * 0.02), c + Vector2(-s * 0.3, -s * 0.22), c + Vector2(s * 0.3, -s * 0.22), c + Vector2(s * 0.4, -s * 0.02)]), col.darkened(0.2))
			ci.draw_line(c + Vector2(s * 0.28, -s * 0.22), c + Vector2(s * 0.28, -s * 0.46), col, w * 0.8)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.28, -s * 0.46), c + Vector2(s * 0.44, -s * 0.4), c + Vector2(s * 0.28, -s * 0.34)]), col)
		"torre":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.18, s * 0.4), c + Vector2(-s * 0.14, -s * 0.22), c + Vector2(s * 0.14, -s * 0.22), c + Vector2(s * 0.18, s * 0.4)]), col)
			for i in 3:
				ci.draw_rect(Rect2(c + Vector2(-s * 0.22 + i * s * 0.17, -s * 0.38), Vector2(s * 0.1, s * 0.14)), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.22, -s * 0.26), Vector2(s * 0.44, s * 0.06)), col)
		"hito":
			for i in 4:
				var ww := s * (0.8 - i * 0.18)
				ci.draw_rect(Rect2(Vector2(c.x - ww / 2, c.y + s * 0.26 - i * s * 0.17), Vector2(ww, s * 0.15)), col.darkened(0.08 * (3 - i)))
		"hito_economia":
			draw(ci, "hito", r, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.46), c + Vector2(s * 0.12, -s * 0.32), c + Vector2(0, -s * 0.18), c + Vector2(-s * 0.12, -s * 0.32)]), Palette.RES["riqueza"])
		"hito_guerra":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.38, -s * 0.05), Vector2(s * 0.76, s * 0.4)), col)
			for i in 4:
				ci.draw_rect(Rect2(c + Vector2(-s * 0.38 + i * s * 0.22, -s * 0.16), Vector2(s * 0.12, s * 0.12)), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.12, -s * 0.42), Vector2(s * 0.24, s * 0.4)), col.darkened(0.2))
			ci.draw_line(c + Vector2(-s * 0.2, s * 0.25), c + Vector2(s * 0.2, s * 0.02), Palette.UI_BAD, w)
			ci.draw_line(c + Vector2(-s * 0.2, s * 0.02), c + Vector2(s * 0.2, s * 0.25), Palette.UI_BAD, w)
		"carga":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.32, -s * 0.1), c + Vector2(s * 0.32, -s * 0.1), c + Vector2(s * 0.24, s * 0.34), c + Vector2(-s * 0.24, s * 0.34)]), col)
			ci.draw_arc(c + Vector2(0, -s * 0.1), s * 0.22, PI, TAU, 10, col, w)
			for i in 3:
				ci.draw_line(c + Vector2(-s * 0.22 + i * s * 0.22, -s * 0.02), c + Vector2(-s * 0.18 + i * s * 0.18, s * 0.3), col.darkened(0.35), w * 0.6)
		"escudo":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.3, -s * 0.36), c + Vector2(s * 0.3, -s * 0.36), c + Vector2(s * 0.3, 0), c + Vector2(0, s * 0.4), c + Vector2(-s * 0.3, 0)]), col)
			ci.draw_line(c + Vector2(0, -s * 0.3), c + Vector2(0, s * 0.3), col.darkened(0.35), w)
		"vida":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.1, -s * 0.34), Vector2(s * 0.2, s * 0.68)), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.34, -s * 0.1), Vector2(s * 0.68, s * 0.2)), col)
		"velocidad":
			for i in 2:
				var o := Vector2(-s * 0.18 + i * s * 0.26, 0)
				ci.draw_colored_polygon(PackedVector2Array([c + o + Vector2(-s * 0.14, -s * 0.3), c + o + Vector2(s * 0.14, 0), c + o + Vector2(-s * 0.14, s * 0.3)]), col)
		"campana":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.32, s * 0.22), c + Vector2(-s * 0.2, -s * 0.2), c + Vector2(0, -s * 0.34), c + Vector2(s * 0.2, -s * 0.2), c + Vector2(s * 0.32, s * 0.22)]), col)
			ci.draw_circle(c + Vector2(0, s * 0.32), s * 0.08, col)
		"calma":
			draw(ci, "campana", r, Color(col, 0.5))
			ci.draw_line(c + Vector2(-s * 0.38, -s * 0.38), c + Vector2(s * 0.38, s * 0.38), Palette.UI_GOOD, w * 1.2)
		"refugio":
			draw(ci, "casa", r, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.1, s * 0.3), c + Vector2(-s * 0.1, s * 0.1), c + Vector2(-s * 0.2, s * 0.1), c + Vector2(0, -s * 0.06), c + Vector2(s * 0.2, s * 0.1), c + Vector2(s * 0.1, s * 0.1), c + Vector2(s * 0.1, s * 0.3)]), Palette.UI_GOOD)
		"expulsar":
			draw(ci, "casa", r, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.1, -s * 0.06), c + Vector2(-s * 0.1, s * 0.14), c + Vector2(-s * 0.2, s * 0.14), c + Vector2(0, s * 0.34), c + Vector2(s * 0.2, s * 0.14), c + Vector2(s * 0.1, s * 0.14), c + Vector2(s * 0.1, -s * 0.06)]), Palette.UI_ACCENT)
		"empalizada":
			for i in 4:
				var x := c.x - s * 0.33 + i * s * 0.22
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x - s * 0.08, c.y + s * 0.36), Vector2(x - s * 0.08, c.y - s * 0.18), Vector2(x, c.y - s * 0.34), Vector2(x + s * 0.08, c.y - s * 0.18), Vector2(x + s * 0.08, c.y + s * 0.36)]), col)
		"puerta":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.36, -s * 0.3), Vector2(s * 0.12, s * 0.66)), col)
			ci.draw_rect(Rect2(c + Vector2(s * 0.24, -s * 0.3), Vector2(s * 0.12, s * 0.66)), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.36, -s * 0.36), Vector2(s * 0.72, s * 0.1)), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.2, -s * 0.12), Vector2(s * 0.4, s * 0.48)), col.darkened(0.3))
		"ariete":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.36, s * 0.1), c + Vector2(-s * 0.2, -s * 0.24), c + Vector2(s * 0.2, -s * 0.24), c + Vector2(s * 0.36, s * 0.1)]), col)
			ci.draw_line(c + Vector2(-s * 0.3, s * 0.1), c + Vector2(s * 0.46, s * 0.1), col.darkened(0.3), w * 1.6)
			ci.draw_circle(c + Vector2(-s * 0.22, s * 0.3), s * 0.09, col)
			ci.draw_circle(c + Vector2(s * 0.22, s * 0.3), s * 0.09, col)
		"jinete":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.36, s * 0.1), c + Vector2(s * 0.3, s * 0.1), c + Vector2(s * 0.42, -s * 0.12), c + Vector2(s * 0.3, s * 0.18), c + Vector2(-s * 0.3, s * 0.2)]), col)
			for x in [-0.28, -0.14, 0.14, 0.26]:
				ci.draw_line(c + Vector2(s * x, s * 0.18), c + Vector2(s * x, s * 0.42), col, w)
			ci.draw_circle(c + Vector2(-s * 0.02, -s * 0.28), s * 0.09, col)
			ci.draw_line(c + Vector2(-s * 0.02, -s * 0.2), c + Vector2(-s * 0.02, s * 0.05), col, w * 1.4)
		"elefante":
			ci.draw_colored_polygon(_ngon(c + Vector2(-s * 0.05, 0), s * 0.32, 14, 0.0), col)
			ci.draw_line(c + Vector2(s * 0.28, -s * 0.05), c + Vector2(s * 0.42, s * 0.32), col, w * 1.6)
			for x in [-0.26, -0.08, 0.1]:
				ci.draw_line(c + Vector2(s * x, s * 0.2), c + Vector2(s * x, s * 0.42), col, w * 1.8)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.22, -s * 0.46), Vector2(s * 0.3, s * 0.16)), col.darkened(0.3))
		"arcabuz":
			_figure(ci, c + Vector2(-s * 0.1, 0), s, col, 0.85)
			ci.draw_line(c + Vector2(-s * 0.05, s * 0.05), c + Vector2(s * 0.42, -s * 0.22), col.darkened(0.3), w * 1.3)
		"camino":
			for i in 3:
				ci.draw_rect(Rect2(c + Vector2(-s * 0.36 + i * s * 0.25, -s * 0.12 + (i % 2) * s * 0.08), Vector2(s * 0.2, s * 0.2)), col)
		"mercado":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.42, -s * 0.05), c + Vector2(0, -s * 0.36), c + Vector2(s * 0.42, -s * 0.05)]), col.darkened(0.15))
			for i in 3:
				ci.draw_rect(Rect2(c + Vector2(-s * 0.36 + i * s * 0.26, -s * 0.05), Vector2(s * 0.2, s * 0.36)), col if i != 1 else Palette.WEALTH)
		"detener":
			ci.draw_rect(Rect2(c - Vector2(s * 0.24, s * 0.24), Vector2(s * 0.48, s * 0.48)), col)
		"atacar":
			ci.draw_line(c + Vector2(-s * 0.3, s * 0.3), c + Vector2(s * 0.3, -s * 0.3), col, w * 1.2)
			ci.draw_line(c + Vector2(-s * 0.3, -s * 0.3), c + Vector2(s * 0.3, s * 0.3), col, w * 1.2)
			ci.draw_circle(c, s * 0.1, col)
		# --- grilla --- (submenús del aldeano y edificios propios con ícono distinto del común)
		"menu_economia":
			# Gavilla atada: economía.
			for i in 5:
				var x := -0.22 + i * 0.11
				ci.draw_line(c + Vector2(s * x * 0.5, s * 0.38), c + Vector2(s * x, -s * 0.3), col, w)
				ci.draw_circle(c + Vector2(s * x, -s * 0.32), s * 0.06, col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.18, s * 0.04), Vector2(s * 0.36, s * 0.1)), Palette.RES["riqueza"])
		"menu_militar":
			# Escudo con dos lanzas cruzadas: militar y defensa.
			ci.draw_line(c + Vector2(-s * 0.4, s * 0.4), c + Vector2(s * 0.34, -s * 0.34), col, w)
			ci.draw_line(c + Vector2(s * 0.4, s * 0.4), c + Vector2(-s * 0.34, -s * 0.34), col, w)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.42, -s * 0.42), c + Vector2(s * 0.26, -s * 0.36), c + Vector2(s * 0.36, -s * 0.26)]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.42, -s * 0.42), c + Vector2(-s * 0.26, -s * 0.36), c + Vector2(-s * 0.36, -s * 0.26)]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.22, -s * 0.2), c + Vector2(s * 0.22, -s * 0.2), c + Vector2(s * 0.22, s * 0.06), c + Vector2(0, s * 0.3), c + Vector2(-s * 0.22, s * 0.06)]), Palette.UI_BAD)
		"volver":
			ci.draw_arc(c + Vector2(s * 0.04, s * 0.04), s * 0.24, -PI * 0.5, PI * 0.5, 12, col, w * 1.3)
			ci.draw_line(c + Vector2(s * 0.04, -s * 0.2), c + Vector2(-s * 0.2, -s * 0.2), col, w * 1.3)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.38, -s * 0.2), c + Vector2(-s * 0.18, -s * 0.36), c + Vector2(-s * 0.18, -s * 0.04)]), col)
			ci.draw_line(c + Vector2(s * 0.04, s * 0.28), c + Vector2(-s * 0.24, s * 0.28), col, w * 1.3)
		"terraza":
			# Andén: escalones de cultivo en la ladera.
			for i in 3:
				var y := c.y + s * 0.26 - i * s * 0.22
				var x0 := c.x - s * 0.4 + i * s * 0.2
				ci.draw_rect(Rect2(Vector2(x0, y - s * 0.06), Vector2(c.x + s * 0.4 - x0, s * 0.12)), col.darkened(0.35))
				ci.draw_rect(Rect2(Vector2(x0, y - s * 0.12), Vector2(c.x + s * 0.4 - x0, s * 0.06)), Palette.RES["madera"])
		"gult":
			# Tierra concedida: parcela con mojón y estandarte.
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.42, s * 0.12), c + Vector2(0, -s * 0.06), c + Vector2(s * 0.42, s * 0.12), c + Vector2(0, s * 0.32)]), col.darkened(0.25))
			for i in 3:
				ci.draw_line(c + Vector2(-s * 0.28 + i * s * 0.14, s * 0.06 + i * s * 0.06), c + Vector2(s * 0.0 + i * s * 0.14, s * 0.2 + i * s * 0.06 - s * 0.14), col, w * 0.6)
			ci.draw_line(c + Vector2(-s * 0.1, s * 0.0), c + Vector2(-s * 0.1, -s * 0.44), col, w)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.1, -s * 0.44), c + Vector2(s * 0.24, -s * 0.34), c + Vector2(-s * 0.1, -s * 0.24)]), Palette.UI_ACCENT)
		"telar":
			# Telar de cintura: marco y urdimbre.
			ci.draw_rect(Rect2(c + Vector2(-s * 0.34, -s * 0.38), Vector2(s * 0.68, s * 0.08)), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.34, s * 0.3), Vector2(s * 0.68, s * 0.08)), col)
			for i in 5:
				ci.draw_line(c + Vector2(-s * 0.26 + i * s * 0.13, -s * 0.3), c + Vector2(-s * 0.26 + i * s * 0.13, s * 0.3), col.darkened(0.2), w * 0.6)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.3, -s * 0.04), Vector2(s * 0.6, s * 0.2)), Palette.RES["riqueza"])
		"corral":
			# Cerco circular de palos con una cabeza adentro.
			for i in 10:
				var a := TAU * i / 10.0
				var p := c + Vector2(cos(a), sin(a) * 0.62) * s * 0.36
				ci.draw_line(p + Vector2(0, s * 0.06), p - Vector2(0, s * 0.16), col, w)
			ci.draw_arc(c, s * 0.36, 0, TAU, 20, col.darkened(0.2), w * 0.6)
			ci.draw_circle(c + Vector2(0, -s * 0.02), s * 0.1, col.lightened(0.15))
		"carpa":
			# Corte que se muda: tienda grande con estandarte.
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.42, s * 0.32), c + Vector2(0, -s * 0.3), c + Vector2(s * 0.42, s * 0.32)]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.08, s * 0.32), c + Vector2(0, s * 0.06), c + Vector2(s * 0.08, s * 0.32)]), col.darkened(0.5))
			ci.draw_line(c + Vector2(0, -s * 0.3), c + Vector2(0, -s * 0.46), col, w)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.46), c + Vector2(s * 0.2, -s * 0.41), c + Vector2(0, -s * 0.36)]), Palette.UI_ACCENT)
		"mocambo":
			# Aldea cercada: estacas y techo de paja.
			for i in 7:
				var x := c.x - s * 0.4 + i * s * 0.133
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x - s * 0.04, c.y + s * 0.38), Vector2(x - s * 0.04, c.y + s * 0.1), Vector2(x, c.y + s * 0.02), Vector2(x + s * 0.04, c.y + s * 0.1), Vector2(x + s * 0.04, c.y + s * 0.38)]), col.darkened(0.2))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.26, s * 0.02), c + Vector2(0, -s * 0.4), c + Vector2(s * 0.26, s * 0.02)]), col)
		"qollqa":
			# Depósito redondo de piedra con techo cónico.
			ci.draw_rect(Rect2(c + Vector2(-s * 0.24, -s * 0.06), Vector2(s * 0.48, s * 0.4)), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.32, -s * 0.04), c + Vector2(0, -s * 0.42), c + Vector2(s * 0.32, -s * 0.04)]), col.darkened(0.25))
			for i in 2:
				ci.draw_line(c + Vector2(-s * 0.24, s * 0.08 + i * s * 0.12), c + Vector2(s * 0.24, s * 0.08 + i * s * 0.12), col.darkened(0.35), w * 0.5)
		"kraal":
			draw(ci, "elefante", Rect2(r.position + r.size * 0.12, r.size * 0.76), col)
			for i in 5:
				var x := c.x - s * 0.44 + i * s * 0.22
				ci.draw_line(Vector2(x, c.y + s * 0.46), Vector2(x, c.y + s * 0.18), col.darkened(0.3), w)
			ci.draw_line(Vector2(c.x - s * 0.46, c.y + s * 0.3), Vector2(c.x + s * 0.46, c.y + s * 0.3), col.darkened(0.3), w * 0.7)
		"barrio_japones":
			# Barrio de la compañía japonesa: portal de dos postes y dintel doble.
			ci.draw_rect(Rect2(c + Vector2(-s * 0.26, -s * 0.22), Vector2(s * 0.08, s * 0.6)), col)
			ci.draw_rect(Rect2(c + Vector2(s * 0.18, -s * 0.22), Vector2(s * 0.08, s * 0.6)), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.44, -s * 0.38), c + Vector2(s * 0.44, -s * 0.38), c + Vector2(s * 0.36, -s * 0.28), c + Vector2(-s * 0.36, -s * 0.28)]), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.32, -s * 0.18), Vector2(s * 0.64, s * 0.06)), col)
		"barrio_portugues":
			# Barrio portugués: casa con una vela de nao detrás.
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.04, -s * 0.44), c + Vector2(s * 0.4, -s * 0.06), c + Vector2(s * 0.04, -s * 0.06)]), col.darkened(0.15))
			ci.draw_line(c + Vector2(s * 0.04, -s * 0.44), c + Vector2(s * 0.04, s * 0.0), col, w * 0.7)
			draw(ci, "casa", Rect2(r.position + Vector2(0, r.size.y * 0.2), r.size * 0.8), col)
		"decision":
			# Aviso que pide algo: signo de exclamación en un rombo.
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.46), c + Vector2(s * 0.46, 0), c + Vector2(0, s * 0.46), c + Vector2(-s * 0.46, 0)]), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.05, -s * 0.26), Vector2(s * 0.1, s * 0.3)), Color(0.06, 0.065, 0.075))
			ci.draw_circle(c + Vector2(0, s * 0.16), s * 0.06, Color(0.06, 0.065, 0.075))
		"hito_logro":
			# Logro: estrella de cinco puntas.
			var pts := PackedVector2Array()
			for i in 10:
				var a := -PI / 2 + PI * i / 5.0
				pts.append(c + Vector2(cos(a), sin(a)) * s * (0.46 if i % 2 == 0 else 0.2))
			ci.draw_colored_polygon(pts, col)
		"info":
			ci.draw_arc(c, s * 0.4, 0, TAU, 24, col, w)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.05, -s * 0.06), Vector2(s * 0.1, s * 0.3)), col)
			ci.draw_circle(c + Vector2(0, -s * 0.2), s * 0.06, col)
		# --- fin grilla ---
		"arbol", "arbusto", "roca":
			draw(ci, {"arbol": "madera", "arbusto": "alimento", "roca": "piedra"}[kind], r, col)
		_:
			ci.draw_circle(c, s * 0.25, col)


const KNOWN := ["mercado", "aldeano", "guerrero", "hondero", "lancero", "explorador", "ariete", "centro", "casa", "granja", "deposito", "cuartel", "torre", "hito", "hito_economia", "hito_guerra", "empalizada", "puerta"]


## Ícono para cualquier tipo, también los propios de cada civilización, deducido de sus datos.
static func resolve(def: Dictionary, type: String) -> String:
	if type in KNOWN:
		return type
	# --- grilla --- (ícono propio de la tabla de la interfaz; hitos por su eje: Z economía, X militar)
	var own := Grilla.icono(type)
	if own != "":
		return own
	if def.get("avanza_edad", false):
		return "hito_guerra" if Grilla.eje(def, type) == "militar" else "hito_economia"
	# --- fin grilla ---
	if def.has("funcion"):
		if def.get("elefante", false):
			return "elefante"
		if def.get("montado", false):
			return "jinete"
		if def.get("polvora", false):
			return "arcabuz"
		return {"civil": "aldeano", "choque": "guerrero", "distancia": "hondero", "linea": "lancero", "explorador": "explorador", "asedio": "ariete"}.get(def["funcion"], "aldeano")
	if def.get("avanza_edad", false):
		return "hito_guerra" if def.has("produce") or def.has("flechas") else "hito_economia"
	if def.get("camino", false):
		return "camino"
	if (def.get("produce", []) as Array).has("aldeano") or def.get("cuenta_victoria", false):
		return "centro"
	if def.has("produce"):
		return "cuartel"
	if def.has("fuente") or def.has("renta"):
		return "granja"
	if def.has("deposito"):
		return "deposito"
	return "casa"


static func _figure(ci: CanvasItem, c: Vector2, s: float, col: Color, k: float) -> void:
	ci.draw_circle(c + Vector2(0, -s * 0.22 * k), s * 0.12 * k, col)
	ci.draw_colored_polygon(_round_top(c + Vector2(0, s * 0.34), s * 0.24 * k, s * 0.42 * k), col)


static func _round_top(bottom: Vector2, half_w: float, hgt: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(bottom + Vector2(-half_w, 0))
	for i in 9:
		var a := PI + PI * i / 8.0
		pts.append(bottom + Vector2(cos(a) * half_w, -hgt + half_w + sin(a) * half_w))
	pts.append(bottom + Vector2(half_w, 0))
	return pts


static func _ngon(c: Vector2, r: float, n: int, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := rot + TAU * i / n
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts
