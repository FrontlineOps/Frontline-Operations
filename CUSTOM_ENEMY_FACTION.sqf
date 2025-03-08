// Where are Classnames ? Right click on any Unit or Vehicle in the Editor and Select find in CFG viewer, Last Name in the [path] tab is the Classname,

/*

East_Ground_Vehicles_Ambient = ["Opf_I_I_Offroad_01_F",  "Opf_I_I_Van_01_transport_F", "Opf_I_I_Offroad_01_F", "Opf_O_S_Offroad_01_armed_F", "Opf_O_S_Offroad_01_armed_F", "Opf_O_S_Offroad_01_AT_F"]; 
East_Ground_Vehicles_Light = ["Opf_O_S_Offroad_01_armed_F", "Opf_O_S_Offroad_01_armed_F", "Opf_O_S_APC_Tracked_02_cannon_F", "Opf_O_S_Offroad_01_AT_F"]; 
East_Ground_Vehicles_Heavy = ["Opf_O_S_APC_Tracked_02_cannon_F","Opf_O_S_APC_Tracked_02_cannon_F", "Opf_O_S_Offroad_01_AT_F", "Opf_O_S_Offroad_01_AT_F", "Opf_O_S_Offroad_01_armed_F"]; 
East_Ground_Transport = ["Opf_O_S_Offroad_01_F",  "Opf_O_S_Truck_02_transport_F"]; 

East_Air_Transport = ["Opf_I_R_Heli_Light_02_unarmed_F"];
East_Air_Heli = ["O_Heli_Light_02_dynamicLoadout_F"]; 
East_Air_Jet = ["O_Heli_Light_02_dynamicLoadout_F"]; 

East_Units = ["Opf_O_S_Soldier_9_F","Opf_O_S_Soldier_8_F","Opf_O_S_Soldier_7_F","Opf_O_S_Soldier_6_F","Opf_O_S_Soldier_5_F","Opf_O_S_Soldier_4_F","Opf_O_S_Soldier_3_F","Opf_O_S_Soldier_2_F","Opf_O_S_Soldier_1_F", "Opf_O_P_soldier_TL_F", "Opf_O_P_soldier_1_F", "Opf_O_P_soldier_LAT_F", "Opf_O_P_soldier_M_F", "Opf_O_P_soldier_GL_F", "Opf_O_P_soldier_AR_F", "Opf_O_P_soldier_exp_F", "Opf_O_P_medic_F"];
East_Units_Officers = ["Opf_O_S_Soldier_2_F"];

East_Groups = [
(configfile >> "CfgGroups" >> "East" >> "Opf_OPF_S_F" >> "Infantry" >> "SeparatistShockTeam"),
(configfile >> "CfgGroups" >> "East" >> "Opf_OPF_S_F" >> "Infantry" >> "SeparatistFireTeam"),
(configfile >> "CfgGroups" >> "East" >> "Opf_OPF_S_F" >> "Infantry" >> "SeparatistCombatGroup")
];

*/

// Fill the Lines with your Desired Classnames in the Manners Shown Above,
// Where are Classnames ? Right click on any Unit or Vehicle in the Editor and Select find in CFG viewer, Last Name in the [path] tab is the Classname,

East_Ground_Vehicles_Ambient = ["I_MRAP_03_F"]; 
//publicVariable "East_Ground_Vehicles_Ambient";

East_Ground_Vehicles_Light = ["I_MRAP_03_F", "I_MRAP_03_gmg_F", "I_MRAP_03_hmg_F", "I_A_Truck_02_aa_lxWS", "I_APC_Wheeled_03_cannon_F", "Aegis_I_Raven_APC_Wheeled_04_export_F", "I_Raven_MRAP_02_HMG_F", "I_Raven_MRAP_02_GMG_F"]; 
//publicVariable "East_Ground_Vehicles_Light";

East_Ground_Vehicles_Heavy = ["I_MBT_03_cannon_F", "I_LT_01_cannon_F", "I_LT_01_AT_F", "I_LT_01_AA_F", "I_APC_tracked_03_cannon_v2_F"]; 
//publicVariable "East_Ground_Vehicles_Heavy";

East_Ground_Transport = ["I_MRAP_03_F", "I_Truck_02_transport_F", "I_Truck_02_covered_F", "Aegis_I_Raven_Truck_02_F"]; 
//publicVariable "East_Ground_Transport";

East_Air_Transport = ["I_Heli_Transport_02_F", "Aegis_I_Heli_Transport_02_Heavy_F", "I_Heli_Light_01_F", "I_Heli_light_03_unarmed_F"];
//publicVariable "East_Air_Transport";

East_Air_Heli = ["I_Heli_Attack_03_F", "I_Heli_Light_01_dynamicLoadout_F", "I_Heli_light_03_dynamicLoadout_F", "Aegis_I_Raven_Heli_Attack_04_F"]; 
//publicVariable "East_Air_Heli";

East_Air_Jet = ["I_Plane_Fighter_04_F", "I_Plane_Fighter_03_dynamicLoadout_F"]; 
//publicVariable "East_Air_Jet";

East_Ground_Artillery = ["O_R_MBT_02_arty_F"]; 
//publicVariable "East_Ground_Artillery";

East_Air_Drone = ["I_UAV_02_lxWS", "I_UAV_01_F"]; 
//publicVariable "East_Air_Drone";

East_Units = [
    // Regular infantry (high frequency)
    "I_soldier_F", "I_soldier_F", "I_soldier_F", "I_soldier_F",  // Regular rifleman
    "I_Soldier_AR_F", "I_Soldier_AR_F",                          // Autorifleman
    "I_Soldier_CQ_F", "I_Soldier_CQ_F",                          // CQB specialist
    "I_Soldier_GL_F", "I_Soldier_GL_F",                          // Grenadier
    
    // Support roles (medium frequency)
    "I_medic_F", "I_medic_F",                                    // Medic
    "Aegis_I_Soldier_MG_F", "Aegis_I_Soldier_MG_F",              // Machine gunner
    "I_Soldier_M_F",                                             // Marksman
    "I_Soldier_A_F",                                             // Ammo bearer
    
    // Specialists (low frequency)
    "I_Soldier_LAT_F",                                           // Light AT
    "I_Soldier_LAT2_F",                                          // Light AT
    "I_Soldier_AT_F",                                            // AT Specialist
    "I_Soldier_AA_F",                                            // AA Specialist
    "Aegis_I_HeavyGunner_F"                                     // Heavy gunner
];
//publicVariable "East_Units";

East_FireObserver = ["I_RadioOperator_F"];
East_Units_Officers = ["I_officer_F"];
//publicVariable "East_Units_Officers";

East_Groups = [
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfSquad"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfSquad_Weapons"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfTeam"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfTeam_AA"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfTeam_AT"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "I_InfTeam_Light"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "SpecOps" >> "HAF_SniperTeam"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Support" >> "HAF_Support_EOD"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Support" >> "HAF_Support_GMG"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Support" >> "HAF_Support_MG"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Support" >> "HAF_Support_Mort"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Support" >> "HAF_Support_ENG"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_Raven_F" >> "Infantry" >> "I_Raven_InfSquad"),
(configFile >> "CfgGroups" >> "Indep" >> "IND_Raven_F" >> "Infantry" >> "I_Raven_InfTeam")
];
//publicVariable "East_Groups";