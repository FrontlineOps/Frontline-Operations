/*
 * Function: FLO_fnc_transportCountMountedActivePassengers
 * Author: Frontline Operations Development Group
 * Description:
 *   Counts the surviving live passengers that are still physically mounted in
 *   an active carrier's vehicles.
 *
 * Arguments:
 *   0: Carrier Group Data <HASHMAP>
 *   1: Carrier Vehicles <ARRAY>
 *
 * Return Value:
 *   NUMBER - Mounted live passenger count
 */

params [
    ["_carrierData", createHashMap, [createHashMap]],
    ["_transportVehicles", [], [[]]]
];

if (_transportVehicles isEqualTo []) exitWith { 0 };

private _mountedCount = 0;

{
    private _passengerData = [_x] call FLO_fnc_virtualizationFindGroupSnapshot;
    if (isNil "_passengerData") then { continue; };
    if !(_passengerData get "isActive") then { continue; };

    private _realGroup = _passengerData get "realGroup";
    if (isNull _realGroup) then { continue; };

    _mountedCount = _mountedCount + ({
        private _veh = vehicle _x;
        alive _x && {_veh != _x && {_veh in _transportVehicles}}
    } count units _realGroup);
} forEach ([_carrierData] call FLO_fnc_virtualizationGetTransportPassengers);

_mountedCount
