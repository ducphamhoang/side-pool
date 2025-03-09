extends Node3D

var cue_ball: RigidBody3D
var power: float = 0.0
var max_power: float = 20.0
var is_aiming: bool = true
var shot_taken: bool = false
var touch_start_position: Vector2
var current_touch_position: Vector2
var max_drag_distance: float = 500.0  # Maximum drag distance for full power

# Trajectory prediction
var trajectory_line: Node3D

@onready var ray_cast = $RayCast3D
@onready var power_meter = get_node_or_null("/root/NineBallGame/UI/PowerMeter")

func _ready():
    # We'll get the cue ball from the game manager
    # Find trajectory line if it exists
    trajectory_line = get_node_or_null("/root/NineBallGame/TrajectoryLine")
    
    if power_meter:
        power_meter.max_value = 1.0
        power_meter.value = 0

func setup(ball):
    cue_ball = ball
    
    # Set up trajectory visualization if available
    if trajectory_line:
        trajectory_line.cue_ball = cue_ball
        trajectory_line.cue_stick = self

func _process(_delta):
    if not is_aiming or not cue_ball:
        return
        
    # Position the cue stick near the cue ball
    position_stick()
    
    # Update trajectory visualization
    if trajectory_line and is_aiming and power > 0:
        trajectory_line.update_trajectory(power)

func position_stick():
    # Position the cue stick behind the cue ball
    global_transform.origin = cue_ball.global_transform.origin
    # Offset the stick backwards based on power
    var local_offset = Vector3(0, 0, 1 + power * 0.5)  # Adjust back distance with power
    global_transform.origin = global_transform.origin + global_transform.basis * local_offset

func _input(event):
    # Only process input if we're in aiming mode
    if not is_aiming:
        return
        
    if event is InputEventScreenTouch:
        if event.pressed:
            # Start aiming
            touch_start_position = event.position
            # Show trajectory line
            if trajectory_line:
                trajectory_line.set_trajectory_visible(true)
            # Show power meter
            if power_meter:
                power_meter.visible = true
        else:
            # Execute shot if we were aiming
            if power > 0:
                execute_shot()
            # Hide trajectory line
            if trajectory_line:
                trajectory_line.set_trajectory_visible(false)
            # Hide power meter
            if power_meter:
                power_meter.visible = false
            power = 0
                
    elif event is InputEventScreenDrag:
        # Update current touch position
        current_touch_position = event.position
        
        # Update aiming direction - rotate based on touch position relative to screen center
        var screen_center = get_viewport().get_visible_rect().size / 2
        var aim_direction = (event.position - screen_center).normalized()
        var rotation_y = atan2(aim_direction.x, aim_direction.y)
        
        # Apply rotation to cue stick
        rotation.y = rotation_y
        
        # Calculate power based on drag distance from start
        var drag_distance = touch_start_position.distance_to(event.position)
        power = clamp(drag_distance / max_drag_distance, 0.0, 1.0)
        
        # Update power meter if available
        if power_meter:
            power_meter.value = power

func execute_shot():
    if not cue_ball:
        return
        
    # Calculate shot direction and force
    var direction = -global_transform.basis.z.normalized()
    var force = direction * (power * max_power)
    
    # Apply force to cue ball
    cue_ball.apply_central_impulse(force)
    
    # Track that shot has been taken and we're no longer aiming
    shot_taken = true
    is_aiming = false
    
    # Emit signal that shot has been taken
    # This could be connected to the game manager to handle turn switching
    # emit_signal("shot_taken")

func reset_for_next_shot():
    # Reset cue stick state for next shot
    shot_taken = false
    is_aiming = true
    power = 0
