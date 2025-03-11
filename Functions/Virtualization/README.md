# OPFOR Virtualization System

## Overview
The OPFOR Virtualization System provides a framework for efficiently managing large numbers of AI units in the FLO Gamemode. It tracks and can move groups around the map via the AI Commander's waypoint system, only physically spawning groups when players are within a configured distance.

## How It Works
1. At mission start, virtual groups are created at objectives based on the configuration in `CUSTOM_ENEMY_FACTION.sqf`.
2. These groups exist as data (HashMaps) until a player comes within the activation distance.
3. When players are nearby, virtual groups are physically spawned in the game world.
4. When players move away, physical groups are removed but their state (position, waypoints, etc.) is preserved.
5. The AI Commander can issue waypoints to both virtual and physical groups.

## Key Components

### Virtual Groups HashMap
Central storage for all virtual groups with their properties and states.

### Group Activation/Deactivation
Controls when groups are physically spawned or removed based on player proximity.

### Objective-Based Initialization
Spawns appropriate forces at different objective types according to configuration.

### Debug Visualization
Optional markers to show the positions and states of all virtual groups.

## Functions

1. `FLO_fnc_initVirtualization` - Initializes the virtualization system
2. `FLO_fnc_createVirtualGroup` - Creates a new virtual group
3. `FLO_fnc_activateVirtualGroup` - Spawns a virtual group in the game world
4. `FLO_fnc_deactivateVirtualGroup` - Removes a physical group but preserves its virtual state
5. `FLO_fnc_virtualGroupsUpdateLoop` - Continuously checks player proximity to activate/deactivate groups
6. `FLO_fnc_updateVirtualGroupWaypoints` - Updates waypoints for a virtual group
7. `FLO_fnc_initializeObjectiveGroups` - Creates virtual groups at all appropriate objectives
8. `FLO_fnc_toggleVirtualizationDebug` - Enables/disables debug visualization

## Integration with AI Commander
The virtualization system integrates with the AI Commander (`FLO_fnc_aiCommander`). The commander can issue waypoints to both physical and virtual groups, and the virtualization system handles the transition between the two states.

## Configuration
The system is configured through `CUSTOM_ENEMY_FACTION.sqf`, which defines:

1. The unit types available for each group type
2. How many of each group type should spawn at different objective types
3. The activation distance for virtualization

## Usage Example
```sqf
// Initialize the system
[2000] call FLO_fnc_initVirtualization;

// Create a virtual infantry group
[getMarkerPos "marker_1", "infantry", nil, "objective_1"] call FLO_fnc_createVirtualGroup;

// Send a virtual group to a new position
["vgroup_123", [[getMarkerPos "marker_2", "MOVE", "AWARE", "NORMAL", "COLUMN", "YELLOW"]]] call FLO_fnc_updateVirtualGroupWaypoints;

// Enable debug visualization
[true] call FLO_fnc_toggleVirtualizationDebug;
``` 