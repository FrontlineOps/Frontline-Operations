// ============================================================================
// ADF FACTION - BLUFOR (ADF Re-Cut Mod)
// Australian Defence Force in Australian Multicam Camouflage Uniform (AMCU)
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
 *   transportReserveGroundCount = West_Transport_Reserve_Ground_Count
 *   groundArtillery  = F_Artillery_List
 *   airTransport     = F_Heli_List + F_Heli_Respawn_List
 *   transportReserveAirCount = West_Transport_Reserve_Air_Count
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
 */
// ============================================================================
// INFANTRY UNITS
// ============================================================================
// F_Officer + all F_Assault_* roles feed the commander groundInfantry pool.
// All F_Recon_* and F_Diver_* roles feed the commander groundSpecOps pool.
F_Officer = "ADFRC_MD_AMCU_Soldier_Officer";    // Officer

F_Assault_Eng = "ADFRC_MD_AMCU_Soldier_Engineer";    // Engineer
F_Assault_TL = "ADFRC_MD_AMCU_Soldier_BrickComm";    // Assault Squad Leader 
F_Assault_SL = "ADFRC_MD_AMCU_Soldier_SectionComm";    // Assault Platoon Leader 
F_Assault_Eod = "ADFRC_MD_AMCU_CDO_EOD";    // Explosive Specialist
F_Assault_Mrk = "ADFRC_MD_AMCU_Soldier_Marksman";    // Marksman 
F_Assault_AT = "ADFRC_MD_AMCU_Soldier_MATGunner";    // Anti Tank 
F_Assault_Amm = "ADFRC_MD_AMCU_Soldier_AmmoBearer";    // Ammo Bearer 
F_Assault_Mg = "ADFRC_MD_AMCU_Soldier_MMG";    // Auto Rifleman    
F_Assault_Med = "ADFRC_MD_AMCU_Soldier_CFA";    // Medic
F_Assault_Uav = "ADFRC_MD_AMCU_Support_UAV";    // UAV operator

F_Recon_Snp = "ADFRC_MD_AMCU_CDO_Scout";    // Recon Sniper 
F_Recon_Sct = "ADFRC_MD_AMCU_CDO_Scout";    // Recon Spotter  

F_Recon_TL = "ADFRC_MD_AMCU_CDO_PatrolCom";    // Recon Squad Leader 
F_Recon_Mrk = "ADFRC_MD_AMCU_CDO_Scout";   // Recon Marksman
F_Recon_AT = "ADFRC_MD_AMCU_Soldier_MATGunner";   // Recon AntiTank
F_Recon_Mg = "ADFRC_MD_AMCU_CDO_MMG";    // Recon Auto Rifleman
F_Recon_Eod = "ADFRC_MD_AMCU_CDO_EOD";    // Recon Explosive specialist
F_Recon_Med = "ADFRC_MD_AMCU_CDO_CFA";    // Recon Medic  
F_Recon_Eng = "ADFRC_MD_AMCU_Soldier_Engineer";    // Recon Engineer

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
// F_RADAR feeds the commander radar pool.
F_RADAR = "B_Radar_System_01_F";
F_HQ_01 = "Land_Cargo_HQ_V3_F";
F_HQ_C_01 = "Land_TripodScreen_01_large_sand_F";
F_OP_01 = "Land_Cargo_House_V3_F";
F_OP_C_01 = "Land_TripodScreen_01_dual_v2_sand_F";

// ============================================================================
// VEHICLE LISTS - Format: [[classname, price], ...]
// ============================================================================
// These same lists also feed commander/virtualization pools as described above.

F_Bike_List = [
    ["B_Quadbike_01_F", 50]
];

// groundMotorized
F_Car_List = [
    ["B_LSV_01_unarmed_F", 250],
    ["adfrc_bushmaster_unarmed_F", 500],
    ["B_LSV_01_armed_F", 500],
    ["B_LSV_01_AT_F", 600]
];

// groundMotorized
F_MRAP_List = [
    ["B_T_MRAP_01_F", 500],
    ["B_T_MRAP_01_hmg_F", 700],
    ["B_T_MRAP_01_gmg_F", 1000],
    ["adfrc_bushmaster_pws127mm_F", 700]
];

// groundTransport
F_Truck_List = [
    ["B_Truck_01_covered_F", 650],
    ["B_Truck_01_transport_F", 650],
    ["ADFRC_hemtt_transport", 650]
];

West_Transport_Reserve_Ground_Count = 20;

F_Truck_Ammo_List = [
    ["ADFRC_hemtt_ammo", 1000],
    ["B_Truck_01_ammo_F", 1000]
];

F_Truck_Construction_List = [
    ["B_Truck_01_Repair_F", 1000]
];

F_Truck_Respawn_List = [
    ["B_Truck_01_medical_F", 1500]
];

// groundMechanized
F_APC_List = [
    ["ADFRC_ASLAV_PC", 2000],
    ["ADFRC_ASLAV_PC_MAG58", 2000],
    ["ADFRC_ASLAV_PC_RWS", 2000],
    ["ADFRC_ASLAV", 2500],
    ["adfrc_boxer_crv_b2", 3500]
];

