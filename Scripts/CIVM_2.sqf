

 _V = createVehicle [ "IG_supplyCrate_F", position player , [], 5, "NONE"]; 
 _V allowDammage false;
_mrkrs = allMapMarkers select {markerColor _x == "Color4_FD_F"};
_mrkr = _mrkrs select 0;
_REPSCORE = parseNumber (markerText _mrkr) ;  

_Chance = selectRandom [1, 2, 3]; 

_nearCH = selectRandom nearestTerrainObjects [player, ["HOUSE", "CHURCH", "CHAPEL"], 5000];

_mrker = createMarkerLocal [str getpos _nearCH, getpos _nearCH]; 
_mrker setMarkerType "hd_warning";
_mrker setMarkerColor "colorCivilian";
_mrker setMarkerText "Deliver Resources"; 
_mrker setMarkerSize [0.6, 0.6]; 

sleep 3;

openMap true;
 [markerSize _mrker, markerPos _mrker, 1] call BIS_fnc_zoomOnArea;

sleep 5;

["showNotification", ["CIVILIAN MISSION", "Deliver Resources - Transport the Cargo to the Destination", "info"]] call FLO_fnc_intelSystem;

//////GROUPS/////////////////////////////////////////////////////////////////////////////////////////


if (_REPSCORE < 7) then {

PRL = [getpos _nearCH, East, [selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray]] call BIS_fnc_spawnGroup;
[PRL, getpos _nearCH, 200] call BIS_fnc_taskPatrol;

PRL = [getpos _nearCH, East,  [selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray]] call BIS_fnc_spawnGroup;
[PRL, getpos _nearCH, 100] call BIS_fnc_taskPatrol;

};

_TFOBA = createTrigger ["EmptyDetector", getPos _nearCH];  
_TFOBA setTriggerArea [50, 50, 0, false, 100];  
_TFOBA setTriggerInterval 2;  
_TFOBA setTriggerActivation ["NONE", "PRESENT", false];  
_TFOBA setTriggerStatements [ 
"count (thisTrigger nearObjects ['IG_supplyCrate_F', 20]) > 0",  
"  
_MMarks = allMapMarkers select { markerText _x == 'Deliver Resources'};
_M = [_MMarks,  thisTrigger] call BIS_fnc_nearestPosition;
deleteMarker _M ; 

HCIV = 0;

[] execVM "Scripts\ReputationPlus.sqf";
[] execVM "Scripts\ReputationPlus.sqf";
[] execVM "Scripts\ReputationPlus.sqf";


} forEach _objectLocGreen; 

['ScoreAdded', ['Resources Delivered', 00]] call BIS_fnc_showNotification;  

execVM 'Scripts\Civ_Relations.sqf';

", ""];


