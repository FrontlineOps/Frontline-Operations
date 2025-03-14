
_TWR = _this select 0 ;

_allTWRMarks = allMapMarkers select {markerType _x == "loc_Transmitter"};  
_NearTWRMark = [_allTWRMarks,  getPos _TWR] call BIS_fnc_nearestPosition ;
_NearTWRMark setMarkerColor "colorBLUFOR";


{  
_radius = 50 + (random 250) ;
_mrkr = createMarker [str(_x),getpos _x]; 
_mrkr setMarkerType "Unknown";
_mrkr setMarkerColor "colorOPFOR";
_mrkr setMarkerBrush "FDiagonal";  
_mrkr setMarkerShape "RECTANGLE";	
_mrkr setMarkerSize [_radius, _radius];
_mrkr setMarkerAlpha (0.1 + (random 0.4));
} foreach (allUnits select {side _x == east && getposasl _x distance position _TWR <= 3500}); 

openMap true;
 [[7000, 7000], position player, 1.5] call BIS_fnc_zoomOnArea;


