// ============================================================================
// GAF WOODLAND FACTION - BLUFOR (Bundeswehr Mod)
// German Armed Forces in woodland camouflage
// ============================================================================

// ============================================================================
// INFANTRY UNITS
// ============================================================================
F_Officer = "BWA3_Officer_Fleck";

F_Assault_Eng = "BWA3_Grenadier_G27_Fleck";
F_Assault_TL = "BWA3_TL_Fleck";
F_Assault_SL = "BWA3_SL_Fleck";
F_Assault_Eod = "BWA3_Engineer_Fleck";
F_Assault_Mrk = "BWA3_Marksman_Fleck";
F_Assault_AT = "BWA3_RiflemanAT_PzF3_Fleck";
F_Assault_Amm = "BWA3_RiflemanAA_Fliegerfaust_Fleck";
F_Assault_Mg = "BWA3_MachineGunner_MG5_Fleck";
F_Assault_Med = "BWA3_Medic_Fleck";
F_Assault_Uav = "B_W_Soldier_UAV_F";

F_Recon_Snp = "BWA3_recon_Marksman_Fleck";
F_Recon_Sct = "BWA3_recon_Pioneer_Fleck";
F_Recon_TL = "BWA3_recon_TL_Fleck";
F_Recon_Mrk = "BWA3_recon_Marksman_Fleck";
F_Recon_AT = "BWA3_recon_LAT_Fleck";
F_Recon_Mg = "BWA3_recon_Fleck";
F_Recon_Eod = "BWA3_recon_Pioneer_Fleck";
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
    ["BWA3_Eagle_Fleck", 25],
    ["BWA3_Eagle_FLW100_Fleck", 50]
];

F_MRAP_List = [
    ["BWA3_Dingo2_FLW100_MG3_CG13_Fleck", 70],
    ["BWA3_Dingo2_FLW200_M2_CG13_Fleck", 80],
    ["BWA3_Dingo2_FLW200_GMW_CG13_Fleck", 100]
];

F_Truck_List = [
    ["CUP_B_T810_Armed_CZ_WDL", 65]
];

F_Truck_Ammo_List = [
    ["CUP_B_T810_Reammo_CZ_WDL", 100]
];

F_Truck_Construction_List = [
    ["CUP_B_T810_Repair_CZ_WDL", 100]
];

F_Truck_Respawn_List = [
    ["CUP_B_LR_Ambulance_CZ_W", 150]
];

F_APC_List = [
    ["CUP_B_Boxer_HMG_GER_WDL", 250],
    ["CUP_B_Boxer_GMG_GER_WDL", 300],
    ["BWA3_Puma_Fleck", 400]
];

F_Tank_List = [
    ["BWA3_Leopard2_Fleck", 650]
];

F_Artillery_List = [
    ["B_T_Mortar_01_F", 75],
    ["B_T_MBT_01_arty_F", 400],
    ["B_T_MBT_01_mlrs_F", 500]
];

F_Heli_List = [
    ["CUP_B_UH1D_slick_GER_KSK", 250],
    ["CUP_B_CH53E_GER", 400],
    ["CUP_B_CH53E_VIV_GER", 450]
];

F_Heli_Respawn_List = [];

F_Heli_Gunship_List = [
    ["CUP_B_UH1D_gunship_GER_KSK", 500],
    ["BWA3_Tiger_RMK_Universal", 750]
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
    ["CUP_B_M2StaticMG_GER_Fleck", 35],
    ["CUP_B_AGS_ACR", 35],
    ["CUP_B_RBS70_ACR", 35]
];

F_SAM_List = [
    ["B_SAM_System_01_F", 35],
    ["B_SAM_System_02_F", 35],
    ["B_SAM_System_03_F", 35],
    ["B_AAA_System_01_F", 35]
];