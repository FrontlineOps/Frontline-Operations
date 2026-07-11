/*
 * Function: FLO_fnc_factionCompositionDefaultCaps
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds default objective group type caps.
 *
 * Arguments:
 * 0: Limited <BOOL>
 * 1: Static AA cap <NUMBER>
 * 2: Mobile AA cap <NUMBER>
 *
 * Returns:
 * Caps <ARRAY>
 */
params [
    ["_limited", true, [true]],
    ["_staticAACap", 3, [0]],
    ["_mobileAACap", 20, [0]]
];

private _uncapped = 999;
[
    ["infantry", _uncapped],
    ["motorized", _uncapped],
    ["mechanized", _uncapped],
    ["armor", _uncapped],
    ["helicopter", [_uncapped, 10] select (_limited)],
    ["jet", [_uncapped, 10] select (_limited)],
    ["air", 5],
    ["artillery", [_uncapped, 5] select (_limited)],
    ["mobile_aa", [_uncapped, _mobileAACap] select (_limited)],
    ["static_aa", [_uncapped, _staticAACap] select (_limited)]
]
