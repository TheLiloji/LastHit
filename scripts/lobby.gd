extends Control

@onready var player_list = $VBoxContainer/PlayerList

func _ready():
	PlayerManager.player_joined.connect(_on_player_joined)
	PlayerManager.player_left.connect(_on_player_left)
	
	update_player_list()

func _process(_delta):
	PlayerManager.handle_join_input()
	
	if PlayerManager.get_player_count() > 0 and PlayerManager.someone_wants_to_start():
		start_game()

func _on_player_joined(player: int):
	update_player_list()

func _on_player_left(player: int):
	update_player_list()

func update_player_list():
	for child in player_list.get_children():
		child.queue_free()
	
	var players = PlayerManager.get_player_indexes()
	
	if players.is_empty():
		var label = Label.new()
		label.text = "En attente de joueurs..."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		player_list.add_child(label)
	else:
		for player in players:
			var label = Label.new()
			var device = PlayerManager.get_player_device(player)
			var device_name = "Clavier" if device == -1 else "Manette " + str(device)
			label.text = "Joueur " + str(player + 1) + " (" + device_name + ") - PRÊT ✓"
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 20)
			label.add_theme_color_override("font_color", Color.GREEN)
			player_list.add_child(label)

func start_game():
	get_tree().change_scene_to_file("res://scenes/game.tscn")
