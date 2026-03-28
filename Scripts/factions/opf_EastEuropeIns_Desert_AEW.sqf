// ============================================================================
// EAST EUROPEAN INSURGENTS DESERT FACTION - OPFOR (AEW Mod)
// Eastern European insurgent forces in desert camouflage
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
 *   transportReserveGroundCount = East_Transport_Reserve_Ground_Count
 *   groundArtillery  = East_Ground_Artillery
 *   airTransport     = East_Air_Transport
 *   transportReserveAirCount = East_Transport_Reserve_Air_Count
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
    "Opf_I_I_Soldier_1_F", "Opf_I_I_Soldier_2_F", "Opf_I_I_Soldier_3_F",
    "Opf_I_I_Soldier_4_F", "Opf_I_I_Soldier_5_F", "Opf_I_I_Soldier_6_F",
    "Opf_I_I_Soldier_7_F", "Opf_I_I_Soldier_8_F",
    "Opf_O_P_soldier_TL_F", "Opf_O_P_soldier_1_F", "Opf_O_P_soldier_LAT_F",
    "Opf_O_P_soldier_M_F", "Opf_O_P_soldier_GL_F", "Opf_O_P_soldier_AR_F",
    "Opf_O_P_soldier_exp_F", "Opf_O_P_medic_F"
];
// groundSpecOps
East_Ground_SpecOps = [];

// Fire observer pool for artillery support logic.
East_FireObserver = ["Opf_I_I_Soldier_1_F"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
// groundMotorized
East_Ground_Motorized = [
    "Opf_I_I_Offroad_01_armed_F", "Opf_O_S_APC_Tracked_02_cannon_F", "Opf_I_I_Offroad_01_AT_F"
];

// groundMechanized
East_Ground_Mechanized = [
    "Opf_O_S_APC_Tracked_02_cannon_F", "Opf_I_I_Offroad_01_AT_F", "Opf_I_I_Offroad_01_armed_F"
];
// groundArmor
East_Ground_Armor = [
    "Opf_O_S_APC_Tracked_02_cannon_F", "Opf_I_I_Offroad_01_AT_F", "Opf_I_I_Offroad_01_armed_F"
];

// groundTransport
East_Ground_Transport = ["Opf_I_I_Offroad_01_F", "Opf_I_I_Van_01_transport_F"];
East_Transport_Reserve_Ground_Count = 20;

// groundArtillery
East_Ground_Artillery = ["O_MBT_02_arty_F"];

// airTransport
East_Air_Transport = ["Opf_I_R_Heli_Light_02_unarmed_F"];
East_Transport_Reserve_Air_Count = 10;

// airHeli
East_Air_Heli = ["O_Heli_Light_02_dynamicLoadout_F"];

// airJet
East_Air_Jet = ["O_Heli_Light_02_dynamicLoadout_F"];

// airDrone
East_Air_Drone = ["O_UAV_01_F"];

// mobileAA
East_Mobile_AA = ["O_APC_Tracked_02_AA_F"];

// staticAA
East_Static_AA = ["O_SAM_System_04_F"];

// radar
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

