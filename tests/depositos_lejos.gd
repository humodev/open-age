extends SceneTree
## Depósitos lejos de la base (proceso/24, 4m): en las seis civilizaciones,
##   1. el almacén que recibe alimento tiene nombre común e ícono que lo dicen (el tapyi guaraní
##      no es una "Leñera"), y el aviso de viajes largos sabe qué nombrar;
##   2. si se levanta ese almacén (o se lleva el elefante del rey) junto a una caza lejana, los
##      aldeanos que ya estaban cazando le entregan a él en el viaje siguiente.
##   godot --headless --path . -s tests/depositos_lejos.gd

const Consejos := preload("res://src/game/ui/consejos.gd")
const CIVS := ["guaranies", "tawantinsuyu", "mapuches", "palmares", "etiopia", "ayutthaya"]
const LEJOS := 26 # casillas de la caza al centro


func _init() -> void:
	var fallas: Array[String] = []
	var base := SimData.load_default()
	for civ in CIVS:
		var dd := base.for_civ(civ)
		var store := Consejos.best_store(dd, "alimento", 1)
		var walking := Consejos.walking_store(dd, "alimento")
		var linea := "%-13s " % civ
		if store != "":
			var def: Dictionary = dd.edificios[store]
			var icon := Glyphs.resolve(def, store)
			var comun := Grilla.comun(base, dd, store)
			linea += "%s «%s» común «%s» ícono %s en %s" % [store, def["nombre"], comun, icon, Consejos.grid_path(dd, store)]
			if not icon.contains("alimento") and (def["deposito"] as Array).size() < 4:
				fallas.append("%s: el ícono de %s (%s) no muestra el alimento" % [civ, store, icon])
			if comun == "Leñera":
				fallas.append("%s: %s recibe alimento y se llama Leñera" % [civ, store])
		elif not walking.is_empty():
			linea += "sin almacén: %s (se entrena en %s)" % walking
		else:
			fallas.append("%s: nada recibe alimento lejos" % civ)
		# Lo mismo para madera y piedra: alguien tiene que recibirlas.
		for k in ["madera", "piedra"]:
			var s := Consejos.best_store(dd, k, 1)
			if s == "" and Consejos.walking_store(dd, k).is_empty():
				fallas.append("%s: nada recibe %s lejos" % [civ, k])
			linea += " | %s: %s" % [k, s if s != "" else str(Consejos.walking_store(dd, k))]
		# Cada almacén del pueblo: el ícono y el nombre común dicen qué recibe.
		for t: String in dd.unidades["aldeano"].get("construye", []):
			var def: Dictionary = dd.edificios.get(t, {})
			if def.has("deposito") and not dd.is_hito(t):
				linea += "\n    %-16s %-24s recibe %-34s ícono %-22s común «%s»" % [t, def["nombre"], ", ".join(def["deposito"]), Glyphs.resolve(def, t), Grilla.comun(base, dd, t)]
		print(linea)
		var r := _hunt(civ, store, walking)
		print("    caza a %d casillas: %s" % [LEJOS, r[1]])
		if not r[0]:
			fallas.append("%s: %s" % [civ, r[1]])
	for f in fallas:
		print("FALLO ", f)
	print("DEPÓSITOS LEJOS: ", "OK" if fallas.is_empty() else "FALLO (%d)" % fallas.size())
	quit(0 if fallas.is_empty() else 1)


## Tres aldeanos cazan lejos; a los 40 s aparece el almacén junto a la caza. Devuelve [ok, texto].
func _hunt(civ: String, store: String, walking: Array) -> Array:
	var s := Sim.new(11, 2, null, {"civs": [civ, "guaranies"], "sin_animales": true})
	var cap: SimEntity = null
	for e in s.actives:
		if e.owner == 0 and e.capital:
			cap = e
	var dir := 1 if cap.tx < s.map.n / 2 else -1
	var spot := s.map.nearest_free(cap.tx + dir * LEJOS, cap.ty, 8)
	var meat: Array[SimEntity] = []
	for i in 3:
		var m := s.spawn_resource("carne", spot.x + i, spot.y + 3)
		m.amount = 5000
		meat.append(m)
	var vills: Array[SimEntity] = []
	for e in s.actives:
		if e.owner == 0 and e.is_unit() and e.fn == "civil" and vills.size() < 3:
			vills.append(e)
	for i in vills.size():
		s._order_gather(vills[i], meat[i])
	var depot: SimEntity = null
	var prev := {}
	var to_store := 0
	var to_other := 0
	var built_at := 400 # 40 s: los aldeanos ya están cazando y algunos volvieron al centro
	for tick in 3000:
		if tick == built_at:
			if store != "":
				var at := s.map.nearest_free(spot.x, spot.y - 3, 6)
				depot = s.spawn_building(store, 0, at.x, at.y, true)
			else:
				depot = s.spawn_unit(walking[0], 0, spot.x * Sim.P, (spot.y - 2) * Sim.P)
		s.step()
		for v in vills:
			var was: Array = prev.get(v.id, [-1, -1, 0])
			if was[0] == SimEntity.Order.RETURN and was[2] > 0 and v.carry == 0:
				if depot != null and was[1] == depot.id:
					to_store += 1
				elif depot != null:
					to_other += 1
			prev[v.id] = [v.order, v.aux, v.carry]
	var txt := "tras levantar %s: %d entregas ahí, %d a otro lado" % [depot.def["nombre"] if depot != null else "?", to_store, to_other]
	# Una entrega a otro lado se tolera: la del aldeano que ya volvía cuando apareció el almacén.
	return [to_store >= 3 and to_other <= vills.size(), txt]


## Al salir se sueltan las partidas creadas (ciclos de referencias; proceso/24, paso 6e).
func _finalize() -> void:
	Sim.soltar_todas()
