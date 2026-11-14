extends Node

func _ready() -> void:
	# This wrapper level launches the integrated Akash boss fight.
	# Main sets GameState.next_level_after_boss before loading this level.
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.resume_from_boss_fight = true
		gs.boss_fight_completed = false
	get_tree().change_scene_to_file("res://BossFight/scenes/node_2d.tscn")
