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
    (configfile >> "CfgGroups" >> "East" >> "UK3CB_GAF_O" >> "Infantry" >> "UK3CB_GAF_O_UGL_Sentry"),
    (configfile >> "CfgGroups" >> "East" >> "UK3CB_GAF_O" >> "Infantry" >> "UK3CB_GAF_O_AT_FireTeam"),
    (configfile >> "CfgGroups" >> "East" >> "UK3CB_GAF_O" >> "Infantry" >> "UK3CB_GAF_O_AA_FireTeam"),
    (configfile >> "CfgGroups" >> "East" >> "UK3CB_GAF_O" >> "Infantry" >> "UK3CB_GAF_O_MG_FireTeam"),
    (configfile >> "CfgGroups" >> "East" >> "UK3CB_GAF_O" >> "Infantry" >> "UK3CB_GAF_O_MG_Squad"),
    (configfile >> "CfgGroups" >> "East" >> "UK3CB_GAF_O" >> "Infantry" >> "UK3CB_GAF_O_RIF_Squad"),
    (configfile >> "CfgGroups" >> "East" >> "UK3CB_GAF_O" >> "Infantry" >> "UK3CB_GAF_O_UGL_FireTeam"),
    (configfile >> "CfgGroups" >> "East" >> "UK3CB_GAF_O" >> "Infantry" >> "UK3CB_GAF_O_AT_Squad"),
    (configfile >> "CfgGroups" >> "East" >> "UK3CB_GAF_O" >> "SpecOps" >> "UK3CB_GAF_O_Recon_SpecSquad"),
    (configfile >> "CfgGroups" >> "East" >> "UK3CB_GAF_O" >> "SpecOps" >> "UK3CB_GAF_O_Recon_SpecTeam"),
    (configfile >> "CfgGroups" >> "East" >> "UK3CB_GAF_O" >> "SpecOps" >> "UK3CB_GAF_O_SpecSniperTeam"),
];
// groundSpecOps
East_Ground_SpecOps = [];
// groundMotorized
East_Ground_Motorized = ["UK3CB_GAF_O_Offroad_AT", "UK3CB_GAF_O_UAZ_MG", "UK3CB_GAF_O_Offroad_HMG", "UK3CB_GAF_O_BRDM2_UM", "UK3CB_GAF_O_BRDM2_HQ", "UK3CB_GAF_O_BTR60", "UK3CB_GAF_O_BTR70", "UK3CB_GAF_O_BTR80", "UK3CB_GAF_O_BTR80a"];
// groundMechanized
East_Ground_Mechanized = ["UK3CB_GAF_O_BMD1", "UK3CB_GAF_O_BMD1K", "UK3CB_GAF_O_BMD1P", "UK3CB_GAF_O_BMD1PK", "UK3CB_GAF_O_BMD1R", "UK3CB_GAF_O_BMD2", "UK3CB_GAF_O_BMP1", "UK3CB_GAF_O_BMP2", "UK3CB_GAF_O_BMP2K", "UK3CB_GAF_O_BRM1K", "UK3CB_GAF_O_MTLB_Cannon", "UK3CB_GAF_O_MTLB_BMP", "UK3CB_GAF_O_MTLB_KPVT", "UK3CB_GAF_O_MTLB_PKT"];
// groundArmor
East_Ground_Armor = ["UK3CB_GAF_O_T55", "UK3CB_GAF_O_T72A", "UK3CB_GAF_O_T72B", "UK3CB_GAF_O_T72BA", "UK3CB_GAF_O_T72BB" "UK3CB_GAF_O_T72BC", "UK3CB_GAF_O_T80", "UK3CB_GAF_O_T80A", "UK3CB_GAF_O_T80B", "UK3CB_GAF_O_T80BK", "UK3CB_GAF_O_T80BV", "UK3CB_GAF_O_T80BVK", "UK3CB_GAF_O_T80U", "UK3CB_GAF_O_T80UK" ];
// groundTransport
East_Ground_Transport = ["UK3CB_GAF_O_Offroad_Covered", "UK3CB_GAF_O_Offroad", "UK3CB_GAF_O_Ural"];
East_Transport_Reserve_Ground_Count = 20;
// airTransport
East_Air_Transport = ["UK3CB_GAF_O_Mi8AMT", "UK3CB_GAF_O_Mi8", "UK3CB_GAF_O_Mi8AMTSh", "UK3CB_GAF_O_Mi_24V", "UK3CB_GAF_O_Mi_24G"];
East_Transport_Reserve_Air_Count = 10;
// airHeli
East_Air_Heli = ["UK3CB_GAF_O_Mi8AMTSh", "UK3CB_GAF_O_Mi_24V", "UK3CB_GAF_O_Mi_24P", "UK3CB_GAF_O_Mi_24G_UPK23", "UK3CB_GAF_O_Mi_24G_FAB", "UK3CB_GAF_O_Mi_24G"];
// airJet
East_Air_Jet = ["UK3CB_GAF_O_MIG21_AA", "UK3CB_GAF_O_MIG21_AT", "UK3CB_GAF_O_MIG21", "UK3CB_GAF_O_MIG21_CAS", "UK3CB_GAF_O_MIG29S", "UK3CB_GAF_O_MIG29SM", "UK3CB_GAF_O_Su25SM", "UK3CB_GAF_O_Su25SM_CAS", "UK3CB_GAF_O_Su25SM_Cluster", "UK3CB_GAF_O_Su25SM_KH29"];
// groundArtillery
East_Ground_Artillery = ["UK3CB_GAF_O_2S1", "UK3CB_GAF_O_BM21", "UK3CB_GAF_O_D30"];
// airDrone
East_Air_Drone = ["UK3CB_GAF_O_Drone_Bombs"];
// mobileAA
East_Mobile_AA = ["UK3CB_GAF_O_2S6M_Tunguska", "UK3CB_GAF_O_MTLB_ZU23", "UK3CB_GAF_O_Ural_Zu23", "UK3CB_GAF_O_ZsuTank"];
// staticAA
East_Static_AA = ["UK3CB_GAF_O_ZU23"];
// radar
East_Radar = ["rhs_p37_turret_vpvo", "rhs_p37_turret_vpvo"];
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
        ["motorized", 2],
        ["mechanized", 1],
        ["air", 1],
        ["armor", 1],
        ["artillery", 1],
        ["static_aa", 1],
        ["mobile_aa", 1]
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
    ["motorized", 1],         // Number of armed vehicles (MRAP, GMG, etc.)
    ["mechanized", 1],        // Number of APCs/IFVs
    ["armor", 1],             // Number of tanks
    ["helicopter", 1],        // Number of helicopters
    ["jet", 1],               // Number of jets
    ["air", 1],               // Number of aircraft
    ["artillery", 3],         // Number of artillery pieces
    ["mobile_aa", 1],         // Number of mobile AA vehicles
    ["static_aa", 1]          // Number of static SAM launchers
];
