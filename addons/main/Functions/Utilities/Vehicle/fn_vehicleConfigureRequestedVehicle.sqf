/*
 * Author: Frontline Operations
 * Description:
 * Applies Store vehicle setup for visuals, service actions, and medical flags.
 *
 * Arguments:
 * 0: _vehicle (Object) - Spawned vehicle
 * 1: _vehicleClass (String) - Vehicle classname
 * 2: _fromStore (Bool) - True when the vehicle was created by the Store
 *
 * Return Value:
 * None
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_vehicleClass", "", [""]],
    ["_fromStore", false, [false]]
];

if (isNull _vehicle) exitWith {};
if (_vehicleClass == "") then {
    _vehicleClass = typeOf _vehicle;
};

// Apply Stryker textures.
if ((_vehicleClass == "rhsusf_stryker_m1126_m2_d") or (_vehicleClass == "rhsusf_stryker_m1126_mk19_d") or (_vehicleClass == "rhsusf_stryker_m1134_d")) then {
    [_vehicle, ["Tan", 1]] call BIS_fnc_initVehicle;
};

// Apply woodland MRZR texture for woodland US factions.
if (((markerText "Friendly_Handle" == "United States Armed Forces _ Woodland _ CUP + RHS") or (markerText "Friendly_Handle" == "United States Armed Forces _ Woodland _ RHS")) and (_vehicleClass == "rhsusf_mrzr4_d")) then {
    [_vehicle, ["mud_olive", 1]] call BIS_fnc_initVehicle;
};

if (_fromStore) then {
    _vehicle setVariable ["FLO_StoreVehicle", true, true];
};

if !(_vehicle getVariable ["FLO_StoreVehicle", false]) exitWith {};

private _constructionVehicleTypes = F_Truck_Construction_List apply { _x # 0 };
if ((_vehicleClass in _constructionVehicleTypes) and !(_vehicle getVariable ["FLO_BuildActionAdded", false])) then {
    private _supportRoles = _vehicle getVariable ["FLO_SupportVehicleRoles", []];
    _supportRoles pushBackUnique "build";
    _vehicle setVariable ["FLO_SupportVehicleRoles", _supportRoles, true];

    _vehicle setVariable ["FLO_BuildActionAdded", true, true];
    [_vehicle, "VEHICLE_BUILD", [[
        "<img size=2 color='#FF0000' image='\a3\ui_f\data\igui\cfg\simpletasks\types\Use_ca.paa'/><t font='PuristaBold' color='#FF0000'>Build Mode",
        { [player] call IDS_Logistics_fnc_initBuildCamera; },
        nil,
        1.4,
        false,
        true,
        "",
        "!IDS_Logistics_isHolding"
    ]]] remoteExec [
        "FLO_fnc_configureObjectActionsLocal",
        0,
        format ["FLO_OBJ_ACT_%1_VEHICLE_BUILD", netId _vehicle]
    ];
};

private _medicalVehicleTypes = (F_Truck_Respawn_List + F_Heli_Respawn_List) apply { _x # 0 };
if ((_vehicleClass in _medicalVehicleTypes) and !(_vehicle getVariable ["FLO_MedicalSupportConfigured", false])) then {
    private _supportRoles = _vehicle getVariable ["FLO_SupportVehicleRoles", []];
    _supportRoles pushBackUnique "respawn";
    _vehicle setVariable ["FLO_SupportVehicleRoles", _supportRoles, true];
    _vehicle setVariable ["FLO_MobileRespawnVehicle", true, true];
    _vehicle setVariable ["FLO_MedicalSupportConfigured", true, true];
    _vehicle setVariable ["ace_medical_isMedicalVehicle", true, true];
    _vehicle setVariable ["ace_medical_isMedicalFacility", true, true];
};
