extends Node3D

var cue_ball: RigidBody3D
var power: float = 0.0
var max_power: float = 15.0
var is_aiming: bool = false # Set to true when in aiming state
var is_power_setting: bool = false # Set to true when in power state
var shot_taken: bool = false
var touch_start_position: Vector2
var current_touch_position: Vector2
var max_drag_distance: float = 300.0
var stick_length: float = 1.2
var stick_mass: float = 0.5
var initial_position: Vector3
var last_aim_position: Vector3 # Store the last valid position for smoother movement

# Safety constraints
var min_safe_distance: float = 0.12  # Minimum distance between head and ball during aiming
var ball_radius: float = 0.05        # Cue ball radius for distance calculations

# Named parts of the stick
var head_position: Vector3  # Thinner end (near ball)
var tail_position: Vector3  # Thicker end (away from ball)

# Physical stick properties
var linear_velocity: Vector3 = Vector3.ZERO
var angular_velocity: Vector3 = Vector3.ZERO

# Trajectory prediction
var trajectory_line: Node3D

# Camera reference for better 2D to 3D conversions
var camera: Camera3D

# Current aim angle in radians (0 = pointing toward negative Z, increases clockwise)
var aim_angle: float = 0.0

# For smoother aiming
var current_aim_direction: Vector3 = Vector3(0, 0, -1)

# Game manager reference
var game_manager: GameManager

@onready var ray_cast = $RayCast3D
@onready var power_meter = get_node_or_null("/root/NineBallGame/UI/PowerMeter")

func _ready():
	# Ensure the node is visible
	visible = true
	print("Cue stick ready! Visibility: ", visible)
	
	# Find trajectory line if it exists
	trajectory_line = get_node_or_null("/root/NineBallGame/TrajectoryLine")
	
	# Find the main camera
	camera = get_viewport().get_camera_3d()
	
	# Check for the cue stick mesh
	var stick_mesh = $StickMesh
	if not is_instance_valid(stick_mesh) or not stick_mesh is MeshInstance3D:
		# Create a default stick visualization
		create_default_mesh()
		print("Created default mesh for cue stick")
	else:
		print("Using existing mesh for cue stick: ", stick_mesh.name)
		# Ensure the existing mesh is oriented correctly
		fix_stick_orientation(stick_mesh)
	
	if power_meter:
		power_meter.max_value = 1.0
		power_meter.value = 0
	
	# Find the game manager to connect state signals
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.connect("game_state_changed", _on_game_state_changed)
	else:
		push_warning("Could not find game manager for cue stick")

# Handle game state changes
func _on_game_state_changed(new_state):
	match new_state:
		GameManager.GameState.READY:
			is_aiming = false
			is_power_setting = false
			shot_taken = false
			power = 0.0
			
			# Update stick visuals for ready state
			if power_meter:
				power_meter.value = 0
				power_meter.visible = false
			
			# Make sure we still have a reference to the cue ball
			if not cue_ball and game_manager:
				# Try to find the cue ball in the scene
				cue_ball = get_tree().get_first_node_in_group("cue_ball")
				if not cue_ball:
					print("Warning: Could not find cue ball reference for READY state")
					return
			
			# Now setup for ready state
			setup_for_ready_state()
			
		GameManager.GameState.AIMING:
			is_aiming = true
			is_power_setting = false
			
			# Update trajectory
			if trajectory_line:
				trajectory_line.set_trajectory_visible(true)
				update_trajectory_line()
			
		GameManager.GameState.POWER:
			is_aiming = false
			is_power_setting = true
			
			# Show power meter
			if power_meter:
				power_meter.visible = true
			
		GameManager.GameState.SHOT:
			is_aiming = false
			is_power_setting = false
			shot_taken = true
			
			# Hide UI elements
			if power_meter:
				power_meter.visible = false
				
			if trajectory_line:
				trajectory_line.set_trajectory_visible(false)

