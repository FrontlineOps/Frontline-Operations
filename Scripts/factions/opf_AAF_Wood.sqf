// ============================================================================
// AAF WOODLAND FACTION - OPFOR (Vanilla)
// Altis Armed Forces in woodland camouflage
// ============================================================================

// ============================================================================
// INFANTRY GROUPS
// ============================================================================
East_Groups = [
    (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfSentry"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfTeam_AT"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfTeam_AA"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "I_InfTeam_Light"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfSquad"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfSquad_Weapons")
];

// ============================================================================
// INFANTRY UNITS
// ============================================================================
East_Units = [
    "I_Soldier_F", "I_Soldier_F",
    "I_Soldier_AR_F", "I_Soldier_AR_F",
    "I_Soldier_GL_F", "I_Soldier_GL_F",
    "I_Soldier_M_F",
    "I_Soldier_LAT2_F",
    "I_Soldier_TL_F",
    "I_Soldier_SL_F",
    "I_engineer_F",
    "I_medic_F",
    "I_Soldier_lite_F"
];

East_Units_Officers = ["I_officer_F"];
East_FireObserver = ["I_Soldier_SL_F"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
East_Ground_Vehicles_Ambient = [
    "I_MRAP_03_F", "I_MRAP_03_gmg_F", "I_Truck_02_covered_F",
    "I_Truck_02_ammo_F", "I_Truck_02_fuel_F", "I_Truck_02_transport_F"
];

East_Ground_Vehicles_Light = [
    "I_MRAP_03_hmg_F", "I_MRAP_03_gmg_F", "I_APC_Wheeled_03_cannon_F",
    "I_LT_01_cannon_F", "I_LT_01_AA_F"
];

East_Ground_Vehicles_Heavy = [
    "I_APC_tracked_03_cannon_F", "I_MBT_03_cannon_F"
];

East_Ground_Transport = [
    "I_MRAP_03_F", "I_Truck_02_covered_F", "I_Truck_02_transport_F"
];

East_Ground_Artillery = ["O_MBT_02_arty_F"];

East_Air_Transport = ["I_Heli_Transport_02_F", "I_Heli_light_03_unarmed_F"];

East_Air_Heli = ["I_Heli_light_03_dynamicLoadout_F"];

East_Air_Jet = ["I_Plane_Fighter_03_dynamicLoadout_F", "I_Plane_Fighter_04_F"];

East_Air_Drone = ["O_UAV_01_F"];

East_Mobile_AA = ["I_LT_01_AA_F"];

East_Static_AA = ["B_SAM_System_03_F"];

East_Radar = ["B_Radar_System_01_F"];

// ============================================================================
// GARRISON CONFIGURATION
// ============================================================================
OPFOR_Objective_Groups = [
    ["capital", [["infantry", 12], ["motorized", 2], ["mechanized", 1], ["air", 1], ["armor", 1], ["artillery", 1], ["mobile_aa", 1], ["static_aa", 1]]],
    ["city", [["infantry", 7], ["motorized", 2]]],
    ["village", [["infantry", 3]]],
    ["local", [["infantry", 6], ["motorized", 2], ["mechanized", 1], ["mobile_aa", 1]]],
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
    ["artillery", 3],
    ["mobile_aa", 1],
    ["static_aa", 1]
];

// ============================================================================
// VIRTUALIZATION SETTINGS
// ============================================================================
OPFOR_Objective_Size_Threshold = "Medium";
OPFOR_Virtualization_Distance = 2000;