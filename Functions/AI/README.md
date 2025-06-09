# AI Commander and Task Force System

## Overview
This directory contains the AI Commander system and related functions for controlling OPFOR forces in the FLO mission. The system manages task forces, garrison integration, and tactical operations based on the current situation on the battlefield.

## Key Components

### AI Commander (`fn_aiCommander.sqf`)
The central AI controlling system that:
- Manages outposts and garrisons
- Assesses threats and adapts operation modes (ATTACK, DEFEND, SKIRMISH)
- Deploys task forces for various missions
- Processes reconnaissance reports
- Coordinates combined arms operations with infantry and vehicles

### Waypoint Actions (`Actions/`)
A suite of functions that provide tactical behaviors for groups:
- `fn_attackArea.sqf`: Assigns attack behaviors based on unit type and available support
- `fn_defendArea.sqf`: Assigns defense behaviors including garrisoning buildings
- `fn_patrolArea.sqf`: Creates patrol patterns around a designated area
- `fn_reconArea.sqf`: Assigns reconnaissance behaviors to gather intelligence
- `fn_reconAreaAction.sqf`: Handles reporting intelligence back to the AI Commander

### Vehicle Integration
The system integrates vehicles and infantry in separate groups for maximum control:
- Vehicles are analyzed using `_evaluateVehicleCapabilities` to determine their optimal roles
- Each type of vehicle (Tank, APC, MRAP, etc.) receives appropriate tactical behaviors
- Infantry and vehicle groups are coordinated to work together through linked group references
- Vehicle groups adapt their behavior based on vehicle type and the infantry they're supporting
- Vehicle types are pulled dynamically from the `CUSTOM_ENEMY_FACTION.sqf` file arrays:
  - `East_Ground_Vehicles_Heavy`: Tanks and heavy APCs for anti-armor operations
  - `East_Ground_Vehicles_Light`: Light APCs, MRAPs, and armed vehicles
  - `East_Ground_Vehicles_Ambient`: Civilian-type and ambient vehicles
  - `East_Ground_Transport`: Transport trucks and unarmed vehicles
  - `East_Air_Transport`, `East_Air_Heli`, `East_Air_Jet`: For air operations

### Garrison Integration System (`fn_taskForceGarrisonIntegration.sqf`)
A comprehensive system that connects task forces with outpost garrisons:
- Allows task forces to draw units from garrisons via `_pullUnitsFromGarrison`
- Returns surviving units to garrisons after operations via `_returnUnitsToGarrison`
- New vehicle management methods:
  - `_pullVehicleFromGarrison`: Acquires vehicles from garrison or spawns new ones
  - `_returnVehicleToGarrison`: Returns vehicles to garrisoned outposts
  - `_addVehicleToGarrison`: Adds new vehicles to outpost garrisons
- Intelligent selection of vehicle types based on mission needs and enemy composition

### Task Force System
The task force deployment system now includes:
- Combined arms operations with infantry and vehicle support
- Selection of appropriate vehicle types based on mission and enemy composition
- Coordinated waypoints that ensure vehicles and infantry work together effectively
- Reporting capabilities for reconnaissance units to provide intelligence back to the commander

## Usage

### Deploying the AI Commander
The AI Commander is designed to be initialized at mission start:

```sqf
private _commander = call FLO_fnc_aiCommander;
```

### Working with Task Forces
Task forces are automatically deployed by the AI Commander, but can also be manually created:

```sqf
// Example of manually creating a task force with vehicle support
private _infantryGroup = [_position, _side, _infantryUnits] call BIS_fnc_spawnGroup;
private _vehicleGroup = [_position, _side, _vehicleType] call BIS_fnc_spawnGroup;

// Assign coordinated actions
[_infantryGroup, _targetPosition, "ATTACK", _vehicleGroup] call FLO_fnc_attackArea;
[_vehicleGroup, _targetPosition, "ATTACK", _infantryGroup] call FLO_fnc_attackArea;
```

### Working with Garrison Vehicles
The garrison integration system provides methods for vehicle management:

```sqf
// Initialize the garrison integration system
FLO_TaskForce_Garrison_Integration = call FLO_fnc_taskForceGarrisonIntegration;

// Add vehicles to a garrison
FLO_TaskForce_Garrison_Integration call ["_addVehicleToGarrison", ["marker_outpost_1", "I_MRAP_03_hmg_F", 2]];

// Pull a vehicle for a task force
private _vehicle = FLO_TaskForce_Garrison_Integration call ["_pullVehicleFromGarrison", ["marker_outpost_1", ["MRAP", "Car"], ["I_MRAP_03_hmg_F"], "TF_123"]];

// Return a vehicle to a garrison
FLO_TaskForce_Garrison_Integration call ["_returnVehicleToGarrison", [_vehicle, "marker_outpost_1"]];
```

### Artillery Asset Manager
Virtual artillery groups created by the virtualization system can be used for fire missions via the artillery asset manager. This manager unvirtualizes a group, orders it to fire, then moves and revirtualizes it to simulate shoot‑and‑scoot tactics.

Use `FLO_fnc_requestVirtualArtillery` for a simple support call interface:
```sqf
// Request a fire mission of six rounds at a target position
[getPos player, 6] call FLO_fnc_requestVirtualArtillery;
```

The AI Commander provides a convenient method to request artillery as well:
```sqf
private _commander = call FLO_fnc_aiCommander;
_commander call ["_callArtillerySupport", [getPos player, 6]];
```
This method broadcasts a warning notification when artillery is incoming.

### Customizing Vehicle Selection
The system uses the vehicle arrays from `CUSTOM_ENEMY_FACTION.sqf` to select appropriate vehicles:

```sqf
// Example of manually selecting a vehicle type based on operation needs
private _vehicleType = "";
if (_needAntiArmor) then {
    _vehicleType = selectRandom East_Ground_Vehicles_Heavy;
} else {
    if (_needPatrol) then {
        _vehicleType = selectRandom East_Ground_Vehicles_Light;
    } else {
        _vehicleType = selectRandom East_Ground_Transport;
    };
};
```

## Development Notes
- Vehicle capabilities analysis based on AI ammo usage flags from configs
- Formation and speed settings are tailored to each vehicle type
- Waypoints use appropriate tactical positioning for each unit type
- Stealth vs. combat operations handled differently for different unit compositions
- The system automatically adapts to whatever vehicles are defined in the faction file 