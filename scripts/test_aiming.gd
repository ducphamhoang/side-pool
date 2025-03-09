extends Node3D

# Test script for verifying the cue stick aiming behavior
# This is designed to debug aiming issues with the cue stick

var cue_ball: RigidBody3D
var cue_stick: Node3D
var debug_lines: MeshInstance3D
var debug_material: StandardMaterial3D
var camera: Camera3D
var ui_layer: CanvasLayer
var drag_info_label: Label
var angle_info_label: Label

# Test parameters
var enable_mouse_aim_visualization: bool = true
var draw_aim_lines: bool = true
var show_debug_info: bool = true

func _ready():
	# Create the test environment
	setup_camera()
	setup_ui()
	setup_debug_visuals()
	
	# Create test objects
	create_cue_ball()
	create_cue_stick()
	
	# Connect signals if needed
	if cue_stick:
		print("Cue stick is ready for aim testing")
	
	print("Aim testing scene initialized")
	print("Instructions:")
	print("- Click and drag to aim the cue stick")
	print("- Press R to reset the test")
	print("- Press Space to execute a shot")

func setup_camera():
	# Create a camera optimized for testing
	camera = Camera3D.new()
	camera.name = "TestCamera"
	camera.transform = Transform3D().translated(Vector3(0, 2, 4))
	camera.rotation_degrees = Vector3(-30, 0, 0)
	add_child(camera)

func setup_ui():
	# Create UI for debug information
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	if show_debug_info:
		# Drag info label
		drag_info_label = Label.new()
		drag_info_label.position = Vector2(20, 20)
		drag_info_label.text = "Drag: Not started"
		ui_layer.add_child(drag_info_label)
		
		# Angle info label
		angle_info_label = Label.new()
		angle_info_label.position = Vector2(20, 60)
		angle_info_label.text = "Angle: 0°"
		ui_layer.add_child(angle_info_label)

func setup_debug_visuals():
	# Create debug visualization for aiming
	if draw_aim_lines:
		var lines_mesh = ImmediateGeometry.new()
		lines_mesh.name = "DebugGeometry"
		
		debug_material = StandardMaterial3D.new()
		debug_material.albedo_color = Color(1, 0, 0)
		debug_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		
		add_child(lines_mesh)
		debug_lines = lines_mesh

func create_cue_ball():
	# Try to load the ball scene
	var ball_scene = load("res://scenes/objects/ball.tscn")
	
	if ball_scene:
		cue_ball = ball_scene.instantiate()
	else:
		# Create a simple test ball
		cue_ball = RigidBody3D.new()
		cue_ball.name = "TestCueBall"
		
		# Add a visible mesh
		var mesh_instance = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.05
		sphere.height = 0.1
		mesh_instance.mesh = sphere
		
		# Add a white material
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.WHITE
		mesh_instance.material_override = material
		
		# Add collision
		var collision = CollisionShape3D.new()
		var sphere_shape = SphereShape3D.new()
		sphere_shape.radius = 0.05
		collision.shape = sphere_shape
		
		cue_ball.add_child(mesh_instance)
		cue_ball.add_child(collision)
	
	# Set ball properties
	cue_ball.position = Vector3(0, 0.05, 0)
	cue_ball.mass = 0.16
	cue_ball.linear_damp = 1.0
	cue_ball.angular_damp = 1.0
	
	add_child(cue_ball)
	print("Created test cue ball at position: ", cue_ball.position)

func create_cue_stick():
	# Try to load the cue stick scene
	var cue_stick_scene = load("res://scenes/objects/cue_stick.tscn")
	
	if cue_stick_scene:
		cue_stick = cue_stick_scene.instantiate()
		print("Using scene-based cue stick")
	else:
		# Create a default cue stick
		cue_stick = Node3D.new()
		cue_stick.name = "TestCueStick"
		
		# Add the cue stick script
		var script = load("res://scripts/cue_stick.gd")
		if script:
			cue_stick.set_script(script)
		
		print("Created script-based cue stick")
	
	# Add to scene and setup
	add_child(cue_stick)
	
	# Setup the cue stick with the ball reference
	if cue_stick.has_method("setup"):
		cue_stick.setup(cue_ball)

func _process(_delta):
	# Update debug information
	if show_debug_info and cue_stick:
		if is_instance_valid(drag_info_label):
			var power = get_property(cue_stick, "power")
			if typeof(power) == TYPE_FLOAT:
				drag_info_label.text = "Power: " + str(snappedf(power * 100, 0.1)) + "%"
		
		if is_instance_valid(angle_info_label) and cue_stick.has_method("get_aim_angle"):
			var angle_deg = rad_to_deg(cue_stick.get_aim_angle())
			angle_info_label.text = "Angle: " + str(snappedf(angle_deg, 0.1)) + "°"

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_R:
				reset_test()
			elif event.keycode == KEY_SPACE:
				execute_test_shot()
	
	# Visualize mouse position for aiming debug if enabled
	if enable_mouse_aim_visualization and event is InputEventMouseMotion:
		update_debug_visualization(event.position)

func reset_test():
	# Reset ball position
	if cue_ball:
		cue_ball.position = Vector3(0, 0.05, 0)
		cue_ball.linear_velocity = Vector3.ZERO
		cue_ball.angular_velocity = Vector3.ZERO
	
	# Reset cue stick
	if cue_stick and cue_stick.has_method("reset_for_next_shot"):
		cue_stick.reset_for_next_shot()
	
	print("Test reset")

func execute_test_shot():
	if cue_stick and cue_stick.has_method("execute_shot"):
		# Force some power if none is set
		var power = get_property(cue_stick, "power") 
		if power == null or power <= 0:
			# Use reflection to set power
			set_property(cue_stick, "power", 0.5)
		
		cue_stick.execute_shot()
		print("Test shot executed with power: ", get_property(cue_stick, "power"))

func update_debug_visualization(mouse_pos):
	if not draw_aim_lines or not cue_ball or not debug_lines:
		return
		
	# Skip drawing since we don't have a working ImmediateGeometry in this version
	return

# Helper function to safely get a property from an object
func get_property(object, property_name):
	if object == null:
		return null
		
	var script = object.get_script()
	if script and script.has_script_signal(property_name):
		return object.get(property_name)
	
	# Try directly accessing the property
	if property_name in object:
		return object.get(property_name)
	
	return null

# Helper function to safely set a property
func set_property(object, property_name, value):
	if object == null:
		return
		
	var script = object.get_script()
	if script and script.has_script_signal(property_name):
		object.set(property_name, value)
		return
	
	# Try directly setting the property
	if property_name in object:
		object.set(property_name, value) 