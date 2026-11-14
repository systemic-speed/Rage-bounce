extends CharacterBody2D

const SPEED = 300.0
const DEFAULT_JUMP_VELOCITY = -900.0
const MIN_JUMP_VELOCITY = -1400.0 # stronger/higher bounce
const MAX_JUMP_VELOCITY = -400.0  # weaker/lower bounce
const JUMP_VELOCITY_STEP = 100.0
const MAX_RESET_ANCHORS := 3

var alive: bool = true
var reset_anchors: int = MAX_RESET_ANCHORS
var bounce_enabled: bool = true
var bounce_tuning_enabled: bool = false
var jump_velocity: float = DEFAULT_JUMP_VELOCITY

# Current control bindings (can be glitched/inverted at runtime).
var move_left_action := "ui_left"
var move_right_action := "ui_right"
var jump_action := "ui_accept"
var control_mode: String = "normal"

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump: AudioStreamPlayer2D = $Jump


func _ready() -> void:
	add_to_group("player")


func _unhandled_input(event: InputEvent) -> void:
	if not alive or not bounce_tuning_enabled:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		# Adjust bounce strength after obtaining the bounce thingy.
		if event.keycode == KEY_BRACKETRIGHT or event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			_increase_bounce()
		elif event.keycode == KEY_BRACKETLEFT or event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			_decrease_bounce()


func _physics_process(delta: float) -> void:
	# Add gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	if not alive:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return

	# Add animation
	if not is_on_floor():
		animated_sprite_2d.animation = "jump"
	elif abs(velocity.x) > 1:
		animated_sprite_2d.animation = "walk"
	else:
		animated_sprite_2d.animation = "idle"

	# Handle jump.
	if bounce_enabled and Input.is_action_just_pressed(jump_action) and is_on_floor():
		velocity.y = jump_velocity
		jump.play()

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis(move_left_action, move_right_action)
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	if direction == 1.0:
		animated_sprite_2d.flip_h = false
	elif direction == -1.0:
		animated_sprite_2d.flip_h = true


func die() -> void:
	alive = false
	velocity = Vector2.ZERO
	if animated_sprite_2d.sprite_frames and animated_sprite_2d.sprite_frames.has_animation("dead"):
		animated_sprite_2d.play("dead")
	else:
		animated_sprite_2d.stop()


func restore_default_controls() -> void:
	move_left_action = "ui_left"
	move_right_action = "ui_right"
	jump_action = "ui_accept"
	control_mode = "normal"


func apply_control_glitch(mode: String = "") -> void:
	var chosen := mode
	if chosen == "" or chosen == "random":
		var modes := ["inverted", "jump_swapped", "chaos"]
		chosen = modes[randi() % modes.size()]
	match chosen:
		"inverted":
			move_left_action = "ui_right"
			move_right_action = "ui_left"
			jump_action = "ui_accept"
			control_mode = "inverted"
		"jump_swapped":
			# Swap jump with move-right input to create a meaningful control change.
			move_left_action = "ui_left"
			move_right_action = "ui_accept"
			jump_action = "ui_right"
			control_mode = "jump_swapped"
		"chaos":
			move_left_action = "ui_accept"
			move_right_action = "ui_left"
			jump_action = "ui_right"
			control_mode = "chaos"
		"normal", _:
			restore_default_controls()
	print("Controls changed: ", control_mode)


func get_control_state_text() -> String:
	return control_mode


func restore_bounce() -> void:
	bounce_enabled = true
	bounce_tuning_enabled = true
	if jump_velocity == DEFAULT_JUMP_VELOCITY:
		# Start from a noticeable restored bounce; player can tune after.
		jump_velocity = -1000.0


func apply_bounce(force: float = -1200.0) -> void:
	# Central bounce mechanic: pads and other bounce sources propel the player.
	bounce_enabled = true
	velocity.y = minf(force, jump_velocity - 150.0)
	if jump:
		jump.play()


func disable_bounce() -> void:
	bounce_enabled = false
	bounce_tuning_enabled = false


func _increase_bounce() -> void:
	jump_velocity = clamp(jump_velocity - JUMP_VELOCITY_STEP, MIN_JUMP_VELOCITY, MAX_JUMP_VELOCITY)
	print("Bounce increased (jump velocity): ", jump_velocity)


func _decrease_bounce() -> void:
	jump_velocity = clamp(jump_velocity + JUMP_VELOCITY_STEP, MIN_JUMP_VELOCITY, MAX_JUMP_VELOCITY)
	print("Bounce decreased (jump velocity): ", jump_velocity)


func invert_horizontal_controls() -> void:
	apply_control_glitch("inverted")


func reset_run_state() -> void:
	alive = true
	reset_anchors = MAX_RESET_ANCHORS
	bounce_enabled = true
	bounce_tuning_enabled = false
	jump_velocity = DEFAULT_JUMP_VELOCITY
	restore_default_controls()
	velocity = Vector2.ZERO
	if animated_sprite_2d:
		animated_sprite_2d.play("idle")
