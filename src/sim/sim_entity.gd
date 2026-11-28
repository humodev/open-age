class_name SimEntity
extends RefCounted
## Una entidad de la simulación. Las capacidades salen de `def` (datos), no de subclases.

enum Cat { UNIT, BUILDING, RESOURCE }
enum Order { IDLE, MOVE, ATTACK_MOVE, ATTACK, GATHER, RETURN, BUILD, GARRISON, HOLD, GROUND, TRADE, FOLLOW } # --- esport 1a --- GROUND: atacar el suelo; --- comercio --- TRADE: ruta; --- fluidez 5 --- FOLLOW: escoltar

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
var auto_tgt := false # el blanco de ATACAR lo eligió ella (no fue orden directa): puede cambiarlo por uno más importante
var group := -1 # grupo en marcha (SimGroups), -1 suelta
var amove_x: int
var amove_y: int
# Patrulla (proceso/23, parte B): va y vuelve entre (amove_x, amove_y) y (pat_x, pat_y) atacando
# lo que ve. Es un ataque en movimiento que, al llegar, da la vuelta. Cualquier otra orden la corta.
var patrol := false
var pat_x: int
var pat_y: int
# --- fluidez 5 --- Patrulla de varios puntos (Mayús): la vuelta recorre pat_pts en ronda; pat_i es
# el punto hacia el que va. Con dos puntos o menos se usa la ida y vuelta de arriba.
var pat_pts: Array[Vector2i] = []
var pat_i := 0
# Escolta: id de la unidad propia que sigue (orden FOLLOW, o pelea y vuelve a ella); -1 ninguna.
var esc := -1
# --- fin fluidez 5 ---
# --- esport 1a --- Atacar el suelo: el punto donde tira el asedio de área (orden GROUND).
var gnd_x: int
var gnd_y: int
var rumbo := -1 # último rumbo de su formación (0..15); "formar" lo usa para cambiar de forma en el lugar
var cooldown: int = 0
var gather_kind: String = ""
var gather_acc: int = 0
# --- rendimiento 3 --- tasa de recolección guardada (Sim._do_gather): fuente, época y valor
var rate_t: int = -1
var rate_ep: int = -1
var rate_v: int = 0
var carry_res: String = ""
var carry: int = 0
var anchored := false # trabajando quieto: la separación lo empuja menos
var stuck: int = 0
var prog_d: int = 0 # recolección: menor distancia al recurso desde que eligió camino
var prog_i: int = 0 # recolección: casilla del camino a la que llegó
var prog_tick: int = 0 # recolección: último tick en que se acercó
# --- movimiento 60 --- (proceso/60)
var mv_x: int = 0 # último paso pedido (milésimas): hacia dónde camina, para la separación
var mv_y: int = 0
var mv_tick: int = -10 # tick de ese paso
var arr_d: int = 0 # menor distancia al destino (o a la casilla siguiente) desde el último avance
var arr_i: int = 0 # casilla del camino a la que llegó
var arr_tick: int = 0 # último tick en que avanzó
var arr_n: int = 0 # caminos recalculados sin avanzar
var rodeo := false # en grupo: hay algo sólido entre ella y su lugar
var rodeo_wp: int = -1 # en grupo, con rodeo: casilla del camino del grupo hacia la que va (-1: camino propio)
var inside: int = -1 # id del edificio que la aloja
var last_combat: int = -100000 # último tick en que pegó o recibió un golpe
var slow_until: int = -1 # frenada (boleadoras) hasta este tick
var shots: int = 0 # disparos hechos (munición limitada)
# --- comercio --- (SimComercio): ruta del comerciante
var trade_home: int = -1 # mercado propio
var trade_dest: int = -1 # mercado destino (neutral, aliado o propio)
var trade_leg: int = 0 # SimComercio.Leg
var trade_gain: int = 0 # riqueza que trae (se cobra al volver)
var trade_wx: int = -1 # punto de paso (milésimas); -1 sin punto
var trade_wy: int = -1
var trade_wpd := true # ya pasó por el punto en este tramo
var trade_bx: int = 0 # esperando (Leg.ESPERA): lugar del corte (milésimas)
var trade_by: int = 0
var trade_px: int = 0 # esperando: punto donde espera (milésimas)
var trade_py: int = 0
var trade_since: int = 0 # esperando: tick en que empezó
# --- fin comercio ---
var aura_bits: int = 0 # --- paso 4 --- hitos militares de su dueño en cuya aura está (Sim._aura_combat)

# --- Edificios ---
var built := true
var progress: int = 0
var build_time: int = 0
var queue: Array[String] = []
var queue_paid: Array[Dictionary] = [] # lo que se pagó por cada elemento de la cola (se devuelve al cancelar)
var queue_progress: int = 0
var repeat: String = "" # unidad que se encola sola cuando la cola se vacía ("" = sin repetición; proceso/30, frente 1)
var rally_set := false
var rally_x: int
var rally_y: int
var rally_target: int = -1
var rally_res: String = "" # --- fluidez 2 --- tipo del recurso de la reunión ("arbol", "veta_piedra"…), para seguir si se agota
var rally_kind: String = "" # y su recurso ("madera"…)
var farmer: int = -1
var garrison: Array[int] = [] # unidades alojadas
var carry_src: String = "" # de dónde salió la carga: tipo de recurso, o "granja"
var trib_min: int = -1 # elefante del rey: minuto del último cobro
var trib_used: int = 0 # elefante del rey: riqueza cobrada en ese minuto
var mode: String = "" # gult etíope: "" (señor) o "regimiento"
var heads: int = 0 # corral mapuche: cabezas de ganado
var breed_ms: int = 0 # corral: tiempo acumulado hacia la próxima cría
var feast_age: int = 0 # corral: edad en la que se hizo el último kawiñ (0: nunca)
var feast_until: int = 0 # corral: tick hasta el que no hay cría después del kawiñ
var dmg_q: int = 0 # corral: cuartos de vida perdidos ya descontados en cabezas
var crafts: Array[int] = [] # gente trabajando en un oficio adentro (Palmares); la campana no la saca
var capital := false # el centro inicial cuenta como hito (docs/05, "Victoria"); viaja con la base móvil
var holder: int = -1 # sitio sagrado: jugador que lo controla
var res_owner: int = -1 # arcilla de casa o de flanco: de quién es (-1: disputada)
var capture: int = 0 # sitio sagrado: progreso de captura (ms) y por quién (aux)
var workers_prev: int = 0 # constructores del tick anterior
var workers_now: int = 0

# --- Recursos ---
var res_kind: String = ""
var amount: int = 0


func is_unit() -> bool:
	return cat == Cat.UNIT


func is_building() -> bool:
	return cat == Cat.BUILDING


func is_resource() -> bool:
	return cat == Cat.RESOURCE


## Militar por lista blanca: el ganado, los elefantes de carga y otras unidades
## nuevas no cuentan como ejército (crítica 03b, trampa 1).
func is_military() -> bool:
	return cat == Cat.UNIT and MILITARY_FNS.has(fn)
const MILITARY_FNS := {"choque": true, "distancia": true, "linea": true, "asedio": true} # sin armar un arreglo por llamada
