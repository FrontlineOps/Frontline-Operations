// ============================================================================
// SAF WOODLAND FACTION - BLUFOR (FFAA Mod)
// Spanish Armed Forces in woodland camouflage
// ============================================================================

// ============================================================================
// INFANTRY UNITS
// ============================================================================
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
    ["ffaa_et_vamtac_ume", 25],
    ["ffaa_et_vamtac_m2", 50],
    ["ffaa_et_vamtac_lag40", 60],
    ["ffaa_et_vamtac_tow", 70],
    ["ffaa_et_vamtac_cardom", 80],
    ["ffaa_et_vamtac_mistral", 90]
];

F_MRAP_List = [
    ["ffaa_et_lince_ambulancia", 50],
    ["ffaa_et_lince_m2", 70],
    ["ffaa_et_lince_lag40", 100],
    ["ffaa_et_rg31_samson", 120]
];

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

F_APC_List = [
    ["ffaa_et_toa_mando", 200],
    ["ffaa_et_toa_ambulancia", 150],
    ["ffaa_et_toa_zapador", 200],
    ["ffaa_et_toa_spike", 300],
    ["ffaa_et_pizarro_mauser", 400]
];

F_Tank_List = [
    ["ffaa_et_leopardo", 650]
];

F_Artillery_List = [
    ["B_T_Mortar_01_F", 75],
    ["B_T_MBT_01_arty_F", 400],
    ["B_T_MBT_01_mlrs_F", 500]
];

F_Heli_List = [
    ["ffaa_famet_ec135", 250],
    ["ffaa_nh90_tth_transport", 400],
    ["ffaa_nh90_tth_cargo", 450]
];

F_Heli_Respawn_List = [];

F_Heli_Gunship_List = [
    ["ffaa_famet_tigre", 750]
];

F_Plane_List = [
    ["B_Plane_CAS_01_dynamicLoadout_F", 1500],
    ["ffaa_ar_harrier", 1600],
    ["ffaa_ea_hercules", 1200],
    ["ffaa_ea_hercules_cargo", 1200]
];

F_Boat_List = [
    ["B_Boat_Armed_01_minigun_F", 150]
];

F_UAV_List = [
    ["ffaa_ea_reaper", 80],
    ["B_UAV_05_F", 80],
    ["B_T_UAV_03_dynamicLoadout_F", 80]
];

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

F_SAM_List = [
    ["B_SAM_System_01_F", 500],
    ["B_SAM_System_02_F", 500],
    ["B_SAM_System_03_F", 500],
    ["B_AAA_System_01_F", 500]
];