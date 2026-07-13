/*
 * Function: FLO_fnc_virtualizationProcessInactiveMovement
 */

params [
    "_groupId",
    "_groupData",
    "_now",
    "_virtStats",
    ["_profilePhases", false, [false]]
];

if ((_groupData get "state") == "holding") exitWith {
    if (_profilePhases) then {
        _virtStats set ["phaseHoldingSkipsTotal", (_virtStats get "phaseHoldingSkipsTotal") + 1];
    };
    true
};

private _waypoints = _groupData get "waypoints";
private _currentWpIdx = _groupData get "currentWaypointIndex";

if (_waypoints isNotEqualTo [] && {_currentWpIdx < count _waypoints}) then {
    private _position = _groupData get "position";
    private _wp = _waypoints select _currentWpIdx;
    private _wpPos = _wp select 0;
    private _wpType = _wp select 1;
    private _virtualSpeed = _groupData get "virtualSpeed";
    private _lastMove = _groupData get "lastMoveTime";
    private _carryMeters = _groupData get "virtualMoveCarryMeters";
    private _moveNow = diag_tickTime;
    private _timeDelta = (_moveNow - _lastMove) max 0;
    private _distToWp = _position distance2D _wpPos;
    private _completionRadius = _wp param [6, 20];

    if (_wpType in ["MOVE", "LOITER", "SAD", "DESTROY", "SENTRY", "CYCLE", "GUARD", "HOLD"] && {_distToWp > _completionRadius}) then {
        private _pendingMoveDistance = _carryMeters + (_virtualSpeed * _timeDelta);
        _groupData set ["lastMoveTime", _moveNow];

        if (_pendingMoveDistance > 0) then {
            private _moveDistance = _pendingMoveDistance min _distToWp;
            private _deadbandMeters = ["movementDeadbandMeters"] call FLO_fnc_virtualizationGetConfigValue;

            if (_moveDistance < _deadbandMeters && {_moveDistance < _distToWp}) then {
                _groupData set ["virtualMoveCarryMeters", _pendingMoveDistance];
                _virtStats set ["movementDeadbandSkipsTotal", (_virtStats get "movementDeadbandSkipsTotal") + 1];
                _virtStats set ["movementDeadbandSkipsThisBatch", (_virtStats get "movementDeadbandSkipsThisBatch") + 1];
            } else {
                private _dir = _position getDir _wpPos;
                private _newPos = _position getPos [_moveDistance, _dir];

                private _phaseStart = 0;
                if (_profilePhases) then { _phaseStart = diag_tickTime; };
                [_groupId, _groupData, _newPos] call FLO_fnc_virtualizationUpdateOwnedGroupPosition;
                if (_profilePhases) then {
                    _virtStats set ["phasePositionUpdateMsTotal", (_virtStats get "phasePositionUpdateMsTotal") + ((diag_tickTime - _phaseStart) * 1000)];
                    _virtStats set ["phasePositionUpdatesTotal", (_virtStats get "phasePositionUpdatesTotal") + 1];
                };
                _groupData set ["virtualMoveCarryMeters", (_pendingMoveDistance - _moveDistance) max 0];
                [_groupData, "moving"] call FLO_fnc_virtualizationSetRuntimeState;
                _virtStats set ["virtualMovesTotal", (_virtStats get "virtualMovesTotal") + 1];
                _virtStats set ["virtualMovesThisBatch", (_virtStats get "virtualMovesThisBatch") + 1];

                if (_profilePhases) then { _phaseStart = diag_tickTime; };
                [_groupId, _groupData, _newPos] call FLO_fnc_transportProcessVirtualCarrier;
                if (_profilePhases) then {
                    _virtStats set ["phaseCarrierSyncMsTotal", (_virtStats get "phaseCarrierSyncMsTotal") + ((diag_tickTime - _phaseStart) * 1000)];
                };
            };
        };
    } else {
        if (_distToWp <= _completionRadius) then {
            [_groupId, _groupData, _currentWpIdx, _waypoints] call FLO_fnc_virtualizationAdvanceWaypoint;
            _virtStats set ["waypointAdvancesTotal", (_virtStats get "waypointAdvancesTotal") + 1];
            _virtStats set ["waypointAdvancesThisBatch", (_virtStats get "waypointAdvancesThisBatch") + 1];
        };
    };
} else {
    if ([_groupId] call FLO_fnc_virtualizationAssignAutoPatrol) then {
        _virtStats set ["patrolAssignmentsTotal", (_virtStats get "patrolAssignmentsTotal") + 1];
        _virtStats set ["patrolAssignmentsThisBatch", (_virtStats get "patrolAssignmentsThisBatch") + 1];
    };
};

true
