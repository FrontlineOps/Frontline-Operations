/*
 * Function: FLO_fnc_initFactionSplitMixedInfantryPool
 * Author: Frontline Operations Development Group
 * Description:
 *   Normalizes a mixed infantry pool into group configs and unit classnames.
 *   Group configs are retained for group spawning and also contribute their
 *   contained unit classnames to the fallback unit pool.
 *
 * Arguments:
 *   0: Mixed infantry entries <ARRAY>
 *
 * Return Value:
 *   [group configs, unit classnames] <ARRAY>
 */

params [["_entries", [], [[]]]];

private _groupConfigs = [];
private _unitClasses = [];

{
    private _entry = _x;

    if (_entry isEqualType configNull) then {
        if (isClass _entry) then {
            private _subclasses = "true" configClasses _entry;
            private _groupUnitClasses = [];
            private _validGroup = _subclasses isNotEqualTo [];
            {
                private _unitClass = getText (_x >> "vehicle");
                if (_unitClass == "" || {!([_unitClass] call FLO_fnc_factionClassIsCombatInfantry)}) exitWith {
                    _validGroup = false;
                };
                _groupUnitClasses pushBackUnique _unitClass;
            } forEach _subclasses;
            if (_validGroup) then {
                _groupConfigs pushBack _entry;
                _unitClasses append _groupUnitClasses;
            };
        };
    };

    if (_entry isEqualType "") then {
        if ([_entry] call FLO_fnc_factionClassIsCombatInfantry) then {
            _unitClasses pushBackUnique _entry;
        };
    };
} forEach _entries;

[_groupConfigs, _unitClasses arrayIntersect _unitClasses]
