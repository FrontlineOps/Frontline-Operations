// ============================================================================
// TTI DESERT FACTION - OPFOR (Western Sahara DLC)
// Tura insurgent forces in desert camouflage
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
    (configfile >> "CfgGroups" >> "East" >> "OPF_TURA_lxWS" >> "Infantry" >> "B_Tura_InfTeam_lxWS"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_TURA_lxWS" >> "Infantry" >> "B_Tura_InfSquad_lxWS"),
    "O_Tura_watcher_lxWS", "O_Tura_watcher_lxWS",
    "O_Tura_enforcer_lxWS", "O_Tura_enforcer_lxWS",
    "O_Tura_thug_lxWS", "O_Tura_thug_lxWS",
    "O_Tura_scout_lxWS",
    "O_Tura_deserter_lxWS",
    "O_Tura_hireling_lxWS",
    "O_Tura_medic2_lxWS"
];
// groundSpecOps
East_Ground_SpecOps = [];

// Fire observer pool for artillery support logic.
East_FireObserver = ["O_Tura_watcher_lxWS"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
// groundMotorized
East_Ground_Motorized = [
    "O_Tura_Offroad_armor_lxWS", "O_Tura_Offroad_armor_AT_lxWS",
    "O_Tura_Offroad_armor_armed_lxWS", "O_SFIA_Offroad_AT_lxWS",
    "I_C_Offroad_02_LMG_F", "O_Tura_Truck_02_aa_lxWS"
];

// groundMechanized
East_Ground_Mechanized = [
    "O_SFIA_APC_Tracked_02_cannon_lxWS", "O_Tura_Truck_02_aa_lxWS", "O_SFIA_Truck_02_MRL_lxWS"
];
// groundArmor
East_Ground_Armor = [
    "O_SFIA_APC_Tracked_02_cannon_lxWS", "O_Tura_Truck_02_aa_lxWS", "O_SFIA_Truck_02_MRL_lxWS"
];

// groundTransport
East_Ground_Transport = [
    "O_Tura_Offroad_armor_lxWS", "O_SFIA_Truck_02_transport_lxWS", "O_SFIA_Offroad_lxWS"
];
East_Transport_Reserve_Ground_Count = 20;

// groundArtillery
East_Ground_Artillery = ["O_MBT_02_arty_F"];

// airTransport
East_Air_Transport = ["I_C_Heli_Light_01_civil_F", "O_Heli_Transport_04_covered_F"];
East_Transport_Reserve_Air_Count = 10;

// airHeli
East_Air_Heli = ["O_Heli_Light_02_dynamicLoadout_F"];

// airJet
East_Air_Jet = ["O_Heli_Light_02_dynamicLoadout_F"];

// airDrone
East_Air_Drone = ["O_UAV_01_F"];

// mobileAA
East_Mobile_AA = ["O_Tura_Truck_02_aa_lxWS"];

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

