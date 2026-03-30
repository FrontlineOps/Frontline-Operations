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
 *   objectiveGroupTypeCaps = West_Objective_Group_Type_Caps
 *   boat             = F_Boat_List
 *
 * If you want to change what the commander can spawn, change the source data
 * that feeds the category above. You do not need to define separate West_* pools here.
 *
 * Optional side-wide objective seeding caps:
 *   West_Objective_Group_Type_Caps = [["artillery", 5], ["jet", 3]]
 * These caps apply across all owned seeded objectives combined, not per city.
 */

// Default player faction units (Vanilla Arma 3 NATO)
// F_Officer + all F_Assault_* roles feed the commander groundInfantry pool.
// All F_Recon_* and F_Diver_* roles feed the commander groundSpecOps pool.
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
// F_RADAR feeds the commander radar pool.
F_RADAR = "B_Radar_System_01_F";      // Use "I_E_Radar_System_01_F" for Woodland Camo   // "B_Radar_System_01_F" for Desert Camo

F_HQ_01 = "Land_Cargo_HQ_V3_F";      // Use "Land_Cargo_HQ_V1_F" for Woodland Camo   // "Land_Cargo_HQ_V3_F" for Desert Camo
F_HQ_C_01 = "Land_TripodScreen_01_large_sand_F";      // Use "Land_TripodScreen_01_large_F" for Woodland Camo   // "Land_TripodScreen_01_large_sand_F" for Desert Camo

F_OP_01 = "Land_Cargo_House_V3_F";      // Use "Land_Cargo_House_V1_F" for Woodland Camo   // "Land_Cargo_House_V3_F" for Desert Camo
F_OP_C_01 = "Land_TripodScreen_01_dual_v2_sand_F";      // Use "Land_TripodScreen_01_dual_v2_F" for Woodland Camo   // "Land_TripodScreen_01_dual_v2_sand_F" for Desert Camo

// Vehicle lists with custom prices
// These same lists also feed commander/virtualization pools as described above.
F_Bike_List = [
    ["B_Quadbike_01_F", 5]
];

// groundMotorized
F_Car_List = [
    ["B_LSV_01_unarmed_F", 25],
    ["B_LSV_01_light_F", 35],
    ["B_MRAP_01_F", 50],
    ["B_LSV_01_armed_F", 50]
];

// groundMotorized
F_MRAP_List = [
    ["B_MRAP_01_hmg_F", 70],
    ["B_MRAP_01_gmg_F", 100]
];

// groundTransport
F_Truck_List = [
    ["B_Truck_01_covered_F", 65],
    ["B_Truck_01_transport_F", 65]
];
West_Transport_Reserve_Ground_Count = 20;

F_Truck_Construction_List = [
    ["B_Truck_01_ammo_F", 100]
];

F_Truck_Ammo_List = [
    ["B_Truck_01_box_F", 100]
];

F_Truck_Respawn_List = [
    ["B_Truck_01_medical_F", 150]
];

// groundMechanized
F_APC_List = [
    ["B_APC_Tracked_01_AA_F", 200],
    ["B_APC_Tracked_01_CRV_F", 200],
    ["B_APC_Tracked_01_rcws_F", 250],
    ["B_APC_Wheeled_01_cannon_F", 350]
];

// groundArmor
F_Tank_List = [
    ["B_MBT_01_cannon_F", 500],
    ["B_MBT_01_TUSK_F", 650]
];

// groundArtillery
F_Artillery_List = [
    ["B_Mortar_01_F", 75],    
    ["B_MBT_01_arty_F", 400],
    ["B_MBT_01_mlrs_F", 500]
];

// airTransport
F_Heli_List = [
    ["B_Heli_Transport_01_F", 200],
    ["B_Heli_Transport_03_F", 400],
    ["B_Heli_Light_01_F", 250]
];
West_Transport_Reserve_Air_Count = 10;

// airTransport
F_Heli_Respawn_List = [
    ["B_Heli_Transport_01_medevac_F", 550]
];

// airHeli
F_Heli_Gunship_List = [
    ["B_Heli_Attack_01_dynamicLoadout_F", 750]
];

// airJet
F_Plane_List = [
    ["B_T_VTOL_01_infantry_F", 1200],
    ["B_T_VTOL_01_vehicle_F", 1200],
    ["B_Plane_CAS_01_dynamicLoadout_F", 1500]
];

// boat
F_Boat_List = [];

// airDrone
F_UAV_List = [
    ["B_UAV_02_dynamicLoadout_F", 80],
    ["B_UAV_05_F", 80],
    ["B_T_UAV_03_dynamicLoadout_F", 80]
];

// groundDrone
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

// staticAA
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
        ["motorized", 2]
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

