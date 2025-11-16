extends Area2D

@onready var visual = $Visual
@onready var collision = $CollisionShape2D
@onready var lifetime_timer = $LifetimeTimer

@export var corruption_value: float = 3.0
@export var lifetime: float = 3.0

var velocity: Vector2 = Vector2.ZERO
var fall_speed: float = 800.0
var has_been_collected: bool = false

# Pour l'effet de profondeur Z
var z_height: float = 0.0
var z_velocity: float = 0.0
var base_scale: float = 1.0

func _ready():
	body_entered.connect(_on_body_entered)
	lifetime_timer.wait_time = lifetime
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	lifetime_timer.start()
	
	# Animation d'apparition
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.1)

func _physics_process(delta):
	# Mouvement horizontal avec friction
	velocity.x *= 0.98
	velocity.y *= 0.98
	position += velocity * delta
	
	# Simulation de Z (hauteur)
	z_velocity -= fall_speed * delta  # Gravité
	z_height += z_velocity * delta
	
	# Quand touche le sol
	if z_height <= 0:
		z_height = 0
		z_velocity *= -0.4  # Rebond avec perte d'énergie
		
		# Arrêter de bouger si presque au sol
		if abs(z_velocity) < 50:
			z_velocity = 0
	
	# Simuler la profondeur avec le scale
	var depth_scale = 1.0 - (z_height / 150.0) * 0.5  # Plus c'est haut, plus c'est petit
	depth_scale = clamp(depth_scale, 0.3, 1.0)
	scale = Vector2.ONE * base_scale * depth_scale

func launch(direction: Vector2, force: float, up_force: float):
	velocity = direction * force
	z_velocity = up_force  # Force verticale (vers le haut en Z)

func pulse_effect():
	var tween = create_tween().set_loops()
	tween.tween_property(visual, "scale", Vector2(1.1, 1.1), 0.3)
	tween.tween_property(visual, "scale", Vector2(1.0, 1.0), 0.3)

func _on_body_entered(body):
	if has_been_collected or z_height > 5:  # Ne collecte que si au sol
		return
	
	var target = body
	if body.get_parent() and body.get_parent().is_in_group("players"):
		target = body.get_parent()
	
	if target.is_in_group("players") and not target.is_corrupted:
		if target.has_method("add_corruption"):
			has_been_collected = true
			target.add_corruption(corruption_value)
			collect_effect()

func collect_effect():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", scale * 1.5, 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)

func _on_lifetime_timeout():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
