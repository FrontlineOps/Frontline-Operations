/*
 * Function: FLO_fnc_gtnCombatSidePower
 * Author: Frontline Operations Development Group
 * Description:
 *   Aggregates weighted combat power and force composition data for one side of
 *   an engagement.
 *
 * Arguments:
 *   0: Side group references <ARRAY>
 *
 * Return Value:
 *   Combat power summary <HASHMAP>
 */

params ["_sideRefs"];

private _power = 0;
private _units = 0;
private _inf = 0;
private _armor = 0;

{
    private _groupId = _x select 0;
    private _gData = _x select 1;
    private _count = _gData get "unitCount";
    if (_count <= 0) then { continue };

    private _type = _gData get "groupType";
    private _weight = [_type] call FLO_fnc_gtnCombatTypeWeight;
    private _formationMultiplier = [_groupId] call FLO_fnc_formationGetCombatMultiplier;
    _power = _power + (_count * _weight * _formationMultiplier);
    _units = _units + _count;

    if (_type isEqualTo "infantry") then { _inf = _inf + _count };
    if (_type in ["armor", "mechanized"]) then { _armor = _armor + _count };
} forEach _sideRefs;

createHashMapFromArray [
    ["power", _power],
    ["units", _units],
    ["infantry", _inf],
    ["armor", _armor]
]
