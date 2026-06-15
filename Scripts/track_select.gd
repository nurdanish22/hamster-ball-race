extends Control

func _on_track_01_pressed():
	Global.selected_track = "Track01"
	start_race()

func _on_track_02_pressed():
	Global.selected_track = "Track02"
	start_race()

func start_race():
	get_tree().change_scene_to_file("res://Scenes/race_scene.tscn")
