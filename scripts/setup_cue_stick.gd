@tool
extends EditorScript

# This is a helper script to set up the cue stick structure properly
# Run this from the Godot editor to update the cue stick scene

func _run():
	# Find the cue stick scene
	var cue_stick_scene_path = "res://scenes/objects/cue_stick.tscn"
	var cue_stick_scene = load(cue_stick_scene_path)
	
	if not cue_stick_scene:
		print("Error: Could not load cue stick scene at " + cue_stick_scene_path)
		return
	
	# Instance the scene to modify it
	var cue_stick = cue_stick_scene.instantiate()
	
	# Check if it already has a StickMesh node
	var stick_mesh = cue_stick.find_child("StickMesh")
	if stick_mesh:
		print("StickMesh node already exists")
	else:
		print("Creating StickMesh node")
		
		# Create a new Node3D to hold the mesh
		stick_mesh = Node3D.new()
		stick_mesh.name = "StickMesh"
		
		# Find the existing mesh instance
		var existing_mesh = null
		for child in cue_stick.get_children():
			if child is MeshInstance3D:
				existing_mesh = child
				break
		
		if existing_mesh:
			# Move the existing mesh under the StickMesh node
			var parent = existing_mesh.get_parent()
			parent.remove_child(existing_mesh)
			stick_mesh.add_child(existing_mesh)
			existing_mesh.owner = cue_stick
			
			# Add the StickMesh node to the cue stick
			cue_stick.add_child(stick_mesh)
			stick_mesh.owner = cue_stick
			
			# Rotate the StickMesh to point the tip toward the ball
			stick_mesh.rotation_degrees.y = 180
			
			print("Moved existing mesh under StickMesh node")
		else:
			print("No mesh instance found in cue stick scene")
			
			# Create a default cylinder mesh for visualization
			var mesh_instance = MeshInstance3D.new()
			mesh_instance.name = "DefaultCylinderMesh"
			
			var cylinder_mesh = CylinderMesh.new()
			cylinder_mesh.top_radius = 0.01
			cylinder_mesh.bottom_radius = 0.02
			cylinder_mesh.height = 1.5
			
			mesh_instance.mesh = cylinder_mesh
			
			# Create a material for the cylinder
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.8, 0.6, 0.4)
			cylinder_mesh.material = material
			
			# Add the mesh to the StickMesh node
			stick_mesh.add_child(mesh_instance)
			mesh_instance.owner = cue_stick
			
			# Position the mesh to point forward
			mesh_instance.position.z = -0.75  # Half the height
			mesh_instance.rotation_degrees.x = 90  # Rotate to point forward
			
			# Add the StickMesh node to the cue stick
			cue_stick.add_child(stick_mesh)
			stick_mesh.owner = cue_stick
			
			print("Created default cylinder mesh")
	
	# Add a RayCast3D for aiming if it doesn't exist
	var ray_cast = cue_stick.find_child("RayCast3D")
	if not ray_cast:
		ray_cast = RayCast3D.new()
		ray_cast.name = "RayCast3D"
		ray_cast.target_position = Vector3(0, 0, -2)  # Point forward
		ray_cast.enabled = true
		cue_stick.add_child(ray_cast)
		ray_cast.owner = cue_stick
		print("Added RayCast3D for aiming")
	
	# Save the modified scene
	var packed_scene = PackedScene.new()
	packed_scene.pack(cue_stick)
	var error = ResourceSaver.save(packed_scene, cue_stick_scene_path)
	
	if error == OK:
		print("Successfully saved modified cue stick scene")
	else:
		print("Error saving cue stick scene: " + str(error))
	
	# Clean up
	cue_stick.queue_free() 
