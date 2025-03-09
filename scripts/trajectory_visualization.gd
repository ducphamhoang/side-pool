class_name TrajectoryVisualization
extends Node3D

# Node references
@onready var dot_container = $DotContainer
@onready var dot_prototype = $DotContainer/Dot

# Properties
var cue_ball: RigidBody3D
var cue_stick: Node3D
var is_visible_trajectory: bool = false
var max_distance: float = 10.0
var segment_length: float = 0.2
var max_dots: int = 50
var dots = []

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

func update_trajectory(power: float = 1.0):
	if not is_visible_trajectory or not cue_ball or not cue_stick:
		return
		
	# Get direction from cue stick to cue ball
	var direction = -cue_stick.global_transform.basis.z.normalized()
	
	# Clear previous trajectory visualization
	clear_line()
	
	# Start point is the cue ball position
	var start_point = cue_ball.global_position
	
	# Set up physics space state for raycast
	var space_state = get_world_3d().direct_space_state
	var current_distance = segment_length  # Start a bit ahead of the ball
	
	# Calculate adjusted max distance based on power
	var adjusted_max_distance = max_distance * power
	var dot_index = 0
	
	# Continue adding dots until max distance, collision, or max dots reached
	while current_distance < adjusted_max_distance and dot_index < max_dots:
		# Calculate next point
		var next_point = start_point + direction * current_distance
		
		# Check for collision
		var query = PhysicsRayQueryParameters3D.new()
		query.from = start_point + direction * 0.1  # Start slightly away from the ball
		query.to = next_point
		query.exclude = [cue_ball]
		query.collision_mask = 4  # Only check for collisions with table edges
		
		var result = space_state.intersect_ray(query)
		
		if result:
			# Hit something, add final dot at collision and stop
			add_point(result.position, dot_index)
			dot_index += 1
			
			# Calculate reflection vector for bounce visualization
			var normal = result.normal
			var reflection = direction.reflect(normal)
			
			# Add a few dots along the reflection path
			var reflection_start = result.position
			var reflection_distance = segment_length
			var max_reflection_dots = 10
			var reflection_dots = 0
			
			while dot_index < max_dots and reflection_dots < max_reflection_dots:
				var reflection_point = reflection_start + reflection * reflection_distance
				add_point(reflection_point, dot_index, 0.5)  # Lower alpha for reflection dots
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
		dots[i].visible = false

func add_point(position: Vector3, index: int, alpha_multiplier: float = 1.0):
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