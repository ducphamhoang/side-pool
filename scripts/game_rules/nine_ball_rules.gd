class_name NineBallRules
extends GameRulesBase

# Game specific constants
const BALL_COUNT = 9

# Called when the rules are applied to the game
func setup_game(manager):
	# Store the game manager
	super.setup_game(manager)
	
	# Set up the game info display
	game_manager.update_game_info("9-Ball Pool Game\nPlayer 1's Turn")

# Handle ball pocketing according to nine-ball rules
func on_ball_pocketed(ball):
	if not game_manager:
		return
		
	if ball.ball_number == 0:  # Cue ball
		# Handle scratch (cue ball in pocket)
		game_manager.place_ball_in_hand()
		switch_turn()
		game_manager.update_game_info("Scratch! Player " + str(current_player_id) + "'s Turn")
		return
	
	if ball.ball_number == 9:
		# Winning condition: 9-ball is pocketed
		emit_signal("game_over", current_player_id)
		game_manager.update_game_info("Game Over! Player " + str(current_player_id) + " Wins!")
	else:
		# In 9-ball, you continue shooting after pocketing a ball
		game_manager.update_game_info("Ball " + str(ball.ball_number) + " pocketed! Player " + str(current_player_id) + " continues")

# Process the outcome of a shot based on the last ball hit
func process_shot_outcome(last_ball_hit: int) -> Dictionary:
	var outcome = {"outcome": "continue", "next_player": current_player_id}
	
	# In 9-ball, you must hit the lowest-numbered ball first
	var lowest_ball = _get_lowest_ball_number()
	
	if last_ball_hit != lowest_ball and last_ball_hit != -1:
		# Foul: did not hit the lowest-numbered ball first
		switch_turn()
		game_manager.update_game_info("Foul! Must hit ball " + str(lowest_ball) + " first. Player " + str(current_player_id) + "'s Turn")
		outcome.outcome = "foul"
		outcome.next_player = current_player_id
	else:
		# No foul, but no ball pocketed - switch players
		switch_turn()
		game_manager.update_game_info("Player " + str(current_player_id) + "'s Turn")
		outcome.next_player = current_player_id
	
	return outcome

# Helper function to get the lowest-numbered ball remaining on the table
func _get_lowest_ball_number() -> int:
	var lowest = 10  # Higher than any numbered ball
	
	for ball in game_manager.balls:
		if ball.ball_number > 0 and ball.ball_number < lowest:
			lowest = ball.ball_number
	
	return lowest if lowest < 10 else 0  # Return 0 if no numbered balls left

# Called when balls collide
func on_ball_collision(ball_a, ball_b):
	# Record which ball was hit by the cue ball
	if ball_a.ball_number == 0:
		game_manager.last_ball_hit = ball_b.ball_number
	elif ball_b.ball_number == 0:
		game_manager.last_ball_hit = ball_a.ball_number
