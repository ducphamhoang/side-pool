class_name TableSetup
extends Node

# Ball diameter and spacing constants
const BALL_RADIUS = 0.05      # Ball radius from ball.tscn
const BALL_DIAMETER = BALL_RADIUS * 2
const BALL_SPACING = BALL_DIAMETER * 1.05  # Slight spacing between balls

# Object positioning variables
var cue_ball_position = Vector3(-0.9, 0.06, 0)  # Left side of the table (head spot)
var rack_position = Vector3(0.6, 0.06, 0)       # Right side of the table (foot spot)

var game_manager: Node
var balls = []
var cue_ball: RigidBody3D
var cue_stick: Node3D

# Initialize the table setup with the game manager
func initialize(manager: Node):
	game_manager = manager

# Setup the table with all required objects
func setup_table():
	# Place the cue ball
	setup_cue_ball()
	
	# Place the object balls in rack formation
	setup_rack_9ball()
	
	# Setup cue stick
	setup_cue_stick()
	
	# Setup pockets if needed
	setup_pockets()

# Setup the cue ball
func setup_cue_ball():
	var ball = create_ball(0, cue_ball_position)
	game_manager.add_child(ball)
	cue_ball = ball
	game_manager.cue_ball = ball
	
# Setup the rack for 9-ball in a proper tight triangle formation
func setup_rack_9ball():
	balls.clear()
	
	# Calculate positions for a proper triangle rack formation
	# In 9-ball, we use a triangle with 5 rows: 1-2-3-2-1 (15 total positions, but we only use 9)
	# The spacing factor creates an equilateral triangle
	var row_spacing = BALL_SPACING * 0.866  # sqrt(3)/2 for equilateral triangle height
	
	var row_offsets = [
		# Row 1: 1 ball at the apex
		Vector3(0, 0, 0),  # 1-ball at the front (apex)
		
		# Row 2: 2 balls in second row
		Vector3(-BALL_SPACING/2, 0, row_spacing),  # Left ball
		Vector3(BALL_SPACING/2, 0, row_spacing),   # Right ball
		
		# Row 3: 3 balls in middle row
		Vector3(-BALL_SPACING, 0, row_spacing*2),      # Left ball
		Vector3(0, 0, row_spacing*2),                  # Center ball (9-ball)
		Vector3(BALL_SPACING, 0, row_spacing*2),       # Right ball
		
		# Row 4: 2 balls in fourth row
		Vector3(-BALL_SPACING/2, 0, row_spacing*3),    # Left ball
		Vector3(BALL_SPACING/2, 0, row_spacing*3),     # Right ball
		
		# Row 5: 1 ball at the back
		Vector3(0, 0, row_spacing*4)                   # Back ball
	]
	
	# Ball positions in standard 9-ball formation
	# 1-ball at the apex (front), 9-ball in the center (5th position), others in a specific order
	var ball_numbers = [1, 2, 3, 4, 9, 5, 6, 7, 8]
	
	# Create and position each ball
	for i in range(ball_numbers.size()):
		var ball_number = ball_numbers[i]
		var ball_position = rack_position + row_offsets[i]
		var ball = create_ball(ball_number, ball_position)
		game_manager.add_child(ball)
		balls.append(ball)
	
	# Pass the balls reference to the game manager
	game_manager.balls = balls

# Setup cue stick
func setup_cue_stick():
	if game_manager.cue_stick_scene == null:
		push_error("Cue stick scene not assigned in GameManager")
		# Create a default cue stick scene if one is not assigned
		var default_cue_stick = create_default_cue_stick()
		if default_cue_stick:
			game_manager.add_child(default_cue_stick)
			cue_stick = default_cue_stick
			game_manager.cue_stick = default_cue_stick
			
			# Setup the stick with reference to the cue ball
			if cue_stick.has_method("setup"):
				cue_stick.setup(cue_ball)
		return
		
	var stick = game_manager.cue_stick_scene.instantiate()
	# Ensure the stick is visible
	stick.visible = true
	
	# Add the stick to the scene
	game_manager.add_child(stick)
	cue_stick = stick
	game_manager.cue_stick = stick
	
	# In the new orbital aiming system, we don't need to pre-position the stick
	# The stick's setup function will handle initial positioning properly
	
	# Setup the stick with reference to the cue ball
	if stick.has_method("setup"):
		stick.setup(cue_ball)
	
	print("Cue stick instantiated: ", stick != null)
	print("Cue stick visible: ", stick.visible)
	print("Cue stick position: ", stick.global_position)

# Create a default cue stick if none is assigned
func create_default_cue_stick():
	print("Creating default cue stick")
	var stick = Node3D.new()
	stick.name = "DefaultCueStick"
	
	# Add the adapter script
	var script = load("res://scripts/cue_stick_adapter.gd")
	if script:
		stick.set_script(script)
	else:
		push_error("Could not load cue_stick_adapter.gd script")
		return null
	
	return stick

# Setup pockets around the table
func setup_pockets():
	# Skip if pocket scene is not defined or table is already set up
	if game_manager.pocket_scene == null or game_manager.get_node_or_null("Pockets") != null:
		return
		
	# Pocket positions (assuming table is centered at origin)
	var pocket_positions = [
		Vector3(-1.37, 0.05, -0.685),  # Top left
		Vector3(0, 0.05, -0.685),      # Top center
		Vector3(1.37, 0.05, -0.685),   # Top right
		Vector3(-1.37, 0.05, 0.685),   # Bottom left
		Vector3(0, 0.05, 0.685),       # Bottom center
		Vector3(1.37, 0.05, 0.685)     # Bottom right
	]
	
	# Create pocket container node
	var pockets_container = Node3D.new()
	pockets_container.name = "Pockets"
	game_manager.add_child(pockets_container)
	
	# Create and position each pocket
	for pos in pocket_positions:
		var pocket = game_manager.pocket_scene.instantiate()
		pocket.position = pos
		pockets_container.add_child(pocket)
		pocket.connect("ball_entered", game_manager._on_ball_entered_pocket)

# Helper method to create a ball with given number and position
func create_ball(ball_number, position):
	var ball_scene = preload("res://scenes/objects/ball.tscn")
	var ball = ball_scene.instantiate()
	ball.ball_number = ball_number
	ball.position = position
	
	# Set appropriate ball type based on number
	if ball_number == 0:
		ball.ball_type = 2  # Cue ball
	elif ball_number == 8:
		ball.ball_type = 3  # Black ball (8-ball)
	elif ball_number > 8:
		ball.ball_type = 1  # Striped
	else:
		ball.ball_type = 0  # Solid
	
	return ball

# Reset the table to initial state
func reset_table():
	# Clear all existing balls
	for ball in balls:
		if is_instance_valid(ball):
			ball.queue_free()
	
	balls.clear()
	
	# Remove cue ball and cue stick
	if is_instance_valid(cue_ball):
		cue_ball.queue_free()
	
	if is_instance_valid(cue_stick):
		cue_stick.queue_free()
	
	# Reset game manager references
	game_manager.balls = []
	game_manager.cue_ball = null
	game_manager.cue_stick = null
	
	# Setup the table again
	setup_table()

# Custom layout method for testing different arrangements
func setup_custom_layout(cue_pos: Vector3, rack_pos: Vector3):
	# Store new positions
	cue_ball_position = cue_pos
	rack_position = rack_pos
	
	# Reset and setup with new positions
	reset_table() 