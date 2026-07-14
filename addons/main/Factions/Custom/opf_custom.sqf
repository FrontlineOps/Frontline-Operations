/*
 * Custom OPFOR definition.
 * Every class in this fallback pool is native config side 0.
 */

East_Ground_Infantry = [
    (configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfSentry"),
    (configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfTeam"),
    (configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfTeam_AT"),
    (configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfTeam_AA"),
    (configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfSquad"),
    (configFile >> "CfgGroups" >> "East" >> "OPF_F" >> "Infantry" >> "OIA_InfSquad_Weapons"),
    "O_Soldier_F",
    "O_Soldier_AR_F",
    "O_Soldier_GL_F",
    "O_medic_F",
    "O_soldier_M_F",
    "O_Soldier_A_F",
    "O_Soldier_LAT_F",
    "O_Soldier_AT_F",
    "O_Soldier_AA_F"
];

East_Ground_SpecOps = [];
East_Ground_Motorized = ["O_MRAP_02_F", "O_MRAP_02_gmg_F", "O_MRAP_02_hmg_F"];
East_Ground_Mechanized = ["O_APC_Wheeled_02_rcws_v2_F", "O_APC_Tracked_02_cannon_F"];
East_Ground_Armor = ["O_MBT_02_cannon_F"];
East_Ground_Transport = ["O_MRAP_02_F", "O_Truck_03_transport_F", "O_Truck_03_covered_F"];
East_Air_Transport = ["O_Heli_Light_02_unarmed_F", "O_Heli_Transport_04_covered_F", "O_Heli_Transport_04_bench_F"];
East_Air_Heli = ["O_Heli_Light_02_dynamicLoadout_F", "O_Heli_Attack_02_dynamicLoadout_F"];
East_Air_Jet = ["O_Plane_CAS_02_dynamicLoadout_F", "O_Plane_Fighter_02_F"];
East_Ground_Artillery = ["O_MBT_02_arty_F"];
East_Air_Drone = ["O_UAV_01_F"];
East_Ground_Drone = ["O_UGV_01_rcws_F"];
East_Mobile_AA = ["O_APC_Tracked_02_AA_F"];
East_Static_AA = ["O_static_AA_F", "O_SAM_System_04_F"];
East_Radar = ["O_Radar_System_02_F"];
East_Boat = ["O_Boat_Armed_01_hmg_F"];
East_FireObserver = ["O_recon_JTAC_F"];
