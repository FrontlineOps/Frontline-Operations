East_Ground_Vehicles_Ambient = ["I_MRAP_03_F","I_MRAP_03_gmg_F", "I_Truck_02_covered_F", "I_Truck_02_ammo_F", "I_Truck_02_fuel_F", "I_Truck_02_transport_F"]; 
East_Ground_Vehicles_Light = [ "I_MRAP_03_hmg_F", "I_MRAP_03_gmg_F", "I_APC_Wheeled_03_cannon_F", "I_LT_01_cannon_F", "I_LT_01_AA_F"]; 
East_Ground_Vehicles_Heavy = [ "I_APC_tracked_03_cannon_F", "I_MBT_03_cannon_F"]; 
East_Ground_Transport = ["I_MRAP_03_F", "I_Truck_02_covered_F",  "I_Truck_02_transport_F"]; 

East_Air_Transport = ["I_Heli_Transport_02_F","I_Heli_light_03_unarmed_F"];
East_Air_Heli = ["I_Heli_light_03_dynamicLoadout_F"]; 
East_Air_Jet = ["I_Plane_Fighter_03_dynamicLoadout_F", "I_Plane_Fighter_04_F"]; 

East_Units = ["I_Soldier_SL_F","I_Soldier_TL_F","I_Soldier_lite_F","I_soldier_F","I_Soldier_LAT2_F","I_Soldier_GL_F","I_Soldier_AR_F","I_Soldier_M_F","I_engineer_F","I_medic_F"];
East_FireObserver = ["I_Soldier_SL_F"];
East_Units_Officers = ["I_officer_F"];

East_Groups = [
(configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfSentry"),
(configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfTeam_AT"),
(configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfTeam_AA"),
(configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "I_InfTeam_Light"),
(configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfSquad"),
(configfile >> "CfgGroups" >> "Indep" >> "IND_F" >> "Infantry" >> "HAF_InfSquad_Weapons")
];