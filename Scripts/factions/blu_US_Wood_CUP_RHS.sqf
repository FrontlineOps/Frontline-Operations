// ============================================================================
// US WOODLAND FACTION - BLUFOR (RHS Mods - Modern Era)
// US Forces in woodland camouflage/marpat camouflage
// ============================================================================

// ============================================================================
// INFANTRY UNITS
// ============================================================================
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
F_Assault_Uav = "";

F_Recon_Snp = "rhsusf_usmc_recon_marpat_wd_sniper_M107";
F_Recon_Sct = "rhsusf_usmc_recon_marpat_wd_rifleman";
F_Recon_TL = "rhsusf_usmc_recon_marpat_wd_teamleader";
F_Recon_Mrk = "rhsusf_usmc_recon_marpat_wd_marksman";
F_Recon_AT = "rhsusf_usmc_recon_marpat_wd_rifleman_at";
F_Recon_Mg = "rhsusf_usmc_recon_marpat_wd_autorifleman";
F_Recon_Eod = "";
F_Recon_Med = "";
F_Recon_Eng = "";

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
    ["rhsusf_m1043_w_m2", 15],
    ["rhsusf_m1043_w", 20],
    ["rhsusf_m1025_w", 25],
    ["rhsusf_m1043_w_mk19", 40],
    ["rhsusf_m1151_m2_v2_usarmy_wd", 50],
    ["rhsusf_m1151_mk19_v2_usarmy_wd", 65]
];

F_MRAP_List = [
    ["rhsusf_m1240a1_m2crows_usarmy_wd", 70],
    ["rhsusf_m1240a1_mk19crows_usarmy_wd", 95],
    ["rhsusf_M1230_M2_usarmy_wd", 110],
    ["rhsusf_M1237_M2_usarmy_wd", 120],
    ["rhsusf_M1237_MK19_usarmy_wd", 150]
];

F_Truck_List = [
    ["rhsusf_M1078A1P2_WD_fmtv_usarmy", 45],
    ["rhsusf_M1078A1P2_B_M2_WD_fmtv_usarmy", 65]
];

F_Truck_Ammo_List = [
    ["rhsusf_M977A4_AMMO_usarmy_wd", 100]
];

F_Truck_Construction_List = [
    ["rhsusf_M1078A1P2_B_WD_CP_fmtv_usarmy", 100]
];

F_Truck_Respawn_List = [
    ["rhsusf_M1085A1P2_B_WD_Medical_fmtv_usarmy", 150]
];

F_APC_List = [
    ["rhsusf_m113_usarmy", 100],
    ["rhsusf_stryker_m1126_m2_wd", 150],
    ["rhsusf_stryker_m1126_mk19_wd", 200],
    ["RHS_M2A3_BUSKI_wd", 300],
    ["RHS_M2A3_BUSKIII_wd", 400]
];

F_Tank_List = [
    ["rhsusf_m1a1aim_tuski_wd", 225],
    ["rhsusf_m1a2sep1tuskiiwd_usarmy", 350],
    ["rhsusf_m1a2sep2wd_usarmy", 500]
];

F_Artillery_List = [ 
    ["rhsusf_m109_usarmy ", 600],
    ["rhsusf_M142_usarmy_WD", 900]
];

F_Heli_List = [
    ["RHS_UH1Y_FFAR_wd", 200], 
    ["RHS_UH1Y_wd", 200], 
    ["RHS_UH60M_wd", 250],
    ["RHS_CH_47F_10_wd", 350], 
    ["RHS_CH53E_USMC", 500]
];

F_Heli_Respawn_List = [
    ["RHS_UH60M_MEV_wd", 550]
];

F_Heli_Gunship_List = [
    ["RHS_AH1Z_wd", 400], 
    ["RHS_AH64D_wd", 600]
];

F_Plane_List = [
    ["RHS_C130J", 1000],
    ["RHS_A10", 1500],
    ["rhsusf_f22", 2000]
];

F_Boat_List = [];

F_UAV_List = [];

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

F_SAM_List = [
    ["B_SAM_System_01_F", 500],
    ["B_SAM_System_02_F", 500],
    ["B_SAM_System_03_F", 500],
    ["B_AAA_System_01_F", 500]
];
