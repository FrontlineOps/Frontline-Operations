/*
 * Function: FLO_fnc_virtualizationSetEngagementState
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies temporary commander engagement-overlay state without changing
 *   strategic commander order ownership.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 * 1: Target group ID <STRING>
 * 2: Target position <ARRAY>
 * 3: Target objective ID <STRING>
 * 4: Reason <STRING>
 * 5: Expires at <NUMBER>
 * 6: Leash meters <NUMBER>
 *
 * Return Value:
 * BOOL - True when engagement state was applied
 */

params [
    "_groupData",
    ["_targetGroupId", "", [""]],
    ["_targetPos", [], [[]]],
    ["_targetObjective", "", [""]],
    ["_reason", "", [""]],
    ["_expiresAt", -1, [0]],
    ["_leashMeters", 0, [0]]
];

private _missionLock = _groupData get "missionLock";
private _replacementState = _groupData get "replacementState";
if (_missionLock != "" || {_replacementState != ""}) then {
    throw format [
        "FLO_fnc_virtualizationSetEngagementState: cannot engage while missionLock='%1' replacementState='%2'",
        _missionLock,
        _replacementState
    ];
};

_groupData set ["engagementActive", true];
_groupData set ["engagementTargetGroupId", _targetGroupId];
_groupData set ["engagementTargetPos", _targetPos];
_groupData set ["engagementTargetObjective", _targetObjective];
_groupData set ["engagementReason", _reason];
_groupData set ["engagementExpiresAt", _expiresAt];
_groupData set ["engagementLeashMeters", _leashMeters];
[_groupData, "ENGAGING"] call FLO_fnc_virtualizationSetExecutionState;

true
