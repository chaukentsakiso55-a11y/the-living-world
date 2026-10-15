extends Node3D

const SPEED := 5.0
const RUN_SPEED := 9.0
var player: Node3D
var robot: Node3D
var camera: Camera3D
var npcs: Array[Node3D] = []
var npc_origins: Array[Vector3] = []
var world_minutes := 465.0
var time_multiplier := 6.0
var director_mode := false
var robot_control := false
var npc_motion := true
var night_mode := false
var elapsed := 0.0
var hud: Label
var help: Label
var director_panel: Label
var ground_material: StandardMaterial3D
var lesson_ui: Control
var lesson_text: Label
var lesson_answer: LineEdit
var lesson_feedback: Label
var active_lesson := "maths_g10_linear"
var progress: Dictionary = {}

func _ready() -> void:
	_build_world()
	_build_ui()
	_build_lesson_ui()
	progress = GameSettings.load_progress()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.88
	return m

func _block(parent: Node3D, name: String, pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	parent.add_child(body)
	body.position = pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(color)
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var collider := BoxShape3D.new()
	collider.size = size
	shape.shape = collider
	body.add_child(shape)
	return body

func _build_world() -> void:
	var sky := WorldEnvironment.new()
	add_child(sky)
	sky.environment = Environment.new()
	sky.environment.background_mode = Environment.BG_COLOR
	sky.environment.background_color = Color(0.54, 0.72, 0.86)
	sky.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.environment.ambient_light_color = Color(0.85, 0.85, 0.8)
	sky.environment.ambient_light_energy = 0.8
	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.rotation_degrees = Vector3(-50, -25, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = false
	_block(self, "Ground", Vector3(0, -0.35, 0), Vector3(100, 0.6, 100), Color(0.42, 0.58, 0.33))
	_block(self, "Courtyard", Vector3(0, 0, 3), Vector3(28, 0.12, 23), Color(0.74, 0.68, 0.56))
	for item in [[-18.0, 8.0, 9.0, 28.0], [18.0, 8.0, 9.0, 28.0], [0.0, 25.0, 32.0, 7.0]]:
		var x: float = item[0]
		var z: float = item[1]
		var width: float = item[2]
		var depth: float = item[3]
		_block(self, "Classroom Block", Vector3(x, 2, z), Vector3(width, 4, depth), Color(0.85, 0.75, 0.57))
		_block(self, "Corrugated Roof", Vector3(x, 4.3, z), Vector3(width + 0.8, 0.45, depth + 0.8), Color(0.3, 0.35, 0.4))
	for x in [-18.0, 18.0]:
		for z in [-2.0, 5.0, 12.0, 19.0]:
			var side := 1.0 if x < 0 else -1.0
			_block(self, "Window", Vector3(x + side * 4.55, 2.4, z), Vector3(0.12, 1.2, 2.1), Color(0.24, 0.46, 0.54))
	for spot in [Vector2(-32, -12), Vector2(32, -13), Vector2(-29, 32), Vector2(29, 33)]:
		_block(self, "Tree Trunk", Vector3(spot.x, 1.6, spot.y), Vector3(0.6, 3.2, 0.6), Color(0.37, 0.24, 0.14))
		_block(self, "Tree Canopy", Vector3(spot.x, 4.2, spot.y), Vector3(4, 3.1, 4), Color(0.18, 0.4, 0.2))
	player = Node3D.new()
	player.name = "Playable Student"
	add_child(player)
	player.position = Vector3(0, 0, -8)
	_block(player, "Legs", Vector3(0, 0.5, 0), Vector3(0.7, 1, 0.5), Color(0.15, 0.18, 0.27))
	_block(player, "Uniform", Vector3(0, 1.45, 0), Vector3(0.9, 0.9, 0.6), Color(0.12, 0.28, 0.6))
	_block(player, "Head", Vector3(0, 2.2, 0), Vector3(0.6, 0.6, 0.6), Color(0.43, 0.27, 0.2))
	robot = Node3D.new()
	robot.name = "Science Club Robot"
	add_child(robot)
	robot.position = Vector3(4, 0, 0)
	_block(robot, "Base", Vector3(0, 0.3, 0), Vector3(0.9, 0.6, 0.85), Color(0.23, 0.29, 0.34))
	_block(robot, "Body", Vector3(0, 1.05, 0), Vector3(1, 1.1, 0.8), Color(0.78, 0.85, 0.88))
	_block(robot, "Display", Vector3(0, 1.3, -0.44), Vector3(0.7, 0.4, 0.08), Color(0.1, 0.35, 0.5))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1402
	for i in range(14):
		var npc := Node3D.new()
		npc.name = "Student NPC %02d" % i
		add_child(npc)
		npc.position = Vector3(rng.randf_range(-11, 11), 0, rng.randf_range(-5, 16))
		_block(npc, "Uniform", Vector3(0, 1, 0), Vector3(0.7, 1.35, 0.5), Color(0.14, 0.28 + (i % 3) * 0.06, 0.6))
		_block(npc, "Head", Vector3(0, 1.95, 0), Vector3(0.55, 0.55, 0.55), Color(0.43, 0.27, 0.2))
		npcs.append(npc)
		npc_origins.append(npc.position)
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	camera.fov = 65

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Label.new()
	hud.position = Vector2(22, 20)
	hud.add_theme_color_override("font_color", Color.WHITE)
	hud.add_theme_font_size_override("font_size", 20)
	canvas.add_child(hud)
	help = Label.new()
	help.position = Vector2(22, 652)
	help.text = "WASD Move  |  Shift Run  |  L Lesson  |  F1 Director  |  Esc Quit"
	help.add_theme_color_override("font_color", Color.WHITE)
	canvas.add_child(help)
	director_panel = Label.new()
	director_panel.position = Vector2(875, 24)
	director_panel.add_theme_font_size_override("font_size", 17)
	director_panel.add_theme_color_override("font_color", Color(1, 0.95, 0.65))
	canvas.add_child(director_panel)

func _build_lesson_ui() -> void:
	var canvas := get_node("CanvasLayer") as CanvasLayer
	lesson_ui = PanelContainer.new()
	lesson_ui.position = Vector2(260, 95)
	lesson_ui.custom_minimum_size = Vector2(760, 480)
	canvas.add_child(lesson_ui)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	lesson_ui.add_child(content)
	lesson_text = Label.new()
	lesson_text.custom_minimum_size = Vector2(720, 300)
	lesson_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(lesson_text)
	lesson_answer = LineEdit.new()
	lesson_answer.placeholder_text = "Your answer"
	content.add_child(lesson_answer)
	var submit := Button.new()
	submit.text = "Submit answer"
	submit.pressed.connect(_submit_lesson)
	content.add_child(submit)
	lesson_feedback = Label.new()
	lesson_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(lesson_feedback)
	lesson_ui.visible = false

func _toggle_lesson() -> void:
	lesson_ui.visible = not lesson_ui.visible
	if lesson_ui.visible:
		var data := LessonLibrary.get_lesson(active_lesson)
		lesson_text.text = "%s - Grade %s\\n%s\\n\\nObjective: %s\\n\\n%s\\n\\nQuestion: %s" % [data["subject"], data["grade"], data["title"], data["objective"], data["explanation"], data["question"]]
		lesson_feedback.text = ""
		lesson_answer.text = ""

func _submit_lesson() -> void:
	var data := LessonLibrary.get_lesson(active_lesson)
	if LessonLibrary.check_answer(active_lesson, lesson_answer.text):
		lesson_feedback.text = "Correct! Lesson completed."
		var completed: Array = progress.get("completed_lessons", [])
		if not completed.has(active_lesson):
			completed.append(active_lesson)
			progress["completed_lessons"] = completed
			progress["correct_answers"] = int(progress.get("correct_answers", 0)) + 1
			GameSettings.save_progress(progress)
	else:
		lesson_feedback.text = "Not quite. " + str(data["feedback"])

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_L:
		_toggle_lesson()
		return
	if lesson_ui.visible:
		return
	match event.keycode:
		KEY_F1:
			director_mode = not director_mode
		KEY_TAB:
			if director_mode:
				robot_control = not robot_control
		KEY_1:
			if director_mode:
				time_multiplier = 1
		KEY_2:
			if director_mode:
				time_multiplier = 6
		KEY_3:
			if director_mode:
				time_multiplier = 18
		KEY_P:
			if director_mode:
				npc_motion = not npc_motion
		KEY_N:
			if director_mode:
				night_mode = not night_mode
				var environment := get_node("WorldEnvironment") as WorldEnvironment
				environment.environment.background_color = Color(0.05, 0.08, 0.16) if night_mode else Color(0.54, 0.72, 0.86)
		KEY_ESCAPE:
			get_tree().quit()

func _process(delta: float) -> void:
	var dt := minf(delta, 0.08)
	elapsed += dt
	world_minutes = fposmod(world_minutes + dt * time_multiplier, 1440)
	if lesson_ui.visible:
		return
	var active := robot if robot_control else player
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		direction.y += 1
	if Input.is_key_pressed(KEY_S):
		direction.y -= 1
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_key_pressed(KEY_D):
		direction.x += 1
	if direction.length() > 0:
		var speed := RUN_SPEED if Input.is_key_pressed(KEY_SHIFT) else SPEED
		var move := direction.normalized() * speed * dt
		active.position.x = clampf(active.position.x + move.x, -45, 45)
		active.position.z = clampf(active.position.z + move.y, -45, 45)
	if npc_motion:
		for i in range(npcs.size()):
			var phase := i * 1.7
			npcs[i].position.x = npc_origins[i].x + sin(elapsed * 0.3 + phase) * 2.0
			npcs[i].position.z = npc_origins[i].z + cos(elapsed * 0.3 + phase) * 2.0
	camera.position = active.position + Vector3(0, 12, 18)
	camera.look_at(active.position + Vector3(0, 1.4, 0), Vector3.UP)
	var hour := int(world_minutes / 60)
	var minute := int(world_minutes) % 60
	hud.text = "THE LIVING WORLD | Development Build\nMonday - Term 1 | %02d:%02d\nCharacter: %s | NPCs: %d" % [hour, minute, "ROBOT" if robot_control else "STUDENT", npcs.size()]
	director_panel.text = "DIRECTOR MODE\nTab: Student / Robot\n1: 1x  2: 6x  3: 18x\nP: NPC Movement  N: Sky\nSpeed: %sx\nNPCs: %s" % [str(time_multiplier), "Active" if npc_motion else "Paused"] if director_mode else ""
