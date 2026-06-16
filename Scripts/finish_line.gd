# FinishLine.gd
extends Area3D

@onready var win_label: Label

func _ready() -> void:
	# Clear out old lap data right when the track loads
	Global.reset_race_data()
	
	var hud = get_tree().current_scene.get_node_or_null("RaceHUD")
	if hud:
		win_label = hud.get_node("CenterContainer/CountdownLabel")
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body.has_method("trigger_respawn") or not Global.race_active:
		return

	# ===== PLAYER 1 LAP LOGIC =====
	if body.player_id == 1:
		if Global.p1_cleared_midpoint:
			Global.p1_laps += 1
			Global.p1_cleared_midpoint = false # Lock them out until they drive around again
			check_victory(1)
			
	# ===== PLAYER 2 LAP LOGIC =====
	elif body.player_id == 2:
		if Global.p2_cleared_midpoint:
			Global.p2_laps += 1
			Global.p2_cleared_midpoint = false # Lock them out until they drive around again
			check_victory(2)

func check_victory(id: int) -> void:
	var current_laps = Global.p1_laps if id == 1 else Global.p2_laps
	
	# Check if this crossing completed the final required lap
	if current_laps >= Global.total_laps:
		Global.race_active = false
		
		if win_label:
			if Global.is_two_player:
				win_label.text = "PLAYER %d WINS!" % id
			else:
				win_label.text = "STAGE CLEAR!"
		
		await get_tree().create_timer(4.0).timeout
		get_tree().change_scene_to_file("res://Scenes/character_selection.tscn")
	else:
		# Optional: You can output a console log or update HUD text to show "Lap 2/3" here
		print("Player ", id, " is now on Lap ", current_laps + 1)
