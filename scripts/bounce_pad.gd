extends Area2D

@export var bounce_velocity: float = -1250.0

var _time: float = 0.0
@onready var visual: Node2D = get_node_or_null("Visual")


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if not visual:
		return
	_time += delta
	visual.scale.y = 1.0 + sin(_time * 6.0) * 0.06


func _on_body_entered(body: Node) -> void:
	if not (body.is_in_group("player") or body.name == "Player"):
		return
	# Only bounce when player is landing on/into the pad from above or falling.
	if "velocity" in body and body.velocity.y < -50.0:
		return
	if body.has_method("apply_bounce"):
		body.apply_bounce(bounce_velocity)
	elif "velocity" in body:
		body.velocity.y = bounce_velocity
	if visual:
		visual.scale = Vector2(1.15, 0.8)
		await get_tree().create_timer(0.08).timeout
		if is_instance_valid(visual):
			visual.scale = Vector2.ONE
