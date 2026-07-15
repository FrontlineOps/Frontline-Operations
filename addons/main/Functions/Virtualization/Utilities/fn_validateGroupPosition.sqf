/*
 * Function: FLO_fnc_validateGroupPosition
 * Author: Frontline Operations Development Group
 * Description:
 *   Validates a position for use in the virtualization system.
 *   Checks that position is:
 *   - Not nil
 *   - An array with at least 2 elements
 *   - Not the exact engine origin sentinel
 *
 * Arguments:
 * 0: Position <ARRAY> - Position to validate
 * 1: Log Errors <BOOLEAN> - Whether to log errors (default: false)
 * 2: Context <STRING> - Context for error logging (default: "")
 *
 * Return Value:
 * Boolean - True if position is valid
 *
 * Example:
 * if ([_pos] call FLO_fnc_validateGroupPosition) then { ... };
 * if ([_pos, true, "spawn check"] call FLO_fnc_validateGroupPosition) then { ... };
 */

params [
    ["_position", nil, [[]]],
    ["_logErrors", false, [true]],
    ["_context", "", [""]]
];

// Check if nil
if (isNil "_position") exitWith {
    if (_logErrors) then {
        ["VIRTUALIZATION", 1, format["Invalid position (nil) - %1", _context]] call FLO_fnc_log;
    };
    false
};

// Check if array
if (!(_position isEqualType [])) exitWith {
    if (_logErrors) then {
        ["VIRTUALIZATION", 1, format["Invalid position (not array) - %1: %2", _context, _position]] call FLO_fnc_log;
    };
    false
};

// Check array length
if (count _position < 2) exitWith {
    if (_logErrors) then {
        ["VIRTUALIZATION", 1, format["Invalid position (too short) - %1: %2", _context, _position]] call FLO_fnc_log;
    };
    false
};

// Reject only the engine failure sentinel. Low positive coordinates are valid
// playable positions on terrains whose world bounds approach the map origin.
private _x = _position select 0;
private _y = _position select 1;

if (abs _x < 0.001 && {abs _y < 0.001}) exitWith {
    if (_logErrors) then {
        ["VIRTUALIZATION", 1, format["Invalid position (origin sentinel) - %1: %2", _context, _position]] call FLO_fnc_log;
    };
    false
};

// All checks passed
true

