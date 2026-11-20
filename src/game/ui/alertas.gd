extends Control
## --- fluidez 4 --- Avisos de ataque por zona y por tipo, recursos que se agotan y granjas
## vacías (proceso/30-fluidez/04-avisos-y-equipo.md). Solo la interfaz: lee los sucesos y el
## estado de la simulación, y manda comandos comunes (el de juntar para llenar granjas).
##
## - Ataque: cada golpe a algo propio o de un aliado se clasifica (aldeanos, tropa, edificio,
##   aliado) y se agrupa en zonas de `zona_casillas`. Una zona y un tipo avisan una vez cada
##   `repetir_zona_s`; otra zona avisa enseguida. El freno de 15 s de la simulación ("alert")
##   queda solo para los escenarios que avisan sin golpe.
## - Recursos: lo que trabajan tus aldeanos se sigue; avisa cuando lo que queda cerca baja del
##   umbral del recurso y cuando se acaba sin otro igual a mano.
## - Granjas: las terminadas sin granjero hace `granja_espera_s` se marcan en el mundo y el botón
##   «Llenar granjas» manda aldeanos ociosos (o los más cercanos) a ellas.
## Todo se ajusta en data/interfaz.json → "alertas" y los sonidos en data/respuesta.json.

const P := 1000
const O := SimEntity.Order
const TEXTO := {
	"aldeanos": "Atacan a tus aldeanos",
	"tropa": "Atacan a tu tropa",
	"edificio": "Atacan tu %s",
	"aliado": "Atacan a %s",
	"comerciantes": "Atacan a tus comerciantes", # --- comercio ---
}

var hud: Hud
var sim: Sim
var local: int
var cfg: Dictionary = {}
var boton: Button
var _clock := 0.0
var _zonas := {} # tipo -> Array de {z: Vector2i, t: reloj}
var _ultimo_ataque := -99.0
var _scan := 0.0
var _seguidos := {} # id de recurso -> {x, y, kind, t}
var _avisado_veta := {} # "kind:zx:zy" -> {"nivel": "poco"|"agotado", "t"}
var _vacia_desde := {} # id de granja -> reloj desde que está sin granjero
var vacias: Array[SimEntity] = [] # granjas marcadas (más de granja_espera_s sin granjero)
var conteo := {} # para el autotest: clave del aviso -> veces
var ultimo_recurso := {} # el último aviso de recurso: {texto, lugar} (autotest)
var avisos_recurso: Array[Dictionary] = [] # los últimos, para revisar a cuál se refiere cada uno


func setup(h: Hud) -> void:
	hud = h
	sim = h.sim
	local = h.local
	var path := "res://data/interfaz.json"
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
	cfg = all.get("alertas", {})
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	boton = Button.new()
	boton.focus_mode = Control.FOCUS_NONE
	boton.add_theme_font_size_override("font_size", Hud.ts(13))
	boton.tooltip_text = "Manda aldeanos ociosos (o los más cercanos) a las granjas vacías"
	boton.visible = false
	boton.pressed.connect(llenar_granjas)
	h.add_child(boton)
	h._blockers.append(boton)


func activo() -> bool:
	return bool(cfg.get("activo", true))


func _audio() -> GameAudio:
	var m: Node = hud.get("main")
	return m.get("audio") as GameAudio if m != null else null


func _sonar(tipo: String, path: String) -> void:
	var a := _audio()
	if a != null:
		a.respuesta_ui(tipo, path)


func _contar(k: String) -> void:
	conteo[k] = int(conteo.get(k, 0)) + 1


# ------------------------------------------------------------------ ataques

## Tipo de aviso del golpe a `b`, o "" si no es para el jugador local.
func tipo_de(b: SimEntity) -> String:
	if b == null or b.owner < 0:
		return ""
	if b.owner == local:
		if b.is_building():
			return "edificio"
		if b.def.get("comerciante", false): # --- comercio --- uno por ruta (atacado_comerciante)
			return "comerciantes"
		return "tropa" if b.is_military() else "aldeanos"
	if not sim.enemies(local, b.owner) and not sim.players[b.owner]["defeated"]:
		return "aliado" if bool(cfg.get("avisar_aliado", true)) else ""
	return ""


