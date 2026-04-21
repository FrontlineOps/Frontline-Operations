/*
 * Author: Frontline Operations
 * Description:
 * Applies request-menu vehicle setup for visuals, service actions, and medical flags.
 *
 * Arguments:
 * 0: _vehicle (Object) - Spawned vehicle
 * 1: _vehicleClass (String) - Vehicle classname
 * 2: _fromRequestMenu (Bool) - True when the vehicle was created by a request menu
 *
 * Return Value:
 * None
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_vehicleClass", "", [""]],
    ["_fromRequestMenu", false, [false]]
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

if (_fromRequestMenu) then {
    _vehicle setVariable ["FLO_RequestMenuVehicle", true, true];
};

if !(_vehicle getVariable ["FLO_RequestMenuVehicle", false]) exitWith {};

if ((_vehicleClass == "B_Slingload_01_Repair_F") and !(_vehicle getVariable ["FLO_OPUnpackActionAdded", false])) then {
    _vehicle setVariable ["FLO_OPUnpackActionAdded", true, true];
    [_vehicle, "VEHICLE_OP_UNPACK", [[
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
    ]]] remoteExec [
        "FLO_fnc_configureObjectActionsLocal",
        0,
        format ["FLO_OBJ_ACT_%1_VEHICLE_OP_UNPACK", netId _vehicle]
    ];
};

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

private _arsenalVehicleTypes = F_Truck_Ammo_List apply { _x # 0 };
if ((_vehicleClass in _arsenalVehicleTypes) and !(_vehicle getVariable ["FLO_ArsenalActionAdded", false])) then {
    private _supportRoles = _vehicle getVariable ["FLO_SupportVehicleRoles", []];
    _supportRoles pushBackUnique "arsenal";
    _vehicle setVariable ["FLO_SupportVehicleRoles", _supportRoles, true];

    _vehicle setVariable ["FLO_ArsenalActionAdded", true, true];
    [_vehicle, "VEHICLE_ARSENAL", [[
        "<img size=2 color='#FFE258' image='Screens\FOBA\mg_ca.paa'/><t font='PuristaBold' color='#FFE258'>ARSENAL",
        {
            params ["_target", "_caller", "_actionId", "_arguments"];

            if (isClass (configFile >> "ace_arsenal_loadoutsDisplay")) then {
                private _restrictedArsenal = "RestrictedArsenal" call BIS_fnc_getParamValue;

                if (_restrictedArsenal == 0) then {
                    [_target, true, false] call FLO_fnc_applyAceRestrictedArsenalCargo;
                } else {
                    [_target, true] call ace_arsenal_fnc_initBox;
                };

                [_target, _caller, false] call ace_arsenal_fnc_openBox;
            } else {
                private _restrictedArsenal = "RestrictedArsenal" call BIS_fnc_getParamValue;

                if (_restrictedArsenal == 0) then {
                    [_target] call FLO_fnc_applyVanillaRestrictedArsenalCargo;
                    ["Open", [false, _target, _caller]] spawn BIS_fnc_arsenal;
                } else {
                    ["Open", true] spawn BIS_fnc_arsenal;
                };
            };
        },
        nil,
        1,
        true,
        true,
        "",
        "_this distance _target < 10"
    ]]] remoteExec [
        "FLO_fnc_configureObjectActionsLocal",
        0,
        format ["FLO_OBJ_ACT_%1_VEHICLE_ARSENAL", netId _vehicle]
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
