// ============================================================================
// LDF WOODLAND FACTION - OPFOR (Vanilla)
// Livonian Defense Force in woodland camouflage
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
    (configfile >> "CfgGroups" >> "Indep" >> "IND_E_F" >> "Infantry" >> "I_E_InfSentry"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_E_F" >> "Infantry" >> "I_E_InfTeam"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_E_F" >> "Infantry" >> "I_E_InfSquad"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_E_F" >> "Infantry" >> "I_E_InfTeam_AT"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_E_F" >> "Infantry" >> "I_E_InfTeam_AA"),
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
// groundSpecOps
East_Ground_SpecOps = [];

// Fire observer pool for artillery support logic.
East_FireObserver = ["I_E_RadioOperator_F"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
// groundMotorized
East_Ground_Motorized = [
    "I_E_UGV_01_rcws_F", "O_G_Offroad_01_armed_F",
    "O_G_Offroad_01_AT_F", "I_E_Offroad_01_armed_F"
];

// groundMechanized
East_Ground_Mechanized = [
    "I_E_APC_tracked_03_cannon_F", "I_E_APC_Wheeled_03_cannon_F"
];
// groundArmor
East_Ground_Armor = [
    "I_E_APC_tracked_03_cannon_F", "I_E_APC_Wheeled_03_cannon_F"
];

// groundTransport
East_Ground_Transport = [
    "I_E_Van_02_transport_F", "I_E_Offroad_01_F", "I_E_Offroad_01_covered_F",
    "I_E_Truck_02_F", "I_E_Truck_02_transport_F"
];
East_Transport_Reserve_Ground_Count = 20;

// groundArtillery
East_Ground_Artillery = ["I_E_Truck_02_MRL_F", "I_E_Mortar_01_F"];

// airTransport
East_Air_Transport = ["I_Heli_Transport_02_F", "I_E_Heli_light_03_unarmed_F"];
East_Transport_Reserve_Air_Count = 10;

// airHeli
East_Air_Heli = ["I_E_Heli_light_03_dynamicLoadout_F"];

// airJet
East_Air_Jet = ["I_Plane_Fighter_03_dynamicLoadout_F", "I_Plane_Fighter_04_F"];

// airDrone
East_Air_Drone = ["I_E_UGV_01_F", "I_E_UAV_01_F"];

// mobileAA
East_Mobile_AA = ["I_LT_01_AA_F"];

// staticAA
East_Static_AA = ["B_SAM_System_03_F"];

// radar
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

