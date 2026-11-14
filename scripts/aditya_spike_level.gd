extends Node2D

@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var camera: Camera2D = $Camera2D

const FLOOR_TOP_Y: float = 360.0
const FLOOR_THICKNESS: float = 64.0
const HAZARD_TEXTURE_PATH = "res://assets/imgs/aditya_spike/3_spikes.png"

var score: int = 0
var hazards: Array = []
var player: CharacterBody2D

func _ready() -> void:
	_resolve_player()
	_setup_floor()
	_setup_hazards()
	_update_camera(true)

func _resolve_player() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not player:
		player = get_node_or_null("../Player") as CharacterBody2D
	if not player and get_parent():
		for child in get_parent().get_children():
			if child is CharacterBody2D and (child.name == "Player" or child.is_in_group("player")):
				player = child
				break

func _setup_floor() -> void:
	# Continuous runner floor (solid collision for the player).
	var floor_body = StaticBody2D.new()
	floor_body.name = "RunFloor"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 1

	var collision = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(20000.0, FLOOR_THICKNESS)
	collision.shape = rect
	collision.position = Vector2(10000.0, FLOOR_THICKNESS / 2.0)
	floor_body.add_child(collision)

	var visual = ColorRect.new()
	visual.size = Vector2(20000.0, FLOOR_THICKNESS)
	visual.position = Vector2(0.0, 0.0)
	visual.color = Color(0.18, 0.2, 0.25, 1.0)
	visual.z_index = 0
	floor_body.add_child(visual)

	var top_line = ColorRect.new()
	top_line.size = Vector2(20000.0, 4.0)
	top_line.position = Vector2(0.0, 0.0)
	top_line.color = Color(0.45, 0.55, 0.7, 1.0)
	floor_body.add_child(top_line)

	floor_body.global_position = Vector2(-500.0, FLOOR_TOP_Y)
	add_child(floor_body)

func _setup_hazards() -> void:
	for i in range(8):
		var hazard = create_hazard()
		hazard.global_position = Vector2(700.0 + (i * 380.0), FLOOR_TOP_Y)
		add_child(hazard)
		hazards.append(hazard)

func _process(_delta: float) -> void:
	if not player or not is_instance_valid(player):
		_resolve_player()
		if not player:
			return

	_update_camera()

	score = int(maxf(player.global_position.x, 0.0) / 32.0)
	if score_label:
		score_label.text = "SCORE: " + str(score)

	# Recycle hazards ahead of the player for a continuous spike run.
	var max_x = player.global_position.x
	for h in hazards:
		if h.global_position.x > max_x:
			max_x = h.global_position.x
	for hazard in hazards:
		if hazard.global_position.x < player.global_position.x - 500.0:
			hazard.global_position.x = max_x + randf_range(320.0, 520.0)
			max_x = hazard.global_position.x

func _update_camera(snap: bool = false) -> void:
	if not camera or not player or not is_instance_valid(player):
		return
	if not camera.enabled:
		camera.enabled = true
	camera.make_current()
	var target = Vector2(player.global_position.x + 180.0, 250.0)
	if snap:
		camera.global_position = target
	else:
		camera.global_position = camera.global_position.lerp(target, 0.15)

func create_hazard() -> Area2D:
	var hazard = Area2D.new()
	hazard.z_index = 10

	# Jumpable obstacle sizing (small spike cluster)
	var spike_width := 28.0
	var spike_height := 28.0

	# Collision box
	var h_collision = CollisionShape2D.new()
	var h_rect = RectangleShape2D.new()
	h_rect.size = Vector2(spike_width, spike_height)
	h_collision.shape = h_rect
	h_collision.position = Vector2(0.0, -spike_height / 2.0)
	hazard.add_child(h_collision)

	# Load image asset, or show a fallback spike block if file path is missing
	if ResourceLoader.exists(HAZARD_TEXTURE_PATH):
		var sprite = Sprite2D.new()
		sprite.texture = load(HAZARD_TEXTURE_PATH)
		var tex_size = sprite.texture.get_size()
		if tex_size.x > 0.0 and tex_size.y > 0.0:
			sprite.scale = Vector2(spike_width / tex_size.x, spike_height / tex_size.y)
		sprite.position = Vector2(0.0, -spike_height / 2.0)
		hazard.add_child(sprite)
	else:
		var fallback = ColorRect.new()
		fallback.size = Vector2(spike_width, spike_height)
		fallback.position = Vector2(-spike_width / 2.0, -spike_height)
		fallback.color = Color(1.0, 0.0, 0.0)
		hazard.add_child(fallback)

	# Integrate with main game's death handling when possible
	hazard.body_entered.connect(func(body):
		if body and (body.is_in_group("player") or body.name == "Player"):
			if body.has_method("die"):
				body.die()
			else:
				get_tree().reload_current_scene()
	)

	return hazard
