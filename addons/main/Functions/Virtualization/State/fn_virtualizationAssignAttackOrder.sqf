/* Applies canonical direct ATTACK state to a virtual group. */
params ["_groupData", "_targetPos", "_objectiveId"];

if (_objectiveId == "") then {
    throw "FLO_fnc_virtualizationAssignAttackOrder: objective is required";
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
_groupData set ["orderTargetPos", _targetPos];
_groupData set ["orderMode", "COMBAT"];
true
