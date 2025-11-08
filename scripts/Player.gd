extends Node2D

class_name Player

signal staminaChanged
signal corruptionChanged
signal healthChanged

var player: int
var input

@onready var body: CharacterBody2D = $PlayerBody

# --- Déplacement ---
@export var move_speed := 200.0
@export var accel := 2000.0
@export var deaccel := 2200.0

# --- Stamina / HP ---
@export var stamina_max := 100.0
@export var stamina_regen := 18.0
var stamina

@export var hp_max := 100
var hp

# --- Corruption ---
@export var corruption_max := 100.0
var corruption := 0.0
var is_corrupted := false

# --- Attaques (début de chaîne) ---
@export var attack_light: AttackData
@export var attack_heavy: AttackData

# --- Dodge ---
@export var dodge_cost := 22.0
@export var dodge_speed := 340.0
@export var dodge_duration := 0.22

# --- Réfs ---
@onready var anim: AnimationPlayer = $PlayerBody/AnimationPlayer
@onready var hitbox_shape: CollisionShape2D = $PlayerBody/AttackPivot/Attack/Hitbox
@onready var attack_pivot: Node2D = $PlayerBody/AttackPivot
@onready var attack_sprite: Sprite2D = $PlayerBody/AttackPivot/Attack/Sprite2D
@onready var player_sprite: Sprite2D = $PlayerBody/Sprite2D
@onready var attack_area: Area2D = $PlayerBody/AttackPivot/Attack

# --- État ---
var is_attacking := false
var is_dodging := false
var invincible := false
var queued_attack = null
var current_attack = null
var face_dir := Vector2.RIGHT
var aim_dir := Vector2.RIGHT
var is_aiming := false
const AIM_DEADZONE := 0.15 

func init(player_num: int, device: int):
	player = player_num
	input = DeviceInput.new(device)

func _ready():
	stamina = stamina_max
	hp = hp_max
	corruption = 0.0
	
	add_to_group("players")
	
	anim.animation_finished.connect(_on_animation_finished)
	staminaChanged.emit()
	healthChanged.emit()
	corruptionChanged.emit()

	attack_sprite.visible = false
	
	if attack_area:
		attack_area.body_entered.connect(_on_attack_hit)
	
func _process(_d: float) -> void:
	if input.is_action_just_pressed("leave"):
		PlayerManager.leave(player)

func _physics_process(delta):
	_aim_update()
	_read_combat_inputs()
	if not is_attacking and not is_dodging:
		_move_update(delta)
	_regen_update(delta)
	body.move_and_slide()

func _aim_update():
	var aim_input = input.get_vector("aim_left","aim_right","aim_up","aim_down")
	
	is_aiming = aim_input.length() > AIM_DEADZONE
	
	if is_aiming:
		aim_dir = aim_input.normalized()
		if absf(aim_dir.x) > 0.1:
			player_sprite.flip_h = aim_dir.x < 0.0

func _read_combat_inputs() -> void:
	if is_aiming:
		if not is_attacking:
			attack(attack_light)
		elif current_attack != null and queued_attack == null:
			queued_attack = current_attack.next_attack
	
	if input.is_action_just_pressed("dodge"):
		_try_dodge()

func _move_update(delta):
	var input_vec = input.get_vector("move_left","move_right","move_up","move_down")
	var target_vel = input_vec * move_speed

	var accel_used := 0.0
	if target_vel.length() > body.velocity.length():
		accel_used = accel
	else:
		accel_used = deaccel

	body.velocity = body.velocity.move_toward(target_vel, accel_used * delta)
	
	if input_vec != Vector2.ZERO:
		anim.play("run")
	else:
		anim.play("idle")

func _regen_update(delta):
	stamina = clamp(stamina + stamina_regen * delta, 0.0, stamina_max)
	staminaChanged.emit()
	
	if corruption > 0 and not is_corrupted:
		corruption = max(0, corruption - 5.0 * delta)
		corruptionChanged.emit()

