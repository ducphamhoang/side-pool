# Cue Stick Rules and Mechanics

## Overview

This document specifies the rules and behaviors governing the cue stick in our Side Pool Game. The cue stick is a central interactive element that provides players with a way to aim and shoot the cue ball. Its behavior must follow specific physics-based rules while maintaining an intuitive user experience.

## Stick Components

The cue stick has two distinct ends:
- **Head**: The thinner end of the stick that contacts the cue ball
- **Tail**: The thicker end of the stick that the player holds

## Game Turn States

The game progresses through four distinct states during each player's turn:

1. **Ready State**: The cue stick is positioned behind the cue ball, waiting for player input
2. **Aim State**: The player is dragging to adjust the aim direction
3. **Power State**: The player is setting the power of the shot
4. **Shot State**: The shot is executed and balls are in motion

## Positioning Rules

### Ready State Rules

In the ready state, the following rules apply to the cue stick:

1. **Head-Ball Distance**: The head of the stick must maintain a small, consistent distance from the cue ball
   - Minimum distance: 0.12 units (adjustable via `min_safe_distance`)
   - This ensures that the stick never clips through the ball

2. **Orientation**: The head of the stick must always be positioned between the cue ball and the tail
   - The stick's transform.basis.z vector should point toward the cue ball
   - This ensures realistic stick behavior

3. **Elevation**: The stick should be slightly elevated above the table surface
   - Default elevation: 0.15 units above the cue ball's Y position
   - This improves visibility and prevents clipping with the table

4. **Default Position**: When first entering ready state, the stick should be positioned:
   - Behind the cue ball (in the negative Z direction by default)
   - At a distance of approximately (stick_length * 0.6 + min_safe_distance) from the ball
   - This provides a natural starting position for aiming

### Implementation Details

To ensure these rules are consistently followed:

1. **Safety Distance Check**: A verification function (`verify_safe_distance()`) should run:
   - During initial setup
   - After positioning changes
   - Periodically during aiming
   - This function adjusts the stick position if it violates the minimum distance rule

2. **Orientation Verification**: A debug function (`debug_stick_orientation()`) can be used to verify:
   - Head is closer to the ball than the tail
   - Proper stick direction
   - Correct mesh orientation

3. **Readjustment Logic**: If the stick position violates any rules:
   - Calculate correction vector
   - Apply position adjustment
   - Re-verify constraints

## State Transition Rules

### From Ready to Aim State
- Triggered by: Player initial touch/click
- Actions:
  - Record initial touch position
  - Begin tracking aim direction based on drag movement
  - Keep enforcing distance rules

### From Aim to Power State
- Triggered by: Player releases touch/click after dragging
- Actions:
  - Lock in aim direction
  - Begin power measurement based on subsequent drag
  - Update power meter UI

### From Power to Shot State
- Triggered by: Player releases touch/click after setting power
- Actions:
  - Lock in power value
  - Execute shot based on aim direction and power
  - Disable stick controls until shot sequence completes

### From Shot to Ready State
- Triggered by: All balls stop moving
- Actions:
  - Reset stick position behind the cue ball
  - Reset power to zero
  - Enable stick controls
  - Return to default position for next player

## Code Implementation

To implement these rules:

1. Update the `game_manager.gd` to track these four distinct states:
```gdscript
enum GameState { READY, AIMING, POWER, SHOT }
var game_state = GameState.READY
```

2. Enhance the `cue_stick.gd` script to:
   - Respond to state changes from the game manager
   - Apply appropriate positioning rules based on current state
   - Implement state-specific interaction behaviors

3. Add a state transition method in `game_manager.gd`:
```gdscript
func change_game_state(new_state):
    game_state = new_state
    # Notify relevant objects of state change
```

4. Ensure the stick's position is always corrected when entering the READY state:
```gdscript
func setup_for_ready_state():
    position_stick_behind_ball(current_aim_direction)
    verify_safe_distance("ready")
    update_head_tail_positions()
```

## Conclusion

Following these rules ensures the cue stick behaves in a physically plausible manner while providing players with an intuitive control system. The stick will always maintain a safe distance from the cue ball, ensuring that the head is correctly positioned between the ball and the tail in all game states. 