# Fix the orientation of the stick mesh to ensure the thinner end is near the ball
func fix_stick_orientation(stick_mesh: MeshInstance3D):
	# Assuming the mesh has been created with top_radius smaller than bottom_radius
	# We need to make sure the thinner end (top) is facing the ball
	
	# The stick's Z axis should point toward the ball
	# For most meshes in Godot, the local Z+ would be pointing away from the ball
	# So we need to rotate it 180 degrees around Y axis to flip it
	
	# Check if the mesh is already correctly oriented
	var mesh = stick_mesh.mesh
	if mesh is CylinderMesh:
		print("Stick mesh dimensions - Top (head): ", mesh.top_radius, " Bottom (tail): ", mesh.bottom_radius)
		
		# If the top radius (which should be the head) is larger than the bottom, we need to flip it
		if mesh.top_radius > mesh.bottom_radius:
			print("Fixing stick orientation - flipping cylinder mesh")
			mesh.top_radius = 0.01  # Head (near ball)
			mesh.bottom_radius = 0.02  # Tail (away from ball)
	
	# Ensure the stick is correctly oriented with head toward the ball
	stick_mesh.rotation_degrees.y = 180
	
	print("Stick orientation fixed - head is now facing the ball")

# Create a default visualization mesh if none exists
func create_default_mesh():
	print("Creating default cue stick mesh")
	
	# Create a mesh instance for the stick
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "StickMesh"
	
	# Create a cylinder mesh for the stick
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.01  # Head (thinner end near ball)
	cylinder.bottom_radius = 0.02  # Tail (thicker end away from ball)
	cylinder.height = stick_length
	
	mesh_instance.mesh = cylinder
	
	# Create a material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.6, 0.4)
	material.metallic = 0.1
	material.roughness = 0.2
	
	mesh_instance.material_override = material
	
	# Create a collision shape that matches the mesh
	var collision_shape = CollisionShape3D.new()
	var capsule_shape = CapsuleShape3D.new()
	capsule_shape.radius = 0.015
	capsule_shape.height = stick_length
	collision_shape.shape = capsule_shape
	
	# Add mesh and collision to the stick
	add_child(mesh_instance)
	add_child(collision_shape)
	
	# Orient the mesh to point along Z axis with head toward ball
	mesh_instance.transform.basis = Basis.from_euler(Vector3(PI/2, 0, 0))
	collision_shape.transform.basis = Basis.from_euler(Vector3(PI/2, 0, 0))
	
	# Ensure the head is facing the ball by rotating 180 degrees
	mesh_instance.rotation_degrees.z = 180
	
	# Position mesh properly
	mesh_instance.position.z = -stick_length/2
	collision_shape.position.z = -stick_length/2
	
	print("Created stick mesh with head radius: ", cylinder.top_radius, " and tail radius: ", cylinder.bottom_radius)

func setup(ball):
	print("Cue stick setup called with ball: ", ball)
	cue_ball = ball
	
	if cue_ball:
		print("Cue ball position: ", cue_ball.global_position)
	else:
		print("Cue ball is null!")
		return
	
	# Initial position - behind the ball
	var initial_dir = Vector3(0, 0, -1)  # Default direction (away from player)
	position_stick_behind_ball(initial_dir)
	
	# Store initial position
	initial_position = global_position
	last_aim_position = global_position
	current_aim_direction = initial_dir
	
	# Set up trajectory visualization if available
	if trajectory_line:
		trajectory_line.cue_ball = cue_ball
		trajectory_line.cue_stick = self
		update_trajectory_line()
	
	# Verify stick orientation after positioning
	update_head_tail_positions()
	debug_stick_orientation()
	
	# Verify safe distance
	verify_safe_distance("setup")

# Setup specifically for the READY state
func setup_for_ready_state():
	if not cue_ball:
		print("Cannot setup for ready state: cue ball is null")
		return
	
	# Reset power
	power = 0.0
	if power_meter:
		power_meter.value = 0
	
	# Position behind the ball
	position_stick_behind_ball(current_aim_direction)
	
	# Update positions and verify
	update_head_tail_positions()
	verify_safe_distance("ready_state")
	debug_stick_orientation()
	
	print("Cue stick ready for player input!")

