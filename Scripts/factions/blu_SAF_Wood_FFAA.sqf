// ============================================================================
// SAF WOODLAND FACTION - BLUFOR (FFAA Mod)
// Spanish Armed Forces in woodland camouflage
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
F_Officer = "ffaa_bripac_oficial";

F_Assault_Eng = "ffaa_brilat_ingeniero";
F_Assault_TL = "ffaa_bripac_jefe_peloton";
F_Assault_SL = "ffaa_bripac_jefe_escuadra";
F_Assault_Eod = "ffaa_et_moe_sabot";
F_Assault_Mrk = "ffaa_bripac_tirador";
F_Assault_AT = "ffaa_bripac_proveedor_alcotan";
F_Assault_Amm = "ffaa_bripac_fusilero_mochila";
F_Assault_Mg = "ffaa_bripac_tirador_ameli";
F_Assault_Med = "ffaa_bripac_medico";
F_Assault_Uav = "ffaa_bripac_operador_UAV";

F_Recon_Snp = "ffaa_bripac_francotirador_barrett";
F_Recon_Sct = "ffaa_bripac_observador";
F_Recon_TL = "ffaa_et_moe_lider";
F_Recon_Mrk = "ffaa_et_moe_tirador";
F_Recon_AT = "ffaa_et_moe_at";
F_Recon_Mg = "ffaa_et_moe_mg";
F_Recon_Eod = "ffaa_et_moe_sabot";
F_Recon_Med = "ffaa_et_moe_medico";
F_Recon_Eng = "ffaa_et_moe_sabot";

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
    ["ffaa_et_vamtac_ume", 25],
    ["ffaa_et_vamtac_m2", 50],
    ["ffaa_et_vamtac_lag40", 60],
    ["ffaa_et_vamtac_tow", 70],
    ["ffaa_et_vamtac_cardom", 80],
    ["ffaa_et_vamtac_mistral", 90]
];

// groundMotorized
F_MRAP_List = [
    ["ffaa_et_lince_ambulancia", 50],
    ["ffaa_et_lince_m2", 70],
    ["ffaa_et_lince_lag40", 100],
    ["ffaa_et_rg31_samson", 120]
];

// groundTransport
F_Truck_List = [
    ["ffaa_et_m250_carga_blin", 65]
];

F_Truck_Ammo_List = [
    ["ffaa_et_m250_sistema_nasams_blin", 100]
];

F_Truck_Construction_List = [
    ["ffaa_et_m250_repara_municion_blin", 100]
];

F_Truck_Respawn_List = [
    ["ffaa_et_lince_ambulancia", 150]
];

// groundMechanized
F_APC_List = [
    ["ffaa_et_toa_mando", 200],
    ["ffaa_et_toa_ambulancia", 150],
    ["ffaa_et_toa_zapador", 200],
    ["ffaa_et_toa_spike", 300],
    ["ffaa_et_pizarro_mauser", 400]
];

// groundArmor
F_Tank_List = [
    ["ffaa_et_leopardo", 650]
];

// groundArtillery
F_Artillery_List = [
    ["B_T_Mortar_01_F", 75],
    ["B_T_MBT_01_arty_F", 400],
    ["B_T_MBT_01_mlrs_F", 500]
];

// airTransport
F_Heli_List = [
    ["ffaa_famet_ec135", 250],
    ["ffaa_nh90_tth_transport", 400],
    ["ffaa_nh90_tth_cargo", 450]
];

// airTransport
F_Heli_Respawn_List = [];

// airHeli
F_Heli_Gunship_List = [
    ["ffaa_famet_tigre", 750]
];

// airJet
F_Plane_List = [
    ["B_Plane_CAS_01_dynamicLoadout_F", 1500],
    ["ffaa_ar_harrier", 1600],
    ["ffaa_ea_hercules", 1200],
    ["ffaa_ea_hercules_cargo", 1200]
];

// boat
F_Boat_List = [
    ["B_Boat_Armed_01_minigun_F", 150]
];

// airDrone
F_UAV_List = [
    ["ffaa_ea_reaper", 80],
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
    ["ffaa_m2_ship_tripode", 35],
    ["ffaa_lag40_tripode", 35],
    ["ffaa_tow_tripode", 35]
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

