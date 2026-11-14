extends Area2D

@export var consume_on_use: bool = true
var is_active: bool = true

var _base_visual_y: float = 0.0
var _time: float = 0.0

@onready var visual: Node2D = get_node_or_null("Visual")
@onready var reward_popup: Node2D = get_node_or_null("RewardPopup")
@onready var reward_label: Label = get_node_or_null("RewardPopup/RewardLabel")
@onready var reward_icon: Sprite2D = get_node_or_null("RewardPopup/RewardIcon")


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if visual:
		_base_visual_y = visual.position.y
	if reward_popup:
		reward_popup.visible = false


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
		# High-stakes trade: spend one anchor for a random effect.
		body.reset_anchors -= 1

		var roll := randf()
		if roll < 0.34:
			if body.has_method("restore_bounce"):
				body.restore_bounce()
			else:
				body.set("bounce_enabled", true)
				body.set("bounce_tuning_enabled", true)
			_show_reward("BOUNCE!", Color(0.5, 1, 0.6, 1))
			print("Lucky Block: bounce restored. Anchors left: ", body.reset_anchors, " (use ]/[ or +/- to adjust bounce)")
		elif roll < 0.67:
			if body.has_method("restore_default_controls"):
				body.restore_default_controls()
			elif body.has_method("restore_defaults"):
				body.restore_defaults()
			_show_reward("CONTROLS!", Color(0.6, 0.9, 1, 1))
			print("Lucky Block: controls restored. Anchors left: ", body.reset_anchors)
		else:
			if body.has_method("apply_control_glitch"):
				body.apply_control_glitch("random")
			elif body.has_method("invert_horizontal_controls"):
				body.invert_horizontal_controls()
			_show_reward("GLITCH!", Color(1, 0.55, 1, 1))
			print("Lucky Block: controls glitched! Anchors left: ", body.reset_anchors)

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
		_show_reward("EMPTY", Color(1, 0.5, 0.5, 1))
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


func _show_reward(text: String, tint: Color) -> void:
	if not reward_popup:
		return
	reward_popup.visible = true
	reward_popup.modulate = Color(1, 1, 1, 1)
	reward_popup.position = Vector2(0, -34)
	if reward_label:
		reward_label.text = text
		reward_label.modulate = tint
	if reward_icon:
		reward_icon.modulate = tint
	var t := create_tween()
	t.tween_property(reward_popup, "position", Vector2(0, -58), 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(reward_popup, "modulate:a", 0.0, 0.45).set_delay(0.15)
	t.tween_callback(func():
		if is_instance_valid(reward_popup):
			reward_popup.visible = false
			reward_popup.modulate = Color(1, 1, 1, 1)
	)

