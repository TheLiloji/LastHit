extends CharacterBody2D

class_name Player

signal staminaChanged

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

# --- Attaques (début de chaîne) ---
@export var attack_light: AttackData
@export var attack_heavy: AttackData

# --- Dodge ---
@export var dodge_cost := 22.0
@export var dodge_speed := 340.0
@export var dodge_duration := 0.22

# --- Réfs ---
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var hitbox_shape: CollisionShape2D = $Attack/Hitbox/CollisionShape2D

# --- État ---
var is_attacking := false
var is_dodging := false
var invincible := false
var queued_attack = null
var current_attack = null
var face_dir := Vector2.RIGHT


func _ready():
	stamina = stamina_max
	hp = hp_max
	anim.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	_aim_update()
	_read_combat_inputs()
	if not is_attacking and not is_dodging:
		_move_update(delta)
	_regen_update(delta)
	move_and_slide()

func _aim_update():
	var input_vec := Input.get_vector("move_left","move_right","move_up","move_down")
	if input_vec.length() > 0.01:
		face_dir = input_vec.normalized()

func _read_combat_inputs() -> void:
	if Input.is_action_just_pressed("attack"):
		if current_attack == null:
			queued_attack = attack_light
		else:
			queued_attack = current_attack.next_attack
		attack(queued_attack)
		
	if Input.is_action_just_pressed("attack_heavy"):
		is_attacking = true
	if Input.is_action_just_pressed("dodge"):
		_try_dodge()

func _move_update(delta):
	var input_vec := Input.get_vector("move_left","move_right","move_up","move_down")
	var target_vel := input_vec * move_speed

	var accel_used := 0.0
	if target_vel.length() > velocity.length():
		accel_used = accel
	else:
		accel_used = deaccel

	velocity = velocity.move_toward(target_vel, accel_used * delta)
	
	if input_vec != Vector2.ZERO:
		anim.play("run")
	else:
		anim.play("idle")

func _regen_update(delta):
	stamina = clamp(stamina + stamina_regen * delta, 0.0, stamina_max)
	staminaChanged.emit()

# ---------------- Attaques / Combos ----------------

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
	velocity = Vector2.ZERO # Idée -> rajouter une direction dans le attackdata pour faire des dash lors des attaques apr exemple
	is_attacking = true
	anim.play(current_attack.anim)
	
func _on_animation_finished(animName: StringName) -> void:
	if current_attack != null and animName == StringName(current_attack.anim):
		is_attacking = false
		current_attack = null
		anim.play("idle")

# ---------------- Dodge ----------------
func _try_dodge() -> void:
	if is_attacking:
		return
	if stamina < dodge_cost:
		return
	is_dodging = true
	stamina -= dodge_cost
	anim.play("dodge")
	await _perform_dodge()
	anim.play("idle")
	is_dodging = false

func _perform_dodge() -> void:
	var dir := face_dir
	var until := Time.get_ticks_msec() + int(dodge_duration * 1000.0)
	while Time.get_ticks_msec() < until:
		velocity = dir * dodge_speed
		await get_tree().physics_frame