func update_head_tail_positions():
	# Calculate head and tail positions based on the stick's current orientation
	var forward_direction = -global_transform.basis.z.normalized()
	head_position = global_position + forward_direction * (stick_length * 0.5)  # Head near ball
	tail_position = global_position - forward_direction * (stick_length * 0.5)  # Tail away from ball

# Check and ensure minimum safe distance between stick and ball during aiming
func verify_safe_distance(context: String = ""):
	if not cue_ball:
		return true
	
	update_head_tail_positions()
	var head_to_ball_distance = head_position.distance_to(cue_ball.global_position)
	
	# Calculate the difference between current distance and safe distance
	var distance_diff = head_to_ball_distance - min_safe_distance
	
	if distance_diff < 0:
		# Too close! Adjust stick position
		var correction_direction = (global_position - cue_ball.global_position).normalized()
		correction_direction.y = 0  # Keep correction parallel to table
		
		# Move the stick away to maintain safe distance
		global_position += correction_direction * abs(distance_diff) * 1.1  # Add a small buffer
		update_head_tail_positions()
		
		print("SAFETY CHECK (" + context + "): Adjusted stick position to maintain safe distance. New distance: ", 
			head_position.distance_to(cue_ball.global_position))
		return false
	
	if context != "":
		print("SAFETY CHECK (" + context + "): Distance OK: ", head_to_ball_distance)
	return true

func debug_stick_orientation():
	update_head_tail_positions()
	
	# Check if head is closer to the ball than tail
	var head_to_ball_distance = head_position.distance_to(cue_ball.global_position)
	var tail_to_ball_distance = tail_position.distance_to(cue_ball.global_position)
	
	print("STICK ORIENTATION CHECK:")
	print("- Head position: ", head_position)
	print("- Tail position: ", tail_position)
	print("- Head to ball distance: ", head_to_ball_distance)
	print("- Tail to ball distance: ", tail_to_ball_distance)
	
	if head_to_ball_distance < tail_to_ball_distance:
		print("CORRECT: Head is closer to the ball than tail")
	else:
		print("ERROR: Tail is closer to the ball than head")

func _physics_process(delta):
	if not cue_ball:
		return
		
	# Update trajectory line if available and in aiming mode
	if trajectory_line and is_aiming:
		update_trajectory_line()
	
	# If we're simulating the physical stick moving after a shot
	if shot_taken and linear_velocity != Vector3.ZERO:
		# Move the stick according to its velocity
		position += linear_velocity * delta
		rotation += angular_velocity * delta
		
		# Simulate some damping (reduced from 0.95 to make movement last longer)
		linear_velocity *= 0.98
		angular_velocity *= 0.98
		
		# Check for collision with the cue ball
		update_head_tail_positions()
		var distance_to_ball = head_position.distance_to(cue_ball.global_position)
		
		if distance_to_ball < ball_radius + 0.01:  # Ball radius + a little buffer
			# We hit the ball! Apply impulse to it
			var direction = (cue_ball.global_position - head_position).normalized()
			direction.y = 0  # Keep it parallel to the table
			
			# Calculate collision impulse based on velocity
			var impulse = direction * linear_velocity.length() * stick_mass
			cue_ball.apply_central_impulse(impulse)
			
			# Apply some linear velocity to the ball directly as well
			if cue_ball.linear_velocity.length() < 0.1:
				cue_ball.linear_velocity = direction * linear_velocity.length() * 0.8
			
			print("Stick hit the cue ball with impulse: ", impulse.length())
			print("Ball velocity after hit: ", cue_ball.linear_velocity)
			
			# Stop the stick but don't set to exactly zero to allow small movement
			linear_velocity *= 0.1
		
		# Check if the stick has moved far enough or slowed down enough to stop
		if linear_velocity.length() < 0.1:
			linear_velocity = Vector3.ZERO
			angular_velocity = Vector3.ZERO
			print("Stick stopped moving due to low velocity")
			
	# If in aiming mode, ensure we maintain safe distance
	elif is_aiming and Engine.get_physics_frames() % 15 == 0:  # Only check occasionally to avoid performance impact
		verify_safe_distance()

