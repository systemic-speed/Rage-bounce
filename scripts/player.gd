extends CharacterBody2D

const JUMP_VELOCITY = -590.0 # Increased jump height to clear spikes easily
var gravity = 1200.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	velocity.x = 0.0
	move_and_slide()

	if global_position.y > 850.0:
		get_tree().reload_current_scene()
