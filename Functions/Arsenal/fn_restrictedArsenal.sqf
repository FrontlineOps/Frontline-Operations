/*
    Function: FLO_fnc_restrictedArsenal
    
    Description: Sets up global arsenal restrictions that apply to any arsenal opened in the mission
                Handles both ACE and vanilla arsenals, including FOBs and OPs
    
    Parameter(s):
        None
        
    Returns:
        None
*/

if (isNil "FLO_arsenal_initialized") then {
    FLO_arsenal_initialized = false;
};

if (FLO_arsenal_initialized) exitWith {};

// Check if ACE Arsenal is available
FLO_hasAceArsenal = isClass (configFile >> "ace_arsenal_loadoutsDisplay");

// Weapons and attachments
private _rifles = [
    // Basic MX Series
    "arifle_MX_F",
    "arifle_MXC_F",
    "arifle_MX_GL_F",
    "arifle_MX_SW_F",
    "arifle_MXM_F",
    // MX Variants
    "arifle_MX_ACO_pointer_F",
    "arifle_MXC_ACO_pointer_F",
    "arifle_MXC_Holo_F",
    "arifle_MXC_Holo_pointer_F",
    "arifle_MX_GL_ACO_pointer_F",
    "arifle_MX_Holo_pointer_F",
    "arifle_MX_SW_Hamr_pointer_F",
    "arifle_MX_Hamr_pointer_F",
    "arifle_MXM_MOS_LP_BI_F",
    // SPAR Series
    "arifle_SPAR_01_snd_RCO_Pointer_Snds_F",
    "arifle_SPAR_01_snd_Holo_Pointer_Snds_F",
    "arifle_SPAR_01_GL_snd_RCO_Pointer_Snds_F",
    "arifle_SPAR_02_snd_RCO_Pointer_Snds_Bipod_F",
    // Other Weapons
    "sgun_KSG_ACO_F",
    "srifle_DMR_03_tan_AMS_LP_F",
    "srifle_LRR_camo_LRPS_F",
    "SMG_01_Holo_F",
    "SMG_01_black_Holo_F",
    "LMG_Mk200_plain_RCO_LP_F",
    "LMG_Mk200_plain_RCO_LP_S_F",
    "MMG_02_sand_RCO_LP_F",
    "hgun_P07_F",
    "hgun_P07_snds_F",
    "hgun_Pistol_heavy_01_MRD_F",
    "Aegis_MMG_FNMAG_240_F",
    "arifle_SCAR_black_F",
    "Aegis_arifle_SR25_MR_blk_F",
    "Aegis_arifle_SR25_MR_snd_F"
];

private _launchers = [
    "launch_B_Titan_F",
    "launch_B_Titan_short_F",
    "launch_MRAWS_sand_F",
    "ACE_launch_NLAW_ready_F"
];

private _attachments = [
    // Optics
    "optic_Hamr",
    "optic_Aco",
    "optic_Aco_smg",
    "optic_Holosight",
    "optic_Holosight_smg",
    "optic_Holosight_smg_blk_F",
    "optic_SOS",
    "optic_LRPS",
    "optic_AMS_snd",
    "optic_AMS",
    "optic_DMS",
    "optic_MRD",
    "optic_Arco",
    "optic_NVS",
    "optic_tws_mg",
    // Accessories
    "acc_flashlight",
    "acc_pointer_IR",
    // Muzzles
    "muzzle_snds_H_snd_F",
    "muzzle_snds_338_sand",
    "muzzle_snds_B",
    "muzzle_snds_L",
    "muzzle_snds_m_snd_F",
    "muzzle_snds_acp",
    // Bipods
    "bipod_01_F_snd",
    "bipod_01_F_blk"
];

// Uniforms, vests, and headgear
private _uniforms = [
    "U_B_CombatUniform_mcam",
    "U_B_CombatUniform_mcam_tshirt",
    "U_B_CombatUniform_mcam_vest",
    "U_B_CBRN_Suit_01_MTP_F",
    "U_B_PilotCoveralls",
    "U_B_HeliPilotCoveralls",
    "U_B_GhillieSuit"
];

