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

if (count _waypoints == 0 || _currentIdx >= count _waypoints) exitWith {
    [_groupData, "idle"] call FLO_fnc_virtualizationSetRuntimeState;
    _groupData set ["currentWaypointIndex", 0];
};

private _currentWp = _waypoints select _currentIdx;
private _wpType = _currentWp select 1;
// Patrol detection - check autoPatrol flag or patrolConfig (no longer rely on CYCLE waypoints)
private _isPatrol = (_groupData getOrDefault ["autoPatrol", false]) ||
                    (_groupData getOrDefault ["patrolConfig", []] isNotEqualTo []);

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
        // Check if this is the last waypoint
        private _isLastWp = (_currentIdx >= (count _waypoints - 1));

        if (_isLastWp) then {
            // Final attack waypoint - stay here holding. Effective attacking
            // posture is derived from commanderOrder.
            [_groupData, "holding"] call FLO_fnc_virtualizationSetRuntimeState;
            ["VIRTUALIZATION", 4, format["Group %1 reached final %2 waypoint - entering holding state", _groupId, _wpType]] call FLO_fnc_log;
        } else {
            // More waypoints to go - advance to next
            _waypoints deleteAt _currentIdx;
            _groupData set ["waypoints", _waypoints];
            _groupData set ["currentWaypointIndex", _currentIdx min (count _waypoints - 1)];
            [_groupData, "moving"] call FLO_fnc_virtualizationSetRuntimeState;
            ["VIRTUALIZATION", 4, format["Group %1 completed %2 waypoint - advancing to next", _groupId, _wpType]] call FLO_fnc_log;
        };
    };

    // GUARD/HOLD - defend waypoints
    // Virtual groups advance through these to reach their destination
    // Only enter persistent holding when this is the LAST waypoint
    case "GUARD";
    case "HOLD": {
        // Check if this is the last waypoint
        private _isLastWp = (_currentIdx >= (count _waypoints - 1));

        if (_isLastWp) then {
            // Final defend waypoint - stay here holding. Effective defending
            // posture is derived from commanderOrder.
            [_groupData, "holding"] call FLO_fnc_virtualizationSetRuntimeState;
            ["VIRTUALIZATION", 4, format["Group %1 reached final %2 waypoint - entering holding state", _groupId, _wpType]] call FLO_fnc_log;
        } else {
            // More waypoints to go - advance to next
            _waypoints deleteAt _currentIdx;
            _groupData set ["waypoints", _waypoints];
            _groupData set ["currentWaypointIndex", _currentIdx min (count _waypoints - 1)];
            [_groupData, "moving"] call FLO_fnc_virtualizationSetRuntimeState;
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
                if (_isPatrol) then {
                    _nextIdx = 0;
                } else {
                    _nextIdx = 0;
                    [_groupData, "idle"] call FLO_fnc_virtualizationSetRuntimeState;
                };
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
                [_groupData, "moving"] call FLO_fnc_virtualizationSetRuntimeState;
            } else {
                private _commanderOrder = _groupData get "commanderOrder";
                private _replacementState = _groupData get "replacementState";
                private _holdAtDestination = _commanderOrder in ["ATTACK", "DEFEND"] || {([_groupData] call FLO_fnc_virtualizationGetAADeployState) == "DEPLOYED"};
                [_groupData, if (_replacementState != "") then { "moving" } else { if (_holdAtDestination) then { "holding" } else { "idle" } }] call FLO_fnc_virtualizationSetRuntimeState;
                _groupData set ["currentWaypointIndex", 0];

                // Clear reinforcing/mission flags when destination reached
                if (_replacementState == "REINFORCE") then {
                    [_groupId, _groupData] call FLO_fnc_virtualizationFinalizeReinforcement;
                };
            };
        };
    };
};

