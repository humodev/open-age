class_name BaseLinda
extends RefCounted
## La base linda (frente 7 de fluidez, proceso/30-fluidez/08-base-linda.md). Solo vista: lee la
## simulación y nunca la toca. Números en data/arte_base.json.
##   · tierra pisada por donde más caminan los aldeanos (mapa de tránsito en el suelo);
##   · pilas de recurso junto a lo que recibe depósitos, según lo guardado ahí;
##   · granjas que cambian con el cultivo (brote, verde, espiga, maduro; barbecho sin trabajar);
##   · tocones de los árboles talados;
##   · estandartes: si cambia la opción, se rehacen los edificios;
##   · modo foto: una tecla (Opciones → Teclas, «modo_foto») oculta la interfaz.

var view: WorldView
var sim: Sim
var cfg: Dictionary
var us := 0 # tiempo acumulado (µs) en render, para medir

# Tierra pisada
var _transito := PackedInt32Array()
var _res := 0
var _ultimo := {} # id -> Vector2i (píxel del último muestreo)
var _t_pisada := 0
var _t_subir := 0.0
var _sucio := false

# Pilas
var _guardado := {} # id del depósito -> {recurso: cantidad}
var _pilas := {} # id del depósito -> {recurso: MeshInstance3D}
var _niveles := {} # id del depósito -> {recurso: nivel}
var _t_pilas := 0

# Granjas
var _cultivo := {} # id -> [MeshInstance3D, ms trabajados, etapa dibujada]
var _t_granjas := 0
var _mats := {} # color -> material

# Tocones
var _tocones: MultiMesh
var _n_tocones := 0

# Estandartes y modo foto
var _modo_banderas := ""
var _t_banderas := 0.0
var _foto := false


func setup(v: WorldView) -> void:
	view = v
	sim = v.sim
	cfg = CivMeshes.base_cfg()
	_res = sim.map.n * WorldView.SPLAT_RES
	_transito.resize(_res * _res)
	_modo_banderas = CivMeshes.banderas_modo()
	var tc: Dictionary = cfg.get("tocones", {})
	_tocones = MultiMesh.new()
	_tocones.transform_format = MultiMesh.TRANSFORM_3D
	_tocones.mesh = CivMeshes.tocon()
	_tocones.instance_count = int(tc.get("cuantos_max", 3000))
	_tocones.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _tocones
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view.add_child(mmi)


func _ms() -> int:
	return sim.tick * sim.tick_ms


# ---------------------------------------------------------------- Eventos

## Depósito de un aldeano: se suma a lo guardado en el depósito al que volvió (e.aux).
func deposito(ev: Dictionary) -> void:
	var u: SimEntity = sim.by_id.get(ev["id"])
	if u == null:
		return
	var d: SimEntity = sim.by_id.get(u.aux)
	if d == null or not d.is_building():
		return
	var res := str(ev["res"])
	var g: Dictionary = _guardado.get(d.id, {})
	g[res] = float(g.get(res, 0.0)) + float(ev["n"])
	_guardado[d.id] = g


## Árbol talado: queda el tocón donde estaba (los más viejos se reusan al llegar al tope).
func tocon(t: Transform3D) -> void:
	var i := _n_tocones % _tocones.instance_count
	var y := t.basis.get_rotation_quaternion().get_euler().y
	_tocones.set_instance_transform(i, Transform3D(Basis(Vector3.UP, y), t.origin))
	_n_tocones += 1
	_tocones.visible_instance_count = mini(_n_tocones, _tocones.instance_count)


## Edificio que se fue: se olvidan sus pilas y su cultivo.
func olvidar(id: int) -> void:
	_guardado.erase(id)
	_pilas.erase(id)
	_niveles.erase(id)
	_cultivo.erase(id)
	_ultimo.erase(id)


# ---------------------------------------------------------------- Cada cuadro

