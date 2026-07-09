/*
 * Function: FLO_fnc_virtualizationAdvanceWaypoint
 * Author: Frontline Operations Development Group
 * Description:
 *   Handles waypoint completion for a virtual group.
 *   Advances to next waypoint, handles CYCLE waypoints, and manages patrol logic.
 *
 *   Waypoint Types:
 *   - MOVE: Normal movement, completes when within completion radius
 *   - SAD, DESTROY: Advances through waypoints; enters "holding" runtime state on FINAL waypoint
 *   - GUARD, HOLD: Advances through waypoints; enters "holding" runtime state on FINAL waypoint
 *   - CYCLE: Loops back to first waypoint
 *   - SENTRY: Holds position in holding state
 *   - LOITER: Stays at position for timeout duration
 *
 *   NOTE: Virtual groups advance through ALL waypoints to reach their destination.
 *   Only the FINAL SAD/DESTROY/GUARD/HOLD waypoint triggers persistent holding.
 *   High-level attacking/defending posture is derived from commanderOrder and
 *   other normalized state, not stored directly in the runtime "state" field.
 *
 * Arguments:
 * 0: Group ID <STRING>
 * 1: Group Data <HASHMAP>
 * 2: Current Waypoint Index <NUMBER>
 * 3: Waypoints Array <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_groupId, _groupData, _currentIdx, _waypoints] call FLO_fnc_virtualizationAdvanceWaypoint;
 */

params ["_groupId", "_groupData", "_currentIdx", "_waypoints"];

// Check for transport dismount at this waypoint
[_groupId] call FLO_fnc_transportDismount;

if (_waypoints isEqualTo [] || _currentIdx >= count _waypoints) exitWith {
    [_groupData, "idle"] call FLO_fnc_virtualizationSetRuntimeState;
    _groupData set ["currentWaypointIndex", 0];
    _groupData set ["virtualMoveCarryMeters", 0];
    [_groupData] call FLO_fnc_virtualizationRefreshCurrentWaypointSpeed;
};

private _currentWp = _waypoints select _currentIdx;
private _wpType = _currentWp select 1;
// Patrol detection is explicit in virtual group state.
private _isPatrol = (_groupData get "autoPatrol") || ((_groupData get "patrolConfig") isNotEqualTo []);

switch (_wpType) do {
    // CYCLE - legacy support, loop back to first waypoint
    // NOTE: We're phasing out CYCLE in favor of autoPatrol/patrolConfig
    case "CYCLE": {
        _groupData set ["currentWaypointIndex", 0];
        ["VIRTUALIZATION", 4, format["Group %1 cycling to first waypoint (legacy CYCLE)", _groupId]] call FLO_fnc_log;
    };

    // SENTRY - hold position (never completes)
    case "SENTRY": {
        _groupData set ["lastSentryTime", diag_tickTime];
        [_groupData, "holding"] call FLO_fnc_virtualizationSetRuntimeState;
    };

    // SAD/DESTROY - attack waypoints
    // Virtual groups advance through these to reach their destination
    // Only enter persistent holding when this is the LAST waypoint
    case "SAD";
    case "DESTROY": {
        [_groupId, _groupData, _currentIdx, _waypoints, _wpType] call FLO_fnc_virtualizationAdvanceTerminalWaypoint;
    };

    // GUARD/HOLD - defend waypoints
    // Virtual groups advance through these to reach their destination
    // Only enter persistent holding when this is the LAST waypoint
    case "GUARD";
    case "HOLD": {
        [_groupId, _groupData, _currentIdx, _waypoints, _wpType] call FLO_fnc_virtualizationAdvanceTerminalWaypoint;
    };

    // LOITER - stay in area for timeout duration
    case "LOITER": {
        [_groupData, _currentIdx, _waypoints, _isPatrol, _currentWp] call FLO_fnc_virtualizationAdvanceLoiterWaypoint;
    };

    // Default movement waypoints (MOVE, etc.)
    default {
        [_groupId, _groupData, _currentIdx, _waypoints, _isPatrol] call FLO_fnc_virtualizationAdvanceDefaultWaypoint;
    };
};

_groupData set ["virtualMoveCarryMeters", 0];
[_groupData] call FLO_fnc_virtualizationRefreshCurrentWaypointSpeed;

