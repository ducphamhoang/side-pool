class_name GameRulesBase
extends Resource

signal game_over(winner_id)
signal turn_changed(player_id)
signal score_updated(player_id, score)

var current_player_id: int = 1
var player_scores: Dictionary = {}
var game_active: bool = false
var game_manager = null

func _init():
    # Initialize player scores
    player_scores[1] = 0
    player_scores[2] = 0

# Setup method called by the game manager
func setup_game(manager):
    game_manager = manager

# Start the game
func start_game() -> void:
    game_active = true
    current_player_id = 1
    emit_signal("turn_changed", current_player_id)

# End the game
func end_game() -> void:
    game_active = false
    
# Process the outcome of a shot
func process_shot_outcome(last_ball_hit: int) -> Dictionary:
    # Override in child class
    return {"outcome": "continue", "next_player": current_player_id}

# Switch turns
func switch_turn() -> void:
    current_player_id = 2 if current_player_id == 1 else 1
    emit_signal("turn_changed", current_player_id)

# Called when a ball is pocketed
func on_ball_pocketed(ball) -> void:
    # Override in child class
    pass

# Called when balls collide
func on_ball_collision(ball_a, ball_b) -> void:
    # Override in child class
    pass

# Helper method to create a ball with given number and position
func create_ball(ball_number, position):
    var ball_scene = load("res://scenes/objects/ball.tscn")
    var ball = ball_scene.instantiate()
    ball.ball_number = ball_number
    ball.position = position
    return ball
    
# Update the score
func update_score(player_id: int, points: int) -> void:
    player_scores[player_id] += points
    emit_signal("score_updated", player_id, player_scores[player_id])
