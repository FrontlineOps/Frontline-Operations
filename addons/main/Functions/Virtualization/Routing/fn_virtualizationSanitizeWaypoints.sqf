/*
 * Function: FLO_fnc_virtualizationSanitizeWaypoints
 * Description:
 *   Validates and clones canonical seven-field waypoint descriptors. Route
 *   geometry is resolved separately according to the archetype domain.
 */

params [
    ["_movementDomain", "", [""]],
    ["_waypoints", [], [[]]]
];

if !(_movementDomain in ["LAND", "AIR", "WATER"]) then {
    throw format ["FLO_fnc_virtualizationSanitizeWaypoints: invalid movement domain %1", _movementDomain];
};

private _sanitizedWaypoints = [];
{
    if (!(_x isEqualType []) || {count _x != 7}) then {
        throw format ["FLO_fnc_virtualizationSanitizeWaypoints: malformed waypoint %1: %2", _forEachIndex, _x];
    };

    private _wpPos = _x select 0;
    if (!(_wpPos isEqualType []) || {!(count _wpPos in [2, 3])}) then {
        throw format ["FLO_fnc_virtualizationSanitizeWaypoints: malformed waypoint position %1: %2", _forEachIndex, _wpPos];
    };

    _sanitizedWaypoints pushBack [
        +_wpPos,
        _x select 1,
        _x select 2,
        _x select 3,
        _x select 4,
        _x select 5,
        _x select 6
    ];
} forEach _waypoints;

["ROUTE_REQUEST", _sanitizedWaypoints, 0, -1, -1, [], []] call FLO_fnc_virtualizationValidateWaypointState;

_sanitizedWaypoints
