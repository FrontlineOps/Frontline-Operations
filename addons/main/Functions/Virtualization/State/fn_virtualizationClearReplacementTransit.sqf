/*
 * Function: FLO_fnc_virtualizationClearReplacementTransit
 * Author: Frontline Operations Development Group
 * Description:
 *   Clears canonical logistics transit state once the replacement is no longer in transit.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 * 1: Next execution state <STRING> - Default ""
 *
 * Return Value:
 * BOOL - True when the state was cleared
 */

params ["_groupData", ["_nextExecutionState", ""]];

[_groupData] call FLO_fnc_virtualizationClearCommanderOrder;
[_groupData] call FLO_fnc_virtualizationClearExecutionState;
[_groupData] call FLO_fnc_virtualizationClearMissionLock;
_groupData set ["replacementState", ""];
_groupData set ["reinforcementTargetPos", []];
_groupData set ["reinforcementRequestedObjective", ""];
_groupData set ["reinforcementDeliveryObjective", ""];
if (_nextExecutionState != "") then {
    [_groupData, _nextExecutionState] call FLO_fnc_virtualizationSetExecutionState;
};

true
