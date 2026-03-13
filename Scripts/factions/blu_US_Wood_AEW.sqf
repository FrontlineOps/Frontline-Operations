// ============================================================================
// US WOODLAND FACTION - BLUFOR (Aegis/AEW Mod)
// US Marines in woodland camouflage
// ============================================================================

// ============================================================================
// INFANTRY UNITS
// ============================================================================
F_Officer = "Marine_B_USMC_officer_wdl_F";

F_Assault_Eng = "Marine_B_USMC_Soldier_GL_wdl_F";
F_Assault_TL = "Marine_B_USMC_Soldier_TL_wdl_F";
F_Assault_SL = "Marine_B_USMC_Soldier_SL_wdl_F";
F_Assault_Eod = "Marine_B_USMC_engineer_wdl_F";
F_Assault_Mrk = "Marine_B_USMC_soldier_M_wdl_F";
F_Assault_AT = "Marine_B_USMC_Soldier_LAT_wdl_F";
F_Assault_Amm = "Marine_B_USMC_Soldier_A_wdl_F";
F_Assault_Mg = "Marine_B_USMC_Soldier_AR_wdl_F";
F_Assault_Med = "Atlas_I_I_medic_F";
F_Assault_Uav = "Atlas_I_I_Soldier_UAV_F";

F_Recon_Snp = "B_W_Recon_M_F";
F_Recon_Sct = "B_W_Recon_Exp_F";
F_Recon_TL = "B_W_Recon_GL_F";
F_Recon_Mrk = "B_W_Recon_Medic_F";
F_Recon_AT = "B_W_Recon_LAT_F";
F_Recon_Mg = "B_W_Recon_MG_F";
F_Recon_Eod = "Atlas_I_I_recon_exp_F";
F_Recon_Med = "Atlas_I_I_recon_medic_F";
F_Recon_Eng = "Atlas_I_I_engineer_F";

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
F_RADAR = "I_E_Radar_System_01_F";
F_HQ_01 = "Land_Cargo_HQ_V1_F";
F_HQ_C_01 = "Land_TripodScreen_01_large_F";
F_OP_01 = "Land_Cargo_House_V1_F";
F_OP_C_01 = "Land_TripodScreen_01_dual_v2_F";

// ============================================================================
// VEHICLE LISTS - Format: [[classname, price], ...]
// ============================================================================

F_Bike_List = [
    ["B_T_Quadbike_01_F", 5]
];

F_Car_List = [
    ["B_T_LSV_01_unarmed_F", 25],
    ["B_T_LSV_01_armed_F", 50],
    ["B_T_LSV_01_AT_F", 60]
];

F_MRAP_List = [
    ["B_T_MRAP_01_F", 50],
    ["B_T_MRAP_01_hmg_F", 70],
    ["B_T_MRAP_01_gmg_F", 100]
];

F_Truck_List = [
    ["B_T_Truck_01_transport_F", 65],
    ["B_T_Truck_01_covered_F", 65]
];

F_Truck_Ammo_List = [
    ["B_T_Truck_01_ammo_F", 100]
];

F_Truck_Construction_List = [
    ["B_T_Truck_01_Repair_F", 100]
];

F_Truck_Respawn_List = [
    ["B_T_Truck_01_medical_F", 150]
];

F_APC_List = [
    ["B_T_APC_Tracked_01_rcws_F", 250],
    ["B_T_APC_Tracked_01_CRV_F", 200],
    ["B_T_APC_Tracked_01_AA_F", 200],
    ["B_T_APC_Wheeled_01_cannon_F", 350],
    ["B_T_AFV_Wheeled_01_up_cannon_F", 400]
];

F_Tank_List = [
    ["B_T_MBT_01_cannon_F", 500],
    ["B_T_MBT_01_TUSK_F", 650]
];

F_Artillery_List = [
    ["B_T_Mortar_01_F", 75],
    ["B_T_MBT_01_arty_F", 400],
    ["B_T_MBT_01_mlrs_F", 500]
];

F_Heli_List = [
    ["B_Heli_Light_01_F", 250],
    ["B_Heli_Transport_01_F", 200],
    ["B_Heli_Transport_03_F", 400]
];

F_Heli_Respawn_List = [
    ["B_Heli_Transport_01_medevac_F", 550]
];

F_Heli_Gunship_List = [
    ["B_Heli_Light_01_dynamicLoadout_F", 500],
    ["B_Heli_Attack_01_dynamicLoadout_F", 750]
];

F_Plane_List = [
    ["B_Plane_CAS_01_dynamicLoadout_F", 1500],
    ["B_Plane_Fighter_01_F", 1800],
    ["B_T_VTOL_01_infantry_F", 1200],
    ["B_T_VTOL_01_vehicle_F", 1200],
    ["B_T_VTOL_01_armed_F", 1600]
];

F_Boat_List = [
    ["B_Boat_Armed_01_minigun_F", 150]
];

F_UAV_List = [
    ["B_UAV_02_dynamicLoadout_F", 80],
    ["B_UAV_05_F", 80],
    ["B_T_UAV_03_dynamicLoadout_F", 80]
];

F_UGV_List = [
    ["B_T_UGV_01_rcws_olive_F", 55]
];

F_Container_List = [
    ["B_Slingload_01_Medevac_F", 35],
    ["B_Slingload_01_Ammo_F", 35],
    ["B_Slingload_01_Repair_F", 100],
    ["B_Slingload_01_Fuel_F", 35]
];

F_Turret_List = [
    ["B_HMG_01_high_F", 35],
    ["B_GMG_01_high_F", 35],
    ["B_static_AT_F", 35]
];

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

