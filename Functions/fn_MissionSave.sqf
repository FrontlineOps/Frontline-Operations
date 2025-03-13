if (!isServer) exitWith {};

["Mission", 3, "Saving Mission ..."] call FLO_fnc_log;

private _Centerposition = [worldSize / 2, worldsize / 2, 0];

private _missionTag = missionName;
_missionTag = [_missionTag] call BIS_fnc_filterString;

private _MarkerTimeName = _missionTag + "_Time";
private _MarkerDataName = _missionTag + "_markers";
private _VehicleDataName = _missionTag + "_Vehicles";
private _ObjectDataName = _missionTag + "_Objects";
private _structureMarkerName = _missionTag + "_StructureMarkers";
private _missionStructureTypes = _missionTag + "_StructureTypes";

profileNamespace setVariable [_MarkerTimeName, nil];
profileNamespace setVariable [_MarkerDataName, nil];
profileNamespace setVariable [_VehicleDataName, nil];
profileNamespace setVariable [_ObjectDataName, nil];
profileNamespace setVariable [_structureMarkerName, nil];
profileNamespace setVariable [_missionStructureTypes, nil];

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

private _spheres = nearestObjects [_Centerposition, ["Sign_Sphere10cm_F"], 40000];
if (!isNil "_spheres" && {count _spheres > 0}) then {
    {
        if (!isNull _x) then {
            deleteVehicle _x;
        };
    } forEach _spheres;
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

private _GroupMarks = allMapMarkers select {markerType _x isEqualTo "b_unknown" && markerColor _x isEqualTo "Color6_FD_F"};
{deleteMarker _x;} forEach _GroupMarks;

// Define array of valid unit types
private _validUnitTypes = [
    F_Diver_Eod, F_Diver_Rfl, F_Diver_TL, 
    F_Recon_Eod, F_Recon_Med, F_Recon_Eng, F_Recon_Mg, F_Recon_AT, F_Recon_Mrk, F_Recon_Snp, F_Recon_Sct, F_Recon_TL,
    F_Assault_AT, F_Assault_Amm, F_Assault_Mg, F_Assault_SL, F_Assault_TL, F_Assault_Eng, F_Assault_Eod, F_Assault_Mrk, F_Assault_Uav, F_Assault_Med,
    F_Officer
];

private _SaveGroups = allGroups select {
    if (count units _x > 0) then {
        private _firstUnit = units _x select 0;
        if (!isNull _firstUnit) then {
            (typeOf _firstUnit) in _validUnitTypes && 
            !captive _firstUnit && 
            side _firstUnit isEqualTo west && 
            alive _firstUnit
        };
    };
};

{
	if (!isNull _x) then {
    	private _group = _x;
    	private _units = units _group;
    	private _UnitsArray = [];
    
    	// Build array of unit types
    	{
    	    private _unitClass = typeOf _x;
    	    _UnitsArray pushBack _unitClass;
    	} forEach _units;
    
    	// Remove first unit if it's a player
    	if (isPlayer (_units select 0)) then {
    	    _UnitsArray deleteAt 0;
    	};
    
    	// Create marker for the group
    	private _mrkr = createMarkerLocal [str(_units select 0), getPos (_units select 0)];
    	_mrkr setMarkerTypeLocal "b_unknown";
    	_mrkr setMarkerSizeLocal [0.5, 0.5];
    	_mrkr setMarkerColorLocal "Color6_FD_F";
    	_mrkr setMarkerAlphaLocal 0.006;
    	_mrkr setMarkerText str _UnitsArray;
	};
} forEach _SaveGroups;
	
["Mission", 3, "Groups Saved Successfully ..."] call FLO_fnc_log;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

profileNamespace setVariable [_MarkerTimeName, date];

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

private _VehicleDataName = _missionTag + "_Vehicles";

private _VehicleDataHash = createHashMap;
private _vehicles = [];

private _allFOBMarks = allMapMarkers select {markerType _x isEqualTo "b_installation"};
{
    private _markerPos = getMarkerPos _x;
    private _nearbyVehicles = nearestObjects [_markerPos, ["Air", "Ship", "LandVehicle"], 250];
    private _aliveVehicles = _nearbyVehicles select {alive _x};
    _vehicles append _aliveVehicles;
} forEach _allFOBMarks;

private _vehiclesToSave = _vehicles select {alive _x};
private _finalVehiclesToSave = _vehiclesToSave arrayIntersect _vehiclesToSave;

{
    private _vehicle = _x;
    private _vehicleDataHashEach = createHashMap;
    private _vehicleNameStr = str getPosATL _vehicle + "_Veh";
    _vehicle setVehicleVarName _vehicleNameStr;
    
    private _vehicleName = vehicleVarName _vehicle;
    
    _vehicleDataHashEach set ["type", typeOf _vehicle];
    _vehicleDataHashEach set ["posATL", getPosATL _vehicle];
    _vehicleDataHashEach set ["vectorDirAndUp", [vectorDir _vehicle, vectorUp _vehicle]];
    
    _VehicleDataHash set [_vehicleName, _vehicleDataHashEach];
} forEach _finalVehiclesToSave;

profileNamespace setVariable [_VehicleDataName, _VehicleDataHash];

["Mission", 3, "Vehicles Saved Successfully ..."] call FLO_fnc_log;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

private _ObjectDataName = _missionTag + "_Objects";

private _ObjectDataHash = createHashMap;

private _SaveStatics = [];

private _allFOBMarks = allMapMarkers select {markerType _x isEqualTo "b_installation" && markerColor _x isEqualTo "ColorYellow" && markerText _x isEqualTo "FOB"};  
{
	private _markerPos = getMarkerPos _x;
	private _staticsNew = nearestobjects [_markerPos, ["Static", "Thing"], 300];
	private _staticsNewAlive = _staticsNew select {alive _x};
	private _staticsTerrain = nearestTerrainObjects [_markerPos, [], 300];
	private _staticsSaving = _staticsNewAlive - _staticsTerrain;
	_SaveStatics append _staticsSaving;	
} forEach _allFOBMarks;

private _allNonFOBMarks = allMapMarkers select {
	markerType _x isEqualTo "b_installation" && 
	(markerColor _x isEqualTo "ColorYellow" || markerColor _x isEqualTo "colorBLUFOR" || markerColor _x isEqualTo "ColorWEST") && 
	markerText _x != "FOB"
};  
{
	private _markerPos = getMarkerPos _x;
	private _staticsNew = nearestobjects [_markerPos, ["Static", "Thing"], 200];
	private _staticsNewAlive = _staticsNew select {alive _x};
	private _staticsTerrain = nearestTerrainObjects [_markerPos, [], 200];
	private _staticsSaving = _staticsNewAlive - _staticsTerrain;
	_SaveStatics append _staticsSaving;	
} forEach _allNonFOBMarks;

private _towerTypes = ["Land_TTowerBig_2_F", "Land_TTowerBig_1_F"];
private _staticsNew = nearestobjects [_Centerposition, _towerTypes, 40000];
private _staticsNewAlive = _staticsNew select {alive _x};
private _staticsTerrain = nearestTerrainObjects [_Centerposition, _towerTypes, 40000];
private _staticsSaving = _staticsNewAlive - _staticsTerrain;
{
	_SaveStatics pushBack _x;	
} forEach _staticsSaving;

private _FinalSaving = _SaveStatics arrayIntersect _SaveStatics ;

{
private _ObjectDataHashEach = createHashMap;
private _ObjectNameStr = str getPosASL _x + "_Obj";
_x setVehicleVarName _ObjectNameStr;

private _ObjectName = vehicleVarName _x ;

   _ObjectDataHashEach set ["type", typeOf _x]  ;
   _ObjectDataHashEach set ["posASL",getPosASL _x]  ;
   _ObjectDataHashEach set ["vectorDirAndUp",[vectorDir _x,vectorUp _x]]  ;

   _ObjectDataHash set [_ObjectName, _ObjectDataHashEach];

} forEach _FinalSaving ;

profileNamespace setVariable [_ObjectDataName, _ObjectDataHash];

["Mission", 3, "Structures Saved Successfully ..."] call FLO_fnc_log;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

private _MarkerDataName = _missionTag + "_markers";

private _MarkerDataHash = createHashMap;

// Define marker types to save by category
private _opforMarkerTypes = [
    "loc_Transmitter", "o_support", "n_support", "o_installation", "n_installation",
    "loc_Ruin", "loc_Power", "loc_mine", "o_recon", "o_armor", "o_inf", 
    "o_service", "o_plane", "o_antiair"
];

private _hdMarkerTypes = [
    "hd_warning", "hd_unknown", "hd_start", "hd_pickup", "hd_objective",
    "hd_join", "hd_flag", "hd_end", "hd_dot", "hd_destroy", "hd_arrow", "hd_ambush"
];

private _otherMarkerTypes = [
    "b_installation", "loc_SafetyZone", "White", "RedCrystal"
];

// Select markers to save
private _SaveMarks = allMapMarkers select {
    // OPFOR markers
    (markerColor _x isEqualTo "ColorOPFOR" && markerType _x in _opforMarkerTypes) || 
    // HD markers
    markerType _x in _hdMarkerTypes ||
    // Other marker types
    markerType _x in _otherMarkerTypes ||
    // Special cases
    (markerType _x isEqualTo "b_unknown" && markerColor _x isEqualTo "Color6_FD_F") ||
    (markerType _x isEqualTo "loc_Transmitter" && markerColor _x isEqualTo "colorBLUFOR")
};
		
{
	private _MarkerDataHashEach = createHashMap;
    private _markerColor = getMarkerColor _x;
    private _markerType = markerType _x;
    
    // If marker is b_installation and color is grey, change it to colorBLUFOR when saving
    if (_markerType isEqualTo "b_installation" && _markerColor isEqualTo "ColorGrey") then {
        _markerColor = "ColorWEST";
    };

	_MarkerDataHashEach set ["name",_x];
	_MarkerDataHashEach set ["alpha",markerAlpha _x];
	_MarkerDataHashEach set ["brush",markerBrush _x];
	_MarkerDataHashEach set ["color",_markerColor];
	_MarkerDataHashEach set ["dir",markerDir _x];
	_MarkerDataHashEach set ["pos",getMarkerPos _x];
	_MarkerDataHashEach set ["shape",markerShape _x];
	_MarkerDataHashEach set ["size",getMarkerSize _x];
	_MarkerDataHashEach set ["text",markerText _x];
	_MarkerDataHashEach set ["type",_markerType];

	_MarkerDataHash set [_x, _MarkerDataHashEach];

} forEach _SaveMarks;

profileNamespace setVariable [_MarkerDataName, _MarkerDataHash];

["Mission", 3, "BattleField Saved Successfully ..."] call FLO_fnc_log;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Save garrisons state before finalizing the mission save
private _garrisonSaveResult = FLO_Garrison_Manager call ["saveGarrisonSizes", []];
if !(_garrisonSaveResult) then {
    [[west,"HQ"], "Warning: Failed to save garrison states"] remoteExec ["sideChat", 0];
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Save building types for FOB and OP
// Had to add this because the mission load is pre-mission startup and the variables are not yet defined
private _fobTypeClass = if (!isNil "F_HQ_01") then {F_HQ_01};
private _opTypeClass = if (!isNil "F_OP_01") then {F_OP_01};
profileNamespace setVariable [_missionStructureTypes, [_fobTypeClass, _opTypeClass]];
["Mission", 3, format["Saved structure types: FOB = %1, OP = %2", _fobTypeClass, _opTypeClass]] call FLO_fnc_log;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Save FOB and OP marker references
private _structureMarkerHash = createHashMap;

// Find and save all FOB marker references
private _fobBuildings = nearestObjects [_Centerposition, [_fobTypeClass, "Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F"], 40000];
{
    if (!isNil "_x" && {alive _x} && {_x getVariable ["FLO_FOB_Initialized", false]}) then {
        private _markerName = _x getVariable ["fobMarkerName", ""];
        if (_markerName != "") then {
            private _objectPos = getPosASL _x;
            private _objectPosString = format ["%1_%2_%3", _objectPos#0, _objectPos#1, _objectPos#2];
            _structureMarkerHash set [_objectPosString, [_markerName, "FOB"]];
        };
    };
} forEach _fobBuildings;

// Find and save all OP marker references
private _opBuildings = nearestObjects [_Centerposition, [_opTypeClass], 40000];
{
    if (!isNil "_x" && {alive _x} && {_x getVariable ["FLO_OP_Initialized", false]}) then {
        private _markerName = _x getVariable ["opMarkerName", ""];
        if (_markerName != "") then {
            private _objectPos = getPosASL _x;
            private _objectPosString = format ["%1_%2_%3", _objectPos#0, _objectPos#1, _objectPos#2];
            _structureMarkerHash set [_objectPosString, [_markerName, "OP"]];
        };
    };
} forEach _opBuildings;

// Save the structure marker references
profileNamespace setVariable [_structureMarkerName, _structureMarkerHash];
["Mission", 3, format["Saved %1 FOB/OP marker references", count _structureMarkerHash]] call FLO_fnc_log;

saveProfileNamespace;

["Mission", 3, "Mission Saved !"] call FLO_fnc_log;