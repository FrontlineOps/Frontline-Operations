// private _Centerposition = [worldSize / 2, worldsize / 2, 0];

// // Array to store all placed marker positions for distance checking
// FLO_MarkerPositions = [];

// // Minimum distance between markers (in meters)
// FLO_MinMarkerDistance = 100;

// // Array of marker types that don't need distance validation
// FLO_ExcludedMarkerTypes = ["o_installation", "n_installation", "o_inf", "o_service"];

// // Function to check if a position is too close to coastline
// FLO_fnc_isNearCoast = {
//     params ["_position", ["_checkDistance", 50]];
    
//     // Check points in cardinal directions around the position
//     private _isNearWater = false;
    
//     // Check in four directions
//     private _dirs = [0, 90, 180, 270];
//     {
//         private _checkPos = _position getPos [_checkDistance, _x];
//         if (surfaceIsWater _checkPos) exitWith {
//             _isNearWater = true;
//         };
//     } forEach _dirs;
    
//     _isNearWater
// };

// // Function to check if a position is too close to existing markers
// FLO_fnc_isPositionValid = {
//     params ["_position", ["_minDistance", FLO_MinMarkerDistance], ["_markerType", ""]];
    
//     // If marker type is in the excluded list, skip distance validation
//     if (_markerType in FLO_ExcludedMarkerTypes) exitWith {true};
    
//     private _isTooClose = false;
//     {
//         if (_position distance _x < _minDistance) exitWith {
//             _isTooClose = true;
//         };
//     } forEach FLO_MarkerPositions;
    
//     !_isTooClose
// };

// // Function to find a valid position near the original one
// FLO_fnc_findValidPosition = {
//     params ["_originalPos", ["_maxAttempts", 20], ["_searchRadius", 300], ["_coastalBuffer", 150], ["_markerType", ""]];
    
//     // Immediately return original position for excluded marker types - no position adjustment at all
//     if (_markerType in FLO_ExcludedMarkerTypes) exitWith {
//         _originalPos
//     };
    
//     private _validPos = _originalPos;
//     private _attempts = 0;
    
//     // If original position is already valid, not in water, and not near coast, return it
//     if ([_originalPos, FLO_MinMarkerDistance, _markerType] call FLO_fnc_isPositionValid && 
//         {!(surfaceIsWater _originalPos)} && 
//         {!([_originalPos, _coastalBuffer] call FLO_fnc_isNearCoast)}) exitWith {_originalPos};
    
//     // Try to find a valid position that's not in water and not near coast
//     while {_attempts < _maxAttempts} do {
//         // Fixed random calculation with proper number handling
//         private _randomOffsetX = (random (_searchRadius * 2)) - _searchRadius;
//         private _randomOffsetY = (random (_searchRadius * 2)) - _searchRadius;
        
//         private _randomPos = [
//             (_originalPos select 0) + _randomOffsetX,
//             (_originalPos select 1) + _randomOffsetY,
//             0
//         ];
        
//         // Check if position is valid (not too close to other markers) AND not in water AND not near coast
//         if ([_randomPos, FLO_MinMarkerDistance, _markerType] call FLO_fnc_isPositionValid && 
//             {!(surfaceIsWater _randomPos)} && 
//             {!([_randomPos, _coastalBuffer] call FLO_fnc_isNearCoast)}) exitWith {
//             _validPos = _randomPos;
//         };
        
//         _attempts = _attempts + 1;
//     };
    
//     // If we couldn't find a good position after all attempts, try BIS_fnc_findSafePos as a fallback
//     if (_validPos isEqualTo _originalPos && 
//         {surfaceIsWater _validPos || {[_validPos, _coastalBuffer] call FLO_fnc_isNearCoast}}) then {
        
//         // First try using a larger search radius
//         private _safePosParams = [_originalPos, _coastalBuffer, _searchRadius * 1.5, 5, 0, 0.4, 0];
//         private _safePos = _safePosParams call BIS_fnc_findSafePos;
        
//         // Only use the safe position if it's different from the original and not near coast
//         if (!(_safePos isEqualTo _originalPos) && {!([_safePos, _coastalBuffer] call FLO_fnc_isNearCoast)}) then {
//             _validPos = _safePos;
//         } else {
//             // Desperate fallback - just try to stay out of water, ignore coastal buffer
//             _safePosParams = [_originalPos, 0, _searchRadius * 2, 3, 0, 0.5, 0];
//             _safePos = _safePosParams call BIS_fnc_findSafePos;
            
