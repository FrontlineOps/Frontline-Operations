/*
 * Function: FLO_fnc_virtualizationAssignIntelItem
 * Author: Frontline Operations Development Group
 * Description:
 *   Tries to place one intel item on a unit using multiple inventory targets
 *   so full default loadouts do not silently discard the pickup.
 *
 * Arguments:
 * 0: Carrier unit <OBJECT>
 * 1: Intel item classname <STRING>
 *
 * Return Value:
 * BOOL - True when the item was added
 */

params [
    ["_unit", objNull, [objNull]],
    ["_itemClass", "", [""]]
];

if (isNull _unit || {!alive _unit} || {!(_unit isKindOf "Man")} || {_itemClass == ""}) exitWith { false };

private _beforeCount = {
    _x == _itemClass
} count ((items _unit) + (uniformItems _unit) + (vestItems _unit) + (backpackItems _unit) + (assignedItems _unit));

_unit addItem _itemClass;
private _afterCount = {
    _x == _itemClass
} count ((items _unit) + (uniformItems _unit) + (vestItems _unit) + (backpackItems _unit) + (assignedItems _unit));
if (_afterCount > _beforeCount) exitWith { true };

_unit addItemToBackpack _itemClass;
_afterCount = {
    _x == _itemClass
} count ((items _unit) + (uniformItems _unit) + (vestItems _unit) + (backpackItems _unit) + (assignedItems _unit));
if (_afterCount > _beforeCount) exitWith { true };

_unit addItemToVest _itemClass;
_afterCount = {
    _x == _itemClass
} count ((items _unit) + (uniformItems _unit) + (vestItems _unit) + (backpackItems _unit) + (assignedItems _unit));
if (_afterCount > _beforeCount) exitWith { true };

_unit addItemToUniform _itemClass;
_afterCount = {
    _x == _itemClass
} count ((items _unit) + (uniformItems _unit) + (vestItems _unit) + (backpackItems _unit) + (assignedItems _unit));
_afterCount > _beforeCount
