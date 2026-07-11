# IDS Logistics System

## Overview

The IDS Logistics System is a comprehensive building and logistics framework for Arma 3 missions. It provides a camera-based building system that allows players to place, manipulate, and manage various structures and objects in the game world. The system is designed to be modular, extensible, and easy to integrate into any mission.

## Features

- **Camera-Based Building System**: Intuitive camera controls for precise object placement
- **Configurable Entity Database**: Extensive library of buildable objects organized by category
- **Advanced Placement Controls**: Rotate, raise/lower, and fine-tune object positioning
- **Entity Management**: Pick up, move, or remove previously placed objects
- **Persistence**: Save and load placed objects between mission sessions
- **User-Friendly UI**: Clean and intuitive build menu with search functionality and 3D preview
- **Multiple Vision Modes**: Normal and night vision for building in any conditions
- **Comprehensive Documentation**: Well-documented code with clear function descriptions

## Structure

The IDS Logistics System is organized into the following components:

### Core Files

- `IDS_Logistics_Functions.hpp`: Function definitions and categorization
- `CfgLogistics.hpp`: Main configuration file that includes all entity definitions

### Directories

- `/configs`: Entity definitions organized by category
- `/dialogs`: UI dialog definitions
- `/docs`: Documentation files
- `/functions`: Core functionality scripts
  - `/functions/server`: Server-side functionality
  - `/functions/ui`: User interface functionality

## Installation

1. Copy the `IDS_Logistics` folder to your mission directory
2. Add the following to your `description.ext`:

```cpp
#include "UI\BaseControls.hpp"
#include "IDS_Logistics\IDS_Logistics_Functions.hpp"
#include "IDS_Logistics\CfgLogistics.hpp"
#include "IDS_Logistics\dialogs\BuildMenuDialog.hpp"
```

## Usage

### Initialization

The system initializes automatically through the preInit function. No manual initialization is required.

### Activating Build Mode

To activate the build camera:

```sqf
[player] call IDS_Logistics_fnc_initBuildCamera;
```

### Opening the Build Menu

Once in build mode, open the build menu with <span style="color:#FF9800;font-weight:bold">B</span> key

### Key Controls

When in build mode, the following keys are available:

- <span style="color:#FF9800;font-weight:bold">N</span>: Toggle vision modes (Normal, NVG)
- <span style="color:#FF9800;font-weight:bold">B</span>: Open build menu
- <span style="color:#FF9800;font-weight:bold">WASD</span>: Move camera
- <span style="color:#FF9800;font-weight:bold">Q/Z</span>: Raise/lower camera
- <span style="color:#FF9800;font-weight:bold">C</span>: Toggle 3D cursor
- <span style="color:#FF9800;font-weight:bold">T</span>: Toggle terrain snapping (when placing)
- <span style="color:#FF9800;font-weight:bold">Alt + Scroll</span>: Adjust entity distance (when placing)
- <span style="color:#FF9800;font-weight:bold">Shift + Scroll</span>: Rotate entity (when placing)
- <span style="color:#FF9800;font-weight:bold">Ctrl + Scroll</span>: Raise/lower entity (when placing)
- <span style="color:#FF9800;font-weight:bold">Shift + Left Click</span>: Delete entity
- <span style="color:#FF9800;font-weight:bold">Ctrl + Left Click</span>: Pickup entity
- <span style="color:#FF9800;font-weight:bold">Left Click</span>: Place entity
- <span style="color:#FF9800;font-weight:bold">Right Click</span>: Cancel placement

### Placing Objects

1. Enter build mode
2. Open the build menu
3. Select a category and an entity
4. Position the entity using mouse and keyboard controls
5. <span style="color:#FF9800;font-weight:bold">Left Click</span> to place the entity

### Managing Placed Objects

To pick up a previously placed object:

1. Enter build mode
2. Toggle 3D cursor with <span style="color:#FF9800;font-weight:bold">C</span> key
3. Position 3D cursor on the entity
3. <span style="color:#FF9800;font-weight:bold">Ctrl + Left Click</span> to pickup the entity

To delete a previously placed object:

1. Enter build mode
2. Toggle 3D cursor with <span style="color:#FF9800;font-weight:bold">C</span> key
3. Position 3D cursor on the entity
3. <span style="color:#FF9800;font-weight:bold">Shift + Left Click</span> to delete the entity

## Configuration

### Adding New Entities

To add new buildable entities, edit the appropriate category file in the `/configs` directory or create a new one and include it in `CfgLogistics.hpp`.

Example entity definition:

```cpp
class Land_HBarrier_5_F {
    category = "Fortification";
    cost = 10;
}
```

### Entity Categories

The system comes with the following predefined categories:

- **Equipment**: Lights, tools, and utility items
- **Fortifications**: Defensive structures like barriers and bunkers
- **Furniture**: Chairs, tables, and other interior items
- **Logistics**: Supply containers and resource storage
- **Structures**: Buildings and major constructions

## Core Functions

### Building System

- `fn_initBuildCamera`: Initializes the camera-based building system
- `fn_startPlacement`: Begins the placement process for a selected entity
- `fn_updateEntityPlacement`: Updates entity position during placement
- `fn_placeEntity`: Finalizes entity placement
- `fn_pickupEntity`: Picks up an existing entity for repositioning

### UI Functions

- `fn_openBuildMenu`: Opens the build menu dialog
- `fn_updateEntityList`: Populates the entity list based on selected category
- `fn_selectEntity`: Handles entity selection from the build menu
- `fn_updatePreview`: Updates the 3D preview model in the build menu

### Server Functions

- `fn_finalizeEntity`: Creates or updates entities on the server
- `fn_saveEntities`: Saves placed entities to profileNamespace
- `fn_onEntityKilled`: Handles cleanup when entities are destroyed
- `fn_toggleEntityVisibility`: Controls entity visibility during placement

### Utility Functions

- `fn_getEntityConfig`: Retrieves configuration data for an entity
- `fn_getEntityCategories`: Gets all available entity categories
- `fn_getEntitiesByCategory`: Retrieves entities belonging to a specific category
- `fn_cameraHint`: Displays hints in the build camera view

## Technical Details

### Entity Data Structure

Entities are stored in the global array `IDS_Logistics_Entities` with the following format:

```sqf
[className, category, cost]
```

### Persistence

Placed entities are saved to `profileNamespace` using the `fn_saveEntities` function. The data is stored as an array of HashMaps containing:

- Classname
- Position (ASL coordinates)
- Direction
- Vector up orientation
- Damage

## Extending the System

### Adding Custom Functionality

The modular design allows for easy extension. To add custom functionality:

1. Create a new function file in the appropriate directory
2. Add the function definition to `IDS_Logistics_Functions.hpp`
3. Call your function from the appropriate place in the workflow

### Integration with Other Systems

The IDS Logistics System can be integrated with other systems through:

- Event handlers for entity placement/removal
- Custom entity properties in the config files
- Extended functionality in the `fn_finalizeEntity` function


## Credits

- **Developer**: IDSolutions
- **Version**: 1.0
- **Date**: March 2025

## License

This system is licensed under the [Arma Public License (APL)](https://www.bohemia.net/community/licenses/arma-public-license). Please refer to the license for more information on usage and distribution rights. © 2025 IDSolutions