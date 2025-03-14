/*
    File: fn_getRandomMagazine.sqf
    Author: Frontline Operations Development Group
    Description: Gets a random magazine from a specified unit or vehicle
    
    Parameters:
        _target - Unit or vehicle to get magazines from (Object)
        _includeEmpty - Whether to include empty magazines (Optional, Boolean, Default: false)
    
    Returns:
        Random magazine classname (String), or "" if no magazines are available
    
    Example:
        _randomMag = [player] call FLO_fnc_getRandomMagazine;
        _randomMag = [cursorTarget, true] call FLO_fnc_getRandomMagazine;
*/

params [
    ["_target", objNull, [objNull]],
    ["_includeEmpty", false, [false]]
];

// Return empty string if target is invalid
if (isNull _target) exitWith {
    diag_log "Error: Invalid target passed to getRandomMagazine";
    ""
};

// Get all magazines using the magazines command
private _availableMags = [];

if (_includeEmpty) then {
    // Use the alternative syntax to include empty magazines
    _availableMags = magazines [_target, _includeEmpty];
} else {
    // Use the standard syntax
    _availableMags = magazines _target;
};

// Return empty string if no magazines available
if (count _availableMags == 0) exitWith {
    diag_log format ["No magazines found on %1", _target];
    ""
};

// Select a random magazine from the array
private _randomMag = selectRandom _availableMags;

// Return the result
_randomMag 
