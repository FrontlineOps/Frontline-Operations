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
 *   radar            = FLO_FactionRadar
 *   boat             = F_Boat_List
 *
 * If you want to change what the commander can spawn, change the source data
 * that feeds the category above. You do not need to define separate West_* pools here.
 *
 */

// Default player faction units (Vanilla Arma 3 NATO)
// F_Officer + all F_Assault_* roles feed the commander groundInfantry pool.
// All F_Recon_* and F_Diver_* roles feed the commander groundSpecOps pool.
F_Officer = "BWA3_Officer_Fleck";    // Officer
F_Assault_Eng = "BWA3_Engineer_Fleck";    // Engineer
F_Assault_TL = "BWA3_TL_Fleck";    // Assault Squad Leader
F_Assault_SL = "BWA3_SL_Fleck";    // Assault Platoon Leader
F_Assault_Eod = "BWA3_RiflemanAA_Fliegerfaust_Fleck";    // Explosive Specialist
F_Assault_Mrk = "BWA3_Marksman_Fleck";    // Marksman
F_Assault_AT = "BWA3_RiflemanAT_PzF3_Fleck";    // Anti Tank
F_Assault_Amm = "BWA3_RiflemanAT_RGW90_Fleck";    // Ammo Bearer
F_Assault_Mg = "BWA3_MachineGunner_MG4_Fleck";    // Auto Rifleman
F_Assault_Med = "BWA3_Medic_Fleck";    // Medic
F_Assault_Uav = "BWA3_Rifleman_G27_Fleck1";    // UAV operator

F_Recon_Snp = "BWA3_Sniper_G82_Fleck";    // Recon Sniper
F_Recon_Sct = "BWA3_Spotter_Fleck";    // Recon Spotter

F_Recon_TL = "BWA3_recon_TL_Fleck";    // Recon Squad Leader
F_Recon_Mrk = "BWA3_recon_Marksman_Fleck";   // Recon Marksman
F_Recon_AT = "BWA3_recon_LAT_Fleck";   // Recon AntiTank
F_Recon_Mg = "BWA3_recon_Fleck";    // Recon Auto Rifleman
F_Recon_Eod = "BWA3_recon_Pioneer_Fleck";    // Recon Explosive specialist
F_Recon_Med = "BWA3_recon_Medic_Fleck";    // Recon Medic
F_Recon_Eng = "BWA3_recon_Fleck";    // Recon Engineer

F_Diver_TL = "B_diver_TL_F";    // Diver Team Leader
F_Diver_Rfl = "B_diver_F";    // Diver operator
F_Diver_Eod = "B_diver_exp_F";    // Diver Explosive specialist

// Default base objects and vehicles
// FLO_FactionRadar feeds the commander radar pool.
FLO_FactionRadar = "I_E_Radar_System_01_F";      // Use "I_E_Radar_System_01_F" for Woodland Camo   // "B_Radar_System_01_F" for Desert Camo

FLO_FactionFobType = "Land_Cargo_HQ_V1_F";      // Use "Land_Cargo_HQ_V1_F" for Woodland Camo   // "Land_Cargo_HQ_V3_F" for Desert Camo
FLO_FactionFobTerminalType = "Land_TripodScreen_01_large_F";      // Use "Land_TripodScreen_01_large_F" for Woodland Camo   // "Land_TripodScreen_01_large_sand_F" for Desert Camo

FLO_FactionCopType = "Land_Cargo_House_V1_F";      // Use "Land_Cargo_House_V1_F" for Woodland Camo   // "Land_Cargo_House_V3_F" for Desert Camo
FLO_FactionCopTerminalType = "Land_TripodScreen_01_dual_v2_F";      // Use "Land_TripodScreen_01_dual_v2_F" for Woodland Camo   // "Land_TripodScreen_01_dual_v2_sand_F" for Desert Camo

// Vehicle lists with custom prices
// These same lists also feed commander/virtualization pools as described above.
F_Bike_List = [
    ["B_Quadbike_01_F", 50]
];

// groundMotorized
F_Car_List = [
    ["BWA3_Eagle_FLW100_Fleck", 600],
    ["BWA3_Multi_Fleck", 250]
];

// groundMotorized
F_MRAP_List = [
    ["BWA3_Dingo2_FLW100_MG3_Fleck", 700],
    ["BWA3_Dingo2_FLW200_GMW_Fleck", 900],
    ["BWA3_Dingo2_FLW200_M2_Fleck", 1100],
    ["BWA3_Dingo2_FLW200_GMW_CG13_Fleck", 1300],
    ["BWA3_Dingo2_FLW100_MG3_CG13_Fleck", 1300]
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
    ["BWA3_Eagle_Fleck", 1500]
];

// groundMechanized
F_APC_List = [
    ["BWA3_Puma_Fleck", 2000]
];

// groundArmor
F_Tank_List = [
    ["BWA3_Leopard2_Fleck", 6500]
];

// groundArtillery
F_Artillery_List = [
    ["BWA3_Panzerhaubitze2000_Fleck", 7000]
];

// airTransport
F_Heli_List = [
    ["BWA3_NH90_TTH_Fleck", 4000],
    ["BWA3_NH90_TTH_M3M_Fleck", 4500]
];

// airTransport
F_Heli_Respawn_List = [];

// airHeli
F_Heli_Gunship_List = [
    ["BWA3_Tiger_RMK", 7500],
    ["BWA3_Tiger", 6300]
];

// airJet
F_Plane_List = [
    ["rhsusf_f22", 20000],
    ["RHS_A10", 18000]
];

// boat
F_Boat_List = [];

// airDrone
F_UAV_List = [];

// groundDrone
F_UGV_List = [];

F_Container_List = [
    ["B_Slingload_01_Medevac_F", 350],
    ["B_Slingload_01_Ammo_F", 350],
    ["B_Slingload_01_Fuel_F", 350]
];

F_Turret_List = [
    ["BWA3_Rifleman_Fleck", 750]
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
