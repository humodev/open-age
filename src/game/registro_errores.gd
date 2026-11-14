class_name RegistroErrores
extends Logger
## Los SCRIPT ERROR del juego van a la telemetría (proceso/20): así un error que se repite
## aparece en el informe aunque nadie mire la consola (la ayuda de recursos tiró el juego
## así). Godot puede llamar desde otros hilos: se encola y main.gd lo vuelca cada cuadro.

var _mutex := Mutex.new()
var _pending: Array = []


func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _bt: Array[ScriptBacktrace]) -> void:
	if error_type != ERROR_TYPE_SCRIPT and error_type != ERROR_TYPE_ERROR:
		return
	_mutex.lock()
	if _pending.size() < 200:
		_pending.append({"lugar": "%s:%d" % [file, line], "funcion": function, "msg": (rationale if rationale != "" else code).left(160)})
	_mutex.unlock()


## Pasa lo encolado a la telemetría de la partida (una vez por lugar cada minuto de juego).
func flush(sim: Sim) -> void:
	_mutex.lock()
	var items := _pending
	_pending = []
	_mutex.unlock()
	if sim == null:
		return
	for it in items:
		sim.tele.add(sim.tick, "error_script", -1, -1, -1, it, "es:" + str(it["lugar"]), 600)
