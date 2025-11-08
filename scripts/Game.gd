extends Node

var player_nodes = {}

func _ready():
	PlayerManager.player_joined.connect(spawn_player)
	PlayerManager.player_left.connect(delete_player)
	
	spawn_boss()

func _process(_delta):
	PlayerManager.handle_join_input()

func spawn_boss():
	var boss_scene = load("res://scenes/boss/kraken_boss.tscn")
	var boss_node = boss_scene.instantiate()
	add_child(boss_node)
	boss_node.position = Vector2(500, 300)

func spawn_player(player: int):
	var player_scene = load("res://scenes/proto.tscn")
	var player_node = player_scene.instantiate()
	player_nodes[player] = player_node
	
	var device = PlayerManager.get_player_device(player)
	player_node.init(player, device)
	
	add_child(player_node)
	
	player_node.position = Vector2(randf_range(0, 100), randf_range(0, 100))

func delete_player(player: int):
	player_nodes[player].queue_free()
	player_nodes.erase(player)

func on_player_leave(player: int):
	PlayerManager.leave(player)
