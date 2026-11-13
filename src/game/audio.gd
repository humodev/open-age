class_name GameAudio
extends Node
## Sonido del juego con audio CC0 (assets/CREDITOS.md). Escucha los eventos de la simulación;
## el volumen del mundo baja con la distancia a la cámara.

const BASE := "res://assets/audio/"
const UI := {
	"clic": ["ui/ui_clic.ogg"],
	"error": ["ui/ui_error.ogg"],
	"edad": ["ui/ui_aviso_edad.ogg"],
	"tech": ["ui/ui_investigacion_terminada.ogg"],
	"objetivo": ["ui/ui_investigacion_terminada_2.ogg"],
	"alerta": ["ui/ui_alerta_ataque.ogg"],
	"campana": ["ui/ui_campana.ogg"],
}
const WORLD := {
	"golpe": ["mundo/mundo_golpe_cuerpo_1.ogg", "mundo/mundo_golpe_cuerpo_2.ogg", "mundo/mundo_golpe_escudo.ogg"],
	"arco": ["mundo/mundo_arco_disparo_1.ogg", "mundo/mundo_arco_disparo_2.ogg"],
	"honda": ["mundo/mundo_honda_disparo.ogg"],
	"impacto": ["mundo/mundo_impacto_1.ogg", "mundo/mundo_impacto_2.ogg", "mundo/mundo_impacto_3.ogg"],
	"muerte": ["mundo/mundo_muerte_1.ogg", "mundo/mundo_muerte_2.ogg", "mundo/mundo_muerte_3.ogg"],
	"derrumbe": ["mundo/mundo_edificio_destruido.ogg"],
	"dano_edificio": ["mundo/mundo_edificio_dano.ogg"],
	"terminado": ["mundo/mundo_edificio_terminado.ogg"],
	"ariete": ["mundo/mundo_ariete_1.ogg", "mundo/mundo_ariete_2.ogg"],
	"hacha": ["mundo/mundo_hacha_1.ogg", "mundo/mundo_hacha_2.ogg", "mundo/mundo_hacha_3.ogg"],
	"pico": ["mundo/mundo_pico_1.ogg", "mundo/mundo_pico_2.ogg", "mundo/mundo_pico_3.ogg", "mundo/mundo_pico_4.ogg"],
	"arbusto": ["mundo/mundo_arbusto_1.ogg", "mundo/mundo_arbusto_2.ogg"],
	"martillo": ["mundo/mundo_martillo_1.ogg", "mundo/mundo_martillo_2.ogg", "mundo/mundo_martillo_3.ogg"],
}
const MUSIC := {
	"menu": "musica/musica_flauta_de_pan.ogg",
	"paz": ["musica/musica_tribal.ogg", "musica/musica_krakatoa_loop.ogg"],
	"combate": "musica/musica_marcha_batalla.ogg",
}

var sim: Sim
var cam: RtsCamera
var local := 0
var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _ambient: AudioStreamPlayer
var _mood := ""
var _combat_until := 0.0
var _clock := 0.0
var _work_t := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	for i in 20:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -12.0
	add_child(_music)
	_music.finished.connect(func() -> void: _play_music(_mood, true))
	_ambient = AudioStreamPlayer.new()
	_ambient.volume_db = -20.0
	add_child(_ambient)
	_ambient.finished.connect(func() -> void: _ambient.play())


func _stream(path: String) -> AudioStream:
	if not _streams.has(path):
		_streams[path] = load(BASE + path) if ResourceLoader.exists(BASE + path) else null
	return _streams[path]


func _play(path: String, db: float, pitch: float = 1.0) -> void:
	var s := _stream(path)
	if s == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = s
	p.volume_db = db
	p.pitch_scale = pitch
	p.play()


func ui(kind: String, db: float = -6.0) -> void:
	var list: Array = UI.get(kind, [])
	if not list.is_empty():
		_play(list[_rng.randi() % list.size()], db)