func on_events(events: Array) -> void:
	if not activo():
		return
	for ev in events:
		if ev["t"] == "ruta_cortada": # --- comercio ---
			ruta_cortada(ev)
			continue
		if ev["t"] != "hit":
			continue
		var b: SimEntity = sim.by_id.get(ev["b"])
		var tipo := tipo_de(b)
		if tipo == "":
			continue
		var a: SimEntity = sim.by_id.get(ev["a"])
		if a != null and a.owner >= 0 and not sim.enemies(b.owner, a.owner):
			continue
		atacado(tipo, b)


# --- comercio --- (proceso/33-comercio, §4) avisos de las rutas, con lugar y Espacio
var _rutas := {} # id del mercado destino -> reloj del último «Atacan a tus comerciantes»


## Un comerciante golpeado: un aviso por ruta (mercado destino) cada reglas.comercio.aviso_ms.
func atacado_comerciante(b: SimEntity) -> bool:
	var rep := float(int(sim.comercio.cfg.get("aviso_ms", 30000))) / 1000.0
	var key := b.trade_dest
	if _clock - float(_rutas.get(key, -1000.0)) < rep:
		return false
	_rutas[key] = _clock
	var dest: SimEntity = sim.by_id.get(b.trade_dest)
	var txt: String = TEXTO["comerciantes"]
	txt += " · " + (("en la ruta a %s" % _nombre_mercado(dest)) if dest != null else _donde(b))
	hud.notify(txt, -1.0, "ataque", WorldView.to_world(b.x, b.y))
	if hud._mini != null:
		hud._mini.ping(b.x, b.y)
	_sonar("alerta_aldeanos", "ui/ui_alerta_aldeanos.ogg")
	_ultimo_ataque = _clock
	_contar("ataque_comerciantes")
	return true


## «Ruta cortada» (suceso de la simulación, una vez hasta que se reabra), con lugar.
func ruta_cortada(ev: Dictionary) -> void:
	if int(ev.get("player", -1)) != local:
		return
	var dest: SimEntity = sim.by_id.get(int(ev.get("dest", -1)))
	# --- esport 2b --- uno por ruta cada reglas.comercio.aviso_ms, aunque se corte y se libere seguido
	var rep := float(int(sim.comercio.cfg.get("aviso_ms", 30000))) / 1000.0
	var key := "corte:%d" % int(ev.get("dest", -1))
	if _clock - float(_rutas.get(key, -1000.0)) < rep:
		return
	_rutas[key] = _clock
	var mot := str(ev.get("motivo", ""))
	var why := "mercado tomado" if mot == "tomado" else ("tropa enemiga en el camino; tus comerciantes esperan" if mot == "ruta" else "camino cerrado")
	if mot == "tomado":
		why += "; tus comerciantes esperan"
	var txt := "Ruta a %s cortada (%s)" % [_nombre_mercado(dest), why]
	hud.notify(txt, -1.0, "ataque", WorldView.to_world(int(ev["x"]), int(ev["y"])))
	if hud._mini != null:
		hud._mini.ping(int(ev["x"]), int(ev["y"]))
	_sonar("alerta_edificio", "ui/ui_alerta_edificio.ogg")
	_ultimo_ataque = _clock
	_contar("ruta_cortada")


func _nombre_mercado(m: SimEntity) -> String:
	if m == null:
		return "la ruta"
	var nm := String(m.def.get("nombre", "mercado"))
	if m.def.get("mercado_neutral", false):
		nm = String(((sim.terrain_def().get("neutral", {}) as Dictionary)).get("nombre", nm))
		return "la %s" % nm.to_lower() if not nm.begins_with("Puerto") else "el %s" % nm.to_lower()
	return "el mercado de %s" % Palette.team_name(m.owner) if m.owner != local else "tu %s" % nm.to_lower()
# --- fin comercio ---


