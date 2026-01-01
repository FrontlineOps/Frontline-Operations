// ============================================================================
// CSAT DESERT FACTION - OPFOR (Vanilla)
// CSAT forces in desert camouflage
// ============================================================================

// ============================================================================
// INFANTRY GROUPS
// ============================================================================
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfSentry"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfTeam_AT"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfTeam_AA"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfTeam"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Support" >> "OI_support_Mort"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Support" >> "OI_support_MG"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfSquad_Weapons")
];

// ============================================================================
// INFANTRY UNITS
// ============================================================================
East_Units = [
    "O_Soldier_F", "O_Soldier_F", "O_Soldier_F",
    "O_Soldier_AR_F", "O_Soldier_AR_F",
    "O_Soldier_GL_F", "O_Soldier_GL_F",
    "O_HeavyGunner_F", "O_HeavyGunner_F",
    "O_soldier_M_F",
    "O_Sharpshooter_F",
    "O_soldier_UAV_F",
    "O_Soldier_AT_F",
    "O_soldier_exp_F",
    "O_engineer_F",
    "O_Soldier_lite_F"
];

East_Units_Officers = ["O_officer_F", "O_T_Officer_F"];
East_FireObserver = ["O_T_Officer_F"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
East_Ground_Vehicles_Ambient = [
    "B_GEN_Offroad_01_gen_F", "B_GEN_Van_02_vehicle_F", "B_GEN_Van_02_transport_F",
    "B_GEN_Offroad_01_covered_F", "O_LSV_02_unarmed_F", "O_MRAP_02_F",
    "O_Truck_03_transport_F", "O_Truck_02_fuel_F", "O_Quadbike_01_F",
    "O_UGV_01_F", "O_Truck_02_covered_F", "O_Truck_02_transport_F"
];

East_Ground_Vehicles_Light = [
    "O_APC_Wheeled_02_rcws_v2_F", "O_MRAP_02_gmg_F", "O_MRAP_02_hmg_F",
    "O_LSV_02_AT_F", "O_LSV_02_armed_F"
];

East_Ground_Vehicles_Heavy = [
    "O_APC_Tracked_02_AA_F", "O_APC_Tracked_02_cannon_F",
    "O_MBT_02_cannon_F", "O_MBT_04_cannon_F"
];

East_Ground_Transport = [
    "O_MRAP_02_F", "O_Truck_03_transport_F",
    "O_Truck_02_transport_F", "O_LSV_02_unarmed_F"
];

East_Ground_Artillery = ["O_MBT_02_arty_F"];

East_Air_Transport = [
    "O_Heli_Light_02_dynamicLoadout_F", "O_Heli_Light_02_unarmed_F",
    "O_Heli_Transport_04_covered_F"
];

East_Air_Heli = [
    "O_Heli_Light_02_dynamicLoadout_F", "O_Heli_Attack_02_dynamicLoadout_F"
];

East_Air_Jet = ["O_Plane_Fighter_02_F", "O_Plane_CAS_02_dynamicLoadout_F"];

East_Air_Drone = ["O_UAV_01_F"];

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