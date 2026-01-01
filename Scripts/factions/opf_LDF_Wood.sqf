// ============================================================================
// LDF WOODLAND FACTION - OPFOR (Vanilla)
// Livonian Defense Force in woodland camouflage
// ============================================================================

// ============================================================================
// INFANTRY GROUPS
// ============================================================================
East_Groups = [
    (configfile >> "CfgGroups" >> "Indep" >> "IND_E_F" >> "Infantry" >> "I_E_InfSentry"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_E_F" >> "Infantry" >> "I_E_InfTeam"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_E_F" >> "Infantry" >> "I_E_InfSquad"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_E_F" >> "Infantry" >> "I_E_InfTeam_AT"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_E_F" >> "Infantry" >> "I_E_InfTeam_AA")
];

// ============================================================================
// INFANTRY UNITS
// ============================================================================
East_Units = [
    "I_E_Soldier_F", "I_E_Soldier_F",
    "I_E_Soldier_AR_F", "I_E_Soldier_AR_F",
    "I_E_Soldier_GL_F", "I_E_Soldier_GL_F",
    "I_E_Soldier_TL_F",
    "I_E_Soldier_SL_F",
    "I_E_soldier_M_F",
    "I_E_Soldier_LAT2_F",
    "I_E_Soldier_AR_F",
    "I_E_Medic_F",
    "I_E_Soldier_Exp_F",
    "I_E_RadioOperator_F"
];

East_Units_Officers = ["I_E_Officer_F"];
East_FireObserver = ["I_E_RadioOperator_F"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
East_Ground_Vehicles_Ambient = [
    "I_E_Offroad_01_F", "I_E_Van_02_transport_F", "I_E_Offroad_01_covered_F",
    "I_E_Truck_02_transport_F", "I_E_Truck_02_fuel_F", "I_E_Truck_02_F", "I_E_Truck_02_MRL_F"
];

East_Ground_Vehicles_Light = [
    "I_E_UGV_01_rcws_F", "O_G_Offroad_01_armed_F",
    "O_G_Offroad_01_AT_F", "I_E_Offroad_01_armed_F"
];

East_Ground_Vehicles_Heavy = [
    "I_E_APC_tracked_03_cannon_F", "I_E_APC_Wheeled_03_cannon_F"
];

East_Ground_Transport = [
    "I_E_Van_02_transport_F", "I_E_Offroad_01_F", "I_E_Offroad_01_covered_F",
    "I_E_Truck_02_F", "I_E_Truck_02_transport_F"
];

East_Ground_Artillery = ["I_E_Truck_02_MRL_F", "I_E_Mortar_01_F"];

East_Air_Transport = ["I_Heli_Transport_02_F", "I_E_Heli_light_03_unarmed_F"];

East_Air_Heli = ["I_E_Heli_light_03_dynamicLoadout_F"];

East_Air_Jet = ["I_Plane_Fighter_03_dynamicLoadout_F", "I_Plane_Fighter_04_F"];

East_Air_Drone = ["I_E_UGV_01_F", "I_E_UAV_01_F"];

// ============================================================================
// GARRISON CONFIGURATION
// ============================================================================
OPFOR_Objective_Groups = [
    ["capital", [["infantry", 12], ["motorized", 2], ["mechanized", 1], ["air", 1], ["armor", 1], ["artillery", 1]]],
    ["city", [["infantry", 7], ["motorized", 2]]],
    ["village", [["infantry", 3]]],
    ["local", [["infantry", 6], ["motorized", 2], ["mechanized", 1]]],
    ["marine", [["infantry", 3], ["motorized", 1]]],
    ["cluster", [["infantry", 2]]]
];

OPFOR_Group_Counts = [
    ["infantry", 10],
    ["motorized", 1],
    ["mechanized", 1],
    ["armor", 1],
    ["helicopter", 1],
    ["jet", 1],
    ["air", 1],
    ["artillery", 3]
];

// ============================================================================
// VIRTUALIZATION SETTINGS
// ============================================================================
OPFOR_Objective_Size_Threshold = "Medium";
OPFOR_Virtualization_Distance = 2000;