# Position the stick behind the cue ball
func position_stick_behind_ball(direction: Vector3):
	if not cue_ball:
		print("Cannot position stick: cue ball is null")
		return
	
	# Calculate position behind the ball
	var offset_distance = stick_length * 0.6 + min_safe_distance  # Added safe distance
	var pos = cue_ball.global_position + direction * offset_distance
	
	# Position the stick higher above the table so it's more visible
	pos.y = cue_ball.global_position.y + 0.15  # Increased height above the table
	
	# Set position and look at cue ball
	global_position = pos
	look_at(cue_ball.global_position, Vector3.UP)
	
	# Apply a slight rotation to ensure the stick is parallel to the table
	rotation.x = 0
	
	# Update last aim position
	last_aim_position = pos
	
	# Update head and tail positions after positioning
	update_head_tail_positions()
	
	print("Positioned cue stick at: ", global_position, " looking at ball at: ", cue_ball.global_position)
	print("Head position: ", head_position, " - Tail position: ", tail_position)

# Update the trajectory visualization
func update_trajectory_line():
	if not trajectory_line or not cue_ball:
		return
	
	# Get the direction from the stick to the ball (more accurate than global_transform)
	var direction = (cue_ball.global_position - global_position).normalized()
	direction.y = 0  # Make sure it's parallel to the table
	
	# Check if we have a valid direction
	if direction.length() < 0.1:
		direction = -global_transform.basis.z.normalized()
		direction.y = 0
	
	# Make sure we have a normalized direction
	direction = direction.normalized()
	
	# Show trajectory line
	trajectory_line.set_trajectory_visible(true)
	trajectory_line.update_trajectory(power, direction)

func _input(event):
	if not cue_ball or not game_manager:
		return
	
	# Only process inputs in READY, AIMING, or POWER states
	if game_manager.game_state == GameManager.GameState.SHOT:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start aiming if in READY state
				if game_manager.game_state == GameManager.GameState.READY:
					touch_start_position = event.position
					game_manager.change_game_state(GameManager.GameState.AIMING)
					
				# Start power setting if in AIMING state
				elif game_manager.game_state == GameManager.GameState.AIMING:
					touch_start_position = event.position
					game_manager.change_game_state(GameManager.GameState.POWER)
			else:
				# Handle releasing the button
				if game_manager.game_state == GameManager.GameState.POWER:
					# Execute the shot
					execute_shot()
					game_manager.change_game_state(GameManager.GameState.SHOT)
				
	elif event is InputEventMouseMotion:
		if game_manager.game_state == GameManager.GameState.READY:
			# Start aiming when the user begins to drag
			touch_start_position = event.position
			game_manager.change_game_state(GameManager.GameState.AIMING)
		elif game_manager.game_state == GameManager.GameState.AIMING:
			# Update the direction of the cue stick based on the drag
			handle_aiming_input(event.position)

	elif event is InputEventScreenDrag:
		if game_manager.game_state == GameManager.GameState.POWER:
			# Handle power adjustment based on vertical drag
			handle_power_input(event.position)

# Handle user input for aiming
func handle_aiming_input(position):
	if not camera or not cue_ball:
		return
		
	# Calculate the new direction based on the drag position
	var drag_vector = position - touch_start_position
	
	# Convert to angle in XZ plane (table plane)
	var angle = atan2(drag_vector.x, -drag_vector.y)  # Negative Y is forward in screen space
	
	# Create direction vector from angle (3D vector)
	var direction = Vector3(sin(angle), 0, cos(angle))
	
	# Position the stick in this direction
	position_stick_for_aim(direction)
	
	# Update aim angle for use in other calculations
	aim_angle = angle

