extends ProgressBar

@export var player: Node

func _ready():
	await player.ready
	player.staminaChanged.connect(update_value)
	update_value()

func update_value():
	value = player.stamina * 100 / player.stamina_max
