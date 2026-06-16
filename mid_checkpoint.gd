# MidCheckpoint.gd
extends Area3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	# Check if a player entered this half of the track
	if body.has_method("trigger_respawn"):
		if body.player_id == 1:
			Global.p1_cleared_midpoint = true
		elif body.player_id == 2:
			Global.p2_cleared_midpoint = true
