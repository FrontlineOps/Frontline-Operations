East_Ground_Vehicles_Ambient = ["I_E_Offroad_01_F","I_E_Van_02_transport_F", "I_E_Offroad_01_covered_F", "I_E_Truck_02_transport_F", "I_E_Truck_02_fuel_F", "I_E_Truck_02_F", "I_E_Truck_02_MRL_F"]; 
East_Ground_Vehicles_Light = [ "I_E_UGV_01_rcws_F", "O_G_Offroad_01_armed_F", "O_G_Offroad_01_AT_F"]; 
East_Ground_Vehicles_Heavy = [ "I_E_APC_tracked_03_cannon_F"]; 
East_Ground_Transport = ["I_E_Van_02_transport_F", "I_E_Offroad_01_F", "I_E_Offroad_01_covered_F",  "I_E_Truck_02_F", "I_E_Truck_02_transport_F"]; 

East_Air_Transport = ["I_Heli_Transport_02_F","I_E_Heli_light_03_unarmed_F"];
East_Air_Heli = ["I_E_Heli_light_03_dynamicLoadout_F"]; 
East_Air_Jet = ["I_Plane_Fighter_03_dynamicLoadout_F", "I_Plane_Fighter_04_F"];
East_Ground_Artillery = ["O_MBT_02_arty_F"];
East_Air_Drone = ["O_UAV_01_F"]; 

East_Units = ["I_E_Soldier_F","I_E_Soldier_A_F","I_E_Soldier_AR_F","I_E_Soldier_lite_F","I_E_soldier_M_F","I_E_Soldier_SL_F","I_E_Soldier_LAT2_F", "I_E_RadioOperator_F", "I_E_Soldier_Exp_F"];
East_FireObserver = ["I_E_RadioOperator_F"];
East_Units_Officers = ["I_E_Officer_F"];

East_Groups = [
(configfile >> "CfgGroups" >> "Indep" >> "IND_E_F" >> "Infantry" >> "I_E_InfSentry"),
(configfile >> "CfgGroups" >> "Indep" >> "IND_E_F" >> "Infantry" >> "I_E_InfTeam"),
(configfile >> "CfgGroups" >> "Indep" >> "IND_E_F" >> "Infantry" >> "I_E_InfSquad")
];