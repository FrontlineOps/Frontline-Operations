// ============================================================================
// CSAT DESERT FACTION - OPFOR (Vanilla)
// CSAT forces in desert camouflage
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
    (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfSentry"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfTeam_AT"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfTeam_AA"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfTeam"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Support" >> "OI_support_Mort"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Support" >> "OI_support_MG"),
    (configfile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfSquad_Weapons"),
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
// groundSpecOps
East_Ground_SpecOps = [];

// Fire observer pool for artillery support logic.
East_FireObserver = ["O_T_Officer_F"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
// groundMotorized
East_Ground_Motorized = [
    "O_APC_Wheeled_02_rcws_v2_F", "O_MRAP_02_gmg_F", "O_MRAP_02_hmg_F",
    "O_LSV_02_AT_F", "O_LSV_02_armed_F"
];

// groundMechanized
East_Ground_Mechanized = [
    "O_APC_Tracked_02_AA_F", "O_APC_Tracked_02_cannon_F",
    "O_MBT_02_cannon_F", "O_MBT_04_cannon_F"
];
// groundArmor
East_Ground_Armor = [
    "O_APC_Tracked_02_AA_F", "O_APC_Tracked_02_cannon_F",
    "O_MBT_02_cannon_F", "O_MBT_04_cannon_F"
];

// groundTransport
East_Ground_Transport = [
    "O_MRAP_02_F", "O_Truck_03_transport_F",
    "O_Truck_02_transport_F", "O_LSV_02_unarmed_F"
];

// groundArtillery
East_Ground_Artillery = ["O_MBT_02_arty_F"];

// airTransport
East_Air_Transport = [
    "O_Heli_Light_02_dynamicLoadout_F", "O_Heli_Light_02_unarmed_F",
    "O_Heli_Transport_04_covered_F"
];

// airHeli
East_Air_Heli = [
    "O_Heli_Light_02_dynamicLoadout_F", "O_Heli_Attack_02_dynamicLoadout_F"
];

// airJet
East_Air_Jet = ["O_Plane_Fighter_02_F", "O_Plane_CAS_02_dynamicLoadout_F"];

// airDrone
East_Air_Drone = ["O_UAV_01_F"];

// mobileAA
East_Mobile_AA = ["O_APC_Tracked_02_AA_F"];

// staticAA
East_Static_AA = ["O_SAM_System_04_F"];

// radar
East_Radar = ["O_Radar_System_02_F"];
