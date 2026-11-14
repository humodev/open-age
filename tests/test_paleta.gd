extends SceneTree
## Paleta apta para daltonismo (docs/diseno/interfaz/00-auditoria.md, P2 y sección 5).
##
## Mide la distancia de color ΔE (CIELAB, CIE76, la misma de la auditoría) entre
## equipos, recursos y vida, en visión normal y con deuteranopía, protanopía y
## tritanopía simuladas (matrices de Machado, Oliveira y Fernandes 2009, severidad
## total). También mide el contraste WCAG de los textos y estados de la interfaz.
##
## Umbrales (auditoría, sección 5): 20 entre equipos y 25 entre equipo y recurso.
##   godot --headless --path . -s tests/test_paleta.gd

const VISIONES := {
	"normal": [],
	"deuteranopia": [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]],
	"protanopia": [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]],
	"tritanopia": [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]],
}
const EQUIPO_EQUIPO := 20.0
const EQUIPO_RECURSO := 25.0
const RECURSO_RECURSO := 25.0
## Equipos 5 a 8: solo se miden en visión normal y en la del modo (con la segura, deuteranopía,
## la más común), con un margen algo menor: con ocho colores no alcanza el espacio para más.
const EXTRA_EQUIPO := 18.0
const EXTRA_RECURSO := 22.0
const VIDA := 40.0
const CONTRASTE_TEXTO := 4.5
## Fondo de una casilla de la grilla (panel UI_BG + 7,5 % de blanco, sobre el mapa oscuro).
const FONDO := Color("26282b")

var _fallas: Array[String] = []
var _peor := {}


func _init() -> void:
	for modo in Palette.MODOS_ORDEN:
		Palette.aplicar(modo)
		_medir_modo(modo)
	Palette.aplicar("normal")
	_medir_relativa()
	_medir_vida_y_contraste()
	print("Peor caso de cada regla (ΔE, o contraste para los textos):")
	var claves := _peor.keys()
	claves.sort()
	for k in claves:
		print("  %-52s %5.1f  (%s)" % [k, _peor[k][0], _peor[k][1]])
	for f in _fallas:
		print("FALLO ", f)
	print("PALETA: ", "OK" if _fallas.is_empty() else "FALLO (%d)" % _fallas.size())
	quit(0 if _fallas.is_empty() else 1)


func _medir_modo(modo: String) -> void:
	if modo == "relativa":
		return
	var propia := "deuteranopia" if modo == "normal" else modo
	var res: Array = Palette.RES.values()
	var t := Palette.TEAM
	for i in t.size():
		for j in range(i + 1, t.size()):
			if j < 4:
				_exigir("%s: equipos 1-4 entre sí" % modo, t[i], t[j], VISIONES.keys(), EQUIPO_EQUIPO)
			else:
				_exigir("%s: equipos 5-8 entre sí" % modo, t[i], t[j], ["normal", propia], EXTRA_EQUIPO)
		for r in res:
			if i < 4:
				_exigir("%s: equipos 1-4 contra recursos" % modo, t[i], r, VISIONES.keys(), EQUIPO_RECURSO)
			else:
				_exigir("%s: equipos 5-8 contra recursos" % modo, t[i], r, ["normal", propia], EXTRA_RECURSO)
	for i in res.size():
		for j in range(i + 1, res.size()):
			_exigir("recursos entre sí", res[i], res[j], VISIONES.keys(), RECURSO_RECURSO)


func _medir_relativa() -> void:
	var c: Array = Palette.RELATIVA.values()
	for i in c.size():
		for j in range(i + 1, c.size()):
			_exigir("relativa: yo, aliados y rivales", c[i], c[j], VISIONES.keys(), EQUIPO_EQUIPO)
		for r in Palette.RES.values():
			_exigir("relativa: contra recursos", c[i], r, VISIONES.keys(), EQUIPO_RECURSO)


func _medir_vida_y_contraste() -> void:
	_exigir("vida buena contra vida mala", Palette.UI_GOOD, Palette.UI_BAD, VISIONES.keys(), VIDA)
	for par in [["texto", Palette.UI_TEXT], ["texto atenuado", Palette.UI_DIM], ["no alcanza / malo", Palette.UI_BAD], ["bueno", Palette.UI_GOOD], ["acento", Palette.UI_ACCENT]]:
		var k := contraste(par[1], FONDO)
		var nombre := "contraste WCAG de %s sobre la casilla" % par[0]
		_peor[nombre] = [k, "%.2f:1" % k]
		if k < CONTRASTE_TEXTO:
			_fallas.append("%s: %.2f:1 (mínimo %.1f)" % [nombre, k, CONTRASTE_TEXTO])


func _exigir(regla: String, a: Color, b: Color, visiones: Array, minimo: float) -> void:
	for v in visiones:
		var d := delta_e(a, b, v)
		if not _peor.has(regla) or d < _peor[regla][0]:
			_peor[regla] = [d, "%s / %s en %s" % [a.to_html(false), b.to_html(false), v]]
		if d < minimo:
			_fallas.append("%s: %s y %s a ΔE %.1f en %s (mínimo %.0f)" % [regla, a.to_html(false), b.to_html(false), d, v, minimo])


# ---------------------------------------------------------------- Color

static func _lineal(c: float) -> float:
	return c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4)


static func simular(c: Color, vision: String) -> Vector3:
	var v := Vector3(_lineal(c.r), _lineal(c.g), _lineal(c.b))
	var m: Array = VISIONES[vision]
	if m.is_empty():
		return v
	var o := Vector3.ZERO
	for i in 3:
		var row: Array = m[i]
		o[i] = clampf(row[0] * v.x + row[1] * v.y + row[2] * v.z, 0.0, 1.0)
	return o


static func lab(rgb: Vector3) -> Vector3:
	var x := (0.4124 * rgb.x + 0.3576 * rgb.y + 0.1805 * rgb.z) / 0.95047
	var y := 0.2126 * rgb.x + 0.7152 * rgb.y + 0.0722 * rgb.z
	var z := (0.0193 * rgb.x + 0.1192 * rgb.y + 0.9505 * rgb.z) / 1.08883
	var f := func(t: float) -> float: return pow(t, 1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0
	var fx: float = f.call(x)
	var fy: float = f.call(y)
	var fz: float = f.call(z)
	return Vector3(116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz))


static func delta_e(a: Color, b: Color, vision: String) -> float:
	return lab(simular(a, vision)).distance_to(lab(simular(b, vision)))


static func luminancia(c: Color) -> float:
	return 0.2126 * _lineal(c.r) + 0.7152 * _lineal(c.g) + 0.0722 * _lineal(c.b)


static func contraste(a: Color, b: Color) -> float:
	var la := luminancia(a)
	var lb := luminancia(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)
