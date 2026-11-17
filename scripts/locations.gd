extends Node3D

func clear_all() -> void:
	for c in get_children():
		c.queue_free()

func _box(size: Vector3, pos: Vector3, color: Color, glow: bool = false) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.5
	m.material_override = mat
	m.position = pos
	add_child(m)

func _light(pos: Vector3, color: Color, energy: float, rng: float) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	add_child(l)

func _env(bg: Color, amb: Color, fog_density: float) -> void:
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = bg
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = amb
	e.ambient_light_energy = 0.5
	e.fog_enabled = true
	e.fog_light_color = amb
	e.fog_density = fog_density
	var we := WorldEnvironment.new()
	we.environment = e
	add_child(we)

func build_office() -> void:
	clear_all()
	_env(Color(0.04, 0.04, 0.06), Color(0.3, 0.22, 0.14), 0.01)
	var wall := Color(0.32, 0.26, 0.2)
	var wood := Color(0.35, 0.2, 0.1)
	_box(Vector3(12, 0.2, 12), Vector3(0, -0.1, 0), Color(0.25, 0.16, 0.1))
	_box(Vector3(12, 4, 0.3), Vector3(0, 2, -6), wall)
	_box(Vector3(0.3, 4, 12), Vector3(-6, 2, 0), wall)
	_box(Vector3(3, 0.2, 1.4), Vector3(0, 1, -3), wood)
	_box(Vector3(0.2, 1, 0.2), Vector3(-1.3, 0.5, -3.5), wood)
	_box(Vector3(0.2, 1, 0.2), Vector3(1.3, 0.5, -3.5), wood)
	_box(Vector3(0.2, 1, 0.2), Vector3(-1.3, 0.5, -2.5), wood)
	_box(Vector3(0.2, 1, 0.2), Vector3(1.3, 0.5, -2.5), wood)
	_box(Vector3(0.4, 0.3, 0.3), Vector3(0.8, 1.25, -3), Color(0.9, 0.7, 0.3), true)
	_box(Vector3(0.6, 3, 2.5), Vector3(-5.6, 1.5, 2), wood)
	_box(Vector3(0.1, 1.6, 1.6), Vector3(-5.85, 2.2, -2.5), Color(0.35, 0.45, 0.7), true)
	_box(Vector3(0.8, 3, 0.6), Vector3(4, 1.5, -5.5), Color(0.2, 0.12, 0.07))
	_box(Vector3(0.5, 0.5, 0.05), Vector3(4, 2.4, -5.15), Color(0.9, 0.85, 0.6), true)
	_light(Vector3(0.8, 2.0, -2.5), Color(1.0, 0.7, 0.35), 3.0, 10.0)
	_light(Vector3(-4.5, 2.5, -2.5), Color(0.4, 0.5, 0.9), 1.0, 8.0)
