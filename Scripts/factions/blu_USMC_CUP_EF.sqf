// Where are Classnames? Right click on any Unit or Vehicle in the Editor and Select find in CFG viewer, Last Name in the [path] tab is the Classname,

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

// Flex_CUP_USMC faction units
// F_Officer + all F_Assault_* roles feed the commander groundInfantry pool.
// All F_Recon_* and F_Diver_* roles feed the commander groundSpecOps pool.
F_Officer = "Flex_CUP_USMC_officer";           // Officer
F_Assault_Eng = "Flex_CUP_USMC_mechanic";      // Engineer / Mechanic
F_Assault_TL = "Flex_CUP_USMC_teamleader";     // Assault Team Leader
F_Assault_SL = "Flex_CUP_USMC_radioman";       // Assault Squad Leader / Radioman
F_Assault_Eod = "Flex_CUP_USMC_demolition";    // Explosive Specialist
F_Assault_Mrk = "Flex_CUP_USMC_marksman";      // Marksman
F_Assault_AT = "Flex_CUP_USMC_antitank";       // Anti-Tank
F_Assault_ATL = "Flex_CUP_USMC_antitank_light"; // Light Anti-Tank
F_Assault_ATM = "Flex_CUP_USMC_antitank_missle"; // Anti-Tank Missile
F_Assault_Amm = "Flex_CUP_USMC_assistant";     // Assistant / Ammo Bearer
F_Assault_Mg = "Flex_CUP_USMC_machinegunner";  // Machinegunner
F_Assault_MgH = "Flex_CUP_USMC_machinegunner_heavy"; // Heavy Machinegunner
F_Assault_Med = "Flex_CUP_USMC_medic";         // Medic
F_Assault_Uav = "Flex_CUP_USMC_rifleman_uav";  // UAV Operator
F_Assault_GL = "Flex_CUP_USMC_grenadier";      // Grenadier
F_Assault_AA = "Flex_CUP_USMC_antiair";        // Anti-Air
F_Assault_Pf = "Flex_CUP_USMC_pathfinder";     // Pathfinder
F_Assault_AsMg = "Flex_CUP_USMC_assistant_mg"; // Assistant MG
F_Assault_AsAt = "Flex_CUP_USMC_assistant_at"; // Assistant AT

F_Recon_Snp = "Flex_CUP_USMC_recon_sniper";    // Recon Sniper
F_Recon_Sct = "Flex_CUP_USMC_recon_spotter";   // Recon Spotter
F_Recon_TL = "Flex_CUP_USMC_recon_tl";         // Recon Team Leader
F_Recon_Mrk = "Flex_CUP_USMC_recon_marksman";  // Recon Marksman
F_Recon_AT = "Flex_CUP_USMC_recon_lat";        // Recon Anti-Tank
F_Recon_Mg = "Flex_CUP_USMC_recon_jtac";       // Recon JTAC
F_Recon_Eod = "Flex_CUP_USMC_recon_exp";       // Recon Explosive Specialist
F_Recon_Med = "Flex_CUP_USMC_recon_medic";     // Recon Medic
F_Recon_Eng = "Flex_CUP_USMC_recon";           // Recon Operator

F_Diver_TL = "Flex_CUP_USMC_diver_tl";         // Diver Team Leader
F_Diver_Rfl = "Flex_CUP_USMC_diver";           // Diver Operator
F_Diver_Eod = "Flex_CUP_USMC_diver_engineer";  // Diver Engineer
F_Diver_Sct = "Flex_CUP_USMC_diver_scout";     // Diver Scout
F_Diver_Pt = "Flex_CUP_USMC_diver_pointman";   // Diver Pointman

// Default base objects and vehicles
// F_RADAR feeds the commander radar pool.
F_RADAR = "Flex_CUP_USMC_Radar_System";

F_HQ_01 = "Land_Cargo_HQ_V1_F";
F_HQ_C_01 = "Land_TripodScreen_01_large_F";

F_OP_01 = "Land_Cargo_House_V1_F";
F_OP_C_01 = "Land_TripodScreen_01_dual_v2_F";

// Vehicle lists with custom prices
// These same lists also feed commander/virtualization pools as described above.
F_Bike_List = [
    ["Flex_CUP_USMC_M1030", 50]       // Motorcycle
];

