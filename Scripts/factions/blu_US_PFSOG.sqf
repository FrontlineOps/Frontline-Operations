// ============================================================================
// US PFSOG FACTION - BLUFOR (Prairie Fire SOG DLC)
// US Forces for Vietnam-era operations
// ============================================================================

/*
 * HOW THIS FILE FEEDS THE COMMANDER / VIRTUALIZATION
 *
 * You only edit the faction data in this file. Phase 2 builds the runtime pools
 * from these sections automatically:
 *
 *   groundInfantry   = F_Officer + all F_Assault_* roles
 *   groundSpecOps    = all F_Recon_* + all F_Diver_* roles
 *   groundMotorized  = F_Car_List + F_MRAP_List
 *   groundMechanized = F_APC_List
 *   groundArmor      = F_Tank_List
 *   groundTransport  = F_Truck_List
 *   groundArtillery  = F_Artillery_List
 *   airTransport     = F_Heli_List + F_Heli_Respawn_List
 *   airHeli          = F_Heli_Gunship_List
 *   airJet           = F_Plane_List
 *   airDrone         = F_UAV_List
 *   groundDrone      = F_UGV_List
 *   staticAA         = F_SAM_List
 *   radar            = F_RADAR
 *   boat             = F_Boat_List
 *
 * If you want to change what the commander can spawn, change the source data
 * that feeds the category above. You do not need to define separate West_* pools here.
 */
// ============================================================================
// INFANTRY UNITS
// ============================================================================
// F_Officer + all F_Assault_* roles feed the commander groundInfantry pool.
// All F_Recon_* and F_Diver_* roles feed the commander groundSpecOps pool.
F_Officer = "vn_b_men_army_01";

F_Assault_Eng = "vn_b_men_army_04";
F_Assault_TL = "vn_b_men_army_15";
F_Assault_SL = "vn_b_men_army_02";
F_Assault_Eod = "vn_b_men_army_05";
F_Assault_Mrk = "vn_b_men_army_10";
F_Assault_AT = "vn_b_men_army_12";
F_Assault_Amm = "vn_b_men_army_08";
F_Assault_Mg = "vn_b_men_army_06";
F_Assault_Med = "vn_b_men_army_03";
F_Assault_Uav = "vn_b_men_army_19";

F_Recon_Snp = "vn_b_men_sf_21";
F_Recon_Sct = "vn_b_men_sf_04";
F_Recon_TL = "vn_b_men_sf_01";
F_Recon_Mrk = "vn_b_men_sf_13";
F_Recon_AT = "vn_b_men_sf_08";
F_Recon_Mg = "vn_b_men_sf_05";
F_Recon_Eod = "vn_b_men_sf_03";
F_Recon_Med = "vn_b_men_sf_02";
F_Recon_Eng = "vn_b_men_army_26";

F_Diver_TL = "vn_b_men_seal_32";
F_Diver_Rfl = "vn_b_men_seal_29";
F_Diver_Eod = "vn_b_men_seal_36";

// ============================================================================
// SQUAD COMPOSITIONS
// ============================================================================
F_ASSLT_ENG = [F_Assault_Eng, F_Assault_AT, F_Assault_Eod];
F_ASSLT_TEAM = [F_Assault_TL, F_Assault_Eod, F_Assault_AT, F_Assault_Mg, F_Assault_Mrk, F_Assault_Amm];
F_ASSLT_SQD = [F_Assault_SL, F_Assault_Eod, F_Assault_AT, F_Assault_Mg, F_Assault_Mrk, F_Assault_Amm, F_Assault_Med, F_Assault_AT, F_Assault_Mg, F_Assault_Mrk, F_Assault_Uav];
F_SNP_TEAM = [F_Recon_Snp, F_Recon_Sct];
F_RCN_TEAM = [F_Recon_TL, F_Recon_AT, F_Recon_Mrk, F_Recon_Mg];
F_RCN_SQD = [F_Recon_TL, F_Recon_AT, F_Recon_Eod, F_Recon_Mg, F_Recon_Eng, F_Recon_Mrk];
F_DVR_TEAM = [F_Diver_TL, F_Diver_Eod, F_Diver_Rfl, F_Diver_Eod];
F_OFFICER_TEAM = [F_Officer, F_Assault_Amm];

