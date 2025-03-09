class_name Ball
extends RigidBody3D

signal ball_hit(other_ball)
signal ball_pocketed

@export var ball_number: int = 0
@export_enum("Solid", "Striped", "Cue", "Black") var ball_type: int = 0
@export var custom_color: Color = Color.WHITE

var is_cue_ball: bool = false
var is_pocketed: bool = false

# Dictionary mapping ball numbers to colors for standard pool balls
const BALL_COLORS = {
	0: Color(1, 1, 1, 1),         # White (cue ball)
	1: Color(1, 1, 0, 1),         # Yellow
	2: Color(0, 0, 1, 1),         # Blue
	3: Color(1, 0, 0, 1),         # Red
	4: Color(0.5, 0, 0.5, 1),     # Purple
	5: Color(1, 0.5, 0, 1),       # Orange
	6: Color(0, 0.5, 0, 1),       # Green
	7: Color(0.7, 0, 0, 1),       # Burgundy
	8: Color(0, 0, 0, 1),         # Black
	9: Color(1, 1, 0, 1),         # Yellow (same as 1 but striped)
	10: Color(0, 0, 1, 1),        # Blue (same as 2 but striped)
	11: Color(1, 0, 0, 1),        # Red (same as 3 but striped)
	12: Color(0.5, 0, 0.5, 1),    # Purple (same as 4 but striped)
	13: Color(1, 0.5, 0, 1),      # Orange (same as 5 but striped)
	14: Color(0, 0.5, 0, 1),      # Green (same as 6 but striped)
	15: Color(0.7, 0, 0, 1)       # Burgundy (same as 7 but striped)
}

# Physics properties
@export var default_linear_damp = 1.0
@export var default_angular_damp = 1.0
@export var max_ball_velocity: float = 10.0  # Maximum velocity for a ball
@export var height_on_table: float = 0.06  # Normal height of ball on table
@export var ball_mass: float = 0.16  # Standard pool ball mass

# Material references
var base_material: StandardMaterial3D

# Called when the node enters the scene tree for the first time.
func _ready():
	# Set cue ball flag
	is_cue_ball = (ball_number == 0)
	
	# Set ball type based on number if not explicitly set
	if ball_type == 0 and ball_number > 8:  # Numbers 9-15 are striped by default
		ball_type = 1  # Striped
	elif ball_number == 8:
		ball_type = 3  # Black ball
	elif ball_number == 0:
		ball_type = 2  # Cue ball
	
	# Apply physics properties
	linear_damp = default_linear_damp
	angular_damp = default_angular_damp
	mass = ball_mass
	
	# Set up physics layer and mask
	collision_layer = 2  # Layer 2 for balls
	collision_mask = 13  # Collide with layer 1 (table), layer 3 (edges), and layer 4 (cue stick)
	
	# Apply the appropriate material based on ball type
	apply_ball_material()
	
	# Physics setup
	contact_monitor = true
	max_contacts_reported = 5
	
	# Connect physics signals
	body_entered.connect(_on_body_entered)

func apply_ball_material():
	# Find the mesh instance
	var mesh_instance = find_child("MeshInstance3D")
	if not mesh_instance:
		push_error("Ball is missing MeshInstance3D child node: " + str(get_path()))
		return
	
	# Get the base color for this ball
	var base_color = get_ball_color()
	
	# Create the main material
	base_material = StandardMaterial3D.new()
	
	match ball_type:
		0: # Solid
			base_material.albedo_color = base_color
		1: # Striped
			# Use a shader material for proper striped appearance
			create_striped_material(base_color, mesh_instance)
			return  # Skip the rest as we've already applied the material
		2: # Cue ball
			base_material.albedo_color = Color.WHITE
		3: # Black (8-ball)
			base_material.albedo_color = Color(0, 0, 0, 1)
	
	# Set metallicity and roughness for all ball types
	base_material.metallic = 0.1
	base_material.roughness = 0.2
	
	# Apply to mesh
	if mesh_instance.mesh:
		mesh_instance.set_surface_override_material(0, base_material)
		
		# Add number to the ball if it's not the cue ball
		if ball_number > 0:
			add_number_to_ball(mesh_instance)
	else:
		push_error("Ball MeshInstance3D has no mesh")

func get_ball_color() -> Color:
	# For striped balls (9-15), use the color of the corresponding solid ball (1-7)
	var actual_number = ball_number
	if ball_number > 8:
		actual_number = ball_number - 8
	
	if actual_number in BALL_COLORS:
		return BALL_COLORS[actual_number]
	return Color.WHITE

