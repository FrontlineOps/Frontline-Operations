private _centerPosition = [worldSize / 2, worldsize / 2, 0];

// Helper function to create markers with default parameters
FLO_fnc_createMarkerWithDefaults = {
    params ["_position", "_name", "_type", "_color", "_size", "_alpha", ["_useSafePos", true], ["_safeRadius", 100]];
    
    // Find a safe position if requested
    private _finalPosition = _position;
    if (_useSafePos) then {
        _finalPosition = [_position, 0, _safeRadius, 3, 0, 0.5, 0, [], [_position, _position]] call BIS_fnc_findSafePos;
        
        // If findSafePos returns the original position array, it failed to find a safe position
        // In that case, we'll try with more relaxed parameters
        if (_finalPosition isEqualTo [_position, _position]) then {
            _finalPosition = [_position, 0, _safeRadius * 2, 5, 0, 0.7, 0] call BIS_fnc_findSafePos;
        };
    };
    
    private _markerName = _name + (str _position);
    private _marker = createMarker [_markerName, _finalPosition];
    _marker setMarkerType _type;
    _marker setMarkerColor _color;
    _marker setMarkerSize _size;
    _marker setMarkerAlpha _alpha;
    
    _marker
};

// Helper function to calculate distribution count based on EnemyPrec
FLO_fnc_calculateDistribution = {
    params ["_objectArray", ["_divisionFactor", 1], ["_ensureMinimum", true]];
    
    private _count = count _objectArray;
    private _adjustedCount = round (_count / _divisionFactor);
    private _finalCount = round (_adjustedCount / EnemyPrec);
    
    if (_ensureMinimum && {_finalCount == 0}) then {
        _finalCount = 1;
    };
    
    _finalCount
};

// Helper function to get a subset of shuffled objects based on distribution
FLO_fnc_getRandomSubset = {
    params ["_objectArray", "_count"];
    
    private _shuffled = _objectArray call BIS_fnc_arrayShuffle;
    _shuffled select [0, _count]
};

// Helper function to create markers based on search for objects with variable or specific type
FLO_fnc_createMarkersFromSearch = {
    params [
        "_searchPositions",          // Array of positions to search from
        "_searchRadius",             // Radius to search around each position
        "_variableName",             // Variable name to look for in objects
        "_objectTypes",              // Array of object types to consider as alternatives
        "_fallbackLocationType",     // Type of location to use as fallback
        "_markerPrefix",             // Prefix for marker names
        "_markerType",               // Type of marker to create
        "_markerColor",              // Color of marker
        "_markerSize",               // Size of marker
        "_markerAlpha",              // Alpha (transparency) of marker
        ["_useSafePos", true],       // Whether to use findSafePos for marker placement
        ["_safeRadius", 100]         // Radius to search for a safe position
    ];
    
    {
        private _targetObjects = nearestObjects [(getPos _x), [], _searchRadius] select {
            !isNil {_x getVariable _variableName} || {typeOf _x in _objectTypes}
        };
        
        if (count _targetObjects > 0) then {
            private _target = selectRandom _targetObjects;
            [getPos _target, _markerPrefix, _markerType, _markerColor, _markerSize, _markerAlpha, _useSafePos, _safeRadius] call FLO_fnc_createMarkerWithDefaults;
        } else {
            private _fallbackLocation = selectRandom nearestLocations [getPos _x, [_fallbackLocationType], _searchRadius];
            [locationPosition _fallbackLocation, _markerPrefix, _markerType, _markerColor, _markerSize, _markerAlpha, _useSafePos, _safeRadius] call FLO_fnc_createMarkerWithDefaults;
            
            // For radio tower: create physical tower if none exists and it's a radio tower marker
            if (_variableName == "RadioTower") then {
                private _towerTypes = ["Land_TTowerBig_2_F", "Land_TTowerBig_1_F"];
                private _newTower = createVehicle [selectRandom _towerTypes, (locationPosition _fallbackLocation), [], 5, "NONE"];
                _newTower setVectorUp [0,0,1];
                _newTower setVariable ["RadioTower", true, true];
            };
        };
    } forEach _searchPositions;
};

// Start of main script execution

// Get central evacuation points for distribution calculations
private _evacuationPoints = nearestObjects [_centerPosition, ["LocationEvacPoint_F"], 40000];
private _evacuationPointCount = [_evacuationPoints, 1.5] call FLO_fnc_calculateDistribution;
private _distributedEvacPoints = [_evacuationPoints, _evacuationPointCount] call FLO_fnc_getRandomSubset;

