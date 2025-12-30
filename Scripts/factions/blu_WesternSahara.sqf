// ============================================================================
// WESTERN SAHARA FACTION - BLUFOR (Western Sahara DLC)
// NATO forces for Western Sahara terrain
// ============================================================================

// ============================================================================
// INFANTRY UNITS
// ============================================================================
F_Officer = "B_D_officer_lxWS";

F_Assault_Eng = "B_D_engineer_lxWS";
F_Assault_TL = "B_D_Soldier_TL_lxWS";
F_Assault_SL = "B_D_Soldier_SL_lxWS";
F_Assault_Eod = "B_D_soldier_exp_lxWS";
F_Assault_Mrk = "B_D_soldier_M_lxWS";
F_Assault_AT = "B_D_soldier_LAT_lxWS";
F_Assault_Amm = "B_D_Soldier_A_lxWS";
F_Assault_Mg = "B_D_soldier_AR_lxWS";
F_Assault_Med = "B_D_medic_lxWS";
F_Assault_Uav = "B_D_soldier_UAV01_lxWS";

F_Recon_Snp = "B_D_recon_M_lxWS";
F_Recon_Sct = "B_D_recon_lxWS";
F_Recon_TL = "B_D_recon_TL_lxWS";
F_Recon_Mrk = "B_D_recon_medic_lxWS";
F_Recon_AT = "B_D_recon_LAT_lxWS";
F_Recon_Mg = "B_D_recon_exp_lxWS";
F_Recon_Eod = "B_D_recon_exp_lxWS";
F_Recon_Med = "B_D_recon_medic_lxWS";
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
F_RADAR = "B_Radar_System_01_F";
F_HQ_01 = "Land_Cargo_HQ_V3_F";
F_HQ_C_01 = "Land_TripodScreen_01_large_sand_F";
F_OP_01 = "Land_Cargo_House_V3_F";
F_OP_C_01 = "Land_TripodScreen_01_dual_v2_sand_F";

// ============================================================================
// VEHICLE LISTS - Format: [[classname, price], ...]
// ============================================================================

F_Bike_List = [
    ["B_D_Quadbike_01_lxWS", 5]
];

F_Car_List = [
    ["B_LSV_01_unarmed_F", 25],
    ["B_LSV_01_armed_F", 50],
    ["B_LSV_01_AT_F", 60]
];

F_MRAP_List = [
    ["B_D_MRAP_01_lxWS", 50],
    ["B_D_MRAP_01_hmg_lxWS", 70],
    ["B_D_MRAP_01_gmg_lxWS", 100]
];

F_Truck_List = [
    ["B_D_Truck_01_transport_lxWS", 65],
    ["B_D_Truck_01_covered_lxWS", 65]
];

F_Truck_Ammo_List = [
    ["B_D_Truck_01_ammo_lxWS", 100]
];

F_Truck_Construction_List = [
    ["B_D_Truck_01_Repair_lxWS", 100]
];

F_Truck_Respawn_List = [
    ["B_D_Truck_01_medical_lxWS", 150]
];

F_APC_List = [
    ["B_D_APC_Tracked_01_rcws_lxWS", 250],
    ["B_D_APC_Tracked_01_CRV_lxWS", 200],
    ["B_D_APC_Wheeled_01_command_lxWS", 300],
    ["B_D_APC_Wheeled_01_mortar_lxWS", 350],
    ["B_D_APC_Wheeled_01_atgm_lxWS", 400],
    ["B_D_APC_Tracked_01_aa_lxWS", 350]
];

F_Tank_List = [
    ["B_D_MBT_01_cannon_lxWS", 500],
    ["B_D_MBT_01_TUSK_lxWS", 650]
];

F_Artillery_List = [
    ["B_Mortar_01_F", 75],
    ["B_MBT_01_arty_F", 400],
    ["B_MBT_01_mlrs_F", 500]
];

F_Heli_List = [
    ["B_D_Heli_Light_01_lxWS", 250],
    ["B_D_Heli_Transport_01_lxWS", 200],
    ["B_Heli_Transport_03_F", 400]
];

F_Heli_Respawn_List = [];

F_Heli_Gunship_List = [
    ["B_D_Heli_Light_01_dynamicLoadout_lxWS", 500],
    ["B_D_Heli_Attack_01_dynamicLoadout_lxWS", 750]
];

F_Plane_List = [
    ["B_D_Plane_CAS_01_dynamicLoadout_lxWS", 1500],
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
    ["B_D_UGV_01_rcws_lxWS", 55]
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
    ["B_SAM_System_01_F", 35],
    ["B_SAM_System_02_F", 35],
    ["B_SAM_System_03_F", 35],
    ["B_AAA_System_01_F", 35]
];