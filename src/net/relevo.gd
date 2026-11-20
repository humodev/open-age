class_name RedRelevo
extends RedTransporte
## --- relevo --- (proceso/37-red/04) El mismo transporte que RedTransporte, pero por un relevo:
## los dos se conectan por TCP hacia afuera (server/relevo.py), así nadie abre puertos.
## crear() pide una sala y recibe un código de 6 letras; unirse() entra con `codigo`.
## Los mensajes son los mismos diccionarios (var_to_bytes); el relevo los reenvía sin mirarlos.
##
## Marco: [u32 big endian: largo][u8 tipo][carga]. Tipos en server/relevo.py.
## Si se corta la conexión con el relevo, se reintenta solo con el código y la llave del lugar
## (anfitrión y en sala); el invitado en partida reintenta desde la sesión, como con ENet.

signal codigo_listo(codigo: String)
signal fallo(texto: String)

const HOLA := 1
const RESP := 2
const DATOS := 3
const DENTRO := 4
const FUERA := 5
const VIVO := 6

var servidor := "127.0.0.1"
var puerto := 47900
var codigo := "" # la sala (la da el relevo al crear; se escribe para unirse)
var llave := "" # para recuperar el lugar si el relevo no notó el corte
var error_relevo := "" # el último rechazo del relevo
var latido_ms := 5000
var reintento_ms := 2000
var _tcp: StreamPeerTCP = null
var _op := "" # crear o unirse
var _admitido := false
var _par := false
var _buf := PackedByteArray()
var _prox_latido := 0
var _prox_reintento := 0
var _hola_mandado := false

static var _version := ""


## Versión del juego para el relevo: la del proyecto, la de Godot y un hash de data/.
## Dos clientes con data/ distintos no entran en la misma sala.
static func version() -> String:
	if _version != "":
		return _version
	var archivos: Array[String] = []
	_listar("res://data", archivos)
	archivos.sort()
	var h := HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	for f in archivos:
		h.update(f.to_utf8_buffer())
		h.update(FileAccess.get_file_as_bytes(f))
	var v := Engine.get_version_info()
	_version = "%s-godot%d.%d-%s" % [str(ProjectSettings.get_setting("application/config/version", "0")), int(v["major"]), int(v["minor"]), h.finish().hex_encode().substr(0, 16)]
	return _version


static func _listar(dir: String, out: Array[String]) -> void:
	for d in DirAccess.get_directories_at(dir):
		_listar(dir.path_join(d), out)
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".json"):
			out.append(dir.path_join(f))


## Pide una sala nueva (o vuelve a la propia si ya tiene código y llave). El puerto no se usa.
func crear(_puerto: int) -> Error:
	return _abrir("crear")


## Entra a la sala `codigo`. Los argumentos (los de ENet) no se usan: el relevo es `servidor`.
func unirse(_ip: String, _puerto: int) -> Error:
	return _abrir("unirse")


func _abrir(op: String) -> Error:
	_cortar()
	_op = op
	anfitrion = op == "crear"
	error_relevo = ""
	if op == "unirse" and codigo.length() == 0:
		return ERR_INVALID_PARAMETER
	_tcp = StreamPeerTCP.new()
	var err := _tcp.connect_to_host(servidor, puerto)
	if err != OK:
		_tcp = null
		return err
	_tcp.set_no_delay(true)
	_prox_reintento = Time.get_ticks_msec() + reintento_ms
	return OK


func activo() -> bool:
	return _tcp != null or _op != ""


func conectado_ahora() -> bool:
	return _tcp != null and _admitido and _par


func cerrar() -> void:
	_par = false # cerrar a propósito no avisa (como ENet)
	_cortar()
	_op = ""
	_cola.clear()


func _cortar() -> void:
	if _tcp != null:
		_tcp.disconnect_from_host()
	_tcp = null
	_buf.clear()
	_admitido = false
	_hola_mandado = false
	if _par:
		_par = false
		desconectado.emit(1 if not anfitrion else 2)


