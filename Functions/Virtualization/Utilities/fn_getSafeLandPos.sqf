/*
 * Function: FLO_fnc_getSafeLandPos
 * Author: Frontline Operations Development Group
 * Description:
 * Returns a position on land, avoiding water. If the initial position is on water,
 * searches in a spiral pattern to find the nearest land position.
 *
 * Arguments:
 * 0: Position <ARRAY> - The desired position [x,y,z]
 * 1: Max Search Radius <NUMBER> - Maximum distance to search for land (default: 500)
 *
 * Return Value:
 * Safe position on land <ARRAY> - Returns original position if on land, or nearest land position
 *
 * Example:
 * private _safePos = [[1000, 2000, 0], 300] call FLO_fnc_getSafeLandPos;
 */

params [
    ["_position", [0,0,0], [[]]],
    ["_maxRadius", 500, [0]]
];

// Check if position is already on land
if (!surfaceIsWater _position) exitWith { _position };

// Position is on water - search for land
private _safePos = _position;
private _found = false;

// Search in expanding circles
for "_radius" from 50 to _maxRadius step 50 do {
    if (_found) exitWith {};
    
    // Check 8 directions at this radius
    for "_dir" from 0 to 315 step 45 do {
        private _testPos = _position getPos [_radius, _dir];
        
        if (!surfaceIsWater _testPos) exitWith {
            _safePos = _testPos;
            _found = true;
        };
    };
};

// If still not found, try to find any land position using findEmptyPosition
if (!_found) then {
    private _emptyPos = _position findEmptyPosition [0, _maxRadius, "Land_VASICore_F"];
    if (count _emptyPos > 0 && {!surfaceIsWater _emptyPos}) then {
        _safePos = _emptyPos;
    };
};

_safePos