//             if (!(_safePos isEqualTo _originalPos) && {!(surfaceIsWater _safePos)}) then {
//                 _validPos = _safePos;
//             };
//         };
//     };
    
//     _validPos
// };

// // Helper function to create markers with default parameters
// FLO_fnc_createMarkerWithDefaults = {
//     params ["_position", "_name", "_type", "_color", "_size", "_alpha", ["_useSafePos", true], ["_safeRadius", 100]];
 
//     // Find a safe position if requested (not in water)
//     private _finalPosition = _position;
    
//     // For excluded marker types, skip all position adjustments
//     if !(_type in FLO_ExcludedMarkerTypes) then {
//         if (_useSafePos) then {
//             _finalPosition = [_position, 0, _safeRadius, 3, 0, 0.5, 0, [], [_position, _position]] call BIS_fnc_findSafePos;
            
//             // If findSafePos returns the original position array, it failed to find a safe position
//             // In that case, we'll try with more relaxed parameters
//             if (_finalPosition isEqualTo [_position, _position]) then {
//                 _finalPosition = [_position, 0, _safeRadius * 2, 5, 0, 0.7, 0] call BIS_fnc_findSafePos;
//             };
//         };
        
//         // Check if the position is too close to existing markers - pass correct parameters
//         _finalPosition = [_finalPosition, 20, 300, 150, _type] call FLO_fnc_findValidPosition;
//     };
    
//     // Create the marker (local first for optimization)
//     private _markerName = _name + (str _position);
//     private _marker = createMarkerLocal [_markerName, _finalPosition];
//     _marker setMarkerTypeLocal _type;
//     _marker setMarkerColorLocal _color;
//     _marker setMarkerSizeLocal _size;
    
//     // Final global operation to broadcast the marker
//     _marker setMarkerAlpha _alpha;
    
//     // Add this marker's position to our tracking array
//     if !(_type in FLO_ExcludedMarkerTypes) then {
//         FLO_MarkerPositions pushBack _finalPosition;
//     };
    
//     _marker
// };

// // Helper function to calculate distribution count based on EnemyPrec
// FLO_fnc_calculateDistribution = {
//     params ["_objectArray", ["_divisionFactor", 1], ["_ensureMinimum", true]];
    
//     private _count = count _objectArray;
//     private _adjustedCount = round (_count / _divisionFactor);
//     private _finalCount = round (_adjustedCount / EnemyPrec);
    
//     if (_ensureMinimum && {_finalCount isEqualTo 0}) then {
//         _finalCount = 1;
//     };
    
//     _finalCount
// };

// // Helper function to get a subset of shuffled objects based on distribution
// FLO_fnc_getRandomSubset = {
//     params ["_objectArray", "_count"];
    
//     private _shuffled = _objectArray call BIS_fnc_arrayShuffle;
//     _shuffled select [0, _count]
// };

// // Helper function to create markers based on search for objects with variable or specific type
// FLO_fnc_createMarkersFromSearch = {
//     params [
//         "_searchPositions",          // Array of positions to search from
//         "_searchRadius",             // Radius to search around each position
//         "_variableName",             // Variable name to look for in objects
//         "_objectTypes",              // Array of object types to consider as alternatives
//         "_fallbackLocationType",     // Type of location to use as fallback
//         "_markerPrefix",             // Prefix for marker names
//         "_markerType",               // Type of marker to create
//         "_markerColor",              // Color of marker
//         "_markerSize",               // Size of marker
//         "_markerAlpha",              // Alpha (transparency) of marker
//         ["_useSafePos", true],       // Whether to use findSafePos for marker placement
//         ["_safeRadius", 100]         // Radius to search for a safe position
//     ];
    
//     {
//         private _targetObjects = nearestObjects [(getPos _x), [], _searchRadius] select {
//             !isNil {_x getVariable _variableName} || {typeOf _x in _objectTypes}
//         };
        
//         private _markerPosition = nil;
        
//         if (count _targetObjects > 0) then {
//             private _target = selectRandom _targetObjects;
//             _markerPosition = getPos _target;
//         } else {
//             private _fallbackLocation = selectRandom nearestLocations [getPos _x, [_fallbackLocationType], _searchRadius];
//             _markerPosition = locationPosition _fallbackLocation;
//         };
        
