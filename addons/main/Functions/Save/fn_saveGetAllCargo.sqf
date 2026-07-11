/*
 * Function: FLO_fnc_saveGetAllCargo
 * Author: Frontline Operations Development Group
 * Description:
 *   Captures cargo contents for save data.
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Returns:
 * Cargo records <ARRAY>
 */
params ["_container"];

private _items = [];
(getWeaponCargo _container) params [["_wC", []], ["_wN", []]];
{ _items pushBack [_x, _wN # _forEachIndex, "weapon"]; } forEach _wC;
(getMagazineCargo _container) params [["_mC", []], ["_mN", []]];
{ _items pushBack [_x, _mN # _forEachIndex, "magazine"]; } forEach _mC;
(getItemCargo _container) params [["_iC", []], ["_iN", []]];
{ _items pushBack [_x, _iN # _forEachIndex, "item"]; } forEach _iC;
(getBackpackCargo _container) params [["_bC", []], ["_bN", []]];
{ _items pushBack [_x, _bN # _forEachIndex, "backpack"]; } forEach _bC;

_items select { (_x # 1) > 0 }
