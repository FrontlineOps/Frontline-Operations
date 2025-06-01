// Create supply crate near player
private _supplyBox = createVehicle ["IG_supplyCrate_F", position player, [], 5, "NONE"]; 
_supplyBox allowDamage false;

// Get current reputation score
private _reputationMarkers = allMapMarkers select {markerColor _x == "Color4_FD_F"};
private _reputationMarker = _reputationMarkers select 0;
private _reputationScore = parseNumber (markerText _reputationMarker);  

// Find a random building within 5km for delivery location
private _deliveryLocation = selectRandom nearestTerrainObjects [player, ["HOUSE", "CHURCH", "CHAPEL"], 5000];

// Create marker at delivery location
private _deliveryMarker = createMarkerLocal [str getPos _deliveryLocation, getPos _deliveryLocation]; 
_deliveryMarker setMarkerTypeLocal "hd_warning";
_deliveryMarker setMarkerColorLocal "colorCivilian";
_deliveryMarker setMarkerTextLocal "Deliver Resources"; 
_deliveryMarker setMarkerSize [0.6, 0.6]; 

sleep 3;

openMap true;
 [markerSize _mrker, markerPos _mrker, 1] call BIS_fnc_zoomOnArea;

sleep 5;

["STR_FLO_MISSIONCIV_TITLE", "STR_FLO_MISSIONCIV_DELIVER", "info"] call FLO_fnc_sendNotification;

//////GROUPS/////////////////////////////////////////////////////////////////////////////////////////


if (_REPSCORE < 7) then {

private _PRL = [getpos _nearCH, East, [selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray]] call BIS_fnc_spawnGroup;
[_PRL, getpos _nearCH, 200] call BIS_fnc_taskPatrol;

private _PRL = [getpos _nearCH, East,  [selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray, selectRandom GuerMenArray]] call BIS_fnc_spawnGroup;
[_PRL, getpos _nearCH, 100] call BIS_fnc_taskPatrol;

};

private _TFOBA = createTrigger ["EmptyDetector", getPos _nearCH];  
_TFOBA setTriggerArea [50, 50, 0, false, 100];  
_TFOBA setTriggerInterval 2;  
_TFOBA setTriggerActivation ["NONE", "PRESENT", false];  
_TFOBA setTriggerStatements [ 
"count (thisTrigger nearObjects ['IG_supplyCrate_F', 20]) > 0",  
"  
private _MMarks = allMapMarkers select { markerText _x == 'Deliver Resources'};
private _M = [_MMarks,  thisTrigger] call BIS_fnc_nearestPosition;
deleteMarker _M ; 

[0.35, 'increase'] call FLO_fnc_adjustReputation;

execVM 'Scripts\Civ_Relations.sqf';

", ""];