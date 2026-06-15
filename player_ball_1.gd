extends RigidBody3D

# ===== MOVEMENT =====
@export var move_force := 35.0      
@export var max_speed := 15.0
@export var turn_speed := 3.0       

# ===== DYNAMIC RESPAWN SYSTEM =====
@export var fall_limit := -10.0       
var respawn_position := Vector3.ZERO   
var respawn_heading := 0.0             # Remembers which way we were facing when safe
var should_respawn := false            

# ===== PHYSICS IDENTITY =====
@export var mass_factor := 1.0      
@export var size_factor := 1.0      

var heading_angle := 0.0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		get_tree().quit()

func _ready():
	apply_ball_profile()
	respawn_position = global_position 
	respawn_heading = heading_angle

func _physics_process(delta):
	# 1. CHECK IF FELL OFF THE TRACK
	if global_position.y < fall_limit and not should_respawn:
		trigger_respawn()
		return 

	# 2. DYNAMICALLY TRACK THE GROUND BENEATH THE BALL
	track_last_grounded_position()

	# 3. HANDLE STEERING
	var steer_input = Input.get_action_strength("move_left") - Input.get_action_strength("move_right")
	heading_angle += steer_input * turn_speed * delta
	heading_angle = wrapf(heading_angle, 0.0, TAU) 

	# 4. GET FORWARD/BACKWARD INPUT
	var forward_input = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")

	# 5. CALCULATE DIRECTION
	var move_dir = Vector3.FORWARD.rotated(Vector3.UP, heading_angle)

	# ===== APPLY FORCE =====
	if abs(forward_input) > 0.01:
		var final_force = move_dir * forward_input * move_force / mass_factor
		apply_central_force(final_force)

	# ===== SPEED LIMIT =====
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed


func track_last_grounded_position():
	# Get the direct 3D physics state
	var space_state = get_world_3d().direct_space_state
	
	# Set raycast start (ball center) and end (slightly below the ball)
	# Adjusted for size_factor so it scales if ball changes size
	var start = global_position
	var end = global_position + Vector3.DOWN * (size_factor + 0.5)
	
	var query = PhysicsRayQueryParameters3D.create(start, end)
	
	# OPTIONAL: Exclude the player ball itself from the raycast
	query.exclude = [get_rid()]
	
	var result = space_state.intersect_ray(query)
	
	# If the ray hits the track, save this spot!
	if result:
		# Add a small vertical offset (Vector3.UP) so the ball doesn't spawn stuck inside the mesh
		respawn_position = result.position + Vector3.UP * (size_factor * 0.6)
		respawn_heading = heading_angle


func trigger_respawn():
	should_respawn = true


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if should_respawn:
		# Teleport to the last saved ground position
		var current_transform = state.transform
		current_transform.origin = respawn_position
		state.transform = current_transform
		
		# Reset our driving heading so the camera and controls match the moment before the fall
		heading_angle = respawn_heading
		
		# Kill the falling physics momentum
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		
		should_respawn = false


# ===== APPLY PHYSICS PROFILE =====
func apply_ball_profile():
	scale = Vector3.ONE * size_factor
	mass = mass_factor
	linear_damp = 0.8 * mass_factor
	angular_damp = 1.0 * mass_factor
