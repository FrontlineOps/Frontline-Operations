/*
 * Function: FLO_fnc_factionDialogValidateFactionSelections
 * Author: Frontline Operations Development Group
 * Description:
 *   Validates faction setup dialog selections.
 *
 * Arguments:
 * 0: Label <STRING>
 * 1: Selections <ARRAY>
 *
 * Returns:
 * Errors <ARRAY>
 */
params ["_label", "_selections"];

private _errors = [];
if (_selections isEqualTo []) exitWith {
    [format ["%1 faction must be selected", _label]]
};

private _customSelections = _selections select { ((_x select 1) find "auto|") isNotEqualTo 0 };
if (count _selections > 1 && {_customSelections isNotEqualTo []}) then {
    _errors pushBack format ["%1 custom definitions cannot be combined with other factions", _label];
};

_errors
