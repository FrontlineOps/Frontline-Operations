/*
 * Function: FLO_fnc_civilianSelectObjectiveProtesters
 * Author: Frontline Operations Development Group
 * Description:
 *   Selects active civilian groups in one objective to temporarily repurpose
 *   into a protest crowd.
 *
 * Arguments:
 * 0: Objective ID <STRING>
 * 1: Target player <OBJECT>
 * 2: Maximum group count <NUMBER>
 *
 * Return Value:
 * ARRAY - Selected civilian group IDs
 */

params [
    ["_objectiveId", "", [""]],
    ["_targetPlayer", objNull, [objNull]],
    ["_maxGroups", 3, [0]]
];

if (_objectiveId == "" || {isNull _targetPlayer} || {!alive _targetPlayer}) exitWith { [] };

private _groups = FLO_virtualGroups get "_groups";
private _targetPos = getPosATL _targetPlayer;
private _candidates = [];

{
    private _groupId = _x;
    private _groupData = _y;

    if ((_groupData get "side") != civilian) then { continue };
    if ((_groupData get "civilianObjective") != _objectiveId) then { continue };
    if !(_groupData get "isActive") then { continue };
    if ((_groupData get "groupType") in ["civilianVehicle", "civ_car"]) then { continue };
    if ((_groupData get "civilianRoutineState") == "protest" && {diag_tickTime < (_groupData get "civilianRoutineUntil")}) then { continue };

    private _realGroup = _groupData get "realGroup";
    if (isNull _realGroup) then { continue };

    private _eligibleUnits = units _realGroup select { alive _x && {!captive _x} && {isNull objectParent _x} };
    if (_eligibleUnits isEqualTo []) then { continue };

    private _leader = _eligibleUnits select 0;
    private _distance = _targetPos distance2D (getPosATL _leader);
    _candidates pushBack [_groupId, _distance];
} forEach _groups;

_candidates = [_candidates, [], { _x select 1 }, "ASCEND"] call BIS_fnc_sortBy;
(_candidates apply { _x select 0 }) select [0, _maxGroups min count _candidates]
