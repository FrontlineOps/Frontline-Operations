
E_Officer = "O_officer_F";

East_Units = ["O_T_Soldier_TL_F","O_T_Soldier_F","O_T_Soldier_LAT_F","O_T_Soldier_M_F","O_T_Medic_F","O_T_Soldier_AR_F","O_T_Soldier_GL_F", "O_T_Soldier_AT_F","O_T_Soldier_Exp_F"];
East_FireObserver = ["O_T_Soldier_TL_F"];
East_Units_Officers = ["O_officer_F","O_T_Officer_F"];


E_Sniper = "O_Sniper_F";
E_Spotter = "O_Spotter_F";

E_Recon_TL = "O_Recon_TL_F";
E_Recon_Mrk = "O_Recon_M_F";
E_Recon_AT = "O_Recon_LAT_F";
E_Recon_PF = "O_Pathfinder_F";
E_Recon_Eod = "O_Recon_exp_F";
E_Recon_Med = "O_Recon_Medic_F";
E_Recon_JTAC = "O_Recon_JTAC_F";

E_Diver_TL = "O_diver_TL_F";
E_Diver_Rfl = "O_diver_F";
E_Diver_Eod = "O_diver_exp_F";

//Each Array : [name, Unit Classes, PRIORITY Use case [Defend, Attack, Patrol, Occupy, Recon, Support, Capture, Destroy] 
//    			value from 0 to 3 where 0 = never, 1 = last resort, 2 = normal and 3 is priority 
E_ALL_INF_GROUPS = [
		["Engineers", 	
			[E_Assault_Eng, E_Assault_AT, E_Assault_Eod, E_Assault_Mg],
			[0,0,0,0,0,0,0,3]
		],
		["Defense Team",		
			[E_Assault_TL, E_Assault_Amm, E_Assault_SL, E_Assault_Mg, E_Assault_Med, E_Assault_Mrk, E_Assault_Med, E_Assault_Amm],
			[3,0,0,3,0,0,0,0]
		],
		["Defense Team AT",		
			[E_Assault_TL, E_Assault_Amm, E_Assault_AT, E_Assault_Mg, E_Assault_Med, E_Assault_AT],
			[3,0,0,0,0,0,0,0]
		],
		["Defense Team AA",		
			[E_Assault_TL, E_Assault_Amm, E_Assault_AA, E_Assault_Mg, E_Assault_Med, E_Assault_AA],
			[3,0,0,0,0,0,0,0]
		],
		["Assault Team",		
			[E_Assault_TL, E_Assault_Amm, E_Assault_LAT, E_Assault_Mg, E_Assault_Med],
			[1,3,3,0,0,0,2,0]
		],
		["Assault Squad",		
			[E_Assault_SL, E_Assault_Eod, E_Assault_AT, E_Assault_Mg, E_Assault_Med, E_Assault_Amm, E_Assault_Eng, E_Assault_Mrk, E_Assault_AT, E_Assault_Mg, E_Assault_Med, E_Assault_AA],
			[1,3,0,0,0,0,2,0]
		],
		["Sniper Team",			
			[E_Sniper, E_Spotter],
			[1,3,3,1,3,0,0,0]
		],
		["Recon Team",			
			[E_Recon_TL, E_Recon_AT, E_Recon_Med, E_Recon_PF, E_Recon_Eod],
			[0,2,2,0,2,0,0,1]
		],
		["Recon Squad",			
			[E_Recon_TL, E_Recon_AT, E_Recon_Eod, E_Recon_PF, E_Recon_JTAC, E_Recon_Mrk, E_Recon_Med],
			[0,2,2,0,3,0,0,1]
		],
		["Officer Team",		
			[E_Officer, E_Assault_Amm],
			[0,0,0,0,0,2,3,0]
		]
	];

E_ALL_VEH_GROUPS = [ 
	["Transport 1",["O_Quadbike_01_F"]],
	["Transport 2",["O_Truck_02_covered_F"]],
	["Transport 3",["O_Truck_02_transport_F"]],
	["Transport 4",["O_Truck_02_transport_F"]],
	["Transport 5",["O_Truck_03_transport_F"]],
	["Transport 6",["O_Truck_02_fuel_F"]],
	["MRAP Recon",["O_MRAP_02_F"]],
	["MRAP Assault",["O_MRAP_02_gmg_F","O_MRAP_02_hmg_F"]],
	["LSV Unarmed",["O_LSV_02_unarmed_F"]],
	["LSV AT",["O_LSV_02_armed_F","O_LSV_02_AT_F","O_LSV_02_AT_F"]],
	["APC RCWS Section",["O_APC_Wheeled_02_rcws_v2_F","O_APC_Wheeled_02_rcws_v2_F"]],
	["AA Section",["O_APC_Tracked_02_AA_F","O_APC_Tracked_02_AA_F"]],
	["APC Section",["O_APC_Tracked_02_cannon_F","O_APC_Tracked_02_cannon_F"]],
	["Tank Section Hvy",["O_MBT_02_cannon_F","O_MBT_02_cannon_F"]],
	["Tank Section Lt",["O_MBT_04_cannon_F","O_MBT_04_cannon_F"]],
	["Tank Platoon Hvy",["O_MBT_02_cannon_F","O_MBT_02_cannon_F"]],
	["Tank Platoon Lt",["O_MBT_04_cannon_F","O_MBT_04_cannon_F"]],
	["H Transport 1",["O_Heli_Transport_04_covered_F"]],
	["H Transport 2",["O_Heli_Light_02_unarmed_F"]],
	["H Assault 1",["O_Heli_Light_02_dynamicLoadout_F"]],
	["H Assault 2",["O_Heli_Attack_02_dynamicLoadout_F"]],
	["P Assault 1",["O_Plane_Fighter_02_F"]],
	["P Assault 2",["O_Plane_CAS_02_dynamicLoadout_F"]]
]; 