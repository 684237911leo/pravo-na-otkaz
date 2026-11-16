extends Node3D

const SPEED := 7.0
const DASH_SPEED := 26.0
const DASH_TIME := 0.18
const DASH_COOLDOWN := 1.0
const CAM_OFFSET := Vector3(12, 14, 12)

var player: CharacterBody3D
var cam: Camera3D
var target := Vector3.ZERO
var has_target := false
var holding := false
var facing := Vector3(0, 0, -1)
var dash_dir := Vector3.ZERO
var dash_left := 0.0
var dash_cd := 0.0


func _ready() -> void:
	_build_world()
	_build_player()
	_build_ui()


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
	cam.size = 16.0
	add_child(cam)
	_update_camera()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var btn := Button.new()
	btn.text = "Рывок"
	btn.add_theme_font_size_override("font_size", 36)
	btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn.offset_left = -260
	btn.offset_top = -160
	btn.offset_right = -40
	btn.offset_bottom = -40
	btn.pressed.connect(_on_dash)
	layer.add_child(btn)
	var hint := Label.new()
	hint.text = "Тап: идти. Держать: вести. Кнопка: рывок"
	hint.position = Vector2(20, 16)
	layer.add_child(hint)


func _update_camera() -> void:
	cam.position = player.position + CAM_OFFSET
	cam.look_at(player.position, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		holding = event.pressed
		if event.pressed:
			_set_target(event.position)
	elif event is InputEventMouseMotion and holding:
		_set_target(event.position)


func _set_target(screen_pos: Vector2) -> void:
	var from := cam.project_ray_origin(screen_pos)
	var dir := cam.project_ray_normal(screen_pos)
	var hit = Plane(Vector3.UP, 0.0).intersects_ray(from, dir)
	if hit != null:
		target = hit
		has_target = true


func _on_dash() -> void:
	if dash_cd > 0.0:
		return
	dash_dir = facing
	dash_left = DASH_TIME
	dash_cd = DASH_COOLDOWN
	has_target = false


func _physics_process(delta: float) -> void:
	dash_cd = maxf(0.0, dash_cd - delta)
	var vel := Vector3.ZERO
	if dash_left > 0.0:
		dash_left -= delta
		vel = dash_dir * DASH_SPEED
	elif has_target:
		var diff := target - player.position
		diff.y = 0.0
		if diff.length() > 0.15:
			var d := diff.normalized()
			vel = d * SPEED
			facing = d
		else:
			has_target = false
	player.velocity = vel
	player.move_and_slide()
	player.position.x = clampf(player.position.x, -19.0, 19.0)
	player.position.z = clampf(player.position.z, -19.0, 19.0)
	player.rotation.y = atan2(-facing.x, -facing.z)
	_update_camera()
