extends Node3D

# Test script for verifying the cue stick dragging functionality

var cue_ball: RigidBody3D
var cue_stick: Node3D
var ui_layer: CanvasLayer
var debug_label: Label

# Test parameters
var test_drag_directions = [
	Vector2(100, 0),    # Right
	Vector2(-100, 0),   # Left
	Vector2(0, 100),    # Down
	Vector2(0, -100),   # Up
	Vector2(100, 100),  # Down-Right
	Vector2(-100, 100), # Down-Left
	Vector2(100, -100), # Up-Right
	Vector2(-100, -100) # Up-Left
]
var current_test_index = 0
var test_in_progress = false
var original_position: Vector3
var drag_start_position: Vector2
var test_result_passed = 0
var test_result_failed = 0

func _ready():
	setup_ui()
	
	# Create test environment
	create_cue_ball()
	create_cue_stick()
	
	# Setup camera
	var camera = Camera3D.new()
	camera.transform = Transform3D().translated(Vector3(0, 3, 2))
	camera.rotation_degrees = Vector3(-60, 0, 0)
	add_child(camera)
	
	print("Cue stick drag test initialized")
	print("Press T to run automated tests")
	print("Press R to reset stick position")
	print("Manually test dragging with mouse")
	
	update_debug_info("Ready for testing. Press T to start automated tests.")

func setup_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	debug_label = Label.new()
	debug_label.position = Vector2(20, 20)
	debug_label.text = "Cue Stick Drag Test"
	ui_layer.add_child(debug_label)

func create_cue_ball():
	# Load ball scene
	var ball_scene = load("res://scenes/objects/ball.tscn")
	
	if ball_scene:
		cue_ball = ball_scene.instantiate()
	else:
		# Create a default ball if scene not found
		cue_ball = RigidBody3D.new()
		
		var mesh_instance = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.05
		sphere.height = 0.1
		mesh_instance.mesh = sphere
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.WHITE
		mesh_instance.material_override = material
		
		var collision = CollisionShape3D.new()
		var sphere_shape = SphereShape3D.new()
		sphere_shape.radius = 0.05
		collision.shape = sphere_shape
		
		cue_ball.add_child(mesh_instance)
		cue_ball.add_child(collision)
	
	cue_ball.position = Vector3(0, 0.05, 0)
	add_child(cue_ball)
	
	# Create a table surface for reference
	var table = StaticBody3D.new()
	var table_collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(2, 0.1, 2)
	table_collision.shape = box_shape
	
	var table_mesh = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(2, 0.1, 2)
	table_mesh.mesh = box_mesh
	
	var table_material = StandardMaterial3D.new()
	table_material.albedo_color = Color(0.1, 0.5, 0.1)
	table_mesh.material_override = table_material
	
	table.add_child(table_collision)
	table.add_child(table_mesh)
	table.position = Vector3(0, -0.05, 0)
	add_child(table)

func create_cue_stick():
	# Try to load the cue stick scene
	var cue_stick_scene = load("res://scenes/objects/cue_stick.tscn")
	
	if cue_stick_scene:
		cue_stick = cue_stick_scene.instantiate()
	else:
		# Create a basic stick if scene not found
		cue_stick = Node3D.new()
		
		# Attempt to load the script
		var script = load("res://scripts/cue_stick.gd")
		if script:
			cue_stick.set_script(script)
	
	# Add to scene
	add_child(cue_stick)
	
	# Setup with cue ball
	if cue_stick.has_method("setup"):
		cue_stick.setup(cue_ball)
	
	# Store original position for reference
	original_position = cue_stick.global_position

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_T:
				start_automated_tests()
			elif event.keycode == KEY_R:
				reset_cue_stick()
	
	# Forward drag inputs to cue stick for manual testing
	if cue_stick and cue_stick.has_method("_input"):
		cue_stick._input(event)

func _process(delta):
	if test_in_progress:
		perform_test_step(delta)
	
	# Display current stick position for debugging
	if cue_stick:
		var position_text = "Stick Position: " + str(cue_stick.global_position)
		var angle_text = "Angle: " + str(rad_to_deg(cue_stick.get_aim_angle()))
		var test_results = "Tests Passed: " + str(test_result_passed) + ", Failed: " + str(test_result_failed)
		update_debug_info(position_text + "\n" + angle_text + "\n" + test_results)

func start_automated_tests():
	if test_in_progress:
		return
	
	print("Starting automated drag tests")
	current_test_index = 0
	test_in_progress = true
	test_result_passed = 0
	test_result_failed = 0

func perform_test_step(delta):
	if current_test_index >= test_drag_directions.size():
		test_in_progress = false
		print("All tests completed. Passed: ", test_result_passed, " Failed: ", test_result_failed)
		return
	
	# Get the current test direction
	var direction = test_drag_directions[current_test_index]
	
	# Simulate drag input
	if not "is_dragging" in self or not self.is_dragging:
		# Start drag
		self.is_dragging = true
		reset_cue_stick()
		
		# Get center of screen for starting drag
		var viewport_size = get_viewport().size
		drag_start_position = viewport_size / 2
		
		# Create mock events to simulate drag
		var mock_press_event = InputEventMouseButton.new()
		mock_press_event.button_index = MOUSE_BUTTON_LEFT
		mock_press_event.pressed = true
		mock_press_event.position = drag_start_position
		
		if cue_stick.has_method("_input"):
			cue_stick._input(mock_press_event)
		
		# Record initial position
		self.initial_stick_position = cue_stick.global_position
		self.is_dragging = true
		self.drag_time = 0
		
	else:
		# Continue drag
		self.drag_time += delta
		
		# Calculate current drag position
		var current_drag_position = drag_start_position + direction * (self.drag_time / 0.5)
		
		# Create mock motion event
		var mock_motion_event = InputEventMouseMotion.new()
		mock_motion_event.button_mask = MOUSE_BUTTON_LEFT
		mock_motion_event.position = current_drag_position
		
		if cue_stick.has_method("_input"):
			cue_stick._input(mock_motion_event)
		
		# After 0.5 seconds, end the drag test
		if self.drag_time >= 0.5:
			# End drag
			var mock_release_event = InputEventMouseButton.new()
			mock_release_event.button_index = MOUSE_BUTTON_LEFT
			mock_release_event.pressed = false
			mock_release_event.position = current_drag_position
			
			if cue_stick.has_method("_input"):
				cue_stick._input(mock_release_event)
			
			# Verify the stick moved
			var has_moved = self.initial_stick_position.distance_to(cue_stick.global_position) > 0.05
			
			if has_moved:
				print("Test " + str(current_test_index) + " PASSED: Stick moved in direction " + str(direction))
				test_result_passed += 1
			else:
				print("Test " + str(current_test_index) + " FAILED: Stick did not move in direction " + str(direction))
				test_result_failed += 1
				
			# Move to next test
			current_test_index += 1
			self.is_dragging = false
			
			# Wait a moment before next test
			await get_tree().create_timer(0.5).timeout

func reset_cue_stick():
	if cue_stick and cue_stick.has_method("reset_for_next_shot"):
		cue_stick.reset_for_next_shot()
		print("Cue stick position reset")

func update_debug_info(text):
	if debug_label:
		debug_label.text = text 