/*
 * Function: FLO_fnc_gtnCollectTurretWeapons
 * Author: Frontline Operations Development Group
 * Description:
 *   Recursively collects weapons from a turret config and nested sub-turrets.
 *
 * Arguments:
 * 0: Turret config <CONFIG>
 *
 * Returns:
 * Weapon classes <ARRAY>
 */
params ["_turretCfg"];

private _weapons = getArray (_turretCfg >> "weapons");
private _subTurrets = configProperties [_turretCfg >> "Turrets", "isClass _x"];
{
    _weapons append ([_x] call FLO_fnc_gtnCollectTurretWeapons);
} forEach _subTurrets;

_weapons
