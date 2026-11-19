class_name RedTransporte
extends RefCounted
## ENet para dos (proceso/37): un anfitrión que escucha en un puerto y un cliente que se une.
## Los mensajes son diccionarios (var_to_bytes, sin objetos), confiables y en orden.
## latencia_ms y vaiven_ms simulan una red lenta: lo que sale se retiene ese tiempo (en orden).

signal conectado(id: int)
signal desconectado(id: int)

var peer: ENetMultiplayerPeer = null
var anfitrion := false
var latencia_ms := 0
var vaiven_ms := 0
var timeout_min_ms := 3000
var timeout_max_ms := 8000
var _cola: Array = [] # [ms de salida, bytes]
var _ultima_salida := 0
var _rng := RandomNumberGenerator.new()


func crear(puerto: int) -> Error:
	cerrar()
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(puerto, 1)
	if err != OK:
		peer = null
		return err
	anfitrion = true
	_conectar_senales()
	return OK


func unirse(ip: String, puerto: int) -> Error:
	cerrar()
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, puerto)
	if err != OK:
		peer = null
		return err
	anfitrion = false
	_conectar_senales()
	return OK


func activo() -> bool:
	return peer != null


func conectado_ahora() -> bool:
	return peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and (not anfitrion or _pares > 0)


var _pares := 0


func _conectar_senales() -> void:
	_pares = 0
	_cola.clear()
	peer.transfer_mode = MultiplayerPeer.TRANSFER_MODE_RELIABLE
	peer.peer_connected.connect(func(id: int) -> void:
		_pares += 1
		var p := peer.get_peer(id)
		if p != null:
			p.set_timeout(32, timeout_min_ms, timeout_max_ms)
		conectado.emit(id))
	peer.peer_disconnected.connect(func(id: int) -> void:
		_pares = maxi(0, _pares - 1)
		desconectado.emit(id))


func enviar(msg: Dictionary) -> void:
	if peer == null:
		return
	var b := var_to_bytes(msg)
	if latencia_ms <= 0 and vaiven_ms <= 0:
		_poner(b)
		return
	var t := Time.get_ticks_msec() + latencia_ms + (_rng.randi_range(0, vaiven_ms) if vaiven_ms > 0 else 0)
	_ultima_salida = maxi(_ultima_salida, t) # en orden, como ENet confiable
	_cola.append([_ultima_salida, b])


## Saca lo retenido que ya cumplió su demora, atiende ENet y devuelve lo recibido.
func poll() -> Array:
	var out: Array = []
	if peer == null:
		return out
	var ahora := Time.get_ticks_msec()
	while not _cola.is_empty() and int(_cola[0][0]) <= ahora:
		_poner(_cola.pop_front()[1])
	_en_poll = true
	peer.poll()
	_en_poll = false
	if _cerrar_pend: # una señal pidió cerrar: recién ahora, fuera de poll() (cerrar adentro rompe ENet)
		_cerrar_pend = false
		cerrar()
		return out
	while peer.get_available_packet_count() > 0:
		var v = bytes_to_var(peer.get_packet())
		if v is Dictionary:
			out.append(v)
	return out


func _poner(b: PackedByteArray) -> void:
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	peer.set_target_peer(MultiplayerPeer.TARGET_PEER_BROADCAST)
	peer.put_packet(b)


var _en_poll := false
var _cerrar_pend := false


func cerrar() -> void:
	if _en_poll:
		_cerrar_pend = true
		return
	if peer != null:
		peer.close()
	peer = null
	_pares = 0
	_cola.clear()
