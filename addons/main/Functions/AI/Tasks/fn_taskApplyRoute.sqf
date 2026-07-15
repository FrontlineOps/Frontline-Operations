/*
 * Function: FLO_fnc_taskApplyRoute
 * Description:
 *   Resolves a complete physical route before installing group waypoints. LAND geometry
 *   uses the shared water-aware resolver; AIR and WATER geometry stays direct.
 */

params [
    ["_group", grpNull, [grpNull]],
    ["_waypoints", [], [[]]],
    ["_movementDomain", "LAND", [""]],
    ["_sourceTag", "PHYSICAL_ROUTE", [""]],
    ["_closeLoop", false, [true]],
    ["_allowTrails", true, [true]],
    ["_semanticTimeout", [0, 0, 0], [[]]],
    ["_landGeometryResolved", false, [true]]
];

if (isNull _group) then { throw "Physical route requires a live group"; };
if !(_movementDomain in ["LAND", "AIR", "WATER"]) then {
    throw format ["Physical route %1 has invalid movement domain %2", _sourceTag, _movementDomain];
};
if (_waypoints isEqualTo []) then {
    throw format ["Physical route %1 requires at least one waypoint", _sourceTag];
};
if (count _semanticTimeout != 3 || {_semanticTimeout findIf {!(_x isEqualType 0) || {_x < 0}} >= 0}) then {
    throw format ["Physical route %1 has invalid semantic timeout %2", _sourceTag, _semanticTimeout];
};

private _sanitized = [_movementDomain, _waypoints] call FLO_fnc_virtualizationSanitizeWaypoints;
private _resolvedWaypoints = _sanitized;
private _endpointIndexes = [];
private _routeAllowed = true;
private _routeFailureReason = "";
if (_movementDomain == "LAND") then {
    private _leader = leader _group;
    if (isNull _leader) then { throw format ["Physical LAND route %1 has no leader", _sourceTag]; };
    private _startPos = getPosATL _leader;
    if (_landGeometryResolved) then {
        private _positions = _sanitized apply { +(_x select 0) };
        if (_closeLoop
            && {count _positions > 1}
            && {(_positions select -1) distance2D (_positions select 0) > 1}) then {
            _positions pushBack +(_positions select 0);
        };
        private _validation = [_startPos, _positions] call FLO_fnc_validateWaterAwarePath;
        _routeAllowed = _validation select 0;
        if (!_routeAllowed) then {
            _routeFailureReason = format ["UNSAFE_RESOLVED_ROUTE:samples=%1", _validation select 1];
        };
        for "_i" from 0 to ((count _resolvedWaypoints) - 1) do {
            _endpointIndexes pushBack _i;
        };
    } else {
        private _routeResult = [
            _startPos,
            _sanitized,
            _allowTrails,
            _sourceTag,
            _closeLoop
        ] call FLO_fnc_virtualizationResolveLandWaypoints;
        _routeResult params ["_resolved", "_route", "_reason", "_metrics", "_semanticEndpointIndexes"];
        _routeAllowed = _resolved;
        _routeFailureReason = _reason;
        if (_resolved) then {
            _resolvedWaypoints = _route;
            _endpointIndexes = _semanticEndpointIndexes;
        };
    };
} else {
    for "_i" from 0 to ((count _resolvedWaypoints) - 1) do {
        _endpointIndexes pushBack _i;
    };
};

if (!_routeAllowed) exitWith {
    ["AI TASK", 2, format [
        "Rejected physical LAND route source=%1 group=%2 reason=%3 waypoints=%4",
        _sourceTag,
        _group,
        _routeFailureReason,
        count _sanitized
    ]] call FLO_fnc_log;
    false
};

private _firstWaypointIndex = -1;
private _lastWaypoint = [];
private _applyError = "";
[_group] call CBA_fnc_clearWaypoints;
try {
    {
        _x params [
            "_position",
            "_type",
            "_behaviour",
            "_speed",
            "_formation",
            "_combatMode",
            "_completionRadius"
        ];
        private _waypoint = if (_movementDomain == "LAND") then {
            _group addWaypoint [ATLToASL _position, -1]
        } else {
            _group addWaypoint [_position, 0]
        };
        _waypoint setWaypointType _type;
        _waypoint setWaypointBehaviour _behaviour;
        _waypoint setWaypointSpeed _speed;
        _waypoint setWaypointFormation _formation;
        _waypoint setWaypointCombatMode _combatMode;
        _waypoint setWaypointCompletionRadius _completionRadius;
        if (_forEachIndex in _endpointIndexes) then {
            _waypoint setWaypointTimeout _semanticTimeout;
        };
        if (_firstWaypointIndex < 0) then {
            _firstWaypointIndex = _waypoint select 1;
        };
        _lastWaypoint = _waypoint;
    } forEach _resolvedWaypoints;

    if (_closeLoop) then {
        _lastWaypoint setWaypointStatements [
            "true",
            format ["(group this) setCurrentWaypoint [(group this), %1];", _firstWaypointIndex]
        ];
    };
} catch {
    _applyError = _exception;
};

if (_applyError != "") then {
    [_group] call CBA_fnc_clearWaypoints;
    ["AI TASK", 1, format [
        "Physical route publication failed source=%1 group=%2 reason=%3",
        _sourceTag,
        _group,
        _applyError
    ]] call FLO_fnc_log;
    throw _applyError;
};

true
