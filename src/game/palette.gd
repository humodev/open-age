class_name Palette
extends RefCounted
## Paleta de maqueta (docs/07-arte-y-ui.md).

const GROUND_A := Color("56653c")
const GROUND_B := Color("75834c")
const DIRT := Color("9c8f6c")
const CLAY := Color("eee7da")
const CLAY_SHADE := Color("d6ccb9")
const CLAY_DARK := Color("b8ab93")
const ROOF := Color("a9927a")
const WOOD_BEAM := Color("8c7258")
const FOLIAGE := Color("3f6a3c")
const FOLIAGE_2 := Color("4f7b45")
const TRUNK := Color("7a5c43")
const STONE := Color("a39e94")
const STONE_DARK := Color("86817a")
const WEALTH := Color("e8b530")
const WEALTH_ROCK := Color("b7a689")
const BUSH := Color("47703c")
const BERRY := Color("c43d45")
const FIELD_A := Color("a9a066")
const FIELD_B := Color("7f8a4a")

# --- paleta --- (segunda tanda de interfaz: colores aptos para daltonismo)
# Los colores de equipo, de recursos y de vida dependen del modo de color elegido en
# Opciones. Son variables estáticas: se leen igual que antes (Palette.TEAM[i],
# Palette.RES["madera"]) y cambian con Palette.aplicar(modo). Las distancias entre
# colores se miden en tests/test_paleta.gd.
static var TEAM: Array[Color] = [Color("336ccb"), Color("ff0000"), Color("7f00ff"), Color("7c3f8c"), Color("ff66ff"), Color("446600"), Color("3189c4"), Color("b64e9b")]
static var TEAM_NAMES: Array[String] = ["Azul", "Rojo", "Violeta", "Ciruela", "Rosa", "Oliva", "Celeste", "Magenta"]
# --- fin paleta ---

const UI_BG := Color(0.075, 0.08, 0.09, 0.9)
const UI_BG_2 := Color(0.11, 0.115, 0.125, 0.95)
const UI_LINE := Color(1, 1, 1, 0.07)
const UI_TEXT := Color("ece8e1")
const UI_DIM := Color("9a958c")
const UI_ACCENT := Color("e3b23c")
# --- paleta ---
static var UI_BAD := Color("ff5a26")
static var UI_GOOD := Color("85f2c4")

static var RES: Dictionary = {
	"alimento": Color("bf4a6c"),
	"madera": Color("46bf5a"),
	"piedra": Color("bacad1"),
	"riqueza": Color("e8d317"),
}
# --- fin paleta ---
const RES_NAMES: Dictionary = {
	"alimento": "Alimento",
	"madera": "Madera",
	"piedra": "Piedra",
	"riqueza": "Riqueza",
}


static func team(pid: int) -> Color:
	if pid < 0:
		return Color("c8c2b4")
	# --- paleta --- modo "yo, aliados y rivales": el color dice el bando, no el jugador
	if modo == "relativa":
		if pid == local:
			return RELATIVA["yo"]
		if es_aliado.is_valid() and es_aliado.call(local, pid):
			return RELATIVA["aliado"]
		return RELATIVA["rival"]
	# --- fin paleta ---
	return TEAM[pid % TEAM.size()]


# --- paleta ---
## Modos de color. Los equipos 1 a 4 se distinguen entre sí y de los cuatro recursos
## en las cuatro visiones (normal, deuteranopía, protanopía y tritanopía); los modos
## para cada tipo de daltonismo eligen los equipos 5 a 8 para esa visión. Los recursos
## y la vida son los mismos en todos los modos: ya se distinguen en las cuatro.
const MODOS: Dictionary = {
	"normal": {
		"nombre": "Segura (por defecto)",
		"equipos": ["336ccb", "ff0000", "7f00ff", "7c3f8c", "ff66ff", "446600", "3189c4", "b64e9b"],
		"nombres": ["Azul", "Rojo", "Violeta", "Ciruela", "Rosa", "Oliva", "Celeste", "Magenta"],
	},
	"deuteranopia": {
		"nombre": "Deuteranopía (verde)",
		"equipos": ["336ccb", "ff0000", "7f00ff", "7c3f8c", "00ccff", "446600", "ee00aa", "6666ff"],
		"nombres": ["Azul", "Rojo", "Violeta", "Ciruela", "Celeste", "Oliva", "Magenta", "Lavanda"],
	},
	"protanopia": {
		"nombre": "Protanopía (rojo)",
		"equipos": ["336ccb", "ff0000", "7f00ff", "7c3f8c", "ccaaff", "ee4444", "4466ff", "ffaa88"],
		"nombres": ["Azul", "Rojo", "Violeta", "Ciruela", "Lila", "Coral", "Añil", "Salmón"],
	},
	"tritanopia": {
		"nombre": "Tritanopía (azul)",
		"equipos": ["336ccb", "ff0000", "7f00ff", "7c3f8c", "cc44ff", "888800", "446600", "ee4444"],
		"nombres": ["Azul", "Rojo", "Violeta", "Ciruela", "Orquídea", "Mostaza", "Oliva", "Coral"],
	},
	"relativa": {
		"nombre": "Yo, aliados y rivales",
		"equipos": ["336ccb", "ff0000", "7f00ff", "7c3f8c", "ff66ff", "446600", "3189c4", "b64e9b"],
		"nombres": ["Azul", "Rojo", "Violeta", "Ciruela", "Rosa", "Oliva", "Celeste", "Magenta"],
	},
}
## Colores del modo relativo: vos en azul, tus aliados en violeta, los rivales en rojo.
const RELATIVA: Dictionary = {"yo": Color("336ccb"), "aliado": Color("7f00ff"), "rival": Color("ff0000")}
const MODOS_ORDEN: Array[String] = ["normal", "deuteranopia", "protanopia", "tritanopia", "relativa"]

static var modo := "normal"
## Jugador local, para el modo relativo (lo fija main.gd al armar la partida).
static var local := 0
## (a, b) -> bool: si b es aliado de a. Lo puede fijar el modo por equipos; sin él, todos son rivales.
static var es_aliado := Callable()


static func aplicar(m: String) -> void:
	if not MODOS.has(m):
		m = "normal"
	modo = m
	var d: Dictionary = MODOS[m]
	var t: Array[Color] = []
	for h in d["equipos"]:
		t.append(Color(h))
	TEAM = t
	var n: Array[String] = []
	for x in d["nombres"]:
		n.append(x)
	TEAM_NAMES = n


## Nombre del color de un jugador ("Rojo"), según el modo.
static func team_name(pid: int) -> String:
	if pid < 0:
		return "Naturaleza"
	if modo == "relativa":
		return "Vos" if pid == local else ("Aliado" if es_aliado.is_valid() and es_aliado.call(local, pid) else "Rival")
	return TEAM_NAMES[pid % TEAM_NAMES.size()]
# --- fin paleta ---
