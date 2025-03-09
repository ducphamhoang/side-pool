# MVP Implementation Plan: 9-Ball Pool Game

## Overview
This document outlines the implementation plan for the initial MVP version of our side pool game, focusing on 9-ball rules with touch controls. This plan covers the essential features needed to create a playable experience.

## Core Features

### 1. Game Setup (9-Ball Variant)
- A pool table with 6 pockets
- 9 numbered balls (1-9) plus the cue ball (white)
- Correct initial rack formation for 9-ball (diamond shape with 1-ball at the front, 9-ball in the center)
- Basic UI showing current player and game status

### 2. Touch Control System
- **Aiming Mechanism**: 
  - Touch and drag to rotate the cue stick around the cue ball
  - Cue stick's tip always points toward the cue ball center
  - Visual indicator showing the projected path of the cue ball
  - **Trajectory Prediction**: Dotted line showing the expected path of the white ball based on current aim
  
- **Shot Power**:
  - Slide back to determine shot power (longer slide = more power)
  - Visual power meter indicating shot strength
  - Release to execute the shot
  
- **Camera Control**:
  - Fixed top-down view for initial MVP
  - Consider adding a simple two-finger pinch-to-zoom functionality if time permits

### 3. Physics Implementation
- **Ball Physics**:
  - Realistic ball-to-ball collision using Godot's physics engine
  - Proper mass, friction, and bounce properties for the balls
  - Rolling and spinning mechanics
  
- **Table Physics**:
  - Colliders on all four edges of the table to facilitate ball reflection
  - Proper friction coefficient for the table surface
  - Pocket colliders designed to capture balls at the right angles

### 4. Game Rules Implementation
- Implementation of the 9-ball ruleset:
  - Player must hit the lowest-numbered ball first
  - Pocketing balls in any order is allowed as long as the lowest ball is hit first
  - Game is won by legally pocketing the 9-ball
  - Fouls (hitting wrong ball first, no rail contact, scratching) result in ball-in-hand for opponent
  - Turn-based gameplay switching between players after a miss or foul

## Implementation Steps

### Phase 1: Scene Setup and Basic Objects
1. **Create the main game scene**
   - Configure camera and lighting
   - Set up the environment

2. **Implement the pool table**
   - Create the table with proper dimensions and materials
   - Add colliders to the table edges
   - Implement the six pockets with collision detection

3. **Implement the ball system**
   - Create the ball scene with physics properties
   - Implement the visual appearance for all 10 balls (cue + 9 numbered)
   - Configure physics properties (mass, friction, bounciness)

4. **Implement the cue stick**
   - Create the cue stick model and scene
   - Position it relative to the cue ball

### Phase 2: Touch Control System
1. **Implement basic touch detection**
   - Detect touch input on the screen
   - Track touch movement vectors

2. **Develop cue stick aiming system**
   - Rotate cue stick based on touch drag direction
   - Ensure the cue stick always points at the cue ball
   - Implement angle constraints if needed

3. **Implement trajectory prediction**
   - Create a dotted line that extends from the cue ball in the direction of the shot
   - Update the trajectory line in real-time as the player changes aim
   - Use raycasting to show potential collisions with table edges
   - Consider showing first-order reflections off table edges (if time permits)

4. **Implement power control**
   - Track touch drag distance for power determination
   - Create a visual power meter
   - Map drag distance to shot force

5. **Create shot execution**
   - Apply the calculated force to the cue ball upon release
   - Implement proper follow-through animation

### Phase 3: Game Rules and Logic
1. **Implement the 9-ball rule system**
   - Configure the `nine_ball_rules.gd` script with proper game logic
   - Implement turn management
   - Handle ball-in-hand situations

2. **Detect and process game events**
   - Ball collisions
   - Pocketed balls
   - Fouls (hitting wrong ball first, scratch, etc.)

3. **Game flow management**
   - Starting a new game (rack setup)
   - Turn switching
   - Win conditions

### Phase 4: UI and Feedback
1. **Create minimal game UI**
   - Display current player
   - Show which ball must be hit next
   - Display fouls and game status