## Un golpe de tipo `tipo` a `b`: avisa si su zona (o una vecina) no avisó hace poco.
func atacado(tipo: String, b: SimEntity) -> bool:
	if tipo == "comerciantes":
		return atacado_comerciante(b)
	var zc := maxi(1, int(cfg.get("zona_casillas", 12)))
	var z := Vector2i(b.x / P / zc, b.y / P / zc)
	var rep := float(cfg.get("repetir_zona_s", 20.0))
	var lista: Array = _zonas.get_or_add(tipo, [])
	for r in lista:
		var rz: Vector2i = r["z"]
		if absi(rz.x - z.x) <= 1 and absi(rz.y - z.y) <= 1 and _clock - float(r["t"]) < rep:
			return false
	lista.append({"z": z, "t": _clock})
	while lista.size() > 16:
		lista.pop_front()
	var txt: String = TEXTO[tipo]
	match tipo:
		"edificio":
			txt = txt % String(b.def.get("nombre", "edificio")).to_lower()
		"aliado":
			txt = txt % Palette.team_name(b.owner)
		"aldeanos":
			if b.gather_kind != "":
				txt += " (%s)" % Palette.RES_NAMES.get(b.gather_kind, b.gather_kind).to_lower()
	txt += " · " + _donde(b)
	hud.notify(txt, -1.0, "ataque", WorldView.to_world(b.x, b.y))
	if hud._mini != null:
		hud._mini.ping(b.x, b.y)
	_sonar("alerta_" + tipo, "ui/ui_alerta_%s.ogg" % tipo)
	_ultimo_ataque = _clock
	_contar("ataque_" + tipo)
	return true


## Dónde: junto al edificio propio (o del aliado) más cercano, o «lejos de la base».
func _donde(b: SimEntity) -> String:
	var best: SimEntity = null
	var bd := int(cfg.get("cerca_casillas", 14)) * P
	for e in sim.actives:
		if e == b or not e.is_building() or e.owner != b.owner or not e.built:
			continue
		var d := Sim.dist(e.x, e.y, b.x, b.y)
		if d < bd:
			bd = d
			best = e
	if best == null:
		return "lejos de la base"
	return "junto a %s" % String(best.def.get("nombre", "un edificio")).to_lower()


## Suceso "alert" de la simulación (freno de 15 s): con las alertas por zona, solo avisa si
## no hubo una propia hace poco (los escenarios avisan sin golpe). Devuelve true si lo tapó; si
## no, suena la alarma de siempre (audio.gd la calla cuando las alertas están prendidas).
func cubre_alert(ev: Dictionary) -> bool:
	if not activo():
		return false
	# --- ronda 8 --- el «Atacan a tu aliado» de la simulación repetía las alertas por zona del aliado
	if int(ev.get("player", -2)) != local and bool(cfg.get("avisar_aliado", true)):
		return true
	if _clock - _ultimo_ataque < float(cfg.get("alert_tapa_s", 3.0)):
		return true
	var a := _audio()
	if a != null and int(ev.get("player", -2)) == local and not a.civ_sfx("alarma"):
		a.ui("alerta", -8.0)
	return false


# ------------------------------------------------------------------ recursos y granjas

func _process(delta: float) -> void:
	_clock += delta
	if not activo():
		return
	_scan -= delta
	if _scan <= 0.0:
		_scan = float(cfg.get("revisar_s", 1.0))
		revisar()
	queue_redraw()


func revisar() -> void:
	_seguir_recursos()
	_granjas()


