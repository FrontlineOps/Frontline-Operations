/*
 * Function: FLO_fnc_startSideMission
 * Author: Frontline Operations Development Group
 * Description:
 *   Public API wrapper to spawn a side mission by type name.
 *   Bridges the legacy API to the new mission manager system.
 *
 * Arguments:
 *   0: Mission type name (STRING) - e.g., "pilotRescue", "convoyInterdiction"
 *
 * Returns:
 *   BOOL - True if mission spawned successfully, false otherwise
 *
 * Examples:
 *   ["pilotRescue"] call FLO_fnc_startSideMission;
 *   ["convoyInterdiction"] call FLO_fnc_startSideMission;
 */

params [["_typeName", ""]];

if (_typeName == "") exitWith {
    diag_log "[FLO_SM] startSideMission: No mission type specified";
    false
};

// Delegate to the mission manager's spawn operation
private _result = ["spawn", [_typeName]] call FLO_fnc_sideMissionManager;

if (_result) then {
    diag_log format ["[FLO_SM] startSideMission: Successfully spawned %1", _typeName];
} else {
    diag_log format ["[FLO_SM] startSideMission: Failed to spawn %1", _typeName];
};

_result

