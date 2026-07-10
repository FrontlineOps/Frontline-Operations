/*
 * Function: FLO_fnc_virtualizationAssignAttackOrder
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies canonical commander attack-order state to a virtual group.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 * 1: Target position <ARRAY>
 * 2: Objective ID <STRING>
 * 3: Campaign operation ID <STRING>
 *
 * Return Value:
 * BOOL - True when the state was applied
 */

params ["_groupData", "_targetPos", "_objectiveId", "_campaignOperationId"];

if (_objectiveId == "" || {_campaignOperationId == ""}) then {
    throw format [
        "FLO_fnc_virtualizationAssignAttackOrder: objective and operation are required (%1, %2)",
        _objectiveId,
        _campaignOperationId
    ];
};

private _missionLock = _groupData get "missionLock";
private _replacementState = _groupData get "replacementState";
if (_missionLock != "" || {_replacementState != ""}) then {
    throw format [
        "FLO_fnc_virtualizationAssignAttackOrder: cannot assign ATTACK while missionLock='%1' replacementState='%2'",
        _missionLock,
        _replacementState
    ];
};

[_groupData] call FLO_fnc_virtualizationClearCommanderOrder;
[_groupData, "ATTACK"] call FLO_fnc_virtualizationSetCommanderOrder;
_groupData set ["attackObjective", _objectiveId];
_groupData set ["campaignOperationId", _campaignOperationId];
_groupData set ["orderTargetPos", _targetPos];
_groupData set ["orderMode", "COMBAT"];

true
