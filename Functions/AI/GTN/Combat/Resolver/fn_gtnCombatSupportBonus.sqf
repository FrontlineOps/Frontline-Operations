/*
 * Function: FLO_fnc_gtnCombatSupportBonus
 * Author: Frontline Operations Development Group
 * Description:
 *   Computes support modifiers for one side while respecting virtual support
 *   cooldowns.
 *
 * Arguments:
 *   0: Side <SIDE>
 *   1: Support availability map <HASHMAP>
 *
 * Return Value:
 *   Support bonus summary <HASHMAP>
 */

params ["_side", "_supportAvailability"];

private _sideKey = ([_side] call FLO_fnc_gtnSideContext) get "sideKey";
private _now = diag_tickTime;
private _artyBonus = 0;
private _airBonus = 0;
private _artyKey = _sideKey + "_ARTY";
private _airKey = _sideKey + "_AIR";

if (_supportAvailability get _artyKey) then {
    if (_now >= (FLO_GTN_VirtualSupportCooldowns get _artyKey)) then {
        _artyBonus = 1;
        FLO_GTN_VirtualSupportCooldowns set [_artyKey, _now + 180];
    };
};

if (_supportAvailability get _airKey) then {
    if (_now >= (FLO_GTN_VirtualSupportCooldowns get _airKey)) then {
        _airBonus = 1;
        FLO_GTN_VirtualSupportCooldowns set [_airKey, _now + 240];
    };
};

createHashMapFromArray [
    ["total", _artyBonus + _airBonus],
    ["artillery", _artyBonus],
    ["air", _airBonus]
]
