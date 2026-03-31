/*
 * Author: Frontline Operations
 * Description:
 * Applies support-vehicle setup for visuals, service actions, and medical flags.
 *
 * Arguments:
 * 0: _vehicle (Object) - Spawned vehicle
 * 1: _vehicleClass (String) - Vehicle classname
 *
 * Return Value:
 * None
 */

params ["_vehicle", "_vehicleClass"];

if (isNull _vehicle) exitWith {};

// Apply Stryker textures.
if ((_vehicleClass == "rhsusf_stryker_m1126_m2_d") or (_vehicleClass == "rhsusf_stryker_m1126_mk19_d") or (_vehicleClass == "rhsusf_stryker_m1134_d")) then {
    [_vehicle, ["Tan", 1]] call BIS_fnc_initVehicle;
};

// Apply woodland MRZR texture for woodland US factions.
if (((markerText "Friendly_Handle" == "United States Armed Forces _ Woodland _ CUP + RHS") or (markerText "Friendly_Handle" == "United States Armed Forces _ Woodland _ RHS")) and (_vehicleClass == "rhsusf_mrzr4_d")) then {
    [_vehicle, ["mud_olive", 1]] call BIS_fnc_initVehicle;
};

if ((_vehicleClass == "B_Slingload_01_Repair_F") and !(_vehicle getVariable ["FLO_OPUnpackActionAdded", false])) then {
    _vehicle setVariable ["FLO_OPUnpackActionAdded", true, true];
    [_vehicle, [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\b_hq.paa'/><t font='PuristaBold' color='#7CC2FF'>UnPack OP",
        "Scripts\PObjectives\OPUNPACK.sqf",
        nil,
        0,
        true,
        true,
        "",
        "true",
        40,
        false,
        "",
        ""
    ]] remoteExec ["addAction", 0, true];
};

private _constructionVehicleTypes = F_Truck_Construction_List apply { _x # 0 };
if ((_vehicleClass in _constructionVehicleTypes) and !(_vehicle getVariable ["FLO_BuildActionAdded", false])) then {
    _vehicle setVariable ["FLO_BuildActionAdded", true, true];
    [_vehicle, [
        "<img size=2 color='#FF0000' image='\a3\ui_f\data\igui\cfg\simpletasks\types\Use_ca.paa'/><t font='PuristaBold' color='#FF0000'>Build Mode",
        { [player] call IDS_Logistics_fnc_initBuildCamera; },
        nil,
        1.4,
        false,
        true,
        "",
        "!IDS_Logistics_isHolding"
    ]] remoteExec ["addAction", 0, true];
};

private _arsenalVehicleTypes = F_Truck_Ammo_List apply { _x # 0 };
if ((_vehicleClass in _arsenalVehicleTypes) and !(_vehicle getVariable ["FLO_ArsenalActionAdded", false])) then {
    _vehicle setVariable ["FLO_ArsenalActionAdded", true, true];
    [_vehicle, [
        "<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>ARSENAL",
        {
            if (isClass (configFile >> "ace_arsenal_loadoutsDisplay")) then {
                [player, player, true] call ace_arsenal_fnc_openBox;
            } else {
                ["Open", true] spawn BIS_fnc_arsenal;
            };
        },
        nil,
        1,
        true,
        true,
        "",
        "_this distance _target < 10"
    ]] remoteExec ["addAction", 0, true];
};

private _medicalVehicleTypes = F_Truck_Respawn_List apply { _x # 0 };
if ((_vehicleClass in _medicalVehicleTypes) and !(_vehicle getVariable ["FLO_MedicalSupportConfigured", false])) then {
    _vehicle setVariable ["FLO_MedicalSupportConfigured", true, true];
    _vehicle setVariable ["ace_medical_isMedicalVehicle", true, true];
    _vehicle setVariable ["ace_medical_isMedicalFacility", true, true];
};
