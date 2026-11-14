extends Node2D

@onready var player: CharacterBody2D = $Player

# Path to your platform image asset (adjust if your image is saved elsewhere)
const PLATFORM_TEXTURE_PATH = "res://240_F_1763880074_6QJR9z1SoMxtvEf7WoJnDVIjpUE7avRm.jpg" # Or wherever your image is

var furthest_spawned_x: float = 0.0
var spawn_ahead_distance: float = 2000.0
var min_gap: float = 120.0
var max_gap: float = 220.0

func _ready() -> void:
	if not player:
		return
		
	# Spawn a guaranteed starting platform right under the player
	spawn_single_platform(player.global_position.x - 100.0, player.global_position.y + 60.0, 400.0)

	furthest_spawned_x = player.global_position.x + 400.0
	
	# Pre-spawn platforms to the right
	for i in range(12):
		spawn_random_platform()

func _process(_delta: float) -> void:
	if not player:
		return
		
	if player.global_position.x + spawn_ahead_distance > furthest_spawned_x:
		spawn_random_platform()

func spawn_random_platform() -> void:
	var platform_width = randf_range(120.0, 250.0) # Variable platform lengths
	var target_y = player.global_position.y + randf_range(-80.0, 100.0)
	
	spawn_single_platform(furthest_spawned_x, target_y, platform_width)
	
	furthest_spawned_x += platform_width + randf_range(min_gap, max_gap)

func spawn_single_platform(pos_x: float, pos_y: float, width: float) -> void:
	var platform = StaticBody2D.new()
	
	# Collision Shape
	var collision = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(width, 32.0) # Height of the platform
	collision.shape = rect
	collision.position = Vector2(width / 2.0, 16.0)
	platform.add_child(collision)
	
	# Visual Sprite (using your texture)
	var sprite = Sprite2D.new()
	if ResourceLoader.exists(PLATFORM_TEXTURE_PATH):
		sprite.texture = load(PLATFORM_TEXTURE_PATH)
		sprite.centered = false
		# Scale texture to match the desired platform width
		var tex_width = sprite.texture.get_width()
		if tex_width > 0:
			sprite.scale.x = width / tex_width
	platform.add_child(sprite)
	
	platform.global_position = Vector2(pos_x, pos_y)
	add_child(platform)
