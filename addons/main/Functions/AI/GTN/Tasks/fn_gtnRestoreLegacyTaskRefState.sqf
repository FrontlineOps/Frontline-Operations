/*
 * Function: FLO_fnc_gtnRestoreLegacyTaskRefState
 * Author: Frontline Operations Development Group
 * Description:
 *   Restores split task kind/objective state from legacy task refs.
 *
 * Arguments:
 *   0: Player task state <HASHMAP>
 *   1: Kind key <STRING>
 *   2: Objective key <STRING>
 *   3: Ref key <STRING>
 *
 * Return Value:
 *   Nothing
 */

params ["_state", "_kindKey", "_objKey", "_refKey"];

if ((_state get _kindKey) isEqualTo "" && {(_state get _refKey) != ""}) then {
    private _ref = _state get _refKey;
    private _sep = _ref find "_";
    if (_sep > 0) then {
        _state set [_kindKey, _ref select [0, _sep]];
        _state set [_objKey, _ref select [_sep + 1, (count _ref) - _sep - 1]];
    };
};
