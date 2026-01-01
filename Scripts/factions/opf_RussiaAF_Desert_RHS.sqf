// ============================================================================
// RUSSIAN AF DESERT FACTION - OPFOR (RHS Mod)
// Russian MSV forces in EMR/desert camouflage
// ============================================================================

// ============================================================================
// INFANTRY GROUPS
// ============================================================================
East_Groups = [
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_msv" >> "rhs_group_rus_msv_infantry_des" >> "rhs_group_rus_msv_infantry_des_squad"),
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_msv" >> "rhs_group_rus_msv_infantry_des" >> "rhs_group_rus_msv_infantry_des_squad_2mg"),
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_msv" >> "rhs_group_rus_msv_infantry_des" >> "rhs_group_rus_msv_infantry_des_squad_sniper"),
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_msv" >> "rhs_group_rus_msv_infantry_des" >> "rhs_group_rus_msv_infantry_des_section_mg")
];

// ============================================================================
// INFANTRY UNITS
// ============================================================================
East_Units = [
    "rhs_msv_emr_rifleman", "rhs_msv_emr_rifleman",
    "rhs_msv_emr_arifleman", "rhs_msv_emr_arifleman",
    "rhs_msv_emr_grenadier", "rhs_msv_emr_grenadier",
    "rhs_msv_emr_sergeant",
    "rhs_msv_emr_officer",
    "rhs_msv_emr_marksman",
    "rhs_msv_emr_at",
    "rhs_msv_emr_machinegunner",
    "rhs_msv_emr_medic"
];

East_Units_Officers = ["rhs_msv_emr_officer"];
East_FireObserver = ["rhs_msv_emr_artyp"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
East_Ground_Vehicles_Ambient = [
    "rhs_uaz_open_msv", "rhs_uaz_msv",
    "RHS_Ural_Open_MSV_01", "RHS_Ural_MSV_01"
];

East_Ground_Vehicles_Light = [
    "rhs_tigr_m_msv", "rhs_tigr_sts_msv",
    "rhs_btr80_msv", "rhs_btr80a_msv"
];

East_Ground_Vehicles_Heavy = [
    "rhs_bmp2d_msv", "rhs_bmp3_late_msv",
    "rhs_t72bd_tv", "rhs_t80uk", "rhs_t90sm_tv"
];

East_Ground_Transport = [
    "RHS_Ural_Open_MSV_01", "RHS_Ural_MSV_01",
    "rhs_btr80_msv", "rhs_kamaz5350_msv"
];

East_Ground_Artillery = ["rhs_2s3_tv", "RHS_BM21_MSV_01", "rhs_D30_msv"];

East_Air_Transport = ["RHS_Mi8mt_Cargo_vvs", "RHS_Mi8MTV3_heavy_vvs", "RHS_Mi24V_vvs"];

East_Air_Heli = ["RHS_Mi24P_vvs", "RHS_Mi24V_vvs", "RHS_Mi28N_vvs", "RHS_Ka52_vvs"];

East_Air_Jet = ["RHS_Su25SM_vvs", "rhs_mig29sm_vvs", "RHS_T50_vvs_generic_ext", "RHS_Su25SM3_vvs"];

East_Air_Drone = ["rhs_pchela1t_vvs"];

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