## Sonido del mundo en (x, y) de la simulación; se apaga lejos de la cámara.
func world(kind: String, x: int, y: int, db: float = -8.0) -> void:
	if cam == null:
		return
	var d := Vector2(x / 1000.0, y / 1000.0).distance_to(Vector2(cam.focus.x, cam.focus.z))
	var reach := cam.zoom * 0.9
	if d > reach:
		return
	var list: Array = WORLD.get(kind, [])
	if list.is_empty():
		return
	_play(list[_rng.randi() % list.size()], db - d / reach * 14.0, _rng.randf_range(0.92, 1.08))


func music(mood: String) -> void:
	if mood != _mood:
		_mood = mood
		_play_music(mood, false)


func _play_music(mood: String, _again: bool) -> void:
	var entry: Variant = MUSIC.get(mood, "")
	var path: String = entry if entry is String else (entry as Array)[_rng.randi() % (entry as Array).size()]
	var s := _stream(path)
	if s == null:
		return
	_music.stream = s
	_music.play()


func ambient(on: bool) -> void:
	if on and not _ambient.playing:
		_ambient.stream = _stream("ambiente/ambiente_pajaros_loop.ogg")
		_ambient.play()
	elif not on:
		_ambient.stop()


func on_events(events: Array) -> void:
	if sim == null:
		return
	for ev in events:
		var pid: int = ev.get("player", -2)
		match ev["t"]:
			"hit":
				var a: SimEntity = sim.by_id.get(ev["a"])
				var b: SimEntity = sim.by_id.get(ev["b"])
				if a == null or b == null:
					continue
				if ev["ranged"]:
					world("arco" if a.is_building() or a.def.get("funcion", "") == "distancia" and not a.type.contains("hond") else "honda", a.x, a.y, -14.0)
					world("impacto", b.x, b.y, -16.0)
				elif a.def.get("solo_edificios", false):
					world("ariete", b.x, b.y, -6.0)
				else:
					world("golpe", b.x, b.y, -12.0)
				if b.is_building() and _rng.randf() < 0.15:
					world("dano_edificio", b.x, b.y, -14.0)
				if a.owner == local or b.owner == local:
					_combat_until = _clock + 12.0
			"died":
				if ev.get("cat", -1) == SimEntity.Cat.BUILDING:
					world("derrumbe", ev["x"], ev["y"], -2.0)
				elif ev.get("cat", -1) == SimEntity.Cat.UNIT:
					world("muerte", ev["x"], ev["y"], -12.0)
			"built":
				var e: SimEntity = sim.by_id.get(ev["id"])
				if e != null and e.owner == local:
					world("terminado", e.x, e.y, -6.0)
			"age":
				ui("edad", -4.0 if pid == local else -14.0)
			"tech":
				if pid == local:
					ui("tech")
			"alert":
				if pid == local:
					ui("alerta", -8.0)
					_combat_until = _clock + 20.0
			"alarm":
				if pid == local:
					ui("campana", -4.0)
			"notify":
				if pid == local and String(ev.get("msg", "")).begins_with("Recursos"):
					ui("error", -10.0)
			"objetivo":
				ui("objetivo", -6.0)
			"mision":
				ui("edad", -2.0)


## Ruido de trabajo: aldeanos cerca de la cámara talando, picando, recolectando o construyendo.
func _process(delta: float) -> void:
	_clock += delta
	if sim == null:
		return
	if _mood != "menu":
		music("combate" if _clock < _combat_until else "paz")
	_work_t -= delta
	if _work_t > 0.0:
		return
	_work_t = 0.35
	var tries := 0
	for e in sim.actives:
		if tries >= 2:
			break
		if e.owner != local or not e.anchored or e.fn != "civil" or _rng.randf() > 0.08:
			continue
		var kind := ""
		if e.order == SimEntity.Order.BUILD:
			kind = "martillo"
		elif e.order == SimEntity.Order.GATHER:
			kind = {"madera": "hacha", "piedra": "pico", "riqueza": "pico", "alimento": "arbusto"}.get(e.gather_kind, "")
		if kind != "":
			world(kind, e.x, e.y, -16.0)
			tries += 1