func create_striped_material(stripe_color: Color, mesh_instance: MeshInstance3D):
	# Create a shader material for proper striped appearance
	var shader_material = ShaderMaterial.new()
	
	# Define the shader code for striped balls
	var shader_code = """
	shader_type spatial;
	
	uniform vec4 base_color : source_color = vec4(1.0);
	uniform vec4 stripe_color : source_color = vec4(1.0);
	uniform float metallic : hint_range(0.0, 1.0) = 0.1;
	uniform float roughness : hint_range(0.0, 1.0) = 0.2;
	uniform float stripe_width : hint_range(0.0, 1.0) = 0.5;
	
	varying vec3 world_normal;
	
	void vertex() {
		world_normal = NORMAL;
	}
	
	void fragment() {
		// Use world normal Y component to create horizontal stripes
		float y_factor = abs(world_normal.y);
		
		// Create stripe pattern
		vec4 final_color;
		if (y_factor > stripe_width) {
			final_color = base_color;
		} else {
			final_color = stripe_color;
		}
		
		ALBEDO = final_color.rgb;
		METALLIC = metallic;
		ROUGHNESS = roughness;
	}
	"""
	
	shader_material.shader = Shader.new()
	shader_material.shader.code = shader_code
	
	# Set the shader parameters
	shader_material.set_shader_parameter("base_color", Color.WHITE)  # White base
	shader_material.set_shader_parameter("stripe_color", stripe_color)  # Colored stripe
	shader_material.set_shader_parameter("metallic", 0.1)
	shader_material.set_shader_parameter("roughness", 0.2)
	shader_material.set_shader_parameter("stripe_width", 0.5)
	
	# Apply the shader material to the mesh
	mesh_instance.set_surface_override_material(0, shader_material)
	
	# Add number to the ball
	add_number_to_ball(mesh_instance)

func add_number_to_ball(mesh_instance: MeshInstance3D):
	# For a more practical approach, we'll use a CanvasLayer with a Label to render the number
	# then capture it to a ViewportTexture and apply it as a decal
	
	# Create a viewport for rendering the number
	var viewport = SubViewport.new()
	viewport.name = "NumberViewport"
	viewport.size = Vector2(128, 128)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	
	# Create a control node to hold the label
	var control = Control.new()
	control.anchors_preset = Control.PRESET_FULL_RECT
	viewport.add_child(control)
	
	# Create a label for the number
	var label = Label.new()
	label.text = str(ball_number)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchors_preset = Control.PRESET_FULL_RECT
	
	# Make the text bigger and bold
	var font = label.get_theme_font("font")
	label.add_theme_font_size_override("font_size", 64)
	
	# Set text color - white for darker balls, black for lighter balls
	var color = get_ball_color()
	var brightness = (color.r + color.g + color.b) / 3.0
	if brightness > 0.5 or ball_type == 1:  # Light color or striped
		label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	else:
		label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	
	control.add_child(label)
	
	# Wait for the viewport to render
	await get_tree().process_frame
	
	# Create a decal for the number
	var decal = Decal.new()
	decal.name = "NumberDecal"
	decal.texture_albedo = viewport.get_texture()
	decal.size = Vector3(0.12, 0.12, 0.12)  # Size of the decal
	decal.cull_mask = 1  # Make sure this matches the ball's layer
	
	# Add the decal to the ball
	add_child(decal)
	
	# Position the decal
	# For a ball, we might want multiple decals to show the number from different angles
	for i in range(2):
		var angle = i * PI
		var decal_instance = decal.duplicate()
		add_child(decal_instance)
		decal_instance.rotation = Vector3(0, angle, 0)

func _on_body_entered(body):
	if body is RigidBody3D:
		# Check if it's another ball
		if body.has_method("apply_ball_material"):  # Using has_method to check if it's a Ball
			emit_signal("ball_hit", body)
			
			# Find the game manager
			var game_manager = find_game_manager()
			if game_manager and game_manager.has_method("_on_ball_collision"):
				game_manager._on_ball_collision(self, body)
	
	# Check for pockets
	if body.is_in_group("pocket") and not is_pocketed:
		is_pocketed = true
		emit_signal("ball_pocketed")
		
		var game_manager = find_game_manager()
		if game_manager and game_manager.has_method("_on_ball_entered_pocket"):
			game_manager._on_ball_entered_pocket(self)

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

func _physics_process(delta):
	# If ball falls below the table
	if position.y < -0.5:  # Less strict threshold
		var game_manager = find_game_manager()
		if game_manager and game_manager.has_method("_on_ball_entered_pocket"):
			game_manager._on_ball_entered_pocket(self)
			queue_free()
			
	# Keep the ball on the table by clamping y position
	if not is_pocketed:
		# If the ball jumps too high, bring it back down gently
		if position.y > 0.15:  # Allow some small bounces
			# Apply gradual correction rather than immediate snap
			var correction = (position.y - height_on_table) * 0.5
			position.y -= correction * delta * 20
			
			# Dampen vertical velocity more aggressively when ball is above table
			if linear_velocity.y > 0:
				linear_velocity.y *= 0.7
		
		# Clamp velocity to prevent excessive speeds
		if linear_velocity.length() > max_ball_velocity:
			linear_velocity = linear_velocity.normalized() * max_ball_velocity
			
		# Apply additional damping when ball is slowing down
		if linear_velocity.length() < 1.0:
			linear_velocity *= 0.95
			
		# Ensure angular velocity stays reasonable
		var max_angular_speed = 3.0
		if angular_velocity.length() > max_angular_speed:
			angular_velocity = angular_velocity.normalized() * max_angular_speed
			
		# Keep ball flat on the table by damping x/z rotation
		if abs(rotation.x) > 0.01 or abs(rotation.z) > 0.01:
			rotation.x *= 0.9
			rotation.z *= 0.9
