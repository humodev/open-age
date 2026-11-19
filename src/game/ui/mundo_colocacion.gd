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


# --- aura del hito --- (proceso/24, 4k)
## Aura que va a tener un hito de este tipo: la propia (`aura`) o la de su eje en
## reglas.aura_hito, como `Sim.aura_of` ({} si no tiene).
static func aura_def(sim: Sim, def: Dictionary) -> Dictionary:
	if not def.get("hito", false):
		return {}
	if def.has("aura"):
		return def["aura"]
	return sim.data.reglas.get("aura_hito", {}).get(String(def.get("eje", "")), {})


## "+15 % de recolección a 9 casillas" o "cura 2 por segundo a la tropa a 9 casillas".
static func aura_texto(aura: Dictionary) -> String:
	if aura.is_empty():
		return ""
	var r := int(aura.get("radio", 0)) / P
	if aura.has("recoleccion_pct"):
		var que := "recolección"
		if aura.has("recursos"):
			var nombres := []
			for k in aura["recursos"]:
				nombres.append(_res_name(k))
			que = "recolección de " + " y ".join(nombres)
		return "+%d %% de %s a %d casillas" % [int(aura["recoleccion_pct"]), que, r]
	if aura.has("cura_por_s"):
		return "cura %d de vida por segundo a la tropa a %d casillas" % [int(aura["cura_por_s"]), r]
	return "aura a %d casillas" % r


## Qué rinde dentro del aura de recolección si el hito va en (tx, ty): granjas propias y
## recursos de la naturaleza por tipo ({"granjas": n, "alimento": n, ...}), medidos desde el
## borde del edificio como `Sim.dist_to`.
static var _aura_cache := ["", {}]

static func dentro_del_aura(sim: Sim, pid: int, def: Dictionary, tx: int, ty: int) -> Dictionary:
	var aura := aura_def(sim, def)
	var out := {}
	if not aura.has("recoleccion_pct"):
		return out
	# Se recorre toda la naturaleza: una vez por casilla y por segundo de juego, no por cuadro.
	var key := "%s/%d/%d/%d/%d" % [def.get("nombre", ""), pid, tx, ty, sim.tick * sim.tick_ms / 1000]
	if _aura_cache[0] == key:
		return _aura_cache[1]
	var rad := int(aura["radio"])
	var tam: Array = def["tam"]
	var kinds: Array = aura.get("recursos", [])
	for e in sim.entities: # los recursos no están en `actives`
		if not e.alive or not (e.is_resource() or e.is_building()):
			continue
		var cx := clampi(e.x, tx * P, (tx + int(tam[0])) * P)
		var cy := clampi(e.y, ty * P, (ty + int(tam[1])) * P)
		if Sim.dist(e.x, e.y, cx, cy) > rad:
			continue
		if e.is_resource() and e.amount > 0 and (kinds.is_empty() or kinds.has(e.res_kind)):
			out[e.res_kind] = int(out.get(e.res_kind, 0)) + 1
		elif e.is_building() and e.owner == pid and String(e.def.get("fuente", "")) != "" and (kinds.is_empty() or kinds.has(e.def["fuente"])):
			out["granjas"] = int(out.get("granjas", 0)) + 1
	_aura_cache = [key, out]
	return out
