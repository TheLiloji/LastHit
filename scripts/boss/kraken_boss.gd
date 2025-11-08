extends StaticBody2D

# ====== RÉFÉRENCES ======
@onready var health_bar = $HealthBar
@onready var tentacle_spawners = $TentacleSpawners

# ====== SCÈNES À ASSIGNER ======
@export var tentacle_scene: PackedScene
@export var corruption_projectile_scene: PackedScene

# ====== STATS DU BOSS ======
var max_health: float = 1000.0
var current_health: float = 1000.0
var is_alive: bool = true

# ====== TENTACULES ======
var tentacles: Array = []
var tentacle_count: int = 6

# ====== CORRUPTION ======
var corruption_spawn_chance: float = 0.2  # 1 chance sur 5 = 20%

# ====== PATTERNS D'ATTAQUE ======
var attack_cooldown: float = 3.0
var time_since_attack: float = 0.0

# ====== INITIALISATION ======
func _ready():
	# Configurer la barre de vie
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	# Spawner les tentacules
	spawn_tentacles()
	
	print("🐙 Boss Kraken initialisé !")
	print("HP: " + str(current_health) + "/" + str(max_health))

# ====== SPAWN DES TENTACULES ======
func spawn_tentacles():
	var spawn_points = tentacle_spawners.get_children()
	
	if tentacle_scene == null:
		print("⚠️ ERREUR : Assigne tentacle_scene dans l'Inspector !")
		return
	
	for i in range(min(tentacle_count, spawn_points.size())):
		# Créer la tentacule
		var tentacle = tentacle_scene.instantiate()
		add_child(tentacle)
		
		# Positionner au spawn point
		tentacle.global_position = spawn_points[i].global_position
		
		# Orienter vers l'extérieur
		var direction = (tentacle.global_position - global_position).normalized()
		tentacle.rotation = direction.angle()
		
		# Ajouter à la liste
		tentacles.append(tentacle)
	
	print("✅ " + str(tentacles.size()) + " tentacules créées")

# ====== SYSTÈME DE DÉGÂTS ======
func take_damage(amount: float, attacker_position: Vector2 = Vector2.ZERO):
	if not is_alive:
		return
	
	# Réduire la vie
	current_health -= amount
	current_health = max(0, current_health)
	
	# Mettre à jour la barre
	health_bar.value = current_health
	
	# Flash blanc
	hit_flash()
	
	# 🎯 NOUVEAU : Giclée de corruption avec probabilité
	if randf() < corruption_spawn_chance:  # 20% de chance
		spawn_corruption_projectile(attacker_position)
	
	# Vérifier la mort
	if current_health <= 0:
		die()
	else:
		print("💜 Boss HP: " + str(int(current_health)) + "/" + str(int(max_health)))

func hit_flash():
	# Flash blanc rapide
	var core = $CoreBody
	core.modulate = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	core.modulate = Color(1, 1, 1, 1)

# ====== 🎯 GICLÉE DE CORRUPTION (NOUVEAU) ======
func spawn_corruption_projectile(target_position: Vector2):
	if corruption_projectile_scene == null:
		print("ERREUR : Assigne corruption_projectile_scene dans l'Inspector")
		return
	
	if target_position == Vector2.ZERO:
		var players = get_tree().get_nodes_in_group("players")
		if players.size() > 0:
			var random_player = players[randi() % players.size()]
			var player_body = random_player.get_node("PlayerBody")
			target_position = player_body.global_position
		else:
			return
	
	var projectile = corruption_projectile_scene.instantiate()
	get_parent().add_child(projectile)
	
	projectile.global_position = global_position
	
	var direction = (target_position - global_position).normalized()
	
	var random_offset = Vector2(
		randf_range(-50, 50),
		randf_range(-50, 50)
	)
	var final_target = target_position + random_offset
	direction = (final_target - global_position).normalized()
	
	projectile.launch(direction)
	
	print("Giclée de corruption envoyée")

# ====== MORT DU BOSS ======
func die():
	is_alive = false
	print("💀 BOSS VAINCU !")
	
	# Détruire les tentacules
	for tentacle in tentacles:
		if is_instance_valid(tentacle):
			tentacle.queue_free()
	
	# Animation de disparition
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 2.0)
	tween.tween_callback(queue_free)
	
	# TODO : Déclencher la phase finale (Last Hit)

# ====== PATTERNS D'ATTAQUE ======
func _process(delta):
	if not is_alive:
		return
	
	# Timer pour les attaques
	time_since_attack += delta
	
	if time_since_attack >= attack_cooldown:
		time_since_attack = 0.0
		execute_random_attack()

func execute_random_attack():
	if tentacles.is_empty():
		return
	
	# Choisir un pattern aléatoire
	var pattern = randi() % 3
	
	match pattern:
		0:  # Une tentacule frappe
			var tentacle = tentacles[randi() % tentacles.size()]
			if is_instance_valid(tentacle):
				tentacle.slam_attack()
		
		1:  # Balayage en vague
			for i in tentacles.size():
				if is_instance_valid(tentacles[i]):
					tentacles[i].slam_attack()
					await get_tree().create_timer(0.15).timeout
		
		2:  # Toutes frappent ensemble
			for tentacle in tentacles:
				if is_instance_valid(tentacle):
					tentacle.slam_attack()
