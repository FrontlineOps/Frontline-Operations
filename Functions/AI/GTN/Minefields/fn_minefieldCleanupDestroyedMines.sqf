/*
 * Function: FLO_fnc_minefieldCleanupDestroyedMines
 * Author: Frontline Operations Development Group
 * Description:
 *   Prunes inactive mine references from a tracked field and deletes the field
 *   when no active mines remain.
 *
 * Arguments:
 * 0: Field ID <STRING>
 *
 * Return Value:
 * SCALAR - Active mine count after cleanup
 */

params [
    ["_fieldId", ""]
];

if (_fieldId == "") exitWith { 0 };
if (isNil "FLO_Minefields") exitWith { 0 };

private _field = FLO_Minefields get _fieldId;
if (isNil "_field") exitWith { 0 };

private _previousMineCount = count (_field get "mineObjects");
private _remainingMines = [];
{
    if (isNull _x) then { continue };
    if !(mineActive _x) then { continue };
    _remainingMines pushBack _x;
} forEach (_field get "mineObjects");

if ((count _remainingMines) == 0) exitWith {
    [_fieldId, "CLEARED"] call FLO_fnc_minefieldDeleteField;
    0
};

_field set ["mineObjects", _remainingMines];
FLO_Minefields set [_fieldId, _field];

count _remainingMines
