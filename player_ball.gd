extends RigidBody3D

# ===== MOVEMENT =====
@export var move_force := 25.0
@export var max_speed := 15.0
@export var camera: Node3D

# ===== PHYSICS IDENTITY =====
@export var mass_factor := 1.0      # affects acceleration + inertia
@export var size_factor := 1.0      # affects scale + collision feel

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		get_tree().quit()

func _ready():
	apply_ball_profile()

func _physics_process(delta):

	var input_dir = Vector2.ZERO

	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")

	if input_dir == Vector2.ZERO:
		return

	# CAMERA-RELATIVE MOVEMENT
	var cam_forward = -camera.global_transform.basis.z
	var cam_right = camera.global_transform.basis.x

	cam_forward.y = 0
	cam_right.y = 0

	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()

	var move_dir = (cam_forward * input_dir.y + cam_right * input_dir.x).normalized()

	# ===== APPLY FORCE (mass-aware) =====
	var final_force = move_dir * move_force / mass_factor
	apply_central_force(final_force)

	# ===== SPEED LIMIT =====
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed


# ===== APPLY PHYSICS PROFILE =====
func apply_ball_profile():

	# scale visual size
	scale = Vector3.ONE * size_factor

	# adjust physics mass
	mass = mass_factor

	# optional feel tuning (VERY important for racing feel)
	linear_damp = 0.8 * mass_factor
	angular_damp = 1.0 * mass_factor
