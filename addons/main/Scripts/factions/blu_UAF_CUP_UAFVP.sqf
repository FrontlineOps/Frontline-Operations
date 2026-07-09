// ============================================================================
// UAF FACTION - BLUFOR (CUP)
// Ukrainian Armed Forces in MM14 camouflage
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
F_Officer = "Flex_CUP_UAF_officer";    // Officer

F_Assault_Eng = "Flex_CUP_UAF_mechanic";    // Engineer
F_Assault_TL = "Flex_CUP_UAF_teamleader";    // Assault Squad Leader 
F_Assault_SL = "Flex_CUP_UAF_teamleader";    // Assault Platoon Leader 
F_Assault_Eod = "Flex_CUP_UAF_demolition";    // Explosive Specialist
F_Assault_Mrk = "Flex_CUP_UAF_marksman";    // Marksman 
F_Assault_AT = "Flex_CUP_UAF_antitank";    // Anti Tank 
F_Assault_Amm = "Flex_CUP_UAF_assistant";    // Ammo Bearer 
F_Assault_Mg = "Flex_CUP_UAF_machinegunner";    // Auto Rifleman    
F_Assault_Med = "Flex_CUP_UAF_medic";    // Medic
F_Assault_Uav = "Flex_CUP_UAF_rifleman_uav";    // UAV operator

F_Recon_Snp = "Flex_CUP_UAF_marksman";    // Recon Sniper 
F_Recon_Sct = "Flex_CUP_UAF_radioman";    // Recon Spotter  

F_Recon_TL = "Flex_CUP_UAF_teamleader";    // Recon Squad Leader 
F_Recon_Mrk = "Flex_CUP_UAF_marksman";   // Recon Marksman
F_Recon_AT = "Flex_CUP_UAF_antitank";   // Recon AntiTank
F_Recon_Mg = "Flex_CUP_UAF_machinegunner";    // Recon Auto Rifleman
F_Recon_Eod = "Flex_CUP_UAF_demolition";    // Recon Explosive specialist
F_Recon_Med = "Flex_CUP_UAF_medic";    // Recon Medic  
F_Recon_Eng = "Flex_CUP_UAF_mechanic";    // Recon Engineer

F_Diver_TL = "B_diver_TL_F";    // Diver Team Leader
F_Diver_Rfl = "B_diver_F";    // Diver operator 
F_Diver_Eod = "B_diver_exp_F";    // Diver Explosive specialist

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
FLO_FactionRadar = "I_E_Radar_System_01_F";
FLO_FactionFobType = "Land_Cargo_HQ_V1_F";
FLO_FactionFobTerminalType = "Land_TripodScreen_01_large_F";
FLO_FactionCopType = "Land_Cargo_House_V1_F";
FLO_FactionCopTerminalType = "Land_TripodScreen_01_dual_v2_F";

// ============================================================================
// VEHICLE LISTS - Format: [[classname, price], ...]
// ============================================================================
// These same lists also feed commander/virtualization pools as described above.

F_Bike_List = [
    ["B_T_Quadbike_01_F", 50]
];

// groundMotorized
F_Car_List = [
    ["Flex_CUP_UAF_UAZ_Unarmed", 250],
    ["Flex_CUP_UAF_UAZ_AMB", 250],
    ["Flex_CUP_UAF_UAZ_Open", 250],
    ["Flex_CUP_UAF_UAZ_MG", 500],
    ["Flex_CUP_UAF_UAZ_SPG9", 600],
    ["Flex_CUP_UAF_UAZ_AGS30", 750],
    ["Flex_CUP_UAF_UAZ_METIS", 750],
    ["Flex_CUP_UAF_Tigr_233014", 500],
    ["Flex_CUP_UAF_Tigr_M_233114", 600],
    ["Flex_CUP_UAF_Tigr_233014_PK", 750],
    ["Flex_CUP_UAF_Tigr_M_233114_PK", 850],
    ["Flex_CUP_UAF_Tigr_M_233114_KORD", 1000],
    ["Flex_CUP_UAF_Novator", 500],
    ["Flex_CUP_UAF_Novator_ATGM", 1000],
    ["Flex_CUP_UAF_nM1151_Unarmed_DF", 500],
    ["Flex_CUP_UAF_nM1151_ogpk_m2_DF", 850],
    ["Flex_CUP_UAF_nM1151_ogpk_m240_DF", 750],
    ["Flex_CUP_UAF_nM1151_ogpk_mk19_DF", 1250]
];

