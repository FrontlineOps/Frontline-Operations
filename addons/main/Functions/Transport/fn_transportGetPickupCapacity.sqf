/*
 * Function: FLO_fnc_transportGetPickupCapacity
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns the immediate seat capacity a carrier can use for a new pickup.
 *   Active carriers use live cargo seats from surviving real vehicles. Virtual
 *   carriers use nominal capacity minus current attached passenger load.
 *
 * Arguments:
 *   0: Carrier group data <HASHMAP>
 *
 * Return Value:
 *   NUMBER - Seats currently available for a new pickup
 */

params ["_groupData"];

if (_groupData get "isActive") exitWith {
    private _realGroup = _groupData get "realGroup";
    if (isNull _realGroup) exitWith { 0 };

    private _transportVehicles = ([_realGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles) select {
        !isNull _x && {alive _x}
    };

    if (_transportVehicles isEqualTo []) then {
        _transportVehicles = (_groupData get "realVehicles") select {
            !isNull _x && {alive _x}
        };
    };

    private _freeSeats = 0;
    {
        _freeSeats = _freeSeats + (_x emptyPositions "cargo");
    } forEach _transportVehicles;

    _freeSeats max 0
};

private _nominalCapacity = [_groupData] call FLO_fnc_transportGetGroupCapacity;
private _currentLoad = [_groupData] call FLO_fnc_transportGetPassengerLoad;

(_nominalCapacity - _currentLoad) max 0