func render(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	var ms := _ms()
	var pc: Dictionary = cfg.get("pisada", {})
	var paso := int(pc.get("muestreo_ms", 250))
	if ms - _t_pisada >= paso:
		_pisar(mini(4 * paso, ms - _t_pisada) * 1.0 / paso, pc)
		_t_pisada = ms
	_t_subir += delta
	if _sucio and _t_subir * 1000.0 >= float(pc.get("subir_ms", 2000)):
		_t_subir = 0.0
		_sucio = false
		view._splat_tex.update(view._splat_img)
	var pl: Dictionary = cfg.get("pilas", {})
	if ms - _t_pilas >= int(pl.get("revisar_ms", 1000)):
		_revisar_pilas(ms - _t_pilas, pl)
		_t_pilas = ms
	var gr: Dictionary = cfg.get("granjas", {})
	if ms - _t_granjas >= int(gr.get("revisar_ms", 500)):
		_revisar_granjas(ms - _t_granjas, gr)
		_t_granjas = ms
	_t_banderas += delta
	if _t_banderas >= 0.5:
		_t_banderas = 0.0
		var m := CivMeshes.banderas_modo()
		if m != _modo_banderas:
			_modo_banderas = m
			for v: Dictionary in view.visuals.values():
				if v["kind"] == "building":
					v["look"] = "" # _render_building lo rehace con el estandarte nuevo
	us += Time.get_ticks_usec() - t0


# ---------------------------------------------------------------- Tierra pisada

## Suma tránsito en el píxel de cada aldeano visible que se movió desde el muestreo anterior.
## `k`: cuántos muestreos representa (con el juego rápido pasan varios entre cuadro y cuadro).
func _pisar(k: float, pc: Dictionary) -> void:
	var img: Image = view._splat_img
	if img == null:
		return
	var suma := int(float(pc.get("por_paso", 4)) * k)
	var vec := suma * int(pc.get("vecino_pct", 50)) / 100
	var umbral := int(pc.get("umbral", 60))
	var lleno := maxi(umbral + 1, int(pc.get("lleno", 700)))
	var fuerza := float(pc.get("fuerza_pct", 72)) / 100.0
	var sr := float(WorldView.SPLAT_RES) / WorldView.P
	for e in sim.actives:
		if not e.is_unit() or not e.def.has("tasa"):
			continue
		var px := Vector2i(int(e.x * sr), int(e.y * sr))
		var prev: Variant = _ultimo.get(e.id)
		_ultimo[e.id] = px
		if prev == null or prev == px or view.fog_state(e) != 2 or sim.map.is_water(e.x / 1000, e.y / 1000):
			continue
		for d in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = px + d
			if q.x < 0 or q.y < 0 or q.x >= _res or q.y >= _res:
				continue
			var i := q.y * _res + q.x
			var t := _transito[i] + (suma if d == Vector2i.ZERO else vec)
			_transito[i] = t
			if t <= umbral:
				continue
			var s := fuerza * minf(1.0, float(t - umbral) / float(lleno - umbral))
			var c := img.get_pixel(q.x, q.y)
			if s > c.r + 0.02:
				c.r = s
				img.set_pixel(q.x, q.y, c)
				_sucio = true


# ---------------------------------------------------------------- Pilas

func _revisar_pilas(dt: int, pl: Dictionary) -> void:
	var gasto := pow(1.0 - float(pl.get("consumo_pct_min", 20)) / 100.0, float(dt) / 60000.0)
	var niveles: Array = pl.get("niveles", [40, 150, 400, 900])
	var escalas: Array = pl.get("escala_pct", [55, 75, 92, 110])
	for id: int in _guardado.keys():
		var d: SimEntity = sim.by_id.get(id)
		var v: Dictionary = view.visuals.get(id, {})
		if d == null or not d.alive or v.is_empty():
			olvidar(id)
			continue
		var g: Dictionary = _guardado[id]
		var nv: Dictionary = _niveles.get(id, {})
		for res: String in g:
			g[res] = float(g[res]) * gasto
			var lv := 0
			for j in niveles.size():
				if float(g[res]) >= float(niveles[j]):
					lv = j + 1
			if lv == int(nv.get(res, 0)):
				continue
			nv[res] = lv
			_dibujar_pila(d, v, res, lv, escalas, pl)
		_niveles[id] = nv


## Lugar de cada recurso: a lo largo del frente (-x, -z: el lado que da a la cámara).
const ORDEN_PILAS := ["madera", "piedra", "riqueza", "alimento"]


func _dibujar_pila(d: SimEntity, v: Dictionary, res: String, lv: int, escalas: Array, pl: Dictionary) -> void:
	var ps: Dictionary = _pilas.get(d.id, {})
	var mi: MeshInstance3D = ps.get(res)
	if mi == null or not is_instance_valid(mi):
		var mesh := CivMeshes.pila(res)
		if mesh == null:
			return
		mi = MeshInstance3D.new()
		mi.mesh = mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var slot := maxi(0, ORDEN_PILAS.find(res))
		var hw := d.w / 2.0
		var hh := d.h / 2.0
		# Dos por lado: las dos primeras sobre el borde -z, las otras sobre el -x.
		var along := -0.45 + (slot % 2) * 0.9
		mi.position = Vector3(along * hw, 0.0, -hh + 0.05) if slot < 2 else Vector3(-hw + 0.05, 0.0, along * hh)
		mi.rotation.y = float((d.id * 37 + slot * 53) % 360) * PI / 180.0
		(v["node"] as Node3D).add_child(mi)
		ps[res] = mi
		_pilas[d.id] = ps
	mi.visible = lv > 0
	if lv > 0:
		var k := float(escalas[clampi(lv - 1, 0, escalas.size() - 1)]) / 100.0
		if CivMeshes._is_center(d.type, d.def):
			k *= float(pl.get("centro_pct", 80)) / 100.0
		mi.scale = Vector3.ONE * k


# ---------------------------------------------------------------- Granjas

func _revisar_granjas(dt: int, gr: Dictionary) -> void:
	var ciclo := maxi(1, int(gr.get("ciclo_s", 90)) * 1000)
	var altos: Array = gr.get("alto_pct", [25, 60, 90, 100])
	var colores: Array = gr.get("color", ["8fbf5a", "5f9a3a", "a7a845", "d1a948"])
	for id: int in view.visuals:
		var v: Dictionary = view.visuals[id]
		if v["kind"] != "building":
			continue
		var e: SimEntity = sim.by_id.get(id)
		if e == null or not e.def.has("fuente") or e.def.get("permite_ladera", false):
			continue
		var c: Array = _cultivo.get(id, [])
		if c.is_empty():
			if not e.built:
				continue
			var mi := MeshInstance3D.new()
			mi.mesh = CivMeshes.cultivo(e.w, e.h)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			(v["node"] as Node3D).add_child(mi)
			c = [mi, 0, -2]
			_cultivo[id] = c
		var f: SimEntity = sim.by_id.get(e.farmer) if e.farmer >= 0 else null
		var trabajada: bool = f != null and f.alive and f.target == e.id
		var etapa := -1
		var alto := float(gr.get("barbecho_alto_pct", 18)) / 100.0
		if trabajada:
			c[1] = int(c[1]) + dt
			var fase := float(int(c[1]) % ciclo) / float(ciclo) * altos.size()
			etapa = mini(int(fase), altos.size() - 1)
			# Crece parejo dentro de la etapa, hasta el alto de la siguiente.
			var a0 := float(altos[etapa]) / 100.0
			var a1 := float(altos[mini(etapa + 1, altos.size() - 1)]) / 100.0
			alto = 0.22 * lerpf(a0, a1, fase - etapa)
		else:
			alto *= 0.22
		var mi2: MeshInstance3D = c[0]
		mi2.scale = Vector3(1.0, maxf(0.01, alto), 1.0)
		mi2.position.y = 0.08
		if etapa != int(c[2]):
			c[2] = etapa
			mi2.material_override = _mat(str(colores[etapa]) if etapa >= 0 else str(gr.get("barbecho_color", "9a8a5a")))


func _mat(hex: String) -> StandardMaterial3D:
	if not _mats.has(hex):
		_mats[hex] = Meshes.mat(Color(hex), 0.95)
	return _mats[hex]


# ---------------------------------------------------------------- Modo foto

## Oculta o muestra la interfaz (no en el menú de inicio). Devuelve si quedó en modo foto.
func alternar_foto() -> bool:
	var main := view.get_parent()
	if main == null or bool(main.get("_menu_mode")):
		return false
	var hud: Control = main.get("hud")
	if hud == null:
		return false
	_foto = not _foto
	hud.visible = not _foto
	return _foto
