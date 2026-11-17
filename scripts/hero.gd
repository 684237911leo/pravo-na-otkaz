extends Node3D

const SKIN := Color(0.88, 0.68, 0.55)
const HAIR := Color(0.5, 0.22, 0.08)
const HAIR_LIGHT := Color(0.78, 0.42, 0.14)
const JACKET := Color(0.27, 0.3, 0.14)
const SWEATER := Color(0.78, 0.64, 0.58)
const PANTS := Color(0.22, 0.13, 0.1)
const BOOT := Color(0.1, 0.07, 0.06)
const LEATHER := Color(0.3, 0.17, 0.08)
const METAL := Color(0.75, 0.75, 0.8)
const GLOVE := Color(0.06, 0.06, 0.07)

var _mats := {}
var _body: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _t := 0.0
var _phase := 0.0
var _w := 0.0
var _moving := false

func set_moving(v: bool) -> void:
	_moving = v

func _m(c: Color, rough: float) -> StandardMaterial3D:
	var key := str(c) + str(rough)
	if _mats.has(key):
		return _mats[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = rough
	_mats[key] = mat
	return mat

func _box(parent: Node3D, size: Vector3, pos: Vector3, c: Color, rough: float = 0.8) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.material_override = _m(c, rough)
	m.position = pos
	parent.add_child(m)

func _ball(parent: Node3D, r: float, pos: Vector3, c: Color, rough: float = 0.7) -> void:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	m.mesh = s
	m.material_override = _m(c, rough)
	m.position = pos
	parent.add_child(m)

func _arm(body: Node3D, side: float) -> Node3D:
	var sh := Node3D.new()
	sh.position = Vector3(side * 0.34, 1.46, 0.0)
	sh.rotation.x = 0.45
	sh.rotation.z = side * 0.12
	body.add_child(sh)
	_box(sh, Vector3(0.15, 0.3, 0.15), Vector3(0, -0.15, 0), JACKET)
	var el := Node3D.new()
	el.position = Vector3(0, -0.3, 0)
	el.rotation.x = 1.5
	sh.add_child(el)
	_box(el, Vector3(0.12, 0.24, 0.12), Vector3(0, -0.12, 0), SKIN)
	_box(el, Vector3(0.15, 0.13, 0.15), Vector3(0, -0.29, 0), GLOVE)
	return sh

func _leg(body: Node3D, side: float, zf: float) -> Node3D:
	var hip := Node3D.new()
	hip.position = Vector3(side * 0.16, 0.99, zf)
	body.add_child(hip)
	_box(hip, Vector3(0.3, 0.36, 0.44), Vector3(0, -0.81, -0.04), BOOT, 0.5)
	_box(hip, Vector3(0.32, 0.06, 0.46), Vector3(0, -0.96, -0.04), LEATHER, 0.6)
	_box(hip, Vector3(0.31, 0.66, 0.33), Vector3(0, -0.33, 0), PANTS)
	_box(hip, Vector3(0.09, 0.2, 0.2), Vector3(side * 0.18, -0.29, 0), PANTS)
	return hip

func _process(delta: float) -> void:
	_t += delta
	var target_w := 1.0 if _moving else 0.0
	_w = lerpf(_w, target_w, clampf(delta * 10.0, 0.0, 1.0))
	if _moving:
		_phase += delta * 10.0
	var sw := sin(_phase) * 0.75 * _w
	var idle := 1.0 - _w
	_leg_l.rotation.x = sw
	_leg_r.rotation.x = -sw
	_arm_l.rotation.x = 0.45 - sw * 0.5 + sin(_t * 2.0) * 0.03 * idle
	_arm_r.rotation.x = 0.45 + sw * 0.5 + sin(_t * 2.0 + 1.0) * 0.03 * idle
	_body.position.y = absf(sin(_phase)) * 0.06 * _w + sin(_t * 2.0) * 0.02 * idle
	_body.rotation.x = -0.12 * _w

func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	var body := _body

	# Ноги (шарниры в бёдрах)
	_leg_l = _leg(body, -1.0, -0.05)
	_leg_r = _leg(body, 1.0, 0.04)

	# Ремень, пряжка, цепь
	_box(body, Vector3(0.58, 0.09, 0.36), Vector3(0, 1.0, 0), LEATHER, 0.6)
	_box(body, Vector3(0.1, 0.08, 0.03), Vector3(0, 1.0, -0.19), METAL, 0.3)
	for i in 5:
		_ball(body, 0.03, Vector3(-0.3, 0.98 - i * 0.05, -0.12 + sin(i * 1.3) * 0.03), METAL, 0.3)

	# Свитер и куртка
	_box(body, Vector3(0.5, 0.52, 0.3), Vector3(0, 1.27, 0), SWEATER)
	_box(body, Vector3(0.58, 0.54, 0.1), Vector3(0, 1.27, 0.16), JACKET)
	for side in [-1.0, 1.0]:
		_box(body, Vector3(0.12, 0.54, 0.36), Vector3(side * 0.29, 1.27, 0.0), JACKET)
		_box(body, Vector3(0.22, 0.1, 0.34), Vector3(side * 0.28, 1.52, 0.0), JACKET)

	# Руки (шарниры в плечах)
	_arm_l = _arm(body, -1.0)
	_arm_r = _arm(body, 1.0)

	# Шея и голова
	_box(body, Vector3(0.12, 0.1, 0.12), Vector3(0, 1.57, 0), SKIN)
	_ball(body, 0.17, Vector3(0, 1.68, 0), SKIN, 0.6)
	_box(body, Vector3(0.03, 0.04, 0.04), Vector3(0, 1.65, -0.175), SKIN, 0.6)
	_box(body, Vector3(0.045, 0.045, 0.02), Vector3(-0.065, 1.7, -0.16), Color(0.05, 0.05, 0.05), 0.3)
	_box(body, Vector3(0.045, 0.045, 0.02), Vector3(0.065, 1.7, -0.16), Color(0.05, 0.05, 0.05), 0.3)
	_box(body, Vector3(0.075, 0.015, 0.02), Vector3(-0.065, 1.75, -0.16), HAIR)
	_box(body, Vector3(0.075, 0.015, 0.02), Vector3(0.065, 1.75, -0.16), HAIR)
	_box(body, Vector3(0.08, 0.025, 0.02), Vector3(0, 1.6, -0.158), Color(0.7, 0.2, 0.2), 0.5)
	_ball(body, 0.025, Vector3(-0.17, 1.62, 0), Color(0.9, 0.7, 0.2), 0.3)
	_ball(body, 0.025, Vector3(0.17, 1.62, 0), Color(0.9, 0.7, 0.2), 0.3)

	# Кудрявые волосы
	_ball(body, 0.21, Vector3(0, 1.75, 0.07), HAIR)
	for i in 22:
		var a := i * TAU / 22.0
		var x := cos(a) * 0.2
		var z := sin(a) * 0.2 + 0.03
		if z < -0.06 and absf(x) < 0.11:
			continue
		var y := 1.74 + sin(i * 1.7) * 0.08
		var col := HAIR_LIGHT if i % 3 == 0 else HAIR
		_ball(body, 0.1, Vector3(x, y, z), col)
	for k in 3:
		_ball(body, 0.09, Vector3(-0.1 + k * 0.1, 1.84, -0.08), HAIR_LIGHT if k == 1 else HAIR)
	for row in 4:
		for k in 3:
			var col2 := HAIR_LIGHT if (row + k) % 2 == 0 else HAIR
			_ball(body, 0.1, Vector3(-0.15 + k * 0.15, 1.56 - row * 0.15, 0.2 + row * 0.01), col2)
