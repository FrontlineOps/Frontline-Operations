// ============================================================================
// IAF WOODLAND FACTION - BLUFOR (Aegis/AEW Mod)
// Italian Armed Forces in woodland camouflage
// ============================================================================

// ============================================================================
// INFANTRY UNITS
// ============================================================================
F_Officer = "Atlas_I_I_officer_F";

F_Assault_Eng = "Atlas_I_I_engineer_F";
F_Assault_TL = "Atlas_I_I_Soldier_TL_F";
F_Assault_SL = "Atlas_I_I_Soldier_SL_F";
F_Assault_Eod = "Atlas_I_I_soldier_exp_F";
F_Assault_Mrk = "Atlas_I_I_soldier_M_F";
F_Assault_AT = "Atlas_I_I_Soldier_LAT_F";
F_Assault_Amm = "Atlas_I_I_Soldier_A_F";
F_Assault_Mg = "Atlas_I_I_Soldier_AR_F";
F_Assault_Med = "Atlas_I_I_medic_F";
F_Assault_Uav = "Atlas_I_I_Soldier_UAV_F";

F_Recon_Snp = "Atlas_I_I_sniper_F";
F_Recon_Sct = "Atlas_I_I_spotter_F";
F_Recon_TL = "Atlas_I_I_recon_JTAC_F";
F_Recon_Mrk = "Atlas_I_I_recon_GL_F";
F_Recon_AT = "Atlas_I_I_recon_LAT_F";
F_Recon_Mg = "Atlas_I_I_recon_AR_F";
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
    ["Atlas_I_I_Quadbike_01_F", 5]
];

F_Car_List = [];

F_MRAP_List = [
    ["Atlas_I_I_MRAP_01_F", 50],
    ["Atlas_I_I_MRAP_01_hmg_F", 70],
    ["Atlas_I_I_MRAP_01_gmg_F", 100]
];

F_Truck_List = [
    ["Atlas_B_G_Truck_01_transport_F", 65]
];

F_Truck_Ammo_List = [
    ["Atlas_B_G_Truck_01_ammo_F", 100]
];

F_Truck_Construction_List = [
    ["Atlas_B_G_Truck_01_Repair_F", 100]
];

F_Truck_Respawn_List = [
    ["Atlas_B_G_Truck_01_medical_F", 150]
];

F_APC_List = [
    ["Atlas_I_I_APC_Tracked_01_rcws_F", 250],
    ["Atlas_I_I_APC_Tracked_01_CRV_F", 200],
    ["Atlas_I_I_APC_Tracked_01_AA_F", 350]
];

F_Tank_List = [
    ["Atlas_I_I_MBT_01_cannon_F", 650]
];

F_Artillery_List = [
    ["B_T_Mortar_01_F", 75],
    ["B_T_MBT_01_arty_F", 400],
    ["B_T_MBT_01_mlrs_F", 500]
];

F_Heli_List = [
    ["Atlas_I_I_Heli_Light_01_F", 250],
    ["Atlas_I_I_Heli_Transport_01_F", 400]
];

F_Heli_Respawn_List = [];

F_Heli_Gunship_List = [
    ["Atlas_I_I_Heli_Light_01_dynamicLoadout_F", 500],
    ["Atlas_I_I_Heli_Attack_01_dynamicLoadout_F", 750]
];

F_Plane_List = [
    ["Atlas_I_I_Plane_Fighter_05_F", 1500],
    ["Atlas_I_I_VTOL_01_infantry_F", 1200]
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
    ["Atlas_I_I_UGV_01_rcws_F", 55]
];

F_Container_List = [
    ["B_Slingload_01_Medevac_F", 35],
    ["B_Slingload_01_Ammo_F", 35],
    ["B_Slingload_01_Repair_F", 100],
    ["B_Slingload_01_Fuel_F", 35]
];

F_Turret_List = [
    ["Atlas_B_G_HMG_02_high_F", 35],
    ["Atlas_B_G_GMG_01_high_F", 35],
    ["Atlas_B_G_Static_AT_F", 35]
];

F_SAM_List = [
    ["B_SAM_System_01_F", 500],
    ["B_SAM_System_02_F", 500],
    ["B_SAM_System_03_F", 500],
    ["B_AAA_System_01_F", 500]
];