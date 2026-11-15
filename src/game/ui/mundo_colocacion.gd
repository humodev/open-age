extends RefCounted
## Vista previa al colocar un edificio: por qué no se puede, qué rinde y qué alcanza.
## Solo lee el estado de la simulación; los números salen de los datos (D-008).

const P := 1000


## Motivo por el que no se puede construir ahí ("" si se puede). Sigue el mismo
## orden de chequeos que `Sim.can_place` para nombrar el primero que falla.
static func motivo(sim: Sim, pid: int, type: String, tx: int, ty: int) -> String:
	var dd := sim.dp(pid)
	if not dd.edificios.has(type):
		return "Este pueblo no construye eso"
	var def: Dictionary = dd.edificios[type]
	var tam: Array = def["tam"]
	if tx < 0 or ty < 0 or tx + tam[0] > sim.map.n or ty + tam[1] > sim.map.n:
		return "Fuera del mapa"
	if not sim.can_place(type, tx, ty, pid):
		var why := _tile_problem(sim, tx, ty, tam[0], tam[1], def)
		if why != "":
			return why
		var slot := cupo(sim, pid, type)
		if not slot.is_empty() and int(slot["n"]) >= int(slot["max"]):
			return "Máximo de la edad alcanzado: %d/%d" % [slot["n"], slot["max"]]
		var near := vecino_cercano(sim, pid, type, tx, ty)
		if near != null:
			return "Muy cerca de otro %s: separación mínima de %d casillas" % [String(def["nombre"]).to_lower(), int(def["separacion"])]
		if def.get("requiere_agua", false):
			return "Tiene que quedar junto al agua"
		return "No se puede construir ahí"
	var cost := dd.cost_of(type, sim.players[pid]["age"])
	for k in cost:
		var have := int(sim.players[pid]["res"].get(k, 0))
		if have < int(cost[k]):
			return "Falta %d de %s" % [int(cost[k]) - have, _res_name(k)]
	return ""


static func _res_name(k: String) -> String:
	return String(Palette.RES_NAMES.get(k, k)).to_lower()


## Primer problema de las casillas de la huella: agua, roca, ocupación o desnivel.
static func _tile_problem(sim: Sim, tx: int, ty: int, w: int, h: int, def: Dictionary) -> String:
	var map := sim.map
	var h0 := map.h_at(tx, ty)
	var uneven := false
	for yy in range(ty, ty + h):
		for xx in range(tx, tx + w):
			if map.is_water(xx, yy):
				return "No se puede construir sobre el agua"
			if map.is_rock(xx, yy):
				return "Hay roca: no se puede construir"
			var occ := map.occupant(xx, yy)
			if occ >= 0:
				var o: SimEntity = sim.by_id.get(occ)
				if o != null and o.is_resource():
					return "Hay recursos en el lugar"
				return "El lugar está ocupado"
			elif occ != -1:
				return "El lugar está ocupado"
			if map.h_at(xx, yy) != h0:
				uneven = true
	if uneven and not def.get("permite_ladera", false):
		return "Terreno en pendiente: buscá un llano"
	return ""


## Estado de cada casilla de la huella: 0 libre, 1 ladera aprovechable, 2 bloqueada.
static func casillas(sim: Sim, type: String, tx: int, ty: int, pid: int) -> Array:
	var def: Dictionary = sim.dp(pid).edificios.get(type, {})
	if def.is_empty():
		return []
	var tam: Array = def["tam"]
	var map := sim.map
	var h0 := map.h_at(tx, ty)
	var ladera: bool = def.get("permite_ladera", false)
	var out := []
	for yy in range(ty, ty + int(tam[1])):
		for xx in range(tx, tx + int(tam[0])):
			var st := 0
			if not map.in_bounds(xx, yy) or map.occupant(xx, yy) != -1 or map.is_water(xx, yy):
				st = 2
			elif map.h_at(xx, yy) != h0 or map.is_slope(xx, yy):
				st = 1 if ladera else (2 if map.h_at(xx, yy) != h0 else 0)
			out.append([xx, yy, st])
	return out


## Cuántas piezas de un tipo con máximo por edad hay y cuántas se permiten.
static func cupo(sim: Sim, pid: int, type: String) -> Dictionary:
	var def: Dictionary = sim.dp(pid).edificios.get(type, {})
	var maxes: Array = def.get("maximo_por_edad", [])
	if maxes.is_empty():
		return {}
	var n := 0
	for e in sim.actives:
		if e.alive and e.owner == pid and e.type == type:
			n += 1
	var age := clampi(int(sim.players[pid]["age"]) - 1, 0, maxes.size() - 1)
	return {"n": n, "max": int(maxes[age]) + int(sim.mods.engine_max_bonus(pid, type))}