// groundArmor
F_Tank_List = [
    ["adfrc_m1a1aim_md", 5000]
];

// groundArtillery
F_Artillery_List = [
    ["B_Mortar_01_F", 750],    
    ["B_MBT_01_arty_F", 4000],
    ["B_MBT_01_mlrs_F", 5000]
];

// airTransport
F_Heli_List = [
    ["ADFRC_blackhawk_mag58", 2000],
    ["ADFRC_chinook", 4000],
    ["B_Heli_Light_01_F", 2500]
];
West_Transport_Reserve_Air_Count = 10;

// airTransport
F_Heli_Respawn_List = [
    ["B_Heli_Transport_01_medevac_F", 5500]
];

// airHeli
F_Heli_Gunship_List = [
    ["B_Heli_Light_01_dynamicLoadout_F", 5000],
    ["adfrc_apache", 7500]
];

// airJet
F_Plane_List = [
    ["B_Plane_CAS_01_dynamicLoadout_F", 15000],
    ["B_Plane_Fighter_01_F", 18000],
    ["B_T_VTOL_01_infantry_F", 12000],
    ["B_T_VTOL_01_vehicle_F", 12000],
    ["B_T_VTOL_01_armed_F", 16000]
];

// boat
F_Boat_List = [
    ["B_Boat_Armed_01_minigun_F", 1500]
];

// airDrone
F_UAV_List = [
    ["B_UAV_02_dynamicLoadout_F", 800],
    ["B_UAV_05_F", 800],
    ["B_T_UAV_03_dynamicLoadout_F", 800]
];

// groundDrone
F_UGV_List = [
    ["B_T_UGV_01_rcws_olive_F", 550],
    ["B_UGV_01_rcws_F", 550]
];

F_Container_List = [
    ["B_Slingload_01_Medevac_F", 350],
    ["B_Slingload_01_Ammo_F", 350],
    ["B_Slingload_01_Repair_F", 1000],
    ["B_Slingload_01_Fuel_F", 350]
];

F_Turret_List = [
    ["B_HMG_01_high_F", 350],
    ["B_GMG_01_high_F", 350],
    ["B_static_AT_F", 350]
];

// staticAA
F_SAM_List = [
    ["B_SAM_System_01_F", 5000],
    ["B_SAM_System_02_F", 5000],
    ["B_SAM_System_03_F", 5000],
    ["B_AAA_System_01_F", 5000]
];

/*
 * BLUFOR Virtualization Objective Configuration
 * This section defines how many of each unit type should spawn at different
 * objective subtypes produced by the objective indexing system. Subtypes
 * include "capital", "city", "village", "local", "marine" and "cluster".
 *
 * Structure: [objective subtype, [[group type, count], [group type, count], ...]]
 */
BLUFOR_Objective_Groups = [
    // Capital objectives - highest concentration of defenders
    ["capital", [
        ["infantry", 12],
        ["motorized", 2],
        ["mechanized", 1],
        ["air", 1],
        ["armor", 1],
        ["artillery", 1],
        ["static_aa", 1],
        ["mobile_aa", 1]
    ]],

    // Major cities
    ["city", [
        ["infantry", 7],
        ["motorized", 2],
        ["mechanized", 1],
        ["air", 1],
        ["armor", 1],
        ["artillery", 1],
        ["static_aa", 1],
        ["mobile_aa", 1]
    ]],

    // Villages
    ["village", [
        ["infantry", 3]
    ]],

    // Small local objectives
    // These tend to be military bases, strategic infrastructure, or other military-like objectives
    ["local", [
        ["infantry", 6],
        ["motorized", 2],
        ["mechanized", 1],
        ["mobile_aa", 1]
    ]],

    // Coastal or marine facilities
    ["marine", [
        ["infantry", 3],
        ["motorized", 1]
    ]],

    // Automatically generated clusters
    ["cluster", [
        ["infantry", 2]
    ]]
];

/*
 * Optional side-wide objective seeding caps:
 *   West_Objective_Group_Type_Caps = [["artillery", 5], ["jet", 3]]
 * These caps apply across all owned seeded objectives combined.
 */
West_Objective_Group_Type_Caps = [
    ["jet", 10],
    ["helicopter", 10],
    ["artillery", 5],
    ["static_aa", 3],
    ["mobile_aa", 20]
];

/*
 * Group Type Unit/Vehicle Counts
 * Defines how many physical units/vehicles should be in each type of group
 */
BLUFOR_Group_Counts = [
    ["infantry", 10],          // Number of individual soldiers
    ["motorized", 2],         // Number of armed vehicles (MRAP, GMG, etc.)
    ["mechanized", 2],        // Number of APCs/IFVs
    ["armor", 2],             // Number of tanks
    ["helicopter", 1],        // Number of helicopters
    ["jet", 1],               // Number of jets
    ["air", 1],               // Number of aircraft
    ["artillery", 3],         // Number of artillery pieces
    ["mobile_aa", 1],         // Number of mobile AA vehicles
    ["static_aa", 1]          // Number of static SAM launchers
];
