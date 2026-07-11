/*
 * Function: FLO_fnc_civilianBuildAmbientRoute
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds a short believable civilian ambient route around one objective.
 *
 * Arguments:
 * 0: Objective ID <STRING>
 * 1: Civilian role <STRING>
 * 2: Anchor position <ARRAY>
 *
 * Return Value:
 * HASHMAP - ["anchors", <ARRAY>] ["waypoints", <ARRAY>]
 */

params [
    ["_objectiveId", "", [""]],
    ["_role", "resident", [""]],
    ["_anchorPos", [0, 0, 0], [[]], [3]]
];

private _route = createHashMapFromArray [
    ["anchors", [+_anchorPos]],
    ["waypoints", []]
];

if (_objectiveId == "" || {!(_objectiveId in FLO_Objectives)}) exitWith { _route };
if (_role in ["watcher", "vendor"]) exitWith { _route };

private _objective = FLO_Objectives get _objectiveId;
private _objectivePos = _objective get "position";
private _objectiveRadius = (_objective get "radius") max 60;
private _searchRadius = ((_objectiveRadius + 60) min 220) max 90;

private _roadPositions = [];
{
    private _roadPos = getPos _x;
    _roadPos set [2, 0];
    if ((_roadPos distance2D _objectivePos) > _searchRadius) then { continue };
    _roadPositions pushBackUnique _roadPos;
    if ((count _roadPositions) >= 12) exitWith {};
} forEach (_objectivePos nearRoads _searchRadius);

private _ambientPoints = [];
if (_roadPositions isNotEqualTo []) then {
    _ambientPoints = _roadPositions call BIS_fnc_arrayShuffle;
} else {
    for "_i" from 1 to 8 do {
        private _point = [_objectiveId, true] call FLO_fnc_getRandomObjectivePos;
        if (_point isNotEqualTo [0, 0, 0]) then {
            _ambientPoints pushBackUnique _point;
        };
    };
};

private _pointCount = switch (_role) do {
    case "worker": { 3 };
    case "wanderer": { 5 };
    default { 2 };
};

private _anchors = [+_anchorPos];
{
    if ((count _anchors) >= (_pointCount + 1)) exitWith {};
    if ((_x distance2D _anchorPos) < 15) then { continue };
    _anchors pushBack _x;
} forEach _ambientPoints;

if ((count _anchors) < 2) exitWith { _route };

private _waypoints = [];
{
    _waypoints pushBack [_x, "MOVE", "SAFE", "LIMITED", "FILE", "WHITE", 4];
} forEach (_anchors select [1]);
_waypoints pushBack [_anchors select 1, "CYCLE", "SAFE", "LIMITED", "FILE", "WHITE", 4];

_route set ["anchors", _anchors];
_route set ["waypoints", _waypoints];
_route
