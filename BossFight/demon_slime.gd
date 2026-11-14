extends CharacterBody2D

@export var move_speed: float = 100.0
@export var detection_range: float = 400.0
@export var attack_range: float = 100.0
@export var attack_cooldown: float = 1.5
@export var attack_damage: int = 20
@export var max_health: int = 500
@export var sprite_faces_left: bool = true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var health_bar: ProgressBar = $HealthBar
@onready var hurtbox: Area2D = $HurtBox

var player: CharacterBody2D
var health: int

var can_attack := true
var is_attacking := false
var attack_active := false
var hit_targets: Array[Node] = []
var active_attacks: Array[Area2D] = []


func _ready() -> void:
	health = max_health

	health_bar.max_value = max_health
	health_bar.value = health

	attack_area.monitoring = false
	attack_area.monitorable = true
	attack_area.body_entered.connect(_on_attack_area_body_entered)

	if hurtbox:
		hurtbox.monitorable = true
		hurtbox.monitoring = true
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
		hurtbox.area_exited.connect(_on_hurtbox_area_exited)
	else:
		print("Warning: HurtBox node not found on Boss!")

	sprite.play("IDLE")

	print("BOSS READY")
	print("Animations: ", sprite.sprite_frames.get_animation_names())


func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity += get_gravity() * delta

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	if not is_instance_valid(player):
		velocity.x = 0.0
		play_animation("IDLE")
		move_and_slide()
		return

	if is_attacking:
		velocity.x = 0.0
		move_and_slide()
		return

	var distance_x = player.global_position.x - global_position.x
	var distance_y = absf(player.global_position.y - global_position.y)
	var distance = absf(distance_x)

	if distance_x != 0:
		if sprite_faces_left:
			sprite.flip_h = distance_x > 0
		else:
			sprite.flip_h = distance_x < 0

		attack_area.position.x = signf(distance_x) * 55.0

	if distance > detection_range or distance_y > 100.0:
		velocity.x = 0.0
		play_animation("IDLE")

	elif distance > attack_range:
		velocity.x = signf(distance_x) * move_speed
		play_animation("Walk")

	else:
		velocity.x = 0.0
		play_animation("IDLE")

		if can_attack:
			perform_attack()

	move_and_slide()


func play_animation(animation_name: String) -> void:
	if sprite.animation != animation_name or not sprite.is_playing():
		sprite.play(animation_name)


func perform_attack() -> void:

	can_attack = false
	is_attacking = true
	hit_targets.clear()

	print("BOSS STARTED ATTACK")
	
	sprite.play("Cleave")

	await get_tree().create_timer(0.3).timeout

	if not is_inside_tree():
		return

	attack_active = true
	attack_area.set_deferred("monitoring", true)

	print("ATTACK HITBOX ACTIVATED")

	await get_tree().physics_frame

	if not is_inside_tree():
		return

	var overlapping = attack_area.get_overlapping_bodies()

	print("BODIES DETECTED: ", overlapping.size())

	for body in overlapping:
		damage_player(body)

	await get_tree().create_timer(0.3).timeout

	if not is_inside_tree():
		return

	attack_active = false
	attack_area.set_deferred("monitoring", false)

	await get_tree().create_timer(0.3).timeout

	if not is_inside_tree():
		return

	is_attacking = false
	play_animation("IDLE")

	await get_tree().create_timer(attack_cooldown).timeout

	if is_inside_tree():
		can_attack = true


func _on_attack_area_body_entered(body: Node2D) -> void:
	damage_player(body)


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_attack"):
		if area in active_attacks:
			return
		
		active_attacks.append(area)
		
		var damage_amount = 25
		var player_node = area.get_parent()
		
		if player_node and player_node.has_method("get_damage"):
			damage_amount = player_node.get_damage()
			
		take_damage(damage_amount)
		print("BOSS TOOK DAMAGE! Current Health: ", health)


func _on_hurtbox_area_exited(area: Area2D) -> void:
	if area in active_attacks:
		active_attacks.erase(area)


func damage_player(body: Node) -> void:

	if not attack_active:
		return

	if not body.is_in_group("player"):
		return

	if body in hit_targets:
		return

	hit_targets.append(body)

	if body.has_method("take_damage"):
		await get_tree().create_timer(0.5).timeout
		body.take_damage(attack_damage)
		print("PLAYER HIT! Damage: ", attack_damage)
	else:
		print("Player has no take_damage() function!")


func take_damage(amount: int) -> void:
	health = clampi(health - amount, 0, max_health)
	health_bar.value = health
	print("Boss Health Bar Value Updated to: ", health_bar.value)

	if health <= 0:
		die()


func die() -> void:
	is_attacking = true
	attack_active = false
	attack_area.set_deferred("monitoring", false)
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)

	if sprite.sprite_frames.has_animation("Death"):
		sprite.play("Death")
		
		# Safe backup timer so death doesn't get stuck if the death animation loops
		var anim_speed = sprite.sprite_frames.get_animation_speed("Death")
		var frame_count = sprite.sprite_frames.get_frame_count("Death")
		var anim_duration = (frame_count / anim_speed) if anim_speed > 0 else 1.0
		
		await get_tree().create_timer(anim_duration).timeout
	else:
		await get_tree().create_timer(0.5).timeout

	if is_inside_tree():
		# Return to main progression after boss defeat.
		var gs = get_node_or_null("/root/GameState")
		if gs:
			gs.resume_from_boss_fight = true
			gs.boss_fight_completed = true
		queue_free()
		get_tree().call_deferred("change_scene_to_file", "res://scenes/main.tscn")
		print("Boss defeated! Returning to main progression.")
