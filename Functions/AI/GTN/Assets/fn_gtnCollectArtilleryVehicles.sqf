/*
 * Function: FLO_fnc_gtnCollectArtilleryVehicles
 * Author: Frontline Operations Development Group
 * Description:
 *   Collects the valid artillery vehicles from a real artillery group.
 *
 * Arguments:
 *   0: Real artillery group <GROUP>
 *
 * Return Value:
 *   ARRAY - Artillery vehicle objects
 */

params [["_realGroup", grpNull, [grpNull]]];

if (isNull _realGroup) exitWith { [] };

private _vehicles = [];
{
    private _veh = vehicle _x;
    if (_veh == _x || {!alive _veh}) then { continue };

    private _artyAmmo = getArtilleryAmmo [_veh];
    if !(count _artyAmmo > 0 || {_veh isKindOf "Artillery"} || {_veh isKindOf "MLRS"} || {_veh isKindOf "StaticMortar"} || {_veh isKindOf "Tank_F"}) then {
        continue;
    };

    if (count _artyAmmo > 0 || {count (allTurrets _veh) > 0}) then {
        _vehicles pushBackUnique _veh;
    };
} forEach units _realGroup;

_vehicles
