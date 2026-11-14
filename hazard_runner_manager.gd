extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var score_label: Label = $CanvasLayer/Label

var next_spawn_x: float = 800.0
var cleared_x: float = -400.0
var score: int = 0

func _ready() -> void:
	if not player:
		print("ERROR: Player node not found!")
		return
		
	# Spawn initial starting floor under player
	spawn_floor_segment(player.global_position.x - 200.0, 800.0)
	
	# Pre-spawn initial hazards ahead
	for i in range(8):
		spawn_obstacle_ahead()

func _process(_delta: float) -> void:
	if not player:
		return

	# Update score based on distance run
	score = int(player.global_position.x / 32.0)
	if score_label:
		score_label.text = "SCORE: " + str(score)

	# Infinite spawner: Keep generating obstacles ahead of the player
	if player.global_position.x + 1400.0 > next_spawn_x:
		spawn_obstacle_ahead()

	# Memory cleanup: Delete floor & hazards far behind the player
	if player.global_position.x - 800.0 > cleared_x:
		clear_behind(cleared_x, cleared_x + 600.0)
		cleared_x += 600.0

func spawn_obstacle_ahead() -> void:
	var floor_y = 600.0 # Match your floor's Y coordinate
	
	# 1. Spawn continuous floor segment
	spawn_floor_segment(next_spawn_x, 600.0)

	# 2. Randomly place a spike/fire hazard on this segment
	if randf() > 0.3: # 70% chance to have a hazard on this block
		var hazard = Area2D.new()
		hazard.add_to_group("hazard")
		
		# Collision box for the hazard
		var collision = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(40.0, 40.0) # Spike size
		collision.shape = rect
		collision.position = Vector2(0.0, -20.0)
		hazard.add_child(collision)
		
		# Visual representation (Red warning block / fire / spike placeholder)
		var color_rect = ColorRect.new()
		color_rect.size = Vector2(40.0, 40.0)
		color_rect.position = Vector2(-20.0, -40.0)
		color_rect.color = Color(0.9, 0.1, 0.1) # Danger red
		hazard.add_child(color_rect)
		
		hazard.global_position = Vector2(next_spawn_x + randf_range(100.0, 300.0), floor_y)
		
		# Connect death signal when player touches hazard
		hazard.body_entered.connect(func(body):
			if body == player:
				player.die()
		)
		
		add_child(hazard)

	next_spawn_x += randf_range(500.0, 800.0)

func spawn_floor_segment(pos_x: float, pos_y: float) -> void:
	var floor_body = StaticBody2D.new()
	
	var collision = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(600.0, 64.0) # Length and thickness of floor chunk
	collision.shape = rect
	collision.position = Vector2(300.0, 32.0)
	floor_body.add_child(collision)
	
	var color_rect = ColorRect.new()
	color_rect.size = Vector2(600.0, 64.0)
	color_rect.color = Color(0.2, 0.2, 0.25) # Industrial dark metal floor
	floor_body.add_child(color_rect)
	
	floor_body.global_position = Vector2(pos_x, pos_y)
	add_child(floor_body)

func clear_behind(start_x: float, end_x: float) -> void:
	# Removes old nodes behind the player to maintain peak performance
	for child in get_children():
		if child != player and child is Node2D:
			if child.global_position.x >= start_x and child.global_position.x < end_x:
				child.queue_free()