private _vests = [
    "V_PlateCarrier1_rgr",
    "V_PlateCarrier2_rgr",
    "V_PlateCarrierGL_rgr",
    "V_PlateCarrier1_mtp",
    "V_PlateCarrier2_mtp",
    "V_PlateCarrierGL_mtp",
    "V_PlateCarrierSpec_rgr",
    "V_ChestrigF_rgr",
    "V_Chestrig_rgr",
    "V_TacVest_blk",
    "V_Rangemaster_belt",
    "V_BandollierB_rgr"
];

private _headgear = [
    "H_HelmetB",
    "H_HelmetB_light",
    "H_HelmetSpecB",
    "H_HelmetB_sand",
    "H_HelmetB_light_sand",
    "H_HelmetSpecB_sand",
    "H_HelmetB_plain_mcamo",
    "H_HelmetB_camo_mcamo",
    "H_HelmetSpecB_mcamo",
    "H_HelmetB_light_desert",
    "H_HelmetB_light_grass",
    "H_HelmetB_light_snakeskin",
    "H_HelmetSpecB_light",
    "H_HelmetSpecB_light_desert",
    "H_HelmetSpecB_light_snakeskin",
    "H_HelmetSpecB_paint1",
    "H_HelmetSpecB_paint2",
    "H_PilotHelmetFighter_B",
    "H_PilotHelmetHeli_B",
    "H_CrewHelmetHeli_B",
    "H_MilCap_mcamo",
    "H_Booniehat_mcamo_hs",
    "ACE_EHP",
    "ACE_EarPlugs"
];

// Equipment and items
private _medicalItems = [
    "kat_AFAK",
    "kat_IFAK",
    "kat_MFAK",
    "ace_personalAidKit",
    "ace_surgicalKit"
];

private _toolItems = [
    "ACE_CableTie",
    "ACE_EntrenchingTool",
    "ACE_Flashlight_XL50",
    "ACE_MapTools",
    "ACE_wirecutter",
    "ACE_DefusalKit",
    "ACE_Clacker",
    "ToolKit",
    "MineDetector",
    "ChemicalDetector_01_watch_F",
    "ACE_IR_Strobe_Item",
    "B_UavTerminal",
    "ItemcTab",
    "ItemAndroid"
];

private _navigationItems = [
    "ItemMap",
    "ItemCompass",
    "ItemWatch",
    "ItemRadio",
    "ItemGPS",
    "ACE_NVG_Gen4",
    "ACE_NVG_Gen4_WP",
    "Binocular",
    "Rangefinder",
    "Laserdesignator",
    "TFAR_anprc152",
    "ACE_MX2A",
    "ACE_Vector"
];

private _backpacks = [
    "B_AssaultPack_mcamo",
    "B_Kitbag_mcamo",
    "B_TacticalPack_mcamo",
    "B_Carryall_mcamo",
    "B_Carryall_mcamo_AAA",
    "B_Carryall_mcamo_AAT",
    "B_Carryall_mcamo_Mine",
    "B_AssaultPack_rgr_Medic",
    "B_AssaultPack_rgr_Repair",
    "B_AssaultPack_rgr_LAT",
    "B_AssaultPack_rgr_LAT2",
    "B_AssaultPack_mcamo_AA",
    "B_AssaultPack_mcamo_AT",
    "B_Kitbag_rgr_AAR",
    "B_Kitbag_mcamo_Eng",
    "B_Kitbag_rgr_Exp",
    "B_RadioBag_01_mtp_F",
    "B_Parachute",
    "B_UAV_01_backpack_F",
    "B_UAV_06_backpack_F",
    "B_UAV_02_backpack_lxWS",
    "B_UGV_02_Demining_backpack_F",
    "B_CombinationUnitRespirator_01_F",
    "B_Patrol_Medic_bag_F",
    "B_Patrol_Supply_bag_F",
    "B_Patrol_Respawn_bag_F",
    "tfw_ilbe_whip_mc"
];

