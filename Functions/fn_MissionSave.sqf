if (!isServer) exitWith {};

[[west,"HQ"], "Saving Mission ..."] remoteExec ["sideChat", 0];




Centerposition = [worldSize / 2, worldsize / 2, 0];


_missionTag = missionName;
_missionTag = [_missionTag] call BIS_fnc_filterString;

private _MarkerTimeName = _missionTag + "_Time";
private _MarkerDataName = _missionTag + "_markers";
private _VehicleDataName = _missionTag + "_Vehicles";
private _ObjectDataName = _missionTag + "_Objects";



profileNamespace setVariable [_MarkerTimeName, nil];
profileNamespace setVariable [_MarkerDataName, nil];
profileNamespace setVariable [_VehicleDataName, nil];
profileNamespace setVariable [_ObjectDataName, nil];


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

_spheres = nearestobjects [Centerposition,["Sign_Sphere10cm_F"],40000] ; 
if (count _spheres > 0) then {{deleteVehicle _x;} forEach _spheres ;} ;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


_GroupMarks = allMapMarkers select {markerType _x == "b_unknown" && markerColor _x == "Color6_FD_F"};
{deleteMarker _x; } forEach _GroupMarks;




_SaveGroups = allGroups select {(typeOf (units _x select 0) == F_Diver_Eod or  typeOf (units _x select 0) == F_Diver_Rfl or typeOf (units _x select 0) == F_Diver_TL or typeOf (units _x select 0) == F_Recon_Eod or  typeOf (units _x select 0) == F_Recon_Med or  typeOf (units _x select 0) == F_Recon_Eng or  typeOf (units _x select 0) == F_Recon_Mg or typeOf (units _x select 0) == F_Recon_AT or typeOf (units _x select 0) == F_Recon_Mrk or typeOf (units _x select 0) == F_Assault_AT or typeOf (units _x select 0) == F_Assault_Amm or  typeOf (units _x select 0) == F_Assault_Mg or typeOf (units _x select 0) == F_Recon_Snp or typeOf (units _x select 0) == F_Recon_Sct or  typeOf (units _x select 0) == F_Recon_TL or typeOf (units _x select 0) == F_Assault_SL or typeOf (units _x select 0) == F_Assault_TL or  typeOf (units _x select 0) == F_Assault_Eng or typeOf (units _x select 0) == F_Officer or typeOf (units _x select 0) == F_Assault_Eod or typeOf (units _x select 0) == F_Assault_Mrk  or typeOf (units _x select 0) == F_Assault_Uav or typeOf (units _x select 0) == F_Assault_Med or typeOf (units _x select 0) == F_Officer) && (captive (units _x select 0) == false) && (side (units _x select 0) == west)  && (alive (units _x select 0) == true)};
	{
		_GrpUntCnt = (count (units _x)) -1 ; 
		_UnitsArray = [] ;
				for "_i" from 0 to _GrpUntCnt do {
				_Uclass = typeOf ((units _x) select _i);	
				_UnitsArray append [_Uclass] ;			
				}; 

if (isPlayer ((units _x) select 0)) then {_UnitsArray deleteAt 0;};
_mrkr = createMarkerLocal [str(units _x select 0), getPos (units _x select 0)];   
_mrkr setMarkerType "b_unknown";  
_mrkr setMarkerSize [0.5, 0.5];   
_mrkr setMarkerColor "Color6_FD_F";   
_mrkr setMarkerAlpha 0.006;  
_mrkr setMarkerText str _UnitsArray; 
  
	}forEach _SaveGroups;
	
[[west,"HQ"], "Groups Saved Successfully ..."] remoteExec ["sideChat", 0];



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

profileNamespace setVariable [_MarkerTimeName, date];

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

private _VehicleDataName = _missionTag + "_Vehicles";

private _VehicleDataHash = createHashMap;


_VEHs = [] ;

_allFOBMarks = allMapMarkers select {markerType _x == "b_installation"};  
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

