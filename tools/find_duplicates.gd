@tool
extends EditorScript

func _run():
	print("Scanning project for potential duplicate files...")
	
	var dir = DirAccess.open("res://")
	var file_list = []
	
	# Recursively scan directories
	scan_dir(dir, "", file_list)
	
	# Check for basename duplicates (potentially different directories)
	var basenames = {}
	for file_path in file_list:
		var filename = file_path.get_file()
		if not basenames.has(filename):
			basenames[filename] = []
		basenames[filename].append(file_path)
	
	# Print potential duplicates
	var found_duplicates = false
	for filename in basenames:
		if basenames[filename].size() > 1:
			found_duplicates = true
			print("Potential duplicate: " + filename)
			for path in basenames[filename]:
				print("  - " + path)
	
	if not found_duplicates:
		print("No duplicate files found by name.")
	
	print("\nNote: Files with the same name in different directories might be intentional.")
	print("Check the content of suspected duplicates to confirm.")

func scan_dir(dir: DirAccess, current_path: String, file_list: Array):
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
				scan_dir(subdir, full_path, file_list)
		else:
			# Skip import files and other temporary files
			if not file_name.ends_with(".import") and not file_name.begins_with("."):
				file_list.append(full_path)
		
		file_name = dir.get_next()
