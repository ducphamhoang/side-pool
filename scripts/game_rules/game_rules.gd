class_name GameRules
extends Resource

# Virtual method to set up the game
func setup_game(game_manager):
	pass

# Virtual method to handle ball pocketing
func on_ball_pocketed(game_manager, ball):
	pass

# Helper method to create a ball with given number and position
func create_ball(ball_number, position):
	var ball_scene = load("res://scenes/objects/ball.tscn")
	var ball = ball_scene.instantiate()
	ball.ball_number = ball_number
	ball.position = position
	return ball