# --- fin aura del hito ---


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
	# --- aura del hito --- radio y qué queda adentro (la decisión de dónde levantarlo)
	var aura := aura_def(sim, def)
	if not aura.is_empty():
		out.append(["Aura: " + aura_texto(aura), Palette.UI_GOOD])
		if aura.has("recoleccion_pct"):
			var inn := dentro_del_aura(sim, pid, def, tx, ty)
			var parts := []
			if inn.has("granjas"):
				parts.append("%d %s" % [inn["granjas"], "granja" if int(inn["granjas"]) == 1 else "granjas"])
			var nombres := {"alimento": ["fuente de alimento", "fuentes de alimento"], "madera": ["árbol", "árboles"], "piedra": ["veta de piedra", "vetas de piedra"], "riqueza": ["veta de riqueza", "vetas de riqueza"]}
			for k in nombres:
				if inn.has(k):
					parts.append("%d %s" % [inn[k], nombres[k][0 if int(inn[k]) == 1 else 1]])
			out.append(["En el aura: " + (", ".join(parts) if not parts.is_empty() else "nada que recolectar"), Palette.UI_TEXT if not parts.is_empty() else Palette.UI_BAD])
	# --- fin aura del hito ---
	if dd.has_mod("caminos") and not def.get("camino", false):
		var cfg: Dictionary = dd.mod("caminos")
		if conectado(sim, pid, type, tx, ty):
			out.append(["Conectado a la capital: +%d%% de producción" % int(cfg.get("bono_conectado_pct", 0)), Palette.UI_GOOD])
		else:
			out.append(["Sin conexión: unilo a la capital con caminos", Palette.UI_ACCENT])
	out.append_array(detalles_obra(sim, pid, type, tx, ty)) # --- fluidez 2 --- almacén y granja informan
	return out


# --- fluidez 2 --- (proceso/30-fluidez/02-constructor.md) granjas que se pegan, lugares libres,
# almacén que informa, costo del muro y causa de los huecos. Solo lee la simulación.
static var _cfg := {}

static func cfg() -> Dictionary:
	if _cfg.is_empty():
		_cfg = JSON.parse_string(FileAccess.get_file_as_string("res://data/constructor.json")) as Dictionary
	return _cfg


static func es_granja(def: Dictionary) -> bool:
	return String(def.get("fuente", "")) != ""


## Depósito propio terminado que recibe alimento más cercano a (tx, ty), a `rad` casillas o menos.
static func deposito_alimento(sim: Sim, pid: int, tx: int, ty: int, rad: int) -> SimEntity:
	var best: SimEntity = null
	var best_d := rad + 1
	for b in sim.actives:
		if b.alive and b.owner == pid and b.is_building() and b.built and (b.def.get("deposito", []) as Array).has("alimento"):
			var d := hueco_rect(tx, ty, 1, 1, b.tx, b.ty, b.w, b.h)
			if d < best_d:
				best = b
				best_d = d
	return best


## Las 8 posiciones de una pieza de w×h alrededor del rectángulo (bx, by, bw, bh): esquinas y lados.
static func ocho_lugares(bx: int, by: int, bw: int, bh: int, w: int, h: int) -> Array:
	var xs := [bx - w, bx + (bw - w) / 2, bx + bw]
	var ys := [by - h, by + (bh - h) / 2, by + bh]
	var out := []
	for j in 3:
		for i in 3:
			if i != 1 or j != 1:
				out.append(Vector2i(xs[i], ys[j]))
	return out


## Lugares libres para granjas alrededor del depósito de alimento más cercano:
## {"dep": SimEntity, "libres": n, "total": 8} o {} si no hay depósito cerca.
static func lugares_granja(sim: Sim, pid: int, type: String, tx: int, ty: int) -> Dictionary:
	var def: Dictionary = sim.dp(pid).edificios.get(type, {})
	var dep := deposito_alimento(sim, pid, tx, ty, int(cfg().get("granja_lugares_radio", 12)))
	if dep == null:
		return {}
	var libres := 0
	var lugares := ocho_lugares(dep.tx, dep.ty, dep.w, dep.h, int(def["tam"][0]), int(def["tam"][1]))
	for l: Vector2i in lugares:
		if sim.can_place(type, l.x, l.y, pid):
			libres += 1
	return {"dep": dep, "libres": libres, "total": lugares.size()}


