/*
 * Function: FLO_fnc_virtualizationCaptureRealGroupWaypoints
 * Description:
 *   Captures the remaining physical route and restores the canonical LAND
 *   invariant before the group becomes virtual.
 */

params ["_groupId", "_groupData", "_realGroup"];

private _existingWaypoints = _groupData get "waypoints";
private _existingCycle = _existingWaypoints findIf { toUpper (_x select 1) == "CYCLE" };
private _isLoopRoute = (_groupData get "autoPatrol") || {(_groupData get "patrolConfig") isNotEqualTo []} || {_existingCycle >= 0};
private _archetype = [_groupData get "groupType"] call FLO_fnc_virtualizationGetArchetype;
if (_isLoopRoute) exitWith {
    if ((_archetype get "movementDomain") != "LAND") exitWith { true };

    private _movementWaypoints = _existingWaypoints select { toUpper (_x select 1) != "CYCLE" };
    if (_movementWaypoints isEqualTo []) then {
        throw format ["Physical LAND loop for %1 has no movement waypoints", _groupId];
    };

    private _realWaypoints = waypoints _realGroup;
    private _realCurrentIndex = currentWaypoint _realGroup;
    private _routeIndex = 0;
    if (_realWaypoints isNotEqualTo [] && {_realCurrentIndex < count _realWaypoints}) then {
        private _realTargetPos = waypointPosition [_realGroup, _realCurrentIndex];
        private _matchingIndexes = [];
        {
            if (((_x select 0) distance2D _realTargetPos) < 1) then {
                _matchingIndexes pushBack _forEachIndex;
            };
        } forEach _movementWaypoints;

        private _expectedOffset = (count _realWaypoints) - (count _movementWaypoints);
        private _expectedIndex = _realCurrentIndex - _expectedOffset;
        if (_expectedIndex in _matchingIndexes) then {
            _routeIndex = _expectedIndex;
        } else {
            if (_matchingIndexes isNotEqualTo []) then {
                _routeIndex = _matchingIndexes select 0;
            } else {
                if (_realCurrentIndex != 0) then {
                    ["VIRTUALIZATION", 1, format [
                        "Physical LAND loop target no longer matches authoritative route group=%1 target=%2",
                        _groupId,
                        _realTargetPos
                    ]] call FLO_fnc_log;
                    throw format ["Physical LAND loop target mismatch for %1", _groupId];
                };
            };
        };
    };

    private _routeResult = [
        _groupData get "position",
        _existingWaypoints,
        _routeIndex,
        true,
        "PHYSICAL_LOOP_CAPTURE"
    ] call FLO_fnc_virtualizationResolveLandRouteContinuation;
    _routeResult params ["_resolved", "_resolvedWaypoints", "_reason"];
    if (!_resolved) then {
        ["VIRTUALIZATION", 1, format ["Could not rebase physical LAND loop for %1: %2", _groupId, _reason]] call FLO_fnc_log;
        throw format ["Physical LAND loop rebase failed for %1", _groupId];
    };

    _groupData set ["waypoints", _resolvedWaypoints];
    _groupData set ["currentWaypointIndex", 0];
    _groupData set ["pathSource", "PHYSICAL_LOOP_CAPTURE"];
    _groupData set ["lastMoveTime", diag_tickTime];
    _groupData set ["virtualMoveCarryMeters", 0];
    [_groupData] call FLO_fnc_virtualizationRefreshCurrentWaypointSpeed;
    true
};

private _realWaypoints = waypoints _realGroup;
private _currentWpIndex = currentWaypoint _realGroup;
private _savedWaypoints = [];
private _authoritativeWaypoints = _existingWaypoints select { toUpper (_x select 1) != "CYCLE" };
private _authoritativeCursor = 0;

if (_realWaypoints isNotEqualTo [] && {_currentWpIndex < count _realWaypoints}) then {
    for "_i" from _currentWpIndex to (count _realWaypoints - 1) do {
        private _wp = [_realGroup, _i];
        private _wpPos = waypointPosition _wp;

        if ([_wpPos] call FLO_fnc_validateGroupPosition) then {
            private _savedWaypoint = [
                _wpPos,
                waypointType _wp,
                waypointBehaviour _wp,
                waypointSpeed _wp,
                waypointFormation _wp,
                waypointCombatMode _wp,
                waypointCompletionRadius _wp
            ];

            private _matchedIndex = -1;
            if (_authoritativeCursor < count _authoritativeWaypoints) then {
                for "_candidateIndex" from _authoritativeCursor to (count _authoritativeWaypoints - 1) do {
                    private _candidate = _authoritativeWaypoints select _candidateIndex;
                    if (((_candidate select 0) distance2D _wpPos) < 1) exitWith {
                        _matchedIndex = _candidateIndex;
                    };
                };
            };

            if (_matchedIndex >= 0) then {
                _savedWaypoint = +(_authoritativeWaypoints select _matchedIndex);
                _savedWaypoint set [0, +_wpPos];
                _authoritativeCursor = _matchedIndex + 1;
            };

            _savedWaypoints pushBack _savedWaypoint;
        };
    };
};

if (_savedWaypoints isNotEqualTo []) exitWith {
    private _capturedRoute = _savedWaypoints;
    private _endpointIndexes = [];
    if ((_archetype get "movementDomain") == "LAND") then {
        private _routeResult = [
            _groupData get "position",
            _savedWaypoints,
            true,
            "PHYSICAL_CAPTURE",
            false
        ] call FLO_fnc_virtualizationResolveLandWaypoints;
        _routeResult params ["_resolved", "_resolvedWaypoints", "_reason", "_metrics", "_resolvedEndpointIndexes"];
        if (!_resolved) then {
            ["VIRTUALIZATION", 1, format ["Could not capture a water-safe route for %1: %2", _groupId, _reason]] call FLO_fnc_log;
            throw format ["FLO_fnc_virtualizationCaptureRealGroupWaypoints: no land route for %1", _groupId];
        };
        _capturedRoute = _resolvedWaypoints;
        _endpointIndexes = _resolvedEndpointIndexes;
    };

    private _dismountIndex = _groupData get "dismountAtWaypoint";
    if (_dismountIndex >= 0) then {
        private _insertPos = _groupData get "transportInsertPos";
        if (count _insertPos < 2) then { _insertPos = _groupData get "reinforcementTargetPos"; };
        private _semanticInsertIndex = _savedWaypoints findIf { ((_x select 0) distance2D _insertPos) < 1 };
        if (_semanticInsertIndex < 0) then {
            throw format ["Physical route capture for %1 lost its transport insert endpoint", _groupId];
        };
        _dismountIndex = if (_endpointIndexes isEqualTo []) then {
            _semanticInsertIndex
        } else {
            _endpointIndexes select _semanticInsertIndex
        };
        _groupData set ["dismountAtWaypoint", _dismountIndex];
    };

    _groupData set ["waypoints", _capturedRoute];
    _groupData set ["currentWaypointIndex", 0];
    ["VIRTUALIZATION", 4, format ["Captured %1 remaining waypoints from real group %2", count _capturedRoute, _groupId]] call FLO_fnc_log;
    true
};

if (_realWaypoints isNotEqualTo [] && {_currentWpIndex >= count _realWaypoints}) then {
    _groupData set ["waypoints", []];
    _groupData set ["currentWaypointIndex", 0];
    _groupData set ["dismountAtWaypoint", -1];
    ["VIRTUALIZATION", 4, format ["Group %1 completed all waypoints - clearing virtual waypoints", _groupId]] call FLO_fnc_log;
};

false
