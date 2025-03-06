/* ----------------------------------------------------------------------------
Function: FLO_fnc_reconAreaAction

Description:
    A function to be executed when a unit reaches a reconnaissance waypoint.
    Reports information about enemy presence in the area to the AI commander.

Parameters:
    - Unit (Object) - The unit that triggered the waypoint

Returns:
    BOOL - Success or failure

Example:
    (begin example)
    [this] call FLO_fnc_reconAreaAction
    (end)

Author:
    Azraeelian Angel
---------------------------------------------------------------------------- */

params [
    ["_unit", objNull, [objNull]]
];

// Validate parameters
if (isNull _unit) exitWith {
    ["FLO_fnc_reconAreaAction", 1, "Invalid unit parameter"] call FLO_fnc_log;
    false
};

// Get the unit's group
private _group = group _unit;

// Check if we need to report
if (!(_group getVariable ["FLO_lastReconReport", -1000] < diag_tickTime - 180)) exitWith {
    // Don't spam reports, only report every 3 minutes max
    false
};

// Set the last report time
_group setVariable ["FLO_lastReconReport", diag_tickTime];

// Detect enemies in the area
private _position = getPos _unit;
private _searchRadius = 500;

// Find enemy units in the area
private _nearEntities = _position nearEntities ["Man", _searchRadius];
private _vehicles = _position nearEntities [["Car", "Tank", "Air"], _searchRadius];
_nearEntities append _vehicles;

// Filter for west side (BLUFOR)
private _enemies = _nearEntities select {side _x == west && !(captive _x)};

if (count _enemies == 0) exitWith {
    // No enemies detected, log minimal report
    ["FLO_fnc_reconAreaAction", 3, format["Recon report from %1: No enemies detected at %2", _group, _position]] call FLO_fnc_log;
    true
};

// Count enemy types
private _infantry = 0;
private _vehicles = 0;
private _armor = 0;
private _air = 0;
private _enemyTypes = [];

{
    if (_x isKindOf "Man") then {
        _infantry = _infantry + 1;
        _enemyTypes pushBackUnique "MAN";
    } else {
        _vehicles = _vehicles + 1;
        
        if (_x isKindOf "Tank" || _x isKindOf "Wheeled_APC") then {
            _armor = _armor + 1;
            _enemyTypes pushBackUnique "ARMOR";
        };
        
        if (_x isKindOf "Air") then {
            _air = _air + 1;
            
            if (_x isKindOf "Helicopter") then {
                _enemyTypes pushBackUnique "HELI";
            } else {
                _enemyTypes pushBackUnique "PLANE";
            };
            
            _enemyTypes pushBackUnique "AIR";
        };
        
        if (_x isKindOf "Car") then {
            _enemyTypes pushBackUnique "CAR";
        };
    };
} forEach _enemies;

// Compile the report data
private _reportData = [
    _position,
    count _enemies,
    _infantry,
    _vehicles,
    _armor,
    _air,
    _enemyTypes
];

// Log the report at local level
["FLO_fnc_reconAreaAction", 3, format["Recon report from %1: %2 enemies detected at %3 (%4 infantry, %5 vehicles, %6 armor, %7 air)", 
    _group, count _enemies, _position, _infantry, _vehicles, _armor, _air]] call FLO_fnc_log;

// Report to AI Commander if available
if (!isNil "FLO_AI_Commander") then {
    FLO_AI_Commander call ["_processReconReport", [_reportData, _group]];
};

// Mark the report on the map for debug purposes
private _markerName = format ["recon_report_%1_%2", floor random 1000, floor diag_tickTime];
private _marker = createMarker [_markerName, _position];
_marker setMarkerType "o_recon";
_marker setMarkerColor "ColorOPFOR";
_marker setMarkerAlpha 0.7;
_marker setMarkerText format ["Recon Report (%1)", count _enemies];

// Set up marker deletion after 3 minutes
[_markerName] spawn {
    params ["_markerName"];
    sleep 180;
    deleteMarker _markerName;
};

// Return success
true 