//         // Create the marker and get the final position it was placed at
//         private _marker = [_markerPosition, _markerPrefix, _markerType, _markerColor, _markerSize, _markerAlpha, _useSafePos, _safeRadius] call FLO_fnc_createMarkerWithDefaults;
//         private _finalMarkerPos = getMarkerPos _marker;
        
//         // For radio tower: create physical tower if none exists and it's a radio tower marker
//         // Create it at the FINAL marker position, not the original planned position
//         if (_variableName isEqualTo "RadioTower") then {
//             private _towerTypes = ["Land_TTowerBig_2_F", "Land_TTowerBig_1_F"];
//             private _newTower = createVehicle [selectRandom _towerTypes, _finalMarkerPos, [], 5, "NONE"];
//             _newTower setVectorUp [0,0,1];
//             _newTower setVariable ["RadioTower", true, true];
//         };
//     } forEach _searchPositions;
// };

// // Start of main script execution

// // Get central evacuation points for distribution calculations
// private _evacuationPoints = nearestObjects [_Centerposition, ["LocationEvacPoint_F"], 40000];
// private _evacuationPointCount = [_evacuationPoints, 1.5] call FLO_fnc_calculateDistribution;
// private _distributedEvacPoints = [_evacuationPoints, _evacuationPointCount] call FLO_fnc_getRandomSubset;

// // Create Radio Tower markers
// [
//     _distributedEvacPoints,
//     1500,
//     "RadioTower",
//     [],
//     "Mount",
//     "TowerMark",
//     "loc_Transmitter",
//     "colorOPFOR",
//     [1, 1],
//     1,
//     true,
//     150
// ] call FLO_fnc_createMarkersFromSearch;

// // Clear persistent data
// private _missionTag = missionName;
// _missionTag = [_missionTag] call BIS_fnc_filterString;

// private _markerTimeName = _missionTag + "_Time";
// private _markerDataName = _missionTag + "_markers";
// private _vehicleDataName = _missionTag + "_Vehicles";
// private _objectDataName = _missionTag + "_Objects";

// sleep 2;

// profileNamespace setVariable [_markerTimeName, nil];
// profileNamespace setVariable [_markerDataName, nil];
// profileNamespace setVariable [_vehicleDataName, nil];
// profileNamespace setVariable [_objectDataName, nil];

// // Get points for Factory/Resupply markers
// private _resupplyPoints = nearestObjects [_Centerposition, ["LocationEvacPoint_F", "LocationResupplyPoint_F"], 40000];
// private _resupplyPointCount = [_resupplyPoints, 1] call FLO_fnc_calculateDistribution;
// private _distributedResupplyPoints = [_resupplyPoints, _resupplyPointCount] call FLO_fnc_getRandomSubset;

// // Create Resupply Point markers
// [
//     _distributedResupplyPoints,
//     1500,
//     "ResupplyPoint",
//     ["LocationResupplyPoint_F"],
//     "Mount",
//     "FactMark",
//     "o_support",
//     "colorOPFOR",
//     [1.2, 1.2],
//     0.001,
//     true,
//     150
// ] call FLO_fnc_createMarkersFromSearch;

// // Get points for Outpost/FOB markers
// private _fobPoints = nearestObjects [_Centerposition, ["LocationEvacPoint_F", "LocationFOB_F"], 40000];
// private _fobPointCount = [_fobPoints, 1] call FLO_fnc_calculateDistribution;
// private _distributedFobPoints = [_fobPoints, _fobPointCount] call FLO_fnc_getRandomSubset;

// // Create FOB markers
// [
//     _distributedFobPoints,
//     1500,
//     "FOB",
//     ["LocationFOB_F"],
//     "Mount",
//     "OutpMark",
//     "o_support",
//     "colorOPFOR",
//     [1.2, 1.2],
//     0.001,
//     true,
//     150
// ] call FLO_fnc_createMarkersFromSearch;

// // Convert some outpost markers to different type
// sleep 5;

// private _outpostMarkers = allMapMarkers select {markerType _x isEqualTo "o_support"};
// private _selectedOutpostCount = [_outpostMarkers, 6] call FLO_fnc_calculateDistribution;
// private _selectedOutposts = [_outpostMarkers, _selectedOutpostCount] call FLO_fnc_getRandomSubset;

// { 
// _x setMarkerType "n_support";  
// _x setMarkerSize [1.4, 1.4];   
// _x setMarkerColor "colorOPFOR"; 
//     _x setMarkerAlpha 1;
// } forEach _selectedOutposts;

