East_Ground_Vehicles_Ambient = ["CUP_O_Hilux_unarmed_TK_INS",  "CUP_O_V3S_Open_TKM", "CUP_O_Hilux_UB32_TK_INS", "CUP_O_Hilux_M2_TK_INS", "CUP_O_V3S_Refuel_TKM", "CUP_O_Hilux_DSHKM_TK_INS", "CUP_O_Hilux_metis_TK_INS"]; 
East_Ground_Vehicles_Light = ["CUP_O_Hilux_M2_TK_INS", "CUP_O_Hilux_DSHKM_TK_INS", "CUP_O_Hilux_UB32_TK_INS", "CUP_O_Hilux_SPG9_TK_INS", "CUP_O_Hilux_metis_TK_INS"]; 
East_Ground_Vehicles_Heavy = ["CUP_O_BMP2_CHDKZ","CUP_O_BMP2_CHDKZ", "Opf_I_I_Offroad_01_AT_F", "CUP_O_Hilux_SPG9_TK_INS", "Opf_I_I_Offroad_01_armed_F", "CUP_O_Hilux_UB32_TK_INS"];  
East_Ground_Transport = ["CUP_O_Hilux_unarmed_TK_INS",  "CUP_O_V3S_Open_TKM"]; 

East_Air_Transport = [""];
East_Air_Heli = ["O_Heli_Light_02_dynamicLoadout_F"]; 
East_Air_Jet = ["O_Heli_Light_02_dynamicLoadout_F"]; 
East_Ground_Artillery = ["O_MBT_02_arty_F"];
East_Air_Drone = ["O_UAV_01_F"];

East_Units = ["CUP_O_TK_INS_Soldier_TL","CUP_O_TK_INS_Soldier_MG","CUP_O_TK_INS_Soldier_GL","CUP_O_TK_INS_Soldier_AT","CUP_O_TK_INS_Soldier","CUP_O_TK_INS_Soldier_MG","CUP_O_TK_INS_Soldier_AR","CUP_O_TK_INS_Sniper", "CUP_O_TK_INS_Soldier_Enfield", "CUP_O_TK_INS_Soldier_FNFAL"];
East_FireObserver = ["CUP_O_TK_INS_Soldier_TL"];
East_Units_Officers = ["Opf_I_I_Soldier_Base_unarmed_F"];

East_Groups = [
(configfile >> "CfgGroups" >> "East" >> "CUP_O_TK_MILITIA" >> "Infantry" >> "CUP_O_TK_MILITIA_Patrol"),
(configfile >> "CfgGroups" >> "East" >> "CUP_O_TK_MILITIA" >> "Infantry" >> "CUP_O_TK_MILITIA_Group"),
(configfile >> "CfgGroups" >> "East" >> "CUP_O_TK_MILITIA" >> "Infantry" >> "CUP_O_TK_MILITIA_ATTeam"),
(configfile >> "CfgGroups" >> "East" >> "CUP_O_TK_MILITIA" >> "Infantry" >> "CUP_O_TK_MILITIA_AATeam")
];