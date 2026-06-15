extends RigidBody3D

# ===== MOVEMENT =====
@export var move_force := 35.0      
@export var max_speed := 15.0
@export var turn_speed := 3.0       

# ===== DYNAMIC RESPAWN SYSTEM =====
@export var void_check_distance := 30.0 
@export var void_time_limit := 2.5     # How many seconds to fall before respawning
var void_timer := 0.0                  # Tracks how long we've been in empty space

var respawn_position := Vector3.ZERO   
var respawn_heading := 0.0             
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
	# 1. RUN SMART GROUND & VOID DETECTION (Now takes delta)
	check_ground_and_void(delta)
	
	if should_respawn:
		return 

	# 2. HANDLE STEERING
	var steer_input = Input.get_action_strength("move_left") - Input.get_action_strength("move_right")
	heading_angle += steer_input * turn_speed * delta
	heading_angle = wrapf(heading_angle, 0.0, TAU) 

	# 3. GET FORWARD/BACKWARD INPUT
	var forward_input = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")

	# 4. CALCULATE DIRECTION
	var move_dir = Vector3.FORWARD.rotated(Vector3.UP, heading_angle)

	# ===== APPLY FORCE =====
	if abs(forward_input) > 0.01:
		var final_force = move_dir * forward_input * move_force / mass_factor
		apply_central_force(final_force)

	# ===== SPEED LIMIT =====
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed


func check_ground_and_void(delta: float):
	var space_state = get_world_3d().direct_space_state
	var start = global_position
	
	# ---- RAY 1: SHORT GROUND TRACKER ----
	var short_end = global_position + Vector3.DOWN * (size_factor + 0.5)
	var short_query = PhysicsRayQueryParameters3D.create(start, short_end)
	short_query.exclude = [get_rid()]
	
	var ground_hit = space_state.intersect_ray(short_query)
	
	if ground_hit:
		# Player is safely driving on the track. Save this location and reset timer!
		respawn_position = ground_hit.position + Vector3.UP * (size_factor * 0.6)
		respawn_heading = heading_angle
		void_timer = 0.0
	else:
		# ---- RAY 2: LONG VOID CHECKER (Airborne) ----
		if linear_velocity.y < -1.0:
			var long_end = global_position + Vector3.DOWN * void_check_distance
			var long_query = PhysicsRayQueryParameters3D.create(start, long_end)
			long_query.exclude = [get_rid()]
			
			var void_hit = space_state.intersect_ray(long_query)
			
			# If the long ray hits ABSOLUTELY NOTHING, they are in the void
			if not void_hit:
				void_timer += delta
				
				# Only trigger respawn if they've been out of bounds long enough
				if void_timer >= void_time_limit and not should_respawn:
					trigger_respawn()
			else:
				# They are airborne but a track is below them, reset the timer
				void_timer = 0.0
		else:
			# Player is either going up a ramp or stationary, keep timer at 0
			void_timer = 0.0


func trigger_respawn():
	should_respawn = true


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if should_respawn:
		# Teleport to the last saved track segment
		var current_transform = state.transform
		current_transform.origin = respawn_position
		state.transform = current_transform
		
		# Reset driving heading
		heading_angle = respawn_heading
		
		# Kill all physics velocity
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		
		# Reset our timer for the next fall
		void_timer = 0.0
		should_respawn = false


# ===== APPLY PHYSICS PROFILE =====
func apply_ball_profile():
	scale = Vector3.ONE * size_factor
	mass = mass_factor
	linear_damp = 0.8 * mass_factor
	angular_damp = 1.0 * mass_factor
