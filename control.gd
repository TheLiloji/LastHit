extends Control

func _ready() -> void:
	$VBoxContainer/FIGHT.pressed.connect(_on_fight_pressed)
	$VBoxContainer/CUSTOMISE.pressed.connect(_on_customise_pressed)
	$VBoxContainer/TRAINING.pressed.connect(_on_training_pressed)
	$VBoxContainer/OPTIONS.pressed.connect(_on_options_pressed)
	$VBoxContainer/EXIT.pressed.connect(_on_exit_pressed)

func _on_fight_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/proto.tscn")

func _on_customise_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/proto.tscn")

func _on_training_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/proto.tscn")

func _on_options_pressed() -> void:
	var options_menu = load("res://scenes/options_menu.tscn").instantiate()
	add_child(options_menu)

func _on_exit_pressed() -> void:
	get_tree().quit()
