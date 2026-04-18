// ============================================================================
// AAF WOODLAND FACTION - BLUFOR (Vanilla)
// Altis Armed Forces in woodland camouflage
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
F_Officer = "I_officer_F";

F_Assault_Eng = "I_engineer_F";
F_Assault_TL = "I_Soldier_TL_F";
F_Assault_SL = "I_Soldier_SL_F";
F_Assault_Eod = "I_Soldier_exp_F";
F_Assault_Mrk = "I_Soldier_M_F";
F_Assault_AT = "I_Soldier_LAT2_F";
F_Assault_Amm = "I_Soldier_A_F";
F_Assault_Mg = "I_Soldier_AR_F";
F_Assault_Med = "I_medic_F";
F_Assault_Uav = "I_Soldier_F";

F_Recon_Snp = "I_Sniper_F";
F_Recon_Sct = "I_Spotter_F";
F_Recon_TL = "I_Soldier_SL_F";
F_Recon_Mrk = "I_Soldier_M_F";
F_Recon_AT = "I_Soldier_LAT2_F";
F_Recon_Mg = "I_Soldier_AR_F";
F_Recon_Eod = "I_Soldier_exp_F";
F_Recon_Med = "I_medic_F";
F_Recon_Eng = "I_engineer_F";

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
F_HQ_01 = "Land_Cargo_HQ_V1_F";
F_HQ_C_01 = "Land_TripodScreen_01_large_F";
F_OP_01 = "Land_Cargo_House_V1_F";
F_OP_C_01 = "Land_TripodScreen_01_dual_v2_F";

// ============================================================================
// VEHICLE LISTS - Format: [[classname, price], ...]
// ============================================================================
// These same lists also feed commander/virtualization pools as described above.

F_Bike_List = [
    ["I_Quadbike_01_F", 50]
];

// groundMotorized
F_Car_List = [
    ["I_MRAP_03_F", 500],
    ["I_MRAP_03_hmg_F", 700],
    ["I_MRAP_03_gmg_F", 1000]
];

// groundMotorized
F_MRAP_List = [
    ["I_APC_Wheeled_03_cannon_F", 3500],
    ["I_LT_01_cannon_F", 3500],
    ["I_LT_01_AA_F", 3000]
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
    ["I_APC_tracked_03_cannon_F", 3500]
];

// groundArmor
F_Tank_List = [
    ["I_MBT_03_cannon_F", 5000]
];

// groundArtillery
F_Artillery_List = [
    ["I_Mortar_01_F", 750],
    ["I_Truck_02_MRL_F", 5000],
    ["O_MBT_02_arty_F", 4000]
];

// airTransport
F_Heli_List = [
    ["I_Heli_Transport_02_F", 2500],
    ["I_Heli_light_03_unarmed_F", 2000]
];
West_Transport_Reserve_Air_Count = 10;

// airTransport
F_Heli_Respawn_List = [
    ["I_Heli_Transport_02_F", 5500]
];

// airHeli
F_Heli_Gunship_List = [
    ["I_Heli_light_03_dynamicLoadout_F", 7500]
];

// airJet
F_Plane_List = [
    ["I_Plane_Fighter_03_dynamicLoadout_F", 15000],
    ["I_Plane_Fighter_04_F", 18000]
];

// boat
F_Boat_List = [];

// airDrone
F_UAV_List = [
    ["I_UAV_01_F", 800],
    ["I_UAV_02_dynamicLoadout_F", 1500]
];

// groundDrone
F_UGV_List = [
    ["I_UGV_01_rcws_F", 550]
];

F_Container_List = [
    ["B_Slingload_01_Medevac_F", 350],
    ["B_Slingload_01_Ammo_F", 350],
    ["B_Slingload_01_Repair_F", 1000],
    ["B_Slingload_01_Fuel_F", 350]
];

F_Turret_List = [
    ["I_HMG_01_high_F", 350],
    ["I_GMG_01_high_F", 350],
    ["I_static_AT_F", 350]
];

// staticAA
F_SAM_List = [
    ["I_static_AA_F", 2500],
    ["B_SAM_System_03_F", 35000]
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
    ["capital", [
        ["infantry", 12],
        ["motorized", 1],
        ["mechanized", 1],
        ["air", 1],
        ["armor", 1],
        ["artillery", 1],
        ["static_aa", 1],
        ["mobile_aa", 1]
    ]],
    ["city", [
        ["infantry", 7],
        ["motorized", 1]
    ]],
    ["village", [
        ["infantry", 3]
    ]],
    ["local", [
        ["infantry", 6],
        ["motorized", 1],
        ["mechanized", 1],
        ["mobile_aa", 1]
    ]],
    ["marine", [
        ["infantry", 3],
        ["motorized", 1]
    ]],
    ["cluster", [
        ["infantry", 2]
    ]]
];

/*
 * Group Type Unit/Vehicle Counts
 * Defines how many physical units/vehicles should be in each type of group
 */
BLUFOR_Group_Counts = [
    ["infantry", 10],
    ["motorized", 1],
    ["mechanized", 1],
    ["armor", 1],
    ["helicopter", 1],
    ["jet", 1],
    ["air", 1],
    ["artillery", 3],
    ["mobile_aa", 1],
    ["static_aa", 1]
];
