// Where are Classnames? Right click on any Unit or Vehicle in the Editor and Select find in CFG viewer, Last Name in the [path] tab is the Classname,

// CUSTOM_ENEMY_FACTION_IAF.sqf
// Defines the Flex_CUP_IAF (Iranian Armed Forces) faction units and equipment for the mission
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
    "Flex_CUP_IAF_rifleman",
    "Flex_CUP_IAF_rifleman",
    "Flex_CUP_IAF_rifleman",
    "Flex_CUP_IAF_rifleman",
    "Flex_CUP_IAF_rifleman_lite",
    "Flex_CUP_IAF_rifleman_lite",
    "Flex_CUP_IAF_grenadier",
    "Flex_CUP_IAF_grenadier",
    "Flex_CUP_IAF_machinegunner",
    "Flex_CUP_IAF_machinegunner",
    "Flex_CUP_IAF_assistant",
    "Flex_CUP_IAF_assistant_mg",
    "Flex_CUP_IAF_assistant_at",
    "Flex_CUP_IAF_antitank",
    "Flex_CUP_IAF_antitank_light",
    "Flex_CUP_IAF_antitank_missle",
    "Flex_CUP_IAF_antiair",
    "Flex_CUP_IAF_medic",
    "Flex_CUP_IAF_medic",
    "Flex_CUP_IAF_marksman",
    "Flex_CUP_IAF_teamleader",
    "Flex_CUP_IAF_radioman",
    "Flex_CUP_IAF_officer",
    "Flex_CUP_IAF_demolition",
    "Flex_CUP_IAF_sniper",
    "Flex_CUP_IAF_rifleman_uav"
];

// groundSpecOps - Guerrilla (G_) and Paratrooper (P_) variants
East_Ground_SpecOps = [
    "Flex_CUP_IAF_G_rifleman",
    "Flex_CUP_IAF_G_rifleman_lite",
    "Flex_CUP_IAF_G_grenadier",
    "Flex_CUP_IAF_G_machinegunner",
    "Flex_CUP_IAF_G_antitank",
    "Flex_CUP_IAF_G_antitank_light",
    "Flex_CUP_IAF_G_antitank_missle",
    "Flex_CUP_IAF_G_antiair",
    "Flex_CUP_IAF_G_medic",
    "Flex_CUP_IAF_G_marksman",
    "Flex_CUP_IAF_G_sniper",
    "Flex_CUP_IAF_G_teamleader",
    "Flex_CUP_IAF_G_demolition",
    "Flex_CUP_IAF_G_officer",
    "Flex_CUP_IAF_recon_sniper",
    "Flex_CUP_IAF_recon_spotter",
    "Flex_CUP_IAF_P_paratrooper",
    "Flex_CUP_IAF_P_rifleman",
    "Flex_CUP_IAF_P_grenadier",
    "Flex_CUP_IAF_P_machinegunner",
    "Flex_CUP_IAF_P_antitank",
    "Flex_CUP_IAF_P_antitank_light",
    "Flex_CUP_IAF_P_antitank_missle",
    "Flex_CUP_IAF_P_antiair",
    "Flex_CUP_IAF_P_medic",
    "Flex_CUP_IAF_P_marksman",
    "Flex_CUP_IAF_P_sniper",
    "Flex_CUP_IAF_P_teamleader",
    "Flex_CUP_IAF_P_demolition",
    "Flex_CUP_IAF_P_officer",
    "Flex_CUP_IAF_P_radioman",
    "Flex_CUP_IAF_P_rifleman_uav"
];

// groundMotorized - Light wheeled armed vehicles
East_Ground_Motorized = [
    "Flex_CUP_IAF_UAZ_MG",
    "Flex_CUP_IAF_UAZ_AGS30",
    "Flex_CUP_IAF_UAZ_SPG9",
    "Flex_CUP_IAF_UAZ_METIS",
    "Flex_CUP_IAF_GAZ_Vodnik_PK",
    "Flex_CUP_IAF_GAZ_Vodnik_AGS",
    "Flex_CUP_IAF_GAZ_Vodnik_BPPU",
    "Flex_CUP_IAF_LSV_02_armed",
    "Flex_CUP_IAF_LSV_02_AT",
    "Flex_CUP_IAF_Boat_Armed_01_hmg"
];

