sleep 2;
_INTL = allMapMarkers select { (markerAlpha _x == 0.001 or markerAlpha _x == 0) && markerColor _x == "colorOPFOR" && markerType _x == "o_antiair" && getMarkerPos _x distance player < 7000};              
{
_x setMarkerAlpha 1;
} forEach _INTL;

openMap true;
 [[7000, 7000], position player, 1.5] call BIS_fnc_zoomOnArea;
sleep 1;
["showNotification", ["+ NEW INTEL", "Satellite Intel Received", "intel"]] call FLO_fnc_intelSystem;

 
