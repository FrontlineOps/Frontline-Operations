East_Ground_Vehicles_Ambient = ["Opf_I_I_Offroad_01_F",  "Opf_I_I_Van_01_transport_F", "Opf_I_I_Offroad_01_F", "Opf_O_S_Offroad_01_armed_F", "Opf_O_S_Offroad_01_armed_F", "Opf_O_S_Offroad_01_AT_F"]; 
East_Ground_Vehicles_Light = ["Opf_O_S_Offroad_01_armed_F", "Opf_O_S_Offroad_01_armed_F", "Opf_O_S_APC_Tracked_02_cannon_F", "Opf_O_S_Offroad_01_AT_F"]; 
East_Ground_Vehicles_Heavy = ["Opf_O_S_APC_Tracked_02_cannon_F","Opf_O_S_APC_Tracked_02_cannon_F", "Opf_O_S_Offroad_01_AT_F", "Opf_O_S_Offroad_01_AT_F", "Opf_O_S_Offroad_01_armed_F"]; 
East_Ground_Transport = ["Opf_O_S_Offroad_01_F",  "Opf_O_S_Truck_02_transport_F"]; 

East_Air_Transport = ["Opf_I_R_Heli_Light_02_unarmed_F"];
East_Air_Heli = ["O_Heli_Light_02_dynamicLoadout_F"]; 
East_Air_Jet = ["O_Heli_Light_02_dynamicLoadout_F"]; 

East_Units = ["Opf_O_S_Soldier_9_F","Opf_O_S_Soldier_8_F","Opf_O_S_Soldier_7_F","Opf_O_S_Soldier_6_F","Opf_O_S_Soldier_5_F","Opf_O_S_Soldier_4_F","Opf_O_S_Soldier_3_F","Opf_O_S_Soldier_2_F","Opf_O_S_Soldier_1_F", "Opf_O_P_soldier_TL_F", "Opf_O_P_soldier_1_F", "Opf_O_P_soldier_LAT_F", "Opf_O_P_soldier_M_F", "Opf_O_P_soldier_GL_F", "Opf_O_P_soldier_AR_F", "Opf_O_P_soldier_exp_F", "Opf_O_P_medic_F"];
East_FireObserver = ["Opf_O_S_Soldier_9_F"];
East_Units_Officers = ["Opf_O_S_Soldier_2_F"];

East_Groups = [
(configfile >> "CfgGroups" >> "East" >> "Opf_OPF_S_F" >> "Infantry" >> "SeparatistShockTeam"),
(configfile >> "CfgGroups" >> "East" >> "Opf_OPF_S_F" >> "Infantry" >> "SeparatistFireTeam"),
(configfile >> "CfgGroups" >> "East" >> "Opf_OPF_S_F" >> "Infantry" >> "SeparatistCombatGroup")
];