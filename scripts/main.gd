extends Node3D

const SPEED := 7.0
const DASH_SPEED := 26.0
const DASH_TIME := 0.18
const DASH_COOLDOWN := 1.0
const CAM_OFFSET := Vector3(12, 14, 12)
const ATTACK_RANGE := 2.2
const ATTACK_DMG := 12.0
const ATTACK_CD := 0.6
const VERDICT_RADIUS := 4.5
const VERDICT_DMG := 45.0
const VERDICT_CD := 4.0
const PLAYER_MAX_HP := 100.0

var player: CharacterBody3D
var cam: Camera3D
var target := Vector3.ZERO
var has_target := false
var holding := false
var facing := Vector3(0, 0, -1)
var dash_dir := Vector3.ZERO
var dash_left := 0.0
var dash_cd := 0.0

var hp := PLAYER_MAX_HP
var atk_cd := 0.0
var verdict_cd := 0.0
var attack_target = null
var enemies: Array = []
var shots: Array = []
var wave := 0
var wave_timer := 2.0
var dead := true

var hp_bar: ProgressBar
var info: Label
var verdict_btn: Button
var dash_btn: Button


func _ready() -> void:
	randomize()
	_build_world()
	_build_player()
	_build_ui()
	_start_prologue()


func _build_world() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.07)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.6)
	env.ambient_light_energy = 0.6
	env_node.environment = env
	add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	add_child(sun)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	ground.mesh = plane
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.28, 0.24, 0.21)
	ground.material_override = gmat
	add_child(ground)

	var spots := [
		Vector3(-8, 0, -8), Vector3(8, 0, -8), Vector3(-8, 0, 8),
		Vector3(8, 0, 8), Vector3(0, 0, -12), Vector3(-13, 0, 0),
		Vector3(13, 0, 0), Vector3(0, 0, 12)
	]
	for p in spots:
		_make_pillar(p)


func _make_pillar(pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos + Vector3(0, 2, 0)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2, 4, 2)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.38, 0.4)
	mesh.material_override = mat
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2, 4, 2)
	col.shape = shape
	body.add_child(col)
	add_child(body)


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.position = Vector3(0, 0.9, 0)
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.height = 1.8
	capsule.radius = 0.4
	mesh.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.5, 0.9)
	mesh.material_override = mat
	player.add_child(mesh)
	var nose := MeshInstance3D.new()
	var nb := BoxMesh.new()
	nb.size = Vector3(0.25, 0.25, 0.4)
	nose.mesh = nb
	nose.position = Vector3(0, 0.4, -0.45)
	var nmat := StandardMaterial3D.new()
	nmat.albedo_color = Color(1, 0.9, 0.3)
	nose.material_override = nmat
	player.add_child(nose)
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = 1.8
	shape.radius = 0.4
	col.shape = shape
	player.add_child(col)
	add_child(player)

	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.size = 18.0
	add_child(cam)
	_update_camera()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	hp_bar = ProgressBar.new()
	hp_bar.min_value = 0.0
	hp_bar.max_value = PLAYER_MAX_HP
	hp_bar.value = hp
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(500, 40)
	hp_bar.position = Vector2(20, 60)
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hp_bar)

	info = Label.new()
	info.position = Vector2(20, 14)
	info.add_theme_font_size_override("font_size", 30)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(info)

	dash_btn = Button.new()
	dash_btn.text = "Рывок"
	dash_btn.add_theme_font_size_override("font_size", 36)
	dash_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	dash_btn.offset_left = -260
	dash_btn.offset_top = -160
	dash_btn.offset_right = -40
	dash_btn.offset_bottom = -40
	dash_btn.pressed.connect(_on_dash)
	layer.add_child(dash_btn)

	verdict_btn = Button.new()
	verdict_btn.text = "Вердикт"
	verdict_btn.add_theme_font_size_override("font_size", 36)
	verdict_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	verdict_btn.offset_left = -260
	verdict_btn.offset_top = -300
	verdict_btn.offset_right = -40
	verdict_btn.offset_bottom = -180
	verdict_btn.pressed.connect(_on_verdict)
	layer.add_child(verdict_btn)


func _update_camera() -> void:
	cam.position = player.position + CAM_OFFSET
	cam.look_at(player.position, Vector3.UP)


