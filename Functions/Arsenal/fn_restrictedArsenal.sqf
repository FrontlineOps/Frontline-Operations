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
    // AK Series
    "rhs_weap_ak74_2",
    "rhs_weap_ak74",
    "rhs_weap_aks74",
    "rhs_weap_aks74_2",
    "rhs_weap_aks74u",
    "rhs_weap_aks74_gp25",
    "rhs_weap_ak74_gp25",
    "rhs_weap_rpk74m",
    "rhs_weap_svdp",
    "rhs_weap_pkm",
    "rhs_weap_akm",
    "rhs_weap_akmn",
    "rhs_weap_akmn_gp25",
    "rhs_weap_akmn_gp25_npz",
    "rhs_weap_akmn_npz",
    "rhs_weap_ak74n_2_npz",
    "rhs_weap_ak74n_2_gp25",
    "NMG_weapons_aks74",
    "NMG_weapons_aks74gp",
    "NMG_weapons_aks74gp_wiwa",
    "NMG_weapons_aks74wiwa",
    "NMG_weapons_ak74n",
    "NMG_weapons_ak74rmo",
    "NMG_weapons_ak74rmo_gp",
    "NMG_weapons_ak74rmo_r",
    "NMG_weapons_RPKn",
    "NMG_weapons_RPK74M",
    "NMG_weapons_RPK74Mwiwa",
    "afou_weapons_km_762_plastik_2_F",
    "afou_weapons_km_762_wood_F",
    "afou_weapons_vulkan_545_m_F",
    "NMG_weapons_akHohTk",
    "Snipex_Alligator",
    // Pistols
    "rhs_weap_pb_6p9",
    "rhsusf_weap_glock17g4",
    "rhsusf_weap_m9",
    "rhsusf_weap_m1911a1",
    // Western Weapons
    "rhs_weap_m4a1_blockII_KAC_bk",
    "rhs_weap_mk18_KAC",
    "rhs_weap_mk18_eotech",
    "rhs_weap_mk18_SU230",
    "rhs_weap_mk18_KAC_m230",
    "rhs_weap_m4a1_blockII_KAC_SU230",
    "rhs_weap_m4a1_blockII_KAC_SU230_sup",
    "rhs_weap_m4a1_mstock_grip3",
    "rhs_weap_m4a1_grip3",
    "rhs_weap_m4_grip3",
    "rhs_m4_m203_compm4",
    "rhs_m4_compm4",
    "rhs_weap_sr25_sup_marsoc",
    "rhs_weap_m240b_elcan",
    "rhs_weap_m249_light_L_vfg2",
    // SOCOM/MARSOC Weapons
    "rhs_weap_mk17_CQC_grip2",
    "rhs_weap_mk18_eotech_sup",
    "rhs_weap_mk17_LB_DMR_marsoc",
    "rhs_weap_m4a1_blockII_M203_SU230",
    "rhs_weap_m4a1_blockII_M203_bk",
    "rhs_weap_M107_premier",
    "rhs_weap_SCARH_STD", 
    "rhs_weap_m4_carryhandle",
    "rhs_weap_m32_usmc",
    "rhs_weap_m40_d_usmc",
    "rhs_weap_smaw_gr_optic",
    // USMC Weapons
    "rhs_m4a1_m203_acog3_usmc_sup",
    "rhs_weap_m27iar_bipod_acog_usmc_sup",
    "rhs_m4a1_acog2_usmc_sup",
    "rhs_weap_m4a1_carryhandle_grip3",
    "rhs_weap_m249_pip_S_para_vfg3",
    "rhs_weap_m240b_usmc",
    "rhs_m4_m203_acog_usmc",
    "rhs_weap_m27iar_bipod_acog_usmc",
    "rhs_weap_m4_carryhandle_grip3",
    "rhs_weap_m16a4_acog_usmc",
    "rhs_weap_m16a4_carryhandle_grip2",
    "rhs_weap_m40_wd_usmc",
    "rhs_weap_sr25_usmc",
    // AK Variants
    "BRMC_LI_AK74MR_02",
    "BRMC_LI_AK74MR_03",
    "BRMC_LI_AK74MR_05"
];

