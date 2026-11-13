class_name OndasAgua
extends Node
## Pasa al sombreador del agua las unidades que están en el agua (vados), para
## dibujar ondas a su alrededor (etapa 16). Revisa la lista cinco veces por
## segundo y mueve las ondas cada cuadro con la posición dibujada.

const MAX := 24

var view: WorldView
var mat: ShaderMaterial
var _ids: Array[int] = []
var _t := 0.0
var _buf := PackedVector4Array()


func _ready() -> void:
	_buf.resize(MAX)


func _process(delta: float) -> void:
	if view == null or view.sim == null:
		return
	_t -= delta
	if _t <= 0.0:
		_t = 0.2
		_ids.clear()
		var map := view.sim.map
		for id in view.visuals:
			var v: Dictionary = view.visuals[id]
			if v.get("kind", "") != "unit":
				continue
			var node: Node3D = v["node"]
			if not node.visible:
				continue
			var p := node.position
			if map.is_water(int(p.x), int(p.z)):
				_ids.append(id)
				if _ids.size() >= MAX:
					break
	var n := 0
	for id in _ids:
		var v: Dictionary = view.visuals.get(id, {})
		if v.is_empty():
			continue
		var node: Node3D = v["node"]
		if not node.visible:
			continue
		_buf[n] = Vector4(node.position.x, node.position.z, float(id % 7), 0.0)
		n += 1
	mat.set_shader_parameter("units", _buf)
	mat.set_shader_parameter("unit_count", n)
