extends StaticBody2D

@onready var health_bar = $HealthBar
@onready var tentacle_spawners = $TentacleSpawners

# Ne garde que ces deux scènes
@export var tentacle_scene: PackedScene
@export var corruption_orb_scene: PackedScene  # Les boules de sang

var max_health: float = 1000.0
var current_health: float = 1000.0
var is_alive: bool = true

var tentacles: Array = []
var tentacle_count: int = 6

var attack_cooldown: float = 3.0
var time_since_attack: float = 0.0

func _ready():
	health_bar.max_value = max_health
	health_bar.value = current_health
	spawn_tentacles()
	print("Boss Kraken initialisé")

func spawn_tentacles():
	var spawn_points = tentacle_spawners.get_children()
	
	if tentacle_scene == null:
		print("ERREUR : Assigne tentacle_scene dans l'Inspector")
		return
	
	for i in range(min(tentacle_count, spawn_points.size())):
		var tentacle = tentacle_scene.instantiate()
		add_child(tentacle)
		tentacle.global_position = spawn_points[i].global_position
		var direction = (tentacle.global_position - global_position).normalized()
		tentacle.rotation = direction.angle()
		tentacles.append(tentacle)
	
	print(str(tentacles.size()) + " tentacules créées")

func take_damage(amount: float, attacker_position: Vector2 = Vector2.ZERO):
	if not is_alive:
		return
	
	current_health -= amount
	current_health = max(0, current_health)
	health_bar.value = current_health
	
	
	# Gerbe de sang violet à chaque coup
	spawn_corruption_burst(attacker_position)
	
	if current_health <= 0:
		die()
	else:
		print("Boss HP: " + str(int(current_health)) + "/" + str(int(max_health)))

func spawn_corruption_burst(impact_position: Vector2):
	if corruption_orb_scene == null:
		print("ERREUR : Assigne corruption_orb_scene dans l'Inspector")
		return
	
	var is_big_burst = randf() < 0.2
	
	if is_big_burst:
		spawn_big_corruption_burst(impact_position)
	else:
		spawn_normal_corruption_burst(impact_position)

func spawn_normal_corruption_burst(impact_position: Vector2):
	var orb_count = randi_range(5, 10)
	
	var spawn_pos = global_position
	var target_direction = Vector2.ZERO
	var boss_radius = 100.0
	if impact_position != Vector2.ZERO:
		target_direction = (impact_position - global_position).normalized()
		
		spawn_pos = global_position + (target_direction * boss_radius)
	else:
		# Fallback
		var players = get_tree().get_nodes_in_group("players")
		if not players.is_empty():
			var random_player = players[randi() % players.size()]
			var player_body = random_player.get_node_or_null("PlayerBody")
			if player_body:
				target_direction = (player_body.global_position - global_position).normalized()
				spawn_pos = global_position + (target_direction * boss_radius)
	
	if target_direction == Vector2.ZERO:
		target_direction = Vector2(1, 0).rotated(randf() * TAU)
	
	for i in range(orb_count):
		var orb = corruption_orb_scene.instantiate()
		get_parent().add_child(orb)
		
		orb.global_position = spawn_pos
		orb.corruption_value = randf_range(0.8, 1.2)
		
		var direction: Vector2
		if randf() < 0.02:
			direction = Vector2(1, 0).rotated(randf() * TAU)
		else:
			var cone_angle = deg_to_rad(60)
			var random_angle = randf_range(-cone_angle/2, cone_angle/2)
			direction = target_direction.rotated(random_angle)
		
		var horizontal_force = randf_range(250, 400)
		var vertical_force = randf_range(200, 300)
		
		orb.base_scale = randf_range(0.15, 0.25)
		orb.scale = Vector2.ONE * orb.base_scale
		
		orb.launch(direction, horizontal_force, vertical_force)

func spawn_big_corruption_burst(impact_position: Vector2):
	var orb_count = randi_range(5, 25)
	
	var spawn_pos = global_position
	var target_direction = Vector2.ZERO
	
	if impact_position != Vector2.ZERO:
		target_direction = (impact_position - global_position).normalized()
		var boss_radius = 100.0
		spawn_pos = global_position + (target_direction * boss_radius)
	else:
		var players = get_tree().get_nodes_in_group("players")
		if not players.is_empty():
			var random_player = players[randi() % players.size()]
			var player_body = random_player.get_node_or_null("PlayerBody")
			if player_body:
				target_direction = (player_body.global_position - global_position).normalized()
				var boss_radius = 100.0
				spawn_pos = global_position + (target_direction * boss_radius)
	
	if target_direction == Vector2.ZERO:
		target_direction = Vector2(1, 0).rotated(randf() * TAU)
	
	for i in range(orb_count):
		var orb = corruption_orb_scene.instantiate()
		get_parent().add_child(orb)
		
		orb.global_position = spawn_pos
		
		var size_type = randf()
		if size_type < 0.6:
			orb.base_scale = randf_range(0.1, 0.18)
			orb.corruption_value = randf_range(0.5, 1.0)
		elif size_type < 0.9:
			orb.base_scale = randf_range(0.2, 0.3)
			orb.corruption_value = randf_range(1.5, 2.5)
		else:
			orb.base_scale = randf_range(0.35, 0.5)
			orb.corruption_value = randf_range(3.0, 5.0)
		
		orb.scale = Vector2.ONE * orb.base_scale
		
		var direction: Vector2
		if randf() < 0.02:
			direction = Vector2(1, 0).rotated(randf() * TAU)
		else:
			var cone_angle = deg_to_rad(90)
			var random_angle = randf_range(-cone_angle/2, cone_angle/2)
			direction = target_direction.rotated(random_angle)
		
		var horizontal_force = randf_range(300, 500)
		var vertical_force = randf_range(250, 400)
		
		orb.launch(direction, horizontal_force, vertical_force)

func die():
	is_alive = false
	print("BOSS VAINCU")
	
	for tentacle in tentacles:
		if is_instance_valid(tentacle):
			tentacle.queue_free()
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 2.0)
	tween.tween_callback(queue_free)

func _process(delta):
	if not is_alive:
		return
	
	time_since_attack += delta
	
	if time_since_attack >= attack_cooldown:
		time_since_attack = 0.0
		execute_random_attack()

func execute_random_attack():
	if tentacles.is_empty():
		return
	
	var pattern = randi() % 3
	
	match pattern:
		0:
			var tentacle = tentacles[randi() % tentacles.size()]
			if is_instance_valid(tentacle):
				tentacle.slam_attack()
		1:
			for i in tentacles.size():
				if is_instance_valid(tentacles[i]):
					tentacles[i].slam_attack()
					await get_tree().create_timer(0.15).timeout
		2:
			for tentacle in tentacles:
				if is_instance_valid(tentacle):
					tentacle.slam_attack()
