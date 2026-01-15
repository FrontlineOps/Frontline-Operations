/**
 * Function: FLO_fnc_displayNotification
 * 
 * Description:
 * Displays notifications using Antistasi-style temporary BIS tasks.
 * Creates a task that appears in the task bar, then auto-deletes after a duration.
 *
 * Parameters:
 * _title : STRING or ARRAY - Message to display (array for format)
 * _type : STRING - "info", "success", "warning", "error"
 * _playMusic - BOOL - play music for rewards
 *
 * Returns:
 * Nothing
 *
 * Examples:
 * ["Enemy position revealed", "info"] call FLO_fnc_displayNotification;
 * ["Objective captured!", "success", true] call FLO_fnc_displayNotification;
 */

if !(isServer) exitWith {
    _this remoteExec ["FLO_fnc_displayNotification", 2];
};

params [
    ["_title", "", ["", []]], 
    ["_type", "info", [""]],
    ["_playMusic", false, [true]]
];

// Localize and format title
if (_title isEqualType []) then {
    for "_i" from 0 to (count _title - 1) do {
        private _arg = _title#_i;
        if (_arg isEqualType "" && {_arg find "STR_" != -1}) then {
            _title set [_i, localize _arg];
        };
    };
    _title = format _title;
} else {
    if (_title find "STR_" != -1) then {
        _title = localize _title;
    };
};

// Generate unique task ID
private _taskId = format ["FLO_notify_%1", floor random 999999];

// Get task icon based on type
private _taskType = switch (toLower _type) do {
    case "success": { "Defend" };
    case "warning": { "Target" };
    case "error": { "Destroy" };
    default { "intel" };
};

// Duration based on type
private _duration = switch (toLower _type) do {
    case "success": { 9 };
    case "warning": { 12 };
    case "error": { 15 };
    default { 6 };
};

// Create temporary task - title IS the message
[
    west,
    _taskId,
    ["", _title, ""],  // [Description, Title, Marker]
    objNull,
    "CREATED",
    -1,
    true,
    _taskType,
    false
] call BIS_fnc_taskCreate;

// Delete task after duration
[_taskId, _duration] spawn {
    params ["_id", "_d"];
    sleep _d;
    [_id] call BIS_fnc_deleteTask;
};

// Play music for rewards if requested
if (_playMusic) then {
    playMusic "EventTrack01_F_Curator";
};