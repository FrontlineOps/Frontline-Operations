/*
 * Function: FLO_fnc_virtualizationCollectRealGroupVehicles
 * Author: Frontline Operations Development Group
 * Description:
 *   Collects all live vehicle objects currently associated with a real group.
 *   This captures tracked assets even when some crew are no longer seated.
 *
 * Arguments:
 * 0: Real Group <GROUP>
 *
 * Return Value:
 * ARRAY - Unique vehicle objects
 */

params [["_realGroup", grpNull, [grpNull]]];

if (isNull _realGroup) exitWith { [] };

private _vehicles = [];
{
    private _veh = vehicle _x;
    if (_veh == _x) then {
        _veh = assignedVehicle _x;
    };

    if (!isNull _veh) then {
        _vehicles pushBackUnique _veh;
    };
} forEach units _realGroup;

_vehicles