// ============================================================================
// BASE STRUCTURES
// ============================================================================
// F_RADAR feeds the commander radar pool.
F_RADAR = "I_E_Radar_System_01_F";
F_HQ_01 = "Land_Cargo_HQ_V1_F";
F_HQ_C_01 = "Land_TripodScreen_01_large_F";
F_OP_01 = "Land_Cargo_House_V1_F";
F_OP_C_01 = "Land_TripodScreen_01_dual_v2_F";

// ============================================================================
// VEHICLE LISTS - Format: [[classname, price], ...]
// ============================================================================
// These same lists also feed commander/virtualization pools as described above.

F_Bike_List = [
    ["B_T_Quadbike_01_F", 5]
];

// groundMotorized
F_Car_List = [
    ["vn_b_wheeled_m151_02_mp", 15],
    ["vn_b_wheeled_m151_01", 20],
    ["vn_b_wheeled_m151_mg_04", 40],
    ["vn_b_wheeled_m151_mg_02", 40],
    ["vn_b_wheeled_m151_mg_06", 50],
    ["vn_b_wheeled_m151_mg_05", 50]
];

// groundMotorized
F_MRAP_List = [];

// groundTransport
F_Truck_List = [
    ["vn_b_wheeled_m54_01_aus_army", 65],
    ["vn_b_wheeled_m54_03", 65]
];

F_Truck_Ammo_List = [
    ["vn_b_wheeled_m54_ammo", 100]
];

F_Truck_Construction_List = [
    ["vn_b_wheeled_m54_repair", 100]
];

F_Truck_Respawn_List = [];

// groundMechanized
F_APC_List = [
    ["vn_b_armor_m113_acav_04", 200],
    ["vn_b_armor_m113_acav_02", 200],
    ["vn_b_armor_m113_acav_06", 200],
    ["vn_b_armor_m113_acav_03", 200],
    ["vn_b_armor_m113_acav_05", 200],
    ["vn_b_armor_m113_01", 150]
];

// groundArmor
F_Tank_List = [
    ["vn_b_armor_m41_01_02", 500],
    ["vn_b_armor_m41_01_01", 500]
];

// groundArtillery
F_Artillery_List = [
    ["vn_b_army_static_m101_02", 75],
    ["vn_b_army_static_mortar_m29", 50],
    ["vn_b_army_static_mortar_m2", 50]
];

// airTransport
F_Heli_List = [
    ["vn_b_air_oh6a_01", 200],
    ["vn_b_air_uh1d_02_02", 300],
    ["vn_b_air_uh1d_01_01", 300],
    ["vn_b_air_uh1c_02_01", 400]
];

// airTransport
F_Heli_Respawn_List = [];

// airHeli
F_Heli_Gunship_List = [
    ["vn_b_air_oh6a_05", 400],
    ["vn_b_air_ah1g_07", 600],
    ["vn_b_air_ah1g_03", 600]
];

// airJet
F_Plane_List = [
    ["vn_b_air_f100d_cas", 1200],
    ["vn_b_air_f4b_navy_cas", 1500]
];

// boat
F_Boat_List = [
    ["vn_b_boat_11_01", 100],
    ["vn_b_boat_12_02", 150],
    ["vn_b_boat_05_02", 200]
];

// airDrone
F_UAV_List = [];

// groundDrone
F_UGV_List = [];

F_Container_List = [];

F_Turret_List = [
    ["vn_b_army_static_m1919a4_high", 35],
    ["vn_b_army_static_mk18", 35],
    ["vn_b_army_static_tow", 35]
];

// staticAA
F_SAM_List = [];

/*
 * BLUFOR Virtualization Objective Configuration
 * This section defines how many of each unit type should spawn at different
 * objective subtypes produced by the objective indexing system. Subtypes
 * include "capital", "city", "village", "local", "marine" and "cluster".
 *
 * Structure: [objective subtype, [[group type, count], [group type, count], ...]]
 */
BLUFOR_Objective_Groups = [
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
BLUFOR_Group_Counts = [
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