// Magazines and throwables
private _magazines = [
    // Rifle Magazines
    "30Rnd_65x39_caseless_mag",
    "30Rnd_65x39_caseless_mag_Tracer",
    "100Rnd_65x39_caseless_mag",
    "100Rnd_65x39_caseless_mag_Tracer",
    "150Rnd_762x54_Box",
    "200Rnd_65x39_cased_Box",
    "200Rnd_65x39_cased_Box_Red",
    "200Rnd_65x39_cased_Box_Tracer",
    "20Rnd_762x51_Mag",
    "7Rnd_408_Mag",
    "30Rnd_45ACP_Mag_SMG_01",
    "16Rnd_9x21_Mag",
    "11Rnd_45ACP_Mag",
    "8Rnd_12Gauge_Pellets",
    "8Rnd_12Gauge_Slug",
    "130Rnd_338_Mag",
    "150Rnd_556x45_Drum_Sand_Mag_F",
    "30Rnd_556x45_Stanag_Sand_red",
    "30Rnd_556x45_Stanag_Sand_Tracer_Red",
    "Aegis_20Rnd_762x51_SMAG",
    "Aegis_20Rnd_762x51_Green_SMAG",
    "Aegis_20Rnd_762x51_Red_SMAG",
    "Aegis_20Rnd_762x51_Yellow_SMAG",
    "Aegis_200Rnd_762x51_MAG_Red_F",
    "Aegis_200Rnd_762x51_MAG_Red_Tracer_F",
    "20Rnd_762x51_Mag",
    // Launcher Magazines
    "Titan_AA",
    "Titan_AT",
    "Titan_AP",
    "NLAW_F",
    "MRAWS_HEAT_F",
    "MRAWS_HE_F",
    // Explosives
    "SatchelCharge_Remote_Mag",
    "DemoCharge_Remote_Mag",
    "APERSMine_Range_Mag",
    "APERSBoundingMine_Range_Mag",
    "ClaymoreDirectionalMine_Remote_Mag",
    "SLAMDirectionalMine_Wire_Mag",
    "APERSMineDispenser_Mag",
    "APERSTripMine_Wire_Mag",
    "Laserbatteries"
];

private _grenades = [
    "HandGrenade",
    "MiniGrenade",
    "SmokeShell",
    "SmokeShellGreen",
    "SmokeShellRed",
    "SmokeShellBlue",
    "SmokeShellOrange",
    "SmokeShellYellow",
    "B_IR_Grenade",
    "1Rnd_HE_Grenade_shell",
    "3Rnd_HE_Grenade_shell",
    "1Rnd_Smoke_Grenade_shell",
    "1Rnd_SmokeBlue_Grenade_shell",
    "1Rnd_SmokeGreen_Grenade_shell",
    "1Rnd_SmokeOrange_Grenade_shell",
    "ACE_40mm_Flare_white",
    "ACE_40mm_Flare_red",
    "ACE_40mm_Flare_green",
    "ACE_40mm_Flare_ir",
    "ACE_M84",
    "ACE_CTS9",
    "ACE_M14",
    "KAT_M7A3",
    "Chemlight_green",
    "ACE_Chemlight_HiRed",
    "ACE_Chemlight_HiGreen"
];

// Create global arrays for each category
FLO_arsenal_allowedItems = [];
FLO_arsenal_allowedItems append _rifles;
FLO_arsenal_allowedItems append _launchers;
FLO_arsenal_allowedItems append _attachments;
FLO_arsenal_allowedItems append _uniforms;
FLO_arsenal_allowedItems append _vests;
FLO_arsenal_allowedItems append _headgear;
FLO_arsenal_allowedItems append _navigationItems;
FLO_arsenal_allowedItems append _backpacks;
FLO_arsenal_allowedItems append _magazines;
FLO_arsenal_allowedItems append _grenades;
FLO_arsenal_allowedItems append _medicalItems;
FLO_arsenal_allowedItems append _toolItems;

