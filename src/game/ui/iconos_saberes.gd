extends RefCounted
## --- paso 6 --- Glifos de los saberes propios de mapuches y guaraníes (docs/diseno/27, §3.2 y
## §3.3; proceso/26-juego-tardio/11): las mejoras, las unidades propias y el hoyo con estacas. Los
## usa Iconos.dibujar; el nombre de cada uno está en data/civs (`icono`) y en data/iconos.json.
## Nada sagrado: ni kultrun, ni rewe, ni mbaraka, ni cruces. Dibujo vectorial, sin imágenes.

const OSCURO := Color(0.06, 0.065, 0.075)


## Dibuja `kind` si es de acá; devuelve false si no.
static func dibujar(ci: CanvasItem, kind: String, c: Vector2, s: float, w: float, col: Color, claro: bool, r: Rect2) -> bool:
	var dark := col.darkened(0.3)
	var acc := Palette.UI_ACCENT if claro else col
	match kind:
		"coselete":
			# Coselete de cuero: peto con hombreras y costuras.
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.3, -s * 0.34), c + Vector2(s * 0.3, -s * 0.34), c + Vector2(s * 0.24, s * 0.4), c + Vector2(-s * 0.24, s * 0.4)]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.1, -s * 0.34), c + Vector2(s * 0.1, -s * 0.34), c + Vector2(0, -s * 0.18)]), OSCURO)
			for x: float in [-0.42, 0.28]:
				ci.draw_rect(Rect2(c + Vector2(s * x, -s * 0.38), Vector2(s * 0.14, s * 0.16)), dark)
			for i in 3:
				ci.draw_line(c + Vector2(-s * 0.2, s * (-0.06 + i * 0.14)), c + Vector2(s * 0.2, s * (-0.06 + i * 0.14)), OSCURO, w * 0.5)
		"trigo":
			# Trigo y manzana: espiga con granos y una manzana al pie.
			ci.draw_line(c + Vector2(-s * 0.06, s * 0.44), c + Vector2(-s * 0.06, -s * 0.44), dark, w)
			for i in 5:
				var y := -s * 0.38 + i * s * 0.13
				for sd: float in [-1.0, 1.0]:
					ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.06, y + s * 0.08), c + Vector2(-s * 0.06 + sd * s * 0.14, y), c + Vector2(-s * 0.06 + sd * s * 0.06, y - s * 0.06)]), col)
			ci.draw_circle(c + Vector2(s * 0.24, s * 0.28), s * 0.15, acc)
			ci.draw_line(c + Vector2(s * 0.24, s * 0.14), c + Vector2(s * 0.3, s * 0.04), dark, w * 0.6)
		"estacas":
			# Hoyos y estacas (la mejora): tres estacas aguzadas que salen de un hoyo.
			ci.draw_colored_polygon(_elipse(c + Vector2(0, s * 0.26), s * 0.44, s * 0.16), OSCURO)
			for i in 3:
				var x := -s * 0.24 + i * s * 0.24
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(x - s * 0.06, s * 0.3), c + Vector2(x + s * 0.06, s * 0.3), c + Vector2(x + (i - 1) * s * 0.08, -s * 0.36)]), col)
		"hoyo":
			# El hoyo tapado: ramas cruzadas sobre la boca oscura, con una punta asomando.
			ci.draw_colored_polygon(_elipse(c + Vector2(0, s * 0.1), s * 0.42, s * 0.26), OSCURO)
			for i in 4:
				var y := -s * 0.06 + i * s * 0.1
				ci.draw_line(c + Vector2(-s * 0.4, y), c + Vector2(s * 0.4, y + s * 0.08 * (1 if i % 2 == 0 else -1)), col, w * 0.8)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.1, s * 0.12), c + Vector2(s * 0.2, s * 0.12), c + Vector2(s * 0.15, -s * 0.36)]), acc)
		"lawen":
			# Lawen: hoja de matico con su nervadura y una gota de remedio.
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.36, s * 0.36), c + Vector2(-s * 0.3, -s * 0.06), c + Vector2(0, -s * 0.36), c + Vector2(s * 0.28, -s * 0.4), c + Vector2(s * 0.2, -s * 0.08), c + Vector2(-s * 0.06, s * 0.2)]), col)
			ci.draw_line(c + Vector2(-s * 0.36, s * 0.36), c + Vector2(s * 0.24, -s * 0.36), OSCURO, w * 0.6)
			ci.draw_circle(c + Vector2(s * 0.26, s * 0.24), s * 0.1, acc)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.17, s * 0.21), c + Vector2(s * 0.26, s * 0.04), c + Vector2(s * 0.35, s * 0.21)]), acc)
		"tropilla":
			# Arreo en tropilla: tres cabezas en fila con la flecha del camino.
			for i in 3:
				var p := c + Vector2(-s * 0.3 + i * s * 0.28, s * 0.14 - (i % 2) * s * 0.06)
				ci.draw_colored_polygon(_elipse(p, s * 0.12, s * 0.08), col)
				ci.draw_circle(p + Vector2(s * 0.12, -s * 0.06), s * 0.05, col)
				ci.draw_line(p + Vector2(-s * 0.06, s * 0.06), p + Vector2(-s * 0.06, s * 0.16), dark, w * 0.5)
				ci.draw_line(p + Vector2(s * 0.06, s * 0.06), p + Vector2(s * 0.06, s * 0.16), dark, w * 0.5)
			ci.draw_line(c + Vector2(-s * 0.4, -s * 0.24), c + Vector2(s * 0.34, -s * 0.24), acc, w)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.44, -s * 0.24), c + Vector2(s * 0.3, -s * 0.33), c + Vector2(s * 0.3, -s * 0.15)]), acc)
		"poncho":
			# Makuñ: el poncho abierto con la boca y una guarda escalonada.
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.42), c + Vector2(s * 0.44, 0), c + Vector2(0, s * 0.42), c + Vector2(-s * 0.44, 0)]), col)
			ci.draw_line(c + Vector2(-s * 0.08, -s * 0.06), c + Vector2(s * 0.08, s * 0.06), OSCURO, w * 1.2)
			for i in 3:
				var k := 0.12 + i * 0.08
				ci.draw_polyline(PackedVector2Array([c + Vector2(-s * (0.44 - k), 0), c + Vector2(0, s * (0.42 - k)), c + Vector2(s * (0.44 - k), 0)]), OSCURO if i % 2 == 0 else acc, w * 0.5)
		"remonta":
			# Kawellu: cabeza de caballo con crin y la marca de la cría propia.
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.1, s * 0.42), c + Vector2(-s * 0.18, -s * 0.1), c + Vector2(-s * 0.04, -s * 0.4), c + Vector2(s * 0.08, -s * 0.3), c + Vector2(s * 0.36, s * 0.06), c + Vector2(s * 0.3, s * 0.18), c + Vector2(s * 0.06, s * 0.06), c + Vector2(s * 0.12, s * 0.42)]), col)
			ci.draw_line(c + Vector2(-s * 0.16, -s * 0.06), c + Vector2(-s * 0.04, -s * 0.38), dark, w * 1.2)
			ci.draw_circle(c + Vector2(s * 0.06, -s * 0.16), s * 0.035, OSCURO)
			ci.draw_arc(c + Vector2(-s * 0.3, s * 0.26), s * 0.12, 0.0, TAU, 12, acc, w * 0.8)
		"pron":
			# Werken y pron: la cuerda de nudos para contar los días hasta la junta.
			var pts := PackedVector2Array()
			for i in 13:
				var t := float(i) / 12.0
				pts.append(c + Vector2(lerpf(-s * 0.42, s * 0.42, t), sin(t * TAU * 1.5) * s * 0.12))
			ci.draw_polyline(pts, col, w)
			for i in 5:
				ci.draw_circle(pts[2 + i * 2], s * 0.065, col)
			ci.draw_line(pts[12], pts[12] + Vector2(0, s * 0.3), dark, w * 0.6)
			ci.draw_line(pts[0], pts[0] + Vector2(0, -s * 0.3), dark, w * 0.6)
		"mandioca":
			# Kokue: raíces de mandioca bajo la tierra, con hojas arriba.
			ci.draw_line(c + Vector2(-s * 0.42, -s * 0.02), c + Vector2(s * 0.42, -s * 0.02), dark, w * 0.6)
			for a: float in [-0.5, 0.0, 0.5]:
				var d := Vector2.from_angle(PI / 2.0 + a)
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.04, 0), c + Vector2(s * 0.04, 0), c + d * s * 0.42]), col)
			for a: float in [-2.3, -1.57, -0.8]:
				var d := Vector2.from_angle(a)
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.06), c + d * s * 0.2 + d.orthogonal() * s * 0.06, c + d * s * 0.42, c + d * s * 0.2 - d.orthogonal() * s * 0.06]), acc)
		"remo":
			# Ygá (la mejora): remo de pala ancha sobre las ondas del río.
			ci.draw_line(c + Vector2(-s * 0.34, -s * 0.4), c + Vector2(s * 0.12, s * 0.12), col.darkened(0.15), w * 1.3)
			ci.draw_colored_polygon(_elipse(c + Vector2(s * 0.2, s * 0.22), s * 0.12, s * 0.2, -0.75), col)
			for i in 2:
				var y := s * (0.3 + i * 0.13)
				ci.draw_polyline(PackedVector2Array([c + Vector2(-s * 0.44, y), c + Vector2(-s * 0.26, y - s * 0.06), c + Vector2(-s * 0.08, y), c + Vector2(s * 0.08, y - s * 0.06)]), acc, w * 0.6)
		"yuyo":
			# Pohã ñana: atado de yuyos con tres hojas.
			for a: float in [-0.5, 0.0, 0.5]:
				var d := Vector2.from_angle(-PI / 2.0 + a)
				ci.draw_line(c + Vector2(0, s * 0.42), c + d * s * 0.2, dark, w * 0.6)
				ci.draw_colored_polygon(_elipse(c + d * s * 0.28, s * 0.09, s * 0.17, a), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.08, s * 0.16), Vector2(s * 0.16, s * 0.08)), acc)
		"oga":
			# Óga de takuára: casa larga de techo arqueado, con las cañas a la vista.
			var roof := PackedVector2Array()
			for i in 13:
				var a := PI + PI * i / 12.0
				roof.append(c + Vector2(cos(a) * s * 0.44, s * 0.2 + sin(a) * s * 0.44))
			ci.draw_colored_polygon(roof, col)
			for i in 5:
				var x := -0.3 + i * 0.15
				ci.draw_line(c + Vector2(s * x, s * 0.2), c + Vector2(s * x, s * 0.2 - sqrt(maxf(0.0, 0.44 * 0.44 - x * x)) * s * 0.9), dark, w * 0.5)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.46, s * 0.2), Vector2(s * 0.92, s * 0.1)), dark)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.06, s * 0.02), Vector2(s * 0.12, s * 0.18)), OSCURO)
		"mborore":
			# Defensa de Mbororé: caño de tacuara con zunchos de cuero, sobre el agua.
			ci.draw_line(c + Vector2(-s * 0.34, s * 0.12), c + Vector2(s * 0.34, -s * 0.22), col, w * 3.2)
			for i in 3:
				var p := c + Vector2(-s * 0.2 + i * s * 0.2, s * 0.05 - i * s * 0.1)
				ci.draw_line(p + Vector2(-s * 0.03, -s * 0.07), p + Vector2(s * 0.03, s * 0.07), OSCURO, w)
			ci.draw_circle(c + Vector2(s * 0.38, -s * 0.24), s * 0.06, OSCURO)
			for i in 2:
				var y := s * (0.3 + i * 0.12)
				ci.draw_polyline(PackedVector2Array([c + Vector2(-s * 0.44, y), c + Vector2(-s * 0.22, y - s * 0.06), c + Vector2(0, y), c + Vector2(s * 0.22, y - s * 0.06), c + Vector2(s * 0.44, y)]), acc, w * 0.6)
		"yerba":
			# Ka'a: rama de yerba con hojas.
			ci.draw_line(c + Vector2(-s * 0.36, s * 0.4), c + Vector2(s * 0.3, -s * 0.36), dark, w * 0.9)
			for i in 3:
				var p := c + Vector2(-s * 0.2 + i * s * 0.2, s * 0.22 - i * s * 0.22)
				ci.draw_colored_polygon(_elipse(p + Vector2(-s * 0.1, -s * 0.06), s * 0.07, s * 0.14, -0.9), col)
				ci.draw_colored_polygon(_elipse(p + Vector2(s * 0.1, s * 0.06), s * 0.07, s * 0.14, -0.9), col.darkened(0.12))
		"flecha_dura":
			# U'y hatã: flecha de punta ancha endurecida (la punta, en el color de acento).
			ci.draw_line(c + Vector2(-s * 0.4, s * 0.4), c + Vector2(s * 0.18, -s * 0.18), col, w * 1.2)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.44, -s * 0.44), c + Vector2(s * 0.08, -s * 0.3), c + Vector2(s * 0.3, -s * 0.08)]), acc)
			for i in 2:
				var p := c + Vector2(-s * 0.36 + i * s * 0.08, s * 0.36 - i * s * 0.08)
				ci.draw_line(p, p + Vector2(-s * 0.08, -s * 0.12), col, w * 0.8)
				ci.draw_line(p, p + Vector2(s * 0.12, s * 0.08), col, w * 0.8)
		"imprenta":
			# Imprenta: prensa de tornillo con un pliego impreso al pie.
			ci.draw_rect(Rect2(c + Vector2(-s * 0.36, -s * 0.42), Vector2(s * 0.08, s * 0.6)), col)
			ci.draw_rect(Rect2(c + Vector2(s * 0.28, -s * 0.42), Vector2(s * 0.08, s * 0.6)), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.36, -s * 0.44), Vector2(s * 0.72, s * 0.08)), col)
			ci.draw_line(c + Vector2(0, -s * 0.36), c + Vector2(0, -s * 0.06), dark, w * 1.4)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.2, -s * 0.06), Vector2(s * 0.4, s * 0.08)), dark)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.3, s * 0.16), Vector2(s * 0.6, s * 0.28)), acc)
			for i in 3:
				ci.draw_line(c + Vector2(-s * 0.22, s * (0.22 + i * 0.07)), c + Vector2(s * (0.22 - (i % 2) * 0.1), s * (0.22 + i * 0.07)), OSCURO, w * 0.5)
		"aty":
			# Aty: la ronda de la asamblea (cabezas en círculo, el centro libre).
			for i in 7:
				var d := Vector2.from_angle(TAU * i / 7.0 - PI / 2.0)
				ci.draw_circle(c + d * s * 0.32, s * 0.08, col)
				ci.draw_line(c + d * s * 0.24, c + d * s * 0.16, dark, w * 0.8)
			ci.draw_circle(c, s * 0.08, acc)
		"weichafe_montado":
			# Infantería montada: el jinete con una flecha hacia el suelo (se baja a pelear).
			Glyphs.draw(ci, "jinete", Rect2(r.position + Vector2(-s * 0.06, s * 0.04), r.size * 0.86), col)
			ci.draw_line(c + Vector2(s * 0.36, -s * 0.42), c + Vector2(s * 0.36, s * 0.3), acc, w)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.36, s * 0.44), c + Vector2(s * 0.26, s * 0.28), c + Vector2(s * 0.46, s * 0.28)]), acc)
		"kona_waiki":
			# Kona de waiki: el jinete con la lanza larga de colihue cruzada adelante.
			Glyphs.draw(ci, "jinete", Rect2(r.position + Vector2(s * 0.04, s * 0.06), r.size * 0.86), col)
			ci.draw_line(c + Vector2(-s * 0.46, -s * 0.46), c + Vector2(s * 0.46, s * 0.12), col.darkened(0.2), w * 1.1)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.48, -s * 0.48), c + Vector2(-s * 0.34, -s * 0.44), c + Vector2(-s * 0.4, -s * 0.34)]), acc)
		"canoa":
			# Ygá (la unidad): canoa de un tronco con dos remeros, sobre el agua.
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.46, -s * 0.02), c + Vector2(s * 0.46, -s * 0.02), c + Vector2(s * 0.3, s * 0.18), c + Vector2(-s * 0.3, s * 0.18)]), col)
			for x: float in [-0.16, 0.16]:
				ci.draw_circle(c + Vector2(s * x, -s * 0.26), s * 0.07, col)
				ci.draw_line(c + Vector2(s * x, -s * 0.18), c + Vector2(s * x, -s * 0.04), col, w * 1.4)
				ci.draw_line(c + Vector2(s * (x - 0.12), -s * 0.2), c + Vector2(s * (x + 0.1), s * 0.28), dark, w * 0.7)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-s * 0.46, s * 0.34), c + Vector2(-s * 0.24, s * 0.28), c + Vector2(0, s * 0.34), c + Vector2(s * 0.24, s * 0.28), c + Vector2(s * 0.46, s * 0.34)]), acc, w * 0.6)
		"jinete_lanza":
			# Caballería de las misiones: el jinete con la lanza en alto y un banderín (sin cruz).
			Glyphs.draw(ci, "jinete", Rect2(r.position + Vector2(-s * 0.04, s * 0.06), r.size * 0.86), col)
			ci.draw_line(c + Vector2(s * 0.3, s * 0.2), c + Vector2(s * 0.3, -s * 0.48), col.darkened(0.2), w)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.3, -s * 0.48), c + Vector2(s * 0.48, -s * 0.42), c + Vector2(s * 0.3, -s * 0.34)]), acc)
		"kaaguygua":
			# Ka'aguygua: figura con macana entre dos árboles del monte.
			for x: float in [-0.34, 0.34]:
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * x, -s * 0.44), c + Vector2(s * (x + 0.14), s * 0.04), c + Vector2(s * (x - 0.14), s * 0.04)]), col.darkened(0.25))
				ci.draw_line(c + Vector2(s * x, s * 0.04), c + Vector2(s * x, s * 0.4), col.darkened(0.4), w * 0.8)
			Glyphs._figure(ci, c + Vector2(0, s * 0.06), s, col, 0.8)
			ci.draw_line(c + Vector2(s * 0.06, s * 0.1), c + Vector2(s * 0.2, -s * 0.24), acc, w * 1.4)
		# --- paso 6, par 2 --- Etiopía (§3.4) y Palmares (§3.5). Nada eclesiástico ni religioso.
		"arado":
			# Maresha y ṭef: la reja del arado y tres espigas finas de ṭef.
			ci.draw_line(c + Vector2(-s * 0.42, -s * 0.1), c + Vector2(s * 0.2, s * 0.22), dark, w)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.16, s * 0.16), c + Vector2(s * 0.42, s * 0.34), c + Vector2(s * 0.12, s * 0.3)]), col)
			for i in 3:
				var x := -s * 0.2 + i * s * 0.16
				ci.draw_line(c + Vector2(x, -s * 0.06), c + Vector2(x + s * 0.06, -s * 0.44), acc, w * 0.5)
		"acta":
			# Actas de tierra: hoja suelta con renglones y un sello redondo (no un libro abierto).
			ci.draw_rect(Rect2(c + Vector2(-s * 0.3, -s * 0.4), Vector2(s * 0.6, s * 0.8)), col)
			for i in 4:
				ci.draw_line(c + Vector2(-s * 0.2, -s * 0.26 + i * s * 0.12), c + Vector2(s * 0.2, -s * 0.26 + i * s * 0.12), OSCURO, w * 0.4)
			ci.draw_circle(c + Vector2(s * 0.14, s * 0.26), s * 0.1, acc)
		"kosso":
			# Kosso: racimo colgante de flores (Hagenia) sobre una hoja.
			ci.draw_colored_polygon(_elipse(c + Vector2(-s * 0.16, s * 0.2), s * 0.26, s * 0.1, -0.5), dark)
			for i in 6:
				ci.draw_circle(c + Vector2(s * (0.04 + (i % 2) * 0.12), -s * 0.34 + i * s * 0.11), s * 0.08, col)
		"cota":
			# Cota de malla: peto con trama de anillos.
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.32, -s * 0.36), c + Vector2(s * 0.32, -s * 0.36), c + Vector2(s * 0.28, s * 0.42), c + Vector2(-s * 0.28, s * 0.42)]), col)
			for yy in 4:
				for xx in 4:
					ci.draw_arc(c + Vector2(-s * 0.2 + xx * s * 0.13, -s * 0.22 + yy * s * 0.16), s * 0.05, 0, TAU, 8, OSCURO, w * 0.35)
		"amba":
			# Amba: meseta de paredes a pique con el tesoro arriba.
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.46, s * 0.4), c + Vector2(-s * 0.3, -s * 0.12), c + Vector2(s * 0.3, -s * 0.12), c + Vector2(s * 0.46, s * 0.4)]), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.1, -s * 0.32), Vector2(s * 0.2, s * 0.18)), acc)
		"amole":
			# Caravanas de amole: tres barras de sal apiladas.
			for i in 3:
				ci.draw_rect(Rect2(c + Vector2(-s * 0.36 + (i % 2) * s * 0.1, -s * 0.3 + i * s * 0.22), Vector2(s * 0.62, s * 0.16)), col.lightened(0.3) if i == 1 else col)
		"massawa":
			# Pólvora de Massawa: barril con la vela de la ruta por mar.
			ci.draw_rect(Rect2(c + Vector2(-s * 0.36, -s * 0.04), Vector2(s * 0.4, s * 0.44)), col)
			ci.draw_line(c + Vector2(-s * 0.36, s * 0.18), c + Vector2(s * 0.04, s * 0.18), OSCURO, w * 0.5)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.2, -s * 0.44), c + Vector2(s * 0.44, s * 0.08), c + Vector2(s * 0.2, s * 0.08)]), acc)
		"katama":
			# Orden del kätäma: la tienda del rey al centro y las demás en círculo.
			for i in 6:
				var a := TAU * i / 6.0
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(cos(a), sin(a)) * s * 0.34 + Vector2(0, -s * 0.08), c + Vector2(cos(a), sin(a)) * s * 0.34 + Vector2(s * 0.08, s * 0.06), c + Vector2(cos(a), sin(a)) * s * 0.34 + Vector2(-s * 0.08, s * 0.06)]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.18), c + Vector2(s * 0.14, s * 0.1), c + Vector2(-s * 0.14, s * 0.1)]), acc)
		"palmera":
			# Roças e palmeiras: palmera con sus hojas sobre un surco.
			ci.draw_line(c + Vector2(0, s * 0.42), c + Vector2(s * 0.04, -s * 0.2), dark, w)
			for a: float in [-2.6, -2.0, -1.2, -0.5]:
				ci.draw_line(c + Vector2(s * 0.04, -s * 0.2), c + Vector2(s * 0.04, -s * 0.2) + Vector2(cos(a), sin(a) + 0.5) * s * 0.36, col, w * 0.8)
			ci.draw_line(c + Vector2(-s * 0.44, s * 0.42), c + Vector2(s * 0.44, s * 0.42), acc, w * 0.7)
		"vigia_mocambo":
			# Aviso de los mocambos: dos chozas unidas por la senda con un ojo arriba.
			for x: float in [-0.28, 0.28]:
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * (x - 0.16), s * 0.4), c + Vector2(s * x, s * 0.1), c + Vector2(s * (x + 0.16), s * 0.4)]), col)
			ci.draw_line(c + Vector2(-s * 0.12, s * 0.36), c + Vector2(s * 0.12, s * 0.36), dark, w * 0.6)
			ci.draw_colored_polygon(_elipse(c + Vector2(0, -s * 0.22), s * 0.22, s * 0.1), acc)
			ci.draw_circle(c + Vector2(0, -s * 0.22), s * 0.06, OSCURO)
		"fuelle":
			# Forja de los mocambos: dos fuelles de cuenco y el tubo hacia la brasa.
			for x: float in [-0.24, 0.06]:
				ci.draw_colored_polygon(_elipse(c + Vector2(s * x, -s * 0.1), s * 0.14, s * 0.12), col)
			ci.draw_line(c + Vector2(-s * 0.1, s * 0.04), c + Vector2(s * 0.3, s * 0.3), dark, w)
			ci.draw_circle(c + Vector2(s * 0.32, s * 0.32), s * 0.1, acc)
		"sanguar":
			# Sanguar: figura que se corre de lado y dos flechas que pasan.
			Glyphs._figure(ci, c + Vector2(-s * 0.1, s * 0.08), s, col, 0.8)
			for y: float in [-0.2, 0.1]:
				ci.draw_line(c + Vector2(s * 0.08, s * y), c + Vector2(s * 0.46, s * (y - 0.08)), acc, w * 0.6)
		"kilombo":
			# Kilombo: tres figuras juntas, la del medio con lanza.
			for i in 3:
				Glyphs._figure(ci, c + Vector2(-s * 0.26 + i * s * 0.26, s * 0.1), s * 0.7, col if i != 1 else acc, 0.7)
			ci.draw_line(c + Vector2(s * 0.08, s * 0.3), c + Vector2(s * 0.08, -s * 0.44), dark, w * 0.6)
		"trato":
			# Trato con los moradores: dos canastos que se cruzan con flechas.
			ci.draw_rect(Rect2(c + Vector2(-s * 0.42, s * 0.04), Vector2(s * 0.28, s * 0.28)), col)
			ci.draw_rect(Rect2(c + Vector2(s * 0.14, -s * 0.32), Vector2(s * 0.28, s * 0.28)), acc)
			ci.draw_line(c + Vector2(-s * 0.1, s * 0.1), c + Vector2(s * 0.1, -s * 0.1), dark, w * 0.7)
		"hierro":
			# Hierro de Angola Janga: punta de lanza de hierro y el yunque.
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.46), c + Vector2(s * 0.12, -s * 0.12), c + Vector2(-s * 0.12, -s * 0.12)]), col)
			ci.draw_line(c + Vector2(0, -s * 0.12), c + Vector2(0, s * 0.14), dark, w * 0.8)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.32, s * 0.16), Vector2(s * 0.64, s * 0.14)), acc)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.12, s * 0.3), Vector2(s * 0.24, s * 0.12)), acc)
		"fojo":
			# Fojos e estrepes: pozo con estrepes y una cerca de palos detrás.
			for i in 4:
				ci.draw_line(c + Vector2(-s * 0.36 + i * s * 0.24, -s * 0.42), c + Vector2(-s * 0.36 + i * s * 0.24, -s * 0.06), dark, w * 0.8)
			ci.draw_colored_polygon(_elipse(c + Vector2(0, s * 0.24), s * 0.42, s * 0.14), OSCURO)
			for i in 3:
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.22 + i * s * 0.22 - s * 0.05, s * 0.28), c + Vector2(-s * 0.22 + i * s * 0.22 + s * 0.05, s * 0.28), c + Vector2(-s * 0.22 + i * s * 0.22, s * 0.02)]), col)
		"gasa":
			# Guerrero de gaša: figura con el escudo redondo y dos jabalinas.
			Glyphs._figure(ci, c + Vector2(s * 0.06, s * 0.06), s, col, 0.8)
			ci.draw_circle(c + Vector2(-s * 0.18, s * 0.1), s * 0.18, acc)
			ci.draw_circle(c + Vector2(-s * 0.18, s * 0.1), s * 0.05, OSCURO)
			for x: float in [0.26, 0.36]:
				ci.draw_line(c + Vector2(s * x, s * 0.4), c + Vector2(s * (x + 0.04), -s * 0.44), dark, w * 0.5)
		"farasanna":
			# Färäsäñña: el jinete con la cota (trama de anillos en el pecho).
			Glyphs.draw(ci, "jinete", Rect2(r.position + Vector2(-s * 0.04, s * 0.06), r.size * 0.86), col)
			for i in 3:
				ci.draw_arc(c + Vector2(s * (0.0 + i * 0.08), -s * 0.18), s * 0.04, 0, TAU, 8, acc, w * 0.4)
		"jinete_corte":
			# Caballería de la corte: jinete al galope con las líneas de la velocidad.
			Glyphs.draw(ci, "jinete", Rect2(r.position + Vector2(s * 0.06, s * 0.06), r.size * 0.86), col)
			for i in 3:
				ci.draw_line(c + Vector2(-s * 0.48, -s * 0.1 + i * s * 0.14), c + Vector2(-s * 0.3, -s * 0.1 + i * s * 0.14), acc, w * 0.5)
		"zagaia":
			# Zagaieiro: figura con el brazo atrás y la lanza arrojadiza en vuelo.
			Glyphs._figure(ci, c + Vector2(-s * 0.16, s * 0.08), s, col, 0.8)
			ci.draw_line(c + Vector2(-s * 0.02, -s * 0.06), c + Vector2(s * 0.46, -s * 0.36), acc, w * 0.7)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.48, -s * 0.38), c + Vector2(s * 0.36, -s * 0.36), c + Vector2(s * 0.42, -s * 0.28)]), acc)
		"guarnicao":
			# Guarnição da cerca: figura con lanza delante de la cerca de palos.
			for i in 5:
				ci.draw_line(c + Vector2(-s * 0.44 + i * s * 0.22, s * 0.42), c + Vector2(-s * 0.44 + i * s * 0.22, -s * 0.12), dark, w * 0.7)
			Glyphs._figure(ci, c + Vector2(0, s * 0.02), s * 0.9, col, 0.8)
			ci.draw_line(c + Vector2(s * 0.18, s * 0.34), c + Vector2(s * 0.18, -s * 0.46), acc, w * 0.6)
		"capitao":
			# Capitão de mocambo: figura con lanza y un banderín liso, con dos más chicas detrás.
			for x: float in [-0.32, 0.32]:
				Glyphs._figure(ci, c + Vector2(s * x, s * 0.16), s * 0.6, col.darkened(0.3), 0.6)
			Glyphs._figure(ci, c + Vector2(0, s * 0.06), s, col, 0.8)
			ci.draw_line(c + Vector2(s * 0.16, s * 0.3), c + Vector2(s * 0.16, -s * 0.46), dark, w * 0.6)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.16, -s * 0.46), c + Vector2(s * 0.4, -s * 0.38), c + Vector2(s * 0.16, -s * 0.3)]), acc)
		_:
			return false
	return true


static func _elipse(c: Vector2, rx: float, ry: float, rot: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts
