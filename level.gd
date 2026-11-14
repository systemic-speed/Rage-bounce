extends Node2D

@onready var score_label: Label = $CanvasLayer/Label

const FLOOR_Y: float = 600.0
const SCROLL_SPEED: float = 500.0
const HAZARD_TEXTURE_PATH = "res://3_spikes.png"

var score: float = 0.0
var hazards: Array = []
var floor_segments: Array = []

func _ready() -> void:
	# 1. Create scrolling floor chunks
	for i in range(3):
		var segment = create_floor_segment()
		segment.global_position = Vector2(i * 1200.0, FLOOR_Y)
		add_child(segment)
		floor_segments.append(segment)

	# 2. Create hazards with wider random spacing ahead
	var spawn_x = 1000.0
	for i in range(4):
		var hazard = create_hazard()
		hazard.global_position = Vector2(spawn_x, FLOOR_Y)
		add_child(hazard)
		hazards.append(hazard)
		spawn_x += randf_range(600.0, 950.0)

func _process(delta: float) -> void:
	score += delta * 10.0
	if score_label:
		score_label.text = "SCORE: " + str(int(score))

	# Scroll floor chunks left and loop them
	for seg in floor_segments:
		seg.global_position.x -= SCROLL_SPEED * delta
		if seg.global_position.x <= -1200.0:
			var max_x = -1200.0
			for s in floor_segments:
				if s.global_position.x > max_x:
					max_x = s.global_position.x
			seg.global_position.x = max_x + 1200.0

	# Scroll hazards left and respawn them with wider random gaps
	for hazard in hazards:
		hazard.global_position.x -= SCROLL_SPEED * delta
		if hazard.global_position.x <= -100.0:
			var max_x = 0.0
			for h in hazards:
				if h.global_position.x > max_x:
					max_x = h.global_position.x
			hazard.global_position.x = max_x + randf_range(650.0, 1000.0)

func create_floor_segment() -> StaticBody2D:
	var body = StaticBody2D.new()
	var collision = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(1200.0, 64.0)
	collision.shape = rect
	collision.position = Vector2(600.0, 32.0)
	body.add_child(collision)
	
	var color = ColorRect.new()
	color.size = Vector2(1200.0, 64.0)
	color.color = Color(0.2, 0.2, 0.25)
	body.add_child(color)
	return body

func create_hazard() -> Area2D:
	var hazard = Area2D.new()
	hazard.z_index = 10
	
	if ResourceLoader.exists(HAZARD_TEXTURE_PATH):
		var sprite = Sprite2D.new()
		sprite.texture = load(HAZARD_TEXTURE_PATH)
		sprite.position = Vector2(0.0, -sprite.texture.get_height() / 2.0)
		hazard.add_child(sprite)
		
		# Full collision box matching the entire sprite size
		var h_collision = CollisionShape2D.new()
		var h_rect = RectangleShape2D.new()
		h_rect.size = Vector2(sprite.texture.get_width() * 0.9, sprite.texture.get_height() * 0.9)
		h_collision.shape = h_rect
		h_collision.position = Vector2(0.0, -sprite.texture.get_height() / 2.0)
		hazard.add_child(h_collision)
	else:
		var h_collision = CollisionShape2D.new()
		var h_rect = RectangleShape2D.new()
		h_rect.size = Vector2(40.0, 40.0)
		h_collision.shape = h_rect
		h_collision.position = Vector2(0.0, -20.0)
		hazard.add_child(h_collision)
		
		var fallback = ColorRect.new()
		fallback.size = Vector2(40.0, 40.0)
		fallback.position = Vector2(-20.0, -40.0)
		fallback.color = Color(1.0, 0.0, 0.0)
		hazard.add_child(fallback)
	
	hazard.body_entered.connect(func(body):
		if body.name == "Player" or body is CharacterBody2D:
			get_tree().reload_current_scene()
	)
	
	return hazard
