extends Node3D

# This is an adapter script that creates a RigidBody3D cue stick
# and manages it while maintaining compatibility with the existing scene structure

var cue_ball: RigidBody3D
var physical_stick: Node3D
var original_script = preload("res://scripts/cue_stick.gd")

# Forward all the important variables from the original script
var power: float = 0.0
var max_power: float = 15.0
var is_aiming: bool = true
var shot_taken: bool = false

# For input handling
var touch_start_position: Vector2
var current_touch_position: Vector2

# Trajectory prediction
var trajectory_line: Node3D

func _ready():
	# Create the physical cue stick using the scene
	var cue_stick_scene = load("res://scenes/objects/cue_stick.tscn")
	if cue_stick_scene:
		physical_stick = cue_stick_scene.instantiate()
		print("Created physical cue stick from scene")
	else:
		# Fallback to manual creation
		physical_stick = Node3D.new()
		physical_stick.set_script(original_script)
		print("Created physical cue stick manually")
	
	# Add as child
	add_child(physical_stick)
	
	# Make sure it's visible
	physical_stick.visible = true
	visible = true
	
	# Find trajectory line if it exists
	trajectory_line = get_node_or_null("/root/NineBallGame/TrajectoryLine")
	if trajectory_line:
		# Pass it to the physical stick
		physical_stick.trajectory_line = trajectory_line
		
	print("Cue stick adapter ready. Physical stick visible: ", physical_stick.visible)
	print("Cue stick adapter position: ", global_position)

func setup(ball):
	cue_ball = ball
	
	# Forward the call to the physical stick
	if physical_stick and physical_stick.has_method("setup"):
		physical_stick.setup(cue_ball)
		print("Setup physical cue stick with ball at position: ", ball.global_position)
	else:
		print("Failed to setup physical cue stick")
		
func reset_for_next_shot():
	# Forward to the physical stick
	if physical_stick and physical_stick.has_method("reset_for_next_shot"):
		physical_stick.reset_for_next_shot()
		print("Reset physical cue stick for next shot")
	else:
		print("Failed to reset physical cue stick")

# Forward input events to the physical stick
func _input(event):
	# First update our local variables
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start_position = event.position
		else:
			# When releasing, forward event, then prepare for potential shot
			if physical_stick and physical_stick.has_method("_input"):
				physical_stick._input(event)
				
				# Check if stick has power and should execute shot
				if physical_stick.power > 0:
					print("Adapter: Executing shot through input event")
	
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			touch_start_position = event.position
		else:
			# When releasing, forward event, then prepare for potential shot
			if physical_stick and physical_stick.has_method("_input"):
				physical_stick._input(event)
				
				# Check if stick has power and should execute shot
				if physical_stick.power > 0:
					print("Adapter: Executing shot through input event")
	
	# Forward all events to physical stick
	if physical_stick and physical_stick.has_method("_input"):
		physical_stick._input(event)

# Forward physics processing to the physical stick
func _physics_process(delta):
	if physical_stick and physical_stick.has_method("_physics_process"):
		physical_stick._physics_process(delta)
	
	# Also update our forwarded properties to match the physical stick
	if physical_stick:
		if "power" in physical_stick:
			power = physical_stick.power
		if "is_aiming" in physical_stick:
			is_aiming = physical_stick.is_aiming
		if "shot_taken" in physical_stick:
			shot_taken = physical_stick.shot_taken

# Forward method calls to get aim angle
func get_aim_angle() -> float:
	if physical_stick and physical_stick.has_method("get_aim_angle"):
		return physical_stick.get_aim_angle()
	return 0.0
	
# Forward execute shot
func execute_shot():
	if physical_stick and physical_stick.has_method("execute_shot"):
		print("Adapter: Forwarding execute_shot call")
		physical_stick.execute_shot()
	else:
		print("Failed to execute shot via adapter") 