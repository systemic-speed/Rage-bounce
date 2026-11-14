extends Area2D

@export var glitch_mode: String = "random" # random, inverted, jump_swapped, chaos
@export var one_shot: bool = true

var _active: bool = true
var _time: float = 0.0

@onready var visual: Node2D = get_node_or_null("Visual")


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if not visual or not _active:
		return
	_time += delta
	visual.rotation = sin(_time * 4.0) * 0.08
	visual.modulate.a = 0.75 + sin(_time * 6.0) * 0.2


func _on_body_entered(body: Node) -> void:
	if not _active:
		return
	if not (body.is_in_group("player") or body.name == "Player"):
		return
	if body.has_method("apply_control_glitch"):
		body.apply_control_glitch(glitch_mode)
	elif body.has_method("invert_horizontal_controls") and glitch_mode in ["", "random", "inverted"]:
		body.invert_horizontal_controls()
	_show_trigger_feedback()
	if one_shot:
		_active = false
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		await get_tree().create_timer(0.25).timeout
		if is_instance_valid(self):
			queue_free()


func _show_trigger_feedback() -> void:
	if not visual:
		return
	visual.scale = Vector2(1.3, 1.3)
	visual.modulate = Color(1, 0.4, 1, 1)
	var t := create_tween()
	t.tween_property(visual, "scale", Vector2.ONE, 0.2)
