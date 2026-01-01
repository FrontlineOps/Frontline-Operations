/*
 * Function: FLO_fnc_virtualizationAdvanceWaypoint
 * Author: Frontline Operations Development Group
 * Description:
 *   Handles waypoint completion for a virtual group.
 *   Advances to next waypoint, handles CYCLE waypoints, and manages patrol logic.
 *
 *   Waypoint Types:
 *   - MOVE: Normal movement, completes when within completion radius
 *   - SAD, DESTROY: Advances through waypoints; enters "attacking" state on FINAL waypoint
 *   - GUARD, HOLD: Advances through waypoints; enters "defending" state on FINAL waypoint
 *   - CYCLE: Loops back to first waypoint
 *   - SENTRY: Holds position in defending state
 *   - LOITER: Stays at position for timeout duration
 *
 *   NOTE: Virtual groups advance through ALL waypoints to reach their destination.
 *   Only the FINAL SAD/DESTROY/GUARD/HOLD waypoint triggers persistent state.
 *   Groups stay in attacking/defending state until the AI Commander reassigns them.
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

if (count _waypoints == 0 || _currentIdx >= count _waypoints) exitWith {
    _groupData set ["state", "idle"];
    _groupData set ["currentWaypointIndex", 0];
};

private _currentWp = _waypoints select _currentIdx;
private _wpType = _currentWp select 1;
private _isPatrol = (_groupData getOrDefault ["autoPatrol", false]) ||
                    ({(_x select 1) == "CYCLE"} count _waypoints > 0);

switch (_wpType) do {
    // CYCLE - loop back to first waypoint
    case "CYCLE": {
        _groupData set ["currentWaypointIndex", 0];
        ["VIRTUALIZATION", 4, format["Group %1 cycling to first waypoint", _groupId]] call FLO_fnc_log;
    };

    // SENTRY - hold position (never completes)
    case "SENTRY": {
        _groupData set ["lastSentryTime", diag_tickTime];
        _groupData set ["state", "defending"];
    };

    // SAD/DESTROY - attack waypoints
    // Virtual groups advance through these to reach their destination
    // Only enter "attacking" state when this is the LAST waypoint
    case "SAD";
    case "DESTROY": {
        // Check if this is the last waypoint
        private _isLastWp = (_currentIdx >= (count _waypoints - 1));

        if (_isLastWp) then {
            // Final attack waypoint - stay here attacking
            _groupData set ["state", "attacking"];
            ["VIRTUALIZATION", 4, format["Group %1 reached final %2 waypoint - entering attacking state", _groupId, _wpType]] call FLO_fnc_log;
        } else {
            // More waypoints to go - advance to next
            _waypoints deleteAt _currentIdx;
            _groupData set ["waypoints", _waypoints];
            _groupData set ["currentWaypointIndex", _currentIdx min (count _waypoints - 1)];
            _groupData set ["state", "moving"];
            ["VIRTUALIZATION", 4, format["Group %1 completed %2 waypoint - advancing to next", _groupId, _wpType]] call FLO_fnc_log;
        };
    };

    // GUARD/HOLD - defend waypoints
    // Virtual groups advance through these to reach their destination
    // Only enter "defending" state when this is the LAST waypoint
    case "GUARD";
    case "HOLD": {
        // Check if this is the last waypoint
        private _isLastWp = (_currentIdx >= (count _waypoints - 1));

        if (_isLastWp) then {
            // Final defend waypoint - stay here defending
            _groupData set ["state", "defending"];
            ["VIRTUALIZATION", 4, format["Group %1 reached final %2 waypoint - entering defending state", _groupId, _wpType]] call FLO_fnc_log;
        } else {
            // More waypoints to go - advance to next
            _waypoints deleteAt _currentIdx;
            _groupData set ["waypoints", _waypoints];
            _groupData set ["currentWaypointIndex", _currentIdx min (count _waypoints - 1)];
            _groupData set ["state", "moving"];
            ["VIRTUALIZATION", 4, format["Group %1 completed %2 waypoint - advancing to next", _groupId, _wpType]] call FLO_fnc_log;
        };
    };

    // LOITER - stay in area for timeout duration
    case "LOITER": {
        private _timeout = _currentWp param [6, 60];  // Default 60s loiter
        private _loiterStart = _groupData getOrDefault ["loiterStartTime", 0];

        if (_loiterStart == 0) then {
            _groupData set ["loiterStartTime", diag_tickTime];
        } else {
            if (diag_tickTime - _loiterStart > _timeout) then {
                // Loiter complete - move to next
                _groupData set ["loiterStartTime", 0];
                private _nextIdx = _currentIdx + 1;
                if (_nextIdx >= count _waypoints) then {
                    if (_isPatrol) then { _nextIdx = 0; } else { _nextIdx = 0; _groupData set ["state", "idle"]; };
                };
                _groupData set ["currentWaypointIndex", _nextIdx];
            };
        };
    };

    // Default movement waypoints (MOVE, etc.)
    default {
        if (_isPatrol) then {
            // Patrol mode - cycle through waypoints
            private _nextIdx = _currentIdx + 1;
            if (_nextIdx >= count _waypoints) then {
                _nextIdx = 0;
            };
            _groupData set ["currentWaypointIndex", _nextIdx];
        } else {
            // Non-patrol - delete completed waypoint
            _waypoints deleteAt _currentIdx;
            _groupData set ["waypoints", _waypoints];

            if (count _waypoints > 0) then {
                _groupData set ["currentWaypointIndex", _currentIdx min (count _waypoints - 1)];
                _groupData set ["state", "moving"];
            } else {
                _groupData set ["state", "idle"];
                _groupData set ["currentWaypointIndex", 0];

                // Clear reinforcing/mission flags when destination reached
                if (_groupData getOrDefault ["isReinforcing", false]) then {
                    _groupData set ["isReinforcing", false];
                    _groupData set ["onMission", false];
                    ["VIRTUALIZATION", 3, format["Group %1 reached destination - clearing reinforcement flags", _groupId]] call FLO_fnc_log;
                };
            };
        };
    };
};

