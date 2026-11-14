extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var score_label: Label = $CanvasLayer/Label

const FLOOR_Y: float = 600.0
const HAZARD_TEXTURE_PATH = "res://spike.png" # Update path if your image is named differently or in a folder

var score: int = 0
var hazards: Array = []

func _ready() -> void:
	if not player:
		print("ERROR: Player node not found!")
		return

	# 1. Create a massive continuous floor under the track
	var floor_body = StaticBody2D.new()
	var collision = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(50000.0, 64.0)
	collision.shape = rect
	collision.position = Vector2(25000.0, 32.0)
	floor_body.add_child(collision)
	
	var color_rect = ColorRect.new()
	color_rect.size = Vector2(50000.0, 64.0)
	color_rect.color = Color(0.2, 0.2, 0.25)
	floor_body.add_child(color_rect)
	
	floor_body.global_position = Vector2(0.0, FLOOR_Y)
	add_child(floor_body)

	# 2. Create a pool of recycled hazards ahead of the player (Dino runner style)
	for i in range(6):
		var hazard = create_hazard()
		hazard.global_position = Vector2(900.0 + (i * 350.0), FLOOR_Y)
		add_child(hazard)
		hazards.append(hazard)

func _process(delta: float) -> void:
	if not player:
		return

	# Distance score counting up continuously
	score = int(player.global_position.x / 32.0)
	if score_label:
		score_label.text = "SCORE: " + str(score)

	# Recycle hazards infinitely: when one goes off-screen behind, pop it back up ahead
	for hazard in hazards:
		if hazard.global_position.x < player.global_position.x - 400.0:
			var max_x = player.global_position.x
			for h in hazards:
				if h.global_position.x > max_x:
					max_x = h.global_position.x
			
			hazard.global_position.x = max_x + randf_range(350.0, 600.0)

func create_hazard() -> Area2D:
	var hazard = Area2D.new()
	hazard.z_index = 10
	
	# Collision box
	var h_collision = CollisionShape2D.new()
	var h_rect = RectangleShape2D.new()
	h_rect.size = Vector2(36.0, 36.0)
	h_collision.shape = h_rect
	h_collision.position = Vector2(0.0, -18.0)
	hazard.add_child(h_collision)
	
	# Load image asset, or show a bright red fallback square if file path is missing
	if ResourceLoader.exists(HAZARD_TEXTURE_PATH):
		var sprite = Sprite2D.new()
		sprite.texture = load(HAZARD_TEXTURE_PATH)
		sprite.position = Vector2(0.0, -sprite.texture.get_height() / 2.0)
		hazard.add_child(sprite)
	else:
		var fallback = ColorRect.new()
		fallback.size = Vector2(36.0, 36.0)
		fallback.position = Vector2(-18.0, -36.0)
		fallback.color = Color(1.0, 0.0, 0.0)
		hazard.add_child(fallback)
	
	# Instant reset on contact
	hazard.body_entered.connect(func(body):
		if body == player:
			get_tree().reload_current_scene()
	)
	
	return hazard
