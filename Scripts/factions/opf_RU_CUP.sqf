// ============================================================================
// RUSSIAN AF WOODLAND FACTION - OPFOR (RHS Mod)
// Russian VDV forces in flora camouflage
// ============================================================================

/*
 * HOW THIS FILE FEEDS THE COMMANDER / VIRTUALIZATION
 *
 * You only edit the faction data in this file. Phase 2 builds the runtime pools
 * from these sections automatically:
 *
 *   groundInfantry   = East_Ground_Infantry
 *   groundSpecOps    = East_Ground_SpecOps
 *   groundMotorized  = East_Ground_Motorized
 *   groundMechanized = East_Ground_Mechanized
 *   groundArmor      = East_Ground_Armor
 *   groundTransport  = East_Ground_Transport
 *   transportReserveGroundCount = East_Transport_Reserve_Ground_Count
 *   groundArtillery  = East_Ground_Artillery
 *   airTransport     = East_Air_Transport
 *   transportReserveAirCount = East_Transport_Reserve_Air_Count
 *   airHeli          = East_Air_Heli
 *   airJet           = East_Air_Jet
 *   airDrone         = East_Air_Drone
 *   mobileAA         = East_Mobile_AA
 *   staticAA         = East_Static_AA
 *   radar            = East_Radar
 *
 * If you want to change what the commander can spawn, change the source data
 * that feeds the category above.
 */
// ============================================================================
// INFANTRY
// ============================================================================
// Mixed infantry source for groundInfantry.
// Entries may be full CfgGroups configs or individual unit classnames.
East_Ground_Infantry = [
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_RUS_M" >> "Infantry_VKPO_Winter" >> "InfTeam"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_RUS_M" >> "Infantry_VKPO_Winter" >> "InfTeam_AT"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_RUS_M" >> "Infantry_VKPO_Winter" >> "O_InfTeam_AT_Heavy"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_RUS_M" >> "Infantry_VKPO_Winter" >> "InfTeam_AA"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_RUS_M" >> "Infantry_VKPO_Winter" >> "InfSentry"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_RUS_M" >> "Infantry_VKPO_Winter" >> "InfSquad"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_RUS_M" >> "Infantry_VKPO_Winter" >> "InfSquad_Weapons"),
    (configfile >> "CfgGroups" >> "East" >> "CUP_O_RUS_M" >> "Infantry_VKPO_Winter" >> "InfAssault"),
    "CUP_O_RUS_M_Soldier_VKPO_Winter", "CUP_O_RUS_M_Soldier_VKPO_Winter", "CUP_O_RUS_M_Soldier_VKPO_Winter",
    "CUP_O_RUS_M_Soldier_AR_VKPO_Winter", "CUP_O_RUS_M_Soldier_AR_VKPO_Winter",
    "CUP_O_RUS_M_Soldier_GL_VKPO_Winter", "CUP_O_RUS_M_Soldier_GL_VKPO_Winter",
    "CUP_O_RUS_M_Soldier_MG_VKPO_Winter", "CUP_O_RUS_M_Soldier_MG_VKPO_Winter",
    "CUP_O_RUS_M_Soldier_Marksman_VKPO_Winter",
    "CUP_O_RUS_M_Recon_Sharpshooter_Gorka_EMR",
    "CUP_O_RUS_M_Soldier_AT_VKPO_Winter",
    "CUP_O_RUS_M_Soldier_Exp_VKPO_Winter",
    "CUP_O_RUS_M_Soldier_Engineer_VKPO_Winter",
    "CUP_O_RUS_M_Soldier_Lite_VKPO_Winter"
];
// groundSpecOps
East_Ground_SpecOps = [];

// Fire observer pool for artillery support logic.
East_FireObserver = ["CUP_O_RUS_M_Soldier_SL_VKPO_Winter"];

