extends Area2D

@onready var lifetime_timer = $LifetimeTimer
@onready var visual = $Visual

@export var speed: float = 350.0
@export var corruption_amount: float = 15.0
@export var damage: float = 10.0

var direction: Vector2 = Vector2.ZERO
var has_hit: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)
	
	pulse_effect()

func launch(launch_direction: Vector2):
	direction = launch_direction.normalized()
	rotation = direction.angle()

func _physics_process(delta):
	if direction != Vector2.ZERO:
		position += direction * speed * delta

func pulse_effect():
	var tween = create_tween().set_loops()
	tween.tween_property(visual, "scale", Vector2(1.2, 1.2), 0.3)
	tween.tween_property(visual, "scale", Vector2(1.0, 1.0), 0.3)

func _on_body_entered(body):
	if has_hit:
		return
	
	var target = body
	if body.get_parent() and body.get_parent().is_in_group("players"):
		target = body.get_parent()
	
	if target.is_in_group("players") or target.has_method("add_corruption"):
		has_hit = true
		
		if target.has_method("add_corruption"):
			target.add_corruption(corruption_amount)
			print("Corruption appliquée à " + target.name + " : +" + str(corruption_amount))
		
		if target.has_method("take_damage"):
			target.take_damage(damage)
		
		explode()

func _on_lifetime_timeout():
	explode()

func explode():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(visual, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
