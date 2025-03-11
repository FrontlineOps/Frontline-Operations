East_Ground_Vehicles_Ambient = [ "O_SFIA_Offroad_lxWS","I_C_Offroad_02_AT_F","I_C_Offroad_02_LMG_F", "O_Tura_Offroad_armor_lxWS", "I_C_Offroad_02_unarmed_F","O_SFIA_Truck_02_transport_lxWS","I_C_Offroad_02_LMG_F","O_T_Quadbike_01_ghex_F"]; 
East_Ground_Vehicles_Light = ["O_Tura_Offroad_armor_lxWS",  "O_Tura_Offroad_armor_AT_lxWS",  "O_Tura_Offroad_armor_armed_lxWS","O_SFIA_Offroad_AT_lxWS" ,"I_C_Offroad_02_LMG_F", "O_Tura_Truck_02_aa_lxWS"]; 
East_Ground_Vehicles_Heavy = [ "O_SFIA_APC_Tracked_02_cannon_lxWS", "O_Tura_Truck_02_aa_lxWS", "O_SFIA_Truck_02_MRL_lxWS"]; 
East_Ground_Transport = ["O_Tura_Offroad_armor_lxWS",  "O_SFIA_Truck_02_transport_lxWS","O_SFIA_Offroad_lxWS"]; 

East_Air_Transport = ["I_C_Heli_Light_01_civil_F", "O_Heli_Transport_04_covered_F"];
East_Air_Heli = ["O_Heli_Light_02_dynamicLoadout_F"]; 
East_Air_Jet = ["O_Heli_Light_02_dynamicLoadout_F"];
East_Ground_Artillery = ["O_MBT_02_arty_F"];
East_Air_Drone = ["O_UAV_01_F"]; 

East_Units = ["O_Tura_watcher_lxWS","O_Tura_deserter_lxWS","O_Tura_enforcer_lxWS","O_Tura_hireling_lxWS","O_Tura_scout_lxWS","O_Tura_medic2_lxWS","O_Tura_thug_lxWS"];
East_FireObserver = ["O_Tura_watcher_lxWS"];
East_Units_Officers = ["O_SFIA_officer_lxWS"];

East_Groups = [
(configfile >> "CfgGroups" >> "East" >> "OPF_TURA_lxWS" >> "Infantry" >> "B_Tura_InfTeam_lxWS"),
(configfile >> "CfgGroups" >> "East" >> "OPF_TURA_lxWS" >> "Infantry" >> "B_Tura_InfTeam_lxWS"),
(configfile >> "CfgGroups" >> "East" >> "OPF_TURA_lxWS" >> "Infantry" >> "B_Tura_InfSquad_lxWS")
];