// groundMotorized
F_MRAP_List = [
    ["Flex_CUP_UAF_Shrek", 500],
    ["Flex_CUP_UAF_Fiona", 600],
    ["Flex_CUP_UAF_Dozor", 750],
    ["Flex_CUP_UAF_Dozor_Armed", 1250]
];

// groundTransport
F_Truck_List = [
    ["Flex_CUP_UAF_Ural_Open", 650],
    ["Flex_CUP_UAF_Ural", 650]
];

F_Truck_Ammo_List = [
    ["Flex_CUP_UAF_Ural_Reammo", 1000]
];

F_Truck_Construction_List = [
    ["Flex_CUP_UAF_Ural_Repair", 1000]
];

F_Truck_Respawn_List = [
    ["Flex_CUP_UAF_Fiona_Ambulance", 1500]
];

// groundMechanized
F_APC_List = [
    ["Flex_CUP_UAF_MTLB_pk", 2000],
    ["Flex_CUP_UAF_BRDM2_HQ", 2000],
    ["Flex_CUP_UAF_BRDM2", 2500],
    ["Flex_CUP_UAF_BRDM2_ATGM", 3500],
    ["Flex_CUP_UAF_BMP1U", 4000],
    ["Flex_CUP_UAF_BTR60", 3500],
    ["Flex_CUP_UAF_BTR3", 4000],
    ["Flex_CUP_UAF_BTR4", 4500],
    ["Flex_CUP_UAF_M2Bradley", 5000],
    ["Flex_CUP_UAF_M2A3Bradley", 5500]
];

// groundArmor
F_Tank_List = [
    ["Flex_CUP_UAF_Leopard_1A3GRN", 6500],
    ["Flex_CUP_UAF_Leopard2A4_ERA", 8000],
    ["Flex_CUP_UAF_Leopard2A6", 8500],
    ["Flex_CUP_UAF_M1A1_TUSK", 8250],
    ["Flex_CUP_UAF_T64BV1", 6500],
    ["Flex_CUP_UAF_T64BM2", 7500],
    ["Flex_CUP_UAF_T84M", 8000]
];

// groundArtillery
F_Artillery_List = [
    ["Flex_CUP_UAF_2b14_82mm", 750],
    ["Flex_CUP_UAF_D30", 1500],    
    ["Flex_CUP_UAF_2S17", 4000],
    ["Flex_CUP_UAF_BM21", 5000]
];

// airTransport
F_Heli_List = [
    ["Flex_CUP_UAF_Mi17", 2500],
    ["CUP_B_MH6J_USA", 2000]
];

// airTransport
F_Heli_Respawn_List = [
    ["CUP_B_Mi17_medevac_AFU", 5500],
    ["CUP_B_Mi24_D_MEV_Dynamic_AFU", 7500]
];

// airHeli
F_Heli_Gunship_List = [
    ["Flex_CUP_UAF_Mi24_D", 10000],
    ["Flex_CUP_UAF_Mi171Sh", 6500],
    ["B_Heli_Light_01_dynamicLoadout_F", 4500]
];

// airJet
F_Plane_List = [
    ["Flex_CUP_UAF_Mig29", 15000],
    ["Flex_CUP_UAF_F16A", 18000]
];

// boat
F_Boat_List = [
    ["B_Boat_Armed_01_minigun_F", 1500]
];

// airDrone
F_UAV_List = [
    ["Flex_CUP_UAF_UAV", 800]
];

// groundDrone
F_UGV_List = [
    ["Flex_CUP_UAF_RSVK", 550],
    ["Flex_CUP_UAF_RSVK_Armed", 800]
];

F_Container_List = [
    ["B_Slingload_01_Medevac_F", 350],
    ["B_Slingload_01_Ammo_F", 350],
    ["B_Slingload_01_Fuel_F", 350]
];

F_Turret_List = [
    ["Flex_CUP_UAF_DSHKM", 350],
    ["Flex_CUP_UAF_DSHKM_MiniTriPod", 350],
    ["Flex_CUP_UAF_HMG_high", 350],
    ["Flex_CUP_UAF_AGS", 650],
    ["Flex_CUP_UAF_SPG9", 500],
    ["Flex_CUP_UAF_D30_AT", 1000],
    ["Flex_CUP_UAF_ZU23", 2000],
    ["Flex_CUP_UAF_Igla_AA_pod", 2500]
];

// staticAA
F_SAM_List = [
    ["B_SAM_System_01_F", 35000],
    ["B_SAM_System_02_F", 35000],
    ["B_SAM_System_03_F", 35000],
    ["B_AAA_System_01_F", 35000]
];