// Create Radio Tower markers
[
    _distributedEvacPoints,
    1500,
    "RadioTower",
    [],
    "Mount",
    "TowerMark",
    "loc_Transmitter",
    "colorOPFOR",
    [1, 1],
    1,
    true,
    150
] call FLO_fnc_createMarkersFromSearch;

// Clear persistent data
private _missionTag = missionName;
_missionTag = [_missionTag] call BIS_fnc_filterString;

private _markerTimeName = _missionTag + "_Time";
private _markerDataName = _missionTag + "_markers";
private _vehicleDataName = _missionTag + "_Vehicles";
private _objectDataName = _missionTag + "_Objects";

sleep 2;

profileNamespace setVariable [_markerTimeName, nil];
profileNamespace setVariable [_markerDataName, nil];
profileNamespace setVariable [_vehicleDataName, nil];
profileNamespace setVariable [_objectDataName, nil];

// Get points for Factory/Resupply markers
private _resupplyPoints = nearestObjects [_centerPosition, ["LocationEvacPoint_F", "LocationResupplyPoint_F"], 40000];
private _resupplyPointCount = [_resupplyPoints, 1] call FLO_fnc_calculateDistribution;
private _distributedResupplyPoints = [_resupplyPoints, _resupplyPointCount] call FLO_fnc_getRandomSubset;

// Create Resupply Point markers
[
    _distributedResupplyPoints,
    1500,
    "ResupplyPoint",
    ["LocationResupplyPoint_F"],
    "Mount",
    "FactMark",
    "o_support",
    "colorOPFOR",
    [1.2, 1.2],
    0.001,
    true,
    150
] call FLO_fnc_createMarkersFromSearch;

// Get points for Outpost/FOB markers
private _fobPoints = nearestObjects [_centerPosition, ["LocationEvacPoint_F", "LocationFOB_F"], 40000];
private _fobPointCount = [_fobPoints, 1] call FLO_fnc_calculateDistribution;
private _distributedFobPoints = [_fobPoints, _fobPointCount] call FLO_fnc_getRandomSubset;

// Create FOB markers
[
    _distributedFobPoints,
    1500,
    "FOB",
    ["LocationFOB_F"],
    "Mount",
    "OutpMark",
    "o_support",
    "colorOPFOR",
    [1.2, 1.2],
    0.001,
    true,
    150
] call FLO_fnc_createMarkersFromSearch;

// Convert some outpost markers to different type
sleep 5;

private _outpostMarkers = allMapMarkers select {markerType _x == "o_support"};
private _selectedOutpostCount = [_outpostMarkers, 6] call FLO_fnc_calculateDistribution;
private _selectedOutposts = [_outpostMarkers, _selectedOutpostCount] call FLO_fnc_getRandomSubset;

{ 
_x setMarkerType "n_support";  
_x setMarkerSize [1.4, 1.4];   
_x setMarkerColor "colorOPFOR"; 
    _x setMarkerAlpha 1;
} forEach _selectedOutposts;

// Base markers - use only LocationBase_F objects
private _baseLocations = nearestObjects [_centerPosition, ["Logic", "LocationBase_F"], 40000] select {
    typeOf _x == "LocationBase_F" || !isNil {_x getVariable "BaseLocation"}
};

// Calculate number of base locations to use
private _baseCount = [_baseLocations] call FLO_fnc_calculateDistribution;
private _selectedBases = [_baseLocations, _baseCount] call FLO_fnc_getRandomSubset;

{
    [getPos _x, str(_x), "n_support", "colorOPFOR", [1.4, 1.4], 1, true, 200] call FLO_fnc_createMarkerWithDefaults;
} forEach _selectedBases;

// Capital cities - use logic markers with "Capital" variable or LocationCityCapital_F
private _capitalLocations = nearestObjects [_centerPosition, ["Logic", "LocationCityCapital_F"], 40000] select {
    typeOf _x == "LocationCityCapital_F" || !isNil {_x getVariable "Capital"}
};

private _capitalCount = [_capitalLocations] call FLO_fnc_calculateDistribution;
private _selectedCapitals = [_capitalLocations, _capitalCount] call FLO_fnc_getRandomSubset;

{
    [getPos _x, str(_x), "n_installation", "colorOPFOR", [1.4, 1.4], 1, true, 200] call FLO_fnc_createMarkerWithDefaults;
} forEach _selectedCapitals;

// Cities - use logic markers with "City" variable or LocationCity_F
private _cityLocations = nearestObjects [_centerPosition, ["Logic", "LocationCity_F"], 40000] select {
    typeOf _x == "LocationCity_F" || !isNil {_x getVariable "City"}
};