// // Base markers - use only LocationBase_F objects
// private _baseLocations = nearestObjects [_Centerposition, ["Logic", "LocationBase_F"], 40000] select {
//     typeOf _x isEqualTo "LocationBase_F" || !isNil {_x getVariable "BaseLocation"}
// };

// // Calculate number of base locations to use
// private _baseCount = [_baseLocations] call FLO_fnc_calculateDistribution;
// private _selectedBases = [_baseLocations, _baseCount] call FLO_fnc_getRandomSubset;

// {
//     [getPos _x, str(_x), "n_support", "colorOPFOR", [1.4, 1.4], 1, true, 200] call FLO_fnc_createMarkerWithDefaults;
// } forEach _selectedBases;

// // Capital cities - use logic markers with "Capital" variable or LocationCityCapital_F
// private _capitalLocations = nearestObjects [_Centerposition, ["Logic", "LocationCityCapital_F"], 40000] select {
//     typeOf _x isEqualTo "LocationCityCapital_F" || !isNil {_x getVariable "Capital"}
// };

// private _capitalCount = [_capitalLocations] call FLO_fnc_calculateDistribution;
// private _selectedCapitals = [_capitalLocations, _capitalCount] call FLO_fnc_getRandomSubset;

// {
//     [getPos _x, str(_x), "n_installation", "colorOPFOR", [1.4, 1.4], 1, true, 200] call FLO_fnc_createMarkerWithDefaults;
// } forEach _selectedCapitals;

// // Cities - use logic markers with "City" variable or LocationCity_F
// private _cityLocations = nearestObjects [_Centerposition, ["Logic", "LocationCity_F"], 40000] select {
//     typeOf _x isEqualTo "LocationCity_F" || !isNil {_x getVariable "City"}
// };

// private _cityCount = [_cityLocations] call FLO_fnc_calculateDistribution;
// private _selectedCities = [_cityLocations, _cityCount] call FLO_fnc_getRandomSubset;

// {
//     [getPos _x, str(_x), "o_installation", "colorOPFOR", [1.2, 1.2], 0.001, true, 200] call FLO_fnc_createMarkerWithDefaults;
// } forEach _selectedCities;

// // Get points for Barracks markers
// private _barracksPoints = nearestObjects [_Centerposition, ["LocationEvacPoint_F", "LocationCamp_F"], 40000];
// private _barracksPointCount = [_barracksPoints, 2] call FLO_fnc_calculateDistribution;
// private _distributedBarracksPoints = [_barracksPoints, _barracksPointCount] call FLO_fnc_getRandomSubset;

// // Create Barracks markers
// [
//     _distributedBarracksPoints,
//     1500,
//     "Barracks",
//     ["LocationCamp_F"],
//     "Mount",
//     "BarrackMark",
//     "loc_Ruin",
//     "colorOPFOR",
//     [1.2, 1.2],
//     0.001,
//     true,
//     150
// ] call FLO_fnc_createMarkersFromSearch;

// // Get points for Radar markers
// private _radarPoints = nearestObjects [_Centerposition, ["LocationEvacPoint_F"], 40000];
// private _radarPointCount = [_radarPoints, 2] call FLO_fnc_calculateDistribution;
// private _distributedRadarPoints = [_radarPoints, _radarPointCount] call FLO_fnc_getRandomSubset;

// // Create Radar markers
// [
//     _distributedRadarPoints,
//     1500,
//     "RadarS",
//     [],
//     "Mount",
//     "RadarSMark",
//     "loc_Power",
//     "colorOPFOR",
//     [1, 1],
//     0.001,
//     true,
//     150
// ] call FLO_fnc_createMarkersFromSearch;

// // Get points for Investigation markers
// private _investigationPoints = _evacuationPoints;
// private _investigationPointCount = [_investigationPoints, 1] call FLO_fnc_calculateDistribution;
// private _distributedInvestigationPoints = [_investigationPoints, _investigationPointCount] call FLO_fnc_getRandomSubset;

// // Create Investigation markers
// {
//     private _mount = selectRandom nearestLocations [(getPos _x), ["Mount"], 2000];
//     [locationPosition _mount, "InvesMark", "o_recon", "colorOPFOR", [0.8, 0.8], 0.001, true, 150] call FLO_fnc_createMarkerWithDefaults;
// } forEach _distributedInvestigationPoints;