func _ground_point(screen_pos: Vector2) -> Variant:
	var from := cam.project_ray_origin(screen_pos)
	var dir := cam.project_ray_normal(screen_pos)
	return Plane(Vector3.UP, 0.0).intersects_ray(from, dir)


func _enemy_at_screen(pos: Vector2) -> Variant:
	var best = null
	var best_d := 90.0
	for e in enemies:
		var n: CharacterBody3D = e["node"]
		var sp := cam.unproject_position(n.position)
		var d := sp.distance_to(pos)
		if d < best_d:
			best_d = d
			best = e
	return best


func _unhandled_input(event: InputEvent) -> void:
	if dead:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		holding = event.pressed
		if event.pressed:
			var found = _enemy_at_screen(event.position)
			if found != null:
				attack_target = found
			else:
				attack_target = null
				var hit = _ground_point(event.position)
				if hit != null:
					target = hit
					has_target = true
	elif event is InputEventMouseMotion and holding and attack_target == null:
		var hit2 = _ground_point(event.position)
		if hit2 != null:
			target = hit2
			has_target = true


func _on_dash() -> void:
	if dead or dash_cd > 0.0:
		return
	dash_dir = facing
	dash_left = DASH_TIME
	dash_cd = DASH_COOLDOWN
	has_target = false


func _on_verdict() -> void:
	if dead or verdict_cd > 0.0:
		return
	verdict_cd = VERDICT_CD
	for e in enemies.duplicate():
		var n: CharacterBody3D = e["node"]
		if n.position.distance_to(player.position) <= VERDICT_RADIUS:
			_damage_enemy(e, VERDICT_DMG)
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = VERDICT_RADIUS
	s.height = VERDICT_RADIUS * 2.0
	m.mesh = s
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.8, 0.3, 0.35)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mat
	m.position = player.position
	add_child(m)
	var tw := create_tween()
	tw.tween_property(m, "scale", Vector3(1.2, 1.2, 1.2), 0.3)
	tw.tween_callback(m.queue_free)


func _spawn_wave() -> void:
	wave += 1
	var melee_count := 2 + wave
	var ranged_count := wave
	for i in melee_count:
		_spawn_enemy("melee", _random_edge_pos())
	for i in ranged_count:
		_spawn_enemy("ranged", _random_edge_pos())


func _random_edge_pos() -> Vector3:
	var a := randf() * TAU
	return Vector3(cos(a) * 15.0, 0.0, sin(a) * 15.0)


func _spawn_enemy(kind: String, pos: Vector3) -> void:
	var body := CharacterBody3D.new()
	body.position = Vector3(pos.x, 0.8, pos.z)
	var mesh := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	var e := {"node": body, "kind": kind, "cd": 1.0}
	if kind == "melee":
		var b := BoxMesh.new()
		b.size = Vector3(1.1, 1.6, 1.1)
		mesh.mesh = b
		mat.albedo_color = Color(0.8, 0.2, 0.2)
		e["hp"] = 40.0
		e["speed"] = 3.8
	else:
		var sp := SphereMesh.new()
		sp.radius = 0.55
		sp.height = 1.1
		mesh.mesh = sp
		mat.albedo_color = Color(0.6, 0.3, 0.8)
		e["hp"] = 25.0
		e["speed"] = 2.8
	mesh.material_override = mat
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.6
	col.shape = shape
	body.add_child(col)
	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.pixel_size = 0.01
	lbl.font_size = 48
	lbl.position = Vector3(0, 1.5, 0)
	lbl.text = str(int(e["hp"]))
	body.add_child(lbl)
	e["label"] = lbl
	add_child(body)
	enemies.append(e)


func _damage_enemy(e: Dictionary, dmg: float) -> void:
	e["hp"] -= dmg
	if e["hp"] <= 0.0:
		enemies.erase(e)
		if attack_target == e:
			attack_target = null
		var n: CharacterBody3D = e["node"]
		n.queue_free()
	else:
		var lbl: Label3D = e["label"]
		lbl.text = str(int(ceil(e["hp"])))


func _hurt_player(dmg: float) -> void:
	if dead:
		return
	hp = maxf(0.0, hp - dmg)
	hp_bar.value = hp
	if hp <= 0.0:
		dead = true
		info.text = "Вы пали. Перезапуск..."
		await get_tree().create_timer(2.5).timeout
		get_tree().reload_current_scene()


