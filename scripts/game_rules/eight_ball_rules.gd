class_name EightBallRules
extends GameRulesBase

enum BallGroup { NONE, SOLIDS, STRIPES }
var player_groups = {1: BallGroup.NONE, 2: BallGroup.NONE}
var valid_hit_this_turn: bool = false

func _init():
    super._init()

func start_game() -> void:
    super.start_game()
    reset_player_groups()
    valid_hit_this_turn = false

func reset_player_groups() -> void:
    player_groups[1] = BallGroup.NONE
    player_groups[2] = BallGroup.NONE

func handle_ball_hit(cue_ball: Ball, target_ball: Ball) -> void:
    # In the open table state
    if player_groups[current_player_id] == BallGroup.NONE:
        valid_hit_this_turn = true
        return
    
    # If groups are assigned, player must hit their own group first
    if (player_groups[current_player_id] == BallGroup.SOLIDS and target_ball.ball_number < 8) or \
       (player_groups[current_player_id] == BallGroup.STRIPES and target_ball.ball_number > 8 and target_ball.ball_number < 16):
        valid_hit_this_turn = true
    elif target_ball.ball_number == 8 and is_player_on_eight(current_player_id):
        # Can hit the 8 ball if all their balls are pocketed
        valid_hit_this_turn = true
    else:
        valid_hit_this_turn = false

func handle_ball_pocketed(ball: Ball) -> void:
    if ball.ball_number == 0:  # Cue ball - scratch
        handle_turn_end("scratch")
        return
    
    if not valid_hit_this_turn:
        handle_turn_end("foul")
        return
        
    if ball.ball_number == 8:
        handle_8_ball_pocketed()
        return
    
    # If groups are not assigned yet
    if player_groups[current_player_id] == BallGroup.NONE:
        if ball.ball_number < 8:  # Solids
            player_groups[current_player_id] = BallGroup.SOLIDS
            player_groups[3 - current_player_id] = BallGroup.STRIPES  # Other player gets stripes
        else:  # Stripes
            player_groups[current_player_id] = BallGroup.STRIPES
            player_groups[3 - current_player_id] = BallGroup.SOLIDS  # Other player gets solids
    
    # Continue turn if player pocketed one of their balls
    if (player_groups[current_player_id] == BallGroup.SOLIDS and ball.ball_number < 8) or \
       (player_groups[current_player_id] == BallGroup.STRIPES and ball.ball_number > 8):
        # Continue turn
        pass
    else:
        # Wrong ball pocketed
        handle_turn_end("wrong_ball")

func handle_8_ball_pocketed() -> void:
    if is_player_on_eight(current_player_id):
        # Win condition
        update_score(current_player_id, 1)
        emit_signal("game_over", current_player_id)
    else:
        # Loss condition - pocketed 8 too early
        update_score(3 - current_player_id, 1)  # Other player wins
        emit_signal("game_over", 3 - current_player_id)

func is_player_on_eight(player_id: int) -> bool:
    # Check if all of the player's balls are pocketed
    var all_pocketed = true
    
    # Need to check all balls on the table
    for child in get_parent().get_node("Balls").get_children():
        if child is Ball and not child.is_pocketed and child.ball_number != 0 and child.ball_number != 8:
            if (player_groups[player_id] == BallGroup.SOLIDS and child.ball_number < 8) or \
               (player_groups[player_id] == BallGroup.STRIPES and child.ball_number > 8):
                all_pocketed = false
                break
    
    return all_pocketed
