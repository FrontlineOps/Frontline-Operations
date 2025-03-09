if (isServer) then { 

MissionLoadedLitterally = 0 ; 
publicVariable "MissionLoadedLitterally";

_missionTag = missionName;
_missionTag = [_missionTag] call BIS_fnc_filterString;

private _MarkerDataName = _missionTag + "_markers";
private _VehicleDataName = _missionTag + "_Vehicles";
private _ObjectDataName = _missionTag + "_Objects";
private _MarkerTimeName = _missionTag + "_Time";


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

private _date = profileNamespace getVariable _MarkerTimeName;
if (!isNil "_date") then { setDate _date; };

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

sleep 2 ;


private _GetVariableMark = profileNamespace getVariable _MarkerDataName;

_allMarkNames = keys _GetVariableMark;

{
_M = _x;
_MrkAtts = _GetVariableMark get _x;
_MPos = _MrkAtts get "pos";
_MType = _MrkAtts get "type";
_MSize = _MrkAtts get "size";
_MText = _MrkAtts get "text";
_MBrush = _MrkAtts get "brush";
_MShape = _MrkAtts get "shape";
_MDir = _MrkAtts get "dir";
_Mcolor = _MrkAtts get "color";
_MAlpha = _MrkAtts get "alpha";

_mrkr = createMarkerLocal [_M,[0,0,0]] ;
_mrkr setMarkerPosLocal _MPos ;
_mrkr setMarkerTypeLocal _MType;
_mrkr setMarkerBrushLocal _MBrush; 
_mrkr setMarkerShapeLocal _MShape; 
_mrkr setMarkerSizeLocal _MSize; 
_mrkr setMarkerTextLocal  _MText; 
_mrkr setMarkerDirLocal _MDir; 
_mrkr setMarkerColor _Mcolor;
_mrkr setMarkerAlpha _MAlpha; 
} forEach _allMarkNames ; 





//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
sleep 2 ;


private _GetVariableStatic = profileNamespace getVariable _ObjectDataName;

_allVehNames = keys _GetVariableStatic;

{
_StcAtts = _GetVariableStatic get _x;
_posASL = _StcAtts get "posASL";
_Type = _StcAtts get "type";
_DirUp = _StcAtts get "vectorDirAndUp";

_NewVeh = createVehicle [_Type, [0,0, (500 + random 2000)], [], 0, "CAN_COLLIDE"] ;
     _NewVeh setVectorDirAndUp _DirUp;
     _NewVeh setPosASL _posASL;
} forEach _allVehNames ; 




//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
sleep 2 ;

private _GetVariableVeh = profileNamespace getVariable _VehicleDataName;

_allVehNames = keys _GetVariableVeh;

{
_VehAtts = _GetVariableVeh get _x;
_posATL = _VehAtts get "posATL";
_Type = _VehAtts get "type";
_DirUp = _VehAtts get "vectorDirAndUp";

_NewVeh = createVehicle [_Type, [0,0, (500 + random 2000)], [], 0, "CAN_COLLIDE"] ;

     _NewVeh setVectorDirAndUp _DirUp;
     _NewVeh setPosATL _posATL;

_vehicleConfig = (configFile >> "CfgVehicles" >> typeOf _NewVeh);
_crewType = [west, _vehicleConfig] call BIS_fnc_selectCrew;
_CrewFull = createVehicleCrew _NewVeh ;
_CrewSelCnt = count (units _CrewFull) - 1; 
deleteVehicleCrew _NewVeh;
sleep 1;
_Group = createGroup West ; 
for "_x" from 0 to _CrewSelCnt do { _unit = _Group createunit [_crewType,[0,0,0], [], 0, "CAN_COLLIDE"]; }; 
{_x moveInAny _NewVeh} foreach units _Group;  
	{ [_x] JoinSilent _Group } foreach units _Group;  

} forEach _allVehNames ; 


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
sleep 2 ;

MissionLoadedLitterally = 1;
publicVariable "MissionLoadedLitterally";

}; 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
