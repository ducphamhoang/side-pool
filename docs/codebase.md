# Side Pool Game - Code Structure Documentation

## Project Overview
This project is a side pool game implemented in Godot 4. The architecture follows a component-based approach where reusable objects (ball, cue stick, table, etc.) are separated from scenes to maintain consistency. When loading a scene, the scene calls the appropriate game rules to determine how to add objects and apply game logic.

## Directory Structure

### Root Directory
- `project.godot` - Main Godot project configuration file
- `game.tscn` - Main game scene that serves as the entry point
- `.gitignore`, `.gitattributes` - Git configuration files
- `.editorconfig` - Editor configuration for consistent coding style
- `export_presets.cfg` - Export configuration for different platforms
- `icon.svg` - Project icon resource

### `/scripts`
Contains all the game logic and behavior scripts:

- `game_manager.gd` - Central coordinator that manages game state, setup, and connections between components
- `game.gd` - Manages the main game scene and interfaces with the game manager
- `ball.gd` - Controls ball physics, collisions, and behavior
- `pocket.gd` - Handles pocket collisions and ball pocketing logic
- `cue_stick.gd` - Manages the cue stick behavior, aiming, and shooting mechanics
- `cue_stick_adapter.gd` - Interface between the cue stick and other game components
- `pool_table.gd` - Manages the pool table behavior and properties
- `table_setup.gd` - Handles the setup of the pool table and initial ball positions
- `trajectory_visualization.gd` - Renders the prediction line for ball trajectory
- `setup_cue_stick.gd` - Initializes and configures the cue stick
- `test_aiming.gd`, `test_cue_stick.gd`, `test_cue_stick_drag.gd` - Test scripts for specific mechanics
- `fix_missing_stick.gd` - Utility script to handle missing cue stick references

### `/scripts/game_rules`
Contains rule sets for different pool game variants:

- `game_rules_base.gd` - Abstract base class defining the interface for all game rules
- `game_rules.gd` - Core game rules implementation 
- `eight_ball_rules.gd` - Implementation of 8-ball pool rules
- `nine_ball_rules.gd` - Implementation of 9-ball pool rules

### `/scenes`
Contains scene definitions:

- `game.tscn` - Main game scene that serves as a container for game components
- `nine_ball_game.tscn` - Specific scene for nine-ball pool variant
- `test_aiming.tscn`, `test_cue_stick.tscn`, `test_cue_stick_drag.tscn` - Test scenes for game mechanics

### `/scenes/objects`
Contains reusable object scenes:

- `ball.tscn` - Ball object with physics properties and visuals
- `pool_table.tscn` - Table object with collision surfaces and pockets
- `pocket.tscn` - Individual pocket object for detecting when balls are pocketed
- `cue_stick.tscn` - Player-controlled cue stick for aiming and hitting the cue ball
- `game_camera.tscn` - Camera setup for the game view
- `trajectory_line.tscn` - Visual aid showing the predicted path of the ball

### `/docs`
Contains project documentation:

- `codebase.md` - This file, documenting the code structure
- `rules.md` - Guidelines and best practices for Godot 4 game development

### `/tools`
Contains utility scripts and tools for development:

- `find_duplicates.gd` - Tool to identify and report duplicate resources
- `cleanup_references.gd` - Tool to clean up invalid object references
- `update_ball_references.gd` - Tool to update ball references throughout the codebase

### `/build`
Contains build artifacts and export files for different platforms.

### `/.godot`
Contains Godot engine-specific data and cached resources.

### `/.vscode`
Contains Visual Studio Code configuration for the project.

## Key Components and Relationships

### Game Manager (`scripts/game_manager.gd`)
The central coordinator of the game that:
- Sets up the table, balls, and cue stick
- Instantiates the appropriate rule set based on game type
- Manages player turns and game state
- Processes ball collisions and pocket events

### Game Rules (`scripts/game_rules/*`)
Game rules define the specific mechanics for each pool variant:
- `game_rules_base.gd` provides the common interface and basic functionality
- Variant-specific implementations like `eight_ball_rules.gd` and `nine_ball_rules.gd` define:
  - Initial ball placement
  - Scoring rules
  - Win/loss conditions
  - Turn management
  - Foul detection

### Objects
Reusable objects with consistent properties:
- **Ball (`scenes/objects/ball.tscn`, `scripts/ball.gd`)**: Physics-based with collision detection and material properties
- **Cue Stick (`scenes/objects/cue_stick.tscn`, `scripts/cue_stick.gd`)**: Player-controlled for aiming and shooting
- **Pool Table (`scenes/objects/pool_table.tscn`, `scripts/pool_table.gd`)**: Contains the play surface and boundaries
- **Pockets (`scenes/objects/pocket.tscn`, `scripts/pocket.gd`)**: Detect when balls enter and trigger appropriate events
- **Trajectory Visualization (`scenes/objects/trajectory_line.tscn`, `scripts/trajectory_visualization.gd`)**: Provides visual feedback for aiming

## Flow of Execution
1. The game scene loads and initializes the Game Manager
2. Game Manager sets up the physical objects (table, balls, cue stick)
3. Game Manager instantiates the appropriate rule set based on game type
4. Rules set up the initial game state (ball positions, player turn, etc.)
5. During gameplay:
   - Player uses the cue stick to aim and shoot
   - Trajectory visualization shows the predicted path
   - Physics engine handles ball movements and collisions
   - Pocket detection triggers when balls enter pockets
   - Game rules process the outcome of shots and update game state
6. The game progresses until the rule set determines a winner

## Testing Components
The project includes several test scenes to verify specific components:
- `test_aiming.tscn` - Tests the aiming mechanism
- `test_cue_stick.tscn` - Tests basic cue stick functionality
- `test_cue_stick_drag.tscn` - Tests drag-based interactions with the cue stick

These test scenes help ensure that individual components work correctly before integrating them into the full game.
