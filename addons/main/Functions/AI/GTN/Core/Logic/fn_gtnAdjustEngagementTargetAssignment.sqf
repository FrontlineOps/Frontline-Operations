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

private _entry = _assignmentState getOrDefault [_targetGroupId, [0, 0]];
private _newCount = ((_entry select 0) + _countDelta) max 0;
private _newLoad = ((_entry select 1) + _loadDelta) max 0;

if (_newCount <= 0 && {_newLoad <= 0}) then {
    _assignmentState deleteAt _targetGroupId;
} else {
    _assignmentState set [_targetGroupId, [_newCount, _newLoad]];
};

true