private _launchers = [
    "rhs_weap_rpg18",
    "rhs_weap_rpg26",
    "rhs_weap_rpg7",
    "rhs_weap_igla",
    "rhs_weap_M136",
    "rhs_weap_fgm148",
    "rhs_weap_smaw_gr_optic",
    "ACE_launch_NLAW_ready_F"
];

private _attachments = [
    // Muzzle Devices
    "rhs_acc_dtk",
    "rhs_acc_dtk1983",
    "rhs_acc_dtkrpk",
    "rhs_acc_pgs64_74u",
    "rhs_acc_6p9_suppressor",
    "rhsusf_acc_SFMB556",
    "rhsusf_acc_SF3P556",
    "rhsusf_acc_nt4_black",
    "rhsusf_acc_aac_762sdn6_silencer",
    "rhsusf_acc_aac_scarh_silencer",
    "afou_glushnyk_pzrp_762_F",
    // Optics
    "rhs_acc_pso1m2",
    "rhs_acc_pgo7v3",
    "rhsusf_acc_nxs_3515x50f1_h58_sun",
    "rhsusf_acc_compm4",
    "rhsusf_acc_eotech_552",
    "rhsusf_acc_eotech_xps3",
    "rhsusf_acc_su230",
    "rhsusf_acc_su230_mrds_c",
    "rhsusf_acc_su230a_c",
    "rhsusf_acc_g33_xps3_tan",
    "rhsusf_acc_ACOG2",
    "rhsusf_acc_ELCAN",
    "rhsusf_acc_ELCAN_ard",
    "rhsusf_acc_premier",
    "rhsusf_acc_premier_low",
    "rhsusf_acc_M8541_mrds",
    "rhsusf_acc_M8541_low_d",
    "rhsusf_acc_ACOG3_USMC",
    "rhsusf_acc_ACOG2_USMC",
    "rhsusf_acc_ACOG_MDO",
    "rhsusf_acc_ACOG_USMC",
    "rhsusf_acc_M8541_low_wd",
    "rhs_weap_optic_smaw",
    "Leupold_Mk4",
    // Accessories
    "rhsusf_acc_anpeq15side_bk",
    "rhsusf_acc_anpeq15side",
    "rhsusf_acc_anpeq15",
    "rhsusf_acc_anpeq15_top",
    "rhsusf_acc_anpeq16a",
    "rhsusf_acc_anpeq16a_top",
    "rhsusf_acc_anpeq15_wmx_sc",
    // Grips and Bipods
    "rhsusf_acc_grip4_bipod",
    "rhsusf_acc_grip3",
    "rhsusf_acc_harris_bipod",
    "rhsusf_acc_harris_swivel",
    "rhsusf_acc_kac_grip",
    "rhsusf_acc_kac_grip_saw_bipod",
    "rhsusf_acc_rvg_blk",
    "rhsusf_acc_tdstubby_tan",
    "rhsusf_acc_tdstubby_blk",
    "afou_acc_rk_762_1_F",
    "afou_acc_flashlight_1_F",
    "afou_acc_tactical_grip_1_F"
];

