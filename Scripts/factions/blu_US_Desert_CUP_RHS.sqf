// ============================================================================
// US DESERT FACTION - BLUFOR (CUP/RHS Mods)
// US Marines in desert camouflage
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
F_Officer = "rhsusf_usmc_marpat_d_officer";

F_Assault_Eng = "rhsusf_usmc_marpat_d_engineer";
F_Assault_TL = "rhsusf_usmc_marpat_d_teamleader";
F_Assault_SL = "rhsusf_usmc_marpat_d_squadleader";
F_Assault_Eod = "rhsusf_usmc_marpat_d_explosives";
F_Assault_Mrk = "rhsusf_usmc_marpat_d_sniper_m110";
F_Assault_AT = "rhsusf_usmc_marpat_d_smaw";
F_Assault_Amm = "rhsusf_usmc_marpat_d_autorifleman_m249_ass";
F_Assault_Mg = "rhsusf_usmc_marpat_d_autorifleman_m249";
F_Assault_Med = "rhsusf_army_ocp_medic";
F_Assault_Uav = "rhsusf_usmc_marpat_d_uav";

F_Recon_Snp = "rhsusf_usmc_recon_marpat_d_marksman_lite";
F_Recon_Sct = "rhsusf_usmc_recon_marpat_d_rifleman_at_lite";
F_Recon_TL = "rhsusf_usmc_recon_marpat_d_teamleader_fast";
F_Recon_Mrk = "rhsusf_usmc_recon_marpat_d_marksman_fast";
F_Recon_AT = "rhsusf_usmc_recon_marpat_d_rifleman_at_fast";
F_Recon_Mg = "rhsusf_usmc_recon_marpat_d_autorifleman_fast";
F_Recon_Eod = "rhsusf_socom_marsoc_cso_breacher";
F_Recon_Med = "rhsusf_socom_marsoc_sarc";
F_Recon_Eng = "rhsusf_socom_marsoc_cso_mechanic";

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
    ["rhsusf_m1151_usarmy_d", 25],
    ["rhsusf_m1151_m2_v2_usarmy_d", 50],
    ["rhsusf_m1151_mk19_v2_usarmy_d", 60],
    ["rhsusf_m966_d", 70],
    ["rhsusf_mrzr4_d", 20]
];

// groundMotorized
F_MRAP_List = [
    ["rhsusf_m1240a1_usarmy_d", 80],
    ["rhsusf_m1240a1_m2_uik_usarmy_d", 100],
    ["rhsusf_m1240a1_mk19_uik_usarmy_d", 120],
    ["rhsusf_M1230a1_usarmy_d", 80],
    ["rhsusf_M1230_M2_usarmy_d", 100],
    ["rhsusf_M1230_MK19_usarmy_d", 120]
];

// groundTransport
F_Truck_List = [
    ["rhsusf_M1083A1P2_B_M2_D_fmtv_usarmy", 65]
];

F_Truck_Ammo_List = [
    ["rhsusf_M977A4_AMMO_BKIT_M2_usarmy_d", 100]
];

F_Truck_Construction_List = [
    ["rhsusf_M977A4_REPAIR_BKIT_M2_usarmy_d", 100]
];

F_Truck_Respawn_List = [
    ["rhsusf_M1085A1P2_B_D_Medical_fmtv_usarmy", 150]
];

// groundMechanized
F_APC_List = [
    ["rhsusf_stryker_m1126_m2_d", 250],
    ["rhsusf_stryker_m1126_mk19_d", 300],
    ["rhsusf_stryker_m1134_d", 350],
    ["rhsusf_m113d_usarmy", 150],
    ["RHS_M6", 400],
    ["RHS_M2A3_BUSKIII", 450]
];

// groundArmor
F_Tank_List = [
    ["rhsusf_m1a2sep1tuskiid_usarmy", 700],
    ["rhsusf_m1a2sep1tuskid_usarmy", 650],
    ["rhsusf_m1a2sep2d_usarmy", 750],
    ["B_MBT_01_TUSK_F", 650]
];

// groundArtillery
F_Artillery_List = [
    ["B_Mortar_01_F", 75],
    ["B_MBT_01_arty_F", 400],
    ["B_MBT_01_mlrs_F", 500]
];

// airTransport
F_Heli_List = [
    ["RHS_MELB_MH6M", 200],
    ["RHS_UH60M_d", 350],
    ["RHS_CH_47F_10", 450],
    ["RHS_CH_47F_10_cargo", 500]
];

// airTransport
F_Heli_Respawn_List = [];

// airHeli
F_Heli_Gunship_List = [
    ["RHS_MELB_AH6M", 400],
    ["RHS_AH64D", 800],
    ["RHS_AH1Z", 750]
];

// airJet
F_Plane_List = [
    ["RHS_A10", 1500],
    ["rhsusf_f22", 2000],
    ["RHS_C130J", 1200],
    ["RHS_C130J_Cargo", 1200],
    ["B_T_VTOL_01_infantry_F", 1200],
    ["B_T_VTOL_01_vehicle_F", 1200]
];

// boat
F_Boat_List = [
    ["rhsusf_mkvsoc", 200]
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
    ["RHS_M2StaticMG_D", 35],
    ["RHS_MK19_TriPod_D", 35],
    ["RHS_TOW_TriPod_D", 35]
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