## La granja se corre hasta `granja_pegar` casillas para quedar pegada al depósito de alimento
## o a otra granja propia, si ahí entra. Devuelve la casilla (la misma si no hay dónde pegarla).
static func pegar_granja(sim: Sim, pid: int, type: String, tx: int, ty: int) -> Vector2i:
	var def: Dictionary = sim.dp(pid).edificios.get(type, {})
	if not es_granja(def):
		return Vector2i(tx, ty)
	var w := int(def["tam"][0])
	var h := int(def["tam"][1])
	var tope := int(cfg().get("granja_pegar", 1))
	var best := Vector2i(tx, ty)
	var best_d := tope + 1
	for b in sim.actives:
		if not (b.alive and b.owner == pid and b.is_building()):
			continue
		if not (es_granja(b.def) or (b.built and (b.def.get("deposito", []) as Array).has("alimento"))):
			continue
		if hueco_rect(tx, ty, w, h, b.tx, b.ty, b.w, b.h) > tope + 1:
			continue
		# Pegada a un lado, alineada con el vecino o donde quedó el cursor.
		var cands := ocho_lugares(b.tx, b.ty, b.w, b.h, w, h)
		cands.append_array([Vector2i(b.tx - w, ty), Vector2i(b.tx + b.w, ty), Vector2i(tx, b.ty - h), Vector2i(tx, b.ty + b.h)])
		for c: Vector2i in cands:
			var d := maxi(absi(c.x - tx), absi(c.y - ty))
			if d < best_d and sim.can_place(type, c.x, c.y, pid):
				best = c
				best_d = d
	return best


## Casillas libres entre dos rectángulos (0 si se tocan o se pisan), en la medida de Chebyshev.
static func hueco_rect(ax: int, ay: int, aw: int, ah: int, bx: int, by: int, bw: int, bh: int) -> int:
	var gx := maxi(0, maxi(bx - (ax + aw), ax - (bx + bw)))
	var gy := maxi(0, maxi(by - (ay + ah), ay - (by + bh)))
	return maxi(gx, gy)


## Depósito propio terminado más cercano que recibe alguno de `kinds`, con su distancia en
## casillas desde el borde de la huella: [SimEntity, casillas] o [null, -1].
static func deposito_cerca(sim: Sim, pid: int, kinds: Array, tx: int, ty: int, w: int, h: int) -> Array:
	var best: SimEntity = null
	var best_d := 1 << 30
	for b in sim.actives:
		if not (b.alive and b.owner == pid and b.is_building() and b.built):
			continue
		var dep: Array = b.def.get("deposito", [])
		if not kinds.any(func(k: String) -> bool: return dep.has(k)):
			continue
		var d := hueco_rect(tx, ty, w, h, b.tx, b.ty, b.w, b.h)
		if d < best_d:
			best = b
			best_d = d
	return [best, best_d if best != null else -1]


## Recursos de la naturaleza a `rad` casillas de la huella, por tipo: {kind: [cuántos, cantidad]}.
## Se recorre la naturaleza una vez por casilla y por segundo de juego, no por cuadro.
static var _info_cache := ["", {}]

static func recursos_cerca(sim: Sim, kinds: Array, tx: int, ty: int, w: int, h: int, rad: int) -> Dictionary:
	var key := "%s/%d/%d/%d/%d/%d" % [",".join(kinds), tx, ty, w, h, sim.tick * sim.tick_ms / 1000]
	if _info_cache[0] == key:
		return _info_cache[1]
	var out := {}
	for e in sim.entities:
		if not e.alive or not e.is_resource() or e.amount <= 0 or not kinds.has(e.res_kind):
			continue
		var cx := clampi(e.x, tx * P, (tx + w) * P)
		var cy := clampi(e.y, ty * P, (ty + h) * P)
		if Sim.dist(e.x, e.y, cx, cy) > rad * P:
			continue
		var a: Array = out.get_or_add(e.res_kind, [0, 0])
		a[0] += 1
		a[1] += e.amount
	_info_cache = [key, out]
	return out


