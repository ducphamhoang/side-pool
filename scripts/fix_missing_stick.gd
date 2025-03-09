extends Node

# This is a utility script to recreate a missing cue stick at runtime

func fix_missing_stick(game_manager):
	print("Attempting to fix missing cue stick")
	
	# If cue stick already exists, do nothing
	if game_manager.cue_stick != null and is_instance_valid(game_manager.cue_stick):
		print("Cue stick already exists, no fix needed")
		return
	
	# Get cue ball reference
	var cue_ball = game_manager.cue_ball
	if not cue_ball or not is_instance_valid(cue_ball):
		print("Cannot create cue stick: cue ball is missing")
		return
	
	print("Creating new cue stick for cue ball at position: ", cue_ball.global_position)
	
	# Try to load the cue stick scene
	var cue_stick_scene = null
	if game_manager.cue_stick_scene:
		cue_stick_scene = game_manager.cue_stick_scene
	else:
		# Try to load it directly
		cue_stick_scene = load("res://scenes/objects/cue_stick.tscn")
	
	var new_stick = null
	
	if cue_stick_scene:
		print("Loaded cue stick scene, instantiating")
		new_stick = cue_stick_scene.instantiate()
	else:
		print("Creating default cue stick")
		new_stick = Node3D.new()
		new_stick.name = "DefaultCueStick"
		
		# Add the script
		var script = load("res://scripts/cue_stick.gd")
		if script:
			new_stick.set_script(script)
		else:
			push_error("Could not load cue_stick.gd script")
			return
	
	# Add the stick to the scene
	new_stick.visible = true
	game_manager.add_child(new_stick)
	game_manager.cue_stick = new_stick
	
	# Setup the stick with cue ball reference
	if new_stick.has_method("setup"):
		new_stick.setup(cue_ball)
	
	print("New cue stick created and set up")

# Call this function to create a cue stick in the current scene
func create_cue_stick_in_current_scene():
	# Try to find the game manager
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		fix_missing_stick(game_manager)
	else:
		print("Could not find game manager, cannot create cue stick") 