2. **Implement visual feedback**
   - Shot trajectory prediction line
     - Create a dotted line renderer
     - Vary dot spacing or color based on distance from cue ball
     - Make the line more prominent during active aiming
   - Highlighting the lowest-numbered ball
   - Visual indicators for fouls

3. **Add basic sound effects**
   - Ball collisions
   - Pocketing balls
   - Cue stick hit

## Technical Implementation Details

### Physics Configuration
- Use Godot's built-in physics engine with the following configurations:
  - Ball RigidBody with:
    - Mass: 0.17 kg (standard billiard ball)
    - Friction: Medium (0.3-0.5 range)
    - Bounce: Medium-high (0.7-0.8 range)
  - Table surface with:
    - Friction: Low-medium (0.2-0.3 range)
  - Pocket colliders shaped to guide balls in at appropriate angles

### Touch Input Processing
```gdscript
# Pseudo-code for touch control handling
func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            # Start aiming
            touch_start_position = event.position
            is_aiming = true
        else:
            # Execute shot
            if is_aiming:
                execute_shot(power_level)
                is_aiming = false
                
    elif event is InputEventScreenDrag and is_aiming:
        # Update aiming direction
        var direction = (event.position - cue_ball_screen_position).normalized()
        update_cue_stick_rotation(direction)
        
        # Update power level based on drag distance
        var drag_distance = touch_start_position.distance_to(event.position)
        power_level = clamp(drag_distance / max_drag_distance, 0.1, 1.0)
        update_power_meter(power_level)
```

### Game Flow Control
```gdscript
# Pseudo-code for game flow in GameManager
func _process(delta):
    match game_state:
        GameState.AIMING:
            # Allow player to aim and shoot
            process_player_input()
            
        GameState.BALL_IN_MOTION:
            # Wait for all balls to stop moving
            if all_balls_stopped():
                process_shot_outcome()
                
        GameState.TURN_CHANGE:
            # Switch active player
            current_player = 3 - current_player  # Toggle between 1 and 2
            game_state = GameState.AIMING
```

### Trajectory Prediction Implementation
```gdscript
# Pseudo-code for trajectory prediction
func update_trajectory_line():
    # Clear previous trajectory points
    trajectory_line.clear_points()
    
    # Calculate direction from cue stick to cue ball
    var direction = (cue_ball.global_position - cue_stick_tip.global_position).normalized()
    
    # Set up physics space state for raycast
    var space_state = get_world_3d().direct_space_state
    var start_point = cue_ball.global_position
    
    # Add starting point
    trajectory_line.add_point(start_point)
    
    # Maximum distance to check
    var max_distance = 20.0
    var current_distance = 0.0
    var segment_length = 0.5  # Distance between dots
    
    # Continue adding points until max distance or collision
    while current_distance < max_distance:
        # Calculate next point
        var next_point = start_point + direction * (current_distance + segment_length)
        
        # Check for collision
        var query = PhysicsRayQueryParameters3D.new()
        query.from = start_point
        query.to = next_point
        query.exclude = [cue_ball]
        
        var result = space_state.intersect_ray(query)
        
        if result:
            # Hit something, add final point at collision and stop
            trajectory_line.add_point(result.position)
            break
        
        # Add point to trajectory
        trajectory_line.add_point(next_point)
        current_distance += segment_length
```

## Testing & Refinement
1. **Physics Testing**
   - Test ball collisions and pocket behavior
   - Adjust physics parameters for realistic play

2. **Control Testing**
   - Test touch controls on different device sizes
   - Refine sensitivity and responsiveness

3. **Game Rules Testing**
   - Verify all 9-ball rules are correctly enforced
   - Test edge cases (fouls, scratches, etc.)

## Future Enhancements (Post-MVP)
- Camera angle options
- Advanced cue control (english, draw, follow)
- Multiplayer functionality
- Additional game variants (8-ball, straight pool)
- Customization options (table felt color, ball sets, cue sticks)
- Tutorial and practice modes

## Timeline
- **Week 1**: Scene setup, table and ball physics
- **Week 2**: Touch control system and cue stick behavior
- **Week 3**: Game rules implementation and testing
- **Week 4**: UI, polish, and final testing 