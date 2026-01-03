/*
 * Function: FLO_fnc_sideMissionTaskCreate
 * Author: Frontline Operations Development Group
 * Description:
 *   Creates a BIS task for a side mission with proper configuration.
 *   Integrates with the mission registry to track the task ID.
 *
 * Arguments:
 *   0: Mission ID (STRING)
 *   1: Options (HASHMAP) - Optional overrides:
 *      - "title":       Task title (defaults to template name)
 *      - "description": Task description array [title, desc, marker]
 *      - "position":    Task position (defaults to mission position)
 *      - "parent":      Parent task ID for subtasks
 *      - "priority":    Task priority (default 1)
 *      - "type":        Task type/icon (default from template)
 *
 * Returns:
 *   STRING - Created task ID, or "" on failure
 *
 * Example:
 *   [_missionId] call FLO_fnc_sideMissionTaskCreate;
 *   [_missionId, createHashMapFromArray [["title", "Custom Title"]]] call FLO_fnc_sideMissionTaskCreate;
 */

params [["_missionId", ""], ["_options", createHashMap]];

if (_missionId == "") exitWith { "" };

// Get mission instance
private _instance = ["get", [_missionId]] call FLO_fnc_sideMissionRegistry;
if (isNil "_instance") exitWith { 
    diag_log format ["[FLO_SM] TaskCreate: Mission not found: %1", _missionId];
    "" 
};

// Get template for defaults
private _type = _instance get "type";
private _template = ["get", [_type]] call FLO_fnc_sideMissionTemplate;

// Build task ID
private _taskId = format ["SM_Task_%1", _missionId];

// Get position
private _position = _options getOrDefault ["position", _instance get "position"];

// Get title and description
private _title = _options getOrDefault ["title", ""];
if (_title == "" && !isNil "_template") then {
    _title = _template getOrDefault ["name", _type];
};
if (_title == "") then { _title = "Side Mission"; };

private _desc = _options getOrDefault ["description", ""];
if (_desc == "") then {
    _desc = if (!isNil "_template") then { 
        _template getOrDefault ["description", "Complete the objective."] 
    } else { 
        "Complete the objective." 
    };
};

// Build description array [title, description, marker]
private _markerName = format ["SM_TaskMrk_%1", _missionId];
private _descArray = [_title, _desc, _markerName];

// Get task type/icon
private _taskType = _options getOrDefault ["type", ""];
if (_taskType == "" && !isNil "_template") then {
    _taskType = _template getOrDefault ["icon", "default"];
};
if (_taskType == "") then { _taskType = "default"; };

// Get parent task (for subtasks)
private _parent = _options getOrDefault ["parent", ""];

// Get priority
private _priority = _options getOrDefault ["priority", 1];

// [owner, taskID, description, destination, state, priority, showNotification, type, visibleIn3D]
[
    true,                    // All players
    _taskId,                 // Task ID
    _descArray,              // [title, desc, marker]
    _position,               // Destination
    "CREATED",               // Initial state
    _priority,               // Priority
    true,                    // Show notification
    _taskType,               // Type/icon
    true                     // Visible in 3D
] call BIS_fnc_taskCreate;

// Set parent if provided
if (_parent != "") then {
    [_taskId, _parent] call BIS_fnc_taskSetParent;
};

// Set task as current/assigned
[_taskId, "ASSIGNED"] call BIS_fnc_taskSetState;

// Store task ID in mission instance
["update", [_missionId, "taskId", _taskId]] call FLO_fnc_sideMissionRegistry;

diag_log format ["[FLO_SM] Created task %1 for mission %2", _taskId, _missionId];

_taskId

