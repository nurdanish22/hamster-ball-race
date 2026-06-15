extends RigidBody3D

@export var move_force = 25.0
@export var max_speed = 15.0

@onready var camera = $CameraPivot/Camera3D

func _physics_process(delta):

	var input_dir = Vector2.ZERO

	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

	input_dir.y = Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")

	var cam_forward = -camera.global_transform.basis.z
	var cam_right = camera.global_transform.basis.x

	cam_forward.y = 0
	cam_right.y = 0

	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()

	var move_direction = (
		cam_forward * input_dir.y +
		cam_right * input_dir.x
	).normalized()

	if input_dir.length() > 0:
		apply_central_force(move_direction * move_force)

	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed
