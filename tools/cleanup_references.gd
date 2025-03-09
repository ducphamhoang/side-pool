@tool
extends EditorScript

func _run():
	print("Running reference cleanup check...")
	
	# Define the old and new paths
	var old_path = "res://scenes/objects/ball.tscn"
	var new_path = "res://scenes/ball.tscn"
	
	# Start scan
	var dir = DirAccess.open("res://")
	scan_dir(dir, "", old_path, new_path)
	
	print("Cleanup check complete. Please manually update any references found.")
	print("After confirming all references are updated, you can safely delete:")
	print("- " + old_path)

func scan_dir(dir: DirAccess, current_path: String, old_path: String, new_path: String):
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name == "." or file_name == "..":
			file_name = dir.get_next()
			continue
			
		var full_path = current_path + "/" + file_name
		
		if dir.current_is_dir():
			var subdir = DirAccess.open("res://" + full_path)
			if subdir:
				scan_dir(subdir, full_path, old_path, new_path)
		else:
			# Check scene and script files
			if file_name.ends_with(".tscn") or file_name.ends_with(".gd"):
				check_file("res://" + full_path, old_path, new_path)
		
		file_name = dir.get_next()

func check_file(file_path: String, old_path: String, new_path: String):
	if file_path == old_path or file_path == new_path:
		return
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		if content.find(old_path) != -1:
			print("Found reference to " + old_path + " in " + file_path)
			print("  Replace with: " + new_path)
