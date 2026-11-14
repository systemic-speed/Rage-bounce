extends Node2D

@export var player: CharacterBody2D
@export var screen_width: float = 1152.0 # Adjust to match your window width (e.g., 1152 or 1280)

var next_spawn_y: float = 0.0
var spawn_vertical_gap: float = 120.0 # Comfortable jump distance between platforms
var generation_height_buffer: float = 1000.0

func _ready() -> void:
	if not player:
		# Fallback search if not assigned in inspector
		player = get_node_or_null("../Player")
	
	if player:
		next_spawn_y = player.global_position.y
		# Generate a solid starting platform/floor right where the player spawns
		spawn_starting_floor()
		
		# Pre-generate the initial stack of climbing platforms above
		for i in range(15):
			spawn_platform_row()

func _process(delta: float) -> void:
	if not player:
		return
		
	# Continuously generate platforms ahead as the player climbs higher (-Y direction)
	if player.global_position.y < next_spawn_y + generation_height_buffer:
		spawn_platform_row()

func spawn_starting_floor() -> void:
	# Creates a safe starting floor right beneath the player's initial position
	var floor_node = StaticBody2D.new()
	var collision = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	
	rect.size = Vector2(screen_width, 60.0) # Wide floor across the screen
	collision.shape = rect
	
	floor_node.add_child(collision)
	floor_node.global_position = Vector2(screen_width / 2.0, player.global_position.y + 60.0)
	
	# Assign to your TileMapLayer physics layer or default layer if needed
	add_child(floor_node)

func spawn_platform_row() -> void:
	next_spawn_y -= spawn_vertical_gap
	
	# Random X position ensuring it stays within screen bounds
	var safe_x = randf_range(150.0, screen_width - 150.0)
	
	# Programmatically create a platform so you don't have to manually paint everything
	var platform = StaticBody2D.new()
	var collision = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	
	rect.size = Vector2(120.0, 20.0) # Standard platform size
	collision.shape = rect
	platform.add_child(collision)
	
	platform.global_position = Vector2(safe_x, next_spawn_y)
	add_child(platform)
