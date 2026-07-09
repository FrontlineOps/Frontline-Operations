/*
 * Function: FLO_fnc_virtualizationRestoreEngagementState
 * Author: Frontline Operations Development Group
 * Description:
 *   Restores temporary engagement-overlay state after save/load.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 * 1: Saved group data <HASHMAP>
 *
 * Return Value:
 * BOOL - True when restore completed
 */

params ["_groupData", "_savedData"];

[_groupData] call FLO_fnc_virtualizationClearEngagementState;
if !(_savedData get "engagementActive") exitWith { true };
if ((_groupData get "missionLock") != "" || {(_groupData get "replacementState") != ""}) exitWith { true };

[
    _groupData,
    _savedData get "engagementTargetGroupId",
    _savedData get "engagementTargetPos",
    _savedData get "engagementTargetObjective",
    _savedData get "engagementReason",
    _savedData get "engagementExpiresAt",
    _savedData get "engagementLeashMeters"
] call FLO_fnc_virtualizationSetEngagementState;

true
