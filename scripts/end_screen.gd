extends Control

var _time: float = 0.0
@onready var accent1: ColorRect = $BgAccent1
@onready var accent2: ColorRect = $BgAccent2
@onready var title: Label = $CenterContainer/Panel/Margin/VBox/Title


func _ready() -> void:
	$CenterContainer/Panel/Margin/VBox/RestartButton.pressed.connect(_on_restart_pressed)
	$CenterContainer/Panel/Margin/VBox/MenuButton.pressed.connect(_on_menu_pressed)
	$CenterContainer/Panel/Margin/VBox/QuitButton.pressed.connect(_on_quit_pressed)


func _process(delta: float) -> void:
	_time += delta
	if accent1:
		accent1.position.y = 360.0 + sin(_time * 0.8) * 10.0
	if accent2:
		accent2.position.y = -100.0 + cos(_time * 0.7) * 8.0
	if title:
		var s := 1.0 + sin(_time * 2.0) * 0.012
		title.scale = Vector2(s, s)
		title.pivot_offset = title.size / 2.0


func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()