// Function to restrict an arsenal box
FLO_fnc_restrictArsenalBox = {
    params ["_box"];
    
    if (FLO_hasAceArsenal) then {
        // Initialize ACE Arsenal first (this is key for FOBs/OPs)
        [_box, true] remoteExec ["ace_arsenal_fnc_initBox", 0];
        
        // Wait a frame to ensure initialization is complete
        [{
            params ["_box"];
            // Clear everything first
            [_box, true] call ace_arsenal_fnc_removeVirtualItems;
            // Add only our allowed items
            [_box, FLO_arsenal_allowedItems] call ace_arsenal_fnc_addVirtualItems;
        }, [_box], 0.1] call CBA_fnc_waitAndExecute;
    } else {
        // Clear and set up vanilla arsenal
        ["AmmoboxInit", [_box, false]] call BIS_fnc_arsenal;
        
        // Split items by type for vanilla arsenal
        private _weapons = FLO_arsenal_allowedItems select {_x isKindOf ["Rifle", configFile >> "CfgWeapons"] || 
                                                         _x isKindOf ["Launcher", configFile >> "CfgWeapons"] ||
                                                         _x isKindOf ["Pistol", configFile >> "CfgWeapons"]};
        private _items = FLO_arsenal_allowedItems select {_x isKindOf ["ItemCore", configFile >> "CfgWeapons"] ||
                                                        _x isKindOf ["Equipment", configFile >> "CfgWeapons"] ||
                                                        _x isKindOf ["Uniform_Base", configFile >> "CfgWeapons"] ||
                                                        _x isKindOf ["VestItem", configFile >> "CfgWeapons"] ||
                                                        _x isKindOf ["HeadgearItem", configFile >> "CfgWeapons"]};
        private _magazines = FLO_arsenal_allowedItems select {_x isKindOf ["CA_Magazine", configFile >> "CfgMagazines"]};
        private _backpacks = FLO_arsenal_allowedItems select {_x isKindOf ["Bag_Base", configFile >> "CfgVehicles"]};
        
        [_box, _weapons] call BIS_fnc_addVirtualWeaponCargo;
        [_box, _items] call BIS_fnc_addVirtualItemCargo;
        [_box, _magazines] call BIS_fnc_addVirtualMagazineCargo;
        [_box, _backpacks] call BIS_fnc_addVirtualBackpackCargo;
    };
};

// Add event handlers based on which arsenal system is available
if (FLO_hasAceArsenal) then {
    // ACE Arsenal event handler
    ["ace_arsenal_displayOpened", {
        params ["_display"];
        private _box = ace_arsenal_currentBox;
        [_box] call FLO_fnc_restrictArsenalBox;
    }] call CBA_fnc_addEventHandler;
} else {
    // Vanilla Arsenal event handler
    ["arsenalOpened", {
        params ["_display", "_box"];
        [_box] call FLO_fnc_restrictArsenalBox;
    }] call CBA_fnc_addEventHandler;
};

// Add event handler for object initialization to catch FOBs and OPs
addMissionEventHandler ["EntityCreated", {
    params ["_entity"];
    
    // Check if it's a FOB or OP
    if ((typeOf _entity) in [F_HQ_01, F_OP_01]) then {
        // Wait a frame to let the object initialize
        [{
            params ["_box"];
            [_box] call FLO_fnc_restrictArsenalBox;
        }, [_entity], 0.1] call CBA_fnc_waitAndExecute;
    };
}];

// Initialize restrictions on any existing FOBs/OPs
{
    if ((typeOf _x) in [F_HQ_01, F_OP_01]) then {
        [_x] call FLO_fnc_restrictArsenalBox;
    };
} forEach (entities "All");

// Mark as initialized to prevent multiple executions
FLO_arsenal_initialized = true; 