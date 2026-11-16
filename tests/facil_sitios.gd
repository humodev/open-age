extends SceneTree
## La IA que no toma sitios (`toma_sitios: false`, la fácil) no los captura al pasar
## (proceso/24, paso 4j). Jugador 0 pasivo (sin IA) contra la fácil; se anota cada sitio
## que toma la IA y con qué órdenes estaban sus unidades en el radio en ese momento.
## Uso: godot --headless --path . -s tests/facil_sitios.gd -- --minutes=30 --seeds=7,21,3
## Con --hitos=no la partida no termina por conquista (la IA arrasa todo) y se ve más tiempo.

const O := SimEntity.Order
const NOMBRE := ["ociosa", "mueve", "ataque-mov", "ataca", "junta", "vuelve", "construye", "refugio", "quieta"]


func _init() -> void:
	var args := {"minutes": "30", "seeds": "7,21,3", "hitos": "si", "civ": "tawantinsuyu"}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var total := 0
	for sd_s in String(args["seeds"]).split(","):
		var sd := int(sd_s)
		var opts := {"civs": ["guaranies", args["civ"]], "terreno": "llano"}
		if args["hitos"] == "no":
			opts["hitos_sin_victoria"] = true
		var s := Sim.new(sd, 2, null, opts)
		s.ais = [SimAI.new(s, 1, "facil")]
		var r: int = s.data.reglas["sitios"]["radio"]
		var caps := 0
		var dentro := 0 # ticks-unidad de la IA parada (ociosa) dentro del radio de un sitio ajeno
		while s.tick < int(args["minutes"]) * 600 and not s.game_over:
			s.step()
			for ev in s.events:
				if ev["t"] == "sitio" and ev["player"] == 1:
					caps += 1
					var site: SimEntity = s.by_id.get(ev["id"])
					print("  semilla %d  %s  la fácil toma un sitio  %s" % [sd, _t(s.tick), _orders(s, site, r)])
			if s.tick % 10 == 0:
				for e in s.actives:
					if e.alive and e.owner == 1 and e.is_unit() and e.order == O.IDLE and e.inside < 0:
						for st in s.actives:
							if st.alive and st.def.get("sagrado", false) and st.holder != 1 and absi(e.x - st.x) <= r and absi(e.y - st.y) <= r:
								dentro += 1
								break
		total += caps
		print("semilla %2d  %s  sitios tomados por la fácil: %d  ociosa en un sitio (unidad·s): %d  %s" % [sd, _t(s.tick), caps, dentro, ("ganó %d (%s)" % [s.winner, s.end_reason]) if s.game_over else "sigue"])
	print("FACIL_SITIOS: %s (%d sitios tomados)" % ["OK" if total == 0 else "FALLO", total])
	quit(0 if total == 0 else 1)


func _orders(s: Sim, site: SimEntity, r: int) -> String:
	if site == null:
		return ""
	var c := {}
	for e in s.actives:
		if e.alive and e.owner == 1 and e.is_unit() and absi(e.x - site.x) <= r and absi(e.y - site.y) <= r:
			var k: String = NOMBRE[e.order] + ("/" + e.type)
			c[k] = int(c.get(k, 0)) + 1
	return str(c)


func _t(tick: int) -> String:
	var sec := tick / 10
	return "%02d:%02d" % [sec / 60, sec % 60]