func attack(atk : AttackData):
	if is_dodging:
		return
	if atk == null:
		current_attack = attack_light
	else:
		if stamina < atk.stamina_cost:
			return
		current_attack = atk
	
	stamina -= current_attack.stamina_cost
	staminaChanged.emit()
	
	var attack_dir := aim_dir if(aim_dir.length() > AIM_DEADZONE) else face_dir
	face_dir = attack_dir.normalized()
	
	if absf(face_dir.x) > 0.1:
		player_sprite.flip_h = face_dir.x < 0.0
	
	attack_pivot.rotation = attack_dir.angle()
	attack_pivot.position = attack_dir * current_attack.attack_offset
	attack_sprite.texture = current_attack.attack_texture
	attack_sprite.visible = true
	
	# ACTIVER LA HITBOX ICI
	if hitbox_shape:
		hitbox_shape.disabled = false
	
	body.velocity = Vector2.ZERO
	is_attacking = true
	anim.play(current_attack.anim)

func _on_animation_finished(animName: StringName) -> void:
	if current_attack != null and animName == StringName(current_attack.anim):
		is_attacking = false
		
		# DESACTIVER LA HITBOX ICI
		if hitbox_shape:
			hitbox_shape.disabled = true
		
		if is_aiming and queued_attack != null:
			var next_atk = queued_attack
			queued_attack = null
			attack(next_atk)
		else:
			current_attack = null
			queued_attack = null
			attack_sprite.visible = false
			attack_pivot.position = Vector2.ZERO
			anim.play("idle")

func _on_attack_hit(collided_body):
	if not is_attacking:
		return
	
	if collided_body.has_method("take_damage"):
		var damage = current_attack.damage if current_attack else 10.0
		
		collided_body.take_damage(damage, body.global_position)
		
		print(name + " a frappé " + collided_body.name + " pour " + str(damage) + " dégâts")
		
		add_corruption(3.0)

func _try_dodge() -> void:
	if is_attacking:
		return
	if stamina < dodge_cost:
		return

	is_dodging = true
	invincible = true
	stamina -= dodge_cost
	anim.play("dodge")

	var mv = input.get_vector("move_left","move_right","move_up","move_down")
	var dir = mv.normalized() if(mv.length() > 0.1) else face_dir

	await _perform_dodge(dir)

	anim.play("idle")
	is_dodging = false
	invincible = false

func _perform_dodge(dir: Vector2) -> void:
	var d := dir.normalized()
	var until := Time.get_ticks_msec() + int(dodge_duration * 1000.0)
	while Time.get_ticks_msec() < until:
		body.velocity = d * dodge_speed
		await get_tree().physics_frame

func take_damage(amount: float):
	if invincible or is_dodging:
		return
	
	hp -= amount
	hp = max(0, hp)
	healthChanged.emit()
	
	_hit_flash()
	
	if hp <= 0:
		die()
	
	print(name + " a pris " + str(amount) + " dégâts. HP: " + str(hp) + "/" + str(hp_max))

func _hit_flash():
	player_sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	player_sprite.modulate = Color.WHITE

func die():
	print(name + " est mort")
	#queue_free()
	PlayerManager.leave(player)

func add_corruption(amount: float):
	corruption += amount
	corruption = clamp(corruption, 0.0, corruption_max)
	corruptionChanged.emit()
	
	print(name + " corruption: " + str(int(corruption)) + "/" + str(int(corruption_max)))
	
	if corruption >= corruption_max and not is_corrupted:
		become_corrupted()

func become_corrupted():
	is_corrupted = true
	print(name + " est maintenant CORROMPU")
	
	player_sprite.modulate = Color.PURPLE
	
	await get_tree().create_timer(10.0).timeout
	cure_corruption()

func cure_corruption():
	is_corrupted = false
	corruption = 0.0
	player_sprite.modulate = Color.WHITE
	corruptionChanged.emit()
	print(name + " n'est plus corrompu")
