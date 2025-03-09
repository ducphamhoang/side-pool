class_name TrajectoryVisualization
extends Node3D

# Node references
@onready var dot_container = $DotContainer
@onready var dot_prototype = $DotContainer/Dot

# Properties
var cue_ball: RigidBody3D
var cue_stick: Node3D
var is_visible_trajectory: bool = false
var max_distance: float = 4.0  # Reduced for more accurate short-range prediction
var segment_length: float = 0.075  # Smaller segments for smoother visualization
var max_dots: int = 40  # More dots for better visualization
var dots = []
var table_height: float = 0.06  # Height of the table surface

func _ready():
	# Initially hide the trajectory
	set_trajectory_visible(false)
	
	# Clone the dot prototype to create our dots array
	dot_prototype.visible = false
	for i in range(max_dots):
		var new_dot = dot_prototype.duplicate()
		dot_container.add_child(new_dot)
		dots.append(new_dot)
		new_dot.visible = false

func set_trajectory_visible(value: bool):
	is_visible_trajectory = value
	visible = value
	
	# Hide all dots when hiding the trajectory
	if not value:
		for dot in dots:
			dot.visible = false

func update_trajectory(power: float = 1.0, direction: Vector3 = Vector3.ZERO):
	if not is_visible_trajectory or not cue_ball:
		return
	
	# Use provided direction if given, otherwise try to get it from cue stick
	var shot_direction = direction
	if shot_direction == Vector3.ZERO and cue_stick:
		shot_direction = (cue_ball.global_position - cue_stick.global_position).normalized()
	
	if shot_direction == Vector3.ZERO:
		return  # No valid direction found
	
	# Ensure the direction is parallel to the table
	shot_direction.y = 0
	shot_direction = shot_direction.normalized()
	
	# Clear previous trajectory visualization
	clear_line()
	
	# Start point is the cue ball position, but ensure it's at table height
	var start_point = cue_ball.global_position
	start_point.y = table_height
	
	# Set up physics space state for raycast
	var space_state = get_world_3d().direct_space_state
	var current_distance = 0.1  # Start just ahead of the ball
	
	# Calculate adjusted max distance based on power
	var adjusted_max_distance = max_distance * max(power, 0.2)  # Min power for visualization
	var dot_index = 0
	
	# Continue adding dots until max distance, collision, or max dots reached
	while current_distance < adjusted_max_distance and dot_index < max_dots:
		# Calculate next point (always at table height)
		var next_point = Vector3(
			start_point.x + shot_direction.x * current_distance,
			table_height,
			start_point.z + shot_direction.z * current_distance
		)
		
		# Check for collision
		var query = PhysicsRayQueryParameters3D.new()
		query.from = start_point + shot_direction * 0.06  # Start slightly away from the ball (ball radius)
		query.to = next_point
		query.exclude = [cue_ball]
		query.collision_mask = 6  # Check for collisions with table (2) and edges (4)
		
		var result = space_state.intersect_ray(query)
		
		if result:
			# Hit something, add final dot at collision and stop
			add_point(result.position, dot_index)
			dot_index += 1
			
			# Calculate reflection vector for bounce visualization
			var normal = result.normal
			normal.y = 0  # Keep reflection in the horizontal plane
			normal = normal.normalized()
			
			var reflection = shot_direction.reflect(normal)
			reflection.y = 0  # Ensure it stays parallel to table
			reflection = reflection.normalized()
			
			# Add a few dots along the reflection path
			var reflection_start = result.position
			reflection_start.y = table_height  # Keep at table height
			var reflection_distance = segment_length
			var max_reflection_dots = min(20, max_dots - dot_index)  # Ensure we don't exceed array bounds
			var reflection_dots = 0
			
			while dot_index < max_dots and reflection_dots < max_reflection_dots:
				var reflection_point = Vector3(
					reflection_start.x + reflection.x * reflection_distance,
					table_height,
					reflection_start.z + reflection.z * reflection_distance
				)
				
				add_point(reflection_point, dot_index, 0.7)  # Lower alpha for reflection dots
				dot_index += 1
				reflection_dots += 1
				reflection_distance += segment_length
				
			break
		
		# Add dot to trajectory
		add_point(next_point, dot_index)
		dot_index += 1
		current_distance += segment_length
		
	# Make sure we don't show more dots than we've used
	for i in range(dot_index, max_dots):
		if i < dots.size():  # Safety check to prevent index error
			dots[i].visible = false

func add_point(position: Vector3, index: int, alpha_multiplier: float = 1.0):
	# Always keep dots at table height
	position.y = table_height
	
	# Position the dot at the specified position
	if index < dots.size():
		dots[index].global_position = position
		dots[index].visible = true
		
		# Make dots fade with distance
		var alpha = (1.0 - (float(index) / float(max_dots))) * alpha_multiplier
		var material = dots[index].mesh.material.duplicate() as StandardMaterial3D
		if material:
			var color = material.albedo_color
			color.a = alpha * 0.8
			material.albedo_color = color
			dots[index].mesh.material = material

func clear_line():
	# Hide all dots
	for dot in dots:
		dot.visible = false 