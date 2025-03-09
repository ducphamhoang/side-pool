# Side Pool Game - Code Structure Documentation

## Project Overview
This project is a side pool game implemented in Godot 4. The architecture follows a component-based approach where reusable objects (ball, cue stick, table, etc.) are separated from scenes to maintain consistency. When loading a scene, the scene calls the appropriate game rules to determine how to add objects and apply game logic.

## Directory Structure

### Root Directory
- `project.godot` - Main Godot project configuration file
- `game.tscn` - Main game scene that serves as the entry point

### `/scripts`
Contains all the game logic and behavior scripts:

- `game_manager.gd` - Central coordinator that manages game state, setup, and connections between components
- `game.gd` - Manages the main game scene and interfaces with the game manager
- `ball.gd` - Controls ball physics, collisions, and behavior
- `pocket.gd` - Handles pocket collisions and ball pocketing logic
- `cue_stick.gd` - Manages the cue stick behavior, aiming, and shooting mechanics

### `/scripts/game_rules`
Contains rule sets for different pool game variants:

- `game_rules_base.gd` - Abstract base class defining the interface for all game rules
- `game_rules.gd` - Core game rules implementation 
- `eight_ball_rules.gd` - Implementation of 8-ball pool rules
- `nine_ball_rules.gd` - Implementation of 9-ball pool rules

### `/scenes`
Contains scene definitions:

- `game.tscn` - Main game scene instantiating the overall game environment

### `/scenes/objects`
Contains reusable object scenes:

- `ball.tscn` - Ball object with physics properties and visuals
- `pool_table.tscn` - Table object with collision surfaces and pockets
- `pocket.tscn` - Individual pocket object for detecting when balls are pocketed
- `cue_stick.tscn` - Player-controlled cue stick for aiming and hitting the cue ball

### `/docs`
Contains project documentation:

- `codebase.md` - This file, documenting the code structure

### `/tools`
Contains utility scripts and tools for development

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
- **Ball**: Physics-based with collision detection and material properties
- **Cue Stick**: Player-controlled for aiming and shooting
- **Pool Table**: Contains the play surface and boundaries
- **Pockets**: Detect when balls enter and trigger appropriate events

## Flow of Execution
1. The game scene loads and initializes the Game Manager
2. Game Manager sets up the physical objects (table, balls, cue stick)
3. Game Manager instantiates the appropriate rule set based on game type
4. Rules set up the initial game state (ball positions, player turn, etc.)
5. During gameplay, events are passed between objects and the Game Manager
6. The Game Manager consults the rules to determine the consequences of actions
7. The game progresses until the rule set determines a winner
