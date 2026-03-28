// ============================================================================
// RUSSIAN AF DESERT FACTION - OPFOR (RHS Mod)
// Russian MSV forces in EMR/desert camouflage
// ============================================================================

/*
 * HOW THIS FILE FEEDS THE COMMANDER / VIRTUALIZATION
 *
 * You only edit the faction data in this file. Phase 2 builds the runtime pools
 * from these sections automatically:
 *
 *   groundInfantry   = East_Ground_Infantry
 *   groundSpecOps    = East_Ground_SpecOps
 *   groundMotorized  = East_Ground_Motorized
 *   groundMechanized = East_Ground_Mechanized
 *   groundArmor      = East_Ground_Armor
 *   groundTransport  = East_Ground_Transport
 *   groundArtillery  = East_Ground_Artillery
 *   airTransport     = East_Air_Transport
 *   airHeli          = East_Air_Heli
 *   airJet           = East_Air_Jet
 *   airDrone         = East_Air_Drone
 *   mobileAA         = East_Mobile_AA
 *   staticAA         = East_Static_AA
 *   radar            = East_Radar
 *
 * If you want to change what the commander can spawn, change the source data
 * that feeds the category above.
 */
// ============================================================================
// INFANTRY
// ============================================================================
// Mixed infantry source for groundInfantry.
// Entries may be full CfgGroups configs or individual unit classnames.
East_Ground_Infantry = [
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_msv" >> "rhs_group_rus_msv_infantry_des" >> "rhs_group_rus_msv_infantry_des_squad"),
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_msv" >> "rhs_group_rus_msv_infantry_des" >> "rhs_group_rus_msv_infantry_des_squad_2mg"),
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_msv" >> "rhs_group_rus_msv_infantry_des" >> "rhs_group_rus_msv_infantry_des_squad_sniper"),
    (configfile >> "CfgGroups" >> "East" >> "rhs_faction_msv" >> "rhs_group_rus_msv_infantry_des" >> "rhs_group_rus_msv_infantry_des_section_mg"),
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
// groundSpecOps
East_Ground_SpecOps = [];

// Fire observer pool for artillery support logic.
East_FireObserver = ["rhs_msv_emr_artyp"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
// groundMotorized
East_Ground_Motorized = [
    "rhs_tigr_m_msv", "rhs_tigr_sts_msv",
    "rhs_btr80_msv", "rhs_btr80a_msv"
];

// groundMechanized
East_Ground_Mechanized = [
    "rhs_bmp2d_msv", "rhs_bmp3_late_msv",
    "rhs_t72bd_tv", "rhs_t80uk", "rhs_t90sm_tv"
];
// groundArmor
East_Ground_Armor = [
    "rhs_bmp2d_msv", "rhs_bmp3_late_msv",
    "rhs_t72bd_tv", "rhs_t80uk", "rhs_t90sm_tv"
];

// groundTransport
East_Ground_Transport = [
    "RHS_Ural_Open_MSV_01", "RHS_Ural_MSV_01",
    "rhs_btr80_msv", "rhs_kamaz5350_msv"
];

// groundArtillery
East_Ground_Artillery = ["rhs_2s3_tv", "RHS_BM21_MSV_01", "rhs_D30_msv"];

// airTransport
East_Air_Transport = ["RHS_Mi8mt_Cargo_vvs", "RHS_Mi8MTV3_heavy_vvs", "RHS_Mi24V_vvs"];

// airHeli
East_Air_Heli = ["RHS_Mi24P_vvs", "RHS_Mi24V_vvs", "RHS_Mi28N_vvs", "RHS_Ka52_vvs"];

// airJet
East_Air_Jet = ["RHS_Su25SM_vvs", "rhs_mig29sm_vvs", "RHS_T50_vvs_generic_ext", "RHS_Su25SM3_vvs"];

// airDrone
East_Air_Drone = ["rhs_pchela1t_vvs"];

// mobileAA
East_Mobile_AA = ["rhs_zsu234_aa"];

// staticAA
East_Static_AA = ["rhs_S300_launcher_radar_F"];

// radar
East_Radar = ["rhs_S300_launcher_radar_F"];

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