private _cityCount = [_cityLocations] call FLO_fnc_calculateDistribution;
private _selectedCities = [_cityLocations, _cityCount] call FLO_fnc_getRandomSubset;

{
    [getPos _x, str(_x), "o_installation", "colorOPFOR", [1.2, 1.2], 0.001, true, 200] call FLO_fnc_createMarkerWithDefaults;
} forEach _selectedCities;

// Get points for Barracks markers
private _barracksPoints = nearestObjects [_centerPosition, ["LocationEvacPoint_F", "LocationCamp_F"], 40000];
private _barracksPointCount = [_barracksPoints, 2] call FLO_fnc_calculateDistribution;
private _distributedBarracksPoints = [_barracksPoints, _barracksPointCount] call FLO_fnc_getRandomSubset;

// Create Barracks markers
[
    _distributedBarracksPoints,
    1500,
    "Barracks",
    ["LocationCamp_F"],
    "Mount",
    "BarrackMark",
    "loc_Ruin",
    "colorOPFOR",
    [1.2, 1.2],
    0.001,
    true,
    150
] call FLO_fnc_createMarkersFromSearch;

// Get points for Radar markers
private _radarPoints = nearestObjects [_centerPosition, ["LocationEvacPoint_F"], 40000];
private _radarPointCount = [_radarPoints, 2] call FLO_fnc_calculateDistribution;
private _distributedRadarPoints = [_radarPoints, _radarPointCount] call FLO_fnc_getRandomSubset;

// Create Radar markers
[
    _distributedRadarPoints,
    1500,
    "RadarS",
    [],
    "Mount",
    "RadarSMark",
    "loc_Power",
    "colorOPFOR",
    [1, 1],
    0.001,
    true,
    150
] call FLO_fnc_createMarkersFromSearch;

// Get points for Investigation markers
private _investigationPoints = _evacuationPoints;
private _investigationPointCount = [_investigationPoints, 1] call FLO_fnc_calculateDistribution;
private _distributedInvestigationPoints = [_investigationPoints, _investigationPointCount] call FLO_fnc_getRandomSubset;

// Create Investigation markers
{
    private _mount = selectRandom nearestLocations [(getPos _x), ["Mount"], 2000];
    [locationPosition _mount, "InvesMark", "o_recon", "colorOPFOR", [0.8, 0.8], 0.001, true, 150] call FLO_fnc_createMarkerWithDefaults;
} forEach _distributedInvestigationPoints;

// Get points for Mine field markers
private _minePoints = _evacuationPoints;
private _minePointCount = [_minePoints, 1] call FLO_fnc_calculateDistribution;
private _distributedMinePoints = [_minePoints, _minePointCount] call FLO_fnc_getRandomSubset;

// Create Mine field markers
{
    private _pos = [getPos _x, 10, 2000, 3, 0, 1, 0] call BIS_fnc_findSafePos;
    [_pos, "MineMark", "loc_mine", "colorOPFOR", [1, 1], 0.001, false] call FLO_fnc_createMarkerWithDefaults;
} forEach _distributedMinePoints;

sleep 3;

// Remove mine markers near villages/cities
private _mineMarkers = allMapMarkers select {markerType _x == 'loc_mine'};
{
    if (count (nearestObjects [(getMarkerPos _x), ["LocationVillage_F", "LocationCity_F", "LocationCityCapital_F"], 400]) > 0) then {
        deleteMarker _x;
    };
} forEach _mineMarkers;

// Get points for Armor markers
private _armorPoints = _evacuationPoints;
private _armorPointCount = [_armorPoints, 2] call FLO_fnc_calculateDistribution;
private _distributedArmorPoints = [_armorPoints, _armorPointCount] call FLO_fnc_getRandomSubset;

// Create Armor markers on roads
{
    private _nearRoad = selectRandom ((getPos _x) nearRoads 3500);
    if (!isNull _nearRoad) then {
        [getPos _nearRoad, "ArmorMark", "o_armor", "colorOPFOR", [1.2, 1.2], 0.001, true, 100] call FLO_fnc_createMarkerWithDefaults;
    };
} forEach _distributedArmorPoints;

// Additional armor markers from logic objects with "ArmorPosition" variable or sideOPFOR_F
private _armorLogicMarkers = nearestObjects [_centerPosition, ["Logic", "sideOPFOR_F"], 40000] select {
    !isNil {_x getVariable "ArmorPosition"} || typeOf _x == "sideOPFOR_F"
};

