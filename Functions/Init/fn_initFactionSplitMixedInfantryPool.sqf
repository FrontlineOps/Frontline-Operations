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
        if (!isClass _entry) then { continue };

        _groupConfigs pushBack _entry;
        {
            private _unitClass = getText (_x >> "vehicle");
            if (_unitClass != "") then {
                _unitClasses pushBack _unitClass;
            };
        } forEach configClasses _entry;
        continue;
    };

    if (_entry isEqualType "") then {
        if (_entry != "") then {
            _unitClasses pushBack _entry;
        };
    };
} forEach _entries;

[_groupConfigs, _unitClasses]