// Uniforms, vests, and headgear
private _uniforms = [
    // GPU Series
    "MMM_GPU_MM14Winter_gl2_kn04_MM144top_MM145bot",
    "MMM_GPU_MM14Winter_gl2_kn04_MM145top_MM145bot",
    "MMM_GPU_MM14Winter_gl2_MM145top_MM144bot",
    "MMM_GPU_MM14Winter_gl2_MM145top_MM145bot",
    "MMM_GPU_MM14Winter_gl2_MM144top_MM144bot",
    "MMM_GPU_ACU_kn04_GL2_MM145top_MM145bot",
    "MMM_GPU_ACU_kn04_GL2_MM144top_MM145bot",
    "MMM_GPU_ACU_kn04_GL2_MM144top_MM144bot",
    "MMM_GPU_ACU_GL2_MM145top_MM145bot",
    
    // DShV Series
    "MMM_DShV_ACU_GL2_MM144top_MM145bot",
    "MMM_DShV_ACU_kn04_GL2_MM144top_MM144bot",
    "MMM_DShV_ACU_kn04_GL2_MM145top_MM145bot",
    "MMM_DShV_ACU_GL2_MM145top_MM145bot",
    "MMM_DShV_ACU_GL2_MM144top_MM144bot",
    "MMM_DShV_MM14Winter_gl2_kn04_MM145ptop_MM145bot",
    "MMM_DShV_MM14Winter_gl2_MM145top_MM145bot",
    "MMM_DShV_MM14Winter_gl2_kn04_MM145top_MM145bot",
    "MMM_DShV_MM14Winter_gl2_MM145top_MM144bot",
    
    // MVU Series
    "MMM_MVU_ACU_GL2_MM145top_MM144bot",
    "MMM_MVU_MM14Winter_gl2_MM145top_MM145bot",
    "MMM_MVU_MM14Winter_gl2_kn04_MM145top_MM145bot",
    "MMM_MVU_ACU_GL2_MM145top_MM145bot",
    "MMM_MVU_ACU_GL2_MM144top_MM144bot",
    "MMM_MVU_ACU_kn04_GL2_MM144top_MM144bot",
    "MMM_MVU_ACU_GL2_MM144top_MM145bot",
    "MMM_MVU_ACU_kn04_GL2_MM145top_MM145bot",
    "MMM_MVU_ACU_kn04_GL2_MM145top_MM144bot",
    
    // MPU Series
    "MMM_MPU_ACU_GL2_MM145top_MM145bot",
    "MMM_MPU_ACU_kn04_GL2_MM144top_MM144bot",
    "MMM_MPU_MM14Winter_gl2_MM145top_MM145bot",
    "MMM_MPU_MM14Winter_gl2_kn04_MM145top_MM145bot",
    
    // NGU Series
    "MMM_NGU_MM14Winter_gl2_kn04_NGUOlivetop_NGUOlivebot",
    "MMM_NGU_ACUMVS_kn04_GL2_NGUOlivetop_NGUOlivebot",
    "MMM_NGU_MM14Winter_gl2_NGUOlivetop_NGUOlivebot",
    
    // ILno Series
    "MMM_xILno_MM14Winter_gl2_alta_MultiCamCtop_MultiCamCbot",
    "MMM_xILno_MM14Winter_gl2_MultiCamCtop_MultiCamCbot",
    "MMM_xILno_MM14Winter_gl2_alta_MultiCamtop_MultiCambot",
    "MMM_x_ACUILno_GL2_OEFCPtop_OEFCPbot",
    
    // Other Uniforms
    "UA_Tactical_Jacket",
    "UA_fleece",
    "UA_fleece_tan",
    
    // Azov Uniforms
    "Azov_u_v7",
    "Azov_u_v8",
    "Azov_u_v9",
    "Azov_u_v10",
    "Azov_u_v11",
    "Azov_u_v12",
    "Azov_u_v13",
    "Azov_u_v19",
    "Dick_Azov_v1",
    "Dick_Azov_v2",
    "Dick_Azov_v3",
    "Dick_Azov_v4",
    "Dick_Azov_v5",
    "Dick_Azov_v6",
    "Dick_Azov_v8"
];

