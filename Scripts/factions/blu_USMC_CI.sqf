  // Where are Classnames ? Right click on any Unit or Vehicle in the Editor and Select find in CFG viewer, Last Name in the [path] tab is the Classname,

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
 *
 */

// Default player faction units (Vanilla Arma 3 NATO)
// F_Officer + all F_Assault_* roles feed the commander groundInfantry pool.
// All F_Recon_* and F_Diver_* roles feed the commander groundSpecOps pool.
F_Officer = "B_USAUSMC_Officer_01";    // Officer
F_Assault_Eng = "B_USAUSMC_Combat_Engineer_01";    // Engineer
F_Assault_TL = "B_USAUSMC_Team_Leader_01";    // Assault Squad Leader
F_Assault_SL = "B_USAUSMC_Squad_Leader_01";    // Assault Platoon Leader
F_Assault_Eod = "B_USAUSMC_EOD_Tech_01";    // Explosive Specialist
F_Assault_Mrk = "B_USAUSMC_Designated_Marksman_01";    // Marksman
F_Assault_AT = "B_USAUSMC_Assaultman_SMAW_01";    // Anti Tank
F_Assault_Amm = "B_USAUSMC_Auto_Rifleman_Ass_01";    // Ammo Bearer
F_Assault_Mg = "B_USAUSMC_Autorifleman_M249_01";    // Auto Rifleman
F_Assault_Med = "B_BUSAUSMC_Corps_Man_01";    // Medic
F_Assault_Uav = "B_USAUSMC_Joint_Fires_Observer_01";    // UAV operator

F_Recon_Snp = "B_BUSAUSMC_Marksman_Thermals_01";    // Recon Sniper
F_Recon_Sct = "B_BUSAUSMC_Team_Leader_Ligth_01";    // Recon Spotter

F_Recon_TL = "B_BUSAUSMC_Team_Leader_Ligth_01";    // Recon Squad Leader
F_Recon_Mrk = "B_BUSAUSMC_Marksman_Ligth_02";   // Recon Marksman
F_Recon_AT = "B_BUSAUSMC_Rifleman_M136_Ligth_01";   // Recon AntiTank
F_Recon_Mg = "B_BUSAUSMC_Auto_Rifleman_M249_Ligth_01";    // Recon Auto Rifleman
F_Recon_Eod = "B_BUSAUSMC_Auto_Rifleman_Ligth_01";    // Recon Explosive specialist
F_Recon_Med = "B_BUSAUSMC_Rifleman_Ligth_01";    // Recon Medic
F_Recon_Eng = "B_BUSAUSMC_Rifleman_Ligth_01";    // Recon Engineer

F_Diver_TL = "B_diver_TL_F";    // Diver Team Leader
F_Diver_Rfl = "B_diver_F";    // Diver operator
F_Diver_Eod = "B_diver_exp_F";    // Diver Explosive specialist

// Default base objects and vehicles
// F_RADAR feeds the commander radar pool.
F_RADAR = "I_E_Radar_System_01_F";      // Use "I_E_Radar_System_01_F" for Woodland Camo   // "B_Radar_System_01_F" for Desert Camo

F_HQ_01 = "Land_Cargo_HQ_V1_F";      // Use "Land_Cargo_HQ_V1_F" for Woodland Camo   // "Land_Cargo_HQ_V3_F" for Desert Camo
F_HQ_C_01 = "Land_TripodScreen_01_large_F";      // Use "Land_TripodScreen_01_large_F" for Woodland Camo   // "Land_TripodScreen_01_large_sand_F" for Desert Camo

F_OP_01 = "Land_Cargo_House_V1_F";      // Use "Land_Cargo_House_V1_F" for Woodland Camo   // "Land_Cargo_House_V3_F" for Desert Camo
F_OP_C_01 = "Land_TripodScreen_01_dual_v2_F";      // Use "Land_TripodScreen_01_dual_v2_F" for Woodland Camo   // "Land_TripodScreen_01_dual_v2_sand_F" for Desert Camo

// Vehicle lists with custom prices
// These same lists also feed commander/virtualization pools as described above.
F_Bike_List = [
    ["B_Quadbike_01_F", 50]
];

// groundMotorized
F_Car_List = [
    ["B_USAUSMC_M1151A1_01", 400],
    ["B_USAUSMC_M1151A1_MCTAGS_M2_01", 600],
    ["B_BUSAUSMC_MRZR_4Clean_01", 250]
];