func poll() -> Array:
	var out: Array = []
	if _tcp == null:
		# El anfitrión (siempre) y el invitado en la sala vuelven solos; el invitado en partida
		# lo hace desde la sesión con unirse().
		if _op == "crear" and codigo != "" and error_relevo == "" and Time.get_ticks_msec() >= _prox_reintento:
			_abrir(_op)
		return out
	var ahora := Time.get_ticks_msec()
	_tcp.poll()
	var st := _tcp.get_status()
	if st == StreamPeerTCP.STATUS_CONNECTING:
		return out
	if st != StreamPeerTCP.STATUS_CONNECTED:
		_perdido()
		return out
	if not _hola_mandado:
		_hola_mandado = true
		var h := {"juego": "raices", "version": version(), "op": _op}
		if codigo != "":
			h["codigo"] = codigo
		if llave != "":
			h["llave"] = llave
		_marco(HOLA, JSON.stringify(h).to_utf8_buffer())
		_prox_latido = ahora + latido_ms
	while not _cola.is_empty() and int(_cola[0][0]) <= ahora:
		_poner(_cola.pop_front()[1])
	if ahora >= _prox_latido:
		_prox_latido = ahora + latido_ms
		_marco(VIVO, PackedByteArray())
	var n := _tcp.get_available_bytes()
	if n > 0:
		var r := _tcp.get_partial_data(n)
		if int(r[0]) == OK:
			_buf.append_array(r[1])
	while _tcp != null and _buf.size() >= 5:
		var largo := (_buf[0] << 24) | (_buf[1] << 16) | (_buf[2] << 8) | _buf[3]
		if largo < 1 or largo > max_bytes:
			rechazados += 1
			_perdido()
			return out
		if _buf.size() < 4 + largo:
			break
		var tipo := _buf[4]
		var carga := _buf.slice(5, 4 + largo)
		_buf = _buf.slice(4 + largo)
		_atender(tipo, carga, out)
	return out


func _atender(tipo: int, carga: PackedByteArray, out: Array) -> void:
	match tipo:
		RESP:
			var d = JSON.parse_string(carga.get_string_from_utf8())
			if not (d is Dictionary) or not bool(d.get("ok", false)):
				error_relevo = str(d.get("error", "respuesta rara")) if d is Dictionary else "respuesta rara"
				_op = "" # no se reintenta: lo rechazó
				_cortar()
				fallo.emit(error_relevo)
				return
			_admitido = true
			var nuevo := codigo != str(d["codigo"])
			codigo = str(d["codigo"])
			llave = str(d.get("llave", ""))
			if nuevo or anfitrion:
				codigo_listo.emit(codigo)
		DENTRO:
			if not _par:
				_par = true
				conectado.emit(2 if anfitrion else 1)
		FUERA:
			if _par:
				_par = false
				desconectado.emit(2 if anfitrion else 1)
		DATOS:
			if carga.size() > max_bytes or carga.size() < 4:
				rechazados += 1
				return
			var v = bytes_to_var(carga) # sin objetos: no se decodifican
			if v is Dictionary:
				out.append(v)
			else:
				rechazados += 1


## Se cortó la conexión con el relevo (no un rechazo).
func _perdido() -> void:
	_cortar()
	_prox_reintento = Time.get_ticks_msec() + reintento_ms


func enviar(msg: Dictionary) -> void:
	if _tcp == null:
		return
	var b := var_to_bytes(msg)
	if latencia_ms <= 0 and vaiven_ms <= 0:
		_poner(b)
		return
	var t := Time.get_ticks_msec() + latencia_ms + (_rng.randi_range(0, vaiven_ms) if vaiven_ms > 0 else 0)
	_ultima_salida = maxi(_ultima_salida, t)
	_cola.append([_ultima_salida, b])


func _poner(b: PackedByteArray) -> void:
	if not conectado_ahora():
		return
	_marco(DATOS, b)


func _marco(tipo: int, carga: PackedByteArray) -> void:
	var m := PackedByteArray()
	m.resize(5)
	var n := carga.size() + 1
	m[0] = (n >> 24) & 255
	m[1] = (n >> 16) & 255
	m[2] = (n >> 8) & 255
	m[3] = n & 255
	m[4] = tipo
	m.append_array(carga)
	if _tcp == null:
		return
	if _tcp.put_data(m) != OK:
		_perdido()
