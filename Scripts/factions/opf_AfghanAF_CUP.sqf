East_Ground_Vehicles_Ambient = ["CUP_O_LR_Transport_TKA",  "CUP_O_Ural_TKA", "CUP_O_UAZ_Open_TKA", "CUP_O_LR_MG_TKM", "CUP_O_LR_MG_TKM", "CUP_O_Hilux_AGS30_TK_INS", "CUP_O_Hilux_DSHKM_TK_INS", "CUP_O_Hilux_M2_TK_INS", "CUP_O_Hilux_SPG9_TK_INS","CUP_O_BTR40_MG_TKM","CUP_O_MTLB_pk_TK_MILITIA"]; 
East_Ground_Vehicles_Light = ["CUP_O_LR_MG_TKM", "CUP_O_LR_MG_TKM", "CUP_O_Hilux_AGS30_TK_INS", "CUP_O_Hilux_DSHKM_TK_INS", "CUP_O_Hilux_M2_TK_INS", "CUP_O_Hilux_SPG9_TK_INS","CUP_O_BTR40_MG_TKM","CUP_O_MTLB_pk_TK_MILITIA"]; 
East_Ground_Vehicles_Heavy = ["CUP_O_BTR80_TK","CUP_O_BTR80A_TK", "CUP_O_BMP1P_TKA", "CUP_O_BMP2_TKA", "CUP_O_BMP2_TKA", "CUP_O_ZSU23_Afghan_TK", "CUP_O_ZSU23_TK", "CUP_O_BMP2_ZU_TKA", "CUP_O_T55_TK", "CUP_O_T72_TKA", "CUP_O_T72_TKA"]; 
East_Ground_Transport = ["CUP_O_LR_Transport_TKA",  "CUP_O_Ural_TKA", "CUP_O_UAZ_Open_TKA"]; 

East_Air_Transport = ["CUP_O_UH1H_TKA","CUP_O_Mi17_TK"];
East_Air_Heli = ["CUP_O_UH1H_gunship_TKA",  "CUP_O_Mi24_D_Dynamic_TK"]; 
East_Air_Jet = ["CUP_O_Su25_Dyn_TKA"];
East_Ground_Artillery = ["O_MBT_02_arty_F"];
East_Air_Drone = ["O_UAV_01_F"];

East_Units = ["CUP_O_TK_Soldier_SL","CUP_O_TK_Soldier","CUP_O_TK_Soldier_Backpack","CUP_O_TK_Soldier_AT","CUP_O_TK_Soldier_GL","CUP_O_TK_Soldier_AR","CUP_O_TK_Soldier_MG","CUP_O_TK_Sniper","CUP_O_TK_Soldier_HAT","CUP_O_TK_Engineer"];
East_FireObserver = ["CUP_O_TK_Soldier_SL"];
East_Units_Officers = ["CUP_O_TK_Officer"];

East_Groups = [
(configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySection"),
(configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySectionAT"),
(configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySectionAA"),
(configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySectionMG"),
(configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySquad"),
(configfile >> "CfgGroups" >> "East" >> "CUP_O_TK" >> "Infantry" >> "CUP_O_TK_InfantrySquad")
];