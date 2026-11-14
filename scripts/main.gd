extends Node2D

@export var levels: Array[PackedScene] = [
	preload("res://scenes/levels/level_0.tscn"),
	preload("res://scenes/levels/level_1.tscn"),
	preload("res://scenes/levels/level_2.tscn"),
	preload("res://scenes/levels/level_3.tscn"),
	preload("res://scenes/levels/level_4.tscn"),
]
@export var player_spawn_position: Vector2 = Vector2(46, 305)

var current_level_index: int = 0
var current_level: Node = null
var _is_transitioning: bool = false
var _random_glitch_timer: float = 0.0

@onready var level_container: Node2D = $LevelContainer
@onready var player: CharacterBody2D = $Player
@onready var controls_label: Label = get_node_or_null("HUD/Panel/Margin/ControlsLabel")


func _ready() -> void:
	randomize()
	load_level(current_level_index)
	_update_hud()


func _process(delta: float) -> void:
	_update_hud()
	_process_random_control_glitch(delta)


func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return
	if event.is_action_pressed("ui_accept") and player and not player.alive:
		restart_level()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				restart_level()
			KEY_N:
				next_level()
			KEY_P:
				previous_level()


func load_level(index: int) -> void:
	if levels.is_empty():
		push_warning("No levels configured.")
		return

	_is_transitioning = false
	current_level_index = wrapi(index, 0, levels.size())

	if current_level and is_instance_valid(current_level):
		current_level.queue_free()

	current_level = levels[current_level_index].instantiate()
	level_container.add_child(current_level)
	_connect_level_signals(current_level)
	_reset_player()


func restart_level() -> void:
	load_level(current_level_index)


func next_level() -> void:
	var next_index := current_level_index + 1
	if next_index >= levels.size():
		_show_end_screen()
		return
	load_level(next_index)


func previous_level() -> void:
	load_level(current_level_index - 1)


func _show_end_screen() -> void:
	_is_transitioning = true
	get_tree().change_scene_to_file("res://scenes/end_screen.tscn")


func _connect_level_signals(level: Node) -> void:
	for group_name in ["enemies", "fire", "hazards"]:
		var group_node = level.get_node_or_null(group_name)
		if not group_node:
			continue
		for hazard in group_node.get_children():
			if hazard.has_signal("player_dead") and not hazard.player_dead.is_connected(_on_player_died):
				hazard.player_dead.connect(_on_player_died)

	var exit_node = level.get_node_or_null("LevelExit")
	if exit_node and exit_node.has_signal("level_completed") and not exit_node.level_completed.is_connected(_on_level_completed):
		exit_node.level_completed.connect(_on_level_completed)


func _on_level_completed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	next_level()


func _reset_player() -> void:
	if not player:
		return
	player.global_position = player_spawn_position
	if player.has_method("reset_run_state"):
		player.reset_run_state()
	else:
		player.velocity = Vector2.ZERO
		player.alive = true
		if "reset_anchors" in player:
			player.reset_anchors = 3
		if player.has_method("restore_default_controls"):
			player.restore_default_controls()
		if player.has_node("AnimatedSprite2D"):
			player.get_node("AnimatedSprite2D").play("idle")
	_random_glitch_timer = randf_range(8.0, 16.0)
	_update_hud()


func _process_random_control_glitch(delta: float) -> void:
	if _is_transitioning or not player or not player.alive:
		return
	_random_glitch_timer -= delta
	if _random_glitch_timer > 0.0:
		return
	# Random control glitches can happen during gameplay.
	if player.has_method("apply_control_glitch"):
		player.apply_control_glitch("random")
	elif player.has_method("invert_horizontal_controls"):
		player.invert_horizontal_controls()
	_random_glitch_timer = randf_range(10.0, 20.0)


func _update_hud() -> void:
	if not controls_label:
		return
	var anchors = player.reset_anchors if player and ("reset_anchors" in player) else "?"
	var bounce = "on" if player and player.get("bounce_enabled") else "off"
	var tuning = "on" if player and player.get("bounce_tuning_enabled") else "off"
	var jump_vel = player.get("jump_velocity") if player and ("jump_velocity" in player) else "?"
	var controls_state = player.get_control_state_text() if player and player.has_method("get_control_state_text") else "normal"
	controls_label.text = "BOUNCE to survive! Move: A/Left, D/Right   Jump/Bounce: Space/Enter   Restart: R   Levels: N/P\n" + \
		"Controls can glitch randomly or from Lucky Blocks/triggers. Lucky Block (1 anchor): restore controls, restore bounce, or glitch\n" + \
		"After bounce: ] / = / Numpad+ = higher jump,   [ / - / Numpad- = lower jump\n" + \
		"Anchors: %s   Bounce: %s   Bounce tuning: %s   Jump velocity: %s   Controls: %s" % [str(anchors), str(bounce), str(tuning), str(jump_vel), str(controls_state)]



func _on_player_died(_body: Node = null) -> void:
	if _is_transitioning or not player or not player.alive:
		return
	_is_transitioning = true
	if player.has_method("die"):
		player.die()
	# Quick restart after death so level flow keeps moving.
	var level_at_death := current_level_index
	await get_tree().create_timer(0.6).timeout
	if current_level_index == level_at_death:
		restart_level()
	else:
		_is_transitioning = false