func _seguir_recursos() -> void:
	var umbral: Dictionary = cfg.get("umbral_recurso", {})
	for e in sim.actives:
		if e.owner != local or e.fn != "civil" or not (e.order == O.GATHER or e.order == O.RETURN):
			continue
		var t: SimEntity = sim.by_id.get(e.target)
		if t != null and t.alive and t.is_resource() and umbral.has(t.res_kind) and not t.def.has("reabre"):
			_seguidos[t.id] = {"x": t.x, "y": t.y, "kind": t.res_kind, "t": _clock}
	var olvido := float(cfg.get("olvidar_s", 30.0))
	for id in _seguidos.keys():
		var s: Dictionary = _seguidos[id]
		var t: SimEntity = sim.by_id.get(id)
		var vivo := t != null and t.alive and t.amount > 0
		var queda := _queda(s["kind"], int(s["x"]), int(s["y"]))
		var zc := maxi(1, int(cfg.get("zona_casillas", 12)))
		var clave := "%s:%d:%d" % [s["kind"], int(s["x"]) / P / zc, int(s["y"]) / P / zc]
		var prev: Dictionary = _avisado_veta.get(clave, {})
		if queda <= 0:
			if prev.get("nivel", "") != "agotado":
				_avisado_veta[clave] = {"nivel": "agotado", "t": _clock}
				_aviso_recurso("Se acabó %s acá: buscá otra" % _nombre(s["kind"]), s)
			_seguidos.erase(id)
			continue
		if queda <= int(umbral[s["kind"]]) and prev.is_empty():
			_avisado_veta[clave] = {"nivel": "poco", "t": _clock}
			_aviso_recurso("Se agota %s (quedan %d)" % [_nombre(s["kind"]), queda], s)
		if not vivo or _clock - float(s["t"]) > olvido:
			_seguidos.erase(id)


func _nombre(kind: String) -> String:
	match kind:
		"madera":
			return "el bosque"
		"piedra":
			return "la veta de piedra"
		"riqueza":
			return "la veta de riqueza"
		"alimento":
			return "el alimento"
	return Palette.RES_NAMES.get(kind, kind).to_lower()


## Lo que queda de `kind` a unas `radio_casillas` del lugar. Se suma por celdas de CELDA casillas,
## armadas una vez por revisión (recorrer todos los recursos por cada uno seguido traba).
const CELDA := 3
var _celdas := {} # Vector3i(kind, cx, cy) -> cantidad
var _celdas_t := -1.0


func _queda(kind: String, x: int, y: int) -> int:
	var kinds := ["alimento", "madera", "piedra", "riqueza"]
	if _celdas_t != _clock:
		_celdas_t = _clock
		_celdas.clear()
		for e in sim.entities:
			if e.alive and e.is_resource() and e.amount > 0 and kinds.has(e.res_kind):
				var k := Vector3i(kinds.find(e.res_kind), e.x / P / CELDA, e.y / P / CELDA)
				_celdas[k] = int(_celdas.get(k, 0)) + e.amount
	var ki := kinds.find(kind)
	var rc := maxi(1, int(cfg.get("radio_casillas", 6)) / CELDA)
	var cx := x / P / CELDA
	var cy := y / P / CELDA
	var n := 0
	for dy in range(-rc, rc + 1):
		for dx in range(-rc, rc + 1):
			n += int(_celdas.get(Vector3i(ki, cx + dx, cy + dy), 0))
	return n


func _aviso_recurso(txt: String, s: Dictionary) -> void:
	ultimo_recurso = {"texto": txt, "lugar": WorldView.to_world(int(s["x"]), int(s["y"]))}
	avisos_recurso.push_back(ultimo_recurso)
	if avisos_recurso.size() > 16:
		avisos_recurso.pop_front()
	if Opciones.consejos: # --- ronda 8 --- de gestión: solo para aprender
		hud.notify(txt, -1.0, "decision", ultimo_recurso["lugar"])
		_sonar("aviso_recurso", "ui/ui_aviso_recurso.ogg")
	_contar("recurso")


func _farm_libre(f: SimEntity) -> bool:
	if f.farmer < 0:
		return true
	var w: SimEntity = sim.by_id.get(f.farmer)
	return w == null or not w.alive or w.target != f.id or not (w.order == O.GATHER or w.order == O.RETURN)


