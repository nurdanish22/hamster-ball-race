extends Control

# Inside your Main Menu script:
func _on_one_player_button_pressed() -> void:
	Global.is_two_player = false
	get_tree().change_scene_to_file("res://Scenes/character_selection.tscn")

func _on_two_player_button_pressed() -> void:
	Global.is_two_player = true
	get_tree().change_scene_to_file("res://Scenes/character_selection.tscn")
