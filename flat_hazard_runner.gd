extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var score_label: Label = $CanvasLayer/Label

var next_spawn_x: float = 0.0
const FLOOR_Y: float = 600.0 # Height of your flat ground surface
var score: int = 0

func _ready() -> void:
	if not player:
		print("ERROR: Player node missing!")
		return
		
	# Pre-spawn a long flat floor ahead
	for i in range(15):
		spawn_floor_segment()
		
	print("Game initialized. Spawning floor & hazards...")

func _process(_delta: float) -> void:
	if not player:
		return

	# Score based on distance run
	score = int(player.global_position.x / 32.0)
	if score_label:
		score_label.text = "SCORE: " + str(score)

	# Infinite runner: Keep generating floor chunks ahead of the player
	if player.global_position.x + 1600.0 > next_spawn_x:
		spawn_floor_segment()

func spawn_floor_segment() -> void:
	var segment_width = 400.0
	
	# Create floor body
	var floor_body = StaticBody2D.new()
	var collision = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(segment_width, 64.0)
	collision.shape = rect
	collision.position = Vector2(segment_width / 2.0, 32.0)
	floor_body.add_child(collision)
	
	var color_rect = ColorRect.new()
	color_rect.size = Vector2(segment_width, 64.0)
	color_rect.color = Color(0.2, 0.2, 0.25) # Industrial floor
	floor_body.add_child(color_rect)
	
	floor_body.global_position = Vector2(next_spawn_x, FLOOR_Y)
	add_child(floor_body)

	# Spawn red spikes directly on top of this segment
	# Let's force a spike on EVERY segment for now so you can immediately see them
	var hazard = Area2D.new()
	hazard.z_index = 10 # Force spikes to draw on top of the floor
	
	var h_collision = CollisionShape2D.new()
	var h_rect = RectangleShape2D.new()
	h_rect.size = Vector2(40.0, 40.0)
	h_collision.shape = h_rect
	h_collision.position = Vector2(0.0, -20.0)
	hazard.add_child(h_collision)
	
	var h_visual = ColorRect.new()
	h_visual.size = Vector2(40.0, 40.0)
	h_visual.position = Vector2(-20.0, -40.0)
	h_visual.color = Color(1.0, 0.0, 0.0) # Bright red hazard block
	hazard.add_child(h_visual)
	
	# Position spike right on the flat floor surface
	var hazard_x = next_spawn_x + (segment_width / 2.0)
	hazard.global_position = Vector2(hazard_x, FLOOR_Y)
	
	# Die if player touches hazard
	hazard.body_entered.connect(func(body):
		if body == player:
			print("Hit hazard! Resetting...")
			player.die()
	)
	
	add_child(hazard)
	print("Spawned red spike hazard at X: ", hazard_x)

	next_spawn_x += segment_width
