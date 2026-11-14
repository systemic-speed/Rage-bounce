extends Area2D

@export var consume_on_use: bool = true
var is_active: bool = true

var _base_visual_y: float = 0.0
var _time: float = 0.0

@onready var visual: Node2D = get_node_or_null("Visual")


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if visual:
		_base_visual_y = visual.position.y


func _process(delta: float) -> void:
	if not is_active or not visual:
		return
	_time += delta
	# Subtle idle bob + pulse to make the block feel alive.
	visual.position.y = _base_visual_y + sin(_time * 3.2) * 2.5
	var pulse := 1.0 + sin(_time * 5.0) * 0.04
	visual.scale = Vector2(pulse, pulse)


func _on_body_entered(body: Node) -> void:
	if not is_active:
		return
	if not body.is_in_group("player") and body.name != "Player":
		return

	if body.get("reset_anchors") != null and body.reset_anchors > 0:
		# High-stakes trade: spend one anchor for a random benefit.
		body.reset_anchors -= 1

		var grant_bounce := randf() < 0.5
		if grant_bounce:
			if body.has_method("restore_bounce"):
				body.restore_bounce()
			else:
				body.set("bounce_enabled", true)
				body.set("bounce_tuning_enabled", true)
			print("Lucky Block: bounce restored. Anchors left: ", body.reset_anchors, " (use ]/[ or +/- to adjust bounce)")
		else:
			if body.has_method("restore_default_controls"):
				body.restore_default_controls()
			elif body.has_method("restore_defaults"):
				body.restore_defaults()
			print("Lucky Block: controls restored. Anchors left: ", body.reset_anchors)

		if consume_on_use:
			is_active = false
			# Brief success pop, then settle into a spent state.
			if visual:
				visual.scale = Vector2(1.2, 1.2)
				visual.modulate = Color(1, 1, 1, 1)
				await get_tree().create_timer(0.08).timeout
				if is_instance_valid(visual):
					visual.position.y = _base_visual_y
					visual.scale = Vector2.ONE
					visual.modulate = Color(0.75, 0.75, 0.75, 0.45)
			set_deferred("monitoring", false)
			set_deferred("monitorable", false)
	else:
		# Out of anchors - no benefit applied.
		print("Lucky Block: no anchors left. Nothing changed.")
		if visual:
			var original_modulate := visual.modulate
			var original_pos := visual.position
			visual.modulate = Color(1, 0.35, 0.35, 1)
			visual.position = original_pos + Vector2(4, 0)
			await get_tree().create_timer(0.05).timeout
			if is_instance_valid(visual):
				visual.position = original_pos + Vector2(-4, 0)
			await get_tree().create_timer(0.05).timeout
			if is_instance_valid(visual):
				visual.position = original_pos
				visual.modulate = original_modulate

