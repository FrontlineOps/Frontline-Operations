/*
    Function: FLO_fnc_applyAceRestrictedArsenalCargo

    Description:
        Applies the FLO restricted arsenal whitelist to an ACE arsenal box.
        When reset is true, the box is reinitialized with only the whitelist.
        When reset is false, existing virtual items are removed by classname so
        the ACE arsenal interaction is not removed.

    Arguments:
        0: Arsenal object <OBJECT>
        1: Reset ACE arsenal box <BOOL> default false
        2: Apply globally <BOOL> default false

    Return:
        true when cargo was applied, false for invalid state
*/

params [
    ["_box", objNull, [objNull]],
    ["_resetBox", false, [false]],
    ["_global", false, [false]]
];

if (isNull _box) exitWith { false };
if !(isClass (configFile >> "ace_arsenal_loadoutsDisplay")) exitWith { false };

private _allowedItems = +FLO_arsenal_allowedItems;

if (_allowedItems isEqualTo []) exitWith {
    ["ARSENAL", 1, "ACE restricted arsenal whitelist is empty; arsenal will not be opened"] call FLO_fnc_log;
    false
};

private _configItemsFlat = uiNamespace getVariable ["ace_arsenal_configItemsFlat", createHashMap];
private _allowedNormalized = (_allowedItems select {_x isEqualType ""}) apply {
    _x call ace_common_fnc_getConfigName
};
_allowedNormalized = _allowedNormalized - [""];
_allowedNormalized = _allowedNormalized apply {
    if (_x in _configItemsFlat) then {
        _x
    } else {
        _x call ace_arsenal_fnc_baseWeapon
    }
};
_allowedNormalized = (_allowedNormalized select {_x in _configItemsFlat}) arrayIntersect _allowedNormalized;

if (_resetBox) exitWith {
    [_box, _global] call ace_arsenal_fnc_removeBox;
    [_box, _allowedItems, _global] call ace_arsenal_fnc_initBox;
    true
};

[_box, _allowedItems, _global] call ace_arsenal_fnc_addVirtualItems;

private _currentItems = [_box] call ace_arsenal_fnc_getVirtualItems;
private _currentItemNames = keys _currentItems;
private _itemsToRemove = _currentItemNames - _allowedNormalized;
if (_itemsToRemove isNotEqualTo []) then {
    [_box, _itemsToRemove, _global] call ace_arsenal_fnc_removeVirtualItems;
};

true