// groundMotorized - Light armed wheeled vehicles
F_Car_List = [
    ["Flex_CUP_USMC_nM1025_Unarmed", 250],
    ["Flex_CUP_USMC_nM1025_Unarmed_DF", 250],
    ["Flex_CUP_USMC_nM1025_M240", 350],
    ["Flex_CUP_USMC_nM1025_M240_DF", 350],
    ["Flex_CUP_USMC_nM1025_M2", 500],
    ["Flex_CUP_USMC_nM1025_M2_DF", 500],
    ["Flex_CUP_USMC_nM1025_Mk19", 500],
    ["Flex_CUP_USMC_nM1025_Mk19_DF", 500],
    ["Flex_CUP_USMC_nM1025_SOV_M2", 600],
    ["Flex_CUP_USMC_nM1025_SOV_Mk19", 600],
    ["Flex_CUP_USMC_nM1036_TOW", 700],
    ["Flex_CUP_USMC_nM1036_TOW_DF", 700]
];

// groundMotorized - MRAPs
F_MRAP_List = [
    ["Flex_CUP_USMC_nM1151_Unarmed", 500],
    ["Flex_CUP_USMC_nM1151_Unarmed_DF", 500],
    ["Flex_CUP_USMC_nM1151_mctags_m240", 700],
    ["Flex_CUP_USMC_nM1151_mctags_m240_DF", 700],
    ["Flex_CUP_USMC_nM1151_mctags_m2", 800],
    ["Flex_CUP_USMC_nM1151_mctags_m2_DF", 800],
    ["Flex_CUP_USMC_nM1151_mctags_mk19", 1000],
    ["Flex_CUP_USMC_nM1151_mctags_mk19_DF", 1000],
    ["Flex_CUP_USMC_RG31_M2", 800],
    ["Flex_CUP_USMC_RG31_M2_GC", 800],
    ["Flex_CUP_USMC_RG31E_M2", 900],
    ["Flex_CUP_USMC_RG31_Mk19", 1000],
    ["Flex_CUP_USMC_nM1097_AVENGER", 1500]    // Avenger air defense vehicle
];

// groundTransport
F_Truck_List = [
    ["Flex_CUP_USMC_nM1037sc", 400],
    ["Flex_CUP_USMC_nM1037sc_DF", 400],
    ["Flex_CUP_USMC_nM1038", 500],
    ["Flex_CUP_USMC_nM1038_DF", 500],
    ["Flex_CUP_USMC_nM1038_4s", 550],
    ["Flex_CUP_USMC_nM1038_4s_DF", 550],
    ["Flex_CUP_USMC_MTVR", 650],
    ["Flex_CUP_USMC_nM997", 400],
    ["Flex_CUP_USMC_nM997_DF", 400]
];
West_Transport_Reserve_Ground_Count = 20;

F_Truck_Construction_List = [
    ["Flex_CUP_USMC_nM1038_Repair", 1000],
    ["Flex_CUP_USMC_nM1038_Repair_DF", 1000],
    ["Flex_CUP_USMC_MTVR_Repair", 1000]
];

F_Truck_Ammo_List = [
    ["Flex_CUP_USMC_nM1038_Ammo", 1000],
    ["Flex_CUP_USMC_nM1038_Ammo_DF", 1000],
    ["Flex_CUP_USMC_MTVR_Ammo", 1000]
];

F_Truck_Respawn_List = [
    ["Flex_CUP_USMC_UH1Y_MEV", 5500]    // Medical evac heli as respawn/medevac asset
];

// groundMechanized - APCs / IFVs
F_APC_List = [
    ["Flex_CUP_USMC_AAV_Unarmed", 1500],
    ["Flex_CUP_USMC_AAV", 2000],
    ["Flex_CUP_USMC_AAV_TTS", 2500],
    ["Flex_CUP_USMC_LAV25M240", 2000],
    ["Flex_CUP_USMC_LAV25", 3000],
    ["Flex_CUP_USMC_LAV25_HQ", 3000]
];

// groundArmor - Main battle tanks
F_Tank_List = [
    ["Flex_CUP_USMC_M1A1FEP", 5000],
    ["Flex_CUP_USMC_M1A1FEP_TUSK", 6500]
];

// groundArtillery
F_Artillery_List = [
    ["Flex_CUP_USMC_Mortar", 750],
    ["Flex_CUP_USMC_M119", 1500],
    ["Flex_CUP_USMC_M270_HE", 4000],
    ["Flex_CUP_USMC_M270_DPICM", 5000]
];

// airTransport - Unarmed/transport rotary and tiltrotor
F_Heli_List = [
    ["Flex_CUP_USMC_UH1Y_UNA", 2000],
    ["Flex_CUP_USMC_MH60S_Unarmed", 2000],
    ["Flex_CUP_USMC_MH60S_Unarmed_FFV", 2250],
    ["Flex_CUP_USMC_CH53E", 3500],
    ["Flex_CUP_USMC_MV22", 4000],
    ["Flex_CUP_USMC_MV22_RAMPGUN", 4500],
    ["Flex_CUP_USMC_MV22_VIV", 4500]
];
West_Transport_Reserve_Air_Count = 10;

