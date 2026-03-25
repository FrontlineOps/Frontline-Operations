/*
 * Function: FLO_fnc_gtnAdjustEngagementTargetAssignment
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies a reservation delta for one opportunistic engagement target
 *   within the current commander cycle.
 *
 * Arguments:
 * 0: Assignment state <HASHMAP>
 * 1: Target group ID <STRING>
 * 2: Count delta <NUMBER>
 * 3: Load delta <NUMBER>
 *
 * Return Value:
 * BOOL - True when assignment state changed
 */

params ["_assignmentState", "_targetGroupId", "_countDelta", "_loadDelta"];

if (_targetGroupId == "") exitWith { false };

private _entry = if (_targetGroupId in (keys _assignmentState)) then {
    _assignmentState get _targetGroupId
} else {
    createHashMapFromArray [
        ["count", 0],
        ["load", 0]
    ]
};

private _newCount = ((_entry get "count") + _countDelta) max 0;
private _newLoad = ((_entry get "load") + _loadDelta) max 0;

if (_newCount <= 0 && {_newLoad <= 0}) then {
    _assignmentState deleteAt _targetGroupId;
} else {
    _entry set ["count", _newCount];
    _entry set ["load", _newLoad];
    _assignmentState set [_targetGroupId, _entry];
};

true