[[west,"HQ"], "Vehicles Saved Successfully ..."] remoteExec ["sideChat", 0];


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

	_staticsNew = nearestobjects [Centerposition,["Land_TTowerBig_2_F", "Land_TTowerBig_1_F"],40000] ;
	_staticsNewAlive = _staticsNew select {alive _x == true} ;
	_staticsTerrain = nearestTerrainObjects [Centerposition, ["Land_TTowerBig_2_F", "Land_TTowerBig_1_F"], 40000];
	_staticsSaving = _staticsNewAlive - _staticsTerrain ;
	{
		SaveStatics append [_x] ;	
	} forEach _staticsSaving ;

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

[[west,"HQ"], "Structures Saved Successfully ..."] remoteExec ["sideChat", 0];

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


private _MarkerDataName = _missionTag + "_markers";

private _MarkerDataHash = createHashMap ;

SaveMarks = allMapMarkers select {
(markerColor _x == "colorOPFOR" && 
(markerType _x == "loc_Transmitter" || 
markerType _x == "o_support" || 
markerType _x == "n_support" || 
markerType _x == "o_installation" || 
markerType _x == "n_installation" || 
markerType _x == "loc_Ruin" || 
markerType _x == "loc_Power" || 
markerType _x == "loc_mine" || 
markerType _x == "o_recon" || 
markerType _x == "o_armor" || 
markerType _x == "o_inf" || 
markerType _x == "o_service" || 
markerType _x == "o_plane" || 
markerType _x == "o_antiair" 
)) or (markerType _x == "b_installation")
 or (markerType _x == "loc_SafetyZone")
 or (markerType _x == "hd_warning")
 or (markerType _x == "hd_unknown")
 or (markerType _x == "hd_start")
 or (markerType _x == "hd_pickup")
 or (markerType _x == "hd_objective")
 or (markerType _x == "hd_join")
 or (markerType _x == "hd_flag")
 or (markerType _x == "hd_end")
 or (markerType _x == "hd_dot")
 or (markerType _x == "hd_destroy")
 or (markerType _x == "hd_arrow")
 or (markerType _x == "hd_ambush")
 or (markerType _x == "White")
 or (markerType _x == "RedCrystal")
or (markerType _x == "b_unknown" && markerColor _x == "Color6_FD_F")
or (markerType _x == "loc_Transmitter" && markerColor _x == "colorBLUFOR")
};

/*
SaveMarks = allMapMarkers select {markerColor _x != "Color1_FD_F" && markerColor _x != "colorCivilian" && markerType _x != "mil_marker_noShadow" && markerType _x != "loc_Bunker" && markerType _x != "loc_Lighthouse" && markerType _x != "o_Ordnance" &&  markerShape _x != "RECTANGLE" && markerType _x != "respawn_inf" && markerType _x != "o_unknown" && markerType _x != "mil_warning" && markerType _x != "mil_unknown" && markerType _x != "o_maint"} ;

								BLUSTRUCMs = allMapMarkers select { markerType _x == "o_maint" && markerColor _x == "ColorBlue"};
								if (count BLUSTRUCMs > 0) then {{SaveMarks append [_x] } forEach BLUSTRUCMs ; } ; 
*/
		
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

} forEach SaveMarks ;

profileNamespace setVariable [_MarkerDataName, _MarkerDataHash];

[[west,"HQ"], "BattleField Saved Successfully ..."] remoteExec ["sideChat", 0];

// Save garrisons state before finalizing the mission save
private _garrisonSaveResult = ["saveGarrisonSizes", []] call FLO_fnc_garrisonManager;
if (_garrisonSaveResult) then {
    [[west,"HQ"], "Garrison states saved successfully..."] remoteExec ["sideChat", 0];
} else {
    [[west,"HQ"], "Warning: Failed to save garrison states"] remoteExec ["sideChat", 0];
};

saveProfileNamespace;

[[west,"HQ"], "Mission Saved !"] remoteExec ["sideChat", 0];