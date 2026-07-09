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

private _presetSelections = _selections select { ((_x select 1) find "auto|") isNotEqualTo 0 };
if (count _selections > 1 && {_presetSelections isNotEqualTo []}) then {
    _errors pushBack format ["%1 presets cannot be combined with other factions", _label];
};

private _autoClasses = [];
{
    private _data = _x select 1;
    if ((_data find "auto|") == 0) then {
        _autoClasses pushBack (_data select [5]);
    };
} forEach _selections;

if (count _autoClasses > 1) then {
    private _autoSides = [];
    {
        private _cfg = configFile >> "CfgFactionClasses" >> _x;
        if !(isClass _cfg) then {
            _cfg = missionConfigFile >> "CfgFactionClasses" >> _x;
        };
        private _side = getNumber (_cfg >> "side");
        _autoSides pushBackUnique _side;
    } forEach _autoClasses;

    if (count _autoSides > 1) then {
        _errors pushBack format ["%1 merged auto factions must come from the same config side", _label];
    };
};

_errors
