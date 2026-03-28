// ============================================================================
// GAF DESERT FACTION - BLUFOR (Bundeswehr Mod)
// German Armed Forces in desert camouflage
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
F_Officer = "BWA3_Officer_Tropen";

F_Assault_Eng = "BWA3_Engineer_Tropen";
F_Assault_TL = "BWA3_TL_Tropen";
F_Assault_SL = "BWA3_SL_Tropen";
F_Assault_Eod = "BWA3_Engineer_Tropen";
F_Assault_Mrk = "BWA3_Marksman_Tropen";
F_Assault_AT = "BWA3_RiflemanAT_PzF3_Tropen";
F_Assault_Amm = "BWA3_RiflemanAA_Fliegerfaust_Tropen";
F_Assault_Mg = "BWA3_MachineGunner_MG5_Tropen";
F_Assault_Med = "BWA3_Medic_Tropen";
F_Assault_Uav = "B_soldier_UAV_F";

F_Recon_Snp = "BWA3_Sniper_G82_Tropen";
F_Recon_Sct = "BWA3_Spotter_Tropen";
F_Recon_TL = "BWA3_recon_TL_Tropen";
F_Recon_Mrk = "BWA3_recon_Marksman_Tropen";
F_Recon_AT = "BWA3_recon_LAT_Tropen";
F_Recon_Mg = "BWA3_recon_Tropen";
F_Recon_Eod = "BWA3_recon_Pioneer_Tropen";
F_Recon_Med = "BWA3_recon_Medic_Tropen";
F_Recon_Eng = "B_Patrol_Engineer_F";

F_Diver_TL = "B_diver_TL_F";
F_Diver_Rfl = "B_diver_F";
F_Diver_Eod = "B_diver_exp_F";

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
    ["B_Quadbike_01_F", 5]
];

// groundMotorized
F_Car_List = [
    ["BWA3_Eagle_Tropen", 25],
    ["BWA3_Eagle_FLW100_Tropen", 50]
];

// groundMotorized
F_MRAP_List = [
    ["BWA3_Dingo2_FLW100_MG3_CG13_Tropen", 70],
    ["BWA3_Dingo2_FLW200_M2_CG13_Tropen", 80],
    ["BWA3_Dingo2_FLW200_GMW_CG13_Tropen", 100]
];

// groundTransport
F_Truck_List = [
    ["CUP_B_T810_Armed_CZ_DES", 65]
];
West_Transport_Reserve_Ground_Count = 20;

F_Truck_Ammo_List = [
    ["CUP_B_T810_Reammo_CZ_DES", 100]
];

F_Truck_Construction_List = [
    ["CUP_B_T810_Repair_CZ_DES", 100]
];

F_Truck_Respawn_List = [
    ["CUP_B_LR_Ambulance_GB_D", 150]
];

// groundMechanized
F_APC_List = [
    ["CUP_B_Boxer_HMG_GER_DES", 250],
    ["CUP_B_Boxer_GMG_GER_DES", 300],
    ["BWA3_Puma_Tropen", 400]
];

// groundArmor
F_Tank_List = [
    ["BWA3_Leopard2_Tropen", 650]
];

// groundArtillery
F_Artillery_List = [
    ["B_Mortar_01_F", 75],
    ["B_MBT_01_arty_F", 400],
    ["B_MBT_01_mlrs_F", 500]
];

// airTransport
F_Heli_List = [
    ["CUP_B_UH1D_slick_GER_KSK_Des", 250],
    ["CUP_B_CH53E_GER", 400],
    ["CUP_B_CH53E_VIV_GER", 450]
];
West_Transport_Reserve_Air_Count = 10;

// airTransport
F_Heli_Respawn_List = [];

// airHeli
F_Heli_Gunship_List = [
    ["CUP_B_UH1D_gunship_GER_KSK_Des", 500],
    ["BWA3_Tiger_RMK_Universal", 750]
];

// airJet
F_Plane_List = [
    ["B_Plane_CAS_01_dynamicLoadout_F", 1500],
    ["B_Plane_Fighter_01_F", 1800],
    ["B_T_VTOL_01_infantry_F", 1200],
    ["B_T_VTOL_01_vehicle_F", 1200],
    ["B_T_VTOL_01_armed_F", 1600]
];

// boat
F_Boat_List = [
    ["B_Boat_Armed_01_minigun_F", 150]
];

// airDrone
F_UAV_List = [
    ["B_UAV_02_dynamicLoadout_F", 80],
    ["B_UAV_05_F", 80],
    ["B_T_UAV_03_dynamicLoadout_F", 80]
];

// groundDrone
F_UGV_List = [
    ["B_UGV_01_rcws_F", 55]
];

F_Container_List = [
    ["B_Slingload_01_Medevac_F", 35],
    ["B_Slingload_01_Ammo_F", 35],
    ["B_Slingload_01_Repair_F", 100],
    ["B_Slingload_01_Fuel_F", 35]
];

F_Turret_List = [
    ["CUP_B_M2StaticMG_GER", 35],
    ["CUP_B_AGS_ACR", 35],
    ["CUP_B_RBS70_ACR", 35]
];

// staticAA
F_SAM_List = [
    ["B_SAM_System_01_F", 500],
    ["B_SAM_System_02_F", 500],
    ["B_SAM_System_03_F", 500],
    ["B_AAA_System_01_F", 500]
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

