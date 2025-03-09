extends Node3D

# Test script for the cue stick

var cue_ball: RigidBody3D
var cue_stick: Node3D

func _ready():
	# Create a cue ball
	create_cue_ball()
	
	# Create a cue stick
	create_cue_stick()
	
	# Print debug information
	print("Test scene ready")
	print("Cue ball created at: ", cue_ball.global_position)
	print("Cue stick created: ", cue_stick != null)
	if cue_stick:
		print("Cue stick position: ", cue_stick.global_position)

func create_cue_ball():
	# Load the ball scene if available
	var ball_scene = load("res://scenes/objects/ball.tscn")
	
	if ball_scene:
		cue_ball = ball_scene.instantiate()
	else:
		# Create a basic ball
		cue_ball = RigidBody3D.new()
		cue_ball.name = "CueBall"
		
		# Add collision shape
		var collision_shape = CollisionShape3D.new()
		var sphere_shape = SphereShape3D.new()
		sphere_shape.radius = 0.05
		collision_shape.shape = sphere_shape
		cue_ball.add_child(collision_shape)
		
		# Add mesh
		var mesh_instance = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.05
		sphere_mesh.height = 0.1
		mesh_instance.mesh = sphere_mesh
		
		# Create material
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.WHITE
		mesh_instance.material_override = material
		
		cue_ball.add_child(mesh_instance)
	
	# Position the ball
	cue_ball.position = Vector3(0, 0.05, 0)
	
	# Set basic properties
	cue_ball.mass = 0.16
	cue_ball.linear_damp = 1.0
	cue_ball.angular_damp = 1.0
	
	# Add to scene
	add_child(cue_ball)

func create_cue_stick():
	# Try to load cue stick scene
	var cue_stick_scene = load("res://scenes/objects/cue_stick.tscn")
	
	if cue_stick_scene:
		cue_stick = cue_stick_scene.instantiate()
		print("Using loaded cue stick scene")
	else:
		# Create a basic cue stick
		cue_stick = Node3D.new()
		cue_stick.name = "CueStick"
		
		# Add cue stick script
		var script = load("res://scripts/cue_stick.gd")
		if script:
			cue_stick.set_script(script)
		
		print("Created basic cue stick")
	
	# Position the stick
	cue_stick.position = Vector3(0, 0.5, -1)
	cue_stick.visible = true
	
	# Add to scene
	add_child(cue_stick)
	
	# Setup the stick with reference to the cue ball
	if cue_stick.has_method("setup"):
		cue_stick.setup(cue_ball)
	
func _input(event):
	# Press R to reset
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		reset_scene()

func reset_scene():
	# Remove existing objects
	if cue_ball:
		cue_ball.queue_free()
	if cue_stick:
		cue_stick.queue_free()
	
	# Recreate objects
	create_cue_ball()
	create_cue_stick() 