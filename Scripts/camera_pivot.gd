extends Node3D

@export var target : Node3D
@export var lerp_speed: float = 10.0

func _process(delta):

	if target == null:
		return

	look_at(target.global_position)

	# Smoothly move the camera pivot to the ball's position
	global_transform.origin = global_transform.origin.lerp($PlayerBall.global_transform.origin, lerp_speed * delta)
	
	# Make the camera look directly at the ball
	look_at($PlayerBall.global_transform.origin, Vector3.UP)
