# CameraRig.gd
extends Node3D

@export var target: RigidBody3D    # Drag your player ball here
@export var follow_speed := 8.0    # How fast camera catches up to position
@export var cam_turn_speed := 4.0  # How smoothly the camera swings behind the turn

func _physics_process(delta):
	if target == null:
		return

	# 1. Smoothly follow the ball's position
	global_position = global_position.lerp(
		target.global_position,
		follow_speed * delta
	)
	
	# 2. Smoothly rotate to line up behind the player's steering angle
	# lerp_angle is critical here because it handles the 0 to 360 degree snap seamlessly
	rotation.y = lerp_angle(
		rotation.y, 
		target.heading_angle, 
		cam_turn_speed * delta
	)
