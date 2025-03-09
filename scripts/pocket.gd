extends Area3D

signal ball_entered(ball)

func _ready():
    # Add to pocket group
    add_to_group("pocket")
    
    # Connect to the body entered signal
    body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    if body is RigidBody3D and body.has_method("apply_ball_material"):
        # Emit our own signal
        emit_signal("ball_entered", body)
        
        # Find the game manager through the same method as balls
        var game_manager = find_game_manager()
        if game_manager and game_manager.has_method("_on_ball_entered_pocket"):
            game_manager._on_ball_entered_pocket(body)

func find_game_manager():
    # First try to find GameManager in the current scene
    var scene_root = get_tree().get_root().get_child(get_tree().get_root().get_child_count() - 1)
    var game_manager = scene_root.get_node_or_null("GameManager")
    if game_manager:
        return game_manager
        
    # If not found, search for any GameManager node
    return get_tree().get_first_node_in_group("game_manager")
