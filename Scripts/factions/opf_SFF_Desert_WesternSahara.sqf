// ============================================================================
// SFF DESERT FACTION - OPFOR (Western Sahara DLC)
// SFIA forces in desert camouflage
// ============================================================================

// ============================================================================
// INFANTRY GROUPS
// ============================================================================
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "OPF_SFIA_lxWS" >> "Infantry" >> "OSFIA_InfTeam_lxWS"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_SFIA_lxWS" >> "Infantry" >> "OSFIA_InfSquad_lxWS")
];

// ============================================================================
// INFANTRY UNITS
// ============================================================================
East_Units = [
    "O_SFIA_soldier_lxWS", "O_SFIA_soldier_lxWS",
    "O_SFIA_Soldier_AR_lxWS", "O_SFIA_Soldier_AR_lxWS",
    "O_SFIA_Soldier_GL_lxWS", "O_SFIA_Soldier_GL_lxWS",
    "O_SFIA_sharpshooter_lxWS",
    "O_SFIA_Soldier_TL_lxWS",
    "O_SFIA_Soldier_universal_lxWS",
    "O_SFIA_soldier_aa_lxWS",
    "O_SFIA_soldier_at_lxWS",
    "O_SFIA_medic_lxWS",
    "O_SFIA_exp_lxWS",
    "O_SFIA_repair_lxWS"
];

East_Units_Officers = ["O_SFIA_officer_lxWS"];
East_FireObserver = ["O_SFIA_Soldier_TL_lxWS"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
East_Ground_Vehicles_Ambient = [
    "O_SFIA_Truck_02_covered_lxWS", "I_C_Offroad_02_AT_F", "I_C_Offroad_02_LMG_F",
    "O_SFIA_Offroad_lxWS", "I_C_Offroad_02_unarmed_F",
    "O_SFIA_Truck_02_transport_lxWS", "O_T_Quadbike_01_ghex_F"
];

East_Ground_Vehicles_Light = [
    "O_SFIA_Offroad_armed_lxWS", "I_C_Offroad_02_LMG_F", "I_C_Offroad_02_AT_F",
    "O_SFIA_Offroad_AT_lxWS", "O_SFIA_Truck_02_aa_lxWS", "O_SFIA_Truck_02_MRL_lxWS"
];

East_Ground_Vehicles_Heavy = [
    "O_SFIA_APC_Tracked_02_30mm_lxWS", "O_SFIA_APC_Wheeled_02_hmg_lxWS", "O_SFIA_Truck_02_aa_lxWS"
];

East_Ground_Transport = [
    "O_SFIA_Offroad_lxWS", "O_SFIA_Truck_02_transport_lxWS", "O_SFIA_Truck_02_covered_lxWS"
];

East_Ground_Artillery = ["O_MBT_02_arty_F"];

East_Air_Transport = ["O_Heli_Light_02_dynamicLoadout_F", "O_Heli_Transport_04_covered_F"];

East_Air_Heli = ["O_SFIA_Heli_Attack_02_dynamicLoadout_lxWS"];

East_Air_Jet = ["O_SFIA_Heli_Attack_02_dynamicLoadout_lxWS"];

East_Air_Drone = ["O_UAV_01_F"];

East_Mobile_AA = ["O_SFIA_Truck_02_aa_lxWS"];

East_Static_AA = ["O_SAM_System_04_F"];

East_Radar = ["O_Radar_System_02_F"];

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