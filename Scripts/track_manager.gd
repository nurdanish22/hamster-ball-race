# track_manager.gd
# Attach this script to the root node of Track01.tscn and Track02.tscn.
# It handles dynamic ball spawning based on Global.p1_choice / p2_choice,
# removes the hardcoded PlayerBall instances, and wires up the camera rigs.
extends Node3D

# ===== SPAWN POINT POSITIONS =====
# Adjust these to match your track's actual start positions
@export var p1_spawn_position := Vector3(7.0, 1.0, -4.5)
@export var p2_spawn_position := Vector3(7.5, 1.0, -7.6)

# Internal references set during _ready
var player1: RigidBody3D = null
var player2: RigidBody3D = null

func _ready() -> void:
	_remove_hardcoded_balls()
	_spawn_players()
	_wire_cameras()

# ─────────────────────────────────────────────────────────────────────────────
# Step 1: Remove any hardcoded PlayerBall instances baked into the scene
# ─────────────────────────────────────────────────────────────────────────────
func _remove_hardcoded_balls() -> void:
	for node_name in ["PlayerBall1", "PlayerBall2"]:
		var node = get_node_or_null(node_name)
		if node:
			node.queue_free()

# ─────────────────────────────────────────────────────────────────────────────
# Step 2: Instantiate player_ball.tscn for each active player and position them
# ─────────────────────────────────────────────────────────────────────────────
func _spawn_players() -> void:
	var player_ball_scene: PackedScene = load("res://Scenes/player_ball.tscn")
	if player_ball_scene == null:
		push_error("TrackManager: Could not load res://Scenes/player_ball.tscn")
		return

	# Always spawn Player 1
	player1 = player_ball_scene.instantiate()
	player1.name = "PlayerBall1"
	player1.player_id = 1
	add_child(player1)
	player1.global_position = p1_spawn_position

	# Only spawn Player 2 in two-player mode
	if Global.is_two_player:
		player2 = player_ball_scene.instantiate()
		player2.name = "PlayerBall2"
		player2.player_id = 2
		add_child(player2)
		player2.global_position = p2_spawn_position

# ─────────────────────────────────────────────────────────────────────────────
# Step 3: Point existing CameraRig nodes at the newly spawned players
# ─────────────────────────────────────────────────────────────────────────────
func _wire_cameras() -> void:
	# Track02 layout: CameraRig1 is a direct child of the root
	var cam_rig1 = get_node_or_null("CameraRig1")
	if cam_rig1 and player1:
		cam_rig1.target = player1

	# Track01 layout: cameras are nested inside SubViewports
	var cam_rig1_nested = get_node_or_null(
		"GridContainer/SubViewportContainer1/SubViewport1/CameraRig1"
	)
	if cam_rig1_nested and player1:
		cam_rig1_nested.target = player1

	if Global.is_two_player:
		var cam_rig2_nested = get_node_or_null(
			"GridContainer/SubViewportContainer2/SubViewport2/CameraRig2"
		)
		if cam_rig2_nested and player2:
			cam_rig2_nested.target = player2
