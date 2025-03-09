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
	var cue_stick_tip_pos = cue_stick.get_node("RayCast3D").global_position
	var direction = (cue_ball.global_position - cue_stick_tip_pos).normalized()
	
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
		
		var result = space_state.intersect_ray(query)
		
		if result:
			# Hit something, add final dot at collision and stop
			add_point(result.position, dot_index)
			dot_index += 1
			break
		
		# Add dot to trajectory
		add_point(next_point, dot_index)
		dot_index += 1
		current_distance += segment_length
		
	# Make sure we don't show more dots than we've used
	for i in range(dot_index, max_dots):
		dots[i].visible = false

func add_point(position: Vector3, index: int):
	# Position the dot at the specified position
	if index < dots.size():
		dots[index].global_position = position
		dots[index].visible = true
		
		# Make dots fade with distance
		var alpha = 1.0 - (float(index) / float(max_dots))
		var material = dots[index].mesh.material as StandardMaterial3D
		if material:
			var color = material.albedo_color
			color.a = alpha * 0.8
			material = material.duplicate()
			material.albedo_color = color
			dots[index].mesh.material = material

func clear_line():
	# Hide all dots
	for dot in dots:
		dot.visible = false 