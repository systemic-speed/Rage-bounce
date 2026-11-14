extends Control

func _ready() -> void:
	hide() # Force hidden at game start

func _on_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
