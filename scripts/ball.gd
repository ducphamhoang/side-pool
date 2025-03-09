class_name Ball
extends RigidBody3D

signal ball_hit(other_ball)
signal ball_pocketed

@export var ball_number: int = 0
var is_cue_ball: bool = false
var ball_color: Color = Color.WHITE
var is_pocketed: bool = false

# Dictionary mapping ball numbers to colors
const BALL_COLORS = {
	0: Color(1, 1, 1, 1),       # White (cue ball)
	1: Color(1, 1, 0, 1),       # Yellow
	2: Color(0, 0, 1, 1),       # Blue
	3: Color(1, 0, 0, 1),       # Red
	4: Color(0.5, 0, 0.5, 1),   # Purple
	5: Color(1, 0.5, 0, 1),     # Orange
	6: Color(0, 0.5, 0, 1),     # Green
	7: Color(0.7, 0, 0, 1),     # Burgundy
	8: Color(0, 0, 0, 1),       # Black
	9: Color(0.7, 0.7, 0.7, 1)  # Gray/silver
}

# Physics properties
@export var default_linear_damp = 0.5
@export var default_angular_damp = 0.5

# References to materials
var material = StandardMaterial3D.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set color based on ball number
	if ball_number == 0:
		# Cue ball
		ball_color = Color.WHITE
		is_cue_ball = true
	else:
		# Colored balls
		match ball_number:
			1: ball_color = Color(1, 1, 0)    # Yellow (1-ball)
			2: ball_color = Color(0, 0, 1)    # Blue (2-ball)
			3: ball_color = Color(1, 0, 0)    # Red (3-ball)
			4: ball_color = Color(0.5, 0, 0.5) # Purple (4-ball)
			5: ball_color = Color(1, 0.5, 0)  # Orange (5-ball)
			6: ball_color = Color(0, 0.5, 0)  # Green (6-ball)
			7: ball_color = Color(0.5, 0, 0)  # Burgundy (7-ball)
			8: ball_color = Color(0, 0, 0)    # Black (8-ball)
			9: ball_color = Color(1, 1, 1)    # White with yellow stripe (9-ball)
			_: ball_color = Color(1, 1, 1)    # Default white
	
	apply_ball_material()
	
	# Physics callbacks
	contact_monitor = true
	max_contacts_reported = 5
	
	# Connect physics signals
	body_entered.connect(_on_body_entered)

func apply_ball_material():
	# Find the mesh instance using safer methods
	var mesh_instance = find_child("MeshInstance3D")
	if not mesh_instance:
		push_error("Ball is missing MeshInstance3D child node: " + str(get_path()))
		return
		
	# Create and apply material
	var material = StandardMaterial3D.new()
	material.albedo_color = ball_color
	
	# Set metallicity and roughness
	material.metallic = 0.1
	material.roughness = 0.2
	
	# Apply to mesh
	if mesh_instance.mesh:
		mesh_instance.mesh.surface_set_material(0, material)
	else:
		push_error("Ball MeshInstance3D has no mesh")

func _on_body_entered(body):
	if body is RigidBody3D:
		# Check if it's another ball
		if body.get_script() == get_script():
			emit_signal("ball_hit", body)
			
			# Find the game manager
			var game_manager = find_game_manager()
			if game_manager and game_manager.has_method("ball_hit"):
				game_manager.ball_hit(self, body)
	
	# Check for pockets
	if body.is_in_group("pocket") and not is_pocketed:
		is_pocketed = true
		emit_signal("ball_pocketed")
		
		var game_manager = find_game_manager()
		if game_manager and game_manager.has_method("on_ball_pocketed"):
			game_manager.on_ball_pocketed(self)
			queue_free()

func find_game_manager():
	# First try to find GameManager in the current scene
	var scene_root = get_tree().get_root().get_child(get_tree().get_root().get_child_count() - 1)
	var game_manager = scene_root.get_node_or_null("GameManager")
	if game_manager:
		return game_manager
		
	# If not found, try direct parent
	if get_parent() and get_parent().get_class() == "GameManager":
		return get_parent()
		
	# If still not found, search for any GameManager node
	return get_tree().get_first_node_in_group("game_manager")

func set_color(color: Color):
	ball_color = color
	apply_ball_material()

func set_as_cue_ball():
	is_cue_ball = true
	ball_color = Color.WHITE
	apply_ball_material()

# Reset the ball's state
func reset():
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

func _physics_process(_delta):
	# If ball falls below the table
	if position.y < -1:
		var game_manager = find_game_manager()
		if game_manager and game_manager.has_method("on_ball_pocketed"):
			game_manager.on_ball_pocketed(self)
			queue_free()
