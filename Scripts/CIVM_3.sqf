_Chance = selectRandom [1, 2, 3]; 

_nearRoad = selectRandom ( (getpos player) nearRoads 500 ) ; 


_mrker = createMarkerLocal [str getpos _nearRoad, getpos _nearRoad]; 
_mrker setMarkerType "hd_warning";
_mrker setMarkerColor "colorCivilian";
_mrker setMarkerText "Clear Minefield"; 
_mrker setMarkerSize [0.6, 0.6]; 

sleep 3;

openMap true;
 [markerSize _mrker, markerPos _mrker, 1] call BIS_fnc_zoomOnArea;

sleep 5;

["showNotification", ["CIVILIAN MISSION", "Clear Minefield - Disarm Every Mine in the Area", "info"]] call FLO_fnc_intelSystem;


_V = createVehicle [ VP,getpos _nearRoad, [], 4, "NONE"]; 
_nextRoad = ( roadsConnectedTo _nearRoad ) select 0;
_dir = _nearRoad getDir _nextRoad;
_V setDir _dir;
_V setdamage 0.7;


_Mine = selectRandom [ 
"APERSMine", 
"APERSBoundingMine"
 ]; 
_mine = createMine [_Mine,  (getMarkerpos _mrker), [], (0 + (random 50))];

_Mine = selectRandom [ 
"APERSMine", 
"APERSBoundingMine"
 ]; 
_mine = createMine [_Mine,  (getMarkerpos _mrker), [], (0 + (random 50))];

_Mine = selectRandom [ 
"APERSMine", 
"APERSBoundingMine"
 ]; 
_mine = createMine [_Mine,  (getMarkerpos _mrker), [], (0 + (random 50))];

_Mine = selectRandom [ 
"APERSMine", 
"APERSBoundingMine"
 ]; 
_mine = createMine [_Mine,  (getMarkerpos _mrker), [], (0 + (random 50))];

_Mine = selectRandom [ 
"APERSMine", 
"APERSBoundingMine"
 ]; 
_mine = createMine [_Mine,  (getMarkerpos _mrker), [], (0 + (random 50))];

_Mine = selectRandom [ 
"APERSMine", 
"APERSBoundingMine"
 ]; 
_mine = createMine [_Mine,  (getMarkerpos _mrker), [], (0 + (random 50))];



//////////////////Trigger////////////////////////////////////////////////////////////////////////////////////////////////////////////

_TFOBA = createTrigger ["EmptyDetector", (getMarkerpos _mrker)];  
_TFOBA setTriggerArea [20, 20, 0, false, 50];  
_TFOBA setTriggerInterval 2;  
_TFOBA setTriggerActivation ["ANYPLAYER", "PRESENT", false];  
_TFOBA setTriggerStatements [  
"count (allMines select {position _x inArea thisTrigger}) == 0",  
"
_MMarks = allMapMarkers select { markerText _x == 'Clear Minefield'};
_M = [_MMarks,  thisTrigger] call BIS_fnc_nearestPosition;
deleteMarker _M ; 

HCIV = 0;

['ScoreAdded', ['Minefield Cleared', 00]] call BIS_fnc_showNotification;  

[] execVM 'Scripts\ReputationPlus.sqf';
[] execVM 'Scripts\ReputationPlus.sqf';
[] execVM 'Scripts\ReputationPlus.sqf';


 execVM 'Scripts\Civ_Relations.sqf';

", ""];




