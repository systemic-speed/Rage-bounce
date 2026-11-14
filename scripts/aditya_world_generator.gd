extends Node2D

# Disabled for the integrated runner version of this stage to avoid conflicting
# generated platforms/collisions. Kept as part of the imported stage files.
@export var enabled: bool = true
@export var player: CharacterBody2D
@export var screen_width: float = 1152.0

var next_spawn_y: float = 0.0
var spawn_vertical_gap: float = 120.0
var generation_height_buffer: float = 1000.0

func _ready() -> void:
	if not enabled:
		set_process(false)
		return
	if not player:
		player = get_node_or_null("../Player")
		if not player:
			player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player:
		next_spawn_y = player.global_position.y
		spawn_starting_floor()
		for i in range(15):
			spawn_platform_row()

func _process(_delta: float) -> void:
	if not enabled or not player:
		return
	if player.global_position.y < next_spawn_y + generation_height_buffer:
		spawn_platform_row()

func spawn_starting_floor() -> void:
	var floor_node = StaticBody2D.new()
	var collision = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(screen_width, 60.0)
	collision.shape = rect
	floor_node.add_child(collision)
	floor_node.global_position = Vector2(screen_width / 2.0, player.global_position.y + 60.0)
	add_child(floor_node)

func spawn_platform_row() -> void:
	next_spawn_y -= spawn_vertical_gap
	var safe_x = randf_range(150.0, screen_width - 150.0)
	var platform = StaticBody2D.new()
	var collision = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(120.0, 20.0)
	collision.shape = rect
	platform.add_child(collision)
	platform.global_position = Vector2(safe_x, next_spawn_y)
	add_child(platform)
