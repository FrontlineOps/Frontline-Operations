/*
 * Function: FLO_fnc_factionApplyAutoFriendlyGlobals
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies an auto-generated military catalog to the legacy friendly globals.
 *
 * Arguments:
 *   0: Auto military catalog <HASHMAP>
 *
 * Return Value:
 *   BOOL
 */

params [["_catalog", createHashMap, [createHashMap]]];

private _units = _catalog get "groundInfantryUnits";

West_Ground_Infantry = (_catalog get "groundInfantryGroups") + (_catalog get "groundInfantryUnits");
West_Ground_SpecOps = (_catalog get "groundSpecOpsGroups") + (_catalog get "groundSpecOpsUnits");
West_Ground_Motorized = _catalog get "groundMotorized";
West_Ground_Mechanized = _catalog get "groundMechanized";
West_Ground_Armor = _catalog get "groundArmor";
West_Ground_Transport = _catalog get "groundTransport";
West_Ground_Artillery = _catalog get "groundArtillery";
West_Air_Heli = _catalog get "airHeli";
West_Air_Jet = _catalog get "airJet";
West_Air_Transport = _catalog get "airTransport";
West_Air_Drone = _catalog get "airDrone";
West_Ground_Drone = _catalog get "groundDrone";
West_Mobile_AA = _catalog get "mobileAA";
West_Static_AA = _catalog get "staticAA";
West_Boat = _catalog get "boat";
West_Radar = _catalog get "radar";
West_Transport_Reserve_Ground_Count = _catalog get "transportReserveGroundCount";
West_Transport_Reserve_Air_Count = _catalog get "transportReserveAirCount";
West_Objective_Group_Type_Caps = _catalog get "objectiveGroupTypeCaps";
BLUFOR_Objective_Groups = _catalog get "objectiveGroups";
BLUFOR_Group_Counts = _catalog get "groupCounts";

private _fallback = _units select 0;
F_Officer = [_units, "officer"] call FLO_fnc_factionPickUnitByRole;
if (F_Officer == "") then { F_Officer = _fallback };

F_Assault_Eng = [_units, "engineer"] call FLO_fnc_factionPickUnitByRole;
F_Assault_TL = [_units, "leader"] call FLO_fnc_factionPickUnitByRole;
F_Assault_SL = F_Assault_TL;
F_Assault_Eod = [_units, "eod"] call FLO_fnc_factionPickUnitByRole;
F_Assault_Mrk = [_units, "marksman"] call FLO_fnc_factionPickUnitByRole;
F_Assault_AT = [_units, "at"] call FLO_fnc_factionPickUnitByRole;
F_Assault_Amm = [_units, "ammo"] call FLO_fnc_factionPickUnitByRole;
F_Assault_Mg = [_units, "mg"] call FLO_fnc_factionPickUnitByRole;
F_Assault_Med = [_units, "medic"] call FLO_fnc_factionPickUnitByRole;
F_Assault_Uav = [_units, "uav"] call FLO_fnc_factionPickUnitByRole;

F_Recon_Snp = [_units, "marksman"] call FLO_fnc_factionPickUnitByRole;
F_Recon_Sct = _fallback;
F_Recon_TL = F_Assault_TL;
F_Recon_Mrk = F_Assault_Mrk;
F_Recon_AT = F_Assault_AT;
F_Recon_Mg = F_Assault_Mg;
F_Recon_Eod = F_Assault_Eod;
F_Recon_Med = F_Assault_Med;
F_Recon_Eng = F_Assault_Eng;
F_Diver_TL = [_units, "diver"] call FLO_fnc_factionPickUnitByRole;
F_Diver_Eod = F_Assault_Eod;
F_Diver_Rfl = _fallback;

F_ASSLT_ENG = [F_Assault_Eng, F_Assault_AT, F_Assault_Eod];
F_ASSLT_TEAM = [F_Assault_TL, F_Assault_Eod, F_Assault_AT, F_Assault_Mg, F_Assault_Mrk, F_Assault_Amm];
F_ASSLT_SQD = [F_Assault_SL, F_Assault_Eod, F_Assault_AT, F_Assault_Mg, F_Assault_Mrk, F_Assault_Amm, F_Assault_Med, F_Assault_AT];
F_SNP_TEAM = [F_Recon_Snp, F_Recon_Sct];
F_RCN_TEAM = [F_Recon_TL, F_Recon_AT, F_Recon_Mrk, F_Recon_Mg];
F_RCN_SQD = [F_Recon_TL, F_Recon_AT, F_Recon_Eod, F_Recon_Mg, F_Recon_Eng, F_Recon_Mrk];
F_DVR_TEAM = [F_Diver_TL, F_Diver_Eod, F_Diver_Rfl];
F_OFFICER_TEAM = [F_Officer, F_Assault_Amm];

F_RADAR = if (West_Radar isEqualTo []) then { "" } else { West_Radar select 0 };
F_HQ_01 = "Land_Cargo_HQ_V3_F";
F_HQ_C_01 = "Land_TripodScreen_01_large_sand_F";
F_OP_01 = "Land_Cargo_House_V3_F";
F_OP_C_01 = "Land_TripodScreen_01_dual_v2_sand_F";

F_Bike_List = [];
F_Car_List = West_Ground_Motorized apply { [_x, 500] };
F_MRAP_List = [];
F_Truck_List = West_Ground_Transport apply { [_x, 650] };
F_Truck_Construction_List = West_Ground_Transport apply { [_x, 1000] };
F_Truck_Ammo_List = West_Ground_Transport apply { [_x, 1000] };
F_Truck_Respawn_List = West_Ground_Transport apply { [_x, 1500] };
F_APC_List = West_Ground_Mechanized apply { [_x, 2500] };
F_Tank_List = West_Ground_Armor apply { [_x, 5000] };
F_Artillery_List = West_Ground_Artillery apply { [_x, 4000] };
F_Heli_List = West_Air_Transport apply { [_x, 3000] };
F_Heli_Respawn_List = [];
F_Heli_Gunship_List = West_Air_Heli apply { [_x, 5000] };
F_Plane_List = West_Air_Jet apply { [_x, 12000] };
F_Boat_List = West_Boat apply { [_x, 500] };
F_UAV_List = West_Air_Drone apply { [_x, 1000] };
F_UGV_List = West_Ground_Drone apply { [_x, 1000] };
F_Container_List = [];
F_Turret_List = West_Static_AA apply { [_x, 1000] };
F_SAM_List = West_Static_AA apply { [_x, 2000] };

true
