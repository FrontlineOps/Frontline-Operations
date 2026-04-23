/*
    Function: FLO_fnc_applyAceRestrictedArsenalCargo

    Description:
        Applies the FLO restricted arsenal whitelist to an ACE arsenal box.
        When reset is true, the box is reinitialized with only the whitelist.
        When reset is false, the whitelist is re-applied without rebuilding the
        ACE interaction.

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

if (_resetBox) exitWith {
    [_box, _global] call ace_arsenal_fnc_removeBox;
    [_box, _allowedItems, _global] call ace_arsenal_fnc_initBox;
    true
};

[_box, _allowedItems, _global] call ace_arsenal_fnc_addVirtualItems;

true
