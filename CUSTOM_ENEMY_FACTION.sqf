// Where are Classnames ? Right click on any Unit or Vehicle in the Editor and Select find in CFG viewer, Last Name in the [path] tab is the Classname,

// CUSTOM_ENEMY_FACTION.sqf
// Defines the OPFOR faction units and equipment for the mission
// Used for both physical and virtual spawning through the virtualization system

/*
 * Unit and Vehicle Type Definitions
 * These arrays define what types of units and vehicles can spawn in the mission.
*/

// Mixed infantry source. Entries may be full CfgGroups configs or individual unit classnames.
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
East_Ground_SpecOps = [];
// Light wheeled combat vehicles
East_Ground_Motorized = ["I_MRAP_03_F", "I_MRAP_03_gmg_F", "I_MRAP_03_hmg_F"];
// APCs and IFVs
East_Ground_Mechanized = ["I_APC_Wheeled_03_cannon_F", "I_APC_tracked_03_cannon_v2_F"];
// Tanks and assault armor
East_Ground_Armor = ["I_MBT_03_cannon_F", "I_LT_01_cannon_F", "I_LT_01_AT_F"];
// Transport Ground Vehicles
East_Ground_Transport = ["I_MRAP_03_F", "I_Truck_02_transport_F", "I_Truck_02_covered_F"]; 
// Transport Air Vehicles
East_Air_Transport = ["I_Heli_Transport_02_F", "Aegis_I_Heli_Transport_02_Heavy_F", "I_Heli_Light_01_F", "I_Heli_light_03_unarmed_F"];
// Armed Helicopters
East_Air_Heli = ["I_Heli_Attack_03_F", "I_Heli_Light_01_dynamicLoadout_F", "I_Heli_light_03_dynamicLoadout_F"]; 
// Fixed-Wing Aircraft
East_Air_Jet = ["I_Plane_Fighter_04_F", "I_Plane_Fighter_03_dynamicLoadout_F"]; 
// Artillery Units
East_Ground_Artillery = ["O_MBT_02_arty_F"]; 
// Drone Units
East_Air_Drone = ["I_UAV_01_F"]; 
// Mobile AA - Tracked/Wheeled AA vehicles
East_Mobile_AA = ["I_LT_01_AA_F"];
// Static AA - Emplaced SAM launchers
East_Static_AA = ["O_SAM_System_04_F"];
// Radar Systems
East_Radar = ["O_Radar_System_02_F"];
// Fire Observer Units for Artillery
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

