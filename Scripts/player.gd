extends RigidBody3D

# ===== MULTIPLAYER IDENTITY =====
@export_enum("Player 1:1", "Player 2:2") var player_id: int = 1

var ball_color := Color.WHITE

# ===== MOVEMENT (Values will be overwritten by Global) =====
var move_force := 35.0      
var max_speed := 15.0
var turn_speed := 3.0       

# ===== DYNAMIC RESPAWN SYSTEM =====
@export var void_check_distance := 30.0 
@export var void_time_limit := 2.5     
var void_timer := 0.0                  
var respawn_position := Vector3.ZERO   
var respawn_heading := 0.0             
var should_respawn := false            

# ===== PHYSICS IDENTITY =====
var mass_factor := 1.0      
var size_factor := 1.0      

var heading_angle := 0.0

# Dynamic Input Action Strings
var input_left := ""
var input_right := ""
var input_forward := ""
var input_backward := ""

func _ready():
	# 1. Setup split screen controls dynamically based on ID
	input_left = "move_left_p" + str(player_id)
	input_right = "move_right_p" + str(player_id)
	input_forward = "move_forward_p" + str(player_id)
	input_backward = "move_backward_p" + str(player_id)

	# 2. Fetch selected stats from Autoload
	load_selected_profile()
	
	# 3. Apply the physical changes
	apply_ball_profile()
	
	respawn_position = global_position 
	respawn_heading = heading_angle


func load_selected_profile():
	# Check whether this specific node is P1 or P2
	var choice = Global.p1_choice if player_id == 1 else Global.p2_choice
	var profile = Global.BALL_PROFILES[choice]
	
	# Inject stats
	mass_factor = profile["mass_factor"]
	size_factor = profile["size_factor"]
	move_force = profile["move_force"]
	max_speed = profile["max_speed"]
	ball_color = profile["color"]


func _physics_process(delta):
	check_ground_and_void(delta)
	if should_respawn: return 

	# 4. HANDLE STEERING (Using dynamic inputs)
	var steer_input = Input.get_action_strength(input_left) - Input.get_action_strength(input_right)
	heading_angle += steer_input * turn_speed * delta
	heading_angle = wrapf(heading_angle, 0.0, TAU) 

	# 5. GET FORWARD/BACKWARD INPUT
	var forward_input = Input.get_action_strength(input_backward) - Input.get_action_strength(input_forward)

	var move_dir = Vector3.FORWARD.rotated(Vector3.UP, heading_angle)

	if abs(forward_input) > 0.01:
		var final_force = move_dir * forward_input * move_force / mass_factor
		apply_central_force(final_force)

	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed


func check_ground_and_void(delta: float):
	var space_state = get_world_3d().direct_space_state
	var start = global_position
	
	var short_end = global_position + Vector3.DOWN * (size_factor + 0.5)
	var short_query = PhysicsRayQueryParameters3D.create(start, short_end)
	short_query.exclude = [get_rid()]
	var ground_hit = space_state.intersect_ray(short_query)
	
	if ground_hit:
		respawn_position = ground_hit.position + Vector3.UP * (size_factor * 0.6)
		respawn_heading = heading_angle
		void_timer = 0.0
	else:
		if linear_velocity.y < -1.0:
			var long_end = global_position + Vector3.DOWN * void_check_distance
			var long_query = PhysicsRayQueryParameters3D.create(start, long_end)
			long_query.exclude = [get_rid()]
			var void_hit = space_state.intersect_ray(long_query)
			
			if not void_hit:
				void_timer += delta
				if void_timer >= void_time_limit and not should_respawn:
					trigger_respawn()
			else:
				void_timer = 0.0
		else:
			void_timer = 0.0

func trigger_respawn():
	should_respawn = true

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if should_respawn:
		var current_transform = state.transform
		current_transform.origin = respawn_position
		state.transform = current_transform
		heading_angle = respawn_heading
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		void_timer = 0.0
		should_respawn = false

func apply_ball_profile():
	scale = Vector3.ONE * size_factor
	mass = mass_factor
	linear_damp = 0.8 * mass_factor
	angular_damp = 1.0 * mass_factor

	# DYNAMIC COLOR CODES
	var mesh_node = get_node_or_null("MeshInstance3D")
	if mesh_node and mesh_node is MeshInstance3D:
		var new_material = StandardMaterial3D.new()
		new_material.albedo_color = ball_color

		# This forces the mesh to use temporary script-generated color
		mesh_node.material_override = new_material