private _vests = [
    // TMC Series
    "MMM_TMC6094A_545_MultiCam_top06_front00_sides00_bot00_tape02",
    "MMM_TMC6094A_545_DarkGreen_top06_front01_sides00_bot00_tape02",
    "MMM_TMC6094A_545_MultiCam_top07_front01_sides00_bot00_tape02",
    "MMM_TMC6094A_545_MultiCam_top02_front01_sides00_bot00_tape02",
    "MMM_TMC6094A_545_MultiCam_top06_front01_sides00_bot00_tape02",
    "MMM_TMC6094A_545_MultiCamC_top06_front01_sides00_bot00_tape02",
    "MMM_TMC6094A_545_MultiCamC_top07_front01_sides00_bot00_tape02",
    "MMM_TMC6094A_545_DarkGreen_top04_front03_sides00_bot00_tape02",
    "MMM_TMC6094A_545_MM145_top06_front00_sides00_bot00_tape02",
    "MMM_TMC6094A_545_MM145_top06_front01_sides00_bot00_tape02",
    "MMM_TMC6094A_545_MM145_top07_front00_sides00_bot00_tape02",
    "MMM_TMC6094A_545_DarkGreen_top07_front01_sides00_bot00_tape02",
    "MMM_TMC6094A_545_DarkGreen_top04_front00_sides00_bot00_tape02",
    "MMM_TMC6094A_545_DarkGreen_top04_front01_sides00_bot00_tape02",
    "MMM_TMC6094A_545_MultiCamC_top06_front00_sides00_bot00_tape02",
    "MMM_TMC6094A_545_MultiCamC_top07_front00_sides00_bot00_tape02",
    "MMM_TMC6094A_545_MultiCamC_top04_front00_sides00_bot00_tape02",
    "MMM_TMC6094A_545_MultiCam_top04_front02_sides02_bot02_tape01",
    "MMM_TMC6094A_545_MultiCamC_top04_front02_sides02_bot02_tape01",
    "MMM_TMC6094A_545_MultiCam_top02_front02_sides02_bot02_tape01",
    "MMM_TMC6094A_545_MultiCamC_top04_front00_sides02_bot02_tape01",
    "MMM_TMC6094A_545_MultiCam_top04_front00_sides02_bot02_tape01",
    "MMM_TMC6094A_545_MultiCam_top04_front03_sides02_bot02_tape01",
    "MMM_TMC6094A_545_MultiCamC_top04_front03_sides02_bot02_tape01",
    "MMM_TMC6094A_545_MultiCamC_top06_front02_sides02_bot02_tape01",
    "MMM_TMC6094A_556_MultiCamC_top06_front01_sides02_bot00_tape01",
    
    // LBV Series
    "ua_lbv_mm14_st_tl",
    "ua_lbv_mm14_st_lmg_rpk",
    "ua_lbv_mm14_st_assault",
    "ua_lbv_mm14_st_mg",
    "ua_lbv_mm14_st_sniper",
    "ua_lbv_mm14_st_tl_rune",
    
    // Other Vests
    "UA_tactec",
    "ua_platecarrier_ak",
    "ua_platecarrier_ak2",
    "ua_platecarrier_ak3",
    "ua_platecarrier",
    "UA_AK_LBT",
    
    // Belts
    "UA_Warbelt_zsu",
    "UA_Warbelt_mc",
    "UA_Warbelt_ngu"
];

private _headgear = [
    // Kaska Series
    "ua_kaska_1m_cover_mm14_st",
    "ua_kaska_1m_cover_ggl_mm14_st",
    "MMM_UA_Kaska1M1_DarkGreen_ESS",
    "MMM_UA_Kaska1M1_DarkGreen",
    "MMM_UA_Kaska1M1_Black_TapeYellow",
    "MMM_UA_Kaska1M1_Black_ESS_TapeYellow",
    "MMM_UA_Kaska1M1_Black_ESS",
    "MMM_UA_Kaska1M1_Black",
    "MMM_UA_Kaska1M1_DarkGreen_ESS_TapeYellow",
    "MMM_UA_Kaska1M1_DarkGreen_TapeYellow",
    
    // Tor Series
    "MMM_UA_TorD_CMM143_ImpactSport_ESS_TapeNone",
    "MMM_UA_TorD_CMM145_TapeNone",
    "MMM_UA_TorD_CMM145_up_ESS_TapeYellow",
    "MMM_UA_TorD_CMM145_up_ESS_TapeNone",
    "MMM_UA_TorD_CMM143_up_TapeYellow",
    "MMM_UA_TorD_CMM143_up_ESS_TapeYellow",
    "MMM_UA_TorD_CMM143_up_ESS_TapeNone",
    "MMM_UA_TorD_CMM143_TapeNone",
    "MMM_UA_TorD_CMM143_TapeYellow",
    "MMM_UA_TorD_CMM143_ESS_TapeNone",
    "MMM_UA_TorD_CMM143_ImpactSport_up_ESS_TapeNone",
    
    // MultiCam Tor Series
    "MMM_UA_TorD_CMultiCam_up_TapeNone",
    "MMM_UA_TorD_CMultiCam_ImpactSport_up_TapeBlue",
    "MMM_UA_TorD_CMultiCam_up_ESS_TapeBlue",
    "MMM_UA_TorD_CMultiCam_ImpactSport_ESS_TapeNone",
    "MMM_UA_TorD_CMultiCam_TapeNone",
    "MMM_UA_TorD_CMultiCam_ImpactSport_ESS_TapeBlue",
    "MMM_UA_TorD_CMultiCam_ImpactSport_up_ESS_TapeBlue",
    "MMM_UA_TorD_CMultiCam_up_TapeBlue",
    "MMM_UA_TorD_CMultiCam_ESS_TapeNone",
    "MMM_UA_TorD_CMultiCam_ImpactSport_up_ESS_TapeNone",
    "MMM_UA_TorD_CMultiCam_ESS_TapeBlue",
    "MMM_UA_TorD_CMultiCam_TapeBlue",
    "MMM_UA_TorD_CMultiCam_ImpactSport_TapeBlue",
    
    // Azov Helmets
    "azov_helmet_2",
    "azov_helmet_3",
    "azov_helmet_4",
    "azov_helmet_5",
    "azov_helmet_6",
    "azov_helmet_7",
    "azov_helmet_8",
    "azov_helmet_10",
    "azov_helmet_11",
    "azov_helmet_14",
    
    // Facewear
    "UA_Scarf_Neck_b1",
    "UA_Balaclava2_1",
    "UA_Scarf_Neck_b2",
    "UA_Balaclava2_2",
    "UA_Balaclava2_3",
    "UA_ScarfMask_2",
    "UA_Balaclava_1",
    "UA_Balaclava_3",
    "UA_Balaclava_4",
    "UA_ScarfMask_1",
    "UA_Scarf_Neck_b3",
    
    // Other Headgear
    "ACE_EarPlugs",
    "UA_beanie_green",
    "UA_Beanie_Cpt_v2",
    "UA_exfil",
    "UA_Perun",
    "UA_MaWka_Puf",
    "UA_GY_MAWKA_tan"
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
    "ItemAndroid",
    "rhs_tr8_periscope",
    "VTN_LPR1",
    "VTN_B8"
];

