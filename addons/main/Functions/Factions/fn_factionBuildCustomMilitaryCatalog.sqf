/* Builds a canonical military catalog from the documented custom inputs. */
params [
    ["_role", "", [""]],
    ["_compositionDefaults", createHashMap, [createHashMap]]
];

private _sideLabel = toUpper _role;
if !(_sideLabel in ["BLUFOR", "OPFOR"]) then {
    throw format ["Unsupported custom military role %1", _role];
};

if (_sideLabel == "OPFOR") exitWith {
    private _infantryPools = [(["East_Ground_Infantry"] call FLO_fnc_factionGetVariableArray)] call FLO_fnc_initFactionSplitMixedInfantryPool;
    _infantryPools params ["_infantryGroups", "_infantryUnits"];
    private _specOpsPools = [(["East_Ground_SpecOps"] call FLO_fnc_factionGetVariableArray)] call FLO_fnc_initFactionSplitMixedInfantryPool;
    _specOpsPools params ["_specOpsGroups", "_specOpsUnits"];

    private _groundTransport = [["East_Ground_Transport"]] call FLO_fnc_factionBuildVehiclePoolFromVariables;

    createHashMapFromArray [
        ["groups", _infantryGroups],
        ["units", _infantryUnits],
        ["officers", ["East_FireObserver"] call FLO_fnc_factionGetVariableArray],
        ["groundInfantryGroups", _infantryGroups],
        ["groundInfantryUnits", _infantryUnits],
        ["groundSpecOpsGroups", _specOpsGroups],
        ["groundSpecOpsUnits", _specOpsUnits],
        ["groundMotorized", [["East_Ground_Motorized"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
        ["groundMechanized", [["East_Ground_Mechanized"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
        ["groundArmor", [["East_Ground_Armor"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
        ["groundTransport", _groundTransport],
        ["transportReserveGroundCount", _compositionDefaults get "transportReserveGroundCount"],
        ["groundArtillery", [["East_Ground_Artillery"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
        ["airHeli", [["East_Air_Heli"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
        ["airJet", [["East_Air_Jet"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
        ["airTransport", [["East_Air_Transport"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
        ["transportReserveAirCount", _compositionDefaults get "transportReserveAirCount"],
        ["airDrone", [["East_Air_Drone"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
        ["groundDrone", [["East_Ground_Drone"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
        ["mobileAA", [["East_Mobile_AA"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
        ["staticAA", [["East_Static_AA"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
        ["boat", [["East_Boat"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
        ["logisticsConstruction", +_groundTransport],
        ["logisticsAmmo", +_groundTransport],
        ["logisticsRespawn", +_groundTransport],
        ["containers", []],
        ["radar", [["East_Radar"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
        ["objectiveGroups", _compositionDefaults get "objectiveGroups"],
        ["objectiveGroupTypeCaps", _compositionDefaults get "objectiveGroupTypeCaps"],
        ["groupCounts", _compositionDefaults get "groupCounts"]
    ]
};

private _infantryVars = [
    "F_Officer", "F_Assault_Eng", "F_Assault_TL", "F_Assault_SL", "F_Assault_Eod",
    "F_Assault_Mrk", "F_Assault_AT", "F_Assault_Amm", "F_Assault_Mg", "F_Assault_Med",
    "F_Assault_Uav"
];
private _specOpsVars = [
    "F_Recon_Snp", "F_Recon_Sct", "F_Recon_TL", "F_Recon_Mrk",
    "F_Recon_AT", "F_Recon_Mg", "F_Recon_Eod", "F_Recon_Med", "F_Recon_Eng",
    "F_Diver_TL", "F_Diver_Eod", "F_Diver_Rfl"
];

private _infantryPools = [([_infantryVars] call FLO_fnc_factionCollectDirectUnitVariables)] call FLO_fnc_initFactionSplitMixedInfantryPool;
_infantryPools params ["_infantryGroups", "_infantryUnits"];
private _specOpsPools = [([_specOpsVars] call FLO_fnc_factionCollectDirectUnitVariables)] call FLO_fnc_initFactionSplitMixedInfantryPool;
_specOpsPools params ["_specOpsGroups", "_specOpsUnits"];
if (_infantryUnits isEqualTo []) then {
    throw "Custom BLUFOR definition has no eligible infantry units";
};

private _officerClass = missionNamespace getVariable "F_Officer";
private _officers = if (_officerClass == "") then { [_infantryUnits select 0] } else { [_officerClass] };
private _groundMotorized = [["F_Car_List", "F_MRAP_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables;
private _groundMechanized = [["F_APC_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables;
private _groundArmor = [["F_Tank_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables;
private _groundTransport = [["F_Truck_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables;
private _airTransport = [["F_Heli_List", "F_Heli_Respawn_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables;
private _mobileAA = (_groundMechanized + _groundArmor) arrayIntersect (_groundMechanized + _groundArmor);

if (isNil "FLO_FactionRadar" || {!(FLO_FactionRadar isEqualType "")}) then {
    throw "Custom BLUFOR definition requires text FLO_FactionRadar";
};

createHashMapFromArray [
    ["groups", _infantryGroups],
    ["units", _infantryUnits],
    ["officers", _officers],
    ["groundInfantryGroups", _infantryGroups],
    ["groundInfantryUnits", _infantryUnits],
    ["groundSpecOpsGroups", _specOpsGroups],
    ["groundSpecOpsUnits", _specOpsUnits],
    ["groundMotorized", _groundMotorized],
    ["groundMechanized", _groundMechanized],
    ["groundArmor", _groundArmor],
    ["groundTransport", _groundTransport],
    ["transportReserveGroundCount", _compositionDefaults get "transportReserveGroundCount"],
    ["groundArtillery", [["F_Artillery_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
    ["airHeli", [["F_Heli_Gunship_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
    ["airJet", [["F_Plane_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
    ["airTransport", _airTransport],
    ["transportReserveAirCount", _compositionDefaults get "transportReserveAirCount"],
    ["airDrone", [["F_UAV_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
    ["groundDrone", [["F_UGV_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
    ["mobileAA", _mobileAA],
    ["staticAA", [["F_SAM_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
    ["boat", [["F_Boat_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
    ["logisticsConstruction", [["F_Truck_Construction_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
    ["logisticsAmmo", [["F_Truck_Ammo_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
    ["logisticsRespawn", [["F_Truck_Respawn_List", "F_Heli_Respawn_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
    ["containers", [["F_Container_List"]] call FLO_fnc_factionBuildVehiclePoolFromVariables],
    ["radar", if (FLO_FactionRadar == "") then { [] } else { [FLO_FactionRadar] }],
    ["objectiveGroups", _compositionDefaults get "objectiveGroups"],
    ["objectiveGroupTypeCaps", _compositionDefaults get "objectiveGroupTypeCaps"],
    ["groupCounts", _compositionDefaults get "groupCounts"]
]
