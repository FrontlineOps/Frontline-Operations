/*
 * Function: FLO_fnc_virtualizationDeleteRealGroupAssets
 */

params [
    ["_groupData", createHashMap, [createHashMap]],
    ["_realGroup", grpNull, [grpNull]],
    ["_preserveAftermath", false, [false]]
];

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

private _preserveEvidence = false;
if (_preserveAftermath) then {
    _preserveEvidence = [(_vehiclesToDelete + units _realGroup)] call FLO_fnc_aftermathShouldPreserveEvidence;
};

{
    private _veh = _x;
    if (isNull _veh) then { continue };
    if (_preserveEvidence && {!alive _veh}) then {
        [_veh, "wreck"] call FLO_fnc_aftermathRegisterEntity;
        continue;
    };
    _veh hideObjectGlobal true;
    {
        _x hideObjectGlobal true;
        _veh deleteVehicleCrew _x;
    } forEach (crew _veh);
    deleteVehicle _veh;
} forEach _vehiclesToDelete;

{
    if (_preserveEvidence && {!alive _x}) then {
        [_x, "corpse"] call FLO_fnc_aftermathRegisterEntity;
        continue;
    };
    _x hideObjectGlobal true;
    deleteVehicle _x;
} forEach units _realGroup;

deleteGroup _realGroup;

true
