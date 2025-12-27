/*
 * Function: FLO_fnc_sideMissionTaskUpdate
 * Author: Frontline Operations Development Group
 * Description:
 *   Updates a BIS task state for a side mission.
 *   Syncs mission state machine with BIS task state.
 *
 * BIS Task States:
 *   "CREATED"   - Task exists but not assigned
 *   "ASSIGNED"  - Task is current/active
 *   "SUCCEEDED" - Task completed successfully
 *   "FAILED"    - Task failed
 *   "CANCELED"  - Task was cancelled
 *
 * Arguments:
 *   0: Mission ID (STRING)
 *   1: New State (STRING) - BIS task state
 *   2: Notify (BOOL) - Show notification (default true)
 *
 * Returns:
 *   BOOL - True if update successful
 *
 * Example:
 *   [_missionId, "SUCCEEDED"] call FLO_fnc_sideMissionTaskUpdate;
 *   [_missionId, "FAILED", false] call FLO_fnc_sideMissionTaskUpdate;
 */

params [["_missionId", ""], ["_newState", ""], ["_notify", true]];

if (_missionId == "" || _newState == "") exitWith { false };

// Get mission instance
private _instance = ["get", [_missionId]] call FLO_fnc_sideMissionRegistry;
if (isNil "_instance") exitWith { 
    diag_log format ["[FLO_SM] TaskUpdate: Mission not found: %1", _missionId];
    false 
};

// Get task ID
private _taskId = _instance getOrDefault ["taskId", ""];
if (_taskId == "") exitWith { 
    diag_log format ["[FLO_SM] TaskUpdate: No task for mission: %1", _missionId];
    false 
};

// Validate state
private _validStates = ["CREATED", "ASSIGNED", "SUCCEEDED", "FAILED", "CANCELED"];
_newState = toUpper _newState;

if !(_newState in _validStates) exitWith {
    diag_log format ["[FLO_SM] TaskUpdate: Invalid state: %1", _newState];
    false
};

// Update BIS task state
[_taskId, _newState, _notify] call BIS_fnc_taskSetState;

// Sync with mission state machine
private _missionState = switch (_newState) do {
    case "CREATED":   { 0 };  // QUEUED
    case "ASSIGNED":  { 2 };  // ACTIVE
    case "SUCCEEDED": { 3 };  // SUCCESS
    case "FAILED":    { 4 };  // FAILED
    case "CANCELED":  { 5 };  // CANCELLED
    default           { -1 };
};

if (_missionState >= 0) then {
    ["set", [_missionId, _missionState, true]] call FLO_fnc_sideMissionState;
};

diag_log format ["[FLO_SM] Updated task %1 to state %2", _taskId, _newState];

true