private _navigationItems = [
    "ItemMap",
    "ItemCompass",
    "ItemWatch",
    "ItemGPS",
    "MMM_MotoDP4400",
    "rhsusf_bino_leopold_mk4",
    "rhsusf_bino_lerca_1200_black",
    "rhsusf_bino_lerca_1200_tan",
    "TFAR_ASELSAN4700",
    "TFAR_aselsan9661_sage",
    "TFAR_ASELSAN9651",
    "MMM_BaoUV5R",
    "MMM_R148_bp",
    "Binocular",
    "VTN_LPR1",
    "VTN_LPR2",
    "VTN_M22",
    "ACE_MX2A",
    "VTN_B15",
    "VTN_BN1",
    "VTN_BN3",
    "VTN_B8",
    "ace_flags_blue",
    "ace_flags_red",
    "ace_flags_green",
    "ace_flags_yellow",
    "ace_flags_white",
    "ace_flags_black",
    "ace_flags_orange",
    "ace_flags_purple",
    "ACE_MicroDAGR",
    "ACE_PlottingBoard",
    "ACE_RangeCard",
    "ACE_SpottingScope",
    "ACE_Tripod",
    "ACE_MapTools",
    "ACE_Kestrel4500",
    "ACE_artilleryTable",
    "ACE_RangeTable_82mm",
    "ACE_IR_Strobe_Item",
    "ACE_ATragMX",
    "ACE_Vector"
];

private _backpacks = [
    "RUS_rpg_bag",
    "rhs_rpg_2",
    "MMM_PRC119_Mixed",
    "MMM_PRC119_Blade_Fld",
    "MMM_PRC119_Whip_Ret",
    "ua_back_pack_mm14_st",
    "ua_lbt_1476a_mm14_st",
    "ua_lbt_1476a_cg_nr_mm14_st",
    "ua_lbt_1476a_cg_mm14_st",
    "ua_light_back_pack_cg_nr_mm14_st",
    "ua_light_back_pack_cg_mm14_st",
    "ua_light_back_pack_mm14_st",
    "FARA_PV_RUCK"
];

