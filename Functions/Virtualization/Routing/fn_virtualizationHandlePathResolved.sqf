/*
 * Function: FLO_fnc_virtualizationHandlePathResolved
 */

params ["_resolved", "_posArray", "_args"];

_args params ["_groupId", "_waypointSettings", "_requestToken"];

private _groupData = (FLO_virtualGroups get "_groups") get _groupId;
if (isNil "_groupData") exitWith {};
if ((_groupData get "pathToken") != _requestToken) exitWith {};

private _wpType = _waypointSettings select 1;
private _wpBehavior = _waypointSettings select 2;
private _wpSpeed = _waypointSettings select 3;
private _wpFormation = _waypointSettings select 4;
private _wpMode = _waypointSettings select 5;
private _wpCompletionRadius = _waypointSettings select 6;
private _resolvedPositions = +_posArray;
private _newWaypoints = [];

{
    private _wpPos = _x;
    if (surfaceIsWater _wpPos) then {
        _wpPos = [_wpPos, 300] call FLO_fnc_getSafeLandPos;
    };
    _newWaypoints pushBack [_wpPos, _wpType, _wpBehavior, _wpSpeed, _wpFormation, _wpMode, _wpCompletionRadius];
} forEach _resolvedPositions;

[_groupData, _newWaypoints, _groupData get "pathSource", "moving"] call FLO_fnc_virtualizationSetRouteState;

["VIRTUALIZATION", 3, format ["Pathfinding resolved for group %1 with %2 waypoints", _groupId, count _newWaypoints]] call FLO_fnc_log;

if (_groupData get "isActive") then {
    [_groupId, _groupData] call FLO_fnc_virtualizationApplyRealRoute;
};
