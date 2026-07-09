// ============================================================================
// NATO DESERT FACTION - BLUFOR
// Vanilla Arma 3 NATO units in desert camouflage
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
 *   radar            = FLO_FactionRadar
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

F_Assault_Eng = "B_engineer_F";
F_Assault_TL = "B_Soldier_TL_F";
F_Assault_SL = "B_Soldier_SL_F";
F_Assault_Eod = "B_soldier_exp_F";
F_Assault_Mrk = "B_Sharpshooter_F";
F_Assault_AT = "B_soldier_LAT_F";
F_Assault_Amm = "B_Soldier_A_F";
F_Assault_Mg = "B_soldier_AR_F";
F_Assault_Med = "B_medic_F";
F_Assault_Uav = "B_soldier_UAV_F";

F_Recon_Snp = "B_Recon_Sharpshooter_F";
F_Recon_Sct = "B_recon_F";
F_Recon_TL = "B_Patrol_Soldier_TL_F";
F_Recon_Mrk = "B_Patrol_Soldier_M_F";
F_Recon_AT = "B_recon_LAT_F";
F_Recon_Mg = "B_Patrol_Soldier_MG_F";
F_Recon_Eod = "B_recon_exp_F";
F_Recon_Med = "B_Patrol_Medic_F";
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
// FLO_FactionRadar feeds the commander radar pool.
FLO_FactionRadar = "B_Radar_System_01_F";
FLO_FactionFobType = "Land_Cargo_HQ_V3_F";
FLO_FactionFobTerminalType = "Land_TripodScreen_01_large_sand_F";
FLO_FactionCopType = "Land_Cargo_House_V3_F";
FLO_FactionCopTerminalType = "Land_TripodScreen_01_dual_v2_sand_F";

// ============================================================================
// VEHICLE LISTS - Format: [[classname, price], ...]
// ============================================================================
// These same lists also feed commander/virtualization pools as described above.

F_Bike_List = [
    ["B_Quadbike_01_F", 5]
];

// groundMotorized
F_Car_List = [
    ["B_LSV_01_unarmed_F", 250],
    ["B_LSV_01_armed_F", 500],
    ["B_LSV_01_AT_F", 600]
];

// groundMotorized
F_MRAP_List = [
    ["B_MRAP_01_F", 500],
    ["B_MRAP_01_hmg_F", 700],
    ["B_MRAP_01_gmg_F", 1000]
];

// groundTransport
F_Truck_List = [
    ["B_Truck_01_transport_F", 650],
    ["B_Truck_01_covered_F", 650]
];

F_Truck_Ammo_List = [
    ["B_Truck_01_ammo_F", 1000]
];

F_Truck_Construction_List = [
    ["B_Truck_01_Repair_F", 1000]
];

F_Truck_Respawn_List = [
    ["B_Truck_01_medical_F", 1500]
];

// groundMechanized
F_APC_List = [
    ["B_APC_Tracked_01_rcws_F", 2500],
    ["B_APC_Tracked_01_AA_F", 2000],
    ["B_APC_Tracked_01_CRV_F", 2000],
    ["B_APC_Wheeled_01_cannon_F", 3500],
    ["B_AFV_Wheeled_01_up_cannon_F", 4000]
];

// groundArmor
F_Tank_List = [
    ["B_MBT_01_cannon_F", 5000],
    ["B_MBT_01_TUSK_F", 6500]
];

// groundArtillery
F_Artillery_List = [
    ["B_Mortar_01_F", 750],
    ["B_MBT_01_arty_F", 4000],
    ["B_MBT_01_mlrs_F", 5000]
];

// airTransport
F_Heli_List = [
    ["B_Heli_Light_01_F", 2500],
    ["B_Heli_Transport_01_F", 2000],
    ["B_Heli_Transport_03_F", 4000]
];

// airTransport
F_Heli_Respawn_List = [
    ["B_Heli_Transport_01_medevac_F", 550]
];

// airHeli
F_Heli_Gunship_List = [
    ["B_Heli_Light_01_dynamicLoadout_F", 500],
    ["B_Heli_Attack_01_dynamicLoadout_F", 750]
];

// airJet
F_Plane_List = [
    ["B_Plane_CAS_01_dynamicLoadout_F", 15000],
    ["B_Plane_Fighter_01_F", 18000],
    ["B_T_VTOL_01_infantry_F", 12000],
    ["B_T_VTOL_01_vehicle_F", 12000],
    ["B_T_VTOL_01_armed_F", 16000]
];

// boat
F_Boat_List = [
    ["B_Boat_Armed_01_minigun_F", 1500]
];

// airDrone
F_UAV_List = [
    ["B_UAV_02_dynamicLoadout_F", 800],
    ["B_UAV_05_F", 800],
    ["B_T_UAV_03_dynamicLoadout_F", 800]
];

// groundDrone
F_UGV_List = [
    ["B_UGV_01_rcws_F", 550]
];

F_Container_List = [
    ["B_Slingload_01_Medevac_F", 350],
    ["B_Slingload_01_Ammo_F", 350],
    ["B_Slingload_01_Fuel_F", 350]
];

F_Turret_List = [
    ["B_HMG_01_high_F", 350],
    ["B_GMG_01_high_F", 350],
    ["B_static_AT_F", 350]
];

// staticAA
F_SAM_List = [
    ["B_SAM_System_01_F", 35000],
    ["B_SAM_System_02_F", 35000],
    ["B_SAM_System_03_F", 35000],
    ["B_AAA_System_01_F", 35000]
];
