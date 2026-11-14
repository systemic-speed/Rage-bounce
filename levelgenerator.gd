extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var tilemap: TileMapLayer = $TileMapLayer

const SOURCE_ID = 0 
const PLATFORM_TILE = Vector2i(0, 0) # Your orange platform tile in the atlas
const PLATFORM_WIDTH_TILES = 3      # Width of each platform in tiles
const GRID_WIDTH = 32               # Total columns across your screen
const ROW_GAP = 5                   # Vertical gap between platform rows

var highest_generated_row: int = 0

# Track moving platforms: Dictionary mapping Vector2i grid position -> movement data
var moving_platforms: Dictionary = {}

func _ready() -> void:
	if not player or not tilemap:
		return
		
	var start_cell = tilemap.local_to_map(player.global_position)
	highest_generated_row = start_cell.y - 2
	
	# Place solid starting platform under player
	place_platform(start_cell.x - 1, start_cell.y + 2, false)
	
	# Generate initial rows upward
	for i in range(25):
		generate_next_row()

func _process(delta: float) -> void:
	if not player or not tilemap:
		return
		
	var player_row = tilemap.local_to_map(player.global_position).y
	
	# Continuously generate rows ahead of the player as they climb
	while highest_generated_row > player_row - 25:
		generate_next_row()
		
	# Handle sideways horizontal scrolling / oscillation for moving platforms
	update_moving_platforms(delta)

func generate_next_row() -> void:
	highest_generated_row -= ROW_GAP
	var start_col = randi_range(2, GRID_WIDTH - PLATFORM_WIDTH_TILES - 2)
	
	# 40% chance for a platform to move sideways back and forth
	var is_moving = randf() < 0.4 
	place_platform(start_col, highest_generated_row, is_moving)

func place_platform(col: int, row: int, is_moving: bool) -> void:
	var base_pos = Vector2i(col, row)
	for i in range(PLATFORM_WIDTH_TILES):
		tilemap.set_cell(base_pos + Vector2i(i, 0), SOURCE_ID, PLATFORM_TILE)
		
	if is_moving:
		# Store movement parameters: start col, speed direction, travel limits
		moving_platforms[base_pos] = {
			"min_col": max(1, col - 4),
			"max_col": min(GRID_WIDTH - PLATFORM_WIDTH_TILES - 1, col + 4),
			"current_col": float(col),
			"direction": 1.0 if randf() > 0.5 else -1.0,
			"speed": randf_range(1.5, 3.0) # Sideways travel speed
		}

func update_moving_platforms(delta: float) -> void:
	# Clear out rows way below the player to save performance
	var current_row = tilemap.local_to_map(player.global_position).y
	var keys_to_remove = []
	
	for base_pos in moving_platforms.keys():
		if base_pos.y > current_row + 20:
			keys_to_remove.append(base_pos)
			continue
			
		var data = moving_platforms[base_pos]
		data["current_col"] += data["direction"] * data["speed"] * delta
		
		# Reverse direction at boundaries
		if data["current_col"] <= data["min_col"]:
			data["current_col"] = data["min_col"]
			data["direction"] = 1.0
		elif data["current_col"] >= data["max_col"]:
			data["current_col"] = data["max_col"]
			data["direction"] = -1.0
			
		var new_col = round(data["current_col"])
		if new_col != base_pos.x:
			# Erase old tile positions
			for i in range(PLATFORM_WIDTH_TILES):
				tilemap.erase_cell(base_pos + Vector2i(i, 0))
				
			# Update base position key
			var new_base_pos = Vector2i(new_col, base_pos.y)
			moving_platforms.erase(base_pos)
			moving_platforms[new_base_pos] = data
			
			# Draw at new sideways scrolled position
			for i in range(PLATFORM_WIDTH_TILES):
				tilemap.set_cell(new_base_pos + Vector2i(i, 0), SOURCE_ID, PLATFORM_TILE)

	for k in keys_to_remove:
		moving_platforms.erase(k)
