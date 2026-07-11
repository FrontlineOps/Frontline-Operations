/*
 * Function: FLO_fnc_virtualizationClearEngagementState
 * Author: Frontline Operations Development Group
 * Description:
 *   Clears temporary commander engagement-overlay state.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 *
 * Return Value:
 * BOOL - True when engagement state was cleared
 */

params ["_groupData"];

_groupData set ["engagementActive", false];
_groupData set ["engagementTargetGroupId", ""];
_groupData set ["engagementTargetPos", []];
_groupData set ["engagementTargetObjective", ""];
_groupData set ["engagementReason", ""];
_groupData set ["engagementExpiresAt", -1];
_groupData set ["engagementLeashMeters", 0];

if ((_groupData get "executionState") == "ENGAGING") then {
    [_groupData] call FLO_fnc_virtualizationClearExecutionState;
};

true
