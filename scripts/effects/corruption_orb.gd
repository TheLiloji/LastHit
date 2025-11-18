extends Area2D

@onready var visual = $Visual
@onready var collision = $CollisionShape2D
@onready var lifetime_timer = $LifetimeTimer

@export var corruption_value: float = 3.0
@export var lifetime: float = 3.0

var velocity: Vector2 = Vector2.ZERO
var fall_speed: float = 1500.0
var has_been_collected: bool = false

var z_height: float = 0.0
var z_velocity: float = 0.0
var base_scale: float = 1.0

var is_moving: bool = true

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	lifetime_timer.wait_time = lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	lifetime_timer.start()
	
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.1)
	
	monitoring = true
	monitorable = true

func _physics_process(delta):
	# Mouvement horizontal
	velocity.x *= 0.96
	velocity.y *= 0.96
	position += velocity * delta
	
	# Chute (gravité)
	z_velocity -= fall_speed * delta
	z_height += z_velocity * delta
	
	# Touche le sol = s'écrase et s'arrête
	if z_height <= 0:
		z_height = 0
		z_velocity = 0
		velocity = Vector2.ZERO  # S'arrête complètement
		is_moving = false  # Plus de mouvement
	
	# Effet de profondeur (plus c'est haut, plus c'est petit)
	var depth_scale = 1.0 - (z_height / 120.0) * 0.4
	depth_scale = clamp(depth_scale, 0.4, 1.0)
	scale = Vector2.ONE * base_scale * depth_scale

func launch(direction: Vector2, force: float, up_force: float):
	velocity = direction * force
	z_velocity = up_force
	is_moving = true

func _on_body_entered(body):
	try_collect(body)

func _on_area_entered(area):
	try_collect(area)

func try_collect(collider):
	if has_been_collected or not is_moving:
		return
	
	var target = collider
	
	var current = collider
	for i in range(3):
		if current == null:
			break
		if current.is_in_group("players"):
			target = current
			break
		current = current.get_parent()
	
	if target.is_in_group("players"):
		# Vérifier si corrompu (correction ici)
		if "is_corrupted" in target and target.is_corrupted:
			return
		
		if target.has_method("add_corruption"):
			has_been_collected = true
			target.add_corruption(corruption_value)
			print("Orbe collectée ! +" + str(corruption_value) + " corruption")
			collect_effect()

func collect_effect():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", scale * 1.8, 0.12)
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	tween.tween_callback(queue_free)

func _on_lifetime_timeout():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
