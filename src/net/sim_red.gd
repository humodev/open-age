class_name SimRed
extends Sim
## La simulación de siempre con la entrada de comandos desviada a la red (proceso/37).
## No cambia nada de src/sim: solo pisa push_command. Los comandos de un jugador de la red
## no entran directo: si es el local, van al lockstep para el turno actual + retardo; si es
## el otro, se descartan (llegan por la red con su turno). Los de jugadores que no son de
## la red (una IA compartida) siguen como siempre, porque las dos máquinas los generan iguales.

var red: Lockstep = null


func _init(seed_value: int, num_players: int = 2, data_override: SimData = null, opts: Dictionary = {}) -> void:
	super(seed_value, num_players, data_override, opts)
	if SesionRed.activa != null:
		SesionRed.activa.adjuntar(self)


func push_command(cmd: Dictionary, delay: int = 0) -> void:
	if red == null or not red.es_de_red(int(cmd.get("player", -1))):
		super.push_command(cmd, delay)
		return
	red.comando(cmd)