func _granjas() -> void:
	var espera := float(cfg.get("granja_espera_s", 4.0))
	var antes := vacias.size()
	var nuevas := 0
	vacias.clear()
	var vistas := {}
	for e in sim.actives:
		if e.owner != local or not e.is_building() or not e.built or String(e.def.get("fuente", "")) == "":
			continue
		if not _farm_libre(e):
			continue
		vistas[e.id] = true
		var desde := float(_vacia_desde.get_or_add(e.id, _clock))
		if _clock - desde >= espera:
			vacias.append(e)
			if _clock - desde < espera + float(cfg.get("revisar_s", 1.0)):
				nuevas += 1
	for id in _vacia_desde.keys():
		if not vistas.has(id):
			_vacia_desde.erase(id)
	if nuevas > 0 and vacias.size() > antes:
		var f := vacias[-1]
		if Opciones.consejos: # --- ronda 8 --- la marca en el mundo y el botón quedan siempre
			hud.notify("Granja vacía" if vacias.size() == 1 else "%d granjas vacías" % vacias.size(), -1.0, "decision", WorldView.to_world(f.x, f.y))
			_sonar("aviso_granja", "ui/ui_aviso_granja.ogg")
		_contar("granja")
	boton.visible = not vacias.is_empty()
	if boton.visible:
		boton.text = "Llenar granjas (%d)" % vacias.size()
		var m: Control = hud._mini
		boton.reset_size()
		boton.position = Vector2(m.position.x, m.position.y - boton.size.y - 6)


## Manda un aldeano a cada granja vacía: primero los ociosos, después los más cercanos que
## juntan alimento fuera de una granja y, si faltan, cualquiera que trabaje. Devuelve cuántos.
func llenar_granjas() -> int:
	if vacias.is_empty():
		revisar()
	var libres: Array[SimEntity] = []
	var otros: Array[SimEntity] = []
	for e in sim.actives:
		if e.owner != local or e.fn != "civil" or e.inside >= 0 or not e.alive:
			continue
		if e.order == O.IDLE:
			libres.append(e)
		elif e.order == O.GATHER or e.order == O.RETURN:
			var t: SimEntity = sim.by_id.get(e.target)
			if t != null and t.is_building():
				continue # ya está en una granja
			otros.append(e)
	var n := 0
	for f in vacias:
		var pool := libres if not libres.is_empty() else otros
		if pool.is_empty():
			break
		if pool == otros and bool(cfg.get("llenar_prefiere_alimento", true)):
			pool.sort_custom(func(a: SimEntity, b: SimEntity) -> bool:
				return (0 if a.gather_kind == "alimento" else 1) * 1000000000 + Sim.dist(a.x, a.y, f.x, f.y) < (0 if b.gather_kind == "alimento" else 1) * 1000000000 + Sim.dist(b.x, b.y, f.x, f.y))
		else:
			pool.sort_custom(func(a: SimEntity, b: SimEntity) -> bool: return Sim.dist(a.x, a.y, f.x, f.y) < Sim.dist(b.x, b.y, f.x, f.y))
		var v: SimEntity = pool.pop_front()
		sim.push_command({"t": "target", "player": local, "ids": [v.id], "target": f.id})
		_vacia_desde.erase(f.id)
		n += 1
	if n > 0:
		hud.notify("%d %s a las granjas" % [n, "aldeano" if n == 1 else "aldeanos"], -1.0, "info")
		vacias.clear()
		boton.visible = false
	else:
		hud.notify("No hay aldeanos para las granjas", -1.0, "decision")
	return n


func _draw() -> void:
	if vacias.is_empty() or not bool(cfg.get("marcar_granjas", true)):
		return
	var cam: Camera3D = hud.cam.cam
	var pulso := 0.5 + 0.5 * sin(_clock * 4.0)
	for f in vacias:
		if not f.alive:
			continue
		var wp := WorldView.to_world(f.x, f.y)
		wp.y = WorldView.height_at(wp.x, wp.z) + 1.2
		if cam.is_position_behind(wp):
			continue
		var sp := cam.unproject_position(wp)
		if not get_viewport_rect().grow(30).has_point(sp):
			continue
		draw_circle(sp, 17.0, Color(0, 0, 0, 0.55))
		draw_arc(sp, 17.0 + pulso * 3.0, 0, TAU, 24, Color(Palette.UI_ACCENT, 0.5 + 0.5 * pulso), 2.5, true)
		Glyphs.draw(self, "granja", Rect2(sp - Vector2(11, 11), Vector2(22, 22)), Palette.UI_ACCENT)
		draw_string(Hud.font_b, sp + Vector2(-30, -24), "vacía", HORIZONTAL_ALIGNMENT_CENTER, 60, Hud.ts(12), Palette.UI_TEXT)
