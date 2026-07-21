/*
 * Function: FLO_fnc_virtualizationNormalizeSavedLandRoute
 * Description:
 *   Rebuilds derived current-version LAND route geometry during restore when
 *   exact terrain validation rejects the saved continuation. The saved record
 *   shape must already be current and structurally valid; this only rebases
 *   canonical route waypoints from the saved authoritative group position.
 *
 * Return Value:
 *   BOOL - True when route geometry was normalized and revalidated
 */

params [
    ["_savedData", createHashMap, [createHashMap]],
    ["_groupId", "", [""]],
    ["_failureReason", "", [""]]
];

private _waypoints = _savedData get "waypoints";
if (_waypoints isEqualTo []) exitWith { false };
if (_failureReason == "START_IN_WATER") exitWith { false };

private _currentWaypointIndex = _savedData get "currentWaypointIndex";
private _loopRoute = (_savedData get "autoPatrol") || {(_savedData get "patrolConfig") isNotEqualTo []};
private _pathSource = _savedData get "pathSource";
private _sourceTag = if (_pathSource == "") then {
    "SAVE_RESTORE"
} else {
    format ["SAVE_RESTORE_%1", _pathSource]
};

private _routeResult = [
    _savedData get "position",
    _waypoints,
    _currentWaypointIndex,
    _loopRoute,
    _sourceTag
] call FLO_fnc_virtualizationResolveLandRouteContinuation;
_routeResult params ["_resolved", "_resolvedWaypoints", "_resolverReason", "_metrics", "_endpointIndexes"];

if (!_resolved || {_resolvedWaypoints isEqualTo []}) exitWith {
    ["VIRTUALIZATION", 2, format [
        "Saved LAND route normalization failed group=%1 originalReason=%2 resolverReason=%3 waypoints=%4",
        _groupId,
        _failureReason,
        _resolverReason,
        count _waypoints
    ]] call FLO_fnc_log;
    false
};

private _dismountIndex = _savedData get "dismountAtWaypoint";
if (_dismountIndex >= 0) then {
    private _remappedDismountIndex = -1;
    private _dismountOffset = _dismountIndex - _currentWaypointIndex;

    if (_loopRoute && {_dismountOffset < 0}) then {
        _dismountOffset = _dismountOffset + (count _waypoints);
    };

    if (_dismountOffset >= 0 && {_dismountOffset < count _endpointIndexes}) then {
        _remappedDismountIndex = _endpointIndexes select _dismountOffset;
    };

    if (_remappedDismountIndex < 0 && {(_savedData get "attachedGroups") isNotEqualTo []}) then {
        private _message = format [
            "Saved LAND route normalization lost transport dismount endpoint group=%1 dismount=%2 current=%3 waypoints=%4",
            _groupId,
            _dismountIndex,
            _currentWaypointIndex,
            count _waypoints
        ];
        ["VIRTUALIZATION", 1, _message] call FLO_fnc_log;
        throw _message;
    };

    _savedData set ["dismountAtWaypoint", _remappedDismountIndex];
};

_savedData set ["waypoints", _resolvedWaypoints];
_savedData set ["currentWaypointIndex", 0];

[_savedData, _groupId] call FLO_fnc_virtualizationValidateSavedGroup;
private _routeValidation = [
    _groupId,
    _savedData get "position",
    _savedData get "waypoints",
    _savedData get "currentWaypointIndex",
    _savedData get "autoPatrol",
    _savedData get "patrolConfig"
] call FLO_fnc_virtualizationValidateLandRoute;

if !(_routeValidation select 0) then {
    private _message = format [
        "Normalized saved LAND route for %1 failed exact validation: %2",
        _groupId,
        _routeValidation select 1
    ];
    ["VIRTUALIZATION", 1, _message] call FLO_fnc_log;
    throw _message;
};

["VIRTUALIZATION", 2, format [
    "Normalized saved LAND route group=%1 reason=%2 waypointsBefore=%3 waypointsAfter=%4 samples=%5",
    _groupId,
    _failureReason,
    count _waypoints,
    count _resolvedWaypoints,
    _routeValidation select 2
]] call FLO_fnc_log;

true
