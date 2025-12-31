/*
 * Function: FLO_fnc_virtualizationAdvanceWaypoint
 * Author: Frontline Operations Development Group
 * Description:
 *   Handles waypoint completion for a virtual group.
 *   Advances to next waypoint, handles CYCLE waypoints, and manages patrol logic.
 *
 *   Waypoint Types:
 *   - MOVE, SAD, DESTROY: Normal movement, completes when within completion radius
 *   - CYCLE: Loops back to first waypoint
 *   - SENTRY: Holds position in defending state
 *   - LOITER: Stays at position for timeout duration
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

    // SENTRY - hold position
    case "SENTRY": {
        _groupData set ["lastSentryTime", diag_tickTime];
        _groupData set ["state", "defending"];
    };

    // LOITER - stay in area
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

    // Default movement waypoints
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

