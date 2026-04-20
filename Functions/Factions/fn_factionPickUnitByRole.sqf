/*
 * Function: FLO_fnc_factionPickUnitByRole
 * Author: Frontline Operations Development Group
 * Description:
 *   Picks the best matching unit classname from a faction unit pool.
 *
 * Arguments:
 *   0: Unit classnames <ARRAY>
 *   1: Role token <STRING>
 *
 * Return Value:
 *   Unit classname <STRING>
 */

params [
    ["_units", [], [[]]],
    ["_role", "rifleman", [""]]
];

if (_units isEqualTo []) exitWith { "" };

private _needles = switch (toLower _role) do {
    case "officer": { ["officer", "commander"] };
    case "leader": { ["leader", "_sl", "_tl", "squadleader", "teamleader"] };
    case "engineer": { ["engineer", "repair"] };
    case "eod": { ["explosive", "demo", "sapper", "_exp"] };
    case "marksman": { ["marksman", "sharpshooter", "sniper"] };
    case "at": { ["_at", "lat", "missile", "antitank"] };
    case "ammo": { ["ammo", "assistant", "_aar"] };
    case "mg": { ["machinegun", "_mg", "autorifleman", "_ar"] };
    case "medic": { ["medic", "corpsman"] };
    case "uav": { ["uav", "drone"] };
    case "diver": { ["diver"] };
    case "crew": { ["crew", "pilot"] };
    default { ["rifleman", "soldier"] };
};

private _match = "";
{
    private _unit = _x;
    private _cfg = configFile >> "CfgVehicles" >> _unit;
    private _cnLower = toLower _unit;
    private _dnLower = toLower (getText (_cfg >> "displayName"));

    {
        if ((_cnLower find _x) >= 0 || {(_dnLower find _x) >= 0}) exitWith {
            _match = _unit;
        };
    } forEach _needles;

    if (_match != "") exitWith {};
} forEach _units;

if (_match != "") exitWith { _match };

_units select 0
