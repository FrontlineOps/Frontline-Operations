// Where are Classnames ? Right click on any Unit or Vehicle in the Editor and Select find in CFG viewer, Last Name in the [path] tab is the Classname,

/*
 * TEMPLATE EXAMPLE - UNCOMMENT AND REPLACE WITH YOUR DESIRED CLASSES
 *
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

// Default OPFOR vehicles (Vanilla Arma 3 CSAT)
East_Ground_Vehicles_Ambient = ["O_MRAP_02_F", "O_Truck_02_covered_F", "O_Truck_02_transport_F"]; 
//publicVariable "East_Ground_Vehicles_Ambient";

East_Ground_Vehicles_Light = ["O_MRAP_02_hmg_F", "O_MRAP_02_gmg_F", "O_LSV_02_armed_F", "O_LSV_02_AT_F"]; 
//publicVariable "East_Ground_Vehicles_Light";

East_Ground_Vehicles_Heavy = ["O_APC_Tracked_02_cannon_F", "O_APC_Wheeled_02_rcws_v2_F", "O_MBT_02_cannon_F"]; 
//publicVariable "East_Ground_Vehicles_Heavy";

East_Ground_Transport = ["O_Truck_02_transport_F", "O_Truck_02_covered_F", "O_MRAP_02_F"]; 
//publicVariable "East_Ground_Transport";

East_Air_Transport = ["O_Heli_Light_02_unarmed_F", "O_Heli_Transport_04_covered_F"];
//publicVariable "East_Air_Transport";

East_Air_Heli = ["O_Heli_Light_02_dynamicLoadout_F", "O_Heli_Attack_02_dynamicLoadout_F"]; 
//publicVariable "East_Air_Heli";

East_Air_Jet = ["O_Plane_CAS_02_dynamicLoadout_F", "O_Plane_Fighter_02_F"]; 
//publicVariable "East_Air_Jet";

East_Ground_Artillery = ["O_MBT_02_arty_F", "O_Mortar_01_F"]; 
//publicVariable "East_Ground_Artillery";

East_Air_Drone = ["O_UAV_02_dynamicLoadout_F", "O_UAV_01_F"]; 
//publicVariable "East_Air_Drone";

// Default OPFOR units (Vanilla Arma 3 CSAT)
East_Units = [
    // Regular infantry
    "O_Soldier_F",
    "O_Soldier_AR_F",
    "O_Soldier_GL_F",
    "O_Soldier_LAT_F",
    "O_Soldier_AT_F",
    "O_soldier_M_F",
    "O_Soldier_AA_F",
    "O_Soldier_TL_F",
    "O_medic_F",
    "O_engineer_F"
];
//publicVariable "East_Units";

East_FireObserver = ["O_RadioOperator_F"];

East_Units_Officers = ["O_officer_F"];
//publicVariable "East_Units_Officers";

East_Groups = [
    (configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfSquad"),
    (configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfTeam"),
    (configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfTeam_AT")
];
//publicVariable "East_Groups";