extends Area2D

@onready var visual = $VisualBody
@onready var collision = $CollisionShape2D
@onready var cooldown_timer = $AttackCooldown

@export var damage: float = 10.0
@export var slam_speed: float = 0.4
@export var telegraph_duration: float = 0.4
@export var attack_range: float = 250.0

var is_attacking: bool = false
var rest_position: Vector2
var has_saved_position: bool = false
var original_color: Color
var original_scale: Vector2

func _ready():
	original_color = visual.color
	original_scale = visual.scale
	collision.set_deferred("disabled", true)
	body_entered.connect(_on_body_entered)

func _process(_delta):
	if not has_saved_position and is_inside_tree():
		rest_position = global_position
		has_saved_position = true

func slam_attack():
	if is_attacking or not cooldown_timer.is_stopped():
		return
	
	is_attacking = true
	
	await telegraph()
	await strike()
	await return_to_base()
	
	is_attacking = false
	cooldown_timer.start()

func telegraph():
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(visual, "color", Color.RED, telegraph_duration * 0.5)
	tween.tween_property(visual, "color", Color.DARK_RED, telegraph_duration * 0.5).set_delay(telegraph_duration * 0.5)
	tween.tween_property(visual, "scale", Vector2(0.9, 1.2), telegraph_duration)
	
	await get_tree().create_timer(telegraph_duration).timeout

func strike():
	var target_global = get_nearest_player_position()
	
	var direction_to_target = (target_global - rest_position).normalized()
	var strike_global_position = rest_position + (direction_to_target * attack_range)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(self, "global_position", strike_global_position, slam_speed)
	tween.tween_property(visual, "scale", Vector2(1.5, 0.8), slam_speed)
	
	collision.set_deferred("disabled", false)
	
	await tween.finished
	await get_tree().create_timer(0.15).timeout

func get_nearest_player_position() -> Vector2:
	var players = get_tree().get_nodes_in_group("players")
	
	if players.is_empty():
		return rest_position + Vector2(200, 0).rotated(global_rotation)
	
	var nearest_pos = Vector2.ZERO
	var min_distance = INF
	
	for player in players:
		if not is_instance_valid(player):
			continue
		
		if player.is_corrupted:
			continue
			
		var player_body = player.get_node_or_null("PlayerBody")
		if player_body == null:
			continue
		
		var distance = rest_position.distance_to(player_body.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest_pos = player_body.global_position
	
	if nearest_pos == Vector2.ZERO:
		return rest_position + Vector2(200, 0).rotated(global_rotation)
	
	return nearest_pos

func return_to_base():
	collision.set_deferred("disabled", true)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(self, "global_position", rest_position, slam_speed * 0.8)
	tween.tween_property(visual, "color", original_color, slam_speed * 0.8)
	tween.tween_property(visual, "scale", original_scale, slam_speed * 0.8)
	
	await tween.finished

func _on_body_entered(body):
	if not is_attacking or collision.disabled:
		return
	
	var target = body
	if body.get_parent() and body.get_parent().is_in_group("players"):
		target = body.get_parent()
	
	if target.has_method("take_damage"):
		target.take_damage(damage)
		print("Tentacule a frappé : " + target.name)
