extends ProgressBar

@export var player: Player

func _ready():
	player.staminaChanged.connect(update)
	update()

func update():
	value = player.stamina * 100 / player.stamina_max
