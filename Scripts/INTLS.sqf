sleep 2;

// Find all hidden OPFOR anti-air markers within 7000m of player
private _revealedMarkers = allMapMarkers select { 
    (markerAlpha _x == 0.001 or markerAlpha _x == 0) && 
    markerColor _x == "colorOPFOR" && 
    markerType _x == "o_antiair" && 
    getMarkerPos _x distance player < 7000
};

// Make all found markers visible
{
    _x setMarkerAlpha 1;
} forEach _revealedMarkers;

// Open map and zoom to player's position
openMap true;
[[7000, 7000], position player, 1.5] call BIS_fnc_zoomOnArea;
sleep 1;
["STR_FLO_INTEL_TITLE", "STR_FLO_INTEL_SAT", "info"] call FLO_fnc_sendNotification;

 
