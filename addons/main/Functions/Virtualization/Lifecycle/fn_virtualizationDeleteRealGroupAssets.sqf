/*
 * Function: FLO_fnc_virtualizationDeleteRealGroupAssets
 */

params [
    ["_groupData", createHashMap, [createHashMap]],
    ["_realGroup", grpNull, [grpNull]],
    ["_retainDeadEntities", false, [false]]
];

if !([_groupData, _realGroup, false] call FLO_fnc_virtualizationCanDeactivateGroup) then {
    ["VIRTUALIZATION", 1, format ["Refusing entity deletion for %1: player or foreign occupant", _groupData get "id"]] call FLO_fnc_log;
    throw "Virtualization entity deletion crossed group ownership";
};

private _vehiclesToDelete = +(_groupData get "realVehicles");
if (!isNull _realGroup) then {
    // Deliberate virtualization owns removal; Empty must not retire its record.
    ["", _realGroup] call FLO_fnc_virtualizationBindRealGroup;
    _vehiclesToDelete append (assignedVehicles _realGroup);
};
_vehiclesToDelete = _vehiclesToDelete arrayIntersect _vehiclesToDelete;
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
    if (_retainDeadEntities && {!alive _veh}) then {
        [_veh, "wreck"] call FLO_fnc_aftermathRegisterEntity;
        continue;
    };

    {
        if (_retainDeadEntities && {!alive _x}) then {
            moveOut _x;
            [_x, "corpse"] call FLO_fnc_aftermathRegisterEntity;
            continue;
        };
        _x hideObjectGlobal true;
        _veh deleteVehicleCrew _x;
    } forEach (crew _veh);

    _veh hideObjectGlobal true;
    deleteVehicle _veh;
} forEach _vehiclesToDelete;

{
    if (isNull _x) then { continue };
    if (_retainDeadEntities && {!alive _x}) then {
        [_x, "corpse"] call FLO_fnc_aftermathRegisterEntity;
        continue;
    };
    _x hideObjectGlobal true;
    deleteVehicle _x;
} forEach units _realGroup;

deleteGroup _realGroup;

true
