class_name GameManager
extends Node3D

# Preload required scripts
const TableSetupScript = preload("res://scripts/table_setup.gd")

@export var game_type: String = "9ball"  # Could be "8ball", "9ball", etc.
@export var table_scene: PackedScene
@export var ball_scene: PackedScene
@export var pocket_scene: PackedScene
@export var cue_stick_scene: PackedScene
@export var rules_script: Script

var rules
var table_setup
var cue_ball
var cue_stick
var balls = []
var current_player = 1
var last_ball_hit = -1
var game_over = false
var trajectory_line
var all_balls_stopped = true

# Game states
enum GameState { AIMING, BALL_IN_MOTION, TURN_CHANGE, GAME_OVER }
var game_state = GameState.AIMING

func _ready():
	# Add to the game_manager group for easier discovery
	add_to_group("game_manager")
	
	# Initialize table setup
	table_setup = TableSetupScript.new()
	table_setup.initialize(self)
	
	# Initialize game objects on the table
	setup_table()
	setup_trajectory()
	
	# Instantiate the rules
	if rules_script:
		rules = rules_script.new()
		rules.setup_game(self)
	else:
		push_error("No game rules assigned!")
	
	# Connect signals from rules to UI
	rules.connect("turn_changed", _on_turn_changed)
	rules.connect("game_over", _on_game_over)
	rules.connect("score_updated", _on_score_updated)
	
	# Start the game
	rules.start_game()

func setup_table():
	# First instantiate the physical table
	if table_scene:
		var table = table_scene.instantiate()
		add_child(table)
	
	# Use the table_setup to handle object positioning
	table_setup.setup_table()

func setup_trajectory():
	# Get the trajectory line directly from the scene tree
	trajectory_line = get_node_or_null("/root/NineBallGame/TrajectoryLine")
	
	# Make sure it exists
	if not trajectory_line:
		push_warning("Trajectory line not found in scene tree.")
		return
		
	# Connect it to the cue ball and cue stick if available
	if cue_stick and cue_ball:
		trajectory_line.cue_ball = cue_ball
		trajectory_line.cue_stick = cue_stick
		
		# Ensure it's initialized properly
		trajectory_line.update_trajectory(0.2)
		
		# For debugging, make it visible briefly then hide
		trajectory_line.set_trajectory_visible(true)
		
		# Create a timer to hide it after a moment (for debugging purposes)
		var timer = get_tree().create_timer(1.0)
		timer.timeout.connect(func(): trajectory_line.set_trajectory_visible(false))

func _process(delta):
	match game_state:
		GameState.AIMING:
			# In aiming state, player can control the cue stick
			# This is handled by the cue_stick script
			pass
			
		GameState.BALL_IN_MOTION:
			# Check if all balls have stopped moving
			if all_balls_have_stopped():
				process_shot_outcome()
				
		GameState.TURN_CHANGE:
			# Handle turn change logic here
			game_state = GameState.AIMING
			
		GameState.GAME_OVER:
			# Handle game over state
			pass

func all_balls_have_stopped():
	# Check if all balls have stopped moving
	for ball in balls:
		if is_instance_valid(ball) and ball.linear_velocity.length() > 0.1:
			return false
			
	# Also check cue ball separately (it might not be in the balls array)
	if is_instance_valid(cue_ball) and cue_ball.linear_velocity.length() > 0.1:
		return false
		
	return true

# New method specifically for the cue stick to call
func are_all_balls_stopped():
	return all_balls_have_stopped()

func process_shot_outcome():
	# Let the rules determine the outcome
	var outcome = rules.process_shot_outcome(last_ball_hit)
	
	if game_over:
		game_state = GameState.GAME_OVER
	else:
		game_state = GameState.TURN_CHANGE
		
	# Reset cue stick for next shot
	cue_stick.reset_for_next_shot()
	
	# If it's player's turn again, set up for next shot
	if game_state == GameState.AIMING:
		# Make sure cue stick is properly connected to the cue ball
		cue_stick.setup(cue_ball)

func _on_ball_entered_pocket(ball):
	# Let the rules handle the ball entering a pocket
	rules.on_ball_pocketed(ball)

func _on_ball_collision(ball_a, ball_b):
	# Let the rules handle ball collisions
	rules.on_ball_collision(ball_a, ball_b)
	
	# Track the last ball hit by the cue ball for rules enforcement
	if ball_a.ball_number == 0:
		last_ball_hit = ball_b.ball_number
	elif ball_b.ball_number == 0:
		last_ball_hit = ball_a.ball_number

func _on_turn_changed(player_id):
	current_player = player_id
	update_game_info("Player " + str(player_id) + "'s Turn")

func _on_game_over(winner_id):
	game_over = true
	update_game_info("Game Over - Player " + str(winner_id) + " Wins!")

func _on_score_updated(player_id, score):
	update_game_info("Player " + str(player_id) + " Score: " + str(score))

func update_game_info(text):
	var game_info = get_node_or_null("/root/NineBallGame/UI/GameInfo")
	if game_info:
		game_info.text = text

func place_ball_in_hand():
	# This will be implemented for fouls when the player gets ball-in-hand
	cue_ball.set_sleeping(true)
	cue_ball.position = Vector3(0, 0.5, 0)  # Default position
	cue_ball.set_sleeping(false)
	
	# TODO: Implement touch-based placing of the ball

# Reset the game to initial state
func reset_game():
	# Reset table setup
	table_setup.reset_table()
	
	# Reset game state
	game_state = GameState.AIMING
	current_player = 1
	last_ball_hit = -1
	game_over = false
	
	# Update trajectory
	setup_trajectory()
	
	# Reset rules and start the game
	if rules:
		rules.start_game()

# Change the layout (for custom arrangements)
func set_custom_layout(cue_pos: Vector3, rack_pos: Vector3):
	table_setup.setup_custom_layout(cue_pos, rack_pos)
