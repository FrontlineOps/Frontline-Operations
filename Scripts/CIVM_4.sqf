




_NearRoadBig= player nearRoads 700  ; 
_NearRoadSml= player nearRoads 100  ; 
_NearRoads = _NearRoadBig - _NearRoadSml ;
_CeckLoc = selectRandom _NearRoads ;

_mrker = createMarkerLocal [str getpos _CeckLoc, getpos _CeckLoc]; 
_mrker setMarkerType "hd_warning";
_mrker setMarkerColor "colorCivilian";
_mrker setMarkerText "Create Checkpooint"; 
_mrker setMarkerSize [0.6, 0.6]; 

sleep 3;

openMap true ; 
 [markerSize _mrker, markerPos _mrker, 1] call BIS_fnc_zoomOnArea;

sleep 5;

[parseText "<t color='#1AA3FF' font='PuristaBold' align = 'right' shadow = '1' size='2.5'>Mission : Create Roadblock</t><br /><t  align = 'right' shadow = '1' size='2'>_ Create 1x Observation Post</t><br /><t  align = 'right' shadow = '1' size='2'>_ Create 2x Sandbag Bunkers</t>", [0, 0.5, 1, 1], nil, 5, 1.7, 0] remoteExec ["BIS_fnc_textTiles", 0];

//////////////////Trigger/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////









////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

_TFOBA = createTrigger ["EmptyDetector", (getMarkerpos _mrker)];  
_TFOBA setTriggerArea [100, 100, 0, false, 100];  
_TFOBA setTriggerInterval 2;  
_TFOBA setTriggerActivation ["ANYPLAYER", "PRESENT", false];  
_TFOBA setTriggerStatements [  
"(count (allMapMarkers select {getMarkerPos _x inArea thisTrigger && markerType _x == 'b_installation' && markerColor _x == 'ColorYellow'}) > 0) && (count (nearestObjects [ thisTrigger, ['Land_Cargo_House_V1_F', 'Land_Cargo_House_V3_F'], 100]) > 0) && (count (nearestObjects [ thisTrigger, ['Land_BagBunker_Small_F'], 100]) > 1)",  
"
_MMarks = allMapMarkers select { markerText _x == 'Create Checkpooint'};
_M = [_MMarks,  thisTrigger] call BIS_fnc_nearestPosition;
deleteMarker _M ; 

HCIV = 0;

['ScoreAdded', ['CheckPoint Established', 00]] call BIS_fnc_showNotification;  

_mrkrs = allMapMarkers select {markerColor _x == 'Color4_FD_F'};
_mrkr = _mrkrs select 0;
_REPSCORE = parseNumber (markerText _mrkr) ;  

if (_REPSCORE < 7) then {
	
_PRL = [thisTrigger getpos [(300 + (random 100)), (0 + (random 360))], East, [selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray]] call BIS_fnc_spawnGroup;
{ _x setUnitPos 'MIDDLE'; } forEach units _PRL ;
 _wp = _PRL addWaypoint [thisTrigger, 0];   
   _wp SetWaypointType 'MOVE';   

_PRL = [thisTrigger getpos [(300 + (random 100)), (0 + (random 360))], East, [selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray]] call BIS_fnc_spawnGroup;
{ _x setUnitPos 'MIDDLE'; } forEach units _PRL ;
 _wp = _PRL addWaypoint [thisTrigger, 0];   
   _wp SetWaypointType 'MOVE';   

};	

[] execVM 'Scripts\ReputationPlus.sqf';
[] execVM 'Scripts\ReputationPlus.sqf';
[] execVM 'Scripts\ReputationPlus.sqf';


 execVM 'Scripts\Civ_Relations.sqf';


	
", ""];




