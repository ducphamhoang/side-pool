extends StaticBody3D

# Script for the pool table
# Adjusts the edge height and other properties

@export var edge_height: float = 0.05  # Further reduced from 0.08 to 0.05 for much lower edges

func _ready():
	# Apply the edge height adjustment
	adjust_edge_height()

# Lower the edge heights
func adjust_edge_height():
	var edges = $Edges
	if not edges:
		push_error("Edges node not found in pool table")
		return
	
	# Adjust each edge's y position
	for edge in edges.get_children():
		var current_transform = edge.transform
		current_transform.origin.y = edge_height  # Set the new height
		edge.transform = current_transform
		
		# Also reduce the mesh scale to make edges shorter
		var mesh_instance = edge.get_node_or_null("MeshInstance3D")
		if mesh_instance:
			mesh_instance.scale.y = 0.5  # Further reduced from 0.7 to 0.5 for very short edges
			
			# Also reduce the collision shape to match
			var collision_shape = edge.get_node_or_null("CollisionShape3D")
			if collision_shape:
				collision_shape.scale.y = 0.5  # Match the visual scale 