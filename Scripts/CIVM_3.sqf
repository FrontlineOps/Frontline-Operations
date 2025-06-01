private _nearRoad = selectRandom ( (getpos player) nearRoads 500 ) ; 

private _mrker = createMarkerLocal [str getpos _nearRoad, getpos _nearRoad]; 
_mrker setMarkerTypeLocal "hd_warning";
_mrker setMarkerColorLocal "colorCivilian";
_mrker setMarkerTextLocal "Clear Minefield"; 
_mrker setMarkerSize [0.6, 0.6]; 

sleep 3;

openMap true;
 [markerSize _mrker, markerPos _mrker, 1] call BIS_fnc_zoomOnArea;

sleep 5;

["STR_FLO_MISSIONCIV_TITLE", "STR_FLO_MISSIONCIV_MINE", "info"] call FLO_fnc_sendNotification;


private _V = createVehicle [ selectRandom CivVehArray, getpos _nearRoad, [], 4, "NONE"]; 
private _nextRoad = ( roadsConnectedTo _nearRoad ) select 0;
private _dir = _nearRoad getDir _nextRoad;
_V setDir _dir;
_V setdamage 0.7;


for "_i" from 1 to 6 do {
    private _MineType = selectRandom [ 
        "APERSMine", 
        "APERSBoundingMine"
    ]; 
    private _Mines = createMine [_MineType, (getMarkerpos _mrker), [], (0 + (random 50))];
};

//////////////////Trigger////////////////////////////////////////////////////////////////////////////////////////////////////////////

private _TFOBA = createTrigger ["EmptyDetector", (getMarkerpos _mrker)];  
_TFOBA setTriggerArea [20, 20, 0, false, 50];  
_TFOBA setTriggerInterval 2;  
_TFOBA setTriggerActivation ["ANYPLAYER", "PRESENT", false];  
_TFOBA setTriggerStatements [  
"count (allMines select {position _x inArea thisTrigger}) == 0",  
"
private _MMarks = allMapMarkers select { markerText _x == 'Clear Minefield'};
private _M = [_MMarks,  thisTrigger] call BIS_fnc_nearestPosition;
deleteMarker _M ; 

['ScoreAdded', ['Minefield Cleared', 00]] call BIS_fnc_showNotification;  

[0.35, 'increase'] call FLO_fnc_adjustReputation;

execVM 'Scripts\Civ_Relations.sqf';

", ""];




