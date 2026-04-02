/*
 * Function: FLO_fnc_civilianApplyRoutinePlan
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies one planned civilian routine onto virtual-group state and route
 *   storage, updating the active group route when needed.
 *
 * Arguments:
 * 0: Group ID <STRING>
 * 1: Group data <HASHMAP>
 * 2: Routine plan <HASHMAP>
 *
 * Return Value:
 * BOOL - True when a plan was applied
 */

params [
    ["_groupId", "", [""]],
    ["_groupData", createHashMap, [createHashMap]],
    ["_plan", createHashMap, [createHashMap]]
];

if (_groupId == "" || {(count (keys _plan)) == 0}) exitWith { false };

private _state = _plan get "state";
private _homeAnchorPos = _plan get "homeAnchorPos";
private _anchorPos = _plan get "anchorPos";
private _routeAnchors = _plan get "routeAnchors";
private _waypoints = _plan get "waypoints";
private _until = _plan get "until";
private _mood = _plan get "mood";
private _source = _plan get "source";

_groupData set ["civilianRoutineState", _state];
_groupData set ["civilianLastRoutineAt", diag_tickTime];
_groupData set ["civilianRoutineUntil", _until];
_groupData set ["civilianLastMood", _mood];
_groupData set ["civilianHomeAnchorPos", _homeAnchorPos];
_groupData set ["civilianRoutineAnchorPos", _anchorPos];
_groupData set ["civilianAnchorPos", _anchorPos];
_groupData set ["civilianRouteAnchors", _routeAnchors];

if !(_groupData get "isActive") then {
    [FLO_virtualGroups, _groupId, _anchorPos] call FLO_fnc_virtualizationUpdateGroupPosition;
};

if ((count _waypoints) > 0) then {
    _groupData set ["noWaypoints", false];
    [_groupId, _waypoints, false, true, _source] call FLO_fnc_updateVirtualGroupWaypoints;
} else {
    [_groupData] call FLO_fnc_virtualizationClearPathRequest;
    _groupData set ["waypoints", []];
    _groupData set ["currentWaypointIndex", 0];
    _groupData set ["noWaypoints", true];
    [_groupData, "idle"] call FLO_fnc_virtualizationSetRuntimeState;

    if (_groupData get "isActive") then {
        [_groupId, _groupData] call FLO_fnc_virtualizationApplyRealRoute;
    };
};

private _realGroup = _groupData get "realGroup";
if (!isNull _realGroup) then {
    {
        _x setVariable ["FLO_CivilianRoutineState", _state, true];
    } forEach units _realGroup;
};

true
