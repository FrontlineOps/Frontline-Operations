/*
 * Function: FLO_fnc_saveGetCompressedDamage
 * Author: Frontline Operations Development Group
 * Description:
 *   Captures non-trivial hitpoint damage values for save data.
 *
 * Arguments:
 * 0: Vehicle/object <OBJECT>
 *
 * Returns:
 * Damaged hitpoints <ARRAY>
 */
params ["_vehicle"];

private _result = [];
private _allDamage = getAllHitPointsDamage _vehicle;
if (count _allDamage >= 3) then {
    private _names = _allDamage # 0;
    private _values = _allDamage # 2;
    {
        if ((_values # _forEachIndex) > 0.01) then {
            _result pushBack [_x, _values # _forEachIndex];
        };
    } forEach _names;
};

_result
