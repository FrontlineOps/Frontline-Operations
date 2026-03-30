// ============================================================================
// US WOODLAND FACTION - BLUFOR (RHS Mods - Modern Era)
// US Forces in woodland camouflage/marpat camouflage
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
F_Officer = "rhsusf_army_ucp_officer";

F_Assault_Eng = "rhsusf_army_ucp_engineer";
F_Assault_TL = "rhsusf_army_ucp_teamleader";
F_Assault_SL = "rhsusf_army_ucp_squadleader";
F_Assault_Eod = "rhsusf_army_ucp_explosives";
F_Assault_Mrk = "rhsusf_army_ucp_marksman";
F_Assault_AT = "rhsusf_army_ucp_javelin";
F_Assault_Amm = "rhsusf_army_ucp_autoriflemana";
F_Assault_Mg = "rhsusf_army_ucp_machinegunner";
F_Assault_Med = "rhsusf_army_ucp_medic";
F_Assault_Uav = "B_soldier_UAV_F";

F_Recon_Snp = "rhsusf_usmc_recon_marpat_wd_sniper_M107";
F_Recon_Sct = "rhsusf_usmc_recon_marpat_wd_rifleman";
F_Recon_TL = "rhsusf_usmc_recon_marpat_wd_teamleader";
F_Recon_Mrk = "rhsusf_usmc_recon_marpat_wd_marksman";
F_Recon_AT = "rhsusf_usmc_recon_marpat_wd_rifleman_at";
F_Recon_Mg = "rhsusf_usmc_recon_marpat_wd_autorifleman";
F_Recon_Eod = F_Assault_Eod;
F_Recon_Med = F_Assault_Med;
F_Recon_Eng = F_Assault_Eng;

F_Diver_TL = "rhsusf_socom_marsoc_teamleader";
F_Diver_Rfl = "rhsusf_socom_marsoc_cso";
F_Diver_Eod = "rhsusf_socom_marsoc_cso_eod";

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
    ["rhsusf_m1043_w_m2", 15],
    ["rhsusf_m1043_w", 20],
    ["rhsusf_m1025_w", 25],
    ["rhsusf_m1043_w_mk19", 40],
    ["rhsusf_m1151_m2_v2_usarmy_wd", 50],
    ["rhsusf_m1151_mk19_v2_usarmy_wd", 65]
];

// groundMotorized
F_MRAP_List = [
    ["rhsusf_m1240a1_m2crows_usarmy_wd", 70],
    ["rhsusf_m1240a1_mk19crows_usarmy_wd", 95],
    ["rhsusf_M1230_M2_usarmy_wd", 110],
    ["rhsusf_M1237_M2_usarmy_wd", 120],
    ["rhsusf_M1237_MK19_usarmy_wd", 150]
];

// groundTransport
F_Truck_List = [
    ["rhsusf_M1078A1P2_WD_fmtv_usarmy", 45],
    ["rhsusf_M1078A1P2_B_M2_WD_fmtv_usarmy", 65]
];
West_Transport_Reserve_Ground_Count = 20;

F_Truck_Ammo_List = [
    ["rhsusf_M977A4_AMMO_usarmy_wd", 100]
];

F_Truck_Construction_List = [
    ["rhsusf_M1078A1P2_B_WD_CP_fmtv_usarmy", 100]
];

F_Truck_Respawn_List = [
    ["rhsusf_M1085A1P2_B_WD_Medical_fmtv_usarmy", 150]
];

// groundMechanized
F_APC_List = [
    ["rhsusf_m113_usarmy", 100],
    ["rhsusf_stryker_m1126_m2_wd", 150],
    ["rhsusf_stryker_m1126_mk19_wd", 200],
    ["RHS_M2A3_BUSKI_wd", 300],
    ["RHS_M2A3_BUSKIII_wd", 400]
];

// groundArmor
F_Tank_List = [
    ["rhsusf_m1a1aim_tuski_wd", 225],
    ["rhsusf_m1a2sep1tuskiiwd_usarmy", 350],
    ["rhsusf_m1a2sep2wd_usarmy", 500]
];

// groundArtillery
F_Artillery_List = [ 
    ["rhsusf_m109_usarmy", 600],
    ["rhsusf_M142_usarmy_WD", 900]
];

// airTransport
F_Heli_List = [
    ["RHS_UH1Y_FFAR_wd", 200], 
    ["RHS_UH1Y_wd", 200], 
    ["RHS_UH60M_wd", 250],
    ["RHS_CH_47F_10_wd", 350], 
    ["RHS_CH53E_USMC", 500]
];
West_Transport_Reserve_Air_Count = 10;

// airTransport
F_Heli_Respawn_List = [
    ["RHS_UH60M_MEV_wd", 550]
];

// airHeli
F_Heli_Gunship_List = [
    ["RHS_AH1Z_wd", 400], 
    ["RHS_AH64D_wd", 600]
];

// airJet
F_Plane_List = [
    ["RHS_C130J", 1000],
    ["RHS_A10", 1500],
    ["rhsusf_f22", 2000]
];

// boat
F_Boat_List = [];

// airDrone
F_UAV_List = [];

// groundDrone
F_UGV_List = [];

F_Container_List = [
    ["B_Slingload_01_Medevac_F", 35],
    ["B_Slingload_01_Ammo_F", 35],
    ["B_Slingload_01_Repair_F", 100],
    ["B_Slingload_01_Fuel_F", 35]
];

F_Turret_List = [
    ["RHS_M2StaticMG_WD", 35],
    ["RHS_MK19_TriPod_WD", 50],
    ["RHS_Stinger_AA_pod_WD", 75],
    ["RHS_TOW_TriPod_WD", 100]
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

