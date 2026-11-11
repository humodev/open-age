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

const TEAM: Array[Color] = [Color("2f6fdb"), Color("d4553a"), Color("3aa36b"), Color("c9a227")]
const TEAM_NAMES: Array[String] = ["Azul", "Rojo", "Verde", "Ocre"]

const UI_BG := Color(0.075, 0.08, 0.09, 0.9)
const UI_BG_2 := Color(0.11, 0.115, 0.125, 0.95)
const UI_LINE := Color(1, 1, 1, 0.07)
const UI_TEXT := Color("ece8e1")
const UI_DIM := Color("9a958c")
const UI_ACCENT := Color("e3b23c")
const UI_BAD := Color("e0564a")
const UI_GOOD := Color("6cc46a")

const RES: Dictionary = {
	"alimento": Color("d9534f"),
	"madera": Color("7fae5a"),
	"piedra": Color("9aa4b2"),
	"riqueza": Color("e3b23c"),
}
const RES_NAMES: Dictionary = {
	"alimento": "Alimento",
	"madera": "Madera",
	"piedra": "Piedra",
	"riqueza": "Riqueza",
}


static func team(pid: int) -> Color:
	if pid < 0:
		return Color("c8c2b4")
	return TEAM[pid % TEAM.size()]
