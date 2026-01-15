/**
 * Function: FLO_fnc_displayNotification
 * 
 * Description:
 * Displays notifications using Antistasi-style temporary BIS tasks.
 * Creates a task that appears in the task bar, then auto-deletes after a duration.
 * Much cleaner than hint or TextTiles - integrates with task UI.
 *
 * Parameters:
 * _title : STRING - Notification title
 * _msg : STRING or ARRAY - Message (array for format)
 * _type : STRING - "info", "success", "warning", "error"
 * _playMusic - BOOL - play music for rewards
 *
 * Returns:
 * Nothing
 *
 * Examples:
 * ["Intel", "Enemy position revealed", "info"] call FLO_fnc_displayNotification;
 * ["Mission", "Objective captured!", "success"] call FLO_fnc_displayNotification;
 */

if !(isServer) exitWith {
    // Redirect to server
    _this remoteExec ["FLO_fnc_displayNotification", 2];
};

params [
    ["_title", "", [""]],
    ["_msg", "", ["", []]], 
    ["_type", "info", [""]],
    ["_playMusic", false, [true]]
];

// Localize message
if (_msg isEqualType []) then {
    for "_i" from 0 to (count _msg - 1) do {
        private _arg = _msg#_i;
        if (_arg isEqualType "" && {_arg find "STR_" != -1}) then {
            _msg set [_i, localize _arg];
        };
    };
    _msg = format _msg;
} else {
    if (_msg find "STR_" != -1) then {
        _msg = localize _msg;
    };
};

// Localize title
private _titleText = if (_title find "STR_" != -1) then { localize _title } else { _title };

// Generate unique task ID
private _taskId = format ["FLO_notify_%1", floor random 999999];

// Get task icon based on type
private _taskType = switch (toLower _type) do {
    case "success": { "Defend" };      // Green shield icon
    case "warning": { "Target" };       // Target icon  
    case "error": { "Destroy" };        // Red X icon
    default { "intel" };                // Intel icon for info
};

// Duration based on type
private _duration = switch (toLower _type) do {
    case "success": { 9 };
    case "warning": { 12 };
    case "error": { 15 };
    default { 6 };
};

// Create temporary task for all players
// BIS_fnc_taskCreate: [sides, taskID, [description, title, marker], destination, state, priority, showNotification, type, visibleIn3D]
[
    west,                                           // Side(s) to show to
    _taskId,                                        // Unique task ID
    [_msg, _titleText, ""],                         // [Description, Title, Marker]
    objNull,                                        // No destination  
    "CREATED",                                      // State
    -1,                                             // Priority (low so it doesn't interfere)
    true,                                           // Show notification popup
    _taskType,                                      // Task type for icon
    false                                           // Not visible in 3D
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