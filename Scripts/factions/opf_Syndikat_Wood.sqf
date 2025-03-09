East_Ground_Vehicles_Ambient = [ "I_G_Offroad_01_armed_F","I_C_Offroad_02_AT_F","I_C_Offroad_02_LMG_F", "I_C_Offroad_02_unarmed_F", "I_C_Offroad_02_unarmed_F","I_C_Van_01_transport_F","I_C_Van_02_transport_F","O_T_Quadbike_01_ghex_F"]; 
East_Ground_Vehicles_Light = ["I_G_Offroad_01_armed_F",  "I_C_Offroad_02_LMG_F",  "I_C_Offroad_02_AT_F","I_G_Offroad_01_armed_F" ,"I_C_Offroad_02_LMG_F"]; 
East_Ground_Vehicles_Heavy = [ "I_E_APC_tracked_03_cannon_F",  "I_C_Offroad_02_AT_F",  "I_G_Offroad_01_armed_F"]; 
East_Ground_Transport = ["I_C_Van_01_transport_F",  "I_C_Van_02_transport_F","I_C_Offroad_02_unarmed_F"]; 

East_Air_Transport = ["I_C_Heli_Light_01_civil_F"];
East_Air_Heli = ["I_C_Heli_Light_01_civil_F"]; 
East_Air_Jet = ["I_C_Heli_Light_01_civil_F"];
East_Ground_Artillery = ["O_MBT_02_arty_F"];
East_Air_Drone = ["O_UAV_01_F"]; 

East_Units = ["I_C_Soldier_Para_8_F","I_C_Soldier_Para_7_F","I_C_Soldier_Para_6_F","I_C_Soldier_Para_5_F","I_C_Soldier_Para_4_F","I_C_Soldier_Para_3_F","I_C_Soldier_Para_2_F", "I_C_Soldier_Para_1_F"];
East_FireObserver = ["I_C_Soldier_Para_4_F"];
East_Units_Officers = ["I_C_Soldier_Para_4_F"];


East_Groups = [
(configfile >> "CfgGroups" >> "Indep" >> "IND_C_F" >> "Infantry" >> "ParaShockTeam"),
(configfile >> "CfgGroups" >> "Indep" >> "IND_C_F" >> "Infantry" >> "ParaFireTeam"),
(configfile >> "CfgGroups" >> "Indep" >> "IND_C_F" >> "Infantry" >> "ParaCombatGroup")
];