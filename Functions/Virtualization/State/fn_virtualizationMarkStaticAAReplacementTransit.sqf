/*
 * Function: FLO_fnc_virtualizationMarkStaticAAReplacementTransit
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies the canonical transit state for a logistics-created static AA deployment.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 * 1: Target position <ARRAY>
 * 2: Requested objective ID <STRING>
 * 3: Delivery objective ID <STRING>
 *
 * Return Value:
 * BOOL - True when the state was applied
 */

params ["_groupData", "_targetPos", "_requestedObjectiveId", "_deliveryObjectiveId"];

[_groupData] call FLO_fnc_virtualizationClearCommanderOrder;
[_groupData] call FLO_fnc_virtualizationClearExecutionState;
_groupData set ["replacementState", "AA_DEPLOY"];
[_groupData, "LOGISTICS", "AA_DEPLOY"] call FLO_fnc_virtualizationSetMissionLock;
_groupData set ["reinforcementTargetPos", _targetPos];
_groupData set ["reinforcementRequestedObjective", _requestedObjectiveId];
_groupData set ["reinforcementDeliveryObjective", _deliveryObjectiveId];
[_groupData, "MOVING", _targetPos, _deliveryObjectiveId, true] call FLO_fnc_virtualizationSetAADeployState;

true
