/*
 * Function: FLO_fnc_flipObjective
 * Author: Frontline Operations Development Group
 * Description:
 *   Changes the owner of an objective and updates its marker color.
 *   Uses centralized config for marker colors.
 *
 * Arguments:
 *   0: Objective ID (STRING)
 *   1: New owner (SIDE)
 *
 * Returns: BOOL - Success
 *
 * Example:
 *   ["virtual_1", west] call FLO_fnc_flipObjective;
 */

params [
    ["_objectiveId", ""],
    ["_newOwner", civilian]
];

// Validate inputs
if (_objectiveId == "") exitWith { false };
if (isNil "FLO_Objectives") exitWith { false };

private _obj = FLO_Objectives get _objectiveId;
if (isNil "_obj") exitWith { false };

// Store previous owner for event
private _previousOwner = _obj getOrDefault ["owner", east];

// Update owner
_obj set ["owner", _newOwner];
FLO_Objectives set [_objectiveId, _obj];

// Update marker using centralized function
[_objectiveId, _obj] call FLO_fnc_createObjectiveMarker;
[] call FLO_fnc_refreshRespawnMarkersByTerritory;

// Broadcast change
publicVariable "FLO_Objectives";

// Log the flip
["OBJECTIVE", 3, format ["Objective %1 flipped from %2 to %3", _objectiveId, _previousOwner, _newOwner]] call FLO_fnc_log;

true
