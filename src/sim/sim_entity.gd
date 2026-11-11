class_name SimEntity
extends RefCounted
## Una entidad de la simulación. Las capacidades salen de `def` (datos), no de subclases.

enum Cat { UNIT, BUILDING, RESOURCE }
enum Order { IDLE, MOVE, ATTACK_MOVE, ATTACK, GATHER, RETURN, BUILD }

var id: int
var owner: int = -1 # -1 = naturaleza
var cat: int
var type: String
var def: Dictionary

# Posición en milésimas de casilla (centro de la entidad).
var x: int
var y: int
# Huella en casillas (edificios y recursos).
var tx: int
var ty: int
var w: int = 1
var h: int = 1

var hp: int
var hp_max: int
var alive := true

# --- Unidades ---
var fn: String = "" # función: civil, choque, distancia, linea, edificio
var radius: int = 0
var speed: int = 0 # milésimas de casilla por tick
var order: int = Order.IDLE
var target: int = -1
var aux: int = -1 # depósito elegido al entregar
var goal_x: int
var goal_y: int
var path: Array[Vector2i] = []
var path_i: int = 0
var path_target: int = -1
var path_tick: int = -1000
var resume_amove := false
var amove_x: int
var amove_y: int
var cooldown: int = 0
var gather_kind: String = ""
var gather_acc: int = 0
var carry_res: String = ""
var carry: int = 0
var anchored := false # trabajando quieto: la separación lo empuja menos
var stuck: int = 0

# --- Edificios ---
var built := true
var progress: int = 0
var build_time: int = 0
var queue: Array[String] = []
var queue_progress: int = 0
var rally_set := false
var rally_x: int
var rally_y: int
var rally_target: int = -1
var farmer: int = -1

# --- Recursos ---
var res_kind: String = ""
var amount: int = 0


func is_unit() -> bool:
	return cat == Cat.UNIT


func is_building() -> bool:
	return cat == Cat.BUILDING


func is_resource() -> bool:
	return cat == Cat.RESOURCE


func is_military() -> bool:
	return cat == Cat.UNIT and fn != "civil"
