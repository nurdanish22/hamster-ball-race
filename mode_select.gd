extends Control

var player_count := 1

func _on_one_player_button_pressed() -> void:
	player_count = 1
	Global.player_count = player_count
	get_tree().change_scene_to_file("res://Tracks/Track02.tscn")

func _on_two_player_button_pressed() -> void:
	player_count = 2
	Global.player_count = player_count
	get_tree().change_scene_to_file("res://Tracks/Track01.tscn")
