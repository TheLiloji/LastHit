extends Resource
class_name AttackData

@export var name := "Light 1"
@export var anim: StringName = &"attack_light_1"
@export var damage: int = 10
@export var stamina_cost: float = 10.0
@export var knockback: float = 160.0
@export var next_attack: AttackData
@export var attack_offset: float = 40.0
@export var attack_texture: Texture2D
