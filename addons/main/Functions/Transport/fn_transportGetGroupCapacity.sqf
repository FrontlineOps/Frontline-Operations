/*
 * Function: FLO_fnc_transportGetGroupCapacity
 */

params ["_groupData"];

private _composition = _groupData get "comp";
if (_composition isNotEqualTo []) exitWith {
    private _capacity = 0;
    {
        _capacity = _capacity + ([_x] call FLO_fnc_transportGetCapacity);
    } forEach _composition;
    _capacity
};

private _vehicleType = _groupData get "vehicleType";
private _capacityPerVehicle = if (_vehicleType != "") then {
    [_vehicleType] call FLO_fnc_transportGetCapacity
} else {
    [(_groupData get "groupType")] call FLO_fnc_transportGetCapacity
};

private _carrierCount = (_groupData get "unitCount") max 1;
_capacityPerVehicle * _carrierCount
