extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@export var max_health: int = 100
@export var attack_damage: int = 25 # Damage the player deals to enemies

var health: int
var is_attacking := false
var facing_direction := 1.0 # Tracks which way the player is looking

@onready var health_bar: ProgressBar = $HealthBar
@onready var attack_area: Area2D = $AttackArea # Reference to player's attack hitbox
@onready var attack_pulse: CPUParticles2D = $AttackPulse # Reference to our huge pulse visual effect


func _ready() -> void:
	add_to_group("player")

	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health

	# Configure the attack hitbox on startup
	if attack_area:
		attack_area.monitoring = false
		attack_area.monitorable = true
		if not attack_area.is_in_group("player_attack"):
			attack_area.add_to_group("player_attack")


func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle Attack Input (presses "attack" action)
	if Input.is_action_just_pressed("attack"):
		perform_attack()

	var direction := Input.get_axis("move_left", "move_right")

	if direction:
		velocity.x = direction * SPEED
		facing_direction = signf(direction) # Save direction for the pulse/hitbox
		
		# Flip attack area position based on movement direction
		if attack_area:
			attack_area.position.x = facing_direction * 50.0
			
		# Flip pulse effect direction and push it further forward for a huge effect
		if attack_pulse:
			attack_pulse.direction.x = facing_direction
			attack_pulse.position.x = facing_direction * 40.0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func perform_attack() -> void:
	if is_attacking:
		return

	is_attacking = true
	print("Player fired a HUGE pulse attack!")

	# Enable attack hitbox so the boss's HurtBox can detect it
	if attack_area:
		attack_area.monitoring = true

	# === TRIGGER THE HUGE PULSE VISUAL EFFECT ===
	if attack_pulse:
		attack_pulse.restart() # Fires the massive particle wave
		attack_pulse.emitting = true

	# Keep hitbox active briefly during the giant wave animation (0.3 seconds)
	await get_tree().create_timer(0.3).timeout

	if attack_area:
		attack_area.monitoring = false

	is_attacking = false


# Allows the boss script to retrieve the player's attack damage value
func get_damage() -> int:
	return attack_damage


func take_damage(amount: int) -> void:

	health -= amount
	health = clampi(health, 0, max_health)

	health_bar.value = health

	print("Player health: ", health)

	if health <= 0:
		print("Player died!")
		# Return to main progression to retry the boss fight level.
		var gs = get_node_or_null("/root/GameState")
		if gs:
			gs.resume_from_boss_fight = true
			gs.boss_fight_completed = false
		get_tree().call_deferred("change_scene_to_file", "res://scenes/main.tscn")
		queue_free()
