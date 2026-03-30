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
 *   objectiveGroupTypeCaps = East_Objective_Group_Type_Caps
 *
 * If you want to change what the commander can spawn, change the source data
 * that feeds the category above.
 *
 * Optional side-wide objective seeding caps:
 *   East_Objective_Group_Type_Caps = [["artillery", 5], ["jet", 3]]
 * These caps apply across all owned seeded objectives combined, not per city.
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
East_Transport_Reserve_Ground_Count = 20;
// airTransport
East_Air_Transport = ["I_Heli_Transport_02_F", "Aegis_I_Heli_Transport_02_Heavy_F", "I_Heli_Light_01_F", "I_Heli_light_03_unarmed_F"];
East_Transport_Reserve_Air_Count = 10;
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

/*
 * OPFOR Virtualization Objective Configuration
 * This section defines how many of each unit type should spawn at different
 * objective subtypes produced by the objective indexing system. Subtypes
 * include "capital", "city", "village", "local", "marine" and "cluster".
 *
 * Structure: [objective subtype, [[group type, count], [group type, count], ...]]
 */
OPFOR_Objective_Groups = [
    // Capital objectives - highest concentration of defenders
    ["capital", [
        ["infantry", 12],
        ["motorized", 2],
        ["mechanized", 1],
        ["air", 1],
        ["armor", 1],
        ["artillery", 1],
        ["static_aa", 1],
        ["mobile_aa", 1]
    ]],

    // Major cities
    ["city", [
        ["infantry", 7],
        ["motorized", 2]
    ]],

    // Villages
    ["village", [
        ["infantry", 3]
    ]],

    // Small local objectives
    // These tend to be military bases, strategic infrastructure, or other military-like objectives
    ["local", [
        ["infantry", 6],
        ["motorized", 2],
        ["mechanized", 1],
        ["mobile_aa", 1]
    ]],

    // Coastal or marine facilities
    ["marine", [
        ["infantry", 3],
        ["motorized", 1]
    ]],

    // Automatically generated clusters
    ["cluster", [
        ["infantry", 2]
    ]]
];

/*
 * Optional side-wide objective seeding caps:
 *   East_Objective_Group_Type_Caps = [["artillery", 5], ["jet", 3]]
 * These caps apply across all owned seeded objectives combined.
 */
East_Objective_Group_Type_Caps = [
    ["jet", 10],
    ["helicopter", 10],
    ["artillery", 5],
    ["static_aa", 3],
    ["mobile_aa", 20]
];

/*
 * Group Type Unit/Vehicle Counts
 * Defines how many physical units/vehicles should be in each type of group
 */
OPFOR_Group_Counts = [
    ["infantry", 10],          // Number of individual soldiers
    ["motorized", 2],         // Number of armed vehicles (MRAP, GMG, etc.)
    ["mechanized", 2],        // Number of APCs/IFVs
    ["armor", 2],             // Number of tanks
    ["helicopter", 1],        // Number of helicopters
    ["jet", 1],               // Number of jets
    ["air", 1],               // Number of aircraft
    ["artillery", 3],         // Number of artillery pieces
    ["mobile_aa", 1],         // Number of mobile AA vehicles
    ["static_aa", 1]          // Number of static SAM launchers
];

