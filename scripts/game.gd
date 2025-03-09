extends Node3D

var ball_scene = preload("res://scenes/objects/ball.tscn")

func _ready():
	# Wait a frame before spawning objects
	await get_tree().process_frame
	spawn_balls()
	# Add other initialization here

func spawn_balls():
	# Define the balls to create with their positions and numbers
	var ball_data = [
		{"position": Vector3(0, 0.5, 0), "number": 0},       # Cue ball
		{"position": Vector3(0.2, 0.5, 0.1), "number": 1},   # Ball 1
		{"position": Vector3(-0.2, 0.5, -0.1), "number": 2}  # Ball 2
	]
	
	for data in ball_data:
		var ball = ball_scene.instantiate()
		ball.position = data.position
		ball.ball_number = data.number
		add_child(ball)
		
	print("Spawned ", ball_data.size(), " balls")

func _process(_delta):
	# Add game logic here
	pass
	
func ball_hit(cue_ball, target_ball):
	print("Cue ball hit ball number ", target_ball.ball_number)
	
func on_ball_pocketed(ball):
	print("Ball number ", ball.ball_number, " was pocketed")
