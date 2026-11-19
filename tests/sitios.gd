extends SceneTree
## Sitios sagrados en mapas de varios (jugadores de prueba, proceso/22): al menos uno por
## jugador en todos los terrenos con agua y fortines. El del centro puede faltar si es un lago.
## Uso: godot --headless --path . -s tests/sitios.gd
func _init() -> void:
	var civs := ["guaranies", "mapuches", "etiopia", "palmares", "ayutthaya", "tawantinsuyu", "guaranies", "mapuches"]
	var fails := 0
	for t in ["islas", "rio", "fortines", "bosque", "delta", "llano"]:
		for np in [3, 4, 6, 8]:
			var worst := 99
			for sd in 6:
				var s := Sim.new(5 + sd * 48, np, null, {"civs": civs.slice(0, np), "terreno": t})
				var n := 0
				for e in s.entities:
					if e.alive and e.def.get("sagrado", false):
						n += 1
				worst = mini(worst, n)
			if worst < np:
				fails += 1
				print("  FALLA %s con %d jugadores: %d sitios" % [t, np, worst])
	# --- esport 1a --- se toman desde la II (reglas.sitios.captura_edad_min): en la I no
	var sc := Sim.new(11, 2, null, {"civs": ["guaranies", "mapuches"], "terreno": "llano"})
	var site: SimEntity = null
	for e in sc.entities:
		if e.alive and e.def.get("sagrado", false) and site == null:
			site = e
	var cap_ticks := int(sc.data.reglas["sitios"]["captura_ms"]) / sc.tick_ms + 30
	sc.spawn_unit("guerrero", 0, site.x + 1500, site.y)
	for k in cap_ticks:
		sc.step()
	var in_i := site.holder
	sc.players[0]["age"] = 2
	for k in cap_ticks:
		sc.step()
	var ok_age := in_i < 0 and site.holder == 0
	print("%s sitios: en la I no se toman (dueño %d) y en la II sí (dueño %d)" % ["OK  " if ok_age else "FALLA", in_i, site.holder])
	if not ok_age:
		fails += 1
	print("SITIOS: ", "OK" if fails == 0 else "%d fallas" % fails)
	quit()


## Al salir se sueltan las partidas creadas (ciclos de referencias; proceso/24, paso 6e).
func _finalize() -> void:
	Sim.soltar_todas()