## Renglones del almacén y de la granja: qué hay cerca y a cuánto queda el depósito.
static func detalles_obra(sim: Sim, pid: int, type: String, tx: int, ty: int) -> Array:
	var def: Dictionary = sim.dp(pid).edificios.get(type, {})
	var out := []
	var w := int(def["tam"][0])
	var h := int(def["tam"][1])
	if es_granja(def):
		var lg := lugares_granja(sim, pid, type, tx, ty)
		if not lg.is_empty():
			var dn: String = String((lg["dep"] as SimEntity).def.get("nombre", "depósito"))
			out.append(["%d de %d lugares libres junto a: %s" % [lg["libres"], lg["total"], dn], Palette.UI_GOOD if int(lg["libres"]) > 0 else Palette.UI_DIM])
		var dc := deposito_cerca(sim, pid, ["alimento"], tx, ty, w, h)
		if dc[0] == null:
			out.append(["Sin depósito de alimento: los granjeros no tienen dónde dejar", Palette.UI_BAD])
		elif int(dc[1]) == 0:
			out.append(["Pegada al depósito de alimento", Palette.UI_GOOD])
		else:
			out.append(["Los granjeros caminan %d casillas hasta el depósito" % int(dc[1]), Palette.UI_ACCENT if int(dc[1]) > 4 else Palette.UI_TEXT])
		return out
	var kinds: Array = def.get("deposito", [])
	if kinds.is_empty() or def.get("hito", false):
		return out
	var rad := int(cfg().get("info_radio", 6))
	var cerca := recursos_cerca(sim, kinds, tx, ty, w, h, rad)
	var nombres := {"alimento": ["fuente de alimento", "fuentes de alimento"], "madera": ["árbol", "árboles"], "piedra": ["veta de piedra", "vetas de piedra"], "riqueza": ["veta de riqueza", "vetas de riqueza"]}
	var parts := []
	for k in kinds:
		if cerca.has(k):
			var n := int(cerca[k][0])
			parts.append("%d %s (≈%d de %s)" % [n, nombres.get(k, [k, k])[0 if n == 1 else 1], int(cerca[k][1]), _res_name(k)])
	if parts.is_empty():
		out.append(["A %d casillas: nada que recibir" % rad, Palette.UI_BAD])
	else:
		out.append(["A %d casillas: %s" % [rad, ", ".join(parts)], Palette.UI_GOOD])
	var dc := deposito_cerca(sim, pid, kinds, tx, ty, w, h)
	if dc[0] != null:
		out.append(["El depósito más cercano está a %d casillas" % int(dc[1]), Palette.UI_DIM])
	return out


## "48 de madera + 10 de piedra".
static func costo_texto(cost: Dictionary) -> String:
	var parts := []
	for k in cost:
		if int(cost[k]) > 0:
			parts.append("%d de %s" % [int(cost[k]), _res_name(k)])
	return " + ".join(parts) if not parts.is_empty() else "gratis"


## Por qué una casilla del trazo queda como hueco: "árboles", "recursos", "edificios", "agua",
## "roca", "borde" o "pendiente".
static func causa_hueco(sim: Sim, tx: int, ty: int) -> String:
	if not sim.map.in_bounds(tx, ty):
		return "borde"
	if sim.map.is_water(tx, ty):
		return "agua"
	if sim.map.is_rock(tx, ty):
		return "roca"
	var occ := sim.map.occupant(tx, ty)
	var o: SimEntity = sim.by_id.get(occ)
	if o != null and o.is_resource():
		return "árboles" if o.res_kind == "madera" else "recursos"
	if occ != -1:
		return "edificios"
	return "pendiente"


## Tipo de puerta del pueblo (el edificio con "puerta"), o "". Con el muro que se traza, la suya
## (`su_puerta`: la muralla de piedra lleva la puerta de piedra; proceso/32-ronda-8/06).
static func tipo_puerta(sim: Sim, pid: int, muro := "") -> String:
	var suya: String = sim.dp(pid).edificios.get(muro, {}).get("su_puerta", "")
	if suya != "" and sim.dp(pid).edificios.has(suya):
		return suya
	for k in sim.dp(pid).edificios:
		if sim.dp(pid).edificios[k].get("puerta", false):
			return k
	return ""
# --- fin fluidez 2 ---