func _shoot(from: Vector3, dir: Vector3) -> void:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.2
	s.height = 0.4
	m.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.4, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mat
	m.position = Vector3(from.x, 0.9, from.z)
	add_child(m)
	shots.append({"node": m, "dir": dir, "life": 3.0})


func _update_enemies(delta: float) -> void:
	for e in enemies:
		var n: CharacterBody3D = e["node"]
		var to := player.position - n.position
		to.y = 0.0
		var dist := to.length()
		var dir := to.normalized() if dist > 0.01 else Vector3.ZERO
		var spd: float = e["speed"]
		e["cd"] = maxf(0.0, e["cd"] - delta)
		var v := Vector3.ZERO
		if e["kind"] == "melee":
			if dist > 1.7:
				v = dir * spd
			elif e["cd"] <= 0.0:
				_hurt_player(8.0)
				e["cd"] = 1.0
		else:
			if dist > 9.0:
				v = dir * spd
			elif dist < 6.0:
				v = -dir * spd
			if dist <= 12.0 and e["cd"] <= 0.0:
				_shoot(n.position, dir)
				e["cd"] = 2.2
		n.velocity = v
		n.move_and_slide()


func _update_shots(delta: float) -> void:
	for i in range(shots.size() - 1, -1, -1):
		var s: Dictionary = shots[i]
		var m: MeshInstance3D = s["node"]
		m.position += s["dir"] * 10.0 * delta
		s["life"] -= delta
		var flat := Vector3(m.position.x - player.position.x, 0.0, m.position.z - player.position.z)
		if flat.length() < 0.8:
			_hurt_player(10.0)
			m.queue_free()
			shots.remove_at(i)
		elif s["life"] <= 0.0:
			m.queue_free()
			shots.remove_at(i)


func _physics_process(delta: float) -> void:
	if dead:
		return
	dash_cd = maxf(0.0, dash_cd - delta)
	atk_cd = maxf(0.0, atk_cd - delta)
	verdict_cd = maxf(0.0, verdict_cd - delta)

	if enemies.is_empty():
		wave_timer -= delta
		if wave_timer <= 0.0:
			_spawn_wave()
			wave_timer = 2.0
	else:
		wave_timer = 2.0

	if attack_target != null:
		if not enemies.has(attack_target):
			attack_target = null
		else:
			var en: CharacterBody3D = attack_target["node"]
			var diff := en.position - player.position
			diff.y = 0.0
			if diff.length() > ATTACK_RANGE:
				target = en.position
				has_target = true
			else:
				has_target = false
				facing = diff.normalized()
				if atk_cd <= 0.0:
					atk_cd = ATTACK_CD
					_damage_enemy(attack_target, ATTACK_DMG)

	var vel := Vector3.ZERO
	if dash_left > 0.0:
		dash_left -= delta
		vel = dash_dir * DASH_SPEED
	elif has_target:
		var d2 := target - player.position
		d2.y = 0.0
		if d2.length() > 0.15:
			var dn := d2.normalized()
			vel = dn * SPEED
			facing = dn
		else:
			has_target = false
	player.velocity = vel
	player.move_and_slide()
	player.position.x = clampf(player.position.x, -19.0, 19.0)
	player.position.z = clampf(player.position.z, -19.0, 19.0)
	player.rotation.y = atan2(-facing.x, -facing.z)

	_update_enemies(delta)
	_update_shots(delta)
	_update_camera()

	info.text = "Волна %d   Врагов: %d" % [wave, enemies.size()]
	if verdict_cd > 0.0:
		verdict_btn.text = "Вердикт %.1f" % verdict_cd
	else:
		verdict_btn.text = "Вердикт"

var arena_nodes: Array = []
var office: Node3D

func _start_prologue() -> void:
	for c in get_children():
		if c == player or c == cam or c is CanvasLayer:
			continue
		arena_nodes.append(c)
		remove_child(c)
	office = preload("res://scripts/locations.gd").new()
	add_child(office)
	office.build_office()
	cam.size = 12.0
	var dlg = preload("res://scripts/dialogue.gd").new()
	add_child(dlg)
	dlg.finished.connect(_on_prologue_done)
	dlg.start("res://data/prologue.json")

func _on_prologue_done(flags: Dictionary) -> void:
	office.queue_free()
	for c in arena_nodes:
		add_child(c)
	arena_nodes.clear()
	cam.size = 18.0
	dead = false
