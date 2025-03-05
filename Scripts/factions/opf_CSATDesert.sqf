East_Ground_Vehicles_Ambient = [ "B_GEN_Offroad_01_gen_F","B_GEN_Van_02_vehicle_F","B_GEN_Van_02_transport_F", "B_GEN_Offroad_01_covered_F", "O_T_LSV_02_unarmed_F","O_T_MRAP_02_ghex_F","O_T_Truck_03_transport_ghex_F", "O_Truck_02_fuel_F",  "O_T_Quadbike_01_ghex_F","O_T_UGV_01_ghex_F", "O_T_Truck_02_transport_F","O_T_Truck_02_transport_F","O_T_Quadbike_01_ghex_F"]; 
East_Ground_Vehicles_Light = [ "O_T_APC_Wheeled_02_rcws_v2_ghex_F",  "O_T_MRAP_02_gmg_ghex_F",  "O_T_MRAP_02_hmg_ghex_F","O_T_LSV_02_AT_F" ,"O_T_LSV_02_armed_F","O_T_UGV_01_rcws_ghex_F"]; 
East_Ground_Vehicles_Heavy = [ "O_T_APC_Tracked_02_AA_ghex_F",  "O_T_APC_Tracked_02_cannon_ghex_F",  "O_T_MBT_02_cannon_ghex_F","O_T_MBT_04_cannon_F" ]; 
East_Ground_Transport = ["O_T_MRAP_02_ghex_F",  "O_T_Truck_03_transport_ghex_F","O_T_Truck_02_transport_F", "O_T_LSV_02_unarmed_F"]; 

East_Air_Transport = ["O_Heli_Light_02_unarmed_F","O_Heli_Transport_04_covered_F"];
East_Air_Heli = ["O_Heli_Light_02_dynamicLoadout_F",  "O_Heli_Attack_02_dynamicLoadout_F"]; 
East_Air_Jet = ["O_T_VTOL_02_infantry_dynamicLoadout_F", "O_Plane_CAS_02_dynamicLoadout_F"];
East_Ground_Artillery = ["O_MBT_02_arty_F"];
East_Air_Drone = ["O_UAV_01_F"];

East_Units = ["O_T_Soldier_TL_F","O_T_Soldier_F","O_T_Soldier_LAT_F","O_T_Soldier_M_F","O_T_Medic_F","O_T_Soldier_AR_F","O_T_Soldier_GL_F", "O_T_Soldier_AT_F","O_T_Soldier_Exp_F"];
East_FireObserver = ["O_T_Soldier_TL_F"];
East_Units_Officers = ["O_officer_F","O_T_Officer_F"];

East_Groups = [
(configfile >> "CfgGroups" >> "East" >> "OPF_T_F" >> "Infantry" >> "O_T_InfSentry"),
(configfile >> "CfgGroups" >> "East" >> "OPF_T_F" >> "Infantry" >> "O_T_InfTeam_AT"),
(configfile >> "CfgGroups" >> "East" >> "OPF_T_F" >> "Infantry" >> "O_T_InfTeam_AA"),
(configfile >> "CfgGroups" >> "East" >> "OPF_T_F" >> "Infantry" >> "O_T_InfTeam"),
(configfile >> "CfgGroups" >> "East" >> "OPF_T_F" >> "Support" >> "O_T_support_Mort"),
(configfile >> "CfgGroups" >> "East" >> "OPF_T_F" >> "Support" >> "O_T_support_MG"),
(configfile >> "CfgGroups" >> "East" >> "OPF_T_F" >> "Infantry" >> "O_T_InfSquad_Weapons")
];