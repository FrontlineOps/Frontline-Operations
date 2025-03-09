if (isServer) then { 

[[west,"HQ"], "Saving Mission ..."] remoteExec ["sideChat", 0];

sleep 5;

_missionTag = missionName;
_missionTag = [_missionTag] call BIS_fnc_filterString;

private _MarkerTimeName = _missionTag + "_Time";
private _MarkerDataName = _missionTag + "_markers";
private _VehicleDataName = _missionTag + "_Vehicles";
private _ObjectDataName = _missionTag + "_Objects";

sleep 2;

profileNamespace setVariable [_MarkerTimeName, nil];
profileNamespace setVariable [_MarkerDataName, nil];
profileNamespace setVariable [_VehicleDataName, nil];
profileNamespace setVariable [_ObjectDataName, nil];


sleep 2;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

_spheres = nearestobjects [player,["Sign_Sphere10cm_F"],40000] ; 
if (count _spheres > 0) then {{deleteVehicle _x;} forEach _spheres ;} ;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

private _MarkerDataName = _missionTag + "_markers";

private _MarkerDataHash = createHashMap;

private _SaveMarks = allMapMarkers select {markerColor _x != "Color1_FD_F" && markerColor _x != "colorCivilian" && markerType _x != "mil_marker_noShadow" && markerType _x != "loc_Bunker" && markerType _x != "loc_Lighthouse" && markerType _x != "o_Ordnance" &&  markerShape _x != "RECTANGLE" && markerType _x != "respawn_inf" && markerType _x != "o_unknown" && markerType _x != "mil_warning" && markerType _x != "mil_unknown" && markerType _x != "o_maint"} ;

				
				_STRUCMs = allMapMarkers select { markerType _x == "o_maint"};
								_BLUMs = allMapMarkers select { markerType _x == "b_installation"};

	if ( (count _STRUCMs > 0) && (count _BLUMs > 0) ) then {			
					{			
								_BLUMs = allMapMarkers select { markerType _x == "b_installation"};
								_BLUM = [_BLUMs,  _x] call BIS_fnc_nearestPosition;
								if (((getMarkerPos _x) distance (getMarkerPos _BLUM)) < 200) then {_SaveMarks append [_x] ; };
								} forEach _STRUCMs ;					
	};
							
{
private _MarkerDataHashEach = createHashMap;

   _MarkerDataHashEach set ["name",_x]  ;
   _MarkerDataHashEach set ["alpha",markerAlpha _x]  ;
   _MarkerDataHashEach set ["brush",markerBrush _x]  ;
   _MarkerDataHashEach set ["color",getMarkerColor _x]  ;
   _MarkerDataHashEach set ["dir",markerDir _x]  ;
   _MarkerDataHashEach set ["pos",getMarkerPos _x]  ;
   _MarkerDataHashEach set ["shape",markerShape _x]  ;
   _MarkerDataHashEach set ["size",getMarkerSize _x]  ;
   _MarkerDataHashEach set ["text",markerText _x]  ;
   _MarkerDataHashEach set ["type",getMarkerType _x]  ;

_MarkerDataHash set [_x, _MarkerDataHashEach];

} forEach _SaveMarks ;

profileNamespace setVariable [_MarkerDataName, _MarkerDataHash];

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

profileNamespace setVariable [_MarkerTimeName, date];

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

private _VehicleDataName = _missionTag + "_Vehicles";

private _VehicleDataHash = createHashMap;


_VEHs = [] ;

_Centerposition = [worldSize / 2, worldsize / 2, 0];
_ALLFACVEHs = nearestobjects [_Centerposition,[
"B_SAM_System_01_F",
"B_AAA_System_01_F",
"B_SAM_System_02_F",
"B_SAM_System_03_F",
"B_GMG_01_A_F",
"B_HMG_01_A_F",
"B_W_Static_Designator_01_F",
"B_UGV_02_Demining_F",
"B_UAV_02_lxWS",
"B_UAV_01_F",
"B_SDV_01_F",
"B_Boat_Transport_01_F",
"USAF_A10",
"USAF_F22",
"USAF_F22_Heavy",
"USAF_F35A_STEALTH",
"USAF_F35A",
"USAF_AC130U",
"USAF_C130J",
"USAF_C130J_Cargo",
"usaf_kc135",
"USAF_C17",
F_RADAR,
F_Bike_01,
F_ABT_01,
F_UAV_01,
F_UAV_02,
F_UAV_03,
F_UGV_01,
F_turret_01,
F_turret_02,
F_turret_03,
F_Car_01,
F_Car_02,
F_Car_03,
F_Car_04,
F_Car_05,
F_Car_06,
F_MRAP_01,
F_MRAP_02,
F_MRAP_03,
F_MRAP_04,
F_MRAP_05,
F_MRAP_06,
F_Truck_01,
F_Truck_02,
F_Truck_03,
F_Truck_04,
F_Truck_05,
F_Truck_06,
F_APC_01,
F_APC_02,
F_APC_03,
F_APC_04,
F_APC_05,
F_APC_06,
F_TNK_01,
F_TNK_02,
F_TNK_03,
F_TNK_04,
F_Art_00,
F_Art_01,
F_Art_02,
F_Heli_01,
F_Heli_02,
F_Heli_03,
F_Heli_04,
F_Heli_05,
F_Heli_06_G,
F_Heli_07_G,
F_Plane_01_CAS,
F_Plane_02_CAS,
F_Plane_03,
F_Plane_04,
F_Plane_05,
F_Plane_06
],40000] ;
_VEHs append _ALLFACVEHs ;	

_allFOBMarks = allMapMarkers select {markerType _x == "b_installation" && markerColor _x == "ColorYellow"};  
	{
_VehsNew = nearestobjects [(getMarkerPos _x),["Air","Ship","LandVehicle"],250] ;
_VehsNewAlive = _VehsNew select {alive _x == true} ;
_VEHs append _VehsNewAlive ;	
	} forEach _allFOBMarks ;


VEHSave = _VEHs select {alive _x == true} ;
FinalVehSaving = VEHSave arrayIntersect VEHSave ;



{
private _VehicleDataHashEach = createHashMap;
private _VehicleNameStr = str getPosATL _x + "_Veh";
_x setVehicleVarName _VehicleNameStr;

private _VehicleName = vehicleVarName _x ;

   _VehicleDataHashEach set ["type", typeOf _x]  ;
   _VehicleDataHashEach set ["posATL",getPosATL _x]  ;
   _VehicleDataHashEach set ["vectorDirAndUp",[vectorDir _x,vectorUp _x]]  ;

_VehicleDataHash set [_VehicleName, _VehicleDataHashEach];

} forEach FinalVehSaving ;

profileNamespace setVariable [_VehicleDataName, _VehicleDataHash];



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

private _ObjectDataName = _missionTag + "_Objects";

private _ObjectDataHash = createHashMap;

SaveStatics = [] ;


_allFOBMarks = allMapMarkers select {markerType _x == "b_installation" && markerColor _x == "ColorYellow" && markerText _x == "FOB"};  
	{
_staticsNew = nearestobjects [(getMarkerPos _x),["Static", "Thing"],300] ;
_staticsNewAlive = _staticsNew select {alive _x == true} ;
_staticsTerrain = nearestTerrainObjects [(getMarkerPos _x), [], 300];
_staticsSaving = _staticsNewAlive - _staticsTerrain ;
SaveStatics append _staticsSaving ;	
	} forEach _allFOBMarks ;


_allNonFOBMarks = allMapMarkers select {markerType _x == "b_installation" && (markerColor _x == "ColorYellow" or markerColor _x == "colorBLUFOR" or markerColor _x == "colorWEST") && markerText _x != "FOB"};  
	{
_staticsNew = nearestobjects [(getMarkerPos _x),["Static", "Thing"],200] ;
_staticsNewAlive = _staticsNew select {alive _x == true} ;
_staticsTerrain = nearestTerrainObjects [(getMarkerPos _x), [], 200];
_staticsSaving = _staticsNewAlive - _staticsTerrain ;
SaveStatics append _staticsSaving ;	
	} forEach _allNonFOBMarks ;


FinalSaving = SaveStatics arrayIntersect SaveStatics ;
	

{
private _ObjectDataHashEach = createHashMap;
private _ObjectNameStr = str getPosASL _x + "_Obj";
_x setVehicleVarName _ObjectNameStr;

private _ObjectName = vehicleVarName _x ;

   _ObjectDataHashEach set ["type", typeOf _x]  ;
   _ObjectDataHashEach set ["posASL",getPosASL _x]  ;
   _ObjectDataHashEach set ["vectorDirAndUp",[vectorDir _x,vectorUp _x]]  ;

   
_ObjectDataHash set [_ObjectName, _ObjectDataHashEach];

} forEach FinalSaving ;

profileNamespace setVariable [_ObjectDataName, _ObjectDataHash];

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

[[west,"HQ"], "Mission Saved !"] remoteExec ["sideChat", 0];

};