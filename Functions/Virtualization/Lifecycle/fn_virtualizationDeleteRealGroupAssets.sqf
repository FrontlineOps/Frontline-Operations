/*
 * Function: FLO_fnc_virtualizationDeleteRealGroupAssets
 */

params ["_realGroup"];

private _vehiclesToDelete = [];
{
    private _veh = vehicle _x;
    if (!isNull _veh && {_veh != _x}) then {
        _vehiclesToDelete pushBackUnique _veh;
    };
} forEach units _realGroup;

{
    private _veh = _x;
    _veh hideObjectGlobal true;
    {
        _x hideObjectGlobal true;
        _veh deleteVehicleCrew _x;
    } forEach (crew _veh);
    deleteVehicle _veh;
} forEach _vehiclesToDelete;

{
    _x hideObjectGlobal true;
    deleteVehicle _x;
} forEach units _realGroup;

deleteGroup _realGroup;

true
