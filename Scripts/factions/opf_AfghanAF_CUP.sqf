// ============================================================================
// AFGHAN AF FACTION - OPFOR (CUP Mod)
// Afghan Armed Forces (Takistani Army)
// ============================================================================

// ============================================================================
// INFANTRY GROUPS
// ============================================================================
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySection"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySectionAT"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySectionAA"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySectionMG"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySquad")
];

// ============================================================================
// INFANTRY UNITS
// ============================================================================
East_Units = [
    "CUP_O_TK_Soldier", "CUP_O_TK_Soldier",
    "CUP_O_TK_Soldier_AR", "CUP_O_TK_Soldier_AR",
    "CUP_O_TK_Soldier_GL", "CUP_O_TK_Soldier_GL",
    "CUP_O_TK_Soldier_SL",
    "CUP_O_TK_Soldier_MG",
    "CUP_O_TK_Sniper",
    "CUP_O_TK_Soldier_AT",
    "CUP_O_TK_Soldier_HAT",
    "CUP_O_TK_Engineer",
    "CUP_O_TK_Soldier_Backpack"
];

East_Units_Officers = ["CUP_O_TK_Officer"];
East_FireObserver = ["CUP_O_TK_Soldier_SL"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
East_Ground_Vehicles_Ambient = [
    "CUP_O_LR_Transport_TKA", "CUP_O_Ural_TKA", "CUP_O_UAZ_Open_TKA",
    "CUP_O_LR_MG_TKM", "CUP_O_Hilux_AGS30_TK_INS", "CUP_O_Hilux_DSHKM_TK_INS",
    "CUP_O_Hilux_M2_TK_INS", "CUP_O_Hilux_SPG9_TK_INS",
    "CUP_O_BTR40_MG_TKM", "CUP_O_MTLB_pk_TK_MILITIA"
];

East_Ground_Vehicles_Light = [
    "CUP_O_LR_MG_TKM", "CUP_O_Hilux_AGS30_TK_INS", "CUP_O_Hilux_DSHKM_TK_INS",
    "CUP_O_Hilux_M2_TK_INS", "CUP_O_Hilux_SPG9_TK_INS",
    "CUP_O_BTR40_MG_TKM", "CUP_O_MTLB_pk_TK_MILITIA"
];

East_Ground_Vehicles_Heavy = [
    "CUP_O_BTR80_TK", "CUP_O_BTR80A_TK", "CUP_O_BMP1P_TKA", "CUP_O_BMP2_TKA",
    "CUP_O_ZSU23_Afghan_TK", "CUP_O_ZSU23_TK", "CUP_O_BMP2_ZU_TKA",
    "CUP_O_T55_TK", "CUP_O_T72_TKA"
];

East_Ground_Transport = ["CUP_O_LR_Transport_TKA", "CUP_O_Ural_TKA", "CUP_O_UAZ_Open_TKA"];

East_Ground_Artillery = ["O_MBT_02_arty_F"];

East_Air_Transport = ["CUP_O_UH1H_TKA", "CUP_O_Mi17_TK"];

East_Air_Heli = ["CUP_O_UH1H_gunship_TKA", "CUP_O_Mi24_D_Dynamic_TK"];

East_Air_Jet = ["CUP_O_Su25_Dyn_TKA"];

East_Air_Drone = ["O_UAV_01_F"];

East_Mobile_AA = ["CUP_O_ZSU23_Afghan_TK", "CUP_O_ZSU23_TK"];

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