// groundMechanized - APCs and IFVs
East_Ground_Mechanized = [
    "Flex_CUP_IAF_BMP1",
    "Flex_CUP_IAF_BMP2",
    "Flex_CUP_IAF_BTR90",
    "Flex_CUP_IAF_BTR90_HQ"
];

// groundArmor - Main battle tanks and light tanks
East_Ground_Armor = [
    "Flex_CUP_IAF_T90MS",
    "Flex_CUP_IAF_T72"
];

// groundTransport - Unarmed or lightly armed logistics/transport
East_Ground_Transport = [
    "Flex_CUP_IAF_Truck_Transport",
    "Flex_CUP_IAF_Truck_Covered",
    "Flex_CUP_IAF_G_Truck_Transport",
    "Flex_CUP_IAF_G_Truck_Covered",
    "Flex_CUP_IAF_UAZ_Unarmed",
    "Flex_CUP_IAF_GAZ_Vodnik_Unarmed",
    "Flex_CUP_IAF_LSV_02_unarmed",
    "Flex_CUP_IAF_Quadbike",
    "Flex_CUP_IAF_Boat_Transport",
    "Flex_CUP_IAF_RHIB_Unarmed"
];
East_Transport_Reserve_Ground_Count = 20;

// airTransport - Unarmed/transport helicopters and cargo aircraft
East_Air_Transport = [
    "Flex_CUP_IAF_Mi8",
    "Flex_CUP_IAF_CH47F",
    "Flex_CUP_IAF_CH47F_VIV",
    "Flex_CUP_IAF_Heli_Light_02_unarmed",
    "Flex_CUP_IAF_C130J",
    "Flex_CUP_IAF_C130J_Cargo"
];
East_Transport_Reserve_Air_Count = 10;

// airHeli - Attack and armed helicopters
East_Air_Heli = [
    "Flex_CUP_IAF_AH1Z_Dynamic",
    "Flex_CUP_IAF_Heli_Light_02"
];

// airJet - Fixed-wing combat aircraft
East_Air_Jet = [
    "Flex_CUP_IAF_Su25_Dyn"
];

// groundArtillery - Artillery pieces and MRL
East_Ground_Artillery = [
    "Flex_CUP_IAF_MBT_02_arty",
    "Flex_CUP_IAF_Truck_MRL",
    "Flex_CUP_IAF_D30",
    "Flex_CUP_IAF_Mortar"
];

// airDrone - Unmanned aerial vehicles
East_Air_Drone = [
    "Flex_CUP_IAF_UAV_04_CAS",
    "Flex_CUP_IAF_UAV_06",
    "Flex_CUP_IAF_UAV_01",
    "Flex_CUP_IAF_UAV_02_dynamicLoadout_F"
];

// mobileAA - Mobile anti-air vehicles
East_Mobile_AA = [
    "Flex_CUP_IAF_UAZ_AA",
    "Flex_CUP_IAF_ZSU23"
];

// staticAA - Static SAM systems
East_Static_AA = [
    "Flex_CUP_IAF_SAM_System",
    "Flex_CUP_IAF_Igla_AA_pod",
    "Flex_CUP_IAF_ZU23"
];

// radar
East_Radar = [
    "Flex_CUP_IAF_Radar_System"
];

// Fire observer pool for artillery support logic.
East_FireObserver = [
    "Flex_CUP_IAF_radioman",
    "Flex_CUP_IAF_rifleman_uav",
    "Flex_CUP_IAF_P_radioman",
    "Flex_CUP_IAF_P_rifleman_uav"
];

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
