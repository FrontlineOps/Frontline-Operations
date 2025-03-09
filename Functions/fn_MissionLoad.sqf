if (!isServer) exitWith {};

Centerposition = [worldSize / 2, worldsize / 2, 0];

MissionLoadedLitterally = 0 ; 
publicVariable "MissionLoadedLitterally";


_missionTag = missionName;
_missionTag = [_missionTag] call BIS_fnc_filterString;

private _MarkerDataName = _missionTag + "_markers";
private _VehicleDataName = _missionTag + "_Vehicles";
private _ObjectDataName = _missionTag + "_Objects";
private _MarkerTimeName = _missionTag + "_Time";
private _missionStructureTypes = _missionTag + "_StructureTypes";

// Load structure types from saved mission data
private _structureTypes = profileNamespace getVariable [_missionStructureTypes, ["Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F", "Land_Cargo_House_V3_F", "Land_Cargo_House_V1_F"]];
private _fobTypeClass = _structureTypes select 0;
private _opTypeClass = _structureTypes select 1;
["Mission", 3, format["Loaded structure types: FOB = %1, OP = %2", _fobTypeClass, _opTypeClass]] call FLO_fnc_log;

		FreshStartVal = "FreshStart" call BIS_fnc_getParamValue;
		 if (FreshStartVal == 1) then {
		 
			profileNamespace setVariable [_MarkerTimeName, nil];
			profileNamespace setVariable [_MarkerDataName, nil];
			profileNamespace setVariable [_VehicleDataName, nil];
			profileNamespace setVariable [_ObjectDataName, nil];
		} ;
		

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

private _date = profileNamespace getVariable _MarkerTimeName;
if (!isNil "_date") then { setDate _date; };

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



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
_mrkr setMarkerShapeLocal "ICON"; //_MShape; 
_mrkr setMarkerSizeLocal _MSize; 
_mrkr setMarkerTextLocal  _MText; 
_mrkr setMarkerDirLocal _MDir; 
_mrkr setMarkerColor _Mcolor;
_mrkr setMarkerAlpha _MAlpha; 
} forEach _allMarkNames ; 





//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


private _GetVariableStatic = profileNamespace getVariable _ObjectDataName;

_allVehNames = keys _GetVariableStatic;

{
    _StcAtts = _GetVariableStatic get _x;
    _posASL = _StcAtts get "posASL";
    _Type = _StcAtts get "type";
    _DirUp = _StcAtts get "vectorDirAndUp";
    
    _NewVeh = createVehicle [_Type, [0,0, (500 + random 2000)], [], 0, "CAN_COLLIDE"];
    _NewVeh setVectorDirAndUp _DirUp;
    _NewVeh setPosASL _posASL;

} forEach _allVehNames;




//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
_Group = createGroup West ; 
for "_x" from 0 to _CrewSelCnt do { _unit = _Group createunit [_crewType,[0,0,0], [], 0, "CAN_COLLIDE"]; }; 
{_x moveInAny _NewVeh} foreach units _Group;  
	{ [_x] JoinSilent _Group } foreach units _Group;  

} forEach _allVehNames ; 

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Load garrison sizes and initialize garrisons for saved objectives
private _garrisonLoadResult = FLO_Garrison_Manager call ["loadGarrisonSizes", []]; 
if (_garrisonLoadResult) then {
    [[west,"HQ"], "Garrison states loaded successfully..."] remoteExec ["sideChat", 0];
} else {
    [[west,"HQ"], "No saved garrison states found"] remoteExec ["sideChat", 0];
};

// Load FOB and OP marker references
private _structureMarkerName = _missionTag + "_StructureMarkers";
private _structureMarkerHash = profileNamespace getVariable [_structureMarkerName, createHashMap];

if (count _structureMarkerHash > 0) then {
    // Process FOB buildings
    private _fobBuildings = nearestObjects [Centerposition, [_fobTypeClass, "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F"], 40000];
    {
        if (!isNil "_x" && {alive _x}) then {
            private _objectPos = getPosASL _x;
            private _objectPosString = format ["%1_%2_%3", _objectPos#0, _objectPos#1, _objectPos#2];
            private _markerData = _structureMarkerHash getOrDefault [_objectPosString, []];
            
            if (count _markerData > 0) then {
                private _markerName = _markerData#0;
                private _type = _markerData#1;
                
                if (_type == "FOB") then {
                    _x setVariable ["fobMarkerName", _markerName, true];
                    _x setVariable ["FLO_FOB_Initialized", true, true];
                    ["Mission", 3, format["Restored FOB marker reference %1 for building at %2", _markerName, _objectPos]] call FLO_fnc_log;
                };
            };
        };
    } forEach _fobBuildings;
    
    // Process OP buildings
    private _opBuildings = nearestObjects [Centerposition, [_opTypeClass], 40000];
    {
        if (!isNil "_x" && {alive _x}) then {
            private _objectPos = getPosASL _x;
            private _objectPosString = format ["%1_%2_%3", _objectPos#0, _objectPos#1, _objectPos#2];
            private _markerData = _structureMarkerHash getOrDefault [_objectPosString, []];
            
            if (count _markerData > 0) then {
                private _markerName = _markerData#0;
                private _type = _markerData#1;
                
                if (_type == "OP") then {
                    _x setVariable ["opMarkerName", _markerName, true];
                    _x setVariable ["FLO_OP_Initialized", true, true];
                    ["Mission", 3, format["Restored OP marker reference %1 for building at %2", _markerName, _objectPos]] call FLO_fnc_log;
                };
            };
        };
    } forEach _opBuildings;
    
    [[west,"HQ"], format["Restored %1 FOB/OP marker references", count _structureMarkerHash]] remoteExec ["sideChat", 0];
} else {
    ["Mission", 2, "No FOB/OP marker references found to restore"] call FLO_fnc_log;
};

MissionLoadedLitterally = true ;
publicVariable "MissionLoadedLitterally";


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

