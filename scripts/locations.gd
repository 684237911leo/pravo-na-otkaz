extends Node3D

func clear_all() -> void:
	for c in get_children():
		c.queue_free()

func _mat(color: Color, rough: float = 0.8, glow: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	if glow > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = glow
	return mat

func _box(size: Vector3, pos: Vector3, color: Color, rough: float = 0.8, glow: float = 0.0, rot_y: float = 0.0, parent: Node = null) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.material_override = _mat(color, rough, glow)
	m.position = pos
	m.rotation.y = rot_y
	if parent != null:
		parent.add_child(m)
	else:
		add_child(m)
	return m

func _cyl(radius: float, height: float, pos: Vector3, color: Color, rough: float = 0.5, glow: float = 0.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = height
	m.mesh = c
	m.material_override = _mat(color, rough, glow)
	m.position = pos
	add_child(m)
	return m

func _ball(radius: float, pos: Vector3, color: Color, rough: float = 0.5, glow: float = 0.0, parent: Node = null) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	m.mesh = s
	m.material_override = _mat(color, rough, glow)
	m.position = pos
	if parent != null:
		parent.add_child(m)
	else:
		add_child(m)
	return m

func _env(bg: Color, amb: Color, amb_energy: float, fog_density: float) -> void:
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = bg
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = amb
	e.ambient_light_energy = amb_energy
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.glow_enabled = true
	e.glow_intensity = 0.9
	e.glow_hdr_threshold = 0.8
	e.adjustment_enabled = true
	e.adjustment_contrast = 1.1
	e.adjustment_saturation = 1.15
	e.fog_enabled = true
	e.fog_light_color = amb
	e.fog_density = fog_density
	var we := WorldEnvironment.new()
	we.environment = e
	add_child(we)

func build_office() -> void:
	clear_all()
	_env(Color(0.02, 0.02, 0.03), Color(0.25, 0.2, 0.28), 0.35, 0.008)

	var wood := Color(0.33, 0.19, 0.1)
	var dark_wood := Color(0.2, 0.11, 0.07)
	var brass := Color(0.75, 0.55, 0.2)

	# Пол: доски двух оттенков
	_box(Vector3(12, 0.2, 12), Vector3(0, -0.1, 0), Color(0.1, 0.06, 0.04))
	for i in 12:
		var c := Color(0.3, 0.18, 0.1) if i % 2 == 0 else Color(0.25, 0.15, 0.085)
		_box(Vector3(12, 0.06, 0.94), Vector3(0, 0.02, -5.5 + i), c, 0.55)

	# Стены, панели, планки
	_box(Vector3(12.6, 4, 0.3), Vector3(0, 2, -6.15), Color(0.3, 0.25, 0.22))
	_box(Vector3(0.3, 4, 12.6), Vector3(-6.15, 2, 0), Color(0.3, 0.25, 0.22))
	_box(Vector3(12, 1.3, 0.12), Vector3(0, 0.65, -5.94), dark_wood, 0.6)
	_box(Vector3(0.12, 1.3, 12), Vector3(-5.94, 0.65, 0), dark_wood, 0.6)
	_box(Vector3(12, 0.1, 0.18), Vector3(0, 1.35, -5.92), wood, 0.5)
	_box(Vector3(0.18, 0.1, 12), Vector3(-5.92, 1.35, 0), wood, 0.5)

	# Ковёр
	_box(Vector3(5.4, 0.03, 3.8), Vector3(0, 0.065, 0.3), Color(0.3, 0.07, 0.07), 0.95)
	_box(Vector3(4.6, 0.04, 3.0), Vector3(0, 0.075, 0.3), Color(0.5, 0.14, 0.1), 0.95)

	# Стол
	_box(Vector3(3.4, 0.16, 1.5), Vector3(0, 1.0, -3.2), wood, 0.45)
	for sx in [-1.55, 1.55]:
		for sz in [-3.8, -2.6]:
			_box(Vector3(0.18, 0.92, 0.18), Vector3(sx, 0.46, sz), dark_wood, 0.6)
	_box(Vector3(1.4, 0.45, 0.04), Vector3(0.8, 0.75, -2.43), dark_wood, 0.6)
	_box(Vector3(0.1, 0.06, 0.05), Vector3(0.8, 0.75, -2.4), brass, 0.3)

	# Кресло
	_box(Vector3(1.0, 0.1, 1.0), Vector3(0, 0.55, -4.6), Color(0.22, 0.1, 0.08), 0.5, 0.0, 0.1)
	_box(Vector3(1.0, 1.0, 0.1), Vector3(0, 1.05, -5.1), Color(0.22, 0.1, 0.08), 0.5, 0.0, 0.1)
	for cx in [-0.42, 0.42]:
		for cz in [-4.18, -5.02]:
			_box(Vector3(0.1, 0.5, 0.1), Vector3(cx, 0.25, cz), dark_wood, 0.6)

	# Предметы на столе
	_cyl(0.18, 0.05, Vector3(0.9, 1.105, -3.2), brass, 0.3)
	_cyl(0.07, 0.4, Vector3(0.9, 1.33, -3.2), Color(0.9, 0.85, 0.7), 0.9)
	_ball(0.07, Vector3(0.9, 1.6, -3.2), Color(1.0, 0.7, 0.3), 0.5, 4.0)
	_box(Vector3(0.7, 0.02, 0.5), Vector3(-0.5, 1.09, -3.1), Color(0.85, 0.8, 0.65), 0.9, 0.0, 0.25)
	_box(Vector3(0.6, 0.02, 0.45), Vector3(-0.35, 1.1, -3.25), Color(0.8, 0.75, 0.6), 0.9, 0.0, -0.3)
	_box(Vector3(0.5, 0.1, 0.38), Vector3(0.1, 1.13, -2.85), Color(0.15, 0.25, 0.3), 0.6, 0.0, -0.2)
	_cyl(0.06, 0.22, Vector3(-1.3, 1.19, -3.0), Color(0.6, 0.6, 0.65), 0.2)
	_cyl(0.09, 0.45, Vector3(-1.35, 1.31, -3.5), Color(0.1, 0.22, 0.12), 0.2)

	# Ящики в углу
	_box(Vector3(1.0, 0.8, 1.0), Vector3(-4.3, 0.4, -5.0), wood, 0.7)
	_box(Vector3(0.7, 0.5, 0.7), Vector3(-4.3, 1.05, -5.0), dark_wood, 0.7, 0.0, 0.3)

	# Картины на стене
	_box(Vector3(1.3, 1.0, 0.06), Vector3(-2, 2.8, -5.95), Color(0.4, 0.3, 0.12), 0.4)
	_box(Vector3(1.1, 0.8, 0.07), Vector3(-2, 2.8, -5.93), Color(0.12, 0.2, 0.25), 0.9)
	_box(Vector3(0.8, 1.0, 0.06), Vector3(1.2, 2.9, -5.95), Color(0.4, 0.3, 0.12), 0.4)
	_box(Vector3(0.6, 0.8, 0.07), Vector3(1.2, 2.9, -5.93), Color(0.3, 0.2, 0.15), 0.9)

	# Книжный шкаф у левой стены
	_box(Vector3(0.08, 3.2, 3.0), Vector3(-5.82, 1.6, 2.0), dark_wood, 0.6)
	_box(Vector3(0.7, 3.2, 0.1), Vector3(-5.5, 1.6, 0.5), wood, 0.6)
	_box(Vector3(0.7, 3.2, 0.1), Vector3(-5.5, 1.6, 3.5), wood, 0.6)
	var palette := [
		Color(0.5, 0.1, 0.1), Color(0.15, 0.3, 0.2), Color(0.2, 0.2, 0.45),
		Color(0.55, 0.4, 0.15), Color(0.3, 0.12, 0.3), Color(0.12, 0.12, 0.12)
	]
	for lvl in 4:
		var y := 0.2 + lvl * 0.85
		_box(Vector3(0.7, 0.08, 3.0), Vector3(-5.5, y, 2.0), wood, 0.6)
		if lvl < 3:
			for i in 15:
				var h := 0.5 + (i % 3) * 0.08
				_box(Vector3(0.35, h, 0.13), Vector3(-5.55, y + 0.04 + h / 2.0, 0.7 + i * 0.18), palette[(i + lvl * 2) % palette.size()], 0.8)

	# Окно
	_box(Vector3(0.1, 2.0, 1.8), Vector3(-5.9, 2.3, -2.5), dark_wood, 0.5)
	_box(Vector3(0.04, 1.7, 1.5), Vector3(-5.84, 2.3, -2.5), Color(0.5, 0.65, 1.0), 0.2, 1.3)
	_box(Vector3(0.08, 1.8, 0.07), Vector3(-5.82, 2.3, -2.5), dark_wood, 0.5)
	_box(Vector3(0.08, 0.07, 1.6), Vector3(-5.82, 2.3, -2.5), dark_wood, 0.5)

	# Напольные часы с маятником
	_box(Vector3(0.9, 3.4, 0.6), Vector3(4, 1.7, -5.65), dark_wood, 0.5)
	_box(Vector3(0.55, 0.55, 0.04), Vector3(4, 2.7, -5.33), Color(0.9, 0.85, 0.6), 0.5, 0.6)
	_box(Vector3(0.04, 0.22, 0.02), Vector3(4, 2.78, -5.3), Color(0.05, 0.05, 0.05))
	_box(Vector3(0.16, 0.04, 0.02), Vector3(4.07, 2.7, -5.3), Color(0.05, 0.05, 0.05))
	_box(Vector3(0.5, 1.2, 0.04), Vector3(4, 1.5, -5.33), Color(0.03, 0.02, 0.02), 0.3)
	var pivot := Node3D.new()
	pivot.position = Vector3(4, 2.0, -5.3)
	add_child(pivot)
	_box(Vector3(0.04, 0.8, 0.02), Vector3(0, -0.4, 0), brass, 0.3, 0.0, 0.0, pivot)
	_ball(0.12, Vector3(0, -0.85, 0), brass, 0.3, 0.0, pivot)
	var tw := pivot.create_tween().set_loops()
	tw.tween_property(pivot, "rotation:z", 0.25, 0.6)
	tw.tween_property(pivot, "rotation:z", -0.25, 0.6)

	# Свет: свеча (с тенями и мерцанием), лунный луч из окна, слабая заливка
	var candle := OmniLight3D.new()
	candle.position = Vector3(0.9, 1.75, -3.2)
	candle.light_color = Color(1.0, 0.68, 0.35)
	candle.light_energy = 2.5
	candle.omni_range = 11.0
	candle.shadow_enabled = true
	add_child(candle)
	var ftw := candle.create_tween().set_loops()
	ftw.tween_property(candle, "light_energy", 2.0, 0.12)
	ftw.tween_property(candle, "light_energy", 2.8, 0.18)
	ftw.tween_property(candle, "light_energy", 2.3, 0.1)

	var moon := SpotLight3D.new()
	moon.position = Vector3(-5.5, 2.3, -2.5)
	moon.light_color = Color(0.55, 0.65, 1.0)
	moon.light_energy = 4.0
	moon.spot_range = 16.0
	moon.spot_angle = 35.0
	moon.shadow_enabled = true
	add_child(moon)
	moon.look_at(Vector3(0.5, 0.0, -1.5), Vector3.UP)

	var fill := OmniLight3D.new()
	fill.position = Vector3(0, 3.5, 1)
	fill.light_color = Color(1.0, 0.8, 0.6)
	fill.light_energy = 0.5
	fill.omni_range = 14.0
	add_child(fill)