// groundMotorized
F_MRAP_List = [
    ["B_USAUSMC_M1240_01", 700],
    ["B_USAUSMC_M1240_OGPK_M240_01", 900],
    ["B_USAUSMC_M1240_OGPK_M2_01", 1100],
    ["B_USAUSMC_M1240_OGPK_Mk19_01", 1300],
    ["B_USAUSMC_M1277_CROWS_M2_01", 1300],
    ["B_USAUSMC_M1277_CROWS_Mk19_01", 1600]
];

// groundTransport
F_Truck_List = [
    ["rhsusf_M1078A1P2_WD_fmtv_usarmy", 650],
    ["rhsusf_M1078A1P2_B_WD_fmtv_usarmy", 650]
];

F_Truck_Construction_List = [
    ["rhsusf_M977A4_REPAIR_usarmy_wd", 1000]
];

F_Truck_Ammo_List = [
    ["rhsusf_M977A4_AMMO_usarmy_wd", 1000]
];

F_Truck_Respawn_List = [
    ["B_BUSAUSMC_CGR_CAT1A2_01", 1500]
];

// groundMechanized
F_APC_List = [
    ["B_USAUSMC_M1232_MCTAGS_M2_01", 2000],
    ["B_USAUSMC_M1232_MCTAGS_Mk19_01", 2300]
];

// groundArmor
F_Tank_List = [
    ["B_USAUSMC_M1A1FEP_01", 5000],
    ["B_USAUSMC_M1A1HC_01", 6500]
];

// groundArtillery
F_Artillery_List = [
    ["B_USAUSMC_Rifleman_01", 950],
    ["B_USAUSMC_M142_HIMARS_01", 7000]
];

// airTransport
F_Heli_List = [
    ["rhsusf_CH53E_USMC", 4000],
    ["rhsusf_CH53E_USMC_GAU21", 4500],
    ["RHS_UH1Y", 6300]
];

// airTransport
F_Heli_Respawn_List = [
    ["B_USAUSMC_UH_1Y_Unarmed_01", 5500]
];

// airHeli
F_Heli_Gunship_List = [
    ["RHS_AH1Z_wd", 7500],
    ["RHS_UH1Y", 6300]
];

// airJet
F_Plane_List = [
    ["rhsusf_f22", 20000],
    ["RHS_A10", 18000],
];

// boat
F_Boat_List = [];

// airDrone
F_UAV_List = [
    ["B_UAV_05_F", 15000],
];

// groundDrone
F_UGV_List = [];

F_Container_List = [
    ["B_Slingload_01_Medevac_F", 350],
    ["B_Slingload_01_Ammo_F", 350],
    ["B_Slingload_01_Repair_F", 1000],
    ["B_Slingload_01_Fuel_F", 350]
];

F_Turret_List = [
    ["B_USAUSMC_M2HB_M3_01", 350],
    ["B_USAUSMC_M2HB_M3_AA_01", 350],
    ["B_USAUSMC_M41A4_TOW_01", 750]
];

// staticAA
F_SAM_List = [
    ["B_SAM_System_01_F", 35000],
    ["B_SAM_System_02_F", 35000],
    ["B_SAM_System_03_F", 35000],
    ["B_AAA_System_01_F", 35000]
];

// Default squad compositions
F_ASSLT_ENG = [F_Assault_Eng, F_Assault_AT, F_Assault_Eod];

F_ASSLT_TEAM = [F_Assault_TL, F_Assault_Eod, F_Assault_AT, F_Assault_Mg, F_Assault_Mrk, F_Assault_Amm];

F_ASSLT_SQD = [F_Assault_SL, F_Assault_Eod, F_Assault_AT, F_Assault_Mg, F_Assault_Mrk, F_Assault_Amm, F_Assault_Med, F_Assault_AT, F_Assault_Mg, F_Assault_Mrk, F_Assault_Uav];

F_SNP_TEAM = [F_Recon_Snp, F_Recon_Sct];

F_RCN_TEAM = [F_Recon_TL, F_Recon_AT, F_Recon_Mrk, F_Recon_Mg];

F_RCN_SQD = [F_Recon_TL, F_Recon_AT, F_Recon_Eod, F_Recon_Mg, F_Recon_Eng, F_Recon_Mrk];

F_DVR_TEAM = [F_Diver_TL, F_Diver_Eod, F_Diver_Rfl, F_Diver_Eod];

F_OFFICER_TEAM = [F_Officer, F_Assault_Amm];