// Magazines and throwables
private _magazines = [
    // Rifle Magazines
    "rhs_30Rnd_545x39_7N6M_plum_AK",
    "rhs_30Rnd_545x39_AK_plum_green",
    "rhs_45Rnd_545X39_7N6M_AK",
    "rhs_100Rnd_762x54mmR",
    "rhs_10Rnd_762x54mmR_7N1",
    "rhs_45Rnd_545X39_AK_Green",
    "rhs_100Rnd_762x54mmR_green",
    "rhs_mag_30Rnd_556x45_M855_PMAG",
    "rhs_mag_30Rnd_556x45_M855A1_Stanag",
    "rhs_mag_30Rnd_556x45_M855A1_Stanag_Pull",
    "rhs_mag_30Rnd_556x45_Mk318_Stanag",
    "rhs_mag_30Rnd_556x45_M855_Stanag",
    "rhs_mag_30Rnd_556x45_M855_Stanag_Tracer_Red",
    "rhsusf_50Rnd_762x51",
    "rhsusf_100Rnd_556x45_soft_pouch",
    "rhsusf_100Rnd_556x45_M855_soft_pouch",
    "rhsusf_200Rnd_556x45_mixed_soft_pouch_ucp",
    "rhsusf_20Rnd_762x51_SR25_m118_special_Mag",
    "rhsusf_10Rnd_762x51_m118_special_Mag",
    "rhsusf_mag_10Rnd_STD_50BMG_M33",
    "rhs_mag_20Rnd_SCAR_762x51_m80a1_epr",
    "rhs_mag_20Rnd_SCAR_762x51_m118_special",
    "rhs_mag_20Rnd_SCAR_762x51_m80_ball_bk",
    "SNIPEX_5rnd_Ball",
    "rhs_mag_9x18_8_57N181S",
    "rhsusf_mag_17Rnd_9x19_JHP",
    "rhsusf_mag_17Rnd_9x19_FMJ",
    "rhsusf_mag_15Rnd_9x19_FMJ",
    "rhsusf_mag_7x45acp_MHP",
    
    // Launcher Magazines
    "rhs_rpg18_mag",
    "rhs_rpg26_mag",
    "rhs_rpg7_PG7VM_mag",
    "rhs_rpg7_TBG7V_mag",
    "rhs_rpg7_PG7VR_mag",
    "rhs_mag_9k38_rocket",
    "NLAW_F",
    "rhs_m136_mag",
    "rhs_fgm148_magazine_AT",
    "rhs_mag_smaw_HEDP",
    "rhs_mag_smaw_SR",
    
    // UGL and Special Ammo
    "rhs_VOG25",
    "rhs_VOG25p",
    "rhs_VOG40MD",
    "rhs_VOG40OP_green",
    "rhs_VOG40OP_red",
    "rhs_VOG40OP_white",
    "rhs_VOG40SZ",
    "rhs_VOG40TB",
    "rhs_GDM40",
    "rhs_GDM40_white",
    "rhs_GDM40_green",
    "rhs_GDM40_red",
    "rhs_mag_M433_HEDP",
    "rhs_mag_M441_HE",
    "rhs_mag_M583A1_white",
    "rhsusf_mag_6Rnd_M433_HEDP",
    "rhsusf_mag_6Rnd_M714_white",
    
    // Explosive Magazines
    "rhs_mine_ozm72_b_mag",
    "rhs_mine_pmn2_mag",
    "rhsusf_m112x4_mag",
    "rhsusf_m112_mag",
    
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
    "rhs_mag_rdg2_white",
    "rhs_mag_f1",
    "rhs_mag_rgd5",
    "rhs_mag_rgo",
    "rhs_mag_mk84",
    "rhs_mag_mk3a2",
    "rhs_mag_m67",
    "rhs_mag_an_m8hc",
    "rhs_mag_an_m14_th3",
    "rhs_mag_m18_purple",
    "rhs_mag_m18_yellow",
    "rhs_mag_m18_red",
    "rhs_mag_m18_green",
    "B_IR_Grenade",
    "I_IR_Grenade",
    "MiniGrenade",
    "SmokeShell",
    "SmokeShellGreen",
    "SmokeShellRed",
    "SmokeShellBlue",
    "SmokeShellOrange",
    "SmokeShellYellow",
    "ACE_M84",
    "ACE_CTS9",
    "ACE_M14",
    "KAT_M7A3",
    "Chemlight_green",
    "Chemlight_red",
    "ACE_Chemlight_HiRed",
    "ACE_Chemlight_HiGreen",
    "ACE_40mm_Flare_white",
    "ACE_40mm_Flare_red",
    "ACE_40mm_Flare_green",
    "ACE_40mm_Flare_ir",
    "afou_mag_gd01_white",
    "afou_mag_gd01_orange"
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