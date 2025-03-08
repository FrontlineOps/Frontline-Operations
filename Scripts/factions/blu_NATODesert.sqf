F_Officer = "B_officer_F";

F_Assault_Eng = "B_engineer_F";
F_Assault_TL = "B_Soldier_TL_F";
F_Assault_SL = "B_Soldier_SL_F";
F_Assault_Eod = "B_soldier_exp_F";
F_Assault_Mrk = "B_Sharpshooter_F";
F_Assault_AT = "B_soldier_LAT_F";
F_Assault_Amm = "B_Soldier_A_F";
F_Assault_Mg = "B_soldier_AR_F";
F_Assault_Med = "B_medic_F";
F_Assault_Uav= "B_soldier_UAV_F";


F_Recon_Snp = "B_Recon_Sharpshooter_F";
F_Recon_Sct = "B_recon_F";

F_Recon_TL = "B_Patrol_Soldier_TL_F";
F_Recon_Mrk = "B_Patrol_Soldier_M_F";
F_Recon_AT = "B_recon_LAT_F";
F_Recon_Mg = "B_Patrol_Soldier_MG_F";
F_Recon_Eod = "B_recon_exp_F";
F_Recon_Med = "B_Patrol_Medic_F";
F_Recon_Eng = "B_Patrol_Engineer_F";

F_Diver_TL = "B_diver_TL_F";
F_Diver_Rfl = "B_diver_F";
F_Diver_Eod = "B_diver_exp_F";

if (isClass (configfile >> "CfgFactionClasses" >> "mas_nat_actrg") == true ) then {
F_Recon_TL = "B_mas_natctrg_recon_TL_F";
F_Recon_Mrk = "B_mas_natctrg_recon_M_F";
F_Recon_AT = "B_mas_natctrg_recon_LAT_F";
F_Recon_Mg = "B_mas_natctrg_recon_AR_F";
F_Diver_TL = "B_mas_natctrg_recon_TL_diverU_F";
F_Diver_Rfl = "B_mas_natctrg_recon_exp_diverU_F";
		}; 

F_RADAR = "B_Radar_System_01_F";  

F_HQ_01 = "Land_Cargo_HQ_V3_F";
F_HQ_C_01 = "Land_TripodScreen_01_large_sand_F";
F_OP_01 = "Land_Cargo_House_V3_F" ;
F_OP_C_01 = "Land_TripodScreen_01_dual_v2_sand_F" ;

F_Bike_01 = "B_Quadbike_01_F";

F_ABT_01 = "B_Boat_Armed_01_minigun_F";

F_UAV_01 = "B_UAV_02_dynamicLoadout_F";
F_UAV_02 = "B_UAV_05_F";
F_UAV_03 = "B_T_UAV_03_dynamicLoadout_F";
F_UGV_01 = "B_UGV_01_rcws_F";

F_turret_01 = "B_HMG_01_high_F";
F_turret_02 = "B_GMG_01_high_F";
F_turret_03 = "B_static_AT_F";

F_Car_01 = "B_LSV_01_unarmed_F";
F_Car_02 = "B_LSV_01_armed_F";
F_Car_03 = "B_LSV_01_AT_F";
F_Car_04 = "";
F_Car_05 = "";
F_Car_06 = "";

F_MRAP_01 = "B_MRAP_01_F";
F_MRAP_02 = "B_MRAP_01_hmg_F";
F_MRAP_03 = "B_MRAP_01_gmg_F";
F_MRAP_04 = "";
F_MRAP_05 = "";
F_MRAP_06 = "";

F_Truck_01 = "B_Truck_01_transport_F";
F_Truck_02 = "B_Truck_01_fuel_F";
F_Truck_03 = "B_Truck_01_ammo_F";
F_Truck_04 = "B_Truck_01_Repair_F";
F_Truck_05 = "B_Truck_01_medical_F";
F_Truck_06 = "";

F_APC_01 = "B_APC_Tracked_01_rcws_F";
F_APC_02 = "B_APC_Tracked_01_AA_F";
F_APC_03 = "B_APC_Tracked_01_CRV_F";
F_APC_04 = "B_APC_Wheeled_01_cannon_F";
F_APC_05 = "B_AFV_Wheeled_01_up_cannon_F";
F_APC_06 = "";

F_TNK_01= "B_MBT_01_TUSK_F";
F_TNK_02= "";
F_TNK_03= "";
F_TNK_04= "";

F_Art_00 = "B_Mortar_01_F";
F_Art_01 = "B_MBT_01_arty_F";
F_Art_02 = "B_MBT_01_mlrs_F";

F_Heli_01 = "B_Heli_Light_01_F";
F_Heli_02 = "B_Heli_Light_01_dynamicLoadout_F";
F_Heli_03 = "B_Heli_Transport_01_F";
F_Heli_04 = "B_Heli_Transport_03_F";
F_Heli_05 = "";

F_Heli_06_G = "B_Heli_Attack_01_dynamicLoadout_F";
F_Heli_07_G = "";

F_Plane_01_CAS = "B_Plane_CAS_01_dynamicLoadout_F";
F_Plane_02_CAS = "B_Plane_Fighter_01_F";
F_Plane_03 = "B_T_VTOL_01_infantry_F";
F_Plane_04 = "B_T_VTOL_01_vehicle_F";
F_Plane_05 = "B_T_VTOL_01_armed_F";
F_Plane_06 = "";