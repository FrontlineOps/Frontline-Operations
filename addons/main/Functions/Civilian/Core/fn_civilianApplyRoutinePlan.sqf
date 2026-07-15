/*
 * Function: FLO_fnc_civilianApplyRoutinePlan
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies one planned civilian routine onto virtual-group state and route
 *   storage, updating the active group route when needed.
 *
 * Arguments:
 * 0: Group ID <STRING>
 * 1: Routine plan <HASHMAP>
 *
 * Return Value:
 * BOOL - True when a plan was applied
 */

params [
    ["_groupId", "", [""]],
    ["_plan", createHashMap, [createHashMap]]
];

if (_groupId == "" || {(keys _plan) isEqualTo []}) exitWith { false };
private _groupData = [_groupId] call FLO_fnc_virtualizationGetGroup;

private _state = _plan get "state";
private _homeAnchorPos = _plan get "homeAnchorPos";
private _anchorPos = _plan get "anchorPos";
private _routeAnchors = _plan get "routeAnchors";
private _waypoints = _plan get "waypoints";
private _until = _plan get "until";
private _mood = _plan get "mood";
private _source = _plan get "source";

if !([_groupId, _waypoints, true, _source] call FLO_fnc_updateVirtualGroupWaypoints) exitWith {
    false
};

private _changes = createHashMapFromArray [
    ["civilianRoutineState", _state],
    ["civilianLastRoutineAt", diag_tickTime],
    ["civilianRoutineUntil", _until],
    ["civilianLastMood", _mood],
    ["civilianHomeAnchorPos", _homeAnchorPos],
    ["civilianRoutineAnchorPos", _anchorPos],
    ["civilianAnchorPos", _anchorPos],
    ["civilianRouteAnchors", _routeAnchors],
    ["noWaypoints", _waypoints isEqualTo []]
];
[_groupId, _changes] call FLO_fnc_virtualizationPatchGroup;

private _realGroup = _groupData get "realGroup";
if (!isNull _realGroup) then {
    {
        _x setVariable ["FLO_CivilianRoutineState", _state, true];
    } forEach units _realGroup;
};

true
