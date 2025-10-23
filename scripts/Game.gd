extends Node2D

# Scène du joueur (CharacterBody2D) contenant le script Player.gd
@export var PlayerScene: PackedScene

# Positions de spawn (si tu n’as pas de Marker2D en scène)
@export var default_spawns := [
	Vector2(100, 100),
	Vector2(200, 100),
	Vector2(100, 200),
	Vector2(200, 200),
]

var device_to_player: Dictionary = {} # device_id -> Player node (device -1 = clavier)

func _ready() -> void:
	print("Connected joypads at start:", Input.get_connected_joypads())

func _input(event: InputEvent) -> void:
	# --- Auto-join via manette : bouton START ---
	if event is InputEventJoypadButton and event.pressed:
		# JOY_BUTTON_START est l’énum Godot (Start/Options/Menu selon la manette)
		if event.button_index == JOY_BUTTON_START:
			var dev := event.device
			if not device_to_player.has(dev):
				_spawn_player_for_device(dev)
				return

	# --- Auto-join via clavier : action "start" ---
	if event is InputEventKey:
		if event.is_action_pressed("start"):
			if not device_to_player.has(-1):
				_spawn_player_for_device(-1)
				return

func _spawn_player_for_device(device_id: int) -> void:
	if PlayerScene == null:
		push_error("PlayerScene n'est pas défini dans Game.gd")
		return

	var p := PlayerScene.instantiate()
	add_child(p)

	# Assigne le device au Player
	p.call_deferred("bind_device", device_id)

	# Position de spawn
	var idx := device_to_player.size()
	var spawn_pos := _find_spawn_position(idx)
	p.global_position = spawn_pos

	device_to_player[device_id] = p
	print("Spawned player for device:", device_id, "at", spawn_pos)

func _find_spawn_position(index: int) -> Vector2:
	# Si tu as un Node "Spawns" avec des Marker2D -> on s’en sert
	if has_node("Spawns"):
		var markers := get_node("Spawns").get_children()
		if markers.size() > 0:
			return markers[index % markers.size()].global_position

	# Sinon, fallback sur default_spawns
	return default_spawns[index % default_spawns.size()]
