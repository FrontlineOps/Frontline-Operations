/*
 * Function: FLO_fnc_getRandomObjectivePos
 * Author: Frontline Operations Development Group
 * Description:
 *   Gets a random position inside an objective's area.
 *   Supports polygon-based objectives for accurate positioning.
 *
 * Arguments:
 *   0: Objective ID (STRING) or Objective data (HASHMAP)
 *   1: Prefer road positions (BOOL) - Optional, default false
 *
 * Returns:
 *   ARRAY - Random position [x,y,z], or [0,0,0] on failure
 *
 * Examples:
 *   [_objectiveId] call FLO_fnc_getRandomObjectivePos;
 *   [_objectiveId, true] call FLO_fnc_getRandomObjectivePos;
 */

params [
    ["_objective", ""],
    ["_preferRoad", false]
];

// Get objective data
private _objData = if (_objective isEqualType "") then {
    if (isNil "FLO_Objectives") exitWith { nil };
    FLO_Objectives get _objective
} else {
    _objective
};

if (isNil "_objData") exitWith { [0,0,0] };

private _pos = _objData get "position";
private _radius = _objData getOrDefault ["radius", 50];

// Generate random position within radius
private _dir = random 360;
private _dist = random _radius;
private _randomPos = _pos getPos [_dist, _dir];

// Optionally find nearest road
if (_preferRoad) then {
    private _roads = _randomPos nearRoads _radius;
    if (count _roads > 0) then {
        _randomPos = getPos (selectRandom _roads);
    };
};

// Ensure position is on ground
_randomPos set [2, 0];

_randomPos