// Where are Classnames ? Right click on any Unit or Vehicle in the Editor and Select find in CFG viewer, Last Name in the [path] tab is the Classname,

// CUSTOM_ENEMY_FACTION.sqf
// Defines the OPFOR faction units and equipment for the mission
// Used for both physical and virtual spawning through the virtualization system

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
 *
 */

/*
 * Unit and Vehicle Type Definitions
 * These arrays define what types of units and vehicles can spawn in the mission.
 */

// Mixed infantry source for groundInfantry.
// Entries may be full CfgGroups configs or individual unit classnames.
East_Ground_Infantry = [
    (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfSentry"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfTeam_AT"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfTeam_AA"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "I_InfTeam_Light"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfSquad"),
    (configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfSquad_Weapons"),
    "I_soldier_F", "I_soldier_F", "I_soldier_F", "I_soldier_F",
    "I_Soldier_AR_F", "I_Soldier_AR_F",
    "I_Soldier_CQ_F", "I_Soldier_CQ_F",
    "I_Soldier_GL_F", "I_Soldier_GL_F",
    "I_medic_F", "I_medic_F",
    "I_Soldier_MG_F", "I_Soldier_MG_F",
    "I_Soldier_M_F",
    "I_Soldier_A_F",
    "I_Soldier_LAT_F",
    "I_Soldier_LAT2_F",
    "I_Soldier_AT_F",
    "I_Soldier_AA_F"
];
// groundSpecOps
East_Ground_SpecOps = [];
// groundMotorized
East_Ground_Motorized = ["I_MRAP_03_F", "I_MRAP_03_gmg_F", "I_MRAP_03_hmg_F"];
// groundMechanized
East_Ground_Mechanized = ["I_APC_Wheeled_03_cannon_F", "I_APC_tracked_03_cannon_v2_F"];
// groundArmor
East_Ground_Armor = ["I_MBT_03_cannon_F", "I_LT_01_cannon_F", "I_LT_01_AT_F"];
// groundTransport
East_Ground_Transport = ["I_MRAP_03_F", "I_Truck_02_transport_F", "I_Truck_02_covered_F"]; 
// airTransport
East_Air_Transport = ["I_Heli_Transport_02_F", "Aegis_I_Heli_Transport_02_Heavy_F", "I_Heli_Light_01_F", "I_Heli_light_03_unarmed_F"];
// airHeli
East_Air_Heli = ["I_Heli_Attack_03_F", "I_Heli_Light_01_dynamicLoadout_F", "I_Heli_light_03_dynamicLoadout_F"]; 
// airJet
East_Air_Jet = ["I_Plane_Fighter_04_F", "I_Plane_Fighter_03_dynamicLoadout_F"]; 
// groundArtillery
East_Ground_Artillery = ["O_MBT_02_arty_F"]; 
// airDrone
East_Air_Drone = ["I_UAV_01_F"]; 
// mobileAA
East_Mobile_AA = ["I_LT_01_AA_F"];
// staticAA
East_Static_AA = ["O_SAM_System_04_F"];
// radar
East_Radar = ["O_Radar_System_02_F"];
// Fire observer pool for artillery support logic.
East_FireObserver = ["I_RadioOperator_F"];
