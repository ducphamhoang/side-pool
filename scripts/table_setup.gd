class_name TableSetup
extends Node

# Ball diameter and spacing constants
const BALL_RADIUS = 0.05      # Ball radius from ball.tscn
const BALL_DIAMETER = BALL_RADIUS * 2
const BALL_SPACING = BALL_DIAMETER * 1.05  # Slight spacing between balls

# Object positioning variables (no longer constants)
var cue_ball_position = Vector3(-0.9, 0.06, 0)  # Left side of the table (head spot)
var rack_position = Vector3(0.7, 0.06, 0)       # Right side of the table (foot spot)

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
	
# Setup the rack for 9-ball
func setup_rack_9ball():
	balls.clear()
	
	# Calculate positions for a proper diamond rack formation
	# The diamond rack has 5 rows in this pattern: 1-2-3-2-1
	var row_offsets = [
		Vector3(0, 0, 0),                                     # Row 1: 1-ball at the apex (front)
		Vector3(-BALL_SPACING/2, 0, BALL_SPACING*0.866),      # Row 2: Left ball
		Vector3(BALL_SPACING/2, 0, BALL_SPACING*0.866),       # Row 2: Right ball
		Vector3(-BALL_SPACING, 0, BALL_SPACING*0.866*2),      # Row 3: Left ball
		Vector3(0, 0, BALL_SPACING*0.866*2),                  # Row 3: Center ball (9-ball position)
		Vector3(BALL_SPACING, 0, BALL_SPACING*0.866*2),       # Row 3: Right ball
		Vector3(-BALL_SPACING/2, 0, BALL_SPACING*0.866*3),    # Row 4: Left ball
		Vector3(BALL_SPACING/2, 0, BALL_SPACING*0.866*3),     # Row 4: Right ball
		Vector3(0, 0, BALL_SPACING*0.866*4),                  # Row 5: Back ball
	]
	
	# Ball positions in standard 9-ball formation
	# 1-ball at the apex (front), 9-ball in the center (5th position), others can be random
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
		return
		
	var stick = game_manager.cue_stick_scene.instantiate()
	game_manager.add_child(stick)
	cue_stick = stick
	game_manager.cue_stick = stick
	
	# Position cue stick in relation to cue ball
	stick.position = cue_ball_position + Vector3(0, 0, 0.3)
	stick.look_at(cue_ball_position, Vector3.UP)
	
	# Setup the stick with reference to the cue ball
	if stick.has_method("setup"):
		stick.setup(cue_ball)

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