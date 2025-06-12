// Where are Classnames ? Right click on any Unit or Vehicle in the Editor and Select find in CFG viewer, Last Name in the [path] tab is the Classname,

// Default player faction units (Vanilla Arma 3 NATO)
F_Officer = "B_officer_F";    // Officer 
F_Assault_Eng = "B_engineer_F";    // Engineer
F_Assault_TL = "B_Soldier_TL_F";    // Assault Squad Leader 
F_Assault_SL = "B_Soldier_SL_F";    // Assault Platoon Leader 
F_Assault_Eod = "B_soldier_exp_F";    // Explosive Specialist
F_Assault_Mrk = "B_soldier_M_F";    // Marksman 
F_Assault_AT = "B_soldier_LAT_F";    // Anti Tank 
F_Assault_Amm = "B_Soldier_A_F";    // Ammo Bearer 
F_Assault_Mg = "B_soldier_AR_F";    // Auto Rifleman    
F_Assault_Med = "B_medic_F";    // Medic
F_Assault_Uav = "B_soldier_UAV_F";    // UAV operator

F_Recon_Snp = "B_sniper_F";    // Recon Sniper 
F_Recon_Sct = "B_spotter_F";    // Recon Spotter  

F_Recon_TL = "B_recon_TL_F";    // Recon Squad Leader 
F_Recon_Mrk = "B_recon_M_F";   // Recon Marksman
F_Recon_AT = "B_recon_LAT_F";   // Recon AntiTank
F_Recon_Mg = "B_recon_JTAC_F";    // Recon Auto Rifleman
F_Recon_Eod = "B_recon_exp_F";    // Recon Explosive specialist
F_Recon_Med = "B_recon_medic_F";    // Recon Medic  
F_Recon_Eng = "B_recon_F";    // Recon Engineer

F_Diver_TL = "B_diver_TL_F";    // Diver Team Leader
F_Diver_Rfl = "B_diver_F";    // Diver operator 
F_Diver_Eod = "B_diver_exp_F";    // Diver Explosive specialist

// Default base objects and vehicles
F_RADAR = "B_Radar_System_01_F";      // Use "I_E_Radar_System_01_F" for Woodland Camo   // "B_Radar_System_01_F" for Desert Camo

F_HQ_01 = "Land_Cargo_HQ_V3_F";      // Use "Land_Cargo_HQ_V1_F" for Woodland Camo   // "Land_Cargo_HQ_V3_F" for Desert Camo
F_HQ_C_01 = "Land_TripodScreen_01_large_sand_F";      // Use "Land_TripodScreen_01_large_F" for Woodland Camo   // "Land_TripodScreen_01_large_sand_F" for Desert Camo

F_OP_01 = "Land_Cargo_House_V3_F";      // Use "Land_Cargo_House_V1_F" for Woodland Camo   // "Land_Cargo_House_V3_F" for Desert Camo
F_OP_C_01 = "Land_TripodScreen_01_dual_v2_sand_F";      // Use "Land_TripodScreen_01_dual_v2_F" for Woodland Camo   // "Land_TripodScreen_01_dual_v2_sand_F" for Desert Camo

// Vehicle lists with custom prices
F_Bike_List = [
    ["B_Quadbike_01_F", 5]
];

F_Car_List = [
    ["B_LSV_01_unarmed_F", 25],
    ["B_LSV_01_light_F", 35],
    ["B_MRAP_01_F", 50],
    ["B_LSV_01_armed_F", 50]
];

F_MRAP_List = [
    ["B_MRAP_01_hmg_F", 70],
    ["B_MRAP_01_gmg_F", 100]
];

F_Truck_List = [
    ["B_Truck_01_covered_F", 65],
    ["B_Truck_01_transport_F", 65]
];

F_Truck_Special_List = [
    ["B_Truck_01_ammo_F", 100],
    ["B_Truck_01_box_F", 100]
];

F_Truck_Respawn_List = [
    ["B_Truck_01_medical_F", 150]
];

F_APC_List = [
    ["B_APC_Tracked_01_AA_F", 200],
    ["B_APC_Tracked_01_CRV_F", 200],
    ["B_APC_Tracked_01_rcws_F", 250],
    ["B_APC_Wheeled_01_cannon_F", 350]
];

F_Tank_List = [
    ["B_MBT_01_cannon_F", 500],
    ["B_MBT_01_TUSK_F", 650]
];

F_Artillery_List = [
    ["B_Mortar_01_F", 75],    
    ["B_MBT_01_arty_F", 400],
    ["B_MBT_01_mlrs_F", 500]
];

F_Heli_List = [
    ["B_Heli_Transport_01_F", 200],
    ["B_Heli_Transport_03_F", 400],
    ["B_Heli_Light_01_F", 250]
];

F_Heli_Respawn_List = [
    ["B_Heli_Transport_01_medevac_F", 550]
];

F_Heli_Gunship_List = [
    ["B_Heli_Attack_01_dynamicLoadout_F", 750]
];

F_Plane_List = [
    ["B_T_VTOL_01_infantry_F", 1200],
    ["B_T_VTOL_01_vehicle_F", 1200],
    ["B_Plane_CAS_01_dynamicLoadout_F", 1500]
];

F_Boat_List = [];

F_UAV_List = [
    ["B_UAV_02_dynamicLoadout_F", 80],
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

// Default squad compositions
F_ASSLT_ENG = [F_Assault_Eng, F_Assault_AT, F_Assault_Eod];

F_ASSLT_TEAM = [F_Assault_TL, F_Assault_Eod, F_Assault_AT, F_Assault_Mg, F_Assault_Mrk, F_Assault_Amm];

F_ASSLT_SQD = [F_Assault_SL, F_Assault_Eod, F_Assault_AT, F_Assault_Mg, F_Assault_Mrk, F_Assault_Amm, F_Assault_Med, F_Assault_AT, F_Assault_Mg, F_Assault_Mrk, F_Assault_Uav];

F_SNP_TEAM = [F_Recon_Snp, F_Recon_Sct];

F_RCN_TEAM = [F_Recon_TL, F_Recon_AT, F_Recon_Mrk, F_Recon_Mg];

F_RCN_SQD = [F_Recon_TL, F_Recon_AT, F_Recon_Eod, F_Recon_Mg, F_Recon_Eng, F_Recon_Mrk];

F_DVR_TEAM = [F_Diver_TL, F_Diver_Eod, F_Diver_Rfl, F_Diver_Eod];

F_OFFICER_TEAM = [F_Officer, F_Assault_Amm];
