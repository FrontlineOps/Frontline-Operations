/*
 * Function: FLO_fnc_virtualizationDeleteRealGroupAssets
 */

params ["_groupData", "_realGroup"];

private _vehiclesToDelete = +(_groupData get "realVehicles");
{
    private _veh = vehicle _x;
    if (_veh == _x) then {
        _veh = assignedVehicle _x;
    };

    if (!isNull _veh) then {
        _vehiclesToDelete pushBackUnique _veh;
    };
} forEach units _realGroup;

{
    private _veh = _x;
    if (isNull _veh) then { continue };
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