## Pieza del mismo tipo que queda dentro de la separación mínima.
static func vecino_cercano(sim: Sim, pid: int, type: String, tx: int, ty: int) -> SimEntity:
	var def: Dictionary = sim.dp(pid).edificios.get(type, {})
	var sep := int(def.get("separacion", 0))
	if sep <= 0:
		return null
	for e in sim.actives:
		if e.alive and e.owner == pid and e.type == type and maxi(absi(e.tx - tx), absi(e.ty - ty)) < sep:
			return e
	return null


## Bonificación de rendimiento del lugar (ladera para andenes, agua para arrozales),
## calculada por la misma función de la simulación sobre una entidad de prueba.
static func bono_sitio(sim: Sim, pid: int, type: String, tx: int, ty: int) -> int:
	var def: Dictionary = sim.dp(pid).edificios.get(type, {})
	if not (def.has("bono_ladera_pct") or def.has("bono_agua_pct")):
		return 0
	var probe := SimEntity.new()
	probe.cat = SimEntity.Cat.BUILDING
	probe.def = def
	probe.tx = tx
	probe.ty = ty
	probe.w = int(def["tam"][0])
	probe.h = int(def["tam"][1])
	return sim._site_bonus(probe)


## ¿Quedaría unido a la capital? (módulo caminos: basta tocar un edificio o camino conectado).
static func conectado(sim: Sim, pid: int, type: String, tx: int, ty: int) -> bool:
	var tam: Array = sim.dp(pid).edificios[type]["tam"]
	for yy in range(ty - 1, ty + int(tam[1]) + 1):
		for xx in range(tx - 1, tx + int(tam[0]) + 1):
			if xx >= tx and xx < tx + int(tam[0]) and yy >= ty and yy < ty + int(tam[1]):
				continue
			var o: SimEntity = sim.by_id.get(sim.map.occupant(xx, yy))
			if o != null and o.alive and o.owner == pid and o.is_building() and (o.capital or sim.mods.connected(o)):
				return true
	return false


## Renglones de información para mostrar junto al cursor: [texto, color].
static func detalles(sim: Sim, pid: int, type: String, tx: int, ty: int) -> Array:
	var dd := sim.dp(pid)
	var def: Dictionary = dd.edificios.get(type, {})
	var out := []
	if def.is_empty():
		return out
	var why := motivo(sim, pid, type, tx, ty)
	if why != "":
		out.append([why, Palette.UI_BAD])
	var slot := cupo(sim, pid, type)
	if not slot.is_empty():
		var full := int(slot["n"]) >= int(slot["max"])
		out.append(["%s: %d/%d en esta edad" % [def["nombre"], slot["n"], slot["max"]], Palette.UI_BAD if full else Palette.UI_TEXT])
	if int(def.get("separacion", 0)) > 0:
		out.append(["Separación mínima: %d casillas" % int(def["separacion"]), Palette.UI_DIM])
	if def.has("bono_ladera_pct"):
		var b := bono_sitio(sim, pid, type, tx, ty)
		if b > 0:
			out.append(["En ladera: +%d%% de alimento" % b, Palette.UI_GOOD])
		else:
			out.append(["En llano: pierde el +%d%% de la ladera" % int(def["bono_ladera_pct"]), Palette.UI_DIM])
	if def.has("bono_agua_pct"):
		var b := bono_sitio(sim, pid, type, tx, ty)
		if b > 0:
			out.append(["Junto al agua: +%d%% de alimento" % b, Palette.UI_GOOD])
		else:
			out.append(["Lejos del agua: pierde el +%d%%" % int(def["bono_agua_pct"]), Palette.UI_DIM])
	if def.has("alcance") and def.has("ataque"):
		var reach := int(def["alcance"]) + sim.mod(pid, "b_alcance")
		out.append(["Alcance: %.1f casillas" % (reach / float(P)), Palette.UI_TEXT])
	if int(def.get("guarnicion", 0)) > 0:
		var rc := int(sim.data.reglas.get("radio_campana", 0))
		out.append(["Refugia %d · campana a %d casillas" % [int(def["guarnicion"]), rc / P], Palette.UI_DIM])
	if dd.has_mod("caminos") and not def.get("camino", false):
		var cfg: Dictionary = dd.mod("caminos")
		if conectado(sim, pid, type, tx, ty):
			out.append(["Conectado a la capital: +%d%% de producción" % int(cfg.get("bono_conectado_pct", 0)), Palette.UI_GOOD])
		else:
			out.append(["Sin conexión: unilo a la capital con caminos", Palette.UI_ACCENT])
	return out