# Position the stick for aiming in a specific direction
func position_stick_for_aim(direction: Vector3):
	if not cue_ball:
		return
		
	# Normalize direction and ensure it's parallel to the table
	direction.y = 0
	direction = direction.normalized()
	
	# Calculate position behind the ball with safe distance
	var offset_distance = stick_length * 0.6 + min_safe_distance  # Added safe distance
	var pos = cue_ball.global_position + direction * offset_distance
	
	# Keep stick elevated above the table
	pos.y = cue_ball.global_position.y + 0.15
	
	# Set position directly - no smoothing for immediate feedback
	global_position = pos
	
	# Look at cue ball - this can be immediate
	look_at(cue_ball.global_position, Vector3.UP)
	
	# Store this as the initial position for pullback
	initial_position = global_position
	
	# Update head and tail positions
	update_head_tail_positions()
	
	# Store the current aim angle and direction
	aim_angle = atan2(direction.x, direction.z)
	current_aim_direction = direction
	
	if Engine.get_physics_frames() % 30 == 0:
		print("Positioned stick for aim: ", global_position, " Direction: ", direction, " Angle: ", rad_to_deg(aim_angle))
		
	# Ensure safe distance is maintained
	verify_safe_distance("aim")

# Handle user input for power
func handle_power_input(position):
	if not initial_position or not cue_ball:
		return
	
	# Calculate power based on the vertical position of the drag
	var power_ratio = position.y / get_viewport().size.y
	power = clamp(power_ratio, 0.0, 1.0)
	
	# Direction is from the stick's current position toward the ball
	var stick_direction = (cue_ball.global_position - initial_position).normalized()
	stick_direction.y = 0  # Keep parallel to table
	
	# Calculate pull-back distance based on power
	var pull_back_distance = power * stick_length * 0.5
	
	# Pull the stick back
	global_position = initial_position - stick_direction * pull_back_distance
	
	# Make sure we're still looking at the ball
	look_at(cue_ball.global_position, Vector3.UP)
	
	# Ensure we haven't violated the safe distance rule
	if not verify_safe_distance("drag"):
		# If adjustment was needed, update initial_position to prevent oscillation
		initial_position = global_position - stick_direction * pull_back_distance
	
	# Update power meter if available
	if power_meter:
		power_meter.value = power
	
	# Update trajectory prediction
	if trajectory_line:
		update_trajectory_line()
	
	# Debug the orientation during dragging (only occasionally to avoid spam)
	if Engine.get_physics_frames() % 60 == 0:
		debug_stick_orientation()

func execute_shot():
	if not cue_ball:
		return
	
	# Debug logging
	print("Execute shot called with power: ", power)
	
	# Get the direction from head to ball for accurate shooting
	update_head_tail_positions()
	var direction = (cue_ball.global_position - head_position).normalized()
	direction.y = 0  # Keep it parallel to the table
	
	# Calculate velocity to apply (ensure it's strong enough to move)
	var actual_power = max(power, 0.2)  # Ensure minimum power for shot
	
	# Record the stick's current position before moving forward
	var start_position = global_position
	
	# Now we can move the stick toward the ball for the shot
	# Apply forward movement to simulate the "strike"
	linear_velocity = direction * (actual_power * max_power * 1.5)
	
	# Track that shot has been taken
	shot_taken = true
	
	# Apply force directly to the ball based on power and direction
	cue_ball.linear_velocity = direction * (actual_power * max_power)
	
	print("Applied linear velocity: ", cue_ball.linear_velocity, " Length: ", cue_ball.linear_velocity.length())
	print("Shot direction (from head to ball): ", direction)
	print("Stick is now moving toward ball for strike")

# Get the current aim angle in radians
func get_aim_angle() -> float:
	return aim_angle

func update_cue_stick_direction(direction):
	# Convert screen direction to world direction if necessary
	# Update the cue stick's orientation based on the new direction
	var angle = atan2(direction.x, direction.y)
	rotation_degrees.y = rad_to_deg(angle)
