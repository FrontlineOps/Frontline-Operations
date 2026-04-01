/*
 * Function: FLO_fnc_virtualizationProcessInactiveMovement
 */

params ["_groupId", "_groupData", "_now", "_virtStats", ["_speedMultiplier", 1, [0]]];

private _waypoints = _groupData get "waypoints";
private _currentWpIdx = _groupData get "currentWaypointIndex";

if (count _waypoints > 0 && {_currentWpIdx < count _waypoints}) then {
    private _position = _groupData get "position";
    private _wp = _waypoints select _currentWpIdx;
    private _wpPos = _wp select 0;
    private _wpType = _wp select 1;
    private _virtualSpeed = (_groupData get "virtualSpeed") * _speedMultiplier;
    private _lastMove = _groupData get "lastMoveTime";
    private _timeDelta = _now - _lastMove;
    private _distToWp = _position distance2D _wpPos;
    private _completionRadius = _wp param [6, 20];

    if (_wpType in ["MOVE", "LOITER", "SAD", "DESTROY", "SENTRY", "CYCLE", "GUARD"] && {_distToWp > _completionRadius}) then {
        private _moveDistance = (_virtualSpeed * _timeDelta) min _distToWp;
        private _dir = _position getDir _wpPos;
        private _newPos = _position getPos [_moveDistance, _dir];

        [FLO_virtualGroups, _groupId, _newPos] call FLO_fnc_virtualizationUpdateGroupPosition;
        _groupData set ["lastMoveTime", _now];
        [_groupData, "moving"] call FLO_fnc_virtualizationSetRuntimeState;
        _virtStats set ["virtualMovesTotal", (_virtStats get "virtualMovesTotal") + 1];
        _virtStats set ["virtualMovesThisBatch", (_virtStats get "virtualMovesThisBatch") + 1];

        [_groupId, _groupData, _newPos] call FLO_fnc_transportProcessVirtualCarrier;
    } else {
        if (_distToWp <= _completionRadius) then {
            [_groupId, _groupData, _currentWpIdx, _waypoints] call FLO_fnc_virtualizationAdvanceWaypoint;
            _virtStats set ["waypointAdvancesTotal", (_virtStats get "waypointAdvancesTotal") + 1];
            _virtStats set ["waypointAdvancesThisBatch", (_virtStats get "waypointAdvancesThisBatch") + 1];
        };
    };
} else {
    if ([_groupId, _groupData] call FLO_fnc_virtualizationAssignAutoPatrol) then {
        _virtStats set ["patrolAssignmentsTotal", (_virtStats get "patrolAssignmentsTotal") + 1];
        _virtStats set ["patrolAssignmentsThisBatch", (_virtStats get "patrolAssignmentsThisBatch") + 1];
    };
};

true
