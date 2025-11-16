extends Node2D

var player_nodes = {}
var boss_node = null

func _ready():
	PlayerManager.player_left.connect(delete_player)
	
	spawn_boss()
	spawn_all_players()

func get_screen_size() -> Vector2:
	return get_viewport_rect().size

func spawn_boss():
	var boss_scene = load("res://scenes/boss/kraken_boss.tscn")
	boss_node = boss_scene.instantiate()
	add_child(boss_node)
	
	var screen_size = get_screen_size()
	boss_node.position = Vector2(screen_size.x / 2, 200)

func spawn_all_players():
	var players = PlayerManager.get_player_indexes()
	var player_count = players.size()
	
	if player_count == 0:
		return
	
	var screen_size = get_screen_size()
	var player_spawn_y = 850  # Ajuste cette valeur selon où tu veux les joueurs
	var player_spacing = 180
	
	var total_width = (player_count - 1) * player_spacing
	var start_x = (screen_size.x - total_width) / 2
	
	for i in range(player_count):
		var player = players[i]
		var spawn_pos = Vector2(start_x + i * player_spacing, player_spawn_y)
		spawn_player(player, spawn_pos)

func spawn_player(player: int, spawn_pos: Vector2):
	var player_scene = load("res://scenes/proto.tscn")
	var player_node = player_scene.instantiate()
	player_nodes[player] = player_node
	
	var device = PlayerManager.get_player_device(player)
	player_node.init(player, device)
	
	add_child(player_node)
	player_node.position = spawn_pos

func delete_player(player: int):
	if player_nodes.has(player):
		player_nodes[player].queue_free()
		player_nodes.erase(player)
	
	if player_nodes.is_empty():
		game_over()

func game_over():
	print("Tous les joueurs sont morts - Game Over")
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")