// airTransport - Medevac
F_Heli_Respawn_List = [
    ["Flex_CUP_USMC_UH1Y_MEV", 5500],
    ["Flex_CUP_USMC_CH53E_VIV", 6000],
    ["Flex_CUP_USMC_UH60S", 4000],
    ["Flex_CUP_USMC_MH60S", 4000]
];

// airHeli - Attack helicopters
F_Heli_Gunship_List = [
    ["Flex_CUP_USMC_AH1Z_Dynamic", 7500],
    ["Flex_CUP_USMC_UH1Y_Gunship_Dynamic", 6500],
    ["Flex_CUP_USMC_MH60L_DAP_2x", 8000],
    ["Flex_CUP_USMC_MH60L_DAP_4x", 9000]
];

// airJet - Fixed-wing combat aircraft
F_Plane_List = [
    ["Flex_CUP_USMC_AV8B_DYN", 12000],
    ["Flex_CUP_USMC_F35B", 15000],
    ["Flex_CUP_USMC_F35B_Stealth", 18000],
    ["Flex_CUP_USMC_C130J", 8000],
    ["Flex_CUP_USMC_C130J_Cargo", 8000]
];

// boat
F_Boat_List = [
    ["Flex_CUP_USMC_CombatBoat_Unarmed", 500],
    ["Flex_CUP_USMC_RHIB", 500],
    ["Flex_CUP_USMC_Boat_Transport", 500],
    ["Flex_CUP_USMC_Lifeboat", 300],
    ["Flex_CUP_USMC_CombatBoat_HMG", 1000],
    ["Flex_CUP_USMC_CombatBoat_AT", 1200],
    ["Flex_CUP_USMC_RHIB2Turret", 1200],
    ["Flex_CUP_USMC_Boat_Armed_01_minigun", 1500],
    ["Flex_CUP_USMC_SDV_01", 1000]           // Diver SDV
];

// airDrone
F_UAV_List = [
    ["Flex_CUP_USMC_UAV_01", 800],
    ["Flex_CUP_USMC_UAV_05", 800],
    ["Flex_CUP_USMC_UAV_06", 800],
    ["Flex_CUP_USMC_UAV_02_dynamicLoadout", 1200],
    ["Flex_CUP_USMC_DYN_MQ9", 1500]
];

// groundDrone - No UGV in this faction list; placeholder left empty
F_UGV_List = [];

F_Container_List = [
    ["B_Slingload_01_Medevac_F", 350],
    ["B_Slingload_01_Ammo_F", 350],
    ["B_Slingload_01_Repair_F", 1000],
    ["B_Slingload_01_Fuel_F", 350]
];

F_Turret_List = [
    ["Flex_CUP_USMC_HMG_Low", 350],
    ["Flex_CUP_USMC_HMG_High", 350],
    ["Flex_CUP_USMC_TOW2", 500],
    ["Flex_CUP_USMC_MK19_TriPod", 350]
];

// staticAA
F_SAM_List = [
    ["Flex_CUP_USMC_SAM_System", 35000],
    ["Flex_CUP_USMC_SAM_System_01", 35000],
    ["Flex_CUP_USMC_SAM_System_02", 35000],
    ["Flex_CUP_USMC_AAA_System_01", 35000],
    ["Flex_CUP_USMC_CRAM", 100000],
    ["Flex_CUP_USMC_Stinger_AA_pod", 3500],
    ["Flex_CUP_USMC_RAM_Launcher", 10000],
    ["Flex_CUP_USMC_SS_Launcher", 10000]
];

// Default squad compositions
F_ASSLT_ENG = [F_Assault_Eng, F_Assault_AT, F_Assault_Eod];

F_ASSLT_TEAM = [F_Assault_TL, F_Assault_Eod, F_Assault_AT, F_Assault_Mg, F_Assault_Mrk, F_Assault_Amm];

F_ASSLT_SQD = [F_Assault_SL, F_Assault_Eod, F_Assault_AT, F_Assault_Mg, F_Assault_Mrk, F_Assault_Amm, F_Assault_Med, F_Assault_ATM, F_Assault_MgH, F_Assault_GL, F_Assault_Uav];

F_SNP_TEAM = [F_Recon_Snp, F_Recon_Sct];

F_RCN_TEAM = [F_Recon_TL, F_Recon_AT, F_Recon_Mrk, F_Recon_Mg];

F_RCN_SQD = [F_Recon_TL, F_Recon_AT, F_Recon_Eod, F_Recon_Mg, F_Recon_Eng, F_Recon_Mrk];

F_DVR_TEAM = [F_Diver_TL, F_Diver_Eod, F_Diver_Rfl, F_Diver_Sct, F_Diver_Pt];

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
