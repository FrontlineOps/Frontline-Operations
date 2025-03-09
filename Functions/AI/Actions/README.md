# Task Force Waypoint Actions

This directory contains a set of functions for managing AI unit waypoints and behaviors in the FLO mission framework.

## Core Functions

### `FLO_fnc_addWaypoint`
The base function for adding waypoints to a group. All other waypoint functions use this.

### `FLO_fnc_getTargetType`
Categorizes units and vehicles into types (MAN, CAR, ARMOR, HELI, etc.) for determining appropriate behaviors.

## Area Action Functions

These functions are used to assign groups to perform specific tasks in an area:

### `FLO_fnc_attackArea`
Assigns a group to attack a specific area. Behavior varies by unit type:
- Infantry will move to the area and execute a taskAttack
- Aircraft will perform search and destroy missions and then land
- Vehicles will perform search and destroy missions

### `FLO_fnc_defendArea`
Assigns a group to defend a specific area:
- Infantry will garrison buildings and use static weapons
- Aircraft will patrol and land when done
- Vehicles will perform perimeter security

### `FLO_fnc_patrolArea`
Assigns a group to patrol a specific area:
- Infantry will perform random patrols and search nearby
- Aircraft will fly between randomly generated points
- Vehicles will patrol a wider area

### `FLO_fnc_reconArea`
Assigns a group to perform reconnaissance in a specific area:
- Infantry will use stealth movement and report enemy contacts
- Aircraft will perform high-altitude surveillance
- Vehicles will perform wider perimeter checks

## Task Functions

These are lower-level functions that implement specific tactical behaviors:

### `FLO_fnc_taskAttack`
Orders a group to attack a specific position using search and destroy tactics.

### `FLO_fnc_taskDefend`
Orders a group to defend a position by manning static weapons, occupying buildings, and patrolling.

### `FLO_fnc_taskPatrol`
Creates a pattern of waypoints for a group to patrol around a central position.

### `FLO_fnc_reconAreaAction`
Called when a unit reaches a recon waypoint to report enemy presence to the AI commander.

## Usage Example

```sqf
// Group attacking an area
[_myGroup, _targetPosition] call FLO_fnc_attackArea;

// Group defending a position
[_myGroup, _objectivePosition] call FLO_fnc_defendArea;

// Group patrolling with a 500m radius
[_myGroup, _patrolCenter, 500] call FLO_fnc_patrolArea;

// Group performing recon
[_myGroup, _reconPosition] call FLO_fnc_reconArea;
``` 