// ============================================================================
// VEHICLE ARRAYS
// ============================================================================
// groundMotorized
East_Ground_Motorized = [
    "CUP_O_Tigr_233011_GREEN_RU", "CUP_O_Tigr_233014_GREEN_RU",
    "CUP_O_Tigr_233014_GREEN_PK_RU", "CUP_O_Tigr_M_233114_GREEN_RU", "CUP_O_Tigr_M_233114_GREEN_KORD_RU",
    "CUP_O_Tigr_M_233114_KORD_RU", "CUP_O_Tigr_M_233114_RU", "CUP_O_Tigr_M_233114_GREEN_PK_RU",
    "CUP_O_Tigr_M_233114_PK_RU", "CUP_O_UAZ_Unarmed_RU", "CUP_O_UAZ_MG_RU", "CUP_O_UAZ_AGS30_RU", "CUP_O_UAZ_SPG9_RU", "CUP_O_UAZ_AA_RU",
    "CUP_O_UAZ_METIS_RU", "CUP_O_BRDM2_HQ_RUS",
    "CUP_O_GAZ_Vodnik_Unarmed_RU", "CUP_O_GAZ_Vodnik_PK_RU", "CUP_O_GAZ_Vodnik_AGS_RU", "CUP_O_GAZ_Vodnik_BPPU_RU",
    "CUP_O_GAZ_Vodnik_KPVT_RU", "CUP_O_GAZ_Vodnik_MedEvac_RU", "CUP_O_Ural_ZU23_RU"
];

// groundMechanized
East_Ground_Mechanized = [
    "CUP_O_MTLB_pk_WDL_RU", "CUP_O_MTLB_pk_Green_RU", "CUP_O_BMP2_RU", "CUP_O_BMP_HQ_RU", "CUP_O_BTR60_Green_RU", "CUP_O_BTR60_RU", "CUP_O_BTR80_CAMO_RU", "CUP_O_BTR80_GREEN_RU",
    "CUP_O_BTR80A_CAMO_RU", "CUP_O_BTR80A_GREEN_RU", "CUP_O_BTR90_RU", "CUP_O_BTR90_HQ_RU",
    "CUP_O_BMP3_RU", "CUP_O_BRDM2_RUS", "CUP_O_BRDM2_ATGM_RUS"
];
// groundArmor
East_Ground_Armor = [
    "CUP_O_T72_RU", "CUP_O_T90_RU",
    "CUP_O_T90M_RU", "CUP_O_T90M_CAMO_RU"
];

// groundTransport
East_Ground_Transport = [
    "CUP_O_Tigr_233011_GREEN_RU", "CUP_O_Tigr_233011_RU", "CUP_O_Kamaz_6396_covered_RUS_M",
    "O_Truck_02_transport_F", "CUP_O_GAZ_Vodnik_Unarmed_RU"
];
East_Transport_Reserve_Ground_Count = 20;

// groundArtillery
East_Ground_Artillery = ["O_MBT_02_arty_F", "CUP_O_BM21_RU"];

// airTransport
East_Air_Transport = [
    "CUP_O_Mi8AMT_RU", "CUP_O_Mi8_RU",
    "CUP_O_MI6T_RU"
];
East_Transport_Reserve_Air_Count = 10;

// airHeli
East_Air_Heli = [
    "CUP_O_Ka50_DL_RU", "CUP_O_Ka52_RU", "CUP_O_Ka60_Grey_RU", "CUP_O_Mi24_P_Dynamic_RU",
    "CUP_O_Mi24_V_Dynamic_RU"
];

// airJet
East_Air_Jet = ["CUP_O_SU34_RU", "CUP_O_Su25_Dyn_RU"];

// airDrone
East_Air_Drone = ["O_UAV_01_F", "CUP_O_Pchela1T_RU"];

// mobileAA
East_Mobile_AA = ["CUP_O_2S6M_RU"];

// staticAA
East_Static_AA = ["O_SAM_System_04_F"];

// radar
East_Radar = ["O_Radar_System_02_F"];

// ============================================================================
// GARRISON CONFIGURATION
// ============================================================================
OPFOR_Objective_Groups = [
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
 *   East_Objective_Group_Type_Caps = [["artillery", 5], ["jet", 3]]
 * These caps apply across all owned seeded objectives combined.
 */
East_Objective_Group_Type_Caps = [
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
OPFOR_Group_Counts = [
    ["infantry", 10],          // Number of individual soldiers
    ["motorized", 1],         // Number of armed vehicles (MRAP, GMG, etc.)
    ["mechanized", 1],        // Number of APCs/IFVs
    ["armor", 1],             // Number of tanks
    ["helicopter", 1],        // Number of helicopters
    ["jet", 1],               // Number of jets
    ["air", 1],               // Number of aircraft
    ["artillery", 3],         // Number of artillery pieces
    ["mobile_aa", 1],         // Number of mobile AA vehicles
    ["static_aa", 1]          // Number of static SAM launchers
];