/*
 * Function: FLO_fnc_sideMissionTaskCleanup
 * Author: Frontline Operations Development Group
 * Description:
 *   Removes a BIS task and associated markers after a delay.
 *   Called automatically by the mission manager on completion.
 *
 * Arguments:
 *   0: Mission ID (STRING)
 *   1: Delay (NUMBER) - Seconds to wait before cleanup (default 60)
 *   2: Immediate (BOOL) - If true, ignore delay (default false)
 *
 * Returns:
 *   BOOL - True if cleanup initiated
 *
 * Example:
 *   [_missionId] call FLO_fnc_sideMissionTaskCleanup;
 *   [_missionId, 120] call FLO_fnc_sideMissionTaskCleanup;
 *   [_missionId, 0, true] call FLO_fnc_sideMissionTaskCleanup;
 */

params [["_missionId", ""], ["_delay", 60], ["_immediate", false]];

if (_missionId == "") exitWith { false };

// Get mission instance
private _instance = ["get", [_missionId]] call FLO_fnc_sideMissionRegistry;
if (isNil "_instance") exitWith { 
    diag_log format ["[FLO_SM] TaskCleanup: Mission not found: %1", _missionId];
    false 
};

// Get task ID
private _taskId = _instance getOrDefault ["taskId", ""];
if (_taskId == "") exitWith { 
    diag_log format ["[FLO_SM] TaskCleanup: No task for mission: %1", _missionId];
    true // Not an error - mission may not have a task
};

// Cleanup function
private _doCleanup = {
    params ["_taskId", "_missionId"];

    [_taskId] call BIS_fnc_deleteTask;
    diag_log format ["[FLO_SM] Deleted task: %1", _taskId];
};

if (_immediate) then {
    // Cleanup immediately
    [_taskId, _missionId] call _doCleanup;
} else {
    // Schedule cleanup after delay
    [_taskId, _missionId, _delay, _doCleanup] spawn {
        params ["_taskId", "_missionId", "_delay", "_fnc"];
        sleep _delay;
        [_taskId, _missionId] call _fnc;
    };
};

diag_log format ["[FLO_SM] Task cleanup %1 for %2 (delay: %3s)", 
    if (_immediate) then {"immediate"} else {"scheduled"}, _missionId, _delay];

true