if (count _armorLogicMarkers > 0) then {
    private _logicArmorCount = [_armorLogicMarkers] call FLO_fnc_calculateDistribution;
    private _selectedArmorLogic = [_armorLogicMarkers, _logicArmorCount] call FLO_fnc_getRandomSubset;
    
    {
        [getPos _x, "ArmorMark", "o_armor", "colorOPFOR", [1.2, 1.2], 0.001, true, 150] call FLO_fnc_createMarkerWithDefaults;
    } forEach _selectedArmorLogic;
};

// Get points for Service markers
private _servicePoints = _evacuationPoints;
private _servicePointCount = [_servicePoints] call FLO_fnc_calculateDistribution;
private _distributedServicePoints = [_servicePoints, _servicePointCount] call FLO_fnc_getRandomSubset;

// Create Service markers on roads
{
    private _nearRoad = selectRandom ((getPos _x) nearRoads 2500);
    if (!isNull _nearRoad) then {
        [getPos _nearRoad, str(_nearRoad), "o_service", "colorOPFOR", [0.8, 0.8], 0.001, false] call FLO_fnc_createMarkerWithDefaults;
    };
} forEach _distributedServicePoints;

// Infantry markers in villages
private _villageLocations = nearestObjects [_centerPosition, ["Logic", "LocationVillage_F"], 40000] select {
    typeOf _x == "LocationVillage_F" || !isNil {_x getVariable "Village"}
};

{
    private _randomPos = _x getPos [(0 + (random 100)), (0 + (random 360))];
    private _markerName = "InsurVillMark" + (str _randomPos);
    [getPos _x, _markerName, "o_inf", "colorOPFOR", [0.7, 0.7], 0.001, true, 100] call FLO_fnc_createMarkerWithDefaults;
} forEach _villageLocations;

// Get points for AA site markers
private _aaPoints = _evacuationPoints;
private _aaPointCount = [_aaPoints, 2] call FLO_fnc_calculateDistribution;
private _distributedAAPoints = [_aaPoints, _aaPointCount] call FLO_fnc_getRandomSubset;

// Create AA site markers
[
    _distributedAAPoints,
    2000,
    "AASite",
    [],
    "Mount",
    "AAMark",
    "o_antiair",
    "colorOPFOR",
    [1.2, 1.2],
    0.001,
    true,
    150
] call FLO_fnc_createMarkersFromSearch;

// Get points for Aircraft markers
private _aircraftPoints = _evacuationPoints;
private _aircraftPointCount = [_aircraftPoints, 2] call FLO_fnc_calculateDistribution;
private _distributedAircraftPoints = [_aircraftPoints, _aircraftPointCount] call FLO_fnc_getRandomSubset;

// Create Aircraft markers
{
    private _randomPos = _x getPos [(0 + (random 300)), (0 + (random 350))];
    private _markName = "marker" + (str(_forEachIndex + 1));
    [_randomPos, _markName, "o_plane", "colorOPFOR", [1, 1], 0.001, true, 200] call FLO_fnc_createMarkerWithDefaults;
} forEach _distributedAircraftPoints;

// Remove markers near the commander
sleep 2;

private _allMarks = allMapMarkers select {
    markerType _x == "o_support" || 
    markerType _x == "n_support" || 
    markerType _x == "o_installation" || 
    markerType _x == "n_installation" || 
    markerType _x == "o_antiair" || 
    markerType _x == "o_armor" || 
    markerType _x == "o_service" || 
    markerType _x == "o_plane" || 
    markerType _x == "o_maint" || 
    markerType _x == "loc_mine" || 
    markerType _x == "loc_Power" || 
    markerType _x == "loc_Ruin" || 
    markerType _x == "mil_unknown" || 
    markerType _x == "mil_warning" || 
    markerType _x == "o_naval" || 
    markerType _x == "o_recon" || 
    markerType _x == "o_inf"
};

private _commanderNearbyMarkers = _allMarks select {getPos TheCommander distance getMarkerPos _x < 2000};
{
    deleteMarker _x;
} forEach _commanderNearbyMarkers;

// Create respawn marker
sleep 2;

private _respawnMarkerName = "respawn_west" + (str (position player));
private _respawnMarker = createMarker [_respawnMarkerName, (position player)];
_respawnMarker setMarkerType "b_unknown";
_respawnMarker setMarkerSize [0.6, 0.6];
_respawnMarker setMarkerText "Respawn";
_respawnMarker setMarkerAlpha 1;

MarLOCC = 1;
publicVariable "MarLOCC";


