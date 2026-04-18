// ============================================================================
// AAF FACTION - Indfor
// Vanilla Arma 3 AAF units 
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
 *   transportReserveGroundCount = West_Transport_Reserve_Ground_Count
 *   groundArtillery  = F_Artillery_List
 *   airTransport     = F_Heli_List + F_Heli_Respawn_List
 *   transportReserveAirCount = West_Transport_Reserve_Air_Count
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
F_Officer = "B_officer_F";

F_Assault_Eng = "I_engineer_F";
F_Assault_TL = "I_Soldier_TL_F";
F_Assault_SL = "I_Soldier_SL_F";
F_Assault_Eod = "I_Soldier_exp_F";
F_Assault_Mrk = "I_Soldier_M_F";
F_Assault_AT = "I_Soldier_AT_F";
F_Assault_Amm = "I_Soldier_A_F";
F_Assault_Mg = "I_Soldier_AR_F";
F_Assault_Med = "I_medic_F";
F_Assault_Uav = "I_soldier_UAV_F";

F_Recon_Snp = "I_Sniper_F";
F_Recon_Sct = "I_Soldier_lite_F";
F_Recon_TL = "I_Soldier_lite_F";
F_Recon_Mrk = "I_Soldier_lite_F";
F_Recon_AT = "I_Soldier_LAT_F";
F_Recon_Mg = "I_Soldier_AR_F";
F_Recon_Eod = "I_Soldier_exp_F";
F_Recon_Med = "I_medic_F";
F_Recon_Eng = "I_engineer_F";

F_Diver_TL = "I_diver_TL_F";
F_Diver_Rfl = "I_diver_F";
F_Diver_Eod = "I_diver_exp_F";

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
F_RADAR = "B_Radar_System_01_F";
F_HQ_01 = "Land_Cargo_HQ_V3_F";
F_HQ_C_01 = "Land_TripodScreen_01_large_sand_F";
F_OP_01 = "Land_Cargo_House_V3_F";
F_OP_C_01 = "Land_TripodScreen_01_dual_v2_sand_F";

// ============================================================================
// VEHICLE LISTS - Format: [[classname, price], ...]
// ============================================================================
// These same lists also feed commander/virtualization pools as described above.

F_Bike_List = [
    ["I_Quadbike_01_F", 5]
];

// groundMotorized
F_Car_List = [
    ["I_G_Offroad_01_F", 200],
	["C_Offroad_01_comms_F", 200],
    ["I_G_Offroad_01_armed_F", 500],
    ["I_G_Offroad_01_AT_F", 600]
];

// groundMotorized
F_MRAP_List = [
    ["I_MRAP_03_F", 500],
    ["I_MRAP_03_hmg_F", 700],
    ["I_MRAP_03_gmg_F", 1000]
];

// groundTransport
F_Truck_List = [
    ["I_Truck_02_transport_F", 650],
    ["I_Truck_02_covered_F", 650]
];
West_Transport_Reserve_Ground_Count = 20;

F_Truck_Ammo_List = [
    ["I_Truck_02_ammo_F", 1000]
];

F_Truck_Construction_List = [
    ["I_Truck_02_box_F", 1000]
];

F_Truck_Respawn_List = [
    ["I_Truck_02_medical_F", 1500]
];

// groundMechanized
F_APC_List = [
	["I_LT_01_cannon_F", 1500],
	["I_LT_01_AT_F", 2000],
	["I_LT_01_scout_F", 1000],
    ["I_APC_tracked_03_cannon_F", 3000],
    ["I_APC_Wheeled_03_cannon_F", 4000]
];

// groundArmor
F_Tank_List = [
    ["I_MBT_03_cannon_F", 5000]
];

// groundArtillery
F_Artillery_List = [
    ["I_Mortar_01_F", 750],
    ["I_Truck_02_MRL_F", 5000]
];

// airTransport
F_Heli_List = [
    ["I_Heli_light_03_unarmed_F", 2000],
    ["I_Heli_Transport_02_F", 3000],
    ["I_Heli_light_03_dynamicLoadout_F", 4000]
];
West_Transport_Reserve_Air_Count = 10;

// airTransport
F_Heli_Respawn_List = [
    ["I_Heli_light_03_unarmed_F", 550]
];

// airHeli
F_Heli_Gunship_List = [
    ["I_Heli_light_03_dynamicLoadout_F", 750]
];

// airJet
F_Plane_List = [
    ["I_Plane_Fighter_03_dynamicLoadout_F", 15000],
    ["I_Plane_Fighter_04_F", 12000]
];

// boat
F_Boat_List = [
	["I_Boat_Transport_01_F", 500],
    ["I_Boat_Armed_01_minigun_F", 1500]
];

// airDrone
F_UAV_List = [
    ["I_UAV_01_F", 600],
    ["I_UAV_06_F", 800],
    ["I_UAV_02_dynamicLoadout_F", 1000]
];

// groundDrone
F_UGV_List = [
    ["I_UGV_01_F", 550],
	["I_UGV_01_rcws_F", 1000]
];

F_Container_List = [
    ["B_Slingload_01_Medevac_F", 350],
    ["B_Slingload_01_Ammo_F", 350],
    ["B_Slingload_01_Repair_F", 500],
    ["B_Slingload_01_Fuel_F", 350]
];

F_Turret_List = [
    ["I_HMG_02_F", 350],
	["I_HMG_02_high_F", 350],
	["I_HMG_01_F", 350],
	["I_HMG_01_high_F", 350],
	["I_GMG_01_F", 350],
    ["I_GMG_01_high_F", 350],
    ["I_static_AT_F", 350]
];

// staticAA
F_SAM_List = [
    ["I_static_AA_F", 5000]
];

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
 *   West_Objective_Group_Type_Caps = [["artillery", 5], ["jet", 3]]
 * These caps apply across all owned seeded objectives combined.
 */
West_Objective_Group_Type_Caps = [
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

