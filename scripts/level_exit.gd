extends Area2D

signal level_completed

var _active: bool = true
var _time: float = 0.0

@onready var visual: Node2D = get_node_or_null("Visual")


func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	# In case the player is already overlapping when the level loads.
	call_deferred("_check_initial_overlap")


func _process(delta: float) -> void:
	if not visual:
		return
	_time += delta
	visual.modulate.a = 0.85 + sin(_time * 4.0) * 0.15
	visual.scale.y = 1.0 + sin(_time * 2.5) * 0.03


func _check_initial_overlap() -> void:
	if not _active:
		return
	for body in get_overlapping_bodies():
		_try_complete(body)


func _on_body_entered(body: Node2D) -> void:
	_try_complete(body)


func _try_complete(body: Node) -> void:
	if not _active:
		return
	if body and (body.name == "Player" or body.is_in_group("player")):
		_active = false
		level_completed.emit()

