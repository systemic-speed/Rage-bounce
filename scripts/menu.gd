extends Control

var _time: float = 0.0
@onready var accent1: ColorRect = $BgAccent1
@onready var accent2: ColorRect = $BgAccent2
@onready var title: Label = $CenterContainer/Panel/Margin/VBox/Title


func _ready() -> void:
	$CenterContainer/Panel/Margin/VBox/StartButton.pressed.connect(_on_start_pressed)
	$CenterContainer/Panel/Margin/VBox/QuitButton.pressed.connect(_on_quit_pressed)


func _process(delta: float) -> void:
	_time += delta
	if accent1:
		accent1.position.y = 420.0 + sin(_time * 0.7) * 10.0
	if accent2:
		accent2.position.y = -120.0 + cos(_time * 0.6) * 8.0
	if title:
		var s := 1.0 + sin(_time * 1.8) * 0.015
		title.scale = Vector2(s, s)
		title.pivot_offset = title.size / 2.0


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()

