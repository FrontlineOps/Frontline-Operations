/*
 * Function: FLO_fnc_gtnCombatApplyAttrition
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies virtual combat losses to the provided groups and removes depleted
 *   groups from virtualization state.
 *
 * Arguments:
 *   0: Virtual groups map <HASHMAP>
 *   1: Group references <ARRAY>
 *   2: Loss percentage <NUMBER>
 *
 * Return Value:
 *   Applied casualty count <NUMBER>
 */

params ["_groups", "_groupRefs", "_lossPct"];

private _eligibleRefs = _groupRefs select {
    private _groupId = _x select 0;
    _groupId in _groups && {((_groups get _groupId) get "unitCount") > 0}
};
if (_eligibleRefs isEqualTo [] || {_lossPct <= 0}) exitWith { 0 };

private _sortedRefs = _eligibleRefs apply { [_x select 0, (_groups get (_x select 0)) get "unitCount"] };
_sortedRefs sort true;
private _totalUnits = 0;
{ _totalUnits = _totalUnits + (_x select 1); } forEach _sortedRefs;
private _targetLosses = (round (_totalUnits * (_lossPct min 1))) min _totalUnits;
if (_targetLosses <= 0) exitWith { 0 };
private _remainingLosses = _targetLosses;
private _remainingUnits = _totalUnits;

{
    _x params ["_groupId", "_count"];
    private _loss = if (_forEachIndex == ((count _sortedRefs) - 1)) then {
        _remainingLosses min _count
    } else {
        (round (_remainingLosses * (_count / (_remainingUnits max 1)))) min _count
    };
    _remainingLosses = _remainingLosses - _loss;
    _remainingUnits = _remainingUnits - _count;
    if (_loss <= 0) then { continue };

    private _appliedLoss = [_groupId, _loss] call FLO_fnc_gtnCombatApplyGroupLoss;
    _remainingLosses = _remainingLosses + _loss - _appliedLoss;
} forEach _sortedRefs;

_targetLosses - _remainingLosses
