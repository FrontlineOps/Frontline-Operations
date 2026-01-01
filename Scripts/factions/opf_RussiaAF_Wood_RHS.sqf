// ============================================================================
// RUSSIAN AF WOODLAND FACTION - OPFOR (RHS Mod)
// Russian VDV forces in flora camouflage
// ============================================================================

// ============================================================================
// INFANTRY GROUPS
// ============================================================================
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_vdv" >> "rhs_group_rus_vdv_infantry_flora" >> "rhs_group_rus_vdv_infantry_flora_fireteam"),
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_vdv" >> "rhs_group_rus_vdv_infantry_flora" >> "rhs_group_rus_vdv_infantry_flora_section_AT"),
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_vdv" >> "rhs_group_rus_vdv_infantry_flora" >> "rhs_group_rus_vdv_infantry_flora_section_AA"),
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_vdv" >> "rhs_group_rus_vdv_infantry_flora" >> "rhs_group_rus_vdv_infantry_flora_squad_mg_sniper"),
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_vdv" >> "rhs_group_rus_vdv_infantry_flora" >> "rhs_group_rus_vdv_infantry_flora_squad_2mg")
];

// ============================================================================
// INFANTRY UNITS
// ============================================================================
East_Units = [
    "rhs_vdv_flora_rifleman", "rhs_vdv_flora_rifleman", "rhs_vdv_flora_rifleman",
    "rhs_vdv_flora_machinegunner", "rhs_vdv_flora_machinegunner",
    "rhs_vdv_flora_grenadier", "rhs_vdv_flora_grenadier",
    "rhs_vdv_flora_medic", "rhs_vdv_flora_medic",
    "rhs_vdv_flora_marksman",
    "rhs_vdv_flora_efreitor",
    "rhs_vdv_flora_LAT",
    "rhs_vdv_flora_at",
    "rhs_vdv_flora_engineer"
];

East_Units_Officers = ["rhs_vdv_des_officer", "rhs_vdv_flora_officer"];
East_FireObserver = ["rhs_vdv_des_officer"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
East_Ground_Vehicles_Ambient = [
    "rhs_tigr_sts_msv", "rhs_tigr_msv", "rhs_gaz66o_msv",
    "rhs_gaz66_repair_msv", "rhs_gaz66_vdv"
];

East_Ground_Vehicles_Light = ["rhs_btr60_vmf", "rhs_tigr_sts_msv"];

East_Ground_Vehicles_Heavy = [
    "rhs_zsu234_aa", "rhs_Ob_681_2", "rhs_bmp2_tv", "rhs_bmp1_tv",
    "rhs_t72be_tv", "rhs_t80bvk", "rhs_t90sm_tv"
];

East_Ground_Transport = ["rhs_tigr_msv", "rhs_gaz66_msv", "rhs_gaz66o_msv"];

East_Ground_Artillery = ["O_MBT_02_arty_F"];

East_Air_Transport = ["rhs_ka60_c", "RHS_Mi8mt_vvsc", "RHS_Mi8MTV3_heavy_vvsc"];

East_Air_Heli = ["RHS_Ka52_vvsc", "RHS_Mi24P_vdv"];

East_Air_Jet = ["rhs_mig29sm_vvsc", "RHS_Su25SM_vvsc"];

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