// // Get points for Mine field markers
// private _minePoints = _evacuationPoints;
// private _minePointCount = [_minePoints, 1] call FLO_fnc_calculateDistribution;
// private _distributedMinePoints = [_minePoints, _minePointCount] call FLO_fnc_getRandomSubset;

// // Create Mine field markers
// {
//     private _pos = [getPos _x, 10, 2000, 3, 0, 1, 0] call BIS_fnc_findSafePos;
//     [_pos, "MineMark", "loc_mine", "colorOPFOR", [1, 1], 0.001, false] call FLO_fnc_createMarkerWithDefaults;
// } forEach _distributedMinePoints;

// sleep 3;

// // Remove mine markers near villages/cities
// private _mineMarkers = allMapMarkers select {markerType _x isEqualTo 'loc_mine'};
// {
//     if (count (nearestObjects [(getMarkerPos _x), ["LocationVillage_F", "LocationCity_F", "LocationCityCapital_F"], 400]) > 0) then {
//         deleteMarker _x;
//     };
// } forEach _mineMarkers;

// // Get points for Service markers
// private _servicePoints = _evacuationPoints;
// private _servicePointCount = [_servicePoints] call FLO_fnc_calculateDistribution;
// private _distributedServicePoints = [_servicePoints, _servicePointCount] call FLO_fnc_getRandomSubset;

// // Create Service markers on roads
// {
//     private _nearRoad = selectRandom ((getPos _x) nearRoads 2500);
//     if (!isNull _nearRoad) then {
//         [getPos _nearRoad, str(_nearRoad), "o_service", "colorOPFOR", [0.8, 0.8], 0.001, false] call FLO_fnc_createMarkerWithDefaults;
//     };
// } forEach _distributedServicePoints;

// // Infantry markers in villages
// private _villageLocations = nearestObjects [_Centerposition, ["Logic", "LocationVillage_F"], 40000] select {
//     typeOf _x isEqualTo "LocationVillage_F" || !isNil {_x getVariable "Village"}
// };

// {
//     private _randomPos = _x getPos [(0 + (random 100)), (0 + (random 360))];
//     private _markerName = "InsurVillMark" + (str _randomPos);
//     [getPos _x, _markerName, "o_inf", "colorOPFOR", [0.7, 0.7], 0.001, true, 100] call FLO_fnc_createMarkerWithDefaults;
// } forEach _villageLocations;

// // Get points for AA site markers
// private _aaPoints = _evacuationPoints;
// private _aaPointCount = [_aaPoints, 2] call FLO_fnc_calculateDistribution;
// private _distributedAAPoints = [_aaPoints, _aaPointCount] call FLO_fnc_getRandomSubset;

// // Create AA site markers
// [
//     _distributedAAPoints,
//     2000,
//     "AASite",
//     [],
//     "Mount",
//     "AAMark",
//     "o_antiair",
//     "colorOPFOR",
//     [1.2, 1.2],
//     0.001,
//     true,
//     150
// ] call FLO_fnc_createMarkersFromSearch;

// // Remove markers near the commander
// sleep 2;

// // Define all marker types to consider
// private _validMarkerTypes = [
//     "o_support", 
//     "n_support", 
//     "o_installation", 
//     "n_installation", 
//     "o_antiair", 
//     "o_armor", 
//     "o_service", 
//     "o_plane", 
//     "o_maint", 
//     "loc_mine", 
//     "loc_Power", 
//     "loc_Ruin", 
//     "mil_unknown", 
//     "mil_warning", 
//     "o_naval", 
//     "o_recon", 
//     "o_inf"
// ];

// private _allMarks = allMapMarkers select {markerType _x in _validMarkerTypes};

// private _commanderNearbyMarkers = _allMarks select {getPos TheCommander distance getMarkerPos _x < 2000};
// {
//     deleteMarker _x;
// } forEach _commanderNearbyMarkers;

// // Create respawn marker
// sleep 2;

// private _respawnMarkerName = "respawn_west" + (str (position player));
// private _respawnMarker = createMarker [_respawnMarkerName, (position player)];
// _respawnMarker setMarkerType "b_unknown";
// _respawnMarker setMarkerSize [0.6, 0.6];
// _respawnMarker setMarkerText "Respawn";
// _respawnMarker setMarkerAlpha 1;

[] call FLO_fnc_indexObjectives;

MarLOCC = 1;
publicVariable "MarLOCC";