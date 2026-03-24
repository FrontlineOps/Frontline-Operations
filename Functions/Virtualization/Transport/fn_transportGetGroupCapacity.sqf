/*
 * Function: FLO_fnc_transportGetGroupCapacity
 */

params ["_groupData"];

private _vehicleType = _groupData get "vehicleType";
if (_vehicleType != "") exitWith {
    [_vehicleType] call FLO_fnc_transportGetCapacity
};

[(_groupData get "groupType")] call FLO_fnc_transportGetCapacity
