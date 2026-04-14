// ============================================================================
// CSAT WOODLAND FACTION - OPFOR (Vanilla)
// CSAT forces in woodland/GHEX camouflage
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
    (configfile >> "CfgGroups" >> "East" >> "OPF_T_F" >> "Infantry" >> "O_T_InfSentry"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_T_F" >> "Infantry" >> "O_T_InfTeam_AT"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_T_F" >> "Infantry" >> "O_T_InfTeam_AA"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_T_F" >> "Infantry" >> "O_T_InfTeam"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_T_F" >> "Support" >> "O_T_support_Mort"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_T_F" >> "Support" >> "O_T_support_MG"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_T_F" >> "Infantry" >> "O_T_InfSquad_Weapons"),
    "O_T_Soldier_F", "O_T_Soldier_F", "O_T_Soldier_F",
    "O_T_Soldier_AR_F", "O_T_Soldier_AR_F",
    "O_T_Soldier_GL_F", "O_T_Soldier_GL_F",
    "O_T_Medic_F", "O_T_Medic_F",
    "O_T_Soldier_M_F",
    "O_T_Soldier_TL_F",
    "O_T_Soldier_LAT_F",
    "O_T_Soldier_AT_F",
    "O_T_Soldier_Exp_F"
];
// groundSpecOps
East_Ground_SpecOps = [];

// Fire observer pool for artillery support logic.
East_FireObserver = ["O_T_Soldier_TL_F"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
// groundMotorized
East_Ground_Motorized = [
    "O_T_APC_Wheeled_02_rcws_v2_ghex_F", "O_T_MRAP_02_gmg_ghex_F", "O_T_MRAP_02_hmg_ghex_F",
    "O_T_LSV_02_AT_F", "O_T_LSV_02_armed_F", "O_T_UGV_01_rcws_ghex_F"
];

// groundMechanized
East_Ground_Mechanized = [
    "O_T_APC_Tracked_02_AA_ghex_F", "O_T_APC_Tracked_02_cannon_ghex_F",
    "O_T_MBT_02_cannon_ghex_F", "O_T_MBT_04_cannon_F"
];
// groundArmor
East_Ground_Armor = [
    "O_T_APC_Tracked_02_AA_ghex_F", "O_T_APC_Tracked_02_cannon_ghex_F",
    "O_T_MBT_02_cannon_ghex_F", "O_T_MBT_04_cannon_F"
];

// groundTransport
East_Ground_Transport = [
    "O_T_MRAP_02_ghex_F", "O_T_Truck_03_transport_ghex_F",
    "O_T_Truck_02_transport_F", "O_T_LSV_02_unarmed_F"
];
East_Transport_Reserve_Ground_Count = 20;

// groundArtillery
East_Ground_Artillery = ["O_MBT_02_arty_F"];

// airTransport
East_Air_Transport = ["O_Heli_Light_02_unarmed_F", "O_Heli_Transport_04_covered_F"];
East_Transport_Reserve_Air_Count = 10;

// airHeli
East_Air_Heli = ["O_Heli_Light_02_dynamicLoadout_F", "O_Heli_Attack_02_dynamicLoadout_F"];

// airJet
East_Air_Jet = ["O_T_VTOL_02_infantry_dynamicLoadout_F", "O_Plane_CAS_02_dynamicLoadout_F"];

// airDrone
East_Air_Drone = ["O_UAV_01_F"];

// mobileAA
East_Mobile_AA = ["O_T_APC_Tracked_02_AA_ghex_F"];

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

