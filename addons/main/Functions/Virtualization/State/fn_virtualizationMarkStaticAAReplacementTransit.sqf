/*
 * Function: FLO_fnc_virtualizationMarkStaticAAReplacementTransit
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies the canonical transit state for a logistics-created static AA deployment.
 *
 * Arguments:
 * 0: Group ID <STRING>
 * 1: Target position <ARRAY>
 * 2: Requested objective ID <STRING>
 * 3: Delivery objective ID <STRING>
 *
 * Return Value:
 * BOOL - True when the state was applied
 */

params ["_groupId", "_targetPos", "_requestedObjectiveId", "_deliveryObjectiveId"];

private _groupData = [_groupId] call FLO_fnc_virtualizationRequireGroup;
private _candidate = [_groupData] call FLO_fnc_virtualizationCloneValue;

[_candidate] call FLO_fnc_virtualizationClearCommanderOrder;
[_candidate] call FLO_fnc_virtualizationClearExecutionState;
_candidate set ["replacementState", "AA_DEPLOY"];
[_candidate, "LOGISTICS", "AA_DEPLOY"] call FLO_fnc_virtualizationSetMissionLock;
_candidate set ["reinforcementTargetPos", _targetPos];
_candidate set ["reinforcementRequestedObjective", _requestedObjectiveId];
_candidate set ["reinforcementDeliveryObjective", _deliveryObjectiveId];
[_candidate, "MOVING", _targetPos, _deliveryObjectiveId, true] call FLO_fnc_virtualizationSetAADeployState;

_candidate set ["nextProcessAt", 0];
[_candidate, _groupId] call FLO_fnc_virtualizationValidateGroup;
{
    _groupData set [_x, _y];
} forEach _candidate;
call FLO_fnc_virtualizationTouchRegistry;
[
    "FLO_Virtualization_GroupPatched",
    [_groupId, ["replacementState", "missionLock"]]
] call CBA_fnc_localEvent;

true
