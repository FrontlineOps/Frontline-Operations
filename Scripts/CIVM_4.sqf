private _NearRoadBig= player nearRoads 700  ; 
private _NearRoadSml= player nearRoads 100  ; 
private _NearRoads = _NearRoadBig - _NearRoadSml ;
private _CeckLoc = selectRandom _NearRoads ;

private _mrker = createMarkerLocal [str getpos _CeckLoc, getpos _CeckLoc]; 
_mrker setMarkerTypeLocal "hd_warning";
_mrker setMarkerColorLocal "colorCivilian";
_mrker setMarkerTextLocal "Create Checkpooint"; 
_mrker setMarkerSize [0.6, 0.6]; 

sleep 3;

openMap true ; 
[markerSize _mrker, markerPos _mrker, 1] call BIS_fnc_zoomOnArea;

sleep 5;

[parseText "<t color='#1AA3FF' font='PuristaBold' align = 'right' shadow = '1' size='2.5'>Mission : Create Roadblock</t><br /><t  align = 'right' shadow = '1' size='2'>_ Create 1x Observation Post</t><br /><t  align = 'right' shadow = '1' size='2'>_ Create 2x Sandbag Bunkers</t>", [0, 0.5, 1, 1], nil, 5, 1.7, 0] remoteExec ["BIS_fnc_textTiles", 0];

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

private _TFOBA = createTrigger ["EmptyDetector", (getMarkerpos _mrker)];  
_TFOBA setTriggerArea [100, 100, 0, false, 100];  
_TFOBA setTriggerInterval 2;  
_TFOBA setTriggerActivation ["ANYPLAYER", "PRESENT", false];  
_TFOBA setTriggerStatements [  
"(count (allMapMarkers select {getMarkerPos _x inArea thisTrigger && markerType _x == 'b_installation' && markerColor _x == 'ColorYellow'}) > 0) && (count (nearestObjects [ thisTrigger, ['Land_Cargo_House_V1_F', 'Land_Cargo_House_V3_F'], 100]) > 0) && (count (nearestObjects [ thisTrigger, ['Land_BagBunker_Small_F'], 100]) > 1)",  
"
private _MMarks = allMapMarkers select { markerText _x == 'Create Checkpooint'};
private _M = [_MMarks,  thisTrigger] call BIS_fnc_nearestPosition;
deleteMarker _M ; 

['ScoreAdded', ['CheckPoint Established', 00]] call BIS_fnc_showNotification;  

private _REPSCORE = FLO_ReputationHandle get ""value"";  

if (_REPSCORE < 7) then {
	
private _PRL = [thisTrigger getpos [(300 + (random 100)), (0 + (random 360))], East, [selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray]] call BIS_fnc_spawnGroup;
{ _x setUnitPos 'MIDDLE'; } forEach units _PRL ;
private _wp = _PRL addWaypoint [thisTrigger, 0];   
   _wp SetWaypointType 'MOVE';   

private _PRL = [thisTrigger getpos [(300 + (random 100)), (0 + (random 360))], East, [selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray]] call BIS_fnc_spawnGroup;
{ _x setUnitPos 'MIDDLE'; } forEach units _PRL ;
private _wp = _PRL addWaypoint [thisTrigger, 0];   
   _wp SetWaypointType 'MOVE';   

};	

[0.35, 'increase'] call FLO_fnc_adjustReputation;

execVM 'Scripts\Civ_Relations.sqf';

", ""];