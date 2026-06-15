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

# ===== CAMERA RIG REFERENCE (set by track_manager.gd after spawn) =====
# The CameraRig that follows this player. Used to read the camera's facing
# direction so the BallMesh can rotate to face it when moving forward.
var camera_rig: Node3D = null

# Smooth rotation speed for the visual mesh facing direction (degrees/sec feel)
@export var mesh_turn_speed := 10.0

# ===== ANIMATION =====
# Reference to the AnimationPlayer inside the hamsteranimated2 node.
# Populated automatically in apply_ball_profile().
var anim_player: AnimationPlayer = null

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

	# 6. VISUAL MESH ORIENTATION
	# Keep BallMesh upright and facing the camera's forward direction.
	var is_moving: bool = abs(forward_input) > 0.01
	_update_ball_mesh_rotation(delta, is_moving)

	# 7. ANIMATION CONTROL
	_update_animation(is_moving)


func _update_animation(is_moving: bool) -> void:
	if anim_player == null:
		return

	if is_moving:
		# Switch to "running" if not already playing it
		if anim_player.current_animation != "running":
			anim_player.play("running")

		# Dynamic speed scale based on horizontal (XZ) velocity.
		# At max_speed the animation plays at 1.0x (natural pace).
		# Clamped to [0.1, 2.0] so it never freezes or looks absurd.
		var horizontal_speed: float = Vector2(linear_velocity.x, linear_velocity.z).length()
		anim_player.speed_scale = clamp(horizontal_speed / max_speed, 0.1, 2.0)
	else:
		# Transition to idle and reset speed_scale to natural pace
		if anim_player.current_animation != "Idle":
			anim_player.speed_scale = 1.0
			anim_player.play("Idle")


func _update_ball_mesh_rotation(delta: float, is_moving: bool) -> void:
	var mesh: Node3D = get_node_or_null("BallMesh")
	if mesh == null:
		return

	# --- Step A: Start from the mesh's current Y so it doesn't snap ---
	# Because lock_rotation = true the body won't rotate, but we still force the
	# mesh's world rotation to be flat (no X/Z tilt) every frame.
	var target_y_angle: float = mesh.global_rotation.y

	# --- Step B: When moving, rotate the mesh to face the camera direction ---
	if is_moving and camera_rig != null:
		# The CameraRig's -Z axis (forward) projected onto the XZ plane gives us
		# the direction the camera is currently facing.
		var cam_forward: Vector3 = -camera_rig.global_transform.basis.z
		cam_forward.y = 0.0
		if cam_forward.length_squared() > 0.001:
			cam_forward = cam_forward.normalized()
			# atan2 gives us the Y-axis angle for that direction
			target_y_angle = atan2(cam_forward.x, cam_forward.z)
			# If moving backward, flip 180 degrees so the mesh faces away from camera
			if Input.get_action_strength(input_backward) < Input.get_action_strength(input_forward):
				target_y_angle += PI

	# --- Step C: Smoothly interpolate the mesh's Y rotation toward the target ---
	var current_y: float = mesh.global_rotation.y
	var new_y: float = lerp_angle(current_y, target_y_angle, mesh_turn_speed * delta)

	# Apply: zero out X and Z tilt, only allow Y rotation
	mesh.global_rotation = Vector3(0.0, new_y, 0.0)


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
	# Lock all angular rotation on the physics body so the RigidBody3D never
	# visibly rolls or tips. The BallMesh child handles all visual orientation.
	lock_rotation = true

	# ===== DYNAMIC MESH SWAP =====
	# Remove the old placeholder MeshInstance3D (if present)
	var old_mesh = get_node_or_null("MeshInstance3D")
	if old_mesh:
		old_mesh.queue_free()

	# Load and instantiate the correct ball visual scene
	var choice: String = Global.p1_choice if player_id == 1 else Global.p2_choice
	var ball_scene_path: String = Global.BALL_SCENES.get(choice, Global.BALL_SCENES["standard"])
	var ball_scene: PackedScene = load(ball_scene_path)
	if ball_scene:
		var ball_visual: Node3D = ball_scene.instantiate()
		# The Balls/*.tscn root is a RigidBody3D.
		# We create a single container "BallMesh" Node3D and move ALL visual
		# children (ball shell + hamsteranimated2) into it, skipping only
		# CollisionShape3D which belongs to the physics body we're discarding.
		var container: Node3D = Node3D.new()
		container.name = "BallMesh"
		add_child(container)

		# Collect children first (can't iterate while re-parenting)
		var visual_children: Array = []
		for child in ball_visual.get_children():
			if not child is CollisionShape3D:
				visual_children.append(child)

		for visual_child in visual_children:
			ball_visual.remove_child(visual_child)
			container.add_child(visual_child)

		# Find and cache the AnimationPlayer inside hamsteranimated2
		var hamster: Node = container.get_node_or_null("hamsteranimated2")
		if hamster:
			anim_player = hamster.get_node_or_null("AnimationPlayer")
			if anim_player:
				anim_player.play("Idle")

		ball_visual.queue_free()
