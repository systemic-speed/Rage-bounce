extends Area2D

signal level_completed

var _active: bool = true
var _time: float = 0.0

@onready var visual: Node2D = get_node_or_null("Visual")


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if not visual:
		return
	_time += delta
	visual.modulate.a = 0.85 + sin(_time * 4.0) * 0.15
	visual.scale.y = 1.0 + sin(_time * 2.5) * 0.03


func _on_body_entered(body: Node2D) -> void:
	if not _active:
		return
	if body.name == "Player" or body.is_in_group("player"):
		_active = false
		level_completed.emit()

