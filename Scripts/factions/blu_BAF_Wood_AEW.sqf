// ============================================================================
// BAF WOODLAND FACTION - BLUFOR (Aegis/AEW Mod)
// British Armed Forces in woodland camouflage
// ============================================================================

// ============================================================================
// INFANTRY UNITS
// ============================================================================
F_Officer = "B_A_Officer_wdl_F";

F_Assault_Eng = "B_A_Engineer_wdl_F";
F_Assault_TL = "B_A_Soldier_TL_wdl_F";
F_Assault_SL = "B_A_Soldier_SL_wdl_F";
F_Assault_Eod = "B_A_Soldier_Exp_wdl_F";
F_Assault_Mrk = "B_A_soldier_M_wdl_F";
F_Assault_AT = "B_A_Soldier_LAT_wdl_F";
F_Assault_Amm = "B_A_Soldier_A_wdl_F";
F_Assault_Mg = "B_A_Soldier_AR_wdl_F";
F_Assault_Med = "B_A_Medic_wdl_F";
F_Assault_Uav = "B_A_Soldier_UAV_wdl_F";

F_Recon_Snp = "B_A_ghillie_wdl_F";
F_Recon_Sct = "B_A_ghillie_spotter_wdl_F";
F_Recon_TL = "B_A_Recon_TL_wdl_F";
F_Recon_Mrk = "B_A_Recon_M_wdl_F";
F_Recon_AT = "B_A_Recon_LAT_wdl_F";
F_Recon_Mg = "B_A_Recon_MG_wdl_F";
F_Recon_Eod = "B_A_Recon_Exp_wdl_F";
F_Recon_Med = "B_A_Recon_Medic_wdl_F";
F_Recon_Eng = "B_A_Engineer_wdl_F";

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
    ["B_A_Quadbike_01_wdl_F", 5]
];

F_Car_List = [
    ["B_A_LSV_01_light_wdl_F", 25],
    ["B_A_LSV_01_armed_wdl_F", 50],
    ["B_A_LSV_01_AT_wdl_F", 60]
];

F_MRAP_List = [
    ["B_A_MRAP_03_wdl_F", 50],
    ["B_A_MRAP_03_hmg_wdl_F", 70],
    ["B_A_MRAP_03_gmg_wdl_F", 100]
];

F_Truck_List = [
    ["B_A_Truck_01_transport_wdl_F", 65],
    ["B_A_Truck_01_covered_wdl_F", 65]
];

F_Truck_Ammo_List = [
    ["B_A_Truck_01_ammo_wdl_F", 100]
];

F_Truck_Construction_List = [
    ["B_A_Truck_01_Repair_wdl_F", 100]
];

F_Truck_Respawn_List = [
    ["B_A_Truck_01_medical_wdl_F", 150]
];

F_APC_List = [
    ["B_A_APC_tracked_03_cannon_v2_wdl_F", 350]
];

F_Tank_List = [
    ["B_T_MBT_01_TUSK_F", 650]
];

F_Artillery_List = [
    ["B_T_Mortar_01_F", 75],
    ["B_T_MBT_01_arty_F", 400],
    ["B_T_MBT_01_mlrs_F", 500]
];

F_Heli_List = [
    ["B_A_Heli_light_03_unarmed_F", 250],
    ["B_A_Heli_Transport_02_F", 400]
];

F_Heli_Respawn_List = [];

F_Heli_Gunship_List = [
    ["B_A_Heli_light_03_dynamicLoadout_F", 500],
    ["B_A_Heli_Attack_01_dynamicLoadout_F", 750]
];

F_Plane_List = [
    ["B_Plane_CAS_01_dynamicLoadout_F", 1500],
    ["B_A_Plane_Fighter_05_F", 1800],
    ["B_A_VTOL_01_infantry_F", 1200],
    ["B_A_VTOL_01_vehicle_F", 1200]
];

F_Boat_List = [
    ["B_A_Boat_Armed_01_hmg_F", 150]
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
    ["B_A_HMG_02_high_wdl_F", 35],
    ["B_A_GMG_01_high_wdl_F", 35],
    ["B_A_Static_AT_wdl_F", 35]
];

F_SAM_List = [
    ["B_SAM_System_01_F", 500],
    ["B_SAM_System_02_F", 500],
    ["B_SAM_System_03_F", 500],
    ["B_AAA_System_01_F", 500]
];